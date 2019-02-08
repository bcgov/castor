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
seismic_E <- tapply (sub$seismic, sub$uniqueID, sum)

inds <- as.character (rsf.data.human.dist.du6.ew$uniqueID)
rsf.data.human.dist.du6.ew <- cbind (rsf.data.human.dist.du6.ew, 
                                      "std.distance_to_cut_1to4yo_E" = std.distance_to_cut_1to4yo_E [inds],
                                      "std.distance_to_cut_5to9yo_E" = std.distance_to_cut_5to9yo_E [inds],
                                      "std.distance_to_cut_10yoorOver_E" = std.distance_to_cut_10yoorOver_E [inds],
                                      "std.distance_to_paved_road_E" = std.distance_to_paved_road_E [inds],
                                      "std.distance_to_mines_E" = std.distance_to_mines_E [inds],
                                      "std.distance_to_pipeline_E" = std.distance_to_pipeline_E [inds],
                                      "std.distance_to_resource_road_E" = std.distance_to_resource_road_E [inds],
                                      "seismic_E" = seismic_E [inds])

rsf.data.human.dist.du6.ew$std.seismic_E <- (rsf.data.human.dist.du6.ew$seismic_E - mean (rsf.data.human.dist.du6.ew$seismic_E)) / sd (rsf.data.human.dist.du6.ew$seismic_E)

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
table.aic [9, 6] <-  AIC (model.lme4.du6.ew.seismic)

model.lme4.fxn.du6.ew.seismic <- glmer (pttype ~ seismic + 
                                                 seismic_E +
                                                 seismic:seismic_E +
                                                 (1 | uniqueID), 
                                         data = rsf.data.human.dist.du6.ew, 
                                         family = binomial (link = "logit"),
                                         verbose = T) 
# AIC
table.aic [10, 1] <- "DU6"
table.aic [10, 2] <- "Early Winter"
table.aic [10, 3] <- "GLMM with Functional Response"
table.aic [10, 4] <- "Seismic, A_Seismic, Seismic*A_Seismic"
table.aic [10, 5] <- "(1 | UniqueID)"
table.aic [10, 6] <-  AIC (model.lme4.fxn.du6.ew.seismic)

