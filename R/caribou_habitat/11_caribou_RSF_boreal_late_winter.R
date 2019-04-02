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
#  Script Name: 11_caribou_RSF_boreal_late_winter.R
#  Script Version: 1.0
#  Script Purpose: Script to develop caribou RSF model for DU6 and Late winter.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 19 February 2019
#  R Version: 
#  R Packages: 
#  Data: 
#=================================

#==========================================
# TO TURN SCRIPT FOR DIFFERENT DUs and SEASONS:
# Find and Replace:
# 1. ew .lw .s
# 2. du6, du7, du8, du9

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
test <- rsf.data.terrain.water %>% filter (is.na (soil_parent_material_name))
rsf.data.terrain.water <- rsf.data.terrain.water %>% 
                            filter (!is.na (soil_parent_material_name))
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

# noticed issue with eastness/northness data, need to make value = 0 if slope = 0
rsf.data.terrain.water$easting <- ifelse (rsf.data.terrain.water$slope == 0, 0, rsf.data.terrain.water$easting) 
rsf.data.terrain.water$northing <- ifelse (rsf.data.terrain.water$slope == 0, 0, rsf.data.terrain.water$northing) 


# Group road data into low-use types (resource roads)
rsf.data.human.dist <- dplyr::mutate (rsf.data.human.dist, distance_to_resource_road = pmin (distance_to_loose_road, 
                                                                                             distance_to_petroleum_road,
                                                                                             distance_to_rough_road,
                                                                                             distance_to_trim_transport_road,
                                                                                             distance_to_unknown_road))

# collapse wetland classes for caribou as defined by Demars (2018)
rsf.data.veg$wetland_demars <- rsf.data.veg$wetland_class_du_boreal_name
rsf.data.veg$wetland_demars <- recode (rsf.data.veg$wetland_demars,
                                       "c('Treed Bog', 'Open Bog', 'Shrubby Bog') = 'Treed Bog'")
rsf.data.veg$wetland_demars <- recode (rsf.data.veg$wetland_demars,
                                       "c ('Graminoid Poor Fen', 'Shrubby Poor Fen', 'Treed Poor Fen') = 'Nutrient Poor Fen'")
rsf.data.veg$wetland_demars <- recode (rsf.data.veg$wetland_demars,
                                       "c ('Graminoid Rich Fen', 'Shrubby Rich Fen', 'Treed Rich Fen') = 'Nutrient Rich Fen'")
rsf.data.veg$wetland_demars <- recode (rsf.data.veg$wetland_demars,
                                       "c ('Shrub Swamp', 'Hardwood Swamp', 'Mixedwood Swamp') = 'Deciduous Swamp'")
rsf.data.veg$wetland_demars <- recode (rsf.data.veg$wetland_demars,
                                       "c ('Upland Other', 'Cloud Shadow', 'Anthropogenic', 'Burn', 'Aquatic Bed', 'Cloud', 'Mountain', 'Agriculture', 'Mudflats', 'Open Water', 'Meadow Marsh', 'Emergent Marsh', 'Cutblock') = 'Other'")
rsf.data.veg$wetland_demars <- recode (rsf.data.veg$wetland_demars,
                                       "c ('Upland Deciduous', 'Upland Mixedwood') = 'Upland Deciduous'")
rsf.data.veg$wetland_demars <- recode (rsf.data.veg$wetland_demars,
                                       "c ('Upland Deciduous', 'Upland Mixedwood') = 'Upland Deciduous'")

########################################
### BUILD COMBO MODEL RSF DATASETS  ###
######################################

rsf.data.combo <- rsf.data.terrain.water [, c (1:9, 13:15)]
rm (rsf.data.terrain.water)
gc ()
rsf.data.combo <- dplyr::full_join (rsf.data.combo, 
                                    rsf.data.human.dist [, c (9:14, 26, 21:23)],
                                    by = "ptID")
rm (rsf.data.human.dist)
gc ()
rsf.data.combo <- dplyr::full_join (rsf.data.combo, 
                                    rsf.data.natural.dist [, c (9:14)],
                                    by = "ptID")
rm (rsf.data.natural.dist)
gc ()
rsf.data.combo <- dplyr::full_join (rsf.data.combo, 
                                    rsf.data.climate.annual [, c (9, 19, 11, 15)],
                                    by = "ptID")
rm (rsf.data.climate.annual)
gc ()
rsf.data.combo <- dplyr::full_join (rsf.data.combo, 
                                    rsf.data.climate.winter [, c (9, 12, 14)],
                                    by = "ptID")
rm (rsf.data.climate.winter)
gc ()
rsf.data.combo <- dplyr::full_join (rsf.data.combo, 
                                    rsf.data.veg [, c (9:10, 18:24, 44)],
                                    by = "ptID")
rm (rsf.data.veg)
gc ()

rsf.data.combo.du6.lw <- rsf.data.combo %>%
                          dplyr::filter (du == "du6") %>%
                          dplyr::filter (season == "LateWinter")

# group cutblock ages together, as per forest cutblcok model results
rsf.data.combo.du6.lw <- dplyr::mutate (rsf.data.combo.du6.lw, distance_to_cut_10yoorOver = pmin (distance_to_cut_10to29yo, distance_to_cut_30orOveryo))
rsf.data.combo.du6.lw <- rsf.data.combo.du6.lw %>% 
                          filter (!is.na (wetland_demars))
rsf.data.combo.du6.lw$bec_label <- relevel (rsf.data.combo.du6.lw$bec_label,
                                            ref = "BWBSmk")
rsf.data.combo.du6.lw$wetland_demars <- relevel (rsf.data.combo.du6.lw$wetland_demars,
                                                 ref = "Upland Conifer") # upland confier as referencce, as per Demars 2018
write.csv (rsf.data.combo.du6.lw, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du6_lw.csv")


#######################
### FITTING MODELS ###
#####################


#=================================
# Terrain and Water Models
#=================================
rsf.data.terrain.water.du6.lw <- rsf.data.terrain.water %>%
                                  dplyr::filter (du == "du6") %>%
                                  dplyr::filter (season == "LateWinter")
rsf.data.terrain.water.du6.lw$soil_parent_material_name <- relevel (rsf.data.terrain.water.du6.lw$soil_parent_material_name,
                                                                    ref = "Till")
### OUTLIERS ###
ggplot (rsf.data.terrain.water.du6.lw, aes (x = pttype, y = slope)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Late Winter Slope at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Slope")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_lw_slope.png")

####
rsf.data.terrain.water.du6.lw <- rsf.data.terrain.water.du6.lw %>%
                                  filter (slope < 75) # remove outlier
####
ggplot (rsf.data.terrain.water.du6.lw, aes (x = pttype, y = distance_to_lake)) +
            geom_boxplot (outlier.colour = "red") +
            labs (title = "Boxplot DU6, Late Winter Distance to Lake at Available (0) and Used (1) Locations",
                  x = "Available (0) and Used (1) Locations",
                  y = "Distance to Lake")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_lw_dist_lake.png")
ggplot (rsf.data.terrain.water.du6.lw, aes (x = pttype, y = distance_to_watercourse)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Watercourse at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Watercourse")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_lw_dist_watercourse.png")

### HISTOGRAMS ###
ggplot (rsf.data.terrain.water.du6.lw, aes (x = slope, fill = pttype)) + 
          geom_histogram (position = "dodge", binwidth = 5) +
          labs (title = "Histogram DU6, Late Winter Slope at Available (0) and Used (1) Locations",
                x = "Slope",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_lw_slope.png")
ggplot (rsf.data.terrain.water.du6.lw, aes (x = distance_to_lake, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 200) +
        labs (title = "Histogram DU6, Late Winter Distance to Lake at Available (0) and Used (1) Locations",
              x = "Distance to Lake",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_lw_dist_lake.png")
ggplot (rsf.data.terrain.water.du6.lw, aes (x = distance_to_watercourse, fill = pttype)) + 
          geom_histogram (position = "dodge", binwidth = 200) +
          labs (title = "Histogram DU6, Late Winter Distance to Watercourse at Available (0) and Used (1) Locations",
                x = "Distance to Watercourse",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_lw_dist_watercourse.png")

### CORRELATION ###
corr.terrain.water.du6.lw <- rsf.data.terrain.water.du6.lw [c (13:15)]
corr.terrain.water.du6.lw <- round (cor (corr.terrain.water.du6.lw, method = "spearman"), 3)
ggcorrplot (corr.terrain.water.du6.lw, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Terrain and Water Resource Selection Function Model
            Covariate Correlations for DU6, Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_terrain_water_du6_lw.png")

### VIF ###
glm.terrain.du6.lw <- glm (pttype ~ slope + distance_to_lake +
                                    distance_to_watercourse + soil_parent_material_name, 
                            data = rsf.data.terrain.water.du6.lw,
                            family = binomial (link = 'logit'))
car::vif (glm.terrain.du6.lw)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

### Generalized Linear Mixed Models (GLMMs) ###
# standardize covariates  (helps with model convergence)
rsf.data.terrain.water.du6.lw$std.elevation <- (rsf.data.terrain.water.du6.lw$elevation - 
                                                  mean (rsf.data.terrain.water.du6.lw$elevation)) / 
                                                  sd (rsf.data.terrain.water.du6.lw$elevation)
rsf.data.terrain.water.du6.lw$std.easting <- (rsf.data.terrain.water.du6.lw$easting - 
                                                  mean (rsf.data.terrain.water.du6.lw$easting)) / 
                                                  sd (rsf.data.terrain.water.du6.lw$easting)
rsf.data.terrain.water.du6.lw$std.northing <- (rsf.data.terrain.water.du6.lw$northing - 
                                                mean (rsf.data.terrain.water.du6.lw$northing)) / 
                                                sd (rsf.data.terrain.water.du6.lw$northing)
rsf.data.terrain.water.du6.lw$std.slope <- (rsf.data.terrain.water.du6.lw$slope - 
                                                 mean (rsf.data.terrain.water.du6.lw$slope)) / 
                                                  sd (rsf.data.terrain.water.du6.lw$slope)
rsf.data.terrain.water.du6.lw$std.distance_to_lake <- (rsf.data.terrain.water.du6.lw$distance_to_lake - 
                                                        mean (rsf.data.terrain.water.du6.lw$distance_to_lake)) / 
                                                        sd (rsf.data.terrain.water.du6.lw$distance_to_lake)
rsf.data.terrain.water.du6.lw$std.distance_to_watercourse <- (rsf.data.terrain.water.du6.lw$distance_to_watercourse - 
                                                              mean (rsf.data.terrain.water.du6.lw$distance_to_watercourse)) / 
                                                              sd (rsf.data.terrain.water.du6.lw$distance_to_watercourse)

## SLOPE ##
model.lme4.du6.lw.slope <- glmer (pttype ~ std.slope + (1 | uniqueID), 
                                   data = rsf.data.terrain.water.du6.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Late Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "Slope"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du6.lw.slope)

## DISTANCE TO LAKE ##
model.lme4.du6.lw.lake <- glmer (pttype ~ std.distance_to_lake + (1 | uniqueID), 
                                  data = rsf.data.terrain.water.du6.lw, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Late Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "Dist. to Lake"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du6.lw.lake)

## DISTANCE TO WATERCOURSE ##
model.lme4.du6.lw.wc <- glmer (pttype ~ std.distance_to_watercourse  + 
                                          (1 | uniqueID), 
                                 data = rsf.data.terrain.water.du6.lw, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Late Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "Dist. to Watercourse"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du6.lw.wc)

## SLOPE AND DISTANCE TO LAKE ##
model.lme4.du6.lw.slope.lake <- update (model.lme4.du6.lw.slope,
                                         . ~ . + std.distance_to_lake) 
# AIC
table.aic [4, 1] <- "DU6"
table.aic [4, 2] <- "Late Winter"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "Slope, Dist. to Lake"
table.aic [4, 5] <- "(1 | UniqueID)"
table.aic [4, 6] <-  AIC (model.lme4.du6.lw.slope.lake) 

## SLOPE AND DISTANCE TO WATERCOURSE ##
model.lme4.du6.lw.slope.water <- update (model.lme4.du6.lw.slope,
                                         . ~ . + std.distance_to_watercourse) 
# AIC
table.aic [5, 1] <- "DU6"
table.aic [5, 2] <- "Late Winter"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "Slope, Dist. to Watercourse"
table.aic [5, 5] <- "(1 | UniqueID)"
table.aic [5, 6] <-  AIC (model.lme4.du6.lw.slope.water) 

## DISTANCE TO LAKE AND WATERCOURSE ##
model.lme4.du6.lw.lake.water <- update (model.lme4.du6.lw.lake,
                                        . ~ . + std.distance_to_watercourse)
# AIC
table.aic [6, 1] <- "DU6"
table.aic [6, 2] <- "Late Winter"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "Dist. to Lake, Dist. to Watercourse"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <-  AIC (model.lme4.du6.lw.lake.water)

## SLOPE, DISTANCE TO LAKE AND DISTANCE TO WATERCOURSE ##
model.lme4.du6.lw.slope.lake.wc <- update (model.lme4.du6.lw.slope.lake,
                                            . ~ . + std.distance_to_watercourse) 
# AIC
table.aic [7, 1] <- "DU6"
table.aic [7, 2] <- "Late Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "Slope, Dist. to Lake, Dist. to Watercourse"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du6.lw.slope.lake.wc) 

## AIC comparison of MODELS ## 
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:7, 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:7, 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:7, 6])))),
                    (exp (-0.5 * (table.aic [4, 6] - min (table.aic [1:7, 6])))),
                    (exp (-0.5 * (table.aic [5, 6] - min (table.aic [1:7, 6])))),
                    (exp (-0.5 * (table.aic [6, 6] - min (table.aic [1:7, 6])))),
                    (exp (-0.5 * (table.aic [7, 6] - min (table.aic [1:7, 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:7, 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:7, 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:7, 6])))) / sum (list.aic.like), 3)
