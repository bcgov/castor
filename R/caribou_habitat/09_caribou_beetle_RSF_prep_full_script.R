# Copyright 2018 Province of British Columbia
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
#  Script Name: 09_caribou_beetle_RSF_prep_full_script.R
#  Script Version: 1.0
#  Script Purpose: Script exploring/analysing distance to burn data to identify covariates to 
#                 include in RSF model.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 11 January 2018
#  R Version: 
#  R Packages: 
#  Data: 
#=================================
options (scipen = 999)
require (RPostgreSQL)
require (dplyr)
require (ggplot2)
require (raster)
require (rgdal)
require (tidyr)
# require (snow)
require (ggcorrplot)
require (rpart)
require (car)
require (reshape2)
require (lme4)
require (mgcv)
require (gamm4)
require (lattice)
require (ROCR)

#================
# Beetle Data
#===============
beetle.data <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_beetle_age.csv")

#=================================
# Data exploration/visualization
#=================================

#########
## DU6 ## 
########
beetle.data.du.6 <- beetle.data %>%
                      dplyr::filter (du == "du6")
corr.beetle.du6 <- round (cor (beetle.data.du.6 [c (10:32)], method = "spearman"), 3)
ggcorrplot (corr.beetle.du6, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU6 Beetle Infestation Correlation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_beetle_corr_du6.png")

#########
## DU7 ## 
########
beetle.data.du.7 <- beetle.data %>%
                      dplyr::filter (du == "du7")
corr.beetle.du7 <- round (cor (beetle.data.du.7 [c (10:32)], method = "spearman"), 3)
ggcorrplot (corr.beetle.du7, type = "lower", lab = TRUE, tl.cex = 8,  lab_size = 2, 
            title = "DU7 Beetle Infestation Correlation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_beetle_corr_du7.png")

#########
## DU8 ## 
########
beetle.data.du.8 <- beetle.data %>%
                      dplyr::filter (du == "du8")
corr.beetle.du8 <- round (cor (beetle.data.du.8 [c (10:32)], method = "spearman"), 3)
ggcorrplot (corr.beetle.du8, type = "lower", lab = TRUE, tl.cex = 8,  lab_size = 2, 
            title = "DU8 Beetle Infestation Correlation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_beetle_corr_du8.png")

#########
## DU9 ## 
########
beetle.data.du.9 <- beetle.data %>%
                       dplyr::filter (du == "du9")
corr.beetle.du9 <- round (cor (beetle.data.du.9 [c (10:32)], method = "spearman"), 3)
ggcorrplot (corr.beetle.du9, type = "lower", lab = TRUE, tl.cex = 8,  lab_size = 2, 
            title = "DU9 Beetle Infestation Correlation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_beetle_corr_du9.png")

#=============================================================================
# Classification and regression trees to see how the covariates relate to use
#=============================================================================

#########
## DU6 ## 
########
beetle.data.du.6 <- beetle.data %>%
                      dplyr::filter (du == "du6")
cart.beetle.du6 <- rpart (pttype ~ beetle_moderate_1yo + beetle_moderate_2yo + beetle_moderate_3yo +
                                   beetle_moderate_4yo + beetle_moderate_5yo + beetle_moderate_6yo +
                                   beetle_moderate_7yo + beetle_moderate_8yo + beetle_moderate_9yo +
                                   beetle_severe_1yo + beetle_severe_2yo + beetle_severe_3yo +
                                   beetle_severe_4yo + beetle_severe_5yo + beetle_severe_6yo +
                                   beetle_severe_7yo + beetle_severe_8yo + beetle_severe_9yo +
                                   beetle_very_severe_1yo + beetle_very_severe_2yo +
                                   beetle_very_severe_3yo + beetle_very_severe_4yo + beetle_very_severe_5yo,
                            data = beetle.data.du.6, 
                            method = "class")
summary (cart.beetle.du6)
print (cart.beetle.du6)
plot (cart.beetle.du6, uniform = T)
text (cart.beetle.du6, use.n = T, splits = T, fancy = F)
post (cart.beetle.du6, file = "", uniform = T)
# Nothing to see here

#########
## DU7 ## 
########
beetle.data.du.7 <- beetle.data %>%
                      dplyr::filter (du == "du7")
cart.beetle.du7 <- rpart (pttype ~ beetle_moderate_1yo + beetle_moderate_2yo + beetle_moderate_3yo +
                            beetle_moderate_4yo + beetle_moderate_5yo + beetle_moderate_6yo +
                            beetle_moderate_7yo + beetle_moderate_8yo + beetle_moderate_9yo +
                            beetle_severe_1yo + beetle_severe_2yo + beetle_severe_3yo +
                            beetle_severe_4yo + beetle_severe_5yo + beetle_severe_6yo +
                            beetle_severe_7yo + beetle_severe_8yo + beetle_severe_9yo +
                            beetle_very_severe_1yo + beetle_very_severe_2yo +
                            beetle_very_severe_3yo + beetle_very_severe_4yo + beetle_very_severe_5yo,
                          data = beetle.data.du.7, 
                          method = "class")
summary (cart.beetle.du7)
print (cart.beetle.du7)
plot (cart.beetle.du7, uniform = T)
text (cart.beetle.du7, use.n = T, splits = T, fancy = F)
post (cart.beetle.du7, file = "", uniform = T)

#########
## DU8 ## 
########
beetle.data.du.8 <- beetle.data %>%
                      dplyr::filter (du == "du8")
cart.beetle.du8 <- rpart (pttype ~ beetle_moderate_1yo + beetle_moderate_2yo + beetle_moderate_3yo +
                            beetle_moderate_4yo + beetle_moderate_5yo + beetle_moderate_6yo +
                            beetle_moderate_7yo + beetle_moderate_8yo + beetle_moderate_9yo +
                            beetle_severe_1yo + beetle_severe_2yo + beetle_severe_3yo +
                            beetle_severe_4yo + beetle_severe_5yo + beetle_severe_6yo +
                            beetle_severe_7yo + beetle_severe_8yo + beetle_severe_9yo +
                            beetle_very_severe_1yo + beetle_very_severe_2yo +
                            beetle_very_severe_3yo + beetle_very_severe_4yo + beetle_very_severe_5yo,
                          data = beetle.data.du.8, 
                          method = "class")
summary (cart.beetle.du8)
print (cart.beetle.du8)
plot (cart.beetle.du8, uniform = T)
text (cart.beetle.du8, use.n = T, splits = T, fancy = F)
post (cart.beetle.du8, file = "", uniform = T)

#########
## DU9 ## 
########
beetle.data.du.9 <- beetle.data %>%
                      dplyr::filter (du == "du9")
cart.beetle.du9 <- rpart (pttype ~ beetle_moderate_1yo + beetle_moderate_2yo + beetle_moderate_3yo +
                            beetle_moderate_4yo + beetle_moderate_5yo + beetle_moderate_6yo +
                            beetle_moderate_7yo + beetle_moderate_8yo + beetle_moderate_9yo +
                            beetle_severe_1yo + beetle_severe_2yo + beetle_severe_3yo +
                            beetle_severe_4yo + beetle_severe_5yo + beetle_severe_6yo +
                            beetle_severe_7yo + beetle_severe_8yo + beetle_severe_9yo +
                            beetle_very_severe_1yo + beetle_very_severe_2yo +
                            beetle_very_severe_3yo + beetle_very_severe_4yo + beetle_very_severe_5yo,
                          data = beetle.data.du.9, 
                          method = "class")
summary (cart.beetle.du9)
print (cart.beetle.du9)
plot (cart.beetle.du9, uniform = T)
text (cart.beetle.du9, use.n = T, splits = T, fancy = F)
post (cart.beetle.du9, file = "", uniform = T)

#====================================
# GLMs, by year
#===================================
# filter data by DU and season
beetle.data.du.6.ew <- beetle.data %>%
                        dplyr::filter (du == "du6") %>% 
                        dplyr::filter (season == "EarlyWinter")
beetle.data.du.6.lw <- beetle.data %>%
                        dplyr::filter (du == "du6") %>% 
                        dplyr::filter (season == "LateWinter")
beetle.data.du.6.s <- beetle.data %>%
                          dplyr::filter (du == "du6") %>% 
                          dplyr::filter (season == "Summer")

beetle.data.du.7.ew <- beetle.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "EarlyWinter")
beetle.data.du.7.lw <- beetle.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "LateWinter")
beetle.data.du.7.s <- beetle.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "Summer")

beetle.data.du.8.ew <- beetle.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "EarlyWinter")
beetle.data.du.8.lw <- beetle.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "LateWinter")
beetle.data.du.8.s <- beetle.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "Summer")

beetle.data.du.9.ew <- beetle.data %>%
  dplyr::filter (du == "du9") %>% 
  dplyr::filter (season == "EarlyWinter")
beetle.data.du.9.lw <- beetle.data %>%
  dplyr::filter (du == "du9") %>% 
  dplyr::filter (season == "LateWinter")
beetle.data.du.9.s <- beetle.data %>%
  dplyr::filter (du == "du9") %>% 
  dplyr::filter (season == "Summer")

# summary table
table.glm.summary.insect <- data.frame (matrix (ncol = 6, nrow = 0))
colnames (table.glm.summary.insect ) <- c ("DU", "Season", "Severity", "Years Old", "Coefficient", "p-values")