## DISTANCE TO CUTBLOCK and DISTANCE TO ROAD ##
model.lme4.du6.ew.cut.road <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                              std.distance_to_cut_5to9yo + 
                                              std.distance_to_cut_10yoorOver + 
                                              std.distance_to_paved_road +
                                              std.distance_to_resource_road +
                                              (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [11, 1] <- "DU6"
table.aic [11, 2] <- "Early Winter"
table.aic [11, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [11, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR"
table.aic [11, 5] <- "(1 | UniqueID)"
table.aic [11, 6] <-  AIC (model.lme4.du6.ew.cut.road)

model.lme4.fxn.du6.ew.cut.road1 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                  std.distance_to_cut_5to9yo + 
                                                  std.distance_to_cut_10yoorOver + 
                                                  std.distance_to_paved_road +
                                                  std.distance_to_resource_road +
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
table.aic [12, 1] <- "DU6"
table.aic [12, 2] <- "Early Winter"
table.aic [12, 3] <- "GLMM with Functional Response"
table.aic [12, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DC5to9"
table.aic [12, 5] <- "(1 | UniqueID)"
table.aic [12, 6] <-  AIC (model.lme4.fxn.du6.ew.cut.road1)

model.lme4.fxn.du6.ew.cut.road2 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                            std.distance_to_cut_5to9yo + 
                                            std.distance_to_cut_10yoorOver + 
                                            std.distance_to_paved_road +
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
table.aic [13, 1] <- "DU6"
table.aic [13, 2] <- "Early Winter"
table.aic [13, 3] <- "GLMM with Functional Response"
table.aic [13, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, A_DPR, A_DRR, DPR*A_DPR, DRR*A_DRR"
table.aic [13, 5] <- "(1 | UniqueID)"
table.aic [13, 6] <-  AIC (model.lme4.fxn.du6.ew.cut.road2)


## DISTANCE TO CUTBLOCK and DISTANCE TO MINE ##
model.lme4.du6.ew.cut.mine <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                               std.distance_to_cut_5to9yo + 
                                               std.distance_to_cut_10yoorOver + 
                                               std.distance_to_mines +
                                               (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [14, 1] <- "DU6"
table.aic [14, 2] <- "Early Winter"
table.aic [14, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [14, 4] <- "DC1to4, DC5to9, DCover9, DMine"
table.aic [14, 5] <- "(1 | UniqueID)"
table.aic [14, 6] <-  AIC (model.lme4.du6.ew.cut.mine)

model.lme4.fxn.du6.ew.cut.mine1 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                            std.distance_to_cut_5to9yo + 
                                            std.distance_to_cut_10yoorOver + 
                                            std.distance_to_mines +
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
table.aic [15, 1] <- "DU6"
table.aic [15, 2] <- "Early Winter"
table.aic [15, 3] <- "GLMM with Functional Response"
table.aic [15, 4] <- "DC1to4, DC5to9, DCover9, DMine, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DC5to9"
table.aic [15, 5] <- "(1 | UniqueID)"
table.aic [15, 6] <- "NA" # failed to converge

model.lme4.fxn.du6.ew.cut.mine2 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                            std.distance_to_cut_5to9yo + 
                                            std.distance_to_cut_10yoorOver + 
                                            std.distance_to_mines +
                                            std.distance_to_mines_E +
                                            std.distance_to_mines:std.distance_to_mines_E +
                                            (1 | uniqueID), 
                                          data = rsf.data.human.dist.du6.ew, 
                                          family = binomial (link = "logit"),
                                          verbose = T) 
# AIC
table.aic [16, 1] <- "DU6"
table.aic [16, 2] <- "Early Winter"
table.aic [16, 3] <- "GLMM with Functional Response"
table.aic [16, 4] <- "DC1to4, DC5to9, DCover9, DMine, A_DMine, DMine*A_DMine"
table.aic [16, 5] <- "(1 | UniqueID)"
table.aic [16, 6] <-  AIC (model.lme4.fxn.du6.ew.cut.mine2)

## DISTANCE TO CUTBLOCK and DISTANCE TO PIPELINE ##
model.lme4.du6.ew.cut.pipe <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                               std.distance_to_cut_5to9yo + 
                                               std.distance_to_cut_10yoorOver + 
                                               std.distance_to_pipeline +
                                               (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [17, 1] <- "DU6"
table.aic [17, 2] <- "Early Winter"
table.aic [17, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [17, 4] <- "DC1to4, DC5to9, DCover9, DPipeline"
table.aic [17, 5] <- "(1 | UniqueID)"
table.aic [17, 6] <-  AIC (model.lme4.du6.ew.cut.pipe)

model.lme4.du6.ew.cut.pipe1 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                          std.distance_to_cut_5to9yo + 
                                          std.distance_to_cut_10yoorOver + 
                                          std.distance_to_pipeline +
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
table.aic [18, 1] <- "DU6"
table.aic [18, 2] <- "Early Winter"
table.aic [18, 3] <- "GLMM with Functional Response"
table.aic [18, 4] <- "DC1to4, DC5to9, DCover9, DPipeline, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DC5to9"
table.aic [18, 5] <- "(1 | UniqueID)"
table.aic [18, 6] <-  AIC (model.lme4.du6.ew.cut.pipe1)

model.lme4.du6.ew.cut.pipe2 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                        std.distance_to_cut_5to9yo + 
                                        std.distance_to_cut_10yoorOver + 
                                        std.distance_to_pipeline +
                                        std.distance_to_pipeline_E + 
                                        std.distance_to_pipeline:std.distance_to_pipeline_E +
                                        (1 | uniqueID), 
                                      data = rsf.data.human.dist.du6.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [19, 1] <- "DU6"
table.aic [19, 2] <- "Early Winter"
table.aic [19, 3] <- "GLMM with Functional Response"
table.aic [19, 4] <- "DC1to4, DC5to9, DCover9, DPipeline, A_DPipeline, DPipeline*A_DPipeline"
table.aic [19, 5] <- "(1 | UniqueID)"
table.aic [19, 6] <-  AIC (model.lme4.du6.ew.cut.pipe2)

## DISTANCE TO CUTBLOCK and SEISMIC ##
model.lme4.du6.ew.cut.seis <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                       std.distance_to_cut_5to9yo + 
                                       std.distance_to_cut_10yoorOver + 
                                       seismic +
                                       (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [20, 1] <- "DU6"
table.aic [20, 2] <- "Early Winter"
table.aic [20, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [20, 4] <- "DC1to4, DC5to9, DCover9, Seismic"
table.aic [20, 5] <- "(1 | UniqueID)"
table.aic [20, 6] <-  AIC (model.lme4.du6.ew.cut.seis)

model.lme4.du6.ew.cut.seis1 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                        std.distance_to_cut_5to9yo + 
                                        std.distance_to_cut_10yoorOver + 
                                        seismic +
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
table.aic [21, 1] <- "DU6"
table.aic [21, 2] <- "Early Winter"
table.aic [21, 3] <- "GLMM with Functional Response"
table.aic [21, 4] <- "DC1to4, DC5to9, DCover9, Seismic, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DC5to9"
table.aic [21, 5] <- "(1 | UniqueID)"
table.aic [21, 6] <-  AIC (model.lme4.du6.ew.cut.seis1)

model.lme4.du6.ew.cut.seis2 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                        std.distance_to_cut_5to9yo + 
                                        std.distance_to_cut_10yoorOver + 
                                        seismic +
                                        seismic_E + 
                                        seismic:seismic_E +
                                        (1 | uniqueID), 
                                      data = rsf.data.human.dist.du6.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [22, 1] <- "DU6"
table.aic [22, 2] <- "Early Winter"
table.aic [22, 3] <- "GLMM with Functional Response"
table.aic [22, 4] <- "DC1to4, DC5to9, DCover9, Seismic, A_Seismic, Seismic*A_Seismic"
table.aic [22, 5] <- "(1 | UniqueID)"
table.aic [22, 6] <-  AIC (model.lme4.du6.ew.cut.seis2)

## DISTANCE TO ROAD AND DISTANCE TO MINE ##
model.lme4.du6.ew.road.mine <- glmer (pttype ~ std.distance_to_paved_road + 
                                                std.distance_to_resource_road + 
                                                std.distance_to_mines +
                                                (1 | uniqueID), 
                                       data = rsf.data.human.dist.du6.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [23, 1] <- "DU6"
table.aic [23, 2] <- "Early Winter"
table.aic [23, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [23, 4] <- "DPR, DRR, DMine"
table.aic [23, 5] <- "(1 | UniqueID)"
table.aic [23, 6] <-  AIC (model.lme4.du6.ew.road.mine)

model.lme4.du6.ew.road.mine1 <- glmer (pttype ~ std.distance_to_paved_road + 
                                                std.distance_to_resource_road + 
                                                std.distance_to_mines +
                                                std.distance_to_paved_road_E + 
                                                std.distance_to_resource_road_E + 
                                                std.distance_to_paved_road:std.distance_to_paved_road_E +
                                                std.distance_to_resource_road:std.distance_to_resource_road_E + 
                                                (1 | uniqueID), 
                                      data = rsf.data.human.dist.du6.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [24, 1] <- "DU6"
table.aic [24, 2] <- "Early Winter"
table.aic [24, 3] <- "GLMM with Functional Response"
table.aic [24, 4] <- "DPR, DRR, DMine, A_DPR, A_DRR, DPR*A_DPR, DRR*A_DRR"
table.aic [24, 5] <- "(1 | UniqueID)"
table.aic [24, 6] <-  AIC (model.lme4.du6.ew.road.mine1)

model.lme4.du6.ew.road.mine2 <- glmer (pttype ~ std.distance_to_paved_road + 
                                         std.distance_to_resource_road + 
                                         std.distance_to_mines +
                                         std.distance_to_mines_E + 
                                         std.distance_to_mines:std.distance_to_mines_E +
                                         (1 | uniqueID), 
                                       data = rsf.data.human.dist.du6.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [25, 1] <- "DU6"
table.aic [25, 2] <- "Early Winter"
table.aic [25, 3] <- "GLMM with Functional Response"
table.aic [25, 4] <- "DPR, DRR, DMine, A_DMine, DMine*A_DMine"
table.aic [25, 5] <- "(1 | UniqueID)"
table.aic [25, 6] <-  AIC (model.lme4.du6.ew.road.mine2)

## DISTANCE TO ROAD AND DISTANCE TO PIPELINE ##
model.lme4.du6.ew.road.pipe <- glmer (pttype ~ std.distance_to_paved_road + 
                                                std.distance_to_resource_road + 
                                                std.distance_to_pipeline +
                                                (1 | uniqueID), 
                                      data = rsf.data.human.dist.du6.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [26, 1] <- "DU6"
table.aic [26, 2] <- "Early Winter"
table.aic [26, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [26, 4] <- "DPR, DRR, DPipeline"
table.aic [26, 5] <- "(1 | UniqueID)"
table.aic [26, 6] <-  AIC (model.lme4.du6.ew.road.pipe)

model.lme4.du6.ew.road.pipe1 <- glmer (pttype ~ std.distance_to_paved_road + 
                                                 std.distance_to_resource_road + 
                                                 std.distance_to_pipeline +
                                                 std.distance_to_paved_road_E + 
                                                 std.distance_to_resource_road_E + 
                                                 std.distance_to_paved_road:std.distance_to_paved_road_E +
                                                 std.distance_to_resource_road:std.distance_to_resource_road_E + 
                                                 (1 | uniqueID), 
                                      data = rsf.data.human.dist.du6.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [27, 1] <- "DU6"
table.aic [27, 2] <- "Early Winter"
table.aic [27, 3] <- "GLMM with Functional Response"
table.aic [27, 4] <- "DPR, DRR, DPipeline, A_DPR, A_DRR, DPR*A_DPR, DRR*A_DRR"
table.aic [27, 5] <- "(1 | UniqueID)"
table.aic [27, 6] <-  AIC (model.lme4.du6.ew.road.pipe1)

model.lme4.du6.ew.road.pipe2 <- glmer (pttype ~ std.distance_to_paved_road + 
                                         std.distance_to_resource_road + 
                                         std.distance_to_pipeline +
                                         std.distance_to_pipeline_E + 
                                         std.distance_to_pipeline:std.distance_to_pipeline_E +
                                         (1 | uniqueID), 
                                       data = rsf.data.human.dist.du6.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [28, 1] <- "DU6"
table.aic [28, 2] <- "Early Winter"
table.aic [28, 3] <- "GLMM with Functional Response"
table.aic [28, 4] <- "DPR, DRR, DPipeline, A_DPipeline, DPipeline*A_DPipeline"
table.aic [28, 5] <- "(1 | UniqueID)"
table.aic [28, 6] <-  AIC (model.lme4.du6.ew.road.pipe2)

## DISTANCE TO ROAD AND SEISMIC ##
model.lme4.du6.ew.road.seis <- glmer (pttype ~ std.distance_to_paved_road + 
                                                std.distance_to_resource_road + 
                                                seismic +
                                                (1 | uniqueID), 
                                      data = rsf.data.human.dist.du6.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [29, 1] <- "DU6"
table.aic [29, 2] <- "Early Winter"
table.aic [29, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [29, 4] <- "DPR, DRR, Seismic"
table.aic [29, 5] <- "(1 | UniqueID)"
table.aic [29, 6] <-  AIC (model.lme4.du6.ew.road.seis)

model.lme4.du6.ew.road.seis1 <- glmer (pttype ~ std.distance_to_paved_road + 
                                                 std.distance_to_resource_road + 
                                                 seismic +
                                                 std.distance_to_paved_road_E + 
                                                 std.distance_to_resource_road_E + 
                                                 std.distance_to_paved_road:std.distance_to_paved_road_E +
                                                 std.distance_to_resource_road:std.distance_to_resource_road_E + 
                                                 (1 | uniqueID), 
                                      data = rsf.data.human.dist.du6.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [30, 1] <- "DU6"
table.aic [30, 2] <- "Early Winter"
table.aic [30, 3] <- "GLMM with Functional Response"
table.aic [30, 4] <- "DPR, DRR, Seismic, A_DPR, A_DRR, DPR*A_DPR, DRR*A_DRR"
table.aic [30, 5] <- "(1 | UniqueID)"
table.aic [30, 6] <-  AIC (model.lme4.du6.ew.road.seis1)

model.lme4.du6.ew.road.seis2 <- glmer (pttype ~ std.distance_to_paved_road + 
                                                   std.distance_to_resource_road + 
                                                   seismic +
                                                   seismic_E + 
                                                   seismic:seismic_E +
                                                   (1 | uniqueID), 
                                       data = rsf.data.human.dist.du6.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [31, 1] <- "DU6"
table.aic [31, 2] <- "Early Winter"
table.aic [31, 3] <- "GLMM with Functional Response"
table.aic [31, 4] <- "DPR, DRR, Seismic, A_Seismic, Seismic*A_Seismic"
table.aic [31, 5] <- "(1 | UniqueID)"
table.aic [31, 6] <-  AIC (model.lme4.du6.ew.road.seis2)

## DISTANCE TO MINE AND DISTANCE TO PIPELINE ##
model.lme4.du6.ew.mine.pipe <- glmer (pttype ~ std.distance_to_mines + 
                                               std.distance_to_pipeline +
                                               (1 | uniqueID), 
                                     data = rsf.data.human.dist.du6.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [32, 1] <- "DU6"
table.aic [32, 2] <- "Early Winter"
table.aic [32, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [32, 4] <- "DMine, DPipeline"
table.aic [32, 5] <- "(1 | UniqueID)"
table.aic [32, 6] <-  AIC (model.lme4.du6.ew.mine.pipe)

model.lme4.du6.ew.mine.pipe1 <- glmer (pttype ~ std.distance_to_mines + 
                                                std.distance_to_pipeline +
                                                std.distance_to_mines_E + 
                                                std.distance_to_mines:std.distance_to_mines_E +
                                                (1 | uniqueID), 
                                      data = rsf.data.human.dist.du6.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [33, 1] <- "DU6"
table.aic [33, 2] <- "Early Winter"
table.aic [33, 3] <- "GLMM with Functional Response"
table.aic [33, 4] <- "DMine, DPipeline, A_DMine, DMine*A_DMine"
table.aic [33, 5] <- "(1 | UniqueID)"
table.aic [33, 6] <-  AIC (model.lme4.du6.ew.mine.pipe1)

model.lme4.du6.ew.mine.pipe2 <- glmer (pttype ~ std.distance_to_mines + 
                                         std.distance_to_pipeline +
                                         std.distance_to_pipeline_E + 
                                         std.distance_to_pipeline:std.distance_to_pipeline_E +
                                         (1 | uniqueID), 
                                       data = rsf.data.human.dist.du6.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [34, 1] <- "DU6"
table.aic [34, 2] <- "Early Winter"
table.aic [34, 3] <- "GLMM with Functional Response"
table.aic [34, 4] <- "DMine, DPipeline, A_DPipeline, DPipeline*A_DPipeline"
table.aic [34, 5] <- "(1 | UniqueID)"
table.aic [34, 6] <-  AIC (model.lme4.du6.ew.mine.pipe2)

## DISTANCE TO MINE AND SEISMIC ##
model.lme4.du6.ew.mine.seis <- glmer (pttype ~ std.distance_to_mines + 
                                                seismic +
                                                (1 | uniqueID), 
                                      data = rsf.data.human.dist.du6.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [35, 1] <- "DU6"
table.aic [35, 2] <- "Early Winter"
table.aic [35, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [35, 4] <- "DMine, Seismic"
table.aic [35, 5] <- "(1 | UniqueID)"
table.aic [35, 6] <-  AIC (model.lme4.du6.ew.mine.seis)

model.lme4.du6.ew.mine.seis1 <- glmer (pttype ~ std.distance_to_mines + 
                                                 seismic +
                                                 std.distance_to_mines_E + 
                                                 std.distance_to_mines:std.distance_to_mines_E +
                                                 (1 | uniqueID), 
                                      data = rsf.data.human.dist.du6.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [36, 1] <- "DU6"
table.aic [36, 2] <- "Early Winter"
table.aic [36, 3] <- "GLMM with Functional Response"
table.aic [36, 4] <- "DMine, Seismic, A_DMine, DMine*A_DMine"
table.aic [36, 5] <- "(1 | UniqueID)"
table.aic [36, 6] <-  AIC (model.lme4.du6.ew.mine.seis1)

model.lme4.du6.ew.mine.seis2 <- glmer (pttype ~ std.distance_to_mines + 
                                                 seismic +
                                                 seismic_E + 
                                                 seismic:seismic_E +
                                                 (1 | uniqueID), 
                                       data = rsf.data.human.dist.du6.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [37, 1] <- "DU6"
table.aic [37, 2] <- "Early Winter"
table.aic [37, 3] <- "GLMM with Functional Response"
table.aic [37, 4] <- "DMine, Seismic, A_Seismic, Seismic*A_Seismic"
table.aic [37, 5] <- "(1 | UniqueID)"
table.aic [37, 6] <-  AIC (model.lme4.du6.ew.mine.seis2)

## DISTANCE TO PIPELINE AND SEISMIC ##
model.lme4.du6.ew.pipe.seis <- glmer (pttype ~ std.distance_to_pipeline + 
                                               seismic +
                                               (1 | uniqueID), 
                                       data = rsf.data.human.dist.du6.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [38, 1] <- "DU6"
table.aic [38, 2] <- "Early Winter"
table.aic [38, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [38, 4] <- "DPipeline, Seismic"
table.aic [38, 5] <- "(1 | UniqueID)"
table.aic [38, 6] <-  AIC (model.lme4.du6.ew.pipe.seis)

model.lme4.du6.ew.pipe.seis1 <- glmer (pttype ~ std.distance_to_pipeline + 
                                                 seismic +
                                                 std.distance_to_pipeline_E + 
                                                 std.distance_to_pipeline:std.distance_to_pipeline_E +
                                                 (1 | uniqueID), 
                                      data = rsf.data.human.dist.du6.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [39, 1] <- "DU6"
table.aic [39, 2] <- "Early Winter"
table.aic [39, 3] <- "GLMM with Functional Response"
table.aic [39, 4] <- "DPipeline, Seismic, A_DPipeline, DPipeline*A_DPipeline"
table.aic [39, 5] <- "(1 | UniqueID)"
table.aic [39, 6] <-  AIC (model.lme4.du6.ew.pipe.seis)

model.lme4.du6.ew.pipe.seis2 <- glmer (pttype ~ std.distance_to_pipeline + 
                                                 seismic +
                                                 seismic_E + 
                                                 seismic:seismic_E +
                                                 (1 | uniqueID), 
                                       data = rsf.data.human.dist.du6.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T) 
# AIC
table.aic [40, 1] <- "DU6"
table.aic [40, 2] <- "Early Winter"
table.aic [40, 3] <- "GLMM with Functional Response"
table.aic [40, 4] <- "DPipeline, Seismic, A_Seismic, Seismic*A_Seismic"
table.aic [40, 5] <- "(1 | UniqueID)"
table.aic [40, 6] <-  AIC (model.lme4.du6.ew.pipe.seis2)


## DISTANCE TO CUTBLOCK, DISTANCE TO ROAD, DISTANCE TO MINE ##
model.lme4.du6.ew.cut.road.mine <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                   std.distance_to_cut_5to9yo + 
                                                   std.distance_to_cut_10yoorOver + 
                                                   std.distance_to_paved_road +
                                                   std.distance_to_resource_road +
                                                   std.distance_to_mines +
                                                   (1 | uniqueID), 
                                         data = rsf.data.human.dist.du6.ew, 
                                         family = binomial (link = "logit"),
                                         verbose = T) 
# AIC
table.aic [41, 1] <- "DU6"
table.aic [41, 2] <- "Early Winter"
table.aic [41, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [41, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, DMine"
table.aic [41, 5] <- "(1 | UniqueID)"
table.aic [41, 6] <-  AIC (model.lme4.du6.ew.cut.road.mine)

model.lme4.du6.ew.cut.road.mine1 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                    std.distance_to_cut_5to9yo + 
                                                    std.distance_to_cut_10yoorOver + 
                                                    std.distance_to_paved_road +
                                                    std.distance_to_resource_road +
                                                    std.distance_to_mines +
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
table.aic [42, 1] <- "DU6"
table.aic [42, 2] <- "Early Winter"
table.aic [42, 3] <- "GLMM with Functional Response"
table.aic [42, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, DMine, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DC5to9"
table.aic [42, 5] <- "(1 | UniqueID)"
table.aic [42, 6] <-  AIC (model.lme4.du6.ew.cut.road.mine1)

model.lme4.du6.ew.cut.road.mine2 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                             std.distance_to_cut_5to9yo + 
                                             std.distance_to_cut_10yoorOver + 
                                             std.distance_to_paved_road +
                                             std.distance_to_resource_road +
                                             std.distance_to_mines +
                                             std.distance_to_paved_road_E + 
                                             std.distance_to_resource_road_E + 
                                             std.distance_to_paved_road:std.distance_to_paved_road_E +
                                             std.distance_to_resource_road:std.distance_to_resource_road_E + 
                                             (1 | uniqueID), 
                                           data = rsf.data.human.dist.du6.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [43, 1] <- "DU6"
table.aic [43, 2] <- "Early Winter"
table.aic [43, 3] <- "GLMM with Functional Response"
table.aic [43, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, DMine, A_DPR, A_DRR, DPR*A_DPR, DRR*A_DRR"
table.aic [43, 5] <- "(1 | UniqueID)"
table.aic [43, 6] <-  AIC (model.lme4.du6.ew.cut.road.mine2)

model.lme4.du6.ew.cut.road.mine3 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                     std.distance_to_cut_5to9yo + 
                                                     std.distance_to_cut_10yoorOver + 
                                                     std.distance_to_paved_road +
                                                     std.distance_to_resource_road +
                                                     std.distance_to_mines +
                                                     std.distance_to_mines_E + 
                                                     std.distance_to_mines:std.distance_to_mines_E +
                                                     (1 | uniqueID), 
                                           data = rsf.data.human.dist.du6.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [44, 1] <- "DU6"
table.aic [44, 2] <- "Early Winter"
table.aic [44, 3] <- "GLMM with Functional Response"
table.aic [44, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, DMine, A_DMine, DMine*A_DMine"
table.aic [44, 5] <- "(1 | UniqueID)"
table.aic [44, 6] <-  AIC (model.lme4.du6.ew.cut.road.mine3)


## DISTANCE TO CUTBLOCK, DISTANCE TO ROAD, DISTANCE TO PIPELINE ##
model.lme4.du6.ew.cut.road.pipe <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                    std.distance_to_cut_5to9yo + 
                                                    std.distance_to_cut_10yoorOver + 
                                                    std.distance_to_paved_road +
                                                    std.distance_to_resource_road +
                                                    std.distance_to_pipeline +
                                                    (1 | uniqueID), 
                                          data = rsf.data.human.dist.du6.ew, 
                                          family = binomial (link = "logit"),
                                          verbose = T) 
# AIC
table.aic [45, 1] <- "DU6"
table.aic [45, 2] <- "Early Winter"
table.aic [45, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [45, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, DPipeline"
table.aic [45, 5] <- "(1 | UniqueID)"
table.aic [45, 6] <-  AIC (model.lme4.du6.ew.cut.road.pipe)

model.lme4.du6.ew.cut.road.pipe1 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                     std.distance_to_cut_5to9yo + 
                                                     std.distance_to_cut_10yoorOver + 
                                                     std.distance_to_paved_road +
                                                     std.distance_to_resource_road +
                                                     std.distance_to_pipeline +
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
table.aic [46, 1] <- "DU6"
table.aic [46, 2] <- "Early Winter"
table.aic [46, 3] <- "GLMM with Functional Response"
table.aic [46, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, DPipeline, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DC5to9"
table.aic [46, 5] <- "(1 | UniqueID)"
table.aic [46, 6] <-  "NA" # failed to converge

model.lme4.du6.ew.cut.road.pipe2 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                     std.distance_to_cut_5to9yo + 
                                                     std.distance_to_cut_10yoorOver + 
                                                     std.distance_to_paved_road +
                                                     std.distance_to_resource_road +
                                                     std.distance_to_pipeline +
                                                     std.distance_to_paved_road_E + 
                                                     std.distance_to_resource_road_E + 
                                                     std.distance_to_paved_road:std.distance_to_paved_road_E +
                                                     std.distance_to_resource_road:std.distance_to_resource_road_E + 
                                                     (1 | uniqueID), 
                                           data = rsf.data.human.dist.du6.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [47, 1] <- "DU6"
table.aic [47, 2] <- "Early Winter"
table.aic [47, 3] <- "GLMM with Functional Response"
table.aic [47, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, DPipeline, A_DPR, DPR*A_DPR, A_DRR, DRR*A_DRR"
table.aic [47, 5] <- "(1 | UniqueID)"
table.aic [47, 6] <-  AIC (model.lme4.du6.ew.cut.road.pipe2)

model.lme4.du6.ew.cut.road.pipe3 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                             std.distance_to_cut_5to9yo + 
                                             std.distance_to_cut_10yoorOver + 
                                             std.distance_to_paved_road +
                                             std.distance_to_resource_road +
                                             std.distance_to_pipeline +
                                             std.distance_to_pipeline_E + 
                                             std.distance_to_pipeline:std.distance_to_pipeline_E +
                                             (1 | uniqueID), 
                                           data = rsf.data.human.dist.du6.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [48, 1] <- "DU6"
table.aic [48, 2] <- "Early Winter"
table.aic [48, 3] <- "GLMM with Functional Response"
table.aic [48, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, DPipeline, A_DPipeline, DPipeline*A_DPipeline"
table.aic [48, 5] <- "(1 | UniqueID)"
table.aic [48, 6] <-  AIC (model.lme4.du6.ew.cut.road.pipe3)

## DISTANCE TO CUTBLOCK, DISTANCE TO ROAD, SEISMIC ##
model.lme4.du6.ew.cut.road.seis <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                    std.distance_to_cut_5to9yo + 
                                                    std.distance_to_cut_10yoorOver + 
                                                    std.distance_to_paved_road +
                                                    std.distance_to_resource_road +
                                                    seismic +
                                                    (1 | uniqueID), 
                                          data = rsf.data.human.dist.du6.ew, 
                                          family = binomial (link = "logit"),
                                          verbose = T) 
# AIC
table.aic [49, 1] <- "DU6"
table.aic [49, 2] <- "Early Winter"
table.aic [49, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [49, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, Seismic"
table.aic [49, 5] <- "(1 | UniqueID)"
table.aic [49, 6] <-  AIC (model.lme4.du6.ew.cut.road.seis)

model.lme4.du6.ew.cut.road.seis1 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                     std.distance_to_cut_5to9yo + 
                                                     std.distance_to_cut_10yoorOver + 
                                                     std.distance_to_paved_road +
                                                     std.distance_to_resource_road +
                                                     seismic +
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
table.aic [50, 1] <- "DU6"
table.aic [50, 2] <- "Early Winter"
table.aic [50, 3] <- "GLMM with Functional Response"
table.aic [50, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, Seismic, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DC5to9"
table.aic [50, 5] <- "(1 | UniqueID)"
table.aic [50, 6] <-  "NA" #failed to converge

model.lme4.du6.ew.cut.road.seis2 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                     std.distance_to_cut_5to9yo + 
                                                     std.distance_to_cut_10yoorOver + 
                                                     std.distance_to_paved_road +
                                                     std.distance_to_resource_road +
                                                     seismic +
                                                     std.distance_to_paved_road_E + 
                                                     std.distance_to_resource_road_E +
                                                     std.distance_to_paved_road:std.distance_to_paved_road_E +
                                                     std.distance_to_resource_road:std.distance_to_resource_road_E + 
                                                     (1 | uniqueID), 
                                           data = rsf.data.human.dist.du6.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [51, 1] <- "DU6"
table.aic [51, 2] <- "Early Winter"
table.aic [51, 3] <- "GLMM with Functional Response"
table.aic [51, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, Seismic, A_DPR, A_DRR, DPR*A_DPR, DRR*A_DRR"
table.aic [51, 5] <- "(1 | UniqueID)"
table.aic [51, 6] <-  AIC (model.lme4.du6.ew.cut.road.seis2)

model.lme4.du6.ew.cut.road.seis3 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                             std.distance_to_cut_5to9yo + 
                                             std.distance_to_cut_10yoorOver + 
                                             std.distance_to_paved_road +
                                             std.distance_to_resource_road +
                                             seismic +
                                             seismic_E +
                                             seismic:std.seismic_E +
                                             (1 | uniqueID), 
                                           data = rsf.data.human.dist.du6.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [52, 1] <- "DU6"
table.aic [52, 2] <- "Early Winter"
table.aic [52, 3] <- "GLMM with Functional Response"
table.aic [52, 4] <- "DC1to4, DC5to9, DCover9, DPR, DRR, Seismic, A_Seismic, Seismic*A_Seismic"
table.aic [52, 5] <- "(1 | UniqueID)"
table.aic [52, 6] <-  AIC (model.lme4.du6.ew.cut.road.seis3)


## DISTANCE TO CUTBLOCK, DISTANCE TO MINE, DISTANCE TO PIPELINE ##
model.lme4.du6.ew.cut.mine.pipe <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                   std.distance_to_cut_5to9yo + 
                                                   std.distance_to_cut_10yoorOver + 
                                                   std.distance_to_mines +
                                                   std.distance_to_pipeline +
                                                   (1 | uniqueID), 
                                           data = rsf.data.human.dist.du6.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [53, 1] <- "DU6"
table.aic [53, 2] <- "Early Winter"
table.aic [53, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [53, 4] <- "DC1to4, DC5to9, DCover9, DMine, DPipeline"
table.aic [53, 5] <- "(1 | UniqueID)"
table.aic [53, 6] <-  AIC (model.lme4.du6.ew.cut.mine.pipe)

model.lme4.du6.ew.cut.mine.pipe1 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                    std.distance_to_cut_5to9yo + 
                                                    std.distance_to_cut_10yoorOver + 
                                                    std.distance_to_mines +
                                                    std.distance_to_pipeline +
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
table.aic [54, 1] <- "DU6"
table.aic [54, 2] <- "Early Winter"
table.aic [54, 3] <- "GLMM with Functional Response"
table.aic [54, 4] <- "DC1to4, DC5to9, DCover9, DMine, DPipeline, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DC5to9"
table.aic [54, 5] <- "(1 | UniqueID)"
table.aic [54, 6] <-  AIC (model.lme4.du6.ew.cut.mine.pipe1)

model.lme4.du6.ew.cut.mine.pipe2 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                     std.distance_to_cut_5to9yo + 
                                                     std.distance_to_cut_10yoorOver + 
                                                     std.distance_to_mines +
                                                     std.distance_to_pipeline +
                                                     std.distance_to_mines_E + 
                                                     std.distance_to_mines:std.distance_to_mines_E +
                                                     (1 | uniqueID), 
                                           data = rsf.data.human.dist.du6.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [55, 1] <- "DU6"
table.aic [55, 2] <- "Early Winter"
table.aic [55, 3] <- "GLMM with Functional Response"
table.aic [55, 4] <- "DC1to4, DC5to9, DCover9, DMine, DPipeline, A_DMine, DMine*A_DMine"
table.aic [55, 5] <- "(1 | UniqueID)"
table.aic [55, 6] <-  AIC (model.lme4.du6.ew.cut.mine.pipe2)

model.lme4.du6.ew.cut.mine.pipe3 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                     std.distance_to_cut_5to9yo + 
                                                     std.distance_to_cut_10yoorOver + 
                                                     std.distance_to_mines +
                                                     std.distance_to_pipeline +
                                                     std.distance_to_pipeline_E + 
                                                     std.distance_to_pipeline:std.distance_to_pipeline_E +
                                                     (1 | uniqueID), 
                                           data = rsf.data.human.dist.du6.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [56, 1] <- "DU6"
table.aic [56, 2] <- "Early Winter"
table.aic [56, 3] <- "GLMM with Functional Response"
table.aic [56, 4] <- "DC1to4, DC5to9, DCover9, DMine, DPipeline, A_DPipeline, DPipeline*A_DPipeline"
table.aic [56, 5] <- "(1 | UniqueID)"
table.aic [56, 6] <-  AIC (model.lme4.du6.ew.cut.mine.pipe3)

## DISTANCE TO CUTBLOCK, DISTANCE TO MINE, SEISMIC ##
model.lme4.du6.ew.cut.mine.seis <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                    std.distance_to_cut_5to9yo + 
                                                    std.distance_to_cut_10yoorOver + 
                                                    std.distance_to_mines +
                                                    seismic +
                                                    (1 | uniqueID), 
                                          data = rsf.data.human.dist.du6.ew, 
                                          family = binomial (link = "logit"),
                                          verbose = T) 
# AIC
table.aic [57, 1] <- "DU6"
table.aic [57, 2] <- "Early Winter"
table.aic [57, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [57, 4] <- "DC1to4, DC5to9, DCover9, DMine, Seismic"
table.aic [57, 5] <- "(1 | UniqueID)"
table.aic [57, 6] <-  AIC (model.lme4.du6.ew.cut.mine.seis)

model.lme4.du6.ew.cut.mine.seis1 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                     std.distance_to_cut_5to9yo + 
                                                     std.distance_to_cut_10yoorOver + 
                                                     std.distance_to_mines +
                                                     seismic +
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
table.aic [58, 1] <- "DU6"
table.aic [58, 2] <- "Early Winter"
table.aic [58, 3] <- "GLMM with Functional Response"
table.aic [58, 4] <- "DC1to4, DC5to9, DCover9, DMine, Seismic, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DC5to9"
table.aic [58, 5] <- "(1 | UniqueID)"
table.aic [58, 6] <- "NA" # failed to converge

model.lme4.du6.ew.cut.mine.seis2 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                             std.distance_to_cut_5to9yo + 
                                             std.distance_to_cut_10yoorOver + 
                                             std.distance_to_mines +
                                             seismic +
                                             std.distance_to_mines_E +
                                             std.distance_to_mines:std.distance_to_mines_E +
                                             (1 | uniqueID), 
                                           data = rsf.data.human.dist.du6.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [59, 1] <- "DU6"
table.aic [59, 2] <- "Early Winter"
table.aic [59, 3] <- "GLMM with Functional Response"
table.aic [59, 4] <- "DC1to4, DC5to9, DCover9, DMine, Seismic, A_DMine, DMine*A_DMine"
table.aic [59, 5] <- "(1 | UniqueID)"
table.aic [59, 6] <- AIC (model.lme4.du6.ew.cut.mine.seis2)

model.lme4.du6.ew.cut.mine.seis3 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                     std.distance_to_cut_5to9yo + 
                                                     std.distance_to_cut_10yoorOver + 
                                                     std.distance_to_mines +
                                                     seismic +
                                                     seismic_E +
                                                     seismic:seismic_E +
                                                     (1 | uniqueID), 
                                           data = rsf.data.human.dist.du6.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [60, 1] <- "DU6"
table.aic [60, 2] <- "Early Winter"
table.aic [60, 3] <- "GLMM with Functional Response"
table.aic [60, 4] <- "DC1to4, DC5to9, DCover9, DMine, Seismic, A_Seismic, Seismic*A_Seismic"
table.aic [60, 5] <- "(1 | UniqueID)"
table.aic [60, 6] <- AIC (model.lme4.du6.ew.cut.mine.seis3)


## DISTANCE TO CUTBLOCK, DISTANCE TO PIPELINE, SEISMIC ##
model.lme4.du6.ew.cut.pipe.seis <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                   std.distance_to_cut_5to9yo + 
                                                   std.distance_to_cut_10yoorOver + 
                                                   std.distance_to_pipeline +
                                                   seismic +
                                                   (1 | uniqueID), 
                                           data = rsf.data.human.dist.du6.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [61, 1] <- "DU6"
table.aic [61, 2] <- "Early Winter"
table.aic [61, 3] <- "GLMM with Functional Response"
table.aic [61, 4] <- "DC1to4, DC5to9, DCover9, DPipeline, Seismic"
table.aic [61, 5] <- "(1 | UniqueID)"
table.aic [61, 6] <-  AIC (model.lme4.du6.ew.cut.pipe.seis)

model.lme4.du6.ew.cut.pipe.seis1 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                     std.distance_to_cut_5to9yo + 
                                                     std.distance_to_cut_10yoorOver + 
                                                     std.distance_to_pipeline +
                                                     seismic +
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
table.aic [62, 1] <- "DU6"
table.aic [62, 2] <- "Early Winter"
table.aic [62, 3] <- "GLMM with Functional Response"
table.aic [62, 4] <- "DC1to4, DC5to9, DCover9, DPipeline, Seismic, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DC5to9"
table.aic [62, 5] <- "(1 | UniqueID)"
table.aic [62, 6] <-  AIC (model.lme4.du6.ew.cut.pipe.seis1)

model.lme4.du6.ew.cut.pipe.seis2 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                     std.distance_to_cut_5to9yo + 
                                                     std.distance_to_cut_10yoorOver + 
                                                     std.distance_to_pipeline +
                                                     seismic +
                                                     std.distance_to_pipeline_E + 
                                                     std.distance_to_pipeline:std.distance_to_pipeline_E +
                                                     (1 | uniqueID), 
                                           data = rsf.data.human.dist.du6.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [63, 1] <- "DU6"
table.aic [63, 2] <- "Early Winter"
table.aic [63, 3] <- "GLMM with Functional Response"
table.aic [63, 4] <- "DC1to4, DC5to9, DCover9, DPipeline, Seismic, A_DPipeline, DPipeline*A_DPipeline"
table.aic [63, 5] <- "(1 | UniqueID)"
table.aic [63, 6] <-  AIC (model.lme4.du6.ew.cut.pipe.seis2)

model.lme4.du6.ew.cut.pipe.seis3 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                                     std.distance_to_cut_5to9yo + 
                                                     std.distance_to_cut_10yoorOver + 
                                                     std.distance_to_pipeline +
                                                     seismic +
                                                     seismic_E + 
                                                     seismic:seismic_E +
                                                     (1 | uniqueID), 
                                           data = rsf.data.human.dist.du6.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [64, 1] <- "DU6"
table.aic [64, 2] <- "Early Winter"
table.aic [64, 3] <- "GLMM with Functional Response"
table.aic [64, 4] <- "DC1to4, DC5to9, DCover9, DPipeline, Seismic, A_Seismic, Seismic*A_Seismic"
table.aic [64, 5] <- "(1 | UniqueID)"
table.aic [64, 6] <-  AIC (model.lme4.du6.ew.cut.pipe.seis3)

## DISTANCE TO ROAD, DISTANCE TO MINE, DISTANCE TO PIPELINE ##
model.lme4.du6.ew.road.mine.pipe <- glmer (pttype ~ std.distance_to_paved_road + 
                                                    std.distance_to_resource_road + 
                                                    std.distance_to_mines +
                                                    std.distance_to_pipeline +
                                                    (1 | uniqueID), 
                                            data = rsf.data.human.dist.du6.ew, 
                                            family = binomial (link = "logit"),
                                            verbose = T) 
# AIC
table.aic [65, 1] <- "DU6"
table.aic [65, 2] <- "Early Winter"
table.aic [65, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [65, 4] <- "DPR, DRR, DMine, DPipeline"
table.aic [65, 5] <- "(1 | UniqueID)"
table.aic [65, 6] <-  AIC (model.lme4.du6.ew.road.mine.pipe)

model.lme4.du6.ew.road.mine.pipe1 <- glmer (pttype ~ std.distance_to_paved_road + 
                                                      std.distance_to_resource_road + 
                                                      std.distance_to_mines +
                                                      std.distance_to_pipeline +
                                                      std.distance_to_paved_road_E + 
                                                      std.distance_to_resource_road_E +
                                                      std.distance_to_paved_road:std.distance_to_paved_road_E +
                                                      std.distance_to_resource_road:std.distance_to_resource_road_E + 
                                                      (1 | uniqueID), 
                                           data = rsf.data.human.dist.du6.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T) 
# AIC
table.aic [66, 1] <- "DU6"
table.aic [66, 2] <- "Early Winter"
table.aic [66, 3] <- "GLMM with Functional Response"
table.aic [66, 4] <- "DPR, DRR, DMine, DPipeline, A_DPR, A_DRR, DPR*A_DPR, DRR*A_DRR"
table.aic [66, 5] <- "(1 | UniqueID)"
table.aic [66, 6] <-  AIC (model.lme4.du6.ew.road.mine.pipe1)

model.lme4.du6.ew.road.mine.pipe2 <- glmer (pttype ~ std.distance_to_paved_road + 
                                                      std.distance_to_resource_road + 
                                                      std.distance_to_mines +
                                                      std.distance_to_pipeline +
                                                      std.distance_to_mines_E + 
                                                      std.distance_to_mines:std.distance_to_mines_E +
                                                      (1 | uniqueID), 
                                            data = rsf.data.human.dist.du6.ew, 
                                            family = binomial (link = "logit"),
                                            verbose = T) 
# AIC
table.aic [67, 1] <- "DU6"
table.aic [67, 2] <- "Early Winter"
table.aic [67, 3] <- "GLMM with Functional Response"
table.aic [67, 4] <- "DPR, DRR, DMine, DPipeline, A_DMine, DMine*A_DMine"
table.aic [67, 5] <- "(1 | UniqueID)"
table.aic [67, 6] <-  AIC (model.lme4.du6.ew.road.mine.pipe2)

model.lme4.du6.ew.road.mine.pipe3 <- glmer (pttype ~ std.distance_to_paved_road + 
                                                      std.distance_to_resource_road + 
                                                      std.distance_to_mines +
                                                      std.distance_to_pipeline +
                                                      std.distance_to_pipeline_E + 
                                                      std.distance_to_pipeline:std.distance_to_pipeline_E +
                                                      (1 | uniqueID), 
                                            data = rsf.data.human.dist.du6.ew, 
                                            family = binomial (link = "logit"),
                                            verbose = T) 
# AIC
table.aic [68, 1] <- "DU6"
table.aic [68, 2] <- "Early Winter"
table.aic [68, 3] <- "GLMM with Functional Response"
table.aic [68, 4] <- "DPR, DRR, DMine, DPipeline, A_DPipeline, DPipeline*A_DPipeline"
table.aic [68, 5] <- "(1 | UniqueID)"
table.aic [68, 6] <-  AIC (model.lme4.du6.ew.road.mine.pipe3)

## DISTANCE TO ROAD, DISTANCE TO MINE, SEISMIC ##
model.lme4.du6.ew.road.mine.seismic <- glmer (pttype ~ std.distance_to_paved_road + 
                                                        std.distance_to_resource_road + 
                                                        std.distance_to_mines +
                                                        seismic +
                                                        (1 | uniqueID), 
                                              data = rsf.data.human.dist.du6.ew, 
                                              family = binomial (link = "logit"),
                                              verbose = T) 
# AIC
table.aic [69, 1] <- "DU6"
table.aic [69, 2] <- "Early Winter"
table.aic [69, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [69, 4] <- "DPR, DRR, DMine, Seismic"
table.aic [69, 5] <- "(1 | UniqueID)"
table.aic [69, 6] <-  AIC (model.lme4.du6.ew.road.mine.seismic)




write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_human_disturb.csv", sep = ",")
