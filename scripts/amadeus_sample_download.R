# scripts/amadeus_sample_download.R
#
# Builds mini datasets from each amadeus exposure source using the full
# download → process → calculate pipeline. Oregon ZCTAs are the test
# locations. Run source-by-source; each block is self-contained.
#
# Reference: https://niehs.github.io/PCOR_bookdown_staging/
#              chapter-hcup-amadeus-usecase.html
#
# Usage:
#   Rscript scripts/amadeus_sample_download.R
#
# See README.md for workarounds, known issues, and auth setup.

suppressPackageStartupMessages({
  if (!requireNamespace("here",    quietly = TRUE)) install.packages("here")
  if (!requireNamespace("fs",      quietly = TRUE)) install.packages("fs")
  if (!requireNamespace("dotenv",  quietly = TRUE)) install.packages("dotenv")
  if (!requireNamespace("amadeus", quietly = TRUE)) stop("Install amadeus first (see README.md)")
  library(here)
  library(fs)
})

# NASA Earthdata token — see README.md "Auth setup".
# Prefer a token already persisted via `amadeus::setup_nasa_token(method = "renviron")`
# (loaded automatically into the environment when R starts). Otherwise fall back to
# this repo's gitignored .env file, registering it for the session via amadeus's own
# setup_nasa_token(method = "session") rather than setting Sys.setenv() directly.
if (!nzchar(Sys.getenv("NASA_EARTHDATA_TOKEN"))) {
  if (file.exists(here(".env"))) {
    dotenv::load_dot_env(here(".env"))
    env_token <- trimws(Sys.getenv("NASA_EARTHDATA_TOKEN", ""))
    if (nzchar(env_token)) amadeus::setup_nasa_token(method = "session", token = env_token)
  } else if (interactive()) {
    amadeus::setup_nasa_token()  # prompts and stores to ~/.Renviron
  }
}

suppressPackageStartupMessages({
  library(amadeus)
  library(terra)
  library(tigris)
  library(sf)
})
options(tigris_use_cache = TRUE)

# ── Config ────────────────────────────────────────────────────────────────────
CACHE_DIR <- fs::path(here("data"), "amadeus_sample")
fs::dir_create(CACHE_DIR)

NASA_TOKEN <- trimws(Sys.getenv("NASA_EARTHDATA_TOKEN", ""))
HAS_NASA   <- nchar(NASA_TOKEN) > 0

# ── httr2 1.0+ compatibility patch ───────────────────────────────────────────
# amadeus 2.0.1 calls req_retry(retry_on_failure=TRUE) which was removed in
# httr2 1.0.0. Patch it in-place so downloads don't error on modern httr2.
if (utils::packageVersion("httr2") >= "1.0.0") {
  orig_fn     <- get("download_run_method", envir = asNamespace("amadeus"))
  fn_lines    <- deparse(body(orig_fn))
  fixed_lines <- gsub(",\\s*retry_on_failure\\s*=\\s*TRUE", "", fn_lines)
  body(orig_fn) <- parse(text = paste(fixed_lines, collapse = "\n"))[[1]]
  assignInNamespace("download_run_method", orig_fn, ns = "amadeus")
  cat("Patched amadeus::download_run_method for httr2 >= 1.0\n\n")
}

# ── Test locations: Oregon ZCTAs (matches bookdown example) ──────────────────
cat("Loading Oregon ZCTAs...\n")
or      <- tigris::zctas(state = "OR", year = 2010)
or_bbox <- sf::st_bbox(or)
LOCS_ID <- "ZCTA5CE10"

# Centroid points for fast raster extraction (avoids slow zonal stats on polygons)
or_pts <- sf::st_centroid(or)
cat(sprintf("  %d Oregon ZCTAs loaded\n\n", nrow(or)))

cat("amadeus version:", as.character(packageVersion("amadeus")), "\n")
cat("NASA auth:      ", if (HAS_NASA) "YES (note: MERRA-2/gROADS still skipped — GES DISC needs ~/.netrc)" else "NO (MERRA-2 / gROADS will be skipped)", "\n\n")

# ── Helpers ───────────────────────────────────────────────────────────────────
results <- list()

