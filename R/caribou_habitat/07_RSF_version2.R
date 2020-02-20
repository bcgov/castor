# Copyright 2020 Province of British Columbia
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


#################
### PACKAGES ###
###############
library (dplyr)
library (ggcorrplot)
library (ggplot2)
library (lme4)
library (plot3D)
library (raster)
library (rgdal)


#--------------------------------------------------------------------------- 

#####################
### Boreal (DU6) ###
###################

#---------------------------------------------------------------------------

##########################
### CREATING THE DATA ###
#########################

## Pull in the previously processed GIS data
rsf.data.combo.du6.ew <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du6_ew.csv", sep = ",")
rsf.data.combo.du6.lw <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du6_lw.csv", sep = ",")
rsf.data.combo.du6.s <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_combo_du6_s.csv", sep = ",")

# select the covars
rsf.data.du6.ew <- rsf.data.combo.du6.ew %>%
                        select (pttype, uniqueID, du, season, animal_id, year, ECOTYPE, HERD_NAME, ptID,
                                distance_to_resource_road, wetland_demars, distance_to_cut_1to4yo,
                                distance_to_cut_5to9yo, distance_to_cut_10yoorOver)
rsf.data.du6.lw <- rsf.data.combo.du6.lw %>%
                        select (pttype, uniqueID, du, season, animal_id, year, ECOTYPE, HERD_NAME, ptID,
                                distance_to_resource_road, wetland_demars, distance_to_cut_1to4yo,
                                distance_to_cut_5to9yo, distance_to_cut_10yoorOver)
rsf.data.du6.s <- rsf.data.combo.du6.s %>%
                        select (pttype, uniqueID, du, season, animal_id, year, ECOTYPE, HERD_NAME, ptID,
                                distance_to_resource_road, wetland_demars, distance_to_cut_1to4yo,
                                distance_to_cut_5to9yo, distance_to_cut_10yoorOver)

# bind the data together
rsf.data.du6 <- rbind (rsf.data.du6.ew, rsf.data.du6.lw, rsf.data.du6.s)

# save it for later
write.csv (rsf.data.du6, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du6.csv")

#####################
### EXPLORE DATA ###
###################

### Check the data first ###
## set ref category for wetlands and set pttype as factor##
rsf.data.du6$wetland_demars <- relevel (rsf.data.du6$wetland_demars,
                                        ref = "Upland Conifer") # upland conifer as referencce, as per Demars 2018
rsf.data.du6$pttype <- as.factor (rsf.data.du6$pttype)

### OUTLIERS ###
ggplot (rsf.data.du6, aes (x = pttype, y = distance_to_resource_road)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Distance to Resource Roads at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Resource Road")
ggplot (rsf.data.du6, aes (x = pttype, y = distance_to_cut_1to4yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Distance to Cutblock 1 to 4 Years Old at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock 1 to 4 Years Old")
ggplot (rsf.data.du6, aes (x = pttype, y = distance_to_cut_5to9yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Distance to Cutblock 5 to 9 Years Old at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock 5 to 9 Years Old")
ggplot (rsf.data.du6, aes (x = pttype, y = distance_to_cut_10yoorOver)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU6, Distance to Cutblock Greater than 9 Years Old at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock Greater than 9 Years Old")

### HISTOGRAMS ###
ggplot (rsf.data.du6, aes (x = distance_to_resource_road, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 5) +
  labs (title = "Histogram DU6, Distance to Resource Roads at Available (0) and Used (1) Locations",
        x = "Distance to Resource Road",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggplot (rsf.data.du6, aes (x = distance_to_cut_1to4yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 5) +
  labs (title = "Histogram DU6, Distance to  Cutblock 1 to 4 Years Old at Available (0) and Used (1) Locations",
        x = "Distance to  Cutblock 1 to 4 Years Old",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggplot (rsf.data.du6, aes (x = distance_to_cut_5to9yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 5) +
  labs (title = "Histogram DU6, Distance to  Cutblock 5 to 9 Years Old at Available (0) and Used (1) Locations",
        x = "Distance to  Cutblock 5 to 9 Years Old",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggplot (rsf.data.du6, aes (x = distance_to_cut_10yoorOver, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 5) +
  labs (title = "Histogram DU6, Distance to  Cutblock Greater than 9 Years Old at Available (0) and Used (1) Locations",
        x = "Distance to  Cutblock Greater than 9 Years Old",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")

ggplot (rsf.data.du6, aes (wetland_demars)) + 
  geom_bar ()

### CORRELATION ###
corr.rsf.data.du6 <- rsf.data.du6 [c (10, 12:14)]
corr.rsf.data.du6 <- round (cor (corr.rsf.data.du6, method = "spearman"), 3)
ggcorrplot (corr.rsf.data.du6, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Resource Selection Function Model Covariate Correlations for DU6")

### VIF ###
glm.du6 <- glm (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + distance_to_cut_10yoorOver +
                          distance_to_resource_road + wetland_demars, 
                data = rsf.data.du6,
                family = binomial (link = 'logit'))
car::vif (glm.du6)

#########################
### TRANSFORM COVARS ###
#######################

# Transform distance to covars as exponentinal function, follwoing Demars (2018)[http://www.bcogris.ca/sites/default/files/bcip-2019-01-final-report-demars-ver-2.pdf]
# decay.distance = exp (-0.002 8 distance to road)
# 0.002 = distances > 1500-m essentially have a similar and limited effect
rsf.data.du6$exp_dist_res_road <- exp ((rsf.data.du6$distance_to_resource_road * -0.002))
rsf.data.du6$exp_dist_cut_1to4 <- exp ((rsf.data.du6$distance_to_cut_1to4yo * -0.002))
rsf.data.du6$exp_dist_cut_5to9 <- exp ((rsf.data.du6$distance_to_cut_5to9yo * -0.002))
rsf.data.du6$exp_dist_cut_10 <- exp ((rsf.data.du6$distance_to_cut_10yoorOver * -0.002))

### Standardize the data (helps with model convergence) ###
rsf.data.du6$std_exp_dist_res_road <- (rsf.data.du6$exp_dist_res_road - 
                                                 mean (rsf.data.du6$exp_dist_res_road)) / 
                                                 sd (rsf.data.du6$exp_dist_res_road)
rsf.data.du6$std_exp_dist_cut_1to4 <- (rsf.data.du6$exp_dist_cut_1to4 - 
                                       mean (rsf.data.du6$exp_dist_cut_1to4)) / 
                                       sd (rsf.data.du6$exp_dist_cut_1to4)
rsf.data.du6$std_exp_dist_cut_5to9 <- (rsf.data.du6$exp_dist_cut_5to9 - 
                                       mean (rsf.data.du6$exp_dist_cut_5to9)) / 
                                       sd (rsf.data.du6$exp_dist_cut_5to9)
rsf.data.du6$std_exp_dist_cut_10 <- (rsf.data.du6$exp_dist_cut_10 - 
                                                 mean (rsf.data.du6$exp_dist_cut_10)) / 
                                                 sd (rsf.data.du6$exp_dist_cut_10)

### Functional Response Covariates ###
#### Calc mean available distance to road and cutblock in home range, by unique individual
avail.rsf.data.du6 <- subset (rsf.data.du6, pttype == 0)

std_exp_dist_res_road_E <- tapply (avail.rsf.data.du6$std_exp_dist_res_road, avail.rsf.data.du6$animal_id, mean)
std_exp_dist_cut_1to4_E <- tapply (avail.rsf.data.du6$std_exp_dist_cut_1to4, avail.rsf.data.du6$animal_id, mean)
std_exp_dist_cut_5to9_E <- tapply (avail.rsf.data.du6$std_exp_dist_cut_5to9, avail.rsf.data.du6$animal_id, mean)
std_exp_dist_cut_10_E <- tapply (avail.rsf.data.du6$std_exp_dist_cut_10, avail.rsf.data.du6$animal_id, mean)

inds <- as.character (rsf.data.du6$animal_id)
rsf.data.du6 <- cbind (rsf.data.du6, "dist_rd_E" = std_exp_dist_res_road_E[inds], 
                       "dist_cut_1to4_E" = std_exp_dist_cut_1to4_E[inds],
                       "dist_cut_5to9_E" = std_exp_dist_cut_5to9_E[inds],
                       "dist_cut_10_E" = std_exp_dist_cut_10_E[inds])

# to simplify available cutblock effect; interact with distance to any cutblock age
rsf.data.du6$dist_cut_min_all <- pmin (rsf.data.du6$distance_to_cut_1to4,
                                       rsf.data.du6$distance_to_cut_5to9yo,
                                       rsf.data.du6$distance_to_cut_10yoorOver)
rsf.data.du6$exp_dist_cut_min <- exp ((rsf.data.du6$dist_cut_min_all * -0.002))
rsf.data.du6$std_exp_dist_cut_min <- (rsf.data.du6$exp_dist_cut_min - 
                                      mean (rsf.data.du6$exp_dist_cut_min)) / 
                                      sd (rsf.data.du6$exp_dist_cut_min)

std_exp_dist_cut_min_E <- tapply (avail.rsf.data.du6$std_exp_dist_cut_min, avail.rsf.data.du6$animal_id, mean)
rsf.data.du6 <- cbind (rsf.data.du6, "dist_cut_min_E" = std_exp_dist_cut_min_E[inds])

###################
### FIT MODELS ###
#################

### Generalized Linear Mixed Models (GLMMs) ###
#### First, determine the random effects structure

# Individual animal
model.lme4.du6.animal <- glmer (pttype ~ 1 + (1 | animal_id), # random effect for animal
                                 data = rsf.data.du6, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 

#### Season
model.lme4.du6.season <- glmer (pttype ~ 1 + (1 | season), # random effect for season
                                 data = rsf.data.du6, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 

#### Individual animal and Season
model.lme4.du6.anim.seas <- glmer (pttype ~ 1 + (1 | animal_id) + (1 | season), # random effect intercepts for indivudal and season
                                    data = rsf.data.du6, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 

# Compare models 
anova (model.lme4.du6.animal, model.lme4.du6.season, model.lme4.du6.anim.seas)

# animal and season model had best fit; use both




#### Second, determine the fixed effects structure
### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 5, nrow = 0))
colnames (table.aic) <- c ("DU", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

#### Wetland only model
model.lme4.du6.wetland <- glmer (pttype ~ wetland_demars + (1 | animal_id) + (1 | season), 
                                  data = rsf.data.du6, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
ss <- getME (model.lme4.du6.wetland, c ("theta","fixef")) # needed to be rerun 3x, but converged
model.lme4.du6.wetland <- update (model.lme4.du6.wetland, start = ss, control = glmerControl (optCtrl = list (maxfun=2e4)))
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Wetland"
table.aic [1, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [1, 4] <-  AIC (model.lme4.du6.wetland)

# Dist Road model
model.lme4.du6.road <- glmer (pttype ~ std_exp_dist_res_road + (1 | animal_id) + (1 | season),
                                 data = rsf.data.du6, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Distance to Resource Road"
table.aic [2, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [2, 4] <-  AIC (model.lme4.du6.road)

# Dist Cut model
model.lme4.du6.cut <- glmer (pttype ~ std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + std_exp_dist_cut_10 + (1 | animal_id) + (1 | season),
                             data = rsf.data.du6, 
                             family = binomial (link = "logit"),
                             verbose = T) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Distance to Cutblock"
table.aic [3, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [3, 4] <-  AIC (model.lme4.du6.cut)

# Dist Road and Cut model
model.lme4.du6.rd.cut <- glmer (pttype ~ std_exp_dist_res_road + std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + std_exp_dist_cut_10 + (1 | animal_id) + (1 | season),
                                 data = rsf.data.du6, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [4, 1] <- "DU6"
table.aic [4, 2] <- "Distance to Resource Road + Distance to Cutblock"
table.aic [4, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [4, 4] <-  AIC (model.lme4.du6.rd.cut)

# Dist Road Fxn Response
model.lme4.du6.rd.fxn <- glmer (pttype ~ std_exp_dist_res_road + dist_rd_E + std_exp_dist_res_road*dist_rd_E + (1 | animal_id) + (1 | season),
                                data = rsf.data.du6, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [5, 1] <- "DU6"
table.aic [5, 2] <- "Distance to Resource Road + Available Distance to Resource Road + Distance to Resource Road*Available Distance to Resource Road"
table.aic [5, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [5, 4] <-  AIC (model.lme4.du6.rd.fxn)

scatter3D (rsf.data.du6$distance_to_resource_road, # stronger avoidance of roads in areas with more roads; higher slection at disatcne further form roads in high rod available areas
           rsf.data.du6$dist_rd_E,
           (predict (model.lme4.du6.rd.fxn,
            newdata = rsf.data.du6, 
            re.form = NA, type = "response")), 
           xlab = "Dist. Road",
           ylab = "Avail. Dist Road", 
           zlab = "Selection",
           theta = 15, phi = 20)

# Dist Cut Fxn Response
model.lme4.du6.cut.fxn <- glmer (pttype ~ std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + std_exp_dist_cut_10 + dist_cut_min_E + std_exp_dist_cut_1to4*dist_cut_min_E + std_exp_dist_cut_5to9*dist_cut_min_E + std_exp_dist_cut_10*dist_cut_min_E + (1 | animal_id) + (1 | season),
                                data = rsf.data.du6, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [6, 1] <- "DU6"
table.aic [6, 2] <- "Distance to Cutblock + Available Distance to Cutblock + Distance to Cutblock*Available Distance to Cutblock"
table.aic [6, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [6, 4] <-  AIC (model.lme4.du6.cut.fxn)

scatter3D (rsf.data.du6$distance_to_cut_1to4yo, # no real evidence of fucntional response in response figure here
           rsf.data.du6$dist_rd_E,
           (predict (model.lme4.du6.cut.fxn,
                     newdata = rsf.data.du6, 
                     re.form = NA, type = "response")), 
           xlab = "Dist. Cut 1to4",
           ylab = "Avail. Dist Cut", 
           zlab = "Selection")

# Wetland, Dist Road and Cut model
model.lme4.du6.all <- glmer (pttype ~ wetland_demars + std_exp_dist_res_road + std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + std_exp_dist_cut_10 + (1 | animal_id) + (1 | season),
                                data = rsf.data.du6, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [7, 1] <- "DU6"
table.aic [7, 2] <- "Wetland + Distance to Resource Road + Distance to Cutblock"
table.aic [7, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [7, 4] <-  AIC (model.lme4.du6.all)

# Wetland, Dist Road (fxn) and Cut model
model.lme4.du6.all.fxn <- glmer (pttype ~ wetland_demars + std_exp_dist_res_road + std_exp_dist_cut_10 + dist_rd_E + std_exp_dist_res_road*dist_rd_E + (1 | animal_id) + (1 | season),
                             data = rsf.data.du6, 
                             family = binomial (link = "logit"),
                             verbose = T) 
# AIC
table.aic [8, 1] <- "DU6"
table.aic [8, 2] <- "Wetland + Distance to Resource Road + Distance to Cutblock + Available Distance to Resource Road + Distance to Resource Road*Available Distance to Resource Road"
table.aic [8, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [8, 4] <-  AIC (model.lme4.du6.all.fxn)

scatter3D (x = rsf.data.du6$distance_to_resource_road, 
           y = rsf.data.du6$exp_dist_res_road, 
           z = (predict (model.lme4.du6.all.fxn,
                         newdata = rsf.data.du6, 
                         re.form = NA, type = "response")),
           xlab = "Dist. Road",
           ylab = "Avail. Dist Road", 
           zlab = "Selection",
           theta = 15, phi = 20)

## AIC comparison of MODELS ## 
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 4] - min (table.aic [1:8, 4])))), 
                    (exp (-0.5 * (table.aic [2, 4] - min (table.aic [1:8, 4])))),
                    (exp (-0.5 * (table.aic [3, 4] - min (table.aic [1:8, 4])))),
                    (exp (-0.5 * (table.aic [4, 4] - min (table.aic [1:8, 4])))),
                    (exp (-0.5 * (table.aic [5, 4] - min (table.aic [1:8, 4])))),
                    (exp (-0.5 * (table.aic [6, 4] - min (table.aic [1:8, 4])))),
                    (exp (-0.5 * (table.aic [7, 4] - min (table.aic [1:8, 4])))),
                    (exp (-0.5 * (table.aic [8, 4] - min (table.aic [1:8, 4])))))
table.aic [1, 5] <- round ((exp (-0.5 * (table.aic [1, 4] - min (table.aic [1:8, 4])))) / sum (list.aic.like), 3)
table.aic [2, 5] <- round ((exp (-0.5 * (table.aic [2, 4] - min (table.aic [1:8, 4])))) / sum (list.aic.like), 3)
table.aic [3, 5] <- round ((exp (-0.5 * (table.aic [3, 4] - min (table.aic [1:8, 4])))) / sum (list.aic.like), 3)
table.aic [4, 5] <- round ((exp (-0.5 * (table.aic [4, 4] - min (table.aic [1:8, 4])))) / sum (list.aic.like), 3)
table.aic [5, 5] <- round ((exp (-0.5 * (table.aic [5, 4] - min (table.aic [1:8, 4])))) / sum (list.aic.like), 3)
table.aic [6, 5] <- round ((exp (-0.5 * (table.aic [6, 4] - min (table.aic [1:8, 4])))) / sum (list.aic.like), 3)
table.aic [7, 5] <- round ((exp (-0.5 * (table.aic [7, 4] - min (table.aic [1:8, 4])))) / sum (list.aic.like), 3)
table.aic [8, 5] <- round ((exp (-0.5 * (table.aic [8, 4] - min (table.aic [1:8, 4])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_du6_v2.csv", sep = ",")

# used model without functional response because didn't appear to improve interpretation of model, i.e.,
# the distance to road covariate didn't change much over variability in available distance to road

# save the top model
save (model.lme4.du6.all, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_du6_top_v2.rda")

###################
### SAVE MODEL ###
#################

# Create table of model coefficients from top model
model.coeffs <- as.data.frame (coef (summary (model.lme4.du6.all)))
model.coeffs$mean_exp_neg0002 <- 0
model.coeffs$sd_exp_neg0002 <- 0

model.coeffs [9, 5] <- mean (exp ((rsf.data.du6$distance_to_resource_road * -0.002)))
model.coeffs [10, 5] <- mean (exp ((rsf.data.du6$distance_to_cut_1to4yo * -0.002)))
model.coeffs [11, 5] <- mean (exp ((rsf.data.du6$distance_to_cut_5to9yo * -0.002)))
model.coeffs [12, 5] <- mean (exp ((rsf.data.du6$distance_to_cut_10yoorOver * -0.002)))

model.coeffs [9, 6] <- sd (exp ((rsf.data.du6$distance_to_resource_road * -0.002)))
model.coeffs [10, 6] <- sd (exp ((rsf.data.du6$distance_to_cut_1to4yo * -0.002)))
model.coeffs [11, 6] <- sd (exp ((rsf.data.du6$distance_to_cut_5to9yo * -0.002)))
model.coeffs [12, 6] <- sd (exp ((rsf.data.du6$distance_to_cut_10yoorOver * -0.002)))

write.table (model.coeffs, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\model_coefficients\\table_du6_summ_model_coeffs_top.csv", sep = ",")


###############################
### RSF RASTER CALCULATION ###
#############################

### LOAD RASTERS ###
wet.conifer.swamp <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\du6\\summer\\conifer_swamp.tif")
wet.decid.swamp <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\du6\\summer\\deciduous_swamp.tif")
wet.poor.fen <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\du6\\summer\\poor_fen.tif")
wet.rich.fen <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\du6\\summer\\rich_fen.")
wet.other <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\du6\\summer\\wet_other.tif")
wet.tree.bog <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\du6\\summer\\treed_bog.tif")
wet.upland.decid <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\du6\\summer\\upland_deciduous.tif")
dist.cut.1to4 <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_1to4yo.tif")
dist.cut.5to9 <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_5to9yo.tif")
dist.cut.10over <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_10yo_over.tif")
dist.resource.rd <- raster ("C:\\Work\\caribou\\clus_data\\roads_ha_bc\\dist_crds_resource.tif")


### Mask to Study Area
# caribou.boreal.sa <- readOGR ("C:\\Work\\caribou\\climate_analysis\\data\\studyarea\\caribou_boreal_study_area.shp", stringsAsFactors = T) # herds with 25km buffer
# 
# dist.cut.1to4 <- mask (dist.cut.1to4, caribou.boreal.sa)
# dist.cut.5to9 <- mask (dist.cut.5to9, caribou.boreal.sa)
# dist.cut.10over <- mask (dist.cut.10over, caribou.boreal.sa)
# dist.resource.rd <- mask (dist.resource.rd, caribou.boreal.sa)
# wet.conifer.swamp <- mask (wet.conifer.swamp, caribou.boreal.sa)
# wet.decid.swamp <- mask (wet.decid.swamp, caribou.boreal.sa)
# wet.poor.fen <- mask (wet.poor.fen, caribou.boreal.sa)
# wet.rich.fen <- mask (wet.rich.fen, caribou.boreal.sa)
# wet.other <- mask (wet.other, caribou.boreal.sa)
# wet.tree.bog <- mask (wet.tree.bog, caribou.boreal.sa)
# wet.upland.decid <- mask (wet.upland.decid, caribou.boreal.sa)

### Need to resample raster to make them fit together
wet.conifer.swamp <- resample (wet.conifer.swamp, dist.cut.1to4, method = 'bilinear')
wet.decid.swamp <- resample (wet.decid.swamp, dist.cut.1to4, method = 'bilinear')
wet.poor.fen <- resample (wet.poor.fen, dist.cut.1to4, method = 'bilinear')
wet.rich.fen <- resample (wet.rich.fen, dist.cut.1to4, method = 'bilinear')
wet.other <- resample (wet.other, dist.cut.1to4, method = 'bilinear')
wet.tree.bog <- resample (wet.tree.bog, dist.cut.1to4, method = 'bilinear')
wet.upland.decid <- resample (wet.upland.decid, dist.cut.1to4, method = 'bilinear')

### Adjust the raster data for 'standardized' model covariates ###
std.dist.resource.rd <- (exp (dist.resource.rd * -0.002) - 0.4363667) / 0.2952693
std.dist.cut.1to4 <- (exp (dist.cut.1to4 * -0.002) - 2.249313e-05) / 0.002068421
std.dist.cut.5to9 <- (exp (dist.cut.5to9 * -0.002) - 0.0008984509) / 0.01939174
std.dist.cut.10over <- (exp (dist.cut.10over * -0.002) - 0.01939174) / 0.0661427

### CALCULATE RASTER OF STATIC VARIABLES ###
raster.rsf <- (exp (-2.33 + (wet.conifer.swamp * 0.30) + (wet.decid.swamp * -0.04) +
                      (wet.poor.fen * 0.62) + (wet.rich.fen * 0.34) +
                      (wet.other * 0.51) + (wet.tree.bog * 0.88) + 
                      (wet.upland.decid * -1.00) + (std.dist.cut.1to4 * -0.01) + 
                      (std.dist.cut.5to9 * -0.01) + (std.dist.cut.10over * -0.03) +
                      (std.dist.resource.rd * -0.08))) / 
  (1 + exp (-2.33 + (wet.conifer.swamp * 0.30) + (wet.decid.swamp * -0.04) +
              (wet.poor.fen * 0.62) + (wet.rich.fen * 0.34) +
              (wet.other * 0.51) + (wet.tree.bog * 0.88) + 
              (wet.upland.decid * -1.00) + (std.dist.cut.1to4 * -0.01) + 
              (std.dist.cut.5to9 * -0.01) + (std.dist.cut.10over * -0.03) +
              (std.dist.resource.rd * -0.08)))

plot (raster.rsf)

writeRaster (raster.rsf, "C:\\Work\\caribou\\clus_data\\rsf\\du6\\rsf_du6_v2.tif", 
             format = "GTiff", overwrite = T)


##########################
### k-fold Validation ###
########################
df.animal.id <- as.data.frame (unique (rsf.data.du6$animal_id))
names (df.animal.id) [1] <-"animal_id"
df.animal.id$group <- rep_len (1:5, nrow (df.animal.id)) # orderly selection of groups
rsf.data.du6 <- dplyr::full_join (rsf.data.du6, df.animal.id, by = "animal_id")

### FOLD 1 ###
train.data.1 <- rsf.data.du6 %>%
  filter (group < 5)
test.data.1 <- rsf.data.du6 %>%
  filter (group == 5)

model.lme4.du6train1 <- glmer (pttype ~ wetland_demars + std_exp_dist_res_road + 
                                    std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + 
                                    std_exp_dist_cut_10 + (1 | animal_id) + (1 | season), 
                                  data = train.data.1, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 

# create a table of k-fold outputs
table.kfold <- data.frame (matrix (ncol = 12, nrow = 50))
colnames (table.kfold) <- c ("test.number", "bin.mid", "bin.weight", "utilization", "used.count", 
                             "expected.count", "lm.slope", "lm.slope.p.value", "lm.intercept",
                             "lm.intercept.p.value", "adj.R.sq", "chi.sq.p.value")
table.kfold [c (1:10), 1] <- 1
table.kfold$bin.mid <- c (0.011, 0.033, 0.055, 0.077, 0.099, 0.121, 0.143, 0.165, 0.187, 0.209)

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du6$preds.train1 <- predict (model.lme4.du6train1, 
                                      newdata = rsf.data.du6, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du6, aes (preds.train1)) +
  geom_histogram()
max (rsf.data.du6$preds.train1)
min (rsf.data.du6$preds.train1)

rsf.data.du6$preds.train1.class <- cut (rsf.data.du6$preds.train1, # put into classes; 0 to 0.22, based on max and min values
                                                breaks = c (-Inf, 0.022, 0.044, 0.066, 0.088, 0.110, 0.132, 0.154, 0.176, 0.198, Inf), 
                                                labels = c ("0.011", "0.033", "0.055", "0.077", "0.099",
                                                            "0.121", "0.143", "0.165", "0.187", "0.209"))
rsf.data.du6.avail <- dplyr::filter (rsf.data.du6, pttype == 0)

table.kfold [1, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train1.class == "0.011")) * 0.011) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [2, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train1.class == "0.033")) * 0.033)
table.kfold [3, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train1.class == "0.055")) * 0.055)
table.kfold [4, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train1.class == "0.077")) * 0.077)
table.kfold [5, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train1.class == "0.099")) * 0.099)
table.kfold [6, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train1.class == "0.121")) * 0.121)
table.kfold [7, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train1.class == "0.143")) * 0.143)
table.kfold [8, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train1.class == "0.165")) * 0.165)
table.kfold [9, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train1.class == "0.187")) * 0.187)
table.kfold [10, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train1.class == "0.209")) * 0.209)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\table_kfold_valid_du6.csv")

# data for estimating use
test.data.1$preds <- predict (model.lme4.du6train1, newdata = test.data.1, re.form = NA, type = "response")
test.data.1$preds.class <- cut (test.data.1$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.022, 0.044, 0.066, 0.088, 0.110, 0.132, 0.154, 0.176, 0.198, Inf), 
                                labels = c ("0.011", "0.033", "0.055", "0.077", "0.099",
                                            "0.121", "0.143", "0.165", "0.187", "0.209"))
write.csv (test.data.1, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\rsf_preds_du6_train1.csv")
test.data.1.used <- dplyr::filter (test.data.1, pttype == 1)

table.kfold [1, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.011"))
table.kfold [2, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.033"))
table.kfold [3, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.055"))
table.kfold [4, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.077"))
table.kfold [5, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.099"))
table.kfold [6, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.121"))
table.kfold [7, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.143"))
table.kfold [8, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.165"))
table.kfold [9, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.187"))
table.kfold [10, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.209"))

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

table.kfold [1, 7] <- 1.0301
table.kfold [1, 8] <- "<0.001"
table.kfold [1, 9] <- -131.5415
table.kfold [1, 10] <- 0.745
table.kfold [1, 11] <- 0.963

chisq.test(dplyr::filter(table.kfold, test.number == 1)$used.count, dplyr::filter(table.kfold, test.number == 1)$expected.count)
table.kfold [1, 12] <-  0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\table_kfold_valid_du6.csv")


ggplot (dplyr::filter(table.kfold, test.number == 1), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 1 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 15000, by = 1000)) + 
  scale_y_continuous (breaks = seq (0, 15000, by = 1000))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du6_grp1.png")

write.csv (rsf.data.du6, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du6_preds.csv")

### FOLD 2 ###
train.data.2 <- rsf.data.du6 %>%
  filter (group == 1 | group == 2 | group == 3 | group == 5)
test.data.2 <- rsf.data.du6 %>%
  filter (group == 4)

model.lme4.du6train2 <- glmer (pttype ~ wetland_demars + std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + 
                                 std_exp_dist_cut_10 + (1 | animal_id) + (1 | season), 
                               data = train.data.2, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du6$preds.train2 <- predict (model.lme4.du6train2, 
                                      newdata = rsf.data.du6, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du6, aes (preds.train2)) +
  geom_histogram()
max (rsf.data.du6$preds.train2)
min (rsf.data.du6$preds.train2)

rsf.data.du6$preds.train2.class <- cut (rsf.data.du6$preds.train2, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.022, 0.044, 0.066, 0.088, 0.110, 0.132, 0.154, 0.176, 0.198, Inf), 
                                        labels = c ("0.011", "0.033", "0.055", "0.077", "0.099",
                                                    "0.121", "0.143", "0.165", "0.187", "0.209"))
table.kfold [c (11:20), 1] <- 2

rsf.data.du6.avail <- dplyr::filter (rsf.data.du6, pttype == 0)

table.kfold [11, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.011")) * 0.011) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [12, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.033")) * 0.033)
table.kfold [13, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.055")) * 0.055)
table.kfold [14, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.077")) * 0.077)
table.kfold [15, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.099")) * 0.099)
table.kfold [16, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.121")) * 0.121)
table.kfold [17, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.143")) * 0.143)
table.kfold [18, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.165")) * 0.165)
table.kfold [19, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.187")) * 0.187)
table.kfold [20, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.209")) * 0.209)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\table_kfold_valid_du6.csv")

# data for estimating use
test.data.2$preds <- predict (model.lme4.du6train2, newdata = test.data.2, re.form = NA, type = "response")
test.data.2$preds.class <- cut (test.data.2$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.022, 0.044, 0.066, 0.088, 0.110, 0.132, 0.154, 0.176, 0.198, Inf), 
                                labels = c ("0.011", "0.033", "0.055", "0.077", "0.099",
                                            "0.121", "0.143", "0.165", "0.187", "0.209"))
write.csv (test.data.2, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\rsf_preds_du6_train2.csv")
test.data.2.used <- dplyr::filter (test.data.2, pttype == 1)

table.kfold [11, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.011"))
table.kfold [12, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.033"))
table.kfold [13, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.055"))
table.kfold [14, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.077"))
table.kfold [15, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.099"))
table.kfold [16, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.121"))
table.kfold [17, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.143"))
table.kfold [18, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.165"))
table.kfold [19, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.187"))
table.kfold [20, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.209"))

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
                       data = dplyr::filter(table.kfold, test.number == 2))
summary (glm.kfold.test2)

table.kfold [11, 7] <- 0.97041
table.kfold [11, 8] <- "<0.001"
table.kfold [11, 9] <- 110.89754
table.kfold [11, 10] <- 0.681
table.kfold [11, 11] <- 0.976

chisq.test(dplyr::filter(table.kfold, test.number == 2)$used.count, dplyr::filter(table.kfold, test.number == 2)$expected.count)
table.kfold [11, 12] <-  0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\table_kfold_valid_du6.csv")

ggplot (dplyr::filter(table.kfold, test.number == 2), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 2 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 15000, by = 1000)) + 
  scale_y_continuous (breaks = seq (0, 15000, by = 1000))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du6_grp2.png")

write.csv (rsf.data.du6, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du6_preds.csv")

### FOLD 3 ###
train.data.3 <- rsf.data.du6 %>%
  filter (group == 1 | group == 2 | group == 4 | group == 5)
test.data.3 <- rsf.data.du6 %>%
  filter (group == 3)

model.lme4.du6train3 <- glmer (pttype ~ wetland_demars + std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + 
                                 std_exp_dist_cut_10 + (1 | animal_id) + (1 | season), 
                               data = train.data.3, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du6$preds.train3 <- predict (model.lme4.du6train3, 
                                      newdata = rsf.data.du6, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du6, aes (preds.train3)) +
  geom_histogram()
max (rsf.data.du6$preds.train3)
min (rsf.data.du6$preds.train3)

rsf.data.du6$preds.train3.class <- cut (rsf.data.du6$preds.train3, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.022, 0.044, 0.066, 0.088, 0.110, 0.132, 0.154, 0.176, 0.198, Inf), 
                                        labels = c ("0.011", "0.033", "0.055", "0.077", "0.099",
                                                    "0.121", "0.143", "0.165", "0.187", "0.209"))
table.kfold [c (21:30), 1] <- 3

rsf.data.du6.avail <- dplyr::filter (rsf.data.du6, pttype == 0)

table.kfold [21, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train3.class == "0.011")) * 0.011) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [22, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train3.class == "0.033")) * 0.033)
table.kfold [23, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train3.class == "0.055")) * 0.055)
table.kfold [24, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train3.class == "0.077")) * 0.077)
table.kfold [25, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train3.class == "0.099")) * 0.099)
table.kfold [26, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train3.class == "0.121")) * 0.121)
table.kfold [27, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train3.class == "0.143")) * 0.143)
table.kfold [28, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train3.class == "0.165")) * 0.165)
table.kfold [29, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train3.class == "0.187")) * 0.187)
table.kfold [30, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train3.class == "0.209")) * 0.209)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\table_kfold_valid_du6.csv")

# data for estimating use
test.data.3$preds <- predict (model.lme4.du6train3, newdata = test.data.3, re.form = NA, type = "response")
test.data.3$preds.class <- cut (test.data.3$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.022, 0.044, 0.066, 0.088, 0.110, 0.132, 0.154, 0.176, 0.198, Inf), 
                                labels = c ("0.011", "0.033", "0.055", "0.077", "0.099",
                                            "0.121", "0.143", "0.165", "0.187", "0.209"))
write.csv (test.data.3, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\rsf_preds_du6_train3.csv")
test.data.3.used <- dplyr::filter (test.data.3, pttype == 1)

table.kfold [21, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.011"))
table.kfold [22, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.033"))
table.kfold [23, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.055"))
table.kfold [24, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.077"))
table.kfold [25, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.099"))
table.kfold [26, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.121"))
table.kfold [27, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.143"))
table.kfold [28, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.165"))
table.kfold [29, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.187"))
table.kfold [30, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.209"))

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
                       data = dplyr::filter(table.kfold, test.number == 3))
summary (glm.kfold.test3)

table.kfold [21, 7] <- 1.01773
table.kfold [21, 8] <- "<0.001"
table.kfold [21, 9] <- -74.12514
table.kfold [21, 10] <- 0.673
table.kfold [21, 11] <- 0.9923

chisq.test(dplyr::filter(table.kfold, test.number == 3)$used.count, dplyr::filter(table.kfold, test.number == 3)$expected.count)
table.kfold [21, 12] <-  0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\table_kfold_valid_du6.csv")

ggplot (dplyr::filter(table.kfold, test.number == 3), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 3 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 15000, by = 1000)) + 
  scale_y_continuous (breaks = seq (0, 15000, by = 1000))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du6_grp3.png")

write.csv (rsf.data.du6, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du6_preds.csv")

### FOLD 4 ###
train.data.4 <- rsf.data.du6 %>%
  filter (group == 1 | group == 3 | group == 4 | group == 5)
test.data.4 <- rsf.data.du6 %>%
  filter (group == 2)

model.lme4.du6train4 <- glmer (pttype ~ wetland_demars + std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + 
                                 std_exp_dist_cut_10 + (1 | animal_id) + (1 | season), 
                               data = train.data.4, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du6$preds.train4 <- predict (model.lme4.du6train4, 
                                      newdata = rsf.data.du6, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du6, aes (preds.train4)) +
  geom_histogram()
max (rsf.data.du6$preds.train4)
min (rsf.data.du6$preds.train4)

rsf.data.du6$preds.train4.class <- cut (rsf.data.du6$preds.train4, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.022, 0.044, 0.066, 0.088, 0.110, 0.132, 0.154, 0.176, 0.198, Inf), 
                                        labels = c ("0.011", "0.033", "0.055", "0.077", "0.099",
                                                    "0.121", "0.143", "0.165", "0.187", "0.209"))
table.kfold [c (31:40), 1] <- 4

rsf.data.du6.avail <- dplyr::filter (rsf.data.du6, pttype == 0)

table.kfold [31, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train4.class == "0.011")) * 0.011) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [32, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train4.class == "0.033")) * 0.033)
table.kfold [33, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train4.class == "0.055")) * 0.055)
table.kfold [34, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train4.class == "0.077")) * 0.077)
table.kfold [35, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train4.class == "0.099")) * 0.099)
table.kfold [36, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train4.class == "0.121")) * 0.121)
table.kfold [37, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train4.class == "0.143")) * 0.143)
table.kfold [38, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train4.class == "0.165")) * 0.165)
table.kfold [39, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train4.class == "0.187")) * 0.187)
table.kfold [40, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train4.class == "0.209")) * 0.209)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\table_kfold_valid_du6.csv")

# data for estimating use
test.data.4$preds <- predict (model.lme4.du6train4, newdata = test.data.4, re.form = NA, type = "response")
test.data.4$preds.class <- cut (test.data.4$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.022, 0.044, 0.066, 0.088, 0.110, 0.132, 0.154, 0.176, 0.198, Inf), 
                                labels = c ("0.011", "0.033", "0.055", "0.077", "0.099",
                                            "0.121", "0.143", "0.165", "0.187", "0.209"))
write.csv (test.data.4, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\rsf_preds_du6_train4.csv")
test.data.4.used <- dplyr::filter (test.data.4, pttype == 1)

table.kfold [31, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.011"))
table.kfold [32, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.033"))
table.kfold [33, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.055"))
table.kfold [34, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.077"))
table.kfold [35, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.099"))
table.kfold [36, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.121"))
table.kfold [37, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.143"))
table.kfold [38, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.165"))
table.kfold [39, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.187"))
table.kfold [40, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.209"))

table.kfold [31, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [31, 4], 0) # expected number of uses in each bin
table.kfold [32, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [32, 4], 0) # expected number of uses in each bin
table.kfold [33, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [33, 4], 0) # expected number of uses in each bin
table.kfold [34, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [34, 4], 0) # expected number of uses in each bin
table.kfold [35, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [35, 4], 0) # expected number of uses in each bin
table.kfold [36, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [36, 4], 0) # expected number of uses in each bin
table.kfold [37, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [37, 4], 0) # expected number of uses in each bin
table.kfold [38, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [38, 4], 0) # expected number of uses in each bin
table.kfold [39, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [39, 4], 0) # expected number of uses in each bin
table.kfold [40, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [40, 4], 0) # expected number of uses in each bin

glm.kfold.test4 <- lm (used.count ~ expected.count, 
                       data = dplyr::filter(table.kfold, test.number == 4))
summary (glm.kfold.test4)

table.kfold [31, 7] <- 0.97177
table.kfold [31, 8] <- "<0.001"
table.kfold [31, 9] <- 123.56581
table.kfold [31, 10] <- 0.646
table.kfold [31, 11] <- 0.9824

chisq.test(dplyr::filter(table.kfold, test.number == 4)$used.count, dplyr::filter(table.kfold, test.number == 4)$expected.count)
table.kfold [31, 12] <-  0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\table_kfold_valid_du6.csv")

ggplot (dplyr::filter(table.kfold, test.number == 4), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 4 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 15000, by = 1000)) + 
  scale_y_continuous (breaks = seq (0, 15000, by = 1000))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du6_grp4.png")

write.csv (rsf.data.du6, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du6_preds.csv")

### FOLD 5 ###
train.data.5 <- rsf.data.du6 %>%
  filter (group == 5 | group == 2 | group == 3 | group == 4)
test.data.5 <- rsf.data.du6 %>%
  filter (group == 1)

model.lme4.du6train5 <- glmer (pttype ~ wetland_demars + std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + 
                                 std_exp_dist_cut_10 + (1 | animal_id) + (1 | season), 
                               data = train.data.5, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du6$preds.train5 <- predict (model.lme4.du6train5, 
                                      newdata = rsf.data.du6, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du6, aes (preds.train5)) +
  geom_histogram()
max (rsf.data.du6$preds.train5)
min (rsf.data.du6$preds.train5)

rsf.data.du6$preds.train5.class <- cut (rsf.data.du6$preds.train5, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.022, 0.044, 0.066, 0.088, 0.110, 0.132, 0.154, 0.176, 0.198, Inf), 
                                        labels = c ("0.011", "0.033", "0.055", "0.077", "0.099",
                                                    "0.121", "0.143", "0.165", "0.187", "0.209"))
table.kfold [c (41:50), 1] <- 5

rsf.data.du6.avail <- dplyr::filter (rsf.data.du6, pttype == 0)

table.kfold [41, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train5.class == "0.011")) * 0.011) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [42, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train5.class == "0.033")) * 0.033)
table.kfold [43, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train5.class == "0.055")) * 0.055)
table.kfold [44, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train5.class == "0.077")) * 0.077)
table.kfold [45, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train5.class == "0.099")) * 0.099)
table.kfold [46, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train5.class == "0.121")) * 0.121)
table.kfold [47, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train5.class == "0.143")) * 0.143)
table.kfold [48, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train5.class == "0.165")) * 0.165)
table.kfold [49, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train5.class == "0.187")) * 0.187)
table.kfold [50, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train5.class == "0.209")) * 0.209)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\table_kfold_valid_du6.csv")

