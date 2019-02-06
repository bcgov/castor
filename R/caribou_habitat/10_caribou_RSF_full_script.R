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

#==========================================
# TO TURN SCRIPT FOR DIFFERENT DUs and SEASONS:
# Find and Repalce:
# 1. .ew .lw .s
# dy6, du7, du8, du9

options (scipen = 999)
require (dplyr)
require (ggplot2)
require (ggcorrplot)
require (car)
require (lme4)

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
test <- rsf.data.human.dist %>% filter (is.na (distance_to_ski_hill))

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

# noticed issue with eastness/northness data, need to make value = 0 if slope = 0
rsf.data.terrain.water$easting <- ifelse (rsf.data.terrain.water$slope == 0, 0, rsf.data.terrain.water$easting) 
rsf.data.terrain.water$northing <- ifelse (rsf.data.terrain.water$slope == 0, 0, rsf.data.terrain.water$northing) 


# Group road data into low-use types (resource roads)
rsf.data.human.dist <- dplyr::mutate (rsf.data.human.dist, distance_to_resource_road = pmin (distance_to_loose_road, 
                                                                                             distance_to_petroleum_road,
                                                                                             distance_to_rough_road,
                                                                                             distance_to_trim_transport_road,
                                                                                             distance_to_unknown_road))
#######################
### FITTING MODELS ###
#####################




############
### DU6 ###
#### Early Winter ####
#####################
#=================================
# Terrain and Water Models
#=================================
rsf.data.terrain.water.du6.ew <- rsf.data.terrain.water %>%
                                  dplyr::filter (du == "du6") %>%
                                  dplyr::filter (season == "EarlyWinter")
rsf.data.terrain.water.du6.ew$soil_parent_material_name <- relevel (rsf.data.terrain.water.du6.ew$soil_parent_material_name,
                                                                    ref = "Till")
### OUTLIERS ###
ggplot (rsf.data.terrain.water.du6.ew, aes (x = pttype, y = slope)) +
        geom_boxplot (outlier.colour = "red") +
        labs (title = "Boxplot DU6, Early Winter Slope at Available (0) and Used (1) Locations",
              x = "Available (0) and Used (1) Locations",
              y = "Slope")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_ew_slope.png")

####
rsf.data.terrain.water.du6.ew <- rsf.data.terrain.water.du6.ew %>%
                                  filter (slope < 85) # remove outlier