# Version-safe caller: drops args the installed amadeus version doesn't accept
safe_call <- function(fn_name, ...) {
  fn <- tryCatch(get(fn_name, envir = asNamespace("amadeus")),
                 error = function(e) NULL)
  if (is.null(fn)) stop(sprintf("'%s' not found in amadeus", fn_name))
  accepted <- names(formals(fn))
  args     <- list(...)
  if ("..." %in% accepted) do.call(fn, args)
  else                     do.call(fn, args[names(args) %in% accepted])
}

# Wrap download so that "No URLs" (already cached) is silently ignored
try_download <- function(...) {
  tryCatch(safe_call(...), error = function(e) {
    if (grepl("No URLs|no URLs", conditionMessage(e))) {
      cat("    (files already cached, skipping download)\n")
    } else {
      stop(e)
    }
  })
}

run_source <- function(label, expr, auth_required = FALSE) {
  if (auth_required && !HAS_NASA) {
    cat(sprintf("[SKIP] %s — NASA_EARTHDATA_TOKEN not set\n\n", label))
    results[[label]] <<- list(status = "skipped", vars = character(0))
    return(invisible(NULL))
  }
  cat(sprintf("── %s ──\n", label))
  tryCatch({
    df   <- expr
    vars <- setdiff(names(df), c(LOCS_ID, "time", "geometry"))
    cat(sprintf("  OK | %d rows × %d exposure cols\n", nrow(df), length(vars)))
    cat(sprintf("  vars: %s\n\n", paste(vars, collapse = ", ")))
    results[[label]] <<- list(status = "ok", vars = vars, n_rows = nrow(df))
  }, error = function(e) {
    cat(sprintf("  ERROR: %s\n\n", conditionMessage(e)))
    results[[label]] <<- list(status = "error", msg = conditionMessage(e),
                               vars = character(0))
  })
}

subdir <- function(nm) {
  d <- fs::path(CACHE_DIR, nm)
  fs::dir_create(d)
  as.character(d)
}

# ═══════════════════════════════════════════════════════════════════════════════
# 1. HMS smoke plumes
#    Oregon had heavy wildfire smoke Aug–Sep 2021; use that window.
# ═══════════════════════════════════════════════════════════════════════════════
run_source("HMS", {
  dl_dir    <- subdir("hms")
  HMS_START <- "2021-08-01"
  HMS_END   <- "2021-09-15"

  try_download("download_hms",
    data_format       = "shapefile",
    date              = c(HMS_START, HMS_END),
    directory_to_save = dl_dir,
    acknowledgement   = TRUE,
    download          = TRUE
  )

  cov <- process_hms(
    date   = c(HMS_START, HMS_END),
    path   = fs::path(dl_dir, "data_files"),
    extent = or_bbox
  )

  calculate_hms(
    from    = cov,
    locs    = or_pts,
    locs_id = LOCS_ID,
    radius  = 0,
    geom    = "sf"
  )
})

# ═══════════════════════════════════════════════════════════════════════════════
# 2. gridMET — daily precipitation for one week in June 2023
# ═══════════════════════════════════════════════════════════════════════════════
run_source("gridMET", {
  dl_dir <- subdir("gridmet")
  GM_START <- "2023-06-01"
  GM_END   <- "2023-06-07"
  GM_YEAR  <- 2023L

  try_download("download_gridmet",
    variables         = "pr",
    year              = GM_YEAR,
    directory_to_save = dl_dir,
    acknowledgement   = TRUE,
    download          = TRUE
  )

  # download_gridmet saves to <dl_dir>/<variable>/<variable>_<year>.nc
  cov <- process_gridmet(
    date     = c(GM_START, GM_END),
    variable = "pr",
    path     = fs::path(dl_dir, "pr")
  )

  calculate_gridmet(
    from    = cov,
    locs    = or_pts,
    locs_id = LOCS_ID,
    radius  = 0,
    fun     = "mean",
    geom    = "sf"
  )
})

