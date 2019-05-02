# Copyright 2019 Province of British Columbia
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
#  Script Name: 15_caribou_RSF_du8_summer.R
#  Script Version: 1.0
#  Script Purpose: Script to develop caribou RSF model for du8 and Summer.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 29 April 2019
#  R Version: 
#  R Packages: 
#  Data: 
#=================================

#==========================================
# TO TURN SCRIPT FOR DIFFERENT DUs and SEASONS:
# Find and Replace:
# 1. ew .s .s
# 2. du8, du7, du8, du9

options (scipen = 999)
require (dplyr)
require (ggplot2)
require (ggcorrplot)
require (car)
require (lme4)
require (raster)
require (rgdal)

#===========
# Datasets
#==========
# rsf.data <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data.csv")
rsf.data.terrain.water <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_terrain_water.csv", header = T, sep = ",")
rsf.data.forestry <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_forestry.csv", header = T, sep = "")
rsf.data.ag <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_agriculture.csv", header = T, sep = "")
rsf.data.mine <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_mine.csv", header = T, sep = "")
rsf.data.energy <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_energy.csv", header = T, sep = "")
rsf.data.ski <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_ski.csv", header = T, sep = "")
rsf.data.human.dist <- dplyr::full_join (dplyr::full_join (dplyr::full_join (dplyr::full_join (rsf.data.forestry, rsf.data.ag [, c (9:10)], by = "ptID"), rsf.data.mine [, c (9:10)], by = "ptID"), rsf.data.energy [, c (9:12)], by = "ptID"), rsf.data.ski [, c (9:10)], by = "ptID")
rsf.data.natural.dist <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_natural_disturbance.csv", header = T, sep = "")
rsf.data.climate.annual <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_climate_annual.csv", header = T, sep = "")
rsf.data.climate.winter <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_climate_winter.csv", header = T, sep = "")
rsf.data.climate.spring <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_climate_spring.csv", header = T, sep = "")
rsf.data.climate.summer <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_climate_summer.csv", header = T, sep = "")
rsf.data.climate.fall <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_climate_fall.csv", header = T, sep = "")
rsf.data.veg <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_veg.csv")

# load RSF data into postgres
connKyle <- dbConnect(drv = dbDriver ("PostgreSQL"), 
                     host = "DC052586", # Kyle's computer name
                      user = "Tyler",
                      dbname = "clus",
                      password = "tyler",
                      port = "5432")
conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")
dbWriteDataFrame (df = rsf.data.forestry, 
                  conn = connKyle, 
                  name = c ("public", "rsf_data_forestry"))
dbWriteDataFrame (df = rsf.data.ag, 
                  conn = connKyle, 
                  name = c ("public", "rsf_data_agriculture"))
dbWriteDataFrame (df = rsf.data.mine, 
                  conn = connKyle, 
                  name = c ("public", "rsf_data_mine"))
dbWriteDataFrame (df = rsf.data.energy, 
                  conn = connKyle, 
                  name = c ("public", "rsf_data_energy"))
dbWriteDataFrame (df = rsf.data.natural.dist, 
                  conn = connKyle, 
                  name = c ("public", "rsf_data_natural_disturbance"))
dbWriteDataFrame (df = rsf.data.human.dist, 
                  conn = connKyle, 
                  name = c ("public", "rsf_data_human_disturbance"))
dbWriteDataFrame (df = rsf.data.climate.annual, 
                  conn = connKyle, 
                  name = c ("public", "rsf_data_climate_annual"), overwrite = T)
dbWriteDataFrame (df = rsf.data.climate.winter, 
                  conn = connKyle, 
                  name = c ("public", "rsf_data_climate_winter"))
dbWriteDataFrame (df = rsf.data.climate.spring, 
                  conn = connKyle, 
                  name = c ("public", "rsf_data_climate_spring"))
dbWriteDataFrame (df = rsf.data.climate.summer, 
                  conn = connKyle, 
                  name = c ("public", "rsf_data_climate_summer"))
dbWriteDataFrame (df = rsf.data.climate.fall, 
                  conn = connKyle, 
                  name = c ("public", "rsf_data_climate_fall"))
dbDisconnect (connKyle) 


#########################
### A BIT OF CLEAN-UP ###
########################
# look for and remove NA data #
test <- rsf.data.terrain.water %>% filter (is.na (distance_to_lake))
rsf.data.terrain.water <- rsf.data.terrain.water %>% 
                              filter (!is.na (distance_to_lake))
rsf.data.terrain.water <- rsf.data.terrain.water %>% 
                            filter (!is.na (distance_to_watercourse))
rsf.data.terrain.water <- rsf.data.terrain.water %>% 
                            filter (!is.na (slope))
rsf.data.terrain.water <- rsf.data.terrain.water %>% 
                            filter (!is.na (elevation))
rsf.data.terrain.water <- rsf.data.terrain.water %>% 
                            filter (!is.na (easting))
rsf.data.terrain.water <- rsf.data.terrain.water %>% 
                            filter (!is.na (northing))
rsf.data.terrain.water$pttype <- as.factor (rsf.data.terrain.water$pttype)

rsf.data.human.dist$pttype <- as.factor (rsf.data.human.dist$pttype)

test <- rsf.data.climate.annual %>% filter (is.na (frost_free_start_julian))
rsf.data.climate.annual <- rsf.data.climate.annual %>% 
                            filter (!is.na (frost_free_start_julian))

test <- rsf.data.climate.winter %>% filter (is.na (winter_growing_degree_days))
rsf.data.climate.winter <- rsf.data.climate.winter %>% 
                               filter (!is.na (winter_growing_degree_days))

test <- rsf.data.veg %>% filter (is.na (bec_label))
rsf.data.veg <- rsf.data.veg %>% 
                  filter (!is.na (bec_label))

# RECLASS SOME OF THESE
# soil moisture
rsf.data.veg$vri_soil_moisture_name <- rsf.data.veg$vri_soil_moisture
rsf.data.veg$vri_soil_moisture_name <- recode (rsf.data.veg$vri_soil_moisture_name,
                                               "'0' = 'very xeric'")
rsf.data.veg$vri_soil_moisture_name <- recode (rsf.data.veg$vri_soil_moisture_name,
                                               "'1' = 'xeric'")
rsf.data.veg$vri_soil_moisture_name <- recode (rsf.data.veg$vri_soil_moisture_name,
                                               "'2' = 'subxeric'")
rsf.data.veg$vri_soil_moisture_name <- recode (rsf.data.veg$vri_soil_moisture_name,
                                               "'3' = 'submesic'")
rsf.data.veg$vri_soil_moisture_name <- recode (rsf.data.veg$vri_soil_moisture_name,
                                               "'4' = 'mesic'")
rsf.data.veg$vri_soil_moisture_name <- recode (rsf.data.veg$vri_soil_moisture_name,
                                               "'5' = 'subhygric'")
rsf.data.veg$vri_soil_moisture_name <- recode (rsf.data.veg$vri_soil_moisture_name,
                                               "'6' = 'hygric'")
rsf.data.veg$vri_soil_moisture_name <- recode (rsf.data.veg$vri_soil_moisture_name,
                                               "'7' = 'subhydric'")
rsf.data.veg$vri_soil_moisture_name <- recode (rsf.data.veg$vri_soil_moisture_name,
                                               "'8' = 'hydric'")
rsf.data.veg$vri_soil_moisture_name <- as.factor (rsf.data.veg$vri_soil_moisture_name)
rsf.data.veg$vri_soil_moisture_name  <- relevel (rsf.data.veg$vri_soil_moisture_name,
                                                 ref = "mesic")

# soil nutrient
rsf.data.veg$vri_soil_nutrient_name <- rsf.data.veg$vri_soil_nutrient
rsf.data.veg$vri_soil_nutrient_name <- recode (rsf.data.veg$vri_soil_nutrient_name,
                                               "'1' = 'very poor'")
rsf.data.veg$vri_soil_nutrient_name <- recode (rsf.data.veg$vri_soil_nutrient_name,
                                               "'2' = 'poor'")
rsf.data.veg$vri_soil_nutrient_name <- recode (rsf.data.veg$vri_soil_nutrient_name,
                                               "'3' = 'medium'")
rsf.data.veg$vri_soil_nutrient_name <- recode (rsf.data.veg$vri_soil_nutrient_name,
                                               "'4' = 'rich'")
rsf.data.veg$vri_soil_nutrient_name <- recode (rsf.data.veg$vri_soil_nutrient_name,
                                               "'5' = 'very rich'")
rsf.data.veg$vri_soil_nutrient_name <- recode (rsf.data.veg$vri_soil_nutrient_name,
                                               "'6' = 'ultra rich'")
rsf.data.veg$vri_soil_nutrient_name <- recode (rsf.data.veg$vri_soil_nutrient_name,
                                               "'0' = 'NA'")
rsf.data.veg$vri_soil_nutrient_name <- as.factor (rsf.data.veg$vri_soil_nutrient_name)
rsf.data.veg$vri_soil_nutrient_name  <- relevel (rsf.data.veg$vri_soil_nutrient_name,
                                                 ref = "medium")

# BCLCS class
rsf.data.veg$vri_bclcs_class <- rsf.data.veg$vri_bclcs_class_code
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'N' = 'Non-Vegetated'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'N-L' = 'Non-Vegetated'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'N-W' = 'Water'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A' = 'Alpine-NonTreed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A' = 'Alpine-NonTreed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-BL-CL' = 'Alpine-Lichen'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-BL-OP' = 'Alpine-Lichen'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-BM-CL' = 'Alpine-NonTreed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-BM-OP' = 'Alpine-NonTreed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-BY-CL' = 'Alpine-NonTreed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-BY-OP' = 'Alpine-NonTreed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-BY-OP' = 'Alpine-NonTreed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-HE-DE' = 'Alpine-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-HE-OP' = 'Alpine-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-HE-SP' = 'Alpine-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-HF-DE' = 'Alpine-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-HF-OP' = 'Alpine-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-HF-SP' = 'Alpine-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-HG-DE' = 'Alpine-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-HG-OP' = 'Alpine-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-HG-SP' = 'Alpine-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-SL-DE' = 'Alpine-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-SL-OP' = 'Alpine-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-SL-SP' = 'Alpine-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-ST-DE' = 'Alpine-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-ST-OP' = 'Alpine-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-A-ST-SP' = 'Alpine-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-SL-SP' = 'Upland-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U' = 'Upland-NonTreed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-BL-CL' = 'Upland-Lichen'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-BL-OP' = 'Upland-Lichen'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-BM-CL' = 'Upland-NonTreed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-BM-OP' = 'Upland-NonTreed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-BY-CL' = 'Upland-NonTreed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-BY-OP' = 'Upland-NonTreed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-HE-DE' = 'Upland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-HE-OP' = 'Upland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-HE-SP' = 'Upland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-HF-DE' = 'Upland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-HF-OP' = 'Upland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-HE-SP' = 'Upland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-HG-DE' = 'Upland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-HF-SP' = 'Upland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-HG-OP' = 'Upland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-HG-SP' = 'Upland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-SL-DE' = 'Upland-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-SL-OP' = 'Upland-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-SL-SP' = 'Upland-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-ST-DE' = 'Upland-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-ST-SP' = 'Upland-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-ST-OP' = 'Upland-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-U-TM-SP' = 'Upland-NonTreed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-BL-CL' = 'Wetland-Lichen'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-BM-CL' = 'Wetland-NonTreed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-BM-OP' = 'Wetland-NonTreed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-BY-CL' = 'Wetland-NonTreed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-BY-OP' = 'Wetland-NonTreed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-HE-DE' = 'Wetland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-HE-OP' = 'Wetland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-HE-SP' = 'Wetland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-HF-DE' = 'Wetland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-HF-OP' = 'Wetland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-HF-SP' = 'Wetland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-HG-DE' = 'Wetland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-HG-OP' = 'Wetland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-HG-SP' = 'Wetland-Herb'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-SL-DE' = 'Wetland-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-SL-OP' = 'Wetland-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-SL-SP' = 'Wetland-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-ST-DE' = 'Wetland-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-ST-OP' = 'Wetland-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-N-W-ST-SP' = 'Wetland-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T' = 'Unknown'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'U' = 'Unknown'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'' = 'Unknown'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-U-SL-SP' = 'Upland-Treed-Shrub'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-U-TB-DE' = 'Upland-Treed-Deciduous'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-U-TB-OP' = 'Upland-Treed-Deciduous'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-U-TB-SP' = 'Upland-Treed-Deciduous'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-U-TC-DE' = 'Upland-Treed-Conifer'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-U-TC-OP' = 'Upland-Treed-Conifer'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-U-TC-SP' = 'Upland-Treed-Conifer'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-U-TM-DE' = 'Upland-Treed-Mixed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-U-TM-OP' = 'Upland-Treed-Mixed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-U-TM-SP' = 'Upland-Treed-Mixed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-W-TB-DE' = 'Wetland-Treed-Deciduous'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-W-TB-OP' = 'Wetland-Treed-Deciduous'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-W-TB-SP' = 'Wetland-Treed-Deciduous'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-W-TC-DE' = 'Wetland-Treed-Conifer'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-W-TC-SP' = 'Wetland-Treed-Conifer'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-W-TC-OP' = 'Wetland-Treed-Conifer'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-W-TC-SP' = 'Wetland-Treed-Conifer'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-W-TM-DE' = 'Wetland-Treed-Mixed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-W-TM-OP' = 'Wetland-Treed-Mixed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-T-W-TM-SP' = 'Wetland-Treed-Mixed'")
rsf.data.veg$vri_bclcs_class <- recode (rsf.data.veg$vri_bclcs_class,
                                        "'V-U-TC-OP' = 'Upland-Treed-Conifer'")
rsf.data.veg$vri_bclcs_class <- as.factor (rsf.data.veg$vri_bclcs_class)
rsf.data.veg$vri_bclcs_class [is.na (rsf.data.veg$vri_bclcs_class)] <- "Unknown"
rsf.data.veg$vri_bclcs_class  <- relevel (rsf.data.veg$vri_bclcs_class,
                                          ref = "Upland-Treed-Conifer")
# PRIMARY TREE SPECIES
rsf.data.veg$vri_species_primary_name_reclass <- rsf.data.veg$vri_species_primary_name
rsf.data.veg$vri_species_primary_name_reclass <- as.character (rsf.data.veg$vri_species_primary_name_reclass)
rsf.data.veg$vri_species_primary_name_reclass <- rsf.data.veg$vri_species_primary_name_reclass %>% 
                                                      tidyr::replace_na ("Unknown")
rsf.data.veg$vri_species_primary_name_reclass <- as.factor (rsf.data.veg$vri_species_primary_name_reclass)

# noticed issue with eastness/northness data, need to make value = 0 if slope = 0
rsf.data.terrain.water$easting <- ifelse (rsf.data.terrain.water$slope == 0, 0, rsf.data.terrain.water$easting) 
rsf.data.terrain.water$northing <- ifelse (rsf.data.terrain.water$slope == 0, 0, rsf.data.terrain.water$northing) 

# Group road data into low-use types (resource roads)
rsf.data.human.dist <- dplyr::mutate (rsf.data.human.dist, distance_to_resource_road = pmin (distance_to_loose_road, 
                                                                                             distance_to_petroleum_road,
                                                                                             distance_to_rough_road,
                                                                                             distance_to_trim_transport_road,
                                                                                             distance_to_unknown_road))

########################################
### BUILD COMBO MODEL RSF DATASETS  ###
######################################
rsf.data.combo <- rsf.data.terrain.water [, c (1:10, 13:15)]
rm (rsf.data.terrain.water)
gc ()
rsf.data.combo <- dplyr::full_join (rsf.data.combo, 
                                    rsf.data.human.dist [, c (9:13, 26, 22)],
                                    by = "ptID")
rm (rsf.data.human.dist)
gc ()
rsf.data.combo <- dplyr::full_join (rsf.data.combo, 
                                    rsf.data.natural.dist [, c (9:14)],
                                    by = "ptID")
rm (rsf.data.natural.dist)
gc ()
rsf.data.combo <- dplyr::full_join (rsf.data.combo, 
                                    rsf.data.climate.annual [, c (9, 14, 15)],
                                    by = "ptID")
rm (rsf.data.climate.annual)
gc ()
rsf.data.combo <- dplyr::full_join (rsf.data.combo, 
                                    rsf.data.climate.summer [, c (9, 13, 16)],
                                    by = "ptID")
rm (rsf.data.climate.summer)
gc ()
rsf.data.combo <- dplyr::full_join (rsf.data.combo, 
                                    rsf.data.veg [, c (9, 10, 20, 22, 24, 26)],
                                    by = "ptID")
rm (rsf.data.veg)
gc ()

rsf.data.combo.du8.s <- rsf.data.combo %>%
                          dplyr::filter (du == "du8") %>%
                          dplyr::filter (season == "Summer")