## DU6 ###
### Early Winter ###
glm.du.6.ew.1yo.m <- glm (pttype ~ beetle_moderate_1yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [1, 1] <- "6"
table.glm.summary.insect  [1, 2] <- "Early Winter"
table.glm.summary.insect  [1, 3] <- "Moderate"
table.glm.summary.insect  [1, 4] <- 1
table.glm.summary.insect [1, 5] <- glm.du.6.ew.1yo.m$coefficients [[2]]
table.glm.summary.insect [1, 6] <- summary (glm.du.6.ew.1yo.m)$coefficients[2, 4] # p-value
rm (glm.du.6.ew.1yo.m)
gc ()

glm.du.6.ew.2yo.m <- glm (pttype ~ beetle_moderate_2yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [2, 1] <- "6"
table.glm.summary.insect  [2, 2] <- "Early Winter"
table.glm.summary.insect  [2, 3] <- "Moderate"
table.glm.summary.insect  [2, 4] <- 2
table.glm.summary.insect [2, 5] <- glm.du.6.ew.2yo.m$coefficients [[2]]
table.glm.summary.insect [2, 6] <- summary (glm.du.6.ew.2yo.m)$coefficients[2, 4] # p-value
rm (glm.du.6.ew.2yo.m)
gc ()

glm.du.6.ew.3yo.m <- glm (pttype ~ beetle_moderate_3yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [3, 1] <- "6"
table.glm.summary.insect  [3, 2] <- "Early Winter"
table.glm.summary.insect  [3, 3] <- "Moderate"
table.glm.summary.insect  [3, 4] <- 3
table.glm.summary.insect [3, 5] <- glm.du.6.ew.3yo.m$coefficients [[2]]
table.glm.summary.insect [3, 6] <- summary (glm.du.6.ew.3yo.m)$coefficients[2, 4] # p-value
rm (glm.du.6.ew.3yo.m)
gc ()

glm.du.6.ew.4yo.m <- glm (pttype ~ beetle_moderate_4yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [4, 1] <- "6"
table.glm.summary.insect  [4, 2] <- "Early Winter"
table.glm.summary.insect  [4, 3] <- "Moderate"
table.glm.summary.insect  [4, 4] <- 4
table.glm.summary.insect [4, 5] <- glm.du.6.ew.4yo.m$coefficients [[2]]
table.glm.summary.insect [4, 6] <- summary (glm.du.6.ew.4yo.m)$coefficients[2, 4] # p-value
rm (glm.du.6.ew.4yo.m)
gc ()

glm.du.6.ew.5yo.m <- glm (pttype ~ beetle_moderate_5yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [5, 1] <- "6"
table.glm.summary.insect  [5, 2] <- "Early Winter"
table.glm.summary.insect  [5, 3] <- "Moderate"
table.glm.summary.insect  [5, 4] <- 5
table.glm.summary.insect [5, 5] <- glm.du.6.ew.5yo.m$coefficients [[2]]
table.glm.summary.insect [5, 6] <- summary (glm.du.6.ew.5yo.m)$coefficients[2, 4] # p-value
rm (glm.du.6.ew.5yo.m)
gc ()

glm.du.6.ew.6yo.m <- glm (pttype ~ beetle_moderate_6yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [6, 1] <- "6"
table.glm.summary.insect  [6, 2] <- "Early Winter"
table.glm.summary.insect  [6, 3] <- "Moderate"
table.glm.summary.insect  [6, 4] <- 6
table.glm.summary.insect [6, 5] <- glm.du.6.ew.6yo.m$coefficients [[2]]
table.glm.summary.insect [6, 6] <- summary (glm.du.6.ew.6yo.m)$coefficients[2, 4] # p-value
rm (glm.du.6.ew.6yo.m)
gc ()

glm.du.6.ew.7yo.m <- glm (pttype ~ beetle_moderate_7yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [7, 1] <- "6"
table.glm.summary.insect  [7, 2] <- "Early Winter"
table.glm.summary.insect  [7, 3] <- "Moderate"
table.glm.summary.insect  [7, 4] <- 7
table.glm.summary.insect [7, 5] <- glm.du.6.ew.7yo.m$coefficients [[2]]
table.glm.summary.insect [7, 6] <- summary (glm.du.6.ew.7yo.m)$coefficients[2, 4] # p-value
rm (glm.du.6.ew.7yo.m)
gc ()

glm.du.6.ew.8yo.m <- glm (pttype ~ beetle_moderate_8yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [8, 1] <- "6"
table.glm.summary.insect  [8, 2] <- "Early Winter"
table.glm.summary.insect  [8, 3] <- "Moderate"
table.glm.summary.insect  [8, 4] <- 8
table.glm.summary.insect [8, 5] <- glm.du.6.ew.8yo.m$coefficients [[2]]
table.glm.summary.insect [8, 6] <- summary (glm.du.6.ew.8yo.m)$coefficients[2, 4] # p-value
rm (glm.du.6.ew.8yo.m)
gc ()

glm.du.6.ew.9yo.m <- glm (pttype ~ beetle_moderate_9yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [9, 1] <- "6"
table.glm.summary.insect  [9, 2] <- "Early Winter"
table.glm.summary.insect  [9, 3] <- "Moderate"
table.glm.summary.insect  [9, 4] <- 9
table.glm.summary.insect [9, 5] <- NA
table.glm.summary.insect [9, 6] <- NA
rm (glm.du.6.ew.9yo.m)
gc ()

glm.du.6.ew.1yo.s <- glm (pttype ~ beetle_severe_1yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [10, 1] <- "6"
table.glm.summary.insect  [10, 2] <- "Early Winter"
table.glm.summary.insect  [10, 3] <- "Severe"
table.glm.summary.insect  [10, 4] <- 1
table.glm.summary.insect [10, 5] <- glm.du.6.ew.1yo.s$coefficients [[2]]
table.glm.summary.insect [10, 6] <- summary (glm.du.6.ew.1yo.s)$coefficients[2, 4] # p-value
rm (glm.du.6.ew.1yo.s)
gc ()

glm.du.6.ew.2yo.s <- glm (pttype ~ beetle_severe_2yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [11, 1] <- "6"
table.glm.summary.insect  [11, 2] <- "Early Winter"
table.glm.summary.insect  [11, 3] <- "Severe"
table.glm.summary.insect  [11, 4] <- 2
table.glm.summary.insect [11, 5] <- glm.du.6.ew.2yo.s$coefficients [[2]]
table.glm.summary.insect [11, 6] <- summary (glm.du.6.ew.2yo.s)$coefficients[2, 4] # p-value
rm (glm.du.6.ew.2yo.s)
gc ()

glm.du.6.ew.3yo.s <- glm (pttype ~ beetle_severe_3yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [12, 1] <- "6"
table.glm.summary.insect  [12, 2] <- "Early Winter"
table.glm.summary.insect  [12, 3] <- "Severe"
table.glm.summary.insect  [12, 4] <- 3
table.glm.summary.insect [12, 5] <- glm.du.6.ew.3yo.s$coefficients [[2]]
table.glm.summary.insect [12, 6] <- summary (glm.du.6.ew.3yo.s)$coefficients[2, 4] # p-value
rm (glm.du.6.ew.3yo.s)
gc ()

glm.du.6.ew.4yo.s <- glm (pttype ~ beetle_severe_4yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [13, 1] <- "6"
table.glm.summary.insect  [13, 2] <- "Early Winter"
table.glm.summary.insect  [13, 3] <- "Severe"
table.glm.summary.insect  [13, 4] <- 4
table.glm.summary.insect [13, 5] <- glm.du.6.ew.4yo.s$coefficients [[2]]
table.glm.summary.insect [13, 6] <- summary (glm.du.6.ew.4yo.s)$coefficients[2, 4] # p-value
rm (glm.du.6.ew.4yo.s)
gc ()

glm.du.6.ew.5yo.s <- glm (pttype ~ beetle_severe_5yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [14, 1] <- "6"
table.glm.summary.insect  [14, 2] <- "Early Winter"
table.glm.summary.insect  [14, 3] <- "Severe"
table.glm.summary.insect  [14, 4] <- 5
table.glm.summary.insect [14, 5] <- glm.du.6.ew.5yo.s$coefficients [[2]]
table.glm.summary.insect [14, 6] <- summary (glm.du.6.ew.5yo.s)$coefficients[2, 4]
rm (glm.du.6.ew.5yo.s)
gc ()

glm.du.6.ew.6yo.s <- glm (pttype ~ beetle_severe_6yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [15, 1] <- "6"
table.glm.summary.insect  [15, 2] <- "Early Winter"
table.glm.summary.insect  [15, 3] <- "Severe"
table.glm.summary.insect  [15, 4] <- 6
table.glm.summary.insect [15, 5] <- NA
table.glm.summary.insect [15, 6] <- NA # p-value
rm (glm.du.6.ew.6yo.s)
gc ()

glm.du.6.ew.7yo.s <- glm (pttype ~ beetle_severe_7yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [16, 1] <- "6"
table.glm.summary.insect  [16, 2] <- "Early Winter"
table.glm.summary.insect  [16, 3] <- "Severe"
table.glm.summary.insect  [16, 4] <- 7
table.glm.summary.insect [16, 5] <- NA
table.glm.summary.insect [16, 6] <- NA
rm (glm.du.6.ew.7yo.s)
gc ()

glm.du.6.ew.8yo.s <- glm (pttype ~ beetle_severe_8yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [17, 1] <- "6"
table.glm.summary.insect  [17, 2] <- "Early Winter"
table.glm.summary.insect  [17, 3] <- "Severe"
table.glm.summary.insect  [17, 4] <- 8
table.glm.summary.insect [17, 5] <- NA
table.glm.summary.insect [17, 6] <- NA
rm (glm.du.6.ew.8yo.s)
gc ()

glm.du.6.ew.9yo.s <- glm (pttype ~ beetle_severe_9yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [18, 1] <- "6"
table.glm.summary.insect  [18, 2] <- "Early Winter"
table.glm.summary.insect  [18, 3] <- "Severe"
table.glm.summary.insect  [18, 4] <- 8
table.glm.summary.insect [18, 5] <- NA
table.glm.summary.insect [18, 6] <- NA
rm (glm.du.6.ew.9yo.s)
gc ()

glm.du.6.ew.1yo.vs <- glm (pttype ~ beetle_very_severe_1yo, 
                          data = beetle.data.du.6.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect [19, 1] <- "6"
table.glm.summary.insect [19, 2] <- "Early Winter"
table.glm.summary.insect [19, 3] <- "Very Severe"
table.glm.summary.insect [19, 4] <- 1
table.glm.summary.insect [19, 5] <- NA
table.glm.summary.insect [19, 6] <- NA
rm (glm.du.6.ew.1yo.vs)
gc ()

glm.du.6.ew.2yo.vs <- glm (pttype ~ beetle_very_severe_2yo, 
                           data = beetle.data.du.6.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [20, 1] <- "6"
table.glm.summary.insect [20, 2] <- "Early Winter"
table.glm.summary.insect [20, 3] <- "Very Severe"
table.glm.summary.insect [20, 4] <- 2
table.glm.summary.insect [20, 5] <- NA
table.glm.summary.insect [20, 6] <- NA
rm (glm.du.6.ew.2yo.vs)
gc ()

glm.du.6.ew.3yo.vs <- glm (pttype ~ beetle_very_severe_3yo, 
                           data = beetle.data.du.6.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [21, 1] <- "6"
table.glm.summary.insect [21, 2] <- "Early Winter"
table.glm.summary.insect [21, 3] <- "Very Severe"
table.glm.summary.insect [21, 4] <- 3
table.glm.summary.insect [21, 5] <- NA
table.glm.summary.insect [21, 6] <- NA
rm (glm.du.6.ew.3yo.vs)
gc ()

glm.du.6.ew.4yo.vs <- glm (pttype ~ beetle_very_severe_4yo, 
                           data = beetle.data.du.6.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [22, 1] <- "6"
table.glm.summary.insect [22, 2] <- "Early Winter"
table.glm.summary.insect [22, 3] <- "Very Severe"
table.glm.summary.insect [22, 4] <- 4
table.glm.summary.insect [22, 5] <- NA
table.glm.summary.insect [22, 6] <- NA
rm (glm.du.6.ew.4yo.vs)
gc ()

glm.du.6.ew.5yo.vs <- glm (pttype ~ beetle_very_severe_5yo, 
                           data = beetle.data.du.6.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [23, 1] <- "6"
table.glm.summary.insect [23, 2] <- "Early Winter"
table.glm.summary.insect [23, 3] <- "Very Severe"
table.glm.summary.insect [23, 4] <- 5
table.glm.summary.insect [23, 5] <- NA
table.glm.summary.insect [23, 6] <- NA
rm (glm.du.6.ew.5yo.vs)
gc ()

### Late Winter ###
glm.du.6.lw.1yo.m <- glm (pttype ~ beetle_moderate_1yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [24, 1] <- "6"
table.glm.summary.insect  [24, 2] <- "Late Winter"
table.glm.summary.insect  [24, 3] <- "Moderate"
table.glm.summary.insect  [24, 4] <- 1
table.glm.summary.insect [24, 5] <- glm.du.6.lw.1yo.m$coefficients [[2]]
table.glm.summary.insect [24, 6] <- summary (glm.du.6.lw.1yo.m)$coefficients[2, 4]
rm (glm.du.6.lw.1yo.m)
gc ()

glm.du.6.lw.2yo.m <- glm (pttype ~ beetle_moderate_2yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [25, 1] <- "6"
table.glm.summary.insect  [25, 2] <- "Late Winter"
table.glm.summary.insect  [25, 3] <- "Moderate"
table.glm.summary.insect  [25, 4] <- 2
table.glm.summary.insect [25, 5] <- glm.du.6.lw.2yo.m$coefficients [[2]]
table.glm.summary.insect [25, 6] <- summary (glm.du.6.lw.2yo.m)$coefficients[2, 4]
rm (glm.du.6.lw.2yo.m)
gc ()

glm.du.6.lw.3yo.m <- glm (pttype ~ beetle_moderate_3yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [26, 1] <- "6"
table.glm.summary.insect  [26, 2] <- "Late Winter"
table.glm.summary.insect  [26, 3] <- "Moderate"
table.glm.summary.insect  [26, 4] <- 3
table.glm.summary.insect [26, 5] <- glm.du.6.lw.3yo.m$coefficients [[2]]
table.glm.summary.insect [26, 6] <- summary (glm.du.6.lw.3yo.m)$coefficients[2, 4]
rm (glm.du.6.lw.3yo.m)
gc ()

glm.du.6.lw.4yo.m <- glm (pttype ~ beetle_moderate_4yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [27, 1] <- "6"
table.glm.summary.insect  [27, 2] <- "Late Winter"
table.glm.summary.insect  [27, 3] <- "Moderate"
table.glm.summary.insect  [27, 4] <- 4
table.glm.summary.insect [27, 5] <- glm.du.6.lw.4yo.m$coefficients [[2]]
table.glm.summary.insect [27, 6] <- summary (glm.du.6.lw.4yo.m)$coefficients[2, 4]
rm (glm.du.6.lw.4yo.m)
gc ()

glm.du.6.lw.5yo.m <- glm (pttype ~ beetle_moderate_5yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [28, 1] <- "6"
table.glm.summary.insect  [28, 2] <- "Late Winter"
table.glm.summary.insect  [28, 3] <- "Moderate"
table.glm.summary.insect  [28, 4] <- 5
table.glm.summary.insect [28, 5] <- glm.du.6.lw.5yo.m$coefficients [[2]]
table.glm.summary.insect [28, 6] <- summary (glm.du.6.lw.5yo.m)$coefficients[2, 4]
rm (glm.du.6.lw.5yo.m)
gc ()

glm.du.6.lw.6yo.m <- glm (pttype ~ beetle_moderate_6yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [29, 1] <- "6"
table.glm.summary.insect  [29, 2] <- "Late Winter"
table.glm.summary.insect  [29, 3] <- "Moderate"
table.glm.summary.insect  [29, 4] <- 6
table.glm.summary.insect [29, 5] <- glm.du.6.lw.6yo.m$coefficients [[2]]
table.glm.summary.insect [29, 6] <- summary (glm.du.6.lw.6yo.m)$coefficients[2, 4]
rm (glm.du.6.lw.6yo.m)
gc ()

glm.du.6.lw.7yo.m <- glm (pttype ~ beetle_moderate_7yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [30, 1] <- "6"
table.glm.summary.insect  [30, 2] <- "Late Winter"
table.glm.summary.insect  [30, 3] <- "Moderate"
table.glm.summary.insect  [30, 4] <- 7
table.glm.summary.insect [30, 5] <- glm.du.6.lw.7yo.m$coefficients [[2]]
table.glm.summary.insect [30, 6] <- summary (glm.du.6.lw.7yo.m)$coefficients[2, 4]
rm (glm.du.6.lw.7yo.m)
gc ()

glm.du.6.lw.8yo.m <- glm (pttype ~ beetle_moderate_8yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [31, 1] <- "6"
table.glm.summary.insect  [31, 2] <- "Late Winter"
table.glm.summary.insect  [31, 3] <- "Moderate"
table.glm.summary.insect  [31, 4] <- 8
table.glm.summary.insect [31, 5] <- glm.du.6.lw.8yo.m$coefficients [[2]]
table.glm.summary.insect [31, 6] <- summary (glm.du.6.lw.8yo.m)$coefficients[2, 4]
rm (glm.du.6.lw.8yo.m)
gc ()

glm.du.6.lw.9yo.m <- glm (pttype ~ beetle_moderate_9yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [32, 1] <- "6"
table.glm.summary.insect  [32, 2] <- "Late Winter"
table.glm.summary.insect  [32, 3] <- "Moderate"
table.glm.summary.insect  [32, 4] <- 9
table.glm.summary.insect [32, 5] <- glm.du.6.lw.9yo.m$coefficients [[2]]
table.glm.summary.insect [32, 6] <- summary (glm.du.6.lw.9yo.m)$coefficients[2, 4]
rm (glm.du.6.lw.9yo.m)
gc ()

glm.du.6.lw.1yo.s <- glm (pttype ~ beetle_severe_1yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [33, 1] <- "6"
table.glm.summary.insect  [33, 2] <- "Late Winter"
table.glm.summary.insect  [33, 3] <- "Severe"
table.glm.summary.insect  [33, 4] <- 1
table.glm.summary.insect [33, 5] <- glm.du.6.lw.1yo.s$coefficients [[2]]
table.glm.summary.insect [33, 6] <- summary (glm.du.6.lw.1yo.s)$coefficients[2, 4]
rm (glm.du.6.lw.1yo.s)
gc ()

glm.du.6.lw.2yo.s <- glm (pttype ~ beetle_severe_2yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [34, 1] <- "6"
table.glm.summary.insect  [34, 2] <- "Late Winter"
table.glm.summary.insect  [34, 3] <- "Severe"
table.glm.summary.insect  [34, 4] <- 2
table.glm.summary.insect [34, 5] <- glm.du.6.lw.2yo.s$coefficients [[2]]
table.glm.summary.insect [34, 6] <- summary (glm.du.6.lw.2yo.s)$coefficients[2, 4]
rm (glm.du.6.lw.2yo.s)
gc ()

glm.du.6.lw.3yo.s <- glm (pttype ~ beetle_severe_3yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [35, 1] <- "6"
table.glm.summary.insect  [35, 2] <- "Late Winter"
table.glm.summary.insect  [35, 3] <- "Severe"
table.glm.summary.insect  [35, 4] <- 3
table.glm.summary.insect [35, 5] <- glm.du.6.lw.3yo.s$coefficients [[2]]
table.glm.summary.insect [35, 6] <- summary (glm.du.6.lw.3yo.s)$coefficients[2, 4]
rm (glm.du.6.lw.3yo.s)
gc ()

glm.du.6.lw.4yo.s <- glm (pttype ~ beetle_severe_4yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [36, 1] <- "6"
table.glm.summary.insect  [36, 2] <- "Late Winter"
table.glm.summary.insect  [36, 3] <- "Severe"
table.glm.summary.insect  [36, 4] <- 4
table.glm.summary.insect [36, 5] <- glm.du.6.lw.4yo.s$coefficients [[2]]
table.glm.summary.insect [36, 6] <- summary (glm.du.6.lw.4yo.s)$coefficients[2, 4]
rm (glm.du.6.lw.4yo.s)
gc ()

glm.du.6.lw.5yo.s <- glm (pttype ~ beetle_severe_5yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [37, 1] <- "6"
table.glm.summary.insect  [37, 2] <- "Late Winter"
table.glm.summary.insect  [37, 3] <- "Severe"
table.glm.summary.insect  [37, 4] <- 5
table.glm.summary.insect [37, 5] <- glm.du.6.lw.5yo.s$coefficients [[2]]
table.glm.summary.insect [37, 6] <- summary (glm.du.6.lw.5yo.s)$coefficients[2, 4]
rm (glm.du.6.lw.5yo.s)
gc ()

glm.du.6.lw.6yo.s <- glm (pttype ~ beetle_severe_6yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [38, 1] <- "6"
table.glm.summary.insect  [38, 2] <- "Late Winter"
table.glm.summary.insect  [38, 3] <- "Severe"
table.glm.summary.insect  [38, 4] <- 6
table.glm.summary.insect [38, 5] <- NA
table.glm.summary.insect [38, 6] <- NA
rm (glm.du.6.lw.6yo.s)
gc ()

glm.du.6.lw.7yo.s <- glm (pttype ~ beetle_severe_7yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [39, 1] <- "6"
table.glm.summary.insect  [39, 2] <- "Late Winter"
table.glm.summary.insect  [39, 3] <- "Severe"
table.glm.summary.insect  [39, 4] <- 7
table.glm.summary.insect [39, 5] <- NA
table.glm.summary.insect [39, 6] <- NA
rm (glm.du.6.lw.7yo.s)
gc ()

glm.du.6.lw.8yo.s <- glm (pttype ~ beetle_severe_8yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [40, 1] <- "6"
table.glm.summary.insect  [40, 2] <- "Late Winter"
table.glm.summary.insect  [40, 3] <- "Severe"
table.glm.summary.insect  [40, 4] <- 8
table.glm.summary.insect [40, 5] <- NA
table.glm.summary.insect [40, 6] <- NA
rm (glm.du.6.lw.8yo.s)
gc ()

glm.du.6.lw.9yo.s <- glm (pttype ~ beetle_severe_9yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [41, 1] <- "6"
table.glm.summary.insect  [41, 2] <- "Late Winter"
table.glm.summary.insect  [41, 3] <- "Severe"
table.glm.summary.insect  [41, 4] <- 9
table.glm.summary.insect [41, 5] <- NA
table.glm.summary.insect [41, 6] <- NA
rm (glm.du.6.lw.9yo.s)
gc ()

glm.du.6.lw.1yo.vs <- glm (pttype ~ beetle_very_severe_1yo, 
                          data = beetle.data.du.6.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect [42, 1] <- "6"
table.glm.summary.insect [42, 2] <- "Late Winter"
table.glm.summary.insect [42, 3] <- "Very Severe"
table.glm.summary.insect [42, 4] <- 1
table.glm.summary.insect [42, 5] <- NA
table.glm.summary.insect [42, 6] <- NA
rm (glm.du.6.lw.1yo.vs)
gc ()

glm.du.6.lw.2yo.vs <- glm (pttype ~ beetle_very_severe_2yo, 
                           data = beetle.data.du.6.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [43, 1] <- "6"
table.glm.summary.insect [43, 2] <- "Late Winter"
table.glm.summary.insect [43, 3] <- "Very Severe"
table.glm.summary.insect [43, 4] <- 2
table.glm.summary.insect [43, 5] <- NA
table.glm.summary.insect [43, 6] <- NA
rm (glm.du.6.lw.2yo.vs)
gc ()

glm.du.6.lw.3yo.vs <- glm (pttype ~ beetle_very_severe_3yo, 
                           data = beetle.data.du.6.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [44, 1] <- "6"
table.glm.summary.insect [44, 2] <- "Late Winter"
table.glm.summary.insect [44, 3] <- "Very Severe"
table.glm.summary.insect [44, 4] <- 3
table.glm.summary.insect [44, 5] <- NA
table.glm.summary.insect [44, 6] <- NA
rm (glm.du.6.lw.3yo.vs)
gc ()

glm.du.6.lw.4yo.vs <- glm (pttype ~ beetle_very_severe_4yo, 
                           data = beetle.data.du.6.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [45, 1] <- "6"
table.glm.summary.insect [45, 2] <- "Late Winter"
table.glm.summary.insect [45, 3] <- "Very Severe"
table.glm.summary.insect [45, 4] <- 4
table.glm.summary.insect [45, 5] <- NA
table.glm.summary.insect [45, 6] <- NA
rm (glm.du.6.lw.4yo.vs)
gc ()

glm.du.6.lw.5yo.vs <- glm (pttype ~ beetle_very_severe_5yo, 
                           data = beetle.data.du.6.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [46, 1] <- "6"
table.glm.summary.insect [46, 2] <- "Late Winter"
table.glm.summary.insect [46, 3] <- "Very Severe"
table.glm.summary.insect [46, 4] <- 5
table.glm.summary.insect [46, 5] <- NA
table.glm.summary.insect [46, 6] <- NA
rm (glm.du.6.lw.5yo.vs)
gc ()

### Summer ###
glm.du.6.s.1yo.m <- glm (pttype ~ beetle_moderate_1yo, 
                          data = beetle.data.du.6.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [47, 1] <- "6"
table.glm.summary.insect  [47, 2] <- "Summer"
table.glm.summary.insect  [47, 3] <- "Moderate"
table.glm.summary.insect  [47, 4] <- 1
table.glm.summary.insect [47, 5] <- glm.du.6.s.1yo.m$coefficients [[2]]
table.glm.summary.insect [47, 6] <- summary (glm.du.6.s.1yo.m)$coefficients[2, 4]
rm (glm.du.6.s.1yo.m)
gc ()

glm.du.6.s.2yo.m <- glm (pttype ~ beetle_moderate_2yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect  [48, 1] <- "6"
table.glm.summary.insect  [48, 2] <- "Summer"
table.glm.summary.insect  [48, 3] <- "Moderate"
table.glm.summary.insect  [48, 4] <- 2
table.glm.summary.insect [48, 5] <- glm.du.6.s.2yo.m$coefficients [[2]]
table.glm.summary.insect [48, 6] <- summary (glm.du.6.s.2yo.m)$coefficients[2, 4]
rm (glm.du.6.s.2yo.m)
gc ()

glm.du.6.s.3yo.m <- glm (pttype ~ beetle_moderate_3yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect  [49, 1] <- "6"
table.glm.summary.insect  [49, 2] <- "Summer"
table.glm.summary.insect  [49, 3] <- "Moderate"
table.glm.summary.insect  [49, 4] <- 3
table.glm.summary.insect [49, 5] <- glm.du.6.s.3yo.m$coefficients [[2]]
table.glm.summary.insect [49, 6] <- summary (glm.du.6.s.3yo.m)$coefficients[2, 4]
rm (glm.du.6.s.3yo.m)
gc ()

glm.du.6.s.4yo.m <- glm (pttype ~ beetle_moderate_4yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect  [50, 1] <- "6"
table.glm.summary.insect  [50, 2] <- "Summer"
table.glm.summary.insect  [50, 3] <- "Moderate"
table.glm.summary.insect  [50, 4] <- 4
table.glm.summary.insect [50, 5] <- glm.du.6.s.4yo.m$coefficients [[2]]
table.glm.summary.insect [50, 6] <- summary (glm.du.6.s.4yo.m)$coefficients[2, 4]
rm (glm.du.6.s.4yo.m)
gc ()

glm.du.6.s.5yo.m <- glm (pttype ~ beetle_moderate_5yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect  [51, 1] <- "6"
table.glm.summary.insect  [51, 2] <- "Summer"
table.glm.summary.insect  [51, 3] <- "Moderate"
table.glm.summary.insect  [51, 4] <- 5
table.glm.summary.insect [51, 5] <- glm.du.6.s.5yo.m$coefficients [[2]]
table.glm.summary.insect [51, 6] <- summary (glm.du.6.s.5yo.m)$coefficients[2, 4]
rm (glm.du.6.s.5yo.m)
gc ()

glm.du.6.s.6yo.m <- glm (pttype ~ beetle_moderate_6yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect  [52, 1] <- "6"
table.glm.summary.insect  [52, 2] <- "Summer"
table.glm.summary.insect  [52, 3] <- "Moderate"
table.glm.summary.insect  [52, 4] <- 6
table.glm.summary.insect [52, 5] <- glm.du.6.s.6yo.m$coefficients [[2]]
table.glm.summary.insect [52, 6] <- summary (glm.du.6.s.6yo.m)$coefficients[2, 4]
rm (glm.du.6.s.6yo.m)
gc ()

glm.du.6.s.7yo.m <- glm (pttype ~ beetle_moderate_7yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect  [53, 1] <- "6"
table.glm.summary.insect  [53, 2] <- "Summer"
table.glm.summary.insect  [53, 3] <- "Moderate"
table.glm.summary.insect  [53, 4] <- 7
table.glm.summary.insect [53, 5] <- glm.du.6.s.7yo.m$coefficients [[2]]
table.glm.summary.insect [53, 6] <- summary (glm.du.6.s.7yo.m)$coefficients[2, 4]
rm (glm.du.6.s.7yo.m)
gc ()

glm.du.6.s.8yo.m <- glm (pttype ~ beetle_moderate_8yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect  [54, 1] <- "6"
table.glm.summary.insect  [54, 2] <- "Summer"
table.glm.summary.insect  [54, 3] <- "Moderate"
table.glm.summary.insect  [54, 4] <- 8
table.glm.summary.insect [54, 5] <- glm.du.6.s.8yo.m$coefficients [[2]]
table.glm.summary.insect [54, 6] <- summary (glm.du.6.s.8yo.m)$coefficients[2, 4]
rm (glm.du.6.s.8yo.m)
gc ()

glm.du.6.s.9yo.m <- glm (pttype ~ beetle_moderate_9yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect  [55, 1] <- "6"
table.glm.summary.insect  [55, 2] <- "Summer"
table.glm.summary.insect  [55, 3] <- "Moderate"
table.glm.summary.insect  [55, 4] <- 9
table.glm.summary.insect [55, 5] <- glm.du.6.s.9yo.m$coefficients [[2]]
table.glm.summary.insect [55, 6] <- summary (glm.du.6.s.9yo.m)$coefficients[2, 4]
rm (glm.du.6.s.9yo.m)
gc ()

glm.du.6.s.1yo.s <- glm (pttype ~ beetle_severe_1yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect [56, 1] <- "6"
table.glm.summary.insect [56, 2] <- "Summer"
table.glm.summary.insect [56, 3] <- "Severe"
table.glm.summary.insect [56, 4] <- 1
table.glm.summary.insect [56, 5] <- glm.du.6.s.1yo.s$coefficients [[2]]
table.glm.summary.insect [56, 6] <- summary (glm.du.6.s.1yo.s)$coefficients[2, 4]
rm (glm.du.6.s.1yo.s)
gc ()

glm.du.6.s.2yo.s <- glm (pttype ~ beetle_severe_2yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect [57, 1] <- "6"
table.glm.summary.insect [57, 2] <- "Summer"
table.glm.summary.insect [57, 3] <- "Severe"
table.glm.summary.insect [57, 4] <- 2
table.glm.summary.insect [57, 5] <- glm.du.6.s.2yo.s$coefficients [[2]]
table.glm.summary.insect [57, 6] <- summary (glm.du.6.s.2yo.s)$coefficients[2, 4]
rm (glm.du.6.s.2yo.s)
gc ()

glm.du.6.s.3yo.s <- glm (pttype ~ beetle_severe_3yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect [58, 1] <- "6"
table.glm.summary.insect [58, 2] <- "Summer"
table.glm.summary.insect [58, 3] <- "Severe"
table.glm.summary.insect [58, 4] <- 3
table.glm.summary.insect [58, 5] <- glm.du.6.s.3yo.s$coefficients [[2]]
table.glm.summary.insect [58, 6] <- summary (glm.du.6.s.3yo.s)$coefficients[2, 4]
rm (glm.du.6.s.3yo.s)
gc ()

glm.du.6.s.4yo.s <- glm (pttype ~ beetle_severe_4yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect [59, 1] <- "6"
table.glm.summary.insect [59, 2] <- "Summer"
table.glm.summary.insect [59, 3] <- "Severe"
table.glm.summary.insect [59, 4] <- 4
table.glm.summary.insect [59, 5] <- glm.du.6.s.4yo.s$coefficients [[2]]
table.glm.summary.insect [59, 6] <- summary (glm.du.6.s.4yo.s)$coefficients[2, 4]
rm (glm.du.6.s.4yo.s)
gc ()

glm.du.6.s.5yo.s <- glm (pttype ~ beetle_severe_5yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect [60, 1] <- "6"
table.glm.summary.insect [60, 2] <- "Summer"
table.glm.summary.insect [60, 3] <- "Severe"
table.glm.summary.insect [60, 4] <- 5
table.glm.summary.insect [60, 5] <- glm.du.6.s.5yo.s$coefficients [[2]]
table.glm.summary.insect [60, 6] <- summary (glm.du.6.s.5yo.s)$coefficients[2, 4]
rm (glm.du.6.s.5yo.s)
gc ()

glm.du.6.s.6yo.s <- glm (pttype ~ beetle_severe_6yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect [61, 1] <- "6"
table.glm.summary.insect [61, 2] <- "Summer"
table.glm.summary.insect [61, 3] <- "Severe"
table.glm.summary.insect [61, 4] <- 6
table.glm.summary.insect [61, 5] <- NA
table.glm.summary.insect [61, 6] <- NA
rm (glm.du.6.s.6yo.s)
gc ()

glm.du.6.s.7yo.s <- glm (pttype ~ beetle_severe_7yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect [62, 1] <- "6"
table.glm.summary.insect [62, 2] <- "Summer"
table.glm.summary.insect [62, 3] <- "Severe"
table.glm.summary.insect [62, 4] <- 7
table.glm.summary.insect [62, 5] <- NA
table.glm.summary.insect [62, 6] <- NA
rm (glm.du.6.s.7yo.s)
gc ()

glm.du.6.s.8yo.s <- glm (pttype ~ beetle_severe_8yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect [63, 1] <- "6"
table.glm.summary.insect [63, 2] <- "Summer"
table.glm.summary.insect [63, 3] <- "Severe"
table.glm.summary.insect [63, 4] <- 8
table.glm.summary.insect [63, 5] <- NA
table.glm.summary.insect [63, 6] <- NA
rm (glm.du.6.s.8yo.s)
gc ()

glm.du.6.s.9yo.s <- glm (pttype ~ beetle_severe_9yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect [64, 1] <- "6"
table.glm.summary.insect [64, 2] <- "Summer"
table.glm.summary.insect [64, 3] <- "Severe"
table.glm.summary.insect [64, 4] <- 9
table.glm.summary.insect [64, 5] <- NA
table.glm.summary.insect [64, 6] <- NA
rm (glm.du.6.s.9yo.s)
gc ()

glm.du.6.s.1yo.vs <- glm (pttype ~ beetle_very_severe_1yo, 
                         data = beetle.data.du.6.s,
                         family = binomial (link = 'logit'))
table.glm.summary.insect [65, 1] <- "6"
table.glm.summary.insect [65, 2] <- "Summer"
table.glm.summary.insect [65, 3] <- "Very Severe"
table.glm.summary.insect [65, 4] <- 1
table.glm.summary.insect [65, 5] <- NA
table.glm.summary.insect [65, 6] <- NA
rm (glm.du.6.s.1yo.vs)
gc ()

glm.du.6.s.2yo.vs <- glm (pttype ~ beetle_very_severe_2yo, 
                          data = beetle.data.du.6.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect [66, 1] <- "6"
table.glm.summary.insect [66, 2] <- "Summer"
table.glm.summary.insect [66, 3] <- "Very Severe"
table.glm.summary.insect [66, 4] <- 2
table.glm.summary.insect [66, 5] <- glm.du.6.s.2yo.vs$coefficients [[2]]
table.glm.summary.insect [66, 6] <- summary (glm.du.6.s.2yo.vs)$coefficients[2, 4]
rm (glm.du.6.s.2yo.vs)
gc ()

glm.du.6.s.3yo.vs <- glm (pttype ~ beetle_very_severe_3yo, 
                          data = beetle.data.du.6.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect [67, 1] <- "6"
table.glm.summary.insect [67, 2] <- "Summer"
table.glm.summary.insect [67, 3] <- "Very Severe"
table.glm.summary.insect [67, 4] <- 3
table.glm.summary.insect [67, 5] <- NA
table.glm.summary.insect [67, 6] <- NA
rm (glm.du.6.s.3yo.vs)
gc ()

glm.du.6.s.4yo.vs <- glm (pttype ~ beetle_very_severe_4yo, 
                          data = beetle.data.du.6.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect [68, 1] <- "6"
table.glm.summary.insect [68, 2] <- "Summer"
table.glm.summary.insect [68, 3] <- "Very Severe"
table.glm.summary.insect [68, 4] <- 4
table.glm.summary.insect [68, 5] <- NA
table.glm.summary.insect [68, 6] <- NA
rm (glm.du.6.s.4yo.vs)
gc ()

glm.du.6.s.5yo.vs <- glm (pttype ~ beetle_very_severe_5yo, 
                          data = beetle.data.du.6.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect [69, 1] <- "6"
table.glm.summary.insect [69, 2] <- "Summer"
table.glm.summary.insect [69, 3] <- "Very Severe"
table.glm.summary.insect [69, 4] <- 5
table.glm.summary.insect [69, 5] <- NA
table.glm.summary.insect [69, 6] <- NA
rm (glm.du.6.s.5yo.vs)
gc ()

## DU7 ###
### Early Winter ###
glm.du.7.ew.1yo.m <- glm (pttype ~ beetle_moderate_1yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [70, 1] <- "7"
table.glm.summary.insect  [70, 2] <- "Early Winter"
table.glm.summary.insect  [70, 3] <- "Moderate"
table.glm.summary.insect  [70, 4] <- 1
table.glm.summary.insect [70, 5] <- glm.du.7.ew.1yo.m$coefficients [[2]]
table.glm.summary.insect [70, 6] <- summary (glm.du.7.ew.1yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.ew.1yo.m)
gc ()

glm.du.7.ew.2yo.m <- glm (pttype ~ beetle_moderate_2yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [71, 1] <- "7"
table.glm.summary.insect  [71, 2] <- "Early Winter"
table.glm.summary.insect  [71, 3] <- "Moderate"
table.glm.summary.insect  [71, 4] <- 2
table.glm.summary.insect [71, 5] <- glm.du.7.ew.2yo.m$coefficients [[2]]
table.glm.summary.insect [71, 6] <- summary (glm.du.7.ew.2yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.ew.2yo.m)
gc ()

glm.du.7.ew.3yo.m <- glm (pttype ~ beetle_moderate_3yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect [72, 1] <- "7"
table.glm.summary.insect [72, 2] <- "Early Winter"
table.glm.summary.insect [72, 3] <- "Moderate"
table.glm.summary.insect [72, 4] <- 3
table.glm.summary.insect [72, 5] <- glm.du.7.ew.3yo.m$coefficients [[2]]
table.glm.summary.insect [72, 6] <- summary (glm.du.7.ew.3yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.ew.3yo.m)
gc ()

glm.du.7.ew.4yo.m <- glm (pttype ~ beetle_moderate_4yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [73, 1] <- "7"
table.glm.summary.insect  [73, 2] <- "Early Winter"
table.glm.summary.insect  [73, 3] <- "Moderate"
table.glm.summary.insect  [73, 4] <- 4
table.glm.summary.insect [73, 5] <- glm.du.7.ew.4yo.m$coefficients [[2]]
table.glm.summary.insect [73, 6] <- summary (glm.du.7.ew.4yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.ew.4yo.m)
gc ()

glm.du.7.ew.5yo.m <- glm (pttype ~ beetle_moderate_5yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [74, 1] <- "7"
table.glm.summary.insect  [74, 2] <- "Early Winter"
table.glm.summary.insect  [74, 3] <- "Moderate"
table.glm.summary.insect  [74, 4] <- 5
table.glm.summary.insect [74, 5] <- glm.du.7.ew.5yo.m$coefficients [[2]]
table.glm.summary.insect [74, 6] <- summary (glm.du.7.ew.5yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.ew.5yo.m)
gc ()

glm.du.7.ew.6yo.m <- glm (pttype ~ beetle_moderate_6yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [75, 1] <- "7"
table.glm.summary.insect  [75, 2] <- "Early Winter"
table.glm.summary.insect  [75, 3] <- "Moderate"
table.glm.summary.insect  [75, 4] <- 6
table.glm.summary.insect [75, 5] <- glm.du.7.ew.6yo.m$coefficients [[2]]
table.glm.summary.insect [75, 6] <- summary (glm.du.7.ew.6yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.ew.6yo.m)
gc ()

glm.du.7.ew.7yo.m <- glm (pttype ~ beetle_moderate_7yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [76, 1] <- "7"
table.glm.summary.insect  [76, 2] <- "Early Winter"
table.glm.summary.insect  [76, 3] <- "Moderate"
table.glm.summary.insect  [76, 4] <- 7
table.glm.summary.insect [76, 5] <- glm.du.7.ew.7yo.m$coefficients [[2]]
table.glm.summary.insect [76, 6] <- summary (glm.du.7.ew.7yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.ew.7yo.m)
gc ()

glm.du.7.ew.8yo.m <- glm (pttype ~ beetle_moderate_8yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [77, 1] <- "7"
table.glm.summary.insect  [77, 2] <- "Early Winter"
table.glm.summary.insect  [77, 3] <- "Moderate"
table.glm.summary.insect  [77, 4] <- 8
table.glm.summary.insect [77, 5] <- glm.du.7.ew.8yo.m$coefficients [[2]]
table.glm.summary.insect [77, 6] <- summary (glm.du.7.ew.8yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.ew.8yo.m)
gc ()

glm.du.7.ew.9yo.m <- glm (pttype ~ beetle_moderate_9yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [78, 1] <- "7"
table.glm.summary.insect  [78, 2] <- "Early Winter"
table.glm.summary.insect  [78, 3] <- "Moderate"
table.glm.summary.insect  [78, 4] <- 9
table.glm.summary.insect [78, 5] <- glm.du.7.ew.9yo.m$coefficients [[2]]
table.glm.summary.insect [78, 6] <- summary (glm.du.7.ew.9yo.m)$coefficients[2, 4]
rm (glm.du.7.ew.9yo.m)
gc ()

glm.du.7.ew.1yo.s <- glm (pttype ~ beetle_severe_1yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [79, 1] <- "7"
table.glm.summary.insect  [79, 2] <- "Early Winter"
table.glm.summary.insect  [79, 3] <- "Severe"
table.glm.summary.insect  [79, 4] <- 1
table.glm.summary.insect [79, 5] <- glm.du.7.ew.1yo.s$coefficients [[2]]
table.glm.summary.insect [79, 6] <- summary (glm.du.7.ew.1yo.s)$coefficients[2, 4] # p-value
rm (glm.du.7.ew.1yo.s)
gc ()

glm.du.7.ew.2yo.s <- glm (pttype ~ beetle_severe_2yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [80, 1] <- "7"
table.glm.summary.insect  [80, 2] <- "Early Winter"
table.glm.summary.insect  [80, 3] <- "Severe"
table.glm.summary.insect  [80, 4] <- 2
table.glm.summary.insect [80, 5] <- glm.du.7.ew.2yo.s$coefficients [[2]]
table.glm.summary.insect [80, 6] <- summary (glm.du.7.ew.2yo.s)$coefficients[2, 4] # p-value
rm (glm.du.7.ew.2yo.s)
gc ()

glm.du.7.ew.3yo.s <- glm (pttype ~ beetle_severe_3yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [81, 1] <- "7"
table.glm.summary.insect  [81, 2] <- "Early Winter"
table.glm.summary.insect  [81, 3] <- "Severe"
table.glm.summary.insect  [81, 4] <- 3
table.glm.summary.insect [81, 5] <- glm.du.7.ew.3yo.s$coefficients [[2]]
table.glm.summary.insect [81, 6] <- summary (glm.du.7.ew.3yo.s)$coefficients[2, 4] # p-value
rm (glm.du.7.ew.3yo.s)
gc ()

glm.du.7.ew.4yo.s <- glm (pttype ~ beetle_severe_4yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [82, 1] <- "7"
table.glm.summary.insect  [82, 2] <- "Early Winter"
table.glm.summary.insect  [82, 3] <- "Severe"
table.glm.summary.insect  [82, 4] <- 4
table.glm.summary.insect [82, 5] <- glm.du.7.ew.4yo.s$coefficients [[2]]
table.glm.summary.insect [82, 6] <- summary (glm.du.7.ew.4yo.s)$coefficients[2, 4] # p-value
rm (glm.du.7.ew.4yo.s)
gc ()

glm.du.7.ew.5yo.s <- glm (pttype ~ beetle_severe_5yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [83, 1] <- "7"
table.glm.summary.insect  [83, 2] <- "Early Winter"
table.glm.summary.insect  [83, 3] <- "Severe"
table.glm.summary.insect  [83, 4] <- 5
table.glm.summary.insect [83, 5] <- glm.du.7.ew.5yo.s$coefficients [[2]]
table.glm.summary.insect [83, 6] <- summary (glm.du.7.ew.5yo.s)$coefficients[2, 4]
rm (glm.du.7.ew.5yo.s)
gc ()

glm.du.7.ew.6yo.s <- glm (pttype ~ beetle_severe_6yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [84, 1] <- "7"
table.glm.summary.insect  [84, 2] <- "Early Winter"
table.glm.summary.insect  [84, 3] <- "Severe"
table.glm.summary.insect  [84, 4] <- 6
table.glm.summary.insect [84, 5] <- glm.du.7.ew.6yo.s$coefficients [[2]]
table.glm.summary.insect [84, 6] <- summary (glm.du.7.ew.6yo.s)$coefficients[2, 4]
rm (glm.du.7.ew.6yo.s)
gc ()

glm.du.7.ew.7yo.s <- glm (pttype ~ beetle_severe_7yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [85, 1] <- "7"
table.glm.summary.insect  [85, 2] <- "Early Winter"
table.glm.summary.insect  [85, 3] <- "Severe"
table.glm.summary.insect  [85, 4] <- 7
table.glm.summary.insect [85, 5] <- glm.du.7.ew.7yo.s$coefficients [[2]]
table.glm.summary.insect [85, 6] <- summary (glm.du.7.ew.7yo.s)$coefficients[2, 4]
rm (glm.du.7.ew.7yo.s)
gc ()

glm.du.7.ew.8yo.s <- glm (pttype ~ beetle_severe_8yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [86, 1] <- "7"
table.glm.summary.insect  [86, 2] <- "Early Winter"
table.glm.summary.insect  [86, 3] <- "Severe"
table.glm.summary.insect  [86, 4] <- 8
table.glm.summary.insect [86, 5] <- glm.du.7.ew.8yo.s$coefficients [[2]]
table.glm.summary.insect [86, 6] <- summary (glm.du.7.ew.8yo.s)$coefficients[2, 4]
rm (glm.du.7.ew.8yo.s)
gc ()

glm.du.7.ew.9yo.s <- glm (pttype ~ beetle_severe_9yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [87, 1] <- "7"
table.glm.summary.insect  [87, 2] <- "Early Winter"
table.glm.summary.insect  [87, 3] <- "Severe"
table.glm.summary.insect  [87, 4] <- 9
table.glm.summary.insect [87, 5] <- glm.du.7.ew.9yo.s$coefficients [[2]]
table.glm.summary.insect [87, 6] <- summary (glm.du.7.ew.9yo.s)$coefficients[2, 4]
rm (glm.du.7.ew.9yo.s)
gc ()

glm.du.7.ew.1yo.vs <- glm (pttype ~ beetle_very_severe_1yo, 
                           data = beetle.data.du.7.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [88, 1] <- "7"
table.glm.summary.insect [88, 2] <- "Early Winter"
table.glm.summary.insect [88, 3] <- "Very Severe"
table.glm.summary.insect [88, 4] <- 1
table.glm.summary.insect [88, 5] <- glm.du.7.ew.1yo.vs$coefficients [[2]]
table.glm.summary.insect [88, 6] <- summary (glm.du.7.ew.1yo.vs)$coefficients[2, 4]
rm (glm.du.7.ew.1yo.vs)
gc ()

glm.du.7.ew.2yo.vs <- glm (pttype ~ beetle_very_severe_2yo, 
                           data = beetle.data.du.7.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [89, 1] <- "7"
table.glm.summary.insect [89, 2] <- "Early Winter"
table.glm.summary.insect [89, 3] <- "Very Severe"
table.glm.summary.insect [89, 4] <- 2
table.glm.summary.insect [89, 5] <- glm.du.7.ew.2yo.vs$coefficients [[2]]
table.glm.summary.insect [89, 6] <- summary (glm.du.7.ew.2yo.vs)$coefficients[2, 4]
rm (glm.du.7.ew.2yo.vs)
gc ()

glm.du.7.ew.3yo.vs <- glm (pttype ~ beetle_very_severe_3yo, 
                           data = beetle.data.du.7.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [90, 1] <- "7"
table.glm.summary.insect [90, 2] <- "Early Winter"
table.glm.summary.insect [90, 3] <- "Very Severe"
table.glm.summary.insect [90, 4] <- 3
table.glm.summary.insect [90, 5] <- glm.du.7.ew.3yo.vs$coefficients [[2]]
table.glm.summary.insect [90, 6] <- summary (glm.du.7.ew.3yo.vs)$coefficients[2, 4]
rm (glm.du.7.ew.3yo.vs)
gc ()

glm.du.7.ew.4yo.vs <- glm (pttype ~ beetle_very_severe_4yo, 
                           data = beetle.data.du.7.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [91, 1] <- "7"
table.glm.summary.insect [91, 2] <- "Early Winter"
table.glm.summary.insect [91, 3] <- "Very Severe"
table.glm.summary.insect [91, 4] <- 4
table.glm.summary.insect [91, 5] <- glm.du.7.ew.4yo.vs$coefficients [[2]]
table.glm.summary.insect [91, 6] <- summary (glm.du.7.ew.4yo.vs)$coefficients[2, 4]
rm (glm.du.7.ew.4yo.vs)
gc ()

glm.du.7.ew.5yo.vs <- glm (pttype ~ beetle_very_severe_5yo, 
                           data = beetle.data.du.7.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [92, 1] <- "7"
table.glm.summary.insect [92, 2] <- "Early Winter"
table.glm.summary.insect [92, 3] <- "Very Severe"
table.glm.summary.insect [92, 4] <- 5
table.glm.summary.insect [92, 5] <- glm.du.7.ew.5yo.vs$coefficients [[2]]
table.glm.summary.insect [92, 6] <- summary (glm.du.7.ew.5yo.vs)$coefficients[2, 4]
rm (glm.du.7.ew.5yo.vs)
gc ()

## DU7 ###
### Late Winter ###
glm.du.7.lw.1yo.m <- glm (pttype ~ beetle_moderate_1yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [93, 1] <- "7"
table.glm.summary.insect  [93, 2] <- "Late Winter"
table.glm.summary.insect  [93, 3] <- "Moderate"
table.glm.summary.insect  [93, 4] <- 1
table.glm.summary.insect [93, 5] <- glm.du.7.lw.1yo.m$coefficients [[2]]
table.glm.summary.insect [93, 6] <- summary (glm.du.7.lw.1yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.lw.1yo.m)
gc ()

glm.du.7.lw.2yo.m <- glm (pttype ~ beetle_moderate_2yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [94, 1] <- "7"
table.glm.summary.insect  [94, 2] <- "Late Winter"
table.glm.summary.insect  [94, 3] <- "Moderate"
table.glm.summary.insect  [94, 4] <- 2
table.glm.summary.insect [94, 5] <- glm.du.7.lw.2yo.m$coefficients [[2]]
table.glm.summary.insect [94, 6] <- summary (glm.du.7.lw.2yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.lw.2yo.m)
gc ()

glm.du.7.lw.3yo.m <- glm (pttype ~ beetle_moderate_3yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect [95, 1] <- "7"
table.glm.summary.insect [95, 2] <- "Late Winter"
table.glm.summary.insect [95, 3] <- "Moderate"
table.glm.summary.insect [95, 4] <- 3
table.glm.summary.insect [95, 5] <- glm.du.7.lw.3yo.m$coefficients [[2]]
table.glm.summary.insect [95, 6] <- summary (glm.du.7.lw.3yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.lw.3yo.m)
gc ()

glm.du.7.lw.4yo.m <- glm (pttype ~ beetle_moderate_4yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [96, 1] <- "7"
table.glm.summary.insect  [96, 2] <- "Late Winter"
table.glm.summary.insect  [96, 3] <- "Moderate"
table.glm.summary.insect  [96, 4] <- 4
table.glm.summary.insect [96, 5] <- glm.du.7.lw.4yo.m$coefficients [[2]]
table.glm.summary.insect [96, 6] <- summary (glm.du.7.lw.4yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.lw.4yo.m)
gc ()

glm.du.7.lw.5yo.m <- glm (pttype ~ beetle_moderate_5yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [97, 1] <- "7"
table.glm.summary.insect  [97, 2] <- "Late Winter"
table.glm.summary.insect  [97, 3] <- "Moderate"
table.glm.summary.insect  [97, 4] <- 5
table.glm.summary.insect [97, 5] <- glm.du.7.lw.5yo.m$coefficients [[2]]
table.glm.summary.insect [97, 6] <- summary (glm.du.7.lw.5yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.lw.5yo.m)
gc ()

glm.du.7.lw.6yo.m <- glm (pttype ~ beetle_moderate_6yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [98, 1] <- "7"
table.glm.summary.insect  [98, 2] <- "Late Winter"
table.glm.summary.insect  [98, 3] <- "Moderate"
table.glm.summary.insect  [98, 4] <- 6
table.glm.summary.insect [98, 5] <- glm.du.7.lw.6yo.m$coefficients [[2]]
table.glm.summary.insect [98, 6] <- summary (glm.du.7.lw.6yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.lw.6yo.m)
gc ()

glm.du.7.lw.7yo.m <- glm (pttype ~ beetle_moderate_7yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [99, 1] <- "7"
table.glm.summary.insect  [99, 2] <- "Late Winter"
table.glm.summary.insect  [99, 3] <- "Moderate"
table.glm.summary.insect  [99, 4] <- 7
table.glm.summary.insect [99, 5] <- glm.du.7.lw.7yo.m$coefficients [[2]]
table.glm.summary.insect [99, 6] <- summary (glm.du.7.lw.7yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.lw.7yo.m)
gc ()

glm.du.7.lw.8yo.m <- glm (pttype ~ beetle_moderate_8yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [100, 1] <- "7"
table.glm.summary.insect  [100, 2] <- "Late Winter"
table.glm.summary.insect  [100, 3] <- "Moderate"
table.glm.summary.insect  [100, 4] <- 8
table.glm.summary.insect [100, 5] <- glm.du.7.lw.8yo.m$coefficients [[2]]
table.glm.summary.insect [100, 6] <- summary (glm.du.7.lw.8yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.lw.8yo.m)
gc ()

glm.du.7.lw.9yo.m <- glm (pttype ~ beetle_moderate_9yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [101, 1] <- "7"
table.glm.summary.insect  [101, 2] <- "Late Winter"
table.glm.summary.insect  [101, 3] <- "Moderate"
table.glm.summary.insect  [101, 4] <- 9
table.glm.summary.insect [101, 5] <- glm.du.7.lw.9yo.m$coefficients [[2]]
table.glm.summary.insect [101, 6] <- summary (glm.du.7.lw.9yo.m)$coefficients[2, 4]
rm (glm.du.7.lw.9yo.m)
gc ()

glm.du.7.lw.1yo.s <- glm (pttype ~ beetle_severe_1yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [102, 1] <- "7"
table.glm.summary.insect  [102, 2] <- "Late Winter"
table.glm.summary.insect  [102, 3] <- "Severe"
table.glm.summary.insect  [102, 4] <- 1
table.glm.summary.insect [102, 5] <- glm.du.7.lw.1yo.s$coefficients [[2]]
table.glm.summary.insect [102, 6] <- summary (glm.du.7.lw.1yo.s)$coefficients[2, 4] # p-value
rm (glm.du.7.lw.1yo.s)
gc ()

glm.du.7.lw.2yo.s <- glm (pttype ~ beetle_severe_2yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [103, 1] <- "7"
table.glm.summary.insect  [103, 2] <- "Late Winter"
table.glm.summary.insect  [103, 3] <- "Severe"
table.glm.summary.insect  [103, 4] <- 2
table.glm.summary.insect [103, 5] <- glm.du.7.lw.2yo.s$coefficients [[2]]
table.glm.summary.insect [103, 6] <- summary (glm.du.7.lw.2yo.s)$coefficients[2, 4] # p-value
rm (glm.du.7.lw.2yo.s)
gc ()

glm.du.7.lw.3yo.s <- glm (pttype ~ beetle_severe_3yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [104, 1] <- "7"
table.glm.summary.insect  [104, 2] <- "Late Winter"
table.glm.summary.insect  [104, 3] <- "Severe"
table.glm.summary.insect  [104, 4] <- 3
table.glm.summary.insect [104, 5] <- glm.du.7.lw.3yo.s$coefficients [[2]]
table.glm.summary.insect [104, 6] <- summary (glm.du.7.lw.3yo.s)$coefficients[2, 4] # p-value
rm (glm.du.7.lw.3yo.s)
gc ()

glm.du.7.lw.4yo.s <- glm (pttype ~ beetle_severe_4yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [105, 1] <- "7"
table.glm.summary.insect  [105, 2] <- "Late Winter"
table.glm.summary.insect  [105, 3] <- "Severe"
table.glm.summary.insect  [105, 4] <- 4
table.glm.summary.insect [105, 5] <- glm.du.7.lw.4yo.s$coefficients [[2]]
table.glm.summary.insect [105, 6] <- summary (glm.du.7.lw.4yo.s)$coefficients[2, 4] # p-value
rm (glm.du.7.lw.4yo.s)
gc ()

glm.du.7.lw.5yo.s <- glm (pttype ~ beetle_severe_5yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [106, 1] <- "7"
table.glm.summary.insect  [106, 2] <- "Late Winter"
table.glm.summary.insect  [106, 3] <- "Severe"
table.glm.summary.insect  [106, 4] <- 5
table.glm.summary.insect [106, 5] <- glm.du.7.lw.5yo.s$coefficients [[2]]
table.glm.summary.insect [106, 6] <- summary (glm.du.7.lw.5yo.s)$coefficients[2, 4]
rm (glm.du.7.lw.5yo.s)
gc ()

glm.du.7.lw.6yo.s <- glm (pttype ~ beetle_severe_6yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [107, 1] <- "7"
table.glm.summary.insect  [107, 2] <- "Late Winter"
table.glm.summary.insect  [107, 3] <- "Severe"
table.glm.summary.insect  [107, 4] <- 6
table.glm.summary.insect [107, 5] <- glm.du.7.lw.6yo.s$coefficients [[2]]
table.glm.summary.insect [107, 6] <- summary (glm.du.7.lw.6yo.s)$coefficients[2, 4]
rm (glm.du.7.lw.6yo.s)
gc ()

glm.du.7.lw.7yo.s <- glm (pttype ~ beetle_severe_7yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [108, 1] <- "7"
table.glm.summary.insect  [108, 2] <- "Late Winter"
table.glm.summary.insect  [108, 3] <- "Severe"
table.glm.summary.insect  [108, 4] <- 7
table.glm.summary.insect [108, 5] <- glm.du.7.lw.7yo.s$coefficients [[2]]
table.glm.summary.insect [108, 6] <- summary (glm.du.7.lw.7yo.s)$coefficients[2, 4]
rm (glm.du.7.lw.7yo.s)
gc ()

glm.du.7.lw.8yo.s <- glm (pttype ~ beetle_severe_8yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [109, 1] <- "7"
table.glm.summary.insect  [109, 2] <- "Late Winter"
table.glm.summary.insect  [109, 3] <- "Severe"
table.glm.summary.insect  [109, 4] <- 8
table.glm.summary.insect [109, 5] <- glm.du.7.lw.8yo.s$coefficients [[2]]
table.glm.summary.insect [109, 6] <- summary (glm.du.7.lw.8yo.s)$coefficients[2, 4]
rm (glm.du.7.lw.8yo.s)
gc ()

glm.du.7.lw.9yo.s <- glm (pttype ~ beetle_severe_9yo, 
                          data = beetle.data.du.7.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [110, 1] <- "7"
table.glm.summary.insect  [110, 2] <- "Late Winter"
table.glm.summary.insect  [110, 3] <- "Severe"
table.glm.summary.insect  [110, 4] <- 9
table.glm.summary.insect [110, 5] <- glm.du.7.lw.9yo.s$coefficients [[2]]
table.glm.summary.insect [110, 6] <- summary (glm.du.7.lw.9yo.s)$coefficients[2, 4]
rm (glm.du.7.lw.9yo.s)
gc ()

glm.du.7.lw.1yo.vs <- glm (pttype ~ beetle_very_severe_1yo, 
                           data = beetle.data.du.7.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [111, 1] <- "7"
table.glm.summary.insect [111, 2] <- "Late Winter"
table.glm.summary.insect [111, 3] <- "Very Severe"
table.glm.summary.insect [111, 4] <- 1
table.glm.summary.insect [111, 5] <- glm.du.7.lw.1yo.vs$coefficients [[2]]
table.glm.summary.insect [111, 6] <- summary (glm.du.7.lw.1yo.vs)$coefficients[2, 4]
rm (glm.du.7.lw.1yo.vs)
gc ()

glm.du.7.lw.2yo.vs <- glm (pttype ~ beetle_very_severe_2yo, 
                           data = beetle.data.du.7.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [112, 1] <- "7"
table.glm.summary.insect [112, 2] <- "Late Winter"
table.glm.summary.insect [112, 3] <- "Very Severe"
table.glm.summary.insect [112, 4] <- 2
table.glm.summary.insect [112, 5] <- glm.du.7.lw.2yo.vs$coefficients [[2]]
table.glm.summary.insect [112, 6] <- summary (glm.du.7.lw.2yo.vs)$coefficients[2, 4]
rm (glm.du.7.lw.2yo.vs)
gc ()

glm.du.7.lw.3yo.vs <- glm (pttype ~ beetle_very_severe_3yo, 
                           data = beetle.data.du.7.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [113, 1] <- "7"
table.glm.summary.insect [113, 2] <- "Late Winter"
table.glm.summary.insect [113, 3] <- "Very Severe"
table.glm.summary.insect [113, 4] <- 3
table.glm.summary.insect [113, 5] <- glm.du.7.lw.3yo.vs$coefficients [[2]]
table.glm.summary.insect [113, 6] <- summary (glm.du.7.lw.3yo.vs)$coefficients[2, 4]
rm (glm.du.7.lw.3yo.vs)
gc ()

glm.du.7.lw.4yo.vs <- glm (pttype ~ beetle_very_severe_4yo, 
                           data = beetle.data.du.7.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [114, 1] <- "7"
table.glm.summary.insect [114, 2] <- "Late Winter"
table.glm.summary.insect [114, 3] <- "Very Severe"
table.glm.summary.insect [114, 4] <- 4
table.glm.summary.insect [114, 5] <- glm.du.7.lw.4yo.vs$coefficients [[2]]
table.glm.summary.insect [114, 6] <- summary (glm.du.7.lw.4yo.vs)$coefficients[2, 4]
rm (glm.du.7.lw.4yo.vs)
gc ()

glm.du.7.lw.5yo.vs <- glm (pttype ~ beetle_very_severe_5yo, 
                           data = beetle.data.du.7.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [115, 1] <- "7"
table.glm.summary.insect [115, 2] <- "Late Winter"
table.glm.summary.insect [115, 3] <- "Very Severe"
table.glm.summary.insect [115, 4] <- 5
table.glm.summary.insect [115, 5] <- glm.du.7.lw.5yo.vs$coefficients [[2]]
table.glm.summary.insect [115, 6] <- summary (glm.du.7.lw.5yo.vs)$coefficients[2, 4]
rm (glm.du.7.lw.5yo.vs)
gc ()

## DU7 ###
### Summer ###
glm.du.7.s.1yo.m <- glm (pttype ~ beetle_moderate_1yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [116, 1] <- "7"
table.glm.summary.insect  [116, 2] <- "Summer"
table.glm.summary.insect  [116, 3] <- "Moderate"
table.glm.summary.insect  [116, 4] <- 1
table.glm.summary.insect [116, 5] <- glm.du.7.s.1yo.m$coefficients [[2]]
table.glm.summary.insect [116, 6] <- summary (glm.du.7.s.1yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.s.1yo.m)
gc ()

glm.du.7.s.2yo.m <- glm (pttype ~ beetle_moderate_2yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [117, 1] <- "7"
table.glm.summary.insect  [117, 2] <- "Summer"
table.glm.summary.insect  [117, 3] <- "Moderate"
table.glm.summary.insect  [117, 4] <- 2
table.glm.summary.insect [117, 5] <- glm.du.7.s.2yo.m$coefficients [[2]]
table.glm.summary.insect [117, 6] <- summary (glm.du.7.s.2yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.s.2yo.m)
gc ()

glm.du.7.s.3yo.m <- glm (pttype ~ beetle_moderate_3yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect [118, 1] <- "7"
table.glm.summary.insect [118, 2] <- "Summer"
table.glm.summary.insect [118, 3] <- "Moderate"
table.glm.summary.insect [118, 4] <- 3
table.glm.summary.insect [118, 5] <- glm.du.7.s.3yo.m$coefficients [[2]]
table.glm.summary.insect [118, 6] <- summary (glm.du.7.s.3yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.s.3yo.m)
gc ()

glm.du.7.s.4yo.m <- glm (pttype ~ beetle_moderate_4yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [119, 1] <- "7"
table.glm.summary.insect  [119, 2] <- "Summer"
table.glm.summary.insect  [119, 3] <- "Moderate"
table.glm.summary.insect  [119, 4] <- 4
table.glm.summary.insect [119, 5] <- glm.du.7.s.4yo.m$coefficients [[2]]
table.glm.summary.insect [119, 6] <- summary (glm.du.7.s.4yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.s.4yo.m)
gc ()

glm.du.7.s.5yo.m <- glm (pttype ~ beetle_moderate_5yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [120, 1] <- "7"
table.glm.summary.insect  [120, 2] <- "Summer"
table.glm.summary.insect  [120, 3] <- "Moderate"
table.glm.summary.insect  [120, 4] <- 5
table.glm.summary.insect [120, 5] <- glm.du.7.s.5yo.m$coefficients [[2]]
table.glm.summary.insect [120, 6] <- summary (glm.du.7.s.5yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.s.5yo.m)
gc ()

glm.du.7.s.6yo.m <- glm (pttype ~ beetle_moderate_6yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [121, 1] <- "7"
table.glm.summary.insect  [121, 2] <- "Summer"
table.glm.summary.insect  [121, 3] <- "Moderate"
table.glm.summary.insect  [121, 4] <- 6
table.glm.summary.insect [121, 5] <- glm.du.7.s.6yo.m$coefficients [[2]]
table.glm.summary.insect [121, 6] <- summary (glm.du.7.s.6yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.s.6yo.m)
gc ()

glm.du.7.s.7yo.m <- glm (pttype ~ beetle_moderate_7yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [122, 1] <- "7"
table.glm.summary.insect  [122, 2] <- "Summer"
table.glm.summary.insect  [122, 3] <- "Moderate"
table.glm.summary.insect  [122, 4] <- 7
table.glm.summary.insect [122, 5] <- glm.du.7.s.7yo.m$coefficients [[2]]
table.glm.summary.insect [122, 6] <- summary (glm.du.7.s.7yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.s.7yo.m)
gc ()

glm.du.7.s.8yo.m <- glm (pttype ~ beetle_moderate_8yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [123, 1] <- "7"
table.glm.summary.insect  [123, 2] <- "Summer"
table.glm.summary.insect  [123, 3] <- "Moderate"
table.glm.summary.insect  [123, 4] <- 8
table.glm.summary.insect [123, 5] <- glm.du.7.s.8yo.m$coefficients [[2]]
table.glm.summary.insect [123, 6] <- summary (glm.du.7.s.8yo.m)$coefficients[2, 4] # p-value
rm (glm.du.7.s.8yo.m)
gc ()

glm.du.7.s.9yo.m <- glm (pttype ~ beetle_moderate_9yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [124, 1] <- "7"
table.glm.summary.insect  [124, 2] <- "Summer"
table.glm.summary.insect  [124, 3] <- "Moderate"
table.glm.summary.insect  [124, 4] <- 9
table.glm.summary.insect [124, 5] <- glm.du.7.s.9yo.m$coefficients [[2]]
table.glm.summary.insect [124, 6] <- summary (glm.du.7.s.9yo.m)$coefficients[2, 4]
rm (glm.du.7.s.9yo.m)
gc ()

glm.du.7.s.1yo.s <- glm (pttype ~ beetle_severe_1yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [125, 1] <- "7"
table.glm.summary.insect  [125, 2] <- "Summer"
table.glm.summary.insect  [125, 3] <- "Severe"
table.glm.summary.insect  [125, 4] <- 1
table.glm.summary.insect [125, 5] <- glm.du.7.s.1yo.s$coefficients [[2]]
table.glm.summary.insect [125, 6] <- summary (glm.du.7.s.1yo.s)$coefficients[2, 4] # p-value
rm (glm.du.7.s.1yo.s)
gc ()

glm.du.7.s.2yo.s <- glm (pttype ~ beetle_severe_2yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [126, 1] <- "7"
table.glm.summary.insect  [126, 2] <- "Summer"
table.glm.summary.insect  [126, 3] <- "Severe"
table.glm.summary.insect  [126, 4] <- 2
table.glm.summary.insect [126, 5] <- glm.du.7.s.2yo.s$coefficients [[2]]
table.glm.summary.insect [126, 6] <- summary (glm.du.7.s.2yo.s)$coefficients[2, 4] # p-value
rm (glm.du.7.s.2yo.s)
gc ()

glm.du.7.s.3yo.s <- glm (pttype ~ beetle_severe_3yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [127, 1] <- "7"
table.glm.summary.insect  [127, 2] <- "Summer"
table.glm.summary.insect  [127, 3] <- "Severe"
table.glm.summary.insect  [127, 4] <- 3
table.glm.summary.insect [127, 5] <- glm.du.7.s.3yo.s$coefficients [[2]]
table.glm.summary.insect [127, 6] <- summary (glm.du.7.s.3yo.s)$coefficients[2, 4] # p-value
rm (glm.du.7.s.3yo.s)
gc ()

glm.du.7.s.4yo.s <- glm (pttype ~ beetle_severe_4yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [128, 1] <- "7"
table.glm.summary.insect  [128, 2] <- "Summer"
table.glm.summary.insect  [128, 3] <- "Severe"
table.glm.summary.insect  [128, 4] <- 4
table.glm.summary.insect [128, 5] <- glm.du.7.s.4yo.s$coefficients [[2]]
table.glm.summary.insect [128, 6] <- summary (glm.du.7.s.4yo.s)$coefficients[2, 4] # p-value
rm (glm.du.7.s.4yo.s)
gc ()

glm.du.7.s.5yo.s <- glm (pttype ~ beetle_severe_5yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [129, 1] <- "7"
table.glm.summary.insect  [129, 2] <- "Summer"
table.glm.summary.insect  [129, 3] <- "Severe"
table.glm.summary.insect  [129, 4] <- 5
table.glm.summary.insect [129, 5] <- glm.du.7.s.5yo.s$coefficients [[2]]
table.glm.summary.insect [129, 6] <- summary (glm.du.7.s.5yo.s)$coefficients[2, 4]
rm (glm.du.7.s.5yo.s)
gc ()

glm.du.7.s.6yo.s <- glm (pttype ~ beetle_severe_6yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [130, 1] <- "7"
table.glm.summary.insect  [130, 2] <- "Summer"
table.glm.summary.insect  [130, 3] <- "Severe"
table.glm.summary.insect  [130, 4] <- 6
table.glm.summary.insect [130, 5] <- glm.du.7.s.6yo.s$coefficients [[2]]
table.glm.summary.insect [130, 6] <- summary (glm.du.7.s.6yo.s)$coefficients[2, 4]
rm (glm.du.7.s.6yo.s)
gc ()

glm.du.7.s.7yo.s <- glm (pttype ~ beetle_severe_7yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [131, 1] <- "7"
table.glm.summary.insect  [131, 2] <- "Summer"
table.glm.summary.insect  [131, 3] <- "Severe"
table.glm.summary.insect  [131, 4] <- 7
table.glm.summary.insect [131, 5] <- glm.du.7.s.7yo.s$coefficients [[2]]
table.glm.summary.insect [131, 6] <- summary (glm.du.7.s.7yo.s)$coefficients[2, 4]
rm (glm.du.7.s.7yo.s)
gc ()

glm.du.7.s.8yo.s <- glm (pttype ~ beetle_severe_8yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [132, 1] <- "7"
table.glm.summary.insect  [132, 2] <- "Summer"
table.glm.summary.insect  [132, 3] <- "Severe"
table.glm.summary.insect  [132, 4] <- 8
table.glm.summary.insect [132, 5] <- glm.du.7.s.8yo.s$coefficients [[2]]
table.glm.summary.insect [132, 6] <- summary (glm.du.7.s.8yo.s)$coefficients[2, 4]
rm (glm.du.7.s.8yo.s)
gc ()

glm.du.7.s.9yo.s <- glm (pttype ~ beetle_severe_9yo, 
                          data = beetle.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [133, 1] <- "7"
table.glm.summary.insect  [133, 2] <- "Summer"
table.glm.summary.insect  [133, 3] <- "Severe"
table.glm.summary.insect  [133, 4] <- 9
table.glm.summary.insect [133, 5] <- glm.du.7.s.9yo.s$coefficients [[2]]
table.glm.summary.insect [133, 6] <- summary (glm.du.7.s.9yo.s)$coefficients[2, 4]
rm (glm.du.7.s.9yo.s)
gc ()

glm.du.7.s.1yo.vs <- glm (pttype ~ beetle_very_severe_1yo, 
                           data = beetle.data.du.7.s,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [134, 1] <- "7"
table.glm.summary.insect [134, 2] <- "Summer"
table.glm.summary.insect [134, 3] <- "Very Severe"
table.glm.summary.insect [134, 4] <- 1
table.glm.summary.insect [134, 5] <- glm.du.7.s.1yo.vs$coefficients [[2]]
table.glm.summary.insect [134, 6] <- summary (glm.du.7.s.1yo.vs)$coefficients[2, 4]
rm (glm.du.7.s.1yo.vs)
gc ()

glm.du.7.s.2yo.vs <- glm (pttype ~ beetle_very_severe_2yo, 
                           data = beetle.data.du.7.s,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [135, 1] <- "7"
table.glm.summary.insect [135, 2] <- "Summer"
table.glm.summary.insect [135, 3] <- "Very Severe"
table.glm.summary.insect [135, 4] <- 2
table.glm.summary.insect [135, 5] <- NA
table.glm.summary.insect [135, 6] <- NA
rm (glm.du.7.s.2yo.vs)
gc ()

glm.du.7.s.3yo.vs <- glm (pttype ~ beetle_very_severe_3yo, 
                           data = beetle.data.du.7.s,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [136, 1] <- "7"
table.glm.summary.insect [136, 2] <- "Summer"
table.glm.summary.insect [136, 3] <- "Very Severe"
table.glm.summary.insect [136, 4] <- 3
table.glm.summary.insect [136, 5] <- glm.du.7.s.3yo.vs$coefficients [[2]]
table.glm.summary.insect [136, 6] <- summary (glm.du.7.s.3yo.vs)$coefficients[2, 4]
rm (glm.du.7.s.3yo.vs)
gc ()

glm.du.7.s.4yo.vs <- glm (pttype ~ beetle_very_severe_4yo, 
                           data = beetle.data.du.7.s,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [137, 1] <- "7"
table.glm.summary.insect [137, 2] <- "Summer"
table.glm.summary.insect [137, 3] <- "Very Severe"
table.glm.summary.insect [137, 4] <- 4
table.glm.summary.insect [137, 5] <- NA
table.glm.summary.insect [137, 6] <- NA
rm (glm.du.7.s.4yo.vs)
gc ()

glm.du.7.s.5yo.vs <- glm (pttype ~ beetle_very_severe_5yo, 
                           data = beetle.data.du.7.s,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [138, 1] <- "7"
table.glm.summary.insect [138, 2] <- "Summer"
table.glm.summary.insect [138, 3] <- "Very Severe"
table.glm.summary.insect [138, 4] <- 5
table.glm.summary.insect [138, 5] <- glm.du.7.s.5yo.vs$coefficients [[2]]
table.glm.summary.insect [138, 6] <- summary (glm.du.7.s.5yo.vs)$coefficients[2, 4]
rm (glm.du.7.s.5yo.vs)
gc ()

## DU8 ###
### Early Winter ###
glm.du.8.ew.1yo.m <- glm (pttype ~ beetle_moderate_1yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [139, 1] <- "8"
table.glm.summary.insect  [139, 2] <- "Early Winter"
table.glm.summary.insect  [139, 3] <- "Moderate"
table.glm.summary.insect  [139, 4] <- 1
table.glm.summary.insect [139, 5] <- glm.du.8.ew.1yo.m$coefficients [[2]]
table.glm.summary.insect [139, 6] <- summary (glm.du.8.ew.1yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.ew.1yo.m)
gc ()

glm.du.8.ew.2yo.m <- glm (pttype ~ beetle_moderate_2yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [140, 1] <- "8"
table.glm.summary.insect  [140, 2] <- "Early Winter"
table.glm.summary.insect  [140, 3] <- "Moderate"
table.glm.summary.insect  [140, 4] <- 2
table.glm.summary.insect [140, 5] <- glm.du.8.ew.2yo.m$coefficients [[2]]
table.glm.summary.insect [140, 6] <- summary (glm.du.8.ew.2yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.ew.2yo.m)
gc ()

glm.du.8.ew.3yo.m <- glm (pttype ~ beetle_moderate_3yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect [141, 1] <- "8"
table.glm.summary.insect [141, 2] <- "Early Winter"
table.glm.summary.insect [141, 3] <- "Moderate"
table.glm.summary.insect [141, 4] <- 3
table.glm.summary.insect [141, 5] <- glm.du.8.ew.3yo.m$coefficients [[2]]
table.glm.summary.insect [141, 6] <- summary (glm.du.8.ew.3yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.ew.3yo.m)
gc ()

glm.du.8.ew.4yo.m <- glm (pttype ~ beetle_moderate_4yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [142, 1] <- "8"
table.glm.summary.insect  [142, 2] <- "Early Winter"
table.glm.summary.insect  [142, 3] <- "Moderate"
table.glm.summary.insect  [142, 4] <- 4
table.glm.summary.insect [142, 5] <- glm.du.8.ew.4yo.m$coefficients [[2]]
table.glm.summary.insect [142, 6] <- summary (glm.du.8.ew.4yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.ew.4yo.m)
gc ()

glm.du.8.ew.5yo.m <- glm (pttype ~ beetle_moderate_5yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [143, 1] <- "8"
table.glm.summary.insect  [143, 2] <- "Early Winter"
table.glm.summary.insect  [143, 3] <- "Moderate"
table.glm.summary.insect  [143, 4] <- 5
table.glm.summary.insect [143, 5] <- glm.du.8.ew.5yo.m$coefficients [[2]]
table.glm.summary.insect [143, 6] <- summary (glm.du.8.ew.5yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.ew.5yo.m)
gc ()

glm.du.8.ew.6yo.m <- glm (pttype ~ beetle_moderate_6yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [144, 1] <- "8"
table.glm.summary.insect  [144, 2] <- "Early Winter"
table.glm.summary.insect  [144, 3] <- "Moderate"
table.glm.summary.insect  [144, 4] <- 6
table.glm.summary.insect [144, 5] <- glm.du.8.ew.6yo.m$coefficients [[2]]
table.glm.summary.insect [144, 6] <- summary (glm.du.8.ew.6yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.ew.6yo.m)
gc ()

glm.du.8.ew.7yo.m <- glm (pttype ~ beetle_moderate_7yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [145, 1] <- "8"
table.glm.summary.insect  [145, 2] <- "Early Winter"
table.glm.summary.insect  [145, 3] <- "Moderate"
table.glm.summary.insect  [145, 4] <- 7
table.glm.summary.insect [145, 5] <- glm.du.8.ew.7yo.m$coefficients [[2]]
table.glm.summary.insect [145, 6] <- summary (glm.du.8.ew.7yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.ew.7yo.m)
gc ()

glm.du.8.ew.8yo.m <- glm (pttype ~ beetle_moderate_8yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [146, 1] <- "8"
table.glm.summary.insect  [146, 2] <- "Early Winter"
table.glm.summary.insect  [146, 3] <- "Moderate"
table.glm.summary.insect  [146, 4] <- 8
table.glm.summary.insect [146, 5] <- glm.du.8.ew.8yo.m$coefficients [[2]]
table.glm.summary.insect [146, 6] <- summary (glm.du.8.ew.8yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.ew.8yo.m)
gc ()

glm.du.8.ew.9yo.m <- glm (pttype ~ beetle_moderate_9yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [147, 1] <- "8"
table.glm.summary.insect  [147, 2] <- "Early Winter"
table.glm.summary.insect  [147, 3] <- "Moderate"
table.glm.summary.insect  [147, 4] <- 9
table.glm.summary.insect [147, 5] <- glm.du.8.ew.9yo.m$coefficients [[2]]
table.glm.summary.insect [147, 6] <- summary (glm.du.8.ew.9yo.m)$coefficients[2, 4]
rm (glm.du.8.ew.9yo.m)
gc ()

glm.du.8.ew.1yo.s <- glm (pttype ~ beetle_severe_1yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [148, 1] <- "8"
table.glm.summary.insect  [148, 2] <- "Early Winter"
table.glm.summary.insect  [148, 3] <- "Severe"
table.glm.summary.insect  [148, 4] <- 1
table.glm.summary.insect [148, 5] <- glm.du.8.ew.1yo.s$coefficients [[2]]
table.glm.summary.insect [148, 6] <- summary (glm.du.8.ew.1yo.s)$coefficients[2, 4] # p-value
rm (glm.du.8.ew.1yo.s)
gc ()

glm.du.8.ew.2yo.s <- glm (pttype ~ beetle_severe_2yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [149, 1] <- "8"
table.glm.summary.insect  [149, 2] <- "Early Winter"
table.glm.summary.insect  [149, 3] <- "Severe"
table.glm.summary.insect  [149, 4] <- 2
table.glm.summary.insect [149, 5] <- glm.du.8.ew.2yo.s$coefficients [[2]]
table.glm.summary.insect [149, 6] <- summary (glm.du.8.ew.2yo.s)$coefficients[2, 4] # p-value
rm (glm.du.8.ew.2yo.s)
gc ()

glm.du.8.ew.3yo.s <- glm (pttype ~ beetle_severe_3yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [150, 1] <- "8"
table.glm.summary.insect  [150, 2] <- "Early Winter"
table.glm.summary.insect  [150, 3] <- "Severe"
table.glm.summary.insect  [150, 4] <- 3
table.glm.summary.insect [150, 5] <- glm.du.8.ew.3yo.s$coefficients [[2]]
table.glm.summary.insect [150, 6] <- summary (glm.du.8.ew.3yo.s)$coefficients[2, 4] # p-value
rm (glm.du.8.ew.3yo.s)
gc ()

glm.du.8.ew.4yo.s <- glm (pttype ~ beetle_severe_4yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [151, 1] <- "8"
table.glm.summary.insect  [151, 2] <- "Early Winter"
table.glm.summary.insect  [151, 3] <- "Severe"
table.glm.summary.insect  [151, 4] <- 4
table.glm.summary.insect [151, 5] <- glm.du.8.ew.4yo.s$coefficients [[2]]
table.glm.summary.insect [151, 6] <- summary (glm.du.8.ew.4yo.s)$coefficients[2, 4] # p-value
rm (glm.du.8.ew.4yo.s)
gc ()

glm.du.8.ew.5yo.s <- glm (pttype ~ beetle_severe_5yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [152, 1] <- "8"
table.glm.summary.insect  [152, 2] <- "Early Winter"
table.glm.summary.insect  [152, 3] <- "Severe"
table.glm.summary.insect  [152, 4] <- 5
table.glm.summary.insect [152, 5] <- glm.du.8.ew.5yo.s$coefficients [[2]]
table.glm.summary.insect [152, 6] <- summary (glm.du.8.ew.5yo.s)$coefficients[2, 4]
rm (glm.du.8.ew.5yo.s)
gc ()

glm.du.8.ew.6yo.s <- glm (pttype ~ beetle_severe_6yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [153, 1] <- "8"
table.glm.summary.insect  [153, 2] <- "Early Winter"
table.glm.summary.insect  [153, 3] <- "Severe"
table.glm.summary.insect  [153, 4] <- 6
table.glm.summary.insect [153, 5] <- glm.du.8.ew.6yo.s$coefficients [[2]]
table.glm.summary.insect [153, 6] <- summary (glm.du.8.ew.6yo.s)$coefficients[2, 4]
rm (glm.du.8.ew.6yo.s)
gc ()

glm.du.8.ew.7yo.s <- glm (pttype ~ beetle_severe_7yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [154, 1] <- "8"
table.glm.summary.insect  [154, 2] <- "Early Winter"
table.glm.summary.insect  [154, 3] <- "Severe"
table.glm.summary.insect  [154, 4] <- 7
table.glm.summary.insect [154, 5] <- glm.du.8.ew.7yo.s$coefficients [[2]]
table.glm.summary.insect [154, 6] <- summary (glm.du.8.ew.7yo.s)$coefficients[2, 4]
rm (glm.du.8.ew.7yo.s)
gc ()

glm.du.8.ew.8yo.s <- glm (pttype ~ beetle_severe_8yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [155, 1] <- "8"
table.glm.summary.insect  [155, 2] <- "Early Winter"
table.glm.summary.insect  [155, 3] <- "Severe"
table.glm.summary.insect  [155, 4] <- 8
table.glm.summary.insect [155, 5] <- glm.du.8.ew.8yo.s$coefficients [[2]]
table.glm.summary.insect [155, 6] <- summary (glm.du.8.ew.8yo.s)$coefficients[2, 4]
rm (glm.du.8.ew.8yo.s)
gc ()

glm.du.8.ew.9yo.s <- glm (pttype ~ beetle_severe_9yo, 
                          data = beetle.data.du.8.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [156, 1] <- "8"
table.glm.summary.insect  [156, 2] <- "Early Winter"
table.glm.summary.insect  [156, 3] <- "Severe"
table.glm.summary.insect  [156, 4] <- 9
table.glm.summary.insect [156, 5] <- glm.du.8.ew.9yo.s$coefficients [[2]]
table.glm.summary.insect [156, 6] <- summary (glm.du.8.ew.9yo.s)$coefficients[2, 4]
rm (glm.du.8.ew.9yo.s)
gc ()

glm.du.8.ew.1yo.vs <- glm (pttype ~ beetle_very_severe_1yo, 
                           data = beetle.data.du.8.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [157, 1] <- "8"
table.glm.summary.insect [157, 2] <- "Early Winter"
table.glm.summary.insect [157, 3] <- "Very Severe"
table.glm.summary.insect [157, 4] <- 1
table.glm.summary.insect [157, 5] <- glm.du.8.ew.1yo.vs$coefficients [[2]]
table.glm.summary.insect [157, 6] <- summary (glm.du.8.ew.1yo.vs)$coefficients[2, 4]
rm (glm.du.8.ew.1yo.vs)
gc ()

glm.du.8.ew.2yo.vs <- glm (pttype ~ beetle_very_severe_2yo, 
                           data = beetle.data.du.8.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [158, 1] <- "8"
table.glm.summary.insect [158, 2] <- "Early Winter"
table.glm.summary.insect [158, 3] <- "Very Severe"
table.glm.summary.insect [158, 4] <- 2
table.glm.summary.insect [158, 5] <- glm.du.8.ew.2yo.vs$coefficients [[2]]
table.glm.summary.insect [158, 6] <- summary (glm.du.8.ew.2yo.vs)$coefficients[2, 4]
rm (glm.du.8.ew.2yo.vs)
gc ()

glm.du.8.ew.3yo.vs <- glm (pttype ~ beetle_very_severe_3yo, 
                           data = beetle.data.du.8.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [159, 1] <- "8"
table.glm.summary.insect [159, 2] <- "Early Winter"
table.glm.summary.insect [159, 3] <- "Very Severe"
table.glm.summary.insect [159, 4] <- 3
table.glm.summary.insect [159, 5] <- glm.du.8.ew.3yo.vs$coefficients [[2]]
table.glm.summary.insect [159, 6] <- summary (glm.du.8.ew.3yo.vs)$coefficients[2, 4]
rm (glm.du.8.ew.3yo.vs)
gc ()

glm.du.8.ew.4yo.vs <- glm (pttype ~ beetle_very_severe_4yo, 
                           data = beetle.data.du.8.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [160, 1] <- "8"
table.glm.summary.insect [160, 2] <- "Early Winter"
table.glm.summary.insect [160, 3] <- "Very Severe"
table.glm.summary.insect [160, 4] <- 4
table.glm.summary.insect [160, 5] <- glm.du.8.ew.4yo.vs$coefficients [[2]]
table.glm.summary.insect [160, 6] <- summary (glm.du.8.ew.4yo.vs)$coefficients[2, 4]
rm (glm.du.8.ew.4yo.vs)
gc ()

glm.du.8.ew.5yo.vs <- glm (pttype ~ beetle_very_severe_5yo, 
                           data = beetle.data.du.8.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [161, 1] <- "8"
table.glm.summary.insect [161, 2] <- "Early Winter"
table.glm.summary.insect [161, 3] <- "Very Severe"
table.glm.summary.insect [161, 4] <- 5
table.glm.summary.insect [161, 5] <- glm.du.8.ew.5yo.vs$coefficients [[2]]
table.glm.summary.insect [161, 6] <- summary (glm.du.8.ew.5yo.vs)$coefficients[2, 4]
rm (glm.du.8.ew.5yo.vs)
gc ()

### Late Winter ###
glm.du.8.lw.1yo.m <- glm (pttype ~ beetle_moderate_1yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [162, 1] <- "8"
table.glm.summary.insect  [162, 2] <- "Late Winter"
table.glm.summary.insect  [162, 3] <- "Moderate"
table.glm.summary.insect  [162, 4] <- 1
table.glm.summary.insect [162, 5] <- glm.du.8.lw.1yo.m$coefficients [[2]]
table.glm.summary.insect [162, 6] <- summary (glm.du.8.lw.1yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.lw.1yo.m)
gc ()

glm.du.8.lw.2yo.m <- glm (pttype ~ beetle_moderate_2yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [163, 1] <- "8"
table.glm.summary.insect  [163, 2] <- "Late Winter"
table.glm.summary.insect  [163, 3] <- "Moderate"
table.glm.summary.insect  [163, 4] <- 2
table.glm.summary.insect [163, 5] <- glm.du.8.lw.2yo.m$coefficients [[2]]
table.glm.summary.insect [163, 6] <- summary (glm.du.8.lw.2yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.lw.2yo.m)
gc ()

glm.du.8.lw.3yo.m <- glm (pttype ~ beetle_moderate_3yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect [164, 1] <- "8"
table.glm.summary.insect [164, 2] <- "Late Winter"
table.glm.summary.insect [164, 3] <- "Moderate"
table.glm.summary.insect [164, 4] <- 3
table.glm.summary.insect [164, 5] <- glm.du.8.lw.3yo.m$coefficients [[2]]
table.glm.summary.insect [164, 6] <- summary (glm.du.8.lw.3yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.lw.3yo.m)
gc ()

glm.du.8.lw.4yo.m <- glm (pttype ~ beetle_moderate_4yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [165, 1] <- "8"
table.glm.summary.insect  [165, 2] <- "Late Winter"
table.glm.summary.insect  [165, 3] <- "Moderate"
table.glm.summary.insect  [165, 4] <- 4
table.glm.summary.insect [165, 5] <- glm.du.8.lw.4yo.m$coefficients [[2]]
table.glm.summary.insect [165, 6] <- summary (glm.du.8.lw.4yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.lw.4yo.m)
gc ()

glm.du.8.lw.5yo.m <- glm (pttype ~ beetle_moderate_5yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [166, 1] <- "8"
table.glm.summary.insect  [166, 2] <- "Late Winter"
table.glm.summary.insect  [166, 3] <- "Moderate"
table.glm.summary.insect  [166, 4] <- 5
table.glm.summary.insect [166, 5] <- glm.du.8.lw.5yo.m$coefficients [[2]]
table.glm.summary.insect [166, 6] <- summary (glm.du.8.lw.5yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.lw.5yo.m)
gc ()

glm.du.8.lw.6yo.m <- glm (pttype ~ beetle_moderate_6yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [167, 1] <- "8"
table.glm.summary.insect  [167, 2] <- "Late Winter"
table.glm.summary.insect  [167, 3] <- "Moderate"
table.glm.summary.insect  [167, 4] <- 6
table.glm.summary.insect [167, 5] <- glm.du.8.lw.6yo.m$coefficients [[2]]
table.glm.summary.insect [167, 6] <- summary (glm.du.8.lw.6yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.lw.6yo.m)
gc ()

glm.du.8.lw.7yo.m <- glm (pttype ~ beetle_moderate_7yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [168, 1] <- "8"
table.glm.summary.insect  [168, 2] <- "Late Winter"
table.glm.summary.insect  [168, 3] <- "Moderate"
table.glm.summary.insect  [168, 4] <- 7
table.glm.summary.insect [168, 5] <- glm.du.8.lw.7yo.m$coefficients [[2]]
table.glm.summary.insect [168, 6] <- summary (glm.du.8.lw.7yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.lw.7yo.m)
gc ()

glm.du.8.lw.8yo.m <- glm (pttype ~ beetle_moderate_8yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [169, 1] <- "8"
table.glm.summary.insect  [169, 2] <- "Late Winter"
table.glm.summary.insect  [169, 3] <- "Moderate"
table.glm.summary.insect  [169, 4] <- 8
table.glm.summary.insect [169, 5] <- glm.du.8.lw.8yo.m$coefficients [[2]]
table.glm.summary.insect [169, 6] <- summary (glm.du.8.lw.8yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.lw.8yo.m)
gc ()

glm.du.8.lw.9yo.m <- glm (pttype ~ beetle_moderate_9yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [170, 1] <- "8"
table.glm.summary.insect  [170, 2] <- "Late Winter"
table.glm.summary.insect  [170, 3] <- "Moderate"
table.glm.summary.insect  [170, 4] <- 9
table.glm.summary.insect [170, 5] <- glm.du.8.lw.9yo.m$coefficients [[2]]
table.glm.summary.insect [170, 6] <- summary (glm.du.8.lw.9yo.m)$coefficients[2, 4]
rm (glm.du.8.lw.9yo.m)
gc ()

glm.du.8.lw.1yo.s <- glm (pttype ~ beetle_severe_1yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [171, 1] <- "8"
table.glm.summary.insect  [171, 2] <- "Late Winter"
table.glm.summary.insect  [171, 3] <- "Severe"
table.glm.summary.insect  [171, 4] <- 1
table.glm.summary.insect [171, 5] <- glm.du.8.lw.1yo.s$coefficients [[2]]
table.glm.summary.insect [171, 6] <- summary (glm.du.8.lw.1yo.s)$coefficients[2, 4] # p-value
rm (glm.du.8.lw.1yo.s)
gc ()

glm.du.8.lw.2yo.s <- glm (pttype ~ beetle_severe_2yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [172, 1] <- "8"
table.glm.summary.insect  [172, 2] <- "Late Winter"
table.glm.summary.insect  [172, 3] <- "Severe"
table.glm.summary.insect  [172, 4] <- 2
table.glm.summary.insect [172, 5] <- glm.du.8.lw.2yo.s$coefficients [[2]]
table.glm.summary.insect [172, 6] <- summary (glm.du.8.lw.2yo.s)$coefficients[2, 4] # p-value
rm (glm.du.8.lw.2yo.s)
gc ()

glm.du.8.lw.3yo.s <- glm (pttype ~ beetle_severe_3yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [173, 1] <- "8"
table.glm.summary.insect  [173, 2] <- "Late Winter"
table.glm.summary.insect  [173, 3] <- "Severe"
table.glm.summary.insect  [173, 4] <- 3
table.glm.summary.insect [173, 5] <- glm.du.8.lw.3yo.s$coefficients [[2]]
table.glm.summary.insect [173, 6] <- summary (glm.du.8.lw.3yo.s)$coefficients[2, 4] # p-value
rm (glm.du.8.lw.3yo.s)
gc ()

glm.du.8.lw.4yo.s <- glm (pttype ~ beetle_severe_4yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [174, 1] <- "8"
table.glm.summary.insect  [174, 2] <- "Late Winter"
table.glm.summary.insect  [174, 3] <- "Severe"
table.glm.summary.insect  [174, 4] <- 4
table.glm.summary.insect [174, 5] <- glm.du.8.lw.4yo.s$coefficients [[2]]
table.glm.summary.insect [174, 6] <- summary (glm.du.8.lw.4yo.s)$coefficients[2, 4] # p-value
rm (glm.du.8.lw.4yo.s)
gc ()

glm.du.8.lw.5yo.s <- glm (pttype ~ beetle_severe_5yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [175, 1] <- "8"
table.glm.summary.insect  [175, 2] <- "Late Winter"
table.glm.summary.insect  [175, 3] <- "Severe"
table.glm.summary.insect  [175, 4] <- 5
table.glm.summary.insect [175, 5] <- glm.du.8.lw.5yo.s$coefficients [[2]]
table.glm.summary.insect [175, 6] <- summary (glm.du.8.lw.5yo.s)$coefficients[2, 4]
rm (glm.du.8.lw.5yo.s)
gc ()

glm.du.8.lw.6yo.s <- glm (pttype ~ beetle_severe_6yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [176, 1] <- "8"
table.glm.summary.insect  [176, 2] <- "Late Winter"
table.glm.summary.insect  [176, 3] <- "Severe"
table.glm.summary.insect  [176, 4] <- 6
table.glm.summary.insect [176, 5] <- glm.du.8.lw.6yo.s$coefficients [[2]]
table.glm.summary.insect [176, 6] <- summary (glm.du.8.lw.6yo.s)$coefficients[2, 4]
rm (glm.du.8.lw.6yo.s)
gc ()

glm.du.8.lw.7yo.s <- glm (pttype ~ beetle_severe_7yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [177, 1] <- "8"
table.glm.summary.insect  [177, 2] <- "Late Winter"
table.glm.summary.insect  [177, 3] <- "Severe"
table.glm.summary.insect  [177, 4] <- 7
table.glm.summary.insect [177, 5] <- glm.du.8.lw.7yo.s$coefficients [[2]]
table.glm.summary.insect [177, 6] <- summary (glm.du.8.lw.7yo.s)$coefficients[2, 4]
rm (glm.du.8.lw.7yo.s)
gc ()

glm.du.8.lw.8yo.s <- glm (pttype ~ beetle_severe_8yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [178, 1] <- "8"
table.glm.summary.insect  [178, 2] <- "Late Winter"
table.glm.summary.insect  [178, 3] <- "Severe"
table.glm.summary.insect  [178, 4] <- 8
table.glm.summary.insect [178, 5] <- glm.du.8.lw.8yo.s$coefficients [[2]]
table.glm.summary.insect [178, 6] <- summary (glm.du.8.lw.8yo.s)$coefficients[2, 4]
rm (glm.du.8.lw.8yo.s)
gc ()

glm.du.8.lw.9yo.s <- glm (pttype ~ beetle_severe_9yo, 
                          data = beetle.data.du.8.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [179, 1] <- "8"
table.glm.summary.insect  [179, 2] <- "Late Winter"
table.glm.summary.insect  [179, 3] <- "Severe"
table.glm.summary.insect  [179, 4] <- 9
table.glm.summary.insect [179, 5] <- glm.du.8.lw.9yo.s$coefficients [[2]]
table.glm.summary.insect [179, 6] <- summary (glm.du.8.lw.9yo.s)$coefficients[2, 4]
rm (glm.du.8.lw.9yo.s)
gc ()

glm.du.8.lw.1yo.vs <- glm (pttype ~ beetle_very_severe_1yo, 
                           data = beetle.data.du.8.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [180, 1] <- "8"
table.glm.summary.insect [180, 2] <- "Late Winter"
table.glm.summary.insect [180, 3] <- "Very Severe"
table.glm.summary.insect [180, 4] <- 1
table.glm.summary.insect [180, 5] <- glm.du.8.lw.1yo.vs$coefficients [[2]]
table.glm.summary.insect [180, 6] <- summary (glm.du.8.lw.1yo.vs)$coefficients[2, 4]
rm (glm.du.8.lw.1yo.vs)
gc ()

glm.du.8.lw.2yo.vs <- glm (pttype ~ beetle_very_severe_2yo, 
                           data = beetle.data.du.8.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [181, 1] <- "8"
table.glm.summary.insect [181, 2] <- "Late Winter"
table.glm.summary.insect [181, 3] <- "Very Severe"
table.glm.summary.insect [181, 4] <- 2
table.glm.summary.insect [181, 5] <- glm.du.8.lw.2yo.vs$coefficients [[2]]
table.glm.summary.insect [181, 6] <- summary (glm.du.8.lw.2yo.vs)$coefficients[2, 4]
rm (glm.du.8.lw.2yo.vs)
gc ()

glm.du.8.lw.3yo.vs <- glm (pttype ~ beetle_very_severe_3yo, 
                           data = beetle.data.du.8.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [182, 1] <- "8"
table.glm.summary.insect [182, 2] <- "Late Winter"
table.glm.summary.insect [182, 3] <- "Very Severe"
table.glm.summary.insect [182, 4] <- 3
table.glm.summary.insect [182, 5] <- glm.du.8.lw.3yo.vs$coefficients [[2]]
table.glm.summary.insect [182, 6] <- summary (glm.du.8.lw.3yo.vs)$coefficients[2, 4]
rm (glm.du.8.lw.3yo.vs)
gc ()

glm.du.8.lw.4yo.vs <- glm (pttype ~ beetle_very_severe_4yo, 
                           data = beetle.data.du.8.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [183, 1] <- "8"
table.glm.summary.insect [183, 2] <- "Late Winter"
table.glm.summary.insect [183, 3] <- "Very Severe"
table.glm.summary.insect [183, 4] <- 4
table.glm.summary.insect [183, 5] <- glm.du.8.lw.4yo.vs$coefficients [[2]]
table.glm.summary.insect [183, 6] <- summary (glm.du.8.lw.4yo.vs)$coefficients[2, 4]
rm (glm.du.8.lw.4yo.vs)
gc ()

glm.du.8.lw.5yo.vs <- glm (pttype ~ beetle_very_severe_5yo, 
                           data = beetle.data.du.8.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [184, 1] <- "8"
table.glm.summary.insect [184, 2] <- "Late Winter"
table.glm.summary.insect [184, 3] <- "Very Severe"
table.glm.summary.insect [184, 4] <- 5
table.glm.summary.insect [184, 5] <- glm.du.8.lw.5yo.vs$coefficients [[2]]
table.glm.summary.insect [184, 6] <- summary (glm.du.8.lw.5yo.vs)$coefficients[2, 4]
rm (glm.du.8.lw.5yo.vs)
gc ()

### Summer ###
glm.du.8.s.1yo.m <- glm (pttype ~ beetle_moderate_1yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [185, 1] <- "8"
table.glm.summary.insect  [185, 2] <- "Summer"
table.glm.summary.insect  [185, 3] <- "Moderate"
table.glm.summary.insect  [185, 4] <- 1
table.glm.summary.insect [185, 5] <- glm.du.8.s.1yo.m$coefficients [[2]]
table.glm.summary.insect [185, 6] <- summary (glm.du.8.s.1yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.s.1yo.m)
gc ()

glm.du.8.s.2yo.m <- glm (pttype ~ beetle_moderate_2yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [186, 1] <- "8"
table.glm.summary.insect  [186, 2] <- "Summer"
table.glm.summary.insect  [186, 3] <- "Moderate"
table.glm.summary.insect  [186, 4] <- 2
table.glm.summary.insect [186, 5] <- glm.du.8.s.2yo.m$coefficients [[2]]
table.glm.summary.insect [186, 6] <- summary (glm.du.8.s.2yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.s.2yo.m)
gc ()

glm.du.8.s.3yo.m <- glm (pttype ~ beetle_moderate_3yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect [187, 1] <- "8"
table.glm.summary.insect [187, 2] <- "Summer"
table.glm.summary.insect [187, 3] <- "Moderate"
table.glm.summary.insect [187, 4] <- 3
table.glm.summary.insect [187, 5] <- glm.du.8.s.3yo.m$coefficients [[2]]
table.glm.summary.insect [187, 6] <- summary (glm.du.8.s.3yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.s.3yo.m)
gc ()

glm.du.8.s.4yo.m <- glm (pttype ~ beetle_moderate_4yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [188, 1] <- "8"
table.glm.summary.insect  [188, 2] <- "Summer"
table.glm.summary.insect  [188, 3] <- "Moderate"
table.glm.summary.insect  [188, 4] <- 4
table.glm.summary.insect [188, 5] <- glm.du.8.s.4yo.m$coefficients [[2]]
table.glm.summary.insect [188, 6] <- summary (glm.du.8.s.4yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.s.4yo.m)
gc ()

glm.du.8.s.5yo.m <- glm (pttype ~ beetle_moderate_5yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [189, 1] <- "8"
table.glm.summary.insect  [189, 2] <- "Summer"
table.glm.summary.insect  [189, 3] <- "Moderate"
table.glm.summary.insect  [189, 4] <- 5
table.glm.summary.insect [189, 5] <- glm.du.8.s.5yo.m$coefficients [[2]]
table.glm.summary.insect [189, 6] <- summary (glm.du.8.s.5yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.s.5yo.m)
gc ()

glm.du.8.s.6yo.m <- glm (pttype ~ beetle_moderate_6yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [190, 1] <- "8"
table.glm.summary.insect  [190, 2] <- "Summer"
table.glm.summary.insect  [190, 3] <- "Moderate"
table.glm.summary.insect  [190, 4] <- 6
table.glm.summary.insect [190, 5] <- glm.du.8.s.6yo.m$coefficients [[2]]
table.glm.summary.insect [190, 6] <- summary (glm.du.8.s.6yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.s.6yo.m)
gc ()

glm.du.8.s.7yo.m <- glm (pttype ~ beetle_moderate_7yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [191, 1] <- "8"
table.glm.summary.insect  [191, 2] <- "Summer"
table.glm.summary.insect  [191, 3] <- "Moderate"
table.glm.summary.insect  [191, 4] <- 7
table.glm.summary.insect [191, 5] <- glm.du.8.s.7yo.m$coefficients [[2]]
table.glm.summary.insect [191, 6] <- summary (glm.du.8.s.7yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.s.7yo.m)
gc ()

glm.du.8.s.8yo.m <- glm (pttype ~ beetle_moderate_8yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [192, 1] <- "8"
table.glm.summary.insect  [192, 2] <- "Summer"
table.glm.summary.insect  [192, 3] <- "Moderate"
table.glm.summary.insect  [192, 4] <- 8
table.glm.summary.insect [192, 5] <- glm.du.8.s.8yo.m$coefficients [[2]]
table.glm.summary.insect [192, 6] <- summary (glm.du.8.s.8yo.m)$coefficients[2, 4] # p-value
rm (glm.du.8.s.8yo.m)
gc ()

glm.du.8.s.9yo.m <- glm (pttype ~ beetle_moderate_9yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [193, 1] <- "8"
table.glm.summary.insect  [193, 2] <- "Summer"
table.glm.summary.insect  [193, 3] <- "Moderate"
table.glm.summary.insect  [193, 4] <- 9
table.glm.summary.insect [193, 5] <- glm.du.8.s.9yo.m$coefficients [[2]]
table.glm.summary.insect [193, 6] <- summary (glm.du.8.s.9yo.m)$coefficients[2, 4]
rm (glm.du.8.s.9yo.m)
gc ()

glm.du.8.s.1yo.s <- glm (pttype ~ beetle_severe_1yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [194, 1] <- "8"
table.glm.summary.insect  [194, 2] <- "Summer"
table.glm.summary.insect  [194, 3] <- "Severe"
table.glm.summary.insect  [194, 4] <- 1
table.glm.summary.insect [194, 5] <- glm.du.8.s.1yo.s$coefficients [[2]]
table.glm.summary.insect [194, 6] <- summary (glm.du.8.s.1yo.s)$coefficients[2, 4] # p-value
rm (glm.du.8.s.1yo.s)
gc ()

glm.du.8.s.2yo.s <- glm (pttype ~ beetle_severe_2yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [195, 1] <- "8"
table.glm.summary.insect  [195, 2] <- "Summer"
table.glm.summary.insect  [195, 3] <- "Severe"
table.glm.summary.insect  [195, 4] <- 2
table.glm.summary.insect [195, 5] <- glm.du.8.s.2yo.s$coefficients [[2]]
table.glm.summary.insect [195, 6] <- summary (glm.du.8.s.2yo.s)$coefficients[2, 4] # p-value
rm (glm.du.8.s.2yo.s)
gc ()

glm.du.8.s.3yo.s <- glm (pttype ~ beetle_severe_3yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [196, 1] <- "8"
table.glm.summary.insect  [196, 2] <- "Summer"
table.glm.summary.insect  [196, 3] <- "Severe"
table.glm.summary.insect  [196, 4] <- 3
table.glm.summary.insect [196, 5] <- glm.du.8.s.3yo.s$coefficients [[2]]
table.glm.summary.insect [196, 6] <- summary (glm.du.8.s.3yo.s)$coefficients[2, 4] # p-value
rm (glm.du.8.s.3yo.s)
gc ()

glm.du.8.s.4yo.s <- glm (pttype ~ beetle_severe_4yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [197, 1] <- "8"
table.glm.summary.insect  [197, 2] <- "Summer"
table.glm.summary.insect  [197, 3] <- "Severe"
table.glm.summary.insect  [197, 4] <- 4
table.glm.summary.insect [197, 5] <- glm.du.8.s.4yo.s$coefficients [[2]]
table.glm.summary.insect [197, 6] <- summary (glm.du.8.s.4yo.s)$coefficients[2, 4] # p-value
rm (glm.du.8.s.4yo.s)
gc ()

glm.du.8.s.5yo.s <- glm (pttype ~ beetle_severe_5yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [198, 1] <- "8"
table.glm.summary.insect  [198, 2] <- "Summer"
table.glm.summary.insect  [198, 3] <- "Severe"
table.glm.summary.insect  [198, 4] <- 5
table.glm.summary.insect [198, 5] <- glm.du.8.s.5yo.s$coefficients [[2]]
table.glm.summary.insect [198, 6] <- summary (glm.du.8.s.5yo.s)$coefficients[2, 4]
rm (glm.du.8.s.5yo.s)
gc ()

glm.du.8.s.6yo.s <- glm (pttype ~ beetle_severe_6yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [199, 1] <- "8"
table.glm.summary.insect  [199, 2] <- "Summer"
table.glm.summary.insect  [199, 3] <- "Severe"
table.glm.summary.insect  [199, 4] <- 6
table.glm.summary.insect [199, 5] <- glm.du.8.s.6yo.s$coefficients [[2]]
table.glm.summary.insect [199, 6] <- summary (glm.du.8.s.6yo.s)$coefficients[2, 4]
rm (glm.du.8.s.6yo.s)
gc ()

glm.du.8.s.7yo.s <- glm (pttype ~ beetle_severe_7yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [200, 1] <- "8"
table.glm.summary.insect  [200, 2] <- "Summer"
table.glm.summary.insect  [200, 3] <- "Severe"
table.glm.summary.insect  [200, 4] <- 7
table.glm.summary.insect [200, 5] <- glm.du.8.s.7yo.s$coefficients [[2]]
table.glm.summary.insect [200, 6] <- summary (glm.du.8.s.7yo.s)$coefficients[2, 4]
rm (glm.du.8.s.7yo.s)
gc ()

glm.du.8.s.8yo.s <- glm (pttype ~ beetle_severe_8yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [201, 1] <- "8"
table.glm.summary.insect  [201, 2] <- "Summer"
table.glm.summary.insect  [201, 3] <- "Severe"
table.glm.summary.insect  [201, 4] <- 8
table.glm.summary.insect [201, 5] <- glm.du.8.s.8yo.s$coefficients [[2]]
table.glm.summary.insect [201, 6] <- summary (glm.du.8.s.8yo.s)$coefficients[2, 4]
rm (glm.du.8.s.8yo.s)
gc ()

glm.du.8.s.9yo.s <- glm (pttype ~ beetle_severe_9yo, 
                          data = beetle.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [202, 1] <- "8"
table.glm.summary.insect  [202, 2] <- "Summer"
table.glm.summary.insect  [202, 3] <- "Severe"
table.glm.summary.insect  [202, 4] <- 9
table.glm.summary.insect [202, 5] <- glm.du.8.s.9yo.s$coefficients [[2]]
table.glm.summary.insect [202, 6] <- summary (glm.du.8.s.9yo.s)$coefficients[2, 4]
rm (glm.du.8.s.9yo.s)
gc ()

glm.du.8.s.1yo.vs <- glm (pttype ~ beetle_very_severe_1yo, 
                           data = beetle.data.du.8.s,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [203, 1] <- "8"
table.glm.summary.insect [203, 2] <- "Summer"
table.glm.summary.insect [203, 3] <- "Very Severe"
table.glm.summary.insect [203, 4] <- 1
table.glm.summary.insect [203, 5] <- glm.du.8.s.1yo.vs$coefficients [[2]]
table.glm.summary.insect [203, 6] <- summary (glm.du.8.s.1yo.vs)$coefficients[2, 4]
rm (glm.du.8.s.1yo.vs)
gc ()

glm.du.8.s.2yo.vs <- glm (pttype ~ beetle_very_severe_2yo, 
                           data = beetle.data.du.8.s,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [204, 1] <- "8"
table.glm.summary.insect [204, 2] <- "Summer"
table.glm.summary.insect [204, 3] <- "Very Severe"
table.glm.summary.insect [204, 4] <- 2
table.glm.summary.insect [204, 5] <- glm.du.8.s.2yo.vs$coefficients [[2]]
table.glm.summary.insect [204, 6] <- summary (glm.du.8.s.2yo.vs)$coefficients[2, 4]
rm (glm.du.8.s.2yo.vs)
gc ()

glm.du.8.s.3yo.vs <- glm (pttype ~ beetle_very_severe_3yo, 
                           data = beetle.data.du.8.s,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [205, 1] <- "8"
table.glm.summary.insect [205, 2] <- "Summer"
table.glm.summary.insect [205, 3] <- "Very Severe"
table.glm.summary.insect [205, 4] <- 3
table.glm.summary.insect [205, 5] <- glm.du.8.s.3yo.vs$coefficients [[2]]
table.glm.summary.insect [205, 6] <- summary (glm.du.8.s.3yo.vs)$coefficients[2, 4]
rm (glm.du.8.s.3yo.vs)
gc ()

glm.du.8.s.4yo.vs <- glm (pttype ~ beetle_very_severe_4yo, 
                           data = beetle.data.du.8.s,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [206, 1] <- "8"
table.glm.summary.insect [206, 2] <- "Summer"
table.glm.summary.insect [206, 3] <- "Very Severe"
table.glm.summary.insect [206, 4] <- 4
table.glm.summary.insect [206, 5] <- glm.du.8.s.4yo.vs$coefficients [[2]]
table.glm.summary.insect [206, 6] <- summary (glm.du.8.s.4yo.vs)$coefficients[2, 4]
rm (glm.du.8.s.4yo.vs)
gc ()

glm.du.8.s.5yo.vs <- glm (pttype ~ beetle_very_severe_5yo, 
                           data = beetle.data.du.8.s,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [207, 1] <- "8"
table.glm.summary.insect [207, 2] <- "Summer"
table.glm.summary.insect [207, 3] <- "Very Severe"
table.glm.summary.insect [207, 4] <- 5
table.glm.summary.insect [207, 5] <- glm.du.8.s.5yo.vs$coefficients [[2]]
table.glm.summary.insect [207, 6] <- summary (glm.du.8.s.5yo.vs)$coefficients[2, 4]
rm (glm.du.8.s.5yo.vs)
gc ()

## DU9 ##
### Early Winter ###
glm.du.9.ew.1yo.m <- glm (pttype ~ beetle_moderate_1yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [208, 1] <- "9"
table.glm.summary.insect  [208, 2] <- "Early Winter"
table.glm.summary.insect  [208, 3] <- "Moderate"
table.glm.summary.insect  [208, 4] <- 1
table.glm.summary.insect [208, 5] <- glm.du.9.ew.1yo.m$coefficients [[2]]
table.glm.summary.insect [208, 6] <- summary (glm.du.9.ew.1yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.ew.1yo.m)
gc ()

glm.du.9.ew.2yo.m <- glm (pttype ~ beetle_moderate_2yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [209, 1] <- "9"
table.glm.summary.insect  [209, 2] <- "Early Winter"
table.glm.summary.insect  [209, 3] <- "Moderate"
table.glm.summary.insect  [209, 4] <- 2
table.glm.summary.insect [209, 5] <- glm.du.9.ew.2yo.m$coefficients [[2]]
table.glm.summary.insect [209, 6] <- summary (glm.du.9.ew.2yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.ew.2yo.m)
gc ()

glm.du.9.ew.3yo.m <- glm (pttype ~ beetle_moderate_3yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect [210, 1] <- "9"
table.glm.summary.insect [210, 2] <- "Early Winter"
table.glm.summary.insect [210, 3] <- "Moderate"
table.glm.summary.insect [210, 4] <- 3
table.glm.summary.insect [210, 5] <- glm.du.9.ew.3yo.m$coefficients [[2]]
table.glm.summary.insect [210, 6] <- summary (glm.du.9.ew.3yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.ew.3yo.m)
gc ()

glm.du.9.ew.4yo.m <- glm (pttype ~ beetle_moderate_4yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [211, 1] <- "9"
table.glm.summary.insect  [211, 2] <- "Early Winter"
table.glm.summary.insect  [211, 3] <- "Moderate"
table.glm.summary.insect  [211, 4] <- 4
table.glm.summary.insect [211, 5] <- NA
table.glm.summary.insect [211, 6] <- NA
rm (glm.du.9.ew.4yo.m)
gc ()

glm.du.9.ew.5yo.m <- glm (pttype ~ beetle_moderate_5yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [212, 1] <- "9"
table.glm.summary.insect  [212, 2] <- "Early Winter"
table.glm.summary.insect  [212, 3] <- "Moderate"
table.glm.summary.insect  [212, 4] <- 5
table.glm.summary.insect [212, 5] <- glm.du.9.ew.5yo.m$coefficients [[2]]
table.glm.summary.insect [212, 6] <- summary (glm.du.9.ew.5yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.ew.5yo.m)
gc ()

glm.du.9.ew.6yo.m <- glm (pttype ~ beetle_moderate_6yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [213, 1] <- "9"
table.glm.summary.insect  [213, 2] <- "Early Winter"
table.glm.summary.insect  [213, 3] <- "Moderate"
table.glm.summary.insect  [213, 4] <- 6
table.glm.summary.insect [213, 5] <- glm.du.9.ew.6yo.m$coefficients [[2]]
table.glm.summary.insect [213, 6] <- summary (glm.du.9.ew.6yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.ew.6yo.m)
gc ()

glm.du.9.ew.7yo.m <- glm (pttype ~ beetle_moderate_7yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [214, 1] <- "9"
table.glm.summary.insect  [214, 2] <- "Early Winter"
table.glm.summary.insect  [214, 3] <- "Moderate"
table.glm.summary.insect  [214, 4] <- 7
table.glm.summary.insect [214, 5] <- glm.du.9.ew.7yo.m$coefficients [[2]]
table.glm.summary.insect [214, 6] <- summary (glm.du.9.ew.7yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.ew.7yo.m)
gc ()

glm.du.9.ew.8yo.m <- glm (pttype ~ beetle_moderate_8yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [215, 1] <- "9"
table.glm.summary.insect  [215, 2] <- "Early Winter"
table.glm.summary.insect  [215, 3] <- "Moderate"
table.glm.summary.insect  [215, 4] <- 8
table.glm.summary.insect [215, 5] <- glm.du.9.ew.8yo.m$coefficients [[2]]
table.glm.summary.insect [215, 6] <- summary (glm.du.9.ew.8yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.ew.8yo.m)
gc ()

glm.du.9.ew.9yo.m <- glm (pttype ~ beetle_moderate_9yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [216, 1] <- "9"
table.glm.summary.insect  [216, 2] <- "Early Winter"
table.glm.summary.insect  [216, 3] <- "Moderate"
table.glm.summary.insect  [216, 4] <- 9
table.glm.summary.insect [216, 5] <- glm.du.9.ew.9yo.m$coefficients [[2]]
table.glm.summary.insect [216, 6] <- summary (glm.du.9.ew.9yo.m)$coefficients[2, 4]
rm (glm.du.9.ew.9yo.m)
gc ()

glm.du.9.ew.1yo.s <- glm (pttype ~ beetle_severe_1yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [217, 1] <- "9"
table.glm.summary.insect  [217, 2] <- "Early Winter"
table.glm.summary.insect  [217, 3] <- "Severe"
table.glm.summary.insect  [217, 4] <- 1
table.glm.summary.insect [217, 5] <- NA
table.glm.summary.insect [217, 6] <- NA
rm (glm.du.9.ew.1yo.s)
gc ()

glm.du.9.ew.2yo.s <- glm (pttype ~ beetle_severe_2yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [218, 1] <- "9"
table.glm.summary.insect  [218, 2] <- "Early Winter"
table.glm.summary.insect  [218, 3] <- "Severe"
table.glm.summary.insect  [218, 4] <- 2
table.glm.summary.insect [218, 5] <- glm.du.9.ew.2yo.s$coefficients [[2]]
table.glm.summary.insect [218, 6] <- summary (glm.du.9.ew.2yo.s)$coefficients[2, 4] # p-value
rm (glm.du.9.ew.2yo.s)
gc ()

glm.du.9.ew.3yo.s <- glm (pttype ~ beetle_severe_3yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [219, 1] <- "9"
table.glm.summary.insect  [219, 2] <- "Early Winter"
table.glm.summary.insect  [219, 3] <- "Severe"
table.glm.summary.insect  [219, 4] <- 3
table.glm.summary.insect [219, 5] <- NA
table.glm.summary.insect [219, 6] <- NA
rm (glm.du.9.ew.3yo.s)
gc ()

glm.du.9.ew.4yo.s <- glm (pttype ~ beetle_severe_4yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [220, 1] <- "9"
table.glm.summary.insect  [220, 2] <- "Early Winter"
table.glm.summary.insect  [220, 3] <- "Severe"
table.glm.summary.insect  [220, 4] <- 4
table.glm.summary.insect [220, 5] <- glm.du.9.ew.4yo.s$coefficients [[2]]
table.glm.summary.insect [220, 6] <- summary (glm.du.9.ew.4yo.s)$coefficients[2, 4] # p-value
rm (glm.du.9.ew.4yo.s)
gc ()

glm.du.9.ew.5yo.s <- glm (pttype ~ beetle_severe_5yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [221, 1] <- "9"
table.glm.summary.insect  [221, 2] <- "Early Winter"
table.glm.summary.insect  [221, 3] <- "Severe"
table.glm.summary.insect  [221, 4] <- 5
table.glm.summary.insect [221, 5] <- NA
table.glm.summary.insect [221, 6] <- NA
rm (glm.du.9.ew.5yo.s)
gc ()

glm.du.9.ew.6yo.s <- glm (pttype ~ beetle_severe_6yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [222, 1] <- "9"
table.glm.summary.insect  [222, 2] <- "Early Winter"
table.glm.summary.insect  [222, 3] <- "Severe"
table.glm.summary.insect  [222, 4] <- 6
table.glm.summary.insect [222, 5] <- NA
table.glm.summary.insect [222, 6] <- NA
rm (glm.du.9.ew.6yo.s)
gc ()

glm.du.9.ew.7yo.s <- glm (pttype ~ beetle_severe_7yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [223, 1] <- "9"
table.glm.summary.insect  [223, 2] <- "Early Winter"
table.glm.summary.insect  [223, 3] <- "Severe"
table.glm.summary.insect  [223, 4] <- 7
table.glm.summary.insect [223, 5] <- NA
table.glm.summary.insect [223, 6] <- NA
rm (glm.du.9.ew.7yo.s)
gc ()

glm.du.9.ew.8yo.s <- glm (pttype ~ beetle_severe_8yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [224, 1] <- "9"
table.glm.summary.insect  [224, 2] <- "Early Winter"
table.glm.summary.insect  [224, 3] <- "Severe"
table.glm.summary.insect  [224, 4] <- 8
table.glm.summary.insect [224, 5] <- glm.du.9.ew.8yo.s$coefficients [[2]]
table.glm.summary.insect [224, 6] <- summary (glm.du.9.ew.8yo.s)$coefficients[2, 4]
rm (glm.du.9.ew.8yo.s)
gc ()

glm.du.9.ew.9yo.s <- glm (pttype ~ beetle_severe_9yo, 
                          data = beetle.data.du.9.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [225, 1] <- "9"
table.glm.summary.insect  [225, 2] <- "Early Winter"
table.glm.summary.insect  [225, 3] <- "Severe"
table.glm.summary.insect  [225, 4] <- 9
table.glm.summary.insect [225, 5] <- glm.du.9.ew.9yo.s$coefficients [[2]]
table.glm.summary.insect [225, 6] <- summary (glm.du.9.ew.9yo.s)$coefficients[2, 4]
rm (glm.du.9.ew.9yo.s)
gc ()

glm.du.9.ew.1yo.vs <- glm (pttype ~ beetle_very_severe_1yo, 
                           data = beetle.data.du.9.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [226, 1] <- "9"
table.glm.summary.insect [226, 2] <- "Early Winter"
table.glm.summary.insect [226, 3] <- "Very Severe"
table.glm.summary.insect [226, 4] <- 1
table.glm.summary.insect [226, 5] <- glm.du.9.ew.1yo.vs$coefficients [[2]]
table.glm.summary.insect [226, 6] <- summary (glm.du.9.ew.1yo.vs)$coefficients[2, 4]
rm (glm.du.9.ew.1yo.vs)
gc ()

glm.du.9.ew.2yo.vs <- glm (pttype ~ beetle_very_severe_2yo, 
                           data = beetle.data.du.9.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [227, 1] <- "9"
table.glm.summary.insect [227, 2] <- "Early Winter"
table.glm.summary.insect [227, 3] <- "Very Severe"
table.glm.summary.insect [227, 4] <- 2
table.glm.summary.insect [227, 5] <- NA
table.glm.summary.insect [227, 6] <- NA
rm (glm.du.9.ew.2yo.vs)
gc ()

glm.du.9.ew.3yo.vs <- glm (pttype ~ beetle_very_severe_3yo, 
                           data = beetle.data.du.9.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [228, 1] <- "9"
table.glm.summary.insect [228, 2] <- "Early Winter"
table.glm.summary.insect [228, 3] <- "Very Severe"
table.glm.summary.insect [228, 4] <- 3
table.glm.summary.insect [228, 5] <- NA
table.glm.summary.insect [228, 6] <- NA
rm (glm.du.9.ew.3yo.vs)
gc ()

glm.du.9.ew.4yo.vs <- glm (pttype ~ beetle_very_severe_4yo, 
                           data = beetle.data.du.9.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [229, 1] <- "9"
table.glm.summary.insect [229, 2] <- "Early Winter"
table.glm.summary.insect [229, 3] <- "Very Severe"
table.glm.summary.insect [229, 4] <- 4
table.glm.summary.insect [229, 5] <- NA
table.glm.summary.insect [229, 6] <- NA
rm (glm.du.9.ew.4yo.vs)
gc ()

glm.du.9.ew.5yo.vs <- glm (pttype ~ beetle_very_severe_5yo, 
                           data = beetle.data.du.9.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [230, 1] <- "9"
table.glm.summary.insect [230, 2] <- "Early Winter"
table.glm.summary.insect [230, 3] <- "Very Severe"
table.glm.summary.insect [230, 4] <- 5
table.glm.summary.insect [230, 5] <- NA
table.glm.summary.insect [230, 6] <- NA
rm (glm.du.9.ew.5yo.vs)
gc ()

### Late Winter ###
glm.du.9.lw.1yo.m <- glm (pttype ~ beetle_moderate_1yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [231, 1] <- "9"
table.glm.summary.insect  [231, 2] <- "Late Winter"
table.glm.summary.insect  [231, 3] <- "Moderate"
table.glm.summary.insect  [231, 4] <- 1
table.glm.summary.insect [231, 5] <- glm.du.9.lw.1yo.m$coefficients [[2]]
table.glm.summary.insect [231, 6] <- summary (glm.du.9.lw.1yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.lw.1yo.m)
gc ()

glm.du.9.lw.2yo.m <- glm (pttype ~ beetle_moderate_2yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [232, 1] <- "9"
table.glm.summary.insect  [232, 2] <- "Late Winter"
table.glm.summary.insect  [232, 3] <- "Moderate"
table.glm.summary.insect  [232, 4] <- 2
table.glm.summary.insect [232, 5] <- glm.du.9.lw.2yo.m$coefficients [[2]]
table.glm.summary.insect [232, 6] <- summary (glm.du.9.lw.2yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.lw.2yo.m)
gc ()

glm.du.9.lw.3yo.m <- glm (pttype ~ beetle_moderate_3yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect [233, 1] <- "9"
table.glm.summary.insect [233, 2] <- "Late Winter"
table.glm.summary.insect [233, 3] <- "Moderate"
table.glm.summary.insect [233, 4] <- 3
table.glm.summary.insect [233, 5] <- glm.du.9.lw.3yo.m$coefficients [[2]]
table.glm.summary.insect [233, 6] <- summary (glm.du.9.lw.3yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.lw.3yo.m)
gc ()

glm.du.9.lw.4yo.m <- glm (pttype ~ beetle_moderate_4yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [234, 1] <- "9"
table.glm.summary.insect  [234, 2] <- "Late Winter"
table.glm.summary.insect  [234, 3] <- "Moderate"
table.glm.summary.insect  [234, 4] <- 4
table.glm.summary.insect [234, 5] <- glm.du.9.lw.4yo.m$coefficients [[2]]
table.glm.summary.insect [234, 6] <- summary (glm.du.9.lw.4yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.lw.4yo.m)
gc ()

glm.du.9.lw.5yo.m <- glm (pttype ~ beetle_moderate_5yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [235, 1] <- "9"
table.glm.summary.insect  [235, 2] <- "Late Winter"
table.glm.summary.insect  [235, 3] <- "Moderate"
table.glm.summary.insect  [235, 4] <- 5
table.glm.summary.insect [235, 5] <- glm.du.9.lw.5yo.m$coefficients [[2]]
table.glm.summary.insect [235, 6] <- summary (glm.du.9.lw.5yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.lw.5yo.m)
gc ()

glm.du.9.lw.6yo.m <- glm (pttype ~ beetle_moderate_6yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [236, 1] <- "9"
table.glm.summary.insect  [236, 2] <- "Late Winter"
table.glm.summary.insect  [236, 3] <- "Moderate"
table.glm.summary.insect  [236, 4] <- 6
table.glm.summary.insect [236, 5] <- glm.du.9.lw.6yo.m$coefficients [[2]]
table.glm.summary.insect [236, 6] <- summary (glm.du.9.lw.6yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.lw.6yo.m)
gc ()

glm.du.9.lw.7yo.m <- glm (pttype ~ beetle_moderate_7yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [237, 1] <- "9"
table.glm.summary.insect  [237, 2] <- "Late Winter"
table.glm.summary.insect  [237, 3] <- "Moderate"
table.glm.summary.insect  [237, 4] <- 7
table.glm.summary.insect [237, 5] <- glm.du.9.lw.7yo.m$coefficients [[2]]
table.glm.summary.insect [237, 6] <- summary (glm.du.9.lw.7yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.lw.7yo.m)
gc ()

glm.du.9.lw.8yo.m <- glm (pttype ~ beetle_moderate_8yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [238, 1] <- "9"
table.glm.summary.insect  [238, 2] <- "Late Winter"
table.glm.summary.insect  [238, 3] <- "Moderate"
table.glm.summary.insect  [238, 4] <- 8
table.glm.summary.insect [238, 5] <- glm.du.9.lw.8yo.m$coefficients [[2]]
table.glm.summary.insect [238, 6] <- summary (glm.du.9.lw.8yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.lw.8yo.m)
gc ()

glm.du.9.lw.9yo.m <- glm (pttype ~ beetle_moderate_9yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [239, 1] <- "9"
table.glm.summary.insect  [239, 2] <- "Late Winter"
table.glm.summary.insect  [239, 3] <- "Moderate"
table.glm.summary.insect  [239, 4] <- 9
table.glm.summary.insect [239, 5] <- glm.du.9.lw.9yo.m$coefficients [[2]]
table.glm.summary.insect [239, 6] <- summary (glm.du.9.lw.9yo.m)$coefficients[2, 4]
rm (glm.du.9.lw.9yo.m)
gc ()

glm.du.9.lw.1yo.s <- glm (pttype ~ beetle_severe_1yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [240, 1] <- "9"
table.glm.summary.insect  [240, 2] <- "Late Winter"
table.glm.summary.insect  [240, 3] <- "Severe"
table.glm.summary.insect  [240, 4] <- 1
table.glm.summary.insect [240, 5] <- NA
table.glm.summary.insect [240, 6] <- NA
rm (glm.du.9.lw.1yo.s)
gc ()

glm.du.9.lw.2yo.s <- glm (pttype ~ beetle_severe_2yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [241, 1] <- "9"
table.glm.summary.insect  [241, 2] <- "Late Winter"
table.glm.summary.insect  [241, 3] <- "Severe"
table.glm.summary.insect  [241, 4] <- 2
table.glm.summary.insect [241, 5] <- NA
table.glm.summary.insect [241, 6] <- NA
rm (glm.du.9.lw.2yo.s)
gc ()

glm.du.9.lw.3yo.s <- glm (pttype ~ beetle_severe_3yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [242, 1] <- "9"
table.glm.summary.insect  [242, 2] <- "Late Winter"
table.glm.summary.insect  [242, 3] <- "Severe"
table.glm.summary.insect  [242, 4] <- 3
table.glm.summary.insect [242, 5] <- NA
table.glm.summary.insect [242, 6] <- NA
rm (glm.du.9.lw.3yo.s)
gc ()

glm.du.9.lw.4yo.s <- glm (pttype ~ beetle_severe_4yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [243, 1] <- "9"
table.glm.summary.insect  [243, 2] <- "Late Winter"
table.glm.summary.insect  [243, 3] <- "Severe"
table.glm.summary.insect  [243, 4] <- 4
table.glm.summary.insect [243, 5] <- glm.du.9.lw.4yo.s$coefficients [[2]]
table.glm.summary.insect [243, 6] <- summary (glm.du.9.lw.4yo.s)$coefficients[2, 4] # p-value
rm (glm.du.9.lw.4yo.s)
gc ()

glm.du.9.lw.5yo.s <- glm (pttype ~ beetle_severe_5yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [244, 1] <- "9"
table.glm.summary.insect  [244, 2] <- "Late Winter"
table.glm.summary.insect  [244, 3] <- "Severe"
table.glm.summary.insect  [244, 4] <- 5
table.glm.summary.insect [244, 5] <- NA
table.glm.summary.insect [244, 6] <- NA
rm (glm.du.9.lw.5yo.s)
gc ()

glm.du.9.lw.6yo.s <- glm (pttype ~ beetle_severe_6yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [245, 1] <- "9"
table.glm.summary.insect  [245, 2] <- "Late Winter"
table.glm.summary.insect  [245, 3] <- "Severe"
table.glm.summary.insect  [245, 4] <- 6
table.glm.summary.insect [245, 5] <- NA
table.glm.summary.insect [245, 6] <- NA
rm (glm.du.9.lw.6yo.s)
gc ()

glm.du.9.lw.7yo.s <- glm (pttype ~ beetle_severe_7yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [246, 1] <- "9"
table.glm.summary.insect  [246, 2] <- "Late Winter"
table.glm.summary.insect  [246, 3] <- "Severe"
table.glm.summary.insect  [246, 4] <- 7
table.glm.summary.insect [246, 5] <- glm.du.9.lw.7yo.s$coefficients [[2]]
table.glm.summary.insect [246, 6] <- summary (glm.du.9.lw.7yo.s)$coefficients[2, 4]
rm (glm.du.9.lw.7yo.s)
gc ()

glm.du.9.lw.8yo.s <- glm (pttype ~ beetle_severe_8yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [247, 1] <- "9"
table.glm.summary.insect  [247, 2] <- "Late Winter"
table.glm.summary.insect  [247, 3] <- "Severe"
table.glm.summary.insect  [247, 4] <- 8
table.glm.summary.insect [247, 5] <- glm.du.9.lw.8yo.s$coefficients [[2]]
table.glm.summary.insect [247, 6] <- summary (glm.du.9.lw.8yo.s)$coefficients[2, 4]
rm (glm.du.9.lw.8yo.s)
gc ()

glm.du.9.lw.9yo.s <- glm (pttype ~ beetle_severe_9yo, 
                          data = beetle.data.du.9.lw,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [248, 1] <- "9"
table.glm.summary.insect  [248, 2] <- "Late Winter"
table.glm.summary.insect  [248, 3] <- "Severe"
table.glm.summary.insect  [248, 4] <- 9
table.glm.summary.insect [248, 5] <- NA
table.glm.summary.insect [248, 6] <- NA
rm (glm.du.9.lw.9yo.s)
gc ()

glm.du.9.lw.1yo.vs <- glm (pttype ~ beetle_very_severe_1yo, 
                           data = beetle.data.du.9.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [249, 1] <- "9"
table.glm.summary.insect [249, 2] <- "Late Winter"
table.glm.summary.insect [249, 3] <- "Very Severe"
table.glm.summary.insect [249, 4] <- 1
table.glm.summary.insect [249, 5] <- NA
table.glm.summary.insect [249, 6] <- NA
rm (glm.du.9.lw.1yo.vs)
gc ()

glm.du.9.lw.2yo.vs <- glm (pttype ~ beetle_very_severe_2yo, 
                           data = beetle.data.du.9.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [250, 1] <- "9"
table.glm.summary.insect [250, 2] <- "Late Winter"
table.glm.summary.insect [250, 3] <- "Very Severe"
table.glm.summary.insect [250, 4] <- 2
table.glm.summary.insect [250, 5] <- NA
table.glm.summary.insect [250, 6] <- NA
rm (glm.du.9.lw.2yo.vs)
gc ()

glm.du.9.lw.3yo.vs <- glm (pttype ~ beetle_very_severe_3yo, 
                           data = beetle.data.du.9.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [251, 1] <- "9"
table.glm.summary.insect [251, 2] <- "Late Winter"
table.glm.summary.insect [251, 3] <- "Very Severe"
table.glm.summary.insect [251, 4] <- 3
table.glm.summary.insect [251, 5] <- NA
table.glm.summary.insect [251, 6] <- NA
rm (glm.du.9.lw.3yo.vs)
gc ()

glm.du.9.lw.4yo.vs <- glm (pttype ~ beetle_very_severe_4yo, 
                           data = beetle.data.du.9.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [252, 1] <- "9"
table.glm.summary.insect [252, 2] <- "Late Winter"
table.glm.summary.insect [252, 3] <- "Very Severe"
table.glm.summary.insect [252, 4] <- 4
table.glm.summary.insect [252, 5] <- NA
table.glm.summary.insect [252, 6] <- NA
rm (glm.du.9.lw.4yo.vs)
gc ()

glm.du.9.lw.5yo.vs <- glm (pttype ~ beetle_very_severe_5yo, 
                           data = beetle.data.du.9.lw,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [253, 1] <- "9"
table.glm.summary.insect [253, 2] <- "Late Winter"
table.glm.summary.insect [253, 3] <- "Very Severe"
table.glm.summary.insect [253, 4] <- 5
table.glm.summary.insect [253, 5] <- NA
table.glm.summary.insect [253, 6] <- NA
rm (glm.du.9.lw.5yo.vs)
gc ()

### Summer ###
glm.du.9.s.1yo.m <- glm (pttype ~ beetle_moderate_1yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [254, 1] <- "9"
table.glm.summary.insect  [254, 2] <- "Summer"
table.glm.summary.insect  [254, 3] <- "Moderate"
table.glm.summary.insect  [254, 4] <- 1
table.glm.summary.insect [254, 5] <- glm.du.9.s.1yo.m$coefficients [[2]]
table.glm.summary.insect [254, 6] <- summary (glm.du.9.s.1yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.s.1yo.m)
gc ()

glm.du.9.s.2yo.m <- glm (pttype ~ beetle_moderate_2yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [255, 1] <- "9"
table.glm.summary.insect  [255, 2] <- "Summer"
table.glm.summary.insect  [255, 3] <- "Moderate"
table.glm.summary.insect  [255, 4] <- 2
table.glm.summary.insect [255, 5] <- glm.du.9.s.2yo.m$coefficients [[2]]
table.glm.summary.insect [255, 6] <- summary (glm.du.9.s.2yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.s.2yo.m)
gc ()

glm.du.9.s.3yo.m <- glm (pttype ~ beetle_moderate_3yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect [256, 1] <- "9"
table.glm.summary.insect [256, 2] <- "Summer"
table.glm.summary.insect [256, 3] <- "Moderate"
table.glm.summary.insect [256, 4] <- 3
table.glm.summary.insect [256, 5] <- glm.du.9.s.3yo.m$coefficients [[2]]
table.glm.summary.insect [256, 6] <- summary (glm.du.9.s.3yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.s.3yo.m)
gc ()

glm.du.9.s.4yo.m <- glm (pttype ~ beetle_moderate_4yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [257, 1] <- "9"
table.glm.summary.insect  [257, 2] <- "Summer"
table.glm.summary.insect  [257, 3] <- "Moderate"
table.glm.summary.insect  [257, 4] <- 4
table.glm.summary.insect [257, 5] <- glm.du.9.s.4yo.m$coefficients [[2]]
table.glm.summary.insect [257, 6] <- summary (glm.du.9.s.4yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.s.4yo.m)
gc ()

glm.du.9.s.5yo.m <- glm (pttype ~ beetle_moderate_5yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [258, 1] <- "9"
table.glm.summary.insect  [258, 2] <- "Summer"
table.glm.summary.insect  [258, 3] <- "Moderate"
table.glm.summary.insect  [258, 4] <- 5
table.glm.summary.insect [258, 5] <- glm.du.9.s.5yo.m$coefficients [[2]]
table.glm.summary.insect [258, 6] <- summary (glm.du.9.s.5yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.s.5yo.m)
gc ()

glm.du.9.s.6yo.m <- glm (pttype ~ beetle_moderate_6yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [259, 1] <- "9"
table.glm.summary.insect  [259, 2] <- "Summer"
table.glm.summary.insect  [259, 3] <- "Moderate"
table.glm.summary.insect  [259, 4] <- 6
table.glm.summary.insect [259, 5] <- glm.du.9.s.6yo.m$coefficients [[2]]
table.glm.summary.insect [259, 6] <- summary (glm.du.9.s.6yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.s.6yo.m)
gc ()

glm.du.9.s.7yo.m <- glm (pttype ~ beetle_moderate_7yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [260, 1] <- "9"
table.glm.summary.insect  [260, 2] <- "Summer"
table.glm.summary.insect  [260, 3] <- "Moderate"
table.glm.summary.insect  [260, 4] <- 7
table.glm.summary.insect [260, 5] <- glm.du.9.s.7yo.m$coefficients [[2]]
table.glm.summary.insect [260, 6] <- summary (glm.du.9.s.7yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.s.7yo.m)
gc ()

glm.du.9.s.8yo.m <- glm (pttype ~ beetle_moderate_8yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [261, 1] <- "9"
table.glm.summary.insect  [261, 2] <- "Summer"
table.glm.summary.insect  [261, 3] <- "Moderate"
table.glm.summary.insect  [261, 4] <- 8
table.glm.summary.insect [261, 5] <- glm.du.9.s.8yo.m$coefficients [[2]]
table.glm.summary.insect [261, 6] <- summary (glm.du.9.s.8yo.m)$coefficients[2, 4] # p-value
rm (glm.du.9.s.8yo.m)
gc ()

glm.du.9.s.9yo.m <- glm (pttype ~ beetle_moderate_9yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [262, 1] <- "9"
table.glm.summary.insect  [262, 2] <- "Summer"
table.glm.summary.insect  [262, 3] <- "Moderate"
table.glm.summary.insect  [262, 4] <- 9
table.glm.summary.insect [262, 5] <- glm.du.9.s.9yo.m$coefficients [[2]]
table.glm.summary.insect [262, 6] <- summary (glm.du.9.s.9yo.m)$coefficients[2, 4]
rm (glm.du.9.s.9yo.m)
gc ()

glm.du.9.s.1yo.s <- glm (pttype ~ beetle_severe_1yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [263, 1] <- "9"
table.glm.summary.insect  [263, 2] <- "Summer"
table.glm.summary.insect  [263, 3] <- "Severe"
table.glm.summary.insect  [263, 4] <- 1
table.glm.summary.insect [263, 5] <- glm.du.9.s.1yo.s$coefficients [[2]]
table.glm.summary.insect [263, 6] <- summary (glm.du.9.s.1yo.s)$coefficients[2, 4]
rm (glm.du.9.s.1yo.s)
gc ()

glm.du.9.s.2yo.s <- glm (pttype ~ beetle_severe_2yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [264, 1] <- "9"
table.glm.summary.insect  [264, 2] <- "Summer"
table.glm.summary.insect  [264, 3] <- "Severe"
table.glm.summary.insect  [264, 4] <- 2
table.glm.summary.insect [264, 5] <- NA
table.glm.summary.insect [264, 6] <- NA
rm (glm.du.9.s.2yo.s)
gc ()

glm.du.9.s.3yo.s <- glm (pttype ~ beetle_severe_3yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [265, 1] <- "9"
table.glm.summary.insect  [265, 2] <- "Summer"
table.glm.summary.insect  [265, 3] <- "Severe"
table.glm.summary.insect  [265, 4] <- 3
table.glm.summary.insect [265, 5] <- NA
table.glm.summary.insect [265, 6] <- NA
rm (glm.du.9.s.3yo.s)
gc ()

glm.du.9.s.4yo.s <- glm (pttype ~ beetle_severe_4yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [266, 1] <- "9"
table.glm.summary.insect  [266, 2] <- "Summer"
table.glm.summary.insect  [266, 3] <- "Severe"
table.glm.summary.insect  [266, 4] <- 4
table.glm.summary.insect [266, 5] <- NA
table.glm.summary.insect [266, 6] <- NA
rm (glm.du.9.s.4yo.s)
gc ()

glm.du.9.s.5yo.s <- glm (pttype ~ beetle_severe_5yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [267, 1] <- "9"
table.glm.summary.insect  [267, 2] <- "Summer"
table.glm.summary.insect  [267, 3] <- "Severe"
table.glm.summary.insect  [267, 4] <- 5
table.glm.summary.insect [267, 5] <- NA
table.glm.summary.insect [267, 6] <- NA
rm (glm.du.9.s.5yo.s)
gc ()

glm.du.9.s.6yo.s <- glm (pttype ~ beetle_severe_6yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [268, 1] <- "9"
table.glm.summary.insect  [268, 2] <- "Summer"
table.glm.summary.insect  [268, 3] <- "Severe"
table.glm.summary.insect  [268, 4] <- 6
table.glm.summary.insect [268, 5] <- glm.du.9.s.6yo.s$coefficients [[2]]
table.glm.summary.insect [268, 6] <- summary (glm.du.9.s.6yo.s)$coefficients[2, 4]
rm (glm.du.9.s.6yo.s)
gc ()

glm.du.9.s.7yo.s <- glm (pttype ~ beetle_severe_7yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [269, 1] <- "9"
table.glm.summary.insect  [269, 2] <- "Summer"
table.glm.summary.insect  [269, 3] <- "Severe"
table.glm.summary.insect  [269, 4] <- 7
table.glm.summary.insect [269, 5] <- glm.du.9.s.7yo.s$coefficients [[2]]
table.glm.summary.insect [269, 6] <- summary (glm.du.9.s.7yo.s)$coefficients[2, 4]
rm (glm.du.9.s.7yo.s)
gc ()

glm.du.9.s.8yo.s <- glm (pttype ~ beetle_severe_8yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [270, 1] <- "9"
table.glm.summary.insect  [270, 2] <- "Summer"
table.glm.summary.insect  [270, 3] <- "Severe"
table.glm.summary.insect  [270, 4] <- 8
table.glm.summary.insect [270, 5] <- glm.du.9.s.8yo.s$coefficients [[2]]
table.glm.summary.insect [270, 6] <- summary (glm.du.9.s.8yo.s)$coefficients[2, 4]
rm (glm.du.9.s.8yo.s)
gc ()

glm.du.9.s.9yo.s <- glm (pttype ~ beetle_severe_9yo, 
                          data = beetle.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [271, 1] <- "9"
table.glm.summary.insect  [271, 2] <- "Summer"
table.glm.summary.insect  [271, 3] <- "Severe"
table.glm.summary.insect  [271, 4] <- 9
table.glm.summary.insect [271, 5] <- glm.du.9.s.9yo.s$coefficients [[2]]
table.glm.summary.insect [271, 6] <- summary (glm.du.9.s.9yo.s)$coefficients[2, 4]
rm (glm.du.9.s.9yo.s)
gc ()

glm.du.9.s.1yo.vs <- glm (pttype ~ beetle_very_severe_1yo, 
                           data = beetle.data.du.9.s,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [272, 1] <- "9"
table.glm.summary.insect [272, 2] <- "Summer"
table.glm.summary.insect [272, 3] <- "Very Severe"
table.glm.summary.insect [272, 4] <- 1
table.glm.summary.insect [272, 5] <- NA
table.glm.summary.insect [272, 6] <- NA
rm (glm.du.9.s.1yo.vs)
gc ()

glm.du.9.s.2yo.vs <- glm (pttype ~ beetle_very_severe_2yo, 
                           data = beetle.data.du.9.s,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [273, 1] <- "9"
table.glm.summary.insect [273, 2] <- "Summer"
table.glm.summary.insect [273, 3] <- "Very Severe"
table.glm.summary.insect [273, 4] <- 2
table.glm.summary.insect [273, 5] <- NA
table.glm.summary.insect [273, 6] <- NA
rm (glm.du.9.s.2yo.vs)
gc ()

glm.du.9.s.3yo.vs <- glm (pttype ~ beetle_very_severe_3yo, 
                           data = beetle.data.du.9.s,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [274, 1] <- "9"
table.glm.summary.insect [274, 2] <- "Summer"
table.glm.summary.insect [274, 3] <- "Very Severe"
table.glm.summary.insect [274, 4] <- 3
table.glm.summary.insect [274, 5] <- NA
table.glm.summary.insect [274, 6] <- NA
rm (glm.du.9.s.3yo.vs)
gc ()

glm.du.9.s.4yo.vs <- glm (pttype ~ beetle_very_severe_4yo, 
                           data = beetle.data.du.9.s,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [275, 1] <- "9"
table.glm.summary.insect [275, 2] <- "Summer"
table.glm.summary.insect [275, 3] <- "Very Severe"
table.glm.summary.insect [275, 4] <- 4
table.glm.summary.insect [275, 5] <- NA
table.glm.summary.insect [275, 6] <- NA
rm (glm.du.9.s.4yo.vs)
gc ()

glm.du.9.s.5yo.vs <- glm (pttype ~ beetle_very_severe_5yo, 
                           data = beetle.data.du.9.s,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [276, 1] <- "9"
table.glm.summary.insect [276, 2] <- "Summer"
table.glm.summary.insect [276, 3] <- "Very Severe"
table.glm.summary.insect [276, 4] <- 5
table.glm.summary.insect [276, 5] <- NA
table.glm.summary.insect [276, 6] <- NA
rm (glm.du.9.s.5yo.vs)
gc ()

# save table
table.glm.summary.insect$years <- as.numeric (table.glm.summary.insect [, 4])
write.table (table.glm.summary.insect, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_glm_summary_insect.csv", sep = ",")
table.glm.summary.insect$DU <- as.factor (table.glm.summary.insect$DU )

# plot of coefficents
table.glm.summary.insect.du6 <- table.glm.summary.insect %>%
                                  filter (DU == 6)
ggplot (data = table.glm.summary.insect.du6, 
        aes (years, Coefficient)) +
  geom_line (aes (group = interaction (Severity, Season),
                  colour = Severity,
                  linetype = Season)) +
  ggtitle ("Beta coefficient values of selection of beetle infested forest stands \n by year, severity and season for caribou designatable unit (DU) 6.") +
  xlab ("Years since beetle infestation") + 
  ylab ("Beta coefficient") +
  geom_line (aes (x = years, y = 0), 
             size = 0.5, linetype = "solid", colour = "black") +
  theme (plot.title = element_text (hjust = 0.5),
         axis.text = element_text (size = 10),
         axis.title = element_text (size = 12),
         axis.line.x = element_line (size = 1),
         axis.line.y = element_line (size = 1),
         panel.grid.minor = element_blank (),
         panel.border = element_blank (),
         panel.background = element_blank ()) +
  scale_x_continuous (limits = c (0, 10), breaks = seq (0, 10, by = 1)) +
  scale_y_continuous (limits = c (-10, 10), breaks = seq (-10, 10, by = 2))

table.glm.summary.insect.du7 <- table.glm.summary.insect %>%
                                          filter (DU == 7)
ggplot (data = table.glm.summary.insect.du7, 
        aes (years, Coefficient)) +
  geom_line (aes (group = interaction (Severity, Season),
                  colour = Severity,
                  linetype = Season)) +
  ggtitle ("Beta coefficient values of selection of beetle infested forest stands \n by year, severity and season for caribou designatable unit (DU) 7.") +
  xlab ("Years since beetle infestation") + 
  ylab ("Beta coefficient") +
  geom_line (aes (x = years, y = 0), 
             size = 0.5, linetype = "solid", colour = "black") +
  theme (plot.title = element_text (hjust = 0.5),
         axis.text = element_text (size = 10),
         axis.title = element_text (size = 12),
         axis.line.x = element_line (size = 1),
         axis.line.y = element_line (size = 1),
         panel.grid.minor = element_blank (),
         panel.border = element_blank (),
         panel.background = element_blank ()) +
  scale_x_continuous (limits = c (0, 10), breaks = seq (0, 10, by = 1)) +
  scale_y_continuous (limits = c (-10, 10), breaks = seq (-10, 10, by = 2))


table.glm.summary.insect.du8 <- table.glm.summary.insect %>%
                                      filter (DU == 8)
ggplot (data = table.glm.summary.insect.du8, 
        aes (years, Coefficient)) +
  geom_line (aes (group = interaction (Severity, Season),
                  colour = Severity,
                  linetype = Season)) +
  ggtitle ("Beta coefficient values of selection of beetle infested forest stands \n by year, severity and season for caribou designatable unit (DU) 8.") +
  xlab ("Years since beetle infestation") + 
  ylab ("Beta coefficient") +
  geom_line (aes (x = years, y = 0), 
             size = 0.5, linetype = "solid", colour = "black") +
  theme (plot.title = element_text (hjust = 0.5),
         axis.text = element_text (size = 10),
         axis.title = element_text (size = 12),
         axis.line.x = element_line (size = 1),
         axis.line.y = element_line (size = 1),
         panel.grid.minor = element_blank (),
         panel.border = element_blank (),
         panel.background = element_blank ()) +
  scale_x_continuous (limits = c (0, 10), breaks = seq (0, 10, by = 1)) +
  scale_y_continuous (limits = c (-10, 10), breaks = seq (-10, 10, by = 2))

table.glm.summary.insect.du9 <- table.glm.summary.insect %>%
                                            filter (DU == 9)
ggplot (data = table.glm.summary.insect.du9, 
        aes (years, Coefficient)) +
  geom_line (aes (group = interaction (Severity, Season),
                  colour = Severity,
                  linetype = Season)) +
  ggtitle ("Beta coefficient values of selection of beetle infested forest stands \n by year, severity and season for caribou designatable unit (DU) 9.") +
  xlab ("Years since beetle infestation") + 
  ylab ("Beta coefficient") +
  geom_line (aes (x = years, y = 0), 
             size = 0.5, linetype = "solid", colour = "black") +
  theme (plot.title = element_text (hjust = 0.5),
         axis.text = element_text (size = 10),
         axis.title = element_text (size = 12),
         axis.line.x = element_line (size = 1),
         axis.line.y = element_line (size = 1),
         panel.grid.minor = element_blank (),
         panel.border = element_blank (),
         panel.background = element_blank ()) +
  scale_x_continuous (limits = c (0, 10), breaks = seq (0, 10, by = 1)) +
  scale_y_continuous (limits = c (-14, 14), breaks = seq (-14, 14, by = 2))

#=======================================================================
# re-categorize data and test correlations, beta coeffs again
#=====================================================================
rsf.data.insect <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_beetle_age.csv")

rsf.data.insect <- dplyr::mutate (rsf.data.insect, 
                                  beetle_1to5yo = beetle_moderate_1yo + beetle_moderate_2yo + 
                                                  beetle_moderate_3yo + beetle_moderate_4yo + 
                                                  beetle_moderate_5yo + beetle_severe_1yo +
                                                  beetle_severe_2yo + beetle_severe_3yo +
                                                  beetle_severe_4yo + beetle_severe_5yo +
                                                  beetle_very_severe_1yo + beetle_very_severe_2yo +
                                                  beetle_very_severe_3yo + beetle_very_severe_4yo +
                                                  beetle_very_severe_5yo)
rsf.data.insect$beetle_1to5yo [rsf.data.insect$beetle_1to5yo > 1] <- 1
rsf.data.insect <- dplyr::mutate (rsf.data.insect, 
                                  beetle_6to9yo = beetle_moderate_6yo + beetle_moderate_7yo + 
                                                  beetle_moderate_8yo + beetle_moderate_9yo + 
                                                  beetle_severe_6yo + beetle_severe_7yo + 
                                                  beetle_severe_8yo + beetle_severe_9yo)
rsf.data.insect$beetle_6to9yo [rsf.data.insect$beetle_6to9yo > 1] <- 1








#=================================================
# Model selection Process by DU and Season 
#================================================
# load data
rsf.data.insect <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_beetle_age.csv")
insect.data <- rsf.data.insect [c (1:9, 33:34)] # class data only

# filter by DU, Season 
insect.data.du.6.ew <- insect.data %>%
  dplyr::filter (du == "du6") %>% 
  dplyr::filter (season == "EarlyWinter")
insect.data.du.6.lw <- insect.data %>%
  dplyr::filter (du == "du6") %>% 
  dplyr::filter (season == "LateWinter")
insect.data.du.6.s <- insect.data %>%
  dplyr::filter (du == "du6") %>% 
  dplyr::filter (season == "Summer")

insect.data.du.7.ew <- insect.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "EarlyWinter")
insect.data.du.7.lw <- insect.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "LateWinter")
insect.data.du.7.s <- insect.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "Summer")

insect.data.du.8.ew <- insect.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "EarlyWinter")
insect.data.du.8.lw <- insect.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "LateWinter")
insect.data.du.8.s <- insect.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "Summer")

insect.data.du.9.ew <- insect.data %>%
  dplyr::filter (du == "du9") %>% 
  dplyr::filter (season == "EarlyWinter")
insect.data.du.9.lw <- insect.data %>%
  dplyr::filter (du == "du9") %>% 
  dplyr::filter (season == "LateWinter")
insect.data.du.9.s <- insect.data %>%
  dplyr::filter (du == "du9") %>% 
  dplyr::filter (season == "Summer")

## Build an AIC and AUC Table
table.aic <- data.frame (matrix (ncol = 8, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw", "AUC")

#===============
## DU6 ##
#==============
## Early Winter
### Correlation
corr.insect.du.6.ew <- round (cor (insect.data.du.6.ew [10:11], method = "spearman"), 3)
ggcorrplot (corr.insect.du.6.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Beetle Infested Forest Stand Age Correlation DU6 Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_insect_corr_du_6_ew.png")

### CART
cart.du.6.ew <- rpart (pttype ~ beetle_1to5yo + beetle_6to9yo,
                       data = insect.data.du.6.ew, 
                       method = "class")
summary (cart.du.6.ew)
print (cart.du.6.ew)
plot (cart.du.6.ew, uniform = T)
text (cart.du.6.ew, use.n = T, splits = T, fancy = F)
post (cart.du.6.ew, file = "", uniform = T)

### VIF
model.glm.du6.ew <- glm (pttype ~ beetle_1to5yo + beetle_6to9yo, 
                         data = insect.data.du.6.ew,
                         family = binomial (link = 'logit'))
vif (model.glm.du6.ew) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du6.ew <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                                     (beetle_1to5yo | uniqueID) + 
                                     (beetle_6to9yo | uniqueID), 
                           data = insect.data.du.6.ew, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                   optimizer = "nloptwrap", # these settings should provide results quicker
                                                   optCtrl = list (maxfun = 2e5))) # 20,000 iterations)
summary (model.lme.du6.ew)
plot (model.lme.du6.ew) # should be mostly a straight line

# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Early Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "Beetle1to5, Beetle6to9"
table.aic [1, 5] <- "(Beetle1to5 | UniqueID), (Beetle6to9 | UniqueID)"
table.aic [1, 6] <- AIC (model.lme.du6.ew)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew, type = 'response'), insect.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [1, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du6.ew.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                        (beetle_1to5yo | uniqueID), 
                           data = insect.data.du.6.ew, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5))) 

# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Early Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "Beetle1to5"
table.aic [2, 5] <- "(Beetle1to5 | UniqueID)"
table.aic [2, 6] <- AIC (model.lme.du6.ew.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew.1to5, type = 'response'), insect.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [2, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.du6.ew.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                          (beetle_6to9yo | uniqueID), 
                                data = insect.data.du.6.ew, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Early Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "Beetle6to9"
table.aic [3, 5] <- "(Beetle6to9 | UniqueID)"
table.aic [3, 6] <- AIC (model.lme.du6.ew.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew.6to9, type = 'response'), insect.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [3, 8] <- auc.temp@y.values[[1]]

# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (insect.data.du.6.ew, pttype == 0)
beetle_1to5yo_E <- tapply (sub$beetle_1to5yo, sub$uniqueID, sum)
beetle_6to9yo_E <- tapply (sub$beetle_6to9yo, sub$uniqueID, sum)

inds <- as.character (insect.data.du.6.ew$uniqueID)
insect.data.du.6.ew <- cbind (insect.data.du.6.ew, 
                               "beetle_1to5yo_E" = beetle_1to5yo_E [inds],
                               "beetle_6to9yo_E" = beetle_6to9yo_E [inds])
# Functional Responses
# All COVARS
model.lme.fxn.du6.ew.all <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo +
                                             beetle_1to5yo_E + beetle_6to9yo_E + 
                                             beetle_1to5yo:beetle_1to5yo_E +
                                             beetle_6to9yo:beetle_6to9yo_E +
                                             (1 | uniqueID), 
                                  data = insect.data.du.6.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [4, 1] <- "DU6"
table.aic [4, 2] <- "Early Winter"
table.aic [4, 3] <- "GLMM with Functional Response"
table.aic [4, 4] <- "Beetle1to5, Beetle6to9, A_Beetle1to5, A_Beetle6to9, Beetle1to5*A_Beetle1to5, Beetle6to9*A_Beetle6to9"
table.aic [4, 5] <- "(1 | UniqueID)"
table.aic [4, 6] <- AIC (model.lme.fxn.du6.ew.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.all, type = 'response'), insect.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [4, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du6.ew.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                              beetle_1to5yo_E + 
                                              beetle_1to5yo:beetle_1to5yo_E +
                                              (1 | uniqueID), 
                                   data = insect.data.du.6.ew, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [5, 1] <- "DU6"
table.aic [5, 2] <- "Early Winter"
table.aic [5, 3] <- "GLMM with Functional Response"
table.aic [5, 4] <- "Beetle1to5, A_Beetle1to5, Beetle1to5*A_Beetle1to5"
table.aic [5, 5] <- "(1 | UniqueID)"
table.aic [5, 6] <- AIC (model.lme.fxn.du6.ew.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.1to5, type = 'response'), insect.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [5, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.fxn.du6.ew.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                              beetle_6to9yo_E + 
                                              beetle_6to9yo:beetle_6to9yo_E +
                                              (1 | uniqueID), 
                                    data = insect.data.du.6.ew, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [6, 1] <- "DU6"
table.aic [6, 2] <- "Early Winter"
table.aic [6, 3] <- "GLMM with Functional Response"
table.aic [6, 4] <- "Beetle6to9, A_Beetle6to9, Beetle6to9*A_Beetle6to9"
table.aic [6, 5] <- "(1 | UniqueID)"
table.aic [6, 6] <- AIC (model.lme.fxn.du6.ew.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.6to9, type = 'response'), insect.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [6, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:6, 6])))),
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:6, 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:6, 6])))),
                    (exp (-0.5 * (table.aic [4, 6] - min (table.aic [1:6, 6])))),
                    (exp (-0.5 * (table.aic [5, 6] - min (table.aic [1:6, 6])))),
                    (exp (-0.5 * (table.aic [6, 6] - min (table.aic [1:6, 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:6, 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:6, 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:6, 6])))) / sum (list.aic.like), 3)
table.aic [4, 7] <- round ((exp (-0.5 * (table.aic [4, 6] - min (table.aic [1:6, 6])))) / sum (list.aic.like), 3)
table.aic [5, 7] <- round ((exp (-0.5 * (table.aic [5, 6] - min (table.aic [1:6, 6])))) / sum (list.aic.like), 3)
table.aic [6, 7] <- round ((exp (-0.5 * (table.aic [6, 6] - min (table.aic [1:6, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_insect.csv", sep = ",")

# save the top model
save (model.lme.du6.ew, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\fire\\model_lme_fxn_du6_ew_top.rda")





### Late Winter
### Correlation
corr.insect.du.6.lw <- round (cor (insect.data.du.6.lw [10:11], method = "spearman"), 3)
ggcorrplot (corr.insect.du.6.lw, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Beetle Infested Forest Stand Age Correlation DU6 Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_insect_corr_du_6_lw.png")

### VIF
model.glm.du6.lw <- glm (pttype ~ beetle_1to5yo + beetle_6to9yo, 
                         data = insect.data.du.6.lw,
                         family = binomial (link = 'logit'))
vif (model.glm.du6.lw) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du6.lw <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                             (beetle_1to5yo | uniqueID) + 
                             (beetle_6to9yo | uniqueID), 
                           data = insect.data.du.6.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [7, 1] <- "DU6"
table.aic [7, 2] <- "Late Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "Beetle1to5, Beetle6to9"
table.aic [7, 5] <- "(Beetle1to5 | UniqueID), (Beetle6to9 | UniqueID)"
table.aic [7, 6] <- AIC (model.lme.du6.lw)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw, type = 'response'), insect.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [7, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du6.lw.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                    (beetle_1to5yo | uniqueID), 
                           data = insect.data.du.6.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [8, 1] <- "DU6"
table.aic [8, 2] <- "Late Winter"
table.aic [8, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [8, 4] <- "Beetle1to5"
table.aic [8, 5] <- "(Beetle1to5 | UniqueID)"
table.aic [8, 6] <- AIC (model.lme.du6.lw.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.1to5, type = 'response'), insect.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [8, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.du6.lw.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                        (beetle_6to9yo | uniqueID), 
                                data = insect.data.du.6.lw, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [9, 1] <- "DU6"
table.aic [9, 2] <- "Late Winter"
table.aic [9, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [9, 4] <- "Beetle6to9"
table.aic [9, 5] <- "(Beetle6to9 | UniqueID)"
table.aic [9, 6] <- AIC (model.lme.du6.lw.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.6to9, type = 'response'), insect.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [9, 8] <- auc.temp@y.values[[1]]

# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (insect.data.du.6.lw, pttype == 0)
beetle_1to5yo_E <- tapply (sub$beetle_1to5yo, sub$uniqueID, sum)
beetle_6to9yo_E <- tapply (sub$beetle_6to9yo, sub$uniqueID, sum)

inds <- as.character (insect.data.du.6.lw$uniqueID)
insect.data.du.6.lw <- cbind (insect.data.du.6.lw, 
                              "beetle_1to5yo_E" = beetle_1to5yo_E [inds],
                              "beetle_6to9yo_E" = beetle_6to9yo_E [inds])
# Functional Responses
# All COVARS
model.lme.fxn.du6.lw.all <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo +
                                     beetle_1to5yo_E + beetle_6to9yo_E + 
                                     beetle_1to5yo:beetle_1to5yo_E +
                                     beetle_6to9yo:beetle_6to9yo_E +
                                     (1 | uniqueID), 
                                   data = insect.data.du.6.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [10, 1] <- "DU6"
table.aic [10, 2] <- "Late Winter"
table.aic [10, 3] <- "GLMM with Functional Response"
table.aic [10, 4] <- "Beetle1to5, Beetle6to9, A_Beetle1to5, A_Beetle6to9, Beetle1to5*A_Beetle1to5, Beetle6to9*A_Beetle6to9"
table.aic [10, 5] <- "(1 | UniqueID)"
table.aic [10, 6] <- AIC (model.lme.fxn.du6.lw.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.all, type = 'response'), insect.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [10, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du6.lw.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                              beetle_1to5yo_E + 
                                              beetle_1to5yo:beetle_1to5yo_E +
                                              (1 | uniqueID), 
                                   data = insect.data.du.6.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [11, 1] <- "DU6"
table.aic [11, 2] <- "Late Winter"
table.aic [11, 3] <- "GLMM with Functional Response"
table.aic [11, 4] <- "Beetle1to5, A_Beetle1to5, Beetle1to5*A_Beetle1to5"
table.aic [11, 5] <- "(1 | UniqueID)"
table.aic [11, 6] <- AIC (model.lme.fxn.du6.lw.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.1to5, type = 'response'), insect.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [11, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.fxn.du6.lw.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                      beetle_6to9yo_E + 
                                      beetle_6to9yo:beetle_6to9yo_E +
                                      (1 | uniqueID), 
                                    data = insect.data.du.6.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [12, 1] <- "DU6"
table.aic [12, 2] <- "Late Winter"
table.aic [12, 3] <- "GLMM with Functional Response"
table.aic [12, 4] <- "Beetle6to9, A_Beetle6to9, Beetle6to9*A_Beetle6to9"
table.aic [12, 5] <- "(1 | UniqueID)"
table.aic [12, 6] <- AIC (model.lme.fxn.du6.lw.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.6to9, type = 'response'), insect.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [12, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [7, 6] - min (table.aic [7:12, 6])))),
                    (exp (-0.5 * (table.aic [8, 6] - min (table.aic [7:12, 6])))),
                    (exp (-0.5 * (table.aic [9, 6] - min (table.aic [7:12, 6])))),
                    (exp (-0.5 * (table.aic [10, 6] - min (table.aic [7:12, 6])))),
                    (exp (-0.5 * (table.aic [11, 6] - min (table.aic [7:12, 6])))),
                    (exp (-0.5 * (table.aic [12, 6] - min (table.aic [7:12, 6])))))
table.aic [7, 7] <- round ((exp (-0.5 * (table.aic [7, 6] - min (table.aic [7:12, 6])))) / sum (list.aic.like), 3)
table.aic [8, 7] <- round ((exp (-0.5 * (table.aic [8, 6] - min (table.aic [7:12, 6])))) / sum (list.aic.like), 3)
table.aic [9, 7] <- round ((exp (-0.5 * (table.aic [9, 6] - min (table.aic [7:12, 6])))) / sum (list.aic.like), 3)
table.aic [10, 7] <- round ((exp (-0.5 * (table.aic [10, 6] - min (table.aic [7:12, 6])))) / sum (list.aic.like), 3)
table.aic [11, 7] <- round ((exp (-0.5 * (table.aic [11, 6] - min (table.aic [7:12, 6])))) / sum (list.aic.like), 3)
table.aic [12, 7] <- round ((exp (-0.5 * (table.aic [12, 6] - min (table.aic [7:12, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_insect.csv", sep = ",")



### Summer
### Correlation
corr.insect.du.6.s <- round (cor (insect.data.du.6.s [10:11], method = "spearman"), 3)
ggcorrplot (corr.insect.du.6.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Beetle Infested Forest Stand Age Correlation DU6 Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_insect_corr_du_6_s.png")

### VIF
model.glm.du6.s <- glm (pttype ~ beetle_1to5yo + beetle_6to9yo, 
                         data = insect.data.du.6.s,
                         family = binomial (link = 'logit'))
vif (model.glm.du6.s) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du6.s <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                             (beetle_1to5yo | uniqueID) + 
                             (beetle_6to9yo | uniqueID), 
                           data = insect.data.du.6.s, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [13, 1] <- "DU6"
table.aic [13, 2] <- "Summer"
table.aic [13, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [13, 4] <- "Beetle1to5, Beetle6to9"
table.aic [13, 5] <- "(Beetle1to5 | UniqueID), (Beetle6to9 | UniqueID)"
table.aic [13, 6] <- AIC (model.lme.du6.s)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.s, type = 'response'), insect.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [13, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du6.s.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                        (beetle_1to5yo | uniqueID), 
                          data = insect.data.du.6.s, 
                          family = binomial (link = "logit"),
                          verbose = T,
                          control = glmerControl (calc.derivs = FALSE, 
                                                  optimizer = "nloptwrap", 
                                                  optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [14, 1] <- "DU6"
table.aic [14, 2] <- "Summer"
table.aic [14, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [14, 4] <- "Beetle1to5"
table.aic [14, 5] <- "(Beetle1to5 | UniqueID)"
table.aic [14, 6] <- AIC (model.lme.du6.s.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.s.1to5, type = 'response'), insect.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [14, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.du6.s.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                        (beetle_6to9yo | uniqueID), 
                               data = insect.data.du.6.s, 
                               family = binomial (link = "logit"),
                               verbose = T,
                               control = glmerControl (calc.derivs = FALSE, 
                                                       optimizer = "nloptwrap", 
                                                       optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [15, 1] <- "DU6"
table.aic [15, 2] <- "Summer"
table.aic [15, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [15, 4] <- "Beetle6to9"
table.aic [15, 5] <- "(Beetle6to9 | UniqueID)"
table.aic [15, 6] <- AIC (model.lme.du6.s.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.s.6to9, type = 'response'), insect.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [15, 8] <- auc.temp@y.values[[1]]


# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (insect.data.du.6.s, pttype == 0)
beetle_1to5yo_E <- tapply (sub$beetle_1to5yo, sub$uniqueID, sum)
beetle_6to9yo_E <- tapply (sub$beetle_6to9yo, sub$uniqueID, sum)
inds <- as.character (insect.data.du.6.s$uniqueID)
insect.data.du.6.s <- cbind (insect.data.du.6.s, 
                              "beetle_1to5yo_E" = beetle_1to5yo_E [inds],
                              "beetle_6to9yo_E" = beetle_6to9yo_E [inds])
# Functional Responses
# All COVARS
model.lme.fxn.du6.s.all <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo +
                                     beetle_1to5yo_E + beetle_6to9yo_E + 
                                     beetle_1to5yo:beetle_1to5yo_E +
                                     beetle_6to9yo:beetle_6to9yo_E +
                                     (1 | uniqueID), 
                                   data = insect.data.du.6.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [16, 1] <- "DU6"
table.aic [16, 2] <- "Summer"
table.aic [16, 3] <- "GLMM with Functional Response"
table.aic [16, 4] <- "Beetle1to5, Beetle6to9, A_Beetle1to5, A_Beetle6to9, Beetle1to5*A_Beetle1to5, Beetle6to9*A_Beetle6to9"
table.aic [16, 5] <- "(1 | UniqueID)"
table.aic [16, 6] <- AIC (model.lme.fxn.du6.s.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.s.all, type = 'response'), insect.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [16, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du6.s.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                            beetle_1to5yo_E + 
                                            beetle_1to5yo:beetle_1to5yo_E +
                                            (1 | uniqueID), 
                                  data = insect.data.du.6.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [17, 1] <- "DU6"
table.aic [17, 2] <- "Summer"
table.aic [17, 3] <- "GLMM with Functional Response"
table.aic [17, 4] <- "Beetle1to5, A_Beetle1to5, Beetle1to5*A_Beetle1to5"
table.aic [17, 5] <- "(1 | UniqueID)"
table.aic [17, 6] <- AIC (model.lme.fxn.du6.s.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.s.1to5, type = 'response'), insect.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [17, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.fxn.du6.s.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                             beetle_6to9yo_E + 
                                             beetle_6to9yo:beetle_6to9yo_E +
                                             (1 | uniqueID), 
                                   data = insect.data.du.6.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [18, 1] <- "DU6"
table.aic [18, 2] <- "Summer"
table.aic [18, 3] <- "GLMM with Functional Response"
table.aic [18, 4] <- "Beetle6to9, A_Beetle6to9, Beetle6to9*A_Beetle6to9"
table.aic [18, 5] <- "(1 | UniqueID)"
table.aic [18, 6] <- AIC (model.lme.fxn.du6.s.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.s.6to9, type = 'response'), insect.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [18, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [13, 6] - min (table.aic [13:18, 6])))),
                    (exp (-0.5 * (table.aic [14, 6] - min (table.aic [13:18, 6])))),
                    (exp (-0.5 * (table.aic [15, 6] - min (table.aic [13:18, 6])))),
                    (exp (-0.5 * (table.aic [16, 6] - min (table.aic [13:18, 6])))),
                    (exp (-0.5 * (table.aic [17, 6] - min (table.aic [13:18, 6])))),
                    (exp (-0.5 * (table.aic [18, 6] - min (table.aic [13:18, 6])))))
table.aic [13, 7] <- round ((exp (-0.5 * (table.aic [13, 6] - min (table.aic [13:18, 6])))) / sum (list.aic.like), 3)
table.aic [14, 7] <- round ((exp (-0.5 * (table.aic [14, 6] - min (table.aic [13:18, 6])))) / sum (list.aic.like), 3)
table.aic [15, 7] <- round ((exp (-0.5 * (table.aic [15, 6] - min (table.aic [13:18, 6])))) / sum (list.aic.like), 3)
table.aic [16, 7] <- round ((exp (-0.5 * (table.aic [16, 6] - min (table.aic [13:18, 6])))) / sum (list.aic.like), 3)
table.aic [17, 7] <- round ((exp (-0.5 * (table.aic [17, 6] - min (table.aic [13:18, 6])))) / sum (list.aic.like), 3)
table.aic [18, 7] <- round ((exp (-0.5 * (table.aic [18, 6] - min (table.aic [13:18, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_insect.csv", sep = ",")

#===============
## DU7 ##
#==============
## Early Winter
### Correlation
corr.insect.du.7.ew <- round (cor (insect.data.du.7.ew [10:11], method = "spearman"), 3)
ggcorrplot (corr.insect.du.7.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Beetle Infested Forest Stand Age Correlation DU7 Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_insect_corr_du_7_ew.png")

### VIF
model.glm.du7.ew <- glm (pttype ~ beetle_1to5yo + beetle_6to9yo, 
                         data = insect.data.du.7.ew,
                         family = binomial (link = 'logit'))
vif (model.glm.du7.ew) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du7.ew <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                             (beetle_1to5yo | uniqueID) + 
                             (beetle_6to9yo | uniqueID), 
                           data = insect.data.du.7.ew, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [19, 1] <- "DU7"
table.aic [19, 2] <- "Early Winter"
table.aic [19, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [19, 4] <- "Beetle1to5, Beetle6to9"
table.aic [19, 5] <- "(Beetle1to5 | UniqueID), (Beetle6to9 | UniqueID)"
table.aic [19, 6] <- AIC (model.lme.du7.ew)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.ew, type = 'response'), insect.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [19, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du7.ew.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                        (beetle_1to5yo | uniqueID), 
                           data = insect.data.du.7.ew, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [20, 1] <- "DU7"
table.aic [20, 2] <- "Early Winter"
table.aic [20, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [20, 4] <- "Beetle1to5"
table.aic [20, 5] <- "(Beetle1to5 | UniqueID)"
table.aic [20, 6] <- AIC (model.lme.du7.ew.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.ew.1to5, type = 'response'), insect.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [20, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.du7.ew.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                  (beetle_6to9yo | uniqueID), 
                                data = insect.data.du.7.ew, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [21, 1] <- "DU7"
table.aic [21, 2] <- "Early Winter"
table.aic [21, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [21, 4] <- "Beetle6to9"
table.aic [21, 5] <- "(Beetle6to9 | UniqueID)"
table.aic [21, 6] <- AIC (model.lme.du7.ew.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.ew.6to9, type = 'response'), insect.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [21, 8] <- auc.temp@y.values[[1]]


# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (insect.data.du.7.ew, pttype == 0)
beetle_1to5yo_E <- tapply (sub$beetle_1to5yo, sub$uniqueID, sum)
beetle_6to9yo_E <- tapply (sub$beetle_6to9yo, sub$uniqueID, sum)
inds <- as.character (insect.data.du.7.ew$uniqueID)
insect.data.du.7.ew <- cbind (insect.data.du.7.ew, 
                             "beetle_1to5yo_E" = beetle_1to5yo_E [inds],
                             "beetle_6to9yo_E" = beetle_6to9yo_E [inds])
# Functional Responses
# All COVARS
model.lme.fxn.du7.ew.all <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo +
                                    beetle_1to5yo_E + beetle_6to9yo_E + 
                                    beetle_1to5yo:beetle_1to5yo_E +
                                    beetle_6to9yo:beetle_6to9yo_E +
                                    (1 | uniqueID), 
                                  data = insect.data.du.7.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [22, 1] <- "DU7"
table.aic [22, 2] <- "Early Winter"
table.aic [22, 3] <- "GLMM with Functional Response"
table.aic [22, 4] <- "Beetle1to5, Beetle6to9, A_Beetle1to5, A_Beetle6to9, Beetle1to5*A_Beetle1to5, Beetle6to9*A_Beetle6to9"
table.aic [22, 5] <- "(1 | UniqueID)"
table.aic [22, 6] <- AIC (model.lme.fxn.du7.ew.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.ew.all, type = 'response'), insect.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [22, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du7.ew.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                             beetle_1to5yo_E + 
                                             beetle_1to5yo:beetle_1to5yo_E +
                                              (1 | uniqueID), 
                                   data = insect.data.du.7.ew, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [23, 1] <- "DU7"
table.aic [23, 2] <- "Early Winter"
table.aic [23, 3] <- "GLMM with Functional Response"
table.aic [23, 4] <- "Beetle1to5, A_Beetle1to5, Beetle1to5*A_Beetle1to5"
table.aic [23, 5] <- "(1 | UniqueID)"
table.aic [23, 6] <- AIC (model.lme.fxn.du7.ew.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.ew.1to5, type = 'response'), insect.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [23, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.fxn.du7.ew.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                              beetle_6to9yo_E + 
                                              beetle_6to9yo:beetle_6to9yo_E +
                                              (1 | uniqueID), 
                                    data = insect.data.du.7.ew, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [24, 1] <- "DU7"
table.aic [24, 2] <- "Early Winter"
table.aic [24, 3] <- "GLMM with Functional Response"
table.aic [24, 4] <- "Beetle6to9, A_Beetle6to9, Beetle6to9*A_Beetle6to9"
table.aic [24, 5] <- "(1 | UniqueID)"
table.aic [24, 6] <- AIC (model.lme.fxn.du7.ew.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.ew.6to9, type = 'response'), insect.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [24, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [19, 6] - min (table.aic [19:24, 6])))),
                    (exp (-0.5 * (table.aic [20, 6] - min (table.aic [19:24, 6])))),
                    (exp (-0.5 * (table.aic [21, 6] - min (table.aic [19:24, 6])))),
                    (exp (-0.5 * (table.aic [22, 6] - min (table.aic [19:24, 6])))),
                    (exp (-0.5 * (table.aic [23, 6] - min (table.aic [19:24, 6])))),
                    (exp (-0.5 * (table.aic [24, 6] - min (table.aic [19:24, 6])))))
table.aic [19, 7] <- round ((exp (-0.5 * (table.aic [19, 6] - min (table.aic [19:24, 6])))) / sum (list.aic.like), 3)
table.aic [20, 7] <- round ((exp (-0.5 * (table.aic [20, 6] - min (table.aic [19:24, 6])))) / sum (list.aic.like), 3)
table.aic [21, 7] <- round ((exp (-0.5 * (table.aic [21, 6] - min (table.aic [19:24, 6])))) / sum (list.aic.like), 3)
table.aic [22, 7] <- round ((exp (-0.5 * (table.aic [22, 6] - min (table.aic [19:24, 6])))) / sum (list.aic.like), 3)
table.aic [23, 7] <- round ((exp (-0.5 * (table.aic [23, 6] - min (table.aic [19:24, 6])))) / sum (list.aic.like), 3)
table.aic [24, 7] <- round ((exp (-0.5 * (table.aic [24, 6] - min (table.aic [19:24, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_insect.csv", sep = ",")

## Late Winter
### Correlation
corr.insect.du.7.lw <- round (cor (insect.data.du.7.lw [10:11], method = "spearman"), 3)
ggcorrplot (corr.insect.du.7.lw, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Beetle Infested Forest Stand Age Correlation DU7 Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_insect_corr_du_7_lw.png")

### VIF
model.glm.du7.lw <- glm (pttype ~ beetle_1to5yo + beetle_6to9yo, 
                         data = insect.data.du.7.lw,
                         family = binomial (link = 'logit'))
vif (model.glm.du7.lw) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du7.lw <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                                     (beetle_1to5yo | uniqueID) + 
                                     (beetle_6to9yo | uniqueID), 
                           data = insect.data.du.7.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [25, 1] <- "DU7"
table.aic [25, 2] <- "Late Winter"
table.aic [25, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [25, 4] <- "Beetle1to5, Beetle6to9"
table.aic [25, 5] <- "(Beetle1to5 | UniqueID), (Beetle6to9 | UniqueID)"
table.aic [25, 6] <- AIC (model.lme.du7.lw)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.lw, type = 'response'), insect.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [25, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du7.lw.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                        (beetle_1to5yo | uniqueID), 
                           data = insect.data.du.7.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [26, 1] <- "DU7"
table.aic [26, 2] <- "Late Winter"
table.aic [26, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [26, 4] <- "Beetle1to5"
table.aic [26, 5] <- "(Beetle1to5 | UniqueID)"
table.aic [26, 6] <- AIC (model.lme.du7.lw.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.lw.1to5, type = 'response'), insect.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [26, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.du7.lw.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                         (beetle_6to9yo | uniqueID), 
                                data = insect.data.du.7.lw, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [27, 1] <- "DU7"
table.aic [27, 2] <- "Late Winter"
table.aic [27, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [27, 4] <- "Beetle6to9"
table.aic [27, 5] <- "(Beetle6to9 | UniqueID)"
table.aic [27, 6] <- AIC (model.lme.du7.lw.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.lw.6to9, type = 'response'), insect.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [27, 8] <- auc.temp@y.values[[1]]

# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (insect.data.du.7.lw, pttype == 0)
beetle_1to5yo_E <- tapply (sub$beetle_1to5yo, sub$uniqueID, sum)
beetle_6to9yo_E <- tapply (sub$beetle_6to9yo, sub$uniqueID, sum)
inds <- as.character (insect.data.du.7.lw$uniqueID)
insect.data.du.7.lw <- cbind (insect.data.du.7.lw, 
                              "beetle_1to5yo_E" = beetle_1to5yo_E [inds],
                              "beetle_6to9yo_E" = beetle_6to9yo_E [inds])
# Functional Responses
# All COVARS
model.lme.fxn.du7.lw.all <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo +
                                             beetle_1to5yo_E + beetle_6to9yo_E + 
                                             beetle_1to5yo:beetle_1to5yo_E +
                                             beetle_6to9yo:beetle_6to9yo_E +
                                             (1 | uniqueID), 
                                   data = insect.data.du.7.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [28, 1] <- "DU7"
table.aic [28, 2] <- "Late Winter"
table.aic [28, 3] <- "GLMM with Functional Response"
table.aic [28, 4] <- "Beetle1to5, Beetle6to9, A_Beetle1to5, A_Beetle6to9, Beetle1to5*A_Beetle1to5, Beetle6to9*A_Beetle6to9"
table.aic [28, 5] <- "(1 | UniqueID)"
table.aic [28, 6] <- AIC (model.lme.fxn.du7.lw.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.lw.all, type = 'response'), insect.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [28, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du7.lw.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                              beetle_1to5yo_E + 
                                              beetle_1to5yo:beetle_1to5yo_E +
                                              (1 | uniqueID), 
                                   data = insect.data.du.7.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [29, 1] <- "DU7"
table.aic [29, 2] <- "Late Winter"
table.aic [29, 3] <- "GLMM with Functional Response"
table.aic [29, 4] <- "Beetle1to5, A_Beetle1to5, Beetle1to5*A_Beetle1to5"
table.aic [29, 5] <- "(1 | UniqueID)"
table.aic [29, 6] <- AIC (model.lme.fxn.du7.lw.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.lw.1to5, type = 'response'), insect.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [29, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.fxn.du7.lw.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                              beetle_6to9yo_E + 
                                              beetle_6to9yo:beetle_6to9yo_E +
                                              (1 | uniqueID), 
                                    data = insect.data.du.7.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [30, 1] <- "DU7"
table.aic [30, 2] <- "Late Winter"
table.aic [30, 3] <- "GLMM with Functional Response"
table.aic [30, 4] <- "Beetle6to9, A_Beetle6to9, Beetle6to9*A_Beetle6to9"
table.aic [30, 5] <- "(1 | UniqueID)"
table.aic [30, 6] <- AIC (model.lme.fxn.du7.lw.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.lw.6to9, type = 'response'), insect.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [30, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [25, 6] - min (table.aic [25:30, 6])))),
                    (exp (-0.5 * (table.aic [26, 6] - min (table.aic [25:30, 6])))),
                    (exp (-0.5 * (table.aic [27, 6] - min (table.aic [25:30, 6])))),
                    (exp (-0.5 * (table.aic [28, 6] - min (table.aic [25:30, 6])))),
                    (exp (-0.5 * (table.aic [29, 6] - min (table.aic [25:30, 6])))),
                    (exp (-0.5 * (table.aic [30, 6] - min (table.aic [25:30, 6])))))
table.aic [25, 7] <- round ((exp (-0.5 * (table.aic [25, 6] - min (table.aic [25:30, 6])))) / sum (list.aic.like), 3)
table.aic [26, 7] <- round ((exp (-0.5 * (table.aic [26, 6] - min (table.aic [25:30, 6])))) / sum (list.aic.like), 3)
table.aic [27, 7] <- round ((exp (-0.5 * (table.aic [27, 6] - min (table.aic [25:30, 6])))) / sum (list.aic.like), 3)
table.aic [28, 7] <- round ((exp (-0.5 * (table.aic [28, 6] - min (table.aic [25:30, 6])))) / sum (list.aic.like), 3)
table.aic [29, 7] <- round ((exp (-0.5 * (table.aic [29, 6] - min (table.aic [25:30, 6])))) / sum (list.aic.like), 3)
table.aic [30, 7] <- round ((exp (-0.5 * (table.aic [30, 6] - min (table.aic [25:30, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_insect.csv", sep = ",")

## Summer
### Correlation
corr.insect.du.7.s <- round (cor (insect.data.du.7.s [10:11], method = "spearman"), 3)
ggcorrplot (corr.insect.du.7.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Beetle Infested Forest Stand Age Correlation DU7 Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_insect_corr_du_7_s.png")

### VIF
model.glm.du7.s <- glm (pttype ~ beetle_1to5yo + beetle_6to9yo, 
                         data = insect.data.du.7.s,
                         family = binomial (link = 'logit'))
vif (model.glm.du7.s) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du7.s <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                                   (beetle_1to5yo | uniqueID) + 
                                   (beetle_6to9yo | uniqueID), 
                           data = insect.data.du.7.s, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [31, 1] <- "DU7"
table.aic [31, 2] <- "Summer"
table.aic [31, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [31, 4] <- "Beetle1to5, Beetle6to9"
table.aic [31, 5] <- "(Beetle1to5 | UniqueID), (Beetle6to9 | UniqueID)"
table.aic [31, 6] <- AIC (model.lme.du7.s)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.s, type = 'response'), insect.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [31, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du7.s.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                        (beetle_1to5yo | uniqueID), 
                          data = insect.data.du.7.s, 
                          family = binomial (link = "logit"),
                          verbose = T,
                          control = glmerControl (calc.derivs = FALSE, 
                                                  optimizer = "nloptwrap", 
                                                  optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [32, 1] <- "DU7"
table.aic [32, 2] <- "Summer"
table.aic [32, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [32, 4] <- "Beetle1to5"
table.aic [32, 5] <- "(Beetle1to5 | UniqueID)"
table.aic [32, 6] <- AIC (model.lme.du7.s.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.s.1to5, type = 'response'), insect.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [32, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.du7.s.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                        (beetle_6to9yo | uniqueID), 
                               data = insect.data.du.7.s, 
                               family = binomial (link = "logit"),
                               verbose = T,
                               control = glmerControl (calc.derivs = FALSE, 
                                                       optimizer = "nloptwrap", 
                                                       optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [33, 1] <- "DU7"
table.aic [33, 2] <- "Summer"
table.aic [33, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [33, 4] <- "Beetle6to9"
table.aic [33, 5] <- "(Beetle6to9 | UniqueID)"
table.aic [33, 6] <- AIC (model.lme.du7.s.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.s.6to9, type = 'response'), insect.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [33, 8] <- auc.temp@y.values[[1]]

# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (insect.data.du.7.s, pttype == 0)
beetle_1to5yo_E <- tapply (sub$beetle_1to5yo, sub$uniqueID, sum)
beetle_6to9yo_E <- tapply (sub$beetle_6to9yo, sub$uniqueID, sum)
inds <- as.character (insect.data.du.7.s$uniqueID)
insect.data.du.7.s <- cbind (insect.data.du.7.s, 
                              "beetle_1to5yo_E" = beetle_1to5yo_E [inds],
                              "beetle_6to9yo_E" = beetle_6to9yo_E [inds])
# Functional Responses
# All COVARS
model.lme.fxn.du7.s.all <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo +
                                     beetle_1to5yo_E + beetle_6to9yo_E + 
                                     beetle_1to5yo:beetle_1to5yo_E +
                                     beetle_6to9yo:beetle_6to9yo_E +
                                     (1 | uniqueID), 
                                   data = insect.data.du.7.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [34, 1] <- "DU7"
table.aic [34, 2] <- "Summer"
table.aic [34, 3] <- "GLMM with Functional Response"
table.aic [34, 4] <- "Beetle1to5, Beetle6to9, A_Beetle1to5, A_Beetle6to9, Beetle1to5*A_Beetle1to5, Beetle6to9*A_Beetle6to9"
table.aic [34, 5] <- "(1 | UniqueID)"
table.aic [34, 6] <- AIC (model.lme.fxn.du7.s.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.s.all, type = 'response'), insect.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [34, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du7.s.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                            beetle_1to5yo_E + 
                                            beetle_1to5yo:beetle_1to5yo_E +
                                            (1 | uniqueID), 
                                  data = insect.data.du.7.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [35, 1] <- "DU7"
table.aic [35, 2] <- "Summer"
table.aic [35, 3] <- "GLMM with Functional Response"
table.aic [35, 4] <- "Beetle1to5, A_Beetle1to5, Beetle1to5*A_Beetle1to5"
table.aic [35, 5] <- "(1 | UniqueID)"
table.aic [35, 6] <- AIC (model.lme.fxn.du7.s.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.s.1to5, type = 'response'), insect.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [35, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.fxn.du7.s.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                             beetle_6to9yo_E + 
                                             beetle_6to9yo:beetle_6to9yo_E +
                                             (1 | uniqueID), 
                                   data = insect.data.du.7.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [36, 1] <- "DU7"
table.aic [36, 2] <- "Summer"
table.aic [36, 3] <- "GLMM with Functional Response"
table.aic [36, 4] <- "Beetle6to9, A_Beetle6to9, Beetle6to9*A_Beetle6to9"
table.aic [36, 5] <- "(1 | UniqueID)"
table.aic [36, 6] <- AIC (model.lme.fxn.du7.s.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.s.6to9, type = 'response'), insect.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [36, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [31, 6] - min (table.aic [31:36, 6])))),
                    (exp (-0.5 * (table.aic [32, 6] - min (table.aic [31:36, 6])))),
                    (exp (-0.5 * (table.aic [33, 6] - min (table.aic [31:36, 6])))),
                    (exp (-0.5 * (table.aic [34, 6] - min (table.aic [31:36, 6])))),
                    (exp (-0.5 * (table.aic [35, 6] - min (table.aic [31:36, 6])))),
                    (exp (-0.5 * (table.aic [36, 6] - min (table.aic [31:36, 6])))))
table.aic [31, 7] <- round ((exp (-0.5 * (table.aic [31, 6] - min (table.aic [31:36, 6])))) / sum (list.aic.like), 3)
table.aic [32, 7] <- round ((exp (-0.5 * (table.aic [32, 6] - min (table.aic [31:36, 6])))) / sum (list.aic.like), 3)
table.aic [33, 7] <- round ((exp (-0.5 * (table.aic [33, 6] - min (table.aic [31:36, 6])))) / sum (list.aic.like), 3)
table.aic [34, 7] <- round ((exp (-0.5 * (table.aic [34, 6] - min (table.aic [31:36, 6])))) / sum (list.aic.like), 3)
table.aic [35, 7] <- round ((exp (-0.5 * (table.aic [35, 6] - min (table.aic [31:36, 6])))) / sum (list.aic.like), 3)
table.aic [36, 7] <- round ((exp (-0.5 * (table.aic [36, 6] - min (table.aic [31:36, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_insect.csv", sep = ",")

#===============
## DU8 ##
#==============
## Early Winter
### Correlation
corr.insect.du.8.ew <- round (cor (insect.data.du.8.ew [10:11], method = "spearman"), 3)
ggcorrplot (corr.insect.du.8.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Beetle Infested Forest Stand Age Correlation DU8 Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_insect_corr_du_8_ew.png")

### VIF
model.glm.du8.ew <- glm (pttype ~ beetle_1to5yo + beetle_6to9yo, 
                         data = insect.data.du.8.ew,
                         family = binomial (link = 'logit'))
vif (model.glm.du8.ew) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du8.ew <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                                     (beetle_1to5yo | uniqueID) + 
                                     (beetle_6to9yo | uniqueID), 
                           data = insect.data.du.8.ew, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [37, 1] <- "DU8"
table.aic [37, 2] <- "Early Winter"
table.aic [37, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [37, 4] <- "Beetle1to5, Beetle6to9"
table.aic [37, 5] <- "(Beetle1to5 | UniqueID), (Beetle6to9 | UniqueID)"
table.aic [37, 6] <- AIC (model.lme.du8.ew)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.ew, type = 'response'), insect.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [37, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du8.ew.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                        (beetle_1to5yo | uniqueID), 
                           data = insect.data.du.8.ew, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [38, 1] <- "DU8"
table.aic [38, 2] <- "Early Winter"
table.aic [38, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [38, 4] <- "Beetle1to5"
table.aic [38, 5] <- "(Beetle1to5 | UniqueID)"
table.aic [38, 6] <- AIC (model.lme.du8.ew.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.ew.1to5, type = 'response'), insect.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [38, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.du8.ew.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                        (beetle_6to9yo | uniqueID), 
                                data = insect.data.du.8.ew, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [39, 1] <- "DU8"
table.aic [39, 2] <- "Early Winter"
table.aic [39, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [39, 4] <- "Beetle6to9"
table.aic [39, 5] <- "(Beetle6to9 | UniqueID)"
table.aic [39, 6] <- AIC (model.lme.du8.ew.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.ew.6to9, type = 'response'), insect.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [39, 8] <- auc.temp@y.values[[1]]

# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (insect.data.du.8.ew, pttype == 0)
beetle_1to5yo_E <- tapply (sub$beetle_1to5yo, sub$uniqueID, sum)
beetle_6to9yo_E <- tapply (sub$beetle_6to9yo, sub$uniqueID, sum)
inds <- as.character (insect.data.du.8.ew$uniqueID)
insect.data.du.8.ew <- cbind (insect.data.du.8.ew, 
                             "beetle_1to5yo_E" = beetle_1to5yo_E [inds],
                             "beetle_6to9yo_E" = beetle_6to9yo_E [inds])
# Functional Responses
# All COVARS
model.lme.fxn.du8.ew.all <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo +
                                    beetle_1to5yo_E + beetle_6to9yo_E + 
                                    beetle_1to5yo:beetle_1to5yo_E +
                                    beetle_6to9yo:beetle_6to9yo_E +
                                    (1 | uniqueID), 
                                  data = insect.data.du.8.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [40, 1] <- "DU8"
table.aic [40, 2] <- "Early Winter"
table.aic [40, 3] <- "GLMM with Functional Response"
table.aic [40, 4] <- "Beetle1to5, Beetle6to9, A_Beetle1to5, A_Beetle6to9, Beetle1to5*A_Beetle1to5, Beetle6to9*A_Beetle6to9"
table.aic [40, 5] <- "(1 | UniqueID)"
table.aic [40, 6] <- AIC (model.lme.fxn.du8.ew.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.ew.all, type = 'response'), insect.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [40, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du8.ew.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                              beetle_1to5yo_E + 
                                              beetle_1to5yo:beetle_1to5yo_E +
                                              (1 | uniqueID), 
                                   data = insect.data.du.8.ew, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [41, 1] <- "DU8"
table.aic [41, 2] <- "Early Winter"
table.aic [41, 3] <- "GLMM with Functional Response"
table.aic [41, 4] <- "Beetle1to5, A_Beetle1to5, Beetle1to5*A_Beetle1to5"
table.aic [41, 5] <- "(1 | UniqueID)"
table.aic [41, 6] <- AIC (model.lme.fxn.du8.ew.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.ew.1to5, type = 'response'), insect.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [41, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.fxn.du8.ew.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                              beetle_6to9yo_E + 
                                              beetle_6to9yo:beetle_6to9yo_E +
                                              (1 | uniqueID), 
                                    data = insect.data.du.8.ew, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [42, 1] <- "DU8"
table.aic [42, 2] <- "Early Winter"
table.aic [42, 3] <- "GLMM with Functional Response"
table.aic [42, 4] <- "Beetle6to9, A_Beetle6to9, Beetle6to9*A_Beetle6to9"
table.aic [42, 5] <- "(1 | UniqueID)"
table.aic [42, 6] <- AIC (model.lme.fxn.du8.ew.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.ew.6to9, type = 'response'), insect.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [42, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [37, 6] - min (table.aic [37:42, 6])))),
                    (exp (-0.5 * (table.aic [38, 6] - min (table.aic [37:42, 6])))),
                    (exp (-0.5 * (table.aic [39, 6] - min (table.aic [37:42, 6])))),
                    (exp (-0.5 * (table.aic [40, 6] - min (table.aic [37:42, 6])))),
                    (exp (-0.5 * (table.aic [41, 6] - min (table.aic [37:42, 6])))),
                    (exp (-0.5 * (table.aic [42, 6] - min (table.aic [37:42, 6])))))
table.aic [37, 7] <- round ((exp (-0.5 * (table.aic [37, 6] - min (table.aic [37:42, 6])))) / sum (list.aic.like), 3)
table.aic [38, 7] <- round ((exp (-0.5 * (table.aic [38, 6] - min (table.aic [37:42, 6])))) / sum (list.aic.like), 3)
table.aic [39, 7] <- round ((exp (-0.5 * (table.aic [39, 6] - min (table.aic [37:42, 6])))) / sum (list.aic.like), 3)
table.aic [40, 7] <- round ((exp (-0.5 * (table.aic [40, 6] - min (table.aic [37:42, 6])))) / sum (list.aic.like), 3)
table.aic [41, 7] <- round ((exp (-0.5 * (table.aic [41, 6] - min (table.aic [37:42, 6])))) / sum (list.aic.like), 3)
table.aic [42, 7] <- round ((exp (-0.5 * (table.aic [42, 6] - min (table.aic [37:42, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_insect.csv", sep = ",")

## Late Winter
### Correlation
corr.insect.du.8.lw <- round (cor (insect.data.du.8.lw [10:11], method = "spearman"), 3)
ggcorrplot (corr.insect.du.8.lw, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Beetle Infested Forest Stand Age Correlation DU8 Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_insect_corr_du_8_lw.png")

### VIF
model.glm.du8.lw <- glm (pttype ~ beetle_1to5yo + beetle_6to9yo, 
                         data = insect.data.du.8.lw,
                         family = binomial (link = 'logit'))
vif (model.glm.du8.lw) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du8.lw <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                                     (beetle_1to5yo | uniqueID) + 
                                     (beetle_6to9yo | uniqueID), 
                           data = insect.data.du.8.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [43, 1] <- "DU8"
table.aic [43, 2] <- "Late Winter"
table.aic [43, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [43, 4] <- "Beetle1to5, Beetle6to9"
table.aic [43, 5] <- "(Beetle1to5 | UniqueID), (Beetle6to9 | UniqueID)"
table.aic [43, 6] <- AIC (model.lme.du8.lw)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.lw, type = 'response'), insect.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [43, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du8.lw.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                        (beetle_1to5yo | uniqueID), 
                           data = insect.data.du.8.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [44, 1] <- "DU8"
table.aic [44, 2] <- "Late Winter"
table.aic [44, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [44, 4] <- "Beetle1to5"
table.aic [44, 5] <- "(Beetle1to5 | UniqueID)"
table.aic [44, 6] <- AIC (model.lme.du8.lw.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.lw.1to5, type = 'response'), insect.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [44, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.du8.lw.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                        (beetle_6to9yo | uniqueID), 
                                data = insect.data.du.8.lw, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [45, 1] <- "DU8"
table.aic [45, 2] <- "Late Winter"
table.aic [45, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [45, 4] <- "Beetle6to9"
table.aic [45, 5] <- "(Beetle6to9 | UniqueID)"
table.aic [45, 6] <- AIC (model.lme.du8.lw.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.lw.6to9, type = 'response'), insect.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [45, 8] <- auc.temp@y.values[[1]]

# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (insect.data.du.8.lw, pttype == 0)
beetle_1to5yo_E <- tapply (sub$beetle_1to5yo, sub$uniqueID, sum)
beetle_6to9yo_E <- tapply (sub$beetle_6to9yo, sub$uniqueID, sum)
inds <- as.character (insect.data.du.8.lw$uniqueID)
insect.data.du.8.lw <- cbind (insect.data.du.8.lw, 
                              "beetle_1to5yo_E" = beetle_1to5yo_E [inds],
                              "beetle_6to9yo_E" = beetle_6to9yo_E [inds])
# Functional Responses
# All COVARS
model.lme.fxn.du8.lw.all <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo +
                                     beetle_1to5yo_E + beetle_6to9yo_E + 
                                     beetle_1to5yo:beetle_1to5yo_E +
                                     beetle_6to9yo:beetle_6to9yo_E +
                                     (1 | uniqueID), 
                                   data = insect.data.du.8.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [46, 1] <- "DU8"
table.aic [46, 2] <- "Late Winter"
table.aic [46, 3] <- "GLMM with Functional Response"
table.aic [46, 4] <- "Beetle1to5, Beetle6to9, A_Beetle1to5, A_Beetle6to9, Beetle1to5*A_Beetle1to5, Beetle6to9*A_Beetle6to9"
table.aic [46, 5] <- "(1 | UniqueID)"
table.aic [46, 6] <- AIC (model.lme.fxn.du8.lw.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.lw.all, type = 'response'), insect.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [46, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du8.lw.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                              beetle_1to5yo_E + 
                                              beetle_1to5yo:beetle_1to5yo_E +
                                              (1 | uniqueID), 
                                   data = insect.data.du.8.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [47, 1] <- "DU8"
table.aic [47, 2] <- "Late Winter"
table.aic [47, 3] <- "GLMM with Functional Response"
table.aic [47, 4] <- "Beetle1to5, A_Beetle1to5, Beetle1to5*A_Beetle1to5"
table.aic [47, 5] <- "(1 | UniqueID)"
table.aic [47, 6] <- AIC (model.lme.fxn.du8.lw.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.lw.1to5, type = 'response'), insect.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [47, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.fxn.du8.lw.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                              beetle_6to9yo_E + 
                                              beetle_6to9yo:beetle_6to9yo_E +
                                              (1 | uniqueID), 
                                    data = insect.data.du.8.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [48, 1] <- "DU8"
table.aic [48, 2] <- "Late Winter"
table.aic [48, 3] <- "GLMM with Functional Response"
table.aic [48, 4] <- "Beetle6to9, A_Beetle6to9, Beetle6to9*A_Beetle6to9"
table.aic [48, 5] <- "(1 | UniqueID)"
table.aic [48, 6] <- AIC (model.lme.fxn.du8.lw.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.lw.6to9, type = 'response'), insect.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [48, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [43, 6] - min (table.aic [43:48, 6])))),
                    (exp (-0.5 * (table.aic [44, 6] - min (table.aic [43:48, 6])))),
                    (exp (-0.5 * (table.aic [45, 6] - min (table.aic [43:48, 6])))),
                    (exp (-0.5 * (table.aic [46, 6] - min (table.aic [43:48, 6])))),
                    (exp (-0.5 * (table.aic [47, 6] - min (table.aic [43:48, 6])))),
                    (exp (-0.5 * (table.aic [48, 6] - min (table.aic [43:48, 6])))))
table.aic [43, 7] <- round ((exp (-0.5 * (table.aic [43, 6] - min (table.aic [43:48, 6])))) / sum (list.aic.like), 3)
table.aic [44, 7] <- round ((exp (-0.5 * (table.aic [44, 6] - min (table.aic [43:48, 6])))) / sum (list.aic.like), 3)
table.aic [45, 7] <- round ((exp (-0.5 * (table.aic [45, 6] - min (table.aic [43:48, 6])))) / sum (list.aic.like), 3)
table.aic [46, 7] <- round ((exp (-0.5 * (table.aic [46, 6] - min (table.aic [43:48, 6])))) / sum (list.aic.like), 3)
table.aic [47, 7] <- round ((exp (-0.5 * (table.aic [47, 6] - min (table.aic [43:48, 6])))) / sum (list.aic.like), 3)
table.aic [48, 7] <- round ((exp (-0.5 * (table.aic [48, 6] - min (table.aic [43:48, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_insect.csv", sep = ",")

## Summer
### Correlation
corr.insect.du.8.s <- round (cor (insect.data.du.8.s [10:11], method = "spearman"), 3)
ggcorrplot (corr.insect.du.8.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Beetle Infested Forest Stand Age Correlation DU8 Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_insect_corr_du_8_s.png")

### VIF
model.glm.du8.s <- glm (pttype ~ beetle_1to5yo + beetle_6to9yo, 
                         data = insect.data.du.8.s,
                         family = binomial (link = 'logit'))
vif (model.glm.du8.s) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du8.s <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                                     (beetle_1to5yo | uniqueID) + 
                                     (beetle_6to9yo | uniqueID), 
                           data = insect.data.du.8.s, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [49, 1] <- "DU8"
table.aic [49, 2] <- "Summer"
table.aic [49, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [49, 4] <- "Beetle1to5, Beetle6to9"
table.aic [49, 5] <- "(Beetle1to5 | UniqueID), (Beetle6to9 | UniqueID)"
table.aic [49, 6] <- AIC (model.lme.du8.s)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.s, type = 'response'), insect.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [49, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du8.s.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                        (beetle_1to5yo | uniqueID), 
                          data = insect.data.du.8.s, 
                          family = binomial (link = "logit"),
                          verbose = T,
                          control = glmerControl (calc.derivs = FALSE, 
                                                  optimizer = "nloptwrap", 
                                                  optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [50, 1] <- "DU8"
table.aic [50, 2] <- "Summer"
table.aic [50, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [50, 4] <- "Beetle1to5"
table.aic [50, 5] <- "(Beetle1to5 | UniqueID)"
table.aic [50, 6] <- AIC (model.lme.du8.s.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.s.1to5, type = 'response'), insect.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [50, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.du8.s.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                        (beetle_6to9yo | uniqueID), 
                               data = insect.data.du.8.s, 
                               family = binomial (link = "logit"),
                               verbose = T,
                               control = glmerControl (calc.derivs = FALSE, 
                                                       optimizer = "nloptwrap", 
                                                       optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [51, 1] <- "DU8"
table.aic [51, 2] <- "Summer"
table.aic [51, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [51, 4] <- "Beetle6to9"
table.aic [51, 5] <- "(Beetle6to9 | UniqueID)"
table.aic [51, 6] <- AIC (model.lme.du8.s.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.s.6to9, type = 'response'), insect.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [51, 8] <- auc.temp@y.values[[1]]

# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (insect.data.du.8.s, pttype == 0)
beetle_1to5yo_E <- tapply (sub$beetle_1to5yo, sub$uniqueID, sum)
beetle_6to9yo_E <- tapply (sub$beetle_6to9yo, sub$uniqueID, sum)
inds <- as.character (insect.data.du.8.s$uniqueID)
insect.data.du.8.s <- cbind (insect.data.du.8.s, 
                              "beetle_1to5yo_E" = beetle_1to5yo_E [inds],
                              "beetle_6to9yo_E" = beetle_6to9yo_E [inds])
# Functional Responses
# All COVARS
model.lme.fxn.du8.s.all <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo +
                                     beetle_1to5yo_E + beetle_6to9yo_E + 
                                     beetle_1to5yo:beetle_1to5yo_E +
                                     beetle_6to9yo:beetle_6to9yo_E +
                                     (1 | uniqueID), 
                                   data = insect.data.du.8.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [52, 1] <- "DU8"
table.aic [52, 2] <- "Summer"
table.aic [52, 3] <- "GLMM with Functional Response"
table.aic [52, 4] <- "Beetle1to5, Beetle6to9, A_Beetle1to5, A_Beetle6to9, Beetle1to5*A_Beetle1to5, Beetle6to9*A_Beetle6to9"
table.aic [52, 5] <- "(1 | UniqueID)"
table.aic [52, 6] <- AIC (model.lme.fxn.du8.s.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.s.all, type = 'response'), insect.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [52, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du8.s.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                            beetle_1to5yo_E + 
                                            beetle_1to5yo:beetle_1to5yo_E +
                                            (1 | uniqueID), 
                                  data = insect.data.du.8.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [53, 1] <- "DU8"
table.aic [53, 2] <- "Summer"
table.aic [53, 3] <- "GLMM with Functional Response"
table.aic [53, 4] <- "Beetle1to5, A_Beetle1to5, Beetle1to5*A_Beetle1to5"
table.aic [53, 5] <- "(1 | UniqueID)"
table.aic [53, 6] <- AIC (model.lme.fxn.du8.s.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.s.1to5, type = 'response'), insect.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [53, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.fxn.du8.s.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                             beetle_6to9yo_E + 
                                             beetle_6to9yo:beetle_6to9yo_E +
                                             (1 | uniqueID), 
                                   data = insect.data.du.8.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [54, 1] <- "DU8"
table.aic [54, 2] <- "Summer"
table.aic [54, 3] <- "GLMM with Functional Response"
table.aic [54, 4] <- "Beetle6to9, A_Beetle6to9, Beetle6to9*A_Beetle6to9"
table.aic [54, 5] <- "(1 | UniqueID)"
table.aic [54, 6] <- AIC (model.lme.fxn.du8.s.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.s.6to9, type = 'response'), insect.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [54, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [49, 6] - min (table.aic [49:54, 6])))),
                    (exp (-0.5 * (table.aic [50, 6] - min (table.aic [49:54, 6])))),
                    (exp (-0.5 * (table.aic [51, 6] - min (table.aic [49:54, 6])))),
                    (exp (-0.5 * (table.aic [52, 6] - min (table.aic [49:54, 6])))),
                    (exp (-0.5 * (table.aic [53, 6] - min (table.aic [49:54, 6])))),
                    (exp (-0.5 * (table.aic [54, 6] - min (table.aic [49:54, 6])))))
table.aic [49, 7] <- round ((exp (-0.5 * (table.aic [49, 6] - min (table.aic [49:54, 6])))) / sum (list.aic.like), 3)
table.aic [50, 7] <- round ((exp (-0.5 * (table.aic [50, 6] - min (table.aic [49:54, 6])))) / sum (list.aic.like), 3)
table.aic [51, 7] <- round ((exp (-0.5 * (table.aic [51, 6] - min (table.aic [49:54, 6])))) / sum (list.aic.like), 3)
table.aic [52, 7] <- round ((exp (-0.5 * (table.aic [52, 6] - min (table.aic [49:54, 6])))) / sum (list.aic.like), 3)
table.aic [53, 7] <- round ((exp (-0.5 * (table.aic [53, 6] - min (table.aic [49:54, 6])))) / sum (list.aic.like), 3)
table.aic [54, 7] <- round ((exp (-0.5 * (table.aic [54, 6] - min (table.aic [49:54, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_insect.csv", sep = ",")



#===============
## DU9 ##
#==============
## Early Winter
### Correlation
corr.insect.du.9.ew <- round (cor (insect.data.du.9.ew [10:11], method = "spearman"), 3)
ggcorrplot (corr.insect.du.9.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Beetle Infested Forest Stand Age Correlation DU9 Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_insect_corr_du_9_ew.png")

### VIF
model.glm.du9.ew <- glm (pttype ~ beetle_1to5yo + beetle_6to9yo, 
                         data = insect.data.du.9.ew,
                         family = binomial (link = 'logit'))
vif (model.glm.du9.ew) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du9.ew <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                             (beetle_1to5yo | uniqueID) + 
                             (beetle_6to9yo | uniqueID), 
                           data = insect.data.du.9.ew, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [55, 1] <- "DU9"
table.aic [55, 2] <- "Early Winter"
table.aic [55, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [55, 4] <- "Beetle1to5, Beetle6to9"
table.aic [55, 5] <- "(Beetle1to5 | UniqueID), (Beetle6to9 | UniqueID)"
table.aic [55, 6] <- AIC (model.lme.du9.ew)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.ew, type = 'response'), insect.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [55, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du9.ew.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                          (beetle_1to5yo | uniqueID), 
                           data = insect.data.du.9.ew, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [56, 1] <- "DU9"
table.aic [56, 2] <- "Early Winter"
table.aic [56, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [56, 4] <- "Beetle1to5"
table.aic [56, 5] <- "(Beetle1to5 | UniqueID)"
table.aic [56, 6] <- AIC (model.lme.du9.ew.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.ew.1to5, type = 'response'), insect.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [56, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.du9.ew.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                          (beetle_6to9yo | uniqueID), 
                                data = insect.data.du.9.ew, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [57, 1] <- "DU9"
table.aic [57, 2] <- "Early Winter"
table.aic [57, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [57, 4] <- "Beetle6to9"
table.aic [57, 5] <- "(Beetle6to9 | UniqueID)"
table.aic [57, 6] <- AIC (model.lme.du9.ew.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.ew.6to9, type = 'response'), insect.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [57, 8] <- auc.temp@y.values[[1]]

# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (insect.data.du.9.ew, pttype == 0)
beetle_1to5yo_E <- tapply (sub$beetle_1to5yo, sub$uniqueID, sum)
beetle_6to9yo_E <- tapply (sub$beetle_6to9yo, sub$uniqueID, sum)
inds <- as.character (insect.data.du.9.ew$uniqueID)
insect.data.du.9.ew <- cbind (insect.data.du.9.ew, 
                              "beetle_1to5yo_E" = beetle_1to5yo_E [inds],
                              "beetle_6to9yo_E" = beetle_6to9yo_E [inds])
# Functional Responses
# All COVARS
model.lme.fxn.du9.ew.all <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo +
                                     beetle_1to5yo_E + beetle_6to9yo_E + 
                                     beetle_1to5yo:beetle_1to5yo_E +
                                     beetle_6to9yo:beetle_6to9yo_E +
                                     (1 | uniqueID), 
                                   data = insect.data.du.9.ew, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [58, 1] <- "DU9"
table.aic [58, 2] <- "Early Winter"
table.aic [58, 3] <- "GLMM with Functional Response"
table.aic [58, 4] <- "Beetle1to5, Beetle6to9, A_Beetle1to5, A_Beetle6to9, Beetle1to5*A_Beetle1to5, Beetle6to9*A_Beetle6to9"
table.aic [58, 5] <- "(1 | UniqueID)"
table.aic [58, 6] <- AIC (model.lme.fxn.du9.ew.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.ew.all, type = 'response'), insect.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [58, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du9.ew.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                              beetle_1to5yo_E + 
                                              beetle_1to5yo:beetle_1to5yo_E +
                                              (1 | uniqueID), 
                                   data = insect.data.du.9.ew, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [59, 1] <- "DU9"
table.aic [59, 2] <- "Early Winter"
table.aic [59, 3] <- "GLMM with Functional Response"
table.aic [59, 4] <- "Beetle1to5, A_Beetle1to5, Beetle1to5*A_Beetle1to5"
table.aic [59, 5] <- "(1 | UniqueID)"
table.aic [59, 6] <- AIC (model.lme.fxn.du9.ew.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.ew.1to5, type = 'response'), insect.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [59, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.fxn.du9.ew.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                              beetle_6to9yo_E + 
                                              beetle_6to9yo:beetle_6to9yo_E +
                                              (1 | uniqueID), 
                                    data = insect.data.du.9.ew, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [60, 1] <- "DU9"
table.aic [60, 2] <- "Early Winter"
table.aic [60, 3] <- "GLMM with Functional Response"
table.aic [60, 4] <- "Beetle6to9, A_Beetle6to9, Beetle6to9*A_Beetle6to9"
table.aic [60, 5] <- "(1 | UniqueID)"
table.aic [60, 6] <- AIC (model.lme.fxn.du9.ew.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.ew.6to9, type = 'response'), insect.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [60, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [55, 6] - min (table.aic [55:60, 6])))),
                    (exp (-0.5 * (table.aic [56, 6] - min (table.aic [55:60, 6])))),
                    (exp (-0.5 * (table.aic [57, 6] - min (table.aic [55:60, 6])))),
                    (exp (-0.5 * (table.aic [58, 6] - min (table.aic [55:60, 6])))),
                    (exp (-0.5 * (table.aic [59, 6] - min (table.aic [55:60, 6])))),
                    (exp (-0.5 * (table.aic [60, 6] - min (table.aic [55:60, 6])))))
table.aic [55, 7] <- round ((exp (-0.5 * (table.aic [55, 6] - min (table.aic [55:60, 6])))) / sum (list.aic.like), 3)
table.aic [56, 7] <- round ((exp (-0.5 * (table.aic [56, 6] - min (table.aic [55:60, 6])))) / sum (list.aic.like), 3)
table.aic [57, 7] <- round ((exp (-0.5 * (table.aic [57, 6] - min (table.aic [55:60, 6])))) / sum (list.aic.like), 3)
table.aic [58, 7] <- round ((exp (-0.5 * (table.aic [58, 6] - min (table.aic [55:60, 6])))) / sum (list.aic.like), 3)
table.aic [59, 7] <- round ((exp (-0.5 * (table.aic [59, 6] - min (table.aic [55:60, 6])))) / sum (list.aic.like), 3)
table.aic [60, 7] <- round ((exp (-0.5 * (table.aic [60, 6] - min (table.aic [55:60, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_insect.csv", sep = ",")

## Late Winter
### Correlation
corr.insect.du.9.lw <- round (cor (insect.data.du.9.lw [10:11], method = "spearman"), 3)
ggcorrplot (corr.insect.du.9.lw, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Beetle Infested Forest Stand Age Correlation DU9 Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_insect_corr_du_9_lw.png")

### VIF
model.glm.du9.lw <- glm (pttype ~ beetle_1to5yo + beetle_6to9yo, 
                         data = insect.data.du.9.lw,
                         family = binomial (link = 'logit'))
vif (model.glm.du9.lw) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du9.lw <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                                     (beetle_1to5yo | uniqueID) + 
                                     (beetle_6to9yo | uniqueID), 
                           data = insect.data.du.9.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [61, 1] <- "DU9"
table.aic [61, 2] <- "Late Winter"
table.aic [61, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [61, 4] <- "Beetle1to5, Beetle6to9"
table.aic [61, 5] <- "(Beetle1to5 | UniqueID), (Beetle6to9 | UniqueID)"
table.aic [61, 6] <- AIC (model.lme.du9.lw)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.lw, type = 'response'), insect.data.du.9.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [61, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du9.lw.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                          (beetle_1to5yo | uniqueID), 
                           data = insect.data.du.9.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [62, 1] <- "DU9"
table.aic [62, 2] <- "Late Winter"
table.aic [62, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [62, 4] <- "Beetle1to5"
table.aic [62, 5] <- "(Beetle1to5 | UniqueID)"
table.aic [62, 6] <- AIC (model.lme.du9.lw.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.lw.1to5, type = 'response'), insect.data.du.9.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [62, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.du9.lw.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                        (beetle_6to9yo | uniqueID), 
                                data = insect.data.du.9.lw, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [63, 1] <- "DU9"
table.aic [63, 2] <- "Late Winter"
table.aic [63, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [63, 4] <- "Beetle6to9"
table.aic [63, 5] <- "(Beetle6to9 | UniqueID)"
table.aic [63, 6] <- AIC (model.lme.du9.lw.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.lw.6to9, type = 'response'), insect.data.du.9.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [63, 8] <- auc.temp@y.values[[1]]

# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (insect.data.du.9.lw, pttype == 0)
beetle_1to5yo_E <- tapply (sub$beetle_1to5yo, sub$uniqueID, sum)
beetle_6to9yo_E <- tapply (sub$beetle_6to9yo, sub$uniqueID, sum)
inds <- as.character (insect.data.du.9.lw$uniqueID)
insect.data.du.9.lw <- cbind (insect.data.du.9.lw, 
                              "beetle_1to5yo_E" = beetle_1to5yo_E [inds],
                              "beetle_6to9yo_E" = beetle_6to9yo_E [inds])
# Functional Responses
# All COVARS
model.lme.fxn.du9.lw.all <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo +
                                             beetle_1to5yo_E + beetle_6to9yo_E + 
                                             beetle_1to5yo:beetle_1to5yo_E +
                                             beetle_6to9yo:beetle_6to9yo_E +
                                             (1 | uniqueID), 
                                   data = insect.data.du.9.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [64, 1] <- "DU9"
table.aic [64, 2] <- "Late Winter"
table.aic [64, 3] <- "GLMM with Functional Response"
table.aic [64, 4] <- "Beetle1to5, Beetle6to9, A_Beetle1to5, A_Beetle6to9, Beetle1to5*A_Beetle1to5, Beetle6to9*A_Beetle6to9"
table.aic [64, 5] <- "(1 | UniqueID)"
table.aic [64, 6] <- AIC (model.lme.fxn.du9.lw.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.lw.all, type = 'response'), insect.data.du.9.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [64, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du9.lw.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                              beetle_1to5yo_E + 
                                              beetle_1to5yo:beetle_1to5yo_E +
                                              (1 | uniqueID), 
                                   data = insect.data.du.9.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [65, 1] <- "DU9"
table.aic [65, 2] <- "Late Winter"
table.aic [65, 3] <- "GLMM with Functional Response"
table.aic [65, 4] <- "Beetle1to5, A_Beetle1to5, Beetle1to5*A_Beetle1to5"
table.aic [65, 5] <- "(1 | UniqueID)"
table.aic [65, 6] <- AIC (model.lme.fxn.du9.lw.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.lw.1to5, type = 'response'), insect.data.du.9.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [65, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.fxn.du9.lw.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                              beetle_6to9yo_E + 
                                              beetle_6to9yo:beetle_6to9yo_E +
                                              (1 | uniqueID), 
                                    data = insect.data.du.9.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [66, 1] <- "DU9"
table.aic [66, 2] <- "Late Winter"
table.aic [66, 3] <- "GLMM with Functional Response"
table.aic [66, 4] <- "Beetle6to9, A_Beetle6to9, Beetle6to9*A_Beetle6to9"
table.aic [66, 5] <- "(1 | UniqueID)"
table.aic [66, 6] <- AIC (model.lme.fxn.du9.lw.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.lw.6to9, type = 'response'), insect.data.du.9.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [66, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [61, 6] - min (table.aic [61:66, 6])))),
                    (exp (-0.5 * (table.aic [62, 6] - min (table.aic [61:66, 6])))),
                    (exp (-0.5 * (table.aic [63, 6] - min (table.aic [61:66, 6])))),
                    (exp (-0.5 * (table.aic [64, 6] - min (table.aic [61:66, 6])))),
                    (exp (-0.5 * (table.aic [65, 6] - min (table.aic [61:66, 6])))),
                    (exp (-0.5 * (table.aic [66, 6] - min (table.aic [61:66, 6])))))
table.aic [61, 7] <- round ((exp (-0.5 * (table.aic [61, 6] - min (table.aic [61:66, 6])))) / sum (list.aic.like), 3)
table.aic [62, 7] <- round ((exp (-0.5 * (table.aic [62, 6] - min (table.aic [61:66, 6])))) / sum (list.aic.like), 3)
table.aic [63, 7] <- round ((exp (-0.5 * (table.aic [63, 6] - min (table.aic [61:66, 6])))) / sum (list.aic.like), 3)
table.aic [64, 7] <- round ((exp (-0.5 * (table.aic [64, 6] - min (table.aic [61:66, 6])))) / sum (list.aic.like), 3)
table.aic [65, 7] <- round ((exp (-0.5 * (table.aic [65, 6] - min (table.aic [61:66, 6])))) / sum (list.aic.like), 3)
table.aic [66, 7] <- round ((exp (-0.5 * (table.aic [66, 6] - min (table.aic [61:66, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_insect.csv", sep = ",")

## Summer
### Correlation
corr.insect.du.9.s <- round (cor (insect.data.du.9.s [10:11], method = "spearman"), 3)
ggcorrplot (corr.insect.du.9.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Beetle Infested Forest Stand Age Correlation DU9 Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_insect_corr_du_9_s.png")

### VIF
model.glm.du9.s <- glm (pttype ~ beetle_1to5yo + beetle_6to9yo, 
                         data = insect.data.du.9.s,
                         family = binomial (link = 'logit'))
vif (model.glm.du9.s) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du9.s <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo + 
                                     (beetle_1to5yo | uniqueID) + 
                                     (beetle_6to9yo | uniqueID), 
                           data = insect.data.du.9.s, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [67, 1] <- "DU9"
table.aic [67, 2] <- "Summer"
table.aic [67, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [67, 4] <- "Beetle1to5, Beetle6to9"
table.aic [67, 5] <- "(Beetle1to5 | UniqueID), (Beetle6to9 | UniqueID)"
table.aic [67, 6] <- AIC (model.lme.du9.s)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.s, type = 'response'), insect.data.du.9.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [67, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du9.s.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                        (beetle_1to5yo | uniqueID), 
                          data = insect.data.du.9.s, 
                          family = binomial (link = "logit"),
                          verbose = T,
                          control = glmerControl (calc.derivs = FALSE, 
                                                  optimizer = "nloptwrap", 
                                                  optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [68, 1] <- "DU9"
table.aic [68, 2] <- "Summer"
table.aic [68, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [68, 4] <- "Beetle1to5"
table.aic [68, 5] <- "(Beetle1to5 | UniqueID)"
table.aic [68, 6] <- AIC (model.lme.du9.s.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.s.1to5, type = 'response'), insect.data.du.9.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [68, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.du9.s.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                        (beetle_6to9yo | uniqueID), 
                               data = insect.data.du.9.s, 
                               family = binomial (link = "logit"),
                               verbose = T,
                               control = glmerControl (calc.derivs = FALSE, 
                                                       optimizer = "nloptwrap", 
                                                       optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [69, 1] <- "DU9"
table.aic [69, 2] <- "Summer"
table.aic [69, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [69, 4] <- "Beetle6to9"
table.aic [69, 5] <- "(Beetle6to9 | UniqueID)"
table.aic [69, 6] <- AIC (model.lme.du9.s.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.s.6to9, type = 'response'), insect.data.du.9.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [69, 8] <- auc.temp@y.values[[1]]

# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (insect.data.du.9.s, pttype == 0)
beetle_1to5yo_E <- tapply (sub$beetle_1to5yo, sub$uniqueID, sum)
beetle_6to9yo_E <- tapply (sub$beetle_6to9yo, sub$uniqueID, sum)
inds <- as.character (insect.data.du.9.s$uniqueID)
insect.data.du.9.s <- cbind (insect.data.du.9.s, 
                              "beetle_1to5yo_E" = beetle_1to5yo_E [inds],
                              "beetle_6to9yo_E" = beetle_6to9yo_E [inds])
# Functional Responses
# All COVARS
model.lme.fxn.du9.s.all <- glmer (pttype ~ beetle_1to5yo + beetle_6to9yo +
                                     beetle_1to5yo_E + beetle_6to9yo_E + 
                                     beetle_1to5yo:beetle_1to5yo_E +
                                     beetle_6to9yo:beetle_6to9yo_E +
                                     (1 | uniqueID), 
                                   data = insect.data.du.9.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [70, 1] <- "DU9"
table.aic [70, 2] <- "Summer"
table.aic [70, 3] <- "GLMM with Functional Response"
table.aic [70, 4] <- "Beetle1to5, Beetle6to9, A_Beetle1to5, A_Beetle6to9, Beetle1to5*A_Beetle1to5, Beetle6to9*A_Beetle6to9"
table.aic [70, 5] <- "(1 | UniqueID)"
table.aic [70, 6] <- AIC (model.lme.fxn.du9.s.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.s.all, type = 'response'), insect.data.du.9.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [70, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du9.s.all.1to5 <- glmer (pttype ~ beetle_1to5yo + 
                                                beetle_1to5yo_E + 
                                                beetle_1to5yo:beetle_1to5yo_E +
                                                (1 | uniqueID), 
                                  data = insect.data.du.9.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [71, 1] <- "DU9"
table.aic [71, 2] <- "Summer"
table.aic [71, 3] <- "GLMM with Functional Response"
table.aic [71, 4] <- "Beetle1to5, A_Beetle1to5, Beetle1to5*A_Beetle1to5"
table.aic [71, 5] <- "(1 | UniqueID)"
table.aic [71, 6] <- AIC (model.lme.fxn.du9.s.all.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.s.all.1to5, type = 'response'), insect.data.du.9.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [71, 8] <- auc.temp@y.values[[1]]

# 6to9
model.lme.fxn.du9.s.all.6to9 <- glmer (pttype ~ beetle_6to9yo + 
                                                 beetle_6to9yo_E + 
                                                 beetle_6to9yo:beetle_6to9yo_E +
                                                 (1 | uniqueID), 
                                       data = insect.data.du.9.s, 
                                       family = binomial (link = "logit"),
                                       verbose = T,
                                       control = glmerControl (calc.derivs = FALSE, 
                                                               optimizer = "nloptwrap", 
                                                               optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [72, 1] <- "DU9"
table.aic [72, 2] <- "Summer"
table.aic [72, 3] <- "GLMM with Functional Response"
table.aic [72, 4] <- "Beetle6to9, A_Beetle6to9, Beetle6to9*A_Beetle6to9"
table.aic [72, 5] <- "(1 | UniqueID)"
table.aic [72, 6] <- AIC (model.lme.fxn.du9.s.all.6to9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.s.all.6to9, type = 'response'), insect.data.du.9.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [72, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [67, 6] - min (table.aic [67:72, 6])))),
                    (exp (-0.5 * (table.aic [68, 6] - min (table.aic [67:72, 6])))),
                    (exp (-0.5 * (table.aic [69, 6] - min (table.aic [67:72, 6])))),
                    (exp (-0.5 * (table.aic [70, 6] - min (table.aic [67:72, 6])))),
                    (exp (-0.5 * (table.aic [71, 6] - min (table.aic [67:72, 6])))),
                    (exp (-0.5 * (table.aic [72, 6] - min (table.aic [67:72, 6])))))
table.aic [67, 7] <- round ((exp (-0.5 * (table.aic [67, 6] - min (table.aic [67:72, 6])))) / sum (list.aic.like), 3)
table.aic [68, 7] <- round ((exp (-0.5 * (table.aic [68, 6] - min (table.aic [67:72, 6])))) / sum (list.aic.like), 3)
table.aic [69, 7] <- round ((exp (-0.5 * (table.aic [69, 6] - min (table.aic [67:72, 6])))) / sum (list.aic.like), 3)
table.aic [70, 7] <- round ((exp (-0.5 * (table.aic [70, 6] - min (table.aic [67:72, 6])))) / sum (list.aic.like), 3)
table.aic [71, 7] <- round ((exp (-0.5 * (table.aic [71, 6] - min (table.aic [67:72, 6])))) / sum (list.aic.like), 3)
table.aic [72, 7] <- round ((exp (-0.5 * (table.aic [72, 6] - min (table.aic [67:72, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_insect.csv", sep = ",")