# ═══════════════════════════════════════════════════════════════════════════════
# 3. TerraClimate — monthly precipitation for 2023
# ═══════════════════════════════════════════════════════════════════════════════
run_source("TerraClimate", {
  dl_dir <- subdir("terraclimate")
  TC_YEAR <- 2023L

  try_download("download_terraclimate",
    variables         = "ppt",
    year              = TC_YEAR,
    directory_to_save = dl_dir,
    acknowledgement   = TRUE,
    download          = TRUE
  )

  # TerraClimate saves to <dl_dir>/<variable>/<variable>_<year>.nc
  cov <- process_terraclimate(
    date     = c("2023-01-01", "2023-06-28"),
    variable = "ppt",
    path     = fs::path(dl_dir, "ppt")
  )

  calculate_terraclimate(
    from    = cov,
    locs    = or_pts,
    locs_id = LOCS_ID,
    radius  = 0,
    fun     = "mean",
    geom    = "sf"
  )
})

# ═══════════════════════════════════════════════════════════════════════════════
# 4. PRISM — daily mean temperature for 3 days in June 2021
#    Workarounds:
#    (a) download_prism(time=c(start,end)) triggers an ifelse vectorization bug;
#        call once per date using YYYYMMDD format instead.
#    (b) process_prism expects uppercase "PRISM_*" filenames but the download
#        now produces lowercase "prism_*" nc files; load directly with terra.
# ═══════════════════════════════════════════════════════════════════════════════
run_source("PRISM", {
  dl_dir <- subdir("prism")
  PR_DATES <- c("20210601", "20210602", "20210603")

  for (d in PR_DATES) {
    try_download("download_prism",
      time              = d,
      element           = "tmean",
      data_type         = "ts",
      directory_to_save = dl_dir,
      acknowledgement   = TRUE,
      download          = TRUE
    )
  }

  # process_prism file pattern doesn't match the nc filenames; load directly
  nc_files <- list.files(
    fs::path(dl_dir, "data_files"),
    pattern    = "prism_tmean.*\\.nc$",
    full.names = TRUE
  )
  cov <- terra::rast(nc_files)
  dates <- regmatches(basename(nc_files),
                      regexpr("[0-9]{8}", basename(nc_files)))
  names(cov) <- paste0("tmean_", dates)

  calculate_prism(
    from    = cov,
    locs    = or_pts,
    locs_id = LOCS_ID,
    radius  = 0,
    geom    = "sf"
  )
})

# ═══════════════════════════════════════════════════════════════════════════════
# 5. GMTED — elevation (Breakline Emphasis, 7.5 arc-seconds)
#    Static; download once. "be75" in filename = 7.5 arc-seconds.
# ═══════════════════════════════════════════════════════════════════════════════
run_source("GMTED", {
  dl_dir <- subdir("gmted")

  # download_gmted re-downloads even when cached; skip if grid already present
  gmted_grid <- list.files(fs::path(dl_dir, "data_files"),
                           pattern = "be75_grd$", full.names = TRUE)
  if (length(gmted_grid) == 0) {
    try_download("download_gmted",
      directory_to_save = dl_dir,
      acknowledgement   = TRUE,
      download          = TRUE
    )
  } else {
    cat("    (GMTED grid already cached, skipping download)\n")
  }

  cov <- process_gmted(
    variable = c("Breakline Emphasis", "7.5 arc-seconds"),
    path     = fs::path(dl_dir, "data_files")
  )

  calculate_gmted(
    from    = cov,
    locs    = or_pts,
    locs_id = LOCS_ID,
    radius  = 0,
    fun     = "mean",
    geom    = "sf"
  )
})

# ═══════════════════════════════════════════════════════════════════════════════
# 6. NLCD — land cover class 2021
#    process_nlcd returns raw categorical raster; calculate_nlcd gives class at pt
# ═══════════════════════════════════════════════════════════════════════════════
run_source("NLCD", {
  dl_dir <- subdir("nlcd")

  # download_nlcd re-downloads even when cached; skip if .tif already present
  nlcd_tif <- list.files(fs::path(dl_dir, "data_files"),
                          pattern = "\\.tif$", full.names = TRUE)
  if (length(nlcd_tif) == 0) {
    try_download("download_nlcd",
      year              = 2021L,
      directory_to_save = dl_dir,
      acknowledgement   = TRUE,
      download          = TRUE
    )
  } else {
    cat("    (NLCD .tif already cached, skipping download)\n")
  }

  cov <- process_nlcd(path = dl_dir, year = 2021L)

  # Use centroid points: polygon extraction ("exact" mode) over 419 ZCTAs is
  # very slow; centroid lookup returns the land cover class at each ZCTA center.
  calculate_nlcd(
    from    = cov,
    locs    = or_pts,
    locs_id = LOCS_ID,
    mode    = "exact",
    radius  = 0,
    geom    = "sf"
  )
})

