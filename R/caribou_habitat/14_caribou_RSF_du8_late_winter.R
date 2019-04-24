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
#  Script Name: 13_caribou_RSF_du8_early_winter.R
#  Script Version: 1.0
#  Script Purpose: Script to develop caribou RSF model for du8 and Early Winter.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 8 April 2019
#  R Version: 
#  R Packages: 
#  Data: 
#=================================

#==========================================
# TO TURN SCRIPT FOR DIFFERENT DUs and SEASONS:
# Find and Replace:
# 1. ew .ew .s
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

rsf.data.combo <- rsf.data.terrain.water [, c (1:9, 10, 13, 15)]
rm (rsf.data.terrain.water)
gc ()
rsf.data.combo <- dplyr::full_join (rsf.data.combo, 
                                    rsf.data.human.dist [, c (9:14, 26, 21:22)],
                                    by = "ptID")
rm (rsf.data.human.dist)
gc ()
rsf.data.combo <- dplyr::full_join (rsf.data.combo, 
                                    rsf.data.natural.dist [, c (9:14)],
                                    by = "ptID")
rm (rsf.data.natural.dist)
gc ()
rsf.data.combo <- dplyr::full_join (rsf.data.combo, 
                                    rsf.data.climate.annual [, c (9, 19)],
                                    by = "ptID")
rm (rsf.data.climate.annual)
gc ()
rsf.data.combo <- dplyr::full_join (rsf.data.combo, 
                                    rsf.data.climate.winter [, c (9, 12, 14)],
                                    by = "ptID")
rm (rsf.data.climate.winter)
gc ()
rsf.data.combo <- dplyr::full_join (rsf.data.combo, 
                                    rsf.data.veg [, c (9, 10, 18, 19, 20, 22, 24, 26)],
                                    by = "ptID")
rm (rsf.data.veg)
gc ()

rsf.data.combo.du8.ew <- rsf.data.combo %>%
                          dplyr::filter (du == "du8") %>%
                          dplyr::filter (season == "EarlyWinter")

