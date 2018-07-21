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

tsa.diss <- st_read (conn, query = "SELECT * FROM fadm_tsa_dissolve_polygons")
sp.tsa.diss <- sf::as_Spatial (st_transform (tsa.diss, 4326))
names.TSA <- list (unique (tsa.diss$TSA_NUMB_1))

tsa.100Mile <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "100 Mile House TSA", ]
tsa.Arrow <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Arrow TSA", ]
tsa.Arrowsmith <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Arrowsmith TSA", ]
tsa.Boundary <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Boundary TSA", ]
tsa.Bulkley <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Bulkley TSA", ]
tsa.Cascadia <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Cascadia TSA", ]
tsa.Cassiar <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Cassiar TSA", ]
tsa.Cranbrook <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Cranbrook TSA", ]
tsa.DawsonCreek <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Dawson Creek TSA", ]
tsa.FortNelson <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Fort Nelson TSA", ]
tsa.FortSt.John <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Fort St. John TSA", ]
tsa.Fraser <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Fraser TSA", ]
tsa.GBRNorth <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "GBR North TSA", ]
tsa.GBRSouth <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "GBR South TSA", ]
tsa.Golden <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Golden TSA", ]
tsa.Invermere <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Invermere TSA", ]
tsa.Kalum <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Kalum TSA", ]
tsa.Kamloops <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Kamloops TSA", ]
tsa.Kingcome <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Kingcome TSA", ]
tsa.Kispiox <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Kispiox TSA", ]
tsa.KootenayLake <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Kootenay Lake TSA", ]
tsa.Lakes <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Lakes TSA", ]
tsa.Lillooet <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Lillooet TSA", ]
tsa.MacKenzie <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "MacKenzie TSA", ]
tsa.Merritt <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Merritt TSA", ]
tsa.MidCoast <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Mid Coast TSA", ]
tsa.Morice <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Morice TSA", ]
tsa.Nass <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Nass TSA", ]
tsa.NorthCoast <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "North Coast TSA", ]
tsa.NorthIsland <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "North Island TSA", ]
tsa.Okanagan <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Okanagan TSA", ]
tsa.Pacific <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Pacific TSA", ]
tsa.PrinceGeorge <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Prince George TSA", ]
tsa.QueenCharlotte <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Queen Charlotte TSA", ]
tsa.Quesnel <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Quesnel TSA", ]
tsa.Revelstoke <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Revelstoke TSA", ]
tsa.RobsonValley <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Robson Valley TSA", ]
tsa.Soo <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Soo TSA", ]
tsa.Strathcona <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Strathcona TSA", ]
tsa.SunshineCoast <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Sunshine Coast TSA", ]
tsa.WilliamsLake <- sp.tsa.diss[sp.tsa.diss$TSA_NUMB_1 == "Williams Lake TSA", ]


fxnExtractData <- function (rasterName, TSAName) {
   na.omit (
      raster::as.data.frame (
        raster::mask (
          pgGetRast (conn, name = rasterName, boundary = TSAName
          ), 
          mask = TSAName
        )
      )
    )  
}