# ═══════════════════════════════════════════════════════════════════════════════
# 7. Koppen-Geiger climate classification
#    process_koppen_geiger needs path to a specific .tif, not a directory
# ═══════════════════════════════════════════════════════════════════════════════
run_source("Koppen-Geiger", {
  dl_dir <- subdir("koppen_geiger")

  try_download("download_koppen_geiger",
    directory_to_save = dl_dir,
    acknowledgement   = TRUE,
    download          = TRUE
  )

  # Use 0.083° resolution (present-day) as a balance of resolution vs. size
  kg_tif <- fs::path(dl_dir, "data_files", "Beck_KG_V1_present_0p083.tif")
  cov <- process_koppen_geiger(path = as.character(kg_tif))

  # Use centroid points: fractional class coverage over polygon ZCTAs is slow
  calculate_koppen_geiger(
    from    = cov,
    locs    = or_pts,
    locs_id = LOCS_ID,
    geom    = "sf"
  )
})

# ═══════════════════════════════════════════════════════════════════════════════
# 8. TRI — Toxic Release Inventory (point sources → spatial decay to ZCTAs)
#    process_tri returns a SpatVector with per-chemical columns
# ═══════════════════════════════════════════════════════════════════════════════
run_source("TRI", {
  dl_dir <- subdir("tri")

  try_download("download_tri",
    year              = 2023L,
    directory_to_save = dl_dir,
    acknowledgement   = TRUE,
    download          = TRUE
  )

  cov <- process_tri(path = dl_dir, year = 2023L)

  # calculate_tri joins per chemical per location — filter to Oregon facilities
  # and 5 sample centroids to keep runtime feasible (~85s for 5 locs x 222 fac).
  cov_vals <- terra::values(cov)
  in_or <- cov_vals[, "LONGITUDE"] >= or_bbox["xmin"] &
    cov_vals[, "LONGITUDE"] <= or_bbox["xmax"] &
    cov_vals[, "LATITUDE"]  >= or_bbox["ymin"] &
    cov_vals[, "LATITUDE"]  <= or_bbox["ymax"]
  cov_or <- cov[in_or]
  cat(sprintf("    TRI facilities in Oregon bbox: %d\n", nrow(cov_or)))

  calculate_tri(
    from    = cov_or,
    locs    = or_pts[1:5, ],
    locs_id = LOCS_ID,
    geom    = "sf"
  )
})

# ═══════════════════════════════════════════════════════════════════════════════
# 9. Population — NASA SEDAC gridded population density (GPWv4)
#    Use 2.5 arc-minute resolution: the default 30 arc-second is a multi-GB
#    global GeoTIFF; 2.5 arc-minute is ~47MB and plenty for ZCTA-scale joins.
# ═══════════════════════════════════════════════════════════════════════════════
run_source("Population", {
  dl_dir <- subdir("population")

  try_download("download_population",
    data_resolution   = "2.5 minute",
    data_format       = "GeoTIFF",
    year              = "2020",
    directory_to_save = dl_dir,
    acknowledgement   = TRUE,
    download          = TRUE
  )

  tif <- list.files(fs::path(dl_dir, "data_files"), pattern = "\\.tif$", full.names = TRUE)
  cov <- process_population(path = tif, extent = or_bbox)

  calculate_population(
    from    = cov,
    locs    = or_pts,
    locs_id = LOCS_ID,
    radius  = 0,
    fun     = "mean",
    geom    = "sf"
  )
}, auth_required = TRUE)

