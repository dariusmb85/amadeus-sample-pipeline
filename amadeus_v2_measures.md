# Amadeus v2.0.1 — Complete Measure Reference

All measures available via `download_*` / `process_*` / `calculate_*` functions in the `amadeus` R package.
Variable names match those produced in the `zip_monthly_long` dataverse dataset (2010–2024, monthly, zip code).

---

## gridMET — Climatology Lab Daily Gridded Meteorology

**Download:** `download_gridmet()` | **Process:** `process_gridmet()` | **Calculate:** `calculate_gridmet()`  
**Temporal resolution:** Daily → aggregated monthly  
**Spatial resolution:** ~4 km  
**Coverage:** Contiguous US, 1979–present

| Variable | Description | Units |
|----------|-------------|-------|
| `etr` | Reference alfalfa evapotranspiration | mm/day |
| `pr` | Precipitation | mm/day |
| `rmax` | Daily maximum near-surface relative humidity | % |
| `rmin` | Daily minimum near-surface relative humidity | % |
| `sph` | Near-surface specific humidity | kg/kg |
| `srad` | Surface downwelling solar radiation | W/m² |
| `th` | Wind direction at 10 m | degrees |
| `tmmn` | Daily minimum near-surface air temperature | K |
| `tmmx` | Daily maximum near-surface air temperature | K |
| `vs` | Wind speed at 10 m | m/s |

---

## HMS — NOAA Hazard Mapping System Fire and Smoke Product

**Download:** `download_hms()` | **Process:** `process_hms()` | **Calculate:** `calculate_hms()`  
**Temporal resolution:** Daily shapefiles  
**Spatial resolution:** Polygon plumes  
**Coverage:** North America, 2005–present

| Variable | Description | Units |
|----------|-------------|-------|
| `prop_light_coverage` | Proportion of light wildfire smoke cover | proportion |
| `prop_med_coverage` | Proportion of medium wildfire smoke cover | proportion |
| `prop_heavy_coverage` | Proportion of heavy wildfire smoke cover | proportion |

> **Smoke PM₂.₅ proxy** (derived): `light × 5 + medium × 16 + heavy × 27` μg/m³ intensity-weighted composite.

---

## MERRA-2 — NASA Modern-Era Retrospective Analysis for Research and Applications, Version 2

**Download:** `download_merra2()` | **Process:** `process_merra2()` | **Calculate:** `calculate_merra2()`  
**Temporal resolution:** Hourly → aggregated monthly  
**Spatial resolution:** 0.5° × 0.625°  
**Coverage:** Global, 1980–present  
**Authentication:** NASA EarthData token required

| Variable | Description | Units |
|----------|-------------|-------|
| `albedo` | Surface albedo (shortwave reflectance) | unitless |
| `bcsmass` | Black carbon surface mass concentration | kg m⁻³ |
| `cldtot` | Total cloud fraction | proportion |
| `dusmass25` | Dust surface mass concentration, particles <2.5 μm | kg m⁻³ |
| `evap` | Evaporation from turbulence | kg m⁻² s⁻¹ |
| `grn` | Greenness index (fraction of green vegetation) | proportion |
| `gwetroot` | Root zone soil wetness | proportion |
| `lai` | Leaf area index | dimensionless |
| `lwgab` | Surface absorbed longwave radiation | W m⁻² |
| `pblh` | Planetary boundary layer height | m |
| `precsno` | Snowfall precipitation | kg m⁻² s⁻¹ |
| `prectotcorr` | Bias-corrected total precipitation | kg m⁻² s⁻¹ |
| `ps` | Surface pressure | Pa |
| `qv2m` | Specific humidity at 2 m | kg/kg |
| `slp` | Sea level pressure | Pa |
| `t2mdew` | Dew point temperature at 2 m | K |
| `totexttau` | Total aerosol optical thickness | unitless |
| `ts` | Surface skin temperature | K |
| `u10m` | Zonal wind speed at 10 m (east–west) | m/s |
| `z0m` | Surface roughness length | m |

