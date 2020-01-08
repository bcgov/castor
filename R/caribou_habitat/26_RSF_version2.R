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
                                distance_to_resource_road, wetland_demars, distance_to_cut_10yoorOver)
rsf.data.du6.lw <- rsf.data.combo.du6.lw %>%
                        select (pttype, uniqueID, du, season, animal_id, year, ECOTYPE, HERD_NAME, ptID,
                                distance_to_resource_road, wetland_demars, distance_to_cut_10yoorOver)
rsf.data.du6.s <- rsf.data.combo.du6.s %>%
                        select (pttype, uniqueID, du, season, animal_id, year, ECOTYPE, HERD_NAME, ptID,
                                distance_to_resource_road, wetland_demars, distance_to_cut_10yoorOver)

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
ggplot (rsf.data.du6, aes (x = distance_to_cut_10yoorOver, fill = pttype)) + 
  geom_histogram (position = "dodge", binwidth = 5) +
  labs (title = "Histogram DU6, Distance to  Cutblock Greater than 9 Years Old at Available (0) and Used (1) Locations",
        x = "Distance to  Cutblock Greater than 9 Years Old",
        y = "Count") +
  scale_fill_discrete (name = "Location Type")
ggplot (rsf.data.du6, aes (wetland_demars)) + 
  geom_bar ()