# ═══════════════════════════════════════════════════════════════════════════════
# 10. gROADS — NASA SEDAC Global Roads Open Access Data Set
#     NOTE: an earlier version of this script skipped gROADS assuming it hit
#     the same GES DISC Bearer-token wall as MERRA-2 (see section 21 below).
#     That assumption was never tested. gROADS is SEDAC-hosted, not GES
#     DISC-hosted, and downloads fine with the same NASA_EARTHDATA_TOKEN.
# ═══════════════════════════════════════════════════════════════════════════════
run_source("gROADS", {
  dl_dir <- subdir("groads")

  try_download("download_groads",
    data_region       = "Americas",
    data_format       = "Shapefile",
    directory_to_save = dl_dir,
    acknowledgement   = TRUE,
    download          = TRUE
  )

  shp <- list.files(fs::path(dl_dir, "data_files"), pattern = "\\.shp$",
                     full.names = TRUE, recursive = TRUE)
  cov <- process_groads(path = shp, extent = or_bbox)

  # Roads are line features — a 0m point buffer always returns zero length.
  # Use a 1km buffer (the function default) to get nonzero road density.
  calculate_groads(
    from    = cov,
    locs    = or_pts,
    locs_id = LOCS_ID,
    radius  = 1000,
    fun     = "sum",
    geom    = "sf"
  )
}, auth_required = TRUE)

# ═══════════════════════════════════════════════════════════════════════════════
# 11. GOES ADP — NOAA GOES-16 Aerosol Detection Product (Smoke)
#     Uses the same wildfire smoke day as HMS (2021-08-17) as a natural
#     cross-check: continuous satellite-detected smoke fraction vs. HMS's
#     binary intensity categories.
# ═══════════════════════════════════════════════════════════════════════════════
run_source("GOES", {
  dl_dir     <- subdir("goes")
  GOES_DATE  <- "2021-08-17"

  try_download("download_goes",
    date              = GOES_DATE,
    satellite         = "16",
    product           = "ADP-C",
    directory_to_save = dl_dir,
    acknowledgement   = TRUE,
    download          = TRUE
  )

  cov <- process_goes(
    date      = c(GOES_DATE, GOES_DATE),
    variable  = "Smoke",
    path      = dl_dir,
    extent    = or_bbox,
    daily_agg = TRUE,
    fun       = "mean"
  )

  calculate_goes(
    from    = cov,
    locs    = or_pts,
    locs_id = LOCS_ID,
    radius  = 0,
    fun     = "mean",
    geom    = "sf"
  )
})

# ═══════════════════════════════════════════════════════════════════════════════
# 12. NEI — EPA National Emissions Inventory (onroad emissions, county-level)
#     Workaround: calculate_nei() preserves every column of `locs` verbatim
#     (unlike other calculate_* functions, which subset to locs_id/time/value).
#     Pass only the ID column to avoid carrying tigris ZCTA metadata columns
#     (STATEFP10, GEOID10, ALAND10, ...) into the result.
# ═══════════════════════════════════════════════════════════════════════════════
run_source("NEI", {
  dl_dir <- subdir("nei")

  try_download("download_nei",
    year              = 2020L,
    directory_to_save = dl_dir,
    acknowledgement   = TRUE,
    download          = TRUE
  )

  or_counties <- tigris::counties(state = "OR", year = 2020)
  cov <- process_nei(path = fs::path(dl_dir, "data_files"), county = or_counties, year = 2020L)

  calculate_nei(
    from    = cov,
    locs    = or_pts[, LOCS_ID],
    locs_id = LOCS_ID,
    geom    = "sf"
  )
})

# ═══════════════════════════════════════════════════════════════════════════════
# 13. Drought indices — SPEI (monthly), EDDI (weekly), USDM (weekly polygons)
#     Three sources share one download_drought()/process_drought() API but
#     return different object types, so each gets its own run_source() call.
# ═══════════════════════════════════════════════════════════════════════════════
DR_START <- "2020-06-01"
DR_END   <- "2020-06-30"

run_source("Drought-SPEI", {
  dl_dir <- subdir("drought_spei")

  try_download("download_drought",
    source            = "spei",
    date              = c(DR_START, DR_END),
    timescale         = 1L,
    directory_to_save = dl_dir,
    acknowledgement   = TRUE
  )

  # SPEI ships as one global multi-year file (spei01.nc, ~365MB); date only
  # selects which layer(s) process_drought() returns, not what's downloaded.
  cov <- process_drought(source = "spei", path = dl_dir, date = c(DR_START, DR_END),
                          timescale = 1L, extent = or_bbox)

  calculate_drought(from = cov, locs = or_pts, locs_id = LOCS_ID, radius = 0L,
                     fun = "mean", geom = "sf")
})