# data for estimating use
test.data.5$preds <- predict (model.lme4.du6train5, newdata = test.data.5, re.form = NA, type = "response")
test.data.5$preds.class <- cut (test.data.5$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.022, 0.044, 0.066, 0.088, 0.110, 0.132, 0.154, 0.176, 0.198, Inf), 
                                labels = c ("0.011", "0.033", "0.055", "0.077", "0.099",
                                            "0.121", "0.143", "0.165", "0.187", "0.209"))
write.csv (test.data.5, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\rsf_preds_du6_train5.csv")
test.data.5.used <- dplyr::filter (test.data.5, pttype == 1)

table.kfold [41, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.011"))
table.kfold [42, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.033"))
table.kfold [43, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.055"))
table.kfold [44, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.077"))
table.kfold [45, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.099"))
table.kfold [46, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.121"))
table.kfold [47, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.143"))
table.kfold [48, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.165"))
table.kfold [49, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.187"))
table.kfold [50, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.209"))

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
                       data = dplyr::filter(table.kfold, test.number == 5))
summary (glm.kfold.test5)

table.kfold [41, 7] <- 1.06086
table.kfold [41, 8] <- "<0.001"
table.kfold [41, 9] <- -256.31452
table.kfold [41, 10] <- 0.301
table.kfold [41, 11] <- 0.9872

chisq.test(dplyr::filter(table.kfold, test.number == 5)$used.count, dplyr::filter(table.kfold, test.number == 5)$expected.count)
table.kfold [41, 12] <-  0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\table_kfold_valid_du6.csv")

ggplot (dplyr::filter(table.kfold, test.number == 5), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 5 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 15000, by = 1000)) + 
  scale_y_continuous (breaks = seq (0, 15000, by = 1000))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du6_grp5.png")

write.csv (rsf.data.du6, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du6_preds.csv")


#--------------------------------------------------------------------------- 

################################
### Northern Mountain (DU7) ###
##############################

#---------------------------------------------------------------------------

##########################
### CREATING THE DATA ###
#########################

## Pull in the previously processed GIS data
rsf.data.forestry <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_forestry.csv", header = T, sep = "")
rsf.data.veg <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_veg.csv")
rsf.data.veg <- rsf.data.veg %>% 
  filter (!is.na (bec_label))
rsf.data.forestry <- dplyr::mutate (rsf.data.forestry, distance_to_resource_road = pmin (distance_to_loose_road, 
                                                                                         distance_to_petroleum_road,
                                                                                         distance_to_rough_road,
                                                                                         distance_to_trim_transport_road,
                                                                                         distance_to_unknown_road))
rsf.data.forestry.lean <- rsf.data.forestry [, c (1:13, 20)]
rsf.data.veg.lean <- rsf.data.veg [, c (9:10)]

rsf.data.combo <- dplyr::full_join (rsf.data.forestry.lean, 
                                    rsf.data.veg.lean,
                                    by = "ptID")

rsf.data.du7 <- rsf.data.combo %>%
  dplyr::filter (du == "du7")

rm (rsf.data.forestry, rsf.data.veg, rsf.data.forestry.lean, rsf.data.veg.lean, rsf.data.combo)
gc ()

# save it
write.csv (rsf.data.du7, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du7.csv")

#####################
### EXPLORE DATA ###
###################

rsf.data.du7$pttype <- as.factor (rsf.data.du7$pttype)

## reclassify BEC and set ref category
ggplot (rsf.data.du7, aes (x = bec_label, fill = pttype)) + 
  geom_histogram (position = "dodge", stat = "count") +
  labs (title = "Histogram DU7, Summer, BEC Type\
                          at Available (0) and Used (1) Locations",
        x = "Biogeclimatic Unit Type",
        y = "Count") +
  scale_fill_discrete (name = "Location Type") +
  theme (axis.text.x = element_text (angle = 45))

rsf.data.du7$bec_label_reclass <- rsf.data.du7$bec_label

rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                                 "'BAFAun' = 'BAFA'") 
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                                 "'BAFAunp' = 'BAFA'")
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                                "'BWBSmk' = 'BWBSm'")
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                                "'BWBSmw' = 'BWBSm'")
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                                "'BWBSwk 2' = 'BWBSwk'")
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                                "'BWBSwk 3' = 'BWBSwk'")
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                                "'CMA un' = 'BAFA'")
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                                "'CMA unp' = 'BAFA'")
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                               "'ESSFmv 1' = 'ESSFmv'")
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                               "'ESSFmv 3' = 'ESSFmv'")
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                               "'ESSFmv 4' = 'ESSFmv'")
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                               "'ESSFmvp' = 'ESSFmv'")
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                               "'ESSFmcp' = 'ESSFmc'")
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                               "'ESSFxv 1' = 'ESSFxv'")
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                               "'ESSFxvp' = 'ESSFxv'")
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                               "'MH  mm 2' = 'MHmm'")
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                               "'MH  mmp' = 'MHmm'")
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                               "'SWB un' = 'SWBun'")
rsf.data.du7$bec_label_reclass <- car::recode (rsf.data.du7$bec_label_reclass,
                                               "'SWB uns' = 'SWBun'")