### CORRELATION ###
corr.rsf.data.du6 <- rsf.data.du6 [c (10, 12)]
corr.rsf.data.du6 <- round (cor (corr.rsf.data.du6, method = "spearman"), 3)
ggcorrplot (corr.rsf.data.du6, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Resource Selection Function Model Covariate Correlations for DU6")

### VIF ###
glm.du6 <- glm (pttype ~ std_exp_dist_res_road + std_exp_dist_cut_10 + wetland_demars, 
                data = rsf.data.du6,
                family = binomial (link = 'logit'))
car::vif (glm.du6)

# Transform distance to covars as exponentinal function, follwoing Demars (2018)[http://www.bcogris.ca/sites/default/files/bcip-2019-01-final-report-demars-ver-2.pdf]
# decay.distance = exp (-0.002 8 distance to road)
# 0.002 = distances > 1500-m essentially have a similar and limited effect
rsf.data.du6$exp_dist_res_road <- exp ((rsf.data.du6$distance_to_resource_road * -0.002))
rsf.data.du6$exp_dist_cut_10 <- exp ((rsf.data.du6$distance_to_cut_10yoorOver * -0.002))

### Standardize the data (helps with model convergence) ###
rsf.data.du6$std_exp_dist_res_road <- (rsf.data.du6$exp_dist_res_road - 
                                                 mean (rsf.data.du6$exp_dist_res_road)) / 
                                                 sd (rsf.data.du6$exp_dist_res_road)
rsf.data.du6$std_exp_dist_cut_10 <- (rsf.data.du6$exp_dist_cut_10 - 
                                                 mean (rsf.data.du6$exp_dist_cut_10)) / 
                                                 sd (rsf.data.du6$exp_dist_cut_10)

### Functional Response Covariates ###
#### Calc mean available distance to road and cutblock in home range, by unique individual ####
avail.rsf.data.du6 <- subset (rsf.data.du6, pttype == 0)

std_exp_dist_res_road_E <- tapply (avail.rsf.data.du6$std_exp_dist_res_road, avail.rsf.data.du6$animal_id, mean)
std_exp_dist_cut_10_E <- tapply (avail.rsf.data.du6$std_exp_dist_cut_10, avail.rsf.data.du6$animal_id, mean)
inds <- as.character (rsf.data.du6$animal_id)
rsf.data.du6 <- cbind (rsf.data.du6, "dist_rd_E" = std_exp_dist_res_road_E[inds], "dist_cut_E" = std_exp_dist_cut_10_E[inds])


### Generalized Linear Mixed Models (GLMMs) ###
#### First, determine the random effects structure #####

# Individual animal
model.lme4.du6.animal <- glmer (pttype ~ 1 + (1 | animal_id), # random effect for animal
                                 data = rsf.data.du6, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 

#### Season ####
model.lme4.du6.season <- glmer (pttype ~ wetland_demars + (1 | season), # random effect for season
                                 data = rsf.data.du6, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# failed to converge
# check singularity; should be far from zero
tt <- getME(model.lme4.du6.season,"theta")
ll <- getME(model.lme4.du6.season,"lower")
min(tt[ll==0]) # 0.3581371

# check gradietn calcs; should be > 0.001
derivs1 <- model.lme4.du6.season@optinfo$derivs
sc_grad1 <- with(derivs1,solve(Hessian,gradient))
max(abs(sc_grad1))


#### Individual animal and Season ####
model.lme4.du6.anim.seas <- glmer (pttype ~ wetland_demars + (1 | animal_id) + (1 | season), # random effect intercepts for indivudal and season
                                    data = rsf.data.du6, 
                                    family = binomial (link = "logit"),
                                    verbose = T) 
# failed to converge

# Compare models 
anova (model.lme4.du6.animal, model.lme4.du6.season, model.lme4.du6.anim.seas)

#----------------
# NOTE: season random effect causes convergenece failures, dropped that from the model
#----------------

#### Second, determine the fixed effects structure #####
### Build an AIC Table ###
table.aic <- data.frame (matrix (ncol = 5, nrow = 0))
colnames (table.aic) <- c ("DU", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw")

#### Wetland only model ####
model.lme4.du6.wetland <- glmer (pttype ~ wetland_demars + (1 | animal_id), # random effect for animal
                                  data = rsf.data.du6, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
ss <- getME (model.lme4.du6.wetland, c ("theta","fixef"))
model.lme4.du6.wetland <- update (model.lme4.du6.wetland, start = ss, control = glmerControl (optCtrl = list (maxfun=2e4)))
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Wetland"
table.aic [1, 3] <- "(1 | animal_id)"
table.aic [1, 4] <-  AIC (model.lme4.du6.wetland)

# Dist Road model
model.lme4.du6.road <- glmer (pttype ~ std_exp_dist_res_road + (1 | animal_id),
                                 data = rsf.data.du6, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Distance to Resource Road"
table.aic [2, 3] <- "(1 | animal_id)"
table.aic [2, 4] <-  AIC (model.lme4.du6.road)

# Dist Cut model
model.lme4.du6.cut <- glmer (pttype ~ std_exp_dist_cut_10 + (1 | animal_id),
                             data = rsf.data.du6, 
                             family = binomial (link = "logit"),
                             verbose = T) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Distance to Cutblock >9 years old"
table.aic [3, 3] <- "(1 | animal_id)"
table.aic [3, 4] <-  AIC (model.lme4.du6.cut)

# Dist Road and Cut model
model.lme4.du6.rd.cut <- glmer (pttype ~ std_exp_dist_res_road + std_exp_dist_cut_10 + (1 | animal_id),
                                 data = rsf.data.du6, 
                                 family = binomial (link = "logit"),
                                 verbose = T) 
# AIC
table.aic [4, 1] <- "DU6"
table.aic [4, 2] <- "Distance to Resource Road + Distance to Cutblock >9 years old"
table.aic [4, 3] <- "(1 | animal_id)"
table.aic [4, 4] <-  AIC (model.lme4.du6.rd.cut)

# Dist Road Fxn Response
model.lme4.du6.rd.fxn <- glmer (pttype ~ std_exp_dist_res_road + dist_rd_E + std_exp_dist_res_road*dist_rd_E + (1 | animal_id),
                                data = rsf.data.du6, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [5, 1] <- "DU6"
table.aic [5, 2] <- "Distance to Resource Road + Available Distance to Resource Road + Distance to Resource Road*Available Distance to Resource Road"
table.aic [5, 3] <- "(1 | animal_id)"
table.aic [5, 4] <-  AIC (model.lme4.du6.rd.fxn)

# doesn't look like the effect changes across varying dist road
scatter3D (rsf.data.du6$distance_to_resource_road, (predict (model.lme4.du6.rd.fxn,
                                                             newdata = rsf.data.du6, 
                                                             re.form = NA, type = "response")), rsf.data.du6$dist_rd_E)
# Dist Cut Fxn Response
model.lme4.du6.cut.fxn <- glmer (pttype ~ std_exp_dist_cut_10 + dist_cut_E + std_exp_dist_cut_10*dist_cut_E + (1 | animal_id),
                                data = rsf.data.du6, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [6, 1] <- "DU6"
table.aic [6, 2] <- "Distance to Cutblock >9 years old + Available Distance to Cutblock + Distance to Cutblock >9 years old*Available Distance to Cutblock"
table.aic [6, 3] <- "(1 | animal_id)"
table.aic [6, 4] <-  AIC (model.lme4.du6.cut.fxn)

# doesn't look like the effect changes across varying dist cut
scatter3D(rsf.data.du6$distance_to_cut_10yoorOver, (predict (model.lme4.du6.cut.fxn,
                                                   newdata = rsf.data.du6, 
                                                    re.form = NA, type = "response")), rsf.data.du6$dist_cut_E)
# Wetland, Dist Road and Cut model
model.lme4.du6.all <- glmer (pttype ~ wetland_demars + std_exp_dist_res_road + std_exp_dist_cut_10 + (1 | animal_id),
                                data = rsf.data.du6, 
                                family = binomial (link = "logit"),
                                verbose = T) 
# AIC
table.aic [7, 1] <- "DU6"
table.aic [7, 2] <- "Wetland + Distance to Resource Road + Distance to Cutblock >9 years old"
table.aic [7, 3] <- "(1 | animal_id)"
table.aic [7, 4] <-  AIC (model.lme4.du6.all)

# Wetland, Dist Road (fxn) and Cut model
model.lme4.du6.all.fxn <- glmer (pttype ~ wetland_demars + std_exp_dist_res_road + std_exp_dist_cut_10 + dist_rd_E + std_exp_dist_res_road*dist_rd_E + (1 | animal_id),
                             data = rsf.data.du6, 
                             family = binomial (link = "logit"),
                             verbose = T) 
# AIC
table.aic [8, 1] <- "DU6"
table.aic [8, 2] <- "Wetland + Distance to Resource Road + Distance to Cutblock >9 years old + Available Distance to Resource Road + Distance to Resource Road*Available Distance to Resource Road"
table.aic [8, 3] <- "(1 | animal_id)"
table.aic [8, 4] <-  AIC (model.lme4.du6.all.fxn)

scatter3D (x = rsf.data.du6$distance_to_resource_road, 
           y = rsf.data.du6$exp_dist_res_road , 
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
model.coeffs$mean <- 0
model.coeffs$sd <- 0

model.coeffs [9, 5] <- mean (rsf.data.du6$distance_to_resource_road)
model.coeffs [10, 5] <- mean (rsf.data.du6$distance_to_cut_10yoorOver)

model.coeffs [9, 6] <- sd (rsf.data.du6$distance_to_resource_road)
model.coeffs [10, 6] <- sd (rsf.data.du6$distance_to_cut_10yoorOver)

write.table (model.coeffs, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\model_coefficients\\table_du6_summ_model_coeffs_top.csv", sep = ",")