run_source("Drought-EDDI", {
  dl_dir <- subdir("drought_eddi")

  try_download("download_drought",
    source            = "eddi",
    date              = c(DR_START, DR_END),
    timescale         = 1L,
    directory_to_save = dl_dir,
    acknowledgement   = TRUE
  )

  cov <- process_drought(source = "eddi", path = dl_dir, date = c(DR_START, DR_END),
                          timescale = 1L, extent = or_bbox)

  calculate_drought(from = cov, locs = or_pts, locs_id = LOCS_ID, radius = 0L,
                     fun = "mean", geom = "sf")
})

run_source("Drought-USDM", {
  dl_dir <- subdir("drought_usdm")

  try_download("download_drought",
    source            = "usdm",
    date              = c(DR_START, DR_END),
    directory_to_save = dl_dir,
    acknowledgement   = TRUE
  )

  cov <- process_drought(source = "usdm", path = dl_dir, date = c(DR_START, DR_END), extent = or_bbox)

  calculate_drought(from = cov, locs = or_pts, locs_id = LOCS_ID, radius = 0L, geom = "sf")
})

# ═══════════════════════════════════════════════════════════════════════════════
# 14. Ecoregion — EPA Level III Ecoregions
#     Workaround: process_ecoregion() keeps the shapefile's native Albers
#     Equal Area projected CRS. Passing a lon/lat `extent` (as used for every
#     other raster source in this script) gets silently misapplied in
#     projected units, cropping the layer to nothing (0/419 locations
#     matched). Skip `extent` here — calculate_ecoregion() reprojects the
#     input locations to match `from`'s CRS internally, so it works without it.
# ═══════════════════════════════════════════════════════════════════════════════
run_source("Ecoregion", {
  dl_dir <- subdir("ecoregion")

  try_download("download_ecoregion",
    directory_to_save = dl_dir,
    acknowledgement   = TRUE,
    download          = TRUE
  )

  shp <- list.files(fs::path(dl_dir, "data_files"), pattern = "\\.shp$",
                     full.names = TRUE, recursive = TRUE)
  cov <- process_ecoregion(path = shp)

  # geom = "sf" here produces a duplicated geometry.x/geometry.y artifact
  # rather than real geometry; use geom = FALSE (a plain data.frame join works
  # fine for the run_source() variable summary below).
  calculate_ecoregion(from = cov, locs = or_pts, locs_id = LOCS_ID, geom = FALSE)
})

# ═══════════════════════════════════════════════════════════════════════════════
# 15. NARR — NOAA North American Regional Reanalysis (daily snow depth, weasd)
#     Same CRS gotcha as Ecoregion: process_narr() keeps the native Lambert
#     Conformal Conic grid, and a lon/lat `extent` gets misapplied in
#     projected meters — the crop collapses to a ~32km box near the grid
#     origin and every extracted value comes back 0/NA. Skip `extent` at
#     process time; calculate_narr() reprojects locations correctly.
# ═══════════════════════════════════════════════════════════════════════════════
run_source("NARR", {
  dl_dir <- subdir("narr")

  try_download("download_narr",
    variables         = "weasd",
    year              = 2022,
    directory_to_save = dl_dir,
    acknowledgement   = TRUE,
    download          = TRUE
  )

  cov <- process_narr(date = c("2022-01-01", "2022-01-05"), variable = "weasd", path = dl_dir)

  calculate_narr(from = cov, locs = or_pts, locs_id = LOCS_ID, radius = 0,
                 fun = "mean", geom = "sf")
})

# ═══════════════════════════════════════════════════════════════════════════════
# 16. EDGAR — global emissions inventory (PM2.5, yearly totals)
# ═══════════════════════════════════════════════════════════════════════════════
run_source("EDGAR", {
  dl_dir <- subdir("edgar")

  try_download("download_edgar",
    species           = "PM2.5",
    version           = "8.1",
    temp_res          = "yearly",
    format            = "nc",
    output            = "emi",
    year_range        = 2020,
    directory_to_save = dl_dir,
    acknowledgement   = TRUE,
    download          = TRUE
  )

  nc_file <- list.files(fs::path(dl_dir, "data_files"), pattern = "\\.nc$", full.names = TRUE)
  cov <- process_edgar(path = nc_file, extent = or_bbox)

  calculate_edgar(from = cov, locs = or_pts, locs_id = LOCS_ID, radius = 0,
                   fun = "mean", geom = "sf")
})