#==================
# Current BEC Data 
#==================
bec.curr.100Mile <- fxnExtractData ("bec_current", tsa.100Mile)
bec.curr.Arrow <- fxnExtractData ("bec_current", tsa.Arrow)
bec.curr.Arrowsmith <- fxnExtractData ("bec_current", tsa.Arrowsmith)
bec.curr.Boundary <- fxnExtractData ("bec_current", tsa.Boundary)
bec.curr.Bulkley <- fxnExtractData ("bec_current", tsa.Bulkley)
bec.curr.Cascadia <- fxnExtractData ("bec_current", tsa.Cascadia)
bec.curr.Cassiar <- fxnExtractData ("bec_current", tsa.Cassiar)
bec.curr.Cranbrook <- fxnExtractData ("bec_current", tsa.Cranbrook)
bec.curr.DawsonCreek <- fxnExtractData ("bec_current", tsa.DawsonCreek)
bec.curr.FortNelson <- fxnExtractData ("bec_current", tsa.FortNelson)
bec.curr.FortSt.John <- fxnExtractData ("bec_current", tsa.FortSt.John)
bec.curr.Fraser <- fxnExtractData ("bec_current", tsa.Fraser)
bec.curr.GBRNorth <- fxnExtractData ("bec_current", tsa.GBRNorth)
bec.curr.GBRSouth <- fxnExtractData ("bec_current", tsa.GBRSouth)
bec.curr.Golden <- fxnExtractData ("bec_current", tsa.Golden)
bec.curr.Invermere <- fxnExtractData ("bec_current", tsa.Invermere)
bec.curr.Kalum <- fxnExtractData ("bec_current", tsa.Kalum)
bec.curr.Kamloops <- fxnExtractData ("bec_current", tsa.Kamloops)
bec.curr.Kingcome <- fxnExtractData ("bec_current", tsa.Kingcome)
bec.curr.Kispiox <- fxnExtractData ("bec_current", tsa.Kispiox)
bec.curr.KootenayLake <- fxnExtractData ("bec_current", tsa.KootenayLake)
bec.curr.Lakes <- fxnExtractData ("bec_current", tsa.Lakes)
bec.curr.Lillooet <- fxnExtractData ("bec_current", tsa.Lillooet)
bec.curr.MacKenzie <- fxnExtractData ("bec_current", tsa.MacKenzie)
bec.curr.Merritt <- fxnExtractData ("bec_current", tsa.Merritt)
bec.curr.MidCoast <- fxnExtractData ("bec_current", tsa.MidCoast)
bec.curr.Morice <- fxnExtractData ("bec_current", tsa.Morice)
bec.curr.Nass <- fxnExtractData ("bec_current", tsa.Nass)
bec.curr.NorthCoast <- fxnExtractData ("bec_current", tsa.NorthCoast)
bec.curr.NorthIsland <- fxnExtractData ("bec_current", tsa.NorthIsland)
bec.curr.Okanagan <- fxnExtractData ("bec_current", tsa.Okanagan)
bec.curr.Pacific <- fxnExtractData ("bec_current", tsa.Pacific)
bec.curr.PrinceGeorge <- fxnExtractData ("bec_current", tsa.PrinceGeorge)
bec.curr.QueenCharlotte <- fxnExtractData ("bec_current", tsa.QueenCharlotte)
bec.curr.Quesnel <- fxnExtractData ("bec_current", tsa.Quesnel)
bec.curr.Revelstoke <- fxnExtractData ("bec_current", tsa.Revelstoke)
bec.curr.RobsonValley <- fxnExtractData ("bec_current", tsa.RobsonValley)
bec.curr.Soo <- fxnExtractData ("bec_current", tsa.Soo)
bec.curr.Strathcona <- fxnExtractData ("bec_current", tsa.Strathcona)
bec.curr.SunshineCoast <- fxnExtractData ("bec_current", tsa.SunshineCoast)
bec.curr.WilliamsLake <- fxnExtractData ("bec_current", tsa.WilliamsLake)

bec.curr.100Mile$tsa <- "100 Mile House TSA"
bec.curr.Arrow$tsa <- "Arrow TSA"
bec.curr.Arrowsmith$tsa <- "Arrowsmith TSA"
bec.curr.Boundary$tsa <- "Boundary TSA" 
bec.curr.Bulkley$tsa <- "Bulkley TSA" 
bec.curr.Cascadia$tsa <- "Cascadia TSA"
bec.curr.Cassiar$tsa <- "Cassiar TSA"
bec.curr.Cranbrook$tsa <- "Cranbrook TSA"
bec.curr.DawsonCreek$tsa <- "Dawson Creek TSA"
bec.curr.FortNelson$tsa <- "Fort Nelson TSA"
bec.curr.FortSt.John$tsa <- "Fort St. John TSA"
bec.curr.Fraser$tsa <- "Fraser TSA"
bec.curr.GBRNorth$tsa <- "GBR North TSA"
bec.curr.GBRSouth$tsa <- "GBR South TSA"
bec.curr.Golden$tsa <- "Golden TSA"
bec.curr.Invermere$tsa <- "Invermere TSA"
bec.curr.Kalum$tsa <- "Kalum TSA"
bec.curr.Kamloops$tsa <- "Kamloops TSA"
bec.curr.Kingcome$tsa <- "Kingcome TSA"
bec.curr.Kispiox$tsa <- "Kispiox TSA"
bec.curr.KootenayLake$tsa <- "Kootenay Lake TSA"
bec.curr.Lakes$tsa <- "Lakes TSA"
bec.curr.Lillooet$tsa <- "Lillooet TSA"
bec.curr.MacKenzie$tsa <- "MacKenzie TSA"
bec.curr.Merritt$tsa <- "Merritt TSA"
bec.curr.MidCoast$tsa <- "Mid Coast TSA"
bec.curr.Morice$tsa <- "Morice TSA"
bec.curr.Nass$tsa <- "Nass TSA"
bec.curr.NorthCoast$tsa <- "North Coast TSA"
bec.curr.NorthIsland$tsa <- "North Island TSA"
bec.curr.Okanagan$tsa <- "Okanagan TSA"
bec.curr.Pacific$tsa <- "Pacific TSA"
bec.curr.PrinceGeorge$tsa <- "Prince George TSA"
bec.curr.QueenCharlotte$tsa <- "Queen Charlotte TSA"
bec.curr.Quesnel$tsa <- "Quesnel TSA"
bec.curr.Revelstoke$tsa <- "Revelstoke TSA"
bec.curr.RobsonValley$tsa <- "Robson Valley TSA"
bec.curr.Soo$tsa <- "Soo TSA"
bec.curr.Strathcona$tsa <- "Strathcona TSA"
bec.curr.SunshineCoast$tsa <- "Sunshine Coast TSA"
bec.curr.WilliamsLake$tsa <- "Williams Lake TSA"

