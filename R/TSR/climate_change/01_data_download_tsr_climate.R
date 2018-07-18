# Copyright 2018 Province of British Columbia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

#=================================
#  Script Name: 01_download_data_tsr_climate.R
#  Script Version: 1.0
#  Script Purpose: Download data for timber supply area scale climate summaries.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 16 July 2018
#  R Version: 3.4.3
#  R Package Versions: 
#  Data: 
#=================================

#=================================
# data directory and packages
#=================================
setwd ('C:\\Work\\tsr_climate\\data\\') # where you are puttign the data
require (downloader)
require (RPostgreSQL)
require (sf)
require (raster)
require (rpostgis)

#########################
# MANUAL DATA DOWNLOADS #
#########################
# BEC zone climate projections; 2020s, 2050s and 2080s; downloaded 7 July 2018
# <http://www.climatewna.com/ClimateBC_Map.aspx>
# At top of map 'Òverlays' select from 'Climate Maps': 'BEC zone - currently mapped', 
# 'BEC zone - climate_2020s',  'BEC zone - climate_2050s', and 'BEC zone - climate_2080s'.
# Click 'Download Overlay raster files" after each selection
# C:\Work\tsr_climate\data\bec\
unzip ("bec\\BEC_zone.zip",  # unzip the files
       exdir = "C:\\Work\\tsr_climate\\data\\bec")
file.remove ("bec\\BEC_zone.zip")

unzip ("bec\\BEC_zone_2020s.zip", 
       exdir = "C:\\Work\\tsr_climate\\data\\bec")
file.remove ("bec\\BEC_zone_2020s.zip")

unzip ("bec\\BEC_zone_2050s.zip", 
       exdir = "C:\\Work\\tsr_climate\\data\\bec")
file.remove ("bec\\BEC_zone_2050s.zip")

unzip ("bec\\BEC_zone_2080s.zip", 
       exdir = "C:\\Work\\tsr_climate\\data\\bec")
file.remove ("bec\\BEC_zone_2080s.zip")

# TSA and TFL Boundary data
# Needs to copied from BCGW
# WHSE_ADMIN_BOUNDARIES.FADM_TSA
# created a dissolved version in ArcGIS

###################################
# Data downloadable from websites #
###################################
# current, past and future climate measure projections; downloaded 16 July 2018
# Reference: <http://climatebcdata.climatewna.com/#3._reference> # Wang, T., Hamann, A., Spittlehouse, D.L., Murdock, T., 2012. ClimateWNA - High-Resolution Spatial Climate Data for Western North America. Journal of Applied Meteorology and Climatology, 51: 16-29.

# Current Data
download ("http://climatebcdata.climatewna.com/download/Normal_1981_2010MSY/Normal_1981_2010_annual.zip", 
          dest = "climate\\annual\\1981_2010\\Normal_1981_2010_seasonal.zip", 
          mode = "wb")
unzip ("climate\\annual\\1981_2010\\Normal_1981_2010_seasonal.zip", 
       exdir = "C:\\Work\\tsr_climate\\data\\climate\\annual\\1981_2010")
file.remove ("climate\\annual\\1981_2010\\Normal_1981_2010_seasonal.zip")

# Only downloaded RCP45 model (see https://en.wikipedia.org/wiki/Representative_Concentration_Pathways)
# used RCP 45 as 'moderate' scenario for climate change
# CanESM2 model
download ("http://climatebcdata.climatewna.com/download/CanESM2_RCP45_2025MSY/CanESM2_RCP45_2025_annual.zip", 
          dest = "climate\\annual\\2011_2040\\RCP45\\CanESM2\\CanESM2_RCP45_2025_annual.zip", 
          mode = "wb")
unzip ("climate\\annual\\2011_2040\\RCP45\\CanESM2\\CanESM2_RCP45_2025_annual.zip", 
       exdir = "climate\\annual\\2011_2040\\RCP45\\CanESM2")
file.remove ("climate\\annual\\2011_2040\\RCP45\\CanESM2\\CanESM2_RCP45_2025_annual.zip")

download ("http://climatebcdata.climatewna.com/download/CanESM2_RCP45_2055MSY/CanESM2_RCP45_2055_annual.zip", 
          dest = "climate\\annual\\2041_2070\\RCP45\\CanESM2\\CanESM2_RCP45_2055_annual.zip", 
          mode = "wb")
unzip ("climate\\annual\\2041_2070\\RCP45\\CanESM2\\CanESM2_RCP45_2055_annual.zip", 
       exdir = "climate\\annual\\2041_2070\\RCP45\\CanESM2")
file.remove ("climate\\annual\\2041_2070\\RCP45\\CanESM2\\CanESM2_RCP45_2055_annual.zip")

download ("http://climatebcdata.climatewna.com/download/CanESM2_RCP45_2085MSY/CanESM2_RCP45_2085_annual.zip", 
          dest = "climate\\annual\\2071_2100\\RCP45\\CanESM2\\CanESM2_RCP45_2085_annual.zip", 
          mode = "wb")
unzip ("climate\\annual\\2071_2100\\RCP45\\CanESM2\\CanESM2_RCP45_2085_annual.zip", 
       exdir = "climate\\annual\\2071_2100\\RCP45\\CanESM2")