# ═══════════════════════════════════════════════════════════════════════════════
# 17. AQS — EPA Air Quality System (PM2.5 daily monitors)
#     No calculate_aqs() exists in amadeus: AQS is monitoring-station point
#     data meant as a dependent variable, not a spatial-join covariate.
#     process_aqs() alone returns per-site daily measurements within extent.
#     NOTE: process_aqs()'s extent order is (xmin, xmax, ymin, ymax) — NOT
#     the (xmin, ymin, xmax, ymax) order of sf::st_bbox().
# ═══════════════════════════════════════════════════════════════════════════════
run_source("AQS", {
  dl_dir <- subdir("aqs")

  try_download("download_aqs",
    parameter_code      = 88101,
    resolution_temporal = "daily",
    year                = 2023,
    directory_to_save   = dl_dir,
    acknowledgement     = TRUE,
    download            = TRUE
  )

  aqs_extent <- c(or_bbox["xmin"], or_bbox["xmax"], or_bbox["ymin"], or_bbox["ymax"])
  process_aqs(
    path          = fs::path(dl_dir, "data_files"),
    date          = c("2023-08-15", "2023-08-15"),
    mode          = "available-data",
    return_format = "sf",
    extent        = aqs_extent
  )
})

# ═══════════════════════════════════════════════════════════════════════════════
# 18. IMPROVE — aerosol monitoring at federal Class I areas
#     No calculate_improve() exists in amadeus (same rationale as AQS).
#     Workarounds:
#     (a) download_improve() extracts .txt files directly into the save
#         directory, not into a "data_files" subdirectory like other
#         download_*() functions — pass the top-level dir to process_improve().
#     (b) IMPROVE samples on a ~1-in-3-day cycle; a single arbitrary date
#         often returns zero rows. Use a full month window instead.
# ═══════════════════════════════════════════════════════════════════════════════
run_source("IMPROVE", {
  dl_dir <- subdir("improve")

  try_download("download_improve",
    year              = 2020,
    product           = "raw",
    directory_to_save = dl_dir,
    acknowledgement   = TRUE,
    download          = TRUE
  )

  improve_extent <- c(or_bbox["xmin"], or_bbox["xmax"], or_bbox["ymin"], or_bbox["ymax"])
  process_improve(
    path          = dl_dir,
    product       = "raw",
    date          = c("2020-06-01", "2020-06-30"),
    return_format = "sf",
    extent        = improve_extent
  )
})

# ═══════════════════════════════════════════════════════════════════════════════
# 19. MODIS — MOD11A1 land surface temperature (Kelvin)
#     Workarounds:
#     (a) The `extent` argument order is (min_lon, min_lat, max_lon, max_lat)
#         despite the amadeus docs describing it as (min_lon, max_lon,
#         min_lat, max_lat) — verified against the function's own CONUS
#         default value, which only makes sense in the former order.
#     (b) calculate_modis() infers `date` from the downloaded HDF filenames
#         itself; passing an explicit date= throws "formal argument matched
#         by multiple actual arguments".
# ═══════════════════════════════════════════════════════════════════════════════
run_source("MODIS", {
  dl_dir     <- subdir("modis")
  MODIS_DATE <- "2023-08-15"
  modis_extent <- c(or_bbox["xmin"], or_bbox["ymin"], or_bbox["xmax"], or_bbox["ymax"])

  try_download("download_modis",
    product           = "MOD11A1",
    version           = "061",
    date              = MODIS_DATE,
    extent            = modis_extent,
    directory_to_save = dl_dir,
    acknowledgement   = TRUE,
    download          = TRUE
  )

  hdf_files <- list.files(dl_dir, pattern = "\\.hdf$", full.names = TRUE, recursive = TRUE)

  calculate_modis(
    from            = hdf_files,
    locs            = or_pts,
    locs_id         = LOCS_ID,
    radius          = 0,
    subdataset      = "^LST_Day_1km$",
    name_covariates = "MOD_LSTDY_",
    scale           = "* 0.02",
    geom            = "sf"
  )
}, auth_required = TRUE)