table.aic [4, 7] <- round ((exp (-0.5 * (table.aic [4, 6] - min (table.aic [1:7, 6])))) / sum (list.aic.like), 3)
table.aic [5, 7] <- round ((exp (-0.5 * (table.aic [5, 6] - min (table.aic [1:7, 6])))) / sum (list.aic.like), 3)
table.aic [6, 7] <- round ((exp (-0.5 * (table.aic [6, 6] - min (table.aic [1:7, 6])))) / sum (list.aic.like), 3)
table.aic [7, 7] <- round ((exp (-0.5 * (table.aic [7, 6] - min (table.aic [1:7, 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\late_winter\\table_aic_terrain_water.csv", sep = ",")

#=================================
# Human Disturbance Models
#=================================
rsf.data.human.dist.du6.lw <- rsf.data.human.dist %>%
                                    dplyr::filter (du == "du6") %>%
                                    dplyr::filter (season == "LateWinter")

# group cutblock ages together, as per forest cutblcok model results
rsf.data.human.dist.du6.lw <- dplyr::mutate (rsf.data.human.dist.du6.lw, distance_to_cut_10yoorOver = pmin (distance_to_cut_10to29yo, distance_to_cut_30orOveryo))

### OUTLIERS ###
ggplot (rsf.data.human.dist.du6.lw, aes (x = pttype, y = distance_to_cut_1to4yo)) +
        geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Cutblocks 1 to 4 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_lw_distcut1to4.png")
ggplot (rsf.data.human.dist.du6.lw, aes (x = pttype, y = distance_to_cut_5to9yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Cutblocks 5 to 9 Years Old\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_lw_distcut5to9.png")
ggplot (rsf.data.human.dist.du6.lw, aes (x = pttype, y = distance_to_cut_10yoorOver)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Cutblocks over 10 Years Old\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_lw_distcut_over10.png")
ggplot (rsf.data.human.dist.du6.lw, aes (x = pttype, y = distance_to_paved_road)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Paved Road\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Paved Road")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_lw_dist_pvd_rd.png")
ggplot (rsf.data.human.dist.du6.lw, aes (x = pttype, y = distance_to_resource_road)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Resource Road\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Resource Road")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_lw_dist_resource_rd.png")
ggplot (rsf.data.human.dist.du6.lw, aes (x = pttype, y = distance_to_agriculture)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Agriculture\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Agriculture")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_lw_dist_ag.png")
ggplot (rsf.data.human.dist.du6.lw, aes (x = pttype, y = distance_to_mines)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Mine\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Mine")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_lw_dist_mine.png")
ggplot (rsf.data.human.dist.du6.lw, aes (x = pttype, y = distance_to_pipeline)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Pipeline\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Pipeline")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_lw_dist_pipe.png")
ggplot (rsf.data.human.dist.du6.lw, aes (x = pttype, y = distance_to_wells)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Well\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Well")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_lw_dist_well.png")

### HISTOGRAMS ###
ggplot (rsf.data.human.dist.du6.lw, aes (x = distance_to_cut_1to4yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 5) +
  labs (title = "Histogram DU6, Late Winter Distance to Cutblock 1 to 4 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Distance to Cutblock",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_lw_dist_cut_1to4.png")
ggplot (rsf.data.human.dist.du6.lw, aes (x = distance_to_cut_5to9yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 5) +
  labs (title = "Histogram DU6, Late Winter Distance to Cutblock 5 to 9 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Distance to Cutblock",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_lw_dist_cut_5to9.png")
ggplot (rsf.data.human.dist.du6.lw, aes (x = distance_to_cut_10yoorOver, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 5) +
  labs (title = "Histogram DU6, Late Winter Distance to Cutblock over 10 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Distance to Cutblock",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_lw_dist_cut_over10.png")
ggplot (rsf.data.human.dist.du6.lw, aes (x = distance_to_paved_road, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Late Winter Distance to Paved Road\
                at Available (0) and Used (1) Locations",
        x = "Distance to Paved Road",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_lw_dist_pvd_rd.png")
ggplot (rsf.data.human.dist.du6.lw, aes (x = distance_to_resource_road, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Late Winter Distance to Resource Road\
                  at Available (0) and Used (1) Locations",
        x = "Distance to Resource Road",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_lw_dist_res_rd.png")
ggplot (rsf.data.human.dist.du6.lw, aes (x = distance_to_agriculture, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Late Winter Distance to Agriculture\
                  at Available (0) and Used (1) Locations",
        x = "Distance to Agriculture",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_lw_dist_ag.png")
ggplot (rsf.data.human.dist.du6.lw, aes (x = distance_to_mines, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Late Winter Distance to Mine at Available (0) and Used (1) Locations",
        x = "Distance to Mine",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_lw_dist_mine.png")
ggplot (rsf.data.human.dist.du6.lw, aes (x = distance_to_pipeline, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Late Winter Distance to Pipeline at\
                 Available (0) and Used (1) Locations",
        x = "Distance to Pipeline",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_lw_dist_pipe.png")
ggplot (rsf.data.human.dist.du6.lw, aes (x = distance_to_wells, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Late Winter Distance to Well at\
                 Available (0) and Used (1) Locations",
        x = "Distance to Pipeline",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_lw_dist_well.png")

### CORRELATION ###
corr.human.dist.du6.lw <- rsf.data.human.dist.du6.lw [c (10:11, 27, 14, 26, 20:24)]
corr.human.dist.du6.lw <- round (cor (corr.human.dist.du6.lw, method = "spearman"), 3)
ggcorrplot (corr.human.dist.du6.lw, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Human Disturbance Resource Selection Function Model
            Covariate Correlations for DU6, Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_human_dist_du6_lw.png")

### VIF ###
glm.human.du6.lw <- glm (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                                  distance_to_cut_10yoorOver + distance_to_paved_road +
                                  distance_to_resource_road + distance_to_mines +
                                  distance_to_pipeline, 
                           data = rsf.data.human.dist.du6.lw,
                           family = binomial (link = 'logit'))
car::vif (glm.human.du6.lw)

### Build an AIC and AUC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

##############################################
### Generalized Linear Mixed Models (GLMMs) #
############################################
# standardize covariates  (helps with model convergence)
rsf.data.human.dist.du6.lw$std.distance_to_cut_1to4yo <- (rsf.data.human.dist.du6.lw$distance_to_cut_1to4yo - mean (rsf.data.human.dist.du6.lw$distance_to_cut_1to4yo)) / sd (rsf.data.human.dist.du6.lw$distance_to_cut_1to4yo)
rsf.data.human.dist.du6.lw$std.distance_to_cut_5to9yo <- (rsf.data.human.dist.du6.lw$distance_to_cut_5to9yo - mean (rsf.data.human.dist.du6.lw$distance_to_cut_5to9yo)) / sd (rsf.data.human.dist.du6.lw$distance_to_cut_5to9yo)
rsf.data.human.dist.du6.lw$std.distance_to_cut_10yoorOver <- (rsf.data.human.dist.du6.lw$distance_to_cut_10yoorOver - mean (rsf.data.human.dist.du6.lw$distance_to_cut_10yoorOver)) / sd (rsf.data.human.dist.du6.lw$distance_to_cut_10yoorOver)
rsf.data.human.dist.du6.lw$std.distance_to_paved_road <- (rsf.data.human.dist.du6.lw$distance_to_paved_road - mean (rsf.data.human.dist.du6.lw$distance_to_paved_road)) / sd (rsf.data.human.dist.du6.lw$distance_to_paved_road)
rsf.data.human.dist.du6.lw$std.distance_to_resource_road <- (rsf.data.human.dist.du6.lw$distance_to_resource_road - mean (rsf.data.human.dist.du6.lw$distance_to_resource_road)) / sd (rsf.data.human.dist.du6.lw$distance_to_resource_road)
rsf.data.human.dist.du6.lw$std.distance_to_mines <- (rsf.data.human.dist.du6.lw$distance_to_mines - mean (rsf.data.human.dist.du6.lw$distance_to_mines)) / sd (rsf.data.human.dist.du6.lw$distance_to_mines)
rsf.data.human.dist.du6.lw$std.distance_to_pipeline <- (rsf.data.human.dist.du6.lw$distance_to_pipeline - mean (rsf.data.human.dist.du6.lw$distance_to_pipeline)) / sd (rsf.data.human.dist.du6.lw$distance_to_pipeline)

## DISTANCE TO CUTBLOCK ##
model.lme4.du6.lw.cutblock <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                                              std.distance_to_cut_10yoorOver + (1 | uniqueID), 
                                      data = rsf.data.human.dist.du6.lw, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Late Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "DC1to4, DC5to9, DCover9"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du6.lw.cutblock)

## DISTANCE TO ROAD ##
model.lme4.du6.lw.road <- glmer (pttype ~ std.distance_to_paved_road + 
                                          std.distance_to_resource_road + (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.lw, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Late Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "DPR, DRR"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du6.lw.road)

## DISTANCE TO MINE ##
model.lme4.du6.lw.mine <- glmer (pttype ~ std.distance_to_mines + (1 | uniqueID), 
                                 data = rsf.data.human.dist.du6.lw, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Late Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "DMine"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du6.lw.mine)

## DISTANCE TO PIPELINE ##
model.lme4.du6.lw.pipe <- glmer (pttype ~ std.distance_to_pipeline + (1 | uniqueID), 
                                 data = rsf.data.human.dist.du6.lw, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [4, 1] <- "DU6"
table.aic [4, 2] <- "Late Winter"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "DPipeline"
table.aic [4, 5] <- "(1 | UniqueID)"
table.aic [4, 6] <-  AIC (model.lme4.du6.lw.pipe)

## DISTANCE TO CUTBLOCK and DISTANCE TO ROAD ##
model.lme4.du6.lw.cut.road <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                              std.distance_to_cut_5to9yo + 
                                              std.distance_to_cut_10yoorOver + 
                                              std.distance_to_paved_road +
                                              std.distance_to_resource_road +
                                              (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.lw, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [5, 1] <- "DU6"
table.aic [5, 2] <- "Late Winter"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR"
table.aic [5, 5] <- "(1 | UniqueID)"
table.aic [5, 6] <-  AIC (model.lme4.du6.lw.cut.road)

## DISTANCE TO CUTBLOCK and DISTANCE TO MINE ##
model.lme4.du6.lw.cut.mine <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                               std.distance_to_cut_5to9yo + 
                                               std.distance_to_cut_10yoorOver + 
                                               std.distance_to_mines +
                                               (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.lw, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [6, 1] <- "DU6"
table.aic [6, 2] <- "Late Winter"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "DC1to4, DC5to9, DCover9, DMine"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <-  AIC (model.lme4.du6.lw.cut.mine)

## DISTANCE TO CUTBLOCK and DISTANCE TO PIPELINE ##
model.lme4.du6.lw.cut.pipe <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                               std.distance_to_cut_5to9yo + 
                                               std.distance_to_cut_10yoorOver + 
                                               std.distance_to_pipeline +
                                               (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.lw, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [7, 1] <- "DU6"
table.aic [7, 2] <- "Late Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "DC1to4, DC5to9, DCover9, DPipeline"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du6.lw.cut.pipe)

## DISTANCE TO ROAD AND DISTANCE TO MINE ##
model.lme4.du6.lw.road.mine <- glmer (pttype ~ std.distance_to_paved_road + 
                                                std.distance_to_resource_road + 
                                                std.distance_to_mines +
                                                (1 | uniqueID), 
                                       data = rsf.data.human.dist.du6.lw, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [8, 1] <- "DU6"
table.aic [8, 2] <- "Late Winter"
table.aic [8, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [8, 4] <- "DPR, DRR, DMine"
table.aic [8, 5] <- "(1 | UniqueID)"
table.aic [8, 6] <-  AIC (model.lme4.du6.lw.road.mine)

## DISTANCE TO ROAD AND DISTANCE TO PIPELINE ##
model.lme4.du6.lw.road.pipe <- glmer (pttype ~ std.distance_to_paved_road + 
                                                std.distance_to_resource_road + 
                                                std.distance_to_pipeline +
                                                (1 | uniqueID), 
                                      data = rsf.data.human.dist.du6.lw, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [9, 1] <- "DU6"
table.aic [9, 2] <- "Late Winter"
table.aic [9, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [9, 4] <- "DPR, DRR, DPipeline"
table.aic [9, 5] <- "(1 | UniqueID)"
table.aic [9, 6] <-  AIC (model.lme4.du6.lw.road.pipe)

## DISTANCE TO MINE AND DISTANCE TO PIPELINE ##
model.lme4.du6.lw.mine.pipe <- glmer (pttype ~ std.distance_to_mines + 
                                               std.distance_to_pipeline +
                                               (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.lw, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [10, 1] <- "DU6"
table.aic [10, 2] <- "Late Winter"
table.aic [10, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [10, 4] <- "DMine, DPipeline"
table.aic [10, 5] <- "(1 | UniqueID)"
table.aic [10, 6] <-  AIC (model.lme4.du6.lw.mine.pipe)

## DISTANCE TO CUTBLOCK, DISTANCE TO ROAD, DISTANCE TO MINE ##
model.lme4.du6.lw.cut.road.mine <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                   std.distance_to_cut_5to9yo + 
                                                   std.distance_to_cut_10yoorOver + 
                                                   std.distance_to_paved_road +
                                                   std.distance_to_resource_road +
                                                   std.distance_to_mines +
                                                   (1 | uniqueID), 
                                         data = rsf.data.human.dist.du6.lw, 
                                         family = binomial (link = "logit"),
                                         verbose = T) 
# AIC
table.aic [11, 1] <- "DU6"
table.aic [11, 2] <- "Late Winter"
table.aic [11, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [11, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, DMine"
table.aic [11, 5] <- "(1 | UniqueID)"
table.aic [11, 6] <-  AIC (model.lme4.du6.lw.cut.road.mine)

## DISTANCE TO CUTBLOCK, DISTANCE TO ROAD, DISTANCE TO PIPELINE ##
model.lme4.du6.lw.cut.road.pipe <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                    std.distance_to_cut_5to9yo + 
                                                    std.distance_to_cut_10yoorOver + 
                                                    std.distance_to_paved_road +
                                                    std.distance_to_resource_road +
                                                    std.distance_to_pipeline +
                                                    (1 | uniqueID), 
                                          data = rsf.data.human.dist.du6.lw, 
                                          family = binomial (link = "logit"),
                                          verbose = T) 
# AIC
table.aic [12, 1] <- "DU6"
table.aic [12, 2] <- "Late Winter"
table.aic [12, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [12, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, DPipeline"
table.aic [12, 5] <- "(1 | UniqueID)"
table.aic [12, 6] <-  AIC (model.lme4.du6.lw.cut.road.pipe)


## DISTANCE TO CUTBLOCK, DISTANCE TO MINE, DISTANCE TO PIPELINE ##
model.lme4.du6.lw.cut.mine.pipe <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                   std.distance_to_cut_5to9yo + 
                                                   std.distance_to_cut_10yoorOver + 
                                                   std.distance_to_mines +
                                                   std.distance_to_pipeline +
                                                   (1 | uniqueID), 
                                           data = rsf.data.human.dist.du6.lw, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [13, 1] <- "DU6"
table.aic [13, 2] <- "Late Winter"
table.aic [13, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [13, 4] <- "DC1to4, DC5to9, DCover9, DMine, DPipeline"
table.aic [13, 5] <- "(1 | UniqueID)"
table.aic [13, 6] <-  AIC (model.lme4.du6.lw.cut.mine.pipe)

## DISTANCE TO ROAD, DISTANCE TO MINE, DISTANCE TO PIPELINE ##
model.lme4.du6.lw.road.mine.pipe <- glmer (pttype ~ std.distance_to_paved_road + 
                                                    std.distance_to_resource_road + 
                                                    std.distance_to_mines +
                                                    std.distance_to_pipeline +
                                                    (1 | uniqueID), 
                                            data = rsf.data.human.dist.du6.lw, 
                                            family = binomial (link = "logit"),
                                            verbose = T) 
# AIC
table.aic [14, 1] <- "DU6"
table.aic [14, 2] <- "Late Winter"
table.aic [14, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [14, 4] <- "DPR, DRR, DMine, DPipeline"
table.aic [14, 5] <- "(1 | UniqueID)"
table.aic [14, 6] <-  AIC (model.lme4.du6.lw.road.mine.pipe)

## DISTANCE TO CUTBLOCK, DISTANCE TO ROAD, DISTANCE TO MINE, DISTANCE TO PIPELINE ##
model.lme4.du6.lw.cut.road.mine.pipe <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                        std.distance_to_cut_5to9yo + 
                                                        std.distance_to_cut_10yoorOver + 
                                                        std.distance_to_paved_road +
                                                        std.distance_to_resource_road +
                                                        std.distance_to_mines +
                                                        std.distance_to_pipeline +
                                                        (1 | uniqueID), 
                                              data = rsf.data.human.dist.du6.lw, 
                                              family = binomial (link = "logit"),
                                              verbose = T) 
# AIC
table.aic [15, 1] <- "DU6"
table.aic [15, 2] <- "Late Winter"
table.aic [15, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [15, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, DMine, DPipeline"
table.aic [15, 5] <- "(1 | UniqueID)"
table.aic [15, 6] <-  AIC (model.lme4.du6.lw.cut.road.mine.pipe)

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

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\late_winter\\table_aic_human_disturb.csv", sep = ",")

#=================================
# Natural Disturbance Models
#=================================
rsf.data.natural.dist.du6.lw <- rsf.data.natural.dist %>%
                                    dplyr::filter (du == "du6") %>%
                                    dplyr::filter (season == "LateWinter")

### CORRELATION ###
corr.rsf.data.natural.dist.du6.lw <- rsf.data.natural.dist.du6.lw [c (10:14)]
corr.rsf.data.natural.dist.du6.lw <- round (cor (corr.rsf.data.natural.dist.du6.lw, method = "spearman"), 3)
ggcorrplot (corr.rsf.data.natural.dist.du6.lw, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Fire and Beetle Disturbance Selection Function Model
            Covariate Correlations for DU6, Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_natrual_disturb_du6_lw.png")

### VIF ###
glm.nat.disturb.du6.lw <- glm (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                                        fire_1to5yo + fire_6to25yo + fire_over25yo, 
                               data = rsf.data.natural.dist.du6.lw,
                               family = binomial (link = 'logit'))
car::vif (glm.nat.disturb.du6.lw)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

## FIRE ##
model.lme4.du6.lw.fire <- glmer (pttype ~ fire_1to5yo + fire_6to25yo +
                                          fire_over25yo + (1 | uniqueID), 
                                 data = rsf.data.natural.dist.du6.lw, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Late Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "Fire1to5, Fire6to25, Fireover25"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du6.lw.fire)

## BEETLE ##
model.lme4.du6.lw.beetle <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo +
                                            (1 | uniqueID), 
                                   data = rsf.data.natural.dist.du6.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Late Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "Beetle1to5, Beetle6to9"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du6.lw.beetle)

## FIRE AND BEETLE ##
model.lme4.du6.lw.fire.beetle <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo + 
                                                 beetle_1to5yo + beetle_6to9yo +
                                                 (1 | uniqueID), 
                                       data = rsf.data.natural.dist.du6.lw, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Late Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "Fire1to5, Fire6to25, Fireover25, Beetle1to5, Beetle6to9"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <- AIC (model.lme4.du6.lw.fire.beetle)

## AIC comparison of MODELS ## 
table.aic$AIC <- as.numeric (table.aic$AIC)
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\late_winter\\table_aic_natural_disturb.csv", sep = ",")

#=================================
# ANNUAL CLIMATE Models
#=================================
rsf.data.climate.annual.du6.lw <- rsf.data.climate.annual %>%
                                            dplyr::filter (du == "du6") %>%
                                            dplyr::filter (season == "LateWinter")
rsf.data.climate.annual.du6.lw$pttype <- as.factor (rsf.data.climate.annual.du6.lw$pttype)

### OUTLIERS ###
ggplot (rsf.data.climate.annual.du6.lw, aes (x = pttype, y = frost_free_start_julian)) +
            geom_boxplot (outlier.colour = "red") +
            labs (title = "Boxplot DU6, Late Winter, Annual Frost Free Period Julian Start Day\ 
                  at Available (0) and Used (1) Locations",
                  x = "Available (0) and Used (1) Locations",
                  y = "Julian Day")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_lw_frost_free_start.png")
ggplot (rsf.data.climate.annual.du6.lw, aes (x = pttype, y = growing_degree_days)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Late Winter, Annual Growing Degree Days \
              at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Number of Days")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_lw_grow_deg_day.png")
ggplot (rsf.data.climate.annual.du6.lw, aes (x = pttype, y = frost_free_end_julian)) +
          geom_boxplot (outlier.colour = "red") +
          labs (title = "Boxplot DU6, Late Winter, Annual Frost Free End Julian Day \
                at Available (0) and Used (1) Locations",
                x = "Available (0) and Used (1) Locations",
                y = "Julian Day")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_lw_frost_free_end.png")
ggplot (rsf.data.climate.annual.du6.lw, aes (x = pttype, y = frost_free_period)) +
          geom_boxplot (outlier.colour = "red") +
          labs (title = "Boxplot DU6, Late Winter, Annual Frost Free Period \
                        at Available (0) and Used (1) Locations",
                x = "Available (0) and Used (1) Locations",
                y = "Number of Days")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_lw_frost_free_period.png")
ggplot (rsf.data.climate.annual.du6.lw, aes (x = pttype, y = mean_annual_ppt)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Late Winter, Mean Annual Precipitation \
                              at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Precipitation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_lw_mean_annual_ppt.png")
ggplot (rsf.data.climate.annual.du6.lw, aes (x = pttype, y = mean_annual_temp)) +
          geom_boxplot (outlier.colour = "red") +
          labs (title = "Boxplot DU6, Late Winter, Mean Annual Temperature \
                                      at Available (0) and Used (1) Locations",
                x = "Available (0) and Used (1) Locations",
                y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_lw_mean_annual_temp.png")
ggplot (rsf.data.climate.annual.du6.lw, aes (x = pttype, y = mean_coldest_month_temp)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Late Winter, Mean Annual Coldest Month Temperature \
                                            at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_lw_mean_cold_mth_temp.png")
ggplot (rsf.data.climate.annual.du6.lw, aes (x = pttype, y = mean_warmest_month_temp)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Late Winter, Mean Annual Warmest Month Temperature \
                                                  at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_lw_mean_warm_mth_temp.png")
ggplot (rsf.data.climate.annual.du6.lw, aes (x = pttype, y = ppt_as_snow_annual)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Late Winter, Mean Annual Precipitation as Snow \
                    at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Precipitation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_lw_mean_annual_pas.png")

### HISTOGRAMS ###
ggplot (rsf.data.climate.annual.du6.lw, aes (x = frost_free_start_julian, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU6, Late Winter, Frost Free Start Julian Day\
              at Available (0) and Used (1) Locations",
              x = "Julian Day",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_lw_frost_free_start.png")
ggplot (rsf.data.climate.annual.du6.lw, aes (x = growing_degree_days, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU6, Late Winter, Annual Growing Degree Days\
                    at Available (0) and Used (1) Locations",
              x = "Number of Days",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_lw_grow_deg_days.png")
ggplot (rsf.data.climate.annual.du6.lw, aes (x = frost_free_end_julian, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU6, Late Winter, Frost Free End Julian Day\
              at Available (0) and Used (1) Locations",
              x = "Julian Day",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_lw_frost_free_end.png")
ggplot (rsf.data.climate.annual.du6.lw, aes (x = frost_free_period, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU6, Late Winter, Frost Free Period\
                    at Available (0) and Used (1) Locations",
              x = "Number of Days",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_lw_frost_free_period.png")
ggplot (rsf.data.climate.annual.du6.lw, aes (x = mean_annual_ppt, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU6, Late Winter, Mean Annual Precipitation\
                          at Available (0) and Used (1) Locations",
              x = "Precipitation",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_lw_mean_annual_ppt.png")
ggplot (rsf.data.climate.annual.du6.lw, aes (x = mean_annual_temp, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU6, Late Winter, Mean Annual Temperature\
                                at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_lw_mean_annual_temp.png")
ggplot (rsf.data.climate.annual.du6.lw, aes (x = mean_coldest_month_temp, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU6, Late Winter, Mean Annual Coldest Month Temperature\
                       at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_lw_mean_annual_cold_mth_temp.png")
ggplot (rsf.data.climate.annual.du6.lw, aes (x = mean_warmest_month_temp, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU6, Late Winter, Mean Annual Warmest Month Temperature\
                             at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_lw_mean_annual_warm_mth_temp.png")
ggplot (rsf.data.climate.annual.du6.lw, aes (x = number_frost_free_days, fill = pttype)) + 
          geom_histogram (position = "dodge") +
          labs (title = "Histogram DU6, Late Winter, Annual Number of Frost Free Days\
                                     at Available (0) and Used (1) Locations",
                x = "Number of Days",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_lw_mean_frost_free_days.png")
ggplot (rsf.data.climate.annual.du6.lw, aes (x = ppt_as_snow_annual, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU6, Late Winter, Annual Precipitation as Snow\
              at Available (0) and Used (1) Locations",
              x = "Precipitation",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_lw_mean_pas.png")

### CORRELATION ###
corr.rsf.data.climate.annual.du6.lw <- rsf.data.climate.annual.du6.lw [c (11:20)]
corr.rsf.data.climate.annual.du6.lw <- round (cor (corr.rsf.data.climate.annual.du6.lw, method = "spearman"), 3)
ggcorrplot (corr.rsf.data.climate.annual.du6.lw, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Annual Climate Resource Selection Function Model
            Covariate Correlations for DU6, Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_annual_climate_du6_lw.png")

### VIF ###
glm.annual.climate.du6.lw <- glm (pttype ~ ppt_as_snow_annual + growing_degree_days + mean_annual_temp, 
                                   data = rsf.data.climate.annual.du6.lw,
                                   family = binomial (link = 'logit'))
car::vif (glm.annual.climate.du6.lw)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

# standardize covariates  (helps with model convergence)
rsf.data.climate.annual.du6.lw$std.ppt_as_snow_annual <- (rsf.data.climate.annual.du6.lw$ppt_as_snow_annual - mean (rsf.data.climate.annual.du6.lw$ppt_as_snow_annual)) / sd (rsf.data.climate.annual.du6.lw$ppt_as_snow_annual)
rsf.data.climate.annual.du6.lw$std.growing_degree_days <- (rsf.data.climate.annual.du6.lw$growing_degree_days - mean (rsf.data.climate.annual.du6.lw$growing_degree_days)) / sd (rsf.data.climate.annual.du6.lw$growing_degree_days)
rsf.data.climate.annual.du6.lw$std.mean_annual_temp <- (rsf.data.climate.annual.du6.lw$mean_annual_temp - mean (rsf.data.climate.annual.du6.lw$mean_annual_temp)) / sd (rsf.data.climate.annual.du6.lw$mean_annual_temp)

## PRECIPITATION AS SNOW ##
model.lme4.du6.lw.pas <- glmer (pttype ~ std.ppt_as_snow_annual + (1 | uniqueID), 
                                data = rsf.data.climate.annual.du6.lw, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Late Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "PaS"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du6.lw.pas)

## GROWING DEGREE DAYS ##
model.lme4.du6.lw.ggd <- glmer (pttype ~ std.growing_degree_days + (1 | uniqueID), 
                                data = rsf.data.climate.annual.du6.lw, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Late Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "GDD"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du6.lw.ggd)

## MEAN ANNUAL TEMPERATURE ##
model.lme4.du6.lw.mat <- glmer (pttype ~ std.mean_annual_temp + (1 | uniqueID), 
                                data = rsf.data.climate.annual.du6.lw, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Late Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "MAT"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du6.lw.mat)

## PRECIPITATION AS SNOW and GROWING DEGREE DAYS ##
model.lme4.du6.lw.pas.gdd <- glmer (pttype ~ std.ppt_as_snow_annual + std.growing_degree_days +
                                              (1 | uniqueID), 
                                    data = rsf.data.climate.annual.du6.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [4, 1] <- "DU6"
table.aic [4, 2] <- "Late Winter"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "PaS, GDD"
table.aic [4, 5] <- "(1 | UniqueID)"
table.aic [4, 6] <-  AIC (model.lme4.du6.lw.pas.gdd)

## PRECIPITATION AS SNOW and MEAN ANNUAL TEMP ##
model.lme4.du6.lw.pas.mat <- glmer (pttype ~ std.ppt_as_snow_annual + std.mean_annual_temp +
                                      (1 | uniqueID), 
                                    data = rsf.data.climate.annual.du6.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [5, 1] <- "DU6"
table.aic [5, 2] <- "Late Winter"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "PaS, MAT"
table.aic [5, 5] <- "(1 | UniqueID)"
table.aic [5, 6] <-  AIC (model.lme4.du6.lw.pas.mat)

## GROWING DEGREE DAYS and MEAN ANNUAL TEMP ##
model.lme4.du6.lw.ggd.mat <- glmer (pttype ~ std.growing_degree_days + std.mean_annual_temp +
                                             (1 | uniqueID), 
                                    data = rsf.data.climate.annual.du6.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [6, 1] <- "DU6"
table.aic [6, 2] <- "Late Winter"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "GDD, MAT"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <-  AIC (model.lme4.du6.lw.ggd.mat)

## PRECIPITATION AS SNOW, GROWING DEGREE DAYS, MEAN ANNUAL TEMP ##
model.lme4.du6.lw.pas.gdd.mat <- glmer (pttype ~ std.ppt_as_snow_annual + std.growing_degree_days +
                                                 std.mean_annual_temp +
                                                 (1 | uniqueID), 
                                        data = rsf.data.climate.annual.du6.lw, 
                                        family = binomial (link = "logit"),
                                        verbose = T) 
# AIC
table.aic [7, 1] <- "DU6"
table.aic [7, 2] <- "Late Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "PaS, GDD, MAT"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du6.lw.pas.gdd.mat)

## AIC comparison of MODELS ## 
table.aic$AIC <- as.numeric (table.aic$AIC)
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:7, 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:7, 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:7, 6])))),
                    (exp (-0.5 * (table.aic [4, 6] - min (table.aic [1:7, 6])))),
                    (exp (-0.5 * (table.aic [5, 6] - min (table.aic [1:7, 6])))),
                    (exp (-0.5 * (table.aic [6, 6] - min (table.aic [1:7, 6])))),
                    (exp (-0.5 * (table.aic [7, 6] - min (table.aic [1:7, 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:7, 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:7, 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:7, 6])))) / sum (list.aic.like), 3)
table.aic [4, 7] <- round ((exp (-0.5 * (table.aic [4, 6] - min (table.aic [1:7, 6])))) / sum (list.aic.like), 3)
table.aic [5, 7] <- round ((exp (-0.5 * (table.aic [5, 6] - min (table.aic [1:7, 6])))) / sum (list.aic.like), 3)
table.aic [6, 7] <- round ((exp (-0.5 * (table.aic [6, 6] - min (table.aic [1:7, 6])))) / sum (list.aic.like), 3)
table.aic [7, 7] <- round ((exp (-0.5 * (table.aic [7, 6] - min (table.aic [1:7, 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\late_winter\\table_aic_annual_climate.csv", sep = ",")


#=================================
# WINTER CLIMATE Models
#=================================
rsf.data.climate.winter.du6.lw <- rsf.data.climate.winter %>%
                                    dplyr::filter (du == "du6") %>%
                                    dplyr::filter (season == "LateWinter")
rsf.data.climate.winter.du6.lw$pttype <- as.factor (rsf.data.climate.winter.du6.lw$pttype)

### OUTLIERS ###
ggplot (rsf.data.climate.winter.du6.lw, aes (x = pttype, y = ppt_as_snow_winter)) +
            geom_boxplot (outlier.colour = "red") +
            labs (title = "Boxplot DU6, Late Winter, Precipitation as Snow\ 
                            at Available (0) and Used (1) Locations",
                  x = "Available (0) and Used (1) Locations",
                  y = "Precipitation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_winter_climate_du6_lw_ppt_as_snow.png")
ggplot (rsf.data.climate.winter.du6.lw, aes (x = pttype, y = ppt_winter)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Late Winter, Precipitation\ 
              at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Precipitation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_winter_climate_du6_lw_ppt.png")
ggplot (rsf.data.climate.winter.du6.lw, aes (x = pttype, y = temp_avg_winter)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Late Winter, Average Temperature\ 
              at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_winter_climate_du6_lw_temp_avg.png")
ggplot (rsf.data.climate.winter.du6.lw, aes (x = pttype, y = temp_max_winter)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Late Winter, Maximum Temperature\ 
                    at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_winter_climate_du6_lw_temp_max.png")
ggplot (rsf.data.climate.winter.du6.lw, aes (x = pttype, y = temp_min_winter)) +
          geom_boxplot (outlier.colour = "red") +
          labs (title = "Boxplot DU6, Late Winter, Minimum Temperature\ 
                            at Available (0) and Used (1) Locations",
                x = "Available (0) and Used (1) Locations",
                y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_winter_climate_du6_lw_temp_min.png")

### HISTOGRAMS ###
ggplot (rsf.data.climate.winter.du6.lw, aes (x = ppt_as_snow_winter, fill = pttype)) + 
          geom_histogram (position = "dodge", binwidth = 5) +
          labs (title = "Histogram DU6, Late Winter, Precipitation as Snow\
                at Available (0) and Used (1) Locations",
                x = "Precipitation",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_lw_pas.png")
ggplot (rsf.data.climate.winter.du6.lw, aes (x = ppt_winter, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU6, Late Winter, Precipitation\
                      at Available (0) and Used (1) Locations",
              x = "Precipitation",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_lw_ppt.png")
ggplot (rsf.data.climate.winter.du6.lw, aes (x = temp_avg_winter, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU6, Late Winter, Average Temperature\
                            at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_lw_temp_avg.png")
ggplot (rsf.data.climate.winter.du6.lw, aes (x = temp_max_winter, fill = pttype)) + 
          geom_histogram (position = "dodge") +
          labs (title = "Histogram DU6, Late Winter, Maximum Temperature\
                         at Available (0) and Used (1) Locations",
                x = "Temperature",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_lw_temp_max.png")
ggplot (rsf.data.climate.winter.du6.lw, aes (x = temp_min_winter, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU6, Late Winter, Minimum Temperature\
                               at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_lw_temp_min.png")

### CORRELATION ###
corr.climate.winter.du6.lw <- rsf.data.climate.winter.du6.lw [c (10, 12:16)] # frost free days all = 0
corr.climate.winter.du6.lw <- round (cor (corr.climate.winter.du6.lw, method = "spearman"), 3)
ggcorrplot (corr.climate.winter.du6.lw, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Winter Climate Resource Selection Function Model
            Covariate Correlations for DU6, Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_winter_climate_du6_lw.png")

### VIF ###
glm.winter.climate.du6.lw <- glm (pttype ~ ppt_as_snow_winter + temp_avg_winter, 
                                  data = rsf.data.climate.winter.du6.lw,
                                  family = binomial (link = 'logit'))
car::vif (glm.winter.climate.du6.lw)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

# standardize covariates  (helps with model convergence)
rsf.data.climate.winter.du6.lw$std.ppt_as_snow_winter <- (rsf.data.climate.winter.du6.lw$ppt_as_snow_winter - mean (rsf.data.climate.winter.du6.lw$ppt_as_snow_winter)) / sd (rsf.data.climate.winter.du6.lw$ppt_as_snow_winter)
rsf.data.climate.winter.du6.lw$std.temp_avg_winter <- (rsf.data.climate.winter.du6.lw$temp_avg_winter - mean (rsf.data.climate.winter.du6.lw$temp_avg_winter)) / sd (rsf.data.climate.winter.du6.lw$temp_avg_winter)

## PRECIPITATION AS SNOW ##
model.lme4.du6.lw.winter.pas <- glmer (pttype ~ std.ppt_as_snow_winter + (1 | uniqueID), 
                                data = rsf.data.climate.winter.du6.lw, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Late Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "WPaS"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du6.lw.winter.pas)

## AVERAGE TEMPERATURE ##
model.lme4.du6.lw.winter.temp <- glmer (pttype ~ std.temp_avg_winter + (1 | uniqueID), 
                                       data = rsf.data.climate.winter.du6.lw, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Late Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "WTemp"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du6.lw.winter.temp)

## PRECIPITATION AS SNOW and AVERAGE TEMPERATURE ##
model.lme4.du6.lw.winter.pas.temp <- glmer (pttype ~ std.ppt_as_snow_winter + std.temp_avg_winter +
                                                      (1 | uniqueID), 
                                       data = rsf.data.climate.winter.du6.lw, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Late Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "WPaS, WTemp"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du6.lw.winter.pas.temp)

## AIC comparison of MODELS ## 
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\late_winter\\table_aic_winter_climate.csv", sep = ",")

#=================================
# VEGETATION/FOREST Models
#=================================
rsf.data.veg.du6.lw <- rsf.data.veg %>%
                         dplyr::filter (du == "du6") %>%
                         dplyr::filter (season == "LateWinter")
rsf.data.veg.du6.lw$pttype <- as.factor (rsf.data.veg.du6.lw$pttype)

test <- rsf.data.veg.du6.lw %>% filter (is.na (wetland_class_du_boreal_name))
rsf.data.veg.du6.lw <- rsf.data.veg.du6.lw %>% 
                        filter (!is.na (wetland_class_du_boreal_name))

rsf.data.veg.du6.lw$bec_label <- relevel (rsf.data.veg.du6.lw$bec_label,
                                          ref = "BWBSmk")
rsf.data.veg.du6.lw$wetland_demars <- relevel (rsf.data.veg.du6.lw$wetland_demars,
                                                ref = "Upland Conifer") # upland confier as reference, as per Demars 2018


### OUTLIERS ###
ggplot (rsf.data.veg.du6.lw, aes (x = pttype, y = vri_basal_area)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter, Basal Area\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Basal Area of Trees")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du6_lw_basal_area.png")
ggplot (rsf.data.veg.du6.lw, aes (x = pttype, y = vri_bryoid_cover_pct)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter, Bryoid Cover\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Percent Cover")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du6_lw_bryoid_perc.png")
ggplot (rsf.data.veg.du6.lw, aes (x = pttype, y = vri_crown_closure)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter, Crown Closure\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Crown Closure")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du6_lw_crown_close.png")
ggplot (rsf.data.veg.du6.lw, aes (x = pttype, y = vri_herb_cover_pct)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter, Herbaceous Cover\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Percent Cover")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du6_lw_herb_cover.png")
ggplot (rsf.data.veg.du6.lw, aes (x = pttype, y = vri_live_volume)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter, Live Forest Stand Volume\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Volume")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du6_lw_live_volume.png")
ggplot (rsf.data.veg.du6.lw, aes (x = pttype, y = vri_proj_age)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter, Projected Forest Stand Age\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Age")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du6_lw_stand_age.png")
ggplot (rsf.data.veg.du6.lw, aes (x = pttype, y = vri_proj_height)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter, Projected Forest Stand Height\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Height")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du6_lw_stand_height.png")
ggplot (rsf.data.veg.du6.lw, aes (x = pttype, y = vri_shrub_crown_close)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter, Shrub Crown Closure\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Crown Closure")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du6_lw_shrub_closure.png")
ggplot (rsf.data.veg.du6.lw, aes (x = pttype, y = vri_shrub_height)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter, Shrub Height\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Height")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du6_lw_shrub_height.png")
ggplot (rsf.data.veg.du6.lw, aes (x = pttype, y = vri_site_index)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter, Site Index\ 
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Site Index")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_veg_du6_lw_site_index.png")

### HISTOGRAMS ###
ggplot (rsf.data.veg.du6.lw, aes (x = bec_label, fill = pttype)) + 
            geom_histogram (position = "dodge", stat = "count") +
            labs (title = "Histogram DU6, Late Winter, BEC Type\
                          at Available (0) and Used (1) Locations",
                  x = "Biogeclimatic Unit",
                  y = "Count") +
            scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_veg_du6_lw_bec.png")
ggplot (rsf.data.veg.du6.lw, aes (x = wetland_demars, fill = pttype)) + 
          geom_histogram (position = "dodge", stat = "count") +
          labs (title = "Histogram DU6, Late Winter, Wetland Type\
                                  at Available (0) and Used (1) Locations",
                x = "Wetland Type",
                y = "Count") +
          scale_fill_discrete (name = "Location Type") +
          theme (axis.text.x = element_text (angle = -90, hjust = 0))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_veg_du6_lw_wetland.png")


### CORRELATION ###
corr.veg.du6.lw <- rsf.data.veg.du6.lw [c (17:26)]
corr.veg.du6.lw <- round (cor (corr.veg.du6.lw, method = "spearman"), 3)
ggcorrplot (corr.veg.du6.lw, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Vegeation Resource Selection Function Model
            Covariate Correlations for DU6, Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_veg_du6_lw.png")

### VIF ###
glm.veg.du6.lw <- glm (pttype ~ bec_label + wetland_demars + vri_proj_height + vri_crown_closure + 
                                vri_bryoid_cover_pct + vri_herb_cover_pct + vri_proj_age + 
                                vri_shrub_crown_close, 
                       data = rsf.data.veg.du6.lw,
                       family = binomial (link = 'logit'))
car::vif (glm.veg.du6.lw)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

# standardize covariates  (helps with model convergence)
rsf.data.veg.du6.lw$std.vri_bryoid_cover_pct <- (rsf.data.veg.du6.lw$vri_bryoid_cover_pct - mean (rsf.data.veg.du6.lw$vri_bryoid_cover_pct)) / sd (rsf.data.veg.du6.lw$vri_bryoid_cover_pct)
rsf.data.veg.du6.lw$std.vri_herb_cover_pct <- (rsf.data.veg.du6.lw$vri_herb_cover_pct - mean (rsf.data.veg.du6.lw$vri_herb_cover_pct)) / sd (rsf.data.veg.du6.lw$vri_herb_cover_pct)
rsf.data.veg.du6.lw$std.vri_proj_age <- (rsf.data.veg.du6.lw$vri_proj_age - mean (rsf.data.veg.du6.lw$vri_proj_age)) / sd (rsf.data.veg.du6.lw$vri_proj_age)
rsf.data.veg.du6.lw$std.vri_shrub_crown_close <- (rsf.data.veg.du6.lw$vri_shrub_crown_close - mean (rsf.data.veg.du6.lw$vri_shrub_crown_close)) / sd (rsf.data.veg.du6.lw$vri_shrub_crown_close)
rsf.data.veg.du6.lw$std.vri_proj_height <- (rsf.data.veg.du6.lw$vri_proj_height - mean (rsf.data.veg.du6.lw$vri_proj_height)) / sd (rsf.data.veg.du6.lw$vri_proj_height)
rsf.data.veg.du6.lw$std.vri_crown_closure <- (rsf.data.veg.du6.lw$vri_crown_closure - mean (rsf.data.veg.du6.lw$vri_crown_closure)) / sd (rsf.data.veg.du6.lw$vri_crown_closure)


### CANDIDATE MODELS ###
## WETLAND, BEC ##
model.lme4.du6.lw.veg.wetland.bec <- glmer (pttype ~ wetland_demars + bec_label + 
                                              (1 | uniqueID), 
                                            data = rsf.data.veg.du6.lw, 
                                            family = binomial (link = "logit"),
                                            verbose = T) 
ss <- getME (model.lme4.du6.lw.veg.wetland.bec, c ("theta","fixef"))
model.lme4.du6.lw.veg.wetland.bec <- update (model.lme4.du6.lw.veg.wetland.bec, start = ss) # failed to converge, restart with parameter estimates

# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Late Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "Wetland, BEC"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du6.lw.veg.wetland.bec)

## FOOD ##
model.lme4.du6.lw.veg.food <- glmer (pttype ~ std.vri_shrub_crown_close + std.vri_bryoid_cover_pct + 
                                       std.vri_herb_cover_pct + (1 | uniqueID), 
                                     data = rsf.data.veg.du6.lw, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Late Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "ShrubClosure, BryoidCover, HerbCover"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du6.lw.veg.food)

## FOREST STAND ##
model.lme4.du6.lw.veg.forest <- glmer (pttype ~ std.vri_proj_age + std.vri_proj_height +
                                         std.vri_crown_closure + (1 | uniqueID), 
                                       data = rsf.data.veg.du6.lw, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Late Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "TreeAge, TreeHeight, TreeClosure"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du6.lw.veg.forest)

## WETLAND, BEC and FOOD ##
model.lme4.du6.lw.veg.wetland.bec.food <- glmer (pttype ~ wetland_demars + bec_label + 
                                                   std.vri_shrub_crown_close + 
                                                   std.vri_bryoid_cover_pct + 
                                                   std.vri_herb_cover_pct +
                                                   (1 | uniqueID), 
                                                 data = rsf.data.veg.du6.lw, 
                                                 family = binomial (link = "logit"),
                                                 verbose = T) 
ss <- getME (model.lme4.du6.lw.veg.wetland.bec.food, c ("theta","fixef"))
model.lme4.du6.lw.veg.wetland.bec.food <- update (model.lme4.du6.lw.veg.wetland.bec.food, start = ss) # failed to converge, restart with parameter estimates

# AIC
table.aic [4, 1] <- "DU6"
table.aic [4, 2] <- "Late Winter"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "Wetland, BEC, ShrubClosure, BryoidCover, HerbCover"
table.aic [4, 5] <- "(1 | UniqueID)"
table.aic [4, 6] <-  AIC (model.lme4.du6.lw.veg.wetland.bec.food)

## WETLAND, BEC and FOREST ##
model.lme4.du6.lw.veg.wetland.bec.forest <- glmer (pttype ~ wetland_demars + bec_label + 
                                                     std.vri_proj_age + 
                                                     std.vri_proj_height +
                                                     std.vri_crown_closure +
                                                     (1 | uniqueID), 
                                                   data = rsf.data.veg.du6.lw, 
                                                   family = binomial (link = "logit"),
                                                   verbose = T) 
ss <- getME (model.lme4.du6.lw.veg.wetland.bec.forest, c ("theta","fixef"))
model.lme4.du6.lw.veg.wetland.bec.forest <- update (model.lme4.du6.lw.veg.wetland.bec.forest, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [5, 1] <- "DU6"
table.aic [5, 2] <- "Late Winter"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "Wetland, BEC, TreeAge, TreeHeight, TreeClosure"
table.aic [5, 5] <- "(1 | UniqueID)"
table.aic [5, 6] <-  AIC (model.lme4.du6.lw.veg.wetland.bec.forest)

## FOOD and FOREST ##
model.lme4.du6.lw.veg.food.forest <- glmer (pttype ~ std.vri_bryoid_cover_pct + 
                                              std.vri_herb_cover_pct + 
                                              std.vri_shrub_crown_close +
                                              std.vri_proj_age + 
                                              std.vri_proj_height +
                                              std.vri_crown_closure +
                                              (1 | uniqueID), 
                                            data = rsf.data.veg.du6.lw, 
                                            family = binomial (link = "logit"),
                                            verbose = T) 
# AIC
table.aic [6, 1] <- "DU6"
table.aic [6, 2] <- "Late Winter"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeHeight, TreeClosure"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <-  AIC (model.lme4.du6.lw.veg.food.forest)

## WETLAND, BEC, FOOD and FOREST ##
model.lme4.du6.lw.veg.food.forest.food <- glmer (pttype ~ wetland_demars + bec_label + 
                                                   std.vri_bryoid_cover_pct + 
                                                   std.vri_herb_cover_pct + 
                                                   std.vri_shrub_crown_close +
                                                   std.vri_proj_age + 
                                                   std.vri_proj_height +
                                                   std.vri_crown_closure +
                                                   (1 | uniqueID), 
                                                 data = rsf.data.veg.du6.lw, 
                                                 family = binomial (link = "logit"),
                                                 verbose = T) 
ss <- getME (model.lme4.du6.lw.veg.food.forest.food, c ("theta","fixef"))
model.lme4.du6.lw.veg.food.forest.food <- update (model.lme4.du6.lw.veg.food.forest.food, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [7, 1] <- "DU6"
table.aic [7, 2] <- "Late Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "Wetland, BEC, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeHeight, TreeClosure"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du6.lw.veg.food.forest.food)

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

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\late_winter\\table_aic_veg.csv", sep = ",")

#=================================
# COMBINATION Models
#=================================

### compile AIC table of top models form each group
table.aic.annual.clim <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\late_winter\\table_aic_annual_climate.csv", header = T, sep = ",")
table.aic <- table.aic.annual.clim [7, ]
rm (table.aic.annual.clim)
table.aic.human <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\late_winter\\table_aic_human_disturb.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.human [15, ])
rm (table.aic.human)
table.aic.nat.disturb <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\late_winter\\table_aic_natural_disturb.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.nat.disturb [3, ])
rm (table.aic.nat.disturb)
table.aic.enduring <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\late_winter\\table_aic_terrain_water.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.enduring [7, ])
rm (table.aic.enduring)
table.aic.winter.clim <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\late_winter\\table_aic_winter_climate.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.winter.clim [3, ])
rm (table.aic.winter.clim)
table.aic.veg <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\late_winter\\table_aic_veg.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.veg [7, ])
rm (table.aic.veg)
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\late_winter\\table_aic_all.csv", sep = ",")


# Load and tidy the data 
rsf.data.combo.du6.lw <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du6_lw.csv", header = T, sep = ",")
rsf.data.combo.du6.lw$pttype <- as.factor (rsf.data.combo.du6.lw$pttype)
rsf.data.combo.du6.lw <- rsf.data.combo.du6.lw %>% 
                         filter (!is.na (ppt_as_snow_annual))
rsf.data.combo.du6.lw$soil_parent_material_name <- relevel (rsf.data.combo.du6.lw$soil_parent_material_name,
                                                            ref = "Till")
rsf.data.combo.du6.lw$bec_label <- relevel (rsf.data.combo.du6.lw$bec_label,
                                            ref = "BWBSmk")
rsf.data.combo.du6.lw$wetland_demars <- relevel (rsf.data.combo.du6.lw$wetland_demars,
                                                 ref = "Upland Conifer") # upland confier as referencce, as per Demars 2018

### CORRELATION ###
corr.data.du6.lw <- rsf.data.combo.du6.lw [c (11:15, 42, 18:21, 28:32, 34:40)]
corr.du6.lw <- round (cor (corr.data.du6.lw, method = "spearman"), 3)
ggcorrplot (corr.du6.lw, type = "lower", lab = TRUE, tl.cex = 9,  lab_size = 2,
            title = "Resource Selection Function Model Covariate Correlations \
                     for DU6, Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_winter_climate_du6_lw.png")

### VIF ###
glm.all.du6.lw <- glm (pttype ~ slope + distance_to_lake + distance_to_watercourse +
                                distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                                distance_to_cut_10yoorOver + distance_to_paved_road +
                                distance_to_resource_road + distance_to_pipeline +
                                beetle_1to5yo + beetle_6to9yo + fire_1to5yo + fire_6to25yo +
                                fire_over25yo + growing_degree_days + ppt_as_snow_winter +
                                temp_avg_winter + bec_label + wetland_demars,  
                       data = rsf.data.combo.du6.lw,
                       family = binomial (link = 'logit'))
car::vif (glm.all.du6.lw)

# standardize covariates  (helps with model convergence)
rsf.data.combo.du6.lw$std.slope <- (rsf.data.combo.du6.lw$slope - 
                                    mean (rsf.data.combo.du6.lw$slope)) / 
                                    sd (rsf.data.combo.du6.lw$slope)
rsf.data.combo.du6.lw$std.distance_to_lake <- (rsf.data.combo.du6.lw$distance_to_lake - 
                                                mean (rsf.data.combo.du6.lw$distance_to_lake)) / 
                                                sd (rsf.data.combo.du6.lw$distance_to_lake)
rsf.data.combo.du6.lw$std.distance_to_watercourse <- (rsf.data.combo.du6.lw$distance_to_watercourse - 
                                                      mean (rsf.data.combo.du6.lw$distance_to_watercourse)) / 
                                                      sd (rsf.data.combo.du6.lw$distance_to_watercourse)
rsf.data.combo.du6.lw$std.distance_to_cut_1to4yo <- (rsf.data.combo.du6.lw$distance_to_cut_1to4yo - 
                                                      mean (rsf.data.combo.du6.lw$distance_to_cut_1to4yo)) / 
                                                      sd (rsf.data.combo.du6.lw$distance_to_cut_1to4yo)
rsf.data.combo.du6.lw$std.distance_to_cut_5to9yo <- (rsf.data.combo.du6.lw$distance_to_cut_5to9yo - 
                                                      mean (rsf.data.combo.du6.lw$distance_to_cut_5to9yo)) / 
                                                      sd (rsf.data.combo.du6.lw$distance_to_cut_5to9yo)
rsf.data.combo.du6.lw$std.distance_to_cut_10yoorOver <- (rsf.data.combo.du6.lw$distance_to_cut_10yoorOver - 
                                                          mean (rsf.data.combo.du6.lw$distance_to_cut_10yoorOver)) / 
                                                          sd (rsf.data.combo.du6.lw$distance_to_cut_10yoorOver)
rsf.data.combo.du6.lw$std.distance_to_paved_road <- (rsf.data.combo.du6.lw$distance_to_paved_road - 
                                                           mean (rsf.data.combo.du6.lw$distance_to_paved_road)) / 
                                                           sd (rsf.data.combo.du6.lw$distance_to_paved_road)
rsf.data.combo.du6.lw$std.distance_to_resource_road <- (rsf.data.combo.du6.lw$distance_to_resource_road - 
                                                        mean (rsf.data.combo.du6.lw$distance_to_resource_road)) / 
                                                        sd (rsf.data.combo.du6.lw$distance_to_resource_road)
rsf.data.combo.du6.lw$std.distance_to_mines <- (rsf.data.combo.du6.lw$distance_to_mines - 
                                                mean (rsf.data.combo.du6.lw$distance_to_mines)) / 
                                                sd (rsf.data.combo.du6.lw$distance_to_mines)
rsf.data.combo.du6.lw$std.distance_to_pipeline <- (rsf.data.combo.du6.lw$distance_to_pipeline - 
                                                    mean (rsf.data.combo.du6.lw$distance_to_pipeline)) / 
                                                    sd (rsf.data.combo.du6.lw$distance_to_pipeline)
rsf.data.combo.du6.lw$std.growing_degree_days <- (rsf.data.combo.du6.lw$growing_degree_days - 
                                                  mean (rsf.data.combo.du6.lw$growing_degree_days)) / 
                                                  sd (rsf.data.combo.du6.lw$growing_degree_days)
rsf.data.combo.du6.lw$std.ppt_as_snow_winter <- (rsf.data.combo.du6.lw$ppt_as_snow_winter - 
                                                  mean (rsf.data.combo.du6.lw$ppt_as_snow_winter)) / 
                                                  sd (rsf.data.combo.du6.lw$ppt_as_snow_winter)
rsf.data.combo.du6.lw$std.temp_avg_winter <- (rsf.data.combo.du6.lw$temp_avg_winter - 
                                                   mean (rsf.data.combo.du6.lw$temp_avg_winter)) / 
                                                   sd (rsf.data.combo.du6.lw$temp_avg_winter)
rsf.data.combo.du6.lw$std.vri_bryoid_cover_pct <- (rsf.data.combo.du6.lw$vri_bryoid_cover_pct - mean (rsf.data.combo.du6.lw$vri_bryoid_cover_pct)) / sd (rsf.data.combo.du6.lw$vri_bryoid_cover_pct)
rsf.data.combo.du6.lw$std.vri_herb_cover_pct <- (rsf.data.combo.du6.lw$vri_herb_cover_pct - mean (rsf.data.combo.du6.lw$vri_herb_cover_pct)) / sd (rsf.data.combo.du6.lw$vri_herb_cover_pct)
rsf.data.combo.du6.lw$std.vri_proj_age <- (rsf.data.combo.du6.lw$vri_proj_age - mean (rsf.data.combo.du6.lw$vri_proj_age)) / sd (rsf.data.combo.du6.lw$vri_proj_age)
rsf.data.combo.du6.lw$std.vri_shrub_crown_close <- (rsf.data.combo.du6.lw$vri_shrub_crown_close - mean (rsf.data.combo.du6.lw$vri_shrub_crown_close)) / sd (rsf.data.combo.du6.lw$vri_shrub_crown_close)
rsf.data.combo.du6.lw$std.vri_proj_height <- (rsf.data.combo.du6.lw$vri_proj_height - mean (rsf.data.combo.du6.lw$vri_proj_height)) / sd (rsf.data.combo.du6.lw$vri_proj_height)
rsf.data.combo.du6.lw$std.vri_crown_closure <- (rsf.data.combo.du6.lw$vri_crown_closure - mean (rsf.data.combo.du6.lw$vri_crown_closure)) / sd (rsf.data.combo.du6.lw$vri_crown_closure)

### HUMAN DISTURBANCE *** NEW - UPDATED WITHOUT SEISMIC AND MINES *** ###
model.lme4.du6.lw.hd <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                                         std.distance_to_cut_10yoorOver + 
                                         std.distance_to_paved_road + std.distance_to_resource_road + 
                                         std.distance_to_pipeline +
                                         (1 | uniqueID), 
                                       data = rsf.data.combo.du6.lw, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Late Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "DC1to4, DC5to9, DC10, DPR, DRR, DPipe"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du6.lw.hd)

### ENDURING FEATURES AND HUMAN DISTURBANCE ###
model.lme4.du6.lw.ef.hd <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                            std.distance_to_watercourse + 
                                            std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                            std.distance_to_cut_10yoorOver + 
                                            std.distance_to_paved_road +
                                            std.distance_to_resource_road + std.distance_to_pipeline +
                                            (1 | uniqueID), 
                                  data = rsf.data.combo.du6.lw, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
#ss <- getME (model.lme4.du6.lw.ef.hd, c ("theta","fixef"))
#model.lme4.du6.lw.ef.hd2 <- update (model.lme4.du6.lw.ef.hd, start = ss) # failed to converge, restart with parameter estimates
#model.lme4.du6.lw.ef.hd3 <- update (model.lme4.du6.lw.ef.hd, 
#                                    . ~ . - seismic) # drop seismic lines
#model.lme4.du6.lw.ef.hd4 <- update (model.lme4.du6.lw.ef.hd, 
#                                    . ~ . - soil_parent_material_name) # drop soil
# AIC
table.aic [7, 1] <- "DU6"
table.aic [7, 2] <- "Late Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "Slope, DLake, DWat, DC1to4, DC5to9, DC10, DPR, DRR, DPipe"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du6.lw.ef.hd)

### ENDURING FEATURES AND NATURAL DISTURBANCE ###
model.lme4.du6.lw.ef.nd <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                    std.distance_to_watercourse + 
                                    beetle_1to5yo + beetle_6to9yo + fire_1to5yo + fire_6to25yo +
                                    fire_over25yo +
                                    (1 | uniqueID), 
                                  data = rsf.data.combo.du6.lw, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
#model.lme4.du6.lw.ef.nd2 <- update (model.lme4.du6.lw.ef.nd, 
#                                    . ~ . - soil_parent_material_name) # drop soils
# AIC
table.aic [8, 1] <- "DU6"
table.aic [8, 2] <- "Late Winter"
table.aic [8, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [8, 4] <- "Slope, DLake, DWat, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [8, 5] <- "(1 | UniqueID)"
table.aic [8, 6] <-  AIC (model.lme4.du6.lw.ef.nd)

### ENDURING FEATURES AND CLIMATE ###
model.lme4.du6.lw.ef.clim <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                              std.distance_to_watercourse + std.growing_degree_days +
                                              std.ppt_as_snow_winter +
                                              (1 | uniqueID), 
                                    data = rsf.data.combo.du6.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [9, 1] <- "DU6"
table.aic [9, 2] <- "Late Winter"
table.aic [9, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [9, 4] <- "Slope, DLake, DWat, GDD, PAS"
table.aic [9, 5] <- "(1 | UniqueID)"
table.aic [9, 6] <-  AIC (model.lme4.du6.lw.ef.clim)

### HUMAN DISTURBANCE AND NATURAL DISTURBANCE ###
model.lme4.du6.lw.hd.nd <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                    std.distance_to_cut_10yoorOver + 
                                    std.distance_to_paved_road +
                                    std.distance_to_resource_road + std.distance_to_pipeline + 
                                    beetle_1to5yo + beetle_6to9yo + 
                                    fire_1to5yo + fire_6to25yo + fire_over25yo +
                                    (1 | uniqueID), 
                                  data = rsf.data.combo.du6.lw, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
# AIC
table.aic [10, 1] <- "DU6"
table.aic [10, 2] <- "Late Winter"
table.aic [10, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [10, 4] <- "DC1to4, DC5to9, DC10, DPR, DRR, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [10, 5] <- "(1 | UniqueID)"
table.aic [10, 6] <-  AIC (model.lme4.du6.lw.hd.nd)

### HUMAN DISTURBANCE AND CLIMATE ###
model.lme4.du6.lw.hd.clim <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                      std.distance_to_cut_5to9yo +
                                      std.distance_to_cut_10yoorOver + 
                                      std.distance_to_paved_road +
                                      std.distance_to_resource_road + 
                                      std.distance_to_pipeline + std.growing_degree_days +
                                      std.ppt_as_snow_winter + 
                                      (1 | uniqueID), 
                                    data = rsf.data.combo.du6.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [11, 1] <- "DU6"
table.aic [11, 2] <- "Late Winter"
table.aic [11, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [11, 4] <- "DC1to4, DC5to9, DC10, DPR, DRR, DPipe, GDD, PAS"
table.aic [11, 5] <- "(1 | UniqueID)"
table.aic [11, 6] <-  AIC (model.lme4.du6.lw.hd.clim)

### NATURAL DISTURBANCE AND CLIMATE ###
model.lme4.du6.lw.nd.clim <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                                      fire_1to5yo + fire_6to25yo + fire_over25yo + 
                                      std.growing_degree_days +
                                      std.ppt_as_snow_winter + 
                                      (1 | uniqueID), 
                                    data = rsf.data.combo.du6.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [12, 1] <- "DU6"
table.aic [12, 2] <- "Late Winter"
table.aic [12, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [12, 4] <- "Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, GDD, PAS"
table.aic [12, 5] <- "(1 | UniqueID)"
table.aic [12, 6] <-  AIC (model.lme4.du6.lw.nd.clim)

### ENDURING FEATURES AND VEGETATION ###
model.lme4.du6.lw.ef.veg <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                     std.distance_to_watercourse + bec_label + wetland_demars +
                                     std.vri_proj_age + std.vri_proj_height +
                                     std.vri_crown_closure + std.vri_bryoid_cover_pct + 
                                     std.vri_herb_cover_pct + std.vri_shrub_crown_close +
                                     (1 | uniqueID), 
                                   data = rsf.data.combo.du6.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 

# AIC
table.aic [13, 1] <- "DU6"
table.aic [13, 2] <- "Late Winter"
table.aic [13, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [13, 4] <- "Slope, DLake, DWat, BEC, Wetland, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeHeight, TreeClosure"
table.aic [13, 5] <- "(1 | UniqueID)"
table.aic [13, 6] <-  AIC (model.lme4.du6.lw.ef.veg)

### HUMAN AND VEGETATION ###
model.lme4.du6.lw.hd.veg <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                             std.distance_to_cut_5to9yo +
                                             std.distance_to_cut_10yoorOver + 
                                             std.distance_to_paved_road +
                                             std.distance_to_resource_road + 
                                             std.distance_to_pipeline + 
                                             bec_label + wetland_demars +
                                             std.vri_proj_age + std.vri_proj_height +
                                             std.vri_crown_closure + std.vri_bryoid_cover_pct + 
                                             std.vri_herb_cover_pct + std.vri_shrub_crown_close +
                                             (1 | uniqueID), 
                                   data = rsf.data.combo.du6.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
ss <- getME (model.lme4.du6.lw.hd.veg, c ("theta","fixef"))
model.lme4.du6.lw.hd.veg <- update (model.lme4.du6.lw.hd.veg, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [14, 1] <- "DU6"
table.aic [14, 2] <- "Late Winter"
table.aic [14, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [14, 4] <- "DC1to4, DC5to9, DC10, DPR, DRR, DPipe, BEC, Wetland, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeHeight, TreeClosure"
table.aic [14, 5] <- "(1 | UniqueID)"
table.aic [14, 6] <-  AIC (model.lme4.du6.lw.hd.veg)

### NATURAL DISTURB AND VEGETATION ###
model.lme4.du6.lw.nd.veg <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                                     fire_1to5yo + fire_6to25yo + fire_over25yo + 
                                     bec_label + wetland_demars +
                                     std.vri_proj_age + std.vri_proj_height +
                                     std.vri_crown_closure + std.vri_bryoid_cover_pct + 
                                     std.vri_herb_cover_pct + std.vri_shrub_crown_close +
                                     (1 | uniqueID), 
                                   data = rsf.data.combo.du6.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
ss <- getME (model.lme4.du6.lw.nd.veg, c ("theta","fixef"))
model.lme4.du6.lw.nd.veg <- update (model.lme4.du6.lw.nd.veg, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [15, 1] <- "DU6"
table.aic [15, 2] <- "Late Winter"
table.aic [15, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [15, 4] <- "Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, BEC, Wetland, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeHeight, TreeClosure"
table.aic [15, 5] <- "(1 | UniqueID)"
table.aic [15, 6] <-  AIC (model.lme4.du6.lw.nd.veg)

### CLIMATE AND VEGETATION ###
model.lme4.du6.lw.clim.veg <- glmer (pttype ~ std.growing_degree_days + std.ppt_as_snow_winter + 
                                       bec_label + wetland_demars +
                                       std.vri_proj_age + std.vri_proj_height +
                                       std.vri_crown_closure + std.vri_bryoid_cover_pct + 
                                       std.vri_herb_cover_pct + std.vri_shrub_crown_close +
                                       (1 | uniqueID), 
                                     data = rsf.data.combo.du6.lw, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
ss <- getME (model.lme4.du6.lw.clim.veg, c ("theta","fixef"))
model.lme4.du6.lw.clim.veg <- update (model.lme4.du6.lw.clim.veg, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [16, 1] <- "DU6"
table.aic [16, 2] <- "Late Winter"
table.aic [16, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [16, 4] <- "GDD, PAS, BEC, Wetland, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeHeight, TreeClosure"
table.aic [16, 5] <- "(1 | UniqueID)"
table.aic [16, 6] <-  AIC (model.lme4.du6.lw.clim.veg)

### ENDURING FEATURES, HUMAN DISTURBANCE, NATURAL DISTURBANCE ###
model.lme4.du6.lw.ef.hd.nd <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                       std.distance_to_watercourse + 
                                       std.distance_to_cut_1to4yo + 
                                       std.distance_to_cut_5to9yo + 
                                       std.distance_to_cut_10yoorOver + 
                                       std.distance_to_paved_road + 
                                       std.distance_to_resource_road + 
                                       std.distance_to_pipeline +
                                       beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                       fire_6to25yo + fire_over25yo +
                                       (1 | uniqueID), 
                                     data = rsf.data.combo.du6.lw, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [17, 1] <- "DU6"
table.aic [17, 2] <- "Late Winter"
table.aic [17, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [17, 4] <- "Slope, DLake, DWat, DC1to4, DC5to9, DC10, DPR, DRR, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [17, 5] <- "(1 | UniqueID)"
table.aic [17, 6] <-  AIC (model.lme4.du6.lw.ef.hd.nd)

### ENDURING FEATURES, HUMAN DISTURBANCE, CLIMATE ###
model.lme4.du6.lw.ef.hd.clim <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                         std.distance_to_watercourse + 
                                         std.distance_to_cut_1to4yo + 
                                         std.distance_to_cut_5to9yo + 
                                         std.distance_to_cut_10yoorOver + 
                                         std.distance_to_paved_road + 
                                         std.distance_to_resource_road + 
                                         std.distance_to_pipeline + 
                                         std.growing_degree_days + std.ppt_as_snow_winter + 
                                         (1 | uniqueID), 
                                       data = rsf.data.combo.du6.lw, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [18, 1] <- "DU6"
table.aic [18, 2] <- "Late Winter"
table.aic [18, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [18, 4] <- "Slope, DLake, DWat, DC1to4, DC5to9, DC10, DPR, DRR, DPipe, GDD, PAS"
table.aic [18, 5] <- "(1 | UniqueID)"
table.aic [18, 6] <-  AIC (model.lme4.du6.lw.ef.hd.clim)

### ENDURING FEATURES, HUMAN DISTURBANCE, VEGETATION ###
model.lme4.du6.lw.ef.hd.veg <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                        std.distance_to_watercourse + 
                                        std.distance_to_cut_1to4yo + 
                                        std.distance_to_cut_5to9yo + 
                                        std.distance_to_cut_10yoorOver + 
                                        std.distance_to_paved_road + 
                                        std.distance_to_resource_road + 
                                        std.distance_to_pipeline + 
                                        bec_label + wetland_demars + std.vri_bryoid_cover_pct + 
                                        std.vri_herb_cover_pct + std.vri_proj_age + 
                                        std.vri_shrub_crown_close + 
                                        std.vri_proj_height + std.vri_crown_closure +
                                        (1 | uniqueID), 
                                      data = rsf.data.combo.du6.lw, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
ss <- getME (model.lme4.du6.lw.ef.hd.veg, c ("theta","fixef"))
model.lme4.du6.lw.ef.hd.veg <- update (model.lme4.du6.lw.ef.hd.veg, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [19, 1] <- "DU6"
table.aic [19, 2] <- "Late Winter"
table.aic [19, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [19, 4] <- "Slope, DLake, DWat, DC1to4, DC5to9, DC10, DPR, DRR, DPipe, Wetland, BEC, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeHeight, TreeClosure"
table.aic [19, 5] <- "(1 | UniqueID)"
table.aic [19, 6] <-  AIC (model.lme4.du6.lw.ef.hd.veg)

### ENDURING FEATURES, NATURAL DISTURBANCE, CLIMATE ###
model.lme4.du6.lw.ef.nd.clim <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                         std.distance_to_watercourse + 
                                         beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                         fire_6to25yo + fire_over25yo +
                                         std.growing_degree_days + std.ppt_as_snow_winter +
                                         (1 | uniqueID), 
                                       data = rsf.data.combo.du6.lw, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [20, 1] <- "DU6"
table.aic [20, 2] <- "Late Winter"
table.aic [20, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [20, 4] <- "Slope, DLake, DWat, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, GDD, PAS"
table.aic [20, 5] <- "(1 | UniqueID)"
table.aic [20, 6] <-  AIC (model.lme4.du6.lw.ef.nd.clim)

### ENDURING FEATURES, NATURAL DISTURBANCE, VEGETATION ###
model.lme4.du6.lw.ef.nd.veg <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                        std.distance_to_watercourse + 
                                        beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                        fire_6to25yo + fire_over25yo +
                                        bec_label + wetland_demars + 
                                        std.vri_bryoid_cover_pct + 
                                        std.vri_herb_cover_pct + std.vri_proj_age + 
                                        std.vri_shrub_crown_close + std.vri_proj_height + 
                                        std.vri_crown_closure +
                                        (1 | uniqueID), 
                                      data = rsf.data.combo.du6.lw, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
ss <- getME (model.lme4.du6.lw.ef.nd.veg, c ("theta","fixef"))
model.lme4.du6.lw.ef.nd.veg <- update (model.lme4.du6.lw.ef.nd.veg, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [21, 1] <- "DU6"
table.aic [21, 2] <- "Late Winter"
table.aic [21, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [21, 4] <- "Slope, DLake, DWat, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, Wetland, BEC, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeHeight, TreeClosure"
table.aic [21, 5] <- "(1 | UniqueID)"
table.aic [21, 6] <-  AIC (model.lme4.du6.lw.ef.nd.veg)

### ENDURING FEATURES, CLIMATE, VEGETATION ###
model.lme4.du6.lw.ef.clim.veg <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                          std.distance_to_watercourse + 
                                          std.growing_degree_days + std.ppt_as_snow_winter +
                                          bec_label + wetland_demars + 
                                          std.vri_bryoid_cover_pct + 
                                          std.vri_herb_cover_pct + std.vri_proj_age + 
                                          std.vri_shrub_crown_close + std.vri_proj_height + 
                                          std.vri_crown_closure +
                                          (1 | uniqueID), 
                                        data = rsf.data.combo.du6.lw, 
                                        family = binomial (link = "logit"),
                                        verbose = T) 
ss <- getME (model.lme4.du6.lw.ef.clim.veg, c ("theta","fixef"))
model.lme4.du6.lw.ef.clim.veg <- update (model.lme4.du6.lw.ef.clim.veg, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [22, 1] <- "DU6"
table.aic [22, 2] <- "Late Winter"
table.aic [22, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [22, 4] <- "Slope, DLake, DWat, GDD, PAS, Wetland, BEC, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeHeight, TreeClosure"
table.aic [22, 5] <- "(1 | UniqueID)"
table.aic [22, 6] <-  AIC (model.lme4.du6.lw.ef.clim.veg)

### HUMAN DISTURBANCE, NATURAL DISTURBANCE, CLIMATE ###
model.lme4.du6.lw.hd.nd.clim <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                         std.distance_to_cut_5to9yo + 
                                         std.distance_to_cut_10yoorOver + 
                                         std.distance_to_paved_road + 
                                         std.distance_to_resource_road + 
                                         std.distance_to_pipeline +
                                         std.growing_degree_days +
                                         std.ppt_as_snow_winter + 
                                         beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                         fire_6to25yo + fire_over25yo +
                                         (1 | uniqueID), 
                                       data = rsf.data.combo.du6.lw, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [23, 1] <- "DU6"
table.aic [23, 2] <- "Late Winter"
table.aic [23, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [23, 4] <- "DC1to4, DC5to9, DC10, DPR, DRR, DPipe, GDD, PAS, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [23, 5] <- "(1 | UniqueID)"
table.aic [23, 6] <-  AIC (model.lme4.du6.lw.hd.nd.clim)

### HUMAN DISTURBANCE, NATURAL DISTURBANCE, VEGETATION ###
model.lme4.du6.lw.hd.nd.veg <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                        std.distance_to_cut_5to9yo + 
                                        std.distance_to_cut_10yoorOver + 
                                        std.distance_to_paved_road + 
                                        std.distance_to_resource_road + 
                                        std.distance_to_pipeline +
                                        beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                        fire_6to25yo + fire_over25yo +
                                        bec_label + wetland_demars + 
                                        std.vri_bryoid_cover_pct + 
                                        std.vri_herb_cover_pct + 
                                        std.vri_proj_age + 
                                        std.vri_shrub_crown_close + 
                                        std.vri_proj_height + 
                                        std.vri_crown_closure +
                                        (1 | uniqueID), 
                                      data = rsf.data.combo.du6.lw, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
ss <- getME (model.lme4.du6.lw.hd.nd.veg, c ("theta","fixef"))
model.lme4.du6.lw.hd.nd.veg <- update (model.lme4.du6.lw.hd.nd.veg, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [24, 1] <- "DU6"
table.aic [24, 2] <- "Late Winter"
table.aic [24, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [24, 4] <- "DC1to4, DC5to9, DC10, DPR, DRR, DPipe, Wetland, BEC, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeHeight, TreeClosure, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [24, 5] <- "(1 | UniqueID)"
table.aic [24, 6] <-  AIC (model.lme4.du6.lw.hd.nd.veg)

### HUMAN DISTURBANCE, CLIMATE, VEGETATION ###
model.lme4.du6.lw.hd.clim.veg <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                          std.distance_to_cut_5to9yo + 
                                          std.distance_to_cut_10yoorOver + 
                                          std.distance_to_paved_road + 
                                          std.distance_to_resource_road + 
                                          std.distance_to_pipeline +
                                          std.growing_degree_days + std.ppt_as_snow_winter +
                                          bec_label + wetland_demars + 
                                          std.vri_bryoid_cover_pct + 
                                          std.vri_herb_cover_pct + 
                                          std.vri_proj_age + 
                                          std.vri_shrub_crown_close + 
                                          std.vri_proj_height + 
                                          std.vri_crown_closure +
                                          (1 | uniqueID), 
                                        data = rsf.data.combo.du6.lw, 
                                        family = binomial (link = "logit"),
                                        verbose = T) 
ss <- getME (model.lme4.du6.lw.hd.clim.veg, c ("theta","fixef"))
model.lme4.du6.lw.hd.clim.veg <- update (model.lme4.du6.lw.hd.clim.veg, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [25, 1] <- "DU6"
table.aic [25, 2] <- "Late Winter"
table.aic [25, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [25, 4] <- "DC1to4, DC5to9, DC10, DPR, DRR, DPipe, Wetland, BEC, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeHeight, TreeClosure, GDD, PAS"
table.aic [25, 5] <- "(1 | UniqueID)"
table.aic [25, 6] <-  AIC (model.lme4.du6.lw.hd.clim.veg)

### NATURAL DISTURBANCE, CLIMATE, VEGETATION ###
model.lme4.du6.lw.nd.clim.veg <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                          fire_6to25yo + fire_over25yo +
                                          std.growing_degree_days + std.ppt_as_snow_winter +
                                          bec_label + wetland_demars + 
                                          std.vri_bryoid_cover_pct + 
                                          std.vri_herb_cover_pct + 
                                          std.vri_proj_age + 
                                          std.vri_shrub_crown_close + 
                                          std.vri_proj_height + 
                                          std.vri_crown_closure +
                                          (1 | uniqueID), 
                                        data = rsf.data.combo.du6.lw, 
                                        family = binomial (link = "logit"),
                                        verbose = T) 
ss <- getME (model.lme4.du6.lw.nd.clim.veg, c ("theta","fixef"))
model.lme4.du6.lw.nd.clim.veg <- update (model.lme4.du6.lw.nd.clim.veg, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [26, 1] <- "DU6"
table.aic [26, 2] <- "Late Winter"
table.aic [26, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [26, 4] <- "Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, Wetland, BEC, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeHeight, TreeClosure, GDD, PAS"
table.aic [26, 5] <- "(1 | UniqueID)"
table.aic [26, 6] <-  AIC (model.lme4.du6.lw.nd.clim.veg)

### ENDURING FEATURES, HUMAN DISTURBANCE, NATURAL DISTURBANCE, CLIMATE ###
model.lme4.du6.lw.ef.hd.nd.clim <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                            std.distance_to_watercourse + 
                                            std.distance_to_cut_1to4yo + 
                                            std.distance_to_cut_5to9yo + 
                                            std.distance_to_cut_10yoorOver + 
                                            std.distance_to_paved_road + 
                                            std.distance_to_resource_road + 
                                            std.distance_to_pipeline +
                                            beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                            fire_6to25yo + fire_over25yo +
                                            std.growing_degree_days + std.ppt_as_snow_winter +
                                            (1 | uniqueID), 
                                          data = rsf.data.combo.du6.lw, 
                                          family = binomial (link = "logit"),
                                          verbose = T) 
# AIC
table.aic [27, 1] <- "DU6"
table.aic [27, 2] <- "Late Winter"
table.aic [27, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [27, 4] <- "Slope, DLake, DWat, DC1to4, DC5to9, DC10, DPR, DRR, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, GDD, PAS"
table.aic [27, 5] <- "(1 | UniqueID)"
table.aic [27, 6] <-  AIC (model.lme4.du6.lw.ef.hd.nd.clim)

### ENDURING FEATURES, HUMAN DISTURBANCE, NATURAL DISTURBANCE, VEGETATION ###
model.lme4.du6.lw.ef.hd.nd.veg <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                           std.distance_to_watercourse + 
                                           std.distance_to_cut_1to4yo + 
                                           std.distance_to_cut_5to9yo + 
                                           std.distance_to_cut_10yoorOver + 
                                           std.distance_to_paved_road + 
                                           std.distance_to_resource_road + 
                                           std.distance_to_pipeline +
                                           beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                           fire_6to25yo + fire_over25yo +
                                           bec_label + wetland_demars + 
                                           std.vri_bryoid_cover_pct + std.vri_herb_cover_pct + 
                                           std.vri_proj_age + 
                                           std.vri_shrub_crown_close + std.vri_proj_height + 
                                           std.vri_crown_closure +
                                           (1 | uniqueID), 
                                         data = rsf.data.combo.du6.lw, 
                                         family = binomial (link = "logit"),
                                         verbose = T) 
ss <- getME (model.lme4.du6.lw.ef.hd.nd.veg, c ("theta","fixef"))
model.lme4.du6.lw.ef.hd.nd.veg <- update (model.lme4.du6.lw.ef.hd.nd.veg, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [28, 1] <- "DU6"
table.aic [28, 2] <- "Late Winter"
table.aic [28, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [28, 4] <- "Slope, DLake, DWat, DC1to4, DC5to9, DC10, DPR, DRR, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, Wetland, BEC, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeHeight, TreeClosure"
table.aic [28, 5] <- "(1 | UniqueID)"
table.aic [28, 6] <-  AIC (model.lme4.du6.lw.ef.hd.nd.veg)

### HUMAN DISTURBANCE, NATURAL DISTURBANCE, CLIMATE, VEGETATION ###
model.lme4.du6.lw.hd.nd.clim.veg <- glmer (pttype ~ std.growing_degree_days + std.ppt_as_snow_winter + 
                                             std.distance_to_cut_1to4yo + 
                                             std.distance_to_cut_5to9yo + 
                                             std.distance_to_cut_10yoorOver + 
                                             std.distance_to_paved_road + 
                                             std.distance_to_resource_road + 
                                             std.distance_to_pipeline +
                                             beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                             fire_6to25yo + fire_over25yo +
                                             bec_label + wetland_demars + 
                                             std.vri_bryoid_cover_pct + std.vri_herb_cover_pct + 
                                             std.vri_proj_age + 
                                             std.vri_shrub_crown_close + std.vri_proj_height + 
                                             std.vri_crown_closure +
                                             (1 | uniqueID), 
                                           data = rsf.data.combo.du6.lw, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
ss <- getME (model.lme4.du6.lw.hd.nd.clim.veg, c ("theta","fixef"))
model.lme4.du6.lw.ef.hd.nd.veg <- update (model.lme4.du6.lw.hd.nd.clim.veg, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [29, 1] <- "DU6"
table.aic [29, 2] <- "Late Winter"
table.aic [29, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [29, 4] <- "GDD, PAS, DC1to4, DC5to9, DC10, DPR, DRR, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, Wetland, BEC, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeHeight, TreeClosure"
table.aic [29, 5] <- "(1 | UniqueID)"
table.aic [29, 6] <-  AIC (model.lme4.du6.lw.hd.nd.clim.veg)

### ENDURING FEATURES, HUMAN DISTURBANCE, CLIMATE, VEGETATION ###
model.lme4.du6.lw.ef.hd.clim.veg <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                             std.distance_to_watercourse + 
                                             std.distance_to_cut_1to4yo + 
                                             std.distance_to_cut_5to9yo + 
                                             std.distance_to_cut_10yoorOver + 
                                             std.distance_to_paved_road + 
                                             std.distance_to_resource_road + 
                                             std.distance_to_pipeline +
                                             std.growing_degree_days + std.ppt_as_snow_winter +
                                             bec_label + wetland_demars + 
                                             std.vri_bryoid_cover_pct + std.vri_herb_cover_pct + 
                                             std.vri_proj_age + 
                                             std.vri_shrub_crown_close + std.vri_proj_height + 
                                             std.vri_crown_closure +
                                             (1 | uniqueID), 
                                           data = rsf.data.combo.du6.lw, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
ss <- getME (model.lme4.du6.lw.ef.hd.clim.veg, c ("theta","fixef"))
model.lme4.du6.lw.ef.hd.clim.veg <- update (model.lme4.du6.lw.ef.hd.clim.veg, start = ss) # failed to converge, restart with parameter estimates
ss <- getME (model.lme4.du6.lw.ef.hd.clim.veg, c ("theta","fixef"))
model.lme4.du6.lw.ef.hd.clim.veg <- update (model.lme4.du6.lw.ef.hd.clim.veg, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [30, 1] <- "DU6"
table.aic [30, 2] <- "Late Winter"
table.aic [30, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [30, 4] <- "Slope, DLake, DWat, DC1to4, DC5to9, DC10, DPR, DRR, DPipe, GDD, PAS, Wetland, BEC, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeHeight, TreeClosure"
table.aic [30, 5] <- "(1 | UniqueID)"
table.aic [30, 6] <-  AIC (model.lme4.du6.lw.ef.hd.clim.veg)

### ENDURING FEATURES, NATURAL DISTURBANCE, CLIMATE, VEGETATION ###
model.lme4.du6.lw.ef.nd.clim.veg <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                             std.distance_to_watercourse + 
                                             beetle_1to5yo + beetle_6to9yo + 
                                             fire_1to5yo + fire_6to25yo + fire_over25yo +
                                             std.growing_degree_days + std.ppt_as_snow_winter +
                                             bec_label + wetland_demars + 
                                             std.vri_bryoid_cover_pct + 
                                             std.vri_herb_cover_pct + 
                                             std.vri_proj_age + 
                                             std.vri_shrub_crown_close + 
                                             std.vri_proj_height + 
                                             std.vri_crown_closure +
                                             (1 | uniqueID), 
                                           data = rsf.data.combo.du6.lw, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
ss <- getME (model.lme4.du6.lw.ef.nd.clim.veg, c ("theta","fixef"))
model.lme4.du6.lw.ef.nd.clim.veg <- update (model.lme4.du6.lw.ef.nd.clim.veg, start = ss) # failed to converge, restart with parameter estimates
# AIC
table.aic [31, 1] <- "DU6"
table.aic [31, 2] <- "Late Winter"
table.aic [31, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [31, 4] <- "Slope, DLake, DWat, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, GDD, PAS, Wetland, BEC, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeHeight, TreeClosure"
table.aic [31, 5] <- "(1 | UniqueID)"
table.aic [31, 6] <-  AIC (model.lme4.du6.lw.ef.nd.clim.veg)

### ENDURING FEATURES, HUMAN DISTURBANCE, NATURAL DISTURBANCE, CLIMATE, VEGETATION ###
model.lme4.du6.lw.ef.hd.nd.clim.veg <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                                std.distance_to_watercourse + 
                                                std.distance_to_cut_1to4yo + 
                                                std.distance_to_cut_5to9yo +
                                                std.distance_to_cut_10yoorOver + 
                                                std.distance_to_paved_road +
                                                std.distance_to_resource_road + 
                                                std.distance_to_pipeline + 
                                                beetle_1to5yo + beetle_6to9yo + 
                                                fire_1to5yo + fire_6to25yo + fire_over25yo +
                                                std.growing_degree_days + 
                                                std.ppt_as_snow_winter +
                                                bec_label + wetland_demars + 
                                                std.vri_bryoid_cover_pct + 
                                                std.vri_herb_cover_pct + 
                                                std.vri_proj_age + 
                                                std.vri_shrub_crown_close + 
                                                std.vri_proj_height + 
                                                std.vri_crown_closure +
                                                (1 | uniqueID), 
                                              data = rsf.data.combo.du6.lw, 
                                              family = binomial (link = "logit"),
                                              verbose = T) 
# AIC
table.aic [32, 1] <- "DU6"
table.aic [32, 2] <- "Late Winter"
table.aic [32, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [32, 4] <- "Slope, DLake, DWat, DC1to4, DC5to9, DC10, DPR, DRR, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, GDD, PAS, Wetland, BEC, ShrubClosure, BryoidCover, HerbCover, TreeAge, TreeHeight, TreeClosure"
table.aic [32, 5] <- "(1 | UniqueID)"
table.aic [32, 6] <-  AIC (model.lme4.du6.lw.ef.hd.nd.clim.veg)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\late_winter\\table_aic_all_top.csv", sep = ",")

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

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\late_winter\\table_aic_all_top.csv", sep = ",")

save (model.lme4.du6.lw.ef.hd.nd.clim.veg, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_du6_lw_final.rda")

# Create table of model coefficients from top model
model.coeffs <- as.data.frame (coef (summary (model.lme4.du6.lw.ef.hd.nd.clim.veg)))
model.coeffs$mean <- 0
model.coeffs$sd <- 0

model.coeffs [2, 5] <- mean (rsf.data.combo.du6.lw$slope)
model.coeffs [3, 5] <- mean (rsf.data.combo.du6.lw$distance_to_lake)
model.coeffs [4, 5] <- mean (rsf.data.combo.du6.lw$distance_to_watercourse)
model.coeffs [5, 5] <- mean (rsf.data.combo.du6.lw$distance_to_cut_1to4yo)
model.coeffs [6, 5] <- mean (rsf.data.combo.du6.lw$distance_to_cut_5to9yo)
model.coeffs [7, 5] <- mean (rsf.data.combo.du6.lw$distance_to_cut_10yoorOver)
model.coeffs [8, 5] <- mean (rsf.data.combo.du6.lw$distance_to_paved_road)
model.coeffs [9, 5] <- mean (rsf.data.combo.du6.lw$distance_to_resource_road)
model.coeffs [10, 5] <- mean (rsf.data.combo.du6.lw$distance_to_pipeline)
model.coeffs [16, 5] <- mean (rsf.data.combo.du6.lw$growing_degree_days)
model.coeffs [17, 5] <- mean (rsf.data.combo.du6.lw$ppt_as_snow_winter)
model.coeffs [26, 5] <- mean (rsf.data.combo.du6.lw$vri_bryoid_cover_pct)
model.coeffs [27, 5] <- mean (rsf.data.combo.du6.lw$vri_herb_cover_pct)
model.coeffs [28, 5] <- mean (rsf.data.combo.du6.lw$vri_proj_age)
model.coeffs [29, 5] <- mean (rsf.data.combo.du6.lw$vri_shrub_crown_close)
model.coeffs [30, 5] <- mean (rsf.data.combo.du6.lw$vri_proj_height)
model.coeffs [31, 5] <- mean (rsf.data.combo.du6.lw$vri_crown_closure)

model.coeffs [2, 6] <- sd (rsf.data.combo.du6.lw$slope)
model.coeffs [3, 6] <- sd (rsf.data.combo.du6.lw$distance_to_lake)
model.coeffs [4, 6] <- sd (rsf.data.combo.du6.lw$distance_to_watercourse)
model.coeffs [5, 6] <- sd (rsf.data.combo.du6.lw$distance_to_cut_1to4yo)
model.coeffs [6, 6] <- sd (rsf.data.combo.du6.lw$distance_to_cut_5to9yo)
model.coeffs [7, 6] <- sd (rsf.data.combo.du6.lw$distance_to_cut_10yoorOver)
model.coeffs [8, 6] <- sd (rsf.data.combo.du6.lw$distance_to_paved_road)
model.coeffs [9, 6] <- sd (rsf.data.combo.du6.lw$distance_to_resource_road)
model.coeffs [10, 6] <- sd (rsf.data.combo.du6.lw$distance_to_pipeline)
model.coeffs [16, 6] <- sd (rsf.data.combo.du6.lw$growing_degree_days)
model.coeffs [17, 6] <- sd (rsf.data.combo.du6.lw$ppt_as_snow_winter)
model.coeffs [26, 6] <- sd (rsf.data.combo.du6.lw$vri_bryoid_cover_pct)
model.coeffs [27, 6] <- sd (rsf.data.combo.du6.lw$vri_herb_cover_pct)
model.coeffs [28, 6] <- sd (rsf.data.combo.du6.lw$vri_proj_age)
model.coeffs [29, 6] <- sd (rsf.data.combo.du6.lw$vri_shrub_crown_close)
model.coeffs [30, 6] <- sd (rsf.data.combo.du6.lw$vri_proj_height)
model.coeffs [31, 6] <- sd (rsf.data.combo.du6.lw$vri_crown_closure)

write.table (model.coeffs, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\model_coefficients\\table_du6_lw_model_coeffs_top.csv", sep = ",")


##########################
### k-fold Validation ###
########################
df.unique.id <- as.data.frame (unique (rsf.data.combo.du6.lw$uniqueID))
names (df.unique.id) [1] <-"uniqueID"
df.unique.id$group <- rep_len (1:5, nrow (df.unique.id)) # orderly selection of groups
rsf.data.combo.du6.lw <- dplyr::full_join (rsf.data.combo.du6.lw, df.unique.id, by = "uniqueID")

### FOLD 1 ###
train.data.1 <- rsf.data.combo.du6.lw %>%
  filter (group < 5)
test.data.1 <- rsf.data.combo.du6.lw %>%
  filter (group == 5)

model.lme4.du6.lw.train1 <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                     std.distance_to_watercourse + 
                                     std.distance_to_cut_1to4yo + 
                                     std.distance_to_cut_5to9yo +
                                     std.distance_to_cut_10yoorOver + 
                                     std.distance_to_paved_road +
                                     std.distance_to_resource_road + 
                                     std.distance_to_pipeline + 
                                     beetle_1to5yo + beetle_6to9yo + 
                                     fire_1to5yo + fire_6to25yo + fire_over25yo +
                                     std.growing_degree_days + 
                                     std.ppt_as_snow_winter +
                                     bec_label + wetland_demars + 
                                     std.vri_bryoid_cover_pct + 
                                     std.vri_herb_cover_pct + 
                                     std.vri_proj_age + 
                                     std.vri_shrub_crown_close + 
                                     std.vri_proj_height + 
                                     std.vri_crown_closure +
                                     (1 | uniqueID), 
                                   data = train.data.1, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 

# create a table of k-fold outputs
table.kfold <- data.frame (matrix (ncol = 12, nrow = 50))
colnames (table.kfold) <- c ("test.number", "bin.mid", "bin.weight", "utilization", "used.count", 
                             "expected.count", "lm.slope", "lm.slope.p.value", "lm.intercept",
                             "lm.intercept.p.value", "adj.R.sq", "chi.sq.p.value")
table.kfold [c (1:10), 1] <- 1
table.kfold$bin.mid <- c (0.02, 0.06, 0.10, 0.14, 0.18, 0.22, 0.26, 0.30, 0.34, 0.38)

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.combo.du6.lw$preds.train1 <- predict (model.lme4.du6.lw.train1, 
                                               newdata = rsf.data.combo.du6.lw, 
                                               re.form = NA, type = "response")
rsf.data.combo.du6.lw$preds.train1.class <- cut (rsf.data.combo.du6.lw$preds.train1, # put into classes; 0 to 0.4, based on max and min values
                                                 breaks = c (-Inf, 0.04, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28, 0.32, 0.36, Inf), 
                                                 labels = c ("0.02", "0.06", "0.10", "0.14", "0.18",
                                                             "0.22", "0.26", "0.30", "0.34", "0.38"))
write.csv (rsf.data.combo.du6.lw, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du6_lw.csv")
rsf.data.combo.du6.lw.avail <- dplyr::filter (rsf.data.combo.du6.lw, pttype == 0)

table.kfold [1, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train1.class == "0.02")) * 0.02) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [2, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train1.class == "0.06")) * 0.06)
table.kfold [3, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train1.class == "0.10")) * 0.10)
table.kfold [4, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train1.class == "0.14")) * 0.14)
table.kfold [5, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train1.class == "0.18")) * 0.18)
table.kfold [6, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train1.class == "0.22")) * 0.22)
table.kfold [7, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train1.class == "0.26")) * 0.26)
table.kfold [8, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train1.class == "0.30")) * 0.30)
table.kfold [9, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train1.class == "0.34")) * 0.34)
table.kfold [10, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train1.class == "0.38")) * 0.38)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\table_kfold_valid_du6_lw.csv")

# data for estimating use
test.data.1$preds <- predict (model.lme4.du6.lw.train1, newdata = test.data.1, re.form = NA, type = "response")
test.data.1$preds.class <- cut (test.data.1$preds, # put into classes; 0 to 0.4, based on max and min values
                                breaks = c (-Inf, 0.04, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28, 0.32, 0.36, Inf), 
                                labels = c ("0.02", "0.06", "0.10", "0.14", "0.18",
                                            "0.22", "0.26", "0.30", "0.34", "0.38"))
write.csv (test.data.1, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\rsf_preds_du6_lw_train1.csv")
test.data.1.used <- dplyr::filter (test.data.1, pttype == 1)

table.kfold [1, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.02"))
table.kfold [2, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.06"))
table.kfold [3, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.10"))
table.kfold [4, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.14"))
table.kfold [5, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.18"))
table.kfold [6, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.22"))
table.kfold [7, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.26"))
table.kfold [8, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.30"))
table.kfold [9, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.34"))
table.kfold [10, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.38"))

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

table.kfold [1, 7] <- 1.02023
table.kfold [1, 8] <- "<0.001"
table.kfold [1, 9] <- -27.39636
table.kfold [1, 10] <- 0.815
table.kfold [1, 11] <- 0.9694

chisq.test(dplyr::filter(table.kfold, test.number == 1)$used.count, dplyr::filter(table.kfold, test.number == 1)$expected.count)
table.kfold [1, 12] <- 0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\table_kfold_valid_du6_lw.csv")


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
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du6_lw_grp1.png")


### FOLD 2 ###
train.data.2 <- rsf.data.combo.du6.lw %>%
  filter (group == 1 | group == 2 | group == 3 | group == 5)
test.data.2 <- rsf.data.combo.du6.lw %>%
  filter (group == 4)

model.lme4.du6.lw.train2 <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                     std.distance_to_watercourse + 
                                     std.distance_to_cut_1to4yo + 
                                     std.distance_to_cut_5to9yo +
                                     std.distance_to_cut_10yoorOver + 
                                     std.distance_to_paved_road +
                                     std.distance_to_resource_road + 
                                     std.distance_to_pipeline + 
                                     beetle_1to5yo + beetle_6to9yo + 
                                     fire_1to5yo + fire_6to25yo + fire_over25yo +
                                     std.growing_degree_days + 
                                     std.ppt_as_snow_winter +
                                     bec_label + wetland_demars + 
                                     std.vri_bryoid_cover_pct + 
                                     std.vri_herb_cover_pct + 
                                     std.vri_proj_age + 
                                     std.vri_shrub_crown_close + 
                                     std.vri_proj_height + 
                                     std.vri_crown_closure +
                                     (1 | uniqueID), 
                                   data = train.data.2, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.combo.du6.lw$preds.train2 <- predict (model.lme4.du6.lw.train2, 
                                               newdata = rsf.data.combo.du6.lw, 
                                               re.form = NA, type = "response")
max (rsf.data.combo.du6.lw$preds.train2)
min (rsf.data.combo.du6.lw$preds.train2)
rsf.data.combo.du6.lw$preds.train2.class <- cut (rsf.data.combo.du6.lw$preds.train2, # put into classes; 0 to 0.4, based on max and min values
                                                 breaks = c (-Inf, 0.04, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28, 0.32, 0.36, Inf), 
                                                 labels = c ("0.02", "0.06", "0.10", "0.14", "0.18",
                                                             "0.22", "0.26", "0.30", "0.34", "0.38"))
write.csv (rsf.data.combo.du6.lw, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du6_lw.csv")
rsf.data.combo.du6.lw.avail <- dplyr::filter (rsf.data.combo.du6.lw, pttype == 0)

table.kfold [c (11:20), 1] <- 2

table.kfold [11, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train2.class == "0.02")) * 0.02) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [12, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train2.class == "0.06")) * 0.06)
table.kfold [13, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train2.class == "0.10")) * 0.10)
table.kfold [14, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train2.class == "0.14")) * 0.14)
table.kfold [15, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train2.class == "0.18")) * 0.18)
table.kfold [16, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train2.class == "0.22")) * 0.22)
table.kfold [17, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train2.class == "0.26")) * 0.26)
table.kfold [18, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train2.class == "0.30")) * 0.30)
table.kfold [19, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train2.class == "0.34")) * 0.34)
table.kfold [20, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train2.class == "0.38")) * 0.38)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\table_kfold_valid_du6_lw.csv")

# data for estimating use
test.data.2$preds <- predict (model.lme4.du6.lw.train2, newdata = test.data.2, re.form = NA, type = "response")
test.data.2$preds.class <- cut (test.data.2$preds, # put into classes; 0 to 0.4, based on max and min values
                                breaks = c (-Inf, 0.04, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28, 0.32, 0.36, Inf), 
                                labels = c ("0.02", "0.06", "0.10", "0.14", "0.18",
                                            "0.22", "0.26", "0.30", "0.34", "0.38"))
write.csv (test.data.2, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\rsf_preds_du6_lw_train2.csv")
test.data.2.used <- dplyr::filter (test.data.2, pttype == 1)

table.kfold [11, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.02"))
table.kfold [12, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.06"))
table.kfold [13, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.10"))
table.kfold [14, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.14"))
table.kfold [15, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.18"))
table.kfold [16, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.22"))
table.kfold [17, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.26"))
table.kfold [18, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.30"))
table.kfold [19, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.34"))
table.kfold [20, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.38"))

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

table.kfold [11, 7] <- 1.08018
table.kfold [11, 8] <- "<0.001"
table.kfold [11, 9] <- -124.25032
table.kfold [11, 10] <- 0.262
table.kfold [11, 11] <- 0.9819

chisq.test(dplyr::filter(table.kfold, test.number == 2)$used.count, dplyr::filter(table.kfold, test.number == 2)$expected.count)
table.kfold [11, 12] <- 0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\table_kfold_valid_du6_lw.csv")


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
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du6_lw_grp2.png")

write.csv (test.data.2, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\rsf_preds_du6_lw_train2.csv")

### FOLD 3 ###
train.data.3 <- rsf.data.combo.du6.lw %>%
  filter (group == 1 | group == 2 | group == 4 | group == 5)
test.data.3 <- rsf.data.combo.du6.lw %>%
  filter (group == 3)

model.lme4.du6.lw.train3 <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                     std.distance_to_watercourse + 
                                     std.distance_to_cut_1to4yo + 
                                     std.distance_to_cut_5to9yo +
                                     std.distance_to_cut_10yoorOver + 
                                     std.distance_to_paved_road +
                                     std.distance_to_resource_road + 
                                     std.distance_to_pipeline + 
                                     beetle_1to5yo + beetle_6to9yo + 
                                     fire_1to5yo + fire_6to25yo + fire_over25yo +
                                     std.growing_degree_days + 
                                     std.ppt_as_snow_winter +
                                     bec_label + wetland_demars + 
                                     std.vri_bryoid_cover_pct + 
                                     std.vri_herb_cover_pct + 
                                     std.vri_proj_age + 
                                     std.vri_shrub_crown_close + 
                                     std.vri_proj_height + 
                                     std.vri_crown_closure +
                                     (1 | uniqueID), 
                                   data = train.data.3, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.combo.du6.lw$preds.train3 <- predict (model.lme4.du6.lw.train3, 
                                               newdata = rsf.data.combo.du6.lw, 
                                               re.form = NA, type = "response")
max (rsf.data.combo.du6.lw$preds.train3)
min (rsf.data.combo.du6.lw$preds.train3)
rsf.data.combo.du6.lw$preds.train3.class <- cut (rsf.data.combo.du6.lw$preds.train3, # put into classes; 0 to 0.4, based on max and min values
                                                 breaks = c (-Inf, 0.04, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28, 0.32, 0.36, Inf), 
                                                 labels = c ("0.02", "0.06", "0.10", "0.14", "0.18",
                                                             "0.22", "0.26", "0.30", "0.34", "0.38"))
write.csv (rsf.data.combo.du6.lw, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du6_lw.csv")
rsf.data.combo.du6.lw.avail <- dplyr::filter (rsf.data.combo.du6.lw, pttype == 0)

table.kfold [c (21:30), 1] <- 3

table.kfold [21, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train3.class == "0.02")) * 0.02) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [22, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train3.class == "0.06")) * 0.06)
table.kfold [23, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train3.class == "0.10")) * 0.10)
table.kfold [24, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train3.class == "0.14")) * 0.14)
table.kfold [25, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train3.class == "0.18")) * 0.18)
table.kfold [26, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train3.class == "0.22")) * 0.22)
table.kfold [27, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train3.class == "0.26")) * 0.26)
table.kfold [28, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train3.class == "0.30")) * 0.30)
table.kfold [29, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train3.class == "0.34")) * 0.34)
table.kfold [30, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train3.class == "0.38")) * 0.38)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\table_kfold_valid_du6_lw.csv")

# data for estimating use
test.data.3$preds <- predict (model.lme4.du6.lw.train3, newdata = test.data.3, re.form = NA, type = "response")
test.data.3$preds.class <- cut (test.data.3$preds, # put into classes; 0 to 0.4, based on max and min values
                                breaks = c (-Inf, 0.04, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28, 0.32, 0.36, Inf), 
                                labels = c ("0.02", "0.06", "0.10", "0.14", "0.18",
                                            "0.22", "0.26", "0.30", "0.34", "0.38"))
write.csv (test.data.3, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\rsf_preds_du6_lw_train3.csv")
test.data.3.used <- dplyr::filter (test.data.3, pttype == 1)

table.kfold [21, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.02"))
table.kfold [22, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.06"))
table.kfold [23, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.10"))
table.kfold [24, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.14"))
table.kfold [25, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.18"))
table.kfold [26, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.22"))
table.kfold [27, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.26"))
table.kfold [28, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.30"))
table.kfold [29, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.34"))
table.kfold [30, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.38"))

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

table.kfold [21, 7] <- 1.08735
table.kfold [21, 8] <- "<0.001"
table.kfold [21, 9] <- -137.25596
table.kfold [21, 10] <- 0.217
table.kfold [21, 11] <- 0.9826

chisq.test(dplyr::filter(table.kfold, test.number == 3)$used.count, dplyr::filter(table.kfold, test.number == 3)$expected.count)
table.kfold [21, 12] <- 0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\table_kfold_valid_du6_lw.csv")

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
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du6_lw_grp3.png")

write.csv (test.data.3, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\rsf_preds_du6_lw_train3.csv")

### FOLD 4 ###
train.data.4 <- rsf.data.combo.du6.lw %>%
  filter (group == 1 | group == 3 | group == 4 | group == 5)
test.data.4 <- rsf.data.combo.du6.lw %>%
  filter (group == 2)

model.lme4.du6.lw.train4 <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                     std.distance_to_watercourse + 
                                     std.distance_to_cut_1to4yo + 
                                     std.distance_to_cut_5to9yo +
                                     std.distance_to_cut_10yoorOver + 
                                     std.distance_to_paved_road +
                                     std.distance_to_resource_road + 
                                     std.distance_to_pipeline + 
                                     beetle_1to5yo + beetle_6to9yo + 
                                     fire_1to5yo + fire_6to25yo + fire_over25yo +
                                     std.growing_degree_days + 
                                     std.ppt_as_snow_winter +
                                     bec_label + wetland_demars + 
                                     std.vri_bryoid_cover_pct + 
                                     std.vri_herb_cover_pct + 
                                     std.vri_proj_age + 
                                     std.vri_shrub_crown_close + 
                                     std.vri_proj_height + 
                                     std.vri_crown_closure +
                                     (1 | uniqueID), 
                                   data = train.data.4, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
ss <- getME (model.lme4.du6.lw.train4, c ("theta","fixef"))
model.lme4.du6.lw.train4 <- update (model.lme4.du6.lw.train4, start = ss) # failed to converge, restart with parameter estimates

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.combo.du6.lw$preds.train4 <- predict (model.lme4.du6.lw.train4, 
                                               newdata = rsf.data.combo.du6.lw, 
                                               re.form = NA, type = "response")
max (rsf.data.combo.du6.lw$preds.train4)
min (rsf.data.combo.du6.lw$preds.train4)
rsf.data.combo.du6.lw$preds.train4.class <- cut (rsf.data.combo.du6.lw$preds.train4, # put into classes; 0 to 0.4, based on max and min values
                                                 breaks = c (-Inf, 0.04, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28, 0.32, 0.36, Inf), 
                                                 labels = c ("0.02", "0.06", "0.10", "0.14", "0.18",
                                                             "0.22", "0.26", "0.30", "0.34", "0.38"))
write.csv (rsf.data.combo.du6.lw, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du6_lw.csv")
rsf.data.combo.du6.lw.avail <- dplyr::filter (rsf.data.combo.du6.lw, pttype == 0)

table.kfold [c (31:40), 1] <- 4

table.kfold [31, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train4.class == "0.02")) * 0.02) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [32, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train4.class == "0.06")) * 0.06)
table.kfold [33, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train4.class == "0.10")) * 0.10)
table.kfold [34, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train4.class == "0.14")) * 0.14)
table.kfold [35, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train4.class == "0.18")) * 0.18)
table.kfold [36, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train4.class == "0.22")) * 0.22)
table.kfold [37, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train4.class == "0.26")) * 0.26)
table.kfold [38, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train4.class == "0.30")) * 0.30)
table.kfold [39, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train4.class == "0.34")) * 0.34)
table.kfold [40, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train4.class == "0.38")) * 0.38)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\table_kfold_valid_du6_lw.csv")

# data for estimating use
test.data.4$preds <- predict (model.lme4.du6.lw.train4, newdata = test.data.4, re.form = NA, type = "response")
test.data.4$preds.class <- cut (test.data.4$preds, # put into classes; 0 to 0.4, based on max and min values
                                breaks = c (-Inf, 0.04, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28, 0.32, 0.36, Inf), 
                                labels = c ("0.02", "0.06", "0.10", "0.14", "0.18",
                                            "0.22", "0.26", "0.30", "0.34", "0.38"))
write.csv (test.data.4, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\rsf_preds_du6_lw_train4.csv")
test.data.4.used <- dplyr::filter (test.data.4, pttype == 1)

table.kfold [31, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.02"))
table.kfold [32, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.06"))
table.kfold [33, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.10"))
table.kfold [34, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.14"))
table.kfold [35, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.18"))
table.kfold [36, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.22"))
table.kfold [37, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.26"))
table.kfold [38, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.30"))
table.kfold [39, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.34"))
table.kfold [40, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.38"))

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

table.kfold [31, 7] <- 1.05713
table.kfold [31, 8] <- "<0.001"
table.kfold [31, 9] <- -87.45899
table.kfold [31, 10] <- 0.387
table.kfold [31, 11] <- 0.9831

chisq.test(dplyr::filter(table.kfold, test.number == 4)$used.count, dplyr::filter(table.kfold, test.number == 4)$expected.count)
table.kfold [31, 12] <- 0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\table_kfold_valid_du6_lw.csv")


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
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du6_lw_grp4.png")

write.csv (test.data.4, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\rsf_preds_du6_lw_train4.csv")

### FOLD 5 ###
train.data.5 <- rsf.data.combo.du6.lw %>%
  filter (group == 5 | group == 2 | group == 3 | group == 4)
test.data.5 <- rsf.data.combo.du6.lw %>%
  filter (group == 1)

model.lme4.du6.lw.train5 <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                     std.distance_to_watercourse + 
                                     std.distance_to_cut_1to4yo + 
                                     std.distance_to_cut_5to9yo +
                                     std.distance_to_cut_10yoorOver + 
                                     std.distance_to_paved_road +
                                     std.distance_to_resource_road + 
                                     std.distance_to_pipeline + 
                                     beetle_1to5yo + beetle_6to9yo + 
                                     fire_1to5yo + fire_6to25yo + fire_over25yo +
                                     std.growing_degree_days + 
                                     std.ppt_as_snow_winter +
                                     bec_label + wetland_demars + 
                                     std.vri_bryoid_cover_pct + 
                                     std.vri_herb_cover_pct + 
                                     std.vri_proj_age + 
                                     std.vri_shrub_crown_close + 
                                     std.vri_proj_height + 
                                     std.vri_crown_closure +
                                     (1 | uniqueID), 
                                   data = train.data.5, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.combo.du6.lw$preds.train5 <- predict (model.lme4.du6.lw.train5, 
                                               newdata = rsf.data.combo.du6.lw, 
                                               re.form = NA, type = "response")
max (rsf.data.combo.du6.lw$preds.train5)
min (rsf.data.combo.du6.lw$preds.train5)
rsf.data.combo.du6.lw$preds.train5.class <- cut (rsf.data.combo.du6.lw$preds.train5, # put into classes; 0 to 0.4, based on max and min values
                                                 breaks = c (-Inf, 0.04, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28, 0.32, 0.36, Inf), 
                                                 labels = c ("0.02", "0.06", "0.10", "0.14", "0.18",
                                                             "0.22", "0.26", "0.30", "0.34", "0.38"))
write.csv (rsf.data.combo.du6.lw, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du6_lw.csv")
rsf.data.combo.du6.lw.avail <- dplyr::filter (rsf.data.combo.du6.lw, pttype == 0)

table.kfold [c (41:50), 1] <- 5

table.kfold [41, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train5.class == "0.02")) * 0.02) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [42, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train5.class == "0.06")) * 0.06)
table.kfold [43, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train5.class == "0.10")) * 0.10)
table.kfold [44, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train5.class == "0.14")) * 0.14)
table.kfold [45, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train5.class == "0.18")) * 0.18)
table.kfold [46, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train5.class == "0.22")) * 0.22)
table.kfold [47, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train5.class == "0.26")) * 0.26)
table.kfold [48, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train5.class == "0.30")) * 0.30)
table.kfold [49, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train5.class == "0.34")) * 0.34)
table.kfold [50, 3] <- (nrow (dplyr::filter (rsf.data.combo.du6.lw.avail, preds.train5.class == "0.38")) * 0.38)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\table_kfold_valid_du6_lw.csv")

# data for estimating use
test.data.5$preds <- predict (model.lme4.du6.lw.train5, newdata = test.data.5, re.form = NA, type = "response")
test.data.5$preds.class <- cut (test.data.5$preds, # put into classes; 0 to 0.4, based on max and min values
                                breaks = c (-Inf, 0.04, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28, 0.32, 0.36, Inf), 
                                labels = c ("0.02", "0.06", "0.10", "0.14", "0.18",
                                            "0.22", "0.26", "0.30", "0.34", "0.38"))
write.csv (test.data.5, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\rsf_preds_du6_lw_train5.csv")
test.data.5.used <- dplyr::filter (test.data.5, pttype == 1)

table.kfold [41, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.02"))
table.kfold [42, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.06"))
table.kfold [43, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.10"))
table.kfold [44, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.14"))
table.kfold [45, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.18"))
table.kfold [46, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.22"))
table.kfold [47, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.26"))
table.kfold [48, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.30"))
table.kfold [49, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.34"))
table.kfold [50, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.38"))

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

table.kfold [41, 7] <- 1.02491
table.kfold [41, 8] <- "<0.001"
table.kfold [41, 9] <- -35.34741
table.kfold [41, 10] <- 0.645
table.kfold [41, 11] <- 0.9886

chisq.test(dplyr::filter(table.kfold, test.number == 5)$used.count, dplyr::filter(table.kfold, test.number == 5)$expected.count)
table.kfold [41, 12] <- 0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\table_kfold_valid_du6_lw.csv")


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
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du6_lw_grp5.png")

write.csv (test.data.5, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\rsf_preds_du6_lw_train5.csv")

# create results table
table.kfold.results.du6.lw <- table.kfold
table.kfold.results.du6.lw <- table.kfold.results.du6.lw [- c (2:6)]

table.kfold.results.du6.lw <- table.kfold.results.du6.lw %>%
  slice (c (1, 11, 21, 31, 41))

write.csv (table.kfold.results.du6.lw, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\late_winter\\table_kfold_summary_du6_lw.csv")

###############################
### RSF RASTER CALCULATION ###
#############################

### LOAD RASTERS ###
slope <- raster ("C:\\Work\\caribou\\clus_data\\dem\\slope_deg_all_bc_8_clip.tif")
dist.lake <- raster ("C:\\Work\\caribou\\clus_data\\water\\raster_dist_to_lakes_bcalbers_20180820.tif")
dist.water <- raster ("C:\\Work\\caribou\\clus_data\\water\\raster_dist_to_watercourses_bcalbers_20180820.tif")
dist.cut.1to4 <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_1to4yo.tif")
dist.cut.5to9 <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_5to9yo.tif")
dist.cut.10over <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_10yo_over.tif")
dist.paved.rd <- raster ("C:\\Work\\caribou\\clus_data\\roads_ha_bc\\dist_crds_paved.tif")
dist.resource.rd <- raster ("C:\\Work\\caribou\\clus_data\\roads_ha_bc\\dist_crds_resource.tif")
dist.pipeline <- raster ("C:\\Work\\caribou\\clus_data\\pipelines\\raster_distance_to_pipelines_bcalbers_20180815.tif")
beetle.1to5 <- raster ("C:\\Work\\caribou\\clus_data\\forest_health\\raster_bark_beetle_all_1to5yo_fin.tif")
beetle.6to9 <- raster ("C:\\Work\\caribou\\clus_data\\forest_health\\raster_bark_beetle_all_6to9yo_fin.tif")
fire.1to5 <- raster ("C:\\Work\\caribou\\clus_data\\fire\\fire_tiffs\\raster_fire_1to5yo_fin.tif")
fire.6to25 <- raster ("C:\\Work\\caribou\\clus_data\\fire\\fire_tiffs\\raster_fire_6to25yo_fin.tif")
fire.over25 <- raster ("C:\\Work\\caribou\\clus_data\\fire\\fire_tiffs\\raster_fire_over25yo_fin.tif")
growing.degree.day <- raster ("C:\\Work\\caribou\\clus_data\\climate\\annual\\dd5")
ppt.as.snow.winter <- raster ("C:\\Work\\caribou\\clus_data\\climate\\seasonal\\pas_wt")
bec.bwbs.mw <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_bwbs_mw.tif")
wet.conifer.swamp <- raster ("C:\\Work\\caribou\\clus_data\\wetland\\boreal\\raster_demars_wetland_coniferswamp.tif")
wet.decid.swamp <- raster ("C:\\Work\\caribou\\clus_data\\wetland\\boreal\\raster_demars_wetland_deciduousswamp.tif")
wet.poor.fen <- raster ("C:\\Work\\caribou\\clus_data\\wetland\\boreal\\raster_demars_wetland_nutrientpoorfen.tif")
wet.rich.fen <- raster ("C:\\Work\\caribou\\clus_data\\wetland\\boreal\\raster_demars_wetland_nutrientrichfen.tif")
wet.other <- raster ("C:\\Work\\caribou\\clus_data\\wetland\\boreal\\raster_demars_wetland_other.tif")
wet.tree.bog <- raster ("C:\\Work\\caribou\\clus_data\\wetland\\boreal\\raster_demars_wetland_treedbog.tif")
wet.upland.decid <- raster ("C:\\Work\\caribou\\clus_data\\wetland\\boreal\\raster_demars_wetland_uplanddeciduous.tif")
vri.bryoid <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\vri_bryoidcoverpct.tif")
vri.herb <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\vri_herbcoverpct.tif")
vri.age <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\vri_projage1.tif")
vri.shrub <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\vri_shrubcrownclosure.tif")
vri.height <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\vri_projheight1.tif")
vri.crown.close <- raster ("C:\\Work\\caribou\\clus_data\\vegetation\\vri_crownclosure.tif")

### CROP RASTERS TO DU; USED "BOX' "of HERD RANGES PLUS 25km BUFFER ###
caribou.boreal.sa <- readOGR ("C:\\Work\\caribou\\climate_analysis\\data\\studyarea\\caribou_boreal_study_area.shp", stringsAsFactors = T) # herds with 25km buffer
slope <- crop (slope, extent (caribou.boreal.sa))
dist.lake <- crop (dist.lake, extent (caribou.boreal.sa))
dist.water <- crop (dist.water, extent (caribou.boreal.sa))
dist.cut.1to4 <- crop (dist.cut.1to4, extent (caribou.boreal.sa))
dist.cut.5to9 <- crop (dist.cut.5to9, extent (caribou.boreal.sa))
dist.cut.10over <- crop (dist.cut.10over, extent (caribou.boreal.sa))
dist.paved.rd <- crop (dist.paved.rd, extent (caribou.boreal.sa))
dist.resource.rd <- crop (dist.resource.rd, extent (caribou.boreal.sa))
dist.pipeline <- crop (dist.pipeline, extent (caribou.boreal.sa))
beetle.1to5 <- crop (beetle.1to5, extent (caribou.boreal.sa))
beetle.6to9 <- crop (beetle.6to9, extent (caribou.boreal.sa))
fire.1to5 <- crop (fire.1to5, extent (caribou.boreal.sa))
fire.6to25 <- crop (fire.6to25, extent (caribou.boreal.sa))
fire.over25 <- crop (fire.over25, extent (caribou.boreal.sa))
bec.bwbs.mw <- crop (bec.bwbs.mw, extent (caribou.boreal.sa))
wet.conifer.swamp <- crop (wet.conifer.swamp, extent (caribou.boreal.sa))
wet.decid.swamp <- crop (wet.decid.swamp, extent (caribou.boreal.sa))
wet.poor.fen <- crop (wet.poor.fen, extent (caribou.boreal.sa))
wet.rich.fen <- crop (wet.rich.fen, extent (caribou.boreal.sa))
wet.other <- crop (wet.other, extent (caribou.boreal.sa))
wet.tree.bog <- crop (wet.tree.bog, extent (caribou.boreal.sa))
wet.upland.decid <- crop (wet.upland.decid, extent (caribou.boreal.sa))
vri.bryoid <- crop (vri.bryoid, extent (caribou.boreal.sa))
vri.herb <- crop (vri.herb, extent (caribou.boreal.sa))
vri.age <- crop (vri.age, extent (caribou.boreal.sa))
vri.shrub <- crop (vri.shrub, extent (caribou.boreal.sa))
vri.height <- crop (vri.height, extent (caribou.boreal.sa))
vri.crown.close <- crop (vri.crown.close, extent (caribou.boreal.sa))

proj.crs <- proj4string (caribou.boreal.sa)
growing.degree.day <- projectRaster (growing.degree.day, crs = proj.crs, method = "bilinear")
ppt.as.snow.winter <- projectRaster (ppt.as.snow.winter, crs = proj.crs, method = "bilinear")
growing.degree.day <- crop (growing.degree.day, extent (caribou.boreal.sa))
ppt.as.snow.winter <- crop (ppt.as.snow.winter, extent (caribou.boreal.sa))

## MAKE RASTERS THE SAME RESOLUTION FOR CALC ###
beginCluster ()

slope <- resample (slope, dist.lake, method = 'bilinear')
writeRaster (slope, "C:\\Work\\caribou\\clus_data\\rsf\\du6\\late_winter\\slope_resample.tif", 
             format = "GTiff")
growing.degree.day <- resample (growing.degree.day, dist.lake, method = 'bilinear')
writeRaster (growing.degree.day, "C:\\Work\\caribou\\clus_data\\rsf\\du6\\late_winter\\grow_deg_day.tif", 
             format = "GTiff")
ppt.as.snow.winter <- resample (ppt.as.snow.winter, dist.lake, method = 'bilinear')
writeRaster (ppt.as.snow.winter, "C:\\Work\\caribou\\clus_data\\rsf\\du6\\late_winter\\ppt_snow_winter.tif", 
             format = "GTiff")
wet.conifer.swamp <- resample (wet.conifer.swamp, dist.lake, method = 'ngb')
writeRaster (wet.conifer.swamp, "C:\\Work\\caribou\\clus_data\\rsf\\du6\\late_winter\\conifer_swamp.tif", 
             format = "GTiff")
wet.decid.swamp <- resample (wet.decid.swamp, dist.lake, method = 'ngb')
writeRaster (wet.decid.swamp, "C:\\Work\\caribou\\clus_data\\rsf\\du6\\late_winter\\deciduous_swamp.tif", 
             format = "GTiff")
wet.poor.fen <- resample (wet.poor.fen, dist.lake, method = 'ngb')
writeRaster (wet.poor.fen, "C:\\Work\\caribou\\clus_data\\rsf\\du6\\late_winter\\poor_fen.tif", 
             format = "GTiff")
wet.rich.fen <- resample (wet.rich.fen, dist.lake, method = 'ngb')
writeRaster (wet.rich.fen, "C:\\Work\\caribou\\clus_data\\rsf\\du6\\late_winter\\rich_fen.tif", 
             format = "GTiff")
wet.other <- resample (wet.other, dist.lake, method = 'ngb')
writeRaster (wet.other, "C:\\Work\\caribou\\clus_data\\rsf\\du6\\late_winter\\wet_other.tif", 
             format = "GTiff")
wet.tree.bog <- resample (wet.tree.bog, dist.lake, method = 'ngb')
writeRaster (wet.tree.bog, "C:\\Work\\caribou\\clus_data\\rsf\\du6\\late_winter\\treed_bog.tif", 
             format = "GTiff")
wet.upland.decid <- resample (wet.upland.decid, dist.lake, method = 'ngb')
writeRaster (wet.upland.decid, "C:\\Work\\caribou\\clus_data\\rsf\\du6\\late_winter\\upland_deciduous.tif", 
             format = "GTiff")
wet.rich.fen <- resample (wet.rich.fen, dist.lake, method = 'ngb')
writeRaster (wet.rich.fen, "C:\\Work\\caribou\\clus_data\\rsf\\du6\\late_winter\\rich_fen.tif", 
             format = "GTiff", overwrite = T)
bec.bwbs.mw <- resample (bec.bwbs.mw, dist.lake, method = 'ngb')
writeRaster (bec.bwbs.mw, "C:\\Work\\caribou\\clus_data\\rsf\\du6\\late_winter\\bec_bwbs_mw.tif", 
             format = "GTiff", overwrite = T)
endCluster ()

### Adjust the raster data for 'standardized' model covariates ###
beginCluster ()

system.time (std.slope <- (slope - 1.34) / 1.82) # rounded these numbers to facilitate faster processing; decreases processing time substantially
std.dist.lake <- (dist.lake - 1931) / 1578
std.dist.water <- (dist.water - 7895) / 5458
std.dist.cut.1to4 <- (dist.cut.1to4 - 77316) / 62909
std.dist.cut.5to9 <- (dist.cut.5to9 - 42943) / 34048
std.dist.cut.10over <- (dist.cut.10over - 21327) / 21454
std.dist.paved.rd <- (dist.paved.rd - 23662) / 16945
std.dist.resource.rd <- (dist.resource.rd - 611) / 571
std.dist.pipeline <- (dist.pipeline - 4452) / 5101
std.growing.degree.day <- (growing.degree.day - 1156) / 79
std.ppt.as.snow.winter <- (ppt.as.snow.winter - 69) / 6
std.vri.bryoid <- (vri.bryoid - 17) / 16
std.vri.herb <- (vri.herb - 12) / 12
std.vri.age <- (vri.age - 98) / 38
std.vri.shrub <- (vri.shrub - 25) / 18
std.vri.height <- (vri.height - 9) / 6
std.vri.crown.close <- (vri.crown.close - 33) / 18

endCluster ()

### CALCULATE RASTER OF STATIC VARIABLES ###
beginCluster ()

raster.rsf.static <- (-2.07 + (std.slope * -0.04) + (std.dist.lake * 0.01) +
                        (std.dist.water * 0.01) + (std.vri.bryoid * 0.14) +
                        (std.vri.herb * 0.02) + (std.vri.shrub * 0.05) + 
                        (wet.conifer.swamp * 0.08) + (wet.decid.swamp * -0.32) +
                        (wet.poor.fen * 0.35) + (wet.rich.fen * -0.07) +
                        (wet.other * 0.31) + (wet.tree.bog * 0.65) + 
                        (wet.upland.decid * -1.07))
writeRaster (raster.rsf.static, "C:\\Work\\caribou\\clus_data\\rsf\\du6\\late_winter\\rsf_static_du6_lw.tif", 
             format = "GTiff")

raster.rsf <- exp (raster.rsf.static + (std.dist.cut.1to4 * -0.06) + 
                     (std.dist.cut.5to9 * -0.05) + (std.dist.cut.10over * -0.01) +
                     (std.dist.paved.rd * -0.002) + (std.dist.resource.rd * 0.03) +
                     (std.dist.pipeline * 0.06) + (beetle.1to5 * 0.21) + 
                     (beetle.6to9 * -0.06) + (fire.1to5 * -0.25) + 
                     (fire.6to25 * -0.41) + (fire.over25 * -0.21) + 
                     (std.growing.degree.day * 0.04) + (std.ppt.as.snow.winter * -0.04) +
                     (bec.bwbs.mw * -0.13)  + (std.vri.age * 0.08) + 
                     (std.vri.height * -0.21) + (std.vri.crown.close * 0.08)) / 
  1 + exp (raster.rsf.static + (std.dist.cut.1to4 * -0.06) + 
             (std.dist.cut.5to9 * -0.05) + (std.dist.cut.10over * -0.01) +
             (std.dist.paved.rd * -0.002) + (std.dist.resource.rd * 0.03) +
             (std.dist.pipeline * 0.06) + (beetle.1to5 * 0.21) + 
             (beetle.6to9 * -0.06) + (fire.1to5 * -0.25) + 
             (fire.6to25 * -0.41) + (fire.over25 * -0.21) + 
             (std.growing.degree.day * 0.04) + (std.ppt.as.snow.winter * -0.04) +
             (bec.bwbs.mw * -0.13)  + (std.vri.age * 0.08) + 
             (std.vri.height * -0.21) + (std.vri.crown.close * 0.08))
writeRaster (raster.rsf, "C:\\Work\\caribou\\clus_data\\rsf\\du6\\late_winter\\rsf_du6_lw.tif", 
             format = "GTiff")
