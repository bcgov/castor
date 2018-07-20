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
#  Script Name: 02_data_prep_tsr_climate.R
#  Script Version: 1.0
#  Script Purpose: Prep data timber supply area scale climate summaries.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 17 July 2018
#  R Version: 3.4.3
#  R Package Versions: 
#  Data: 
#=================================


#=================================
# Data directory and packages
#=================================
require (RPostgreSQL)
require (sf)
require (raster)
require (rpostgis)
require (dplyr)

drv <- dbDriver ("PostgreSQL")
conn <- dbConnect (drv, # connection to the postgres db where you want to store the data
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")

#================================================================================
# Average Raster Values from 3 climate models and divide by 10 (where necessary)
#===============================================================================

# NOTE: the following variables were multiplied by 10
  # Annual: MAT, MWMT, MCMT, TD, AHM, SHM, EMT, EXT and MAR;

# 2025
ahm.canesm2.2025 <- pgGetRast (conn, "annual_heat_moisture_index_canesm2_2011_2040")
ahm.ccsm4.2025 <- pgGetRast (conn, "annual_heat_moisture_index_CCSM4_2011_2040")
ahm.HadGEM.2025 <- pgGetRast (conn, "annual_heat_moisture_index_HadGEM2ES_2011_2040")
ahm.2025 <- mean (ahm.canesm2.2025, ahm.ccsm4.2025, ahm.HadGEM.2025) / 10
pgWriteRast (conn, "annual_heat_moisture_index_avg_2011_2040", ahm.2025, overwrite = TRUE)

dd0.canesm2.2025 <- pgGetRast (conn, "degree_days_below_0_canesm2_2011_2040")
dd0.ccsm4.2025 <- pgGetRast (conn, "degree_days_below_0_CCSM4_2011_2040")
dd0.HadGEM.2025 <- pgGetRast (conn, "degree_days_below_0_HadGEM2ES_2011_2040")
dd0.2025 <- mean (dd0.canesm2.2025, dd0.ccsm4.2025, dd0.HadGEM.2025)
pgWriteRast (conn, "degree_days_below_0_avg_2011_2040", dd0.2025, overwrite = TRUE)

dd5.canesm2.2025 <- pgGetRast (conn, "degree_days_above_5C_canesm2_2011_2040")
dd5.ccsm4.2025 <- pgGetRast (conn, "degree_days_above_5C_CCSM4_2011_2040")
dd5.HadGEM.2025 <- pgGetRast (conn, "degree_days_above_5C_HadGEM2ES_2011_2040")
dd5.2025 <- mean (dd5.canesm2.2025, dd5.ccsm4.2025, dd5.HadGEM.2025)
pgWriteRast (conn, "degree_days_above_5C_avg_2011_2040", dd5.2025, overwrite = TRUE)

emt.canesm2.2025 <- pgGetRast (conn, "extreme_min_temp_30_years_canesm2_2011_2040")
emt.ccsm4.2025 <- pgGetRast (conn, "extreme_min_temp_30_years_CCSM4_2011_2040")
emt.HadGEM.2025 <- pgGetRast (conn, "extreme_min_temp_30_years_HadGEM2ES_2011_2040")
emt.2025 <- mean (emt.canesm2.2025, emt.ccsm4.2025, emt.HadGEM.2025) / 10
pgWriteRast (conn, "extreme_min_temp_30_years_avg_2011_2040", emt.2025, overwrite = TRUE)

ext.canesm2.2025 <- pgGetRast (conn, "extreme_max_temp_30_years_canesm2_2011_2040")
ext.ccsm4.2025 <- pgGetRast (conn, "extreme_max_temp_30_years_CCSM4_2011_2040")
ext.HadGEM.2025 <- pgGetRast (conn, "extreme_max_temp_30_years_HadGEM2ES_2011_2040")
ext.2025 <- mean (ext.canesm2.2025, ext.ccsm4.2025, ext.HadGEM.2025) / 10
pgWriteRast (conn, "extreme_max_temp_30_years_avg_2011_2040", ext.2025, overwrite = TRUE)

map.canesm2.2025 <- pgGetRast (conn, "mean_annual_precip_mm_canesm2_2011_2040")
map.ccsm4.2025 <- pgGetRast (conn, "mean_annual_precip_mm_CCSM4_2011_2040")
map.HadGEM.2025 <- pgGetRast (conn, "mean_annual_precip_mm_HadGEM2ES_2011_2040")
map.2025 <- mean (map.canesm2.2025, map.ccsm4.2025, map.HadGEM.2025)
pgWriteRast (conn, "mean_annual_precip_mm_avg_2011_2040", map.2025, overwrite = TRUE)

mat.canesm2.2025 <- pgGetRast (conn, "mean_annual_temp_C_canesm2_2011_2040")
mat.ccsm4.2025 <- pgGetRast (conn, "mean_annual_temp_C_CCSM4_2011_2040")
mat.HadGEM.2025 <- pgGetRast (conn, "mean_annual_temp_C_HadGEM2ES_2011_2040")
mat.2025 <- mean (mat.canesm2.2025, mat.ccsm4.2025, mat.HadGEM.2025) / 10
pgWriteRast (conn, "mean_annual_temp_C_avg_2011_2040", mat.2025, overwrite = TRUE)

mcmt.canesm2.2025 <- pgGetRast (conn, "mean_coldest_month_temp_canesm2_2011_2040")
mcmt.ccsm4.2025 <- pgGetRast (conn, "mean_coldest_month_temp_CCSM4_2011_2040")
mcmt.HadGEM.2025 <- pgGetRast (conn, "mean_coldest_month_temp_HadGEM2ES_2011_2040")
mcmt.2025 <- mean (mcmt.canesm2.2025, mcmt.ccsm4.2025, mcmt.HadGEM.2025) / 10
pgWriteRast (conn, "mean_coldest_month_temp_avg_2011_2040", mcmt.2025, overwrite = TRUE)

msp.canesm2.2025 <- pgGetRast (conn, "mean_may_to_sept_precip_mm_canesm2_2011_2040")
msp.ccsm4.2025 <- pgGetRast (conn, "mean_may_to_sept_precip_mm_CCSM4_2011_2040")
msp.HadGEM.2025 <- pgGetRast (conn, "mean_may_to_sept_precip_mm_HadGEM2ES_2011_2040")
msp.2025 <- mean (msp.canesm2.2025, msp.ccsm4.2025, msp.HadGEM.2025)
pgWriteRast (conn, "mean_may_to_sept_precip_mm_avg_2011_2040", msp.2025, overwrite = TRUE)

mwmt.canesm2.2025 <- pgGetRast (conn, "mean_warmest_month_temp_canesm2_2011_2040")
mwmt.ccsm4.2025 <- pgGetRast (conn, "mean_warmest_month_temp_CCSM4_2011_2040")
mwmt.HadGEM.2025 <- pgGetRast (conn, "mean_warmest_month_temp_HadGEM2ES_2011_2040")
mwmt.2025 <- mean (mwmt.canesm2.2025, mwmt.ccsm4.2025, mwmt.HadGEM.2025) / 10
pgWriteRast (conn, "mean_warmest_month_temp_avg_2011_2040", mwmt.2025, overwrite = TRUE)

nffd.canesm2.2025 <- pgGetRast (conn, "number_frost_free_days_canesm2_2011_2040")
nffd.ccsm4.2025 <- pgGetRast (conn, "number_frost_free_days_CCSM4_2011_2040")
nffd.HadGEM.2025 <- pgGetRast (conn, "number_frost_free_days_HadGEM2ES_2011_2040")
nffd.2025 <- mean (nffd.canesm2.2025, nffd.ccsm4.2025, nffd.HadGEM.2025)
pgWriteRast (conn, "number_frost_free_days_avg_2011_2040", nffd.2025, overwrite = TRUE)

pas.canesm2.2025 <- pgGetRast (conn, "precip_as_snow_Aug_to_July_canesm2_2011_2040")
pas.ccsm4.2025 <- pgGetRast (conn, "precip_as_snow_Aug_to_July_CCSM4_2011_2040")
pas.HadGEM.2025 <- pgGetRast (conn, "precip_as_snow_Aug_to_July_HadGEM2ES_2011_2040")
pas.2025 <- mean (pas.canesm2.2025, pas.ccsm4.2025, pas.HadGEM.2025)
pgWriteRast (conn, "precip_as_snow_Aug_to_July_avg_2011_2040", pas.2025, overwrite = TRUE)

rh.canesm2.2025 <- pgGetRast (conn, "relative_humidity_canesm2_2011_2040")
rh.ccsm4.2025 <- pgGetRast (conn, "relative_humidity_CCSM4_2011_2040")
rh.HadGEM.2025 <- pgGetRast (conn, "relative_humidity_HadGEM2ES_2011_2040")
rh.2025 <- mean (rh.canesm2.2025, rh.ccsm4.2025, rh.HadGEM.2025)
pgWriteRast (conn, "relative_humidity_avg_2011_2040", rh.2025, overwrite = TRUE)

# 2055
ahm.canesm2.2055 <- pgGetRast (conn, "annual_heat_moisture_index_canesm2_2041_2070")
ahm.ccsm4.2055 <- pgGetRast (conn, "annual_heat_moisture_index_CCSM4_2041_2070")
ahm.HadGEM.2055 <- pgGetRast (conn, "annual_heat_moisture_index_HadGEM2ES_2041_2070")
ahm.2055 <- mean (ahm.canesm2.2055, ahm.ccsm4.2055, ahm.HadGEM.2055) / 10
pgWriteRast (conn, "annual_heat_moisture_index_avg_2041_2070", ahm.2055, overwrite = TRUE)

dd0.canesm2.2055 <- pgGetRast (conn, "degree_days_below_0_canesm2_2041_2070")
dd0.ccsm4.2055 <- pgGetRast (conn, "degree_days_below_0_CCSM4_2041_2070")
dd0.HadGEM.2055 <- pgGetRast (conn, "degree_days_below_0_HadGEM2ES_2041_2070")
dd0.2055 <- mean (dd0.canesm2.2055, dd0.ccsm4.2055, dd0.HadGEM.2055)
pgWriteRast (conn, "degree_days_below_0_avg_2041_2070", dd0.2055, overwrite = TRUE)

dd5.canesm2.2055 <- pgGetRast (conn, "degree_days_above_5C_canesm2_2041_2070")
dd5.ccsm4.2055 <- pgGetRast (conn, "degree_days_above_5C_CCSM4_2041_2070")
dd5.HadGEM.2055 <- pgGetRast (conn, "degree_days_above_5C_HadGEM2ES_2041_2070")
dd5.2055 <- mean (dd5.canesm2.2055, dd5.ccsm4.2055, dd5.HadGEM.2055)
pgWriteRast (conn, "degree_days_above_5C_avg_2041_2070", dd5.2055, overwrite = TRUE)

emt.canesm2.2055 <- pgGetRast (conn, "extreme_min_temp_30_years_canesm2_2041_2070")
emt.ccsm4.2055 <- pgGetRast (conn, "extreme_min_temp_30_years_CCSM4_2041_2070")
emt.HadGEM.2055 <- pgGetRast (conn, "extreme_min_temp_30_years_HadGEM2ES_2041_2070")
emt.2055 <- mean (emt.canesm2.2055, emt.ccsm4.2055, emt.HadGEM.2055) / 10
pgWriteRast (conn, "extreme_min_temp_30_years_avg_2041_2070", emt.2055, overwrite = TRUE)

ext.canesm2.2055 <- pgGetRast (conn, "extreme_max_temp_30_years_canesm2_2041_2070")
ext.ccsm4.2055 <- pgGetRast (conn, "extreme_max_temp_30_years_CCSM4_2041_2070")
ext.HadGEM.2055 <- pgGetRast (conn, "extreme_max_temp_30_years_HadGEM2ES_2041_2070")
ext.2055 <- mean (ext.canesm2.2055, ext.ccsm4.2055, ext.HadGEM.2055) / 10
pgWriteRast (conn, "extreme_max_temp_30_years_avg_2041_2070", ext.2055, overwrite = TRUE)

map.canesm2.2055 <- pgGetRast (conn, "mean_annual_precip_mm_canesm2_2041_2070")
map.ccsm4.2055 <- pgGetRast (conn, "mean_annual_precip_mm_CCSM4_2041_2070")
map.HadGEM.2055 <- pgGetRast (conn, "mean_annual_precip_mm_HadGEM2ES_2041_2070")
map.2055 <- mean (map.canesm2.2055, map.ccsm4.2055, map.HadGEM.2055)
pgWriteRast (conn, "mean_annual_precip_mm_avg_2041_2070", map.2055, overwrite = TRUE)

mat.canesm2.2055 <- pgGetRast (conn, "mean_annual_temp_C_canesm2_2041_2070")
mat.ccsm4.2055 <- pgGetRast (conn, "mean_annual_temp_C_CCSM4_2041_2070")
mat.HadGEM.2055 <- pgGetRast (conn, "mean_annual_temp_C_HadGEM2ES_2041_2070")
mat.2055 <- mean (mat.canesm2.2055, mat.ccsm4.2055, mat.HadGEM.2055) / 10
pgWriteRast (conn, "mean_annual_temp_C_avg_2041_2070", mat.2055, overwrite = TRUE)

mcmt.canesm2.2055 <- pgGetRast (conn, "mean_coldest_month_temp_canesm2_2041_2070")
mcmt.ccsm4.2055 <- pgGetRast (conn, "mean_coldest_month_temp_CCSM4_2041_2070")
mcmt.HadGEM.2055 <- pgGetRast (conn, "mean_coldest_month_temp_HadGEM2ES_2041_2070")
mcmt.2055 <- mean (mcmt.canesm2.2055, mcmt.ccsm4.2055, mcmt.HadGEM.2055) / 10
pgWriteRast (conn, "mean_coldest_month_temp_avg_2041_2070", mcmt.2055, overwrite = TRUE)

msp.canesm2.2055 <- pgGetRast (conn, "mean_may_to_sept_precip_mm_canesm2_2041_2070")
msp.ccsm4.2055 <- pgGetRast (conn, "mean_may_to_sept_precip_mm_CCSM4_2041_2070")
msp.HadGEM.2055 <- pgGetRast (conn, "mean_may_to_sept_precip_mm_HadGEM2ES_2041_2070")
msp.2055 <- mean (msp.canesm2.2055, msp.ccsm4.2055, msp.HadGEM.2055)
pgWriteRast (conn, "mean_may_to_sept_precip_mm_avg_2041_2070", msp.2055, overwrite = TRUE)

mwmt.canesm2.2055 <- pgGetRast (conn, "mean_warmest_month_temp_canesm2_2041_2070")
mwmt.ccsm4.2055 <- pgGetRast (conn, "mean_warmest_month_temp_CCSM4_2041_2070")
mwmt.HadGEM.2055 <- pgGetRast (conn, "mean_warmest_month_temp_HadGEM2ES_2041_2070")
mwmt.2055 <- mean (mwmt.canesm2.2055, mwmt.ccsm4.2055, mwmt.HadGEM.2055) / 10
pgWriteRast (conn, "mean_warmest_month_temp_avg_2041_2070", mwmt.2055, overwrite = TRUE)

nffd.canesm2.2055 <- pgGetRast (conn, "number_frost_free_days_canesm2_2041_2070")
nffd.ccsm4.2055 <- pgGetRast (conn, "number_frost_free_days_CCSM4_2041_2070")
nffd.HadGEM.2055 <- pgGetRast (conn, "number_frost_free_days_HadGEM2ES_2041_2070")
nffd.2055 <- mean (nffd.canesm2.2055, nffd.ccsm4.2055, nffd.HadGEM.2055)
pgWriteRast (conn, "number_frost_free_days_avg_2041_2070", nffd.2055, overwrite = TRUE)

pas.canesm2.2055 <- pgGetRast (conn, "precip_as_snow_Aug_to_July_canesm2_2041_2070")
pas.ccsm4.2055 <- pgGetRast (conn, "precip_as_snow_Aug_to_July_CCSM4_2041_2070")
pas.HadGEM.2055 <- pgGetRast (conn, "precip_as_snow_Aug_to_July_HadGEM2ES_2041_2070")
pas.2055 <- mean (pas.canesm2.2055, pas.ccsm4.2055, pas.HadGEM.2055)
pgWriteRast (conn, "precip_as_snow_Aug_to_July_avg_2041_2070", pas.2055, overwrite = TRUE)

rh.canesm2.2055 <- pgGetRast (conn, "relative_humidity_canesm2_2041_2070")
rh.ccsm4.2055 <- pgGetRast (conn, "relative_humidity_CCSM4_2041_2070")
rh.HadGEM.2055 <- pgGetRast (conn, "relative_humidity_HadGEM2ES_2041_2070")
rh.2055 <- mean (rh.canesm2.2055, rh.ccsm4.2055, rh.HadGEM.2055)
pgWriteRast (conn, "relative_humidity_avg_2041_2070", rh.2055, overwrite = TRUE)

# 2085
ahm.canesm2.2085 <- pgGetRast (conn, "annual_heat_moisture_index_canesm2_2071_2100")
ahm.ccsm4.2085 <- pgGetRast (conn, "annual_heat_moisture_index_CCSM4_2071_2100")
ahm.HadGEM.2085 <- pgGetRast (conn, "annual_heat_moisture_index_HadGEM2ES_2071_2100")
ahm.2085 <- mean (ahm.canesm2.2085, ahm.ccsm4.2085, ahm.HadGEM.2085) / 10
pgWriteRast (conn, "annual_heat_moisture_index_avg_2071_2100", ahm.2085, overwrite = TRUE)

dd0.canesm2.2085 <- pgGetRast (conn, "degree_days_below_0_canesm2_2071_2100")
dd0.ccsm4.2085 <- pgGetRast (conn, "degree_days_below_0_CCSM4_2071_2100")
dd0.HadGEM.2085 <- pgGetRast (conn, "degree_days_below_0_HadGEM2ES_2071_2100")
dd0.2085 <- mean (dd0.canesm2.2085, dd0.ccsm4.2085, dd0.HadGEM.2085)
pgWriteRast (conn, "degree_days_below_0_avg_2071_2100", dd0.2085, overwrite = TRUE)

dd5.canesm2.2085 <- pgGetRast (conn, "degree_days_above_5C_canesm2_2071_2100")
dd5.ccsm4.2085 <- pgGetRast (conn, "degree_days_above_5C_CCSM4_2071_2100")
dd5.HadGEM.2085 <- pgGetRast (conn, "degree_days_above_5C_HadGEM2ES_2071_2100")
dd5.2085 <- mean (dd5.canesm2.2085, dd5.ccsm4.2085, dd5.HadGEM.2085)
pgWriteRast (conn, "degree_days_above_5C_avg_2071_2100", dd5.2085, overwrite = TRUE)

emt.canesm2.2085 <- pgGetRast (conn, "extreme_min_temp_30_years_canesm2_2071_2100")
emt.ccsm4.2085 <- pgGetRast (conn, "extreme_min_temp_30_years_CCSM4_2071_2100")
emt.HadGEM.2085 <- pgGetRast (conn, "extreme_min_temp_30_years_HadGEM2ES_2071_2100")
emt.2085 <- mean (emt.canesm2.2085, emt.ccsm4.2085, emt.HadGEM.2085) / 10
pgWriteRast (conn, "extreme_min_temp_30_years_avg_2071_2100", emt.2085, overwrite = TRUE)

ext.canesm2.2085 <- pgGetRast (conn, "extreme_max_temp_30_years_canesm2_2071_2100")
ext.ccsm4.2085 <- pgGetRast (conn, "extreme_max_temp_30_years_CCSM4_2071_2100")
ext.HadGEM.2085 <- pgGetRast (conn, "extreme_max_temp_30_years_HadGEM2ES_2071_2100")
ext.2085 <- mean (ext.canesm2.2085, ext.ccsm4.2085, ext.HadGEM.2085) / 10
pgWriteRast (conn, "extreme_max_temp_30_years_avg_2071_2100", ext.2085, overwrite = TRUE)

map.canesm2.2085 <- pgGetRast (conn, "mean_annual_precip_mm_canesm2_2071_2100")
map.ccsm4.2085 <- pgGetRast (conn, "mean_annual_precip_mm_CCSM4_2071_2100")
map.HadGEM.2085 <- pgGetRast (conn, "mean_annual_precip_mm_HadGEM2ES_2071_2100")
map.2085 <- mean (map.canesm2.2085, map.ccsm4.2085, map.HadGEM.2085)
pgWriteRast (conn, "mean_annual_precip_mm_avg_2071_2100", map.2085, overwrite = TRUE)

mat.canesm2.2085 <- pgGetRast (conn, "mean_annual_temp_C_canesm2_2071_2100")
mat.ccsm4.2085 <- pgGetRast (conn, "mean_annual_temp_C_CCSM4_2071_2100")
mat.HadGEM.2085 <- pgGetRast (conn, "mean_annual_temp_C_HadGEM2ES_2071_2100")
mat.2085 <- mean (mat.canesm2.2085, mat.ccsm4.2085, mat.HadGEM.2085) / 10
pgWriteRast (conn, "mean_annual_temp_C_avg_2071_2100", mat.2085, overwrite = TRUE)

mcmt.canesm2.2085 <- pgGetRast (conn, "mean_coldest_month_temp_canesm2_2071_2100")
mcmt.ccsm4.2085 <- pgGetRast (conn, "mean_coldest_month_temp_CCSM4_2071_2100")
mcmt.HadGEM.2085 <- pgGetRast (conn, "mean_coldest_month_temp_HadGEM2ES_2071_2100")
mcmt.2085 <- mean (mcmt.canesm2.2085, mcmt.ccsm4.2085, mcmt.HadGEM.2085) / 10
pgWriteRast (conn, "mean_coldest_month_temp_avg_2071_2100", mcmt.2085, overwrite = TRUE)

msp.canesm2.2085 <- pgGetRast (conn, "mean_may_to_sept_precip_mm_canesm2_2071_2100")
msp.ccsm4.2085 <- pgGetRast (conn, "mean_may_to_sept_precip_mm_CCSM4_2071_2100")
msp.HadGEM.2085 <- pgGetRast (conn, "mean_may_to_sept_precip_mm_HadGEM2ES_2071_2100")
msp.2085 <- mean (msp.canesm2.2085, msp.ccsm4.2085, msp.HadGEM.2085)
pgWriteRast (conn, "mean_may_to_sept_precip_mm_avg_2071_2100", msp.2085, overwrite = TRUE)

mwmt.canesm2.2085 <- pgGetRast (conn, "mean_warmest_month_temp_canesm2_2071_2100")
mwmt.ccsm4.2085 <- pgGetRast (conn, "mean_warmest_month_temp_CCSM4_2071_2100")
mwmt.HadGEM.2085 <- pgGetRast (conn, "mean_warmest_month_temp_HadGEM2ES_2071_2100")
mwmt.2085 <- mean (mwmt.canesm2.2085, mwmt.ccsm4.2085, mwmt.HadGEM.2085) / 10
pgWriteRast (conn, "mean_warmest_month_temp_avg_2071_2100", mwmt.2085, overwrite = TRUE)

nffd.canesm2.2085 <- pgGetRast (conn, "number_frost_free_days_canesm2_2071_2100")
nffd.ccsm4.2085 <- pgGetRast (conn, "number_frost_free_days_CCSM4_2071_2100")
nffd.HadGEM.2085 <- pgGetRast (conn, "number_frost_free_days_HadGEM2ES_2071_2100")
nffd.2085 <- mean (nffd.canesm2.2085, nffd.ccsm4.2085, nffd.HadGEM.2085)
pgWriteRast (conn, "number_frost_free_days_avg_2071_2100", nffd.2085, overwrite = TRUE)

pas.canesm2.2085 <- pgGetRast (conn, "precip_as_snow_Aug_to_July_canesm2_2071_2100")
pas.ccsm4.2085 <- pgGetRast (conn, "precip_as_snow_Aug_to_July_CCSM4_2071_2100")
pas.HadGEM.2085 <- pgGetRast (conn, "precip_as_snow_Aug_to_July_HadGEM2ES_2071_2100")
pas.2085 <- mean (pas.canesm2.2085, pas.ccsm4.2085, pas.HadGEM.2085)
pgWriteRast (conn, "precip_as_snow_Aug_to_July_avg_2071_2100", pas.2085, overwrite = TRUE)

rh.canesm2.2085 <- pgGetRast (conn, "relative_humidity_canesm2_2071_2100")
rh.ccsm4.2085 <- pgGetRast (conn, "relative_humidity_CCSM4_2071_2100")
rh.HadGEM.2085 <- pgGetRast (conn, "relative_humidity_HadGEM2ES_2071_2100")
rh.2085 <- mean (rh.canesm2.2085, rh.ccsm4.2085, rh.HadGEM.2085)
pgWriteRast (conn, "relative_humidity_avg_2071_2100", rh.2085, overwrite = TRUE)






#================================================================================
# Pre-process data frames for generating climate plots 
#===============================================================================




getDataQuery <- function (pgRaster, TSASelect) {
  conn <- dbConnect (dbDriver("PostgreSQL"), 
                     host = "",
                     user = "postgres",
                     dbname = "postgres",
                     password = "postgres",
                     port = "5432")
  on.exit (dbDisconnect (conn))
  raster::as.data.frame (
    raster::mask (
      pgGetRast (
        conn, name = "bec_2020s", 
        boundary = spTransform ( # queires the data as a bounding box
          as (TSASelect, "Spatial"), 
          CRS = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
      ),
      mask = spTransform ( # clips the data to the polygon
        as (TSASelect, "Spatial"), 
        CRS = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"),
      updateNA = T,
      updatevalue = -1 # pixels outside the mask get this value, and need to be removed from data 
    )
    %>%
      filter ([, 1] > -1) # somehow remove the -1 values from datframe...
  )
}
# del <- raster::as.data.frame (pgGetRast (conn, name = "bec_2020s", boundary = spTransform (as (tsaData, "Spatial"), CRS = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")))

t <- pgGetRast (conn, name = "bec_2020s", boundary = spTransform (as (tsaData, "Spatial"), CRS = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))
# need classes of raster
# workign on renderign BEC plots usign map_click as input to bound bec raster, 
# then convertign raster to dataframe 
# query uses the bounding-box though; need to 'clip' to polygon extent only
# raster:: mask fucntion


tsaData <- tsa.diss[tsa.diss$TSA_NUMB_1 == "Arrow TSA", ]
b <- raster::mask (
  pgGetRast (
    conn, name = "bec_2020s", 
    boundary = spTransform (
      as (tsaData, "Spatial"), 
      CRS = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
  ),
  mask = spTransform (
    as (tsaData, "Spatial"), 
    CRS = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
)


plot (b)
plot (spTransform (as (tsaData, "Spatial"), CRS = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"), add = T)


c <- 
  as.data.frame (
    raster::mask (
      pgGetRast (
        conn, name = "bec_2020s", 
        boundary = spTransform (
          as (tsaData, "Spatial"), 
          CRS = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
      ),
      mask = spTransform (
        as (tsaData, "Spatial"), 
        CRS = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"),
      updateNA = T,
      updatevalue = -1
    ) ) %>%
  dplyr::filter (
    colnames (
      as.data.frame (
        raster::mask (
          pgGetRast (
            conn, name = "bec_2020s", 
            boundary = spTransform (
              as (tsaData, "Spatial"), 
              CRS = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
          ),
          mask = spTransform (
            as (tsaData, "Spatial"), 
            CRS = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"),
          updateNA = T,
          updatevalue = -1
        ))
      > -1)) # how to get the row name here????

mean (c)