**Collections used for download:**
- `tavg1_2d_aer_Nx` — aerosol diagnostics (BC, dust, AOD)
- `tavg1_2d_slv_Nx` — surface meteorology (T2M, winds, humidity)
- `tavg1_2d_lnd_Nx` — land surface (soil, LAI, greenness)
- `tavg1_2d_rad_Nx` — radiation (albedo, LW/SW)

---

## TerraClimate — Climatology Lab Monthly Climate

**Download:** `download_terraclimate()` | **Process:** `process_terraclimate()` | **Calculate:** `calculate_terraclimate()`  
**Temporal resolution:** Monthly  
**Spatial resolution:** ~4 km  
**Coverage:** Global, 1958–present

| Variable | Description | Units |
|----------|-------------|-------|
| `aet` | Actual evapotranspiration | mm/month |
| `def` | Climatic water deficit | mm/month |
| `pdsi` | Palmer drought severity index | index |
| `pet` | Monthly potential evapotranspiration | mm/month |
| `ppt` | Precipitation | mm/month |
| `soil` | Soil moisture | mm/month |
| `swe` | Snow water equivalent | mm/month |
| `tmax` | Maximum temperature | °C |
| `tmin` | Minimum temperature | °C |
| `vap` | Vapor pressure | kPa |
| `vpd` | Vapor pressure deficit | kPa |
| `ws` | Wind speed | m/s |

---

## PRISM — Parameter Elevation Regressions on Independent Slopes Model

**Download:** `download_prism()` | **Process:** `process_prism()` | **Calculate:** `calculate_prism()`  
**Temporal resolution:** Daily (recent) + 1991–2020 climate normals (static)  
**Spatial resolution:** ~4 km  
**Coverage:** Contiguous US

| Variable | Description | Units |
|----------|-------------|-------|
| `solclear` | Solar radiation under clear sky (normal) | MJ/m²/day |
| `solslope` | Solar shortwave radiation, sloped surface (normal) | MJ/m²/day |
| `soltotal` | Solar shortwave radiation, horizontal surface (normal) | MJ/m²/day |
| `soltrans` | Atmospheric transmittance (normal) | proportion |
| `tdmean` | Mean daily dew point temperature (normal) | °C |
| `tmax_norm` | Maximum daily temperature (normal) | °C |
| `tmean` | Mean temperature (normal) | °C |
| `tmin_norm` | Minimum daily temperature (normal) | °C |
| `vpdmax` | Daily maximum vapor pressure deficit (normal) | hPa |
| `vpdmin` | Daily minimum vapor pressure deficit (normal) | hPa |

---

## TRI — US EPA Toxic Release Inventory

**Download:** `download_tri()` | **Process:** `process_tri()` | **Calculate:** `calculate_tri()`  
**Temporal resolution:** Annual  
**Spatial resolution:** Point sources → zip aggregated  
**Coverage:** US, 1987–present

| Variable | Description | Units |
|----------|-------------|-------|
| `annual_total_air_lb` | Total air emissions (fugitive + stack) | lb |
| `annual_total_air_lb_per_km2` | Total air emissions per area | lb/km² |
| `annual_total_air_lb_plusbuffer` | Total air emissions with 4 km zip buffer | lb |
| `annual_total_fugitive_air_lb` | Fugitive air emissions | lb |
| `annual_total_fugitive_air_lb_per_km2` | Fugitive air emissions per area | lb/km² |
| `annual_total_fugitive_air_lb_plusbuffer` | Fugitive air emissions with 4 km zip buffer | lb |
| `annual_total_stack_air_lb` | Stack (point-source) air emissions | lb |
| `annual_total_stack_air_lb_per_km2` | Stack emissions per area | lb/km² |
| `annual_total_stack_air_lb_plusbuffer` | Stack emissions with 4 km zip buffer | lb |