write.csv (rsf.data.combo.du8.s, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du8_s.csv")


#######################
### FITTING MODELS ###
#####################

#=================================
# Terrain and Water Models
#=================================
rsf.data.terrain.water.du8.s <- rsf.data.terrain.water %>%
                                  dplyr::filter (du == "du8") %>%
                                  dplyr::filter (season == "Summer")

### OUTLIERS ###
ggplot (rsf.data.terrain.water.du8.s, aes (x = pttype, y = slope)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Summer Slope at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Slope")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du8_s_slope.png")
ggplot (rsf.data.terrain.water.du8.s, aes (x = pttype, y = distance_to_lake)) +
            geom_boxplot (outlier.colour = "red") +
            labs (title = "Boxplot DU8, Summer Distance to Lake at Available (0) and Used (1) Locations",
                  x = "Available (0) and Used (1) Locations",
                  y = "Distance to Lake")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du8_s_dist_lake.png")
ggplot (rsf.data.terrain.water.du8.s, aes (x = pttype, y = distance_to_watercourse)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer Distance to Watercourse at Available (0) and Used (1) 
        Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Watercourse")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du8_s_dist_watercourse.png")
ggplot (rsf.data.terrain.water.du8.s, aes (x = pttype, y = easting)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer Eastness at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Eastness")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du8_s_east.png")
ggplot (rsf.data.terrain.water.du8.s, aes (x = pttype, y = northing)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer Northness at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Eastness")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du8_s_north.png")

### HISTOGRAMS ###
ggplot (rsf.data.terrain.water.du8.s, aes (x = slope, fill = pttype)) + 
          geom_histogram (position = "dodge", binwidth = 5) +
          labs (title = "Histogram DU8, Summer Slope at Available (0) and Used (1) Locations",
                x = "Slope",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du8_s_slope.png")
ggplot (rsf.data.terrain.water.du8.s, aes (x = distance_to_lake, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 200) +
        labs (title = "Histogram DU8, Summer Distance to Lake at Available (0) and Used (1) Locations",
              x = "Distance to Lake",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du8_s_dist_lake.png")
ggplot (rsf.data.terrain.water.du8.s, aes (x = distance_to_watercourse, fill = pttype)) + 
          geom_histogram (position = "dodge", binwidth = 200) +
          labs (title = "Histogram DU8, Summer Distance to Watercourse at Available (0) and Used (1) 
                Locations",
                x = "Distance to Watercourse",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du8_s_dist_watercourse.png")
ggplot (rsf.data.terrain.water.du8.s, aes (x = elevation, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 50) +
  labs (title = "Histogram DU8, Summer Elevation at Available (0) and Used (1) Locations",
        x = "Elevation",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du8_s_elevation.png")
ggplot (rsf.data.terrain.water.du8.s, aes (x = easting, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 0.25) +
  labs (title = "Histogram DU8, Summer Eastness at Available (0) and Used (1) Locations",
        x = "Eastness",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du8_s_east.png")
ggplot (rsf.data.terrain.water.du8.s, aes (x = northing, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 0.25) +
  labs (title = "Histogram DU8, Summer Northness at Available (0) and Used (1) Locations",
        x = "Northness",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du8_s_north.png")

### CORRELATION ###
corr.terrain.water.du8.s <- rsf.data.terrain.water.du8.s [c (10:15)]
corr.terrain.water.du8.s <- round (cor (corr.terrain.water.du8.s, method = "spearman"), 3)
ggcorrplot (corr.terrain.water.du8.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Terrain and Water Resource Selection Function Model
            Covariate Correlations for DU8, Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_terrain_water_du8_s.png")

### VIF ###
glm.terrain.du8.s <- glm (pttype ~ elevation + slope + distance_to_lake + distance_to_watercourse, 
                            data = rsf.data.terrain.water.du8.s,
                            family = binomial (link = 'logit'))
car::vif (glm.terrain.du8.s)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

### Generalized Linear Mixed Models (GLMMs) ###
# standardize covariates  (helps with model convergence)
rsf.data.terrain.water.du8.s$std.elevation <- (rsf.data.terrain.water.du8.s$elevation - 
                                               mean (rsf.data.terrain.water.du8.s$elevation)) / 
                                               sd (rsf.data.terrain.water.du8.s$elevation)
rsf.data.terrain.water.du8.s$std.slope <- (rsf.data.terrain.water.du8.s$slope - 
                                           mean (rsf.data.terrain.water.du8.s$slope)) / 
                                           sd (rsf.data.terrain.water.du8.s$slope)
rsf.data.terrain.water.du8.s$std.distance_to_lake <- (rsf.data.terrain.water.du8.s$distance_to_lake - 
                                                      mean (rsf.data.terrain.water.du8.s$distance_to_lake)) / 
                                                      sd (rsf.data.terrain.water.du8.s$distance_to_lake)
rsf.data.terrain.water.du8.s$std.distance_to_watercourse <- (rsf.data.terrain.water.du8.s$distance_to_watercourse - 
                                                             mean (rsf.data.terrain.water.du8.s$distance_to_watercourse)) / 
                                                             sd (rsf.data.terrain.water.du8.s$distance_to_watercourse)

## SLOPE ##
model.lme4.du8.s.slope <- glmer (pttype ~ std.slope + (1 | uniqueID), 
                                   data = rsf.data.terrain.water.du8.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# AIC
table.aic [1, 1] <- "DU8"
table.aic [1, 2] <- "Summer"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "Slope"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du8.s.slope)

## DISTANCE TO LAKE ##
model.lme4.du8.s.lake <- glmer (pttype ~ std.distance_to_lake + (1 | uniqueID), 
                                  data = rsf.data.terrain.water.du8.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
# AIC
table.aic [2, 1] <- "DU8"
table.aic [2, 2] <- "Summer"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "Dist. to Lake"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du8.s.lake)

## DISTANCE TO WATERCOURSE ##
model.lme4.du8.s.wc <- glmer (pttype ~ std.distance_to_watercourse  + 
                                          (1 | uniqueID), 
                                 data = rsf.data.terrain.water.du8.s, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [3, 1] <- "DU8"
table.aic [3, 2] <- "Summer"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "Dist. to Watercourse"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du8.s.wc)

## ELEVATION ##
model.lme4.du8.s.elev <- glmer (pttype ~ std.elevation  + 
                                           (1 | uniqueID), 
                                 data = rsf.data.terrain.water.du8.s, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [4, 1] <- "DU8"
table.aic [4, 2] <- "Summer"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "Elevation"
table.aic [4, 5] <- "(1 | UniqueID)"
table.aic [4, 6] <-  AIC (model.lme4.du8.s.elev)

## SLOPE AND DISTANCE TO LAKE ##
model.lme4.du8.s.slope.lake <- update (model.lme4.du8.s.slope,
                                         . ~ . + std.distance_to_lake) 
# AIC
table.aic [5, 1] <- "DU8"
table.aic [5, 2] <- "Summer"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "Slope, Dist. to Lake"
table.aic [5, 5] <- "(1 | UniqueID)"
table.aic [5, 6] <-  AIC (model.lme4.du8.s.slope.lake) 

## SLOPE AND DISTANCE TO WATERCOURSE ##
model.lme4.du8.s.slope.water <- update (model.lme4.du8.s.slope,
                                         . ~ . + std.distance_to_watercourse) 
# AIC
table.aic [6, 1] <- "DU8"
table.aic [6, 2] <- "Summer"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "Slope, Dist. to Watercourse"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <-  AIC (model.lme4.du8.s.slope.water) 

## SLOPE AND ELEVATION ##
model.lme4.du8.s.slope.elev <- update (model.lme4.du8.s.slope,
                                         . ~ . + std.elevation) 
# AIC
table.aic [7, 1] <- "DU8"
table.aic [7, 2] <- "Summer"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "Slope, Elevation"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du8.s.slope.elev) 

## DISTANCE TO LAKE AND WATERCOURSE ##
model.lme4.du8.s.lake.water <- update (model.lme4.du8.s.lake,
                                        . ~ . + std.distance_to_watercourse)
# AIC
table.aic [8, 1] <- "DU8"
table.aic [8, 2] <- "Summer"
table.aic [8, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [8, 4] <- "Dist. to Lake, Dist. to Watercourse"
table.aic [8, 5] <- "(1 | UniqueID)"
table.aic [8, 6] <-  AIC (model.lme4.du8.s.lake.water)

## DISTANCE TO LAKE AND ELEVATION ##
model.lme4.du8.s.lake.elev <- update (model.lme4.du8.s.lake,
                                        . ~ . + std.elevation)
# AIC
table.aic [9, 1] <- "DU8"
table.aic [9, 2] <- "Summer"
table.aic [9, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [9, 4] <- "Dist. to Lake, Elevation"
table.aic [9, 5] <- "(1 | UniqueID)"
table.aic [9, 6] <-  AIC (model.lme4.du8.s.lake.elev)

## DISTANCE TO WATER AND ELEVATION ##
model.lme4.du8.s.water.elev <- update (model.lme4.du8.s.wc,
                                       . ~ . + std.elevation)
# AIC
table.aic [10, 1] <- "DU8"
table.aic [10, 2] <- "Summer"
table.aic [10, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [10, 4] <- "Dist. to Watercourse, Elevation"
table.aic [10, 5] <- "(1 | UniqueID)"
table.aic [10, 6] <-  AIC (model.lme4.du8.s.water.elev)

## SLOPE, DISTANCE TO LAKE AND DISTANCE TO WATERCOURSE ##
model.lme4.du8.s.slope.lake.wc <- update (model.lme4.du8.s.slope.lake,
                                            . ~ . + std.distance_to_watercourse) 
# AIC
table.aic [11, 1] <- "DU8"
table.aic [11, 2] <- "Summer"
table.aic [11, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [11, 4] <- "Slope, Dist. to Lake, Dist. to Watercourse"
table.aic [11, 5] <- "(1 | UniqueID)"
table.aic [11, 6] <-  AIC (model.lme4.du8.s.slope.lake.wc) 

## SLOPE, DISTANCE TO LAKE AND ELEVATION ##
model.lme4.du8.s.slope.lake.elev <- update (model.lme4.du8.s.slope.lake,
                                              . ~ . + std.elevation) 
# AIC
table.aic [12, 1] <- "DU8"
table.aic [12, 2] <- "Summer"
table.aic [12, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [12, 4] <- "Slope, Dist. to Lake, Elevation"
table.aic [12, 5] <- "(1 | UniqueID)"
table.aic [12, 6] <-  AIC (model.lme4.du8.s.slope.lake.elev) 

## SLOPE, DISTANCE TO WATERCOURSE AND ELEVATION ##
model.lme4.du8.s.slope.water.elev <- update (model.lme4.du8.s.slope.water,
                                              . ~ . + std.elevation) 
# AIC
table.aic [13, 1] <- "DU8"
table.aic [13, 2] <- "Summer"
table.aic [13, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [13, 4] <- "Slope, Dist. to Watercourse, Elevation"
table.aic [13, 5] <- "(1 | UniqueID)"
table.aic [13, 6] <-  AIC (model.lme4.du8.s.slope.water.elev) 

## DISTANCE TO LAKE, WATERCOURSE AND ELEVATION ##
model.lme4.du8.s.lake.water.elev <- update (model.lme4.du8.s.lake.water,
                                              . ~ . + std.elevation) 
# AIC
table.aic [14, 1] <- "DU8"
table.aic [14, 2] <- "Summer"
table.aic [14, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [14, 4] <- "Dist. to Lake, Dist. to Watercourse, Elevation"
table.aic [14, 5] <- "(1 | UniqueID)"
table.aic [14, 6] <-  AIC (model.lme4.du8.s.lake.water.elev) 

## SLOPE, DISTANCE TO LAKE, WATERCOURSE AND ELEVATION ##
model.lme4.du8.s.slope.lake.water.elev <- update (model.lme4.du8.s.slope.lake.wc,
                                                    . ~ . + std.elevation) 
# AIC
table.aic [15, 1] <- "DU8"
table.aic [15, 2] <- "Summer"
table.aic [15, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [15, 4] <- "Slope, Dist. to Lake, Dist. to Watercourse, Elevation"
table.aic [15, 5] <- "(1 | UniqueID)"
table.aic [15, 6] <-  AIC (model.lme4.du8.s.slope.lake.water.elev) 

## AIC comparison of MODELS ## 
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:15, 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:15, 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:15, 6])))),
                    (exp (-0.5 * (table.aic [4, 6] - min (table.aic [1:15, 6])))),
                    (exp (-0.5 * (table.aic [5, 6] - min (table.aic [1:15, 6])))),
                    (exp (-0.5 * (table.aic [6, 6] - min (table.aic [1:15, 6])))),
                    (exp (-0.5 * (table.aic [7, 6] - min (table.aic [1:15, 6])))),
                    (exp (-0.5 * (table.aic [8, 6] - min (table.aic [1:15, 6])))),
                    (exp (-0.5 * (table.aic [9, 6] - min (table.aic [1:15, 6])))),
                    (exp (-0.5 * (table.aic [10, 6] - min (table.aic [1:15, 6])))),
                    (exp (-0.5 * (table.aic [11, 6] - min (table.aic [1:15, 6])))),
                    (exp (-0.5 * (table.aic [12, 6] - min (table.aic [1:15, 6])))),
                    (exp (-0.5 * (table.aic [13, 6] - min (table.aic [1:15, 6])))),
                    (exp (-0.5 * (table.aic [14, 6] - min (table.aic [1:15, 6])))),
                    (exp (-0.5 * (table.aic [15, 6] - min (table.aic [1:15, 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:15, 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:15, 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:15, 6])))) / sum (list.aic.like), 3)
table.aic [4, 7] <- round ((exp (-0.5 * (table.aic [4, 6] - min (table.aic [1:15, 6])))) / sum (list.aic.like), 3)
table.aic [5, 7] <- round ((exp (-0.5 * (table.aic [5, 6] - min (table.aic [1:15, 6])))) / sum (list.aic.like), 3)
table.aic [6, 7] <- round ((exp (-0.5 * (table.aic [6, 6] - min (table.aic [1:15, 6])))) / sum (list.aic.like), 3)
table.aic [7, 7] <- round ((exp (-0.5 * (table.aic [7, 6] - min (table.aic [1:15, 6])))) / sum (list.aic.like), 3)
table.aic [8, 7] <- round ((exp (-0.5 * (table.aic [8, 6] - min (table.aic [1:15, 6])))) / sum (list.aic.like), 3)
table.aic [9, 7] <- round ((exp (-0.5 * (table.aic [9, 6] - min (table.aic [1:15, 6])))) / sum (list.aic.like), 3)
table.aic [10, 7] <- round ((exp (-0.5 * (table.aic [10, 6] - min (table.aic [1:15, 6])))) / sum (list.aic.like), 3)
table.aic [11, 7] <- round ((exp (-0.5 * (table.aic [11, 6] - min (table.aic [1:15, 6])))) / sum (list.aic.like), 3)
table.aic [12, 7] <- round ((exp (-0.5 * (table.aic [12, 6] - min (table.aic [1:15, 6])))) / sum (list.aic.like), 3)
table.aic [13, 7] <- round ((exp (-0.5 * (table.aic [13, 6] - min (table.aic [1:15, 6])))) / sum (list.aic.like), 3)
table.aic [14, 7] <- round ((exp (-0.5 * (table.aic [14, 6] - min (table.aic [1:15, 6])))) / sum (list.aic.like), 3)
table.aic [15, 7] <- round ((exp (-0.5 * (table.aic [15, 6] - min (table.aic [1:15, 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\summer\\table_aic_terrain_water.csv", sep = ",")

#=================================
# Human Disturbance Models
#=================================
rsf.data.human.dist.du8.s <- rsf.data.human.dist %>%
                                    dplyr::filter (du == "du8") %>%
                                    dplyr::filter (season == "Summer")
rsf.data.human.dist.du8.s$pttype <- as.factor (rsf.data.human.dist.du8.s$pttype)
### OUTLIERS ###
ggplot (rsf.data.human.dist.du8.s, aes (x = pttype, y = distance_to_cut_1to4yo)) +
        geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer Distance to Cutblocks 1 to 4 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_s_distcut1to4.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = pttype, y = distance_to_cut_5to9yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer Distance to Cutblocks 5 to 9 Years Old\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_s_distcut5to9.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = pttype, y = distance_to_cut_10to29yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer Distance to Cutblocks 10 to 29 Years Old\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_s_distcut10to29.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = pttype, y = distance_to_cut_30orOveryo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer Distance to Cutblocks Over 30 Years Old\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_s_distcutover30.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = pttype, y = distance_to_paved_road)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer Distance to Paved Road\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Paved Road")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_s_dist_pvd_rd.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = pttype, y = distance_to_resource_road)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer Distance to Resource Road\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Resource Road")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_s_dist_resource_rd.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = pttype, y = distance_to_agriculture)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer Distance to Agriculture\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Agriculture")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_s_dist_ag.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = pttype, y = distance_to_mines)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer Distance to Mine\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Mine")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_s_dist_mine.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = pttype, y = distance_to_pipeline)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer Distance to Pipeline\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Pipeline")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_s_dist_pipe.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = pttype, y = distance_to_wells)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer Distance to Well\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Well")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_s_dist_well.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = pttype, y = distance_to_ski_hill)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer Distance to Ski Hill\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Ski Hill")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_s_dist_ski.png")

### HISTOGRAMS ###
ggplot (rsf.data.human.dist.du8.s, aes (x = distance_to_cut_1to4yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 500) +
  labs (title = "Histogram DU8, Summer Distance to Cutblock 1 to 4 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Distance to Cutblock",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_s_dist_cut_1to4.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = distance_to_cut_5to9yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 500) +
  labs (title = "Histogram DU8, Summer Distance to Cutblock 5 to 9 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Distance to Cutblock",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_s_dist_cut_5to9.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = distance_to_cut_10to29yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 500) +
  labs (title = "Histogram DU8, Summer Distance to Cutblock 10 to 29 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Distance to Cutblock",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_s_dist_cut_10to29.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = distance_to_cut_30orOveryo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 500) +
  labs (title = "Histogram DU8, Summer Distance to Cutblock Over 30 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Distance to Cutblock",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_s_dist_cut_over30.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = distance_to_paved_road, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU8, Summer Distance to Paved Road\
                at Available (0) and Used (1) Locations",
        x = "Distance to Paved Road",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_s_dist_pvd_rd.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = distance_to_resource_road, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU8, Summer Distance to Resource Road\
                  at Available (0) and Used (1) Locations",
        x = "Distance to Resource Road",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_s_dist_res_rd.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = distance_to_agriculture, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 500) +
  labs (title = "Histogram DU8, Summer Distance to Agriculture\
                  at Available (0) and Used (1) Locations",
        x = "Distance to Agriculture",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_s_dist_ag.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = distance_to_mines, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 500) +
  labs (title = "Histogram DU8, Summer Distance to Mine at Available (0) and Used (1) Locations",
        x = "Distance to Mine",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_s_dist_mine.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = distance_to_pipeline, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 500) +
  labs (title = "Histogram DU8, Summer Distance to Pipeline at\
                 Available (0) and Used (1) Locations",
        x = "Distance to Pipeline",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_s_dist_pipe.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = distance_to_wells, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 500) +
  labs (title = "Histogram DU8, Summer Distance to Well at\
                 Available (0) and Used (1) Locations",
        x = "Distance to Pipeline",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_s_dist_well.png")
ggplot (rsf.data.human.dist.du8.s, aes (x = distance_to_ski_hill, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 1000) +
  labs (title = "Histogram DU8, Summer Distance to Ski Hill at\
                 Available (0) and Used (1) Locations",
        x = "Distance to Ski Hill",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_s_dist_ski_hill.png")

### CORRELATION ###
corr.human.dist.du8.s <- rsf.data.human.dist.du8.s [c (10:14, 26, 20:22, 24)]
corr.human.dist.du8.s <- round (cor (corr.human.dist.du8.s, method = "spearman"), 3)
ggcorrplot (corr.human.dist.du8.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Human Disturbance Resource Selection Function Model
            Covariate Correlations for DU8, Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_human_dist_du8_s.png")

### VIF ###
glm.human.du8.s <- glm (pttype ~ distance_to_cut_1to4yo + 
                                  distance_to_cut_5to9yo + 
                                  distance_to_cut_10to29yo + 
                                  distance_to_cut_30orOveryo +
                                  distance_to_paved_road + 
                                  distance_to_resource_road + 
                                  distance_to_pipeline +
                                  distance_to_agriculture,  
                           data = rsf.data.human.dist.du8.s,
                           family = binomial (link = 'logit'))
car::vif (glm.human.du8.s)

### Build an AIC and AUC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

##############################################
### Generalized Linear Mixed Models (GLMMs) #
############################################
# standardize covariates  (helps with model convergence)
rsf.data.human.dist.du8.s$std.distance_to_cut_1to4yo <- (rsf.data.human.dist.du8.s$distance_to_cut_1to4yo - mean (rsf.data.human.dist.du8.s$distance_to_cut_1to4yo)) / sd (rsf.data.human.dist.du8.s$distance_to_cut_1to4yo)
rsf.data.human.dist.du8.s$std.distance_to_cut_5to9yo <- (rsf.data.human.dist.du8.s$distance_to_cut_5to9yo - mean (rsf.data.human.dist.du8.s$distance_to_cut_5to9yo)) / sd (rsf.data.human.dist.du8.s$distance_to_cut_5to9yo)
rsf.data.human.dist.du8.s$std.distance_to_cut_10to29yo <- (rsf.data.human.dist.du8.s$distance_to_cut_10to29yo - mean (rsf.data.human.dist.du8.s$distance_to_cut_10to29yo)) / sd (rsf.data.human.dist.du8.s$distance_to_cut_10to29yo)
rsf.data.human.dist.du8.s$std.distance_to_cut_30orOveryo <- (rsf.data.human.dist.du8.s$distance_to_cut_30orOveryo - mean (rsf.data.human.dist.du8.s$distance_to_cut_30orOveryo)) / sd (rsf.data.human.dist.du8.s$distance_to_cut_30orOveryo)
rsf.data.human.dist.du8.s$std.distance_to_paved_road <- (rsf.data.human.dist.du8.s$distance_to_paved_road - mean (rsf.data.human.dist.du8.s$distance_to_paved_road)) / sd (rsf.data.human.dist.du8.s$distance_to_paved_road)
rsf.data.human.dist.du8.s$std.distance_to_resource_road <- (rsf.data.human.dist.du8.s$distance_to_resource_road - mean (rsf.data.human.dist.du8.s$distance_to_resource_road)) / sd (rsf.data.human.dist.du8.s$distance_to_resource_road)
# rsf.data.human.dist.du8.s$std.distance_to_mines <- (rsf.data.human.dist.du8.s$distance_to_mines - mean (rsf.data.human.dist.du8.s$distance_to_mines)) / sd (rsf.data.human.dist.du8.s$distance_to_mines)
rsf.data.human.dist.du8.s$std.distance_to_pipeline <- (rsf.data.human.dist.du8.s$distance_to_pipeline - mean (rsf.data.human.dist.du8.s$distance_to_pipeline)) / sd (rsf.data.human.dist.du8.s$distance_to_pipeline)
rsf.data.human.dist.du8.s$std.distance_to_agriculture <- (rsf.data.human.dist.du8.s$distance_to_agriculture - mean (rsf.data.human.dist.du8.s$distance_to_agriculture)) / sd (rsf.data.human.dist.du8.s$distance_to_agriculture)

## DISTANCE TO CUTBLOCK ##
model.lme4.du8.s.cutblock <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                              std.distance_to_cut_5to9yo + 
                                              std.distance_to_cut_10to29yo + 
                                              std.distance_to_cut_30orOveryo + 
                                              (1 | uniqueID), 
                                      data = rsf.data.human.dist.du8.s, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [1, 1] <- "DU8"
table.aic [1, 2] <- "Summer"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "DC1to4, DC5to9, DC10to29, DCover30"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du8.s.cutblock)

## DISTANCE TO ROAD ##
model.lme4.du8.s.road <- glmer (pttype ~ std.distance_to_resource_road + 
                                          (1 | uniqueID), 
                                 data = rsf.data.human.dist.du8.s, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [2, 1] <- "DU8"
table.aic [2, 2] <- "Summer"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "DRR"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du8.s.road)

## DISTANCE TO PIPELINE ##
model.lme4.du8.s.pipe <- glmer (pttype ~ std.distance_to_pipeline + 
                                          (1 | uniqueID), 
                                 data = rsf.data.human.dist.du8.s, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [3, 1] <- "DU8"
table.aic [3, 2] <- "Summer"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "DPipe"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du8.s.pipe)

## DISTANCE TO CUTBLOCK and DISTANCE TO ROAD ##
model.lme4.du8.s.cut.road <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                              std.distance_to_cut_5to9yo + 
                                              std.distance_to_cut_10to29yo + 
                                              std.distance_to_cut_30orOveryo + 
                                              std.distance_to_resource_road +
                                              (1 | uniqueID), 
                                     data = rsf.data.human.dist.du8.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [4, 1] <- "DU8"
table.aic [4, 2] <- "Summer"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DRR"
table.aic [4, 5] <- "(1 | UniqueID)"
table.aic [4, 6] <-  AIC (model.lme4.du8.s.cut.road)

## DISTANCE TO CUTBLOCK and DISTANCE TO PIPELINE ##
model.lme4.du8.s.cut.mine <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                               std.distance_to_cut_5to9yo + 
                                               std.distance_to_cut_10to29yo + 
                                               std.distance_to_cut_30orOveryo + 
                                                std.distance_to_pipeline +
                                               (1 | uniqueID), 
                                     data = rsf.data.human.dist.du8.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [5, 1] <- "DU8"
table.aic [5, 2] <- "Summer"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DPipe"
table.aic [5, 5] <- "(1 | UniqueID)"
table.aic [5, 6] <-  AIC (model.lme4.du8.s.cut.mine)

## DISTANCE TO ROAD AND DISTANCE TO PIPELINE ##
model.lme4.du8.s.road.pipe <- glmer (pttype ~ std.distance_to_resource_road + 
                                                std.distance_to_pipeline +
                                                (1 | uniqueID), 
                                      data = rsf.data.human.dist.du8.s, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [6, 1] <- "DU8"
table.aic [6, 2] <- "Summer"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "DRR, DPipeline"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <-  AIC (model.lme4.du8.s.road.pipe)

## DISTANCE TO CUTBLOCK, DISTANCE TO ROAD, DISTANCE TO PIPELINE ##
model.lme4.du8.s.cut.road.pipe <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                    std.distance_to_cut_5to9yo + 
                                                    std.distance_to_cut_10to29yo + 
                                                    std.distance_to_cut_30orOveryo +
                                                    std.distance_to_resource_road +
                                                    std.distance_to_pipeline +
                                                    (1 | uniqueID), 
                                          data = rsf.data.human.dist.du8.s, 
                                          family = binomial (link = "logit"),
                                          verbose = T) 
# AIC
table.aic [7, 1] <- "DU8"
table.aic [7, 2] <- "Summer"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DRR, DPipeline"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du8.s.cut.road.pipe)

## AIC comparison of MODELS ## 
table.aic$AIC <- as.numeric (table.aic$AIC)
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [c (1:7), 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [c (1:7), 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [c (1:7), 6])))),
                    (exp (-0.5 * (table.aic [4, 6] - min (table.aic [c (1:7), 6])))),
                    (exp (-0.5 * (table.aic [5, 6] - min (table.aic [c (1:7), 6])))),
                    (exp (-0.5 * (table.aic [6, 6] - min (table.aic [c (1:7), 6])))),
                    (exp (-0.5 * (table.aic [7, 6] - min (table.aic [c (1:7), 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [c (1:7), 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [c (1:7), 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [c (1:7), 6])))) / sum (list.aic.like), 3)
table.aic [4, 7] <- round ((exp (-0.5 * (table.aic [4, 6] - min (table.aic [c (1:7), 6])))) / sum (list.aic.like), 3)
table.aic [5, 7] <- round ((exp (-0.5 * (table.aic [5, 6] - min (table.aic [c (1:7), 6])))) / sum (list.aic.like), 3)
table.aic [6, 7] <- round ((exp (-0.5 * (table.aic [6, 6] - min (table.aic [c (1:7), 6])))) / sum (list.aic.like), 3)
table.aic [7, 7] <- round ((exp (-0.5 * (table.aic [7, 6] - min (table.aic [c (1:7), 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\summer\\table_aic_human_disturb.csv", sep = ",")

#=================================
# Natural Disturbance Models
#=================================
rsf.data.natural.dist.du8.s <- rsf.data.natural.dist %>%
                                    dplyr::filter (du == "du8") %>%
                                    dplyr::filter (season == "Summer")

### CORRELATION ###
corr.rsf.data.natural.dist.du8.s <- rsf.data.natural.dist.du8.s [c (10:14)]
corr.rsf.data.natural.dist.du8.s <- round (cor (corr.rsf.data.natural.dist.du8.s, method = "spearman"), 3)
ggcorrplot (corr.rsf.data.natural.dist.du8.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Fire and Beetle Disturbance Selection Function Model
            Covariate Correlations for DU8, Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_natural_disturb_du8_s.png")

### VIF ###
glm.nat.disturb.du8.s <- glm (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                                        fire_1to5yo + fire_6to25yo + fire_over25yo, 
                               data = rsf.data.natural.dist.du8.s,
                               family = binomial (link = 'logit'))
car::vif (glm.nat.disturb.du8.s)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

## FIRE ##
model.lme4.du8.s.fire <- glmer (pttype ~ fire_1to5yo + fire_6to25yo +
                                          fire_over25yo + (1 | uniqueID), 
                                 data = rsf.data.natural.dist.du8.s, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [1, 1] <- "DU8"
table.aic [1, 2] <- "Summer"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "Fire1to5, Fire6to25, Fireover25"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du8.s.fire)

## BEETLE ##
model.lme4.du8.s.beetle <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo +
                                            (1 | uniqueID), 
                                   data = rsf.data.natural.dist.du8.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# AIC
table.aic [2, 1] <- "DU8"
table.aic [2, 2] <- "Summer"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "Beetle1to5, Beetle6to9"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du8.s.beetle)

## FIRE AND BEETLE ##
model.lme4.du8.s.fire.beetle <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo + 
                                                 beetle_1to5yo + beetle_6to9yo +
                                                 (1 | uniqueID), 
                                       data = rsf.data.natural.dist.du8.s, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [3, 1] <- "DU8"
table.aic [3, 2] <- "Summer"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "Fire1to5, Fire6to25, Fireover25, Beetle1to5, Beetle6to9"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <- AIC (model.lme4.du8.s.fire.beetle)

## AIC comparison of MODELS ## 
table.aic$AIC <- as.numeric (table.aic$AIC)
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\summer\\table_aic_natural_disturb.csv", sep = ",")

#=================================
# ANNUAL CLIMATE Models
#=================================
rsf.data.climate.annual.du8.s <- rsf.data.climate.annual %>%
                                            dplyr::filter (du == "du8") %>%
                                            dplyr::filter (season == "Summer")
rsf.data.climate.annual.du8.s$pttype <- as.factor (rsf.data.climate.annual.du8.s$pttype)

### OUTLIERS ###
ggplot (rsf.data.climate.annual.du8.s, aes (x = pttype, y = frost_free_start_julian)) +
            geom_boxplot (outlier.colour = "red") +
            labs (title = "Boxplot DU8, Summer, Annual Frost Free Period Julian Start Day\ 
                  at Available (0) and Used (1) Locations",
                  x = "Available (0) and Used (1) Locations",
                  y = "Julian Day")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_s_frost_free_start.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = pttype, y = growing_degree_days)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Summer, Annual Growing Degree Days \
              at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Number of Days")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_s_grow_deg_day.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = pttype, y = frost_free_end_julian)) +
          geom_boxplot (outlier.colour = "red") +
          labs (title = "Boxplot DU8, Summer, Annual Frost Free End Julian Day \
                at Available (0) and Used (1) Locations",
                x = "Available (0) and Used (1) Locations",
                y = "Julian Day")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_s_frost_free_end.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = pttype, y = frost_free_period)) +
          geom_boxplot (outlier.colour = "red") +
          labs (title = "Boxplot DU8, Summer, Annual Frost Free Period \
                        at Available (0) and Used (1) Locations",
                x = "Available (0) and Used (1) Locations",
                y = "Number of Days")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_s_frost_free_period.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = pttype, y = mean_annual_ppt)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Summer, Mean Annual Precipitation \
                              at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Precipitation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_s_mean_annual_ppt.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = pttype, y = mean_annual_temp)) +
          geom_boxplot (outlier.colour = "red") +
          labs (title = "Boxplot DU8, Summer, Mean Annual Temperature \
                                      at Available (0) and Used (1) Locations",
                x = "Available (0) and Used (1) Locations",
                y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_s_mean_annual_temp.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = pttype, y = mean_coldest_month_temp)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Summer, Mean Annual Coldest Month Temperature \
                                            at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_s_mean_cold_mth_temp.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = pttype, y = mean_warmest_month_temp)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Summer, Mean Annual Warmest Month Temperature \
                                                  at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_s_mean_warm_mth_temp.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = pttype, y = ppt_as_snow_annual)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Summer, Mean Annual Precipitation as Snow \
                    at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Precipitation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_s_mean_annual_pas.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = pttype, y = number_frost_free_days)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Summer, Frost Free Days \
                          at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Number of Days")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_s_num_frost_free_days.png")

### HISTOGRAMS ###
ggplot (rsf.data.climate.annual.du8.s, aes (x = frost_free_start_julian, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU8, Summer, Frost Free Start Julian Day\
              at Available (0) and Used (1) Locations",
              x = "Julian Day",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_s_frost_free_start.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = growing_degree_days, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 100) +
        labs (title = "Histogram DU8, Summer, Annual Growing Degree Days\
                    at Available (0) and Used (1) Locations",
              x = "Number of Days",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_s_grow_deg_days.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = frost_free_end_julian, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU8, Summer, Frost Free End Julian Day\
              at Available (0) and Used (1) Locations",
              x = "Julian Day",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_s_frost_free_end.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = frost_free_period, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU8, Summer, Frost Free Period\
                    at Available (0) and Used (1) Locations",
              x = "Number of Days",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_s_frost_free_period.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = mean_annual_ppt, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 250) +
        labs (title = "Histogram DU8, Summer, Mean Annual Precipitation\
                          at Available (0) and Used (1) Locations",
              x = "Precipitation",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_s_mean_annual_ppt.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = mean_annual_temp, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU8, Summer, Mean Annual Temperature\
                                at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_s_mean_annual_temp.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = mean_coldest_month_temp, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU8, Summer, Mean Annual Coldest Month Temperature\
                       at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_s_mean_annual_cold_mth_temp.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = mean_warmest_month_temp, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU8, Summer, Mean Annual Warmest Month Temperature\
                             at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_s_mean_annual_warm_mth_temp.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = number_frost_free_days, fill = pttype)) + 
          geom_histogram (position = "dodge") +
          labs (title = "Histogram DU8, Summer, Annual Number of Frost Free Days\
                                     at Available (0) and Used (1) Locations",
                x = "Number of Days",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_s_mean_frost_free_days.png")
ggplot (rsf.data.climate.annual.du8.s, aes (x = ppt_as_snow_annual, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU8, Summer, Annual Precipitation as Snow\
              at Available (0) and Used (1) Locations",
              x = "Precipitation",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_s_mean_pas.png")

### CORRELATION ###
corr.rsf.data.climate.annual.du8.s <- rsf.data.climate.annual.du8.s [c (10:19)]
corr.rsf.data.climate.annual.du8.s <- round (cor (corr.rsf.data.climate.annual.du8.s, method = "spearman"), 3)
ggcorrplot (corr.rsf.data.climate.annual.du8.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Annual Climate Resource Selection Function Model
            Covariate Correlations for DU8, Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_annual_climate_du8_s.png")

### VIF ###
glm.annual.climate.du8.s <- glm (pttype ~ mean_annual_ppt + mean_annual_temp, 
                                   data = rsf.data.climate.annual.du8.s,
                                   family = binomial (link = 'logit'))
car::vif (glm.annual.climate.du8.s)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

# standardize covariates  (helps with model convergence)
rsf.data.climate.annual.du8.s$std.mean_annual_ppt <- (rsf.data.climate.annual.du8.s$mean_annual_ppt - mean (rsf.data.climate.annual.du8.s$mean_annual_ppt)) / sd (rsf.data.climate.annual.du8.s$mean_annual_ppt)
rsf.data.climate.annual.du8.s$std.mean_annual_temp <- (rsf.data.climate.annual.du8.s$mean_annual_temp - mean (rsf.data.climate.annual.du8.s$mean_annual_temp)) / sd (rsf.data.climate.annual.du8.s$mean_annual_temp)

## PRECIPITATION AS SNOW ##
model.lme4.du8.s.pas <- glmer (pttype ~ std.mean_annual_ppt + 
                                         (1 | uniqueID), 
                                data = rsf.data.climate.annual.du8.s, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [1, 1] <- "DU8"
table.aic [1, 2] <- "Summer"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "MAP"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du8.s.pas)

## MEAN ANNUAL TEMPERATURE ##
model.lme4.du8.s.mat <- glmer (pttype ~ std.mean_annual_temp + 
                                          (1 | uniqueID), 
                                data = rsf.data.climate.annual.du8.s, 
                                family = binomial (link = "logit"),
                                verbose = T) 
ss <- getME (model.lme4.du8.s.mat, c ("theta","fixef"))
model.lme4.du8.s.mat <- update (model.lme4.du8.s.mat, start = ss) # failed to converge, restart with parameter estimates
# MODEL DID NOT CONVERGE
# AIC
table.aic [2, 1] <- "DU8"
table.aic [2, 2] <- "Summer"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "MAT"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du8.s.mat)

## PRECIPITATION AS SNOW and MEAN ANNUAL TEMP ##
model.lme4.du8.s.pas.mat <- glmer (pttype ~ std.mean_annual_ppt + std.mean_annual_temp +
                                              (1 | uniqueID), 
                                    data = rsf.data.climate.annual.du8.s, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [3, 1] <- "DU8"
table.aic [3, 2] <- "Summer"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "MAP, MAT"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du8.s.pas.mat)

## AIC comparison of MODELS ## 
table.aic$AIC <- as.numeric (table.aic$AIC)
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\summer\\table_aic_annual_climate.csv", sep = ",")


#=================================
# SUMMER CLIMATE Models
#=================================
rsf.data.climate.summer.du8.s <- rsf.data.climate.summer %>%
                                    dplyr::filter (du == "du8") %>%
                                    dplyr::filter (season == "Summer")
rsf.data.climate.summer.du8.s$pttype <- as.factor (rsf.data.climate.summer.du8.s$pttype)

### OUTLIERS ###
ggplot (rsf.data.climate.summer.du8.s, aes (x = pttype, y = ppt_as_snow_summer)) +
            geom_boxplot (outlier.colour = "red") +
            labs (title = "Boxplot DU8, Summer, Precipitation as Snow\ 
                            at Available (0) and Used (1) Locations",
                  x = "Available (0) and Used (1) Locations",
                  y = "Precipitation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_summer_climate_du8_s_ppt_as_snow.png")
ggplot (rsf.data.climate.summer.du8.s, aes (x = pttype, y = ppt_summer)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Summer, Precipitation\ 
              at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Precipitation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_summer_climate_du8_s_ppt.png")
ggplot (rsf.data.climate.summer.du8.s, aes (x = pttype, y = temp_avg_summer)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Summer, Average Temperature\ 
              at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_summer_climate_du8_s_temp_avg.png")
ggplot (rsf.data.climate.summer.du8.s, aes (x = pttype, y = temp_max_summer)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Summer, Maximum Temperature\ 
                    at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_summer_climate_du8_s_temp_max.png")
ggplot (rsf.data.climate.summer.du8.s, aes (x = pttype, y = temp_min_summer)) +
          geom_boxplot (outlier.colour = "red") +
          labs (title = "Boxplot DU8, Summer, Minimum Temperature\ 
                            at Available (0) and Used (1) Locations",
                x = "Available (0) and Used (1) Locations",
                y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_summer_climate_du8_s_temp_min.png")

### HISTOGRAMS ###
ggplot (rsf.data.climate.summer.du8.s, aes (x = ppt_summer, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 50) +
        labs (title = "Histogram DU8, Summer, Precipitation\
                      at Available (0) and Used (1) Locations",
              x = "Precipitation",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_s_ppt.png")
ggplot (rsf.data.climate.summer.du8.s, aes (x = temp_avg_summer, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 1) +
        labs (title = "Histogram DU8, Summer, Average Temperature\
                            at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_s_temp_avg.png")
ggplot (rsf.data.climate.summer.du8.s, aes (x = temp_max_summer, fill = pttype)) + 
          geom_histogram (position = "dodge") +
          labs (title = "Histogram DU8, Summer, Maximum Temperature\
                         at Available (0) and Used (1) Locations",
                x = "Temperature",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_s_temp_max.png")
ggplot (rsf.data.climate.summer.du8.s, aes (x = temp_min_summer, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU8, Summer, Minimum Temperature\
                               at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_s_temp_min.png")

### CORRELATION ###
corr.climate.summer.du8.s <- rsf.data.climate.summer.du8.s [c (10, 13:16)] # frost free days all = 0
corr.climate.summer.du8.s <- round (cor (corr.climate.summer.du8.s, method = "spearman"), 3)
ggcorrplot (corr.climate.summer.du8.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Winter Climate Resource Selection Function Model
            Covariate Correlations for DU8, Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_summer_climate_du8_s.png")

### VIF ###
glm.summer.climate.du8.s <- glm (pttype ~ ppt_summer + temp_min_summer, 
                                  data = rsf.data.climate.summer.du8.s,
                                  family = binomial (link = 'logit'))
car::vif (glm.summer.climate.du8.s)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

# standardize covariates  (helps with model convergence)
rsf.data.climate.summer.du8.s$std.ppt_summer <- (rsf.data.climate.summer.du8.s$ppt_summer - mean (rsf.data.climate.summer.du8.s$ppt_summer)) / sd (rsf.data.climate.summer.du8.s$ppt_summer)
rsf.data.climate.summer.du8.s$std.temp_min_summer <- (rsf.data.climate.summer.du8.s$temp_min_summer - mean (rsf.data.climate.summer.du8.s$temp_min_summer)) / sd (rsf.data.climate.summer.du8.s$temp_min_summer)

## PRECIPITATION  ##
model.lme4.du8.s.summer.ppt <- glmer (pttype ~ std.ppt_summer + 
                                                (1 | uniqueID), 
                                data = rsf.data.climate.summer.du8.s, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [1, 1] <- "DU8"
table.aic [1, 2] <- "Summer"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "MSP"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du8.s.summer.ppt)

## TEMPERATURE ##
model.lme4.du8.s.summer.temp <- glmer (pttype ~ std.temp_min_summer + 
                                                  (1 | uniqueID), 
                                       data = rsf.data.climate.summer.du8.s, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [2, 1] <- "DU8"
table.aic [2, 2] <- "Summer"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "MinST"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du8.s.summer.temp)

## PRECIPITATION and TEMPERATURE ##
model.lme4.du8.s.summer.ppt.temp <- glmer (pttype ~ std.ppt_summer + 
                                                    std.temp_min_summer +
                                                    (1 | uniqueID), 
                                       data = rsf.data.climate.summer.du8.s, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [3, 1] <- "DU8"
table.aic [3, 2] <- "Summer"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "MSP, MinST"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du8.s.summer.ppt.temp)

## AIC comparison of MODELS ## 
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\summer\\table_aic_summer_climate.csv", sep = ",")

#=================================
# VEGETATION/FOREST Models
#=================================
rsf.data.veg.du8.s <- rsf.data.veg %>%
                         dplyr::filter (du == "du8") %>%
                         dplyr::filter (season == "Summer")
rsf.data.veg.du8.s$pttype <- as.factor (rsf.data.veg.du8.s$pttype)

rsf.data.veg.du8.s <- rsf.data.veg.du8.s %>% # remove site index outlier
                    filter (vri_site_index < 30)

rsf.data.veg.du8.s$bec_label_reclass2 <- rsf.data.veg.du8.s$bec_label
rsf.data.veg.du8.s <- rsf.data.veg.du8.s %>%
                            dplyr::filter (bec_label_reclass2 != "SBPSmc")
rsf.data.veg.du8.s <- rsf.data.veg.du8.s %>%
                              dplyr::filter (bec_label_reclass2 != "SBS wk 1")
rsf.data.veg.du8.s <- rsf.data.veg.du8.s %>%
                            dplyr::filter (bec_label_reclass2 != "SBS vk")

rsf.data.veg.du8.s$bec_label_reclass2 <- relevel (rsf.data.veg.du8.s$bec_label_reclass2,
                                                     ref = "ESSFwc 3") # reference category

rsf.data.veg.du8.s$vri_bclcs_class  <- relevel (rsf.data.veg.du8.s$vri_bclcs_class,
                                                  ref = "Upland-Treed-Conifer")
### OUTLIERS ###
ggplot (rsf.data.veg.du8.s, aes (x = pttype, y = vri_basal_area)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer, Basal Area\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Basal Area of Trees")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_s_basal_area.png")
ggplot (rsf.data.veg.du8.s, aes (x = pttype, y = vri_bryoid_cover_pct)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer, Bryoid Cover\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Percent Cover")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_s_bryoid_perc.png")
ggplot (rsf.data.veg.du8.s, aes (x = pttype, y = vri_crown_closure)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer, Crown Closure\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Crown Closure")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_s_crown_close.png")
ggplot (rsf.data.veg.du8.s, aes (x = pttype, y = vri_herb_cover_pct)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer, Herbaceous Cover\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Percent Cover")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_s_herb_cover.png")
ggplot (rsf.data.veg.du8.s, aes (x = pttype, y = vri_live_volume)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer, Live Forest Stand Volume\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Volume")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_s_live_volume.png")
ggplot (rsf.data.veg.du8.s, aes (x = pttype, y = vri_proj_age)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer, Projected Forest Stand Age\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Age")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_s_stand_age.png")
ggplot (rsf.data.veg.du8.s, aes (x = pttype, y = vri_proj_height)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer, Projected Forest Stand Height\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Height")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_s_stand_height.png")
ggplot (rsf.data.veg.du8.s, aes (x = pttype, y = vri_shrub_crown_close)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer, Shrub Crown Closure\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Crown Closure")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_s_shrub_closure.png")
ggplot (rsf.data.veg.du8.s, aes (x = pttype, y = vri_shrub_height)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer, Shrub Height\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Height")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_s_shrub_height.png")
ggplot (rsf.data.veg.du8.s, aes (x = pttype, y = vri_site_index)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Summer, Site Index\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Site Index")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_s_site_index.png")

### HISTOGRAMS ###
ggplot (rsf.data.veg.du8.s, aes (x = bec_label, fill = pttype)) + 
            geom_histogram (position = "dodge", stat = "count") +
            labs (title = "Histogram DU8, Summer, BEC Type\
                          at Available (0) and Used (1) Locations",
                  x = "Biogeclimatic Unit Type",
                  y = "Count") +
            scale_fill_discrete (name = "Location Type") +
            theme (axis.text.x = element_text (angle = 45))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_veg_du8_s_bec.png")

ggplot (rsf.data.veg.du8.s, aes (x = bec_label_reclass2, fill = pttype)) + 
          geom_histogram (position = "dodge", stat = "count") +
          labs (title = "Histogram DU8, Summer, BEC Reclass Type\
                                  at Available (0) and Used (1) Locations",
                x = "Biogeclimatic Unit Type",
                y = "Count") +
          scale_fill_discrete (name = "Location Type") +
          theme (axis.text.x = element_text (angle = 45))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_veg_du8_s_bec_reclass.png")

rsf.data.veg.du8.s$vri_bclcs_class <- recode (rsf.data.veg.du8.s$vri_bclcs_class,
                                        "'Wetland-Treed-Conifer' = 'Wetland'")
rsf.data.veg.du8.s$vri_bclcs_class <- recode (rsf.data.veg.du8.s$vri_bclcs_class,
                                        "'Wetland-Shrub' = 'Wetland'")
rsf.data.veg.du8.s$vri_bclcs_class <- recode (rsf.data.veg.du8.s$vri_bclcs_class,
                                        "'Wetland-Treed-Mixed' = 'Wetland'")
rsf.data.veg.du8.s$vri_bclcs_class <- recode (rsf.data.veg.du8.s$vri_bclcs_class,
                                        "'Wetland-Treed-Deciduous' = 'Wetland'")
rsf.data.veg.du8.s$vri_bclcs_class <- recode (rsf.data.veg.du8.s$vri_bclcs_class,
                                               "'Wetland-NonTreed' = 'Wetland'")
rsf.data.veg.du8.s$vri_bclcs_class <- recode (rsf.data.veg.du8.s$vri_bclcs_class,
                                               "'Wetland-Herb' = 'Wetland'")
rsf.data.veg.du8.s$vri_bclcs_class <- recode (rsf.data.veg.du8.s$vri_bclcs_class,
                                               "'Water' = 'Wetland'")
rsf.data.veg.du8.s$vri_bclcs_class <- recode (rsf.data.veg.du8.s$vri_bclcs_class,
                                               "'Alpine-Herb' = 'Alpine'")
rsf.data.veg.du8.s$vri_bclcs_class <- recode (rsf.data.veg.du8.s$vri_bclcs_class,
                                               "'Alpine-NonTreed' = 'Alpine'")
rsf.data.veg.du8.s$vri_bclcs_class <- recode (rsf.data.veg.du8.s$vri_bclcs_class,
                                               "'Alpine-Shrub' = 'Alpine'")
rsf.data.veg.du8.s$vri_bclcs_class <- recode (rsf.data.veg.du8.s$vri_bclcs_class,
                                               "'Alpine-Lichen' = 'Alpine'")
rsf.data.veg.du8.s$vri_bclcs_class <- recode (rsf.data.veg.du8.s$vri_bclcs_class,
                                               "'Upland-Treed-Deciduous' = 'Upland-Treed-Decid-Mixed'")
rsf.data.veg.du8.s$vri_bclcs_class <- recode (rsf.data.veg.du8.s$vri_bclcs_class,
                                               "'Upland-Treed-Mixed' = 'Upland-Treed-Decid-Mixed'")
rsf.data.veg.du8.s$vri_bclcs_class  <- relevel (rsf.data.veg.du8.s$vri_bclcs_class,
                                                 ref = "Upland-Treed-Conifer")

ggplot (rsf.data.veg.du8.s, aes (x = vri_bclcs_class, fill = pttype)) + 
          geom_histogram (position = "dodge", stat = "count") +
          labs (title = "Histogram DU8, Summer, Landcover Type\
                         at Available (0) and Used (1) Locations",
                x = "Landcover Type",
                y = "Count") +
          scale_fill_discrete (name = "Location Type") +
          theme (axis.text.x = element_text (angle = -90, hjust = 0))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_veg_du8_s_landcover.png")

ggplot (rsf.data.veg.du8.s, aes (x = vri_soil_moisture_name, fill = pttype)) + 
          geom_histogram (position = "dodge", stat = "count") +
          labs (title = "Histogram DU8, Summer, Soil Moisture Type\
                         at Available (0) and Used (1) Locations",
                x = "Soil Moisture Type",
                y = "Count") +
          scale_fill_discrete (name = "Location Type") +
          theme (axis.text.x = element_text (angle = -90, hjust = 0))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_veg_du8_s_soil_moisture.png")

ggplot (rsf.data.veg.du8.s, aes (x = vri_soil_nutrient_name, fill = pttype)) + 
          geom_histogram (position = "dodge", stat = "count") +
          labs (title = "Histogram DU8, Summer, Soil Nutrient Type\
                at Available (0) and Used (1) Locations",
                x = "Soil Nutrient Type",
                y = "Count") +
          scale_fill_discrete (name = "Location Type") +
          theme (axis.text.x = element_text (angle = -90, hjust = 0))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_veg_du8_s_soil_nutrient.png")

rsf.data.veg.du8.s$vri_species_primary_name_reclass <- recode (rsf.data.veg.du8.s$vri_species_primary_name_reclass,
                                                                "'ALB' = 'Deciduous'")
rsf.data.veg.du8.s$vri_species_primary_name_reclass <- recode (rsf.data.veg.du8.s$vri_species_primary_name_reclass,
                                                                "'APC' = 'Deciduous'")
rsf.data.veg.du8.s$vri_species_primary_name_reclass  <- relevel (rsf.data.veg.du8.s$vri_species_primary_name_reclass,
                                                                  ref = "PIN")
ggplot (rsf.data.veg.du8.s, aes (x = vri_species_primary_name_reclass, fill = pttype)) + 
          geom_histogram (position = "dodge", stat = "count") +
          labs (title = "Histogram DU8, Summer, Primary Tree Species\
                at Available (0) and Used (1) Locations",
                x = "Tree Species",
                y = "Count") +
          scale_fill_discrete (name = "Location Type") +
          theme (axis.text.x = element_text (angle = -90, hjust = 0))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_veg_du8_s_lead_tree_spp.png")

### CORRELATION ###
corr.veg.du8.s <- rsf.data.veg.du8.s [c (17:26)]
corr.veg.du8.s <- round (cor (corr.veg.du8.s, method = "spearman"), 3)
ggcorrplot (corr.veg.du8.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Vegetation Resource Selection Function Model
            Covariate Correlations for DU8, Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_veg_du8_s.png")

### VIF ###
glm.veg.du8.s <- glm (pttype ~ bec_label_reclass2 + 
                                # vri_bclcs_class + 
                                # vri_species_primary_name_reclass +
                                vri_proj_age + 
                                vri_site_index +
                                vri_herb_cover_pct + 
                                vri_shrub_crown_close, 
                       data = rsf.data.veg.du8.s,
                       family = binomial (link = 'logit'))
car::vif (glm.veg.du8.s)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

# standardize covariates  (helps with model convergence)
# rsf.data.veg.du8.s$std.vri_bryoid_cover_pct <- (rsf.data.veg.du8.s$vri_bryoid_cover_pct - mean (rsf.data.veg.du8.s$vri_bryoid_cover_pct)) / sd (rsf.data.veg.du8.s$vri_bryoid_cover_pct)
rsf.data.veg.du8.s$std.vri_herb_cover_pct <- (rsf.data.veg.du8.s$vri_herb_cover_pct - mean (rsf.data.veg.du8.s$vri_herb_cover_pct)) / sd (rsf.data.veg.du8.s$vri_herb_cover_pct)
rsf.data.veg.du8.s$std.vri_proj_age <- (rsf.data.veg.du8.s$vri_proj_age - mean (rsf.data.veg.du8.s$vri_proj_age)) / sd (rsf.data.veg.du8.s$vri_proj_age)
rsf.data.veg.du8.s$std.vri_shrub_crown_close <- (rsf.data.veg.du8.s$vri_shrub_crown_close - mean (rsf.data.veg.du8.s$vri_shrub_crown_close)) / sd (rsf.data.veg.du8.s$vri_shrub_crown_close)
# rsf.data.veg.du8.s$std.vri_crown_closure <- (rsf.data.veg.du8.s$vri_crown_closure - mean (rsf.data.veg.du8.s$vri_crown_closure)) / sd (rsf.data.veg.du8.s$vri_crown_closure)
rsf.data.veg.du8.s$std.vri_site_index <- (rsf.data.veg.du8.s$vri_site_index - mean (rsf.data.veg.du8.s$vri_site_index)) / sd (rsf.data.veg.du8.s$vri_site_index)

### CANDIDATE MODELS ###
## BEC ##
model.lme4.du8.s.veg.bec <- glmer (pttype ~ bec_label_reclass2 + 
                                             (1 | uniqueID), 
                                    data = rsf.data.veg.du8.s, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [1, 1] <- "DU8"
table.aic [1, 2] <- "Summer"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "BEC"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du8.s.veg.bec)

## FOOD ##
model.lme4.du8.s.veg.food <- glmer (pttype ~ std.vri_shrub_crown_close + 
                                              std.vri_herb_cover_pct + 
                                              (1 | uniqueID), 
                                     data = rsf.data.veg.du8.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [2, 1] <- "DU8"
table.aic [2, 2] <- "Summer"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "ShrubClosure, HerbCover"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du8.s.veg.food)

## FOREST STAND ##
model.lme4.du8.s.veg.forest <- glmer (pttype ~ std.vri_proj_age + 
                                                std.vri_site_index + 
                                                (1 | uniqueID), 
                                       data = rsf.data.veg.du8.s, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [3, 1] <- "DU8"
table.aic [3, 2] <- "Summer"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "TreeAge, SiteIndex"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du8.s.veg.forest)

## BEC and FOOD ##
model.lme4.du8.s.veg.bec.food <- glmer (pttype ~  bec_label_reclass2 + 
                                                   std.vri_shrub_crown_close + 
                                                   std.vri_herb_cover_pct +
                                                   (1 | uniqueID), 
                                                 data = rsf.data.veg.du8.s, 
                                                 family = binomial (link = "logit"),
                                                 verbose = T) 
# AIC
table.aic [4, 1] <- "DU8"
table.aic [4, 2] <- "Summer"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "BEC, ShrubClosure, HerbCover"
table.aic [4, 5] <- "(1 | UniqueID)"
table.aic [4, 6] <-  AIC (model.lme4.du8.s.veg.bec.food)

## BEC and FOREST ##
model.lme4.du8.s.veg.bec.forest <- glmer (pttype ~ bec_label_reclass2 + 
                                                     std.vri_proj_age + 
                                                     std.vri_site_index +
                                                     (1 | uniqueID), 
                                            data = rsf.data.veg.du8.s, 
                                            family = binomial (link = "logit"),
                                            verbose = T) 
# AIC
table.aic [5, 1] <- "DU8"
table.aic [5, 2] <- "Summer"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "BEC, TreeAge, SiteIndex"
table.aic [5, 5] <- "(1 | UniqueID)"
table.aic [5, 6] <-  AIC (model.lme4.du8.s.veg.bec.forest)

## FOOD and FOREST ##
model.lme4.du8.s.veg.food.forest <- glmer (pttype ~ std.vri_shrub_crown_close + 
                                                     std.vri_herb_cover_pct +
                                                     std.vri_proj_age + 
                                                     std.vri_site_index +
                                                     (1 | uniqueID), 
                                            data = rsf.data.veg.du8.s, 
                                            family = binomial (link = "logit"),
                                            verbose = T) 
# AIC
table.aic [6, 1] <- "DU8"
table.aic [6, 2] <- "Summer"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <-  AIC (model.lme4.du8.s.veg.food.forest)

## BEC, FOOD and FOREST ##
model.lme4.du8.s.veg.bec.forest.food <- glmer (pttype ~ bec_label_reclass2 +
                                                         std.vri_shrub_crown_close + 
                                                         std.vri_herb_cover_pct +
                                                         std.vri_proj_age + 
                                                         std.vri_site_index +
                                                         (1 | uniqueID), 
                                                 data = rsf.data.veg.du8.s, 
                                                 family = binomial (link = "logit"),
                                                 verbose = T) 
ss <- getME (model.lme4.du8.s.veg.bec.forest.food, c ("theta","fixef"))
model.lme4.du8.s.veg.bec.forest.food <- update (model.lme4.du8.s.veg.bec.forest.food, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [7, 1] <- "DU8"
table.aic [7, 2] <- "Summer"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "BEC, ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du8.s.veg.bec.forest.food)

## AIC comparison of MODELS ## 
table.aic$AIC <- as.numeric (table.aic$AIC)
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [c (1:7), 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [c (1:7), 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [c (1:7), 6])))),
                    (exp (-0.5 * (table.aic [4, 6] - min (table.aic [c (1:7), 6])))),
                    (exp (-0.5 * (table.aic [5, 6] - min (table.aic [c (1:7), 6])))),
                    (exp (-0.5 * (table.aic [6, 6] - min (table.aic [c (1:7), 6])))),
                    (exp (-0.5 * (table.aic [7, 6] - min (table.aic [c (1:7), 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [c (1:7), 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [c (1:7), 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [c (1:7), 6])))) / sum (list.aic.like), 3)
table.aic [4, 7] <- round ((exp (-0.5 * (table.aic [4, 6] - min (table.aic [c (1:7), 6])))) / sum (list.aic.like), 3)
table.aic [5, 7] <- round ((exp (-0.5 * (table.aic [5, 6] - min (table.aic [c (1:7), 6])))) / sum (list.aic.like), 3)
table.aic [6, 7] <- round ((exp (-0.5 * (table.aic [6, 6] - min (table.aic [c (1:7), 6])))) / sum (list.aic.like), 3)
table.aic [7, 7] <- round ((exp (-0.5 * (table.aic [7, 6] - min (table.aic [c (1:7), 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\summer\\table_aic_veg.csv", sep = ",")

#=================================
# COMBINATION Models
#=================================

### compile AIC table of top models form each group
table.aic.annual.clim <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\summer\\table_aic_annual_climate.csv", header = T, sep = ",")
table.aic <- table.aic.annual.clim [3, ]
rm (table.aic.annual.clim)
table.aic.human <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\summer\\table_aic_human_disturb.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.human [4, ])
rm (table.aic.human)
table.aic.nat.disturb <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\summer\\table_aic_natural_disturb.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.nat.disturb [3, ])
rm (table.aic.nat.disturb)
table.aic.enduring <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\summer\\table_aic_terrain_water.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.enduring [15, ])
rm (table.aic.enduring)
table.aic.summer.clim <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\summer\\table_aic_summer_climate.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.summer.clim [3, ])
rm (table.aic.summer.clim)
table.aic.veg <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\summer\\table_aic_veg.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.veg [7, ])
rm (table.aic.veg)
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\summer\\table_aic_all.csv", sep = ",")

# Load and tidy the data 
# rsf.data.combo.du8.s <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du8_s.csv", header = T, sep = ",")
# rsf.data.combo.du8.s$pttype <- as.factor (rsf.data.combo.du8.s$pttype)
rsf.data.combo.du8.s$bec_label_reclass2 <- rsf.data.combo.du8.s$bec_label
rsf.data.combo.du8.s <- rsf.data.combo.du8.s %>%
                          dplyr::filter (bec_label_reclass2 != "SBPSmc")
rsf.data.combo.du8.s <- rsf.data.combo.du8.s %>%
                          dplyr::filter (bec_label_reclass2 != "SBS wk 1")
rsf.data.combo.du8.s <- rsf.data.combo.du8.s %>%
                          dplyr::filter (bec_label_reclass2 != "SBS vk")
rsf.data.combo.du8.s$bec_label_reclass2 <- relevel (rsf.data.combo.du8.s$bec_label_reclass2,
                                                      ref = "ESSFwc 3") # reference category
### CORRELATION ###
corr.data.du8.s <- rsf.data.combo.du8.s [c (10:28, 30:33)]
corr.du8.s <- round (cor (corr.data.du8.s, method = "spearman"), 3)
ggcorrplot (corr.du8.s, type = "lower", lab = TRUE, tl.cex = 9,  lab_size = 2,
            title = "Resource Selection Function Model Covariate Correlations \
                     for DU8, Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_winter_climate_du8_s.png")

### VIF ###
glm.all.du8.s <- glm (pttype ~ distance_to_watercourse + 
                                slope + 
                                # elevation +
                                distance_to_lake + 
                                distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                                distance_to_cut_10to29yo + distance_to_cut_30orOveryo +
                                distance_to_resource_road + 
                                distance_to_pipeline + 
                                beetle_1to5yo + beetle_6to9yo + 
                                fire_1to5yo + fire_6to25yo + fire_over25yo + 
                                # mean_annual_temp +
                                mean_annual_ppt +
                                # ppt_summer +
                                # temp_min_summer +
                                bec_label_reclass2 +
                                vri_shrub_crown_close + 
                                vri_herb_cover_pct + 
                                vri_proj_age + 
                                vri_site_index,  
                       data = rsf.data.combo.du8.s,
                       family = binomial (link = 'logit'))
car::vif (glm.all.du8.s)

# standardize covariates  (helps with model convergence)
rsf.data.combo.du8.s$std.slope <- (rsf.data.combo.du8.s$slope - mean (rsf.data.combo.du8.s$slope)) / sd (rsf.data.combo.du8.s$slope)
rsf.data.combo.du8.s$std.distance_to_watercourse <- (rsf.data.combo.du8.s$distance_to_watercourse - mean (rsf.data.combo.du8.s$distance_to_watercourse)) / sd (rsf.data.combo.du8.s$distance_to_watercourse)
rsf.data.combo.du8.s$std.distance_to_lake <- (rsf.data.combo.du8.s$distance_to_lake - mean (rsf.data.combo.du8.s$distance_to_lake)) / sd (rsf.data.combo.du8.s$distance_to_lake)
# rsf.data.combo.du8.s$std.elevation <- (rsf.data.combo.du8.s$elevation - mean (rsf.data.combo.du8.s$elevation)) / sd (rsf.data.combo.du8.s$elevation)
rsf.data.combo.du8.s$std.distance_to_cut_1to4yo <- (rsf.data.combo.du8.s$distance_to_cut_1to4yo - mean (rsf.data.combo.du8.s$distance_to_cut_1to4yo)) / sd (rsf.data.combo.du8.s$distance_to_cut_1to4yo)
rsf.data.combo.du8.s$std.distance_to_cut_5to9yo <- (rsf.data.combo.du8.s$distance_to_cut_5to9yo - mean (rsf.data.combo.du8.s$distance_to_cut_5to9yo)) / sd (rsf.data.combo.du8.s$distance_to_cut_5to9yo)
rsf.data.combo.du8.s$std.distance_to_cut_10to29yo <- (rsf.data.combo.du8.s$distance_to_cut_10to29yo - mean (rsf.data.combo.du8.s$distance_to_cut_10to29yo)) / sd (rsf.data.combo.du8.s$distance_to_cut_10to29yo)
rsf.data.combo.du8.s$std.distance_to_cut_30orOveryo <- (rsf.data.combo.du8.s$distance_to_cut_30orOveryo - mean (rsf.data.combo.du8.s$distance_to_cut_30orOveryo)) / sd (rsf.data.combo.du8.s$distance_to_cut_30orOveryo)
# rsf.data.combo.du8.s$std.distance_to_paved_road <- (rsf.data.combo.du8.s$distance_to_paved_road - mean (rsf.data.combo.du8.s$distance_to_paved_road)) / sd (rsf.data.combo.du8.s$distance_to_paved_road)
rsf.data.combo.du8.s$std.distance_to_resource_road <- (rsf.data.combo.du8.s$distance_to_resource_road - mean (rsf.data.combo.du8.s$distance_to_resource_road)) / sd (rsf.data.combo.du8.s$distance_to_resource_road)
rsf.data.combo.du8.s$std.distance_to_pipeline <- (rsf.data.combo.du8.s$distance_to_pipeline - mean (rsf.data.combo.du8.s$distance_to_pipeline)) / sd (rsf.data.combo.du8.s$distance_to_pipeline)
# rsf.data.combo.du8.s$std.distance_to_agriculture <- (rsf.data.combo.du8.s$distance_to_agriculture - mean (rsf.data.combo.du8.s$distance_to_agriculture)) / sd (rsf.data.combo.du8.s$distance_to_agriculture)
# rsf.data.combo.du8.s$std.ppt_summer <- (rsf.data.combo.du8.s$ppt_summer - mean (rsf.data.combo.du8.s$ppt_summer)) / sd (rsf.data.combo.du8.s$ppt_summer)
# rsf.data.combo.du8.s$std.temp_min_summer <- (rsf.data.combo.du8.s$temp_min_summer - mean (rsf.data.combo.du8.s$temp_min_summer)) / sd (rsf.data.combo.du8.s$temp_min_summer)
# rsf.data.combo.du8.s$std.mean_annual_temp <- (rsf.data.combo.du8.s$mean_annual_temp - mean (rsf.data.combo.du8.s$mean_annual_temp)) / sd (rsf.data.combo.du8.s$mean_annual_temp)
rsf.data.combo.du8.s$std.mean_annual_ppt <- (rsf.data.combo.du8.s$mean_annual_ppt - mean (rsf.data.combo.du8.s$mean_annual_ppt)) / sd (rsf.data.combo.du8.s$mean_annual_ppt)
rsf.data.combo.du8.s$std.vri_shrub_crown_close <- (rsf.data.combo.du8.s$vri_shrub_crown_close - mean (rsf.data.combo.du8.s$vri_shrub_crown_close)) / sd (rsf.data.combo.du8.s$vri_shrub_crown_close)
rsf.data.combo.du8.s$std.vri_herb_cover_pct <- (rsf.data.combo.du8.s$vri_herb_cover_pct - mean (rsf.data.combo.du8.s$vri_herb_cover_pct)) / sd (rsf.data.combo.du8.s$vri_herb_cover_pct)
# rsf.data.combo.du8.s$std.vri_bryoid_cover_pct <- (rsf.data.combo.du8.s$vri_bryoid_cover_pct - mean (rsf.data.combo.du8.s$vri_bryoid_cover_pct)) / sd (rsf.data.combo.du8.s$vri_bryoid_cover_pct)
rsf.data.combo.du8.s$std.vri_proj_age <- (rsf.data.combo.du8.s$vri_proj_age - mean (rsf.data.combo.du8.s$vri_proj_age)) / sd (rsf.data.combo.du8.s$vri_proj_age)
# rsf.data.combo.du8.s$std.vri_crown_closure <- (rsf.data.combo.du8.s$vri_crown_closure - mean (rsf.data.combo.du8.s$vri_crown_closure)) / sd (rsf.data.combo.du8.s$vri_crown_closure)
rsf.data.combo.du8.s$std.vri_site_index <- (rsf.data.combo.du8.s$vri_site_index - mean (rsf.data.combo.du8.s$vri_site_index)) / sd (rsf.data.combo.du8.s$vri_site_index)

### ENDURING FEATURES AND HUMAN DISTURBANCE ###
model.lme4.du8.s.ef.hd <- glmer (pttype ~ std.slope + 
                                            std.distance_to_watercourse + 
                                            std.distance_to_lake + 
                                            std.distance_to_cut_1to4yo + 
                                            std.distance_to_cut_5to9yo +
                                            std.distance_to_cut_10to29yo + 
                                            std.distance_to_cut_30orOveryo +
                                            std.distance_to_resource_road + 
                                            std.distance_to_pipeline + 
                                            (1 | uniqueID), 
                                  data = rsf.data.combo.du8.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
# AIC
table.aic [7, 1] <- "DU8"
table.aic [7, 2] <- "Summer"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "Slope, DWat, DLake, DC1to4, DC5to9, DC10to29, DCover30, DRR, DPipe"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du8.s.ef.hd)

### ENDURING FEATURES AND NATURAL DISTURBANCE ###
model.lme4.du8.s.ef.nd <- glmer (pttype ~ std.slope + 
                                            std.distance_to_watercourse +
                                            std.distance_to_lake +
                                            beetle_1to5yo + beetle_6to9yo + 
                                            fire_1to5yo + fire_6to25yo + fire_over25yo +
                                            (1 | uniqueID), 
                                  data = rsf.data.combo.du8.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
# AIC
table.aic [8, 1] <- "DU8"
table.aic [8, 2] <- "Summer"
table.aic [8, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [8, 4] <- "Slope, DWat, DLake, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [8, 5] <- "(1 | UniqueID)"
table.aic [8, 6] <-  AIC (model.lme4.du8.s.ef.nd)

### HUMAN DISTURBANCE AND NATURAL DISTURBANCE ###
model.lme4.du8.s.hd.nd <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                           std.distance_to_cut_5to9yo +
                                           std.distance_to_cut_10to29yo + 
                                           std.distance_to_cut_30orOveryo +
                                           std.distance_to_resource_road + 
                                           std.distance_to_pipeline + 
                                           beetle_1to5yo + beetle_6to9yo + 
                                           fire_1to5yo + fire_6to25yo + fire_over25yo +
                                           (1 | uniqueID), 
                                  data = rsf.data.combo.du8.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
# AIC
table.aic [9, 1] <- "DU8"
table.aic [9, 2] <- "Summer"
table.aic [9, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [9, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DRR, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [9, 5] <- "(1 | UniqueID)"
table.aic [9, 6] <-  AIC (model.lme4.du8.s.hd.nd)

### ENDURING FEATURES AND VEGETATION ###
model.lme4.du8.s.ef.veg <- glmer (pttype ~ std.slope + 
                                            std.distance_to_watercourse + 
                                            std.distance_to_lake +
                                            std.vri_proj_age + 
                                            std.vri_site_index + 
                                            std.vri_herb_cover_pct + 
                                            std.vri_shrub_crown_close + 
                                            bec_label_reclass2 +
                                            (1 | uniqueID), 
                                   data = rsf.data.combo.du8.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# AIC
table.aic [10, 1] <- "DU8"
table.aic [10, 2] <- "Summer"
table.aic [10, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [10, 4] <- "Slope, DWat, DLake, BEC, ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [10, 5] <- "(1 | UniqueID)"
table.aic [10, 6] <-  AIC (model.lme4.du8.s.ef.veg)

### HUMAN AND VEGETATION ###
model.lme4.du8.s.hd.veg <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                              std.distance_to_cut_5to9yo +
                                              std.distance_to_cut_10to29yo + 
                                              std.distance_to_cut_30orOveryo +
                                              std.distance_to_resource_road + 
                                              std.distance_to_pipeline + 
                                              std.vri_proj_age + 
                                               std.vri_site_index + 
                                               std.vri_herb_cover_pct + 
                                               std.vri_shrub_crown_close +  
                                               bec_label_reclass2 +
                                               (1 | uniqueID), 
                                   data = rsf.data.combo.du8.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# AIC
table.aic [11, 1] <- "DU8"
table.aic [11, 2] <- "Summer"
table.aic [11, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [11, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DRR, DPipe, BEC, ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [11, 5] <- "(1 | UniqueID)"
table.aic [11, 6] <-  AIC (model.lme4.du8.s.hd.veg)

### NATURAL DISTURB AND VEGETATION ###
model.lme4.du8.s.nd.veg <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                                             fire_1to5yo + fire_6to25yo + fire_over25yo + 
                                             std.vri_proj_age + 
                                             std.vri_site_index + 
                                             std.vri_herb_cover_pct + 
                                             std.vri_shrub_crown_close +  
                                             bec_label_reclass2 +
                                             (1 | uniqueID), 
                                   data = rsf.data.combo.du8.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# AIC
table.aic [12, 1] <- "DU8"
table.aic [12, 2] <- "Summer"
table.aic [12, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [12, 4] <- "Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, BEC, ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [12, 5] <- "(1 | UniqueID)"
table.aic [12, 6] <-  AIC (model.lme4.du8.s.nd.veg)

### ENDURING FEATURES, HUMAN DISTURBANCE, NATURAL DISTURBANCE ###
model.lme4.du8.s.ef.hd.nd <- glmer (pttype ~ std.slope + 
                                               std.distance_to_watercourse +
                                               std.distance_to_lake +
                                               std.distance_to_cut_1to4yo + 
                                               std.distance_to_cut_5to9yo +
                                               std.distance_to_cut_10to29yo + 
                                               std.distance_to_cut_30orOveryo +
                                               std.distance_to_resource_road + 
                                               std.distance_to_pipeline + 
                                               beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                               fire_6to25yo + fire_over25yo +
                                               (1 | uniqueID), 
                                     data = rsf.data.combo.du8.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [13, 1] <- "DU8"
table.aic [13, 2] <- "Summer"
table.aic [13, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [13, 4] <- "Slope, DWat, DLake, DC1to4, DC5to9, DC10to29, DCover30, DRR, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [13, 5] <- "(1 | UniqueID)"
table.aic [13, 6] <-  AIC (model.lme4.du8.s.ef.hd.nd)

### ENDURING FEATURES, HUMAN DISTURBANCE, VEGETATION ###
model.lme4.du8.s.ef.hd.veg <- glmer (pttype ~ std.slope + 
                                                std.distance_to_watercourse +
                                                std.distance_to_lake +
                                                std.distance_to_cut_1to4yo + 
                                                std.distance_to_cut_5to9yo +
                                                std.distance_to_cut_10to29yo + 
                                                std.distance_to_cut_30orOveryo +
                                                std.distance_to_resource_road + 
                                                std.distance_to_pipeline + 
                                                std.vri_proj_age + 
                                                std.vri_site_index + 
                                                std.vri_herb_cover_pct + 
                                                std.vri_shrub_crown_close + 
                                                bec_label_reclass2 +
                                                (1 | uniqueID), 
                                      data = rsf.data.combo.du8.s, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [14, 1] <- "DU8"
table.aic [14, 2] <- "Summer"
table.aic [14, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [14, 4] <- "Slope, DWat, DLake, DC1to4, DC5to9, DC10to29, DCover30, DRR, DPipe, BEC, ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [14, 5] <- "(1 | UniqueID)"
table.aic [14, 6] <-  AIC (model.lme4.du8.s.ef.hd.veg)

### ENDURING FEATURES, NATURAL DISTURBANCE, VEGETATION ###
model.lme4.du8.s.ef.nd.veg <- glmer (pttype ~ std.slope + 
                                               std.distance_to_watercourse +
                                                std.distance_to_lake +
                                                beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                fire_6to25yo + fire_over25yo +
                                                std.vri_proj_age + 
                                                std.vri_site_index + 
                                                std.vri_herb_cover_pct + 
                                                std.vri_shrub_crown_close + 
                                                bec_label_reclass2 +
                                                (1 | uniqueID), 
                                      data = rsf.data.combo.du8.s, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [15, 1] <- "DU8"
table.aic [15, 2] <- "Summer"
table.aic [15, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [15, 4] <- "Slope, DWat, DLake, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, BEC, ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [15, 5] <- "(1 | UniqueID)"
table.aic [15, 6] <-  AIC (model.lme4.du8.s.ef.nd.veg)

### HUMAN DISTURBANCE, NATURAL DISTURBANCE, VEGETATION ###
model.lme4.du8.s.hd.nd.veg <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                std.distance_to_cut_5to9yo +
                                                std.distance_to_cut_10to29yo + 
                                                std.distance_to_cut_30orOveryo +
                                                std.distance_to_resource_road + 
                                                std.distance_to_pipeline + 
                                                beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                fire_6to25yo + fire_over25yo +
                                                std.vri_proj_age + 
                                                std.vri_site_index + 
                                                std.vri_herb_cover_pct + 
                                                std.vri_shrub_crown_close + 
                                                bec_label_reclass2 +
                                                (1 | uniqueID), 
                                      data = rsf.data.combo.du8.s, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [16, 1] <- "DU8"
table.aic [16, 2] <- "Summer"
table.aic [16, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [16, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DRR, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, BEC, ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [16, 5] <- "(1 | UniqueID)"
table.aic [16, 6] <-  AIC (model.lme4.du8.s.hd.nd.veg)

### ENDURING FEATURES, HUMAN DISTURBANCE, NATURAL DISTURBANCE, VEGETATION ###
model.lme4.du8.s.ef.hd.nd.veg <- glmer (pttype ~ std.slope + 
                                                   std.distance_to_watercourse +
                                                   std.distance_to_lake +
                                                   std.distance_to_cut_1to4yo + 
                                                   std.distance_to_cut_5to9yo +
                                                   std.distance_to_cut_10to29yo + 
                                                   std.distance_to_cut_30orOveryo +
                                                   std.distance_to_resource_road +
                                                   std.distance_to_pipeline + 
                                                   beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                   fire_6to25yo + fire_over25yo +
                                                   std.vri_proj_age + 
                                                   std.vri_site_index + 
                                                   std.vri_herb_cover_pct + 
                                                   std.vri_shrub_crown_close + 
                                                   bec_label_reclass2 +
                                                   (1 | uniqueID), 
                                         data = rsf.data.combo.du8.s, 
                                         family = binomial (link = "logit"),
                                         verbose = T) 
ss <- getME (model.lme4.du8.s.ef.hd.nd.veg, c ("theta","fixef"))
model.lme4.du8.s.ef.hd.nd.veg <- update (model.lme4.du8.s.ef.hd.nd.veg, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [17, 1] <- "DU8"
table.aic [17, 2] <- "Summer"
table.aic [17, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [17, 4] <- "Slope, DWat, DLake, DC1to4, DC5to9, DC10to29, DCover30, DRR, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, BEC, ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [17, 5] <- "(1 | UniqueID)"
table.aic [17, 6] <-  AIC (model.lme4.du8.s.ef.hd.nd.veg)

### ENDURING FEATURES, HUMAN DISTURBANCE, NATURAL DISTURBANCE, VEGETATION, CLIMATE ###
model.lme4.du8.s.ef.hd.nd.veg.clim <- glmer (pttype ~ std.slope + 
                                                     std.distance_to_watercourse +
                                                     std.distance_to_lake +
                                                     std.distance_to_cut_1to4yo + 
                                                     std.distance_to_cut_5to9yo +
                                                     std.distance_to_cut_10to29yo + 
                                                     std.distance_to_cut_30orOveryo +
                                                     std.distance_to_resource_road +
                                                     std.distance_to_pipeline + 
                                                     beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                     fire_6to25yo + fire_over25yo +
                                                     std.vri_proj_age + 
                                                     std.vri_site_index + 
                                                     std.vri_herb_cover_pct + 
                                                     std.vri_shrub_crown_close +
                                                     bec_label_reclass2 +
                                                     std.mean_annual_ppt +
                                                     (1 | uniqueID), 
                                         data = rsf.data.combo.du8.s, 
                                         family = binomial (link = "logit"),
                                         verbose = T) 
# AIC
table.aic [18, 1] <- "DU8"
table.aic [18, 2] <- "Summer"
table.aic [18, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [18, 4] <- "Slope, DWat, DLake, DC1to4, DC5to9, DC10to29, DCover30, DRR, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, MAPpt, BEC, ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [18, 5] <- "(1 | UniqueID)"
table.aic [18, 6] <-  AIC (model.lme4.du8.s.ef.hd.nd.veg.clim)

### ENDURING FEATURES, HUMAN DISTURBANCE, NATURAL DISTURBANCE, CLIMATE ###
model.lme4.du8.s.ef.hd.nd.clim <- glmer (pttype ~ std.slope + 
                                                  std.distance_to_watercourse +
                                                  std.distance_to_lake +
                                                  std.distance_to_cut_1to4yo + 
                                                  std.distance_to_cut_5to9yo +
                                                  std.distance_to_cut_10to29yo + 
                                                  std.distance_to_cut_30orOveryo +
                                                  std.distance_to_resource_road +
                                                  std.distance_to_pipeline + 
                                                  beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                  fire_6to25yo + fire_over25yo +
                                                  std.mean_annual_ppt +
                                                  (1 | uniqueID), 
                                              data = rsf.data.combo.du8.s, 
                                              family = binomial (link = "logit"),
                                              verbose = T) 
# AIC
table.aic [19, 1] <- "DU8"
table.aic [19, 2] <- "Summer"
table.aic [19, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [19, 4] <- "Slope, DWat, DLake, DC1to4, DC5to9, DC10to29, DCover30, DRR, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, MAPpt"
table.aic [19, 5] <- "(1 | UniqueID)"
table.aic [19, 6] <-  AIC (model.lme4.du8.s.ef.hd.nd.clim)

### ENDURING FEATURES, HUMAN DISTURBANCE, NATURAL DISTURBANCE, VEGETATION ###
model.lme4.du8.s.ef.hd.nd.veg <- glmer (pttype ~ std.slope + 
                                                  std.distance_to_watercourse +
                                                  std.distance_to_lake +
                                                  std.distance_to_cut_1to4yo + 
                                                  std.distance_to_cut_5to9yo +
                                                  std.distance_to_cut_10to29yo + 
                                                  std.distance_to_cut_30orOveryo +
                                                  std.distance_to_resource_road +
                                                  std.distance_to_pipeline + 
                                                  beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                  fire_6to25yo + fire_over25yo +
                                                  std.vri_proj_age + 
                                                  std.vri_site_index + 
                                                  std.vri_herb_cover_pct + 
                                                  std.vri_shrub_crown_close +
                                                  bec_label_reclass2 +
                                                  (1 | uniqueID), 
                                              data = rsf.data.combo.du8.s, 
                                              family = binomial (link = "logit"),
                                              verbose = T) 
ss <- getME (model.lme4.du8.s.ef.hd.nd.veg, c ("theta","fixef"))
model.lme4.du8.s.ef.hd.nd.veg <- update (model.lme4.du8.s.ef.hd.nd.veg, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [20, 1] <- "DU8"
table.aic [20, 2] <- "Summer"
table.aic [20, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [20, 4] <- "Slope, DWat, DLake, DC1to4, DC5to9, DC10to29, DCover30, DRR, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, BEC, ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [20, 5] <- "(1 | UniqueID)"
table.aic [20, 6] <-  AIC (model.lme4.du8.s.ef.hd.nd.veg)

### ENDURING FEATURES, HUMAN DISTURBANCE, VEGETATION, CLIMATE ###
model.lme4.du8.s.ef.hd.veg.clim <- glmer (pttype ~ std.slope + 
                                                    std.distance_to_watercourse +
                                                    std.distance_to_lake +
                                                    std.distance_to_cut_1to4yo + 
                                                    std.distance_to_cut_5to9yo +
                                                    std.distance_to_cut_10to29yo + 
                                                    std.distance_to_cut_30orOveryo +
                                                    std.distance_to_resource_road +
                                                    std.distance_to_pipeline + 
                                                    std.vri_proj_age + 
                                                    std.vri_site_index + 
                                                    std.vri_herb_cover_pct + 
                                                    std.vri_shrub_crown_close +
                                                    bec_label_reclass2 +
                                                    std.mean_annual_ppt +
                                                    (1 | uniqueID), 
                                              data = rsf.data.combo.du8.s, 
                                              family = binomial (link = "logit"),
                                              verbose = T) 
ss <- getME (model.lme4.du8.s.ef.hd.veg.clim, c ("theta","fixef"))
model.lme4.du8.s.ef.hd.veg.clim <- update (model.lme4.du8.s.ef.hd.veg.clim, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [21, 1] <- "DU8"
table.aic [21, 2] <- "Summer"
table.aic [21, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [21, 4] <- "Slope, DWat, DLake, DC1to4, DC5to9, DC10to29, DCover30, DRR, DPipe, MAPpt, BEC, ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [21, 5] <- "(1 | UniqueID)"
table.aic [21, 6] <-  AIC (model.lme4.du8.s.ef.hd.veg.clim)

### ENDURING FEATURES, NATURAL DISTURBANCE, VEGETATION, CLIMATE ###
model.lme4.du8.s.ef.nd.veg.clim <- glmer (pttype ~ std.slope + 
                                                      std.distance_to_watercourse +
                                                      std.distance_to_lake +
                                                      beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                      fire_6to25yo + fire_over25yo +
                                                      std.vri_proj_age + 
                                                      std.vri_site_index + 
                                                      std.vri_herb_cover_pct + 
                                                      std.vri_shrub_crown_close +
                                                      bec_label_reclass2 +
                                                      std.mean_annual_ppt +
                                                      (1 | uniqueID), 
                                              data = rsf.data.combo.du8.s, 
                                              family = binomial (link = "logit"),
                                              verbose = T) 
# AIC
table.aic [22, 1] <- "DU8"
table.aic [22, 2] <- "Summer"
table.aic [22, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [22, 4] <- "Slope, DWat, DLake, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, MAPpt, BEC, ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [22, 5] <- "(1 | UniqueID)"
table.aic [22, 6] <-  AIC (model.lme4.du8.s.ef.nd.veg.clim)

### HUMAN DISTURBANCE, NATURAL DISTURBANCE, VEGETATION, CLIMATE ###
model.lme4.du8.s.hd.nd.veg.clim <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                    std.distance_to_cut_5to9yo +
                                                    std.distance_to_cut_10to29yo + 
                                                    std.distance_to_cut_30orOveryo +
                                                    std.distance_to_resource_road +
                                                    std.distance_to_pipeline + 
                                                    beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                    fire_6to25yo + fire_over25yo +
                                                    std.vri_proj_age + 
                                                    std.vri_site_index + 
                                                    std.vri_herb_cover_pct + 
                                                    std.vri_shrub_crown_close +
                                                    bec_label_reclass2 +
                                                    std.mean_annual_ppt +
                                                    (1 | uniqueID), 
                                           data = rsf.data.combo.du8.s, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
ss <- getME (model.lme4.du8.s.hd.nd.veg.clim, c ("theta","fixef"))
model.lme4.du8.s.hd.nd.veg.clim <- update (model.lme4.du8.s.hd.nd.veg.clim, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [23, 1] <- "DU8"
table.aic [23, 2] <- "Summer"
table.aic [23, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [23, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DRR, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, MAPpt, BEC, ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [23, 5] <- "(1 | UniqueID)"
table.aic [23, 6] <-  AIC (model.lme4.du8.s.hd.nd.veg.clim)

### ENDURING FEATURES, HUMAN DISTURBANCE, CLIMATE ###
model.lme4.du8.s.ef.hd.nd <- glmer (pttype ~ std.slope + 
                                                std.distance_to_watercourse +
                                                std.distance_to_lake +
                                                std.distance_to_cut_1to4yo + 
                                                std.distance_to_cut_5to9yo +
                                                std.distance_to_cut_10to29yo + 
                                                std.distance_to_cut_30orOveryo +
                                                std.distance_to_resource_road +
                                                std.distance_to_pipeline + 
                                                std.mean_annual_ppt +
                                                (1 | uniqueID), 
                                              data = rsf.data.combo.du8.s, 
                                              family = binomial (link = "logit"),
                                              verbose = T) 
# AIC
table.aic [24, 1] <- "DU8"
table.aic [24, 2] <- "Summer"
table.aic [24, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [24, 4] <- "Slope, DWat, DLake, DC1to4, DC5to9, DC10to29, DCover30, DRR, DPipe, MAPpt"
table.aic [24, 5] <- "(1 | UniqueID)"
table.aic [24, 6] <-  AIC (model.lme4.du8.s.ef.hd.nd)

### ENDURING FEATURES, NATURAL DISTURBANCE, CLIMATE ###
model.lme4.du8.s.ef.nd.clim <- glmer (pttype ~ std.slope + 
                                                std.distance_to_watercourse +
                                                std.distance_to_lake +
                                                beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                fire_6to25yo + fire_over25yo + 
                                                std.mean_annual_ppt +
                                                (1 | uniqueID), 
                                      data = rsf.data.combo.du8.s, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [25, 1] <- "DU8"
table.aic [25, 2] <- "Summer"
table.aic [25, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [25, 4] <- "Slope, DWat, DLake, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, MAPpt"
table.aic [25, 5] <- "(1 | UniqueID)"
table.aic [25, 6] <-  AIC (model.lme4.du8.s.ef.nd.clim)

### ENDURING FEATURES, CLIMATE, VEGETATION ###
model.lme4.du8.s.ef.veg.clim <- glmer (pttype ~ std.slope + 
                                                  std.distance_to_watercourse +
                                                  std.distance_to_lake +
                                                  std.vri_proj_age + 
                                                  std.vri_site_index + 
                                                  std.vri_herb_cover_pct + 
                                                  std.vri_shrub_crown_close +
                                                  bec_label_reclass2 +
                                                  std.mean_annual_ppt +
                                                  (1 | uniqueID), 
                                          data = rsf.data.combo.du8.s, 
                                          family = binomial (link = "logit"),
                                          verbose = T) 
ss <- getME (model.lme4.du8.s.ef.veg.clim, c ("theta","fixef"))
model.lme4.du8.s.ef.veg.clim <- update (model.lme4.du8.s.ef.veg.clim, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [26, 1] <- "DU8"
table.aic [26, 2] <- "Summer"
table.aic [26, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [26, 4] <- "Slope, DWat, DLake, MAPpt, BEC, ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [26, 5] <- "(1 | UniqueID)"
table.aic [26, 6] <-  AIC (model.lme4.du8.s.ef.veg.clim)

### ENDURING FEATURES, NATURAL DISTURBANCE, CLIMATE ###
model.lme4.du8.s.ef.nd.clim <- glmer (pttype ~ std.slope + 
                                                std.distance_to_watercourse +
                                                std.distance_to_lake +
                                                beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                fire_6to25yo + fire_over25yo + 
                                                std.mean_annual_ppt +
                                                (1 | uniqueID), 
                                      data = rsf.data.combo.du8.s, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [27, 1] <- "DU8"
table.aic [27, 2] <- "Summer"
table.aic [27, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [27, 4] <- "Slope, DWat, DLake, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, MAPpt"
table.aic [27, 5] <- "(1 | UniqueID)"
table.aic [27, 6] <-  AIC (model.lme4.du8.s.ef.nd.clim)

### HUMAN DISTURBANCE, NATURAL DISTURBANCE, CLIMATE ###
model.lme4.du8.s.ef.nd.clim <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                std.distance_to_cut_5to9yo +
                                                std.distance_to_cut_10to29yo + 
                                                std.distance_to_cut_30orOveryo +
                                                std.distance_to_resource_road +
                                                std.distance_to_pipeline + 
                                                beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                fire_6to25yo + fire_over25yo +
                                                std.mean_annual_ppt +
                                                (1 | uniqueID), 
                                       data = rsf.data.combo.du8.s, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [28, 1] <- "DU8"
table.aic [28, 2] <- "Summer"
table.aic [28, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [28, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DRR, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, MAPpt"
table.aic [28, 5] <- "(1 | UniqueID)"
table.aic [28, 6] <-  AIC (model.lme4.du8.s.ef.nd.clim)

### HUMAN DISTURBANCE, CLIMATE, VEG ###
model.lme4.du8.s.hd.clim.veg <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                std.distance_to_cut_5to9yo +
                                                std.distance_to_cut_10to29yo + 
                                                std.distance_to_cut_30orOveryo +
                                                std.distance_to_resource_road +
                                                std.distance_to_pipeline +
                                                std.mean_annual_ppt +
                                                std.vri_proj_age + 
                                                std.vri_site_index + 
                                                std.vri_herb_cover_pct + 
                                                std.vri_shrub_crown_close +
                                                bec_label_reclass2 +
                                                (1 | uniqueID), 
                                      data = rsf.data.combo.du8.s, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [29, 1] <- "DU8"
table.aic [29, 2] <- "Summer"
table.aic [29, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [29, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DRR, DPipe, MAPpt, BEC, ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [29, 5] <- "(1 | UniqueID)"
table.aic [29, 6] <-  AIC (model.lme4.du8.s.hd.clim.veg)

### NATURAL DISTURBANCE, CLIMATE , VEGETATION ###
model.lme4.du8.s.nd.clim.veg <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                fire_6to25yo + fire_over25yo +
                                                std.vri_proj_age + 
                                                std.vri_site_index + 
                                                std.vri_herb_cover_pct + 
                                                std.vri_shrub_crown_close +
                                                bec_label_reclass2 +
                                               std.mean_annual_ppt +
                                               (1 | uniqueID), 
                                     data = rsf.data.combo.du8.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [30, 1] <- "DU8"
table.aic [30, 2] <- "Summer"
table.aic [30, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [30, 4] <- "Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, MAPpt, BEC, ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [30, 5] <- "(1 | UniqueID)"
table.aic [30, 6] <-  AIC (model.lme4.du8.s.nd.clim.veg)

### ENDURING FEATURES, CLIMATE ###
model.lme4.du8.s.ef.clim <- glmer (pttype ~ std.slope + 
                                                std.distance_to_watercourse +
                                                std.distance_to_lake +
                                                std.mean_annual_ppt +
                                                (1 | uniqueID), 
                                              data = rsf.data.combo.du8.s, 
                                              family = binomial (link = "logit"),
                                              verbose = T) 
# AIC
table.aic [31, 1] <- "DU8"
table.aic [31, 2] <- "Summer"
table.aic [31, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [31, 4] <- "Slope, DWat, DLake, MAPpt"
table.aic [31, 5] <- "(1 | UniqueID)"
table.aic [31, 6] <-  AIC (model.lme4.du8.s.ef.clim)

###  HUMAN DISTURBANCE, CLIMATE ###
model.lme4.du8.s.hd.clim <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                std.distance_to_cut_5to9yo +
                                                std.distance_to_cut_10to29yo + 
                                                std.distance_to_cut_30orOveryo +
                                                std.distance_to_resource_road +
                                                std.distance_to_pipeline + 
                                                std.mean_annual_ppt +
                                                (1 | uniqueID), 
                                              data = rsf.data.combo.du8.s, 
                                              family = binomial (link = "logit"),
                                              verbose = T) 
# AIC
table.aic [32, 1] <- "DU8"
table.aic [32, 2] <- "Summer"
table.aic [32, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [32, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DRR, DPipe, MAPpt"
table.aic [32, 5] <- "(1 | UniqueID)"
table.aic [32, 6] <-  AIC (model.lme4.du8.s.hd.clim)

### NATURAL DISTURBANCE, CLIMATE ###
model.lme4.du8.s.nd.clim <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                            fire_6to25yo + fire_over25yo +
                                                std.mean_annual_ppt +
                                                (1 | uniqueID), 
                                   data = rsf.data.combo.du8.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# AIC
table.aic [33, 1] <- "DU8"
table.aic [33, 2] <- "Summer"
table.aic [33, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [33, 4] <- "Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, MAPpt"
table.aic [33, 5] <- "(1 | UniqueID)"
table.aic [33, 6] <-  AIC (model.lme4.du8.s.nd.clim)

### VEGETATION, CLIMATE ###
model.lme4.du8.s.veg.clim <- glmer (pttype ~ std.vri_proj_age + 
                                                std.vri_site_index + 
                                                std.vri_herb_cover_pct + 
                                                std.vri_shrub_crown_close +
                                                bec_label_reclass2 +
                                                std.mean_annual_ppt +
                                                (1 | uniqueID), 
                                              data = rsf.data.combo.du8.s, 
                                              family = binomial (link = "logit"),
                                              verbose = T) 
# AIC
table.aic [34, 1] <- "DU8"
table.aic [34, 2] <- "Summer"
table.aic [34, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [34, 4] <- "MAPpt, BEC, ShrubClosure, HerbCover, TreeAge, SiteIndex"
table.aic [34, 5] <- "(1 | UniqueID)"
table.aic [34, 6] <-  AIC (model.lme4.du8.s.veg.clim)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\summer\\table_aic_all_top.csv", sep = ",")

## AIC comparison of MODELS ## 
table.aic$AIC <- as.numeric (table.aic$AIC)
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [c (1:34), 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [4, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [5, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [6, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [7, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [8, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [9, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [10, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [11, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [12, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [13, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [14, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [15, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [16, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [17, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [18, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [19, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [20, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [21, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [22, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [23, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [24, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [25, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [26, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [27, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [28, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [29, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [30, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [31, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [32, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [33, 6] - min (table.aic [c (1:34), 6])))),
                    (exp (-0.5 * (table.aic [34, 6] - min (table.aic [c (1:34), 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [4, 7] <- round ((exp (-0.5 * (table.aic [4, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [5, 7] <- round ((exp (-0.5 * (table.aic [5, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [6, 7] <- round ((exp (-0.5 * (table.aic [6, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [7, 7] <- round ((exp (-0.5 * (table.aic [7, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [8, 7] <- round ((exp (-0.5 * (table.aic [8, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [9, 7] <- round ((exp (-0.5 * (table.aic [9, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [10, 7] <- round ((exp (-0.5 * (table.aic [10, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [11, 7] <- round ((exp (-0.5 * (table.aic [11, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [12, 7] <- round ((exp (-0.5 * (table.aic [12, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [13, 7] <- round ((exp (-0.5 * (table.aic [13, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [14, 7] <- round ((exp (-0.5 * (table.aic [14, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [15, 7] <- round ((exp (-0.5 * (table.aic [15, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [16, 7] <- round ((exp (-0.5 * (table.aic [16, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [17, 7] <- round ((exp (-0.5 * (table.aic [17, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [18, 7] <- round ((exp (-0.5 * (table.aic [18, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [19, 7] <- round ((exp (-0.5 * (table.aic [19, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [20, 7] <- round ((exp (-0.5 * (table.aic [20, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [21, 7] <- round ((exp (-0.5 * (table.aic [21, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [22, 7] <- round ((exp (-0.5 * (table.aic [22, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [23, 7] <- round ((exp (-0.5 * (table.aic [23, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [24, 7] <- round ((exp (-0.5 * (table.aic [24, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [25, 7] <- round ((exp (-0.5 * (table.aic [25, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [26, 7] <- round ((exp (-0.5 * (table.aic [26, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [27, 7] <- round ((exp (-0.5 * (table.aic [27, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [28, 7] <- round ((exp (-0.5 * (table.aic [28, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [29, 7] <- round ((exp (-0.5 * (table.aic [29, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [30, 7] <- round ((exp (-0.5 * (table.aic [30, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [31, 7] <- round ((exp (-0.5 * (table.aic [31, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [32, 7] <- round ((exp (-0.5 * (table.aic [32, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [33, 7] <- round ((exp (-0.5 * (table.aic [33, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)
table.aic [34, 7] <- round ((exp (-0.5 * (table.aic [34, 6] - min (table.aic [c (1:34), 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\summer\\table_aic_all_top.csv", sep = ",")

save (model.lme4.du8.s.ef.hd.nd.veg.clim, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_du8_s_final.rda")

# Create table of model coefficients from top model
model.coeffs <- as.data.frame (coef (summary (model.lme4.du8.s.ef.hd.nd.veg.clim)))
model.coeffs$mean <- 0
model.coeffs$sd <- 0

model.coeffs [2, 5] <- mean (rsf.data.combo.du8.s$slope)
model.coeffs [3, 5] <- mean (rsf.data.combo.du8.s$distance_to_watercourse)
model.coeffs [4, 5] <- mean (rsf.data.combo.du8.s$distance_to_lake)
model.coeffs [5, 5] <- mean (rsf.data.combo.du8.s$distance_to_cut_1to4yo)
model.coeffs [6, 5] <- mean (rsf.data.combo.du8.s$distance_to_cut_5to9yo)
model.coeffs [7, 5] <- mean (rsf.data.combo.du8.s$distance_to_cut_10to29yo)
model.coeffs [8, 5] <- mean (rsf.data.combo.du8.s$distance_to_cut_30orOveryo)
model.coeffs [9, 5] <- mean (rsf.data.combo.du8.s$distance_to_resource_road)
model.coeffs [10, 5] <- mean (rsf.data.combo.du8.s$distance_to_pipeline)
model.coeffs [16, 5] <- mean (rsf.data.combo.du8.s$vri_proj_age)
model.coeffs [17, 5] <- mean (rsf.data.combo.du8.s$vri_site_index)
model.coeffs [18, 5] <- mean (rsf.data.combo.du8.s$vri_herb_cover_pct)
model.coeffs [19, 5] <- mean (rsf.data.combo.du8.s$vri_shrub_crown_close)
model.coeffs [28, 5] <- mean (rsf.data.combo.du8.s$mean_annual_ppt)

model.coeffs [2, 6] <- sd (rsf.data.combo.du8.s$slope)
model.coeffs [3, 6] <- sd (rsf.data.combo.du8.s$distance_to_watercourse)
model.coeffs [4, 6] <- sd (rsf.data.combo.du8.s$distance_to_lake)
model.coeffs [5, 6] <- sd (rsf.data.combo.du8.s$distance_to_cut_1to4yo)
model.coeffs [6, 6] <- sd (rsf.data.combo.du8.s$distance_to_cut_5to9yo)
model.coeffs [7, 6] <- sd (rsf.data.combo.du8.s$distance_to_cut_10to29yo)
model.coeffs [8, 6] <- sd (rsf.data.combo.du8.s$distance_to_cut_30orOveryo)
model.coeffs [9, 6] <- sd (rsf.data.combo.du8.s$distance_to_resource_road)
model.coeffs [10, 6] <- sd (rsf.data.combo.du8.s$distance_to_pipeline)
model.coeffs [16, 6] <- sd (rsf.data.combo.du8.s$vri_proj_age)
model.coeffs [17, 6] <- sd (rsf.data.combo.du8.s$vri_site_index)
model.coeffs [18, 6] <- sd (rsf.data.combo.du8.s$vri_herb_cover_pct)
model.coeffs [19, 6] <- sd (rsf.data.combo.du8.s$vri_shrub_crown_close)
model.coeffs [28, 6] <- sd (rsf.data.combo.du8.s$sd_annual_ppt)

write.table (model.coeffs, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\model_coefficients\\table_du8_s_model_coeffs_top.csv", sep = ",")

##########################
### k-fold Validation ###
########################
df.unique.id <- as.data.frame (unique (rsf.data.combo.du8.s$uniqueID))
names (df.unique.id) [1] <-"uniqueID"
df.unique.id$group <- rep_len (1:5, nrow (df.unique.id)) # orderly selection of groups
rsf.data.combo.du8.s <- dplyr::full_join (rsf.data.combo.du8.s, df.unique.id, by = "uniqueID")

### FOLD 1 ###
train.data.1 <- rsf.data.combo.du8.s %>%
  filter (group < 5)
test.data.1 <- rsf.data.combo.du8.s %>%
  filter (group == 5)

model.lme4.du8.s.train1 <- glmer (pttype ~ std.slope + 
                                            std.distance_to_watercourse +
                                            std.distance_to_lake +
                                            std.distance_to_cut_1to4yo + 
                                            std.distance_to_cut_5to9yo +
                                            std.distance_to_cut_10to29yo + 
                                            std.distance_to_cut_30orOveryo +
                                            std.distance_to_resource_road +
                                            std.distance_to_pipeline + 
                                            beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                            fire_6to25yo + fire_over25yo +
                                            std.vri_proj_age + 
                                            std.vri_site_index + 
                                            std.vri_herb_cover_pct + 
                                            std.vri_shrub_crown_close +
                                            bec_label_reclass2 +
                                            std.mean_annual_ppt +
                                            (1 | uniqueID), 
                                   data = train.data.1, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
ss <- getME (model.lme4.du8.s.train1, c ("theta","fixef"))
model.lme4.du8.s.train1 <- update (model.lme4.du8.s.train1, start = ss)
# create a table of k-fold outputs
table.kfold <- data.frame (matrix (ncol = 12, nrow = 50))
colnames (table.kfold) <- c ("test.number", "bin.mid", "bin.weight", "utilization", "used.count", 
                             "expected.count", "lm.slope", "lm.slope.p.value", "lm.intercept",
                             "lm.intercept.p.value", "adj.R.sq", "chi.sq.p.value")
table.kfold [c (1:10), 1] <- 1
table.kfold$bin.mid <- c (0.04, 0.12, 0.20, 0.28, 0.36, 0.44, 0.52, 0.60, 0.68, 0.76)

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.combo.du8.s$preds.train1 <- predict (model.lme4.du8.s.train1, 
                                               newdata = rsf.data.combo.du8.s, 
                                               re.form = NA, type = "response")

ggplot (data = rsf.data.combo.du8.s, aes (preds.train1)) +
        geom_histogram()
max (rsf.data.combo.du8.s$preds.train1)
min (rsf.data.combo.du8.s$preds.train1)

rsf.data.combo.du8.s$preds.train1.class <- cut (rsf.data.combo.du8.s$preds.train1, 
                                                 breaks = c (-Inf, 0.08, 0.16, 0.24, 0.32, 0.40, 0.48, 0.56, 0.64, 0.72, Inf), 
                                                 labels = c ("0.04", "0.12", "0.20", "0.28", "0.36",
                                                             "0.44", "0.52", "0.60", "0.68", "0.76"))
write.csv (rsf.data.combo.du8.s, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du8_s.csv")
rsf.data.combo.du8.s.avail <- dplyr::filter (rsf.data.combo.du8.s, pttype == 0)

table.kfold [1, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train1.class == "0.04")) * 0.05) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [2, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train1.class == "0.12")) * 0.15)
table.kfold [3, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train1.class == "0.20")) * 0.25)
table.kfold [4, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train1.class == "0.28")) * 0.35)
table.kfold [5, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train1.class == "0.36")) * 0.45)
table.kfold [6, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train1.class == "0.44")) * 0.55)
table.kfold [7, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train1.class == "0.52")) * 0.65)
table.kfold [8, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train1.class == "0.60")) * 0.75)
table.kfold [9, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train1.class == "0.68")) * 0.85)
table.kfold [10, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train1.class == "0.76")) * 0.95)

table.kfold [1, 4] <- table.kfold [1, 3] / sum  (table.kfold [c (1:10), 3]) 
table.kfold [2, 4] <- table.kfold [2, 3] / sum  (table.kfold [c (1:10), 3]) 
table.kfold [3, 4] <- table.kfold [3, 3] / sum  (table.kfold [c (1:10), 3]) 
table.kfold [4, 4] <- table.kfold [4, 3] / sum  (table.kfold [c (1:10), 3]) 
table.kfold [5, 4] <- table.kfold [5, 3] / sum  (table.kfold [c (1:10), 3]) 
table.kfold [6, 4] <- table.kfold [6, 3] / sum  (table.kfold [c (1:10), 3]) 
table.kfold [7, 4] <- table.kfold [7, 3] / sum  (table.kfold [c (1:10), 3]) 
table.kfold [8, 4] <- table.kfold [8, 3] / sum  (table.kfold [c (1:10), 3])
table.kfold [9, 4] <- table.kfold [9, 3] / sum  (table.kfold [c (1:10), 3]) 
table.kfold [10, 4] <- table.kfold [10, 3] / sum  (table.kfold [c (1:10), 3]) 

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\table_kfold_valid_du8_s.csv")

# data for estimating use
test.data.1$preds <- predict (model.lme4.du8.s.train1, newdata = test.data.1, re.form = NA, type = "response")
test.data.1$preds.class <- cut (test.data.1$preds, # put into classes; 0 to 0.4, based on max and min values
                                breaks = c (-Inf, 0.08, 0.16, 0.24, 0.32, 0.40, 0.48, 0.56, 0.64, 0.72, Inf), 
                                labels = c ("0.04", "0.12", "0.20", "0.28", "0.36",
                                            "0.44", "0.52", "0.60", "0.68", "0.76"))
write.csv (test.data.1, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\rsf_preds_du8_s_train1.csv")
test.data.1.used <- dplyr::filter (test.data.1, pttype == 1)

table.kfold [1, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.04"))
table.kfold [2, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.12"))
table.kfold [3, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.20"))
table.kfold [4, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.28"))
table.kfold [5, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.36"))
table.kfold [6, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.44"))
table.kfold [7, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.52"))
table.kfold [8, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.60"))
table.kfold [9, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.68"))
table.kfold [10, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.76"))

table.kfold [1, 6] <- round (sum (table.kfold [c (1:10), 5]) * table.kfold [1, 4], 0) # expected number of uses in each bin
table.kfold [2, 6] <- round (sum (table.kfold [c (1:10), 5]) * table.kfold [2, 4], 0) # expected number of uses in each bin
table.kfold [3, 6] <- round (sum (table.kfold [c (1:10), 5]) * table.kfold [3, 4], 0) # expected number of uses in each bin
table.kfold [4, 6] <- round (sum (table.kfold [c (1:10), 5]) * table.kfold [4, 4], 0) # expected number of uses in each bin
table.kfold [5, 6] <- round (sum (table.kfold [c (1:10), 5]) * table.kfold [5, 4], 0) # expected number of uses in each bin
table.kfold [6, 6] <- round (sum (table.kfold [c (1:10), 5]) * table.kfold [6, 4], 0) # expected number of uses in each bin
table.kfold [7, 6] <- round (sum (table.kfold [c (1:10), 5]) * table.kfold [7, 4], 0) # expected number of uses in each bin
table.kfold [8, 6] <- round (sum (table.kfold [c (1:10), 5]) * table.kfold [8, 4], 0) # expected number of uses in each bin
table.kfold [9, 6] <- round (sum (table.kfold [c (1:10), 5]) * table.kfold [9, 4], 0) # expected number of uses in each bin
table.kfold [10, 6] <- round (sum (table.kfold [c (1:10), 5]) * table.kfold [10, 4], 0) # expected number of uses in each bin

glm.kfold.test1 <- lm (used.count ~ expected.count, 
                       data = dplyr::filter(table.kfold, test.number == 1))
summary (glm.kfold.test1)

table.kfold [1, 7] <- 0.97028
table.kfold [1, 8] <- "<0.001"
table.kfold [1, 9] <- 30.61729
table.kfold [1, 10] <- 0.713
table.kfold [1, 11] <- 0.9723

chisq.test(dplyr::filter(table.kfold, test.number == 1)$used.count, dplyr::filter(table.kfold, test.number == 1)$expected.count)
table.kfold [1, 12] <- 0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\table_kfold_valid_du8_s.csv")

ggplot (dplyr::filter(table.kfold, test.number == 1), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 1 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 4000, by = 250)) + 
  scale_y_continuous (breaks = seq (0, 4000, by = 250))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du8_s_grp1.png")


### FOLD 2 ###
train.data.2 <- rsf.data.combo.du8.s %>%
  filter (group == 1 | group == 2 | group == 3 | group == 5)
test.data.2 <- rsf.data.combo.du8.s %>%
  filter (group == 4)

model.lme4.du8.s.train2 <- glmer (pttype ~ std.slope + 
                                            std.distance_to_watercourse +
                                            std.distance_to_lake +
                                            std.distance_to_cut_1to4yo + 
                                            std.distance_to_cut_5to9yo +
                                            std.distance_to_cut_10to29yo + 
                                            std.distance_to_cut_30orOveryo +
                                            std.distance_to_resource_road +
                                            std.distance_to_pipeline + 
                                            beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                            fire_6to25yo + fire_over25yo +
                                            std.vri_proj_age + 
                                            std.vri_site_index + 
                                            std.vri_herb_cover_pct + 
                                            std.vri_shrub_crown_close +
                                            bec_label_reclass2 +
                                            std.mean_annual_ppt +
                                            (1 | uniqueID), 
                                   data = train.data.2, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
ss <- getME (model.lme4.du8.s.train2, c ("theta","fixef"))
model.lme4.du8.s.train2 <- update (model.lme4.du8.s.train2, start = ss) # failed to converge, restart with parameter estimates
# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.combo.du8.s$preds.train2 <- predict (model.lme4.du8.s.train2, 
                                               newdata = rsf.data.combo.du8.s, 
                                               re.form = NA, type = "response")
ggplot (data = rsf.data.combo.du8.s, aes (preds.train2)) +
        geom_histogram()
max (rsf.data.combo.du8.s$preds.train2)
min (rsf.data.combo.du8.s$preds.train2)
rsf.data.combo.du8.s$preds.train2.class <- cut (rsf.data.combo.du8.s$preds.train2, # put into classes; 0 to 0.4, based on max and min values
                                                breaks = c (-Inf, 0.08, 0.16, 0.24, 0.32, 0.40, 0.48, 0.56, 0.64, 0.72, Inf), 
                                                labels = c ("0.04", "0.12", "0.20", "0.28", "0.36",
                                                            "0.44", "0.52", "0.60", "0.68", "0.76"))
write.csv (rsf.data.combo.du8.s, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du8_s.csv")
rsf.data.combo.du8.s.avail <- dplyr::filter (rsf.data.combo.du8.s, pttype == 0)

table.kfold [c (11:20), 1] <- 2

table.kfold [11, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train2.class == "0.04")) * 0.05) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [12, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train2.class == "0.12")) * 0.15)
table.kfold [13, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train2.class == "0.20")) * 0.25)
table.kfold [14, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train2.class == "0.28")) * 0.35)
table.kfold [15, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train2.class == "0.36")) * 0.45)
table.kfold [16, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train2.class == "0.44")) * 0.55)
table.kfold [17, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train2.class == "0.52")) * 0.65)
table.kfold [18, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train2.class == "0.60")) * 0.75)
table.kfold [19, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train2.class == "0.68")) * 0.85)
table.kfold [20, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train2.class == "0.76")) * 0.95)

table.kfold [11, 4] <- table.kfold [11, 3] / sum  (table.kfold [c (11:20), 3]) 
table.kfold [12, 4] <- table.kfold [12, 3] / sum  (table.kfold [c (11:20), 3]) 
table.kfold [13, 4] <- table.kfold [13, 3] / sum  (table.kfold [c (11:20), 3]) 
table.kfold [14, 4] <- table.kfold [14, 3] / sum  (table.kfold [c (11:20), 3]) 
table.kfold [15, 4] <- table.kfold [15, 3] / sum  (table.kfold [c (11:20), 3]) 
table.kfold [16, 4] <- table.kfold [16, 3] / sum  (table.kfold [c (11:20), 3]) 
table.kfold [17, 4] <- table.kfold [17, 3] / sum  (table.kfold [c (11:20), 3]) 
table.kfold [18, 4] <- table.kfold [18, 3] / sum  (table.kfold [c (11:20), 3])
table.kfold [19, 4] <- table.kfold [19, 3] / sum  (table.kfold [c (11:20), 3]) 
table.kfold [20, 4] <- table.kfold [20, 3] / sum  (table.kfold [c (11:20), 3]) 

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\table_kfold_valid_du8_s.csv")

# data for estimating use
test.data.2$preds <- predict (model.lme4.du8.s.train2, newdata = test.data.2, re.form = NA, type = "response")
test.data.2$preds.class <- cut (test.data.2$preds, # put into classes; 0 to 0.4, based on max and min values
                                breaks = c (-Inf, 0.08, 0.16, 0.24, 0.32, 0.40, 0.48, 0.56, 0.64, 0.72, Inf), 
                                labels = c ("0.04", "0.12", "0.20", "0.28", "0.36",
                                            "0.44", "0.52", "0.60", "0.68", "0.76"))
write.csv (test.data.2, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\rsf_preds_du8_s_train2.csv")
test.data.2.used <- dplyr::filter (test.data.2, pttype == 1)

table.kfold [11, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.04"))
table.kfold [12, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.12"))
table.kfold [13, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.20"))
table.kfold [14, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.28"))
table.kfold [15, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.36"))
table.kfold [16, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.44"))
table.kfold [17, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.52"))
table.kfold [18, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.60"))
table.kfold [19, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.68"))
table.kfold [20, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.76"))

table.kfold [11, 6] <- round (sum (table.kfold [c (11:20), 5]) * table.kfold [11, 4], 0) # expected number of uses in each bin
table.kfold [12, 6] <- round (sum (table.kfold [c (11:20), 5]) * table.kfold [12, 4], 0) # expected number of uses in each bin
table.kfold [13, 6] <- round (sum (table.kfold [c (11:20), 5]) * table.kfold [13, 4], 0) # expected number of uses in each bin
table.kfold [14, 6] <- round (sum (table.kfold [c (11:20), 5]) * table.kfold [14, 4], 0) # expected number of uses in each bin
table.kfold [15, 6] <- round (sum (table.kfold [c (11:20), 5]) * table.kfold [15, 4], 0) # expected number of uses in each bin
table.kfold [16, 6] <- round (sum (table.kfold [c (11:20), 5]) * table.kfold [16, 4], 0) # expected number of uses in each bin
table.kfold [17, 6] <- round (sum (table.kfold [c (11:20), 5]) * table.kfold [17, 4], 0) # expected number of uses in each bin
table.kfold [18, 6] <- round (sum (table.kfold [c (11:20), 5]) * table.kfold [18, 4], 0) # expected number of uses in each bin
table.kfold [19, 6] <- round (sum (table.kfold [c (11:20), 5]) * table.kfold [19, 4], 0) # expected number of uses in each bin
table.kfold [20, 6] <- round (sum (table.kfold [c (11:20), 5]) * table.kfold [20, 4], 0) # expected number of uses in each bin

glm.kfold.test2 <- lm (used.count ~ expected.count, 
                       data = dplyr::filter (table.kfold, test.number == 2))
summary (glm.kfold.test2)

table.kfold [11, 7] <- 1.01194
table.kfold [11, 8] <- "<0.001"
table.kfold [11, 9] <- -14.14939
table.kfold [11, 10] <- 0.933
table.kfold [11, 11] <- 0.9214

chisq.test(dplyr::filter(table.kfold, test.number == 2)$used.count, dplyr::filter(table.kfold, test.number == 2)$expected.count)
table.kfold [11, 12] <- 0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\table_kfold_valid_du8_s.csv")


ggplot (dplyr::filter(table.kfold, test.number == 2), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 2 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 5000, by = 250)) + 
  scale_y_continuous (breaks = seq (0, 5000, by = 250))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du8_s_grp2.png")

write.csv (test.data.2, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\rsf_preds_du8_s_train2.csv")

### FOLD 3 ###
train.data.3 <- rsf.data.combo.du8.s %>%
  filter (group == 1 | group == 2 | group == 4 | group == 5)
test.data.3 <- rsf.data.combo.du8.s %>%
  filter (group == 3)

model.lme4.du8.s.train3 <- glmer (pttype ~ std.slope + 
                                            std.distance_to_watercourse +
                                            std.distance_to_lake +
                                            std.distance_to_cut_1to4yo + 
                                            std.distance_to_cut_5to9yo +
                                            std.distance_to_cut_10to29yo + 
                                            std.distance_to_cut_30orOveryo +
                                            std.distance_to_resource_road +
                                            std.distance_to_pipeline + 
                                            beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                            fire_6to25yo + fire_over25yo +
                                            std.vri_proj_age + 
                                            std.vri_site_index + 
                                            std.vri_herb_cover_pct + 
                                            std.vri_shrub_crown_close +
                                            bec_label_reclass2 +
                                            std.mean_annual_ppt +
                                            (1 | uniqueID), 
                                   data = train.data.3, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
ss <- getME (model.lme4.du8.s.train3, c ("theta","fixef"))
model.lme4.du8.s.train3 <- update (model.lme4.du8.s.train3, start = ss) # failed to converge, restart with parameter estimates
# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.combo.du8.s$preds.train3 <- predict (model.lme4.du8.s.train3, 
                                               newdata = rsf.data.combo.du8.s, 
                                               re.form = NA, type = "response")
max (rsf.data.combo.du8.s$preds.train3)
min (rsf.data.combo.du8.s$preds.train3)
rsf.data.combo.du8.s$preds.train3.class <- cut (rsf.data.combo.du8.s$preds.train3, # put into classes; 0 to 0.4, based on max and min values
                                                breaks = c (-Inf, 0.08, 0.16, 0.24, 0.32, 0.40, 0.48, 0.56, 0.64, 0.72, Inf), 
                                                labels = c ("0.04", "0.12", "0.20", "0.28", "0.36",
                                                            "0.44", "0.52", "0.60", "0.68", "0.76"))
write.csv (rsf.data.combo.du8.s, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du8_s.csv")
rsf.data.combo.du8.s.avail <- dplyr::filter (rsf.data.combo.du8.s, pttype == 0)

table.kfold [c (21:30), 1] <- 3

table.kfold [21, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train3.class == "0.04")) * 0.05) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [22, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train3.class == "0.12")) * 0.15)
table.kfold [23, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train3.class == "0.20")) * 0.25)
table.kfold [24, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train3.class == "0.28")) * 0.35)
table.kfold [25, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train3.class == "0.36")) * 0.45)
table.kfold [26, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train3.class == "0.44")) * 0.55)
table.kfold [27, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train3.class == "0.52")) * 0.65)
table.kfold [28, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train3.class == "0.60")) * 0.75)
table.kfold [29, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train3.class == "0.68")) * 0.85)
table.kfold [30, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train3.class == "0.76")) * 0.95)

table.kfold [21, 4] <- table.kfold [21, 3] / sum  (table.kfold [c (21:30), 3]) 
table.kfold [22, 4] <- table.kfold [22, 3] / sum  (table.kfold [c (21:30), 3]) 
table.kfold [23, 4] <- table.kfold [23, 3] / sum  (table.kfold [c (21:30), 3]) 
table.kfold [24, 4] <- table.kfold [24, 3] / sum  (table.kfold [c (21:30), 3]) 
table.kfold [25, 4] <- table.kfold [25, 3] / sum  (table.kfold [c (21:30), 3]) 
table.kfold [26, 4] <- table.kfold [26, 3] / sum  (table.kfold [c (21:30), 3]) 
table.kfold [27, 4] <- table.kfold [27, 3] / sum  (table.kfold [c (21:30), 3]) 
table.kfold [28, 4] <- table.kfold [28, 3] / sum  (table.kfold [c (21:30), 3])
table.kfold [29, 4] <- table.kfold [29, 3] / sum  (table.kfold [c (21:30), 3]) 
table.kfold [30, 4] <- table.kfold [30, 3] / sum  (table.kfold [c (21:30), 3]) 

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\table_kfold_valid_du8_s.csv")

# data for estimating use
test.data.3$preds <- predict (model.lme4.du8.s.train3, newdata = test.data.3, re.form = NA, type = "response")
test.data.3$preds.class <- cut (test.data.3$preds, # put into classes; 0 to 0.4, based on max and min values
                                breaks = c (-Inf, 0.08, 0.16, 0.24, 0.32, 0.40, 0.48, 0.56, 0.64, 0.72, Inf), 
                                labels = c ("0.04", "0.12", "0.20", "0.28", "0.36",
                                            "0.44", "0.52", "0.60", "0.68", "0.76"))
write.csv (test.data.3, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\rsf_preds_du8_s_train3.csv")
test.data.3.used <- dplyr::filter (test.data.3, pttype == 1)

table.kfold [21, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.04"))
table.kfold [22, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.12"))
table.kfold [23, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.20"))
table.kfold [24, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.28"))
table.kfold [25, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.36"))
table.kfold [26, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.44"))
table.kfold [27, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.52"))
table.kfold [28, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.60"))
table.kfold [29, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.68"))
table.kfold [30, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.76"))

table.kfold [21, 6] <- round (sum (table.kfold [c (21:30), 5]) * table.kfold [21, 4], 0) # expected number of uses in each bin
table.kfold [22, 6] <- round (sum (table.kfold [c (21:30), 5]) * table.kfold [22, 4], 0) # expected number of uses in each bin
table.kfold [23, 6] <- round (sum (table.kfold [c (21:30), 5]) * table.kfold [23, 4], 0) # expected number of uses in each bin
table.kfold [24, 6] <- round (sum (table.kfold [c (21:30), 5]) * table.kfold [24, 4], 0) # expected number of uses in each bin
table.kfold [25, 6] <- round (sum (table.kfold [c (21:30), 5]) * table.kfold [25, 4], 0) # expected number of uses in each bin
table.kfold [26, 6] <- round (sum (table.kfold [c (21:30), 5]) * table.kfold [26, 4], 0) # expected number of uses in each bin
table.kfold [27, 6] <- round (sum (table.kfold [c (21:30), 5]) * table.kfold [27, 4], 0) # expected number of uses in each bin
table.kfold [28, 6] <- round (sum (table.kfold [c (21:30), 5]) * table.kfold [28, 4], 0) # expected number of uses in each bin
table.kfold [29, 6] <- round (sum (table.kfold [c (21:30), 5]) * table.kfold [29, 4], 0) # expected number of uses in each bin
table.kfold [30, 6] <- round (sum (table.kfold [c (21:30), 5]) * table.kfold [30, 4], 0) # expected number of uses in each bin

glm.kfold.test3 <- lm (used.count ~ expected.count, 
                       data = dplyr::filter (table.kfold, test.number == 3))
summary (glm.kfold.test3)

table.kfold [21, 7] <- 0.9880
table.kfold [21, 8] <- "<0.001"
table.kfold [21, 9] <- 13.2494
table.kfold [21, 10] <- 0.905
table.kfold [21, 11] <- 0.9599

chisq.test(dplyr::filter(table.kfold, test.number == 3)$used.count, dplyr::filter(table.kfold, test.number == 3)$expected.count)
table.kfold [21, 12] <- 0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\table_kfold_valid_du8_s.csv")

ggplot (dplyr::filter(table.kfold, test.number == 3), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 3 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 5000, by = 250)) + 
  scale_y_continuous (breaks = seq (0, 5000, by = 250))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du8_s_grp3.png")

write.csv (test.data.3, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\rsf_preds_du8_s_train3.csv")

### FOLD 4 ###
train.data.4 <- rsf.data.combo.du8.s %>%
  filter (group == 1 | group == 3 | group == 4 | group == 5)
test.data.4 <- rsf.data.combo.du8.s %>%
  filter (group == 2)

model.lme4.du8.s.train4 <- glmer (pttype ~ std.slope + 
                                            std.distance_to_watercourse +
                                            std.distance_to_lake +
                                            std.distance_to_cut_1to4yo + 
                                            std.distance_to_cut_5to9yo +
                                            std.distance_to_cut_10to29yo + 
                                            std.distance_to_cut_30orOveryo +
                                            std.distance_to_resource_road +
                                            std.distance_to_pipeline + 
                                            beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                            fire_6to25yo + fire_over25yo +
                                            std.vri_proj_age + 
                                            std.vri_site_index + 
                                            std.vri_herb_cover_pct + 
                                            std.vri_shrub_crown_close +
                                            bec_label_reclass2 +
                                            std.mean_annual_ppt +
                                            (1 | uniqueID), 
                                   data = train.data.4, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
ss <- getME (model.lme4.du8.s.train4, c ("theta","fixef"))
model.lme4.du8.s.train4 <- update (model.lme4.du8.s.train4, start = ss)
# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.combo.du8.s$preds.train4 <- predict (model.lme4.du8.s.train4, 
                                               newdata = rsf.data.combo.du8.s, 
                                               re.form = NA, type = "response")
max (rsf.data.combo.du8.s$preds.train4)
min (rsf.data.combo.du8.s$preds.train4)
rsf.data.combo.du8.s$preds.train4.class <- cut (rsf.data.combo.du8.s$preds.train4, # put into classes; 0 to 0.4, based on max and min values
                                                breaks = c (-Inf, 0.08, 0.16, 0.24, 0.32, 0.40, 0.48, 0.56, 0.64, 0.72, Inf), 
                                                labels = c ("0.04", "0.12", "0.20", "0.28", "0.36",
                                                            "0.44", "0.52", "0.60", "0.68", "0.76"))
write.csv (rsf.data.combo.du8.s, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du8_s.csv")
rsf.data.combo.du8.s.avail <- dplyr::filter (rsf.data.combo.du8.s, pttype == 0)

table.kfold [c (31:40), 1] <- 4

table.kfold [31, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train4.class == "0.04")) * 0.05) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [32, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train4.class == "0.12")) * 0.15)
table.kfold [33, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train4.class == "0.20")) * 0.25)
table.kfold [34, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train4.class == "0.28")) * 0.35)
table.kfold [35, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train4.class == "0.36")) * 0.45)
table.kfold [36, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train4.class == "0.44")) * 0.55)
table.kfold [37, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train4.class == "0.52")) * 0.65)
table.kfold [38, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train4.class == "0.60")) * 0.75)
table.kfold [39, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train4.class == "0.68")) * 0.85)
table.kfold [40, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train4.class == "0.76")) * 0.95)

table.kfold [31, 4] <- table.kfold [31, 3] / sum  (table.kfold [c (31:40), 3]) 
table.kfold [32, 4] <- table.kfold [32, 3] / sum  (table.kfold [c (31:40), 3]) 
table.kfold [33, 4] <- table.kfold [33, 3] / sum  (table.kfold [c (31:40), 3]) 
table.kfold [34, 4] <- table.kfold [34, 3] / sum  (table.kfold [c (31:40), 3]) 
table.kfold [35, 4] <- table.kfold [35, 3] / sum  (table.kfold [c (31:40), 3]) 
table.kfold [36, 4] <- table.kfold [36, 3] / sum  (table.kfold [c (31:40), 3]) 
table.kfold [37, 4] <- table.kfold [37, 3] / sum  (table.kfold [c (31:40), 3]) 
table.kfold [38, 4] <- table.kfold [38, 3] / sum  (table.kfold [c (31:40), 3])
table.kfold [39, 4] <- table.kfold [39, 3] / sum  (table.kfold [c (31:40), 3]) 
table.kfold [40, 4] <- table.kfold [40, 3] / sum  (table.kfold [c (31:40), 3]) 

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\table_kfold_valid_du8_s.csv")

# data for estimating use
test.data.4$preds <- predict (model.lme4.du8.s.train4, newdata = test.data.4, re.form = NA, type = "response")
test.data.4$preds.class <- cut (test.data.4$preds, # put into classes; 0 to 0.4, based on max and min values
                                breaks = c (-Inf, 0.08, 0.16, 0.24, 0.32, 0.40, 0.48, 0.56, 0.64, 0.72, Inf), 
                                labels = c ("0.04", "0.12", "0.20", "0.28", "0.36",
                                            "0.44", "0.52", "0.60", "0.68", "0.76"))
write.csv (test.data.4, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\rsf_preds_du8_s_train4.csv")
test.data.4.used <- dplyr::filter (test.data.4, pttype == 1)

table.kfold [31, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.04"))
table.kfold [32, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.12"))
table.kfold [33, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.20"))
table.kfold [34, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.28"))
table.kfold [35, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.36"))
table.kfold [36, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.44"))
table.kfold [37, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.52"))
table.kfold [38, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.60"))
table.kfold [39, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.68"))
table.kfold [40, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.76"))

table.kfold [31, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [21, 4], 0) # expected number of uses in each bin
table.kfold [32, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [22, 4], 0) # expected number of uses in each bin
table.kfold [33, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [23, 4], 0) # expected number of uses in each bin
table.kfold [34, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [24, 4], 0) # expected number of uses in each bin
table.kfold [35, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [25, 4], 0) # expected number of uses in each bin
table.kfold [36, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [26, 4], 0) # expected number of uses in each bin
table.kfold [37, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [27, 4], 0) # expected number of uses in each bin
table.kfold [38, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [28, 4], 0) # expected number of uses in each bin
table.kfold [39, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [29, 4], 0) # expected number of uses in each bin
table.kfold [40, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [30, 4], 0) # expected number of uses in each bin

glm.kfold.test4 <- lm (used.count ~ expected.count, 
                       data = dplyr::filter (table.kfold, test.number == 4))
summary (glm.kfold.test4)

table.kfold [31, 7] <- 0.96516
table.kfold [31, 8] <- "<0.001"
table.kfold [31, 9] <- 39.74441
table.kfold [31, 10] <- 0.507
table.kfold [31, 11] <- 0.9883

chisq.test(dplyr::filter(table.kfold, test.number == 4)$used.count, dplyr::filter(table.kfold, test.number == 4)$expected.count)
table.kfold [31, 12] <- 0.2424

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\table_kfold_valid_du8_s.csv")

ggplot (dplyr::filter(table.kfold, test.number == 4), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 4 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 5000, by = 250)) + 
  scale_y_continuous (breaks = seq (0, 5000, by = 250))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du8_s_grp4.png")

write.csv (test.data.4, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\rsf_preds_du8_s_train4.csv")

### FOLD 5 ###
train.data.5 <- rsf.data.combo.du8.s %>%
  filter (group == 5 | group == 2 | group == 3 | group == 4)
test.data.5 <- rsf.data.combo.du8.s %>%
  filter (group == 1)

model.lme4.du8.s.train5 <- glmer (pttype ~ std.slope + 
                                            std.distance_to_watercourse +
                                            std.distance_to_lake +
                                            std.distance_to_cut_1to4yo + 
                                            std.distance_to_cut_5to9yo +
                                            std.distance_to_cut_10to29yo + 
                                            std.distance_to_cut_30orOveryo +
                                            std.distance_to_resource_road +
                                            std.distance_to_pipeline + 
                                            beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                            fire_6to25yo + fire_over25yo +
                                            std.vri_proj_age + 
                                            std.vri_site_index + 
                                            std.vri_herb_cover_pct + 
                                            std.vri_shrub_crown_close +
                                            bec_label_reclass2 +
                                            std.mean_annual_ppt +
                                            (1 | uniqueID), 
                                   data = train.data.5, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
ss <- getME (model.lme4.du8.s.train5, c ("theta","fixef"))
model.lme4.du8.s.train5 <- update (model.lme4.du8.s.train5, start = ss) # failed to converge, restart with parameter estimates
# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.combo.du8.s$preds.train5 <- predict (model.lme4.du8.s.train5, 
                                               newdata = rsf.data.combo.du8.s, 
                                               re.form = NA, type = "response")
max (rsf.data.combo.du8.s$preds.train5)
min (rsf.data.combo.du8.s$preds.train5)
rsf.data.combo.du8.s$preds.train5.class <- cut (rsf.data.combo.du8.s$preds.train5, # put into classes; 0 to 0.4, based on max and min values
                                                breaks = c (-Inf, 0.08, 0.16, 0.24, 0.32, 0.40, 0.48, 0.56, 0.64, 0.72, Inf), 
                                                labels = c ("0.04", "0.12", "0.20", "0.28", "0.36",
                                                            "0.44", "0.52", "0.60", "0.68", "0.76"))
write.csv (rsf.data.combo.du8.s, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du8_s.csv")
rsf.data.combo.du8.s.avail <- dplyr::filter (rsf.data.combo.du8.s, pttype == 0)

table.kfold [c (41:50), 1] <- 5

table.kfold [41, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train5.class == "0.04")) * 0.05) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [42, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train5.class == "0.12")) * 0.15)
table.kfold [43, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train5.class == "0.20")) * 0.25)
table.kfold [44, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train5.class == "0.28")) * 0.35)
table.kfold [45, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train5.class == "0.36")) * 0.45)
table.kfold [46, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train5.class == "0.44")) * 0.55)
table.kfold [47, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train5.class == "0.52")) * 0.65)
table.kfold [48, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train5.class == "0.60")) * 0.75)
table.kfold [49, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train5.class == "0.68")) * 0.85)
table.kfold [50, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.s.avail, preds.train5.class == "0.76")) * 0.95)

table.kfold [41, 4] <- table.kfold [41, 3] / sum  (table.kfold [c (41:50), 3]) 
table.kfold [42, 4] <- table.kfold [42, 3] / sum  (table.kfold [c (41:50), 3]) 
table.kfold [43, 4] <- table.kfold [43, 3] / sum  (table.kfold [c (41:50), 3]) 
table.kfold [44, 4] <- table.kfold [44, 3] / sum  (table.kfold [c (41:50), 3]) 
table.kfold [45, 4] <- table.kfold [45, 3] / sum  (table.kfold [c (41:50), 3]) 
table.kfold [46, 4] <- table.kfold [46, 3] / sum  (table.kfold [c (41:50), 3]) 
table.kfold [47, 4] <- table.kfold [47, 3] / sum  (table.kfold [c (41:50), 3]) 
table.kfold [48, 4] <- table.kfold [48, 3] / sum  (table.kfold [c (41:50), 3])
table.kfold [49, 4] <- table.kfold [49, 3] / sum  (table.kfold [c (41:50), 3]) 
table.kfold [50, 4] <- table.kfold [50, 3] / sum  (table.kfold [c (41:50), 3]) 

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\table_kfold_valid_du8_s.csv")

# data for estimating use
test.data.5$preds <- predict (model.lme4.du8.s.train5, newdata = test.data.5, re.form = NA, type = "response")
test.data.5$preds.class <- cut (test.data.5$preds, # put into classes; 0 to 0.4, based on max and min values
                                breaks = c (-Inf, 0.08, 0.16, 0.24, 0.32, 0.40, 0.48, 0.56, 0.64, 0.72, Inf), 
                                labels = c ("0.04", "0.12", "0.20", "0.28", "0.36",
                                            "0.44", "0.52", "0.60", "0.68", "0.76"))
write.csv (test.data.5, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\rsf_preds_du8_s_train5.csv")
test.data.5.used <- dplyr::filter (test.data.5, pttype == 1)

table.kfold [41, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.04"))
table.kfold [42, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.12"))
table.kfold [43, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.20"))
table.kfold [44, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.28"))
table.kfold [45, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.36"))
table.kfold [46, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.44"))
table.kfold [47, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.52"))
table.kfold [48, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.60"))
table.kfold [49, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.68"))
table.kfold [50, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.76"))

table.kfold [41, 6] <- round (sum (table.kfold [c (41:50), 5]) * table.kfold [41, 4], 0) # expected number of uses in each bin
table.kfold [42, 6] <- round (sum (table.kfold [c (41:50), 5]) * table.kfold [42, 4], 0) # expected number of uses in each bin
table.kfold [43, 6] <- round (sum (table.kfold [c (41:50), 5]) * table.kfold [43, 4], 0) # expected number of uses in each bin
table.kfold [44, 6] <- round (sum (table.kfold [c (41:50), 5]) * table.kfold [44, 4], 0) # expected number of uses in each bin
table.kfold [45, 6] <- round (sum (table.kfold [c (41:50), 5]) * table.kfold [45, 4], 0) # expected number of uses in each bin
table.kfold [46, 6] <- round (sum (table.kfold [c (41:50), 5]) * table.kfold [46, 4], 0) # expected number of uses in each bin
table.kfold [47, 6] <- round (sum (table.kfold [c (41:50), 5]) * table.kfold [47, 4], 0) # expected number of uses in each bin
table.kfold [48, 6] <- round (sum (table.kfold [c (41:50), 5]) * table.kfold [48, 4], 0) # expected number of uses in each bin
table.kfold [49, 6] <- round (sum (table.kfold [c (41:50), 5]) * table.kfold [49, 4], 0) # expected number of uses in each bin
table.kfold [50, 6] <- round (sum (table.kfold [c (41:50), 5]) * table.kfold [50, 4], 0) # expected number of uses in each bin

glm.kfold.test5 <- lm (used.count ~ expected.count, 
                       data = dplyr::filter (table.kfold, test.number == 5))
summary (glm.kfold.test5)

table.kfold [41, 7] <- 0.99844
table.kfold [41, 8] <- "<0.001"
table.kfold [41, 9] <- 1.58635
table.kfold [41, 10] <- 0.984
table.kfold [41, 11] <- 0.9747

chisq.test(dplyr::filter(table.kfold, test.number == 5)$used.count, dplyr::filter(table.kfold, test.number == 5)$expected.count)
table.kfold [41, 12] <- 0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\table_kfold_valid_du8_s.csv")


ggplot (dplyr::filter(table.kfold, test.number == 5), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 5 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 4000, by = 250)) + 
  scale_y_continuous (breaks = seq (0, 4000, by = 250))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du8_s_grp5.png")

write.csv (test.data.5, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\rsf_preds_du8_s_train5.csv")

# create results table
table.kfold.results.du8.s <- table.kfold
table.kfold.results.du8.s <- table.kfold.results.du8.s [- c (1, 3:7)]

table.kfold.results.du8.s <- table.kfold.results.du8.s %>%
  slice (c (1, 11, 21, 31, 41))

write.csv (table.kfold.results.du8.s, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\summer\\table_kfold_summary_du8_s.csv")

###############################
### RSF RASTER CALCULATION ###
#############################
### LOAD RASTERS ###
slope <- raster ("C:\\Work\\caribou\\clus_data\\dem\\slope_deg_all_bc_8_clip.tif")
dist.water <- raster ("C:\\Work\\caribou\\clus_data\\water\\raster_dist_to_watercourses_bcalbers_20180820.tif")
dist.lake <- raster ("C:\\Work\\caribou\\clus_data\\water\\raster_dist_to_lakes_bcalbers_20180820.tif")
elev <- raster ("C:\\Work\\caribou\\clus_data\\dem\\dem_all_bc_clip.tif")
dist.cut.1to4 <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_1to4yo.tif")
dist.cut.5to9 <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_5to9yo.tif")
dist.cut.10to29 <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_10to29yo.tif")
dist.cut.30over <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_30yo_over.tif")
dist.resource.rd <- raster ("C:\\Work\\caribou\\clus_data\\roads_ha_bc\\dist_crds_resource.tif")
dist.pipeline <- raster ("C:\\Work\\caribou\\clus_data\\pipelines\\raster_distance_to_pipelines_bcalbers_20180815.tif")
dist.agric <- raster ("C:\\Work\\caribou\\clus_data\\agriculture\\raster_dist_to_agriculture_bcalbers_ce_2015.tif")
beetle.1to5 <- raster ("C:\\Work\\caribou\\clus_data\\forest_health\\raster_bark_beetle_all_1to5yo_fin.tif")
beetle.6to9 <- raster ("C:\\Work\\caribou\\clus_data\\forest_health\\raster_bark_beetle_all_6to9yo_fin.tif")
fire.1to5 <- raster ("C:\\Work\\caribou\\clus_data\\fire\\fire_tiffs\\raster_fire_1to5yo_fin.tif")
fire.6to25 <- raster ("C:\\Work\\caribou\\clus_data\\fire\\fire_tiffs\\raster_fire_6to25yo_fin.tif")
fire.over25 <- raster ("C:\\Work\\caribou\\clus_data\\fire\\fire_tiffs\\raster_fire_over25yo_fin.tif")
vri.age <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\vri_projage1.tif")
vri.site.index <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\vri_siteindex.tif")
vri.herb <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\vri_herbcoverpct.tif")
vri.shrub <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\vri_shrubcrownclosure.tif")
ppt.as.snow.winter <- raster ("C:\\Work\\caribou\\clus_data\\climate\\seasonal\\pas_wt")
temp.winter <- raster ("C:\\Work\\caribou\\clus_data\\climate\\seasonal\\tave_wt") / 10 #divide by ten; data was multiplied by 10

### CROP RASTERS TO DU8 USED "BOX' "of HERD RANGES PLUS 25km BUFFER ###
caribou.sa <- readOGR ("C:\\Work\\caribou\\clus_data\\caribou\\caribou_herd\\du8_herds_buff25km.shp", stringsAsFactors = T) # DU8 herds with 25km buffer
slope <- crop (slope, extent (caribou.sa))
dist.water <- crop (dist.water, extent (caribou.sa))
dist.lake <- crop (dist.lake, extent (caribou.sa))
elev <- crop (elev, extent (caribou.sa))
dist.resource.rd <- crop (dist.resource.rd, extent (caribou.sa))
dist.pipeline <- crop (dist.pipeline, extent (caribou.sa))
dist.agric <- crop (dist.agric, extent (caribou.sa))
dist.cut.1to4 <- crop (dist.cut.1to4, extent (caribou.sa))
dist.cut.5to9 <- crop (dist.cut.5to9, extent (caribou.sa))
dist.cut.10to29 <- crop (dist.cut.10to29, extent (caribou.sa))
dist.cut.30over <- crop (dist.cut.30over, extent (caribou.sa))
beetle.1to5 <- crop (beetle.1to5, extent (caribou.sa))
beetle.6to9 <- crop (beetle.6to9, extent (caribou.sa))
fire.1to5 <- crop (fire.1to5, extent (caribou.sa))
fire.6to25 <- crop (fire.6to25, extent (caribou.sa))
fire.over25 <- crop (fire.over25, extent (caribou.sa))
vri.age <- crop (vri.shrub, extent (caribou.sa))
vri.site.index <- crop (vri.site.index, extent (caribou.sa))
vri.herb <- crop (vri.herb, extent (caribou.sa))
vri.shrub <- crop (vri.shrub, extent (caribou.sa))

proj.crs <- proj4string (caribou.sa)
ppt.as.snow.winter <- projectRaster (ppt.as.snow.winter, crs = proj.crs, method = "bilinear")
temp.winter <- projectRaster (temp.winter, crs = proj.crs, method = "bilinear")
ppt.as.snow.winter <- crop (ppt.as.snow.winter, extent (caribou.sa))
temp.winter <- crop (temp.winter, extent (caribou.sa))

## MAKE RASTERS THE SAME RESOLUTION FOR CALC ###
beginCluster ()

slope <- resample (slope, dist.lake, method = 'bilinear')
writeRaster (slope, "C:\\Work\\caribou\\clus_data\\rsf\\du8\\summer\\slope_resample.tif", 
             format = "GTiff")
elev <- resample (elev, dist.lake, method = 'bilinear')
writeRaster (elev, "C:\\Work\\caribou\\clus_data\\rsf\\du8\\summer\\elevation_resample.tif", 
             format = "GTiff")
ppt.as.snow.winter <- resample (ppt.as.snow.winter, dist.lake, method = 'bilinear')
writeRaster (ppt.as.snow.winter, "C:\\Work\\caribou\\clus_data\\rsf\\du8\\summer\\ppt_snow_winter.tif", 
             format = "GTiff")
temp.winter <- resample (temp.winter, dist.lake, method = 'bilinear')
writeRaster (temp.winter, "C:\\Work\\caribou\\clus_data\\rsf\\du8\\summer\\temp_winter.tif", 
             format = "GTiff", overwrite = TRUE)

endCluster ()

### Adjust the raster data for 'standardized' model covariates ###
beginCluster ()

slope <- (slope - 17) / 12 # rounded these numbers to facilitate faster processing; decreases processing time substantially
dist.water <- (dist.water - 5000) / 2149 
dist.lake <- (dist.lake - 3420) / 2253 
elev <- (elev - 1524) / 251 
std.dist.cut.1to4 <- (dist.cut.1to4 - 12205) / 6105 
std.dist.cut.5to9 <- (dist.cut.5to9 - 8697) / 4998
dist.cut.10to29 <- (dist.cut.10to29 - 4476) / 3005
dist.cut.30over <- (dist.cut.30over - 7145) / 4048
dist.resource.rd <- (dist.resource.rd - 1929) / 1918
dist.pipeline <- (dist.pipeline - 8436) / 11735
dist.agric <- (dist.agric - 21330) / 8340
vri.age <- (vri.age - 107) / 81
vri.site.index <- (vri.site.index - 5) / 4
vri.herb <- (vri.herb - 13) / 19
vri.shrub <- (vri.shrub - 10) / 15
ppt.as.snow.winter <- (ppt.as.snow.winter - 349) / 128
temp.winter <- (temp.winter - -10) / 0.5

endCluster ()

### CALCULATE RASTER OF STATIC VARIABLES ###
beginCluster ()

raster.rsf <- exp (-1.94 + (slope * -0.6) + (dist.water * -0.06) + 
                           (dist.lake * 0.02) + (elev * 1.36) +
                           (std.dist.cut.1to4 * -0.02) + (std.dist.cut.5to9 * -0.20) +
                           (dist.cut.10to29 * -0.01) + (dist.cut.30over * -0.04) +
                           (dist.resource.rd * 0.02) + (dist.pipeline * -0.10) +
                           (dist.agric * 0.21) + (beetle.1to5 * -0.11) +
                           (beetle.6to9 * 0.15) + (fire.1to5 * -1.21) + 
                           (fire.6to25 * -0.09) + (fire.over25 * -0.45) +
                           (vri.age * 0.09) + (vri.site.index * -0.27) +
                           (vri.herb * 0.06) + (vri.shrub * -0.07) + 
                           (ppt.as.snow.winter * -1.14) + (temp.winter * 0.21)) /
           1 + exp (-1.94 + (slope * -0.6) + (dist.water * -0.06) + 
                      (dist.lake * 0.02) + (elev * 1.36) +
                      (std.dist.cut.1to4 * -0.02) + (std.dist.cut.5to9 * -0.20) +
                      (dist.cut.10to29 * -0.01) + (dist.cut.30over * -0.04) +
                      (dist.resource.rd * 0.02) + (dist.pipeline * -0.10) +
                      (dist.agric * 0.21) + (beetle.1to5 * -0.11) +
                      (beetle.6to9 * 0.15) + (fire.1to5 * -1.21) + 
                      (fire.6to25 * -0.09) + (fire.over25 * -0.45) +
                      (vri.age * 0.09) + (vri.site.index * -0.27) +
                      (vri.herb * 0.06) + (vri.shrub * -0.07) + 
                      (ppt.as.snow.winter * -1.14) + (temp.winter * 0.21))      
                
writeRaster (raster.rsf, "C:\\Work\\caribou\\clus_data\\rsf\\du8\\summer\\rsf_du8_s.tif", 
             format = "GTiff", overwrite = T)

endCluster ()