rsf.data.du7 <- rsf.data.du7 %>%
  dplyr::filter (bec_label_reclass != "ESSFmwp")
rsf.data.du7 <- rsf.data.du7 %>%
  dplyr::filter (bec_label_reclass != "ESSFwm 4")
rsf.data.du7 <- rsf.data.du7 %>%
  dplyr::filter (bec_label_reclass != "ESSFwmw")

ggplot (rsf.data.du7, aes (x = bec_label_reclass, fill = pttype)) + 
  geom_histogram (position = "dodge", stat = "count") +
  labs (title = "Histogram DU7, Summer, BEC Type\
                          at Available (0) and Used (1) Locations",
        x = "Biogeclimatic Unit Type",
        y = "Count") +
  scale_fill_discrete (name = "Location Type") +
  theme (axis.text.x = element_text (angle = 45))

rsf.data.du7$bec_label_reclass <- relevel (rsf.data.du7$bec_label_reclass,
                                           ref = "ESSFmc") # reference category

### OUTLIERS ###
ggplot (rsf.data.du7 %>% filter (HERD_NAME == "Telkwa"), aes (x = pttype, y = distance_to_resource_road)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU7, Distance to Resource Roads at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Resource Road")
ggplot (rsf.data.du7 %>% filter (HERD_NAME == "Pink Mountain"), aes (x = pttype, y = distance_to_cut_1to4yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU7, Distance to Cutblock 1 to 4 Years Old at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock 1 to 4 Years Old")
ggplot (rsf.data.du7, aes (x = pttype, y = distance_to_cut_5to9yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU7, Distance to Cutblock 5 to 9 Years Old at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock 5 to 9 Years Old")
rsf.data.du7 <- rsf.data.du7 %>% # removed outlier locations really far from  (>200km) from cutblocks
  dplyr::filter (distance_to_cut_5to9yo < 200000)
ggplot (rsf.data.du7, aes (x = pttype, y = distance_to_cut_10to29yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU7, Distance to Cutblock 10 to 29 Years Old at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock 10 to 29 Years Old")
ggplot (rsf.data.du7, aes (x = pttype, y = distance_to_cut_30orOveryo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot DU7, Distance to Cutblock Greater than 30 Years Old at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock Greater than 30 Years Old")

### HISTOGRAMS ###
ggplot (rsf.data.du7, aes (x = distance_to_resource_road, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 100) +
  labs (title = "Histogram DU7, Distance to Resource Roads at Available (0) and Used (1) Locations",
        x = "Distance to Resource Road",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggplot (rsf.data.du7, aes (x = distance_to_cut_1to4yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 100) +
  labs (title = "Histogram DU7, Distance to  Cutblock 1 to 4 Years Old at Available (0) and Used (1) Locations",
        x = "Distance to  Cutblock 1 to 4 Years Old",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggplot (rsf.data.du7, aes (x = distance_to_cut_5to9yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 100) +
  labs (title = "Histogram DU7, Distance to  Cutblock 5 to 9 Years Old at Available (0) and Used (1) Locations",
        x = "Distance to  Cutblock 5 to 9 Years Old",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggplot (rsf.data.du7, aes (x = distance_to_cut_10to29yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 100) +
  labs (title = "Histogram DU7, Distance to Cutblocks 10 to 29 Years Old at Available (0) and Used (1) Locations",
        x = "Distance to  Cutblocks 10 to 29 Years Old",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggplot (rsf.data.du7, aes (x = distance_to_cut_30orOveryo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 100) +
  labs (title = "Histogram DU7, Distance to Cutblocks Greater than 30 Years Old at Available (0) and Used (1) Locations",
        x = "Distance to  Cutblocks Greater than 30 Years Old",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")

### CORRELATION ###
corr.rsf.data.du7 <- rsf.data.du7 [c (10:14)]
corr.rsf.data.du7 <- round (cor (corr.rsf.data.du7, method = "spearman"), 3)
ggcorrplot (corr.rsf.data.du7, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Resource Selection Function Model Covariate Correlations for DU7")

# Distance to cut 5 to 9, 10 to 29 and >30 all highly correalted; grouped to >5
rsf.data.du7 <- dplyr::mutate (rsf.data.du7, distance_to_cut_over4 = pmin (distance_to_cut_5to9yo, 
                                                                           distance_to_cut_10to29yo,
                                                                           distance_to_cut_30orOveryo))
### VIF 
glm.du7 <- glm (pttype ~ distance_to_cut_1to4yo + distance_to_cut_over4 +
                          distance_to_resource_road + bec_label_reclass, 
                data = rsf.data.du7,
                family = binomial (link = 'logit'))
car::vif (glm.du7)

write.csv (rsf.data.du7, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du7_v2.csv")

#########################
### TRANSFORM COVARS ###
#######################

# Transform distance to covars as exponentinal function, follwoing Demars (2018)[http://www.bcogris.ca/sites/default/files/bcip-2019-01-final-report-demars-ver-2.pdf]
# decay.distance = exp (-0.002 8 distance to road)
# 0.002 = distances > 1500-m essentially have a similar and limited effect
rsf.data.du7$exp_dist_res_road <- exp ((rsf.data.du7$distance_to_resource_road * -0.002))
rsf.data.du7$exp_dist_cut_1to4 <- exp ((rsf.data.du7$distance_to_cut_1to4yo * -0.002))
rsf.data.du7$exp_dist_cut_over4 <- exp ((rsf.data.du7$distance_to_cut_over4 * -0.002))

### Standardize the data (helps with model convergence) ###
rsf.data.du7$std_exp_dist_res_road <- (rsf.data.du7$exp_dist_res_road - 
                                       mean (rsf.data.du7$exp_dist_res_road)) / 
                                       sd (rsf.data.du7$exp_dist_res_road)
rsf.data.du7$std_exp_dist_cut_1to4 <- (rsf.data.du7$exp_dist_cut_1to4 - 
                                       mean (rsf.data.du7$exp_dist_cut_1to4)) / 
                                       sd (rsf.data.du7$exp_dist_cut_1to4)
rsf.data.du7$std_exp_dist_cut_over4 <- (rsf.data.du7$exp_dist_cut_over4 - 
                                        mean (rsf.data.du7$exp_dist_cut_over4)) / 
                                        sd (rsf.data.du7$exp_dist_cut_over4)

### Functional Response Covariates ###
#### Calc mean available distance to road and cutblock in home range, by unique individual
avail.rsf.data.du7 <- subset (rsf.data.du7, pttype == 0)

std_exp_dist_res_road_E <- tapply (avail.rsf.data.du7$std_exp_dist_res_road, avail.rsf.data.du7$animal_id, mean)
std_exp_dist_cut_1to4_E <- tapply (avail.rsf.data.du7$std_exp_dist_cut_1to4, avail.rsf.data.du7$animal_id, mean)
std_exp_dist_cut_over4_E <- tapply (avail.rsf.data.du7$std_exp_dist_cut_over4, avail.rsf.data.du7$animal_id, mean)

inds <- as.character (rsf.data.du7$animal_id)
rsf.data.du7 <- cbind (rsf.data.du7, "dist_rd_E" = std_exp_dist_res_road_E[inds], 
                       "dist_cut_1to4_E" = std_exp_dist_cut_1to4_E[inds],
                       "dist_cut_over4_E" = std_exp_dist_cut_over4_E[inds])

# to simplify available cutblock effect; interact with distance to any cutblock age
rsf.data.du7$dist_cut_min_all <- pmin (rsf.data.du7$distance_to_cut_1to4,
                                       rsf.data.du7$distance_to_cut_over4)
rsf.data.du7$exp_dist_cut_min <- exp ((rsf.data.du7$dist_cut_min_all * -0.002))
rsf.data.du7$std_exp_dist_cut_min <- (rsf.data.du7$exp_dist_cut_min - 
                                        mean (rsf.data.du7$exp_dist_cut_min)) / 
                                        sd (rsf.data.du7$exp_dist_cut_min)
avail.rsf.data.du7 <- subset (rsf.data.du7, pttype == 0)
std_exp_dist_cut_min_E <- tapply (avail.rsf.data.du7$std_exp_dist_cut_min, avail.rsf.data.du7$animal_id, mean)
rsf.data.du7 <- cbind (rsf.data.du7, "dist_cut_min_E" = std_exp_dist_cut_min_E[inds])

###################
### FIT MODELS ###
#################

### Generalized Linear Mixed Models (GLMMs) ###
#### First, determine the random effects structure

# Individual animal
model.lme4.du7.animal <- glmer (pttype ~ 1 + (1 | animal_id), # random effect for animal
                                data = rsf.data.du7, 
                                family = binomial (link = "logit"),
                                verbose = T) 
ss <- getME (model.lme4.du7.animal, c ("theta","fixef")) # needed to be rerun 3x, but converged
model.lme4.du7.animal <- update (model.lme4.du7.animal, start = ss, control = glmerControl (optCtrl = list (maxfun=2e4)))

#### Season
model.lme4.du7.season <- glmer (pttype ~ 1 + (1 | season), # random effect for season
                                data = rsf.data.du7, 
                                family = binomial (link = "logit"),
                                verbose = T) 

#### Individual animal and Season
model.lme4.du7.anim.seas <- glmer (pttype ~ 1 + (1 | animal_id) + (1 | season), # random effect intercepts for individual and season
                                   data = rsf.data.du7, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 

# Compare models 
anova (model.lme4.du7.animal, model.lme4.du7.season, model.lme4.du7.anim.seas)

# animal and season model had best fit; use both


#### Second, determine the fixed effects structure
### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 5, nrow = 0))
colnames (table.aic) <- c ("DU", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

#### BEC only model
model.lme4.du7.bec <- glmer (pttype ~ bec_label_reclass + (1 | animal_id) + (1 | season), 
                                 data = rsf.data.du7, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
ss <- getME (model.lme4.du7.bec, c ("theta","fixef")) # needed to be rerun , but converged
model.lme4.du7.bec <- update (model.lme4.du7.bec, start = ss, control = glmerControl (optCtrl = list (maxfun=2e4)))
# AIC
table.aic [1, 1] <- "DU7"
table.aic [1, 2] <- "BEC variant"
table.aic [1, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [1, 4] <-  AIC (model.lme4.du7.bec)

# Dist Road model
model.lme4.du7.road <- glmer (pttype ~ std_exp_dist_res_road + (1 | animal_id) + (1 | season),
                              data = rsf.data.du7, 
                              family = binomial (link = "logit"),
                              verbose = T) 
# AIC
table.aic [2, 1] <- "DU7"
table.aic [2, 2] <- "Distance to Resource Road"
table.aic [2, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [2, 4] <-  AIC (model.lme4.du7.road)

# Dist Cut model
model.lme4.du7.cut <- glmer (pttype ~ std_exp_dist_cut_1to4 + std_exp_dist_cut_over4 + (1 | animal_id) + (1 | season),
                             data = rsf.data.du7, 
                             family = binomial (link = "logit"),
                             verbose = T) 
# AIC
table.aic [3, 1] <- "DU7"
table.aic [3, 2] <- "Distance to Cutblock"
table.aic [3, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [3, 4] <-  AIC (model.lme4.du7.cut)

# Dist Road and Cut model
model.lme4.du7.rd.cut <- glmer (pttype ~ std_exp_dist_res_road + std_exp_dist_cut_1to4 + std_exp_dist_cut_over4 + (1 | animal_id) + (1 | season),
                                data = rsf.data.du7, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [4, 1] <- "DU7"
table.aic [4, 2] <- "Distance to Resource Road + Distance to Cutblock"
table.aic [4, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [4, 4] <-  AIC (model.lme4.du7.rd.cut)

# Dist Road Fxn Response
model.lme4.du7.rd.fxn <- glmer (pttype ~ std_exp_dist_res_road + dist_rd_E + std_exp_dist_res_road*dist_rd_E + (1 | animal_id) + (1 | season),
                                data = rsf.data.du7, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [5, 1] <- "DU7"
table.aic [5, 2] <- "Distance to Resource Road + Available Distance to Resource Road + Distance to Resource Road*Available Distance to Resource Road"
table.aic [5, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [5, 4] <-  AIC (model.lme4.du7.rd.fxn)

scatter3D (rsf.data.du7$distance_to_resource_road, # stronger avoidance of roads in areas with more roads; higher slope in selection away form roads in high road available areas
           rsf.data.du7$dist_rd_E,
           (predict (model.lme4.du7.rd.fxn,
                     newdata = rsf.data.du7, 
                     re.form = NA, type = "response")), 
           xlab = "Dist. Road",
           ylab = "Avail. Dist Road", 
           zlab = "Selection",
           theta = 15, phi = 20)

# Dist Cut Fxn Response
model.lme4.du7.cut.fxn <- glmer (pttype ~ std_exp_dist_cut_1to4 + std_exp_dist_cut_over4 + dist_cut_min_E + std_exp_dist_cut_1to4*dist_cut_min_E + std_exp_dist_cut_over4*dist_cut_min_E + (1 | animal_id) + (1 | season),
                                 data = rsf.data.du7, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [6, 1] <- "DU7"
table.aic [6, 2] <- "Distance to Cutblock + Available Distance to Cutblock + Distance to Cutblock*Available Distance to Cutblock"
table.aic [6, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [6, 4] <-  AIC (model.lme4.du7.cut.fxn)

scatter3D (rsf.data.du7$distance_to_cut_1to4, # stronger avoidance of cut in areas with more cut; higher slope in selection away form cut in high cut available areas
           rsf.data.du7$dist_cut_E,
           (predict (model.lme4.du7.cut.fxn,
                     newdata = rsf.data.du7, 
                     re.form = NA, type = "response")), 
           xlab = "Dist. Cut 1to4",
           ylab = "Avail. Dist Cut", 
           zlab = "Selection",
           theta = 15, phi = 20)

# BEC, Dist Road and Cut model
model.lme4.du7.all <- glmer (pttype ~ bec_label_reclass + std_exp_dist_res_road + std_exp_dist_cut_1to4 + std_exp_dist_cut_over4 + (1 | animal_id) + (1 | season),
                             data = rsf.data.du7, 
                             family = binomial (link = "logit"),
                             verbose = T) 
# AIC
table.aic [7, 1] <- "DU7"
table.aic [7, 2] <- "BEC + Distance to Resource Road + Distance to Cutblock"
table.aic [7, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [7, 4] <-  AIC (model.lme4.du7.all)

# BEC, Dist Road (fxn) and Cut model
model.lme4.du7.all.rd.fxn <- glmer (pttype ~ bec_label_reclass + std_exp_dist_res_road + std_exp_dist_cut_1to4 + std_exp_dist_cut_over4 + dist_rd_E + std_exp_dist_res_road*dist_rd_E + (1 | animal_id) + (1 | season),
                                 data = rsf.data.du7, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
ss <- getME (model.lme4.du7.all.fxn, c ("theta","fixef")) # needed to be rerun , but converged
model.lme4.du7.all.rd.fxn <- update (model.lme4.du7.all.fxn, start = ss, control = glmerControl (optCtrl = list (maxfun=2e4)))
# AIC
table.aic [8, 1] <- "DU7"
table.aic [8, 2] <- "BEC + Distance to Resource Road + Distance to Cutblock + Available Distance to Resource Road + Distance to Resource Road*Available Distance to Resource Road"
table.aic [8, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [8, 4] <-  AIC (model.lme4.du7.all.fxn)

scatter3D (x = rsf.data.du7$distance_to_resource_road, 
           y = rsf.data.du7$exp_dist_res_road, 
           z = (predict (model.lme4.du7.all.fxn,
                         newdata = rsf.data.du7, 
                         re.form = NA, type = "response")),
           xlab = "Dist. Road",
           ylab = "Avail. Dist Road", 
           zlab = "Selection",
           theta = 15, phi = 20)

# BEC, Dist Road and Cut model (fxn)
model.lme4.du7.all.cut.fxn <- glmer (pttype ~ bec_label_reclass + std_exp_dist_res_road + std_exp_dist_cut_1to4 + std_exp_dist_cut_over4 + dist_cut_min_E + std_exp_dist_cut_1to4*dist_cut_min_E + std_exp_dist_cut_over4*dist_cut_min_E + (1 | animal_id) + (1 | season),
                                 data = rsf.data.du7, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [9, 1] <- "DU7"
table.aic [9, 2] <- "BEC + Distance to Resource Road + Distance to Cutblock + Available Distance to Cutblock + Distance to Cutblock*Available Distance to Cutblock"
table.aic [9, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [9, 4] <-  AIC (model.lme4.du7.all.cut.fxn)

scatter3D (x = rsf.data.du7$distance_to_cut_1to4, 
           y = rsf.data.du7$dist_cut_min_E, 
           z = (predict (model.lme4.du7.all.fxn,
                         newdata = rsf.data.du7, 
                         re.form = NA, type = "response")),
           xlab = "Dist. Cut 1 to 4",
           ylab = "Avail. Dist Cut", 
           zlab = "Selection",
           theta = 15, phi = 20)

## AIC comparison of MODELS ## 
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 4] - min (table.aic [1:9, 4])))), 
                    (exp (-0.5 * (table.aic [2, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [3, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [4, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [5, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [6, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [7, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [8, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [9, 4] - min (table.aic [1:9, 4])))))
table.aic [1, 5] <- round ((exp (-0.5 * (table.aic [1, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [2, 5] <- round ((exp (-0.5 * (table.aic [2, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [3, 5] <- round ((exp (-0.5 * (table.aic [3, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [4, 5] <- round ((exp (-0.5 * (table.aic [4, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [5, 5] <- round ((exp (-0.5 * (table.aic [5, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [6, 5] <- round ((exp (-0.5 * (table.aic [6, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [7, 5] <- round ((exp (-0.5 * (table.aic [7, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [8, 5] <- round ((exp (-0.5 * (table.aic [8, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [9, 5] <- round ((exp (-0.5 * (table.aic [9, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_du7_v2.csv", sep = ",")

# used model without functional response because didn't appear to improve interpretation of model, i.e.,
# the distance to road covariate didn't change much over variability in available distance to road

# save the top model
save (model.lme4.du7.all, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_du7_top_v2.rda")

###################
### SAVE MODEL ###
#################

# Create table of model coefficients from top model
model.coeffs <- as.data.frame (coef (summary (model.lme4.du7.all)))
model.coeffs$mean_exp_neg0002 <- 0
model.coeffs$sd_exp_neg0002 <- 0

model.coeffs [21, 5] <- mean (exp ((rsf.data.du7$distance_to_resource_road * -0.002)))
model.coeffs [22, 5] <- mean (exp ((rsf.data.du7$distance_to_cut_1to4yo * -0.002)))
model.coeffs [23, 5] <- mean (exp ((rsf.data.du7$distance_to_cut_over4 * -0.002)))

model.coeffs [21, 6] <- sd (exp ((rsf.data.du7$distance_to_resource_road * -0.002)))
model.coeffs [22, 6] <- sd (exp ((rsf.data.du7$distance_to_cut_1to4yo * -0.002)))
model.coeffs [23, 6] <- sd (exp ((rsf.data.du7$distance_to_cut_over4 * -0.002)))

write.table (model.coeffs, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\model_coefficients\\table_du7_summ_model_coeffs_top.csv", sep = ",")


###############################
### RSF RASTER CALCULATION ###
#############################

### LOAD RASTERS ###
bec.bafa <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_bafa_cma_du7.tif")
bec.bwbs.dk <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_bwbs_dk_du7.tif")
bec.bwbs.m <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_bwbs_m_du7.tif")
bec.bwbs.wk <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_bwbs_wk_du7.tif")
bec.cwh.ws2 <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_cwh_ws2_du7.tif")
bec.essf.mk <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_essf_mk_du7.tif")
bec.essf.mkp <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_essf_mkp_du7.tif")
bec.essf.mv <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_essf_mv_du7.tif")
bec.essf.xv <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_essf_xv_du7.tif")
bec.idf.dk4 <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_idf_dk4_du7.tif")
bec.mh.mm <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_mh_mm_du7.tif")
bec.ms.xv <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\bec_ms_xv_du7.tif")
bec.sbps.mc <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_sbps_mc_du7.tif")
bec.sbps.xc <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_sbps_xc_du7.tif")
bec.sbs.dk <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_sbs_dk_du7.tif")
bec.sbs.mc2 <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_sbs_mc2_du7.tif")
bec.sbs.mc3 <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_sbs_mc3_du7.tif")
bec.swb.mk <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_swb_mk_du7.tif")
bec.swb.mks <- raster ("C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\bec_swb_mks_du7.tif")
dist.cut.1to4 <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_1to4yo.tif")
dist.cut.5over <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_5yo_over.tif")
dist.resource.rd <- raster ("C:\\Work\\caribou\\clus_data\\roads_ha_bc\\dist_crds_resource.tif")

### Need to resample road/cut rasters to make them fit together
dist.cut.1to4_du7 <- resample (dist.cut.1to4, bec.swb.mks, method = 'bilinear')
dist.cut.5over_du7 <- resample (dist.cut.5over, bec.swb.mks, method = 'bilinear')
dist.resource.rd_du7 <- resample (dist.resource.rd, bec.swb.mks, method = 'bilinear')

### Adjust the raster data for 'standardized' model covariates ###
std.dist.resource.rd <- (exp (dist.resource.rd_du7 * -0.002) - 0.146857) / 0.2660912
std.dist.cut.1to4 <- (exp (dist.cut.1to4_du7 * -0.002) - 0.004926127) / 0.04917472
std.dist.cut.5over <- (exp (dist.cut.5over_du7 * -0.002) - 0.08146909) / 0.2175302

### CALCULATE RASTER RSF ###
raster.rsf <- (exp (-1.5 + (bec.bafa * 0.45) + (bec.bwbs.dk * -0.13) +
                      (bec.bwbs.m * -0.53) + (bec.bwbs.wk * -0.83) +
                      (bec.cwh.ws2 * -0.54) + (bec.essf.mk * -0.22) + 
                      (bec.essf.mkp * -0.02) + (bec.essf.mv * -0.13) + 
                      (bec.essf.xv * 0.04) + (bec.idf.dk4 * 0.22) +
                      (bec.mh.mm * 0.08) + (bec.ms.xv * -0.02) +
                      (bec.sbps.mc * -0.002) + (bec.sbps.xc * 0.07) +
                      (bec.sbs.dk * -0.002) + (bec.sbs.mc2 * -0.17) +
                      (bec.sbs.mc3 * 	0.10) + (bec.swb.mk * -0.20) +
                      (bec.swb.mks * 	-0.06) + (std.dist.resource.rd * -0.07) +
                      (std.dist.cut.1to4 * 	-0.03) + 
                      (std.dist.cut.5over * 	0.006))) / 
              (1 + exp (-1.5 + (bec.bafa * 0.45) + (bec.bwbs.dk * -0.13) +
              (bec.bwbs.m * -0.53) + (bec.bwbs.wk * -0.83) +
              (bec.cwh.ws2 * -0.54) + (bec.essf.mk * -0.22) + 
              (bec.essf.mkp * -0.02) + (bec.essf.mv * -0.13) + 
              (bec.essf.xv * 0.04) + (bec.idf.dk4 * 0.22) +
              (bec.mh.mm * 0.08) + (bec.ms.xv * -0.02) +
              (bec.sbps.mc * -0.002) + (bec.sbps.xc * 0.07) +
              (bec.sbs.dk * -0.002) + (bec.sbs.mc2 * -0.17) +
              (bec.sbs.mc3 * 	0.10) + (bec.swb.mk * -0.20) +
              (bec.swb.mks * 	-0.06) + (std.dist.resource.rd * -0.07) +
              (std.dist.cut.1to4 * 	-0.03) + 
              (std.dist.cut.5over * 	0.006)))

plot (raster.rsf)

writeRaster (raster.rsf, "C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du7\\rsf_du7_v2.tif", 
             format = "GTiff", overwrite = T)


##########################
### k-fold Validation ###
########################
df.animal.id <- as.data.frame (unique (rsf.data.du7$animal_id))
names (df.animal.id) [1] <-"animal_id"
df.animal.id$group <- rep_len (1:5, nrow (df.animal.id)) # orderly selection of groups
rsf.data.du7 <- dplyr::full_join (rsf.data.du7, df.animal.id, by = "animal_id")

### FOLD 1 ###
train.data.1 <- rsf.data.du7 %>%
  filter (group < 5)
test.data.1 <- rsf.data.du7 %>%
  filter (group == 5)

model.lme4.du7train1 <- glmer (pttype ~ bec_label_reclass + 
                                 std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + 
                                 std_exp_dist_cut_over4 + 
                                 (1 | animal_id) + (1 | season), 
                               data = train.data.1, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# create a table of k-fold outputs
table.kfold <- data.frame (matrix (ncol = 12, nrow = 50))
colnames (table.kfold) <- c ("test.number", "bin.mid", "bin.weight", "utilization", "used.count", 
                             "expected.count", "lm.slope", "lm.slope.p.value", "lm.intercept",
                             "lm.intercept.p.value", "adj.R.sq", "chi.sq.p.value")
table.kfold [c (1:10), 1] <- 1
table.kfold$bin.mid <- c (0.013, 0.039, 0.065, 0.091, 0.117, 0.143, 0.169, 0.195, 0.221, 0.247)

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du7$preds.train1 <- predict (model.lme4.du7train1, 
                                      newdata = rsf.data.du7, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du7, aes (preds.train1)) +
  geom_histogram()
max (rsf.data.du7$preds.train1)
min (rsf.data.du7$preds.train1)

rsf.data.du7$preds.train1.class <- cut (rsf.data.du7$preds.train1, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.026, 0.052, 0.078, 0.104, 0.130, 0.156, 0.182, 0.208, 0.234, Inf), 
                                        labels = c ("0.013", "0.039", "0.065", "0.091", "0.117",
                                                    "0.143", "0.169", "0.195", "0.221", "0.247"))
rsf.data.du7.avail <- dplyr::filter (rsf.data.du7, pttype == 0)

table.kfold [1, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train1.class == "0.013")) * 0.013) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [2, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train1.class == "0.039")) * 0.039)
table.kfold [3, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train1.class == "0.065")) * 0.065)
table.kfold [4, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train1.class == "0.091")) * 0.091)
table.kfold [5, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train1.class == "0.117")) * 0.117)
table.kfold [6, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train1.class == "0.143")) * 0.143)
table.kfold [7, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train1.class == "0.169")) * 0.169)
table.kfold [8, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train1.class == "0.195")) * 0.195)
table.kfold [9, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train1.class == "0.221")) * 0.221)
table.kfold [10, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train1.class == "0.247")) * 0.247)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du7\\table_kfold_valid_du7.csv")

# data for estimating use
test.data.1$preds <- predict (model.lme4.du7train1, newdata = test.data.1, re.form = NA, type = "response")
test.data.1$preds.class <- cut (test.data.1$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.026, 0.052, 0.078, 0.104, 0.130, 0.156, 0.182, 0.208, 0.234, Inf), 
                                labels = c ("0.013", "0.039", "0.065", "0.091", "0.117",
                                            "0.143", "0.169", "0.195", "0.221", "0.247"))
write.csv (test.data.1, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du7\\rsf_preds_du7_train1.csv")
test.data.1.used <- dplyr::filter (test.data.1, pttype == 1)

table.kfold [1, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.013"))
table.kfold [2, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.039"))
table.kfold [3, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.065"))
table.kfold [4, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.091"))
table.kfold [5, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.117"))
table.kfold [6, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.143"))
table.kfold [7, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.169"))
table.kfold [8, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.195"))
table.kfold [9, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.221"))
table.kfold [10, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.247"))

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

table.kfold [1, 7] <- 0.88740
table.kfold [1, 8] <- "<0.001"
table.kfold [1, 9] <- 337.56708
table.kfold [1, 10] <- 0.459
table.kfold [1, 11] <- 0.9046 

chisq.test(dplyr::filter(table.kfold, test.number == 1)$used.count, dplyr::filter(table.kfold, test.number == 1)$expected.count)
table.kfold [1, 12] <-  0.2424

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du7\\table_kfold_valid_du7.csv")


ggplot (dplyr::filter(table.kfold, test.number == 1), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 1 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 20000, by = 1000)) + 
  scale_y_continuous (breaks = seq (0, 20000, by = 1000))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du7_grp1.png")

write.csv (rsf.data.du7, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du7_preds.csv")

### FOLD 2 ###
train.data.2 <- rsf.data.du7 %>%
  filter (group == 1 | group == 2 | group == 3 | group == 5)
test.data.2 <- rsf.data.du7 %>%
  filter (group == 4)

model.lme4.du7train2 <- glmer (pttype ~ bec_label_reclass + 
                                 std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + 
                                 std_exp_dist_cut_over4 + 
                                 (1 | animal_id) + (1 | season), 
                               data = train.data.2, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du7$preds.train2 <- predict (model.lme4.du7train2, 
                                      newdata = rsf.data.du7, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du7, aes (preds.train2)) +
  geom_histogram()
max (rsf.data.du7$preds.train2)
min (rsf.data.du7$preds.train2)

rsf.data.du7$preds.train2.class <- cut (rsf.data.du7$preds.train2, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.026, 0.052, 0.078, 0.104, 0.130, 0.156, 0.182, 0.208, 0.234, Inf), 
                                        labels = c ("0.013", "0.039", "0.065", "0.091", "0.117",
                                                    "0.143", "0.169", "0.195", "0.221", "0.247"))
table.kfold [c (11:20), 1] <- 2

rsf.data.du7.avail <- dplyr::filter (rsf.data.du7, pttype == 0)

table.kfold [11, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train2.class == "0.013")) * 0.013) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [12, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train2.class == "0.039")) * 0.039)
table.kfold [13, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train2.class == "0.065")) * 0.065)
table.kfold [14, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train2.class == "0.091")) * 0.091)
table.kfold [15, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train2.class == "0.117")) * 0.117)
table.kfold [16, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train2.class == "0.143")) * 0.143)
table.kfold [17, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train2.class == "0.169")) * 0.169)
table.kfold [18, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train2.class == "0.195")) * 0.195)
table.kfold [19, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train2.class == "0.221")) * 0.221)
table.kfold [20, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train2.class == "0.247")) * 0.247)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du7\\table_kfold_valid_du7.csv")

# data for estimating use
test.data.2$preds <- predict (model.lme4.du7train2, newdata = test.data.2, re.form = NA, type = "response")
test.data.2$preds.class <- cut (test.data.2$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.026, 0.052, 0.078, 0.104, 0.130, 0.156, 0.182, 0.208, 0.234, Inf), 
                                labels = c ("0.013", "0.039", "0.065", "0.091", "0.117",
                                            "0.143", "0.169", "0.195", "0.221", "0.247"))
write.csv (test.data.2, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du7\\rsf_preds_du7_train2.csv")
test.data.2.used <- dplyr::filter (test.data.2, pttype == 1)

table.kfold [11, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.013"))
table.kfold [12, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.039"))
table.kfold [13, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.065"))
table.kfold [14, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.091"))
table.kfold [15, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.117"))
table.kfold [16, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.143"))
table.kfold [17, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.169"))
table.kfold [18, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.195"))
table.kfold [19, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.221"))
table.kfold [20, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.247"))

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
                       data = dplyr::filter(table.kfold, test.number == 2))
summary (glm.kfold.test2)

table.kfold [11, 7] <- 1.03493
table.kfold [11, 8] <- "<0.001"
table.kfold [11, 9] <- -107.46260
table.kfold [11, 10] <- 0.427
table.kfold [11, 11] <- 0.9967

chisq.test(dplyr::filter(table.kfold, test.number == 2)$used.count, dplyr::filter(table.kfold, test.number == 2)$expected.count)
table.kfold [11, 12] <-  0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du7\\table_kfold_valid_du7.csv")

ggplot (dplyr::filter(table.kfold, test.number == 2), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 2 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 20000, by = 1000)) + 
  scale_y_continuous (breaks = seq (0, 20000, by = 1000))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du7_grp2.png")

write.csv (rsf.data.du7, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du7_preds.csv")

### FOLD 3 ###
train.data.3 <- rsf.data.du7 %>%
  filter (group == 1 | group == 2 | group == 4 | group == 5)
test.data.3 <- rsf.data.du7 %>%
  filter (group == 3)

model.lme4.du7train3 <- glmer (pttype ~ bec_label_reclass + 
                                 std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + 
                                 std_exp_dist_cut_over4 + 
                                 (1 | animal_id) + (1 | season), 
                               data = train.data.3, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du7$preds.train3 <- predict (model.lme4.du7train3, 
                                      newdata = rsf.data.du7, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du7, aes (preds.train3)) +
  geom_histogram()
max (rsf.data.du7$preds.train3)
min (rsf.data.du7$preds.train3)

rsf.data.du7$preds.train3.class <- cut (rsf.data.du7$preds.train3, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.026, 0.052, 0.078, 0.104, 0.130, 0.156, 0.182, 0.208, 0.234, Inf), 
                                        labels = c ("0.013", "0.039", "0.065", "0.091", "0.117",
                                                    "0.143", "0.169", "0.195", "0.221", "0.247"))
table.kfold [c (21:30), 1] <- 3

rsf.data.du7.avail <- dplyr::filter (rsf.data.du7, pttype == 0)

table.kfold [21, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train3.class == "0.013")) * 0.013) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [22, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train3.class == "0.039")) * 0.039)
table.kfold [23, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train3.class == "0.065")) * 0.065)
table.kfold [24, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train3.class == "0.091")) * 0.091)
table.kfold [25, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train3.class == "0.117")) * 0.117)
table.kfold [26, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train3.class == "0.143")) * 0.143)
table.kfold [27, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train3.class == "0.169")) * 0.169)
table.kfold [28, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train3.class == "0.195")) * 0.195)
table.kfold [29, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train3.class == "0.221")) * 0.221)
table.kfold [30, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train3.class == "0.247")) * 0.247)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du7\\table_kfold_valid_du7.csv")

# data for estimating use
test.data.3$preds <- predict (model.lme4.du7train3, newdata = test.data.3, re.form = NA, type = "response")
test.data.3$preds.class <- cut (test.data.3$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.026, 0.052, 0.078, 0.104, 0.130, 0.156, 0.182, 0.208, 0.234, Inf), 
                                labels = c ("0.013", "0.039", "0.065", "0.091", "0.117",
                                            "0.143", "0.169", "0.195", "0.221", "0.247"))
write.csv (test.data.3, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du7\\rsf_preds_du7_train3.csv")
test.data.3.used <- dplyr::filter (test.data.3, pttype == 1)

table.kfold [21, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.013"))
table.kfold [22, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.039"))
table.kfold [23, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.065"))
table.kfold [24, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.091"))
table.kfold [25, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.117"))
table.kfold [26, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.143"))
table.kfold [27, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.169"))
table.kfold [28, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.195"))
table.kfold [29, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.221"))
table.kfold [30, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.247"))

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
                       data = dplyr::filter(table.kfold, test.number == 3))
summary (glm.kfold.test3)

table.kfold [21, 7] <- 1.05214 
table.kfold [21, 8] <- "<0.001"
table.kfold [21, 9] <- -149.04993
table.kfold [21, 10] <- 0.682
table.kfold [21, 11] <- 0.9557

chisq.test(dplyr::filter(table.kfold, test.number == 3)$used.count, dplyr::filter(table.kfold, test.number == 3)$expected.count)
table.kfold [21, 12] <-  0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du7\\table_kfold_valid_du7.csv")

ggplot (dplyr::filter(table.kfold, test.number == 3), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 3 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 20000, by = 1000)) + 
  scale_y_continuous (breaks = seq (0, 20000, by = 1000))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du7_grp3.png")

write.csv (rsf.data.du7, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du7_preds.csv")

### FOLD 4 ###
train.data.4 <- rsf.data.du7 %>%
  filter (group == 1 | group == 3 | group == 4 | group == 5)
test.data.4 <- rsf.data.du7 %>%
  filter (group == 2)

model.lme4.du7train4 <- glmer (pttype ~ bec_label_reclass + 
                                 std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + 
                                 std_exp_dist_cut_over4 + 
                                 (1 | animal_id) + (1 | season), 
                               data = train.data.4, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du7$preds.train4 <- predict (model.lme4.du7train4, 
                                      newdata = rsf.data.du7, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du7, aes (preds.train4)) +
  geom_histogram()
max (rsf.data.du7$preds.train4)
min (rsf.data.du7$preds.train4)

rsf.data.du7$preds.train4.class <- cut (rsf.data.du7$preds.train4, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.026, 0.052, 0.078, 0.104, 0.130, 0.156, 0.182, 0.208, 0.234, Inf), 
                                        labels = c ("0.013", "0.039", "0.065", "0.091", "0.117",
                                                    "0.143", "0.169", "0.195", "0.221", "0.247"))
table.kfold [c (31:40), 1] <- 4

rsf.data.du7.avail <- dplyr::filter (rsf.data.du7, pttype == 0)

table.kfold [31, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train4.class == "0.013")) * 0.013) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [32, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train4.class == "0.039")) * 0.039)
table.kfold [33, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train4.class == "0.065")) * 0.065)
table.kfold [34, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train4.class == "0.091")) * 0.091)
table.kfold [35, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train4.class == "0.117")) * 0.117)
table.kfold [36, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train4.class == "0.143")) * 0.143)
table.kfold [37, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train4.class == "0.169")) * 0.169)
table.kfold [38, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train4.class == "0.195")) * 0.195)
table.kfold [39, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train4.class == "0.221")) * 0.221)
table.kfold [40, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train4.class == "0.247")) * 0.247)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du7\\table_kfold_valid_du7.csv")

# data for estimating use
test.data.4$preds <- predict (model.lme4.du7train4, newdata = test.data.4, re.form = NA, type = "response")
test.data.4$preds.class <- cut (test.data.4$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.026, 0.052, 0.078, 0.104, 0.130, 0.156, 0.182, 0.208, 0.234, Inf), 
                                labels = c ("0.013", "0.039", "0.065", "0.091", "0.117",
                                            "0.143", "0.169", "0.195", "0.221", "0.247"))
table.kfold [c (31:40), 1] <- 4
write.csv (test.data.4, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du7\\rsf_preds_du7_train4.csv")
test.data.4.used <- dplyr::filter (test.data.4, pttype == 1)

table.kfold [31, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.013"))
table.kfold [32, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.039"))
table.kfold [33, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.065"))
table.kfold [34, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.091"))
table.kfold [35, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.117"))
table.kfold [36, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.143"))
table.kfold [37, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.169"))
table.kfold [38, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.195"))
table.kfold [39, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.221"))
table.kfold [40, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.247"))

table.kfold [31, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [31, 4], 0) # expected number of uses in each bin
table.kfold [32, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [32, 4], 0) # expected number of uses in each bin
table.kfold [33, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [33, 4], 0) # expected number of uses in each bin
table.kfold [34, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [34, 4], 0) # expected number of uses in each bin
table.kfold [35, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [35, 4], 0) # expected number of uses in each bin
table.kfold [36, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [36, 4], 0) # expected number of uses in each bin
table.kfold [37, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [37, 4], 0) # expected number of uses in each bin
table.kfold [38, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [38, 4], 0) # expected number of uses in each bin
table.kfold [39, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [39, 4], 0) # expected number of uses in each bin
table.kfold [40, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [40, 4], 0) # expected number of uses in each bin

glm.kfold.test4 <- lm (used.count ~ expected.count, 
                       data = dplyr::filter(table.kfold, test.number == 4))
summary (glm.kfold.test4)

table.kfold [31, 7] <- 1.08965
table.kfold [31, 8] <- "<0.001"
table.kfold [31, 9] <- -249.24929
table.kfold [31, 10] <- 0.1
table.kfold [31, 11] <- 0.9954

chisq.test(dplyr::filter(table.kfold, test.number == 4)$used.count, dplyr::filter(table.kfold, test.number == 4)$expected.count)
table.kfold [31, 12] <-  0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du7\\table_kfold_valid_du7.csv")

ggplot (dplyr::filter(table.kfold, test.number == 4), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 4 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 20000, by = 1000)) + 
  scale_y_continuous (breaks = seq (0, 20000, by = 1000))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du7_grp4.png")

write.csv (rsf.data.du7, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du7_preds.csv")

### FOLD 5 ###
train.data.5 <- rsf.data.du7 %>%
  filter (group == 5 | group == 2 | group == 3 | group == 4)
test.data.5 <- rsf.data.du7 %>%
  filter (group == 1)

model.lme4.du7train5 <- glmer (pttype ~ bec_label_reclass + 
                                 std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + 
                                 std_exp_dist_cut_over4 + 
                                 (1 | animal_id) + (1 | season), 
                               data = train.data.5, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du7$preds.train5 <- predict (model.lme4.du7train5, 
                                      newdata = rsf.data.du7, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du7, aes (preds.train5)) +
  geom_histogram()
max (rsf.data.du7$preds.train5)
min (rsf.data.du7$preds.train5)

rsf.data.du7$preds.train5.class <- cut (rsf.data.du7$preds.train5, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.026, 0.052, 0.078, 0.104, 0.130, 0.156, 0.182, 0.208, 0.234, Inf), 
                                        labels = c ("0.013", "0.039", "0.065", "0.091", "0.117",
                                                    "0.143", "0.169", "0.195", "0.221", "0.247"))
table.kfold [c (41:50), 1] <- 5

rsf.data.du7.avail <- dplyr::filter (rsf.data.du7, pttype == 0)

table.kfold [41, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train5.class == "0.013")) * 0.013) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [42, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train5.class == "0.039")) * 0.039)
table.kfold [43, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train5.class == "0.065")) * 0.065)
table.kfold [44, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train5.class == "0.091")) * 0.091)
table.kfold [45, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train5.class == "0.117")) * 0.117)
table.kfold [46, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train5.class == "0.143")) * 0.143)
table.kfold [47, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train5.class == "0.169")) * 0.169)
table.kfold [48, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train5.class == "0.195")) * 0.195)
table.kfold [49, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train5.class == "0.221")) * 0.221)
table.kfold [50, 3] <- (nrow (dplyr::filter (rsf.data.du7.avail, preds.train5.class == "0.247")) * 0.247)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du7\\table_kfold_valid_du7.csv")

# data for estimating use
test.data.5$preds <- predict (model.lme4.du7train5, newdata = test.data.5, re.form = NA, type = "response")
test.data.5$preds.class <- cut (test.data.5$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.026, 0.052, 0.078, 0.104, 0.130, 0.156, 0.182, 0.208, 0.234, Inf), 
                                labels = c ("0.013", "0.039", "0.065", "0.091", "0.117",
                                            "0.143", "0.169", "0.195", "0.221", "0.247"))
write.csv (test.data.5, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du7\\rsf_preds_du7_train5.csv")
test.data.5.used <- dplyr::filter (test.data.5, pttype == 1)

table.kfold [41, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.013"))
table.kfold [42, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.039"))
table.kfold [43, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.065"))
table.kfold [44, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.091"))
table.kfold [45, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.117"))
table.kfold [46, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.143"))
table.kfold [47, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.169"))
table.kfold [48, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.195"))
table.kfold [49, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.221"))
table.kfold [50, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.247"))

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
                       data = dplyr::filter(table.kfold, test.number == 5))
summary (glm.kfold.test5)

table.kfold [41, 7] <- 1.03636
table.kfold [41, 8] <- "<0.001"
table.kfold [41, 9] <- -119.55447
table.kfold [41, 10] <- 0.12
table.kfold [41, 11] <- 0.9987

chisq.test(dplyr::filter(table.kfold, test.number == 5)$used.count, dplyr::filter(table.kfold, test.number == 5)$expected.count)
table.kfold [41, 12] <-  0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du7\\table_kfold_valid_du7.csv")

ggplot (dplyr::filter(table.kfold, test.number == 5), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 5 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 15000, by = 1000)) + 
  scale_y_continuous (breaks = seq (0, 15000, by = 1000))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du7_grp5.png")

write.csv (rsf.data.du7, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du7_preds.csv")


#--------------------------------------------------------------------------- 

################################
### Central Mountain (DU8) ###
##############################

#---------------------------------------------------------------------------

##########################
### CREATING THE DATA ###
#########################

## Pull in the previously processed GIS data
rsf.data.forestry <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_forestry.csv", header = T, sep = "")
rsf.data.veg <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_veg.csv")
rsf.data.veg <- rsf.data.veg %>% 
  filter (!is.na (bec_label))
rsf.data.forestry <- dplyr::mutate (rsf.data.forestry, distance_to_resource_road = pmin (distance_to_loose_road, 
                                                                                         distance_to_petroleum_road,
                                                                                         distance_to_rough_road,
                                                                                         distance_to_trim_transport_road,
                                                                                         distance_to_unknown_road))
rsf.data.forestry.lean <- rsf.data.forestry [, c (1:13, 20)]
rsf.data.veg.lean <- rsf.data.veg [, c (9:10)]

rsf.data.combo <- dplyr::full_join (rsf.data.forestry.lean, 
                                    rsf.data.veg.lean,
                                    by = "ptID")

rsf.data.du8 <- rsf.data.combo %>%
  dplyr::filter (du == "du8")

rm (rsf.data.forestry, rsf.data.veg, rsf.data.forestry.lean, rsf.data.veg.lean, rsf.data.combo)
gc ()

# save it
write.csv (rsf.data.du8, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du8.csv")

#####################
### EXPLORE DATA ###
###################

rsf.data.du8$pttype <- as.factor (rsf.data.du8$pttype)

## reclassify BEC and set ref category
ggplot (rsf.data.du8, aes (x = bec_label, fill = pttype)) + 
  geom_histogram (position = "dodge", stat = "count") +
  labs (title = "Histogram du8, Summer, BEC Type\
                          at Available (0) and Used (1) Locations",
        x = "Biogeclimatic Unit Type",
        y = "Count") +
  scale_fill_discrete (name = "Location Type") +
  theme (axis.text.x = element_text (angle = 45))

rsf.data.du8$bec_label_reclass <- rsf.data.du8$bec_label

rsf.data.du8$bec_label_reclass <- car::recode (rsf.data.du8$bec_label_reclass,
                                               "'SBS vk' = 'SBS'") 
rsf.data.du8$bec_label_reclass <- car::recode (rsf.data.du8$bec_label_reclass,
                                               "'SBS wk 1' = 'SBS'") 
rsf.data.du8$bec_label_reclass <- car::recode (rsf.data.du8$bec_label_reclass,
                                               "'SBS wk 2' = 'SBS'") 
rsf.data.du8 <- rsf.data.du8 %>%
  dplyr::filter (bec_label_reclass != "NA")
rsf.data.du8 <- rsf.data.du8 %>%
  dplyr::filter (bec_label_reclass != "SBPSmc")

ggplot (rsf.data.du8, aes (x = bec_label_reclass, fill = pttype)) + 
  geom_histogram (position = "dodge", stat = "count") +
  labs (title = "Histogram du8, Summer, BEC Type\
                          at Available (0) and Used (1) Locations",
        x = "Biogeclimatic Unit Type",
        y = "Count") +
  scale_fill_discrete (name = "Location Type") +
  theme (axis.text.x = element_text (angle = 45))

rsf.data.du8$bec_label_reclass <- relevel (rsf.data.du8$bec_label_reclass,
                                           ref = "ESSFmvp") # reference category

### OUTLIERS ###
ggplot (rsf.data.du8, aes (x = pttype, y = distance_to_resource_road)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot du8, Distance to Resource Roads at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Resource Road")
ggplot (rsf.data.du8, aes (x = pttype, y = distance_to_cut_1to4yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot du8, Distance to Cutblock 1 to 4 Years Old at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock 1 to 4 Years Old")
ggplot (rsf.data.du8, aes (x = pttype, y = distance_to_cut_5to9yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot du8, Distance to Cutblock 5 to 9 Years Old at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock 5 to 9 Years Old")
ggplot (rsf.data.du8, aes (x = pttype, y = distance_to_cut_10to29yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot du8, Distance to Cutblock 10 to 29 Years Old at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock 10 to 29 Years Old")
ggplot (rsf.data.du8, aes (x = pttype, y = distance_to_cut_30orOveryo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot du8, Distance to Cutblock Greater than 30 Years Old at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock Greater than 30 Years Old")
rsf.data.du8 <- rsf.data.du8 %>% # removed outlier locations really far from  (>200km) from cutblocks
  dplyr::filter (distance_to_cut_30orOveryo < 27500)

### HISTOGRAMS ###
ggplot (rsf.data.du8, aes (x = distance_to_resource_road, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 100) +
  labs (title = "Histogram du8, Distance to Resource Roads at Available (0) and Used (1) Locations",
        x = "Distance to Resource Road",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggplot (rsf.data.du8, aes (x = distance_to_cut_1to4yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 100) +
  labs (title = "Histogram du8, Distance to  Cutblock 1 to 4 Years Old at Available (0) and Used (1) Locations",
        x = "Distance to  Cutblock 1 to 4 Years Old",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggplot (rsf.data.du8, aes (x = distance_to_cut_5to9yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 100) +
  labs (title = "Histogram du8, Distance to  Cutblock 5 to 9 Years Old at Available (0) and Used (1) Locations",
        x = "Distance to  Cutblock 5 to 9 Years Old",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggplot (rsf.data.du8, aes (x = distance_to_cut_10to29yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 100) +
  labs (title = "Histogram du8, Distance to Cutblocks 10 to 29 Years Old at Available (0) and Used (1) Locations",
        x = "Distance to  Cutblocks 10 to 29 Years Old",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggplot (rsf.data.du8, aes (x = distance_to_cut_30orOveryo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 100) +
  labs (title = "Histogram du8, Distance to Cutblocks Greater than 30 Years Old at Available (0) and Used (1) Locations",
        x = "Distance to  Cutblocks Greater than 30 Years Old",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")

### CORRELATION ###
corr.rsf.data.du8 <- rsf.data.du8 [c (10:14)]
corr.rsf.data.du8 <- round (cor (corr.rsf.data.du8, method = "spearman"), 3)
ggcorrplot (corr.rsf.data.du8, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Resource Selection Function Model Covariate Correlations for du8")

# Distance to cut 5 to 9, 10 to 29 and >30 not highly correlated

### VIF 
glm.du8 <- glm (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo +
                  distance_to_cut_10to29yo + distance_to_cut_30orOveryo +
                  distance_to_resource_road + bec_label_reclass, 
                data = rsf.data.du8,
                family = binomial (link = 'logit'))
car::vif (glm.du8)

write.csv (rsf.data.du8, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du8_v2.csv")


#########################
### TRANSFORM COVARS ###
#######################

# Transform distance to covars as exponentinal function, follwoing Demars (2018)[http://www.bcogris.ca/sites/default/files/bcip-2019-01-final-report-demars-ver-2.pdf]
# decay.distance = exp (-0.002 8 distance to road)
# 0.002 = distances > 1500-m essentially have a similar and limited effect
rsf.data.du8$exp_dist_res_road <- exp ((rsf.data.du8$distance_to_resource_road * -0.002))
rsf.data.du8$exp_dist_cut_1to4 <- exp ((rsf.data.du8$distance_to_cut_1to4yo * -0.002))
rsf.data.du8$exp_dist_cut_5to9 <- exp ((rsf.data.du8$distance_to_cut_5to9yo * -0.002))
rsf.data.du8$exp_dist_cut_10to29 <- exp ((rsf.data.du8$distance_to_cut_10to29yo * -0.002))
rsf.data.du8$exp_dist_cut_30 <- exp ((rsf.data.du8$distance_to_cut_30orOveryo * -0.002))

### Standardize the data (helps with model convergence) ###
rsf.data.du8$std_exp_dist_res_road <- (rsf.data.du8$exp_dist_res_road - 
                                         mean (rsf.data.du8$exp_dist_res_road)) / 
                                         sd (rsf.data.du8$exp_dist_res_road)
rsf.data.du8$std_exp_dist_cut_1to4 <- (rsf.data.du8$exp_dist_cut_1to4 - 
                                         mean (rsf.data.du8$exp_dist_cut_1to4)) / 
                                         sd (rsf.data.du8$exp_dist_cut_1to4)
rsf.data.du8$std_exp_dist_cut_5to9 <- (rsf.data.du8$exp_dist_cut_5to9 - 
                                         mean (rsf.data.du8$exp_dist_cut_5to9)) / 
                                         sd (rsf.data.du8$exp_dist_cut_5to9)
rsf.data.du8$std_exp_dist_cut_10to29 <- (rsf.data.du8$exp_dist_cut_10to29 - 
                                         mean (rsf.data.du8$exp_dist_cut_10to29)) / 
                                         sd (rsf.data.du8$exp_dist_cut_10to29)
rsf.data.du8$std_exp_dist_cut_30 <- (rsf.data.du8$exp_dist_cut_30 - 
                                      mean (rsf.data.du8$exp_dist_cut_30)) / 
                                      sd (rsf.data.du8$exp_dist_cut_30)

### Functional Response Covariates ###
#### Calc mean available distance to road and cutblock in home range, by unique individual
avail.rsf.data.du8 <- subset (rsf.data.du8, pttype == 0)

std_exp_dist_res_road_E <- tapply (avail.rsf.data.du8$std_exp_dist_res_road, avail.rsf.data.du8$animal_id, mean)
std_exp_dist_cut_1to4_E <- tapply (avail.rsf.data.du8$std_exp_dist_cut_1to4, avail.rsf.data.du8$animal_id, mean)
std_exp_dist_cut_5to9_E <- tapply (avail.rsf.data.du8$std_exp_dist_cut_5to9, avail.rsf.data.du8$animal_id, mean)
std_exp_dist_cut_10to29_E <- tapply (avail.rsf.data.du8$std_exp_dist_cut_10to29, avail.rsf.data.du8$animal_id, mean)
std_exp_dist_cut_30_E <- tapply (avail.rsf.data.du8$std_exp_dist_cut_30, avail.rsf.data.du8$animal_id, mean)

inds <- as.character (rsf.data.du8$animal_id)
rsf.data.du8 <- cbind (rsf.data.du8, "dist_rd_E" = std_exp_dist_res_road_E[inds], 
                       "dist_cut_1to4_E" = std_exp_dist_cut_1to4_E[inds],
                       "dist_cut_5to9_E" = std_exp_dist_cut_5to9_E[inds],
                       "dist_cut_10to29_E" = std_exp_dist_cut_10to29_E[inds],
                       "dist_cut_30_E" = std_exp_dist_cut_30_E[inds])

# to simplify available cutblock effect; interact with distance to any cutblock age
rsf.data.du8$dist_cut_min_all <- pmin (rsf.data.du8$distance_to_cut_1to4,
                                       rsf.data.du8$distance_to_cut_5to9yo,
                                       rsf.data.du8$distance_to_cut_10to29yo,
                                       rsf.data.du8$distance_to_cut_30orOveryo)
rsf.data.du8$exp_dist_cut_min <- exp ((rsf.data.du8$dist_cut_min_all * -0.002))
rsf.data.du8$std_exp_dist_cut_min <- (rsf.data.du8$exp_dist_cut_min - 
                                        mean (rsf.data.du8$exp_dist_cut_min)) / 
  sd (rsf.data.du8$exp_dist_cut_min)
avail.rsf.data.du8 <- subset (rsf.data.du8, pttype == 0)
std_exp_dist_cut_min_E <- tapply (avail.rsf.data.du8$std_exp_dist_cut_min, avail.rsf.data.du8$animal_id, mean)
rsf.data.du8 <- cbind (rsf.data.du8, "dist_cut_min_E" = std_exp_dist_cut_min_E[inds])

###################
### FIT MODELS ###
#################

### Generalized Linear Mixed Models (GLMMs) ###
#### First, determine the random effects structure

# Individual animal
model.lme4.du8.animal <- glmer (pttype ~ 1 + (1 | animal_id), # random effect for animal
                                data = rsf.data.du8, 
                                family = binomial (link = "logit"),
                                verbose = T) 

#### Season
model.lme4.du8.season <- glmer (pttype ~ 1 + (1 | season), # random effect for season
                                data = rsf.data.du8, 
                                family = binomial (link = "logit"),
                                verbose = T) 
ss <- getME (model.lme4.du8.season, c ("theta","fixef")) # did not converge after 5x
model.lme4.du8.animal <- update (model.lme4.du8.season, start = ss, control = glmerControl (optCtrl = list (maxfun=2e4)))

#### Individual animal and Season
model.lme4.du8.anim.seas <- glmer (pttype ~ 1 + (1 | animal_id) + (1 | season), # random effect intercepts for individual and season
                                   data = rsf.data.du8, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 

# Compare models 
anova (model.lme4.du8.animal, model.lme4.du8.season, model.lme4.du8.anim.seas)

# animal and season model had best fit; use both


#### Second, determine the fixed effects structure
### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 5, nrow = 0))
colnames (table.aic) <- c ("DU", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

#### BEC only model
model.lme4.du8.bec <- glmer (pttype ~ bec_label_reclass + (1 | animal_id) + (1 | season), 
                             data = rsf.data.du8, 
                             family = binomial (link = "logit"),
                             verbose = T) 
# AIC
table.aic [1, 1] <- "du8"
table.aic [1, 2] <- "BEC variant"
table.aic [1, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [1, 4] <-  AIC (model.lme4.du8.bec)

# Dist Road model
model.lme4.du8.road <- glmer (pttype ~ std_exp_dist_res_road + (1 | animal_id) + (1 | season),
                              data = rsf.data.du8, 
                              family = binomial (link = "logit"),
                              verbose = T) 
# AIC
table.aic [2, 1] <- "du8"
table.aic [2, 2] <- "Distance to Resource Road"
table.aic [2, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [2, 4] <-  AIC (model.lme4.du8.road)

# Dist Cut model
model.lme4.du8.cut <- glmer (pttype ~ std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + 
                               std_exp_dist_cut_10to29 + std_exp_dist_cut_30 +
                               (1 | animal_id) + (1 | season),
                             data = rsf.data.du8, 
                             family = binomial (link = "logit"),
                             verbose = T) 
# AIC
table.aic [3, 1] <- "du8"
table.aic [3, 2] <- "Distance to Cutblock"
table.aic [3, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [3, 4] <-  AIC (model.lme4.du8.cut)

# Dist Road and Cut model
model.lme4.du8.rd.cut <- glmer (pttype ~ std_exp_dist_res_road + std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + 
                                  std_exp_dist_cut_10to29 + std_exp_dist_cut_30 + (1 | animal_id) + (1 | season),
                                data = rsf.data.du8, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [4, 1] <- "du8"
table.aic [4, 2] <- "Distance to Resource Road + Distance to Cutblock"
table.aic [4, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [4, 4] <-  AIC (model.lme4.du8.rd.cut)

# Dist Road Fxn Response
model.lme4.du8.rd.fxn <- glmer (pttype ~ std_exp_dist_res_road + dist_rd_E + std_exp_dist_res_road*dist_rd_E + (1 | animal_id) + (1 | season),
                                data = rsf.data.du8, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [5, 1] <- "du8"
table.aic [5, 2] <- "Distance to Resource Road + Available Distance to Resource Road + Distance to Resource Road*Available Distance to Resource Road"
table.aic [5, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [5, 4] <-  AIC (model.lme4.du8.rd.fxn)

scatter3D (rsf.data.du8$distance_to_resource_road, # pretty clear functional response; selection for roads in low road areas and inverse in high road areas
           rsf.data.du8$dist_rd_E,
           (predict (model.lme4.du8.rd.fxn,
                     newdata = rsf.data.du8, 
                     re.form = NA, type = "response")), 
           xlab = "Dist. Road",
           ylab = "Avail. Dist Road", 
           zlab = "Selection",
           theta = 15, phi = 20)

# Dist Cut Fxn Response
model.lme4.du8.cut.fxn <- glmer (pttype ~ std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + 
                                   std_exp_dist_cut_10to29 + std_exp_dist_cut_30 + 
                                   dist_cut_min_E + std_exp_dist_cut_1to4*dist_cut_min_E + 
                                   std_exp_dist_cut_5to9*dist_cut_min_E + 
                                   std_exp_dist_cut_10to29*dist_cut_min_E +
                                   std_exp_dist_cut_30*dist_cut_min_E +
                                   (1 | animal_id) + (1 | season),
                                 data = rsf.data.du8, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [6, 1] <- "du8"
table.aic [6, 2] <- "Distance to Cutblock + Available Distance to Cutblock + Distance to Cutblock*Available Distance to Cutblock"
table.aic [6, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [6, 4] <-  AIC (model.lme4.du8.cut.fxn)

scatter3D (rsf.data.du8$distance_to_cut_30orOveryo, # a bit scattered, but general pattern is avoidance at low and high densities of cut
           rsf.data.du8$dist_cut_min_E,
           (predict (model.lme4.du8.cut.fxn,
                     newdata = rsf.data.du8, 
                     re.form = NA, type = "response")), 
           xlab = "Dist. Cut 1to4",
           ylab = "Avail. Dist Cut", 
           zlab = "Selection",
           theta = 15, phi = 20)

# BEC, Dist Road and Cut model
model.lme4.du8.all <- glmer (pttype ~ bec_label_reclass + std_exp_dist_res_road + 
                               std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + 
                               std_exp_dist_cut_10to29 + std_exp_dist_cut_30 + (1 | animal_id) + (1 | season),
                             data = rsf.data.du8, 
                             family = binomial (link = "logit"),
                             verbose = T) 
# AIC
table.aic [7, 1] <- "du8"
table.aic [7, 2] <- "BEC + Distance to Resource Road + Distance to Cutblock"
table.aic [7, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [7, 4] <-  AIC (model.lme4.du8.all)

# BEC, Dist Road (fxn) and Cut model
model.lme4.du8.all.rd.fxn <- glmer (pttype ~ bec_label_reclass + std_exp_dist_res_road + 
                                      std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + 
                                      std_exp_dist_cut_10to29 + std_exp_dist_cut_30 + 
                                      dist_rd_E + std_exp_dist_res_road*dist_rd_E + 
                                      (1 | animal_id) + (1 | season),
                                    data = rsf.data.du8, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [8, 1] <- "du8"
table.aic [8, 2] <- "BEC + Distance to Resource Road + Distance to Cutblock + Available Distance to Resource Road + Distance to Resource Road*Available Distance to Resource Road"
table.aic [8, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [8, 4] <-  AIC (model.lme4.du8.all.rd.fxn)

scatter3D (x = rsf.data.du8$distance_to_resource_road, # weird pattern where selection doesn't seem to vary by availability
           y = rsf.data.du8$exp_dist_res_road, 
           z = (predict (model.lme4.du8.all.rd.fxn,
                         newdata = rsf.data.du8, 
                         re.form = NA, type = "response")),
           xlab = "Dist. Road",
           ylab = "Avail. Dist Road", 
           zlab = "Selection",
           theta = 15, phi = 20)

# BEC, Dist Road and Cut model (fxn)
model.lme4.du8.all.cut.fxn <- glmer (pttype ~ bec_label_reclass + std_exp_dist_res_road + 
                                       std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + 
                                       std_exp_dist_cut_10to29 + std_exp_dist_cut_30 + 
                                       dist_cut_min_E + std_exp_dist_cut_1to4*dist_cut_min_E + 
                                       std_exp_dist_cut_5to9*dist_cut_min_E + 
                                       std_exp_dist_cut_10to29*dist_cut_min_E +
                                       std_exp_dist_cut_30*dist_cut_min_E + (1 | animal_id) + (1 | season),
                                     data = rsf.data.du8, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [9, 1] <- "du8"
table.aic [9, 2] <- "BEC + Distance to Resource Road + Distance to Cutblock + Available Distance to Cutblock + Distance to Cutblock*Available Distance to Cutblock"
table.aic [9, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [9, 4] <-  AIC (model.lme4.du8.all.cut.fxn)

scatter3D (x = rsf.data.du8$distance_to_cut_10to29yo, # scatter shot
           y = rsf.data.du8$dist_cut_min_E, 
           z = (predict (model.lme4.du8.all.cut.fxn,
                         newdata = rsf.data.du8, 
                         re.form = NA, type = "response")),
           xlab = "Dist. Cut 1 to 4",
           ylab = "Avail. Dist Cut", 
           zlab = "Selection",
           theta = 15, phi = 20)

## AIC comparison of MODELS ## 
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 4] - min (table.aic [1:9, 4])))), 
                    (exp (-0.5 * (table.aic [2, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [3, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [4, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [5, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [6, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [7, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [8, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [9, 4] - min (table.aic [1:9, 4])))))
table.aic [1, 5] <- round ((exp (-0.5 * (table.aic [1, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [2, 5] <- round ((exp (-0.5 * (table.aic [2, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [3, 5] <- round ((exp (-0.5 * (table.aic [3, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [4, 5] <- round ((exp (-0.5 * (table.aic [4, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [5, 5] <- round ((exp (-0.5 * (table.aic [5, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [6, 5] <- round ((exp (-0.5 * (table.aic [6, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [7, 5] <- round ((exp (-0.5 * (table.aic [7, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [8, 5] <- round ((exp (-0.5 * (table.aic [8, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [9, 5] <- round ((exp (-0.5 * (table.aic [9, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_du8_v2.csv", sep = ",")

# used model without functional response because didn't appear to improve interpretation of model, 
# on its own, road interatction caovraite showed fucntional response, but didn;t hold up when includign other
# terms, so go without for now

# save the top model
save (model.lme4.du8.all, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_du8_top_v2.rda")

###################
### SAVE MODEL ###
#################

# Create table of model coefficients from top model
model.coeffs <- as.data.frame (coef (summary (model.lme4.du8.all)))
model.coeffs$mean_exp_neg0002 <- 0
model.coeffs$sd_exp_neg0002 <- 0

model.coeffs [10, 5] <- mean (exp ((rsf.data.du8$distance_to_resource_road * -0.002)))
model.coeffs [11, 5] <- mean (exp ((rsf.data.du8$distance_to_cut_1to4yo * -0.002)))
model.coeffs [12, 5] <- mean (exp ((rsf.data.du8$distance_to_cut_5to9yo * -0.002)))
model.coeffs [13, 5] <- mean (exp ((rsf.data.du8$distance_to_cut_10to29yo * -0.002)))
model.coeffs [14, 5] <- mean (exp ((rsf.data.du8$distance_to_cut_30orOveryo * -0.002)))

model.coeffs [10, 6] <- sd (exp ((rsf.data.du8$distance_to_resource_road * -0.002)))
model.coeffs [11, 6] <- sd (exp ((rsf.data.du8$distance_to_cut_1to4yo * -0.002)))
model.coeffs [12, 6] <- sd (exp ((rsf.data.du8$distance_to_cut_5to9yo * -0.002)))
model.coeffs [13, 6] <- sd (exp ((rsf.data.du8$distance_to_cut_10to29yo * -0.002)))
model.coeffs [14, 6] <- sd (exp ((rsf.data.du8$distance_to_cut_30orOveryo * -0.002)))

write.table (model.coeffs, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\model_coefficients\\table_du8_summ_model_coeffs_top.csv", sep = ",")

###############################
### RSF RASTER CALCULATION ###
#############################

### LOAD RASTERS ###
bec.bafa.un <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_bafa_un.tif")
bec.bwbs.mw <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_bwbs_mw.tif")
bec.bwbs.wk1 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_bwbs_wk1.tif")
bec.essf.mv2 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_mv2.tif")
bec.essf.wc3 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_wc3.tif")
bec.essf.wcp <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_wcp.tif")
bec.essf.wk2 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_wk2.tif")
bec.sbs <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_sbs.tif")
dist.cut.1to4 <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_1to4yo.tif")
dist.cut.5to9 <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_5to9yo.tif")
dist.cut.10to29 <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_10to29yo.tif")
dist.cut.30 <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_30yo_over.tif")
dist.resource.rd <- raster ("C:\\Work\\caribou\\clus_data\\roads_ha_bc\\dist_crds_resource.tif")

### Adjust the raster data for 'standardized' model covariates ###
std.dist.resource.rd <- (exp (dist.resource.rd * -0.002) - 0.2640364) / 0.3216345
std.dist.cut.1to4 <- (exp (dist.cut.1to4 * -0.002) - 0.008833636) / 0.06770627
std.dist.cut.5to9 <- (exp (dist.cut.5to9 * -0.002) - 0.02159883) / 0.1068735
std.dist.cut.10to29 <- (exp (dist.cut.10to29 * -0.002) - 0.07308026) / 0.1821456
std.dist.cut.30 <- (exp (dist.cut.30 * -0.002) -  0.01283987) / 0.06634038

### CALCULATE RASTER RSF ###
raster.rsf <- (exp (-1.73 + (bec.bafa.un * 0.87) + (bec.bwbs.mw * -0.14) +
                            (bec.bwbs.wk1 * -0.11) + (bec.essf.mv2 * -0.29) + 
                            (bec.essf.wc3 * -0.21) + (bec.essf.wcp * -0.10) +
                            (bec.essf.wk2 * -0.80) + (bec.sbs * 0.08) +
                            (std.dist.resource.rd * -0.06) +
                            (std.dist.cut.1to4 * 	-0.04) + 
                            (std.dist.cut.5to9 * 0.02) +
                            (std.dist.cut.10to29 * 0.04) +
                            (std.dist.cut.30 * -0.08))) / 
  (1 + exp (-1.73 + (bec.bafa.un * 0.87) + (bec.bwbs.mw * -0.14) +
              (bec.bwbs.wk1 * -0.11) + (bec.essf.mv2 * -0.29) + 
              (bec.essf.wc3 * -0.21) + (bec.essf.wcp * -0.10) +
              (bec.essf.wk2 * -0.80) + (bec.sbs * 0.08) +
              (std.dist.resource.rd * -0.06) +
              (std.dist.cut.1to4 * 	-0.04) + 
              (std.dist.cut.5to9 * 0.02) +
              (std.dist.cut.10to29 * 0.04) +
              (std.dist.cut.30 * -0.08)))

plot (raster.rsf)

writeRaster (raster.rsf, "C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du8\\rsf_du8_v2.tif", 
             format = "GTiff", overwrite = T)

##########################
### k-fold Validation ###
########################
df.animal.id <- as.data.frame (unique (rsf.data.du8$animal_id))
names (df.animal.id) [1] <-"animal_id"
df.animal.id$group <- rep_len (1:5, nrow (df.animal.id)) # orderly selection of groups
rsf.data.du8 <- dplyr::full_join (rsf.data.du8, df.animal.id, by = "animal_id")

### FOLD 1 ###
train.data.1 <- rsf.data.du8 %>%
  filter (group < 5)
test.data.1 <- rsf.data.du8 %>%
  filter (group == 5)

model.lme4.du8train1 <- glmer (pttype ~ bec_label_reclass + 
                                 std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + 
                                 std_exp_dist_cut_5to9 + 
                                 std_exp_dist_cut_10to29 +
                                 std_exp_dist_cut_30 +
                                 (1 | animal_id) + (1 | season), 
                               data = train.data.1, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# create a table of k-fold outputs
table.kfold <- data.frame (matrix (ncol = 12, nrow = 50))
colnames (table.kfold) <- c ("test.number", "bin.mid", "bin.weight", "utilization", "used.count", 
                             "expected.count", "lm.slope", "lm.slope.p.value", "lm.intercept",
                             "lm.intercept.p.value", "adj.R.sq", "chi.sq.p.value")
table.kfold [c (1:10), 1] <- 1
table.kfold$bin.mid <- c (0.0165, 0.0495, 0.0825, 0.1155, 0.1485, 0.1815, 0.2145, 0.2475, 0.2805, 0.3135)

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du8$preds.train1 <- predict (model.lme4.du8train1, 
                                      newdata = rsf.data.du8, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du8, aes (preds.train1)) +
  geom_histogram()
max (rsf.data.du8$preds.train1)
min (rsf.data.du8$preds.train1)

rsf.data.du8$preds.train1.class <- cut (rsf.data.du8$preds.train1, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.033, 0.066, 0.099, 0.132, 0.165, 0.198, 0.231, 0.264, 0.297, Inf), 
                                        labels = c ("0.0165", "0.0495", "0.0825", "0.1155", "0.1485",
                                                    "0.1815", "0.2145", "0.2475", "0.2805", "0.3135"))
rsf.data.du8.avail <- dplyr::filter (rsf.data.du8, pttype == 0)

table.kfold [1, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train1.class == "0.0165")) * 0.0165) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [2, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train1.class == "0.0495")) * 0.0495)
table.kfold [3, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train1.class == "0.0825")) * 0.0825)
table.kfold [4, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train1.class == "0.1155")) * 0.1155)
table.kfold [5, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train1.class == "0.1485")) * 0.1485)
table.kfold [6, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train1.class == "0.1815")) * 0.1815)
table.kfold [7, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train1.class == "0.2145")) * 0.2145)
table.kfold [8, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train1.class == "0.2475")) * 0.2475)
table.kfold [9, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train1.class == "0.2805")) * 0.2805)
table.kfold [10, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train1.class == "0.3135")) * 0.3135)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\table_kfold_valid_du8.csv")

# data for estimating use
test.data.1$preds <- predict (model.lme4.du8train1, newdata = test.data.1, re.form = NA, type = "response")
test.data.1$preds.class <- cut (test.data.1$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.033, 0.066, 0.099, 0.132, 0.165, 0.198, 0.231, 0.264, 0.297, Inf), 
                                labels = c ("0.0165", "0.0495", "0.0825", "0.1155", "0.1485",
                                            "0.1815", "0.2145", "0.2475", "0.2805", "0.3135"))
write.csv (test.data.1, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\rsf_preds_du8_train1.csv")
test.data.1.used <- dplyr::filter (test.data.1, pttype == 1)

table.kfold [1, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.0165"))
table.kfold [2, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.0495"))
table.kfold [3, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.0825"))
table.kfold [4, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.1155"))
table.kfold [5, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.1485"))
table.kfold [6, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.1815"))
table.kfold [7, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.2145"))
table.kfold [8, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.2475"))
table.kfold [9, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.2805"))
table.kfold [10, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.3135"))

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

table.kfold [1, 7] <- 0.9740
table.kfold [1, 8] <- "<0.001"
table.kfold [1, 9] <- 71.7651
table.kfold [1, 10] <- 0.872
table.kfold [1, 11] <- 0.9183 

chisq.test(dplyr::filter(table.kfold, test.number == 1)$used.count, dplyr::filter(table.kfold, test.number == 1)$expected.count)
table.kfold [1, 12] <-  0.2424

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\table_kfold_valid_du8.csv")


ggplot (dplyr::filter(table.kfold, test.number == 1), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 1 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 20000, by = 1000)) + 
  scale_y_continuous (breaks = seq (0, 20000, by = 1000))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du8_grp1.png")

write.csv (rsf.data.du8, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du8_preds.csv")

### FOLD 2 ###
train.data.2 <- rsf.data.du8 %>%
  filter (group == 1 | group == 2 | group == 3 | group == 5)
test.data.2 <- rsf.data.du8 %>%
  filter (group == 4)

model.lme4.du8train2 <- glmer (pttype ~ bec_label_reclass + 
                                 std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + 
                                 std_exp_dist_cut_5to9 + 
                                 std_exp_dist_cut_10to29 +
                                 std_exp_dist_cut_30 + 
                                 (1 | animal_id) + (1 | season), 
                               data = train.data.2, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du8$preds.train2 <- predict (model.lme4.du8train2, 
                                      newdata = rsf.data.du8, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du8, aes (preds.train2)) +
  geom_histogram()
max (rsf.data.du8$preds.train2)
min (rsf.data.du8$preds.train2)

rsf.data.du8$preds.train2.class <- cut (rsf.data.du8$preds.train2, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.033, 0.066, 0.099, 0.132, 0.165, 0.198, 0.231, 0.264, 0.297, Inf), 
                                        labels = c ("0.0165", "0.0495", "0.0825", "0.1155", "0.1485",
                                                    "0.1815", "0.2145", "0.2475", "0.2805", "0.3135"))
table.kfold [c (11:20), 1] <- 2

rsf.data.du8.avail <- dplyr::filter (rsf.data.du8, pttype == 0)

table.kfold [11, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train2.class == "0.0165")) * 0.0165) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [12, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train2.class == "0.0495")) * 0.0495)
table.kfold [13, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train2.class == "0.0825")) * 0.0825)
table.kfold [14, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train2.class == "0.1155")) * 0.1155)
table.kfold [15, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train2.class == "0.1485")) * 0.1485)
table.kfold [16, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train2.class == "0.1815")) * 0.1815)
table.kfold [17, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train2.class == "0.2145")) * 0.2145)
table.kfold [18, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train2.class == "0.2475")) * 0.2475)
table.kfold [19, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train2.class == "0.2805")) * 0.2805)
table.kfold [20, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train2.class == "0.3135")) * 0.3135)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\table_kfold_valid_du8.csv")

# data for estimating use
test.data.2$preds <- predict (model.lme4.du8train2, newdata = test.data.2, re.form = NA, type = "response")
test.data.2$preds.class <- cut (test.data.2$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.033, 0.066, 0.099, 0.132, 0.165, 0.198, 0.231, 0.264, 0.297, Inf), 
                                labels = c ("0.0165", "0.0495", "0.0825", "0.1155", "0.1485",
                                            "0.1815", "0.2145", "0.2475", "0.2805", "0.3135"))
write.csv (test.data.2, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\rsf_preds_du8_train2.csv")
test.data.2.used <- dplyr::filter (test.data.2, pttype == 1)

table.kfold [11, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.0165"))
table.kfold [12, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.0495"))
table.kfold [13, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.0825"))
table.kfold [14, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.1155"))
table.kfold [15, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.1485"))
table.kfold [16, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.1815"))
table.kfold [17, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.2145"))
table.kfold [18, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.2475"))
table.kfold [19, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.2805"))
table.kfold [20, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.3135"))

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
                       data = dplyr::filter(table.kfold, test.number == 2))
summary (glm.kfold.test2)

table.kfold [11, 7] <- 0.96563
table.kfold [11, 8] <- "<0.001"
table.kfold [11, 9] <- 101.18977
table.kfold [11, 10] <- 0.39
table.kfold [11, 11] <- 0.9944

chisq.test(dplyr::filter(table.kfold, test.number == 2)$used.count, dplyr::filter(table.kfold, test.number == 2)$expected.count)
table.kfold [11, 12] <-  0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\table_kfold_valid_du8.csv")

ggplot (dplyr::filter(table.kfold, test.number == 2), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 2 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 20000, by = 1000)) + 
  scale_y_continuous (breaks = seq (0, 20000, by = 1000))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du8_grp2.png")

write.csv (rsf.data.du8, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du8_preds.csv")

### FOLD 3 ###
train.data.3 <- rsf.data.du8 %>%
  filter (group == 1 | group == 2 | group == 4 | group == 5)
test.data.3 <- rsf.data.du8 %>%
  filter (group == 3)

model.lme4.du8train3 <- glmer (pttype ~ bec_label_reclass + 
                                 std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + 
                                 std_exp_dist_cut_5to9 + 
                                 std_exp_dist_cut_10to29 +
                                 std_exp_dist_cut_30 + 
                                 (1 | animal_id) + (1 | season), 
                               data = train.data.3, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du8$preds.train3 <- predict (model.lme4.du8train3, 
                                      newdata = rsf.data.du8, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du8, aes (preds.train3)) +
  geom_histogram()
max (rsf.data.du8$preds.train3)
min (rsf.data.du8$preds.train3)

rsf.data.du8$preds.train3.class <- cut (rsf.data.du8$preds.train3, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.033, 0.066, 0.099, 0.132, 0.165, 0.198, 0.231, 0.264, 0.297, Inf), 
                                        labels = c ("0.0165", "0.0495", "0.0825", "0.1155", "0.1485",
                                                    "0.1815", "0.2145", "0.2475", "0.2805", "0.3135"))
table.kfold [c (21:30), 1] <- 3

rsf.data.du8.avail <- dplyr::filter (rsf.data.du8, pttype == 0)

table.kfold [21, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train3.class == "0.0165")) * 0.0165) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [22, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train3.class == "0.0495")) * 0.0495)
table.kfold [23, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train3.class == "0.0825")) * 0.0825)
table.kfold [24, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train3.class == "0.1155")) * 0.1155)
table.kfold [25, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train3.class == "0.1485")) * 0.1485)
table.kfold [26, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train3.class == "0.1815")) * 0.1815)
table.kfold [27, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train3.class == "0.2145")) * 0.2145)
table.kfold [28, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train3.class == "0.2475")) * 0.2475)
table.kfold [29, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train3.class == "0.2805")) * 0.2805)
table.kfold [30, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train3.class == "0.3135")) * 0.3135)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\table_kfold_valid_du8.csv")

# data for estimating use
test.data.3$preds <- predict (model.lme4.du8train3, newdata = test.data.3, re.form = NA, type = "response")
test.data.3$preds.class <- cut (test.data.3$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.033, 0.066, 0.099, 0.132, 0.165, 0.198, 0.231, 0.264, 0.297, Inf), 
                                labels = c ("0.0165", "0.0495", "0.0825", "0.1155", "0.1485",
                                            "0.1815", "0.2145", "0.2475", "0.2805", "0.3135"))
write.csv (test.data.3, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\rsf_preds_du8_train3.csv")
test.data.3.used <- dplyr::filter (test.data.3, pttype == 1)

table.kfold [21, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.0165"))
table.kfold [22, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.0495"))
table.kfold [23, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.0825"))
table.kfold [24, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.1155"))
table.kfold [25, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.1485"))
table.kfold [26, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.1815"))
table.kfold [27, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.2145"))
table.kfold [28, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.2475"))
table.kfold [29, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.2805"))
table.kfold [30, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.3135"))

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
                       data = dplyr::filter(table.kfold, test.number == 3))
summary (glm.kfold.test3)

table.kfold [21, 7] <- 0.99592 
table.kfold [21, 8] <- "<0.001"
table.kfold [21, 9] <- 10.15575
table.kfold [21, 10] <- 0.968
table.kfold [21, 11] <- 0.9695 

chisq.test(dplyr::filter(table.kfold, test.number == 3)$used.count, dplyr::filter(table.kfold, test.number == 3)$expected.count)
table.kfold [21, 12] <-  0.09884

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\table_kfold_valid_du8.csv")

ggplot (dplyr::filter(table.kfold, test.number == 3), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 3 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 20000, by = 1000)) + 
  scale_y_continuous (breaks = seq (0, 20000, by = 1000))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du8_grp3.png")

write.csv (rsf.data.du8, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du8_preds.csv")

### FOLD 4 ###
train.data.4 <- rsf.data.du8 %>%
  filter (group == 1 | group == 3 | group == 4 | group == 5)
test.data.4 <- rsf.data.du8 %>%
  filter (group == 2)

model.lme4.du8train4 <- glmer (pttype ~ bec_label_reclass + 
                                 std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + 
                                 std_exp_dist_cut_5to9 + 
                                 std_exp_dist_cut_10to29 +
                                 std_exp_dist_cut_30 + 
                                 (1 | animal_id) + (1 | season), 
                               data = train.data.4, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du8$preds.train4 <- predict (model.lme4.du8train4, 
                                      newdata = rsf.data.du8, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du8, aes (preds.train4)) +
  geom_histogram()
max (rsf.data.du8$preds.train4)
min (rsf.data.du8$preds.train4)

rsf.data.du8$preds.train4.class <- cut (rsf.data.du8$preds.train4, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.033, 0.066, 0.099, 0.132, 0.165, 0.198, 0.231, 0.264, 0.297, Inf), 
                                        labels = c ("0.0165", "0.0495", "0.0825", "0.1155", "0.1485",
                                                    "0.1815", "0.2145", "0.2475", "0.2805", "0.3135"))
table.kfold [c (31:40), 1] <- 4

rsf.data.du8.avail <- dplyr::filter (rsf.data.du8, pttype == 0)

table.kfold [31, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train4.class == "0.0165")) * 0.0165) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [32, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train4.class == "0.0495")) * 0.0495)
table.kfold [33, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train4.class == "0.0825")) * 0.0825)
table.kfold [34, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train4.class == "0.1155")) * 0.1155)
table.kfold [35, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train4.class == "0.1485")) * 0.1485)
table.kfold [36, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train4.class == "0.1815")) * 0.1815)
table.kfold [37, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train4.class == "0.2145")) * 0.2145)
table.kfold [38, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train4.class == "0.2475")) * 0.2475)
table.kfold [39, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train4.class == "0.2805")) * 0.2805)
table.kfold [40, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train4.class == "0.3135")) * 0.3135)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\table_kfold_valid_du8.csv")

# data for estimating use
test.data.4$preds <- predict (model.lme4.du8train4, newdata = test.data.4, re.form = NA, type = "response")
test.data.4$preds.class <- cut (test.data.4$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.033, 0.066, 0.099, 0.132, 0.165, 0.198, 0.231, 0.264, 0.297, Inf), 
                                labels = c ("0.0165", "0.0495", "0.0825", "0.1155", "0.1485",
                                            "0.1815", "0.2145", "0.2475", "0.2805", "0.3135"))
table.kfold [c (31:40), 1] <- 4
write.csv (test.data.4, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\rsf_preds_du8_train4.csv")
test.data.4.used <- dplyr::filter (test.data.4, pttype == 1)

table.kfold [31, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.0165"))
table.kfold [32, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.0495"))
table.kfold [33, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.0825"))
table.kfold [34, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.1155"))
table.kfold [35, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.1485"))
table.kfold [36, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.1815"))
table.kfold [37, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.2145"))
table.kfold [38, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.2475"))
table.kfold [39, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.2805"))
table.kfold [40, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.3135"))

table.kfold [31, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [31, 4], 0) # expected number of uses in each bin
table.kfold [32, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [32, 4], 0) # expected number of uses in each bin
table.kfold [33, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [33, 4], 0) # expected number of uses in each bin
table.kfold [34, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [34, 4], 0) # expected number of uses in each bin
table.kfold [35, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [35, 4], 0) # expected number of uses in each bin
table.kfold [36, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [36, 4], 0) # expected number of uses in each bin
table.kfold [37, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [37, 4], 0) # expected number of uses in each bin
table.kfold [38, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [38, 4], 0) # expected number of uses in each bin
table.kfold [39, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [39, 4], 0) # expected number of uses in each bin
table.kfold [40, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [40, 4], 0) # expected number of uses in each bin

glm.kfold.test4 <- lm (used.count ~ expected.count, 
                       data = dplyr::filter(table.kfold, test.number == 4))
summary (glm.kfold.test4)

table.kfold [31, 7] <- 1.02302
table.kfold [31, 8] <- "<0.001"
table.kfold [31, 9] <- -61.63044
table.kfold [31, 10] <- 0.633
table.kfold [31, 11] <- 0.9954

chisq.test(dplyr::filter(table.kfold, test.number == 4)$used.count, dplyr::filter(table.kfold, test.number == 4)$expected.count)
table.kfold [31, 12] <-  0.2424

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\table_kfold_valid_du8.csv")

ggplot (dplyr::filter(table.kfold, test.number == 4), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 4 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 20000, by = 1000)) + 
  scale_y_continuous (breaks = seq (0, 20000, by = 1000))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du8_grp4.png")

write.csv (rsf.data.du8, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du8_preds.csv")

### FOLD 5 ###
train.data.5 <- rsf.data.du8 %>%
  filter (group == 5 | group == 2 | group == 3 | group == 4)
test.data.5 <- rsf.data.du8 %>%
  filter (group == 1)

model.lme4.du8train5 <- glmer (pttype ~ bec_label_reclass + 
                                 std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + 
                                 std_exp_dist_cut_5to9 + 
                                 std_exp_dist_cut_10to29 +
                                 std_exp_dist_cut_30 + 
                                 (1 | animal_id) + (1 | season), 
                               data = train.data.5, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du8$preds.train5 <- predict (model.lme4.du8train5, 
                                      newdata = rsf.data.du8, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du8, aes (preds.train5)) +
  geom_histogram()
max (rsf.data.du8$preds.train5)
min (rsf.data.du8$preds.train5)

rsf.data.du8$preds.train5.class <- cut (rsf.data.du8$preds.train5, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.033, 0.066, 0.099, 0.132, 0.165, 0.198, 0.231, 0.264, 0.297, Inf), 
                                        labels = c ("0.0165", "0.0495", "0.0825", "0.1155", "0.1485",
                                                    "0.1815", "0.2145", "0.2475", "0.2805", "0.3135"))
table.kfold [c (41:50), 1] <- 5

rsf.data.du8.avail <- dplyr::filter (rsf.data.du8, pttype == 0)

table.kfold [41, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train5.class == "0.0165")) * 0.0165) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [42, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train5.class == "0.0495")) * 0.0495)
table.kfold [43, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train5.class == "0.0825")) * 0.0825)
table.kfold [44, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train5.class == "0.1155")) * 0.1155)
table.kfold [45, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train5.class == "0.1485")) * 0.1485)
table.kfold [46, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train5.class == "0.1815")) * 0.1815)
table.kfold [47, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train5.class == "0.2145")) * 0.2145)
table.kfold [48, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train5.class == "0.2475")) * 0.2475)
table.kfold [49, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train5.class == "0.2805")) * 0.2805)
table.kfold [50, 3] <- (nrow (dplyr::filter (rsf.data.du8.avail, preds.train5.class == "0.3135")) * 0.3135)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\table_kfold_valid_du8.csv")

# data for estimating use
test.data.5$preds <- predict (model.lme4.du8train5, newdata = test.data.5, re.form = NA, type = "response")
test.data.5$preds.class <- cut (test.data.5$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.033, 0.066, 0.099, 0.132, 0.165, 0.198, 0.231, 0.264, 0.297, Inf), 
                                labels = c ("0.0165", "0.0495", "0.0825", "0.1155", "0.1485",
                                            "0.1815", "0.2145", "0.2475", "0.2805", "0.3135"))
write.csv (test.data.5, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\rsf_preds_du8_train5.csv")
test.data.5.used <- dplyr::filter (test.data.5, pttype == 1)

table.kfold [41, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.0165"))
table.kfold [42, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.0495"))
table.kfold [43, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.0825"))
table.kfold [44, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.1155"))
table.kfold [45, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.1485"))
table.kfold [46, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.1815"))
table.kfold [47, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.2145"))
table.kfold [48, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.2475"))
table.kfold [49, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.2805"))
table.kfold [50, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.3135"))

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
                       data = dplyr::filter(table.kfold, test.number == 5))
summary (glm.kfold.test5)

table.kfold [41, 7] <- 0.9937
table.kfold [41, 8] <- "<0.001"
table.kfold [41, 9] <- 18.3863
table.kfold [41, 10] <- 0.945
table.kfold [41, 11] <- 0.9714

chisq.test(dplyr::filter(table.kfold, test.number == 5)$used.count, dplyr::filter(table.kfold, test.number == 5)$expected.count)
table.kfold [41, 12] <-  0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du8\\table_kfold_valid_du8.csv")

ggplot (dplyr::filter(table.kfold, test.number == 5), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 5 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 15000, by = 1000)) + 
  scale_y_continuous (breaks = seq (0, 15000, by = 1000))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du8_grp5.png")

write.csv (rsf.data.du8, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du8_preds.csv")



#--------------------------------------------------------------------------- 

################################
### Southern Mountain (DU9) ###
##############################

#---------------------------------------------------------------------------

##########################
### CREATING THE DATA ###
#########################

## Pull in the previously processed GIS data
rsf.data.forestry <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_forestry.csv", header = T, sep = "")
rsf.data.veg <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_veg.csv")
rsf.data.veg <- rsf.data.veg %>% 
  filter (!is.na (bec_label))
rsf.data.forestry <- dplyr::mutate (rsf.data.forestry, distance_to_resource_road = pmin (distance_to_loose_road, 
                                                                                         distance_to_petroleum_road,
                                                                                         distance_to_rough_road,
                                                                                         distance_to_trim_transport_road,
                                                                                         distance_to_unknown_road))
rsf.data.forestry.lean <- rsf.data.forestry [, c (1:13, 20)]
rsf.data.veg.lean <- rsf.data.veg [, c (9:10)]

rsf.data.combo <- dplyr::full_join (rsf.data.forestry.lean, 
                                    rsf.data.veg.lean,
                                    by = "ptID")

rsf.data.du9 <- rsf.data.combo %>%
  dplyr::filter (du == "du9")

rm (rsf.data.forestry, rsf.data.veg, rsf.data.forestry.lean, rsf.data.veg.lean, rsf.data.combo)
gc ()

# save it
write.csv (rsf.data.du9, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du9.csv")

#####################
### EXPLORE DATA ###
###################

rsf.data.du9$pttype <- as.factor (rsf.data.du9$pttype)

## reclassify BEC and set ref category
ggplot (rsf.data.du9, aes (x = bec_label, fill = pttype)) + 
  geom_histogram (position = "dodge", stat = "count") +
  labs (title = "Histogram du9, Summer, BEC Type\
                          at Available (0) and Used (1) Locations",
        x = "Biogeclimatic Unit Type",
        y = "Count") +
  scale_fill_discrete (name = "Location Type") +
  theme (axis.text.x = element_text (angle = 45))

rsf.data.du9$bec_label_reclass <- rsf.data.du9$bec_label

rsf.data.du9$bec_label_reclass <- car::recode (rsf.data.du9$bec_label_reclass,
                                               "'ESSFmv 2' = 'ESSFmv'") 
rsf.data.du9$bec_label_reclass <- car::recode (rsf.data.du9$bec_label_reclass,
                                               "'ESSFmvp' = 'ESSFmv'") 
rsf.data.du9 <- rsf.data.du9 %>%
  dplyr::filter (bec_label_reclass != "BWBSmw")
rsf.data.du9 <- rsf.data.du9 %>%
  dplyr::filter (bec_label_reclass != "IMA un")
rsf.data.du9 <- rsf.data.du9 %>%
  dplyr::filter (bec_label_reclass != "SWB mk")
rsf.data.du9 <- rsf.data.du9 %>%
  dplyr::filter (bec_label_reclass != "ICH vk 1")

ggplot (rsf.data.du9, aes (x = bec_label_reclass, fill = pttype)) + 
  geom_histogram (position = "dodge", stat = "count") +
  labs (title = "Histogram du9, Summer, BEC Type\
                          at Available (0) and Used (1) Locations",
        x = "Biogeclimatic Unit Type",
        y = "Count") +
  scale_fill_discrete (name = "Location Type") +
  theme (axis.text.x = element_text (angle = 45))

rsf.data.du9$bec_label_reclass <- relevel (rsf.data.du9$bec_label_reclass,
                                           ref = "ESSFwc 3") # reference category

### OUTLIERS ###
ggplot (rsf.data.du9, aes (x = pttype, y = distance_to_resource_road)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot du9, Distance to Resource Roads at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Resource Road")
ggplot (rsf.data.du9, aes (x = pttype, y = distance_to_cut_1to4yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot du9, Distance to Cutblock 1 to 4 Years Old at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock 1 to 4 Years Old")
ggplot (rsf.data.du9, aes (x = pttype, y = distance_to_cut_5to9yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot du9, Distance to Cutblock 5 to 9 Years Old at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock 5 to 9 Years Old")
ggplot (rsf.data.du9, aes (x = pttype, y = distance_to_cut_10to29yo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot du9, Distance to Cutblock 10 to 29 Years Old at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock 10 to 29 Years Old")
ggplot (rsf.data.du9, aes (x = pttype, y = distance_to_cut_30orOveryo)) +
  geom_boxplot (outlier.colour = "red") +
  labs (title = "Boxplot du9, Distance to Cutblock Greater than 30 Years Old at Available (0) and Used (1) Locations",
        x = "Available (0) and Used (1) Locations",
        y = "Distance to Cutblock Greater than 30 Years Old")

### HISTOGRAMS ###
ggplot (rsf.data.du9, aes (x = distance_to_resource_road, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 100) +
  labs (title = "Histogram du9, Distance to Resource Roads at Available (0) and Used (1) Locations",
        x = "Distance to Resource Road",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggplot (rsf.data.du9, aes (x = distance_to_cut_1to4yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 100) +
  labs (title = "Histogram du9, Distance to  Cutblock 1 to 4 Years Old at Available (0) and Used (1) Locations",
        x = "Distance to  Cutblock 1 to 4 Years Old",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggplot (rsf.data.du9, aes (x = distance_to_cut_5to9yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 100) +
  labs (title = "Histogram du9, Distance to  Cutblock 5 to 9 Years Old at Available (0) and Used (1) Locations",
        x = "Distance to  Cutblock 5 to 9 Years Old",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggplot (rsf.data.du9, aes (x = distance_to_cut_10to29yo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 100) +
  labs (title = "Histogram du9, Distance to Cutblocks 10 to 29 Years Old at Available (0) and Used (1) Locations",
        x = "Distance to  Cutblocks 10 to 29 Years Old",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggplot (rsf.data.du9, aes (x = distance_to_cut_30orOveryo, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 100) +
  labs (title = "Histogram du9, Distance to Cutblocks Greater than 30 Years Old at Available (0) and Used (1) Locations",
        x = "Distance to  Cutblocks Greater than 30 Years Old",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")

### CORRELATION ###
corr.rsf.data.du9 <- rsf.data.du9 [c (10:14)]
corr.rsf.data.du9 <- round (cor (corr.rsf.data.du9, method = "spearman"), 3)
ggcorrplot (corr.rsf.data.du9, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Resource Selection Function Model Covariate Correlations for du9")

# Distance to cut 10 to 29 and >30  highly correlated with roads, removed these cut ages

### VIF 
glm.du9 <- glm (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo +
                  distance_to_resource_road + bec_label_reclass, 
                data = rsf.data.du9,
                family = binomial (link = 'logit'))
car::vif (glm.du9)

write.csv (rsf.data.du9, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du9_v2.csv")


#########################
### TRANSFORM COVARS ###
#######################

# Transform distance to covars as exponentinal function, follwoing Demars (2018)[http://www.bcogris.ca/sites/default/files/bcip-2019-01-final-report-demars-ver-2.pdf]
# decay.distance = exp (-0.002 8 distance to road)
# 0.002 = distances > 1500-m essentially have a similar and limited effect
rsf.data.du9$exp_dist_res_road <- exp ((rsf.data.du9$distance_to_resource_road * -0.002))
rsf.data.du9$exp_dist_cut_1to4 <- exp ((rsf.data.du9$distance_to_cut_1to4yo * -0.002))
rsf.data.du9$exp_dist_cut_5to9 <- exp ((rsf.data.du9$distance_to_cut_5to9yo * -0.002))

### Standardize the data (helps with model convergence) ###
rsf.data.du9$std_exp_dist_res_road <- (rsf.data.du9$exp_dist_res_road - 
                                         mean (rsf.data.du9$exp_dist_res_road)) / 
                                          sd (rsf.data.du9$exp_dist_res_road)
rsf.data.du9$std_exp_dist_cut_1to4 <- (rsf.data.du9$exp_dist_cut_1to4 - 
                                         mean (rsf.data.du9$exp_dist_cut_1to4)) / 
                                          sd (rsf.data.du9$exp_dist_cut_1to4)
rsf.data.du9$std_exp_dist_cut_5to9 <- (rsf.data.du9$exp_dist_cut_5to9 - 
                                         mean (rsf.data.du9$exp_dist_cut_5to9)) / 
                                          sd (rsf.data.du9$exp_dist_cut_5to9)

### Functional Response Covariates ###
#### Calc mean available distance to road and cutblock in home range, by unique individual
avail.rsf.data.du9 <- subset (rsf.data.du9, pttype == 0)

std_exp_dist_res_road_E <- tapply (avail.rsf.data.du9$std_exp_dist_res_road, avail.rsf.data.du9$animal_id, mean)
std_exp_dist_cut_1to4_E <- tapply (avail.rsf.data.du9$std_exp_dist_cut_1to4, avail.rsf.data.du9$animal_id, mean)
std_exp_dist_cut_5to9_E <- tapply (avail.rsf.data.du9$std_exp_dist_cut_5to9, avail.rsf.data.du9$animal_id, mean)

inds <- as.character (rsf.data.du9$animal_id)
rsf.data.du9 <- cbind (rsf.data.du9, "dist_rd_E" = std_exp_dist_res_road_E[inds], 
                       "dist_cut_1to4_E" = std_exp_dist_cut_1to4_E[inds],
                       "dist_cut_5to9_E" = std_exp_dist_cut_5to9_E[inds])

# to simplify available cutblock effect; interact with distance to any cutblock age
rsf.data.du9$dist_cut_min_all <- pmin (rsf.data.du9$distance_to_cut_1to4,
                                       rsf.data.du9$distance_to_cut_5to9yo)
rsf.data.du9$exp_dist_cut_min <- exp ((rsf.data.du9$dist_cut_min_all * -0.002))
rsf.data.du9$std_exp_dist_cut_min <- (rsf.data.du9$exp_dist_cut_min - 
                                        mean (rsf.data.du9$exp_dist_cut_min)) / 
  sd (rsf.data.du9$exp_dist_cut_min)
avail.rsf.data.du9 <- subset (rsf.data.du9, pttype == 0)
std_exp_dist_cut_min_E <- tapply (avail.rsf.data.du9$std_exp_dist_cut_min, avail.rsf.data.du9$animal_id, mean)
rsf.data.du9 <- cbind (rsf.data.du9, "dist_cut_min_E" = std_exp_dist_cut_min_E[inds])

###################
### FIT MODELS ###
#################

### Generalized Linear Mixed Models (GLMMs) ###
#### First, determine the random effects structure

# Individual animal
model.lme4.du9.animal <- glmer (pttype ~ 1 + (1 | animal_id), # random effect for animal
                                data = rsf.data.du9, 
                                family = binomial (link = "logit"),
                                verbose = T) 

#### Season
model.lme4.du9.season <- glmer (pttype ~ 1 + (1 | season), # random effect for season
                                data = rsf.data.du9, 
                                family = binomial (link = "logit"),
                                verbose = T) 

#### Individual animal and Season
model.lme4.du9.anim.seas <- glmer (pttype ~ 1 + (1 | animal_id) + (1 | season), # random effect intercepts for individual and season
                                   data = rsf.data.du9, 
                                   family = binomial (link = "logit"),
                                   verbose = T) 

# Compare models 
anova (model.lme4.du9.animal, model.lme4.du9.season, model.lme4.du9.anim.seas)

# animal and season model had best fit; use both


#### Second, determine the fixed effects structure
### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 5, nrow = 0))
colnames (table.aic) <- c ("DU", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

#### BEC only model
model.lme4.du9.bec <- glmer (pttype ~ bec_label_reclass + (1 | animal_id) + (1 | season), 
                             data = rsf.data.du9, 
                             family = binomial (link = "logit"),
                             verbose = T) 
# AIC
table.aic [1, 1] <- "du9"
table.aic [1, 2] <- "BEC variant"
table.aic [1, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [1, 4] <-  AIC (model.lme4.du9.bec)

# Dist Road model
model.lme4.du9.road <- glmer (pttype ~ std_exp_dist_res_road + (1 | animal_id) + (1 | season),
                              data = rsf.data.du9, 
                              family = binomial (link = "logit"),
                              verbose = T) 
# AIC
table.aic [2, 1] <- "du9"
table.aic [2, 2] <- "Distance to Resource Road"
table.aic [2, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [2, 4] <-  AIC (model.lme4.du9.road)

# Dist Cut model
model.lme4.du9.cut <- glmer (pttype ~ std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + 
                               (1 | animal_id) + (1 | season),
                             data = rsf.data.du9, 
                             family = binomial (link = "logit"),
                             verbose = T) 
# AIC
table.aic [3, 1] <- "du9"
table.aic [3, 2] <- "Distance to Cutblock"
table.aic [3, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [3, 4] <-  AIC (model.lme4.du9.cut)

# Dist Road and Cut model
model.lme4.du9.rd.cut <- glmer (pttype ~ std_exp_dist_res_road + std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + 
                                  (1 | animal_id) + (1 | season),
                                data = rsf.data.du9, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [4, 1] <- "du9"
table.aic [4, 2] <- "Distance to Resource Road + Distance to Cutblock"
table.aic [4, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [4, 4] <-  AIC (model.lme4.du9.rd.cut)

# Dist Road Fxn Response
model.lme4.du9.rd.fxn <- glmer (pttype ~ std_exp_dist_res_road + dist_rd_E + std_exp_dist_res_road*dist_rd_E + (1 | animal_id) + (1 | season),
                                data = rsf.data.du9, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [5, 1] <- "du9"
table.aic [5, 2] <- "Distance to Resource Road + Available Distance to Resource Road + Distance to Resource Road*Available Distance to Resource Road"
table.aic [5, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [5, 4] <-  AIC (model.lme4.du9.rd.fxn)

scatter3D (rsf.data.du9$distance_to_resource_road, # pretty clear functional response; selection for roads in low road areas and less in high road areas
           rsf.data.du9$dist_rd_E,
           (predict (model.lme4.du9.rd.fxn,
                     newdata = rsf.data.du9, 
                     re.form = NA, type = "response")), 
           xlab = "Dist. Road",
           ylab = "Avail. Dist Road", 
           zlab = "Selection",
           theta = 15, phi = 20)

# Dist Cut Fxn Response
model.lme4.du9.cut.fxn <- glmer (pttype ~ std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + 
                                   dist_cut_min_E + std_exp_dist_cut_1to4*dist_cut_min_E + 
                                   std_exp_dist_cut_5to9*dist_cut_min_E + 
                                   (1 | animal_id) + (1 | season),
                                 data = rsf.data.du9, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [6, 1] <- "du9"
table.aic [6, 2] <- "Distance to Cutblock + Available Distance to Cutblock + Distance to Cutblock*Available Distance to Cutblock"
table.aic [6, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [6, 4] <-  AIC (model.lme4.du9.cut.fxn)

scatter3D (rsf.data.du9$distance_to_cut_5to9yo, # a bit scattered, but general pattern is less avoidance at  higher densities of cut
           rsf.data.du9$dist_cut_min_E,
           (predict (model.lme4.du9.cut.fxn,
                     newdata = rsf.data.du9, 
                     re.form = NA, type = "response")), 
           xlab = "Dist. Cut 1to4",
           ylab = "Avail. Dist Cut", 
           zlab = "Selection",
           theta = 15, phi = 20)

# BEC, Dist Road and Cut model
model.lme4.du9.all <- glmer (pttype ~ bec_label_reclass + std_exp_dist_res_road + 
                               std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + 
                               (1 | animal_id) + (1 | season),
                             data = rsf.data.du9, 
                             family = binomial (link = "logit"),
                             verbose = T) 
# AIC
table.aic [7, 1] <- "du9"
table.aic [7, 2] <- "BEC + Distance to Resource Road + Distance to Cutblock"
table.aic [7, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [7, 4] <-  AIC (model.lme4.du9.all)

# BEC, Dist Road (fxn) and Cut model
model.lme4.du9.all.rd.fxn <- glmer (pttype ~ bec_label_reclass + std_exp_dist_res_road + 
                                      std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + 
                                      dist_rd_E + std_exp_dist_res_road*dist_rd_E + 
                                      (1 | animal_id) + (1 | season),
                                    data = rsf.data.du9, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# AIC
table.aic [8, 1] <- "du9"
table.aic [8, 2] <- "BEC + Distance to Resource Road + Distance to Cutblock + Available Distance to Resource Road + Distance to Resource Road*Available Distance to Resource Road"
table.aic [8, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [8, 4] <-  AIC (model.lme4.du9.all.rd.fxn)

scatter3D (x = rsf.data.du9$distance_to_resource_road, # weird pattern where selection doesn't seem to vary by availability
           y = rsf.data.du9$exp_dist_res_road, 
           z = (predict (model.lme4.du9.all.rd.fxn,
                         newdata = rsf.data.du9, 
                         re.form = NA, type = "response")),
           xlab = "Dist. Road",
           ylab = "Avail. Dist Road", 
           zlab = "Selection",
           theta = 15, phi = 20)

# BEC, Dist Road and Cut model (fxn)
model.lme4.du9.all.cut.fxn <- glmer (pttype ~ bec_label_reclass + std_exp_dist_res_road + 
                                       std_exp_dist_cut_1to4 + std_exp_dist_cut_5to9 + 
                                       dist_cut_min_E + std_exp_dist_cut_1to4*dist_cut_min_E + 
                                       std_exp_dist_cut_5to9*dist_cut_min_E + 
                                       (1 | animal_id) + (1 | season),
                                     data = rsf.data.du9, 
                                     family = binomial (link = "logit"),
                                     verbose = T) 
# AIC
table.aic [9, 1] <- "du9"
table.aic [9, 2] <- "BEC + Distance to Resource Road + Distance to Cutblock + Available Distance to Cutblock + Distance to Cutblock*Available Distance to Cutblock"
table.aic [9, 3] <- "(1 | animal_id) + (1 | season)"
table.aic [9, 4] <-  AIC (model.lme4.du9.all.cut.fxn)

scatter3D (x = rsf.data.du9$distance_to_cut_1to4yo, # scatter shot
           y = rsf.data.du9$dist_cut_min_E, 
           z = (predict (model.lme4.du9.all.cut.fxn,
                         newdata = rsf.data.du9, 
                         re.form = NA, type = "response")),
           xlab = "Dist. Cut 1 to 4",
           ylab = "Avail. Dist Cut", 
           zlab = "Selection",
           theta = 15, phi = 20)

## AIC comparison of MODELS ## 
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 4] - min (table.aic [1:9, 4])))), 
                    (exp (-0.5 * (table.aic [2, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [3, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [4, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [5, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [6, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [7, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [8, 4] - min (table.aic [1:9, 4])))),
                    (exp (-0.5 * (table.aic [9, 4] - min (table.aic [1:9, 4])))))
table.aic [1, 5] <- round ((exp (-0.5 * (table.aic [1, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [2, 5] <- round ((exp (-0.5 * (table.aic [2, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [3, 5] <- round ((exp (-0.5 * (table.aic [3, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [4, 5] <- round ((exp (-0.5 * (table.aic [4, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [5, 5] <- round ((exp (-0.5 * (table.aic [5, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [6, 5] <- round ((exp (-0.5 * (table.aic [6, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [7, 5] <- round ((exp (-0.5 * (table.aic [7, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [8, 5] <- round ((exp (-0.5 * (table.aic [8, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)
table.aic [9, 5] <- round ((exp (-0.5 * (table.aic [9, 4] - min (table.aic [1:9, 4])))) / sum (list.aic.like), 3)

write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_du9_v2.csv", sep = ",")

# used model without functional response because was top model (although tnot he clear favourite) 
# and fxn response didn't appear to improve interpretation of model, 
# on its own, road interatction caovraite showed fucntional response, but didn;t hold up when includign other
# terms, so go without for now

# save the top model
save (model.lme4.du9.all, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_du9_top_v2.rda")

###################
### SAVE MODEL ###
#################

# Create table of model coefficients from top model
model.coeffs <- as.data.frame (coef (summary (model.lme4.du9.all)))
model.coeffs$mean_exp_neg0002 <- 0
model.coeffs$sd_exp_neg0002 <- 0

model.coeffs [19, 5] <- mean (exp ((rsf.data.du9$distance_to_resource_road * -0.002)))
model.coeffs [20, 5] <- mean (exp ((rsf.data.du9$distance_to_cut_1to4yo * -0.002)))
model.coeffs [21, 5] <- mean (exp ((rsf.data.du9$distance_to_cut_5to9yo * -0.002)))

model.coeffs [19, 6] <- sd (exp ((rsf.data.du9$distance_to_resource_road * -0.002)))
model.coeffs [20, 6] <- sd (exp ((rsf.data.du9$distance_to_cut_1to4yo * -0.002)))
model.coeffs [21, 6] <- sd (exp ((rsf.data.du9$distance_to_cut_5to9yo * -0.002)))

write.table (model.coeffs, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\model_coefficients\\table_du9_summ_model_coeffs_top.csv", sep = ",")

###############################
### RSF RASTER CALCULATION ###
#############################

### LOAD RASTERS ###
bec.bafa.un <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_bafa_un.tif")
bec.essf.mv <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_mv_du9.tif")
bec.essf.wc4 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_wc4.tif")
bec.essf.wcp <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_wcp.tif")
bec.essf.wcw <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_wcw.tif")
bec.essf.wh1 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_wh1.tif")
bec.essf.wh3 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_wh3.tif")
bec.essf.wk2 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_wk2.tif")
bec.essf.wm3 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_wm3.tif")
bec.essf.wm4 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_wm4.tif")
bec.essf.wmp <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_wmp.tif")
bec.essf.wmw <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_essf_wmw.tif")
bec.ich.mw2 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_ich_mw2.tif")
bec.ich.mw4 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_ich_mw4.tif")
bec.ich.wk1 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_ich_wk1.tif")
bec.sbs.vk <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_sbs_vk.tif")
bec.sbs.wk1 <- raster ("C:\\Work\\caribou\\clus_data\\bec\\BEC_current\\raster\\bec_sbs_wk1.tif")
dist.cut.1to4 <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_1to4yo.tif")
dist.cut.5to9 <- raster ("C:\\Work\\caribou\\clus_data\\cutblocks\\cutblock_tiffs\\raster_dist_cutblocks_5to9yo.tif")
dist.resource.rd <- raster ("C:\\Work\\caribou\\clus_data\\roads_ha_bc\\dist_crds_resource.tif")

### Adjust the raster data for 'standardized' model covariates ###
std.dist.resource.rd <- (exp (dist.resource.rd * -0.002) - 0.1945082) / 0.2734546
std.dist.cut.1to4 <- (exp (dist.cut.1to4 * -0.002) - 0.01632449) / 0.07921517
std.dist.cut.5to9 <- (exp (dist.cut.5to9 * -0.002) - 0.008448977) / 0.05381447

### CALCULATE RASTER RSF ###
raster.rsf <- (exp (-2.58 + (bec.bafa.un * 0.59) + (bec.essf.mv * -0.64) +
                      (bec.essf.wc4 * 0.94) + (bec.essf.wcp * 0.47) + 
                      (bec.essf.wcw * 1.33) + (bec.essf.wh1 * 0.22) +
                      (bec.essf.wh3 * 0.18) + (bec.essf.wk2 * -0.63) + 
                      (bec.essf.wm3 * -0.01) + (bec.essf.wm4 * 	0.23) +  
                      (bec.essf.wmp * -0.49) + (bec.essf.wmw * 	0.49) +
                      (bec.ich.mw2 * 0.25) + (bec.ich.mw4 * -0.89) +
                      (bec.ich.wk1 * 0.53) + (bec.sbs.vk * -0.80) +
                      (bec.sbs.wk1 * 0.42) + (std.dist.resource.rd * -0.24) +
                      (std.dist.cut.1to4 * 0.02) + 
                      (std.dist.cut.5to9 * -0.06))) / 
  (1 + exp (-2.58 + (bec.bafa.un * 0.59) + (bec.essf.mv * -0.64) +
              (bec.essf.wc4 * 0.94) + (bec.essf.wcp * 0.47) + 
              (bec.essf.wcw * 1.33) + (bec.essf.wh1 * 0.22) +
              (bec.essf.wh3 * 0.18) + (bec.essf.wk2 * -0.63) + 
              (bec.essf.wm3 * -0.01) + (bec.essf.wm4 * 	0.23) +  
              (bec.essf.wmp * -0.49) + (bec.essf.wmw * 	0.49) +
              (bec.ich.mw2 * 0.25) + (bec.ich.mw4 * -0.89) +
              (bec.ich.wk1 * 0.53) + (bec.sbs.vk * -0.80) +
              (bec.sbs.wk1 * 0.42) + (std.dist.resource.rd * -0.24) +
              (std.dist.cut.1to4 * 0.02) + 
              (std.dist.cut.5to9 * -0.06)))

plot (raster.rsf)

writeRaster (raster.rsf, "C:\\Work\\caribou\\clus_data\\rsf\\rsf_2pt0\\rasters\\du9\\rsf_du9_v2.tif", 
             format = "GTiff", overwrite = T)

##########################
### k-fold Validation ###
########################
df.animal.id <- as.data.frame (unique (rsf.data.du9$animal_id))
names (df.animal.id) [1] <-"animal_id"
df.animal.id$group <- rep_len (1:5, nrow (df.animal.id)) # orderly selection of groups
rsf.data.du9 <- dplyr::full_join (rsf.data.du9, df.animal.id, by = "animal_id")
rsf.data.du9 <- rsf.data.du9 %>% # drop these animals because only animal using SBS wk 1 adn ESSFmv
                 filter (animal_id != "car069") %>%
                 filter (animal_id != "car078")
  
### FOLD 1 ###
train.data.1 <- rsf.data.du9 %>%
  filter (group < 5)
test.data.1 <- rsf.data.du9 %>%
  filter (group == 5)

model.lme4.du9train1 <- glmer (pttype ~ bec_label_reclass + 
                                 std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + 
                                 std_exp_dist_cut_5to9 + 
                                 (1 | animal_id) + (1 | season), 
                               data = train.data.1, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# create a table of k-fold outputs
table.kfold <- data.frame (matrix (ncol = 12, nrow = 50))
colnames (table.kfold) <- c ("test.number", "bin.mid", "bin.weight", "utilization", "used.count", 
                             "expected.count", "lm.slope", "lm.slope.p.value", "lm.intercept",
                             "lm.intercept.p.value", "adj.R.sq", "chi.sq.p.value")
table.kfold [c (1:10), 1] <- 1
table.kfold$bin.mid <- c (0.015, 0.045, 0.075, 0.105, 0.135, 0.165, 0.195, 0.225, 0.255, 0.285)

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du9$preds.train1 <- predict (model.lme4.du9train1, 
                                      newdata = rsf.data.du9, 
                                      re.form = NA, type = "response",
                                      allow.new.levels = TRUE)

ggplot (data = rsf.data.du9, aes (preds.train1)) +
  geom_histogram()
max (rsf.data.du9$preds.train1)
min (rsf.data.du9$preds.train1)

rsf.data.du9$preds.train1.class <- cut (rsf.data.du9$preds.train1, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24, 0.27, Inf), 
                                        labels = c ("0.015", "0.045", "0.075", "0.105", "0.135",
                                                    "0.165", "0.195", "0.225", "0.255", "0.285"))
rsf.data.du9.avail <- dplyr::filter (rsf.data.du9, pttype == 0)

table.kfold [1, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train1.class == "0.015")) * 0.015) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [2, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train1.class == "0.045")) * 0.045)
table.kfold [3, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train1.class == "0.075")) * 0.075)
table.kfold [4, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train1.class == "0.105")) * 0.105)
table.kfold [5, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train1.class == "0.135")) * 0.135)
table.kfold [6, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train1.class == "0.165")) * 0.165)
table.kfold [7, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train1.class == "0.195")) * 0.195)
table.kfold [8, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train1.class == "0.225")) * 0.225)
table.kfold [9, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train1.class == "0.255")) * 0.255)
table.kfold [10, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train1.class == "0.285")) * 0.285)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du9\\table_kfold_valid_du9.csv")

# data for estimating use
test.data.1$preds <- predict (model.lme4.du9train1, newdata = test.data.1, re.form = NA, type = "response")
test.data.1$preds.class <- cut (test.data.1$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24, 0.27, Inf), 
                                labels = c ("0.015", "0.045", "0.075", "0.105", "0.135",
                                            "0.165", "0.195", "0.225", "0.255", "0.285"))

write.csv (test.data.1, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du9\\rsf_preds_du9_train1.csv")
test.data.1.used <- dplyr::filter (test.data.1, pttype == 1)

table.kfold [1, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.015"))
table.kfold [2, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.045"))
table.kfold [3, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.075"))
table.kfold [4, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.105"))
table.kfold [5, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.135"))
table.kfold [6, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.165"))
table.kfold [7, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.195"))
table.kfold [8, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.225"))
table.kfold [9, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.255"))
table.kfold [10, 5] <- nrow (dplyr::filter (test.data.1.used, preds.class == "0.285"))

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

table.kfold [1, 7] <- 1.3547
table.kfold [1, 8] <- "<0.001"
table.kfold [1, 9] <- -57.1372
table.kfold [1, 10] <- 0.213
table.kfold [1, 11] <- 0.8575 

chisq.test(dplyr::filter(table.kfold, test.number == 1)$used.count, dplyr::filter(table.kfold, test.number == 1)$expected.count)
table.kfold [1, 12] <-  0.2424

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du9\\table_kfold_valid_du9.csv")


ggplot (dplyr::filter(table.kfold, test.number == 1), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 1 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 1000, by = 100)) + 
  scale_y_continuous (breaks = seq (0, 1000, by = 100))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du9_grp1.png")

write.csv (rsf.data.du9, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du9_preds.csv")

### FOLD 2 ###
train.data.2 <- rsf.data.du9 %>%
  filter (group == 1 | group == 2 | group == 3 | group == 5)
test.data.2 <- rsf.data.du9 %>%
  filter (group == 4)

model.lme4.du9train2 <- glmer (pttype ~ bec_label_reclass + 
                                 std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + 
                                 std_exp_dist_cut_5to9 + 
                                 (1 | animal_id) + (1 | season), 
                               data = train.data.2, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du9$preds.train2 <- predict (model.lme4.du9train2, 
                                      newdata = rsf.data.du9, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du9, aes (preds.train2)) +
  geom_histogram()
max (rsf.data.du9$preds.train2)
min (rsf.data.du9$preds.train2)

rsf.data.du9$preds.train2.class <- cut (rsf.data.du9$preds.train2, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24, 0.27, Inf), 
                                        labels = c ("0.015", "0.045", "0.075", "0.105", "0.135",
                                                    "0.165", "0.195", "0.225", "0.255", "0.285"))
table.kfold [c (11:20), 1] <- 2

rsf.data.du9.avail <- dplyr::filter (rsf.data.du9, pttype == 0)

table.kfold [11, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train2.class == "0.015")) * 0.015) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [12, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train2.class == "0.045")) * 0.045)
table.kfold [13, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train2.class == "0.075")) * 0.075)
table.kfold [14, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train2.class == "0.105")) * 0.105)
table.kfold [15, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train2.class == "0.135")) * 0.135)
table.kfold [16, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train2.class == "0.165")) * 0.165)
table.kfold [17, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train2.class == "0.195")) * 0.195)
table.kfold [18, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train2.class == "0.225")) * 0.225)
table.kfold [19, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train2.class == "0.255")) * 0.255)
table.kfold [20, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train2.class == "0.285")) * 0.285)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du9\\table_kfold_valid_du9.csv")

# data for estimating use
test.data.2$preds <- predict (model.lme4.du9train2, newdata = test.data.2, re.form = NA, type = "response")
test.data.2$preds.class <- cut (test.data.2$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24, 0.27, Inf), 
                                labels = c ("0.015", "0.045", "0.075", "0.105", "0.135",
                                            "0.165", "0.195", "0.225", "0.255", "0.285"))
write.csv (test.data.2, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du9\\rsf_preds_du9_train2.csv")
test.data.2.used <- dplyr::filter (test.data.2, pttype == 1)

table.kfold [11, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.015"))
table.kfold [12, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.045"))
table.kfold [13, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.075"))
table.kfold [14, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.105"))
table.kfold [15, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.135"))
table.kfold [16, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.165"))
table.kfold [17, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.195"))
table.kfold [18, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.225"))
table.kfold [19, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.255"))
table.kfold [20, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.285"))

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
                       data = dplyr::filter(table.kfold, test.number == 2))
summary (glm.kfold.test2)

table.kfold [11, 7] <- 1.0511
table.kfold [11, 8] <- "<0.001"
table.kfold [11, 9] <- 1.0511
table.kfold [11, 10] <- 0.732
table.kfold [11, 11] <- 0.9222

chisq.test(dplyr::filter(table.kfold, test.number == 2)$used.count, dplyr::filter(table.kfold, test.number == 2)$expected.count)
table.kfold [11, 12] <-  0.09884

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du9\\table_kfold_valid_du9.csv")

ggplot (dplyr::filter(table.kfold, test.number == 2), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 2 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 1000, by = 100)) + 
  scale_y_continuous (breaks = seq (0, 1000, by = 100))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du9_grp2.png")

write.csv (rsf.data.du9, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du9_preds.csv")

### FOLD 3 ###
train.data.3 <- rsf.data.du9 %>%
  filter (group == 1 | group == 2 | group == 4 | group == 5)
test.data.3 <- rsf.data.du9 %>%
  filter (group == 3)

model.lme4.du9train3 <- glmer (pttype ~ bec_label_reclass + 
                                 std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + 
                                 std_exp_dist_cut_5to9 + 
                                 (1 | animal_id) + (1 | season), 
                               data = train.data.3, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du9$preds.train3 <- predict (model.lme4.du9train3, 
                                      newdata = rsf.data.du9, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du9, aes (preds.train3)) +
  geom_histogram()
max (rsf.data.du9$preds.train3)
min (rsf.data.du9$preds.train3)

rsf.data.du9$preds.train3.class <- cut (rsf.data.du9$preds.train3, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24, 0.27, Inf), 
                                        labels = c ("0.015", "0.045", "0.075", "0.105", "0.135",
                                                    "0.165", "0.195", "0.225", "0.255", "0.285"))
table.kfold [c (21:30), 1] <- 3

rsf.data.du9.avail <- dplyr::filter (rsf.data.du9, pttype == 0)

table.kfold [21, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train3.class == "0.015")) * 0.015) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [22, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train3.class == "0.045")) * 0.045)
table.kfold [23, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train3.class == "0.075")) * 0.075)
table.kfold [24, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train3.class == "0.105")) * 0.105)
table.kfold [25, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train3.class == "0.135")) * 0.135)
table.kfold [26, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train3.class == "0.165")) * 0.165)
table.kfold [27, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train3.class == "0.195")) * 0.195)
table.kfold [28, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train3.class == "0.225")) * 0.225)
table.kfold [29, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train3.class == "0.255")) * 0.255)
table.kfold [30, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train3.class == "0.285")) * 0.285)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du9\\table_kfold_valid_du9.csv")

# data for estimating use
test.data.3$preds <- predict (model.lme4.du9train3, newdata = test.data.3, re.form = NA, type = "response")
test.data.3$preds.class <- cut (test.data.3$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24, 0.27, Inf), 
                                labels = c ("0.015", "0.045", "0.075", "0.105", "0.135",
                                            "0.165", "0.195", "0.225", "0.255", "0.285"))
write.csv (test.data.3, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du9\\rsf_preds_du9_train3.csv")
test.data.3.used <- dplyr::filter (test.data.3, pttype == 1)

table.kfold [21, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.015"))
table.kfold [22, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.045"))
table.kfold [23, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.075"))
table.kfold [24, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.105"))
table.kfold [25, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.135"))
table.kfold [26, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.165"))
table.kfold [27, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.195"))
table.kfold [28, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.225"))
table.kfold [29, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.255"))
table.kfold [30, 5] <- nrow (dplyr::filter (test.data.3.used, preds.class == "0.285"))

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
                       data = dplyr::filter(table.kfold, test.number == 3))
summary (glm.kfold.test3)

table.kfold [21, 7] <- 1.2014 
table.kfold [21, 8] <- "<0.001"
table.kfold [21, 9] <- -40.8562
table.kfold [21, 10] <- 0.291
table.kfold [21, 11] <- 0.8983 

chisq.test(dplyr::filter(table.kfold, test.number == 3)$used.count, dplyr::filter(table.kfold, test.number == 3)$expected.count)
table.kfold [21, 12] <-  0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du9\\table_kfold_valid_du9.csv")

ggplot (dplyr::filter(table.kfold, test.number == 3), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 3 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 1000, by = 100)) + 
  scale_y_continuous (breaks = seq (0, 1000, by = 100))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du9_grp3.png")

write.csv (rsf.data.du9, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du9_preds.csv")

### FOLD 4 ###
train.data.4 <- rsf.data.du9 %>%
  filter (group == 1 | group == 3 | group == 4 | group == 5)
test.data.4 <- rsf.data.du9 %>%
  filter (group == 2)

model.lme4.du9train4 <- glmer (pttype ~ bec_label_reclass + 
                                 std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + 
                                 std_exp_dist_cut_5to9 + 
                                 (1 | animal_id) + (1 | season), 
                               data = train.data.4, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du9$preds.train4 <- predict (model.lme4.du9train4, 
                                      newdata = rsf.data.du9, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du9, aes (preds.train4)) +
  geom_histogram()
max (rsf.data.du9$preds.train4)
min (rsf.data.du9$preds.train4)

rsf.data.du9$preds.train4.class <- cut (rsf.data.du9$preds.train4, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24, 0.27, Inf), 
                                        labels = c ("0.015", "0.045", "0.075", "0.105", "0.135",
                                                    "0.165", "0.195", "0.225", "0.255", "0.285"))
table.kfold [c (31:40), 1] <- 4

rsf.data.du9.avail <- dplyr::filter (rsf.data.du9, pttype == 0)

table.kfold [31, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train4.class == "0.015")) * 0.015) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [32, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train4.class == "0.045")) * 0.045)
table.kfold [33, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train4.class == "0.075")) * 0.075)
table.kfold [34, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train4.class == "0.105")) * 0.105)
table.kfold [35, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train4.class == "0.135")) * 0.135)
table.kfold [36, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train4.class == "0.165")) * 0.165)
table.kfold [37, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train4.class == "0.195")) * 0.195)
table.kfold [38, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train4.class == "0.225")) * 0.225)
table.kfold [39, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train4.class == "0.255")) * 0.255)
table.kfold [40, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train4.class == "0.285")) * 0.285)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du9\\table_kfold_valid_du9.csv")

# data for estimating use
test.data.4$preds <- predict (model.lme4.du9train4, newdata = test.data.4, re.form = NA, type = "response")
test.data.4$preds.class <- cut (test.data.4$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24, 0.27, Inf), 
                                labels = c ("0.015", "0.045", "0.075", "0.105", "0.135",
                                            "0.165", "0.195", "0.225", "0.255", "0.285"))
table.kfold [c (31:40), 1] <- 4
write.csv (test.data.4, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du9\\rsf_preds_du9_train4.csv")
test.data.4.used <- dplyr::filter (test.data.4, pttype == 1)

table.kfold [31, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.015"))
table.kfold [32, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.045"))
table.kfold [33, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.075"))
table.kfold [34, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.105"))
table.kfold [35, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.135"))
table.kfold [36, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.165"))
table.kfold [37, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.195"))
table.kfold [38, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.225"))
table.kfold [39, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.255"))
table.kfold [40, 5] <- nrow (dplyr::filter (test.data.4.used, preds.class == "0.285"))

table.kfold [31, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [31, 4], 0) # expected number of uses in each bin
table.kfold [32, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [32, 4], 0) # expected number of uses in each bin
table.kfold [33, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [33, 4], 0) # expected number of uses in each bin
table.kfold [34, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [34, 4], 0) # expected number of uses in each bin
table.kfold [35, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [35, 4], 0) # expected number of uses in each bin
table.kfold [36, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [36, 4], 0) # expected number of uses in each bin
table.kfold [37, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [37, 4], 0) # expected number of uses in each bin
table.kfold [38, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [38, 4], 0) # expected number of uses in each bin
table.kfold [39, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [39, 4], 0) # expected number of uses in each bin
table.kfold [40, 6] <- round (sum (table.kfold [c (31:40), 5]) * table.kfold [40, 4], 0) # expected number of uses in each bin

glm.kfold.test4 <- lm (used.count ~ expected.count, 
                       data = dplyr::filter(table.kfold, test.number == 4))
summary (glm.kfold.test4)

table.kfold [31, 7] <- 0.9466
table.kfold [31, 8] <- "<0.001"
table.kfold [31, 9] <- 7.0369
table.kfold [31, 10] <- 0.84366
table.kfold [31, 11] <- 0.716

chisq.test(dplyr::filter(table.kfold, test.number == 4)$used.count, dplyr::filter(table.kfold, test.number == 4)$expected.count)
table.kfold [31, 12] <-  0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du9\\table_kfold_valid_du9.csv")

ggplot (dplyr::filter(table.kfold, test.number == 4), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 4 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 1000, by = 100)) + 
  scale_y_continuous (breaks = seq (0, 1000, by = 100))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du9_grp4.png")

write.csv (rsf.data.du9, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du9_preds.csv")

### FOLD 5 ###
train.data.5 <- rsf.data.du9 %>%
  filter (group == 5 | group == 2 | group == 3 | group == 4)
test.data.5 <- rsf.data.du9 %>%
  filter (group == 1)

model.lme4.du9train5 <- glmer (pttype ~ bec_label_reclass + 
                                 std_exp_dist_res_road + 
                                 std_exp_dist_cut_1to4 + 
                                 std_exp_dist_cut_5to9 + 
                                 (1 | animal_id) + (1 | season), 
                               data = train.data.5, 
                               family = binomial (link = "logit"),
                               verbose = T) 

# data for esimating utilization; here I am using the available sample as the RSF GIS 'map'
rsf.data.du9$preds.train5 <- predict (model.lme4.du9train5, 
                                      newdata = rsf.data.du9, 
                                      re.form = NA, type = "response")

ggplot (data = rsf.data.du9, aes (preds.train5)) +
  geom_histogram()
max (rsf.data.du9$preds.train5)
min (rsf.data.du9$preds.train5)

rsf.data.du9$preds.train5.class <- cut (rsf.data.du9$preds.train5, # put into classes; 0 to 0.22, based on max and min values
                                        breaks = c (-Inf, 0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24, 0.27, Inf), 
                                        labels = c ("0.015", "0.045", "0.075", "0.105", "0.135",
                                                    "0.165", "0.195", "0.225", "0.255", "0.285"))
table.kfold [c (41:50), 1] <- 5

rsf.data.du9.avail <- dplyr::filter (rsf.data.du9, pttype == 0)

table.kfold [41, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train5.class == "0.015")) * 0.015) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [42, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train5.class == "0.045")) * 0.045)
table.kfold [43, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train5.class == "0.075")) * 0.075)
table.kfold [44, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train5.class == "0.105")) * 0.105)
table.kfold [45, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train5.class == "0.135")) * 0.135)
table.kfold [46, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train5.class == "0.165")) * 0.165)
table.kfold [47, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train5.class == "0.195")) * 0.195)
table.kfold [48, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train5.class == "0.225")) * 0.225)
table.kfold [49, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train5.class == "0.255")) * 0.255)
table.kfold [50, 3] <- (nrow (dplyr::filter (rsf.data.du9.avail, preds.train5.class == "0.285")) * 0.285)

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

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du9\\table_kfold_valid_du9.csv")

# data for estimating use
test.data.5$preds <- predict (model.lme4.du9train5, newdata = test.data.5, re.form = NA, type = "response")
test.data.5$preds.class <- cut (test.data.5$preds, # put into classes, based on max and min values
                                breaks = c (-Inf, 0.03, 0.06, 0.09, 0.12, 0.15, 0.18, 0.21, 0.24, 0.27, Inf), 
                                labels = c ("0.015", "0.045", "0.075", "0.105", "0.135",
                                            "0.165", "0.195", "0.225", "0.255", "0.285"))
write.csv (test.data.5, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du9\\rsf_preds_du9_train5.csv")
test.data.5.used <- dplyr::filter (test.data.5, pttype == 1)

table.kfold [41, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.015"))
table.kfold [42, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.045"))
table.kfold [43, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.075"))
table.kfold [44, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.105"))
table.kfold [45, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.135"))
table.kfold [46, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.165"))
table.kfold [47, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.195"))
table.kfold [48, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.225"))
table.kfold [49, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.255"))
table.kfold [50, 5] <- nrow (dplyr::filter (test.data.5.used, preds.class == "0.285"))

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
                       data = dplyr::filter(table.kfold, test.number == 5))
summary (glm.kfold.test5)

table.kfold [41, 7] <-  1.1822
table.kfold [41, 8] <- "<0.001"
table.kfold [41, 9] <- -43.7446
table.kfold [41, 10] <- 0.530649
table.kfold [41, 11] <- 0.8013

chisq.test(dplyr::filter(table.kfold, test.number == 5)$used.count, dplyr::filter(table.kfold, test.number == 5)$expected.count)
table.kfold [41, 12] <-  0.02605

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du9\\table_kfold_valid_du9.csv")

ggplot (dplyr::filter(table.kfold, test.number == 5), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 5 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 1000, by = 100)) + 
  scale_y_continuous (breaks = seq (0, 1000, by = 100))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du9_grp5.png")

write.csv (rsf.data.du9, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du9_preds.csv")