---

## GMTED2010 — USGS Global Multi-Resolution Terrain Elevation Data

**Download:** `download_gmted()` | **Process:** `process_gmted()` | **Calculate:** `calculate_gmted()`  
**Temporal resolution:** Static  
**Spatial resolution:** 7.5 / 15 / 30 arc-seconds  
**Coverage:** Global

| Variable | Description | Units |
|----------|-------------|-------|
| `be30_grd` | Breakline emphasis (30-arc seconds) | m |
| `ds30_grd` | Systematic subsample (30-arc seconds) | m |
| `md30_grd` | Median statistic (30-arc seconds) | m |
| `mi30_grd` | Minimum statistic (30-arc seconds) | m |
| `mn30_grd` | Mean statistic (30-arc seconds) | m |
| `mx30_grd` | Maximum statistic (30-arc seconds) | m |
| `sd30_grd` | Standard deviation (30-arc seconds) | m |

---

## NLCD — MRLC National Land Cover Database

**Download:** `download_nlcd()` | **Process:** `process_nlcd()` | **Calculate:** `calculate_nlcd()`  
**Temporal resolution:** Every 2–3 years (2001, 2004, 2006, 2008, 2011, 2013, 2016, 2019, 2021)  
**Spatial resolution:** 30 m → zip aggregated  
**Coverage:** Contiguous US

| Variable | Description | Units |
|----------|-------------|-------|
| `fractional_impervious_surface` | Proportion covered by impervious surfaces | % |
| `land_cover_confidence` | Model certainty confidence score | % |
| `land_cover_11` | Open Water | proportion |
| `land_cover_12` | Perennial Ice/Snow | proportion |
| `land_cover_21` | Developed, Open Space | proportion |
| `land_cover_22` | Developed, Low Intensity | proportion |
| `land_cover_23` | Developed, Medium Intensity | proportion |
| `land_cover_24` | Developed, High Intensity | proportion |
| `land_cover_31` | Barren Land (Rock/Sand/Clay) | proportion |
| `land_cover_41` | Deciduous Forest | proportion |
| `land_cover_42` | Evergreen Forest | proportion |
| `land_cover_43` | Mixed Forest | proportion |
| `land_cover_52` | Shrub/Scrub | proportion |
| `land_cover_71` | Grasslands/Herbaceous | proportion |
| `land_cover_81` | Pasture/Hay | proportion |
| `land_cover_82` | Cultivated Crops | proportion |
| `land_cover_90` | Woody Wetlands | proportion |
| `land_cover_95` | Emergent Herbaceous Wetlands | proportion |

---

## MODIS — NASA Moderate Resolution Imaging Spectroradiometer

**Download:** `download_modis()` | **Process:** `process_modis()` | **Calculate:** `calculate_modis()`  
**Temporal resolution:** Daily / 8-day / 16-day composites → monthly  
**Spatial resolution:** 500 m – 1 km  
**Coverage:** Global  
**Authentication:** NASA EarthData token required

| Variable | Product | Description | Units |
|----------|---------|-------------|-------|
| `sur_refl_b01` | MOD09A1 | Surface reflectance, band 1 (×0.0001) | unitless |
| `sur_refl_b02` | MOD09A1 | Surface reflectance, band 2 (×0.0001) | unitless |
| `sur_refl_b03` | MOD09A1 | Surface reflectance, band 3 (×0.0001) | unitless |
| `sur_refl_b04` | MOD09A1 | Surface reflectance, band 4 (×0.0001) | unitless |
| `sur_refl_b05` | MOD09A1 | Surface reflectance, band 5 (×0.0001) | unitless |
| `sur_refl_b06` | MOD09A1 | Surface reflectance, band 6 (×0.0001) | unitless |
| `sur_refl_b07` | MOD09A1 | Surface reflectance, band 7 (×0.0001) | unitless |
| `lST_day_1km` | MOD11A1 | Daytime land surface temperature | K |
| `lST_night_1km` | MOD11A1 | Nighttime land surface temperature | K |
| `ndvi` | MOD13A2 | Normalized Difference Vegetation Index | index (−1 to 1) |
| `evi` | MOD13A2 | Enhanced Vegetation Index (×0.0001) | index (−1 to 1) |

