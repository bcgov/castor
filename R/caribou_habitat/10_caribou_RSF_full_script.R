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
#  Script Name: 10_caribou_RSF_full_script.R
#  Script Version: 1.0
#  Script Purpose: Script to develop provincical caribou RSF model.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 18 January 2019
#  R Version: 
#  R Packages: 
#  Data: 
#=================================
options (scipen = 999)
require (dplyr)
require (ggplot2)
require (ggcorrplot)


require (RPostgreSQL)
require (raster)
require (rgdal)
require (tidyr)
# require (snow)

require (rpart)
require (car)
require (reshape2)
require (lme4)
require (mgcv)
require (gamm4)
require (lattice)
require (ROCR)

#===========
# Datasets
#==========
# rsf.data <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data.csv")
rsf.data.terrain.water <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_terrain_water.csv", header = T, sep = ",")
rsf.data.forestry <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_forestry.csv", header = T, sep = "")
rsf.data.ag <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_agriculture.csv", header = T, sep = "")
rsf.data.mine <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_mine.csv", header = T, sep = "")
rsf.data.energy <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_energy.csv", header = T, sep = "")
rsf.data.natural.dist <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_natural_disturbance.csv", header = T, sep = "")
rsf.data.ski <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_ski.csv", header = T, sep = "")
rsf.data.human.dist <- dplyr::full_join (dplyr::full_join (dplyr::full_join (dplyr::full_join (rsf.data.forestry, rsf.data.ag [, c (9:10)], by = "ptID"), rsf.data.mine [, c (9:10)], by = "ptID"), rsf.data.energy [, c (9:12)], by = "ptID"), rsf.data.ski [, c (9:10)], by = "ptID")
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

#=================================
# Terrain and Water Models
#=================================
### A BIT OF CLEAN-UP ###
# look for and remove NA data #
test <- rsf.data.terrain.water %>% filter (is.na (soil_parent_material_name))
rsf.data.terrain.water <- rsf.data.terrain.water %>% 
                            filter (!is.na (soil_parent_material_name))
rsf.data.terrain.water$pttype <- as.factor (rsf.data.terrain.water$pttype)

# noticed issue with eastness/northness data, need to make value = 0 if slope = 0
rsf.data.terrain.water$easting <- ifelse (rsf.data.terrain.water$slope == 0, 0, rsf.data.terrain.water$easting) 
rsf.data.terrain.water$northing <- ifelse (rsf.data.terrain.water$slope == 0, 0, rsf.data.terrain.water$northing) 

############
### DU6 ###
#### Early Winter ####
#####################
rsf.data.terrain.water.du6.ew <- rsf.data.terrain.water %>%
                                  dplyr::filter (du == "du6") %>%
                                  dplyr::filter (season == "EarlyWinter")

### OUTLIERS ###
ggplot (rsf.data.terrain.water.du6.ew, aes (x = pttype, y = elevation)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Early Winter Elevation at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Elevation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_ew_elevation.png")
ggplot (rsf.data.terrain.water.du6.ew, aes (x = pttype, y = easting)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Early Winter Eastness at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Eastness")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_ew_east.png")
ggplot (rsf.data.terrain.water.du6.ew, aes (x = pttype, y = northing)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Early Winter Northness at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Northness")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_ew_north.png")
ggplot (rsf.data.terrain.water.du6.ew, aes (x = pttype, y = slope)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Early Winter Slope at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Slope")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_ew_slope.png")

ggplot (rsf.data.terrain.water.du6.ew, aes (x = pttype, y = distance_to_lake)) +
            geom_boxplot (outlier.colour = "red") +
            labs (title = "Boxplot DU6, Early Winter Distance to Lake at Available (0) and Used (1) Locations",
                  x = "Available (0) and Used (1) Locations",
                  y = "Distance to Lake")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_ew_dist_lake.png")
ggplot (rsf.data.terrain.water.du6.ew, aes (x = pttype, y = distance_to_watercourse)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Early Winter Distance to Watercourse at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Watercourse")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_ew_dist_watercourse.png")

### HISTOGRAMS ###
ggplot (rsf.data.terrain.water.du6.ew, aes (x = elevation, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 25) +
        labs (title = "Histogram DU6, Early Winter Elevation at Available (0) and Used (1) Locations",
              x = "Elevation",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_ew_elevation.png")
ggplot (rsf.data.terrain.water.du6.ew, aes (x = easting, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 0.1) +
        labs (title = "Histogram DU6, Early Winter Eastness at Available (0) and Used (1) Locations",
              x = "Eastness",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_ew_eastness.png")
ggplot (rsf.data.terrain.water.du6.ew, aes (x = northing, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 0.1) +
        labs (title = "Histogram DU6, Early Winter Northness at Available (0) and Used (1) Locations",
              x = "Northness",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_ew_northness.png")
ggplot (rsf.data.terrain.water.du6.ew, aes (x = slope, fill = pttype)) + 
          geom_histogram (position = "dodge", binwidth = 5) +
          labs (title = "Histogram DU6, Early Winter Slope at Available (0) and Used (1) Locations",
                x = "Slope",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_ew_slope.png")
ggplot (rsf.data.terrain.water.du6.ew, aes (x = distance_to_lake, fill = pttype)) + 
        geom_histogram (position = "dodge", binwidth = 200) +
        labs (title = "Histogram DU6, Early Winter Distance to Lake at Available (0) and Used (1) Locations",
              x = "Distance to Lake",
              y = "Count") +
        scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_ew_dist_lake.png")
ggplot (rsf.data.terrain.water.du6.ew, aes (x = distance_to_watercourse, fill = pttype)) + 
          geom_histogram (position = "dodge", binwidth = 200) +
          labs (title = "Histogram DU6, Early Winter Distance to Watercourse at Available (0) and Used (1) Locations",
                x = "Distance to Watercourse",
                y = "Count") +
          scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_ew_dist_watercourse.png")

### CORRELATION ###
corr.terrain.water.du6.ew <- rsf.data.terrain.water.du6.ew [c (10:15)]
corr.terrain.water.du6.ew <- round (cor (corr.terrain.water.du6.ew, method = "spearman"), 3)
ggcorrplot (corr.terrain.water.du6.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Terrain and Water Resource Selection Function Model
            Covariate Correlations for DU6, Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_terrain_water.png")

# VIF