file.remove ("climate\\annual\\2071_2100\\RCP45\\CanESM2\\CanESM2_RCP45_2055_annual.zip")

# CCSM4 model
download ("http://climatebcdata.climatewna.com/download/CCSM4_RCP45_2025MSY/CCSM4_RCP45_2025_annual.zip", 
          dest = "climate\\annual\\2011_2040\\RCP45\\CCSM4\\CCSM4_RCP45_2025_annual.zip", 
          mode = "wb")
unzip ("climate\\annual\\2011_2040\\RCP45\\CCSM4\\CCSM4_RCP45_2025_annual.zip", 
       exdir = "climate\\annual\\2011_2040\\RCP45\\CCSM4")
file.remove ("climate\\annual\\2011_2040\\RCP45\\CCSM4\\CCSM4_RCP45_2025_annual.zip")

download ("http://climatebcdata.climatewna.com/download/CCSM4_RCP45_2055MSY/CCSM4_RCP45_2055_annual.zip", 
          dest = "climate\\annual\\2041_2070\\RCP45\\CCSM4\\CCSM4_RCP45_2055_annual.zip", 
          mode = "wb")
unzip ("climate\\annual\\2041_2070\\RCP45\\CCSM4\\CCSM4_RCP45_2055_annual.zip", 
       exdir = "climate\\annual\\2041_2070\\RCP45\\CCSM4")
file.remove ("climate\\annual\\2041_2070\\RCP45\\CCSM4\\CCSM4_RCP45_2055_annual.zip")

download ("http://climatebcdata.climatewna.com/download/CCSM4_RCP45_2085MSY/CCSM4_RCP45_2085_annual.zip", 
          dest = "climate\\annual\\2071_2100\\RCP45\\CCSM4\\CCSM4_RCP45_2085_annual.zip", 
          mode = "wb")
unzip ("climate\\annual\\2071_2100\\RCP45\\CCSM4\\CCSM4_RCP45_2085_annual.zip", 
       exdir = "climate\\annual\\2071_2100\\RCP45\\CCSM4")
file.remove ("climate\\annual\\2071_2100\\RCP45\\CCSM4\\CCSM4_RCP45_2085_annual.zip")

# HadGEM2-ES model
download ("http://climatebcdata.climatewna.com/download/HadGEM2-ES_RCP45_2025MSY/HadGEM2-ES_RCP45_2025_annual.zip", 
          dest = "climate\\annual\\2011_2040\\RCP45\\HadGEM2-ES\\HadGEM2-ES_RCP45_2025_annual.zip", 
          mode = "wb")
unzip ("climate\\annual\\2011_2040\\RCP45\\HadGEM2-ES\\HadGEM2-ES_RCP45_2025_annual.zip", 
       exdir = "climate\\annual\\2011_2040\\RCP45\\HadGEM2-ES")
file.remove ("climate\\annual\\2011_2040\\RCP45\\HadGEM2-ES\\HadGEM2-ES_RCP45_2025_annual.zip")

download ("http://climatebcdata.climatewna.com/download/HadGEM2-ES_RCP45_2055MSY/HadGEM2-ES_RCP45_2055_annual.zip", 
          dest = "climate\\annual\\2041_2070\\RCP45\\HadGEM2-ES\\HadGEM2-ES_RCP45_2055_annual.zip", 
          mode = "wb")
unzip ("climate\\annual\\2041_2070\\RCP45\\HadGEM2-ES\\HadGEM2-ES_RCP45_2055_annual.zip", 
       exdir = "climate\\annual\\2041_2070\\RCP45\\HadGEM2-ES")
file.remove ("climate\\annual\\2041_2070\\RCP45\\HadGEM2-ES\\HadGEM2-ES_RCP45_2055_annual.zip")

download ("http://climatebcdata.climatewna.com/download/HadGEM2-ES_RCP45_2085MSY/HadGEM2-ES_RCP45_2085_annual.zip", 
          dest = "climate\\annual\\2071_2100\\RCP45\\HadGEM2-ES\\HadGEM2-ES_RCP45_2085_annual.zip", 
          mode = "wb")
unzip ("climate\\annual\\2071_2100\\RCP45\\HadGEM2-ES\\HadGEM2-ES_RCP45_2085_annual.zip", 
       exdir = "climate\\annual\\2071_2100\\RCP45\\HadGEM2-ES")
file.remove ("climate\\annual\\2071_2100\\RCP45\\HadGEM2-ES\\HadGEM2-ES_RCP45_2085_annual.zip")

