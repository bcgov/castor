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
#  Script Name: 12_caribou_RSF_boreal_summer.R
#  Script Version: 1.0
#  Script Purpose: Script to develop caribou RSF model for DU6 and Late winter.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 20 February 2019
#  R Version: 
#  R Packages: 
#  Data: 
#=================================

#==========================================
# TO TURN SCRIPT FOR DIFFERENT DUs and SEASONS:
# Find and Replace:
# 1. .ew .lw .s _ew _lw _s
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

test <- rsf.data.climate.summer %>% filter (is.na (summer_growing_degree_days))
rsf.data.climate.summer <- rsf.data.climate.summer %>% 
                                filter (!is.na (summer_growing_degree_days))

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

rsf.data.combo <- rsf.data.terrain.water [, c (1:9, 10, 13:15, 17)]
rm (rsf.data.terrain.water)
gc ()
rsf.data.combo$soil_parent_material_name <- relevel (rsf.data.combo$soil_parent_material_name,
                                                            ref = "Till")
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
                                    rsf.data.veg [, c (9, 10, 17)],
                                    by = "ptID")
rm (rsf.data.veg)
gc ()

rsf.data.combo.du6.s <- rsf.data.combo %>%
                          dplyr::filter (du == "du6") %>%
                          dplyr::filter (season == "Summer")

# group cutblock ages together, as per forest cutblcok model results
rsf.data.combo.du6.s <- dplyr::mutate (rsf.data.combo.du6.s, distance_to_cut_10yoorOver = pmin (distance_to_cut_10to29yo, distance_to_cut_30orOveryo))
rsf.data.combo.du6.s <- rsf.data.combo.du6.s %>% 
                          filter (!is.na (wetland_demars))
rsf.data.combo.du6.s$bec_label <- relevel (rsf.data.combo.du6.s$bec_label,
                                            ref = "BWBSmk")
rsf.data.combo.du6.s$wetland_demars <- relevel (rsf.data.combo.du6.s$wetland_demars,
                                                 ref = "Upland Conifer") # upland confier as referencce, as per Demars 2018
