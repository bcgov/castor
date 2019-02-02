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
require (car)
require (lme4)
require (glmmTMB)
require (bbmle)






require (RPostgreSQL)
require (raster)
require (rgdal)
require (tidyr)
# require (snow)
require (reshape2)

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
test <- rsf.data.terrain.water %>% filter (is.na (elevation))

rsf.data.terrain.water <- rsf.data.terrain.water %>% 
                            filter (!is.na (soil_parent_material_name))
rsf.data.terrain.water <- rsf.data.terrain.water %>% 
                            filter (!is.na (distance_to_watercourse))
rsf.data.terrain.water <- rsf.data.terrain.water %>% 
                            filter (!is.na (slope))
rsf.data.terrain.water <- rsf.data.terrain.water %>% 
                            filter (!is.na (elevation))

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
rsf.data.terrain.water.du6.ew$soil_parent_material_name <- relevel (rsf.data.terrain.water.du6.ew$soil_parent_material_name,
                                                                    ref = "Till")
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
rsf.data.terrain.water.du6.ew <- rsf.data.terrain.water.du6.ew %>%
                                  filter (slope < 85) # remove outlier
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

### VIF ###
glm.terrain.du6.ew <- glm (pttype ~ elevation + easting + northing + slope + distance_to_lake +
                                     distance_to_watercourse + soil_parent_material_name, 
                            data = rsf.data.terrain.water.du6.ew,
                            family = binomial (link = 'logit'))
car::vif (glm.terrain.du6.ew)