bec.current <- rbind (bec.curr.100Mile, bec.curr.Arrow, bec.curr.Arrowsmith, bec.curr.Boundary,
                      bec.curr.Bulkley, bec.curr.Cascadia, bec.curr.Cassiar, bec.curr.Cranbrook,
                      bec.curr.DawsonCreek, bec.curr.FortNelson, bec.curr.FortSt.John, 
                      bec.curr.Fraser, bec.curr.GBRNorth, bec.curr.GBRSouth, bec.curr.Golden,
                      bec.curr.Invermere, bec.curr.Kalum, bec.curr.Kamloops, bec.curr.Kingcome,
                      bec.curr.Kispiox, bec.curr.KootenayLake, bec.curr.Lakes, bec.curr.Lillooet,
                      bec.curr.MacKenzie, bec.curr.Merritt, bec.curr.MidCoast, bec.curr.Morice,
                      bec.curr.Nass, bec.curr.NorthCoast, bec.curr.NorthIsland, bec.curr.Okanagan,
                      bec.curr.Pacific, bec.curr.PrinceGeorge, bec.curr.QueenCharlotte, 
                      bec.curr.Quesnel, bec.curr.Revelstoke, bec.curr.RobsonValley, 
                      bec.curr.Soo, bec.curr.Strathcona, bec.curr.SunshineCoast, bec.curr.WilliamsLake)

bec.current$year <- "2015"

bec.current$BEC_zone <- as.character (bec.current$BEC_zone)