# ═══════════════════════════════════════════════════════════════════════════════
# 20. GEOS-CF — NASA atmospheric composition forecast (surface ozone, O3)
#     GEOS-CF is served over OPeNDAP (opendap.nccs.nasa.gov), not GES DISC —
#     the NASA_EARTHDATA_TOKEN Bearer auth that fails for MERRA-2 works fine
#     here.
#     Note: process_geos()'s `extent` argument does not crop the raster (it
#     stays global, 721x1440); not fatal since calculate_geos() still
#     extracts correctly at points, but the full global raster is held in
#     memory during extraction.
# ═══════════════════════════════════════════════════════════════════════════════
run_source("GEOS-CF", {
  dl_dir    <- subdir("geos")
  GEOS_DATE <- "2023-08-15"

  try_download("download_geos",
    collection        = "aqc_tavg_1hr_g1440x721_v1",
    date              = GEOS_DATE,
    directory_to_save = dl_dir,
    acknowledgement   = TRUE,
    download          = TRUE
  )

  cov <- process_geos(date = c(GEOS_DATE, GEOS_DATE), variable = "O3", path = dl_dir,
                       daily_agg = TRUE, fun = "mean")

  calculate_geos(from = cov, locs = or_pts, locs_id = LOCS_ID, radius = 0,
                  fun = "mean", geom = "sf")
}, auth_required = TRUE)

# ═══════════════════════════════════════════════════════════════════════════════
# 21. HUC watersheds — large download (~7GB); skip with documentation
# ═══════════════════════════════════════════════════════════════════════════════
cat("── HUC ──\n")
cat("  [SKIP] NHDPlusV21 geodatabase is ~7GB; skip in discovery run.\n")
cat("  Variables from calculate_huc: locs_id + watershed membership indicators\n\n")
results[["HUC"]] <- list(status = "skipped",
                          vars   = c("huc02_...", "huc04_...", "huc06_..."),
                          msg    = "Download skipped (~7GB)")

# ═══════════════════════════════════════════════════════════════════════════════
# 22. MERRA-2 — requires NASA EarthData credentials GES DISC does not accept
#
#     GES DISC (MERRA-2 host) uses ~/.netrc-based authentication:
#       machine urs.earthdata.nasa.gov login <user> password <pass>
#     amadeus::download_merra2() sends Authorization: Bearer <token>, which
#     GES DISC does not accept — nc4 data files return 401 even with a valid
#     token. This source is skipped in local discovery runs; it should
#     work on HPC where ~/.netrc is configured. (gROADS was previously also
#     skipped under this same assumption — see section 10 above; that
#     assumption didn't hold, since gROADS is SEDAC-hosted, not GES DISC.)
# ═══════════════════════════════════════════════════════════════════════════════
cat("── MERRA-2 ──\n")
cat("  [SKIP] GES DISC requires ~/.netrc auth; Bearer token not accepted for nc4 files.\n")
cat("  Variables from calculate_merra2: locs_id + time + <variable>_<radius>\n\n")
results[["MERRA-2"]] <- list(status = "skipped",
                              vars   = c("T2M_0", "..."),
                              msg    = "GES DISC requires ~/.netrc auth (Bearer token rejected)")

# ═══════════════════════════════════════════════════════════════════════════════
# 23. CropScape — USDA Cropland Data Layer; skipped, too large (~10.4GB/year)
#     A single national year (zip + full-res tif + overview file) tested at
#     10.4GB — larger than any other source in this script, including GMTED
#     (7.4GB). Not included in local discovery runs.
# ═══════════════════════════════════════════════════════════════════════════════
cat("── CropScape ──\n")
cat("  [SKIP] National CDL raster is ~10.4GB/year (zip + tif + overview); too large.\n\n")
results[["CropScape"]] <- list(status = "skipped",
                                vars   = character(0),
                                msg    = "~10.4GB/year — too large for local discovery")

# ═══════════════════════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n══════════════════════════════════════════════════\n")
cat("Summary\n")
cat("══════════════════════════════════════════════════\n\n")

for (nm in names(results)) {
  r <- results[[nm]]
  if (r$status == "ok") {
    cat(sprintf("[OK]    %-18s  %d vars: %s\n", nm, length(r$vars),
                paste(r$vars, collapse = ", ")))
  } else if (r$status == "skipped") {
    cat(sprintf("[SKIP]  %-18s  %s\n", nm,
                if (!is.null(r$msg)) r$msg else "auth not set"))
  } else {
    cat(sprintf("[ERROR] %-18s  %s\n", nm, r$msg))
  }
}