####
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
corr.terrain.water.du6.ew <- rsf.data.terrain.water.du6.ew [c (13:15)]
corr.terrain.water.du6.ew <- round (cor (corr.terrain.water.du6.ew, method = "spearman"), 3)
ggcorrplot (corr.terrain.water.du6.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Terrain and Water Resource Selection Function Model
            Covariate Correlations for DU6, Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_terrain_water.png")

### VIF ###
glm.terrain.du6.ew <- glm (pttype ~ slope + distance_to_lake +
                                    distance_to_watercourse + soil_parent_material_name, 
                            data = rsf.data.terrain.water.du6.ew,
                            family = binomial (link = 'logit'))
car::vif (glm.terrain.du6.ew)

### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

### Generalized Linear Mixed Models (GLMMs) ###
# standardize covariates  (helps with model convergence)
rsf.data.terrain.water.du6.ew$std.elevation <- (rsf.data.terrain.water.du6.ew$elevation - 
                                                  mean (rsf.data.terrain.water.du6.ew$elevation)) / 
                                                  sd (rsf.data.terrain.water.du6.ew$elevation)
rsf.data.terrain.water.du6.ew$std.easting <- (rsf.data.terrain.water.du6.ew$easting - 
                                                  mean (rsf.data.terrain.water.du6.ew$easting)) / 
                                                  sd (rsf.data.terrain.water.du6.ew$easting)
rsf.data.terrain.water.du6.ew$std.northing <- (rsf.data.terrain.water.du6.ew$northing - 
                                                mean (rsf.data.terrain.water.du6.ew$northing)) / 
                                                sd (rsf.data.terrain.water.du6.ew$northing)
rsf.data.terrain.water.du6.ew$std.slope <- (rsf.data.terrain.water.du6.ew$slope - 
                                                 mean (rsf.data.terrain.water.du6.ew$slope)) / 
                                                  sd (rsf.data.terrain.water.du6.ew$slope)
rsf.data.terrain.water.du6.ew$std.distance_to_lake <- (rsf.data.terrain.water.du6.ew$distance_to_lake - 
                                                        mean (rsf.data.terrain.water.du6.ew$distance_to_lake)) / 
                                                        sd (rsf.data.terrain.water.du6.ew$distance_to_lake)
rsf.data.terrain.water.du6.ew$std.distance_to_watercourse <- (rsf.data.terrain.water.du6.ew$distance_to_watercourse - 
                                                              mean (rsf.data.terrain.water.du6.ew$distance_to_watercourse)) / 
                                                              sd (rsf.data.terrain.water.du6.ew$distance_to_watercourse)

## SLOPE ##
model.lme4.du6.ew.slope <- glmer (pttype ~ std.slope + (1 | uniqueID), 
                                   data = rsf.data.terrain.water.du6.ew, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Early Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "Slope"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du6.ew.slope)

## DISTANCE TO LAKE ##
model.lme4.du6.ew.lake <- glmer (pttype ~ std.distance_to_lake + (1 | uniqueID), 
                                  data = rsf.data.terrain.water.du6.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Early Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "Dist. to Lake"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du6.ew.lake)

## DISTANCE TO WATERCOURSE ##
model.lme4.du6.ew.wc <- glmer (pttype ~ std.distance_to_watercourse  + 
                                          (1 | uniqueID), 
                                 data = rsf.data.terrain.water.du6.ew, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Early Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "Dist. to Watercourse"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du6.ew.wc)

## SOIL ##
model.lme4.du6.ew.soil <- glmer (pttype ~ soil_parent_material_name  + 
                                          (1 | uniqueID), 
                                 data = rsf.data.terrain.water.du6.ew, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [4, 1] <- "DU6"
table.aic [4, 2] <- "Early Winter"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "Soil"
table.aic [4, 5] <- "(1 | UniqueID)"
table.aic [4, 6] <-  AIC (model.lme4.du6.ew.soil)

## SLOPE AND DISTANCE TO LAKE ##
model.lme4.du6.ew.slope.lake <- update (model.lme4.du6.ew.slope,
                                         . ~ . + std.distance_to_lake) 
# AIC
table.aic [5, 1] <- "DU6"
table.aic [5, 2] <- "Early Winter"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "Slope, Dist. to Lake"
table.aic [5, 5] <- "(1 | UniqueID)"
table.aic [5, 6] <-  AIC (model.lme4.du6.ew.slope.lake) 

## SLOPE AND DISTANCE TO WATERCOURSE ##
model.lme4.du6.ew.slope.water <- update (model.lme4.du6.ew.slope,
                                         . ~ . + std.distance_to_watercourse) 
# AIC
table.aic [6, 1] <- "DU6"
table.aic [6, 2] <- "Early Winter"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "Slope, Dist. to Watercourse"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <-  AIC (model.lme4.du6.ew.slope.water) 

## SLOPE AND SOIL ##
model.lme4.du6.ew.slope.soil <- update (model.lme4.du6.ew.slope,
                                          . ~ . + soil_parent_material_name) 
# AIC
table.aic [7, 1] <- "DU6"
table.aic [7, 2] <- "Early Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "Slope, Soil"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du6.ew.slope.soil) 

## DISTANCE TO LAKE AND WATERCOURSE ##
model.lme4.du6.ew.lake.water <- update (model.lme4.du6.ew.lake,
                                        . ~ . + std.distance_to_watercourse)
# AIC
table.aic [8, 1] <- "DU6"
table.aic [8, 2] <- "Early Winter"
table.aic [8, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [8, 4] <- "Dist. to Lake, Dist. to Watercourse"
table.aic [8, 5] <- "(1 | UniqueID)"
table.aic [8, 6] <-  AIC (model.lme4.du6.ew.lake.water)

## DISTANCE TO LAKE AND SOIL ##
model.lme4.du6.ew.lake.soil <- update (model.lme4.du6.ew.lake,
                                        . ~ . + soil_parent_material_name)
# AIC
table.aic [9, 1] <- "DU6"
table.aic [9, 2] <- "Early Winter"
table.aic [9, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [9, 4] <- "Dist. to Lake, Soil"
table.aic [9, 5] <- "(1 | UniqueID)"
table.aic [9, 6] <- AIC (model.lme4.du6.ew.lake.soil)

## DISTANCE TO WATERCOURSE AND SOIL ##
model.lme4.du6.ew.water.soil <- update (model.lme4.du6.ew.wc,
                                         . ~ . + soil_parent_material_name)
# AIC
table.aic [10, 1] <- "DU6"
table.aic [10, 2] <- "Early Winter"
table.aic [10, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [10, 4] <- "Dist. to Watercourse, Soil"
table.aic [10, 5] <- "(1 | UniqueID)"
table.aic [10, 6] <-  AIC (model.lme4.du6.ew.water.soil)

## SLOPE, DISTANCE TO LAKE AND DISTANCE TO WATERCOURSE ##
model.lme4.du6.ew.slope.lake.wc <- update (model.lme4.du6.ew.slope.lake,
                                            . ~ . + std.distance_to_watercourse) 
# AIC
table.aic [11, 1] <- "DU6"
table.aic [11, 2] <- "Early Winter"
table.aic [11, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [11, 4] <- "Slope, Dist. to Lake, Dist. to Watercourse"
table.aic [11, 5] <- "(1 | UniqueID)"
table.aic [11, 6] <-  AIC (model.lme4.du6.ew.slope.lake.wc) 

## SLOPE, DISTANCE TO LAKE AND SOIL ##
model.lme4.du6.ew.slope.lake.soil <- update (model.lme4.du6.ew.slope.lake,
                                            . ~ . + soil_parent_material_name) 
# AIC
table.aic [12, 1] <- "DU6"
table.aic [12, 2] <- "Early Winter"
table.aic [12, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [12, 4] <- "Slope, Dist. to Lake, Soil"
table.aic [12, 5] <- "(1 | UniqueID)"
table.aic [12, 6] <-  AIC (model.lme4.du6.ew.slope.lake.soil) 

## SLOPE, DISTANCE TO WATERCOURSE AND SOIL ##
model.lme4.du6.ew.slope.water.soil <- update (model.lme4.du6.ew.slope.water,
                                             . ~ . + soil_parent_material_name) 
# AIC
table.aic [13, 1] <- "DU6"
table.aic [13, 2] <- "Early Winter"
table.aic [13, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [13, 4] <- "Slope, Dist. to Watercourse, Soil"
table.aic [13, 5] <- "(1 | UniqueID)"
table.aic [13, 6] <-  AIC (model.lme4.du6.ew.slope.water.soil) 

## DISTANCE TO LAKE, DISTANCE TO WATERCOURSE AND SOIL ##
model.lme4.du6.ew.lake.water.soil <- update (model.lme4.du6.ew.lake.water,
                                             . ~ . + soil_parent_material_name) 
# AIC
table.aic [14, 1] <- "DU6"
table.aic [14, 2] <- "Early Winter"
table.aic [14, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [14, 4] <- "Dist. to Lake, Dist. to Watercourse, Soil"
table.aic [14, 5] <- "(1 | UniqueID)"
table.aic [14, 6] <-  AIC (model.lme4.du6.ew.lake.water.soil) 

## SLOPE, DISTANCE TO LAKE, DISTANCE TO WATERCOURSE AND SOIL ##
model.lme4.du6.ew.slope.lake.wc.soil <- update (model.lme4.du6.ew.slope.lake.wc,
                                                  . ~ . + soil_parent_material_name) 
# AIC
table.aic [15, 1] <- "DU6"
table.aic [15, 2] <- "Early Winter"
table.aic [15, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [15, 4] <- "Slope, Dist. to Lake, Dist. to Watercourse, Soil"
table.aic [15, 5] <- "(1 | UniqueID)"
table.aic [15, 6] <- AIC (model.lme4.du6.ew.slope.lake.wc.soil) 

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

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_terrain_water_v3.csv", sep = ",")

# save the top endurign features model
save (model.lme4.du6.ew.slope.lake.wc.soil, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\terrain\\model_du6_ew_ef_top.rda")

#=================================
# Human Disturbance Models
#=================================
rsf.data.human.dist.du6.ew <- rsf.data.human.dist %>%
                                    dplyr::filter (du == "du6") %>%
                                    dplyr::filter (season == "EarlyWinter")


# group cutblock ages together, as per forest cutblcok model results
rsf.data.human.dist.du6.ew <- dplyr::mutate (rsf.data.human.dist.du6.ew, distance_to_cut_10yoorOver = pmin (distance_to_cut_10to29yo, distance_to_cut_30orOveryo))




### OUTLIERS ###
ggplot (rsf.data.human.dist.du6.ew, aes (x = pttype, y = distance_to_cut_1to4yo)) +
        geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Early Winter Distance to Cutblocks 1 to 4 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_ew_distcut1to4.png")
ggplot (rsf.data.human.dist.du6.ew, aes (x = pttype, y = distance_to_cut_5to9yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Early Winter Distance to Cutblocks 5 to 9 Years Old\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_ew_distcut5to9.png")
ggplot (rsf.data.human.dist.du6.ew, aes (x = pttype, y = distance_to_cut_10yoorOver)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Early Winter Distance to Cutblocks over 10 Years Old\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_ew_distcut_over10.png")
ggplot (rsf.data.human.dist.du6.ew, aes (x = pttype, y = distance_to_paved_road)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Early Winter Distance to Paved Road\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Paved Road")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_ew_dist_pvd_rd.png")
ggplot (rsf.data.human.dist.du6.ew, aes (x = pttype, y = distance_to_resource_road)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Early Winter Distance to Resource Road\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Resource Road")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_ew_dist_resource_rd.png")
ggplot (rsf.data.human.dist.du6.ew, aes (x = pttype, y = distance_to_agriculture)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Early Winter Distance to Agriculture\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Agriculture")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_ew_dist_ag.png")
ggplot (rsf.data.human.dist.du6.ew, aes (x = pttype, y = distance_to_mines)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Early Winter Distance to Mine\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Mine")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_ew_dist_mine.png")
ggplot (rsf.data.human.dist.du6.ew, aes (x = pttype, y = distance_to_pipeline)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Early Winter Distance to Pipeline\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Pipeline")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_ew_dist_pipe.png")
ggplot (rsf.data.human.dist.du6.ew, aes (x = pttype, y = distance_to_wells)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Early Winter Distance to Well\
        at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Well")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\boxplot_terrain_water_du6_ew_dist_well.png")

### HISTOGRAMS ###
ggplot (rsf.data.human.dist.du6.ew, aes (x = distance_to_cut_1to4yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 5) +
  labs (title = "Histogram DU6, Early Winter Distance to Cutblock 1 to 4 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Distance to Cutblock",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_ew_dist_cut_1to4.png")
ggplot (rsf.data.human.dist.du6.ew, aes (x = distance_to_cut_5to9yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 5) +
  labs (title = "Histogram DU6, Early Winter Distance to Cutblock 5 to 9 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Distance to Cutblock",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_ew_dist_cut_5to9.png")
ggplot (rsf.data.human.dist.du6.ew, aes (x = distance_to_cut_10yoorOver, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 5) +
  labs (title = "Histogram DU6, Early Winter Distance to Cutblock over 10 Years Old\
                at Available (0) and Used (1) Locations",
        x = "Distance to Cutblock",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_ew_dist_cut_over10.png")
ggplot (rsf.data.human.dist.du6.ew, aes (x = distance_to_paved_road, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Early Winter Distance to Paved Road\
                at Available (0) and Used (1) Locations",
        x = "Distance to Paved Road",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_ew_dist_pvd_rd.png")
ggplot (rsf.data.human.dist.du6.ew, aes (x = distance_to_resource_road, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Early Winter Distance to Resource Road\
                  at Available (0) and Used (1) Locations",
        x = "Distance to Resource Road",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_ew_dist_res_rd.png")
ggplot (rsf.data.human.dist.du6.ew, aes (x = distance_to_agriculture, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Early Winter Distance to Agriculture\
                  at Available (0) and Used (1) Locations",
        x = "Distance to Agriculture",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_ew_dist_ag.png")
ggplot (rsf.data.human.dist.du6.ew, aes (x = distance_to_mines, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Early Winter Distance to Mine at Available (0) and Used (1) Locations",
        x = "Distance to Mine",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_ew_dist_mine.png")
ggplot (rsf.data.human.dist.du6.ew, aes (x = distance_to_pipeline, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Early Winter Distance to Pipeline at\
                 Available (0) and Used (1) Locations",
        x = "Distance to Pipeline",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_ew_dist_pipe.png")
ggplot (rsf.data.human.dist.du6.ew, aes (x = distance_to_wells, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 200) +
  labs (title = "Histogram DU6, Early Winter Distance to Well at\
                 Available (0) and Used (1) Locations",
        x = "Distance to Pipeline",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\hist_terrain_water_du6_ew_dist_well.png")

### CORRELATION ###
corr.human.dist.du6.ew <- rsf.data.human.dist.du6.ew [c (10:11, 27, 14, 26, 20:24)]
corr.human.dist.du6.ew <- round (cor (corr.human.dist.du6.ew, method = "spearman"), 3)
ggcorrplot (corr.human.dist.du6.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Human Disturbance Resource Selection Function Model
            Covariate Correlations for DU6, Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\corr_human_dist.png")

### VIF ###
glm.human.du6.ew <- glm (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                                  distance_to_cut_10yoorOver + distance_to_paved_road +
                                  distance_to_resource_road + distance_to_mines +
                                  distance_to_pipeline + seismic, 
                           data = rsf.data.human.dist.du6.ew,
                           family = binomial (link = 'logit'))
car::vif (glm.human.du6.ew)

### Build an AIC and AUC Table ###
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

##############################################
### Generalized Linear Mixed Models (GLMMs) #
############################################
# standardize covariates  (helps with model convergence)
rsf.data.human.dist.du6.ew$std.distance_to_cut_1to4yo <- (rsf.data.human.dist.du6.ew$distance_to_cut_1to4yo - mean (rsf.data.human.dist.du6.ew$distance_to_cut_1to4yo)) / sd (rsf.data.human.dist.du6.ew$distance_to_cut_1to4yo)
rsf.data.human.dist.du6.ew$std.distance_to_cut_5to9yo <- (rsf.data.human.dist.du6.ew$distance_to_cut_5to9yo - mean (rsf.data.human.dist.du6.ew$distance_to_cut_5to9yo)) / sd (rsf.data.human.dist.du6.ew$distance_to_cut_5to9yo)
rsf.data.human.dist.du6.ew$std.distance_to_cut_10yoorOver <- (rsf.data.human.dist.du6.ew$distance_to_cut_10yoorOver - mean (rsf.data.human.dist.du6.ew$distance_to_cut_10yoorOver)) / sd (rsf.data.human.dist.du6.ew$distance_to_cut_10yoorOver)
rsf.data.human.dist.du6.ew$std.distance_to_paved_road <- (rsf.data.human.dist.du6.ew$distance_to_paved_road - mean (rsf.data.human.dist.du6.ew$distance_to_paved_road)) / sd (rsf.data.human.dist.du6.ew$distance_to_paved_road)
rsf.data.human.dist.du6.ew$std.distance_to_resource_road <- (rsf.data.human.dist.du6.ew$distance_to_resource_road - mean (rsf.data.human.dist.du6.ew$distance_to_resource_road)) / sd (rsf.data.human.dist.du6.ew$distance_to_resource_road)
rsf.data.human.dist.du6.ew$std.distance_to_mines <- (rsf.data.human.dist.du6.ew$distance_to_mines - mean (rsf.data.human.dist.du6.ew$distance_to_mines)) / sd (rsf.data.human.dist.du6.ew$distance_to_mines)
rsf.data.human.dist.du6.ew$std.distance_to_pipeline <- (rsf.data.human.dist.du6.ew$distance_to_pipeline - mean (rsf.data.human.dist.du6.ew$distance_to_pipeline)) / sd (rsf.data.human.dist.du6.ew$distance_to_pipeline)

# FUNCTIONAL RESPONSE Covariates
sub <- subset (rsf.data.human.dist.du6.ew, pttype == 0)
std.distance_to_cut_1to4yo_E <- tapply (sub$std.distance_to_cut_1to4yo, sub$uniqueID, mean)
std.distance_to_cut_5to9yo_E <- tapply (sub$std.distance_to_cut_5to9yo, sub$uniqueID, mean)
std.distance_to_cut_10yoorOver_E <- tapply (sub$std.distance_to_cut_10yoorOver, sub$uniqueID, mean)
std.distance_to_paved_road_E <- tapply (sub$std.distance_to_paved_road, sub$uniqueID, mean)
std.distance_to_mines_E <- tapply (sub$std.distance_to_mines, sub$uniqueID, mean)
std.distance_to_pipeline_E <- tapply (sub$std.distance_to_pipeline, sub$uniqueID, mean)
std.distance_to_resource_road_E <- tapply (sub$std.distance_to_resource_road, sub$uniqueID, mean)

inds <- as.character (rsf.data.human.dist.du6.ew$uniqueID)
rsf.data.human.dist.du6.ew <- cbind (rsf.data.human.dist.du6.ew, 
                                      "std.distance_to_cut_1to4yo_E" = std.distance_to_cut_1to4yo_E [inds],
                                      "std.distance_to_cut_5to9yo_E" = std.distance_to_cut_5to9yo_E [inds],
                                      "std.distance_to_cut_10yoorOver_E" = std.distance_to_cut_10yoorOver_E [inds],
                                      "std.distance_to_paved_road_E" = std.distance_to_paved_road_E [inds],
                                      "std.distance_to_mines_E" = std.distance_to_mines_E [inds],
                                      "std.distance_to_pipeline_E" = std.distance_to_pipeline_E [inds],
                                      "std.distance_to_resource_road_E" = std.distance_to_resource_road_E [inds])

## DISTANCE TO CUTBLOCK ##
model.lme4.du6.ew.cutblock <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                                              std.distance_to_cut_10yoorOver + (1 | uniqueID), 
                                      data = rsf.data.human.dist.du6.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Early Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "DC1to4, DC5to9, DCover9"
table.aic [1, 5] <- "(1 | UniqueID)"
table.aic [1, 6] <-  AIC (model.lme4.du6.ew.cutblock)

model.lme4.fxn.du6.ew.cutblock <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                                                  std.distance_to_cut_10yoorOver + 
                                                  std.distance_to_cut_1to4yo_E + 
                                                  std.distance_to_cut_5to9yo_E + 
                                                  std.distance_to_cut_10yoorOver_E + 
                                                  std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                                  std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E + 
                                                  std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                                  (1 | uniqueID), 
                                         data = rsf.data.human.dist.du6.ew, 
                                         family = binomial (link = "logit"),
                                         verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Early Winter"
table.aic [2, 3] <- "GLMM with Functional Response"
table.aic [2, 4] <- "DC1to4, DC5to9, DCover9, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DC5to9"
table.aic [2, 5] <- "(1 | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.fxn.du6.ew.cutblock)

## DISTANCE TO ROAD ##
model.lme4.du6.ew.road <- glmer (pttype ~ std.distance_to_paved_road + 
                                          std.distance_to_resource_road + (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Early Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "DPR, DRR"
table.aic [3, 5] <- "(1 | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du6.ew.road)

model.lme4.fxn.du6.ew.road <- glmer (pttype ~ std.distance_to_paved_road + 
                                              std.distance_to_resource_road +
                                              std.distance_to_paved_road_E +
                                              std.distance_to_resource_road_E +
                                              std.distance_to_paved_road:std.distance_to_paved_road_E +
                                              std.distance_to_resource_road:std.distance_to_resource_road_E +
                                              (1 | uniqueID), 
                                         data = rsf.data.human.dist.du6.ew, 
                                         family = binomial (link = "logit"),
                                         verbose = T) 
# AIC
table.aic [4, 1] <- "DU6"
table.aic [4, 2] <- "Early Winter"
table.aic [4, 3] <- "GLMM with Functional Response"
table.aic [4, 4] <- "DPR, DRR, A_DRP, A_DRR, DPR*A_DRP, DRR*A_DRR"
table.aic [4, 5] <- "(1 | UniqueID)"
table.aic [4, 6] <-  AIC (model.lme4.fxn.du6.ew.road)

## DISTANCE TO MINE ##
model.lme4.du6.ew.mine <- glmer (pttype ~ std.distance_to_mines + (1 | uniqueID), 
                                 data = rsf.data.human.dist.du6.ew, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [5, 1] <- "DU6"
table.aic [5, 2] <- "Early Winter"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "DMine"
table.aic [5, 5] <- "(1 | UniqueID)"
table.aic [5, 6] <-  AIC (model.lme4.du6.ew.mine)

model.lme4.fxn.du6.ew.mine <- glmer (pttype ~ std.distance_to_mines + 
                                              std.distance_to_mines_E +
                                               std.distance_to_mines:std.distance_to_mines_E +
                                               (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [6, 1] <- "DU6"
table.aic [6, 2] <- "Early Winter"
table.aic [6, 3] <- "GLMM with Functional Response"
table.aic [6, 4] <- "DMine, A_DMine, DMine*A_DMine"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <-  AIC (model.lme4.fxn.du6.ew.mine)

## DISTANCE TO PIPELINE ##
model.lme4.du6.ew.pipe <- glmer (pttype ~ std.distance_to_pipeline + (1 | uniqueID), 
                                 data = rsf.data.human.dist.du6.ew, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [7, 1] <- "DU6"
table.aic [7, 2] <- "Early Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "DPipeline"
table.aic [7, 5] <- "(1 | UniqueID)"
table.aic [7, 6] <-  AIC (model.lme4.du6.ew.pipe)

model.lme4.fxn.du6.ew.pipe <- glmer (pttype ~ std.distance_to_pipeline + 
                                       std.distance_to_pipeline_E +
                                       std.distance_to_pipeline:std.distance_to_pipeline_E +
                                       (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [8, 1] <- "DU6"
table.aic [8, 2] <- "Early Winter"
table.aic [8, 3] <- "GLMM with Functional Response"
table.aic [8, 4] <- "DPipeline, A_DPipeline, DPipeline*A_DPipeline"
table.aic [8, 5] <- "(1 | UniqueID)"
table.aic [8, 6] <-  AIC (model.lme4.fxn.du6.ew.pipe)

## SEISMIC ##
model.lme4.du6.ew.seismic <- glmer (pttype ~ seismic + (1 | uniqueID), 
                                 data = rsf.data.human.dist.du6.ew, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [9, 1] <- "DU6"
table.aic [9, 2] <- "Early Winter"
table.aic [9, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [9, 4] <- "Seismic"
table.aic [9, 5] <- "(1 | UniqueID)"
table.aic [9, 6] <-  AIC (model.lme4.du6.ew.pipe)


write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_human_disturb.csv", sep = ",")