### Build an AIC and AUC Table ###
table.aic <- data.frame (matrix (ncol = 8, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw", "AUC")

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

### fit random effects models ###
## ELEVATION ##
model.lme4.du6.ew.elevation <- glmer (pttype ~ std.elevation + (std.elevation | uniqueID), 
                                      data = rsf.data.terrain.water.du6.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Early Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "Elev"
table.aic [1, 5] <- "(Elev | UniqueID)"
table.aic [1, 6] <- AIC (model.lme4.du6.ew.elevation)

## ASPECT ##
model.lme4.du6.ew.aspect <- glmer (pttype ~ std.easting + std.northing + 
                                            (std.easting | uniqueID) + (std.northing | uniqueID), 
                                      data = rsf.data.terrain.water.du6.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Early Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "East, North"
table.aic [2, 5] <- "(East | UniqueID), (North | UniqueID)"
table.aic [2, 6] <-  AIC (model.lme4.du6.ew.aspect)

## SLOPE ##
model.lme4.du6.ew.slope <- glmer (pttype ~ std.slope + (std.slope | uniqueID), 
                                   data = rsf.data.terrain.water.du6.ew, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Early Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "Slope"
table.aic [3, 5] <- "(Slope | UniqueID)"
table.aic [3, 6] <-  AIC (model.lme4.du6.ew.slope)

## DISTANCE TO LAKE ##
model.lme4.du6.ew.lake <- glmer (pttype ~ std.distance_to_lake + (std.distance_to_lake | uniqueID), 
                                  data = rsf.data.terrain.water.du6.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
# AIC
table.aic [4, 1] <- "DU6"
table.aic [4, 2] <- "Early Winter"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "Dist. to Lake"
table.aic [4, 5] <- "(Dist. to Lake | UniqueID)"
table.aic [4, 6] <-  AIC (model.lme4.du6.ew.lake)

## DISTANCE TO WATERCOURSE ##
model.lme4.du6.ew.wc <- glmer (pttype ~ std.distance_to_watercourse  + 
                                          (std.distance_to_watercourse  | uniqueID), 
                                 data = rsf.data.terrain.water.du6.ew, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [5, 1] <- "DU6"
table.aic [5, 2] <- "Early Winter"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "Dist. to Watercourse"
table.aic [5, 5] <- "(Dist. to Watercourse | UniqueID)"
table.aic [5, 6] <-  AIC (model.lme4.du6.ew.wc)

## SOIL ##
model.lme4.du6.ew.soil <- glmer (pttype ~ soil_parent_material_name  + 
                                          (1 | uniqueID), 
                                 data = rsf.data.terrain.water.du6.ew, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [6, 1] <- "DU6"
table.aic [6, 2] <- "Early Winter"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "Soil"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <-  AIC (model.lme4.du6.ew.soil)

## ELEVATION AND ASPECT ##
model.lme4.du6.ew.elev.asp <- update (model.lme4.du6.ew.elevation, 
                                      . ~ . + std.easting + std.northing + 
                                             (std.easting | uniqueID) + (std.northing | uniqueID))
  
# AIC
table.aic [7, 1] <- "DU6"
table.aic [7, 2] <- "Early Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "Elev, East, North"
table.aic [7, 5] <- "(Elev | UniqueID), (East | UniqueID), (North | UniqueID)"
table.aic [7, 6] <- "NA" # model failed to converge

model.lme4.du6.ew.elev.asp2 <- update (model.lme4.du6.ew.elevation, 
                                      . ~ . + std.easting + std.northing)

# AIC
table.aic [8, 1] <- "DU6"
table.aic [8, 2] <- "Early Winter"
table.aic [8, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [8, 4] <- "Elev, East, North"
table.aic [8, 5] <- "(Elev | UniqueID)"
table.aic [8, 6] <- AIC (model.lme4.du6.ew.elev.asp2)

## ELEVATION AND SLOPE ##
model.lme4.du6.ew.elev.slp <- update (model.lme4.du6.ew.elevation, 
                                       . ~ . + std.slope +
                                       (std.slope | uniqueID))

# AIC
table.aic [9, 1] <- "DU6"
table.aic [9, 2] <- "Early Winter"
table.aic [9, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [9, 4] <- "Elev, Slope"
table.aic [9, 5] <- "(Elev | UniqueID), (Slope | UniqueID)"
table.aic [9, 6] <- "NA" # model failed to converge

model.lme4.du6.ew.elev.slp2 <- update (model.lme4.du6.ew.elevation, 
                                      . ~ . + std.slope )
# AIC
table.aic [10, 1] <- "DU6"
table.aic [10, 2] <- "Early Winter"
table.aic [10, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [10, 4] <- "Elev, Slope"
table.aic [10, 5] <- "(Elev | UniqueID)"
table.aic [10, 6] <- AIC (model.lme4.du6.ew.elev.slp2) 


model.lme4.du6.ew.elev.slp3 <- update (model.lme4.du6.ew.elevation, 
                                       . ~ . - (std.elevation | uniqueID) + 
                                             std.slope + 
                                             (std.slope | uniqueID))
# AIC
table.aic [11, 1] <- "DU6"
table.aic [11, 2] <- "Early Winter"
table.aic [11, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [11, 4] <- "Elev, Slope"
table.aic [11, 5] <- "(Slope | UniqueID)"
table.aic [11, 6] <- AIC (model.lme4.du6.ew.elev.slp3) 

## ELEVATION AND DISTANCE TO LAKE ##
model.lme4.du6.ew.elev.lake1 <- update (model.lme4.du6.ew.elevation, 
                                      . ~ . + std.distance_to_lake)

# AIC
table.aic [12, 1] <- "DU6"
table.aic [12, 2] <- "Early Winter"
table.aic [12, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [12, 4] <- "Elev, Dist. to Lake"
table.aic [12, 5] <- "(Elev | UniqueID)"
table.aic [12, 6] <- AIC (model.lme4.du6.ew.elev.lake1) 

model.lme4.du6.ew.elev.lake2 <- update (model.lme4.du6.ew.elevation, 
                                        . ~ . - (std.elevation | uniqueID) + 
                                          std.distance_to_lake + 
                                          (std.distance_to_lake | uniqueID))

# AIC
table.aic [13, 1] <- "DU6"
table.aic [13, 2] <- "Early Winter"
table.aic [13, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [13, 4] <- "Elev, Dist. to Lake"
table.aic [13, 5] <- "(Dist. to Lake | UniqueID)"
table.aic [13, 6] <- AIC (model.lme4.du6.ew.elev.lake2) 

## ELEVATION AND DISTANCE TO WATERCOURSE ##
model.lme4.du6.ew.elev.wc1 <- update (model.lme4.du6.ew.elevation, 
                                        . ~ . + std.distance_to_watercourse )

# AIC
table.aic [14, 1] <- "DU6"
table.aic [14, 2] <- "Early Winter"
table.aic [14, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [14, 4] <- "Elev, Dist. to Watercourse"
table.aic [14, 5] <- "(Elev | UniqueID)"
table.aic [14, 6] <- AIC (model.lme4.du6.ew.elev.wc1) 

model.lme4.du6.ew.elev.wc2 <- update (model.lme4.du6.ew.elevation, 
                                        . ~ . - (std.elevation | uniqueID) + 
                                          std.distance_to_watercourse + 
                                          (std.distance_to_watercourse | uniqueID))
# AIC
table.aic [15, 1] <- "DU6"
table.aic [15, 2] <- "Early Winter"
table.aic [15, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [15, 4] <- "Elev, Dist. to Watercourse"
table.aic [15, 5] <- "(Dist. to Watercourse | UniqueID)"
table.aic [15, 6] <- AIC (model.lme4.du6.ew.elev.wc2) 

## ELEVATION AND SOIL ##
model.lme4.du6.ew.elev.soil <- update (model.lme4.du6.ew.elevation, 
                                      . ~ . + soil_parent_material_name)

# AIC
table.aic [16, 1] <- "DU6"
table.aic [16, 2] <- "Early Winter"
table.aic [16, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [16, 4] <- "Elev, Soil"
table.aic [16, 5] <- "(Elev | UniqueID)"
table.aic [16, 6] <- AIC (model.lme4.du6.ew.elev.soil) 

## ASPECT AND SLOPE ##
model.lme4.du6.ew.aspect.slope1 <- update (model.lme4.du6.ew.aspect, 
                                            . ~ . + std.slope)

# AIC
table.aic [17, 1] <- "DU6"
table.aic [17, 2] <- "Early Winter"
table.aic [17, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [17, 4] <- "East, North, Slope"
table.aic [17, 5] <- "(East | UniqueID), (North | UniqueID)"
table.aic [17, 6] <-  "NA" # model did not converge

model.lme4.du6.ew.aspect.slope2 <- update (model.lme4.du6.ew.aspect, 
                                           . ~ .  - (std.easting | uniqueID) -
                                                    (std.northing | uniqueID) + 
                                                    std.slope + 
                                                    (std.slope | uniqueID))
# AIC
table.aic [18, 1] <- "DU6"
table.aic [18, 2] <- "Early Winter"
table.aic [18, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [18, 4] <- "East, North, Slope"
table.aic [18, 5] <- "(Slope | UniqueID)"
table.aic [18, 6] <-  AIC (model.lme4.du6.ew.aspect.slope2) 

## ASPECT AND DISTANCE TO LAKE ##
model.lme4.du6.ew.aspect.lake1 <- update (model.lme4.du6.ew.aspect, 
                                           . ~ . + std.distance_to_lake)
# AIC
table.aic [19, 1] <- "DU6"
table.aic [19, 2] <- "Early Winter"
table.aic [19, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [19, 4] <- "East, North, Dist. to Lake"
table.aic [19, 5] <- "(East | UniqueID), (North | UniqueID)"
table.aic [19, 6] <-  "NA" # model did not converge

model.lme4.du6.ew.aspect.lake2 <- update (model.lme4.du6.ew.aspect, 
                                           . ~ .  - (std.easting | uniqueID) -
                                             (std.northing | uniqueID) + 
                                             std.distance_to_lake + 
                                             (std.distance_to_lake | uniqueID))
# AIC
table.aic [20, 1] <- "DU6"
table.aic [20, 2] <- "Early Winter"
table.aic [20, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [20, 4] <- "East, North, Dist. to Lake"
table.aic [20, 5] <- "(Dist. to Lake | UniqueID)"
table.aic [20, 6] <-  AIC (model.lme4.du6.ew.aspect.lake2) 

## ASPECT AND DISTANCE TO WATER ##
model.lme4.du6.ew.aspect.water1 <- update (model.lme4.du6.ew.aspect, 
                                          . ~ . + std.distance_to_watercourse)
# AIC
table.aic [21, 1] <- "DU6"
table.aic [21, 2] <- "Early Winter"
table.aic [21, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [21, 4] <- "East, North, Dist. to Watercourse"
table.aic [21, 5] <- "(East | UniqueID), (North | UniqueID)"
table.aic [21, 6] <-  "NA" # did not converge

model.lme4.du6.ew.aspect.water2 <- update (model.lme4.du6.ew.aspect, 
                                          . ~ .  - (std.easting | uniqueID) -
                                            (std.northing | uniqueID) + 
                                            std.distance_to_watercourse + 
                                            (std.distance_to_watercourse | uniqueID))
# AIC
table.aic [22, 1] <- "DU6"
table.aic [22, 2] <- "Early Winter"
table.aic [22, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [22, 4] <- "East, North, Dist. to Watercourse"
table.aic [22, 5] <- "(Dist. to Watercourse | UniqueID)"
table.aic [22, 6] <-  AIC (model.lme4.du6.ew.aspect.water2) 

## ASPECT AND SOIL ##
model.lme4.du6.ew.aspect.soil1 <- update (model.lme4.du6.ew.aspect, 
                                           . ~ . + soil_parent_material_name)
# AIC
table.aic [23, 1] <- "DU6"
table.aic [23, 2] <- "Early Winter"
table.aic [23, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [23, 4] <- "East, North, Soil"
table.aic [23, 5] <- "(East | UniqueID), (North | UniqueID)"
table.aic [23, 6] <-  "NA" # did not converge

model.lme4.du6.ew.aspect.soil2 <- update (model.lme4.du6.ew.aspect, 
                                           . ~ .  - (std.easting | uniqueID) -
                                             (std.northing | uniqueID) + 
                                             soil_parent_material_name + (1 | uniqueID))
# AIC
table.aic [24, 1] <- "DU6"
table.aic [24, 2] <- "Early Winter"
table.aic [24, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [24, 4] <- "East, North, Dist. to Watercourse"
table.aic [24, 5] <- "(Dist. to Watercourse | UniqueID)"
table.aic [24, 6] <-  AIC (model.lme4.du6.ew.aspect.soil2) 

## SLOPE AND DISTANCE TO LAKE ##
model.lme4.du6.ew.slope.lake1 <- update (model.lme4.du6.ew.slope,
                                         . ~ . + std.distance_to_lake) 
# AIC
table.aic [25, 1] <- "DU6"
table.aic [25, 2] <- "Early Winter"
table.aic [25, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [25, 4] <- "Slope, Dist. to Lake"
table.aic [25, 5] <- "(Slope | UniqueID)"
table.aic [25, 6] <-  AIC (model.lme4.du6.ew.slope.lake1) 

model.lme4.du6.ew.slope.lake2 <- update (model.lme4.du6.ew.slope,
                                         . ~ . - (std.slope | uniqueID) + 
                                           std.distance_to_lake + (std.distance_to_lake | uniqueID)) 
# AIC
table.aic [26, 1] <- "DU6"
table.aic [26, 2] <- "Early Winter"
table.aic [26, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [26, 4] <- "Slope, Dist. to Lake"
table.aic [26, 5] <- "(Dist. to Lake | UniqueID)"
table.aic [26, 6] <-  AIC (model.lme4.du6.ew.slope.lake2) 

## SLOPE AND DISTANCE TO WATERCOURSE ##
model.lme4.du6.ew.slope.water1 <- update (model.lme4.du6.ew.slope,
                                         . ~ . + std.distance_to_watercourse) 
# AIC
table.aic [27, 1] <- "DU6"
table.aic [27, 2] <- "Early Winter"
table.aic [27, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [27, 4] <- "Slope, Dist. to Watercourse"
table.aic [27, 5] <- "(Slope | UniqueID)"
table.aic [27, 6] <-  AIC (model.lme4.du6.ew.slope.water1) 

model.lme4.du6.ew.slope.water2 <- update (model.lme4.du6.ew.slope,
                                          . ~ . - (std.slope | uniqueID) + 
                                            std.distance_to_watercourse +
                                            (std.distance_to_watercourse | uniqueID)) 
# AIC
table.aic [28, 1] <- "DU6"
table.aic [28, 2] <- "Early Winter"
table.aic [28, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [28, 4] <- "Slope, Dist. to Watercourse"
table.aic [28, 5] <- "(Dist. to Watercourse | UniqueID)"
table.aic [28, 6] <-  AIC (model.lme4.du6.ew.slope.water2) 

## SLOPE AND SOIL ##
model.lme4.du6.ew.slope.soil <- update (model.lme4.du6.ew.slope,
                                          . ~ . + soil_parent_material_name) 
# AIC
table.aic [29, 1] <- "DU6"
table.aic [29, 2] <- "Early Winter"
table.aic [29, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [29, 4] <- "Slope, Soil"
table.aic [29, 5] <- "(Slope | UniqueID)"
table.aic [29, 6] <-  "NA"

model.lme4.du6.ew.slope.soil2 <- update (model.lme4.du6.ew.slope,
                                        . ~ . - (std.slope | uniqueID) +
                                              soil_parent_material_name + 
                                              (1 | uniqueID)) 
# AIC
table.aic [30, 1] <- "DU6"
table.aic [30, 2] <- "Early Winter"
table.aic [30, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [30, 4] <- "Slope, Soil"
table.aic [30, 5] <- "(1 | UniqueID)"
table.aic [30, 6] <-  AIC (model.lme4.du6.ew.slope.soil2) 

## DISTANCE TO LAKE AND WATERCOURSE ##
model.lme4.du6.ew.lake.water <- update (model.lme4.du6.ew.lake,
                                        . ~ . + std.distance_to_watercourse)
# AIC
table.aic [31, 1] <- "DU6"
table.aic [31, 2] <- "Early Winter"
table.aic [31, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [31, 4] <- "Dist. to Lake, Dist. to Watercourse"
table.aic [31, 5] <- "(Dist. to Lake | UniqueID)"
table.aic [31, 6] <-  AIC (model.lme4.du6.ew.lake.water)

model.lme4.du6.ew.lake.water2 <- update (model.lme4.du6.ew.lake,
                                         . ~ . - (std.distance_to_lake | uniqueID) +
                                           std.distance_to_watercourse + 
                                           (std.distance_to_watercourse | uniqueID)) 
# AIC
table.aic [32, 1] <- "DU6"
table.aic [32, 2] <- "Early Winter"
table.aic [32, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [32, 4] <- "Dist. to Lake, Dist. to Watercourse"
table.aic [32, 5] <- "(Dist. to Watercourse | UniqueID)"
table.aic [32, 6] <-  AIC (model.lme4.du6.ew.lake.water2)


## DISTANCE TO LAKE AND SOIL ##
model.lme4.du6.ew.lake.soil <- update (model.lme4.du6.ew.lake,
                                        . ~ . + soil_parent_material_name)
# AIC
table.aic [33, 1] <- "DU6"
table.aic [33, 2] <- "Early Winter"
table.aic [33, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [33, 4] <- "Dist. to Lake, Soil"
table.aic [33, 5] <- "(Dist. to Lake | UniqueID)"
table.aic [33, 6] <- "NA"

model.lme4.du6.ew.lake.soil2 <- update (model.lme4.du6.ew.lake,
                                       . ~ . - (std.distance_to_lake | uniqueID) + 
                                         soil_parent_material_name +
                                         (1 | uniqueID))
# AIC
table.aic [34, 1] <- "DU6"
table.aic [34, 2] <- "Early Winter"
table.aic [34, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [34, 4] <- "Dist. to Lake, Soil"
table.aic [34, 5] <- "(1 | UniqueID)"
table.aic [34, 6] <- "NA"

## DISTANCE TO WATERCOURSE AND SOIL ##
model.lme4.du6.ew.water.soil <- update (model.lme4.du6.ew.wc,
                                         . ~ . + soil_parent_material_name)
# AIC
table.aic [35, 1] <- "DU6"
table.aic [35, 2] <- "Early Winter"
table.aic [35, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [35, 4] <- "Dist. to Watercourse, Soil"
table.aic [35, 5] <- "(Dist. to Watercourse | UniqueID)"
table.aic [35, 6] <-  AIC (model.lme4.du6.ew.water.soil)

## ELEVATION, ASPECT AND SLOPE ##
model.lme4.du6.ew.elev.asp.slope1 <- update (model.lme4.du6.ew.elev.asp2, 
                                       . ~ . + std.slope)
# AIC
table.aic [36, 1] <- "DU6"
table.aic [36, 2] <- "Early Winter"
table.aic [36, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [36, 4] <- "Elev, East, North, Slope"
table.aic [36, 5] <- "(Elev | UniqueID)"
table.aic [36, 6] <- AIC (model.lme4.du6.ew.elev.asp.slope1)

model.lme4.du6.ew.elev.asp.slope2 <- update (model.lme4.du6.ew.elev.asp2, 
                                             . ~ . - (std.elevation | uniqueID) + 
                                            std.slope + (std.slope | uniqueID))
# AIC
table.aic [37, 1] <- "DU6"
table.aic [37, 2] <- "Early Winter"
table.aic [37, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [37, 4] <- "Elev, East, North, Slope"
table.aic [37, 5] <- "(Slope | UniqueID)"
table.aic [37, 6] <- AIC (model.lme4.du6.ew.elev.asp.slope2)

## ELEVATION, ASPECT AND DISTANCE TO LAKE ##
model.lme4.du6.ew.elev.asp.lake1 <- update (model.lme4.du6.ew.elev.asp2, 
                                             . ~ . + std.distance_to_lake)
# AIC
table.aic [38, 1] <- "DU6"
table.aic [38, 2] <- "Early Winter"
table.aic [38, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [38, 4] <- "Elev, East, North, Dist. to Lake"
table.aic [38, 5] <- "(Elev | UniqueID)"
table.aic [38, 6] <- AIC (model.lme4.du6.ew.elev.asp.lake1)

model.lme4.du6.ew.elev.asp.lake2 <- update (model.lme4.du6.ew.elev.asp2, 
                                            . ~ . - (std.elevation | uniqueID) + 
                                              std.distance_to_lake + (std.distance_to_lake | uniqueID))
# AIC
table.aic [39, 1] <- "DU6"
table.aic [39, 2] <- "Early Winter"
table.aic [39, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [39, 4] <- "Elev, East, North, Dist. to Lake"
table.aic [39, 5] <- "(Dist. to Lake | UniqueID)"
table.aic [39, 6] <- AIC (model.lme4.du6.ew.elev.asp.lake2)

## ELEVATION, ASPECT AND DISTANCE TO WATERCOURSE ##
model.lme4.du6.ew.elev.asp.water1 <- update (model.lme4.du6.ew.elev.asp2, 
                                             . ~ . + std.distance_to_watercourse)
# AIC
table.aic [40, 1] <- "DU6"
table.aic [40, 2] <- "Early Winter"
table.aic [40, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [40, 4] <- "Elev, East, North, Dist. to Watercourse"
table.aic [40, 5] <- "(Elev | UniqueID)"
table.aic [40, 6] <- AIC (model.lme4.du6.ew.elev.asp.water1)

model.lme4.du6.ew.elev.asp.water2 <- update (model.lme4.du6.ew.elev.asp2, 
                                             . ~ . - (std.elevation | uniqueID) + 
                                               std.distance_to_watercourse +
                                               (std.distance_to_watercourse | uniqueID))
# AIC
table.aic [41, 1] <- "DU6"
table.aic [41, 2] <- "Early Winter"
table.aic [41, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [41, 4] <- "Elev, East, North, Dist. to Watercourse"
table.aic [41, 5] <- "(Dist. to Watercourse | UniqueID)"
table.aic [41, 6] <- AIC (model.lme4.du6.ew.elev.asp.water2)

## ELEVATION, ASPECT AND SOIL ##
model.lme4.du6.ew.elev.asp.soil <- update (model.lme4.du6.ew.elev.asp2, 
                                             . ~ . + soil_parent_material_name)
# AIC
table.aic [42, 1] <- "DU6"
table.aic [42, 2] <- "Early Winter"
table.aic [42, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [42, 4] <- "Elev, East, North, Soil"
table.aic [42, 5] <- "(Elev | UniqueID)"
table.aic [42, 6] <- AIC (model.lme4.du6.ew.elev.asp.soil)






## ELEVATION, SLOPE AND DISTANCE TO LAKE ##




write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_terrain_water.csv", sep = ",")






AICtab ()