write.csv (rsf.data.combo.du6.s, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\summer\\rsf_data_combo_du6_s.csv")






#######################
### FITTING MODELS ###
#####################


#=================================
# Terrain and Water Models
#=================================
rsf.data.terrain.water.du6.s <- rsf.data.terrain.water %>%
                                  dplyr::filter (du == "du6") %>%
                                  dplyr::filter (season == "Summer")
rsf.data.terrain.water.du6.s$soil_parent_material_name <- relevel (rsf.data.terrain.water.du6.s$soil_parent_material_name,
                                                                    ref = "Till")
### OUTLIERS ###
ggplot (rsf.data.terrain.water.du6.s, aes (x = pttype, y = slope)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Late Winter Slope at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Slope")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_s_slope.png")

####
rsf.data.terrain.water.du6.s <- rsf.data.terrain.water.du6.s %>%
                                  filter (slope < 75) # remove outlier
####
ggplot (rsf.data.terrain.water.du6.s, aes (x = pttype, y = distance_to_lake)) +
            geom_boxplot (outlier.colour = "red") +
            labs (title = "Boxplot DU6, Late Winter Distance to Lake \
                  at Available (0) and Used (1) Locations",
                  x = "Available (0) and Used (1) Locations",
                  y = "Distance to Lake")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_s_dist_lake.png")
ggplot (rsf.data.terrain.water.du6.s, aes (x = pttype, y = distance_to_watercourse)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Watercourse \
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Watercourse")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_s_dist_watercourse.png")

### HISTOGRAMS ###
ggplot (rsf.data.terrain.water.du6.s, aes (x = slope, fill = pttype)) + 
          geom_histogram (position = "dodge", binwidth = 5) +
          labs (title = "Histogram DU6, Late Winter Slope at Available (0) and Used (1) Locations",
                x = "Slope",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_s_slope.png")
ggplot (rsf.data.terrain.water.du6.s, aes (x = distance_to_lake, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 200) +
        labs (title = "Histogram DU6, Late Winter Distance to Lake at Available (0) and Used (1) Locations",
              x = "Distance to Lake",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_s_dist_lake.png")
ggplot (rsf.data.terrain.water.du6.s, aes (x = distance_to_watercourse, fill = pttype)) + 
          geom_histogram (position = "dodge", binwidth = 200) +
          labs (title = "Histogram DU6, Late Winter Distance to Watercourse at Available (0) and Used (1) Locations",
                x = "Distance to Watercourse",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_s_dist_watercourse.png")

### CORRELATION ###
corr.terrain.water.du6.s <- rsf.data.terrain.water.du6.s [c (13:15)]
corr.terrain.water.du6.s <- round (cor (corr.terrain.water.du6.s, method = "spearman"), 3)
ggcorrplot (corr.terrain.water.du6.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Terrain and Water Resource Selection Function Model
            Covariate Correlations for DU6, Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_terrain_water_du6_s.png")

### VIF ###
glm.terrain.du6.s <- glm (pttype ~ slope + distance_to_lake +
                                    distance_to_watercourse + soil_parent_material_name, 
                            data = rsf.data.terrain.water.du6.s,
                            family = binomial (link = 'logit'))
car::vif (glm.terrain.du6.s)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

### Generalized Linear Mixed Models (GLMMs) ###
# standardize covariates  (helps with model convergence)
rsf.data.terrain.water.du6.s$std.elevation <- (rsf.data.terrain.water.du6.s$elevation - 
                                                  mean (rsf.data.terrain.water.du6.s$elevation)) / 
                                                  sd (rsf.data.terrain.water.du6.s$elevation)
rsf.data.terrain.water.du6.s$std.easting <- (rsf.data.terrain.water.du6.s$easting - 
                                                  mean (rsf.data.terrain.water.du6.s$easting)) / 
                                                  sd (rsf.data.terrain.water.du6.s$easting)
rsf.data.terrain.water.du6.s$std.northing <- (rsf.data.terrain.water.du6.s$northing - 
                                                mean (rsf.data.terrain.water.du6.s$northing)) / 
                                                sd (rsf.data.terrain.water.du6.s$northing)
rsf.data.terrain.water.du6.s$std.slope <- (rsf.data.terrain.water.du6.s$slope - 
                                                 mean (rsf.data.terrain.water.du6.s$slope)) / 
                                                  sd (rsf.data.terrain.water.du6.s$slope)
rsf.data.terrain.water.du6.s$std.distance_to_lake <- (rsf.data.terrain.water.du6.s$distance_to_lake - 
                                                        mean (rsf.data.terrain.water.du6.s$distance_to_lake)) / 
                                                        sd (rsf.data.terrain.water.du6.s$distance_to_lake)
rsf.data.terrain.water.du6.s$std.distance_to_watercourse <- (rsf.data.terrain.water.du6.s$distance_to_watercourse - 
                                                              mean (rsf.data.terrain.water.du6.s$distance_to_watercourse)) / 
                                                              sd (rsf.data.terrain.water.du6.s$distance_to_watercourse)

## SLOPE ##
model.lme4.du6.s.slope <- glmer (pttype ~ std.slope + (1 | uniqueID), 
                                   data = rsf.data.terrain.water.du6.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Late Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "Slope"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du6.s.slope)

## DISTANCE TO LAKE ##
model.lme4.du6.s.lake <- glmer (pttype ~ std.distance_to_lake + (1 | uniqueID), 
                                  data = rsf.data.terrain.water.du6.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Late Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "Dist. to Lake"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du6.s.lake)

## DISTANCE TO WATERCOURSE ##
model.lme4.du6.s.wc <- glmer (pttype ~ std.distance_to_watercourse  + 
                                          (1 | uniqueID), 
                                 data = rsf.data.terrain.water.du6.s, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Late Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "Dist. to Watercourse"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du6.s.wc)

## SLOPE AND DISTANCE TO LAKE ##
model.lme4.du6.s.slope.lake <- update (model.lme4.du6.s.slope,
                                         . ~ . + std.distance_to_lake) 
# AIC
table.aic [4, 1] <- "DU6"
table.aic [4, 2] <- "Late Winter"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "Slope, Dist. to Lake"
table.aic [4, 5] <- "(1 | UniqueID)"
table.aic [4, 6] <-  AIC (model.lme4.du6.s.slope.lake) 

## SLOPE AND DISTANCE TO WATERCOURSE ##
model.lme4.du6.s.slope.water <- update (model.lme4.du6.s.slope,
                                         . ~ . + std.distance_to_watercourse) 
# AIC
table.aic [5, 1] <- "DU6"
table.aic [5, 2] <- "Late Winter"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "Slope, Dist. to Watercourse"
table.aic [5, 5] <- "(1 | UniqueID)"
table.aic [5, 6] <-  AIC (model.lme4.du6.s.slope.water) 

## DISTANCE TO LAKE AND WATERCOURSE ##
model.lme4.du6.s.lake.water <- update (model.lme4.du6.s.lake,
                                        . ~ . + std.distance_to_watercourse)
# AIC
table.aic [6, 1] <- "DU6"
table.aic [6, 2] <- "Late Winter"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "Dist. to Lake, Dist. to Watercourse"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <-  AIC (model.lme4.du6.s.lake.water)

## SLOPE, DISTANCE TO LAKE AND DISTANCE TO WATERCOURSE ##
model.lme4.du6.s.slope.lake.wc <- update (model.lme4.du6.s.slope.lake,
                                            . ~ . + std.distance_to_watercourse) 
# AIC
table.aic [7, 1] <- "DU6"
table.aic [7, 2] <- "Late Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "Slope, Dist. to Lake, Dist. to Watercourse"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du6.s.slope.lake.wc) 

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

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\summer\\table_aic_terrain_water.csv", sep = ",")


#=================================
# Human Disturbance Models
#=================================
rsf.data.human.dist.du6.s <- rsf.data.human.dist %>%
                                    dplyr::filter (du == "du6") %>%
                                    dplyr::filter (season == "Summer")

# group cutblock ages together, as per forest cutblcok model results
rsf.data.human.dist.du6.s <- dplyr::mutate (rsf.data.human.dist.du6.s, distance_to_cut_10yoorOver = pmin (distance_to_cut_10to29yo, distance_to_cut_30orOveryo))

### OUTLIERS ###
ggplot (rsf.data.human.dist.du6.s, aes (x = pttype, y = distance_to_cut_1to4yo)) +
        geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Cutblocks 1 to 4 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_s_distcut1to4.png")
ggplot (rsf.data.human.dist.du6.s, aes (x = pttype, y = distance_to_cut_5to9yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Cutblocks 5 to 9 Years Old\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_s_distcut5to9.png")
ggplot (rsf.data.human.dist.du6.s, aes (x = pttype, y = distance_to_cut_10yoorOver)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Cutblocks over 10 Years Old\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_s_distcut_over10.png")
ggplot (rsf.data.human.dist.du6.s, aes (x = pttype, y = distance_to_paved_road)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Paved Road\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Paved Road")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_s_dist_pvd_rd.png")
ggplot (rsf.data.human.dist.du6.s, aes (x = pttype, y = distance_to_resource_road)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Resource Road\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Resource Road")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_s_dist_resource_rd.png")
ggplot (rsf.data.human.dist.du6.s, aes (x = pttype, y = distance_to_agriculture)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Agriculture\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Agriculture")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_s_dist_ag.png")
ggplot (rsf.data.human.dist.du6.s, aes (x = pttype, y = distance_to_mines)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Mine\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Mine")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_s_dist_mine.png")
ggplot (rsf.data.human.dist.du6.s, aes (x = pttype, y = distance_to_pipeline)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Pipeline\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Pipeline")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_s_dist_pipe.png")
ggplot (rsf.data.human.dist.du6.s, aes (x = pttype, y = distance_to_wells)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Late Winter Distance to Well\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Well")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_du6_s_dist_well.png")

### HISTOGRAMS ###
ggplot (rsf.data.human.dist.du6.s, aes (x = distance_to_cut_1to4yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 5) +
  labs (title = "Histogram DU6, Late Winter Distance to Cutblock 1 to 4 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Distance to Cutblock",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_s_dist_cut_1to4.png")
ggplot (rsf.data.human.dist.du6.s, aes (x = distance_to_cut_5to9yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 5) +
  labs (title = "Histogram DU6, Late Winter Distance to Cutblock 5 to 9 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Distance to Cutblock",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_s_dist_cut_5to9.png")
ggplot (rsf.data.human.dist.du6.s, aes (x = distance_to_cut_10yoorOver, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 5) +
  labs (title = "Histogram DU6, Late Winter Distance to Cutblock over 10 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Distance to Cutblock",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_s_dist_cut_over10.png")
ggplot (rsf.data.human.dist.du6.s, aes (x = distance_to_paved_road, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Late Winter Distance to Paved Road\
                at Available (0) and Used (1) Locations",
        x = "Distance to Paved Road",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_s_dist_pvd_rd.png")
ggplot (rsf.data.human.dist.du6.s, aes (x = distance_to_resource_road, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Late Winter Distance to Resource Road\
                  at Available (0) and Used (1) Locations",
        x = "Distance to Resource Road",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_s_dist_res_rd.png")
ggplot (rsf.data.human.dist.du6.s, aes (x = distance_to_agriculture, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Late Winter Distance to Agriculture\
                  at Available (0) and Used (1) Locations",
        x = "Distance to Agriculture",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_s_dist_ag.png")
ggplot (rsf.data.human.dist.du6.s, aes (x = distance_to_mines, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Late Winter Distance to Mine at Available (0) and Used (1) Locations",
        x = "Distance to Mine",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_s_dist_mine.png")
ggplot (rsf.data.human.dist.du6.s, aes (x = distance_to_pipeline, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Late Winter Distance to Pipeline at\
                 Available (0) and Used (1) Locations",
        x = "Distance to Pipeline",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_s_dist_pipe.png")
ggplot (rsf.data.human.dist.du6.s, aes (x = distance_to_wells, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Late Winter Distance to Well at\
                 Available (0) and Used (1) Locations",
        x = "Distance to Pipeline",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_du6_s_dist_well.png")

### CORRELATION ###
corr.human.dist.du6.s <- rsf.data.human.dist.du6.s [c (10:11, 27, 14, 26, 20:24)]
corr.human.dist.du6.s <- round (cor (corr.human.dist.du6.s, method = "spearman"), 3)
ggcorrplot (corr.human.dist.du6.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Human Disturbance Resource Selection Function Model
            Covariate Correlations for DU6, Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_human_dist_du6_s.png")

### VIF ###
glm.human.du6.s <- glm (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                                  distance_to_cut_10yoorOver + distance_to_paved_road +
                                  distance_to_resource_road + distance_to_mines +
                                  distance_to_pipeline, 
                           data = rsf.data.human.dist.du6.s,
                           family = binomial (link = 'logit'))
car::vif (glm.human.du6.s)

### Build an AIC and AUC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

##############################################
### Generalized Linear Mixed Models (GLMMs) #
############################################
# standardize covariates  (helps with model convergence)
rsf.data.human.dist.du6.s$std.distance_to_cut_1to4yo <- (rsf.data.human.dist.du6.s$distance_to_cut_1to4yo - mean (rsf.data.human.dist.du6.s$distance_to_cut_1to4yo)) / sd (rsf.data.human.dist.du6.s$distance_to_cut_1to4yo)
rsf.data.human.dist.du6.s$std.distance_to_cut_5to9yo <- (rsf.data.human.dist.du6.s$distance_to_cut_5to9yo - mean (rsf.data.human.dist.du6.s$distance_to_cut_5to9yo)) / sd (rsf.data.human.dist.du6.s$distance_to_cut_5to9yo)
rsf.data.human.dist.du6.s$std.distance_to_cut_10yoorOver <- (rsf.data.human.dist.du6.s$distance_to_cut_10yoorOver - mean (rsf.data.human.dist.du6.s$distance_to_cut_10yoorOver)) / sd (rsf.data.human.dist.du6.s$distance_to_cut_10yoorOver)
rsf.data.human.dist.du6.s$std.distance_to_paved_road <- (rsf.data.human.dist.du6.s$distance_to_paved_road - mean (rsf.data.human.dist.du6.s$distance_to_paved_road)) / sd (rsf.data.human.dist.du6.s$distance_to_paved_road)
rsf.data.human.dist.du6.s$std.distance_to_resource_road <- (rsf.data.human.dist.du6.s$distance_to_resource_road - mean (rsf.data.human.dist.du6.s$distance_to_resource_road)) / sd (rsf.data.human.dist.du6.s$distance_to_resource_road)
rsf.data.human.dist.du6.s$std.distance_to_mines <- (rsf.data.human.dist.du6.s$distance_to_mines - mean (rsf.data.human.dist.du6.s$distance_to_mines)) / sd (rsf.data.human.dist.du6.s$distance_to_mines)
rsf.data.human.dist.du6.s$std.distance_to_pipeline <- (rsf.data.human.dist.du6.s$distance_to_pipeline - mean (rsf.data.human.dist.du6.s$distance_to_pipeline)) / sd (rsf.data.human.dist.du6.s$distance_to_pipeline)

## DISTANCE TO CUTBLOCK ##
model.lme4.du6.s.cutblock <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                                              std.distance_to_cut_10yoorOver + (1 | uniqueID), 
                                      data = rsf.data.human.dist.du6.s, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Late Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "DC1to4, DC5to9, DCover9"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du6.s.cutblock)

## DISTANCE TO ROAD ##
model.lme4.du6.s.road <- glmer (pttype ~ std.distance_to_paved_road + 
                                          std.distance_to_resource_road + (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Late Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "DPR, DRR"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du6.s.road)

## DISTANCE TO MINE ##
model.lme4.du6.s.mine <- glmer (pttype ~ std.distance_to_mines + (1 | uniqueID), 
                                 data = rsf.data.human.dist.du6.s, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Late Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "DMine"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du6.s.mine)

## DISTANCE TO PIPELINE ##
model.lme4.du6.s.pipe <- glmer (pttype ~ std.distance_to_pipeline + (1 | uniqueID), 
                                 data = rsf.data.human.dist.du6.s, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [4, 1] <- "DU6"
table.aic [4, 2] <- "Late Winter"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "DPipeline"
table.aic [4, 5] <- "(1 | UniqueID)"
table.aic [4, 6] <-  AIC (model.lme4.du6.s.pipe)

## DISTANCE TO CUTBLOCK and DISTANCE TO ROAD ##
model.lme4.du6.s.cut.road <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                              std.distance_to_cut_5to9yo + 
                                              std.distance_to_cut_10yoorOver + 
                                              std.distance_to_paved_road +
                                              std.distance_to_resource_road +
                                              (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [5, 1] <- "DU6"
table.aic [5, 2] <- "Late Winter"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR"
table.aic [5, 5] <- "(1 | UniqueID)"
table.aic [5, 6] <-  AIC (model.lme4.du6.s.cut.road)

## DISTANCE TO CUTBLOCK and DISTANCE TO MINE ##
model.lme4.du6.s.cut.mine <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                               std.distance_to_cut_5to9yo + 
                                               std.distance_to_cut_10yoorOver + 
                                               std.distance_to_mines +
                                               (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [6, 1] <- "DU6"
table.aic [6, 2] <- "Late Winter"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "DC1to4, DC5to9, DCover9, DMine"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <-  AIC (model.lme4.du6.s.cut.mine)

## DISTANCE TO CUTBLOCK and DISTANCE TO PIPELINE ##
model.lme4.du6.s.cut.pipe <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                               std.distance_to_cut_5to9yo + 
                                               std.distance_to_cut_10yoorOver + 
                                               std.distance_to_pipeline +
                                               (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [7, 1] <- "DU6"
table.aic [7, 2] <- "Late Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "DC1to4, DC5to9, DCover9, DPipeline"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du6.s.cut.pipe)

## DISTANCE TO ROAD AND DISTANCE TO MINE ##
model.lme4.du6.s.road.mine <- glmer (pttype ~ std.distance_to_paved_road + 
                                                std.distance_to_resource_road + 
                                                std.distance_to_mines +
                                                (1 | uniqueID), 
                                       data = rsf.data.human.dist.du6.s, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [8, 1] <- "DU6"
table.aic [8, 2] <- "Late Winter"
table.aic [8, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [8, 4] <- "DPR, DRR, DMine"
table.aic [8, 5] <- "(1 | UniqueID)"
table.aic [8, 6] <-  AIC (model.lme4.du6.s.road.mine)

## DISTANCE TO ROAD AND DISTANCE TO PIPELINE ##
model.lme4.du6.s.road.pipe <- glmer (pttype ~ std.distance_to_paved_road + 
                                                std.distance_to_resource_road + 
                                                std.distance_to_pipeline +
                                                (1 | uniqueID), 
                                      data = rsf.data.human.dist.du6.s, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [9, 1] <- "DU6"
table.aic [9, 2] <- "Late Winter"
table.aic [9, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [9, 4] <- "DPR, DRR, DPipeline"
table.aic [9, 5] <- "(1 | UniqueID)"
table.aic [9, 6] <-  AIC (model.lme4.du6.s.road.pipe)

## DISTANCE TO MINE AND DISTANCE TO PIPELINE ##
model.lme4.du6.s.mine.pipe <- glmer (pttype ~ std.distance_to_mines + 
                                               std.distance_to_pipeline +
                                               (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [10, 1] <- "DU6"
table.aic [10, 2] <- "Late Winter"
table.aic [10, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [10, 4] <- "DMine, DPipeline"
table.aic [10, 5] <- "(1 | UniqueID)"
table.aic [10, 6] <-  AIC (model.lme4.du6.s.mine.pipe)

## DISTANCE TO CUTBLOCK, DISTANCE TO ROAD, DISTANCE TO MINE ##
model.lme4.du6.s.cut.road.mine <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                   std.distance_to_cut_5to9yo + 
                                                   std.distance_to_cut_10yoorOver + 
                                                   std.distance_to_paved_road +
                                                   std.distance_to_resource_road +
                                                   std.distance_to_mines +
                                                   (1 | uniqueID), 
                                         data = rsf.data.human.dist.du6.s, 
                                         family = binomial (link = "logit"),
                                         verbose = T) 
# AIC
table.aic [11, 1] <- "DU6"
table.aic [11, 2] <- "Late Winter"
table.aic [11, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [11, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, DMine"
table.aic [11, 5] <- "(1 | UniqueID)"
table.aic [11, 6] <-  AIC (model.lme4.du6.s.cut.road.mine)

## DISTANCE TO CUTBLOCK, DISTANCE TO ROAD, DISTANCE TO PIPELINE ##
model.lme4.du6.s.cut.road.pipe <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                    std.distance_to_cut_5to9yo + 
                                                    std.distance_to_cut_10yoorOver + 
                                                    std.distance_to_paved_road +
                                                    std.distance_to_resource_road +
                                                    std.distance_to_pipeline +
                                                    (1 | uniqueID), 
                                          data = rsf.data.human.dist.du6.s, 
                                          family = binomial (link = "logit"),
                                          verbose = T) 
# AIC
table.aic [12, 1] <- "DU6"
table.aic [12, 2] <- "Late Winter"
table.aic [12, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [12, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, DPipeline"
table.aic [12, 5] <- "(1 | UniqueID)"
table.aic [12, 6] <-  AIC (model.lme4.du6.s.cut.road.pipe)

## DISTANCE TO CUTBLOCK, DISTANCE TO MINE, DISTANCE TO PIPELINE ##
model.lme4.du6.s.cut.mine.pipe <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                   std.distance_to_cut_5to9yo + 
                                                   std.distance_to_cut_10yoorOver + 
                                                   std.distance_to_mines +
                                                   std.distance_to_pipeline +
                                                   (1 | uniqueID), 
                                           data = rsf.data.human.dist.du6.s, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [13, 1] <- "DU6"
table.aic [13, 2] <- "Late Winter"
table.aic [13, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [13, 4] <- "DC1to4, DC5to9, DCover9, DMine, DPipeline"
table.aic [13, 5] <- "(1 | UniqueID)"
table.aic [13, 6] <-  AIC (model.lme4.du6.s.cut.mine.pipe)

## DISTANCE TO ROAD, DISTANCE TO MINE, DISTANCE TO PIPELINE ##
model.lme4.du6.s.road.mine.pipe <- glmer (pttype ~ std.distance_to_paved_road + 
                                                    std.distance_to_resource_road + 
                                                    std.distance_to_mines +
                                                    std.distance_to_pipeline +
                                                    (1 | uniqueID), 
                                            data = rsf.data.human.dist.du6.s, 
                                            family = binomial (link = "logit"),
                                            verbose = T) 
# AIC
table.aic [14, 1] <- "DU6"
table.aic [14, 2] <- "Late Winter"
table.aic [14, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [14, 4] <- "DPR, DRR, DMine, DPipeline"
table.aic [14, 5] <- "(1 | UniqueID)"
table.aic [14, 6] <-  AIC (model.lme4.du6.s.road.mine.pipe)

## DISTANCE TO CUTBLOCK, DISTANCE TO ROAD, DISTANCE TO MINE, DISTANCE TO PIPELINE ##
model.lme4.du6.s.cut.road.mine.pipe <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                        std.distance_to_cut_5to9yo + 
                                                        std.distance_to_cut_10yoorOver + 
                                                        std.distance_to_paved_road +
                                                        std.distance_to_resource_road +
                                                        std.distance_to_mines +
                                                        std.distance_to_pipeline +
                                                        (1 | uniqueID), 
                                              data = rsf.data.human.dist.du6.s, 
                                              family = binomial (link = "logit"),
                                              verbose = T) 
# AIC
table.aic [15, 1] <- "DU6"
table.aic [15, 2] <- "Late Winter"
table.aic [15, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [15, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, DMine, DPipeline"
table.aic [15, 5] <- "(1 | UniqueID)"
table.aic [15, 6] <-  AIC (model.lme4.du6.s.cut.road.mine.pipe)

## AIC comparison of MODELS ## 
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

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\summer\\table_aic_human_disturb.csv", sep = ",")

#=================================
# Natural Disturbance Models
#=================================
rsf.data.natural.dist.du6.s <- rsf.data.natural.dist %>%
                                    dplyr::filter (du == "du6") %>%
                                    dplyr::filter (season == "Summer")
### CORRELATION ###
corr.rsf.data.natural.dist.du6.s <- rsf.data.natural.dist.du6.s [c (10:14)]
corr.rsf.data.natural.dist.du6.s <- round (cor (corr.rsf.data.natural.dist.du6.s, method = "spearman"), 3)
ggcorrplot (corr.rsf.data.natural.dist.du6.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Fire and Beetle Disturbance Selection Function Model
            Covariate Correlations for DU6, Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_natural_disturb_du6_s.png")

### VIF ###
glm.nat.disturb.du6.s <- glm (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                                        fire_1to5yo + fire_6to25yo + fire_over25yo, 
                               data = rsf.data.natural.dist.du6.s,
                               family = binomial (link = 'logit'))
car::vif (glm.nat.disturb.du6.s)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

## FIRE ##
model.lme4.du6.s.fire <- glmer (pttype ~ fire_1to5yo + fire_6to25yo +
                                          fire_over25yo + (1 | uniqueID), 
                                 data = rsf.data.natural.dist.du6.s, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Late Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "Fire1to5, Fire6to25, Fireover25"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du6.s.fire)

## BEETLE ##
model.lme4.du6.s.beetle <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo +
                                            (1 | uniqueID), 
                                   data = rsf.data.natural.dist.du6.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Late Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "Beetle1to5, Beetle6to9"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du6.s.beetle)

## FIRE AND BEETLE ##
model.lme4.du6.s.fire.beetle <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo + 
                                                 beetle_1to5yo + beetle_6to9yo +
                                                 (1 | uniqueID), 
                                       data = rsf.data.natural.dist.du6.s, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Late Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "Fire1to5, Fire6to25, Fireover25, Beetle1to5, Beetle6to9"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <- AIC (model.lme4.du6.s.fire.beetle)

## AIC comparison of MODELS ## 
table.aic$AIC <- as.numeric (table.aic$AIC)
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\summer\\table_aic_natural_disturb.csv", sep = ",")

#=================================
# ANNUAL CLIMATE Models
#=================================
rsf.data.climate.annual.du6.s <- rsf.data.climate.annual %>%
                                            dplyr::filter (du == "du6") %>%
                                            dplyr::filter (season == "Summer")
rsf.data.climate.annual.du6.s$pttype <- as.factor (rsf.data.climate.annual.du6.s$pttype)

### OUTLIERS ###
ggplot (rsf.data.climate.annual.du6.s, aes (x = pttype, y = frost_free_start_julian)) +
            geom_boxplot (outlier.colour = "red") +
            labs (title = "Boxplot DU6, Summer, Annual Frost Free Period Julian Start Day\ 
                  at Available (0) and Used (1) Locations",
                  x = "Available (0) and Used (1) Locations",
                  y = "Julian Day")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_s_frost_free_start.png")
ggplot (rsf.data.climate.annual.du6.s, aes (x = pttype, y = growing_degree_days)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Summer, Annual Growing Degree Days \
              at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Number of Days")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_s_grow_deg_day.png")
ggplot (rsf.data.climate.annual.du6.s, aes (x = pttype, y = frost_free_end_julian)) +
          geom_boxplot (outlier.colour = "red") +
          labs (title = "Boxplot DU6, Summer, Annual Frost Free End Julian Day \
                at Available (0) and Used (1) Locations",
                x = "Available (0) and Used (1) Locations",
                y = "Julian Day")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_s_frost_free_end.png")
ggplot (rsf.data.climate.annual.du6.s, aes (x = pttype, y = frost_free_period)) +
          geom_boxplot (outlier.colour = "red") +
          labs (title = "Boxplot DU6, Summer, Annual Frost Free Period \
                        at Available (0) and Used (1) Locations",
                x = "Available (0) and Used (1) Locations",
                y = "Number of Days")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_s_frost_free_period.png")
ggplot (rsf.data.climate.annual.du6.s, aes (x = pttype, y = mean_annual_ppt)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Summer, Mean Annual Precipitation \
                              at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Precipitation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_s_mean_annual_ppt.png")
ggplot (rsf.data.climate.annual.du6.s, aes (x = pttype, y = mean_annual_temp)) +
          geom_boxplot (outlier.colour = "red") +
          labs (title = "Boxplot DU6, Summer, Mean Annual Temperature \
                                      at Available (0) and Used (1) Locations",
                x = "Available (0) and Used (1) Locations",
                y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_s_mean_annual_temp.png")
ggplot (rsf.data.climate.annual.du6.s, aes (x = pttype, y = mean_coldest_month_temp)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Summer, Mean Annual Coldest Month Temperature \
                                            at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_s_mean_cold_mth_temp.png")
ggplot (rsf.data.climate.annual.du6.s, aes (x = pttype, y = mean_warmest_month_temp)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Summer, Mean Annual Warmest Month Temperature \
                                                  at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_s_mean_warm_mth_temp.png")
ggplot (rsf.data.climate.annual.du6.s, aes (x = pttype, y = ppt_as_snow_annual)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Summer, Mean Annual Precipitation as Snow \
                    at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Precipitation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_annual_climate_du6_s_mean_annual_pas.png")

### HISTOGRAMS ###
ggplot (rsf.data.climate.annual.du6.s, aes (x = frost_free_start_julian, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU6, Summer, Frost Free Start Julian Day\
              at Available (0) and Used (1) Locations",
              x = "Julian Day",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_s_frost_free_start.png")
ggplot (rsf.data.climate.annual.du6.s, aes (x = growing_degree_days, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU6, Summer, Annual Growing Degree Days\
                    at Available (0) and Used (1) Locations",
              x = "Number of Days",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_s_grow_deg_days.png")
ggplot (rsf.data.climate.annual.du6.s, aes (x = frost_free_end_julian, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU6, Summer, Frost Free End Julian Day\
              at Available (0) and Used (1) Locations",
              x = "Julian Day",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_s_frost_free_end.png")
ggplot (rsf.data.climate.annual.du6.s, aes (x = frost_free_period, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU6, Summer, Frost Free Period\
                    at Available (0) and Used (1) Locations",
              x = "Number of Days",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_s_frost_free_period.png")
ggplot (rsf.data.climate.annual.du6.s, aes (x = mean_annual_ppt, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU6, Summer, Mean Annual Precipitation\
                          at Available (0) and Used (1) Locations",
              x = "Precipitation",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_s_mean_annual_ppt.png")
ggplot (rsf.data.climate.annual.du6.s, aes (x = mean_annual_temp, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU6, Summer, Mean Annual Temperature\
                                at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_s_mean_annual_temp.png")
ggplot (rsf.data.climate.annual.du6.s, aes (x = mean_coldest_month_temp, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU6, Summer, Mean Annual Coldest Month Temperature\
                       at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_s_mean_annual_cold_mth_temp.png")
ggplot (rsf.data.climate.annual.du6.s, aes (x = mean_warmest_month_temp, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU6, Summer, Mean Annual Warmest Month Temperature\
                             at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_s_mean_annual_warm_mth_temp.png")
ggplot (rsf.data.climate.annual.du6.s, aes (x = number_frost_free_days, fill = pttype)) + 
          geom_histogram (position = "dodge") +
          labs (title = "Histogram DU6, Summer, Annual Number of Frost Free Days\
                                     at Available (0) and Used (1) Locations",
                x = "Number of Days",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_s_mean_frost_free_days.png")
ggplot (rsf.data.climate.annual.du6.s, aes (x = ppt_as_snow_annual, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU6, Summer, Annual Precipitation as Snow\
              at Available (0) and Used (1) Locations",
              x = "Precipitation",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_s_mean_pas.png")

### CORRELATION ###
corr.rsf.data.climate.annual.du6.s <- rsf.data.climate.annual.du6.s [c (11:19)]
corr.rsf.data.climate.annual.du6.s <- round (cor (corr.rsf.data.climate.annual.du6.s, method = "spearman"), 3)
ggcorrplot (corr.rsf.data.climate.annual.du6.s, type = "lower", lab = TRUE, tl.cex = 10, lab_size = 3,
            title = "Annual Climate Resource Selection Function Model
            Covariate Correlations for DU6, Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_annual_climate_du6_s.png")

### VIF ###
glm.annual.climate.du6.s <- glm (pttype ~ ppt_as_snow_annual + growing_degree_days + mean_annual_temp, 
                                   data = rsf.data.climate.annual.du6.s,
                                   family = binomial (link = 'logit'))
car::vif (glm.annual.climate.du6.s)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

# standardize covariates  (helps with model convergence)
rsf.data.climate.annual.du6.s$std.ppt_as_snow_annual <- (rsf.data.climate.annual.du6.s$ppt_as_snow_annual - mean (rsf.data.climate.annual.du6.s$ppt_as_snow_annual)) / sd (rsf.data.climate.annual.du6.s$ppt_as_snow_annual)
rsf.data.climate.annual.du6.s$std.growing_degree_days <- (rsf.data.climate.annual.du6.s$growing_degree_days - mean (rsf.data.climate.annual.du6.s$growing_degree_days)) / sd (rsf.data.climate.annual.du6.s$growing_degree_days)
rsf.data.climate.annual.du6.s$std.mean_annual_temp <- (rsf.data.climate.annual.du6.s$mean_annual_temp - mean (rsf.data.climate.annual.du6.s$mean_annual_temp)) / sd (rsf.data.climate.annual.du6.s$mean_annual_temp)

## PRECIPITATION AS SNOW ##
model.lme4.du6.s.pas <- glmer (pttype ~ std.ppt_as_snow_annual + (1 | uniqueID), 
                                data = rsf.data.climate.annual.du6.s, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Late Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "PaS"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du6.s.pas)

## GROWING DEGREE DAYS ##
model.lme4.du6.s.ggd <- glmer (pttype ~ std.growing_degree_days + (1 | uniqueID), 
                                data = rsf.data.climate.annual.du6.s, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Late Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "GDD"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du6.s.ggd)

## MEAN ANNUAL TEMPERATURE ##
model.lme4.du6.s.mat <- glmer (pttype ~ std.mean_annual_temp + (1 | uniqueID), 
                                data = rsf.data.climate.annual.du6.s, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Late Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "MAT"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du6.s.mat)

## PRECIPITATION AS SNOW and GROWING DEGREE DAYS ##
model.lme4.du6.s.pas.gdd <- glmer (pttype ~ std.ppt_as_snow_annual + std.growing_degree_days +
                                              (1 | uniqueID), 
                                    data = rsf.data.climate.annual.du6.s, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [4, 1] <- "DU6"
table.aic [4, 2] <- "Late Winter"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "PaS, GDD"
table.aic [4, 5] <- "(1 | UniqueID)"
table.aic [4, 6] <-  AIC (model.lme4.du6.s.pas.gdd)

## PRECIPITATION AS SNOW and MEAN ANNUAL TEMP ##
model.lme4.du6.s.pas.mat <- glmer (pttype ~ std.ppt_as_snow_annual + std.mean_annual_temp +
                                      (1 | uniqueID), 
                                    data = rsf.data.climate.annual.du6.s, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [5, 1] <- "DU6"
table.aic [5, 2] <- "Late Winter"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "PaS, MAT"
table.aic [5, 5] <- "(1 | UniqueID)"
table.aic [5, 6] <-  AIC (model.lme4.du6.s.pas.mat)

## GROWING DEGREE DAYS and MEAN ANNUAL TEMP ##
model.lme4.du6.s.ggd.mat <- glmer (pttype ~ std.growing_degree_days + std.mean_annual_temp +
                                             (1 | uniqueID), 
                                    data = rsf.data.climate.annual.du6.s, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [6, 1] <- "DU6"
table.aic [6, 2] <- "Late Winter"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "GDD, MAT"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <-  AIC (model.lme4.du6.s.ggd.mat)

## PRECIPITATION AS SNOW, GROWING DEGREE DAYS, MEAN ANNUAL TEMP ##
model.lme4.du6.s.pas.gdd.mat <- glmer (pttype ~ std.ppt_as_snow_annual + std.growing_degree_days +
                                                 std.mean_annual_temp +
                                                 (1 | uniqueID), 
                                        data = rsf.data.climate.annual.du6.s, 
                                        family = binomial (link = "logit"),
                                        verbose = T) 
# AIC
table.aic [7, 1] <- "DU6"
table.aic [7, 2] <- "Late Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "PaS, GDD, MAT"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du6.s.pas.gdd.mat)

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

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\summer\\table_aic_annual_climate.csv", sep = ",")


#=================================
# SUMMER CLIMATE Models
#=================================
rsf.data.climate.summer.du6.s <- rsf.data.climate.summer %>%
                                    dplyr::filter (du == "du6") %>%
                                    dplyr::filter (season == "Summer")
rsf.data.climate.summer.du6.s$pttype <- as.factor (rsf.data.climate.summer.du6.s$pttype)

### OUTLIERS ###
ggplot (rsf.data.climate.summer.du6.s, aes (x = pttype, y = ppt_summer)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Summer, Precipitation\ 
              at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Precipitation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_summer_climate_du6_s_ppt.png")
ggplot (rsf.data.climate.summer.du6.s, aes (x = pttype, y = temp_avg_summer)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Summer, Average Temperature\ 
              at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_summer_climate_du6_s_temp_avg.png")
ggplot (rsf.data.climate.summer.du6.s, aes (x = pttype, y = temp_max_summer)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Summer, Maximum Temperature\ 
                    at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_summer_climate_du6_s_temp_max.png")
ggplot (rsf.data.climate.summer.du6.s, aes (x = pttype, y = temp_min_summer)) +
          geom_boxplot (outlier.colour = "red") +
          labs (title = "Boxplot DU6, Summer, Minimum Temperature\ 
                            at Available (0) and Used (1) Locations",
                x = "Available (0) and Used (1) Locations",
                y = "Temperature")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_summer_climate_du6_s_temp_min.png")

### HISTOGRAMS ###
ggplot (rsf.data.climate.summer.du6.s, aes (x = ppt_summer, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 5) +
        labs (title = "Histogram DU6, Summer, Precipitation\
                      at Available (0) and Used (1) Locations",
              x = "Precipitation",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_s_ppt.png")
ggplot (rsf.data.climate.summer.du6.s, aes (x = temp_avg_summer, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU6, Summer, Average Temperature\
                            at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_s_temp_avg.png")
ggplot (rsf.data.climate.summer.du6.s, aes (x = temp_max_summer, fill = pttype)) + 
          geom_histogram (position = "dodge") +
          labs (title = "Histogram DU6, Summer, Maximum Temperature\
                         at Available (0) and Used (1) Locations",
                x = "Temperature",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_s_temp_max.png")
ggplot (rsf.data.climate.summer.du6.s, aes (x = temp_min_summer, fill = pttype)) + 
        geom_histogram (position = "dodge") +
        labs (title = "Histogram DU6, Summer, Minimum Temperature\
                               at Available (0) and Used (1) Locations",
              x = "Temperature",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_annual_climate_du6_s_temp_min.png")

### CORRELATION ###
corr.climate.summer.du6.s <- rsf.data.climate.summer.du6.s [c (10:11, 13:16)] # Ppt as snow mostly = 0
corr.climate.summer.du6.s <- round (cor (corr.climate.summer.du6.s, method = "spearman"), 3)
ggcorrplot (corr.climate.summer.du6.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "summer Climate Resource Selection Function Model
            Covariate Correlations for DU6, Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_summer_climate_du6_s.png")

### VIF ###
glm.summer.climate.du6.s <- glm (pttype ~ ppt_summer + temp_avg_summer, 
                                  data = rsf.data.climate.summer.du6.s,
                                  family = binomial (link = 'logit'))
car::vif (glm.summer.climate.du6.s)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

# standardize covariates  (helps with model convergence)
rsf.data.climate.summer.du6.s$std.ppt_summer <- (rsf.data.climate.summer.du6.s$ppt_summer - mean (rsf.data.climate.summer.du6.s$ppt_summer)) / sd (rsf.data.climate.summer.du6.s$ppt_summer)
rsf.data.climate.summer.du6.s$std.temp_avg_summer <- (rsf.data.climate.summer.du6.s$temp_avg_summer - mean (rsf.data.climate.summer.du6.s$temp_avg_summer)) / sd (rsf.data.climate.summer.du6.s$temp_avg_summer)

## PRECIPITATION ##
model.lme4.du6.s.summer.ppt <- glmer (pttype ~ std.ppt_summer + (1 | uniqueID), 
                                data = rsf.data.climate.summer.du6.s, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Summer"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "SPPT"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du6.s.summer.ppt)

## AVERAGE TEMPERATURE ##
model.lme4.du6.s.summer.temp <- glmer (pttype ~ std.temp_avg_summer + (1 | uniqueID), 
                                       data = rsf.data.climate.summer.du6.s, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Summer"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "STemp"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du6.s.summer.temp)

## PRECIPITATION and AVERAGE TEMPERATURE ##
model.lme4.du6.s.summer.ppt.temp <- glmer (pttype ~ std.ppt_summer + std.temp_avg_summer +
                                                      (1 | uniqueID), 
                                       data = rsf.data.climate.summer.du6.s, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Summer"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "SPPT, STemp"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du6.s.summer.ppt.temp)

## AIC comparison of MODELS ## 
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:3, 6])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\summer\\table_aic_summer_climate.csv", sep = ",")


#=================================
# VEGETATION/FOREST Models
#=================================
rsf.data.veg.du6.s <- rsf.data.veg %>%
                         dplyr::filter (du == "du6") %>%
                         dplyr::filter (season == "Summer")
rsf.data.veg.du6.s$pttype <- as.factor (rsf.data.veg.du6.s$pttype)

test <- rsf.data.veg.du6.s %>% filter (is.na (wetland_class_du_boreal_name))
rsf.data.veg.du6.s <- rsf.data.veg.du6.s %>% 
                        filter (!is.na (wetland_class_du_boreal_name))

rsf.data.veg.du6.s$bec_label <- relevel (rsf.data.veg.du6.s$bec_label,
                                          ref = "BWBSmk")
rsf.data.veg.du6.s$wetland_demars <- relevel (rsf.data.veg.du6.s$wetland_demars,
                                                ref = "Upland Conifer") # upland confier as referencce, as per Demars 2018


### OUTLIERS ###


### HISTOGRAMS ###
ggplot (rsf.data.veg.du6.s, aes (x = bec_label, fill = pttype)) + 
            geom_histogram (position = "dodge", stat = "count") +
            labs (title = "Histogram DU6, Late Winter, BEC Type\
                          at Available (0) and Used (1) Locations",
                  x = "Biogeclimatic Unit",
                  y = "Count") +
            scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_veg_du6_s_bec.png")
ggplot (rsf.data.veg.du6.s, aes (x = wetland_demars, fill = pttype)) + 
          geom_histogram (position = "dodge", stat = "count") +
          labs (title = "Histogram DU6, Late Winter, Wetland Type\
                                  at Available (0) and Used (1) Locations",
                x = "Wetland Type",
                y = "Count") +
          scale_fill_discrete (name = "Location Type") +
          theme (axis.text.x = element_text (angle = -90, hjust = 0))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_veg_du6_s_wetland.png")


### CORRELATION ###
corr.veg.du6.s <- rsf.data.veg.du6.s [c (12:16)]
corr.veg.du6.s <- round (cor (corr.veg.du6.s, method = "spearman"), 3)
ggcorrplot (corr.veg.du6.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Vegeation Resource Selection Function Model
            Covariate Correlations for DU6, Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_veg_du6_s.png")

### VIF ###
glm.veg.du6.s <- glm (pttype ~ bec_label + wetland_demars, 
                                  data = rsf.data.veg.du6.s,
                                  family = binomial (link = 'logit'))
car::vif (glm.veg.du6.s)



### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

# standardize covariates  (helps with model convergence)
rsf.data.veg.du6.s$std.ppt_as_snow_winter <- (rsf.data.veg.du6.s$ppt_as_snow_winter - mean (rsf.data.veg.du6.s$ppt_as_snow_winter)) / sd (rsf.data.veg.du6.s$ppt_as_snow_winter)
rsf.data.veg.du6.s$std.temp_avg_winter <- (rsf.data.veg.du6.s$temp_avg_winter - mean (rsf.data.veg.du6.s$temp_avg_winter)) / sd (rsf.data.veg.du6.s$temp_avg_winter)

# FUNCTIONAL RESPONSE Covariates
sub <- subset (rsf.data.veg.du6.s, pttype == 0)
ppt_as_snow_winter_E <- tapply (sub$std.ppt_as_snow_winter, sub$uniqueID, sum)
temp_avg_winter_E <- tapply (sub$std.temp_avg_winter, sub$uniqueID, sum)
inds <- as.character (rsf.data.climate.winter.du6.s$uniqueID)
rsf.data.veg.du6.s <- cbind (rsf.data.veg.du6.s, 
                                         "ppt_as_snow_winter_E" = ppt_as_snow_winter_E [inds],
                                         "temp_avg_winter_E" = temp_avg_winter_E [inds])

## BEC ##
model.lme4.du6.s.veg.bec <- glmer (pttype ~ bec_label + (1 | uniqueID), 
                                    data = rsf.data.veg.du6.s, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Late Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "BEC"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du6.s.veg.bec)

## WETLAND CLASS ##
model.lme4.du6.s.veg.wetland <- glmer (pttype ~ wetland_demars + (1 | uniqueID), 
                                        data = rsf.data.veg.du6.s, 
                                        family = binomial (link = "logit"),
                                        verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Late Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "Wetland"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du6.s.veg.wetland)

## WETLAND CLASS and BEC ##
model.lme4.du6.s.veg.wetland.bec <- glmer (pttype ~ wetland_demars + bec_label + (1 | uniqueID), 
                                            data = rsf.data.veg.du6.s, 
                                            family = binomial (link = "logit"),
                                            verbose = T) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Late Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "Wetland, BEC"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du6.s.veg.wetland.bec)




write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\summer\\table_aic_veg.csv", sep = ",")

#=================================
# COMBINATION Models
#=================================

### compile AIC table of top models form each group
table.aic.annual.clim <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\summer\\table_aic_annual_climate.csv", header = T, sep = ",")
table.aic <- table.aic.annual.clim [10, ]
rm (table.aic.annual.clim)
table.aic.human <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\summer\\table_aic_human_disturb.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.human [110, ])
rm (table.aic.human)
table.aic.nat.disturb <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\summer\\table_aic_natural_disturb.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.nat.disturb [5, ])
rm (table.aic.nat.disturb)
table.aic.enduring <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\summer\\table_aic_terrain_water_v3.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.enduring [15, ])
rm (table.aic.enduring)
table.aic.winter.clim <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\summer\\table_aic_winter_climate.csv", header = T, sep = ",")
table.aic <- bind_rows (table.aic, table.aic.winter.clim [5, ])
rm (table.aic.winter.clim)

# table.aic.veg <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\summer\\table_aic_veg.csv", header = T, sep = ",")
# table.aic <- bind_rows (table.aic, table.aic.veg [5, ])
# rm (table.aic.winter.clim)


# Load and tidy the data 
rsf.data.combo.du6.s <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du6_s.csv", header = T, sep = ",")
rsf.data.combo.du6.s$pttype <- as.factor (rsf.data.combo.du6.s$pttype)
rsf.data.combo.du6.s <- rsf.data.combo.du6.s %>% 
                         filter (!is.na (ppt_as_snow_annual))
rsf.data.combo.du6.s$soil_parent_material_name <- relevel (rsf.data.combo.du6.s$soil_parent_material_name,
                                                            ref = "Till")
rsf.data.combo.du6.s$bec_label <- relevel (rsf.data.combo.du6.s$bec_label,
                                            ref = "BWBSmk")
rsf.data.combo.du6.s$wetland_demars <- relevel (rsf.data.combo.du6.s$wetland_demars,
                                                 ref = "Upland Conifer") # upland confier as referencce, as per Demars 2018

### CORRELATION ###
corr.data.du6.s <- rsf.data.combo.du6.s [c (11:14, 16:17, 37, 20:34)]
corr.du6.s <- round (cor (corr.data.du6.s, method = "spearman"), 3)
ggcorrplot (corr.du6.s, type = "lower", lab = TRUE, tl.cex = 9,  lab_size = 2,
            title = "Resource Selection Function Model Covariate Correlations \
                     for DU6, Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_winter_climate_du6_s.png")

### VIF ###
glm.all.du6.s <- glm (pttype ~ slope + distance_to_lake + distance_to_watercourse +
                                soil_parent_material_name + distance_to_cut_1to4yo + 
                                distance_to_cut_5to9yo + distance_to_cut_10yoorOver + distance_to_paved_road +
                                distance_to_resource_road + distance_to_mines + distance_to_pipeline +
                                seismic + beetle_1to5yo + beetle_6to9yo + fire_1to5yo + fire_6to25yo +
                                fire_over25yo + growing_degree_days + ppt_as_snow_winter +
                                temp_avg_winter + bec_label + wetland_demars,  
                       data = rsf.data.combo.du6.s,
                       family = binomial (link = 'logit'))
car::vif (glm.all.du6.s)

# standardize covariates  (helps with model convergence)
rsf.data.combo.du6.s$std.slope <- (rsf.data.combo.du6.s$slope - 
                                    mean (rsf.data.combo.du6.s$slope)) / 
                                    sd (rsf.data.combo.du6.s$slope)
rsf.data.combo.du6.s$std.distance_to_lake <- (rsf.data.combo.du6.s$distance_to_lake - 
                                                mean (rsf.data.combo.du6.s$distance_to_lake)) / 
                                                sd (rsf.data.combo.du6.s$distance_to_lake)
rsf.data.combo.du6.s$std.distance_to_watercourse <- (rsf.data.combo.du6.s$distance_to_watercourse - 
                                                      mean (rsf.data.combo.du6.s$distance_to_watercourse)) / 
                                                      sd (rsf.data.combo.du6.s$distance_to_watercourse)
rsf.data.combo.du6.s$std.distance_to_cut_1to4yo <- (rsf.data.combo.du6.s$distance_to_cut_1to4yo - 
                                                      mean (rsf.data.combo.du6.s$distance_to_cut_1to4yo)) / 
                                                      sd (rsf.data.combo.du6.s$distance_to_cut_1to4yo)
rsf.data.combo.du6.s$std.distance_to_cut_5to9yo <- (rsf.data.combo.du6.s$distance_to_cut_5to9yo - 
                                                      mean (rsf.data.combo.du6.s$distance_to_cut_5to9yo)) / 
                                                      sd (rsf.data.combo.du6.s$distance_to_cut_5to9yo)
rsf.data.combo.du6.s$std.distance_to_cut_10yoorOver <- (rsf.data.combo.du6.s$distance_to_cut_10yoorOver - 
                                                          mean (rsf.data.combo.du6.s$distance_to_cut_10yoorOver)) / 
                                                          sd (rsf.data.combo.du6.s$distance_to_cut_10yoorOver)
rsf.data.combo.du6.s$std.distance_to_paved_road <- (rsf.data.combo.du6.s$distance_to_paved_road - 
                                                           mean (rsf.data.combo.du6.s$distance_to_paved_road)) / 
                                                           sd (rsf.data.combo.du6.s$distance_to_paved_road)
rsf.data.combo.du6.s$std.distance_to_resource_road <- (rsf.data.combo.du6.s$distance_to_resource_road - 
                                                        mean (rsf.data.combo.du6.s$distance_to_resource_road)) / 
                                                        sd (rsf.data.combo.du6.s$distance_to_resource_road)
rsf.data.combo.du6.s$std.distance_to_mines <- (rsf.data.combo.du6.s$distance_to_mines - 
                                                mean (rsf.data.combo.du6.s$distance_to_mines)) / 
                                                sd (rsf.data.combo.du6.s$distance_to_mines)
rsf.data.combo.du6.s$std.distance_to_pipeline <- (rsf.data.combo.du6.s$distance_to_pipeline - 
                                                    mean (rsf.data.combo.du6.s$distance_to_pipeline)) / 
                                                    sd (rsf.data.combo.du6.s$distance_to_pipeline)
rsf.data.combo.du6.s$std.growing_degree_days <- (rsf.data.combo.du6.s$growing_degree_days - 
                                                  mean (rsf.data.combo.du6.s$growing_degree_days)) / 
                                                  sd (rsf.data.combo.du6.s$growing_degree_days)
rsf.data.combo.du6.s$std.ppt_as_snow_winter <- (rsf.data.combo.du6.s$ppt_as_snow_winter - 
                                                  mean (rsf.data.combo.du6.s$ppt_as_snow_winter)) / 
                                                  sd (rsf.data.combo.du6.s$ppt_as_snow_winter)
rsf.data.combo.du6.s$std.temp_avg_winter <- (rsf.data.combo.du6.s$temp_avg_winter - 
                                                   mean (rsf.data.combo.du6.s$temp_avg_winter)) / 
                                                   sd (rsf.data.combo.du6.s$temp_avg_winter)

# FUNCTIONAL RESPONSE Covariates
sub <- subset (rsf.data.combo.du6.s, pttype == 0)
slope_E <- tapply (sub$std.slope, sub$uniqueID, sum)
distance_to_lake_E <- tapply (sub$std.distance_to_lake, sub$uniqueID, sum)
distance_to_watercourse_E <- tapply (sub$std.distance_to_watercourse, sub$uniqueID, sum)
distance_to_cut_1to4yo_E <- tapply (sub$std.distance_to_cut_1to4yo, sub$uniqueID, sum)
distance_to_cut_5to9yo_E <- tapply (sub$std.distance_to_cut_5to9yo, sub$uniqueID, sum)
distance_to_cut_10yoorOver_E <- tapply (sub$std.distance_to_cut_10yoorOver, sub$uniqueID, sum)
distance_to_paved_road_E <- tapply (sub$std.distance_to_paved_road, sub$uniqueID, sum)
distance_to_resource_road_E <- tapply (sub$std.distance_to_resource_road, sub$uniqueID, sum)
distance_to_mines_E <- tapply (sub$std.distance_to_mines, sub$uniqueID, sum)
distance_to_pipeline_E <- tapply (sub$std.distance_to_pipeline, sub$uniqueID, sum)
growing_degree_days_E <- tapply (sub$std.growing_degree_days, sub$uniqueID, sum)
ppt_as_snow_winter_E <- tapply (sub$std.ppt_as_snow_winter, sub$uniqueID, sum)
inds <- as.character (rsf.data.combo.du6.s$uniqueID)
rsf.data.combo.du6.s <- cbind (rsf.data.combo.du6.s, 
                              "slope_E" = slope_E [inds],
                              "distance_to_lake_E" = distance_to_lake_E [inds],
                              "distance_to_watercourse_E" = distance_to_watercourse_E [inds],
                              "distance_to_cut_1to4yo_E" = distance_to_cut_1to4yo_E [inds],
                              "distance_to_cut_5to9yo_E" = distance_to_cut_5to9yo_E [inds],
                              "distance_to_cut_10yoorOver_E" = distance_to_cut_10yoorOver_E [inds],
                              "distance_to_paved_road_E" = distance_to_paved_road_E [inds],
                              "distance_to_resource_road_E" = distance_to_resource_road_E [inds],
                              "distance_to_mines_E" = distance_to_mines_E [inds],
                              "distance_to_pipeline_E" = distance_to_pipeline_E [inds],
                              "growing_degree_days_E" = growing_degree_days_E [inds],
                              "ppt_as_snow_winter_E" = ppt_as_snow_winter_E [inds])

### ENDURING FEATURES AND HUMAN DISTURBANCE ###
model.lme4.du6.s.ef.hd <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                           std.distance_to_watercourse + soil_parent_material_name +
                                           std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                           std.distance_to_cut_10yoorOver + std.distance_to_paved_road +
                                           std.distance_to_resource_road + std.distance_to_mines +
                                           std.distance_to_pipeline +
                                           (1 | uniqueID), 
                                    data = rsf.data.combo.du6.s, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
ss <- getME (model.lme4.du6.s.ef.hd, c ("theta","fixef"))
model.lme4.du6.s.ef.hd2 <- update (model.lme4.du6.s.ef.hd, start = ss) # failed to converge, restart with parameter estimates
model.lme4.du6.s.ef.hd3 <- update (model.lme4.du6.s.ef.hd, 
                                    . ~ . - seismic) # drop seismic lines
model.lme4.du6.s.ef.hd4 <- update (model.lme4.du6.s.ef.hd, 
                                    . ~ . - soil_parent_material_name) # drop soil
# AIC
table.aic [6, 1] <- "DU6"
table.aic [6, 2] <- "Late Winter"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "Slope, DLake, DWat, DC1to4, DC5to9, DC10, DPR, DRR, DMine, DPipe"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <-  AIC (model.lme4.du6.s.ef.hd)

### ENDURING FEATURES AND NATURAL DISTURBANCE ###
model.lme4.du6.s.ef.nd <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                            std.distance_to_watercourse + soil_parent_material_name +
                                            beetle_1to5yo + beetle_6to9yo + fire_1to5yo + fire_6to25yo +
                                            fire_over25yo +
                                            (1 | uniqueID), 
                                  data = rsf.data.combo.du6.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
model.lme4.du6.s.ef.nd2 <- update (model.lme4.du6.s.ef.nd, 
                                    . ~ . - soil_parent_material_name) # drop soils
# AIC
table.aic [7, 1] <- "DU6"
table.aic [7, 2] <- "Late Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "Slope, DLake, DWat, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du6.s.ef.nd2)

### ENDURING FEATURES AND CLIMATE ###
model.lme4.du6.s.ef.clim <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                              std.distance_to_watercourse + std.growing_degree_days +
                                              std.ppt_as_snow_winter + std.temp_avg_winter + 
                                              (1 | uniqueID), 
                                  data = rsf.data.combo.du6.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
# AIC
table.aic [8, 1] <- "DU6"
table.aic [8, 2] <- "Late Winter"
table.aic [8, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [8, 4] <- "Slope, DLake, DWat, GDD, PAS, WTemp"
table.aic [8, 5] <- "(1 | UniqueID)"
table.aic [8, 6] <-  AIC (model.lme4.du6.s.ef.clim)

### HUMAN DISTURBANCE AND NATURAL DISTURBANCE ###
model.lme4.du6.s.hd.nd <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                            std.distance_to_cut_10yoorOver + std.distance_to_paved_road +
                                            std.distance_to_resource_road + std.distance_to_mines + 
                                            std.distance_to_pipeline + beetle_1to5yo + beetle_6to9yo + 
                                            fire_1to5yo + fire_6to25yo + fire_over25yo +
                                            (1 | uniqueID), 
                                  data = rsf.data.combo.du6.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
# AIC
table.aic [9, 1] <- "DU6"
table.aic [9, 2] <- "Late Winter"
table.aic [9, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [9, 4] <- "DC1to4, DC5to9, DC10, DPR, DRR, DMine, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [9, 5] <- "(1 | UniqueID)"
table.aic [9, 6] <-  AIC (model.lme4.du6.s.hd.nd)

### HUMAN DISTURBANCE AND CLIMATE ###
model.lme4.du6.s.hd.clim <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                            std.distance_to_cut_10yoorOver + std.distance_to_paved_road +
                                            std.distance_to_resource_road + std.distance_to_mines +
                                            std.distance_to_pipeline + std.growing_degree_days +
                                            std.ppt_as_snow_winter + std.temp_avg_winter +
                                            (1 | uniqueID), 
                                  data = rsf.data.combo.du6.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
# AIC
table.aic [10, 1] <- "DU6"
table.aic [10, 2] <- "Late Winter"
table.aic [10, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [10, 4] <- "DC1to4, DC5to9, DC10, DPR, DRR, DMine, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [10, 5] <- "(1 | UniqueID)"
table.aic [10, 6] <-  AIC (model.lme4.du6.s.hd.clim)

### NATURAL DISTURBANCE AND CLIMATE ###
model.lme4.du6.s.nd.clim <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + fire_1to5yo + fire_6to25yo +
                                      fire_over25yo + std.growing_degree_days +
                                      std.ppt_as_snow_winter + std.temp_avg_winter +
                                      (1 | uniqueID), 
                                    data = rsf.data.combo.du6.s, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [11, 1] <- "DU6"
table.aic [11, 2] <- "Late Winter"
table.aic [11, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [11, 4] <- "Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9, GDD, PAS, WTemp"
table.aic [11, 5] <- "(1 | UniqueID)"
table.aic [11, 6] <-  AIC (model.lme4.du6.s.nd.clim)


### ENDURING FEATURES AND VEGETATION ###
model.lme4.du6.s.ef.veg <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                            std.distance_to_watercourse + bec_label + wetland_demars +
                                            (1 | uniqueID), 
                                  data = rsf.data.combo.du6.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
# AIC
table.aic [12, 1] <- "DU6"
table.aic [12, 2] <- "Late Winter"
table.aic [12, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [12, 4] <- "Slope, DLake, DWat, BEC, Wetland"
table.aic [12, 5] <- "(1 | UniqueID)"
table.aic [12, 6] <-  AIC (model.lme4.du6.s.ef.veg)

### ENDURING FEATURES **NEW** ### UPDATED TO REMOVE SOIL
model.lme4.du6.s.ef.new <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                             std.distance_to_watercourse +
                                             (1 | uniqueID), 
                                     data = rsf.data.combo.du6.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 

# AIC
table.aic [4, 1] <- "DU6"
table.aic [4, 2] <- "Late Winter"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "Slope, DLake, DWat"
table.aic [4, 5] <- "(1 | UniqueID)"
table.aic [4, 6] <-  AIC (model.lme4.du6.s.ef.new)

### ENDURING FEATURES, HUMAN DISTURBANCE, NATURAL DISTURBANCE ###
model.lme4.du6.s.ef.hd.nd <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                               std.distance_to_watercourse + std.distance_to_cut_1to4yo + 
                                               std.distance_to_cut_5to9yo + std.distance_to_cut_10yoorOver + 
                                               std.distance_to_paved_road + std.distance_to_resource_road + 
                                               std.distance_to_mines + std.distance_to_pipeline +
                                               beetle_1to5yo + beetle_6to9yo + fire_1to5yo + fire_6to25yo +
                                               fire_over25yo +
                                               (1 | uniqueID), 
                                     data = rsf.data.combo.du6.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [13, 1] <- "DU6"
table.aic [13, 2] <- "Late Winter"
table.aic [13, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [13, 4] <- "Slope, DLake, DWat, DC1to4, DC5to9, DC10, DPR, DRR, DMine, DPipe, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [13, 5] <- "(1 | UniqueID)"
table.aic [13, 6] <-  AIC (model.lme4.du6.s.ef.hd.nd)

### ENDURING FEATURES, HUMAN DISTURBANCE, CLIMATE ###
model.lme4.du6.s.ef.hd.clim <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                                 std.distance_to_watercourse + std.distance_to_cut_1to4yo + 
                                                 std.distance_to_cut_5to9yo + std.distance_to_cut_10yoorOver + 
                                                 std.distance_to_paved_road + std.distance_to_resource_road + 
                                                 std.distance_to_mines + std.distance_to_pipeline + seismic +
                                                 std.growing_degree_days +
                                                 std.ppt_as_snow_winter + std.temp_avg_winter +
                                                 (1 | uniqueID), 
                                     data = rsf.data.combo.du6.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
model.lme4.du6.s.ef.hd.clim2 <- update (model.lme4.du6.s.ef.hd.clim, 
                                    . ~ . - seismic) # drop seismic lines
# AIC
table.aic [14, 1] <- "DU6"
table.aic [14, 2] <- "Late Winter"
table.aic [14, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [14, 4] <- "Slope, DLake, DWat, DC1to4, DC5to9, DC10, DPR, DRR, DMine, DPipe, GDD, PAS, WTemp"
table.aic [14, 5] <- "(1 | UniqueID)"
table.aic [14, 6] <-  AIC (model.lme4.du6.s.ef.hd.clim2)

### HUMAN DISTURBANCE *** NEW - UPDATED WITHOUT SEISMIC *** ###
model.lme4.du6.s.hd <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                                         std.distance_to_cut_10yoorOver + 
                                         std.distance_to_paved_road + std.distance_to_resource_road + 
                                         std.distance_to_mines + std.distance_to_pipeline +
                                         (1 | uniqueID), 
                                       data = rsf.data.combo.du6.s, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Late Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "DC1to4, DC5to9, DC10, DPR, DRR, DMine, DPipe"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du6.s.hd)

### HUMAN DISTURBANCE, NATURAL DISTURBANCE, CLIMATE ###
model.lme4.du6.s.hd.nd.clim <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                                                 std.distance_to_cut_10yoorOver + 
                                                 std.distance_to_paved_road + std.distance_to_resource_road + 
                                                 std.distance_to_mines + std.distance_to_pipeline +
                                                 std.growing_degree_days +
                                                 std.ppt_as_snow_winter + std.temp_avg_winter +
                                                 beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                 fire_6to25yo + fire_over25yo +
                                                 (1 | uniqueID), 
                                       data = rsf.data.combo.du6.s, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
ss <- getME (model.lme4.du6.s.hd.nd.clim, c ("theta","fixef"))
model.lme4.du6.s.hd.nd.clim2 <- update (model.lme4.du6.s.hd.nd.clim, start = ss) # initial model failed to converge, restart with parameter estimates

# AIC
table.aic [15, 1] <- "DU6"
table.aic [15, 2] <- "Late Winter"
table.aic [15, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [15, 4] <- "DC1to4, DC5to9, DC10, DPR, DRR, DMine, DPipe, GDD, PAS, WTemp, Fire1to5, Fire6to25, FireOver25, Beetle1to5, Beetle6to9"
table.aic [15, 5] <- "(1 | UniqueID)"
table.aic [15, 6] <-  AIC (model.lme4.du6.s.hd.nd.clim2)

### ENDURING FEATURES, HUMAN DISTURBANCE, NATURAL DISTURBANCE, CLIMATE ###
model.lme4.du6.s.ed.hd.nd.clim <- glmer (pttype ~ std.slope + std.distance_to_lake + 
                                                   std.distance_to_watercourse +
                                                   std.distance_to_cut_1to4yo + 
                                                   std.distance_to_cut_5to9yo + 
                                                   std.distance_to_cut_10yoorOver + 
                                                   std.distance_to_paved_road + 
                                                   std.distance_to_resource_road + 
                                                   std.distance_to_mines + std.distance_to_pipeline +
                                                   std.growing_degree_days +
                                                   std.ppt_as_snow_winter + std.temp_avg_winter +
                                                   beetle_1to5yo + beetle_6to9yo + fire_1to5yo + 
                                                   fire_6to25yo + fire_over25yo +
                                                   (1 | uniqueID), 
                                       data = rsf.data.combo.du6.s, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
ss <- getME (model.lme4.du6.s.ed.hd.nd.clim, c ("theta","fixef"))
model.lme4.du6.s.ed.hd.nd.clim2 <- update (model.lme4.du6.s.ed.hd.nd.clim, start = ss) # initial model failed to converge, restart with parameter estimates






write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\aic_tables\\du6\\summer\\table_aic_all_top.csv", sep = ",")



# enduring features: elevation, slope, disatnce to lake, disatnce to watercourse, soil type
# human disturbance: distance to cutblock covaraites, distance to road covariates distance to mine,  distance to piepline and included an itneraction term  for distacne to pipeline,  sesimic lines
# natural disturbance: burn age  (burns 1 to 5 years old, 6 to 25 years old and over 25 years old) adn beetle kill age (stands 1 to 5 years old and 6 to 9 years old)
# annual climate: precipitation as snow, growing degree days and mean annual temperature
# winter climate: precipitation as snow and average winter temp
# VEG
 