bec.current$BEC_zone <- gsub ('\\<1\\>', 'CMA unp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<2\\>', 'BAFAunp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<3\\>', 'SWB vk', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<4\\>', 'BWBSvk', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<5\\>', 'SWB dk', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<6\\>', 'BWBSdk 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<7\\>', 'SWB un', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<8\\>', 'BWBSun', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<9\\>', 'ESSFwv', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<10\\>', 'SBS un', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<11\\>', 'SWB mk', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<12\\>', 'BWBSdk 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<13\\>', 'BWBSwk 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<14\\>', 'BWBSmw 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<15\\>', 'SWB mks', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<16\\>', 'BAFAun', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<17\\>', 'MH  un', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<18\\>', 'CWH wm', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<19\\>', 'ESSFmv 4', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<20\\>', 'ESSFmvp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<21\\>', 'BWBSwk 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<22\\>', 'ICH wc', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<23\\>', 'BWBSmw 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<24\\>', 'ESSFmc', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<25\\>', 'ESSFmcp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<26\\>', 'SBS mc 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<27\\>', 'ESSFmv 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<28\\>', 'ESSFwvp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<29\\>', 'ICH vc', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<30\\>', 'SBS mk 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<31\\>', 'ESSFwcp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<32\\>', 'ESSFwc 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<33\\>', 'ESSFwk 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<34\\>', 'SBS wk 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<35\\>', 'ICH mc 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<36\\>', 'SBS wk 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<37\\>', 'ESSFmv 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<38\\>', 'BWBSwk 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<39\\>', 'CMA un', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<40\\>', 'MH  mm 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<41\\>', 'MH  mmp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<42\\>', 'MH  mm 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<43\\>', 'SBS vk', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<44\\>', 'CWH ws 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<45\\>', 'ICH mc 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<46\\>', 'SBS mk 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<47\\>', 'CWH ws 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<48\\>', 'MH  wh 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<49\\>', 'CWH vh 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<50\\>', 'MH  whp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<51\\>', 'SBS wk 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<52\\>', 'SBS dk', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<53\\>', 'CWH vm 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<54\\>', 'CWH vm', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<55\\>', 'CWH vm 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<56\\>', 'SBS dw 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<57\\>', 'ESSFmv 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<58\\>', 'ESSFmk', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<59\\>', 'ESSFmkp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<60\\>', 'ICH vk 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<61\\>', 'CWH wh 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<62\\>', 'SBS mh', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<63\\>', 'CWH wh 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<64\\>', 'ICH wk 4', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<65\\>', 'MH  wh 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<66\\>', 'ESSFwk 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<67\\>', 'SBS mc 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<68\\>', 'ESSFmmp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<69\\>', 'IMA un', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<70\\>', 'ICH wk 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<71\\>', 'ESSFmm 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<72\\>', 'SBS mw', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<73\\>', 'SBS dw 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<74\\>', 'ICH mm', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<75\\>', 'SBS dw 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<76\\>', 'SBPSmk', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<77\\>', 'SBPSdc', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<78\\>', 'SBPSmc', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<79\\>', 'SBS dh 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<80\\>', 'ESSFwcw', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<81\\>', 'ESSFmm 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<82\\>', 'MS  xv', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<83\\>', 'ESSFxv 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<84\\>', 'SBS dh 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<85\\>', 'CWH ms 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<86\\>', 'ICH wk 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<87\\>', 'CWH ds 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<88\\>', 'ESSFxvp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<89\\>', 'SBS mc 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<90\\>', 'CWH vm 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<91\\>', 'ICH vk 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<92\\>', 'ESSFmw', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<93\\>', 'SBPSxc', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<94\\>', 'ESSFwc 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<95\\>', 'ICH wk 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<96\\>', 'ICH mk 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<97\\>', 'ESSFmmw', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<98\\>', 'IDF xm', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<99\\>', 'ESSFdkp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<100\\>', 'IDF dk 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<101\\>', 'ESSFdk 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<102\\>', 'IDF ww', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<103\\>', 'IDF dw', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<104\\>', 'IDF dk 4', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<105\\>', 'ICH mw 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<106\\>', 'MS  un', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<107\\>', 'MS  dc 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<108\\>', 'ESSFvcp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<109\\>', 'ICH mw 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<110\\>', 'ESSFvc', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<111\\>', 'ICH dw 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<112\\>', 'ICH dk', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<113\\>', 'BG  xw 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<114\\>', 'ESSFmwp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<115\\>', 'IDF mw 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<116\\>', 'ESSFdc 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<117\\>', 'SBS mm', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<118\\>', 'ESSFvcw', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<119\\>', 'BG  xh 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<120\\>', 'ICH mk 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<121\\>', 'IMA unp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<122\\>', 'ESSFxv 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<123\\>', 'ICH mk 4', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<124\\>', 'ESSFdcw', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<125\\>', 'MS  dm 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<126\\>', 'CWH ms 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<127\\>', 'ESSFdcp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<128\\>', 'MS  dk 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<129\\>', 'ESSFwm', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<130\\>', 'ESSFwmp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<131\\>', 'IDF dk 5', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<132\\>', 'MS  xk 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<133\\>', 'IDF xh 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<134\\>', 'MS  dv', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<135\\>', 'MS  xk 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<136\\>', 'CWH ds 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<137\\>', 'ESSFxc 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<138\\>', 'ESSFdku', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<139\\>', 'CWH vh 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<140\\>', 'ESSFdkw', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<141\\>', 'IDF xw', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<142\\>', 'ESSFwc 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<143\\>', 'ESSFwc 4', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<144\\>', 'ESSFxcp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<145\\>', 'IDF dk 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<146\\>', 'ESSFxcw', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<147\\>', 'ESSFxvw', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<148\\>', 'ESSFdvw', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<149\\>', 'ESSFdvp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<150\\>', 'MS  dc 3', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<151\\>', 'CWH dm', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<152\\>', 'ESSFdv 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<153\\>', 'CWH un', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<154\\>', 'ESSFxc 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<155\\>', 'IDF dk 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<156\\>', 'IDF dc', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<157\\>', 'ICH mw 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<158\\>', 'PP  xh 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<159\\>', 'BG  xh 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<160\\>', 'IDF xc', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<161\\>', 'MS  dc 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<162\\>', 'ESSFdv 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<163\\>', 'MS  mw 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<164\\>', 'IDF dm 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<165\\>', 'BG  xw 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<166\\>', 'IDF mw 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<167\\>', 'ESSFmw 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<168\\>', 'IDF ww 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<169\\>', 'ESSFmww', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<170\\>', 'IDF xk', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<171\\>', 'ICH mk 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<172\\>', 'IDF xh 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<173\\>', 'MS  dm 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<174\\>', 'CWH xm 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<175\\>', 'ESSFwmw', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<176\\>', 'ESSFdc 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<177\\>', 'CWH mm 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<178\\>', 'CWH mm 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<179\\>', 'ESSFdk 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<180\\>', 'MS  xk 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<181\\>', 'CWH xm 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<182\\>', 'IDF dm 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<183\\>', 'ICH dw 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<184\\>', 'MS  dk 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<185\\>', 'MS  dm 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<186\\>', 'ESSFdc 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<187\\>', 'ESSFmw 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<188\\>', 'PP  xh 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<189\\>', 'CDF mm', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<190\\>', 'MS  mw 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<191\\>', 'PP  dh 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<192\\>', 'ICH dm', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<193\\>', 'ESSFdmp', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<194\\>', 'ESSFdmw', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<195\\>', 'ESSFdm', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<196\\>', 'IDF un', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<197\\>', 'ESSFxc 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<198\\>', 'ICH dw 2', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<199\\>', 'ICH mw 4', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<200\\>', 'ESSFwc 5', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<201\\>', 'ESSFwc 6', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<202\\>', 'ICH xw', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<203\\>', 'BG  xh 1', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<204\\>', 'IDF xh 4', bec.current$BEC_zone)
bec.current$BEC_zone <- gsub ('\\<205\\>', 'PP  xh 3', bec.current$BEC_zone)

bec.current$BEC_zone <- as.factor (bec.current$BEC_zone)






#==================
# 2020 BEC Data 
#==================
bec.2020.100Mile <- fxnExtractData ("bec_2020s", tsa.100Mile)
bec.2020.Arrow <- fxnExtractData ("bec_2020s", tsa.Arrow)
bec.2020.Arrowsmith <- fxnExtractData ("bec_2020s", tsa.Arrowsmith)
bec.2020.Boundary <- fxnExtractData ("bec_2020s", tsa.Boundary)
bec.2020.Bulkley <- fxnExtractData ("bec_2020s", tsa.Bulkley)
bec.2020.Cascadia <- fxnExtractData ("bec_2020s", tsa.Cascadia)
bec.2020.Cassiar <- fxnExtractData ("bec_2020s", tsa.Cassiar)
bec.2020.Cranbrook <- fxnExtractData ("bec_2020s", tsa.Cranbrook)
bec.2020.DawsonCreek <- fxnExtractData ("bec_2020s", tsa.DawsonCreek)
bec.2020.FortNelson <- fxnExtractData ("bec_2020s", tsa.FortNelson)
bec.2020.FortSt.John <- fxnExtractData ("bec_2020s", tsa.FortSt.John)
bec.2020.Fraser <- fxnExtractData ("bec_2020s", tsa.Fraser)
bec.2020.GBRNorth <- fxnExtractData ("bec_2020s", tsa.GBRNorth)
bec.2020.GBRSouth <- fxnExtractData ("bec_2020s", tsa.GBRSouth)
bec.2020.Golden <- fxnExtractData ("bec_2020s", tsa.Golden)
bec.2020.Invermere <- fxnExtractData ("bec_2020s", tsa.Invermere)
bec.2020.Kalum <- fxnExtractData ("bec_2020s", tsa.Kalum)
bec.2020.Kamloops <- fxnExtractData ("bec_2020s", tsa.Kamloops)
bec.2020.Kingcome <- fxnExtractData ("bec_2020s", tsa.Kingcome)
bec.2020.Kispiox <- fxnExtractData ("bec_2020s", tsa.Kispiox)
bec.2020.KootenayLake <- fxnExtractData ("bec_2020s", tsa.KootenayLake)
bec.2020.Lakes <- fxnExtractData ("bec_2020s", tsa.Lakes)
bec.2020.Lillooet <- fxnExtractData ("bec_2020s", tsa.Lillooet)
bec.2020.MacKenzie <- fxnExtractData ("bec_2020s", tsa.MacKenzie)
bec.2020.Merritt <- fxnExtractData ("bec_2020s", tsa.Merritt)
bec.2020.MidCoast <- fxnExtractData ("bec_2020s", tsa.MidCoast)
bec.2020.Morice <- fxnExtractData ("bec_2020s", tsa.Morice)
bec.2020.Nass <- fxnExtractData ("bec_2020s", tsa.Nass)
bec.2020.NorthCoast <- fxnExtractData ("bec_2020s", tsa.NorthCoast)
bec.2020.NorthIsland <- fxnExtractData ("bec_2020s", tsa.NorthIsland)
bec.2020.Okanagan <- fxnExtractData ("bec_2020s", tsa.Okanagan)
bec.2020.Pacific <- fxnExtractData ("bec_2020s", tsa.Pacific)
bec.2020.PrinceGeorge <- fxnExtractData ("bec_2020s", tsa.PrinceGeorge)
bec.2020.QueenCharlotte <- fxnExtractData ("bec_2020s", tsa.QueenCharlotte)
bec.2020.Quesnel <- fxnExtractData ("bec_2020s", tsa.Quesnel)
bec.2020.Revelstoke <- fxnExtractData ("bec_2020s", tsa.Revelstoke)
bec.2020.RobsonValley <- fxnExtractData ("bec_2020s", tsa.RobsonValley)
bec.2020.Soo <- fxnExtractData ("bec_2020s", tsa.Soo)
bec.2020.Strathcona <- fxnExtractData ("bec_2020s", tsa.Strathcona)
bec.2020.SunshineCoast <- fxnExtractData ("bec_2020s", tsa.SunshineCoast)
bec.2020.WilliamsLake <- fxnExtractData ("bec_2020s", tsa.WilliamsLake)

bec.2020.100Mile$tsa <- "100 Mile House TSA"
bec.2020.Arrow$tsa <- "Arrow TSA"
bec.2020.Arrowsmith$tsa <- "Arrowsmith TSA"
bec.2020.Boundary$tsa <- "Boundary TSA" 
bec.2020.Bulkley$tsa <- "Bulkley TSA" 
bec.2020.Cascadia$tsa <- "Cascadia TSA"
bec.2020.Cassiar$tsa <- "Cassiar TSA"
bec.2020.Cranbrook$tsa <- "Cranbrook TSA"
bec.2020.DawsonCreek$tsa <- "Dawson Creek TSA"
bec.2020.FortNelson$tsa <- "Fort Nelson TSA"
bec.2020.FortSt.John$tsa <- "Fort St. John TSA"
bec.2020.Fraser$tsa <- "Fraser TSA"
bec.2020.GBRNorth$tsa <- "GBR North TSA"
bec.2020.GBRSouth$tsa <- "GBR South TSA"
bec.2020.Golden$tsa <- "Golden TSA"
bec.2020.Invermere$tsa <- "Invermere TSA"
bec.2020.Kalum$tsa <- "Kalum TSA"
bec.2020.Kamloops$tsa <- "Kamloops TSA"
bec.2020.Kingcome$tsa <- "Kingcome TSA"
bec.2020.Kispiox$tsa <- "Kispiox TSA"
bec.2020.KootenayLake$tsa <- "Kootenay Lake TSA"
bec.2020.Lakes$tsa <- "Lakes TSA"
bec.2020.Lillooet$tsa <- "Lillooet TSA"
bec.2020.MacKenzie$tsa <- "MacKenzie TSA"
bec.2020.Merritt$tsa <- "Merritt TSA"
bec.2020.MidCoast$tsa <- "Mid Coast TSA"
bec.2020.Morice$tsa <- "Morice TSA"
bec.2020.Nass$tsa <- "Nass TSA"
bec.2020.NorthCoast$tsa <- "North Coast TSA"
bec.2020.NorthIsland$tsa <- "North Island TSA"
bec.2020.Okanagan$tsa <- "Okanagan TSA"
bec.2020.Pacific$tsa <- "Pacific TSA"
bec.2020.PrinceGeorge$tsa <- "Prince George TSA"
bec.2020.QueenCharlotte$tsa <- "Queen Charlotte TSA"
bec.2020.Quesnel$tsa <- "Quesnel TSA"
bec.2020.Revelstoke$tsa <- "Revelstoke TSA"
bec.2020.RobsonValley$tsa <- "Robson Valley TSA"
bec.2020.Soo$tsa <- "Soo TSA"
bec.2020.Strathcona$tsa <- "Strathcona TSA"
bec.2020.SunshineCoast$tsa <- "Sunshine Coast TSA"
bec.2020.WilliamsLake$tsa <- "Williams Lake TSA"

bec.2020 <- rbind (bec.2020.100Mile, bec.2020.Arrow, bec.2020.Arrowsmith, bec.2020.Boundary,
                      bec.2020.Bulkley, bec.2020.Cascadia, bec.2020.Cassiar, bec.2020.Cranbrook,
                      bec.2020.DawsonCreek, bec.2020.FortNelson, bec.2020.FortSt.John, 
                      bec.2020.Fraser, bec.2020.GBRNorth, bec.2020.GBRSouth, bec.2020.Golden,
                      bec.2020.Invermere, bec.2020.Kalum, bec.2020.Kamloops, bec.2020.Kingcome,
                      bec.2020.Kispiox, bec.2020.KootenayLake, bec.2020.Lakes, bec.2020.Lillooet,
                      bec.2020.MacKenzie, bec.2020.Merritt, bec.2020.MidCoast, bec.2020.Morice,
                      bec.2020.Nass, bec.2020.NorthCoast, bec.2020.NorthIsland, bec.2020.Okanagan,
                      bec.2020.Pacific, bec.2020.PrinceGeorge, bec.2020.QueenCharlotte, 
                      bec.2020.Quesnel, bec.2020.Revelstoke, bec.2020.RobsonValley, 
                      bec.2020.Soo, bec.2020.Strathcona, bec.2020.SunshineCoast, bec.2020.WilliamsLake)

bec.2020$year <- "2025"

bec.2020$BEC_zone <- as.character (bec.2020$BEC_zone)

levels.bec.2020 <- data.frame (levels (bec.2020))

bec.2020$BEC_zone <- gsub ('\\<1\\>', 'CMA unp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<2\\>', 'BAFAunp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<3\\>', 'SWB vk', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<4\\>', 'BWBSvk', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<5\\>', 'SWB dk', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<6\\>', 'ESSFmv 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<7\\>', 'SBS wk 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<8\\>', 'BWBSdk 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<9\\>', 'SWB un', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<10\\>', 'ESSFwv', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<11\\>', 'SBS un', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<12\\>', 'SWB mk', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<13\\>', 'BWBSdk 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<14\\>', 'CWH wm', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<15\\>', 'ICH mc 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<16\\>', 'SBS wk 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<17\\>', 'ESSFwk 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<18\\>', 'SBS mk 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<19\\>', 'SBS mk 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<20\\>', 'MH  un', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<21\\>', 'ESSFwc 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<22\\>', 'ESSFmc', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<23\\>', 'BSBS mc 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<24\\>', 'ICH mc 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<25\\>', 'ICH vc', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<26\\>', 'ICH wc', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<27\\>', 'ESSFmv 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<28\\>', 'CWH ws 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<29\\>', 'CWH ws 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<30\\>', 'ESSFmcp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<31\\>', 'MH  mm 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<32\\>', 'CWH vm 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<33\\>', 'CWH ds 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<34\\>', 'CWH vm', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<35\\>', 'CMA un', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<36\\>', 'MH  mmp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<37\\>', 'CWH vh 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<38\\>', 'CWH wh 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<39\\>', 'CWH vh 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<40\\>', 'CWH vm 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<41\\>', 'CWH wh 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<42\\>', 'MH  wh 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<43\\>', 'MH  wh 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<44\\>', 'BWBSwk 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<45\\>', 'BWBSmw 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<46\\>', 'BWBSwk 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<47\\>', 'BWBSmw 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<48\\>', 'SWB mks', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<49\\>', 'BWBSwk 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<50\\>', 'BAFAun', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<51\\>', 'ESSFmv 4', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<52\\>', 'ESSFmvp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<53\\>', 'ESSFmm 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<54\\>', 'ESSFdk 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<55\\>', 'ESSFwcp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<56\\>', 'SBS wk 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<57\\>', 'MH  mm 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<58\\>', 'ESSFwvp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<59\\>', 'SBS dw 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<60\\>', 'ICH wk 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<61\\>', 'SBS vk', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<62\\>', 'IMA un', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<63\\>', 'ESSFmmp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<64\\>', 'ICH mw 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<65\\>', 'CWH ms 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<66\\>', 'SBS dk', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<67\\>', 'ICH vk 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<68\\>', 'ESSFwc 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<69\\>', 'ESSFvc', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<70\\>', 'ESSFwk 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<71\\>', 'CWH ds 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<72\\>', 'IDF mw 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<73\\>', 'ESSFmv 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<74\\>', 'ICH mw 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<75\\>', 'CWH ms 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<76\\>', 'ESSFmk', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<77\\>', 'IDF dk 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<78\\>', 'ESSFmkp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<79\\>', 'IDF xh 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<80\\>', 'SBS dw 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<81\\>', 'SBS mh', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<82\\>', 'ICH dw 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<83\\>', 'ICH mw 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<84\\>', 'SBS dw 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<85\\>', 'CWH dm', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<86\\>', 'SBS mw', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<87\\>', 'ICH wk 4', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<88\\>', 'ICH mm', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<89\\>', 'ICH vk 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<90\\>', 'SBS dh 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<91\\>', 'SBS mc 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<92\\>', 'SBPSmk', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<93\\>', 'ICH wk 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<94\\>', 'SBPSdc', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<95\\>', 'IDF dc', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<96\\>', 'SBPSmc', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<97\\>', 'IDF dk 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<98\\>', 'MS  xv', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<99\\>', 'IDF dw', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<100\\>', 'IDF ww', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<101\\>', 'ESSFmw', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<102\\>', 'SBPSxc', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<103\\>', 'IDF mw 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<104\\>', 'ESSFxv 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<105\\>', 'CWH vm 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<106\\>', 'ESSFxvp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<107\\>', 'ESSFdc 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<108\\>', 'IDF dk 4', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<109\\>', 'MS  dc 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<110\\>', 'SBS mc 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<111\\>', 'IDF xm', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<112\\>', 'IDF xc', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<113\\>', 'IDF ww 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<114\\>', 'MS  un', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<115\\>', 'ESSFdvp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<116\\>', 'IDF dm 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<117\\>', 'BG  xh 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<118\\>', 'BG  xw 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<119\\>', 'IDF dk 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<120\\>', 'ESSFmwp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<121\\>', 'IMA unp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<122\\>', 'BG  xh 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<123\\>', 'PP  xh 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<124\\>', 'MS  dm 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<125\\>', 'ESSFwc 4', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<126\\>', 'ICH wk 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<127\\>', 'ICH mk 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<128\\>', 'ICH dw 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<129\\>', 'ESSFmm 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<130\\>', 'ESSFwcw', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<131\\>', 'SBS dh 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<132\\>', 'ESSFwc 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<133\\>', 'MS  dm 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<134\\>', 'ESSFvcp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<135\\>', 'ESSFdk 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<136\\>', 'ICH mk 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<137\\>', 'MS  dk 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<138\\>', 'ICH dk', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<139\\>', 'MS  dk 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<140\\>', 'ESSFdkw', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<141\\>', 'ICH mk 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<142\\>', 'ESSFdkp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<143\\>', 'PP  dh 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<144\\>', 'SBS mm', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<145\\>', 'MS  dm 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<146\\>', 'ESSFwm', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<147\\>', 'ICH mk 4', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<148\\>', 'ESSFdc 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<149\\>', 'ESSFdcw', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<150\\>', 'IDF dk 5', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<151\\>', 'MS  dv', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<152\\>', 'CWH xm 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<153\\>', 'ESSFxv 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<154\\>', 'MS  xk 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<155\\>', 'PP  xh 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<156\\>', 'ESSFxc 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<157\\>', 'MS  dc 3', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<158\\>', 'ESSFdc 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<159\\>', 'ESSFdv 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<160\\>', 'IDF xh 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<161\\>', 'ESSFdv 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<162\\>', 'ESSFdvw', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<163\\>', 'ESSFxvw', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<164\\>', 'MS  dc 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<165\\>', 'ESSFmw 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<166\\>', 'MS  mw 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<167\\>', 'CWH xm 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<168\\>', 'ESSFmww', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<169\\>', 'CWH mm 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<170\\>', 'CWH mm 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<171\\>', 'CDF mm', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<172\\>', 'ESSFdcp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<173\\>', 'MS  xk 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<174\\>', 'IDF xw', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<175\\>', 'ESSFdku', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<176\\>', 'ESSFwmw', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<177\\>', 'MS  xk 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<178\\>', 'IDF xk', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<179\\>', 'ESSFdm', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<180\\>', 'ICH dm', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<181\\>', 'ESSFxcp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<182\\>', 'IDF dm 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<183\\>', 'ESSFwmp', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<184\\>', 'BG  xh 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<185\\>', 'BG  xw 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<186\\>', 'ESSFmw 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<187\\>', 'ESSFdmw', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<188\\>', 'ICH xw', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<189\\>', 'CDF mm', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<190\\>', 'ICH mw 4', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<191\\>', 'IDF xh 4', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<192\\>', 'ESSFxc 1', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<193\\>', 'ESSFwc 5', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<194\\>', 'ICH dw 2', bec.2020$BEC_zone)
bec.2020$BEC_zone <- gsub ('\\<195\\>', 'PP  xh 3', bec.2020$BEC_zone)

bec.2020$BEC_zone <- as.factor (bec.2020$BEC_zone)











bec.2050.100Mile <- fxnExtractData ("bec_2050s", tsa.100Mile)
bec.2080.100Mile <- fxnExtractData ("bec_2080s", tsa.100Mile)

bec.2020.100Mile$year <- "2025"
bec.2050.100Mile$year <- "2055"
bec.2080.100Mile$year <- "2085"
bec.2020.100Mile$bec <- as.character(bec.2020.100Mile$bec)
bec.2050.100Mile$bec <- as.character(bec.2050.100Mile$bec)
bec.2080.100Mile$bec <- as.character(bec.2080.100Mile$bec)


names (bec.2020.100Mile) [1] <- "bec"
names (bec.2050.100Mile) [1] <- "bec"
names (bec.2080.100Mile) [1] <- "bec"


bec.curr.levels [c (166:205), ]








bec.curr.levels <- data.frame (levels (bec.current))





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
