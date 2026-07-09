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
  if (!requireNamespace("here",   quietly = TRUE)) install.packages("here")
  if (!requireNamespace("fs",     quietly = TRUE)) install.packages("fs")
  if (!requireNamespace("dotenv", quietly = TRUE)) install.packages("dotenv")
  library(here)
  library(fs)
})

# Load .env for NASA_EARTHDATA_TOKEN etc.
if (file.exists(here(".env"))) dotenv::load_dot_env(here(".env"))

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
# 9. HUC watersheds — large download (~7GB); skip with documentation
# ═══════════════════════════════════════════════════════════════════════════════
cat("── HUC ──\n")
cat("  [SKIP] NHDPlusV21 geodatabase is ~7GB; skip in discovery run.\n")
cat("  Variables from calculate_huc: locs_id + watershed membership indicators\n\n")
results[["HUC"]] <- list(status = "skipped",
                          vars   = c("huc02_...", "huc04_...", "huc06_..."),
                          msg    = "Download skipped (~7GB)")

# ═══════════════════════════════════════════════════════════════════════════════
# 10. MERRA-2 / gROADS — require NASA EarthData credentials
#
#     GES DISC (MERRA-2 host) uses ~/.netrc-based authentication:
#       machine urs.earthdata.nasa.gov login <user> password <pass>
#     amadeus::download_merra2() sends Authorization: Bearer <token>, which
#     GES DISC does not accept — nc4 data files return 401 even with a valid
#     token. These sources are skipped in local discovery runs; they should
#     work on HPC where ~/.netrc is configured.
# ═══════════════════════════════════════════════════════════════════════════════
cat("── MERRA-2 ──\n")
cat("  [SKIP] GES DISC requires ~/.netrc auth; Bearer token not accepted for nc4 files.\n")
cat("  Variables from calculate_merra2: locs_id + time + <variable>_<radius>\n\n")
results[["MERRA-2"]] <- list(status = "skipped",
                              vars   = c("T2M_0", "..."),
                              msg    = "GES DISC requires ~/.netrc auth (Bearer token rejected)")

cat("── gROADS ──\n")
cat("  [SKIP] Same GES DISC auth issue as MERRA-2.\n\n")
results[["gROADS"]] <- list(status = "skipped",
                             vars   = character(0),
                             msg    = "GES DISC requires ~/.netrc auth")

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