---

## gROADS — NASA SEDAC Global Roads Open Access Data Set

**Download:** `download_groads()` | **Process:** `process_groads()` | **Calculate:** `calculate_groads()`  
**Temporal resolution:** Static (circa 2010)  
**Coverage:** Global  
**Authentication:** NASA EarthData token required

| Variable | Description | Units |
|----------|-------------|-------|
| `road_density_km_per_km2` | Road density | km/km² |
| `total_road_km` | Total length of roads | km |

---

## HUC — USGS National Hydrography Dataset Watershed Boundaries

**Download:** `download_huc()` | **Process:** `process_huc()` | **Calculate:** `calculate_huc()`  
**Temporal resolution:** Static  
**Coverage:** US

| Variable | Description | Units |
|----------|-------------|-------|
| `prop_cover_huc2_01` | HUC2 01 — New England | proportion |
| `prop_cover_huc2_02` | HUC2 02 — Mid Atlantic | proportion |
| `prop_cover_huc2_03` | HUC2 03 — South Atlantic-Gulf | proportion |
| `prop_cover_huc2_04` | HUC2 04 — Great Lakes | proportion |
| `prop_cover_huc2_05` | HUC2 05 — Ohio | proportion |
| `prop_cover_huc2_06` | HUC2 06 — Tennessee | proportion |
| `prop_cover_huc2_07` | HUC2 07 — Upper Mississippi | proportion |
| `prop_cover_huc2_08` | HUC2 08 — Lower Mississippi | proportion |
| `prop_cover_huc2_09` | HUC2 09 — Souris-Red-Rainy | proportion |
| `prop_cover_huc2_10` | HUC2 10 — Missouri | proportion |
| `prop_cover_huc2_11` | HUC2 11 — Arkansas-White-Red | proportion |
| `prop_cover_huc2_12` | HUC2 12 — Texas-Gulf | proportion |
| `prop_cover_huc2_13` | HUC2 13 — Rio Grande | proportion |
| `prop_cover_huc2_14` | HUC2 14 — Upper Colorado | proportion |
| `prop_cover_huc2_15` | HUC2 15 — Lower Colorado | proportion |
| `prop_cover_huc2_16` | HUC2 16 — Great Basin | proportion |
| `prop_cover_huc2_17` | HUC2 17 — Pacific Northwest | proportion |
| `prop_cover_huc2_18` | HUC2 18 — California | proportion |
| `prop_cover_huc2_19` | HUC2 19 — Alaska | proportion |
| `prop_cover_huc2_20` | HUC2 20 — Hawaii | proportion |
| `prop_cover_huc2_21` | HUC2 21 — Caribbean | proportion |
| `prop_cover_huc2_22` | HUC2 22 — Pacific Islands | proportion |

---

## Koppen-Geiger — Climate Classification

**Download:** `download_koppen_geiger()` | **Process:** `process_koppen_geiger()` | **Calculate:** `calculate_koppen_geiger()`  
**Temporal resolution:** Static (present-day classification)  
**Spatial resolution:** 0.0083° (~1 km)  
**Coverage:** Global