#=================================
# Put data into Postgres db
#=================================
drv <- dbDriver ("PostgreSQL")
conn <- dbConnect (drv, 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")

tsa <-  st_read ("tsa\\FADM_TSA_polygon_20180716.shp")
st_write (tsa, conn, "FADM_TSA_polygon", layer_options = "OVERWRITE = true")

tsa.diss <-  st_read ("tsa\\fadm_tsa_dissolve_polygons_20180717.shp")
st_write (tsa.diss, conn, "fadm_tsa_dissolve_polygons", layer_options = "OVERWRITE = true")

bec.current <- raster ("bec\\BEC_zone.tif")
pgWriteRast (conn, "bec_current", bec.current, overwrite = TRUE)
bec.2020 <- raster ("bec\\BEC_zone_2020s.tif")
pgWriteRast (conn, "bec_2020s", bec.2020, overwrite = TRUE)
bec.2050 <- raster ("bec\\BEC_zone_2050s.tif")
pgWriteRast (conn, "bec_2050s", bec.2050, overwrite = TRUE)
bec.2080 <- raster ("bec\\BEC_zone_2080s.tif")
pgWriteRast (conn, "bec_2080s", bec.2080, overwrite = TRUE)

# 'Currrent' climate data
ahm <- raster ("climate\\annual\\1981_2010\\ahm")
pgWriteRast (conn, "annual_heat_moisture_index_1981_2010", ahm, overwrite = TRUE)
dd0 <- raster ("climate\\annual\\1981_2010\\dd_0")
pgWriteRast (conn, "degree_days_below_0_1981_2010", dd0, overwrite = TRUE)
dd5 <- raster ("climate\\annual\\1981_2010\\dd5")
pgWriteRast (conn, "degree_days_above_5C_1981_2010", dd5, overwrite = TRUE)
emt <- raster ("climate\\annual\\1981_2010\\emt")
pgWriteRast (conn, "extreme_min_temp_30_years_1981_2010", emt, overwrite = TRUE)
ext <- raster ("climate\\annual\\1981_2010\\ext")
pgWriteRast (conn, "extreme_max_temp_30_years_1981_2010", ext, overwrite = TRUE)
map <- raster ("climate\\annual\\1981_2010\\map")
pgWriteRast (conn, "mean_annual_precip_mm_1981_2010", map, overwrite = TRUE)
mat <- raster ("climate\\annual\\1981_2010\\mat")
pgWriteRast (conn, "mean_annual_temp_C_1981_2010", mat, overwrite = TRUE)
mcmt <- raster ("climate\\annual\\1981_2010\\mcmt")
pgWriteRast (conn, "mean_coldest_month_temp_1981_2010", mcmt, overwrite = TRUE)
msp <- raster ("climate\\annual\\1981_2010\\msp")
pgWriteRast (conn, "mean_may_to_sept_precip_mm_1981_2010", msp, overwrite = TRUE)
mwmt <- raster ("climate\\annual\\1981_2010\\mwmt")
pgWriteRast (conn, "mean_warmest_month_temp_1981_2010", mwmt, overwrite = TRUE)
nffd <- raster ("climate\\annual\\1981_2010\\nffd")
pgWriteRast (conn, "number_frost_free_days_1981_2010", nffd, overwrite = TRUE)
pas <- raster ("climate\\annual\\1981_2010\\pas")
pgWriteRast (conn, "precip_as_snow_Aug_to_July_1981_2010", pas, overwrite = TRUE)
rh <- raster ("climate\\annual\\1981_2010\\rh")
pgWriteRast (conn, "relative_humidity_1981_2010", rh, overwrite = TRUE)

# CanESM2 model 'future' climate data
# 2011-2040
ahm <- raster ("climate\\annual\\2011_2040\\RCP45\\CanESM2\\ahm")
pgWriteRast (conn, "annual_heat_moisture_index_canesm2_2011_2040", ahm, overwrite = TRUE)
dd0 <- raster ("climate\\annual\\2011_2040\\RCP45\\CanESM2\\dd_0")
pgWriteRast (conn, "degree_days_below_0_canesm2_2011_2040", dd0, overwrite = TRUE)
dd5 <- raster ("climate\\annual\\2011_2040\\RCP45\\CanESM2\\dd5")
pgWriteRast (conn, "degree_days_above_5C_canesm2_2011_2040", dd5, overwrite = TRUE)
emt <- raster ("climate\\annual\\2011_2040\\RCP45\\CanESM2\\emt")
pgWriteRast (conn, "extreme_min_temp_30_years_canesm2_2011_2040", emt, overwrite = TRUE)
ext <- raster ("climate\\annual\\2011_2040\\RCP45\\CanESM2\\ext")
pgWriteRast (conn, "extreme_max_temp_30_years_canesm2_2011_2040", ext, overwrite = TRUE)
map <- raster ("climate\\annual\\2011_2040\\RCP45\\CanESM2\\map")
pgWriteRast (conn, "mean_annual_precip_mm_canesm2_2011_2040", map, overwrite = TRUE)
mat <- raster ("climate\\annual\\2011_2040\\RCP45\\CanESM2\\mat")
pgWriteRast (conn, "mean_annual_temp_C_canesm2_2011_2040", mat, overwrite = TRUE)
mcmt <- raster ("climate\\annual\\2011_2040\\RCP45\\CanESM2\\mcmt")
pgWriteRast (conn, "mean_coldest_month_temp_canesm2_2011_2040", mcmt, overwrite = TRUE)
msp <- raster ("climate\\annual\\2011_2040\\RCP45\\CanESM2\\msp")
pgWriteRast (conn, "mean_may_to_sept_precip_mm_canesm2_2011_2040", msp, overwrite = TRUE)
mwmt <- raster ("climate\\annual\\2011_2040\\RCP45\\CanESM2\\mwmt")
pgWriteRast (conn, "mean_warmest_month_temp_canesm2_2011_2040", mwmt, overwrite = TRUE)
nffd <- raster ("climate\\annual\\2011_2040\\RCP45\\CanESM2\\nffd")
pgWriteRast (conn, "number_frost_free_days_canesm2_2011_2040", nffd, overwrite = TRUE)
pas <- raster ("climate\\annual\\2011_2040\\RCP45\\CanESM2\\pas")
pgWriteRast (conn, "precip_as_snow_Aug_to_July_canesm2_2011_2040", pas, overwrite = TRUE)
rh <- raster ("climate\\annual\\2011_2040\\RCP45\\CanESM2\\rh")
pgWriteRast (conn, "relative_humidity_canesm2_2011_2040", rh, overwrite = TRUE)

# 2041-2070
ahm <- raster ("climate\\annual\\2041_2070\\RCP45\\CanESM2\\ahm")
pgWriteRast (conn, "annual_heat_moisture_index_canesm2_2041_2070", ahm, overwrite = TRUE)
dd0 <- raster ("climate\\annual\\2041_2070\\RCP45\\CanESM2\\dd_0")
pgWriteRast (conn, "degree_days_below_0_canesm2_2041_2070", dd0, overwrite = TRUE)
dd5 <- raster ("climate\\annual\\2041_2070\\RCP45\\CanESM2\\dd5")
pgWriteRast (conn, "degree_days_above_5C_canesm2_2041_2070", dd5, overwrite = TRUE)
emt <- raster ("climate\\annual\\2041_2070\\RCP45\\CanESM2\\emt")
pgWriteRast (conn, "extreme_min_temp_30_years_canesm2_2041_2070", emt, overwrite = TRUE)
ext <- raster ("climate\\annual\\2041_2070\\RCP45\\CanESM2\\ext")
pgWriteRast (conn, "extreme_max_temp_30_years_canesm2_2041_2070", ext, overwrite = TRUE)
map <- raster ("climate\\annual\\2041_2070\\RCP45\\CanESM2\\map")
pgWriteRast (conn, "mean_annual_precip_mm_canesm2_2041_2070", map, overwrite = TRUE)
mat <- raster ("climate\\annual\\2041_2070\\RCP45\\CanESM2\\mat")
pgWriteRast (conn, "mean_annual_temp_C_canesm2_2041_2070", mat, overwrite = TRUE)
mcmt <- raster ("climate\\annual\\2041_2070\\RCP45\\CanESM2\\mcmt")
pgWriteRast (conn, "mean_coldest_month_temp_canesm2_2041_2070", mcmt, overwrite = TRUE)
msp <- raster ("climate\\annual\\2041_2070\\RCP45\\CanESM2\\msp")
pgWriteRast (conn, "mean_may_to_sept_precip_mm_canesm2_2041_2070", msp, overwrite = TRUE)
mwmt <- raster ("climate\\annual\\2041_2070\\RCP45\\CanESM2\\mwmt")
pgWriteRast (conn, "mean_warmest_month_temp_canesm2_2041_2070", mwmt, overwrite = TRUE)
nffd <- raster ("climate\\annual\\2041_2070\\RCP45\\CanESM2\\nffd")
pgWriteRast (conn, "number_frost_free_days_canesm2_2041_2070", nffd, overwrite = TRUE)
pas <- raster ("climate\\annual\\2041_2070\\RCP45\\CanESM2\\pas")
pgWriteRast (conn, "precip_as_snow_Aug_to_July_canesm2_2041_2070", pas, overwrite = TRUE)
rh <- raster ("climate\\annual\\2041_2070\\RCP45\\CanESM2\\rh")
pgWriteRast (conn, "relative_humidity_canesm2_2041_2070", rh, overwrite = TRUE)

# 2071-2100
ahm <- raster ("climate\\annual\\2071_2100\\RCP45\\CanESM2\\ahm")
pgWriteRast (conn, "annual_heat_moisture_index_canesm2_2071_2100", ahm, overwrite = TRUE)
dd0 <- raster ("climate\\annual\\2071_2100\\RCP45\\CanESM2\\dd_0")
pgWriteRast (conn, "degree_days_below_0_canesm2_2071_2100", dd0, overwrite = TRUE)
dd5 <- raster ("climate\\annual\\2071_2100\\RCP45\\CanESM2\\dd5")
pgWriteRast (conn, "degree_days_above_5C_canesm2_2071_2100", dd5, overwrite = TRUE)
emt <- raster ("climate\\annual\\2071_2100\\RCP45\\CanESM2\\emt")
pgWriteRast (conn, "extreme_min_temp_30_years_canesm2_2071_2100", emt, overwrite = TRUE)
ext <- raster ("climate\\annual\\2071_2100\\RCP45\\CanESM2\\ext")
pgWriteRast (conn, "extreme_max_temp_30_years_canesm2_2071_2100", ext, overwrite = TRUE)
map <- raster ("climate\\annual\\2071_2100\\RCP45\\CanESM2\\map")
pgWriteRast (conn, "mean_annual_precip_mm_canesm2_2071_2100", map, overwrite = TRUE)
mat <- raster ("climate\\annual\\2071_2100\\RCP45\\CanESM2\\mat")
pgWriteRast (conn, "mean_annual_temp_C_canesm2_2071_2100", mat, overwrite = TRUE)
mcmt <- raster ("climate\\annual\\2071_2100\\RCP45\\CanESM2\\mcmt")
pgWriteRast (conn, "mean_coldest_month_temp_canesm2_2071_2100", mcmt, overwrite = TRUE)
msp <- raster ("climate\\annual\\2071_2100\\RCP45\\CanESM2\\msp")
pgWriteRast (conn, "mean_may_to_sept_precip_mm_canesm2_2071_2100", msp, overwrite = TRUE)
mwmt <- raster ("climate\\annual\\2071_2100\\RCP45\\CanESM2\\mwmt")
pgWriteRast (conn, "mean_warmest_month_temp_canesm2_2071_2100", mwmt, overwrite = TRUE)
nffd <- raster ("climate\\annual\\2071_2100\\RCP45\\CanESM2\\nffd")
pgWriteRast (conn, "number_frost_free_days_canesm2_2071_2100", nffd, overwrite = TRUE)
pas <- raster ("climate\\annual\\2071_2100\\RCP45\\CanESM2\\pas")
pgWriteRast (conn, "precip_as_snow_Aug_to_July_canesm2_2071_2100", pas, overwrite = TRUE)
rh <- raster ("climate\\annual\\2071_2100\\RCP45\\CanESM2\\rh")
pgWriteRast (conn, "relative_humidity_canesm2_2071_2100", rh, overwrite = TRUE)


# CCSM4 model 'future' climate data
# 2011-2040
ahm <- raster ("climate\\annual\\2011_2040\\RCP45\\CCSM4\\ahm")
pgWriteRast (conn, "annual_heat_moisture_index_CCSM4_2011_2040", ahm, overwrite = TRUE)
dd0 <- raster ("climate\\annual\\2011_2040\\RCP45\\CCSM4\\dd_0")
pgWriteRast (conn, "degree_days_below_0_CCSM4_2011_2040", dd0, overwrite = TRUE)
dd5 <- raster ("climate\\annual\\2011_2040\\RCP45\\CCSM4\\dd5")
pgWriteRast (conn, "degree_days_above_5C_CCSM4_2011_2040", dd5, overwrite = TRUE)
emt <- raster ("climate\\annual\\2011_2040\\RCP45\\CCSM4\\emt")
pgWriteRast (conn, "extreme_min_temp_30_years_CCSM4_2011_2040", emt, overwrite = TRUE)
ext <- raster ("climate\\annual\\2011_2040\\RCP45\\CCSM4\\ext")
pgWriteRast (conn, "extreme_max_temp_30_years_CCSM4_2011_2040", ext, overwrite = TRUE)
map <- raster ("climate\\annual\\2011_2040\\RCP45\\CCSM4\\map")
pgWriteRast (conn, "mean_annual_precip_mm_CCSM4_2011_2040", map, overwrite = TRUE)
mat <- raster ("climate\\annual\\2011_2040\\RCP45\\CCSM4\\mat")
pgWriteRast (conn, "mean_annual_temp_C_CCSM4_2011_2040", mat, overwrite = TRUE)
mcmt <- raster ("climate\\annual\\2011_2040\\RCP45\\CCSM4\\mcmt")
pgWriteRast (conn, "mean_coldest_month_temp_CCSM4_2011_2040", mcmt, overwrite = TRUE)
msp <- raster ("climate\\annual\\2011_2040\\RCP45\\CCSM4\\msp")
pgWriteRast (conn, "mean_may_to_sept_precip_mm_CCSM4_2011_2040", msp, overwrite = TRUE)
mwmt <- raster ("climate\\annual\\2011_2040\\RCP45\\CCSM4\\mwmt")
pgWriteRast (conn, "mean_warmest_month_temp_CCSM4_2011_2040", mwmt, overwrite = TRUE)
nffd <- raster ("climate\\annual\\2011_2040\\RCP45\\CCSM4\\nffd")
pgWriteRast (conn, "number_frost_free_days_CCSM4_2011_2040", nffd, overwrite = TRUE)
pas <- raster ("climate\\annual\\2011_2040\\RCP45\\CCSM4\\pas")
pgWriteRast (conn, "precip_as_snow_Aug_to_July_CCSM4_2011_2040", pas, overwrite = TRUE)
rh <- raster ("climate\\annual\\2011_2040\\RCP45\\CCSM4\\rh")
pgWriteRast (conn, "relative_humidity_CCSM4_2011_2040", rh, overwrite = TRUE)

# 2041-2070
ahm <- raster ("climate\\annual\\2041_2070\\RCP45\\CCSM4\\ahm")
pgWriteRast (conn, "annual_heat_moisture_index_CCSM4_2041_2070", ahm, overwrite = TRUE)
dd0 <- raster ("climate\\annual\\2041_2070\\RCP45\\CCSM4\\dd_0")
pgWriteRast (conn, "degree_days_below_0_CCSM4_2041_2070", dd0, overwrite = TRUE)
dd5 <- raster ("climate\\annual\\2041_2070\\RCP45\\CCSM4\\dd5")
pgWriteRast (conn, "degree_days_above_5C_CCSM4_2041_2070", dd5, overwrite = TRUE)
emt <- raster ("climate\\annual\\2041_2070\\RCP45\\CCSM4\\emt")
pgWriteRast (conn, "extreme_min_temp_30_years_CCSM4_2041_2070", emt, overwrite = TRUE)
ext <- raster ("climate\\annual\\2041_2070\\RCP45\\CCSM4\\ext")
pgWriteRast (conn, "extreme_max_temp_30_years_CCSM4_2041_2070", ext, overwrite = TRUE)
map <- raster ("climate\\annual\\2041_2070\\RCP45\\CCSM4\\map")
pgWriteRast (conn, "mean_annual_precip_mm_CCSM4_2041_2070", map, overwrite = TRUE)
mat <- raster ("climate\\annual\\2041_2070\\RCP45\\CCSM4\\mat")
pgWriteRast (conn, "mean_annual_temp_C_CCSM4_2041_2070", mat, overwrite = TRUE)
mcmt <- raster ("climate\\annual\\2041_2070\\RCP45\\CCSM4\\mcmt")
pgWriteRast (conn, "mean_coldest_month_temp_CCSM4_2041_2070", mcmt, overwrite = TRUE)
msp <- raster ("climate\\annual\\2041_2070\\RCP45\\CCSM4\\msp")
pgWriteRast (conn, "mean_may_to_sept_precip_mm_CCSM4_2041_2070", msp, overwrite = TRUE)
mwmt <- raster ("climate\\annual\\2041_2070\\RCP45\\CCSM4\\mwmt")
pgWriteRast (conn, "mean_warmest_month_temp_CCSM4_2041_2070", mwmt, overwrite = TRUE)
nffd <- raster ("climate\\annual\\2041_2070\\RCP45\\CCSM4\\nffd")
pgWriteRast (conn, "number_frost_free_days_CCSM4_2041_2070", nffd, overwrite = TRUE)
pas <- raster ("climate\\annual\\2041_2070\\RCP45\\CCSM4\\pas")
pgWriteRast (conn, "precip_as_snow_Aug_to_July_CCSM4_2041_2070", pas, overwrite = TRUE)
rh <- raster ("climate\\annual\\2041_2070\\RCP45\\CCSM4\\rh")
pgWriteRast (conn, "relative_humidity_CCSM4_2041_2070", rh, overwrite = TRUE)

# 2071-2100
ahm <- raster ("climate\\annual\\2071_2100\\RCP45\\CCSM4\\ahm")
pgWriteRast (conn, "annual_heat_moisture_index_CCSM4_2071_2100", ahm, overwrite = TRUE)
dd0 <- raster ("climate\\annual\\2071_2100\\RCP45\\CCSM4\\dd_0")
pgWriteRast (conn, "degree_days_below_0_CCSM4_2071_2100", dd0, overwrite = TRUE)
dd5 <- raster ("climate\\annual\\2071_2100\\RCP45\\CCSM4\\dd5")
pgWriteRast (conn, "degree_days_above_5C_CCSM4_2071_2100", dd5, overwrite = TRUE)
emt <- raster ("climate\\annual\\2071_2100\\RCP45\\CCSM4\\emt")
pgWriteRast (conn, "extreme_min_temp_30_years_CCSM4_2071_2100", emt, overwrite = TRUE)
ext <- raster ("climate\\annual\\2071_2100\\RCP45\\CCSM4\\ext")
pgWriteRast (conn, "extreme_max_temp_30_years_CCSM4_2071_2100", ext, overwrite = TRUE)
map <- raster ("climate\\annual\\2071_2100\\RCP45\\CCSM4\\map")
pgWriteRast (conn, "mean_annual_precip_mm_CCSM4_2071_2100", map, overwrite = TRUE)
mat <- raster ("climate\\annual\\2071_2100\\RCP45\\CCSM4\\mat")
pgWriteRast (conn, "mean_annual_temp_C_CCSM4_2071_2100", mat, overwrite = TRUE)
mcmt <- raster ("climate\\annual\\2071_2100\\RCP45\\CCSM4\\mcmt")
pgWriteRast (conn, "mean_coldest_month_temp_CCSM4_2071_2100", mcmt, overwrite = TRUE)
msp <- raster ("climate\\annual\\2071_2100\\RCP45\\CCSM4\\msp")
pgWriteRast (conn, "mean_may_to_sept_precip_mm_CCSM4_2071_2100", msp, overwrite = TRUE)
mwmt <- raster ("climate\\annual\\2071_2100\\RCP45\\CCSM4\\mwmt")
pgWriteRast (conn, "mean_warmest_month_temp_CCSM4_2071_2100", mwmt, overwrite = TRUE)
nffd <- raster ("climate\\annual\\2071_2100\\RCP45\\CCSM4\\nffd")
pgWriteRast (conn, "number_frost_free_days_CCSM4_2071_2100", nffd, overwrite = TRUE)
pas <- raster ("climate\\annual\\2071_2100\\RCP45\\CCSM4\\pas")
pgWriteRast (conn, "precip_as_snow_Aug_to_July_CCSM4_2071_2100", pas, overwrite = TRUE)
rh <- raster ("climate\\annual\\2071_2100\\RCP45\\CCSM4\\rh")
pgWriteRast (conn, "relative_humidity_CCSM4_2071_2100", rh, overwrite = TRUE)

# HadGEM2-ES model 'future' climate data
# 2011-2040
ahm <- raster ("climate\\annual\\2011_2040\\RCP45\\HadGEM2-ES\\ahm")
pgWriteRast (conn, "annual_heat_moisture_index_HadGEM2ES_2011_2040", ahm, overwrite = TRUE)
dd0 <- raster ("climate\\annual\\2011_2040\\RCP45\\HadGEM2-ES\\dd_0")
pgWriteRast (conn, "degree_days_below_0_HadGEM2ES_2011_2040", dd0, overwrite = TRUE)
dd5 <- raster ("climate\\annual\\2011_2040\\RCP45\\HadGEM2-ES\\dd5")
pgWriteRast (conn, "degree_days_above_5C_HadGEM2ES_2011_2040", dd5, overwrite = TRUE)
emt <- raster ("climate\\annual\\2011_2040\\RCP45\\HadGEM2-ES\\emt")
pgWriteRast (conn, "extreme_min_temp_30_years_HadGEM2ES_2011_2040", emt, overwrite = TRUE)
ext <- raster ("climate\\annual\\2011_2040\\RCP45\\HadGEM2-ES\\ext")
pgWriteRast (conn, "extreme_max_temp_30_years_HadGEM2ES_2011_2040", ext, overwrite = TRUE)
map <- raster ("climate\\annual\\2011_2040\\RCP45\\HadGEM2-ES\\map")
pgWriteRast (conn, "mean_annual_precip_mm_HadGEM2ES_2011_2040", map, overwrite = TRUE)
mat <- raster ("climate\\annual\\2011_2040\\RCP45\\HadGEM2-ES\\mat")
pgWriteRast (conn, "mean_annual_temp_C_HadGEM2ES_2011_2040", mat, overwrite = TRUE)
mcmt <- raster ("climate\\annual\\2011_2040\\RCP45\\HadGEM2-ES\\mcmt")
pgWriteRast (conn, "mean_coldest_month_temp_HadGEM2ES_2011_2040", mcmt, overwrite = TRUE)
msp <- raster ("climate\\annual\\2011_2040\\RCP45\\HadGEM2-ES\\msp")
pgWriteRast (conn, "mean_may_to_sept_precip_mm_HadGEM2ES_2011_2040", msp, overwrite = TRUE)
mwmt <- raster ("climate\\annual\\2011_2040\\RCP45\\HadGEM2-ES\\mwmt")
pgWriteRast (conn, "mean_warmest_month_temp_HadGEM2ES_2011_2040", mwmt, overwrite = TRUE)
nffd <- raster ("climate\\annual\\2011_2040\\RCP45\\HadGEM2-ES\\nffd")
pgWriteRast (conn, "number_frost_free_days_HadGEM2ES_2011_2040", nffd, overwrite = TRUE)
pas <- raster ("climate\\annual\\2011_2040\\RCP45\\HadGEM2-ES\\pas")
pgWriteRast (conn, "precip_as_snow_Aug_to_July_HadGEM2ES_2011_2040", pas, overwrite = TRUE)
rh <- raster ("climate\\annual\\2011_2040\\RCP45\\HadGEM2-ES\\rh")
pgWriteRast (conn, "relative_humidity_HadGEM2ES_2011_2040", rh, overwrite = TRUE)

# 2041-2070
ahm <- raster ("climate\\annual\\2041_2070\\RCP45\\HadGEM2-ES\\ahm")
pgWriteRast (conn, "annual_heat_moisture_index_HadGEM2ES_2041_2070", ahm, overwrite = TRUE)
dd0 <- raster ("climate\\annual\\2041_2070\\RCP45\\HadGEM2-ES\\dd_0")
pgWriteRast (conn, "degree_days_below_0_HadGEM2ES_2041_2070", dd0, overwrite = TRUE)
dd5 <- raster ("climate\\annual\\2041_2070\\RCP45\\HadGEM2-ES\\dd5")
pgWriteRast (conn, "degree_days_above_5C_HadGEM2ES_2041_2070", dd5, overwrite = TRUE)
emt <- raster ("climate\\annual\\2041_2070\\RCP45\\HadGEM2-ES\\emt")
pgWriteRast (conn, "extreme_min_temp_30_years_HadGEM2ES_2041_2070", emt, overwrite = TRUE)
ext <- raster ("climate\\annual\\2041_2070\\RCP45\\HadGEM2-ES\\ext")
pgWriteRast (conn, "extreme_max_temp_30_years_HadGEM2ES_2041_2070", ext, overwrite = TRUE)
map <- raster ("climate\\annual\\2041_2070\\RCP45\\HadGEM2-ES\\map")
pgWriteRast (conn, "mean_annual_precip_mm_HadGEM2ES_2041_2070", map, overwrite = TRUE)
mat <- raster ("climate\\annual\\2041_2070\\RCP45\\HadGEM2-ES\\mat")
pgWriteRast (conn, "mean_annual_temp_C_HadGEM2ES_2041_2070", mat, overwrite = TRUE)
mcmt <- raster ("climate\\annual\\2041_2070\\RCP45\\HadGEM2-ES\\mcmt")
pgWriteRast (conn, "mean_coldest_month_temp_HadGEM2ES_2041_2070", mcmt, overwrite = TRUE)
msp <- raster ("climate\\annual\\2041_2070\\RCP45\\HadGEM2-ES\\msp")
pgWriteRast (conn, "mean_may_to_sept_precip_mm_HadGEM2ES_2041_2070", msp, overwrite = TRUE)
mwmt <- raster ("climate\\annual\\2041_2070\\RCP45\\HadGEM2-ES\\mwmt")
pgWriteRast (conn, "mean_warmest_month_temp_HadGEM2ES_2041_2070", mwmt, overwrite = TRUE)
nffd <- raster ("climate\\annual\\2041_2070\\RCP45\\HadGEM2-ES\\nffd")
pgWriteRast (conn, "number_frost_free_days_HadGEM2ES_2041_2070", nffd, overwrite = TRUE)
pas <- raster ("climate\\annual\\2041_2070\\RCP45\\HadGEM2-ES\\pas")
pgWriteRast (conn, "precip_as_snow_Aug_to_July_HadGEM2ES_2041_2070", pas, overwrite = TRUE)
rh <- raster ("climate\\annual\\2041_2070\\RCP45\\HadGEM2-ES\\rh")
pgWriteRast (conn, "relative_humidity_HadGEM2ES_2041_2070", rh, overwrite = TRUE)

# 2071-2100
ahm <- raster ("climate\\annual\\2071_2100\\RCP45\\HadGEM2-ES\\ahm")
pgWriteRast (conn, "annual_heat_moisture_index_HadGEM2ES_2071_2100", ahm, overwrite = TRUE)
dd0 <- raster ("climate\\annual\\2071_2100\\RCP45\\HadGEM2-ES\\dd_0")
pgWriteRast (conn, "degree_days_below_0_HadGEM2ES_2071_2100", dd0, overwrite = TRUE)
dd5 <- raster ("climate\\annual\\2071_2100\\RCP45\\HadGEM2-ES\\dd5")
pgWriteRast (conn, "degree_days_above_5C_HadGEM2ES_2071_2100", dd5, overwrite = TRUE)
emt <- raster ("climate\\annual\\2071_2100\\RCP45\\HadGEM2-ES\\emt")
pgWriteRast (conn, "extreme_min_temp_30_years_HadGEM2ES_2071_2100", emt, overwrite = TRUE)
ext <- raster ("climate\\annual\\2071_2100\\RCP45\\HadGEM2-ES\\ext")
pgWriteRast (conn, "extreme_max_temp_30_years_HadGEM2ES_2071_2100", ext, overwrite = TRUE)
map <- raster ("climate\\annual\\2071_2100\\RCP45\\HadGEM2-ES\\map")
pgWriteRast (conn, "mean_annual_precip_mm_HadGEM2ES_2071_2100", map, overwrite = TRUE)
mat <- raster ("climate\\annual\\2071_2100\\RCP45\\HadGEM2-ES\\mat")
pgWriteRast (conn, "mean_annual_temp_C_HadGEM2ES_2071_2100", mat, overwrite = TRUE)
mcmt <- raster ("climate\\annual\\2071_2100\\RCP45\\HadGEM2-ES\\mcmt")
pgWriteRast (conn, "mean_coldest_month_temp_HadGEM2ES_2071_2100", mcmt, overwrite = TRUE)
msp <- raster ("climate\\annual\\2071_2100\\RCP45\\HadGEM2-ES\\msp")
pgWriteRast (conn, "mean_may_to_sept_precip_mm_HadGEM2ES_2071_2100", msp, overwrite = TRUE)
mwmt <- raster ("climate\\annual\\2071_2100\\RCP45\\HadGEM2-ES\\mwmt")
pgWriteRast (conn, "mean_warmest_month_temp_HadGEM2ES_2071_2100", mwmt, overwrite = TRUE)
nffd <- raster ("climate\\annual\\2071_2100\\RCP45\\HadGEM2-ES\\nffd")
pgWriteRast (conn, "number_frost_free_days_HadGEM2ES_2071_2100", nffd, overwrite = TRUE)
pas <- raster ("climate\\annual\\2071_2100\\RCP45\\HadGEM2-ES\\pas")
pgWriteRast (conn, "precip_as_snow_Aug_to_July_HadGEM2ES_2071_2100", pas, overwrite = TRUE)
rh <- raster ("climate\\annual\\2071_2100\\RCP45\\HadGEM2-ES\\rh")
pgWriteRast (conn, "relative_humidity_HadGEM2ES_2071_2100", rh, overwrite = TRUE)

