# amadeus-sample-pipeline

Variable discovery and mini-dataset generation for the [amadeus](https://github.com/NIEHS/amadeus) R package (v2.0.1). The goal is to run the full `download → process → calculate` pipeline for every environmental exposure source and document what variables each source produces, what date ranges work, and what workarounds are needed — so this knowledge is available before writing a larger ExWAS pipeline.

The test geography is Oregon ZCTAs (n=419, year=2010), which matches the NIEHS PCOR bookdown reference example.

---

## Quick start

```r
# 1. Clone and open
# 2. Create .env with your credentials (see Auth section below)
# 3. Run:
Rscript scripts/amadeus_sample_download.R
```

Downloaded data lands in `data/amadeus_sample/` (gitignored). The script is fully idempotent — it checks for cached files before re-downloading.

---

## Pipeline pattern

Every amadeus source follows the same three-step pattern:

```r
amadeus::download_*(...)    # fetch raw files → data/amadeus_sample/<source>/
amadeus::process_*(...)     # load + clean → terra SpatRaster or SpatVector
amadeus::calculate_*(...)   # spatial join to locations → sf data frame
```

The `calculate_*` output has one row per location × time period, with exposure columns named `<variable>_<radius>` (radius in meters, 0 = point extraction).

---

## Source status

| Source | Status | Variables | Notes |
|---|---|---|---|
| HMS | OK | light_00000, medium_00000, heavy_00000 | Daily smoke intensity, binary |
| gridMET | OK | pr_0 | Daily precip; file cached per year |
| TerraClimate | OK | ppt_0 | Monthly precip |
| PRISM | OK | tmean_YYYYMMDD_0 | See PRISM workarounds below |
| GMTED | OK | gmted_0 | Elevation (m); 7.4 GB download, static |
| NLCD | OK | NLCD.Land.Cover.Class_0 | 2.6 GB tif; categorical land cover |
| Koppen-Geiger | OK | DUM_CLRG[A-E]_00000 | 5 climate group dummies |
| TRI | OK (slow) | STACK_AIR_\<CAS\>_\<radius\> (1,632) | See TRI notes below |
| Population | OK | population_0 | SEDAC GPWv4; 2.5 arc-min res (~47 MB) |
| gROADS | OK | GRD_TOTAL_01000, GRD_DENKM_01000 | See gROADS correction below — not actually auth-blocked |
| GOES | OK | Smoke_0 | GOES-16 ADP; ~83 MB/day |
| NEI | OK | TRF_NEINP_0_00000 | Onroad emissions, county-level; see NEI notes below |
| Drought (SPEI) | OK | spei_01_0 | Monthly SPEI-1; one global 365 MB file |
| Drought (EDDI) | OK | eddi_01_0 | Weekly EDDI-1 |
| Drought (USDM) | OK | usdm_dm_0 | Weekly drought-monitor class (0–4) |
| Ecoregion | OK | DUM_E2\<code\>_00000, DUM_E3\<code\>_00000 | See Ecoregion workaround below |
| NARR | OK | weasd_0 | Daily snow depth; see NARR workaround below |
| EDGAR | OK | edgar_..._pm2_5_2020_totals_emi_0 | Global emissions, yearly |
| AQS | OK (no calculate_\*) | site_id, lon, lat, time, Arithmetic.Mean | Dependent-variable data; see AQS notes below |
| IMPROVE | OK (no calculate_\*) | SiteCode, FactDate, ParamCode, FactValue | Dependent-variable data; see IMPROVE notes below |
| MODIS | OK | MOD_LSTDY_00000 | MOD11A1 land surface temp (K); see MODIS notes below |
| GEOS-CF | OK | level, o3_0 | Surface ozone; token works fine (not GES DISC-hosted) |
| HUC | SKIPPED | huc02_..., huc04_... | ~7 GB geodatabase |
| MERRA-2 | SKIPPED | T2M_0, ... | GES DISC auth — see auth section |
| CropScape | SKIPPED | — | ~10.4 GB/year — too large |

See [amadeus_sample_vars.md](amadeus_sample_vars.md) for variable lists and example data rows per source.

---

## Workarounds and gotchas

These are things not documented in the amadeus package that were discovered through trial and error.

### httr2 1.0+ compatibility patch

`amadeus 2.0.1` calls `httr2::req_retry(retry_on_failure = TRUE)` which was removed in `httr2 1.0.0`. The script patches `download_run_method` in-place at startup:

```r
if (utils::packageVersion("httr2") >= "1.0.0") {
  orig_fn     <- get("download_run_method", envir = asNamespace("amadeus"))
  fn_lines    <- deparse(body(orig_fn))
  fixed_lines <- gsub(",\\s*retry_on_failure\\s*=\\s*TRUE", "", fn_lines)
  body(orig_fn) <- parse(text = paste(fixed_lines, collapse = "\n"))[[1]]
  assignInNamespace("download_run_method", orig_fn, ns = "amadeus")
}
```

This patch will become unnecessary once amadeus is updated for httr2 1.0.

### "No URLs provided" error on cached files

Several sources (`download_gridmet`, `download_terraclimate`) build an empty URL list when files already exist locally and throw `"No URLs provided"` rather than silently skipping. The `try_download()` helper catches this pattern and continues to the `process_*` step.

### PRISM: two bugs in amadeus 2.0.1

1. **Vectorization bug**: `download_prism(time = c("start", "end"))` calls `ifelse()` with a scalar condition and vector args, returning only the first URL. Fix: call `download_prism()` once per date using `YYYYMMDD` format (not `YYYY-MM-DD`).

   ```r
   # Wrong — only downloads one file:
   download_prism(time = c("2021-06-01", "2021-06-03"), ...)
   
   # Correct:
   for (d in c("20210601", "20210602", "20210603")) download_prism(time = d, ...)
   ```

2. **Filename case mismatch**: `process_prism()` searches for `PRISM_*` (uppercase) but `download_prism()` now saves `prism_*` (lowercase) `.nc` files. Bypass `process_prism()` entirely:

   ```r
   nc_files <- list.files(path, pattern = "prism_tmean.*\\.nc$", full.names = TRUE)
   cov <- terra::rast(nc_files)
   names(cov) <- paste0("tmean_", regmatches(basename(nc_files),
                                              regexpr("[0-9]{8}", basename(nc_files))))
   ```

3. **`data_type` argument**: Valid values are `"ts"`, `"normals_800"`, `"normals"`. The value `"daily"` is not accepted and silently returns no files.

### GMTED and NLCD: no cache check in download functions

Both `download_gmted()` and `download_nlcd()` re-download the full file (7.4 GB and 2.6 GB respectively) on every run even when the file already exists. The script adds explicit guards before calling them:

```r
if (length(list.files(path, pattern = "be75_grd$")) == 0) download_gmted(...)
if (length(list.files(path, pattern = "\\.tif$"))   == 0) download_nlcd(...)
```

### GMTED: resolution string

The `variable` argument to `process_gmted()` must be `c("Breakline Emphasis", "7.5 arc-seconds")`. The filename `be75_grd` contains "be" = Breakline Emphasis and "75" = 7.5 arc-seconds (not 75). Using `"75 arc-seconds"` silently returns nothing.

### Koppen-Geiger: pass file path, not directory

`process_koppen_geiger()` requires a path to a specific `.tif`, not the parent directory:

```r
kg_tif <- fs::path(dl_dir, "data_files", "Beck_KG_V1_present_0p083.tif")
process_koppen_geiger(path = as.character(kg_tif))
```

The downloaded zip contains several resolutions (0p083, 0p5, 0p0083) and both present/future scenarios. Use `Beck_KG_V1_present_0p083.tif` for present-day at 0.083° (~9 km) resolution.

### Use centroid points, not polygon ZCTAs, for raster extraction

Passing polygon ZCTAs directly to `calculate_nlcd()` (exact mode), `calculate_koppen_geiger()`, or `calculate_gmted()` triggers full zonal statistics over 419 polygons, which can take minutes to never complete. Using `sf::st_centroid(or)` instead reduces each to a point lookup — milliseconds vs. timeout.

```r
or_pts <- sf::st_centroid(or)   # do this once, use everywhere
```

### TRI: scale `calculate_tri` to Oregon only

`calculate_tri()` runs an O(n_facilities × n_locations × n_chemicals) join. With 5 locations and 222 Oregon facilities it takes ~85 seconds. With all US facilities (~20,000) it would be impractical. Always filter the `SpatVector` to your study region before calling `calculate_tri()`:

```r
cov_vals <- terra::values(cov)
in_or    <- cov_vals[, "LONGITUDE"] >= or_bbox["xmin"] & ...
calculate_tri(from = cov[in_or], locs = or_pts[1:5, ], ...)
```

The output has 1,632 columns: 544 unique chemical CAS identifiers × 3 buffer radii (1 km, 10 km, 50 km). Column naming is `STACK_AIR_<CAS>_<radius>` where radius is `01000`, `10000`, or `50000`.

### gROADS correction: not actually GES DISC-blocked

An earlier version of this README skipped `gROADS` under the assumption that it hit the same GES DISC Bearer-token wall as MERRA-2, without testing it. That assumption was wrong. `gROADS` is hosted on **NASA SEDAC**, not GES DISC (same host as `Population`), and downloads fine with the same `NASA_EARTHDATA_TOKEN`. Roads are line features, so a `radius = 0` point buffer always returns zero length — use a positive buffer (e.g. 1 km) to get nonzero road density:

```r
calculate_groads(from = cov, locs = or_pts, locs_id = "ZCTA5CE10", radius = 1000, fun = "sum", geom = "sf")
```

Output columns: `GRD_TOTAL_<radius>` (total road length, km) and `GRD_DENKM_<radius>` (density, km/km²).

### Ecoregion and NARR: don't pass a lon/lat `extent` — native CRS is projected

`process_ecoregion()` and `process_narr()` both keep their source data in its native **projected** CRS (Albers Equal Area for Ecoregion, Lambert Conformal Conic for NARR) rather than reprojecting to EPSG:4326. Their `extent` argument is applied as if it were already in that projected CRS, so passing a lon/lat bounding box (as used for every raster source above) gets silently misapplied:

- **Ecoregion**: `extent = or_bbox` (lon/lat) crops to a `NaN` extent — the returned object is effectively empty, and `calculate_ecoregion()` matches 0 of 419 locations.
- **NARR**: `extent = or_bbox` gets interpreted as ~32 km of projected meters near the grid origin, so the crop keeps almost nothing and every extracted value comes back `0`/`NA`.

Fix: omit `extent` at `process_*()` time. `calculate_ecoregion()` / `calculate_narr()` reproject the input locations internally and extract correctly against the full raster/vector:

```r
cov <- process_ecoregion(path = shp)                         # no extent
cov <- process_narr(date = c(start, end), variable = "weasd", path = dl_dir)  # no extent
```

`calculate_ecoregion(..., geom = "sf")` also produces a spurious `geometry.x`/`geometry.y` artifact rather than real geometry; use `geom = FALSE` instead.

### NEI: `calculate_nei()` doesn't subset `locs` columns

Unlike other `calculate_*()` functions, `calculate_nei()` preserves every column of the `locs` object verbatim rather than returning just `locs_id` + value columns. Passing `or_pts` directly carries all of tigris's ZCTA metadata (`STATEFP10`, `GEOID10`, `ALAND10`, ...) into the output. Pass only the ID column:

```r
calculate_nei(from = cov, locs = or_pts[, "ZCTA5CE10"], locs_id = "ZCTA5CE10", geom = "sf")
```

`process_nei()` also requires a `county` argument (an `sf`/`SpatVector` of county boundaries, e.g. `tigris::counties(state = "OR", year = 2020)`) to spatially join the county-level CSV data.

### AQS and IMPROVE: no `calculate_*()` wrapper; extent order differs

Neither `download_aqs()`/`process_aqs()` nor `download_improve()`/`process_improve()` has a companion `calculate_*()` function in amadeus — both are monitoring-station point data intended as **dependent variables**, not spatial-join covariates, so the pipeline stops at `process_*()`.

`process_aqs()` and `process_improve()` both expect `extent` in `c(xmin, xmax, ymin, ymax)` order — **not** the `c(xmin, ymin, xmax, ymax)` order of `sf::st_bbox()` (which every other `extent`-accepting function in this script uses):

```r
aqs_extent <- c(or_bbox["xmin"], or_bbox["xmax"], or_bbox["ymin"], or_bbox["ymax"])
```

`download_improve()` also extracts its `.txt` file directly into the save directory, not into a `data_files/` subdirectory like every other `download_*()` function — pass the top-level directory to `process_improve()`, not `fs::path(dl_dir, "data_files")`.

IMPROVE samples on a roughly 1-in-3-day cycle, so filtering to a single arbitrary date often returns zero rows; use a date range of at least a few weeks.

### MODIS: `extent` order and duplicate `date` argument

The `extent` argument to `download_modis()` is documented as `c(min_lon, max_lon, min_lat, max_lat)`, but the actual order — verified against the function's own CONUS default value — is `c(min_lon, min_lat, max_lon, max_lat)`, matching `sf::st_bbox()` order:

```r
modis_extent <- c(or_bbox["xmin"], or_bbox["ymin"], or_bbox["xmax"], or_bbox["ymax"])
```

Separately, `calculate_modis()` infers the date from the downloaded HDF filenames itself. Passing an explicit `date =` argument throws `formal argument "date" matched by multiple actual arguments` — omit it.

### GEOS-CF: works fine with the NASA token; `process_geos()` doesn't crop

Unlike MERRA-2, `GEOS-CF` is served over OPeNDAP (`opendap.nccs.nasa.gov`), not GES DISC, so the same `Authorization: Bearer <token>` that fails for MERRA-2 works here without issue. Separately, `process_geos()`'s `extent` argument doesn't actually crop the returned raster — it stays global (721×1440). This isn't fatal since `calculate_geos()` still extracts the correct values at each point, but the full global raster is held in memory during extraction.

### CropScape: skipped, too large

A single national CropScape year (zip + full-resolution tif + pyramid overview file) totals **~10.4 GB** — larger than any other source in this pipeline, including GMTED's 7.4 GB. Not included in local discovery runs.

---

## Auth setup

`amadeus` provides [`setup_nasa_token()`](https://niehs.github.io/amadeus/#nasa-earthdata-authentication-with-setup_nasa_token) for NASA Earthdata Login bearer tokens, required by `modis`, `merra2`, `geos`, and `population` (NASA SEDAC) sources. It supports three storage methods:

- `method = "renviron"` — writes `NASA_EARTHDATA_TOKEN` to `~/.Renviron` (persistent, personal machines)
- `method = "file"` — writes a local token file, e.g. `~/.nasa_earthdata_token`
- `method = "session"` — `Sys.setenv()` for the current R session only (shared systems / CI, token supplied from a secret)

```r
setup_nasa_token()                                   # prompts interactively
setup_nasa_token(method = "renviron", token = "<your_token>")
```

**Never commit Earthdata tokens to git or include them in shared scripts.** Prefer `method = "renviron"` on personal machines; use `method = "session"` on shared systems or CI where the token comes from a CI secret.

This repo's `amadeus_sample_download.R` predates that helper and instead reads `NASA_EARTHDATA_TOKEN` from a `.env` file (gitignored) via `dotenv::load_dot_env()`:

```
NASA_EARTHDATA_TOKEN=<your_token>
```

Either approach works — both just need `NASA_EARTHDATA_TOKEN` set in the environment before `download_*()` is called. `setup_nasa_token(method = "renviron")` is the path recommended upstream by amadeus.

**MERRA-2 auth caveat**: Even with a valid NASA EarthData JWT Bearer token, GES DISC returns HTTP 401 for `.nc4` data files. GES DISC uses `.netrc`-based basic auth, not Bearer tokens. `amadeus::download_merra2()` sends `Authorization: Bearer <token>`, which is rejected. The metadata XML files (public) succeed, so the token is valid — the mechanism is just wrong for data files. This is specific to GES DISC: other NASA-hosted sources used in this pipeline (`Population`, `gROADS` via SEDAC; `MODIS`, `GEOS-CF` via their own endpoints) all work fine with the same Bearer token — see the gROADS correction and GEOS-CF notes above.

To use MERRA-2 on HPC: add a `~/.netrc` entry:
```
machine urs.earthdata.nasa.gov login <username> password <password>
```

The NASA EarthData token itself (JWT format) works for other services but not GES DISC nc4 downloads. This is a known GES DISC-specific auth requirement.

---

## Data directory

```
data/amadeus_sample/          # gitignored; ~11 GB total
├── hms/                      # 3.2 MB — shapefiles per day
├── gridmet/                  # 58 MB — annual nc per variable
├── terraclimate/             # 146 MB — annual nc per variable
├── prism/                    # 15 MB — nc per date
├── gmted/                    # 7.4 GB — global DEM grid
├── nlcd/                     # 2.6 GB — CONUS land cover tif
├── koppen_geiger/            # 234 MB — global climate class tifs
├── tri/                      # 59 MB — national facility CSV
├── huc/                      # empty (download skipped)
└── merra2/                   # metadata XML only (auth blocked)
```

---

## Context for continuing this work

This repo started as part of the **HCUP PEGs ExWAS** project ([NIEHS/hcup_pegs_exwas](https://github.com/NIEHS/hcup_pegs_exwas)), where the goal is to construct environmental exposure windows for surgical patients using ZIP code linkage. The amadeus pipeline produces the exposure covariates; this repo is the discovery phase for understanding what each source provides before wiring it into the full ExWAS pipeline.

The next logical steps from here would be:
- Scale HMS, gridMET, TerraClimate, and PRISM to the full study date range and all patient ZCTAs
- Resolve MERRA-2 auth on HPC (add `~/.netrc`)
- Decide whether to include TRI and, if so, how to handle the 1,632 sparse columns
- Handle HUC if watershed-level exposure is wanted
- Port working `calculate_*` calls into the SLURM worker scripts in hcup_pegs_exwas

Key reference: [NIEHS PCOR bookdown — HMS use-case chapter](https://niehs.github.io/PCOR_bookdown_staging/chapter-hcup-amadeus-usecase.html)
