# amadeus v2 Variable Discovery


amadeus: 2.0.1 | test region: Oregon ZCTAs (n=419)


## HMS

Status: OK | 19274 row(s) | 3 variable(s)

Variables (smoke intensity category, 1 row per ZCTA × date):

```
light_00000
medium_00000
heavy_00000
```

Example data (2021-08-17, one of Oregon's heavy wildfire smoke days):

```
 ZCTA5CE10       time  light_00000  medium_00000  heavy_00000
     97004 2021-08-17            1             0            0
     97023 2021-08-17            1             0            0
     97330 2021-08-17            1             0            0
     97833 2021-08-17            0             1            0
     97840 2021-08-17            0             0            1
```


## gridMET

Status: OK | 2933 row(s) | 1 variable(s)

Variables (daily precipitation, 1 row per ZCTA × date):

```
pr_0
```

Example data (2023-06-05, 5 Oregon ZCTAs):

```
 ZCTA5CE10       time  pr_0
     97004 2023-06-05     0
     97023 2023-06-05     0
     97330 2023-06-05     0
     97833 2023-06-05     1
     97840 2023-06-05     0
```


## TerraClimate

Status: OK | 2514 row(s) | 1 variable(s)

Variables (monthly precipitation mm, 1 row per ZCTA × month):

```
ppt_0
```

Example data (June 2023, 5 Oregon ZCTAs):

```
 ZCTA5CE10   time  ppt_0
     97833 202306   32.4
     97840 202306   39.0
     97330 202306   10.6
     97004 202306   28.5
     97023 202306   38.9
```


## PRISM

Status: OK | 419 row(s) | 3 variable(s)

Variables (daily mean temperature °C, one column per date):

```
tmean_20210601_0
tmean_20210602_0
tmean_20210603_0
```

Example data (5 Oregon ZCTAs):

```
 ZCTA5CE10  tmean_20210601_0  tmean_20210602_0  tmean_20210603_0
     97833            16.473            18.590            21.049
     97840            20.357            22.224            25.647
     97330            20.157            23.431            20.278
     97004            19.702            22.206            21.316
     97023            18.849            21.963            20.612
```


## GMTED

Status: OK | 419 row(s) | 1 variable(s)

Variables (elevation in meters, static):

```
gmted_0
```

Example data (5 Oregon ZCTAs):

```
 ZCTA5CE10  gmted_0
     97833     1078
     97840      775
     97330      360
     97004      347
     97023      417
```


## NLCD

Status: OK | 419 row(s) | 1 variable(s)

Variables (land cover class at centroid, static):

```
NLCD.Land.Cover.Class_0
```

Example data (5 Oregon ZCTAs):

```
 ZCTA5CE10  NLCD.Land.Cover.Class_0
     97833         Cultivated Crops
     97840              Shrub/Scrub
     97330             Mixed Forest
     97004         Evergreen Forest
     97023              Shrub/Scrub
```


## Koppen-Geiger

Status: OK | 419 row(s) | 6 variable(s)

Variables (main climate group dummies A–E, static):

```
description
DUM_CLRGA_00000
DUM_CLRGB_00000
DUM_CLRGC_00000
DUM_CLRGD_00000
DUM_CLRGE_00000
```

Example data (5 Oregon ZCTAs; A=tropical, B=dry, C=temperate, D=continental, E=polar):

```
 ZCTA5CE10  DUM_CLRGA_00000  DUM_CLRGB_00000  DUM_CLRGC_00000  DUM_CLRGD_00000  DUM_CLRGE_00000
     97833                0                1                0                0                0
     97840                0                0                0                1                0
     97330                0                0                1                0                0
     97004                0                0                1                0                0
     97023                0                0                1                0                0
```


## TRI

Status: OK | 5 row(s) | 1632 variable(s)

Variable pattern: `STACK_AIR_<CAS>_<radius>` where CAS is the EPA chemical identifier
(numeric CAS number or alphanumeric code) and radius is the buffer in meters
(01000 = 1 km, 10000 = 10 km, 50000 = 50 km). One column per chemical × radius combination
across 222 Oregon TRI facilities (2023).

```
# 1 km radius examples:
STACK_AIR_0000064186_01000   # Formic acid (CAS 64-18-6)
STACK_AIR_0007697372_01000   # Ethylene glycol (CAS 107-21-1)
STACK_AIR_N590_01000         # Glycol ethers (TRI alphanumeric category)
STACK_AIR_MIXTURE_01000      # Chemical mixture (non-specific)
STACK_AIR_TRD_SECRT_01000    # Trade secret chemical

# Same chemicals repeated at 10 km and 50 km radii:
STACK_AIR_0000064186_10000
STACK_AIR_0000064186_50000
# ... 1,632 total (544 unique chemicals × 3 radii)
```

Example data (5 rural Oregon ZCTAs; zeros expected — industrial facilities are sparse):

```
 ZCTA5CE10  time  STACK_AIR_0000064186_01000  STACK_AIR_0007697372_01000  STACK_AIR_N590_01000
     97833  2023                           0                           0                     0
     97840  2023                           0                           0                     0
     97330  2023                           0                           0                     0
     97004  2023                           0                           0                     0
     97023  2023                           0                           0                     0
```


## Population

Status: OK | 419 row(s) | 1 variable(s)

Variables (SEDAC GPWv4 population density, 2.5 arc-min resolution, static):

```
population_0
```

Example data (5 Oregon ZCTAs):

```
 ZCTA5CE10  time  population_0
     97833  2020    3.85046959
     97840  2020    0.07690281
     97330  2020   92.51130676
     97004  2020   36.79584503
     97023  2020    5.60742331
```


## gROADS

Status: OK | 419 row(s) | 3 variable(s)

Variables (road length/density within 1km buffer, static):

```
description
GRD_TOTAL_01000
GRD_DENKM_01000
```

Example data (5 Oregon ZCTAs):

```
 ZCTA5CE10  description  GRD_TOTAL_01000  GRD_DENKM_01000
     97062  1980 - 2010        2.6311236        0.8375233
     97499  1980 - 2010        1.6641541        0.5297234
     97524  1980 - 2010        2.0027716        0.6375101
     97497  1980 - 2010        0.4012242        0.1277153
     97477  1980 - 2010        1.9017147        0.6053423
```


## GOES

Status: OK | 419 row(s) | 1 variable(s)

Variables (GOES-16 ADP smoke detection fraction, 1 row per ZCTA × date):

```
Smoke_0
```

Example data (2021-08-17, same wildfire smoke day as HMS above):

```
 ZCTA5CE10       time    Smoke_0
     97833 2021-08-17 0.08704857
     97840 2021-08-17 0.14924717
     97330 2021-08-17 0.03857605
     97004 2021-08-17 0.35987906
     97023 2021-08-17 0.31265169
```


## NEI

Status: OK | 419 row(s) | 2 variable(s)

Variables (onroad emissions, county-level join, static):

```
geoid
TRF_NEINP_0_00000
```

Example data (5 Oregon ZCTAs):

```
 ZCTA5CE10  geoid  time  TRF_NEINP_0_00000
     97833  41001  2020             285952
     97840  41001  2020             285952
     97330  41003  2020             256892
     97004  41005  2020            1619855
     97023  41005  2020            1619855
```


## Drought (SPEI)

Status: OK | 419 row(s) | 1 variable(s)

Variables (monthly SPEI, timescale=1, 1 row per ZCTA):

```
spei_01_0
```

Example data (mid-June 2020, 5 Oregon ZCTAs):

```
 ZCTA5CE10       time  spei_01_0
     97833 2020-06-16  1.5054700
     97840 2020-06-16  1.6277983
     97330 2020-06-16  1.1022207
     97004 2020-06-16  0.8467892
     97023 2020-06-16  0.8467892
```


## Drought (EDDI)

Status: OK | 2095 row(s) | 1 variable(s)

Variables (weekly EDDI, timescale=1, 1 row per ZCTA × week):

```
eddi_01_0
```

Example data (2020-06-02, 5 Oregon ZCTAs):

```
 ZCTA5CE10       time   eddi_01_0
     97833 2020-06-02  0.06736231
     97840 2020-06-02 -0.13406956
     97330 2020-06-02  0.41437924
     97004 2020-06-02  0.73206991
     97023 2020-06-02  0.64681131
```


## Drought (USDM)

Status: OK | 2095 row(s) | 1 variable(s)

Variables (weekly U.S. Drought Monitor class, 0=abnormally dry–4=exceptional):

```
usdm_dm_0
```

Example data (2020-06-02, 5 Oregon ZCTAs):

```
 ZCTA5CE10       time  usdm_dm_0
     97833 2020-06-02          1
     97840 2020-06-02          1
     97330 2020-06-02          2
     97004 2020-06-02          2
     97023 2020-06-02          1
```


## Ecoregion

Status: OK | 419 row(s) | 13 variable(s)

Variables (EPA Level II/III ecoregion dummy indicators, static):

```
description
DUM_E2101_00000
DUM_E2062_00000
DUM_E2071_00000
DUM_E3001_00000
DUM_E3010_00000
DUM_E3011_00000
DUM_E3012_00000
DUM_E3003_00000
DUM_E3004_00000
DUM_E3078_00000
DUM_E3080_00000
DUM_E3009_00000
```

Example data (5 Oregon ZCTAs, first few dummy columns):

```
 ZCTA5CE10  description  DUM_E2101_00000  DUM_E2062_00000  DUM_E2071_00000
     89421  1997 - 2026                1                0                0
     97001  1997 - 2026                0                1                0
     97002  1997 - 2026                0                0                1
     97004  1997 - 2026                0                0                1
     97005  1997 - 2026                0                0                1
```


## NARR

Status: OK | 2095 row(s) | 1 variable(s)

Variables (daily water-equivalent snow depth, weasd, 1 row per ZCTA × date):

```
weasd_0
```

Example data (January 2022, 5 Oregon ZCTAs):

```
 ZCTA5CE10       time    weasd_0
     97833 2022-01-01 19.2558594
     97840 2022-01-01 37.9658203
     97330 2022-01-01  0.9599609
     97004 2022-01-01  3.8925781
     97023 2022-01-01 34.8056641
```


## EDGAR

Status: OK | 419 row(s) | 1 variable(s)

Variables (global PM2.5 emissions, yearly totals, tonnes, static):

```
edgar_v8_1_ft2022_ap_pm2_5_2020_totals_emi_0
```

Example data (5 Oregon ZCTAs):

```
 ZCTA5CE10  edgar_v8_1_ft2022_ap_pm2_5_2020_totals_emi_0
     97833                                        1.05774
     97840                                        1.02880
     97330                                       19.04530
     97004                                        6.90567
     97023                                        5.34748
```


## AQS

Status: OK (no calculate_\* — dependent-variable data) | 27 row(s) | 5 variable(s)

No `calculate_aqs()` exists in amadeus; AQS monitoring-station data is intended as a
dependent variable, not a spatial-join covariate. Columns below are `process_aqs()`
output directly (one row per site-day):

```
site_id
lon
lat
Event.Type
Arithmetic.Mean
```

Example data (2023-08-15, PM2.5 daily monitors within the Oregon bbox):

```
        site_id        lon      lat  Event.Type       time  Arithmetic.Mean
 16027001088101  -116.5292 43.59946        None 2023-08-15         7.400000
 41013010088101  -120.8448 44.29979        None 2023-08-15        63.400000
 41025000388101  -119.0487 43.58925        None 2023-08-15         6.758333
 41025000388101  -119.0487 43.58925        None 2023-08-15         6.700000
 41029002988101  -122.8891 42.33240        None 2023-08-15        15.000000
```


## IMPROVE

Status: OK (no calculate_\* — dependent-variable data) | 7900 row(s) | 30 variable(s)

No `calculate_improve()` exists in amadeus (same rationale as AQS). IMPROVE samples on
a ~1-in-3-day cycle, so a full month window was used instead of a single date. Columns
below are a subset of `process_improve()` output (one row per site × date × chemical
species):

```
SiteCode
FactDate
ParamCode
FactValue
Units
State
County
# ... 23 more site-metadata / QA columns
```

Example data (June 2020, nearest sites to the Oregon bbox — falls just across the WA border):

```
 SiteCode    FactDate  ParamCode  FactValue   Units  State  County
    CORI1  2020-06-02        ALf    0.22159  ug/m^3     WA   53039
    CORI1  2020-06-02    ammNO3f    0.33946  ug/m^3     WA   53039
    CORI1  2020-06-02    ammSO4f    0.57533  ug/m^3     WA   53039
    CORI1  2020-06-02        ASf    0.00000  ug/m^3     WA   53039
    CORI1  2020-06-02        BRf    0.00138  ug/m^3     WA   53039
```


## MODIS

Status: OK | 419 row(s) | 1 variable(s)

Variables (MOD11A1 daytime land surface temperature, Kelvin, scaled):

```
MOD_LSTDY_00000
```

Example data (2023-08-15, 5 Oregon ZCTAs):

```
 ZCTA5CE10  MOD_LSTDY_00000       time
     89421           309.92 2023-08-15
     97001           320.96 2023-08-15
     97002           313.10 2023-08-15
     97004           310.60 2023-08-15
     97005           316.98 2023-08-15
```


## GEOS-CF

Status: OK | 419 row(s) | 2 variable(s)

Variables (surface ozone, level=72 = lowest model layer, 1 row per ZCTA × date):

```
level
o3_0
```

Example data (2023-08-15, 5 Oregon ZCTAs; o3_0 units are mol/mol):

```
 ZCTA5CE10       time  level         o3_0
     97833 2023-08-15     72 4.093212e-08
     97840 2023-08-15     72 4.287723e-08
     97330 2023-08-15     72 4.915153e-08
     97004 2023-08-15     72 4.438820e-08
     97023 2023-08-15     72 4.824446e-08
```


## HUC

Status: SKIPPED — Download skipped (~7GB)


## MERRA-2

Status: SKIPPED — GES DISC requires ~/.netrc auth (Bearer token rejected)


## CropScape

Status: SKIPPED — ~10.4GB/year, too large for local discovery


