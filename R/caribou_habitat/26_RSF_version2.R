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

##########################
### CREATING THE DATA ###
#########################

## Pull in the previously processed GIS data

### Boreal
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

#######################
### FITTING MODELS ###
#####################

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
#### Calc mean available distance to road and cutblock in home range, by unique individual ####
avail.rsf.data.du6 <- subset (rsf.data.du6, pttype == 0)

std_exp_dist_res_road_E <- tapply (avail.rsf.data.du6$std_exp_dist_res_road, avail.rsf.data.du6$animal_id, mean)
std_exp_dist_cut_1to4_E <- tapply (avail.rsf.data.du6$std_exp_dist_cut_1to4, avail.rsf.data.du6$animal_id, mean)
std_exp_dist_cut_5to9_E <- tapply (avail.rsf.data.du6$exp_dist_cut_5to9, avail.rsf.data.du6$animal_id, mean)
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

### Generalized Linear Mixed Models (GLMMs) ###
#### First, determine the random effects structure #####

# Individual animal
model.lme4.du6.animal <- glmer (pttype ~ 1 + (1 | animal_id), # random effect for animal
                                 data = rsf.data.du6, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 

#### Season ####
model.lme4.du6.season <- glmer (pttype ~ 1 + (1 | season), # random effect for season
                                 data = rsf.data.du6, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 

#### Individual animal and Season ####
model.lme4.du6.anim.seas <- glmer (pttype ~ 1 + (1 | animal_id) + (1 | season), # random effect intercepts for indivudal and season
                                    data = rsf.data.du6, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 

# Compare models 
anova (model.lme4.du6.animal, model.lme4.du6.season, model.lme4.du6.anim.seas)

# animal and season model had best fit; use both

#### Second, determine the fixed effects structure #####
### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 5, nrow = 0))
colnames (table.aic) <- c ("DU", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

#### Wetland only model ####
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
test.data.1$preds.class <- cut (test.data.1$preds, # put into classes; 0 to 0.4, based on max and min values
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
  scale_x_continuous (breaks = seq (0, 9000, by = 500)) + 
  scale_y_continuous (breaks = seq (0, 9000, by = 500))
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







# create a table of k-fold outputs
table.kfold <- data.frame (matrix (ncol = 12, nrow = 50))
colnames (table.kfold) <- c ("test.number", "bin.mid", "bin.weight", "utilization", "used.count", 
                             "expected.count", "lm.slope", "lm.slope.p.value", "lm.intercept",
                             "lm.intercept.p.value", "adj.R.sq", "chi.sq.p.value")
table.kfold [c (1:10), 1] <- 1
table.kfold$bin.mid <- c (0.011, 0.033, 0.055, 0.077, 0.099, 0.121, 0.143, 0.165, 0.187, 0.209)

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
rsf.data.du6.avail <- dplyr::filter (rsf.data.du6, pttype == 0)

table.kfold [1, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.011")) * 0.011) # number of rows is the 'area' of the class on the 'map' (i.e., ha's)
table.kfold [2, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.033")) * 0.033)
table.kfold [3, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.055")) * 0.055)
table.kfold [4, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.077")) * 0.077)
table.kfold [5, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.099")) * 0.099)
table.kfold [6, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.121")) * 0.121)
table.kfold [7, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.143")) * 0.143)
table.kfold [8, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.165")) * 0.165)
table.kfold [9, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.187")) * 0.187)
table.kfold [10, 3] <- (nrow (dplyr::filter (rsf.data.du6.avail, preds.train2.class == "0.209")) * 0.209)

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
test.data.2$preds <- predict (model.lme4.du6train2, newdata = test.data.2, re.form = NA, type = "response")
test.data.2$preds.class <- cut (test.data.2$preds, # put into classes; 0 to 0.4, based on max and min values
                                breaks = c (-Inf, 0.022, 0.044, 0.066, 0.088, 0.110, 0.132, 0.154, 0.176, 0.198, Inf), 
                                labels = c ("0.011", "0.033", "0.055", "0.077", "0.099",
                                            "0.121", "0.143", "0.165", "0.187", "0.209"))
write.csv (test.data.2, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\rsf_preds_du6_train2.csv")
test.data.2.used <- dplyr::filter (test.data.2, pttype == 1)

table.kfold [1, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.011"))
table.kfold [2, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.033"))
table.kfold [3, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.055"))
table.kfold [4, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.077"))
table.kfold [5, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.099"))
table.kfold [6, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.121"))
table.kfold [7, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.143"))
table.kfold [8, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.165"))
table.kfold [9, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.187"))
table.kfold [10, 5] <- nrow (dplyr::filter (test.data.2.used, preds.class == "0.209"))

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
                       data = dplyr::filter(table.kfold, test.number == 2))
summary (glm.kfold.test1)

table.kfold [1, 7] <- 1.0301
table.kfold [1, 8] <- "<0.001"
table.kfold [1, 9] <- -131.5415
table.kfold [1, 10] <- 0.745
table.kfold [1, 11] <- 0.963

chisq.test(dplyr::filter(table.kfold, test.number == 2)$used.count, dplyr::filter(table.kfold, test.number == 2)$expected.count)
table.kfold [1, 12] <-  0.2313

write.csv (table.kfold, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\kfold\\du6\\table_kfold_valid_du6.csv")


ggplot (dplyr::filter(table.kfold, test.number == 2), aes (x = expected.count, y = used.count)) +
  geom_point () +
  geom_smooth (method = 'lm') +
  theme_bw () +
  labs (title = "Group 1 independent sample of expected versus observed proportion of caribou 
        locations in 10 RSF bins",
        x = "Expected proportion",
        y = "Observed proportion") + 
  scale_x_continuous (breaks = seq (0, 9000, by = 500)) + 
  scale_y_continuous (breaks = seq (0, 9000, by = 500))
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\kfold_lm_du6_grp1.png")

write.csv (rsf.data.du6, file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_du6_preds.csv")
