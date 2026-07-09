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


## HUC

Status: SKIPPED — Download skipped (~7GB)


## MERRA-2

Status: SKIPPED — NASA auth not set


## gROADS

Status: SKIPPED — NASA auth not set