write.csv (rsf.data.combo.du8.ew, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du8_ew.csv")


#######################
### FITTING MODELS ###
#####################


#=================================
# Terrain and Water Models
#=================================
rsf.data.terrain.water.du8.ew <- rsf.data.terrain.water %>%
                                  dplyr::filter (du == "du8") %>%
                                  dplyr::filter (season == "EarlyWinter")

### OUTLIERS ###
ggplot (rsf.data.terrain.water.du8.ew, aes (x = pttype, y = slope)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Early Winter Slope at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Slope")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du8_ew_slope.png")
ggplot (rsf.data.terrain.water.du8.ew, aes (x = pttype, y = distance_to_lake)) +
            geom_boxplot (outlier.colour = "red") +
            labs (title = "Boxplot DU8, Early Winter Distance to Lake at Available (0) and Used (1) Locations",
                  x = "Available (0) and Used (1) Locations",
                  y = "Distance to Lake")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du8_ew_dist_lake.png")
ggplot (rsf.data.terrain.water.du8.ew, aes (x = pttype, y = distance_to_watercourse)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter Distance to Watercourse at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Watercourse")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du8_ew_dist_watercourse.png")
ggplot (rsf.data.terrain.water.du8.ew, aes (x = pttype, y = easting)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter Eastness at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Eastness")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du8_ew_east.png")
ggplot (rsf.data.terrain.water.du8.ew, aes (x = pttype, y = northing)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter Northness at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Eastness")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du8_ew_north.png")

### HISTOGRAMS ###
ggplot (rsf.data.terrain.water.du8.ew, aes (x = slope, fill = pttype)) + 
          geom_histogram (position = "dodge", binwidth = 5) +
          labs (title = "Histogram du8, Early Winter Slope at Available (0) and Used (1) Locations",
                x = "Slope",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du8_ew_slope.png")
ggplot (rsf.data.terrain.water.du8.ew, aes (x = distance_to_lake, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 200) +
        labs (title = "Histogram du8, Early Winter Distance to Lake at Available (0) and Used (1) Locations",
              x = "Distance to Lake",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du8_ew_dist_lake.png")
ggplot (rsf.data.terrain.water.du8.ew, aes (x = distance_to_watercourse, fill = pttype)) + 
          geom_histogram (position = "dodge", binwidth = 200) +
          labs (title = "Histogram du8, Early Winter Distance to Watercourse at Available (0) and Used (1) Locations",
                x = "Distance to Watercourse",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du8_ew_dist_watercourse.png")
ggplot (rsf.data.terrain.water.du8.ew, aes (x = elevation, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 50) +
  labs (title = "Histogram du8, Early Winter Elevation at Available (0) and Used (1) Locations",
        x = "Elevation",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du8_ew_elevation.png")
ggplot (rsf.data.terrain.water.du8.ew, aes (x = easting, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 0.25) +
  labs (title = "Histogram du8, Early Winter Eastness at Available (0) and Used (1) Locations",
        x = "Eastness",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du8_ew_east.png")
ggplot (rsf.data.terrain.water.du8.ew, aes (x = northing, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 0.25) +
  labs (title = "Histogram du8, Early Winter Northness at Available (0) and Used (1) Locations",
        x = "Northness",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du8_ew_north.png")

### CORRELATION ###
corr.terrain.water.du8.ew <- rsf.data.terrain.water.du8.ew [c (10:15)]
corr.terrain.water.du8.ew <- round (cor (corr.terrain.water.du8.ew, method = "spearman"), 3)
ggcorrplot (corr.terrain.water.du8.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Terrain and Water Resource Selection Function Model
            Covariate Correlations for DU8, Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_terrain_water_du8_ew.png")

### VIF ###
glm.terrain.du8.ew <- glm (pttype ~ elevation + slope + distance_to_lake + distance_to_watercourse, 
                            data = rsf.data.terrain.water.du8.ew,
                            family = binomial (link = 'logit'))
car::vif (glm.terrain.du8.ew)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

### Generalized Linear Mixed Models (GLMMs) ###
# standardize covariates  (helps with model convergence)
rsf.data.terrain.water.du8.ew$std.elevation <- (rsf.data.terrain.water.du8.ew$elevation - 
                                                  mean (rsf.data.terrain.water.du8.ew$elevation)) / 
                                                  sd (rsf.data.terrain.water.du8.ew$elevation)
rsf.data.terrain.water.du8.ew$std.slope <- (rsf.data.terrain.water.du8.ew$slope - 
                                                 mean (rsf.data.terrain.water.du8.ew$slope)) / 
                                                  sd (rsf.data.terrain.water.du8.ew$slope)
rsf.data.terrain.water.du8.ew$std.distance_to_lake <- (rsf.data.terrain.water.du8.ew$distance_to_lake - 
                                                        mean (rsf.data.terrain.water.du8.ew$distance_to_lake)) / 
                                                        sd (rsf.data.terrain.water.du8.ew$distance_to_lake)
rsf.data.terrain.water.du8.ew$std.distance_to_watercourse <- (rsf.data.terrain.water.du8.ew$distance_to_watercourse - 
                                                              mean (rsf.data.terrain.water.du8.ew$distance_to_watercourse)) / 
                                                              sd (rsf.data.terrain.water.du8.ew$distance_to_watercourse)

## SLOPE ##
model.lme4.du8.ew.slope <- glmer (pttype ~ std.slope + (1 | uniqueID), 
                                   data = rsf.data.terrain.water.du8.ew, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# AIC
table.aic [1, 1] <- "DU8"
table.aic [1, 2] <- "Early Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "Slope"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du8.ew.slope)

## DISTANCE TO LAKE ##
model.lme4.du8.ew.lake <- glmer (pttype ~ std.distance_to_lake + (1 | uniqueID), 
                                  data = rsf.data.terrain.water.du8.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
# AIC
table.aic [2, 1] <- "DU8"
table.aic [2, 2] <- "Early Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "Dist. to Lake"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du8.ew.lake)

## DISTANCE TO WATERCOURSE ##
model.lme4.du8.ew.wc <- glmer (pttype ~ std.distance_to_watercourse  + 
                                          (1 | uniqueID), 
                                 data = rsf.data.terrain.water.du8.ew, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [3, 1] <- "DU8"
table.aic [3, 2] <- "Early Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "Dist. to Watercourse"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du8.ew.wc)

## ELEVATION ##
model.lme4.du8.ew.elev <- glmer (pttype ~ std.elevation  + 
                                           (1 | uniqueID), 
                                 data = rsf.data.terrain.water.du8.ew, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [4, 1] <- "DU8"
table.aic [4, 2] <- "Early Winter"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "Elevation"
table.aic [4, 5] <- "(1 | UniqueID)"
table.aic [4, 6] <-  AIC (model.lme4.du8.ew.elev)

## SLOPE AND DISTANCE TO LAKE ##
model.lme4.du8.ew.slope.lake <- update (model.lme4.du8.ew.slope,
                                         . ~ . + std.distance_to_lake) 
# AIC
table.aic [5, 1] <- "DU8"
table.aic [5, 2] <- "Early Winter"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "Slope, Dist. to Lake"
table.aic [5, 5] <- "(1 | UniqueID)"
table.aic [5, 6] <-  AIC (model.lme4.du8.ew.slope.lake) 

## SLOPE AND DISTANCE TO WATERCOURSE ##
model.lme4.du8.ew.slope.water <- update (model.lme4.du8.ew.slope,
                                         . ~ . + std.distance_to_watercourse) 
# AIC
table.aic [6, 1] <- "DU8"
table.aic [6, 2] <- "Early Winter"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "Slope, Dist. to Watercourse"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <-  AIC (model.lme4.du8.ew.slope.water) 

## SLOPE AND ELEVATION ##
model.lme4.du8.ew.slope.elev <- update (model.lme4.du8.ew.slope,
                                         . ~ . + std.elevation) 
# AIC
table.aic [7, 1] <- "DU8"
table.aic [7, 2] <- "Early Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "Slope, Elevation"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du8.ew.slope.elev) 

## DISTANCE TO LAKE AND WATERCOURSE ##
model.lme4.du8.ew.lake.water <- update (model.lme4.du8.ew.lake,
                                        . ~ . + std.distance_to_watercourse)
# AIC
table.aic [8, 1] <- "DU8"
table.aic [8, 2] <- "Early Winter"
table.aic [8, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [8, 4] <- "Dist. to Lake, Dist. to Watercourse"
table.aic [8, 5] <- "(1 | UniqueID)"
table.aic [8, 6] <-  AIC (model.lme4.du8.ew.lake.water)

## DISTANCE TO LAKE AND ELEVATION ##
model.lme4.du8.ew.lake.elev <- update (model.lme4.du8.ew.lake,
                                        . ~ . + std.elevation)
# AIC
table.aic [9, 1] <- "DU8"
table.aic [9, 2] <- "Early Winter"
table.aic [9, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [9, 4] <- "Dist. to Lake, Elevation"
table.aic [9, 5] <- "(1 | UniqueID)"
table.aic [9, 6] <-  AIC (model.lme4.du8.ew.lake.elev)

## DISTANCE TO WATER AND ELEVATION ##
model.lme4.du8.ew.water.elev <- update (model.lme4.du8.ew.wc,
                                       . ~ . + std.elevation)
# AIC
table.aic [10, 1] <- "DU8"
table.aic [10, 2] <- "Early Winter"
table.aic [10, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [10, 4] <- "Dist. to Watercourse, Elevation"
table.aic [10, 5] <- "(1 | UniqueID)"
table.aic [10, 6] <-  AIC (model.lme4.du8.ew.water.elev)

## SLOPE, DISTANCE TO LAKE AND DISTANCE TO WATERCOURSE ##
model.lme4.du8.ew.slope.lake.wc <- update (model.lme4.du8.ew.slope.lake,
                                            . ~ . + std.distance_to_watercourse) 
# AIC
table.aic [11, 1] <- "DU8"
table.aic [11, 2] <- "Early Winter"
table.aic [11, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [11, 4] <- "Slope, Dist. to Lake, Dist. to Watercourse"
table.aic [11, 5] <- "(1 | UniqueID)"
table.aic [11, 6] <-  AIC (model.lme4.du8.ew.slope.lake.wc) 

## SLOPE, DISTANCE TO LAKE AND ELEVATION ##
model.lme4.du8.ew.slope.lake.elev <- update (model.lme4.du8.ew.slope.lake,
                                              . ~ . + std.elevation) 
# AIC
table.aic [12, 1] <- "DU8"
table.aic [12, 2] <- "Early Winter"
table.aic [12, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [12, 4] <- "Slope, Dist. to Lake, Elevation"
table.aic [12, 5] <- "(1 | UniqueID)"
table.aic [12, 6] <-  AIC (model.lme4.du8.ew.slope.lake.elev) 

## SLOPE, DISTANCE TO WATERCOURSE AND ELEVATION ##
model.lme4.du8.ew.slope.water.elev <- update (model.lme4.du8.ew.slope.water,
                                              . ~ . + std.elevation) 
# AIC
table.aic [13, 1] <- "DU8"
table.aic [13, 2] <- "Early Winter"
table.aic [13, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [13, 4] <- "Slope, Dist. to Watercourse, Elevation"
table.aic [13, 5] <- "(1 | UniqueID)"
table.aic [13, 6] <-  AIC (model.lme4.du8.ew.slope.water.elev) 

## DISTANCE TO LAKE, WATERCOURSE AND ELEVATION ##
model.lme4.du8.ew.lake.water.elev <- update (model.lme4.du8.ew.lake.water,
                                              . ~ . + std.elevation) 
# AIC
table.aic [14, 1] <- "DU8"
table.aic [14, 2] <- "Early Winter"
table.aic [14, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [14, 4] <- "Dist. to Lake, Dist. to Watercourse, Elevation"
table.aic [14, 5] <- "(1 | UniqueID)"
table.aic [14, 6] <-  AIC (model.lme4.du8.ew.lake.water.elev) 

## SLOPE, DISTANCE TO LAKE, WATERCOURSE AND ELEVATION ##
model.lme4.du8.ew.slope.lake.water.elev <- update (model.lme4.du8.ew.slope.lake.wc,
                                                    . ~ . + std.elevation) 
# AIC
table.aic [15, 1] <- "DU8"
table.aic [15, 2] <- "Early Winter"
table.aic [15, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [15, 4] <- "Slope, Dist. to Lake, Dist. to Watercourse, Elevation"
table.aic [15, 5] <- "(1 | UniqueID)"
table.aic [15, 6] <-  AIC (model.lme4.du8.ew.slope.lake.water.elev) 

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

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_terrain_water.csv", sep = ",")

#=================================
# Human Disturbance Models
#=================================
rsf.data.human.dist.du8.ew <- rsf.data.human.dist %>%
                                    dplyr::filter (du == "du8") %>%
                                    dplyr::filter (season == "EarlyWinter")
rsf.data.human.dist.du8.ew$pttype <- as.factor (rsf.data.human.dist.du8.ew$pttype)
### OUTLIERS ###
ggplot (rsf.data.human.dist.du8.ew, aes (x = pttype, y = distance_to_cut_1to4yo)) +
        geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter Distance to Cutblocks 1 to 4 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_ew_distcut1to4.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = pttype, y = distance_to_cut_5to9yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter Distance to Cutblocks 5 to 9 Years Old\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_ew_distcut5to9.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = pttype, y = distance_to_cut_10to29yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter Distance to Cutblocks 10 to 29 Years Old\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_ew_distcut10to29.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = pttype, y = distance_to_cut_30orOveryo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter Distance to Cutblocks Over 30 Years Old\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_ew_distcutover30.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = pttype, y = distance_to_paved_road)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter Distance to Paved Road\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Paved Road")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_ew_dist_pvd_rd.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = pttype, y = distance_to_resource_road)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter Distance to Resource Road\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Resource Road")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_ew_dist_resource_rd.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = pttype, y = distance_to_agriculture)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter Distance to Agriculture\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Agriculture")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_ew_dist_ag.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = pttype, y = distance_to_mines)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter Distance to Mine\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Mine")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_ew_dist_mine.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = pttype, y = distance_to_pipeline)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter Distance to Pipeline\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Pipeline")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_ew_dist_pipe.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = pttype, y = distance_to_wells)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter Distance to Well\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Well")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_ew_dist_well.png")

ggplot (rsf.data.human.dist.du8.ew, aes (x = pttype, y = distance_to_ski_hill)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter Distance to Ski Hill\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Ski Hill")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du8_ew_dist_ski.png")


### HISTOGRAMS ###
ggplot (rsf.data.human.dist.du8.ew, aes (x = distance_to_cut_1to4yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 500) +
  labs (title = "Histogram DU8, Early Winter Distance to Cutblock 1 to 4 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Distance to Cutblock",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_ew_dist_cut_1to4.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = distance_to_cut_5to9yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 500) +
  labs (title = "Histogram DU8, Early Winter Distance to Cutblock 5 to 9 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Distance to Cutblock",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_ew_dist_cut_5to9.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = distance_to_cut_10to29yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 500) +
  labs (title = "Histogram DU8, Early Winter Distance to Cutblock 10 to 29 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Distance to Cutblock",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_ew_dist_cut_10to29.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = distance_to_cut_30orOveryo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 500) +
  labs (title = "Histogram DU8, Early Winter Distance to Cutblock Over 30 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Distance to Cutblock",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_ew_dist_cut_over30.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = distance_to_paved_road, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU8, Early Winter Distance to Paved Road\
                at Available (0) and Used (1) Locations",
        x = "Distance to Paved Road",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_ew_dist_pvd_rd.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = distance_to_resource_road, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU8, Early Winter Distance to Resource Road\
                  at Available (0) and Used (1) Locations",
        x = "Distance to Resource Road",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_ew_dist_res_rd.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = distance_to_agriculture, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 500) +
  labs (title = "Histogram DU8, Early Winter Distance to Agriculture\
                  at Available (0) and Used (1) Locations",
        x = "Distance to Agriculture",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_ew_dist_ag.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = distance_to_mines, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 500) +
  labs (title = "Histogram DU8, Early Winter Distance to Mine at Available (0) and Used (1) Locations",
        x = "Distance to Mine",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_ew_dist_mine.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = distance_to_pipeline, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 500) +
  labs (title = "Histogram DU8, Early Winter Distance to Pipeline at\
                 Available (0) and Used (1) Locations",
        x = "Distance to Pipeline",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_ew_dist_pipe.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = distance_to_wells, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 500) +
  labs (title = "Histogram DU8, Early Winter Distance to Well at\
                 Available (0) and Used (1) Locations",
        x = "Distance to Pipeline",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_ew_dist_well.png")
ggplot (rsf.data.human.dist.du8.ew, aes (x = distance_to_ski_hill, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 1000) +
  labs (title = "Histogram DU8, Early Winter Distance to Ski Hill at\
                 Available (0) and Used (1) Locations",
        x = "Distance to Ski Hill",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du8_ew_dist_ski_hill.png")

### CORRELATION ###
corr.human.dist.du8.ew <- rsf.data.human.dist.du8.ew [c (10:14, 26, 20:22, 24)]
corr.human.dist.du8.ew <- round (cor (corr.human.dist.du8.ew, method = "spearman"), 3)
ggcorrplot (corr.human.dist.du8.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Human Disturbance Resource Selection Function Model
            Covariate Correlations for DU8, Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_human_dist_du8_ew.png")

### VIF ###
glm.human.du8.ew <- glm (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                                  distance_to_cut_10to29yo + distance_to_cut_30orOveryo +
                                  distance_to_paved_road + distance_to_resource_road + 
                                  distance_to_mines + distance_to_pipeline,  
                           data = rsf.data.human.dist.du8.ew,
                           family = binomial (link = 'logit'))
car::vif (glm.human.du8.ew)

### Build an AIC and AUC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

##############################################
### Generalized Linear Mixed Models (GLMMs) #
############################################
# standardize covariates  (helps with model convergence)
rsf.data.human.dist.du8.ew$std.distance_to_cut_1to4yo <- (rsf.data.human.dist.du8.ew$distance_to_cut_1to4yo - mean (rsf.data.human.dist.du8.ew$distance_to_cut_1to4yo)) / sd (rsf.data.human.dist.du8.ew$distance_to_cut_1to4yo)
rsf.data.human.dist.du8.ew$std.distance_to_cut_5to9yo <- (rsf.data.human.dist.du8.ew$distance_to_cut_5to9yo - mean (rsf.data.human.dist.du8.ew$distance_to_cut_5to9yo)) / sd (rsf.data.human.dist.du8.ew$distance_to_cut_5to9yo)
rsf.data.human.dist.du8.ew$std.distance_to_cut_10to29yo <- (rsf.data.human.dist.du8.ew$distance_to_cut_10to29yo - mean (rsf.data.human.dist.du8.ew$distance_to_cut_10to29yo)) / sd (rsf.data.human.dist.du8.ew$distance_to_cut_10to29yo)
rsf.data.human.dist.du8.ew$std.distance_to_cut_30orOveryo <- (rsf.data.human.dist.du8.ew$distance_to_cut_30orOveryo - mean (rsf.data.human.dist.du8.ew$distance_to_cut_30orOveryo)) / sd (rsf.data.human.dist.du8.ew$distance_to_cut_30orOveryo)
rsf.data.human.dist.du8.ew$std.distance_to_paved_road <- (rsf.data.human.dist.du8.ew$distance_to_paved_road - mean (rsf.data.human.dist.du8.ew$distance_to_paved_road)) / sd (rsf.data.human.dist.du8.ew$distance_to_paved_road)
rsf.data.human.dist.du8.ew$std.distance_to_resource_road <- (rsf.data.human.dist.du8.ew$distance_to_resource_road - mean (rsf.data.human.dist.du8.ew$distance_to_resource_road)) / sd (rsf.data.human.dist.du8.ew$distance_to_resource_road)
rsf.data.human.dist.du8.ew$std.distance_to_mines <- (rsf.data.human.dist.du8.ew$distance_to_mines - mean (rsf.data.human.dist.du8.ew$distance_to_mines)) / sd (rsf.data.human.dist.du8.ew$distance_to_mines)
rsf.data.human.dist.du8.ew$std.distance_to_pipeline <- (rsf.data.human.dist.du8.ew$distance_to_pipeline - mean (rsf.data.human.dist.du8.ew$distance_to_pipeline)) / sd (rsf.data.human.dist.du8.ew$distance_to_pipeline)

## DISTANCE TO CUTBLOCK ##
model.lme4.du8.ew.cutblock <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                              std.distance_to_cut_5to9yo + 
                                              std.distance_to_cut_10to29yo + 
                                              std.distance_to_cut_30orOveryo + (1 | uniqueID), 
                                      data = rsf.data.human.dist.du8.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [1, 1] <- "DU8"
table.aic [1, 2] <- "Early Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "DC1to4, DC5to9, DC10to29, DCover30"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du8.ew.cutblock)

## DISTANCE TO ROAD ##
model.lme4.du8.ew.road <- glmer (pttype ~ std.distance_to_paved_road + 
                                          std.distance_to_resource_road + (1 | uniqueID), 
                                     data = rsf.data.human.dist.du8.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [2, 1] <- "DU8"
table.aic [2, 2] <- "Early Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "DPR, DRR"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du8.ew.road)

## DISTANCE TO MINE ##
model.lme4.du8.ew.mine <- glmer (pttype ~ std.distance_to_mines + (1 | uniqueID), 
                                 data = rsf.data.human.dist.du8.ew, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [3, 1] <- "DU8"
table.aic [3, 2] <- "Early Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "DMine"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du8.ew.mine)

## DISTANCE TO PIPELINE ##
model.lme4.du8.ew.pipe <- glmer (pttype ~ std.distance_to_pipeline + (1 | uniqueID), 
                                 data = rsf.data.human.dist.du8.ew, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [4, 1] <- "DU8"
table.aic [4, 2] <- "Early Winter"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "DPipe"
table.aic [4, 5] <- "(1 | UniqueID)"
table.aic [4, 6] <-  AIC (model.lme4.du8.ew.pipe)

## DISTANCE TO CUTBLOCK and DISTANCE TO ROAD ##
model.lme4.du8.ew.cut.road <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                              std.distance_to_cut_5to9yo + 
                                              std.distance_to_cut_10to29yo + 
                                              std.distance_to_cut_30orOveryo + 
                                              std.distance_to_paved_road +
                                              std.distance_to_resource_road +
                                              (1 | uniqueID), 
                                     data = rsf.data.human.dist.du8.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [5, 1] <- "DU8"
table.aic [5, 2] <- "Early Winter"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR"
table.aic [5, 5] <- "(1 | UniqueID)"
table.aic [5, 6] <-  AIC (model.lme4.du8.ew.cut.road)

## DISTANCE TO CUTBLOCK and DISTANCE TO MINE ##
model.lme4.du8.ew.cut.mine <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                               std.distance_to_cut_5to9yo + 
                                               std.distance_to_cut_10to29yo + 
                                               std.distance_to_cut_30orOveryo + 
                                               std.distance_to_mines +
                                               (1 | uniqueID), 
                                     data = rsf.data.human.dist.du8.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [6, 1] <- "DU8"
table.aic [6, 2] <- "Early Winter"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DMine"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <-  AIC (model.lme4.du8.ew.cut.mine)

## DISTANCE TO CUTBLOCK and DISTANCE TO PIPELINE ##
model.lme4.du8.ew.cut.pipe <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                               std.distance_to_cut_5to9yo + 
                                               std.distance_to_cut_10to29yo + 
                                               std.distance_to_cut_30orOveryo + 
                                               std.distance_to_pipeline +
                                               (1 | uniqueID), 
                                     data = rsf.data.human.dist.du8.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [7, 1] <- "DU8"
table.aic [7, 2] <- "Early Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DPipeline"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du8.ew.cut.pipe)

## DISTANCE TO ROAD AND DISTANCE TO MINE ##
model.lme4.du8.ew.road.mine <- glmer (pttype ~ std.distance_to_paved_road + 
                                                std.distance_to_resource_road + 
                                                std.distance_to_mines +
                                                (1 | uniqueID), 
                                       data = rsf.data.human.dist.du8.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [8, 1] <- "DU8"
table.aic [8, 2] <- "Early Winter"
table.aic [8, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [8, 4] <- "DPR, DRR, DMine"
table.aic [8, 5] <- "(1 | UniqueID)"
table.aic [8, 6] <-  AIC (model.lme4.du8.ew.road.mine)

## DISTANCE TO ROAD AND DISTANCE TO PIPELINE ##
model.lme4.du8.ew.road.pipe <- glmer (pttype ~ std.distance_to_paved_road + 
                                                std.distance_to_resource_road + 
                                                std.distance_to_pipeline +
                                                (1 | uniqueID), 
                                      data = rsf.data.human.dist.du8.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [9, 1] <- "DU8"
table.aic [9, 2] <- "Early Winter"
table.aic [9, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [9, 4] <- "DPR, DRR, DPipeline"
table.aic [9, 5] <- "(1 | UniqueID)"
table.aic [9, 6] <-  AIC (model.lme4.du8.ew.road.pipe)

## DISTANCE TO MINE AND DISTANCE TO PIPELINE ##
model.lme4.du8.ew.mine.pipe <- glmer (pttype ~ std.distance_to_mines + 
                                               std.distance_to_pipeline +
                                               (1 | uniqueID), 
                                     data = rsf.data.human.dist.du8.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [10, 1] <- "DU8"
table.aic [10, 2] <- "Early Winter"
table.aic [10, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [10, 4] <- "DMine, DPipeline"
table.aic [10, 5] <- "(1 | UniqueID)"
table.aic [10, 6] <-  AIC (model.lme4.du8.ew.mine.pipe)

## DISTANCE TO CUTBLOCK, DISTANCE TO ROAD, DISTANCE TO MINE ##
model.lme4.du8.ew.cut.road.mine <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                   std.distance_to_cut_5to9yo + 
                                                   std.distance_to_cut_10to29yo + 
                                                   std.distance_to_cut_30orOveryo +
                                                   std.distance_to_paved_road +
                                                   std.distance_to_resource_road +
                                                   std.distance_to_mines +
                                                   (1 | uniqueID), 
                                         data = rsf.data.human.dist.du8.ew, 
                                         family = binomial (link = "logit"),
                                         verbose = T) 
# AIC
table.aic [11, 1] <- "DU8"
table.aic [11, 2] <- "Early Winter"
table.aic [11, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [11, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR, DMine"
table.aic [11, 5] <- "(1 | UniqueID)"
table.aic [11, 6] <-  AIC (model.lme4.du8.ew.cut.road.mine)

## DISTANCE TO CUTBLOCK, DISTANCE TO ROAD, DISTANCE TO PIPELINE ##
model.lme4.du8.ew.cut.road.pipe <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                    std.distance_to_cut_5to9yo + 
                                                    std.distance_to_cut_10to29yo + 
                                                    std.distance_to_cut_30orOveryo +
                                                    std.distance_to_paved_road +
                                                    std.distance_to_resource_road +
                                                    std.distance_to_pipeline +
                                                    (1 | uniqueID), 
                                          data = rsf.data.human.dist.du8.ew, 
                                          family = binomial (link = "logit"),
                                          verbose = T) 
# AIC
table.aic [12, 1] <- "DU8"
table.aic [12, 2] <- "Early Winter"
table.aic [12, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [12, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR, DPipeline"
table.aic [12, 5] <- "(1 | UniqueID)"
table.aic [12, 6] <-  AIC (model.lme4.du8.ew.cut.road.pipe)


## DISTANCE TO CUTBLOCK, DISTANCE TO MINE, DISTANCE TO PIPELINE ##
model.lme4.du8.ew.cut.mine.pipe <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                   std.distance_to_cut_5to9yo + 
                                                   std.distance_to_cut_10to29yo + 
                                                   std.distance_to_cut_30orOveryo + 
                                                   std.distance_to_mines +
                                                   std.distance_to_pipeline +
                                                   (1 | uniqueID), 
                                           data = rsf.data.human.dist.du8.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [13, 1] <- "DU8"
table.aic [13, 2] <- "Early Winter"
table.aic [13, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [13, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DMine, DPipeline"
table.aic [13, 5] <- "(1 | UniqueID)"
table.aic [13, 6] <-  AIC (model.lme4.du8.ew.cut.mine.pipe)

## DISTANCE TO ROAD, DISTANCE TO MINE, DISTANCE TO PIPELINE ##
model.lme4.du8.ew.road.mine.pipe <- glmer (pttype ~ std.distance_to_paved_road + 
                                                    std.distance_to_resource_road + 
                                                    std.distance_to_mines +
                                                    std.distance_to_pipeline +
                                                    (1 | uniqueID), 
                                            data = rsf.data.human.dist.du8.ew, 
                                            family = binomial (link = "logit"),
                                            verbose = T) 
# AIC
table.aic [14, 1] <- "DU8"
table.aic [14, 2] <- "Early Winter"
table.aic [14, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [14, 4] <- "DPR, DRR, DMine, DPipeline"
table.aic [14, 5] <- "(1 | UniqueID)"
table.aic [14, 6] <-  AIC (model.lme4.du8.ew.road.mine.pipe)

## DISTANCE TO CUTBLOCK, DISTANCE TO ROAD, DISTANCE TO MINE, DISTANCE TO PIPELINE ##
model.lme4.du8.ew.cut.road.mine.pipe <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                        std.distance_to_cut_5to9yo + 
                                                        std.distance_to_cut_10to29yo + 
                                                        std.distance_to_cut_30orOveryo + 
                                                        std.distance_to_paved_road +
                                                        std.distance_to_resource_road +
                                                        std.distance_to_mines +
                                                        std.distance_to_pipeline +
                                                        (1 | uniqueID), 
                                              data = rsf.data.human.dist.du8.ew, 
                                              family = binomial (link = "logit"),
                                              verbose = T) 
# AIC
table.aic [15, 1] <- "DU8"
table.aic [15, 2] <- "Early Winter"
table.aic [15, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [15, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR, DMine, DPipeline"
table.aic [15, 5] <- "(1 | UniqueID)"
table.aic [15, 6] <-  AIC (model.lme4.du8.ew.cut.road.mine.pipe)

## AIC comparison of MODELS ## 
table.aic$AIC <- as.numeric (table.aic$AIC)
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [c (1:15), 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [c (1:15), 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [c (1:15), 6])))),
                    (exp (-0.5 * (table.aic [4, 6] - min (table.aic [c (1:15), 6])))),
                    (exp (-0.5 * (table.aic [5, 6] - min (table.aic [c (1:15), 6])))),
                    (exp (-0.5 * (table.aic [6, 6] - min (table.aic [c (1:15), 6])))),
                    (exp (-0.5 * (table.aic [7, 6] - min (table.aic [c (1:15), 6])))),
                    (exp (-0.5 * (table.aic [8, 6] - min (table.aic [c (1:15), 6])))),
                    (exp (-0.5 * (table.aic [9, 6] - min (table.aic [c (1:15), 6])))), 
                    (exp (-0.5 * (table.aic [10, 6] - min (table.aic [c (1:15), 6])))),
                    (exp (-0.5 * (table.aic [11, 6] - min (table.aic [c (1:15), 6])))),
                    (exp (-0.5 * (table.aic [12, 6] - min (table.aic [c (1:15), 6])))),
                    (exp (-0.5 * (table.aic [13, 6] - min (table.aic [c (1:15), 6])))),
                    (exp (-0.5 * (table.aic [14, 6] - min (table.aic [c (1:15), 6])))),
                    (exp (-0.5 * (table.aic [15, 6] - min (table.aic [c (1:15), 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [c (1:15), 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [c (1:15), 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [c (1:15), 6])))) / sum (list.aic.like), 3)
table.aic [4, 7] <- round ((exp (-0.5 * (table.aic [4, 6] - min (table.aic [c (1:15), 6])))) / sum (list.aic.like), 3)
table.aic [5, 7] <- round ((exp (-0.5 * (table.aic [5, 6] - min (table.aic [c (1:15), 6])))) / sum (list.aic.like), 3)
table.aic [6, 7] <- round ((exp (-0.5 * (table.aic [6, 6] - min (table.aic [c (1:15), 6])))) / sum (list.aic.like), 3)
table.aic [7, 7] <- round ((exp (-0.5 * (table.aic [7, 6] - min (table.aic [c (1:15), 6])))) / sum (list.aic.like), 3)
table.aic [8, 7] <- round ((exp (-0.5 * (table.aic [8, 6] - min (table.aic [c (1:15), 6])))) / sum (list.aic.like), 3)
table.aic [9, 7] <- round ((exp (-0.5 * (table.aic [9, 6] - min (table.aic [c (1:15), 6])))) / sum (list.aic.like), 3)
table.aic [10, 7] <- round ((exp (-0.5 * (table.aic [10, 6] - min (table.aic [c (1:15), 6])))) / sum (list.aic.like), 3)
table.aic [11, 7] <- round ((exp (-0.5 * (table.aic [11, 6] - min (table.aic [c (1:15), 6])))) / sum (list.aic.like), 3)
table.aic [12, 7] <- round ((exp (-0.5 * (table.aic [12, 6] - min (table.aic [c (1:15), 6])))) / sum (list.aic.like), 3)
table.aic [13, 7] <- round ((exp (-0.5 * (table.aic [13, 6] - min (table.aic [c (1:15), 6])))) / sum (list.aic.like), 3)
table.aic [14, 7] <- round ((exp (-0.5 * (table.aic [14, 6] - min (table.aic [c (1:15), 6])))) / sum (list.aic.like), 3)
table.aic [15, 7] <- round ((exp (-0.5 * (table.aic [15, 6] - min (table.aic [c (1:15), 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_human_disturb.csv", sep = ",")

#=================================
# Natural Disturbance Models
#=================================
rsf.data.natural.dist.du8.ew <- rsf.data.natural.dist %>%
                                    dplyr::filter (du == "du8") %>%
                                    dplyr::filter (season == "EarlyWinter")

### CORRELATION ###
corr.rsf.data.natural.dist.du8.ew <- rsf.data.natural.dist.du8.ew [c (10:14)]
corr.rsf.data.natural.dist.du8.ew <- round (cor (corr.rsf.data.natural.dist.du8.ew, method = "spearman"), 3)
ggcorrplot (corr.rsf.data.natural.dist.du8.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Fire and Beetle Disturbance Selection Function Model
            Covariate Correlations for DU8, Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_natural_disturb_du8_ew.png")

### VIF ###
glm.nat.disturb.du8.ew <- glm (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                                        fire_1to5yo + fire_6to25yo + fire_over25yo, 
                               data = rsf.data.natural.dist.du8.ew,
                               family = binomial (link = 'logit'))
car::vif (glm.nat.disturb.du8.ew)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

## FIRE ##
model.lme4.du8.ew.fire <- glmer (pttype ~ fire_1to5yo + fire_6to25yo +
                                          fire_over25yo + (1 | uniqueID), 
                                 data = rsf.data.natural.dist.du8.ew, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [1, 1] <- "DU8"
table.aic [1, 2] <- "Early Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "Fire1to5, Fire6to25, Fireover25"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du8.ew.fire)

## BEETLE ##
model.lme4.du8.ew.beetle <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo +
                                            (1 | uniqueID), 
                                   data = rsf.data.natural.dist.du8.ew, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# AIC
table.aic [2, 1] <- "DU8"
table.aic [2, 2] <- "Early Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "Beetle1to5, Beetle6to9"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du8.ew.beetle)

## FIRE AND BEETLE ##
model.lme4.du8.ew.fire.beetle <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo + 
                                                 beetle_1to5yo + beetle_6to9yo +
                                                 (1 | uniqueID), 
                                       data = rsf.data.natural.dist.du8.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [3, 1] <- "DU8"
table.aic [3, 2] <- "Early Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "Fire1to5, Fire6to25, Fireover25, Beetle1to5, Beetle6to9"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <- AIC (model.lme4.du8.ew.fire.beetle)

## AIC comparison of MODELS ## 
table.aic$AIC <- as.numeric (table.aic$AIC)
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_natural_disturb.csv", sep = ",")

#=================================
# ANNUAL CLIMATE Models
#=================================
rsf.data.climate.annual.du8.ew <- rsf.data.climate.annual %>%
                                            dplyr::filter (du == "du8") %>%
                                            dplyr::filter (season == "EarlyWinter")
rsf.data.climate.annual.du8.ew$pttype <- as.factor (rsf.data.climate.annual.du8.ew$pttype)

### OUTLIERS ###
ggplot (rsf.data.climate.annual.du8.ew, aes (x = pttype, y = frost_free_start_julian)) +
            geom_boxplot (outlier.colour = "red") +
            labs (title = "Boxplot DU8, Early Winter, Annual Frost Free Period Julian Start Day\ 
                  at Available (0) and Used (1) Locations",
                  x = "Available (0) and Used (1) Locations",
                  y = "Julian Day")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_ew_frost_free_start.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = pttype, y = growing_degree_days)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Early Winter, Annual Growing Degree Days \
              at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Number of Days")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_ew_grow_deg_day.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = pttype, y = frost_free_end_julian)) +
          geom_boxplot (outlier.colour = "red") +
          labs (title = "Boxplot DU8, Early Winter, Annual Frost Free End Julian Day \
                at Available (0) and Used (1) Locations",
                x = "Available (0) and Used (1) Locations",
                y = "Julian Day")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_ew_frost_free_end.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = pttype, y = frost_free_period)) +
          geom_boxplot (outlier.colour = "red") +
          labs (title = "Boxplot DU8, Early Winter, Annual Frost Free Period \
                        at Available (0) and Used (1) Locations",
                x = "Available (0) and Used (1) Locations",
                y = "Number of Days")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_ew_frost_free_period.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = pttype, y = mean_annual_ppt)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Early Winter, Mean Annual Precipitation \
                              at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Precipitation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_ew_mean_annual_ppt.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = pttype, y = mean_annual_temp)) +
          geom_boxplot (outlier.colour = "red") +
          labs (title = "Boxplot DU8, Early Winter, Mean Annual Temperature \
                                      at Available (0) and Used (1) Locations",
                x = "Available (0) and Used (1) Locations",
                y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_ew_mean_annual_temp.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = pttype, y = mean_coldest_month_temp)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Early Winter, Mean Annual Coldest Month Temperature \
                                            at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_ew_mean_cold_mth_temp.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = pttype, y = mean_warmest_month_temp)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Early Winter, Mean Annual Warmest Month Temperature \
                                                  at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_ew_mean_warm_mth_temp.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = pttype, y = ppt_as_snow_annual)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Early Winter, Mean Annual Precipitation as Snow \
                    at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Precipitation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_ew_mean_annual_pas.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = pttype, y = number_frost_free_days)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Early Winter, Frost Free Days \
                          at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Number of Days")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du8_ew_num_frost_free_days.png")

### HISTOGRAMS ###
ggplot (rsf.data.climate.annual.du8.ew, aes (x = frost_free_start_julian, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU8, Early Winter, Frost Free Start Julian Day\
              at Available (0) and Used (1) Locations",
              x = "Julian Day",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_ew_frost_free_start.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = growing_degree_days, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 100) +
        labs (title = "Histogram DU8, Early Winter, Annual Growing Degree Days\
                    at Available (0) and Used (1) Locations",
              x = "Number of Days",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_ew_grow_deg_days.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = frost_free_end_julian, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU8, Early Winter, Frost Free End Julian Day\
              at Available (0) and Used (1) Locations",
              x = "Julian Day",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_ew_frost_free_end.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = frost_free_period, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU8, Early Winter, Frost Free Period\
                    at Available (0) and Used (1) Locations",
              x = "Number of Days",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_ew_frost_free_period.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = mean_annual_ppt, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 250) +
        labs (title = "Histogram DU8, Early Winter, Mean Annual Precipitation\
                          at Available (0) and Used (1) Locations",
              x = "Precipitation",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_ew_mean_annual_ppt.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = mean_annual_temp, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU8, Early Winter, Mean Annual Temperature\
                                at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_ew_mean_annual_temp.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = mean_coldest_month_temp, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU8, Early Winter, Mean Annual Coldest Month Temperature\
                       at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_ew_mean_annual_cold_mth_temp.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = mean_warmest_month_temp, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU8, Early Winter, Mean Annual Warmest Month Temperature\
                             at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_ew_mean_annual_warm_mth_temp.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = number_frost_free_days, fill = pttype)) + 
          geom_histogram (position = "dodge") +
          labs (title = "Histogram DU8, Early Winter, Annual Number of Frost Free Days\
                                     at Available (0) and Used (1) Locations",
                x = "Number of Days",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_ew_mean_frost_free_days.png")
ggplot (rsf.data.climate.annual.du8.ew, aes (x = ppt_as_snow_annual, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU8, Early Winter, Annual Precipitation as Snow\
              at Available (0) and Used (1) Locations",
              x = "Precipitation",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_ew_mean_pas.png")

### CORRELATION ###
corr.rsf.data.climate.annual.du8.ew <- rsf.data.climate.annual.du8.ew [c (10:19)]
corr.rsf.data.climate.annual.du8.ew <- round (cor (corr.rsf.data.climate.annual.du8.ew, method = "spearman"), 3)
ggcorrplot (corr.rsf.data.climate.annual.du8.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Annual Climate Resource Selection Function Model
            Covariate Correlations for DU8, Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_annual_climate_du8_ew.png")

### VIF ###
glm.annual.climate.du8.ew <- glm (pttype ~ ppt_as_snow_annual + frost_free_start_julian, 
                                   data = rsf.data.climate.annual.du8.ew,
                                   family = binomial (link = 'logit'))
car::vif (glm.annual.climate.du8.ew)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

# standardize covariates  (helps with model convergence)
rsf.data.climate.annual.du8.ew$std.ppt_as_snow_annual <- (rsf.data.climate.annual.du8.ew$ppt_as_snow_annual - mean (rsf.data.climate.annual.du8.ew$ppt_as_snow_annual)) / sd (rsf.data.climate.annual.du8.ew$ppt_as_snow_annual)
rsf.data.climate.annual.du8.ew$std.frost_free_start_julian <- (rsf.data.climate.annual.du8.ew$frost_free_start_julian - mean (rsf.data.climate.annual.du8.ew$growing_degree_days)) / sd (rsf.data.climate.annual.du8.ew$frost_free_start_julian)

## PRECIPITATION AS SNOW ##
model.lme4.du8.ew.pas <- glmer (pttype ~ std.ppt_as_snow_annual + (1 | uniqueID), 
                                data = rsf.data.climate.annual.du8.ew, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [1, 1] <- "DU8"
table.aic [1, 2] <- "Early Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "PaS"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du8.ew.pas)

## FROST FREE START DAY ##
model.lme4.du8.ew.ffsd <- glmer (pttype ~ std.frost_free_start_julian + (1 | uniqueID), 
                                data = rsf.data.climate.annual.du8.ew, 
                                family = binomial (link = "logit"),
                                verbose = T) 
ss <- getME (model.lme4.du8.ew.ffsd, c ("theta","fixef"))
model.lme4.du8.ew.ffsd <- update (model.lme4.du8.ew.ffsd, start = ss) # failed to converge, restart with parameter estimates
# MODEL DID NOT CONVERGE
# AIC
table.aic [2, 1] <- "DU8"
table.aic [2, 2] <- "Early Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "FFSD"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du8.ew.ffsd)

## PRECIPITATION AS SNOW and FROST FREE START DAY ##
model.lme4.du8.ew.pas.gdd <- glmer (pttype ~ std.ppt_as_snow_annual + std.frost_free_start_julian +
                                              (1 | uniqueID), 
                                    data = rsf.data.climate.annual.du8.ew, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [3, 1] <- "DU8"
table.aic [3, 2] <- "Early Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "PaS, FFSD"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du8.ew.pas.gdd)

## AIC comparison of MODELS ## 
table.aic$AIC <- as.numeric (table.aic$AIC)
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_annual_climate.csv", sep = ",")


#=================================
# WINTER CLIMATE Models
#=================================
rsf.data.climate.winter.du8.ew <- rsf.data.climate.winter %>%
                                    dplyr::filter (du == "du8") %>%
                                    dplyr::filter (season == "EarlyWinter")
rsf.data.climate.winter.du8.ew$pttype <- as.factor (rsf.data.climate.winter.du8.ew$pttype)

### OUTLIERS ###
ggplot (rsf.data.climate.winter.du8.ew, aes (x = pttype, y = ppt_as_snow_winter)) +
            geom_boxplot (outlier.colour = "red") +
            labs (title = "Boxplot DU8, Early Winter, Precipitation as Snow\ 
                            at Available (0) and Used (1) Locations",
                  x = "Available (0) and Used (1) Locations",
                  y = "Precipitation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_winter_climate_du8_ew_ppt_as_snow.png")
ggplot (rsf.data.climate.winter.du8.ew, aes (x = pttype, y = ppt_winter)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Early Winter, Precipitation\ 
              at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Precipitation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_winter_climate_du8_ew_ppt.png")
ggplot (rsf.data.climate.winter.du8.ew, aes (x = pttype, y = temp_avg_winter)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Early Winter, Average Temperature\ 
              at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_winter_climate_du8_ew_temp_avg.png")
ggplot (rsf.data.climate.winter.du8.ew, aes (x = pttype, y = temp_max_winter)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU8, Early Winter, Maximum Temperature\ 
                    at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_winter_climate_du8_ew_temp_max.png")
ggplot (rsf.data.climate.winter.du8.ew, aes (x = pttype, y = temp_min_winter)) +
          geom_boxplot (outlier.colour = "red") +
          labs (title = "Boxplot DU8, Early Winter, Minimum Temperature\ 
                            at Available (0) and Used (1) Locations",
                x = "Available (0) and Used (1) Locations",
                y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_winter_climate_du8_ew_temp_min.png")

### HISTOGRAMS ###
ggplot (rsf.data.climate.winter.du8.ew, aes (x = ppt_as_snow_winter, fill = pttype)) + 
          geom_histogram (position = "dodge", binwidth = 50) +
          labs (title = "Histogram DU8, Early Winter, Precipitation as Snow\
                at Available (0) and Used (1) Locations",
                x = "Precipitation",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_ew_pas.png")
ggplot (rsf.data.climate.winter.du8.ew, aes (x = ppt_winter, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 50) +
        labs (title = "Histogram DU8, Early Winter, Precipitation\
                      at Available (0) and Used (1) Locations",
              x = "Precipitation",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_ew_ppt.png")
ggplot (rsf.data.climate.winter.du8.ew, aes (x = temp_avg_winter, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 1) +
        labs (title = "Histogram DU8, Early Winter, Average Temperature\
                            at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_ew_temp_avg.png")
ggplot (rsf.data.climate.winter.du8.ew, aes (x = temp_max_winter, fill = pttype)) + 
          geom_histogram (position = "dodge") +
          labs (title = "Histogram DU8, Early Winter, Maximum Temperature\
                         at Available (0) and Used (1) Locations",
                x = "Temperature",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_ew_temp_max.png")
ggplot (rsf.data.climate.winter.du8.ew, aes (x = temp_min_winter, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU8, Early Winter, Minimum Temperature\
                               at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du8_ew_temp_min.png")

### CORRELATION ###
corr.climate.winter.du8.ew <- rsf.data.climate.winter.du8.ew [c (10, 12:16)] # frost free days all = 0
corr.climate.winter.du8.ew <- round (cor (corr.climate.winter.du8.ew, method = "spearman"), 3)
ggcorrplot (corr.climate.winter.du8.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Winter Climate Resource Selection Function Model
            Covariate Correlations for DU8, Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_winter_climate_du8_ew.png")

### VIF ###
glm.winter.climate.du8.ew <- glm (pttype ~ ppt_as_snow_winter + temp_avg_winter, 
                                  data = rsf.data.climate.winter.du8.ew,
                                  family = binomial (link = 'logit'))
car::vif (glm.winter.climate.du8.ew)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

# standardize covariates  (helps with model convergence)
rsf.data.climate.winter.du8.ew$std.ppt_as_snow_winter <- (rsf.data.climate.winter.du8.ew$ppt_as_snow_winter - mean (rsf.data.climate.winter.du8.ew$ppt_as_snow_winter)) / sd (rsf.data.climate.winter.du8.ew$ppt_as_snow_winter)
rsf.data.climate.winter.du8.ew$std.temp_avg_winter <- (rsf.data.climate.winter.du8.ew$temp_avg_winter - mean (rsf.data.climate.winter.du8.ew$temp_avg_winter)) / sd (rsf.data.climate.winter.du8.ew$temp_avg_winter)

## PRECIPITATION AS SNOW ##
model.lme4.du8.ew.winter.pas <- glmer (pttype ~ std.ppt_as_snow_winter + (1 | uniqueID), 
                                data = rsf.data.climate.winter.du8.ew, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [1, 1] <- "DU8"
table.aic [1, 2] <- "Early Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "WPaS"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du8.ew.winter.pas)

## AVERAGE TEMPERATURE ##
model.lme4.du8.ew.winter.temp <- glmer (pttype ~ std.temp_avg_winter + (1 | uniqueID), 
                                       data = rsf.data.climate.winter.du8.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [2, 1] <- "DU8"
table.aic [2, 2] <- "Early Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "WTemp"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du8.ew.winter.temp)

## PRECIPITATION AS SNOW and AVERAGE TEMPERATURE ##
model.lme4.du8.ew.winter.pas.temp <- glmer (pttype ~ std.ppt_as_snow_winter + std.temp_avg_winter +
                                                      (1 | uniqueID), 
                                       data = rsf.data.climate.winter.du8.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [3, 1] <- "DU8"
table.aic [3, 2] <- "Early Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "WPaS, WTemp"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du8.ew.winter.pas.temp)

## AIC comparison of MODELS ## 
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_winter_climate.csv", sep = ",")

#=================================
# VEGETATION/FOREST Models
#=================================
rsf.data.veg.du8.ew <- rsf.data.veg %>%
                         dplyr::filter (du == "du8") %>%
                         dplyr::filter (season == "EarlyWinter")
rsf.data.veg.du8.ew$pttype <- as.factor (rsf.data.veg.du8.ew$pttype)

rsf.data.veg.du8.ew <- rsf.data.veg.du8.ew %>% # remove basal area outlier
                    filter (vri_basal_area < 150)

# reclassify BEC for caribou: NOTE TWO TYPES; USED THE LATTER IN MODEL
rsf.data.veg.du8.ew$bec_label_reclass <- rsf.data.veg.du8.ew$bec_label
rsf.data.veg.du8.ew$bec_label_reclass <- recode (rsf.data.veg.du8.ew$bec_label_reclass,
                                               "'BAFAun' = 'BAFA'") # simplified to alpine type
rsf.data.veg.du8.ew$bec_label_reclass <- recode (rsf.data.veg.du8.ew$bec_label_reclass,
                                          "'BAFAunp' = 'BAFA'")
rsf.data.veg.du8.ew$bec_label_reclass <- recode (rsf.data.veg.du8.ew$bec_label_reclass,
                                          "'BWBSdk' = 'BWBS'") # simplified to BWBS type
rsf.data.veg.du8.ew$bec_label_reclass <- recode (rsf.data.veg.du8.ew$bec_label_reclass,
                                          "'BWBSmk' = 'BWBS'")
rsf.data.veg.du8.ew$bec_label_reclass <- recode (rsf.data.veg.du8.ew$bec_label_reclass,
                                          "'BWBSmw' = 'BWBS'")
rsf.data.veg.du8.ew$bec_label_reclass <- recode (rsf.data.veg.du8.ew$bec_label_reclass,
                                          "'BWBSwk 1' = 'BWBS'")
rsf.data.veg.du8.ew$bec_label_reclass <- recode (rsf.data.veg.du8.ew$bec_label_reclass,
                                          "'BWBSwk 2' = 'BWBS'")
rsf.data.veg.du8.ew$bec_label_reclass <- recode (rsf.data.veg.du8.ew$bec_label_reclass,
                                          "'BWBSwk 3' = 'BWBS'")
rsf.data.veg.du8.ew$bec_label_reclass <- recode (rsf.data.veg.du8.ew$bec_label_reclass,
                                                 "'SBS wk 1' = 'SBS_very_wet_to_wet_cool'")
rsf.data.veg.du8.ew$bec_label_reclass <- recode (rsf.data.veg.du8.ew$bec_label_reclass,
                                                 "'SBS wk 2' = 'SBS_very_wet_to_wet_cool'")
rsf.data.veg.du8.ew$bec_label_reclass <- recode (rsf.data.veg.du8.ew$bec_label_reclass,
                                                 "'SBS vk' = 'SBS_very_wet_to_wet_cool'")
rsf.data.veg.du8.ew$bec_label_reclass <- recode (rsf.data.veg.du8.ew$bec_label_reclass,
                                                 "'ESSFmvp' = 'ESSF_moist_very_cold'")
rsf.data.veg.du8.ew$bec_label_reclass <- recode (rsf.data.veg.du8.ew$bec_label_reclass,
                                                 "'ESSFmv 2' = 'ESSF_moist_very_cold'")
rsf.data.veg.du8.ew$bec_label_reclass <- recode (rsf.data.veg.du8.ew$bec_label_reclass,
                                                 "'ESSFwc 3' = 'ESSF_wet_cold'")
rsf.data.veg.du8.ew$bec_label_reclass <- recode (rsf.data.veg.du8.ew$bec_label_reclass,
                                                 "'ESSFwcp' = 'ESSF_wet_cold'")
rsf.data.veg.du8.ew$bec_label_reclass <- recode (rsf.data.veg.du8.ew$bec_label_reclass,
                                                 "'ESSFwk 2' = 'ESSF_wet_cool'")
rsf.data.veg.du8.ew$bec_label_reclass <- relevel (rsf.data.veg.du8.ew$bec_label_reclass,
                                                  ref = "ESSF_wet_cold") # reference category

rsf.data.combo.du8.ew$bec_label_reclass2 <- rsf.data.combo.du8.ew$bec_label
rsf.data.combo.du8.ew <- rsf.data.combo.du8.ew %>%
  dplyr::filter (bec_label_reclass2 != "SBS vk")
rsf.data.combo.du8.ew$bec_label_reclass2 <- relevel (rsf.data.combo.du8.ew$bec_label_reclass2,
                                                     ref = "ESSFwc 3") # reference category

rsf.data.veg.du8.ew$vri_bclcs_class  <- relevel (rsf.data.veg.du8.ew$vri_bclcs_class,
                                                  ref = "Upland-Treed-Conifer")
### OUTLIERS ###
ggplot (rsf.data.veg.du8.ew, aes (x = pttype, y = vri_basal_area)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter, Basal Area\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Basal Area of Trees")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_ew_basal_area.png")
ggplot (rsf.data.veg.du8.ew, aes (x = pttype, y = vri_bryoid_cover_pct)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter, Bryoid Cover\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Percent Cover")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_ew_bryoid_perc.png")
ggplot (rsf.data.veg.du8.ew, aes (x = pttype, y = vri_crown_closure)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter, Crown Closure\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Crown Closure")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_ew_crown_close.png")
ggplot (rsf.data.veg.du8.ew, aes (x = pttype, y = vri_herb_cover_pct)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter, Herbaceous Cover\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Percent Cover")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_ew_herb_cover.png")
ggplot (rsf.data.veg.du8.ew, aes (x = pttype, y = vri_live_volume)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter, Live Forest Stand Volume\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Volume")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_ew_live_volume.png")
ggplot (rsf.data.veg.du8.ew, aes (x = pttype, y = vri_proj_age)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter, Projected Forest Stand Age\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Age")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_ew_stand_age.png")
ggplot (rsf.data.veg.du8.ew, aes (x = pttype, y = vri_proj_height)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter, Projected Forest Stand Height\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Height")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_ew_stand_height.png")
ggplot (rsf.data.veg.du8.ew, aes (x = pttype, y = vri_shrub_crown_close)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter, Shrub Crown Closure\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Crown Closure")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_ew_shrub_closure.png")
ggplot (rsf.data.veg.du8.ew, aes (x = pttype, y = vri_shrub_height)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter, Shrub Height\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Height")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_ew_shrub_height.png")
ggplot (rsf.data.veg.du8.ew, aes (x = pttype, y = vri_site_index)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU8, Early Winter, Site Index\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Site Index")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du8_ew_site_index.png")

### HISTOGRAMS ###
ggplot (rsf.data.veg.du8.ew, aes (x = bec_label_reclass, fill = pttype)) + 
            geom_histogram (position = "dodge", stat = "count") +
            labs (title = "Histogram DU8, Early Winter, BEC Type\
                          at Available (0) and Used (1) Locations",
                  x = "Biogeclimatic Unit Type",
                  y = "Count") +
            scale_fill_discrete (name = "Location Type") +
            theme (axis.text.x = element_text (angle = 45))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_veg_du8_ew_bec.png")

rsf.data.veg.du8.ew$vri_bclcs_class <- recode (rsf.data.veg.du8.ew$vri_bclcs_class,
                                        "'Wetland-Treed-Conifer' = 'Wetland'")
rsf.data.veg.du8.ew$vri_bclcs_class <- recode (rsf.data.veg.du8.ew$vri_bclcs_class,
                                        "'Wetland-Shrub' = 'Wetland'")
rsf.data.veg.du8.ew$vri_bclcs_class <- recode (rsf.data.veg.du8.ew$vri_bclcs_class,
                                        "'Wetland-Treed-Mixed' = 'Wetland'")
rsf.data.veg.du8.ew$vri_bclcs_class <- recode (rsf.data.veg.du8.ew$vri_bclcs_class,
                                        "'Wetland-Treed-Deciduous' = 'Wetland'")
rsf.data.veg.du8.ew$vri_bclcs_class <- recode (rsf.data.veg.du8.ew$vri_bclcs_class,
                                               "'Wetland-NonTreed' = 'Wetland'")
rsf.data.veg.du8.ew$vri_bclcs_class <- recode (rsf.data.veg.du8.ew$vri_bclcs_class,
                                               "'Wetland-Herb' = 'Wetland'")
rsf.data.veg.du8.ew$vri_bclcs_class <- recode (rsf.data.veg.du8.ew$vri_bclcs_class,
                                               "'Water' = 'Wetland'")
rsf.data.veg.du8.ew$vri_bclcs_class <- recode (rsf.data.veg.du8.ew$vri_bclcs_class,
                                               "'Alpine-Herb' = 'Alpine'")
rsf.data.veg.du8.ew$vri_bclcs_class <- recode (rsf.data.veg.du8.ew$vri_bclcs_class,
                                               "'Alpine-NonTreed' = 'Alpine'")
rsf.data.veg.du8.ew$vri_bclcs_class <- recode (rsf.data.veg.du8.ew$vri_bclcs_class,
                                               "'Alpine-Shrub' = 'Alpine'")
rsf.data.veg.du8.ew$vri_bclcs_class <- recode (rsf.data.veg.du8.ew$vri_bclcs_class,
                                               "'Alpine-Lichen' = 'Alpine'")
rsf.data.veg.du8.ew$vri_bclcs_class <- recode (rsf.data.veg.du8.ew$vri_bclcs_class,
                                               "'Upland-Treed-Deciduous' = 'Upland-Treed-Decid-Mixed'")
rsf.data.veg.du8.ew$vri_bclcs_class <- recode (rsf.data.veg.du8.ew$vri_bclcs_class,
                                               "'Upland-Treed-Mixed' = 'Upland-Treed-Decid-Mixed'")
rsf.data.veg.du8.ew$vri_bclcs_class  <- relevel (rsf.data.veg.du8.ew$vri_bclcs_class,
                                                 ref = "Upland-Treed-Conifer")

ggplot (rsf.data.veg.du8.ew, aes (x = vri_bclcs_class, fill = pttype)) + 
          geom_histogram (position = "dodge", stat = "count") +
          labs (title = "Histogram DU8, Early Winter, Landcover Type\
                         at Available (0) and Used (1) Locations",
                x = "Landcover Type",
                y = "Count") +
          scale_fill_discrete (name = "Location Type") +
          theme (axis.text.x = element_text (angle = -90, hjust = 0))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_veg_du8_ew_landcover.png")

ggplot (rsf.data.veg.du8.ew, aes (x = vri_soil_moisture_name, fill = pttype)) + 
          geom_histogram (position = "dodge", stat = "count") +
          labs (title = "Histogram DU8, Early Winter, Soil Moisture Type\
                         at Available (0) and Used (1) Locations",
                x = "Soil Moisture Type",
                y = "Count") +
          scale_fill_discrete (name = "Location Type") +
          theme (axis.text.x = element_text (angle = -90, hjust = 0))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_veg_du8_ew_soil_moisture.png")

ggplot (rsf.data.veg.du8.ew, aes (x = vri_soil_nutrient_name, fill = pttype)) + 
          geom_histogram (position = "dodge", stat = "count") +
          labs (title = "Histogram DU8, Early Winter, Soil Nutrient Type\
                at Available (0) and Used (1) Locations",
                x = "Soil Nutrient Type",
                y = "Count") +
          scale_fill_discrete (name = "Location Type") +
          theme (axis.text.x = element_text (angle = -90, hjust = 0))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_veg_du8_ew_soil_nutirent.png")

rsf.data.veg.du8.ew$vri_species_primary_name_reclass <- recode (rsf.data.veg.du8.ew$vri_species_primary_name_reclass,
                                                                "'ALB' = 'Deciduous'")
rsf.data.veg.du8.ew$vri_species_primary_name_reclass <- recode (rsf.data.veg.du8.ew$vri_species_primary_name_reclass,
                                                                "'APC' = 'Deciduous'")
rsf.data.veg.du8.ew$vri_species_primary_name_reclass  <- relevel (rsf.data.veg.du8.ew$vri_species_primary_name_reclass,
                                                                  ref = "PIN")
ggplot (rsf.data.veg.du8.ew, aes (x = vri_species_primary_name_reclass, fill = pttype)) + 
          geom_histogram (position = "dodge", stat = "count") +
          labs (title = "Histogram DU8, Early Winter, Primary Tree Species\
                at Available (0) and Used (1) Locations",
                x = "Tree Species",
                y = "Count") +
          scale_fill_discrete (name = "Location Type") +
          theme (axis.text.x = element_text (angle = -90, hjust = 0))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_veg_du8_ew_lead_tree_spp.png")

### CORRELATION ###
corr.veg.du8.ew <- rsf.data.veg.du8.ew [c (17:26)]
corr.veg.du8.ew <- round (cor (corr.veg.du8.ew, method = "spearman"), 3)
ggcorrplot (corr.veg.du8.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Vegetation Resource Selection Function Model
            Covariate Correlations for DU8, Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_veg_du8_ew.png")

### VIF ###
glm.veg.du8.ew <- glm (pttype ~ bec_label_reclass + vri_bclcs_class + vri_species_primary_name_reclass +
                                vri_proj_age + vri_crown_closure + vri_site_index +
                                vri_bryoid_cover_pct + vri_herb_cover_pct + vri_shrub_crown_close, 
                       data = rsf.data.veg.du8.ew,
                       family = binomial (link = 'logit'))
car::vif (glm.veg.du8.ew)


### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

# standardize covariates  (helps with model convergence)
rsf.data.veg.du8.ew$std.vri_bryoid_cover_pct <- (rsf.data.veg.du8.ew$vri_bryoid_cover_pct - mean (rsf.data.veg.du8.ew$vri_bryoid_cover_pct)) / sd (rsf.data.veg.du8.ew$vri_bryoid_cover_pct)
rsf.data.veg.du8.ew$std.vri_herb_cover_pct <- (rsf.data.veg.du8.ew$vri_herb_cover_pct - mean (rsf.data.veg.du8.ew$vri_herb_cover_pct)) / sd (rsf.data.veg.du8.ew$vri_herb_cover_pct)
rsf.data.veg.du8.ew$std.vri_proj_age <- (rsf.data.veg.du8.ew$vri_proj_age - mean (rsf.data.veg.du8.ew$vri_proj_age)) / sd (rsf.data.veg.du8.ew$vri_proj_age)
rsf.data.veg.du8.ew$std.vri_shrub_crown_close <- (rsf.data.veg.du8.ew$vri_shrub_crown_close - mean (rsf.data.veg.du8.ew$vri_shrub_crown_close)) / sd (rsf.data.veg.du8.ew$vri_shrub_crown_close)
rsf.data.veg.du8.ew$std.vri_crown_closure <- (rsf.data.veg.du8.ew$vri_crown_closure - mean (rsf.data.veg.du8.ew$vri_crown_closure)) / sd (rsf.data.veg.du8.ew$vri_crown_closure)
rsf.data.veg.du8.ew$std.vri_site_index <- (rsf.data.veg.du8.ew$vri_site_index - mean (rsf.data.veg.du8.ew$vri_site_index)) / sd (rsf.data.veg.du8.ew$vri_site_index)

### CANDIDATE MODELS ###
## BEC ##
model.lme4.du8.ew.veg.bec <- glmer (pttype ~ bec_label_reclass + 
                                             (1 | uniqueID), 
                                    data = rsf.data.veg.du8.ew, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [1, 1] <- "DU8"
table.aic [1, 2] <- "Early Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "BEC"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du8.ew.veg.bec)

## FOOD ##
model.lme4.du8.ew.veg.food <- glmer (pttype ~ std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                              std.vri_herb_cover_pct + (1 | uniqueID), 
                                     data = rsf.data.veg.du8.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [2, 1] <- "DU8"
table.aic [2, 2] <- "Early Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "ShrubClosure, BryoidCover, HerbCover"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du8.ew.veg.food)

## FOREST STAND ##
model.lme4.du8.ew.veg.forest <- glmer (pttype ~ std.vri_proj_age + std.vri_crown_closure +
                                                std.vri_site_index + (1 | uniqueID), 
                                       data = rsf.data.veg.du8.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [3, 1] <- "DU8"
table.aic [3, 2] <- "Early Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "TreeAge, TreeClosure, SiteIndex"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du8.ew.veg.forest)

## BEC and FOOD ##
model.lme4.du8.ew.veg.bec.food <- glmer (pttype ~  bec_label_reclass + 
                                                   std.vri_shrub_crown_close + 
                                                   std.vri_bryoid_cover_pct + 
                                                   std.vri_herb_cover_pct +
                                                   (1 | uniqueID), 
                                                 data = rsf.data.veg.du8.ew, 
                                                 family = binomial (link = "logit"),
                                                 verbose = T) 
# AIC
table.aic [4, 1] <- "DU8"
table.aic [4, 2] <- "Early Winter"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "BEC, ShrubClosure, BryoidCover, HerbCover"
table.aic [4, 5] <- "(1 | UniqueID)"
table.aic [4, 6] <-  AIC (model.lme4.du8.ew.veg.bec.food)

## BEC and FOREST ##
model.lme4.du8.ew.veg.bec.forest <- glmer (pttype ~ bec_label_reclass + 
                                                     std.vri_proj_age + 
                                                     std.vri_crown_closure +
                                                     std.vri_site_index +
                                                     (1 | uniqueID), 
                                            data = rsf.data.veg.du8.ew, 
                                            family = binomial (link = "logit"),
                                            verbose = T) 
# AIC
table.aic [5, 1] <- "DU8"
table.aic [5, 2] <- "Early Winter"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "BEC, TreeAge, TreeClosure, SiteIndex"
table.aic [5, 5] <- "(1 | UniqueID)"
table.aic [5, 6] <-  AIC (model.lme4.du8.ew.veg.bec.forest)

## FOOD and FOREST ##
model.lme4.du8.ew.veg.food.forest <- glmer (pttype ~ std.vri_shrub_crown_close + 
                                                     std.vri_bryoid_cover_pct + 
                                                     std.vri_herb_cover_pct +
                                                     std.vri_proj_age + 
                                                     std.vri_crown_closure +
                                                     std.vri_site_index +
                                                     (1 | uniqueID), 
                                            data = rsf.data.veg.du8.ew, 
                                            family = binomial (link = "logit"),
                                            verbose = T) 
# AIC
table.aic [6, 1] <- "DU8"
table.aic [6, 2] <- "Early Winter"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeClosure, SiteIndex"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <-  AIC (model.lme4.du8.ew.veg.food.forest)

## BEC, FOOD and FOREST ##
model.lme4.du8.ew.veg.bec.forest.food <- glmer (pttype ~ bec_label_reclass +
                                                           std.vri_shrub_crown_close + 
                                                           std.vri_bryoid_cover_pct + 
                                                           std.vri_herb_cover_pct +
                                                           std.vri_proj_age + 
                                                           std.vri_crown_closure +
                                                           std.vri_site_index +
                                                           (1 | uniqueID), 
                                                 data = rsf.data.veg.du8.ew, 
                                                 family = binomial (link = "logit"),
                                                 verbose = T) 
ss <- getME (model.lme4.du8.ew.veg.bec.forest.food, c ("theta","fixef"))
model.lme4.du8.ew.veg.bec.forest.food <- update (model.lme4.du8.ew.veg.bec.forest.food, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [7, 1] <- "DU8"
table.aic [7, 2] <- "Early Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "BEC, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeClosure, SiteIndex"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du8.ew.veg.bec.forest.food)

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

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_veg.csv", sep = ",")

#=================================
# COMBINATION Models
#=================================

### compile AIC table of top models form each group
table.aic.annual.clim <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_annual_climate.csv", header = T, sep = ",")
table.aic <- table.aic.annual.clim [1, ]
rm (table.aic.annual.clim)
table.aic.human <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_human_disturb.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.human [15, ])
rm (table.aic.human)
table.aic.nat.disturb <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_natural_disturb.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.nat.disturb [3, ])
rm (table.aic.nat.disturb)
table.aic.enduring <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_terrain_water.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.enduring [13, ])
rm (table.aic.enduring)
table.aic.winter.clim <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_winter_climate.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.winter.clim [3, ])
rm (table.aic.winter.clim)
table.aic.veg <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_veg.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.veg [7, ])
rm (table.aic.veg)
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_all.csv", sep = ",")

# Load and tidy the data 
rsf.data.combo.du8.ew <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du8_ew.csv", header = T, sep = ",")
rsf.data.combo.du8.ew$pttype <- as.factor (rsf.data.combo.du8.ew$pttype)

# reclassify BEC for caribou
rsf.data.combo.du8.ew$bec_label_reclass <- rsf.data.combo.du8.ew$bec_label
rsf.data.combo.du8.ew$bec_label_reclass <- recode (rsf.data.combo.du8.ew$bec_label_reclass,
                                                 "'BAFAun' = 'BAFA'") # simplified to alpine type
rsf.data.combo.du8.ew$bec_label_reclass <- recode (rsf.data.combo.du8.ew$bec_label_reclass,
                                                 "'BAFAunp' = 'BAFA'")
rsf.data.combo.du8.ew$bec_label_reclass <- recode (rsf.data.combo.du8.ew$bec_label_reclass,
                                                 "'BWBSdk' = 'BWBS'") # simplified to BWBS type
rsf.data.combo.du8.ew$bec_label_reclass <- recode (rsf.data.combo.du8.ew$bec_label_reclass,
                                                 "'BWBSmk' = 'BWBS'")
rsf.data.combo.du8.ew$bec_label_reclass <- recode (rsf.data.combo.du8.ew$bec_label_reclass,
                                                 "'BWBSmw' = 'BWBS'")
rsf.data.combo.du8.ew$bec_label_reclass <- recode (rsf.data.combo.du8.ew$bec_label_reclass,
                                                 "'BWBSwk 1' = 'BWBS'")
rsf.data.combo.du8.ew$bec_label_reclass <- recode (rsf.data.combo.du8.ew$bec_label_reclass,
                                                 "'BWBSwk 2' = 'BWBS'")
rsf.data.combo.du8.ew$bec_label_reclass <- recode (rsf.data.combo.du8.ew$bec_label_reclass,
                                                 "'BWBSwk 3' = 'BWBS'")
rsf.data.combo.du8.ew$bec_label_reclass <- recode (rsf.data.combo.du8.ew$bec_label_reclass,
                                                 "'SBS wk 1' = 'SBS_very_wet_to_wet_cool'")
rsf.data.combo.du8.ew$bec_label_reclass <- recode (rsf.data.combo.du8.ew$bec_label_reclass,
                                                 "'SBS wk 2' = 'SBS_very_wet_to_wet_cool'")
rsf.data.combo.du8.ew$bec_label_reclass <- recode (rsf.data.combo.du8.ew$bec_label_reclass,
                                                 "'SBS vk' = 'SBS_very_wet_to_wet_cool'")
rsf.data.combo.du8.ew$bec_label_reclass <- recode (rsf.data.combo.du8.ew$bec_label_reclass,
                                                 "'ESSFmvp' = 'ESSF_moist_very_cold'")
rsf.data.combo.du8.ew$bec_label_reclass <- recode (rsf.data.combo.du8.ew$bec_label_reclass,
                                                 "'ESSFmv 2' = 'ESSF_moist_very_cold'")
rsf.data.combo.du8.ew$bec_label_reclass <- recode (rsf.data.combo.du8.ew$bec_label_reclass,
                                                 "'ESSFwc 3' = 'ESSF_wet_cold'")
rsf.data.combo.du8.ew$bec_label_reclass <- recode (rsf.data.combo.du8.ew$bec_label_reclass,
                                                 "'ESSFwcp' = 'ESSF_wet_cold'")
rsf.data.combo.du8.ew$bec_label_reclass <- recode (rsf.data.combo.du8.ew$bec_label_reclass,
                                                 "'ESSFwk 2' = 'ESSF_wet_cool'")
rsf.data.combo.du8.ew$bec_label_reclass <- relevel (rsf.data.combo.du8.ew$bec_label_reclass,
                                                  ref = "ESSF_wet_cold") # reference category
rsf.data.combo.du8.ew <- rsf.data.combo.du8.ew %>% 
                         filter (!is.na (ppt_as_snow_annual))
rsf.data.combo.du8.ew$slope.sq <- rsf.data.combo.du8.ew$slope * rsf.data.combo.du8.ew$slope
rsf.data.combo.du8.ew$elev.sq <- rsf.data.combo.du8.ew$elevation * rsf.data.combo.du8.ew$elevation

rsf.data.combo.du8.ew$bec_label_reclass2 <- rsf.data.combo.du8.ew$bec_label
rsf.data.combo.du8.ew <- rsf.data.combo.du8.ew %>%
                          dplyr::filter (bec_label_reclass2 != "SBS vk")
rsf.data.combo.du8.ew$bec_label_reclass2 <- relevel (rsf.data.combo.du8.ew$bec_label_reclass2,
                                                     ref = "ESSFwc 3") # reference category

ggplot (rsf.data.combo.du8.ew, aes (x = bec_label_reclass2, fill = pttype)) + 
  geom_histogram (position = "dodge", stat = "count") +
  labs (title = "Histogram DU8, Early Winter, BEC\
                at Available (0) and Used (1) Locations",
        x = "BEC Type",
        y = "Count") +
  scale_fill_discrete (name = "Location Type") +
  theme (axis.text.x = element_text (angle = -90, hjust = 0))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_bec2_du8_ew.png")

### CORRELATION ###
corr.data.du8.ew <- rsf.data.combo.du8.ew [c (11:28, 30:35)]
corr.du8.ew <- round (cor (corr.data.du8.ew, method = "spearman"), 3)
ggcorrplot (corr.du8.ew, type = "lower", lab = TRUE, tl.cex = 9,  lab_size = 2,
            title = "Resource Selection Function Model Covariate Correlations \
                     for DU8, Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_winter_climate_du8_ew.png")

### VIF ###
glm.all.du8.ew <- glm (pttype ~ # distance_to_watercourse + 
                                # slope + slope.sq  + 
                                # elevation +
                                distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                                distance_to_cut_10to29yo + distance_to_cut_30orOveryo +
                                # distance_to_paved_road + 
                                distance_to_resource_road + 
                                # distance_to_pipeline + distance_to_mines + 
                                beetle_1to5yo + beetle_6to9yo + 
                                fire_1to5yo + fire_6to25yo + fire_over25yo + 
                                # ppt_as_snow_winter + temp_avg_winter + 
                                bec_label_reclass2 + 
                                vri_shrub_crown_close + 
                                # vri_herb_cover_pct + 
                                # vri_crown_closure +
                                # vri_proj_age + 
                                # vri_site_index  + 
                                vri_bryoid_cover_pct ,  
                       data = rsf.data.combo.du8.ew,
                       family = binomial (link = 'logit'))
car::vif (glm.all.du8.ew)

# standardize covariates  (helps with model convergence)
rsf.data.combo.du8.ew$std.slope <- (rsf.data.combo.du8.ew$slope - mean (rsf.data.combo.du8.ew$slope)) / sd (rsf.data.combo.du8.ew$slope)
rsf.data.combo.du8.ew$std.distance_to_watercourse <- (rsf.data.combo.du8.ew$distance_to_watercourse - mean (rsf.data.combo.du8.ew$distance_to_watercourse)) / sd (rsf.data.combo.du8.ew$distance_to_watercourse)
rsf.data.combo.du8.ew$std.elevation <- (rsf.data.combo.du8.ew$elevation - mean (rsf.data.combo.du8.ew$elevation)) / sd (rsf.data.combo.du8.ew$elevation)
rsf.data.combo.du8.ew$std.distance_to_cut_1to4yo <- (rsf.data.combo.du8.ew$distance_to_cut_1to4yo - mean (rsf.data.combo.du8.ew$distance_to_cut_1to4yo)) / sd (rsf.data.combo.du8.ew$distance_to_cut_1to4yo)
rsf.data.combo.du8.ew$std.distance_to_cut_5to9yo <- (rsf.data.combo.du8.ew$distance_to_cut_5to9yo - mean (rsf.data.combo.du8.ew$distance_to_cut_5to9yo)) / sd (rsf.data.combo.du8.ew$distance_to_cut_5to9yo)
rsf.data.combo.du8.ew$std.distance_to_cut_10to29yo <- (rsf.data.combo.du8.ew$distance_to_cut_10to29yo - mean (rsf.data.combo.du8.ew$distance_to_cut_10to29yo)) / sd (rsf.data.combo.du8.ew$distance_to_cut_10to29yo)
rsf.data.combo.du8.ew$std.distance_to_cut_30orOveryo <- (rsf.data.combo.du8.ew$distance_to_cut_30orOveryo - mean (rsf.data.combo.du8.ew$distance_to_cut_30orOveryo)) / sd (rsf.data.combo.du8.ew$distance_to_cut_30orOveryo)
rsf.data.combo.du8.ew$std.distance_to_paved_road <- (rsf.data.combo.du8.ew$distance_to_paved_road - mean (rsf.data.combo.du8.ew$distance_to_paved_road)) / sd (rsf.data.combo.du8.ew$distance_to_paved_road)
rsf.data.combo.du8.ew$std.distance_to_resource_road <- (rsf.data.combo.du8.ew$distance_to_resource_road - mean (rsf.data.combo.du8.ew$distance_to_resource_road)) / sd (rsf.data.combo.du8.ew$distance_to_resource_road)
rsf.data.combo.du8.ew$std.distance_to_pipeline <- (rsf.data.combo.du8.ew$distance_to_pipeline - mean (rsf.data.combo.du8.ew$distance_to_pipeline)) / sd (rsf.data.combo.du8.ew$distance_to_pipeline)
rsf.data.combo.du8.ew$std.distance_to_mines <- (rsf.data.combo.du8.ew$distance_to_mines - mean (rsf.data.combo.du8.ew$distance_to_mines)) / sd (rsf.data.combo.du8.ew$distance_to_mines)
rsf.data.combo.du8.ew$std.ppt_as_snow_winter <- (rsf.data.combo.du8.ew$ppt_as_snow_winter - mean (rsf.data.combo.du8.ew$ppt_as_snow_winter)) / sd (rsf.data.combo.du8.ew$ppt_as_snow_winter)
rsf.data.combo.du8.ew$std.temp_avg_winter <- (rsf.data.combo.du8.ew$temp_avg_winter - mean (rsf.data.combo.du8.ew$temp_avg_winter)) / sd (rsf.data.combo.du8.ew$temp_avg_winter)
rsf.data.combo.du8.ew$std.vri_shrub_crown_close <- (rsf.data.combo.du8.ew$vri_shrub_crown_close - mean (rsf.data.combo.du8.ew$vri_shrub_crown_close)) / sd (rsf.data.combo.du8.ew$vri_shrub_crown_close)
rsf.data.combo.du8.ew$std.vri_herb_cover_pct <- (rsf.data.combo.du8.ew$vri_herb_cover_pct - mean (rsf.data.combo.du8.ew$vri_herb_cover_pct)) / sd (rsf.data.combo.du8.ew$vri_herb_cover_pct)
rsf.data.combo.du8.ew$std.vri_bryoid_cover_pct <- (rsf.data.combo.du8.ew$vri_bryoid_cover_pct - mean (rsf.data.combo.du8.ew$vri_bryoid_cover_pct)) / sd (rsf.data.combo.du8.ew$vri_bryoid_cover_pct)
rsf.data.combo.du8.ew$std.vri_proj_age <- (rsf.data.combo.du8.ew$vri_proj_age - mean (rsf.data.combo.du8.ew$vri_proj_age)) / sd (rsf.data.combo.du8.ew$vri_proj_age)
rsf.data.combo.du8.ew$std.vri_crown_closure <- (rsf.data.combo.du8.ew$vri_crown_closure - mean (rsf.data.combo.du8.ew$vri_crown_closure)) / sd (rsf.data.combo.du8.ew$vri_crown_closure)
rsf.data.combo.du8.ew$std.vri_site_index <- (rsf.data.combo.du8.ew$vri_site_index - mean (rsf.data.combo.du8.ew$vri_site_index)) / sd (rsf.data.combo.du8.ew$vri_site_index)
rsf.data.combo.du8.ew$std.slope.sq <- (rsf.data.combo.du8.ew$slope.sq - mean (rsf.data.combo.du8.ew$slope.sq)) / sd (rsf.data.combo.du8.ew$slope.sq)
rsf.data.combo.du8.ew$std.elev.sq <- (rsf.data.combo.du8.ew$elev.sq - mean (rsf.data.combo.du8.ew$elev.sq)) / sd (rsf.data.combo.du8.ew$elev.sq)

### ENDURING FEATURES AND HUMAN DISTURBANCE ###
model.lme4.du8.ew.ef.hd <- glmer (pttype ~ std.slope + std.distance_to_watercourse + 
                                           std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                           std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                           std.distance_to_paved_road + std.distance_to_resource_road + 
                                           (1 | uniqueID), 
                                  data = rsf.data.combo.du8.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
# AIC
table.aic [7, 1] <- "DU8"
table.aic [7, 2] <- "Early Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "Slope, DWat, DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du8.ew.ef.hd)

### ENDURING FEATURES AND NATURAL DISTURBANCE ###
model.lme4.du8.ew.ef.nd <- glmer (pttype ~ std.slope + std.distance_to_watercourse + 
                                            beetle_1to5yo + beetle_6to9yo + 
                                            fire_1to5yo + fire_6to25yo + fire_over25yo +
                                            (1 | uniqueID), 
                                  data = rsf.data.combo.du8.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
# AIC
table.aic [8, 1] <- "DU8"
table.aic [8, 2] <- "Early Winter"
table.aic [8, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [8, 4] <- "Slope, DWat, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [8, 5] <- "(1 | UniqueID)"
table.aic [8, 6] <-  AIC (model.lme4.du8.ew.ef.nd)

### ENDURING FEATURES AND CLIMATE ###
model.lme4.du8.ew.ef.clim <- glmer (pttype ~ std.slope + std.distance_to_watercourse + 
                                             std.ppt_as_snow_winter + std.temp_avg_winter +
                                             (1 | uniqueID), 
                                    data = rsf.data.combo.du8.ew, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [9, 1] <- "DU8"
table.aic [9, 2] <- "Early Winter"
table.aic [9, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [9, 4] <- "Slope, DWat, WPAS, WTemp"
table.aic [9, 5] <- "(1 | UniqueID)"
table.aic [9, 6] <-  AIC (model.lme4.du8.ew.ef.clim)

### HUMAN DISTURBANCE AND NATURAL DISTURBANCE ###
model.lme4.du8.ew.hd.nd <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                           std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                           std.distance_to_paved_road + std.distance_to_resource_road + 
                                           beetle_1to5yo + beetle_6to9yo + 
                                           fire_1to5yo + fire_6to25yo + fire_over25yo +
                                           (1 | uniqueID), 
                                  data = rsf.data.combo.du8.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
# AIC
table.aic [10, 1] <- "DU8"
table.aic [10, 2] <- "Early Winter"
table.aic [10, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [10, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [10, 5] <- "(1 | UniqueID)"
table.aic [10, 6] <-  AIC (model.lme4.du8.ew.hd.nd)

### HUMAN DISTURBANCE AND CLIMATE ###
model.lme4.du8.ew.hd.clim <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                             std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                             std.distance_to_paved_road + std.distance_to_resource_road + 
                                             std.ppt_as_snow_winter + std.temp_avg_winter +
                                             (1 | uniqueID), 
                                    data = rsf.data.combo.du8.ew, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [11, 1] <- "DU8"
table.aic [11, 2] <- "Early Winter"
table.aic [11, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [11, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR, WPAS, WTemp"
table.aic [11, 5] <- "(1 | UniqueID)"
table.aic [11, 6] <-  AIC (model.lme4.du8.ew.hd.clim)

### NATURAL DISTURBANCE AND CLIMATE ###
model.lme4.du8.ew.nd.clim <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                                             fire_1to5yo + fire_6to25yo + fire_over25yo + 
                                             std.ppt_as_snow_winter + std.temp_avg_winter +
                                             (1 | uniqueID), 
                                    data = rsf.data.combo.du8.ew, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [12, 1] <- "DU8"
table.aic [12, 2] <- "Early Winter"
table.aic [12, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [12, 4] <- "Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, WPAS, WTemp"
table.aic [12, 5] <- "(1 | UniqueID)"
table.aic [12, 6] <-  AIC (model.lme4.du8.ew.nd.clim)

### ENDURING FEATURES AND VEGETATION ###
model.lme4.du8.ew.ef.veg <- glmer (pttype ~ std.slope + std.distance_to_watercourse + 
                                            std.vri_proj_age + std.vri_crown_closure + std.vri_site_index + 
                                            std.vri_herb_cover_pct + std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                            (1 | uniqueID), 
                                   data = rsf.data.combo.du8.ew, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# AIC
table.aic [13, 1] <- "DU8"
table.aic [13, 2] <- "Early Winter"
table.aic [13, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [13, 4] <- "Slope, DWat, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeClosure, SiteIndex"
table.aic [13, 5] <- "(1 | UniqueID)"
table.aic [13, 6] <-  AIC (model.lme4.du8.ew.ef.veg)

### HUMAN AND VEGETATION ###
model.lme4.du8.ew.hd.veg <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                             std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                             std.distance_to_paved_road + std.distance_to_resource_road + 
                                             std.vri_proj_age + std.vri_crown_closure + std.vri_site_index + 
                                             std.vri_herb_cover_pct + std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                             (1 | uniqueID), 
                                   data = rsf.data.combo.du8.ew, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# AIC
table.aic [14, 1] <- "DU8"
table.aic [14, 2] <- "Early Winter"
table.aic [14, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [14, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeClosure, SiteIndex"
table.aic [14, 5] <- "(1 | UniqueID)"
table.aic [14, 6] <-  AIC (model.lme4.du8.ew.hd.veg)

### NATURAL DISTURB AND VEGETATION ###
model.lme4.du8.ew.nd.veg <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                                            fire_1to5yo + fire_6to25yo + fire_over25yo + 
                                            std.vri_proj_age + std.vri_crown_closure + std.vri_site_index + 
                                            std.vri_herb_cover_pct + std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                            (1 | uniqueID), 
                                   data = rsf.data.combo.du8.ew, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# AIC
table.aic [15, 1] <- "DU8"
table.aic [15, 2] <- "Early Winter"
table.aic [15, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [15, 4] <- "Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeClosure, SiteIndex"
table.aic [15, 5] <- "(1 | UniqueID)"
table.aic [15, 6] <-  AIC (model.lme4.du8.ew.nd.veg)

### CLIMATE AND VEGETATION ###
model.lme4.du8.ew.clim.veg <- glmer (pttype ~ std.ppt_as_snow_winter + std.temp_avg_winter +
                                              std.vri_proj_age + std.vri_crown_closure + std.vri_site_index + 
                                              std.vri_herb_cover_pct + std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                              (1 | uniqueID), 
                                     data = rsf.data.combo.du8.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [16, 1] <- "DU8"
table.aic [16, 2] <- "Early Winter"
table.aic [16, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [16, 4] <- "ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeClosure, SiteIndex, WPAS, WTemp"
table.aic [16, 5] <- "(1 | UniqueID)"
table.aic [16, 6] <-  AIC (model.lme4.du8.ew.clim.veg)

### ENDURING FEATURES, HUMAN DISTURBANCE, NATURAL DISTURBANCE ###
model.lme4.du8.ew.ef.hd.nd <- glmer (pttype ~ std.slope + std.distance_to_watercourse +
                                               std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                               std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                               std.distance_to_paved_road + std.distance_to_resource_road + 
                                               beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                               fire_6to25yo + fire_over25yo +
                                               (1 | uniqueID), 
                                     data = rsf.data.combo.du8.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [17, 1] <- "DU8"
table.aic [17, 2] <- "Early Winter"
table.aic [17, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [17, 4] <- "Slope, DWat, DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [17, 5] <- "(1 | UniqueID)"
table.aic [17, 6] <-  AIC (model.lme4.du8.ew.ef.hd.nd)

### ENDURING FEATURES, HUMAN DISTURBANCE, CLIMATE ###
model.lme4.du8.ew.ef.hd.clim <- glmer (pttype ~ std.slope + std.distance_to_watercourse +
                                                std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                std.distance_to_paved_road + std.distance_to_resource_road + 
                                                std.ppt_as_snow_winter + std.temp_avg_winter +
                                                (1 | uniqueID), 
                                       data = rsf.data.combo.du8.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [18, 1] <- "DU8"
table.aic [18, 2] <- "Early Winter"
table.aic [18, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [18, 4] <- "Slope, DWat, DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR, WPAS, WTemp"
table.aic [18, 5] <- "(1 | UniqueID)"
table.aic [18, 6] <-  AIC (model.lme4.du8.ew.ef.hd.clim)

### ENDURING FEATURES, HUMAN DISTURBANCE, VEGETATION ###
model.lme4.du8.ew.ef.hd.veg <- glmer (pttype ~ std.slope + std.distance_to_watercourse +
                                                std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                std.distance_to_paved_road + std.distance_to_resource_road + 
                                                std.vri_proj_age + std.vri_crown_closure + std.vri_site_index + 
                                                std.vri_herb_cover_pct + std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                                (1 | uniqueID), 
                                      data = rsf.data.combo.du8.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [19, 1] <- "DU8"
table.aic [19, 2] <- "Early Winter"
table.aic [19, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [19, 4] <- "Slope, DWat, DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeClosure, SiteIndex"
table.aic [19, 5] <- "(1 | UniqueID)"
table.aic [19, 6] <-  AIC (model.lme4.du8.ew.ef.hd.veg)

### ENDURING FEATURES, NATURAL DISTURBANCE, CLIMATE ###
model.lme4.du8.ew.ef.nd.clim <- glmer (pttype ~ std.slope + std.distance_to_watercourse +
                                                 beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                 fire_6to25yo + fire_over25yo +
                                                 std.ppt_as_snow_winter + std.temp_avg_winter +
                                                 (1 | uniqueID), 
                                       data = rsf.data.combo.du8.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [20, 1] <- "DU8"
table.aic [20, 2] <- "Early Winter"
table.aic [20, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [20, 4] <- "Slope, DWat, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, WPAS, WTemp"
table.aic [20, 5] <- "(1 | UniqueID)"
table.aic [20, 6] <-  AIC (model.lme4.du8.ew.ef.nd.clim)

### ENDURING FEATURES, NATURAL DISTURBANCE, VEGETATION ###
model.lme4.du8.ew.ef.nd.veg <- glmer (pttype ~ std.slope + std.distance_to_watercourse +
                                                beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                fire_6to25yo + fire_over25yo +
                                                std.vri_proj_age + std.vri_crown_closure + std.vri_site_index + 
                                                std.vri_herb_cover_pct + std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                                (1 | uniqueID), 
                                      data = rsf.data.combo.du8.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [21, 1] <- "DU8"
table.aic [21, 2] <- "Early Winter"
table.aic [21, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [21, 4] <- "Slope, DWat, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeClosure, SiteIndex"
table.aic [21, 5] <- "(1 | UniqueID)"
table.aic [21, 6] <-  AIC (model.lme4.du8.ew.ef.nd.veg)

### ENDURING FEATURES, CLIMATE, VEGETATION ###
model.lme4.du8.ew.ef.clim.veg <- glmer (pttype ~ std.slope + std.distance_to_watercourse +
                                                  std.ppt_as_snow_winter + std.temp_avg_winter +
                                                  std.vri_proj_age + std.vri_crown_closure + std.vri_site_index + 
                                                  std.vri_herb_cover_pct + std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                                  (1 | uniqueID), 
                                        data = rsf.data.combo.du8.ew, 
                                        family = binomial (link = "logit"),
                                        verbose = T) 
# AIC
table.aic [22, 1] <- "DU8"
table.aic [22, 2] <- "Early Winter"
table.aic [22, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [22, 4] <- "Slope, DWat, WPAS, WTemp, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeClosure, SiteIndex"
table.aic [22, 5] <- "(1 | UniqueID)"
table.aic [22, 6] <-  AIC (model.lme4.du8.ew.ef.clim.veg)

### HUMAN DISTURBANCE, NATURAL DISTURBANCE, CLIMATE ###
model.lme4.du8.ew.hd.nd.clim <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                   std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                   std.distance_to_paved_road + std.distance_to_resource_road + 
                                                   beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                   fire_6to25yo + fire_over25yo +
                                                   std.ppt_as_snow_winter + std.temp_avg_winter +
                                                   (1 | uniqueID), 
                                       data = rsf.data.combo.du8.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [23, 1] <- "DU8"
table.aic [23, 2] <- "Early Winter"
table.aic [23, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [23, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, WPAS, WTemp"
table.aic [23, 5] <- "(1 | UniqueID)"
table.aic [23, 6] <-  AIC (model.lme4.du8.ew.hd.nd.clim)

### HUMAN DISTURBANCE, NATURAL DISTURBANCE, VEGETATION ###
model.lme4.du8.ew.hd.nd.veg <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                std.distance_to_paved_road + std.distance_to_resource_road + 
                                                beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                fire_6to25yo + fire_over25yo +
                                                std.vri_proj_age + std.vri_crown_closure + std.vri_site_index + 
                                                std.vri_herb_cover_pct + std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                                (1 | uniqueID), 
                                      data = rsf.data.combo.du8.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [24, 1] <- "DU8"
table.aic [24, 2] <- "Early Winter"
table.aic [24, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [24, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeClosure, SiteIndex"
table.aic [24, 5] <- "(1 | UniqueID)"
table.aic [24, 6] <-  AIC (model.lme4.du8.ew.hd.nd.veg)

### HUMAN DISTURBANCE, CLIMATE, VEGETATION ###
model.lme4.du8.ew.hd.clim.veg <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                  std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                  std.distance_to_paved_road + std.distance_to_resource_road +
                                                  std.ppt_as_snow_winter + std.temp_avg_winter +
                                                  std.vri_proj_age + std.vri_crown_closure + std.vri_site_index + 
                                                  std.vri_herb_cover_pct + std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                                  (1 | uniqueID), 
                                        data = rsf.data.combo.du8.ew, 
                                        family = binomial (link = "logit"),
                                        verbose = T) 
# AIC
table.aic [25, 1] <- "DU8"
table.aic [25, 2] <- "Early Winter"
table.aic [25, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [25, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR, WPAS, WTemp, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeClosure, SiteIndex"
table.aic [25, 5] <- "(1 | UniqueID)"
table.aic [25, 6] <-  AIC (model.lme4.du8.ew.hd.clim.veg)

### NATURAL DISTURBANCE, CLIMATE, VEGETATION ###
model.lme4.du8.ew.nd.clim.veg <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                 fire_6to25yo + fire_over25yo +
                                                  std.ppt_as_snow_winter + std.temp_avg_winter +
                                                  std.vri_proj_age + std.vri_crown_closure + std.vri_site_index + 
                                                  std.vri_herb_cover_pct + std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                                  (1 | uniqueID), 
                                        data = rsf.data.combo.du8.ew, 
                                        family = binomial (link = "logit"),
                                        verbose = T) 
# AIC
table.aic [26, 1] <- "DU8"
table.aic [26, 2] <- "Early Winter"
table.aic [26, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [26, 4] <- "Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, WPAS, WTemp, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeClosure, SiteIndex"
table.aic [26, 5] <- "(1 | UniqueID)"
table.aic [26, 6] <-  AIC (model.lme4.du8.ew.nd.clim.veg)

### ENDURING FEATURES, HUMAN DISTURBANCE, NATURAL DISTURBANCE, CLIMATE ###
model.lme4.du8.ew.ef.hd.nd.clim <- glmer (pttype ~ std.slope + std.distance_to_watercourse +
                                                    std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                    std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                    std.distance_to_paved_road + std.distance_to_resource_road +
                                                    beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                    fire_6to25yo + fire_over25yo +
                                                    std.ppt_as_snow_winter + std.temp_avg_winter +
                                                    (1 | uniqueID), 
                                          data = rsf.data.combo.du8.ew, 
                                          family = binomial (link = "logit"),
                                          verbose = T) 
# AIC
table.aic [27, 1] <- "DU8"
table.aic [27, 2] <- "Early Winter"
table.aic [27, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [27, 4] <- "Slope, DWat, DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, WPAS, WTemp"
table.aic [27, 5] <- "(1 | UniqueID)"
table.aic [27, 6] <-  AIC (model.lme4.du8.ew.ef.hd.nd.clim)

### ENDURING FEATURES, HUMAN DISTURBANCE, NATURAL DISTURBANCE, VEGETATION ###
model.lme4.du8.ew.ef.hd.nd.veg <- glmer (pttype ~ std.slope + std.distance_to_watercourse +
                                                   std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                   std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                   std.distance_to_paved_road + std.distance_to_resource_road +
                                                   beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                   fire_6to25yo + fire_over25yo +
                                                   std.vri_proj_age + std.vri_crown_closure + std.vri_site_index + 
                                                   std.vri_herb_cover_pct + std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                                   (1 | uniqueID), 
                                         data = rsf.data.combo.du8.ew, 
                                         family = binomial (link = "logit"),
                                         verbose = T) 
# AIC
table.aic [28, 1] <- "DU8"
table.aic [28, 2] <- "Early Winter"
table.aic [28, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [28, 4] <- "Slope, DWat, DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeClosure, SiteIndex"
table.aic [28, 5] <- "(1 | UniqueID)"
table.aic [28, 6] <-  AIC (model.lme4.du8.ew.ef.hd.nd.veg)

### HUMAN DISTURBANCE, NATURAL DISTURBANCE, CLIMATE, VEGETATION ###
model.lme4.du8.ew.hd.nd.clim.veg <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                     std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                     std.distance_to_paved_road + std.distance_to_resource_road +
                                                     beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                     fire_6to25yo + fire_over25yo +
                                                     std.ppt_as_snow_winter + std.temp_avg_winter +
                                                     std.vri_proj_age + std.vri_crown_closure + std.vri_site_index + 
                                                     std.vri_herb_cover_pct + std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                                     (1 | uniqueID), 
                                           data = rsf.data.combo.du8.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [29, 1] <- "DU8"
table.aic [29, 2] <- "Early Winter"
table.aic [29, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [29, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, WPAS, WTemp, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeClosure, SiteIndex"
table.aic [29, 5] <- "(1 | UniqueID)"
table.aic [29, 6] <-  AIC (model.lme4.du8.ew.hd.nd.clim.veg)

### ENDURING FEATURES, HUMAN DISTURBANCE, CLIMATE, VEGETATION ###
model.lme4.du8.ew.ef.hd.clim.veg <- glmer (pttype ~ std.slope + std.distance_to_watercourse +
                                                     std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                     std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                     std.distance_to_paved_road + std.distance_to_resource_road +
                                                     std.ppt_as_snow_winter + std.temp_avg_winter +
                                                     std.vri_proj_age + std.vri_crown_closure + std.vri_site_index + 
                                                     std.vri_herb_cover_pct + std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                                     (1 | uniqueID), 
                                           data = rsf.data.combo.du8.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
ss <- getME (model.lme4.du8.ew.ef.hd.clim.veg, c ("theta","fixef"))
model.lme4.du8.ew.ef.hd.clim.veg <- update (model.lme4.du8.ew.ef.hd.clim.veg, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [30, 1] <- "DU8"
table.aic [30, 2] <- "Early Winter"
table.aic [30, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [30, 4] <- "Slope, DWat, DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR, WPAS, WTemp, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeClosure, SiteIndex"
table.aic [30, 5] <- "(1 | UniqueID)"
table.aic [30, 6] <-  AIC (model.lme4.du8.ew.ef.hd.clim.veg)

### ENDURING FEATURES, NATURAL DISTURBANCE, CLIMATE, VEGETATION ###
model.lme4.du8.ew.ef.nd.clim.veg <- glmer (pttype ~ std.slope + std.distance_to_watercourse +
                                                     beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                     fire_6to25yo + fire_over25yo +
                                                     std.ppt_as_snow_winter + std.temp_avg_winter +
                                                     std.vri_proj_age + std.vri_crown_closure + std.vri_site_index + 
                                                     std.vri_herb_cover_pct + std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                                     (1 | uniqueID), 
                                           data = rsf.data.combo.du8.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [31, 1] <- "DU8"
table.aic [31, 2] <- "Early Winter"
table.aic [31, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [31, 4] <- "Slope, DWat, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, WPAS, WTemp, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeClosure, SiteIndex"
table.aic [31, 5] <- "(1 | UniqueID)"
table.aic [31, 6] <-  AIC (model.lme4.du8.ew.ef.nd.clim.veg)

### ENDURING FEATURES, HUMAN DISTURBANCE, NATURAL DISTURBANCE, CLIMATE, VEGETATION ###
model.lme4.du8.ew.ef.hd.nd.clim.veg <- glmer (pttype ~ std.slope + std.distance_to_watercourse +
                                                        std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                        std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                        std.distance_to_paved_road + std.distance_to_resource_road +
                                                        beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                        fire_6to25yo + fire_over25yo +
                                                        std.ppt_as_snow_winter + std.temp_avg_winter +
                                                        std.vri_proj_age + std.vri_crown_closure + std.vri_site_index + 
                                                        std.vri_herb_cover_pct + std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                                        (1 | uniqueID), 
                                              data = rsf.data.combo.du8.ew, 
                                              family = binomial (link = "logit"),
                                              verbose = T) 
# AIC
table.aic [32, 1] <- "DU8"
table.aic [32, 2] <- "Early Winter"
table.aic [32, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [32, 4] <- "Slope, DWat, DC1to4, DC5to9, DC10to29, DCover30, DPR, DRR, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, WPAS, WTemp, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeClosure, SiteIndex"
table.aic [32, 5] <- "(1 | UniqueID)"
table.aic [32, 6] <-  AIC (model.lme4.du8.ew.ef.hd.nd.clim.veg)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_all_top.csv", sep = ",")

## AIC comparison of MODELS ## 
table.aic$AIC <- as.numeric (table.aic$AIC)
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [c (1:32), 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [4, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [5, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [6, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [7, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [8, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [9, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [10, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [11, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [12, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [13, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [14, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [15, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [16, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [17, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [18, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [19, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [20, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [21, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [22, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [23, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [24, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [25, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [26, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [27, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [28, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [29, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [30, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [31, 6] - min (table.aic [c (1:32), 6])))),
                    (exp (-0.5 * (table.aic [32, 6] - min (table.aic [c (1:32), 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [4, 7] <- round ((exp (-0.5 * (table.aic [4, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [5, 7] <- round ((exp (-0.5 * (table.aic [5, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [6, 7] <- round ((exp (-0.5 * (table.aic [6, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [7, 7] <- round ((exp (-0.5 * (table.aic [7, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [8, 7] <- round ((exp (-0.5 * (table.aic [8, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [9, 7] <- round ((exp (-0.5 * (table.aic [9, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [10, 7] <- round ((exp (-0.5 * (table.aic [10, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [11, 7] <- round ((exp (-0.5 * (table.aic [11, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [12, 7] <- round ((exp (-0.5 * (table.aic [12, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [13, 7] <- round ((exp (-0.5 * (table.aic [13, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [14, 7] <- round ((exp (-0.5 * (table.aic [14, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [15, 7] <- round ((exp (-0.5 * (table.aic [15, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [16, 7] <- round ((exp (-0.5 * (table.aic [16, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [17, 7] <- round ((exp (-0.5 * (table.aic [17, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [18, 7] <- round ((exp (-0.5 * (table.aic [18, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [19, 7] <- round ((exp (-0.5 * (table.aic [19, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [20, 7] <- round ((exp (-0.5 * (table.aic [20, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [21, 7] <- round ((exp (-0.5 * (table.aic [21, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [22, 7] <- round ((exp (-0.5 * (table.aic [22, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [23, 7] <- round ((exp (-0.5 * (table.aic [23, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [24, 7] <- round ((exp (-0.5 * (table.aic [24, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [25, 7] <- round ((exp (-0.5 * (table.aic [25, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [26, 7] <- round ((exp (-0.5 * (table.aic [26, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [27, 7] <- round ((exp (-0.5 * (table.aic [27, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [28, 7] <- round ((exp (-0.5 * (table.aic [28, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [29, 7] <- round ((exp (-0.5 * (table.aic [29, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [30, 7] <- round ((exp (-0.5 * (table.aic [30, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [31, 7] <- round ((exp (-0.5 * (table.aic [31, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)
table.aic [32, 7] <- round ((exp (-0.5 * (table.aic [32, 6] - min (table.aic [c (1:32), 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_all_top.csv", sep = ",")

save (model.lme4.du8.ew.ef.hd.nd.clim.veg, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_du8_ew_final.rda")

### SPARSE FULL MODEL ###
model.lme4.du8.ew.sparse <- glmer (pttype ~ bec_label_reclass2 +
                                             std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                             std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                             std.distance_to_resource_road +
                                             beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                             fire_6to25yo + fire_over25yo +
                                             std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                             (1 | uniqueID), 
                                   data = rsf.data.combo.du8.ew, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
ss <- getME (model.lme4.du8.ew.sparse, c ("theta","fixef"))
model.lme4.du8.ew.sparse <- update (model.lme4.du8.ew.sparse, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [33, 1] <- "DU8"
table.aic [33, 2] <- "Early Winter"
table.aic [33, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [33, 4] <- "BEC, DC1to4, DC5to9, DC10to29, DCover30, DRR, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, ShrubClosure, BryoidCover"
table.aic [33, 5] <- "(1 | UniqueID)"
table.aic [33, 6] <-  AIC (model.lme4.du8.ew.sparse)

### SPARSE BEC ###
model.lme4.du8.ew.sparse.bec <- glmer (pttype ~ bec_label_reclass2 + 
                                                (1 | uniqueID), 
                                       data = rsf.data.combo.du8.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [34, 1] <- "DU8"
table.aic [34, 2] <- "Early Winter"
table.aic [34, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [34, 4] <- "BEC"
table.aic [34, 5] <- "(1 | UniqueID)"
table.aic [34, 6] <-  AIC (model.lme4.du8.ew.sparse.bec)

### SPARSE HUMAN DISTURBANCE ###
model.lme4.du8.ew.sparse.human <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                   std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                   std.distance_to_resource_road +
                                                   (1 | uniqueID), 
                                       data = rsf.data.combo.du8.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [35, 1] <- "DU8"
table.aic [35, 2] <- "Early Winter"
table.aic [35, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [35, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DRR"
table.aic [35, 5] <- "(1 | UniqueID)"
table.aic [35, 6] <-  AIC (model.lme4.du8.ew.sparse.human)

### SPARSE NATURAL DISTURBANCE ###
model.lme4.du8.ew.sparse.nat <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                   fire_6to25yo + fire_over25yo +
                                                   (1 | uniqueID), 
                                         data = rsf.data.combo.du8.ew, 
                                         family = binomial (link = "logit"),
                                         verbose = T) 
# AIC
table.aic [36, 1] <- "DU8"
table.aic [36, 2] <- "Early Winter"
table.aic [36, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [36, 4] <- "Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [36, 5] <- "(1 | UniqueID)"
table.aic [36, 6] <-  AIC (model.lme4.du8.ew.sparse.nat)

### SPARSE FOOD ###
model.lme4.du8.ew.sparse.food <- glmer (pttype ~ std.vri_shrub_crown_close + std.vri_bryoid_cover_pct +
                                                (1 | uniqueID), 
                                        data = rsf.data.combo.du8.ew, 
                                        family = binomial (link = "logit"),
                                        verbose = T) 
# AIC
table.aic [37, 1] <- "DU8"
table.aic [37, 2] <- "Early Winter"
table.aic [37, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [37, 4] <- "ShrubClosure, BryoidCover"
table.aic [37, 5] <- "(1 | UniqueID)"
table.aic [37, 6] <-  AIC (model.lme4.du8.ew.sparse.food)

### SPARSE BEC AND HUMAN ###
model.lme4.du8.ew.sparse.bec.hd <- glmer (pttype ~ bec_label_reclass2 + 
                                                 std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                 std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                 std.distance_to_resource_road +
                                                 (1 | uniqueID), 
                                       data = rsf.data.combo.du8.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [38, 1] <- "DU8"
table.aic [38, 2] <- "Early Winter"
table.aic [38, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [38, 4] <- "BEC, DC1to4, DC5to9, DC10to29, DCover30, DRR"
table.aic [38, 5] <- "(1 | UniqueID)"
table.aic [38, 6] <-  AIC (model.lme4.du8.ew.sparse.bec.hd)

### SPARSE BEC AND NATURAL ###
model.lme4.du8.ew.sparse.bec.nd <- glmer (pttype ~ bec_label_reclass2 + 
                                                    beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                    fire_6to25yo + fire_over25yo +
                                                    (1 | uniqueID), 
                                          data = rsf.data.combo.du8.ew, 
                                          family = binomial (link = "logit"),
                                          verbose = T) 
# AIC
table.aic [39, 1] <- "DU8"
table.aic [39, 2] <- "Early Winter"
table.aic [39, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [39, 4] <- "BEC, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [39, 5] <- "(1 | UniqueID)"
table.aic [39, 6] <-  AIC (model.lme4.du8.ew.sparse.bec.nd)

### SPARSE BEC AND FOOD ###
model.lme4.du8.ew.sparse.bec.food <- glmer (pttype ~ bec_label_reclass2 + 
                                                     std.vri_shrub_crown_close + std.vri_bryoid_cover_pct +
                                                     (1 | uniqueID), 
                                          data = rsf.data.combo.du8.ew, 
                                          family = binomial (link = "logit"),
                                          verbose = T) 
# AIC
table.aic [40, 1] <- "DU8"
table.aic [40, 2] <- "Early Winter"
table.aic [40, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [40, 4] <- "BEC, ShrubClosure, BryoidCover"
table.aic [40, 5] <- "(1 | UniqueID)"
table.aic [40, 6] <-  AIC (model.lme4.du8.ew.sparse.bec.food)

### HUMAN AND NATURAL ###
model.lme4.du8.ew.sparse.hd.nd <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                   std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                   std.distance_to_resource_road +
                                                   beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                   fire_6to25yo + fire_over25yo +
                                                   (1 | uniqueID), 
                                          data = rsf.data.combo.du8.ew, 
                                          family = binomial (link = "logit"),
                                          verbose = T) 
# AIC
table.aic [41, 1] <- "DU8"
table.aic [41, 2] <- "Early Winter"
table.aic [41, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [41, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DRR, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [41, 5] <- "(1 | UniqueID)"
table.aic [41, 6] <-  AIC (model.lme4.du8.ew.sparse.hd.nd)

### HUMAN AND FOOD ###
model.lme4.du8.ew.sparse.hd.food <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                    std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                    std.distance_to_resource_road +
                                                    std.vri_shrub_crown_close + std.vri_bryoid_cover_pct +
                                                    (1 | uniqueID), 
                                         data = rsf.data.combo.du8.ew, 
                                         family = binomial (link = "logit"),
                                         verbose = T) 
# AIC
table.aic [42, 1] <- "DU8"
table.aic [42, 2] <- "Early Winter"
table.aic [42, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [42, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DRR, ShrubClosure, BryoidCover"
table.aic [42, 5] <- "(1 | UniqueID)"
table.aic [42, 6] <-  AIC (model.lme4.du8.ew.sparse.hd.food)

### NATURAL AND FOOD ###
model.lme4.du8.ew.sparse.nd.food <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                    fire_6to25yo + fire_over25yo +
                                                    std.vri_shrub_crown_close + std.vri_bryoid_cover_pct +
                                                    (1 | uniqueID), 
                                           data = rsf.data.combo.du8.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [43, 1] <- "DU8"
table.aic [43, 2] <- "Early Winter"
table.aic [43, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [43, 4] <- "Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, ShrubClosure, BryoidCover"
table.aic [43, 5] <- "(1 | UniqueID)"
table.aic [43, 6] <-  AIC (model.lme4.du8.ew.sparse.nd.food)

### SPARSE BEC AND HUMAN AND NATURAL ###
model.lme4.du8.ew.sparse.bec.hd.nd <- glmer (pttype ~ bec_label_reclass2 + 
                                                      std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                      std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                      std.distance_to_resource_road +
                                                      beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                      fire_6to25yo + fire_over25yo +
                                                      (1 | uniqueID), 
                                            data = rsf.data.combo.du8.ew, 
                                            family = binomial (link = "logit"),
                                            verbose = T) 
ss <- getME (model.lme4.du8.ew.sparse.bec.hd.nd, c ("theta","fixef"))
model.lme4.du8.ew.sparse.bec.hd.nd <- update (model.lme4.du8.ew.sparse.bec.hd.nd, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [44, 1] <- "DU8"
table.aic [44, 2] <- "Early Winter"
table.aic [44, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [44, 4] <- "BEC, DC1to4, DC5to9, DC10to29, DCover30, DRR, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [44, 5] <- "(1 | UniqueID)"
table.aic [44, 6] <-  AIC (model.lme4.du8.ew.sparse.bec.hd.nd)

### SPARSE BEC AND HUMAN AND FOOD ###
model.lme4.du8.ew.sparse.bec.hd.nd <- glmer (pttype ~ bec_label_reclass2 + 
                                                       std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                       std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                       std.distance_to_resource_road +
                                                       std.vri_shrub_crown_close + std.vri_bryoid_cover_pct +
                                                       (1 | uniqueID), 
                                             data = rsf.data.combo.du8.ew, 
                                             family = binomial (link = "logit"),
                                             verbose = T) 
# AIC
table.aic [45, 1] <- "DU8"
table.aic [45, 2] <- "Early Winter"
table.aic [45, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [45, 4] <- "BEC, DC1to4, DC5to9, DC10to29, DCover30, DRR, ShrubClosure, BryoidCover"
table.aic [45, 5] <- "(1 | UniqueID)"
table.aic [45, 6] <-  AIC (model.lme4.du8.ew.sparse.bec.hd.nd)

### SPARSE BEC AND NATURAL AND FOOD ###
model.lme4.du8.ew.sparse.bec.nd.food <- glmer (pttype ~ bec_label_reclass2 + 
                                                       beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                       fire_6to25yo + fire_over25yo +
                                                       std.vri_shrub_crown_close + std.vri_bryoid_cover_pct +
                                                       (1 | uniqueID), 
                                             data = rsf.data.combo.du8.ew, 
                                             family = binomial (link = "logit"),
                                             verbose = T) 
# AIC
table.aic [46, 1] <- "DU8"
table.aic [46, 2] <- "Early Winter"
table.aic [46, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [46, 4] <- "BEC, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, ShrubClosure, BryoidCover"
table.aic [46, 5] <- "(1 | UniqueID)"
table.aic [46, 6] <-  AIC (model.lme4.du8.ew.sparse.bec.nd.food)

### SPARSE HUMAN AND NATURAL AND FOOD ###
model.lme4.du8.ew.sparse.hd.nd.food <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                         std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                         std.distance_to_resource_road +
                                                         beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                         fire_6to25yo + fire_over25yo +
                                                         std.vri_shrub_crown_close + std.vri_bryoid_cover_pct +
                                                         (1 | uniqueID), 
                                               data = rsf.data.combo.du8.ew, 
                                               family = binomial (link = "logit"),
                                               verbose = T) 
# AIC
table.aic [47, 1] <- "DU8"
table.aic [47, 2] <- "Early Winter"
table.aic [47, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [47, 4] <- "DC1to4, DC5to9, DC10to29, DCover30, DRR, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, ShrubClosure, BryoidCover"
table.aic [47, 5] <- "(1 | UniqueID)"
table.aic [47, 6] <-  AIC (model.lme4.du8.ew.sparse.hd.nd.food)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_all_top.csv", sep = ",")

## AIC comparison of MODELS ## 
table.aic$AIC <- as.numeric (table.aic$AIC)
list.aic.like <- c ((exp (-0.5 * (table.aic [33, 6] - min (table.aic [c (33:47), 6])))), 
                    (exp (-0.5 * (table.aic [34, 6] - min (table.aic [c (33:47), 6])))),
                    (exp (-0.5 * (table.aic [35, 6] - min (table.aic [c (33:47), 6])))),
                    (exp (-0.5 * (table.aic [36, 6] - min (table.aic [c (33:47), 6])))),
                    (exp (-0.5 * (table.aic [37, 6] - min (table.aic [c (33:47), 6])))),
                    (exp (-0.5 * (table.aic [38, 6] - min (table.aic [c (33:47), 6])))),
                    (exp (-0.5 * (table.aic [39, 6] - min (table.aic [c (33:47), 6])))),
                    (exp (-0.5 * (table.aic [40, 6] - min (table.aic [c (33:47), 6])))),
                    (exp (-0.5 * (table.aic [41, 6] - min (table.aic [c (33:47), 6])))),
                    (exp (-0.5 * (table.aic [42, 6] - min (table.aic [c (33:47), 6])))),
                    (exp (-0.5 * (table.aic [43, 6] - min (table.aic [c (33:47), 6])))),
                    (exp (-0.5 * (table.aic [44, 6] - min (table.aic [c (33:47), 6])))),
                    (exp (-0.5 * (table.aic [45, 6] - min (table.aic [c (33:47), 6])))),
                    (exp (-0.5 * (table.aic [46, 6] - min (table.aic [c (33:47), 6])))),
                    (exp (-0.5 * (table.aic [47, 6] - min (table.aic [c (33:47), 6])))))
table.aic [33, 7] <- round ((exp (-0.5 * (table.aic [33, 6] - min (table.aic [c (33:47), 6])))) / sum (list.aic.like), 3)
table.aic [34, 7] <- round ((exp (-0.5 * (table.aic [34, 6] - min (table.aic [c (33:47), 6])))) / sum (list.aic.like), 3)
table.aic [35, 7] <- round ((exp (-0.5 * (table.aic [35, 6] - min (table.aic [c (33:47), 6])))) / sum (list.aic.like), 3)
table.aic [36, 7] <- round ((exp (-0.5 * (table.aic [36, 6] - min (table.aic [c (33:47), 6])))) / sum (list.aic.like), 3)
table.aic [37, 7] <- round ((exp (-0.5 * (table.aic [37, 6] - min (table.aic [c (33:47), 6])))) / sum (list.aic.like), 3)
table.aic [38, 7] <- round ((exp (-0.5 * (table.aic [38, 6] - min (table.aic [c (33:47), 6])))) / sum (list.aic.like), 3)
table.aic [39, 7] <- round ((exp (-0.5 * (table.aic [39, 6] - min (table.aic [c (33:47), 6])))) / sum (list.aic.like), 3)
table.aic [40, 7] <- round ((exp (-0.5 * (table.aic [40, 6] - min (table.aic [c (33:47), 6])))) / sum (list.aic.like), 3)
table.aic [41, 7] <- round ((exp (-0.5 * (table.aic [41, 6] - min (table.aic [c (33:47), 6])))) / sum (list.aic.like), 3)
table.aic [42, 7] <- round ((exp (-0.5 * (table.aic [42, 6] - min (table.aic [c (33:47), 6])))) / sum (list.aic.like), 3)
table.aic [43, 7] <- round ((exp (-0.5 * (table.aic [43, 6] - min (table.aic [c (33:47), 6])))) / sum (list.aic.like), 3)
table.aic [44, 7] <- round ((exp (-0.5 * (table.aic [44, 6] - min (table.aic [c (33:47), 6])))) / sum (list.aic.like), 3)
table.aic [45, 7] <- round ((exp (-0.5 * (table.aic [45, 6] - min (table.aic [c (33:47), 6])))) / sum (list.aic.like), 3)
table.aic [46, 7] <- round ((exp (-0.5 * (table.aic [46, 6] - min (table.aic [c (33:47), 6])))) / sum (list.aic.like), 3)
table.aic [47, 7] <- round ((exp (-0.5 * (table.aic [47, 6] - min (table.aic [c (33:47), 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_all_top.csv", sep = ",")

#### BEC INTERACTION MODELS ####
### BEC and STAND AGE ###
model.lme4.du8.ew.interact.bec.age <- glmer (pttype ~ bec_label_reclass + std.vri_proj_age +
                                                      bec_label_reclass * std.vri_proj_age +
                                                      (1 | uniqueID), 
                                              data = rsf.data.combo.du8.ew, 
                                              family = binomial (link = "logit"),
                                              verbose = T) 
# AIC
table.aic [48, 1] <- "DU8"
table.aic [48, 2] <- "Early Winter"
table.aic [48, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [48, 4] <- "BEC, TreeAge, BEC*TreeAge"
table.aic [48, 5] <- "(1 | UniqueID)"
table.aic [48, 6] <-  AIC (model.lme4.du8.ew.interact.bec.age)

### BEC and SITE INDEX ###
model.lme4.du8.ew.interact.bec.site <- glmer (pttype ~ bec_label_reclass + std.vri_site_index+
                                                       bec_label_reclass * std.vri_site_index +
                                                       (1 | uniqueID), 
                                              data = rsf.data.combo.du8.ew, 
                                              family = binomial (link = "logit"),
                                              verbose = T) 
ss <- getME (model.lme4.du8.ew.interact.bec.site, c ("theta","fixef"))
model.lme4.du8.ew.interact.bec.site <- update (model.lme4.du8.ew.interact.bec.site, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [49, 1] <- "DU8"
table.aic [49, 2] <- "Early Winter"
table.aic [49, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [49, 4] <- "BEC, SiteIndex, BEC*SiteIndex"
table.aic [49, 5] <- "(1 | UniqueID)"
table.aic [49, 6] <-  AIC (model.lme4.du8.ew.interact.bec.site)

### ELEVATION and STAND AGE ###
model.lme4.du8.ew.interact.elev.age <- glmer (pttype ~ std.elevation + std.vri_proj_age +
                                                       std.elevation * std.vri_proj_age +
                                                       (1 | uniqueID), 
                                             data = rsf.data.combo.du8.ew, 
                                             family = binomial (link = "logit"),
                                             verbose = T) 
# AIC
table.aic [50, 1] <- "DU8"
table.aic [50, 2] <- "Early Winter"
table.aic [50, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [50, 4] <- "Elevation, TreeAge, Elevation*TreeAge"
table.aic [50, 5] <- "(1 | UniqueID)"
table.aic [50, 6] <-  AIC (model.lme4.du8.ew.interact.elev.age)

### ELEVATION and SITE INDEX ###
model.lme4.du8.ew.interact.elev.site <- glmer (pttype ~ std.elevation + std.vri_site_index +
                                                        std.elevation * std.vri_site_index +
                                                        (1 | uniqueID), 
                                              data = rsf.data.combo.du8.ew, 
                                              family = binomial (link = "logit"),
                                              verbose = T) 
# AIC
table.aic [51, 1] <- "DU8"
table.aic [51, 2] <- "Early Winter"
table.aic [51, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [51, 4] <- "Elevation, SiteIndex, Elevation*SiteIndex"
table.aic [51, 5] <- "(1 | UniqueID)"
table.aic [51, 6] <-  AIC (model.lme4.du8.ew.interact.elev.site)


### BEC x STAND AGE and HUMAN DISTURBANCE ###
model.lme4.du8.ew.interact.bec2.age.hd <- glmer (pttype ~ bec_label_reclass2 + std.vri_proj_age +
                                                         bec_label_reclass2 * std.vri_proj_age +
                                                         std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                                         std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                                         std.distance_to_resource_road +
                                                         (1 | uniqueID), 
                                             data = rsf.data.combo.du8.ew, 
                                             family = binomial (link = "logit"),
                                             verbose = T) 
# AIC
table.aic [53, 1] <- "DU8"
table.aic [53, 2] <- "Early Winter"
table.aic [53, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [53, 4] <- "BEC2, TreeAge, BEC*TreeAge, DC1to4, DC5to9, DC10to29, DCover30, DRR"
table.aic [53, 5] <- "(1 | UniqueID)"
table.aic [53, 6] <-  AIC (model.lme4.du8.ew.interact.bec2.age.hd)


write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du8\\early_winter\\table_aic_all_top.csv", sep = ",")

save (model.lme4.du8.ew.sparse, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_du8_ew_final.rda")

# Create table of model coefficients from top model
model.coeffs <- as.data.frame (coef (summary (model.lme4.du8.ew.sparse)))
model.coeffs$mean <- 0
model.coeffs$sd <- 0

model.coeffs [11, 5] <- mean (rsf.data.combo.du8.ew$distance_to_cut_1to4yo)
model.coeffs [12, 5] <- mean (rsf.data.combo.du8.ew$distance_to_cut_5to9yo)
model.coeffs [13, 5] <- mean (rsf.data.combo.du8.ew$distance_to_cut_10to29yo)
model.coeffs [14, 5] <- mean (rsf.data.combo.du8.ew$distance_to_cut_30orOveryo)
model.coeffs [15, 5] <- mean (rsf.data.combo.du8.ew$distance_to_resource_road)
model.coeffs [21, 5] <- mean (rsf.data.combo.du8.ew$vri_shrub_crown_close)
model.coeffs [22, 5] <- mean (rsf.data.combo.du8.ew$vri_bryoid_cover_pct)

model.coeffs [11, 6] <- sd (rsf.data.combo.du8.ew$distance_to_cut_1to4yo)
model.coeffs [12, 6] <- sd (rsf.data.combo.du8.ew$distance_to_cut_5to9yo)
model.coeffs [13, 6] <- sd (rsf.data.combo.du8.ew$distance_to_cut_10to29yo)
model.coeffs [14, 6] <- sd (rsf.data.combo.du8.ew$distance_to_cut_30orOveryo)
model.coeffs [15, 6] <- sd (rsf.data.combo.du8.ew$distance_to_resource_road)
model.coeffs [21, 6] <- sd (rsf.data.combo.du8.ew$vri_shrub_crown_close)
model.coeffs [22, 6] <- sd (rsf.data.combo.du8.ew$vri_bryoid_cover_pct)

write.table (model.coeffs, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\model_coefficients\\table_du8_ew_model_coeffs_top.csv", sep = ",")

##########################
### k-fold Validation ###
########################
df.unique.id <- as.data.frame (unique (rsf.data.combo.du8.ew$uniqueID))
names (df.unique.id) [1] <-"uniqueID"
df.unique.id$group <- rep_len (1:5, nrow (df.unique.id)) # orderly selection of groups
rsf.data.combo.du8.ew <- dplyr::full_join (rsf.data.combo.du8.ew, df.unique.id, by = "uniqueID")

### FOLD 1 ###
train.data.1 <- rsf.data.combo.du8.ew %>%
  filter (group < 5)
test.data.1 <- rsf.data.combo.du8.ew %>%
  filter (group == 5)

model.lme4.du8.ew.train1 <- glmer (pttype ~ bec_label_reclass2 +
                                             std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                             std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                             std.distance_to_resource_road +
                                             beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                             fire_6to25yo + fire_over25yo +
                                             std.vri_shrub_crown_close + std.vri_bryoid_cover_pct +
                                             (1 | uniqueID), 
                                   data = train.data.1, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
ss <- getME (model.lme4.du8.ew.train1, c ("theta","fixef"))
model.lme4.du8.ew.train1 <- update (model.lme4.du8.ew.train1, start = ss) # failed to converge, restart with parameter estimates
# create a table of k-fold outputs
table.kfold <- data.frame (matrix (ncol = 12, nrow = 50))
colnames (table.kfold) <- c ("test.number", "bin.mid", "bin.weight", "utilization", "used.count", 
                             "expected.count", "lm.slope", "lm.slope.p.value", "lm.intercept",
                             "lm.intercept.p.value", "adj.R.sq", "chi.sq.p.value")
table.kfold [c (1:10), 1] <- 1
table.kfold$bin.mid <- c (0.025, 0.075, 0.125, 0.175, 0.225, 0.275, 0.325, 0.375, 0.45, 0.75)

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.combo.du8.ew$preds.train1 <- predict (model.lme4.du8.ew.train1, 
                                               newdata = rsf.data.combo.du8.ew, 
                                               re.form = NA, type = "response")

ggplot (data = rsf.data.combo.du8.ew, aes (preds.train1)) +
        geom_histogram()
max (rsf.data.combo.du8.ew$preds.train1)
min (rsf.data.combo.du8.ew$preds.train1)

rsf.data.combo.du8.ew$preds.train1.class <- cut (rsf.data.combo.du8.ew$preds.train1, # put into classes; 0 to 0.4, based on max and min values
                                                 breaks = c (-Inf, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.50, Inf), 
                                                 labels = c ("0.025", "0.075", "0.125", "0.175", "0.225",
                                                             "0.275", "0.325", "0.375", "0.45", "0.75"))
write.csv (rsf.data.combo.du8.ew, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du8_ew.csv")
rsf.data.combo.du8.ew.avail <- dplyr::filter (rsf.data.combo.du8.ew, pttype == 0)

table.kfold [1, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train1.class == "0.025")) * 0.025) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [2, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train1.class == "0.075")) * 0.075)
table.kfold [3, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train1.class == "0.125")) * 0.125)
table.kfold [4, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train1.class == "0.175")) * 0.175)
table.kfold [5, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train1.class == "0.225")) * 0.225)
table.kfold [6, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train1.class == "0.275")) * 0.275)
table.kfold [7, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train1.class == "0.325")) * 0.325)
table.kfold [8, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train1.class == "0.375")) * 0.375)
table.kfold [9, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train1.class == "0.45")) * 0.45)
table.kfold [10, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train1.class == "0.75")) * 0.75)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\table_kfold_valid_du8_ew.csv")

# data for estimating use
test.data.1$preds <- predict (model.lme4.du8.ew.train1, newdata = test.data.1, re.form = NA, type = "response")
test.data.1$preds.class <- cut (test.data.1$preds, # put into classes; 0 to 0.4, based on max and min values
                                breaks = c (-Inf, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.50, Inf), 
                                labels = c ("0.025", "0.075", "0.125", "0.175", "0.225",
                                            "0.275", "0.325", "0.375", "0.45", "0.75"))
write.csv (test.data.1, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\rsf_preds_du8_ew_train1.csv")
test.data.1.used <- dplyr::filter (test.data.1, pttype == 1)

table.kfold [1, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.025"))
table.kfold [2, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.075"))
table.kfold [3, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.125"))
table.kfold [4, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.175"))
table.kfold [5, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.225"))
table.kfold [6, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.275"))
table.kfold [7, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.325"))
table.kfold [8, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.375"))
table.kfold [9, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.45"))
table.kfold [10, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.75"))

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

table.kfold [1, 7] <- 0.96588
table.kfold [1, 8] <- "<0.001"
table.kfold [1, 9] <- 20.98490
table.kfold [1, 10] <- 0.715
table.kfold [1, 11] <- 0.9627

chisq.test(dplyr::filter(table.kfold, test.number == 1)$used.count, dplyr::filter(table.kfold, test.number == 1)$expected.count)
table.kfold [1, 12] <- 0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\table_kfold_valid_du8_ew.csv")


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
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du8_ew_grp1.png")


### FOLD 2 ###
train.data.2 <- rsf.data.combo.du8.ew %>%
  filter (group == 1 | group == 2 | group == 3 | group == 5)
test.data.2 <- rsf.data.combo.du8.ew %>%
  filter (group == 4)

model.lme4.du8.ew.train2 <- glmer (pttype ~ bec_label_reclass2 +
                                             std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                             std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                             std.distance_to_resource_road +
                                             beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                             fire_6to25yo + fire_over25yo +
                                             std.vri_shrub_crown_close + std.vri_bryoid_cover_pct +
                                             (1 | uniqueID), 
                                   data = train.data.2, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.combo.du8.ew$preds.train2 <- predict (model.lme4.du8.ew.train2, 
                                               newdata = rsf.data.combo.du8.ew, 
                                               re.form = NA, type = "response")
ggplot (data = rsf.data.combo.du8.ew, aes (preds.train2)) +
        geom_histogram()
max (rsf.data.combo.du8.ew$preds.train2)
min (rsf.data.combo.du8.ew$preds.train2)
rsf.data.combo.du8.ew$preds.train2.class <- cut (rsf.data.combo.du8.ew$preds.train2, # put into classes; 0 to 0.4, based on max and min values
                                                 breaks = c (-Inf, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.50, Inf), 
                                                 labels = c ("0.025", "0.075", "0.125", "0.175", "0.225",
                                                             "0.275", "0.325", "0.375", "0.45", "0.75"))
write.csv (rsf.data.combo.du8.ew, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du8_ew.csv")
rsf.data.combo.du8.ew.avail <- dplyr::filter (rsf.data.combo.du8.ew, pttype == 0)

table.kfold [c (11:20), 1] <- 2

table.kfold [11, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train2.class == "0.025")) * 0.025) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [12, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train2.class == "0.075")) * 0.075)
table.kfold [13, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train2.class == "0.125")) * 0.125)
table.kfold [14, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train2.class == "0.175")) * 0.175)
table.kfold [15, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train2.class == "0.225")) * 0.225)
table.kfold [16, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train2.class == "0.275")) * 0.275)
table.kfold [17, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train2.class == "0.325")) * 0.325)
table.kfold [18, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train2.class == "0.375")) * 0.375)
table.kfold [19, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train2.class == "0.45")) * 0.45)
table.kfold [20, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train2.class == "0.75")) * 0.75)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\table_kfold_valid_du8_ew.csv")

# data for estimating use
test.data.2$preds <- predict (model.lme4.du8.ew.train2, newdata = test.data.2, re.form = NA, type = "response")
test.data.2$preds.class <- cut (test.data.2$preds, # put into classes; 0 to 0.4, based on max and min values
                                breaks = c (-Inf, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.50, Inf), 
                                labels = c ("0.025", "0.075", "0.125", "0.175", "0.225",
                                            "0.275", "0.325", "0.375", "0.45", "0.75"))
write.csv (test.data.2, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\rsf_preds_du8_ew_train2.csv")
test.data.2.used <- dplyr::filter (test.data.2, pttype == 1)

table.kfold [11, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.025"))
table.kfold [12, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.075"))
table.kfold [13, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.125"))
table.kfold [14, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.175"))
table.kfold [15, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.225"))
table.kfold [16, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.275"))
table.kfold [17, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.325"))
table.kfold [18, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.375"))
table.kfold [19, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.45"))
table.kfold [20, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.75"))

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

table.kfold [11, 7] <- 1.0090
table.kfold [11, 8] <- "<0.001"
table.kfold [11, 9] <- -5.6468
table.kfold [11, 10] <- 0.963
table.kfold [11, 11] <- 0.8652

chisq.test(dplyr::filter(table.kfold, test.number == 2)$used.count, dplyr::filter(table.kfold, test.number == 2)$expected.count)
table.kfold [11, 12] <- 0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\table_kfold_valid_du8_ew.csv")


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
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du8_ew_grp2.png")

write.csv (test.data.2, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\rsf_preds_du8_ew_train2.csv")

### FOLD 3 ###
train.data.3 <- rsf.data.combo.du8.ew %>%
  filter (group == 1 | group == 2 | group == 4 | group == 5)
test.data.3 <- rsf.data.combo.du8.ew %>%
  filter (group == 3)

model.lme4.du8.ew.train3 <- glmer (pttype ~ bec_label_reclass2 +
                                             std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                             std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                             std.distance_to_resource_road +
                                             beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                             fire_6to25yo + fire_over25yo +
                                             std.vri_shrub_crown_close + std.vri_bryoid_cover_pct +
                                             (1 | uniqueID), 
                                   data = train.data.3, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.combo.du8.ew$preds.train3 <- predict (model.lme4.du8.ew.train3, 
                                               newdata = rsf.data.combo.du8.ew, 
                                               re.form = NA, type = "response")
max (rsf.data.combo.du8.ew$preds.train3)
min (rsf.data.combo.du8.ew$preds.train3)
rsf.data.combo.du8.ew$preds.train3.class <- cut (rsf.data.combo.du8.ew$preds.train3, # put into classes; 0 to 0.4, based on max and min values
                                                 breaks = c (-Inf, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.50, Inf), 
                                                 labels = c ("0.025", "0.075", "0.125", "0.175", "0.225",
                                                             "0.275", "0.325", "0.375", "0.45", "0.75"))
write.csv (rsf.data.combo.du8.ew, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du8_ew.csv")
rsf.data.combo.du8.ew.avail <- dplyr::filter (rsf.data.combo.du8.ew, pttype == 0)

table.kfold [c (21:30), 1] <- 3

table.kfold [21, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train3.class == "0.025")) * 0.025) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [22, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train3.class == "0.075")) * 0.075)
table.kfold [23, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train3.class == "0.125")) * 0.125)
table.kfold [24, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train3.class == "0.175")) * 0.175)
table.kfold [25, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train3.class == "0.225")) * 0.225)
table.kfold [26, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train3.class == "0.275")) * 0.275)
table.kfold [27, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train3.class == "0.325")) * 0.325)
table.kfold [28, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train3.class == "0.375")) * 0.375)
table.kfold [29, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train3.class == "0.45")) * 0.45)
table.kfold [30, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train3.class == "0.75")) * 0.75)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\table_kfold_valid_du8_ew.csv")

# data for estimating use
test.data.3$preds <- predict (model.lme4.du8.ew.train3, newdata = test.data.3, re.form = NA, type = "response")
test.data.3$preds.class <- cut (test.data.3$preds, # put into classes; 0 to 0.4, based on max and min values
                                breaks = c (-Inf, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.50, Inf), 
                                labels = c ("0.025", "0.075", "0.125", "0.175", "0.225",
                                            "0.275", "0.325", "0.375", "0.45", "0.75"))
write.csv (test.data.3, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\rsf_preds_du8_ew_train3.csv")
test.data.3.used <- dplyr::filter (test.data.3, pttype == 1)

table.kfold [21, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.025"))
table.kfold [22, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.075"))
table.kfold [23, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.125"))
table.kfold [24, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.175"))
table.kfold [25, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.225"))
table.kfold [26, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.275"))
table.kfold [27, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.325"))
table.kfold [28, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.375"))
table.kfold [29, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.45"))
table.kfold [30, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.75"))

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

table.kfold [21, 7] <- 0.9685
table.kfold [21, 8] <- "<0.001"
table.kfold [21, 9] <- 18.4581
table.kfold [21, 10] <- 0.865
table.kfold [21, 11] <- 0.866

chisq.test(dplyr::filter(table.kfold, test.number == 3)$used.count, dplyr::filter(table.kfold, test.number == 3)$expected.count)
table.kfold [21, 12] <- 0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\table_kfold_valid_du8_ew.csv")

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
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du8_ew_grp3.png")

write.csv (test.data.3, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\rsf_preds_du8_ew_train3.csv")

### FOLD 4 ###
train.data.4 <- rsf.data.combo.du8.ew %>%
  filter (group == 1 | group == 3 | group == 4 | group == 5)
test.data.4 <- rsf.data.combo.du8.ew %>%
  filter (group == 2)

model.lme4.du8.ew.train4 <- glmer (pttype ~ bec_label_reclass2 +
                                             std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                             std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                             std.distance_to_resource_road +
                                             beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                             fire_6to25yo + fire_over25yo +
                                             std.vri_shrub_crown_close + std.vri_bryoid_cover_pct +
                                             (1 | uniqueID), 
                                   data = train.data.4, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
ss <- getME (model.lme4.du8.ew.train4, c ("theta","fixef"))
model.lme4.du8.ew.train4 <- update (model.lme4.du8.ew.train4, start = ss) # failed to converge, restart with parameter estimates
# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.combo.du8.ew$preds.train4 <- predict (model.lme4.du8.ew.train4, 
                                               newdata = rsf.data.combo.du8.ew, 
                                               re.form = NA, type = "response")
max (rsf.data.combo.du8.ew$preds.train4)
min (rsf.data.combo.du8.ew$preds.train4)
rsf.data.combo.du8.ew$preds.train4.class <- cut (rsf.data.combo.du8.ew$preds.train4, # put into classes; 0 to 0.4, based on max and min values
                                                 breaks = c (-Inf, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.50, Inf), 
                                                 labels = c ("0.025", "0.075", "0.125", "0.175", "0.225",
                                                             "0.275", "0.325", "0.375", "0.45", "0.75"))
write.csv (rsf.data.combo.du8.ew, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du8_ew.csv")
rsf.data.combo.du8.ew.avail <- dplyr::filter (rsf.data.combo.du8.ew, pttype == 0)

table.kfold [c (31:40), 1] <- 4

table.kfold [31, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train4.class == "0.025")) * 0.025) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [32, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train4.class == "0.075")) * 0.075)
table.kfold [33, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train4.class == "0.125")) * 0.125)
table.kfold [34, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train4.class == "0.175")) * 0.175)
table.kfold [35, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train4.class == "0.225")) * 0.225)
table.kfold [36, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train4.class == "0.275")) * 0.275)
table.kfold [37, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train4.class == "0.325")) * 0.325)
table.kfold [38, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train4.class == "0.375")) * 0.375)
table.kfold [39, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train4.class == "0.45")) * 0.45)
table.kfold [40, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train4.class == "0.75")) * 0.75)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\table_kfold_valid_du8_ew.csv")

# data for estimating use
test.data.4$preds <- predict (model.lme4.du8.ew.train4, newdata = test.data.4, re.form = NA, type = "response")
test.data.4$preds.class <- cut (test.data.4$preds, # put into classes; 0 to 0.4, based on max and min values
                                breaks = c (-Inf, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.50, Inf), 
                                labels = c ("0.025", "0.075", "0.125", "0.175", "0.225",
                                            "0.275", "0.325", "0.375", "0.45", "0.75"))
write.csv (test.data.4, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\rsf_preds_du8_ew_train4.csv")
test.data.4.used <- dplyr::filter (test.data.4, pttype == 1)

table.kfold [31, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.025"))
table.kfold [32, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.075"))
table.kfold [33, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.125"))
table.kfold [34, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.175"))
table.kfold [35, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.225"))
table.kfold [36, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.275"))
table.kfold [37, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.325"))
table.kfold [38, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.375"))
table.kfold [39, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.45"))
table.kfold [40, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.75"))

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

table.kfold [31, 7] <- 0.97592
table.kfold [31, 8] <- "<0.001"
table.kfold [31, 9] <- 15.88603
table.kfold [31, 10] <- 0.779
table.kfold [31, 11] <- 0.969

chisq.test(dplyr::filter(table.kfold, test.number == 4)$used.count, dplyr::filter(table.kfold, test.number == 4)$expected.count)
table.kfold [31, 12] <- 0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\table_kfold_valid_du8_ew.csv")

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
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du8_ew_grp4.png")

write.csv (test.data.4, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\rsf_preds_du8_ew_train4.csv")

### FOLD 5 ###
train.data.5 <- rsf.data.combo.du8.ew %>%
  filter (group == 5 | group == 2 | group == 3 | group == 4)
test.data.5 <- rsf.data.combo.du8.ew %>%
  filter (group == 1)

model.lme4.du8.ew.train5 <- glmer (pttype ~ bec_label_reclass2 +
                                             std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                             std.distance_to_cut_10to29yo + std.distance_to_cut_30orOveryo +
                                             std.distance_to_resource_road +
                                             beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                             fire_6to25yo + fire_over25yo +
                                             std.vri_shrub_crown_close + std.vri_bryoid_cover_pct +
                                             (1 | uniqueID), 
                                   data = train.data.5, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.combo.du8.ew$preds.train5 <- predict (model.lme4.du8.ew.train5, 
                                               newdata = rsf.data.combo.du8.ew, 
                                               re.form = NA, type = "response")
max (rsf.data.combo.du8.ew$preds.train5)
min (rsf.data.combo.du8.ew$preds.train5)
rsf.data.combo.du8.ew$preds.train5.class <- cut (rsf.data.combo.du8.ew$preds.train5, # put into classes; 0 to 0.4, based on max and min values
                                                 breaks = c (-Inf, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.50, Inf), 
                                                 labels = c ("0.025", "0.075", "0.125", "0.175", "0.225",
                                                             "0.275", "0.325", "0.375", "0.45", "0.75"))
write.csv (rsf.data.combo.du8.ew, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du8_ew.csv")
rsf.data.combo.du8.ew.avail <- dplyr::filter (rsf.data.combo.du8.ew, pttype == 0)

table.kfold [c (41:50), 1] <- 5

table.kfold [41, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train5.class == "0.025")) * 0.025) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [42, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train5.class == "0.075")) * 0.075)
table.kfold [43, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train5.class == "0.125")) * 0.125)
table.kfold [44, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train5.class == "0.175")) * 0.175)
table.kfold [45, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train5.class == "0.225")) * 0.225)
table.kfold [46, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train5.class == "0.275")) * 0.275)
table.kfold [47, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train5.class == "0.325")) * 0.325)
table.kfold [48, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train5.class == "0.375")) * 0.375)
table.kfold [49, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train5.class == "0.45")) * 0.45)
table.kfold [50, 3] <- (nrow (dplyr::filter (rsf.data.combo.du8.ew.avail, preds.train5.class == "0.75")) * 0.75)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\table_kfold_valid_du8_ew.csv")

# data for estimating use
test.data.5$preds <- predict (model.lme4.du8.ew.train5, newdata = test.data.5, re.form = NA, type = "response")
test.data.5$preds.class <- cut (test.data.5$preds, # put into classes; 0 to 0.4, based on max and min values
                                breaks = c (-Inf, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.50, Inf), 
                                labels = c ("0.025", "0.075", "0.125", "0.175", "0.225",
                                            "0.275", "0.325", "0.375", "0.45", "0.75"))
write.csv (test.data.5, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\rsf_preds_du8_ew_train5.csv")
test.data.5.used <- dplyr::filter (test.data.5, pttype == 1)

table.kfold [41, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.025"))
table.kfold [42, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.075"))
table.kfold [43, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.125"))
table.kfold [44, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.175"))
table.kfold [45, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.225"))
table.kfold [46, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.275"))
table.kfold [47, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.325"))
table.kfold [48, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.375"))
table.kfold [49, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.45"))
table.kfold [50, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.75"))

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

table.kfold [41, 7] <- 0.84325
table.kfold [41, 8] <- "<0.001"
table.kfold [41, 9] <- 93.19460
table.kfold [41, 10] <- 0.294
table.kfold [41, 11] <- 0.8928

chisq.test(dplyr::filter(table.kfold, test.number == 5)$used.count, dplyr::filter(table.kfold, test.number == 5)$expected.count)
table.kfold [41, 12] <- 0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\table_kfold_valid_du8_ew.csv")


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
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du8_ew_grp5.png")

write.csv (test.data.5, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\rsf_preds_du8_ew_train5.csv")

# create results table
table.kfold.results.du8.ew <- table.kfold
table.kfold.results.du8.ew <- table.kfold.results.du8.ew [- c (1, 3:7)]

table.kfold.results.du8.ew <- table.kfold.results.du8.ew %>%
  slice (c (1, 11, 21, 31, 41))

write.csv (table.kfold.results.du8.ew, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\early_winter\\table_kfold_summary_du8_ew.csv")

###############################
### RSF RASTER CALCULATION ###
#############################
raster.bec <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_subzone.tif")
lut.bec <- read.csv ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\lut_bec_subzone.csv", header = T, sep = ",")

beginCluster ()
bec.bafa.un <- reclassify (raster.bec, c (1,1,1,  2,213,0), include.lowest = T, right = NA)
writeRaster (bec.bafa.un, "C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_bafa_un.tif", 
             format = "GTiff", overwrite = T)
bec.bwbs.mw <- reclassify (raster.bec, c (1,9,0, 10,10,1, 11,213,0), include.lowest = T, right = NA)
writeRaster (bec.bwbs.mw, "C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_bwbs_mw.tif", 
             format = "GTiff", overwrite = T)
bec.bwbs.wk1 <- reclassify (raster.bec, c (1,11,0, 12,12,1, 13,213,0), include.lowest = T, right = NA)
writeRaster (bec.bwbs.wk1, "C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_bwbs_wk1.tif", 
             format = "GTiff", overwrite = T)
bec.essf.mv2 <- reclassify (raster.bec, c (1,61,0, 62,62,1, 63,213,0), include.lowest = T, right = NA)
writeRaster (bec.essf.mv2, "C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_mv2.tif", 
             format = "GTiff", overwrite = T)
bec.essf.mvp <- reclassify (raster.bec, c (1,64,0, 65,65,1, 66,213,0), include.lowest = T, right = NA)
writeRaster (bec.essf.mvp, "C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_mvp.tif", 
             format = "GTiff", overwrite = T)
bec.essf.wcp <- reclassify (raster.bec, c (1,79,0, 80,80,1, 81,213,0), include.lowest = T, right = NA)
writeRaster (bec.essf.wcp, "C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_wcp.tif", 
             format = "GTiff", overwrite = T)
bec.essf.wk2 <- reclassify (raster.bec, c (1,85,0, 86,86,1, 87,213,0), include.lowest = T, right = NA)
writeRaster (bec.essf.wk2, "C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_wk2.tif", 
             format = "GTiff", overwrite = T)
bec.sbs.wk1 <- reclassify (raster.bec, c (1,203,0, 204,204,1, 205,213,0), include.lowest = T, right = NA)
writeRaster (bec.sbs.wk1, "C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_sbs_wk1.tif", 
             format = "GTiff", overwrite = T)
bec.sbs.wk2 <- reclassify (raster.bec, c (1,204,0, 205,205,1, 206,213,0), include.lowest = T, right = NA)
writeRaster (bec.sbs.wk2, "C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_sbs_wk2.tif", 
             format = "GTiff", overwrite = T)
endCluster ()

### LOAD RASTERS ###
bec.bafa.un <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_bafa_un.tif")
bec.bwbs.mw <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_bwbs_mw.tif")
bec.bwbs.wk1 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_bwbs_wk1.tif")
bec.essf.mv2 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_mv2.tif")
bec.essf.mvp <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_mvp.tif")
bec.essf.wcp <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_wcp.tif")
bec.essf.wk2 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_wk2.tif")
bec.sbs.wk1 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_sbs_wk1.tif")
bec.sbs.wk2 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_sbs_wk2.tif")
dist.cut.1to4 <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_1to4yo.tif")
dist.cut.5to9 <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_5to9yo.tif")
dist.cut.10to29 <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_10to29yo.tif")
dist.cut.30over <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_30yo_over.tif")
dist.resource.rd <- raster ("C:\\Work\\caribou\\clus_data\\roads_ha_bc\\dist_crds_resource.tif")
beetle.1to5 <- raster ("C:\\Work\\caribou\\clus_data\\forest_health\\raster_bark_beetle_all_1to5yo_fin.tif")
beetle.6to9 <- raster ("C:\\Work\\caribou\\clus_data\\forest_health\\raster_bark_beetle_all_6to9yo_fin.tif")
fire.1to5 <- raster ("C:\\Work\\caribou\\clus_data\\fire\\fire_tiffs\\raster_fire_1to5yo_fin.tif")
fire.6to25 <- raster ("C:\\Work\\caribou\\clus_data\\fire\\fire_tiffs\\raster_fire_6to25yo_fin.tif")
fire.over25 <- raster ("C:\\Work\\caribou\\clus_data\\fire\\fire_tiffs\\raster_fire_over25yo_fin.tif")
vri.shrub <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\vri_shrubcrownclosure.tif")
vri.bryoid <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\vri_bryoidcoverpct.tif")

### CROP RASTERS TO DU8 USED "BOX' "of HERD RANGES PLUS 25km BUFFER ###
caribou.sa <- readOGR ("C:\\Work\\caribou\\clus_data\\caribou\\caribou_herd\\du8_herds_buff25km.shp", stringsAsFactors = T) # DU8 herds with 25km buffer
bec.bafa.un <- crop (bec.bafa.un, extent (caribou.sa))
bec.bwbs.mw <- crop (bec.bwbs.mw, extent (caribou.sa))
bec.bwbs.wk1 <- crop (bec.bwbs.wk1, extent (caribou.sa))
bec.essf.mv2 <- crop (bec.essf.mv2, extent (caribou.sa))
bec.essf.mvp <- crop (bec.essf.mvp, extent (caribou.sa))
bec.essf.wcp <- crop (bec.essf.wcp, extent (caribou.sa))
bec.essf.wk2 <- crop (bec.essf.wk2, extent (caribou.sa))
bec.sbs.wk1 <- crop (bec.sbs.wk1, extent (caribou.sa))
bec.sbs.wk2 <- crop (bec.sbs.wk2, extent (caribou.sa))
dist.cut.1to4 <- crop (dist.cut.1to4, extent (caribou.sa))
dist.cut.5to9 <- crop (dist.cut.5to9, extent (caribou.sa))
dist.cut.10to29 <- crop (dist.cut.10to29, extent (caribou.sa))
dist.cut.30over <- crop (dist.cut.30over, extent (caribou.sa))
dist.resource.rd <- crop (dist.resource.rd, extent (caribou.sa))
beetle.1to5 <- crop (beetle.1to5, extent (caribou.sa))
beetle.6to9 <- crop (beetle.6to9, extent (caribou.sa))
fire.1to5 <- crop (fire.1to5, extent (caribou.sa))
fire.6to25 <- crop (fire.6to25, extent (caribou.sa))
fire.over25 <- crop (fire.over25, extent (caribou.sa))
vri.bryoid <- crop (vri.bryoid, extent (caribou.sa))
vri.shrub <- crop (vri.shrub, extent (caribou.sa))

# proj.crs <- proj4string (caribou.boreal.sa)
# growing.degree.day <- projectRaster (growing.degree.day, crs = proj.crs, method = "bilinear")

### Adjust the raster data for 'standardized' model covariates ###
beginCluster ()

std.dist.cut.1to4 <- (dist.cut.1to4 - 9648) / 6560 # rounded these numbers to facilitate faster processing; decreases processing time substantially
std.dist.cut.5to9 <- (dist.cut.5to9 - 6604) / 4833
dist.cut.10to29 <- (dist.cut.10to29 - 3176) / 2656
dist.cut.30over <- (dist.cut.30over - 5803) / 3683
std.dist.resource.rd <- (dist.resource.rd - 1295) / 1550
std.vri.bryoid <- (vri.bryoid - 5) / 10
std.vri.shrub <- (vri.shrub - 10) / 14

endCluster ()

### CALCULATE RASTER OF STATIC VARIABLES ###
beginCluster ()

raster.rsf <- exp (-2.88 + (bec.bafa.un * 1.86) + (bec.bwbs.mw * 0.94) + 
                           (bec.bwbs.wk1 * 0.86) + (bec.essf.mv2 * 0.55) +
                           (bec.essf.mvp * 0.96) + (bec.essf.wcp * 0.78) +
                           (bec.essf.wk2 * 0.21) + (bec.sbs.wk1 * 0.01) +
                           (bec.sbs.wk2 * 0.53) +
                           (std.dist.cut.1to4 * 0.03) + (std.dist.cut.5to9 * -0.14) +
                           (dist.cut.10to29 * 0.07) + (dist.cut.30over * -0.14) +
                           (std.dist.resource.rd * 0.002) +
                           (beetle.1to5 * 0.13) + (beetle.6to9 * -0.05) +
                           (fire.1to5 * -1.02) + (fire.6to25 * -0.10) + (fire.over25 * -0.21) +
                           (std.vri.shrub * -0.06) + (std.vri.bryoid * 0.43)) /
           1 + exp (-2.88 + (bec.bafa.un * 1.86) + (bec.bwbs.mw * 0.94) + 
                           (bec.bwbs.wk1 * 0.86) + (bec.essf.mv2 * 0.55) +
                           (bec.essf.mvp * 0.96) + (bec.essf.wcp * 0.78) +
                           (bec.essf.wk2 * 0.21) + (bec.sbs.wk1 * 0.01) +
                           (bec.sbs.wk2 * 0.53) +
                           (std.dist.cut.1to4 * 0.03) + (std.dist.cut.5to9 * -0.14) +
                           (dist.cut.10to29 * 0.07) + (dist.cut.30over * -0.14) +
                           (std.dist.resource.rd * 0.002) +
                           (beetle.1to5 * 0.13) + (beetle.6to9 * -0.05) +
                           (fire.1to5 * -1.02) + (fire.6to25 * -0.10) + (fire.over25 * -0.21) +
                           (std.vri.shrub * -0.06) + (std.vri.bryoid * 0.43))       
                
writeRaster (raster.rsf, "C:\\Work\\caribou\\clus_data\\rsf\\du8\\early_winter\\rsf_du8_ew.tif", 
             format = "GTiff", overwrite = T)

endCluster ()