| Variable | Description | Units |
|----------|-------------|-------|
| `koppen_confidence` | Confidence metric for zone coverage | % |
| `koppen_1` | Af — Tropical, rainforest | proportion |
| `koppen_2` | Am — Tropical, monsoon | proportion |
| `koppen_3` | Aw — Tropical, savannah | proportion |
| `koppen_4` | BWh — Arid, desert, hot | proportion |
| `koppen_5` | BWk — Arid, desert, cold | proportion |
| `koppen_6` | BSh — Arid, steppe, hot | proportion |
| `koppen_7` | BSk — Arid, steppe, cold | proportion |
| `koppen_8` | Csa — Temperate, dry summer, hot summer | proportion |
| `koppen_9` | Csb — Temperate, dry summer, warm summer | proportion |
| `koppen_10` | Csc — Temperate, dry summer, cold summer | proportion |
| `koppen_11` | Cwa — Temperate, dry winter, hot summer | proportion |
| `koppen_12` | Cwb — Temperate, dry winter, warm summer | proportion |
| `koppen_13` | Cwc — Temperate, dry winter, cold summer | proportion |
| `koppen_14` | Cfa — Temperate, no dry season, hot summer | proportion |
| `koppen_15` | Cfb — Temperate, no dry season, warm summer | proportion |
| `koppen_16` | Cfc — Temperate, no dry season, cold summer | proportion |
| `koppen_17` | Dsa — Cold, dry summer, hot summer | proportion |
| `koppen_18` | Dsb — Cold, dry summer, warm summer | proportion |
| `koppen_19` | Dsc — Cold, dry summer, cold summer | proportion |
| `koppen_20` | Dsd — Cold, dry summer, very cold winter | proportion |
| `koppen_21` | Dwa — Cold, dry winter, hot summer | proportion |
| `koppen_22` | Dwb — Cold, dry winter, warm summer | proportion |
| `koppen_23` | Dwc — Cold, dry winter, cold summer | proportion |
| `koppen_24` | Dwd — Cold, dry winter, very cold winter | proportion |
| `koppen_25` | Dfa — Cold, no dry season, hot summer | proportion |
| `koppen_26` | Dfb — Cold, no dry season, warm summer | proportion |
| `koppen_27` | Dfc — Cold, no dry season, cold summer | proportion |
| `koppen_28` | Dfd — Cold, no dry season, very cold winter | proportion |
| `koppen_29` | ET — Polar, tundra | proportion |
| `koppen_30` | EF — Polar, frost | proportion |

---

## Zip Code Boundaries

**Download:** `download_zcta()` (Census TIGER/Line ZCTA5 shapefiles)  
**Temporal resolution:** Static (2020 vintage)  
**Coverage:** US (ZCTAs — sparse in unpopulated areas)

| Variable | Description | Units |
|----------|-------------|-------|
| `area_km2` | Area of zip code tabulation area | km² |

---

## Sources Requiring Authentication

| Source | Token Type | Where to Register |
|--------|-----------|-------------------|
| MERRA-2 | NASA EarthData | urs.earthdata.nasa.gov |
| MODIS | NASA EarthData | urs.earthdata.nasa.gov |
| gROADS | NASA EarthData | urs.earthdata.nasa.gov |
| GEOS-CF | NASA EarthData | urs.earthdata.nasa.gov |
| GOES | NASA EarthData | urs.earthdata.nasa.gov |
| Population (SEDAC) | NASA EarthData | urs.earthdata.nasa.gov |

Set token in R: `Sys.setenv(NASA_EARTHDATA_TOKEN = "your_token")`  
Or add to `~/.Renviron`: `NASA_EARTHDATA_TOKEN=your_token`

---

## Summary Count

| Source | # Variables | Type |
|--------|------------|------|
| gridMET | 10 | Dynamic (daily) |
| HMS | 3 | Dynamic (daily) |
| MERRA-2 | 20 | Dynamic (hourly) |
| TerraClimate | 12 | Dynamic (monthly) |
| PRISM | 10 | Static normals |
| TRI | 9 | Dynamic (annual) |
| GMTED | 7 | Static |
| NLCD | 18 | Dynamic (biennial) |
| MODIS | 11 | Dynamic (daily/8-day) |
| gROADS | 2 | Static |
| HUC | 22 | Static |
| Koppen-Geiger | 31 | Static |
| Boundaries | 1 | Static |
| **Total** | **156** | |
