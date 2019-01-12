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
table.glm.summary.insect [78, 5] <- NA
table.glm.summary.insect [78, 6] <- NA
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
table.glm.summary.insect [84, 5] <- NA
table.glm.summary.insect [84, 6] <- NA # p-value
rm (glm.du.7.ew.6yo.s)
gc ()

glm.du.7.ew.7yo.s <- glm (pttype ~ beetle_severe_7yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [85, 1] <- "7"
table.glm.summary.insect  [85, 2] <- "Early Winter"
table.glm.summary.insect  [85, 3] <- "Severe"
table.glm.summary.insect  [85, 4] <- 7
table.glm.summary.insect [85, 5] <- NA
table.glm.summary.insect [85, 6] <- NA
rm (glm.du.7.ew.7yo.s)
gc ()

glm.du.7.ew.8yo.s <- glm (pttype ~ beetle_severe_8yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [86, 1] <- "7"
table.glm.summary.insect  [86, 2] <- "Early Winter"
table.glm.summary.insect  [86, 3] <- "Severe"
table.glm.summary.insect  [86, 4] <- 8
table.glm.summary.insect [86, 5] <- NA
table.glm.summary.insect [86, 6] <- NA
rm (glm.du.7.ew.8yo.s)
gc ()

glm.du.7.ew.9yo.s <- glm (pttype ~ beetle_severe_9yo, 
                          data = beetle.data.du.7.ew,
                          family = binomial (link = 'logit'))
table.glm.summary.insect  [87, 1] <- "7"
table.glm.summary.insect  [87, 2] <- "Early Winter"
table.glm.summary.insect  [87, 3] <- "Severe"
table.glm.summary.insect  [87, 4] <- 8
table.glm.summary.insect [87, 5] <- NA
table.glm.summary.insect [87, 6] <- NA
rm (glm.du.7.ew.9yo.s)
gc ()

glm.du.7.ew.1yo.vs <- glm (pttype ~ beetle_very_severe_1yo, 
                           data = beetle.data.du.7.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [88, 1] <- "7"
table.glm.summary.insect [88, 2] <- "Early Winter"
table.glm.summary.insect [88, 3] <- "Very Severe"
table.glm.summary.insect [88, 4] <- 1
table.glm.summary.insect [88, 5] <- NA
table.glm.summary.insect [88, 6] <- NA
rm (glm.du.7.ew.1yo.vs)
gc ()

glm.du.7.ew.2yo.vs <- glm (pttype ~ beetle_very_severe_2yo, 
                           data = beetle.data.du.7.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [89, 1] <- "7"
table.glm.summary.insect [89, 2] <- "Early Winter"
table.glm.summary.insect [89, 3] <- "Very Severe"
table.glm.summary.insect [89, 4] <- 2
table.glm.summary.insect [89, 5] <- NA
table.glm.summary.insect [89, 6] <- NA
rm (glm.du.7.ew.2yo.vs)
gc ()

glm.du.7.ew.3yo.vs <- glm (pttype ~ beetle_very_severe_3yo, 
                           data = beetle.data.du.7.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [90, 1] <- "7"
table.glm.summary.insect [90, 2] <- "Early Winter"
table.glm.summary.insect [90, 3] <- "Very Severe"
table.glm.summary.insect [90, 4] <- 3
table.glm.summary.insect [90, 5] <- NA
table.glm.summary.insect [90, 6] <- NA
rm (glm.du.7.ew.3yo.vs)
gc ()

glm.du.7.ew.4yo.vs <- glm (pttype ~ beetle_very_severe_4yo, 
                           data = beetle.data.du.7.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [91, 1] <- "7"
table.glm.summary.insect [91, 2] <- "Early Winter"
table.glm.summary.insect [91, 3] <- "Very Severe"
table.glm.summary.insect [91, 4] <- 4
table.glm.summary.insect [91, 5] <- NA
table.glm.summary.insect [91, 6] <- NA
rm (glm.du.7.ew.4yo.vs)
gc ()

glm.du.7.ew.5yo.vs <- glm (pttype ~ beetle_very_severe_5yo, 
                           data = beetle.data.du.7.ew,
                           family = binomial (link = 'logit'))
table.glm.summary.insect [92, 1] <- "7"
table.glm.summary.insect [92, 2] <- "Early Winter"
table.glm.summary.insect [92, 3] <- "Very Severe"
table.glm.summary.insect [92, 4] <- 5
table.glm.summary.insect [92, 5] <- NA
table.glm.summary.insect [92, 6] <- NA
rm (glm.du.7.ew.5yo.vs)
gc ()




## DU7 ###
### Late Winter ###





## DU7 ###
### Summer ###




## DU8 ###
### Early Winter ###




### Late Winter ###





### Summer ###





## DU9 ##
### Early Winter ###





### Late Winter ###





### Summer ###




# save table
table.glm.summary.fire$years <- as.character (table.glm.summary.fire [, 3])
table.glm.summary.fire$years <- as.numeric (table.glm.summary.fire$years)
write.table (table.glm.summary.fire, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_glm_summary_fire.csv", sep = ",")
# table.glm.summary.fire <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_glm_summary_fire.csv")
table.glm.summary.fire$DU <- as.factor (table.glm.summary.fire$DU )

# plot of coefficents
ggplot (data = table.glm.summary.fire, 
        aes (years, Coefficient)) +
  geom_line (aes (group = interaction (DU, Season),
                  colour = DU,
                  linetype = Season)) +
  ggtitle ("Beta coefficient values of burn by year, \n season and caribou designatable unit (DU).") +
  xlab ("Years since burn") + 
  ylab ("Beta coefficient") +
  geom_line (aes (x = years, y = 0), 
             size = 0.5, linetype = "solid", colour = "black") +
  theme (plot.title = element_text(hjust = 0.5),
         axis.text = element_text (size = 10),
         axis.title = element_text (size = 12),
         axis.line.x = element_line (size = 1),
         axis.line.y = element_line (size = 1),
         panel.grid.minor = element_blank (),
         panel.border = element_blank (),
         panel.background = element_blank ()) +
  scale_x_continuous (limits = c (0, 51), breaks = seq (0, 51, by = 5)) +
  scale_y_continuous (limits = c (-15, 15), breaks = seq (-15, 15, by = 3))


table.glm.summary.fire.du6 <- table.glm.summary.fire %>%
  filter (DU == 6)
ggplot (data = table.glm.summary.fire.du6, 
        aes (years, Coefficient)) +
  geom_line (aes (colour = Season)) +
  ggtitle ("Beta coefficient values of burn by year \n and season for caribou designatable unit (DU) 6.") +
  xlab ("Years since burn") + 
  ylab ("Beta coefficient") +
  geom_line (aes (x = years, y = 0), 
             size = 0.5, linetype = "solid", colour = "black") +
  theme (plot.title = element_text(hjust = 0.5),
         axis.text = element_text (size = 10),
         axis.title = element_text (size = 12),
         axis.line.x = element_line (size = 1),
         axis.line.y = element_line (size = 1),
         panel.grid.minor = element_blank (),
         panel.border = element_blank (),
         panel.background = element_blank ()) +
  scale_x_continuous (limits = c (0, 51), breaks = seq (0, 51, by = 5)) +
  scale_y_continuous (limits = c (-10, 10), breaks = seq (-10, 10, by = 2))


table.glm.summary.fire.du7 <- table.glm.summary.fire %>%
  filter (DU == 7)
ggplot (data = table.glm.summary.fire.du7, 
        aes (years, Coefficient)) +
  geom_line (aes (colour = Season)) +
  ggtitle ("Beta coefficient values of burn by year \n and season for caribou designatable unit (DU) 7.") +
  xlab ("Years since burn") + 
  ylab ("Beta coefficient") +
  geom_line (aes (x = years, y = 0), 
             size = 0.5, linetype = "solid", colour = "black") +
  theme (plot.title = element_text(hjust = 0.5),
         axis.text = element_text (size = 10),
         axis.title = element_text (size = 12),
         axis.line.x = element_line (size = 1),
         axis.line.y = element_line (size = 1),
         panel.grid.minor = element_blank (),
         panel.border = element_blank (),
         panel.background = element_blank ()) +
  scale_x_continuous (limits = c (0, 51), breaks = seq (0, 51, by = 5)) +
  scale_y_continuous (limits = c (-12, 12), breaks = seq (-12, 12, by = 2))


table.glm.summary.fire.du8 <- table.glm.summary.fire %>%
  filter (DU == 8)
ggplot (data = table.glm.summary.fire.du8, 
        aes (years, Coefficient)) +
  geom_line (aes (colour = Season)) +
  ggtitle ("Beta coefficient values of burn by year \n and season for caribou designatable unit (DU) 8.") +
  xlab ("Years since burn") + 
  ylab ("Beta coefficient") +
  geom_line (aes (x = years, y = 0), 
             size = 0.5, linetype = "solid", colour = "black") +
  theme (plot.title = element_text(hjust = 0.5),
         axis.text = element_text (size = 10),
         axis.title = element_text (size = 12),
         axis.line.x = element_line (size = 1),
         axis.line.y = element_line (size = 1),
         panel.grid.minor = element_blank (),
         panel.border = element_blank (),
         panel.background = element_blank ()) +
  scale_x_continuous (limits = c (0, 51), breaks = seq (0, 51, by = 5)) +
  scale_y_continuous (limits = c (-10, 10), breaks = seq (-10, 10, by = 2))


table.glm.summary.fire.du9 <- table.glm.summary.fire %>%
  filter (DU == 9)
ggplot (data = table.glm.summary.fire.du9, 
        aes (years, Coefficient)) +
  geom_line (aes (colour = Season)) +
  ggtitle ("Beta coefficient values of burn by year \n and season for caribou designatable unit (DU) 9.") +
  xlab ("Years since burn") + 
  ylab ("Beta coefficient") +
  geom_line (aes (x = years, y = 0), 
             size = 0.5, linetype = "solid", colour = "black") +
  theme (plot.title = element_text(hjust = 0.5),
         axis.text = element_text (size = 10),
         axis.title = element_text (size = 12),
         axis.line.x = element_line (size = 1),
         axis.line.y = element_line (size = 1),
         panel.grid.minor = element_blank (),
         panel.border = element_blank (),
         panel.background = element_blank ()) +
  scale_x_continuous (limits = c (0, 51), breaks = seq (0, 51, by = 5)) +
  scale_y_continuous (limits = c (-14, 0), breaks = seq (-14, 0, by = 2))

#=======================================================================
# re-categorize forestry data and test correlations, beta coeffs again
#=====================================================================
rsf.data.fire <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_fire.csv")

rsf.data.fire <- dplyr::mutate (rsf.data.fire, fire_1to5yo = fire_1yo + fire_2yo + fire_3yo + fire_4yo + fire_5yo)
rsf.data.fire$fire_1to5yo [rsf.data.fire$fire_1to5yo > 1] <- 1

rsf.data.fire <- dplyr::mutate (rsf.data.fire, fire_6to25yo = fire_6yo + fire_7yo + fire_8yo + fire_9yo + fire_10yo + fire_11yo + fire_12yo + fire_13yo + fire_14yo + fire_15yo + fire_16yo + fire_17yo + fire_18yo + fire_19yo + fire_20yo + fire_21yo + fire_22yo + fire_23yo + fire_24yo + fire_25yo)
rsf.data.fire$fire_6to25yo [rsf.data.fire$fire_6to25yo > 1] <- 1

rsf.data.fire <- dplyr::mutate (rsf.data.fire, fire_over25yo = fire_26yo + fire_27yo + fire_28yo + fire_29yo + fire_30yo + fire_31yo + fire_32yo + fire_33yo + fire_34yo + fire_35yo + fire_36yo + fire_37yo + fire_38yo + fire_39yo + fire_40yo + fire_41yo + fire_42yo + fire_43yo + fire_44yo + fire_45yo + fire_46yo + fire_47yo + fire_48yo + fire_49yo + fire_50yo + fire_51yo)
rsf.data.fire$fire_over25yo [rsf.data.fire$fire_over25yo > 1] <- 1

rsf.data.fire.age <-  rsf.data.fire[c (1:9, 71:124)] # fire age class only
# write.table (rsf.data.fire.age, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_fire_age.csv", sep = ",")

# Correlations
fire.corr <- rsf.data.fire.age [c (61:63)]
corr <- round (cor (fire.corr), 3)
p.mat <- round (cor_pmat (fire.corr), 2)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Burn Age Correlation")

#########
## DU6 ## 
#########
fire.corr.du.6 <- rsf.data.fire.age %>%
  dplyr::filter (du == "du6")
fire.corr.du.6 <- fire.corr.du.6 [c (61:63)]
corr.du6 <- round (cor (fire.corr.du.6), 3)
p.mat <- round (cor_pmat (corr.du6), 2)
ggcorrplot (corr.du6, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU6 Burn Age Correlation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_fire_age_corr_class_du6.png")

#########
## DU7 ## 
#########
fire.corr.du.7 <- rsf.data.fire.age %>%
  dplyr::filter (du == "du7")
fire.corr.du.7 <- fire.corr.du.7 [c (61:63)]
corr.du7 <- round (cor (fire.corr.du.7), 3)
p.mat <- round (cor_pmat (corr.du7), 2)
ggcorrplot (corr.du7, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU7 Burn Age Correlation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_fire_age_corr_class_du7.png")

#########
## DU8 ## 
#########
fire.corr.du.8 <- rsf.data.fire.age %>%
  dplyr::filter (du == "du8")
fire.corr.du.8 <- fire.corr.du.8 [c (61:63)]
corr.du8 <- round (cor (fire.corr.du.8), 3)
p.mat <- round (cor_pmat (corr.du8), 2)
ggcorrplot (corr.du8, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU8 Burn Age Correlation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_fire_age_corr_class_du8.png")

#########
## DU9 ## 
#########
fire.corr.du.9 <- rsf.data.fire.age %>%
  dplyr::filter (du == "du9")
fire.corr.du.9 <- fire.corr.du.9 [c (61:63)]
corr.du9 <- round (cor (fire.corr.du.9), 3)
p.mat <- round (cor_pmat (corr.du9), 2)
ggcorrplot (corr.du9, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU9 Burn Age Correlation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_fire_age_corr_class_du9.png")













#=================================================
# Model selection Process by DU and Season 
#================================================
# load data
rsf.data.fire.age <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_fire_age.csv")
fire.data <- rsf.data.fire.age [c (1:9, 61:63)] # fire age class data only

# filter by DU, Season 
fire.data.du.6.ew <- fire.data %>%
  dplyr::filter (du == "du6") %>% 
  dplyr::filter (season == "EarlyWinter")
fire.data.du.6.lw <- fire.data %>%
  dplyr::filter (du == "du6") %>% 
  dplyr::filter (season == "LateWinter")
fire.data.du.6.s <- fire.data %>%
  dplyr::filter (du == "du6") %>% 
  dplyr::filter (season == "Summer")

fire.data.du.7.ew <- fire.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "EarlyWinter")
fire.data.du.7.lw <- fire.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "LateWinter")
fire.data.du.7.s <- fire.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "Summer")

fire.data.du.8.ew <- fire.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "EarlyWinter")
fire.data.du.8.lw <- fire.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "LateWinter")
fire.data.du.8.s <- fire.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "Summer")

fire.data.du.9.ew <- fire.data %>%
  dplyr::filter (du == "du9") %>% 
  dplyr::filter (season == "EarlyWinter")
fire.data.du.9.lw <- fire.data %>%
  dplyr::filter (du == "du9") %>% 
  dplyr::filter (season == "LateWinter")
fire.data.du.9.s <- fire.data %>%
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
corr.fire.du.6.ew <- round (cor (fire.data.du.6.ew [10:12], method = "spearman"), 3)
ggcorrplot (corr.fire.du.6.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Fire Age Correlation DU6 Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_fire_corr_du_6_ew.png")

### CART
cart.du.6.ew <- rpart (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo,
                       data = fire.data.du.6.ew, 
                       method = "class")
summary (cart.du.6.ew)
print (cart.du.6.ew)
plot (cart.du.6.ew, uniform = T)
text (cart.du.6.ew, use.n = T, splits = T, fancy = F)
post (cart.du.6.ew, file = "", uniform = T)
# results indicate no partioning, suggesting no effect of fire

### VIF
model.glm.du6.ew <- glm (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo, 
                         data = fire.data.du.6.ew,
                         family = binomial (link = 'logit'))
vif (model.glm.du6.ew) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du6.ew <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo + 
                             (fire_1to5yo | uniqueID) + 
                             (fire_6to25yo | uniqueID) +
                             (fire_over25yo | uniqueID), 
                           data = fire.data.du.6.ew, 
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
table.aic [1, 4] <- "Burn1to5, Burn6to25, Burnover25"
table.aic [1, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [1, 6] <- AIC (model.lme.du6.ew)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew, type = 'response'), fire.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [1, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du6.ew.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                        (fire_1to5yo | uniqueID), 
                           data = fire.data.du.6.ew, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Early Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "Burn1to5"
table.aic [2, 5] <- "(Burn1to5 | UniqueID)"
table.aic [2, 6] <- AIC (model.lme.du6.ew.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew.1to5, type = 'response'), fire.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [2, 8] <- auc.temp@y.values[[1]]

# 5to25
model.lme.du6.ew.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                  (fire_6to25yo | uniqueID), 
                                data = fire.data.du.6.ew, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Early Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "Burn6to25"
table.aic [3, 5] <- "(Burn6to25 | UniqueID)"
table.aic [3, 6] <- AIC (model.lme.du6.ew.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew.6to25, type = 'response'), fire.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [3, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.du6.ew.over25 <- glmer (pttype ~ fire_over25yo + 
                                   (fire_over25yo | uniqueID), 
                                 data = fire.data.du.6.ew, 
                                 family = binomial (link = "logit"),
                                 verbose = T,
                                 control = glmerControl (calc.derivs = FALSE, 
                                                         optimizer = "nloptwrap", 
                                                         optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [4, 1] <- "DU6"
table.aic [4, 2] <- "Early Winter"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "Burnover25"
table.aic [4, 5] <- "(Burnover25 | UniqueID)"
table.aic [4, 6] <- AIC (model.lme.du6.ew.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew.over25, type = 'response'), fire.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [4, 8] <- auc.temp@y.values[[1]]

# 1to5, 6to25
model.lme.du6.ew.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + 
                                              (fire_1to5yo | uniqueID) +
                                              (fire_6to25yo | uniqueID), 
                                  data = fire.data.du.6.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [5, 1] <- "DU6"
table.aic [5, 2] <- "Early Winter"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "Burn1to5, Burn6to25"
table.aic [5, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID)"
table.aic [5, 6] <- AIC (model.lme.du6.ew.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew.1to5.6to25, type = 'response'), fire.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [5, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.du6.ew.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo + 
                                        (fire_1to5yo | uniqueID) +
                                        (fire_over25yo | uniqueID), 
                                      data = fire.data.du.6.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T,
                                      control = glmerControl (calc.derivs = FALSE, 
                                                              optimizer = "nloptwrap", 
                                                              optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [6, 1] <- "DU6"
table.aic [6, 2] <- "Early Winter"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "Burn1to5, Burnover25"
table.aic [6, 5] <- "(Burn1to5 | UniqueID), (Burnover25 | UniqueID)"
table.aic [6, 6] <- AIC (model.lme.du6.ew.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew.1to5.over25, type = 'response'), fire.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [6, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.du6.ew.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo + 
                                         (fire_6to25yo | uniqueID) +
                                         (fire_over25yo | uniqueID), 
                                       data = fire.data.du.6.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T,
                                       control = glmerControl (calc.derivs = FALSE, 
                                                               optimizer = "nloptwrap", 
                                                               optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [7, 1] <- "DU6"
table.aic [7, 2] <- "Early Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "Burn6to25, Burnover25"
table.aic [7, 5] <- "(Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [7, 6] <- AIC (model.lme.du6.ew.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew.6to25.over25, type = 'response'), fire.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [7, 8] <- auc.temp@y.values[[1]]

# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (fire.data.du.6.ew, pttype == 0)
fire_1to5yo_E <- tapply (sub$fire_1to5yo, sub$uniqueID, sum)
fire_6to25yo_E <- tapply (sub$fire_6to25yo, sub$uniqueID, sum)
fire_over25yo_E <- tapply (sub$fire_over25yo, sub$uniqueID, sum)

inds <- as.character (fire.data.du.6.ew$uniqueID)
fire.data.du.6.ew <- cbind (fire.data.du.6.ew, 
                               "fire_1to5yo_E" = fire_1to5yo_E [inds],
                               "fire_6to25yo_E" = fire_6to25yo_E [inds],
                               "fire_over25yo_E" = fire_over25yo_E [inds])
# Functional Responses
# All COVARS
model.lme.fxn.du6.ew.all <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo +
                                             fire_1to5yo_E + fire_6to25yo_E + fire_over25yo_E + 
                                             fire_1to5yo:fire_1to5yo_E +
                                             fire_6to25yo:fire_6to25yo_E +
                                             fire_over25yo:fire_over25yo_E +
                                             (1 | uniqueID), 
                                  data = fire.data.du.6.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [8, 1] <- "DU6"
table.aic [8, 2] <- "Early Winter"
table.aic [8, 3] <- "GLMM with Functional Response"
table.aic [8, 4] <- "Burn1to5, Burn6to25, Burnover25, A_Burn1to5, A_Burn6to25, A_Burnover25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [8, 5] <- "(1 | UniqueID)"
table.aic [8, 6] <- AIC (model.lme.fxn.du6.ew.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.all, type = 'response'), fire.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [8, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du6.ew.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                              fire_1to5yo_E + 
                                              fire_1to5yo:fire_1to5yo_E +
                                              (1 | uniqueID), 
                                   data = fire.data.du.6.ew, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [9, 1] <- "DU6"
table.aic [9, 2] <- "Early Winter"
table.aic [9, 3] <- "GLMM with Functional Response"
table.aic [9, 4] <- "Burn1to5, A_Burn1to5, Burn1to5*A_Burn1to5"
table.aic [9, 5] <- "(1 | UniqueID)"
table.aic [9, 6] <- AIC (model.lme.fxn.du6.ew.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.1to5, type = 'response'), fire.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [9, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.fxn.du6.ew.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                       fire_6to25yo_E + 
                                       fire_6to25yo:fire_6to25yo_E +
                                      (1 | uniqueID), 
                                    data = fire.data.du.6.ew, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [10, 1] <- "DU6"
table.aic [10, 2] <- "Early Winter"
table.aic [10, 3] <- "GLMM with Functional Response"
table.aic [10, 4] <- "Burn6to25, A_Burn6to25, Burn6to25*A_Burn6to25"
table.aic [10, 5] <- "(1 | UniqueID)"
table.aic [10, 6] <- AIC (model.lme.fxn.du6.ew.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.6to25, type = 'response'), fire.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [10, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.fxn.du6.ew.over25 <- glmer (pttype ~ fire_over25yo + 
                                        fire_over25yo_E + 
                                        fire_over25yo:fire_over25yo_E +
                                       (1 | uniqueID), 
                                     data = fire.data.du.6.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, 
                                                             optimizer = "nloptwrap", 
                                                             optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [11, 1] <- "DU6"
table.aic [11, 2] <- "Early Winter"
table.aic [11, 3] <- "GLMM with Functional Response"
table.aic [11, 4] <- "Burnover25, A_Burnover25, Burnover25*A_Burnover25"
table.aic [11, 5] <- "(1 | UniqueID)"
table.aic [11, 6] <- AIC (model.lme.fxn.du6.ew.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.over25, type = 'response'), fire.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [11, 8] <- auc.temp@y.values[[1]]

# 1to5, 6to25
model.lme.fxn.du6.ew.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + 
                                            fire_1to5yo_E + fire_6to25yo_E + 
                                            fire_1to5yo:fire_1to5yo_E +
                                            fire_6to25yo:fire_6to25yo_E +
                                        (1 | uniqueID), 
                                      data = fire.data.du.6.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T,
                                      control = glmerControl (calc.derivs = FALSE, 
                                                              optimizer = "nloptwrap", 
                                                              optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [12, 1] <- "DU6"
table.aic [12, 2] <- "Early Winter"
table.aic [12, 3] <- "GLMM with Functional Response"
table.aic [12, 4] <- "Burn1to5, Burn6to25, A_Burn1to5, A_Burn6to25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25"
table.aic [12, 5] <- "(1 | UniqueID)"
table.aic [12, 6] <- AIC (model.lme.fxn.du6.ew.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.1to5.6to25, type = 'response'), fire.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [12, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.fxn.du6.ew.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo + 
                                            fire_1to5yo_E + fire_over25yo_E + 
                                            fire_1to5yo:fire_1to5yo_E +
                                             fire_over25yo:fire_over25yo_E +
                                            (1 | uniqueID), 
                                          data = fire.data.du.6.ew, 
                                          family = binomial (link = "logit"),
                                          verbose = T,
                                          control = glmerControl (calc.derivs = FALSE, 
                                                                  optimizer = "nloptwrap", 
                                                                  optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [13, 1] <- "DU6"
table.aic [13, 2] <- "Early Winter"
table.aic [13, 3] <- "GLMM with Functional Response"
table.aic [13, 4] <- "Burn1to5, Burnover25, A_Burn1to5, A_Burnover25, Burn1to5*A_Burn1to5, Burnover25*A_Burnover25"
table.aic [13, 5] <- "(1 | UniqueID)"
table.aic [13, 6] <- AIC (model.lme.fxn.du6.ew.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.1to5.over25, type = 'response'), fire.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [13, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.fxn.du6.ew.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo + 
                                              fire_6to25yo_E + fire_over25yo_E + 
                                              fire_6to25yo:fire_6to25yo_E +
                                             fire_over25yo:fire_over25yo_E +
                                             (1 | uniqueID), 
                                           data = fire.data.du.6.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T,
                                           control = glmerControl (calc.derivs = FALSE, 
                                                                   optimizer = "nloptwrap", 
                                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [14, 1] <- "DU6"
table.aic [14, 2] <- "Early Winter"
table.aic [14, 3] <- "GLMM with Functional Response"
table.aic [14, 4] <- "Burn6to25, Burnover25, A_Burn6to25, A_Burnover25, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [14, 5] <- "(1 | UniqueID)"
table.aic [14, 6] <- AIC (model.lme.fxn.du6.ew.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.6to25.over25, type = 'response'), fire.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [14, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [4, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [5, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [6, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [7, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [8, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [9, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [10, 6] - min (table.aic [1:14, 6])))), 
                    (exp (-0.5 * (table.aic [11, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [12, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [13, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [14, 6] - min (table.aic [1:14, 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [4, 7] <- round ((exp (-0.5 * (table.aic [4, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [5, 7] <- round ((exp (-0.5 * (table.aic [5, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [6, 7] <- round ((exp (-0.5 * (table.aic [6, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [7, 7] <- round ((exp (-0.5 * (table.aic [7, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [8, 7] <- round ((exp (-0.5 * (table.aic [8, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [9, 7] <- round ((exp (-0.5 * (table.aic [9, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [10, 7] <- round ((exp (-0.5 * (table.aic [10, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [11, 7] <- round ((exp (-0.5 * (table.aic [11, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [12, 7] <- round ((exp (-0.5 * (table.aic [12, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [13, 7] <- round ((exp (-0.5 * (table.aic [13, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [14, 7] <- round ((exp (-0.5 * (table.aic [14, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_fire.csv", sep = ",")

# save the top model
save (model.lme.du6.ew, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\fire\\model_lme_fxn_du6_ew_top.rda")



### Late Winter
corr.fire.du.6.lw <- round (cor (fire.data.du.6.lw [10:12], method = "spearman"), 3)
ggcorrplot (corr.fire.du.6.lw, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Fire Age Correlation DU6 Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_fire_corr_du_6_lw.png")

### CART
cart.du.6.lw <- rpart (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo,
                       data = fire.data.du.6.lw, 
                       method = "class")
summary (cart.du.6.lw)
print (cart.du.6.lw)
plot (cart.du.6.lw, uniform = T)
text (cart.du.6.lw, use.n = T, splits = T, fancy = F)
post (cart.du.6.lw, file = "", uniform = T)
# results indicate no partioning, suggesting no effect of fire

### VIF
model.glm.du6.lw <- glm (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo, 
                         data = fire.data.du.6.lw,
                         family = binomial (link = 'logit'))
vif (model.glm.du6.lw) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du6.lw <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo + 
                             (fire_1to5yo | uniqueID) + 
                             (fire_6to25yo | uniqueID) +
                             (fire_over25yo | uniqueID), 
                           data = fire.data.du.6.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5))) 
summary (model.lme.du6.lw)
plot (model.lme.du6.lw) # should be mostly a straight line

# AIC
table.aic [15, 1] <- "DU6"
table.aic [15, 2] <- "Late Winter"
table.aic [15, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [15, 4] <- "Burn1to5, Burn6to25, Burnover25"
table.aic [15, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [15, 6] <- AIC (model.lme.du6.lw)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw, type = 'response'), fire.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [15, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du6.lw.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                        (fire_1to5yo | uniqueID), 
                                 data = fire.data.du.6.lw, 
                                 family = binomial (link = "logit"),
                                 verbose = T,
                                 control = glmerControl (calc.derivs = FALSE,
                                                         optimizer = "nloptwrap",
                                                         optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [16, 1] <- "DU6"
table.aic [16, 2] <- "Late Winter"
table.aic [16, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [16, 4] <- "Burn1to5"
table.aic [16, 5] <- "(Burn1to5 | UniqueID)"
table.aic [16, 6] <- AIC (model.lme.du6.lw.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.1to5, type = 'response'), fire.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [16, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.du6.lw.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                  (fire_6to25yo | uniqueID), 
                                data = fire.data.du.6.lw, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE,
                                                        optimizer = "nloptwrap",
                                                        optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [17, 1] <- "DU6"
table.aic [17, 2] <- "Late Winter"
table.aic [17, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [17, 4] <- "Burn6to25"
table.aic [17, 5] <- "(Burn6to25 | UniqueID)"
table.aic [17, 6] <- AIC (model.lme.du6.lw.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.6to25, type = 'response'), fire.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [17, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.du6.lw.over25 <- glmer (pttype ~ fire_over25yo + 
                                   (fire_over25yo | uniqueID), 
                                 data = fire.data.du.6.lw, 
                                 family = binomial (link = "logit"),
                                 verbose = T,
                                 control = glmerControl (calc.derivs = FALSE,
                                                         optimizer = "nloptwrap",
                                                         optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [18, 1] <- "DU6"
table.aic [18, 2] <- "Late Winter"
table.aic [18, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [18, 4] <- "Burnover25"
table.aic [18, 5] <- "(Burnover25 | UniqueID)"
table.aic [18, 6] <- AIC (model.lme.du6.lw.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.over25, type = 'response'), fire.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [18, 8] <- auc.temp@y.values[[1]]

# 1to5, 6to25
model.lme.du6.lw.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + 
                                               fire_6to25yo +
                                              (fire_1to5yo | uniqueID) +
                                              (fire_6to25yo | uniqueID), 
                                data = fire.data.du.6.lw, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE,
                                                        optimizer = "nloptwrap",
                                                        optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [19, 1] <- "DU6"
table.aic [19, 2] <- "Late Winter"
table.aic [19, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [19, 4] <- "Burn1to5, Burn6to25"
table.aic [19, 5] <- "(Burn1to5 | UniqueID), (Burn6to25| UniqueID)"
table.aic [19, 6] <- AIC (model.lme.du6.lw.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.1to5.6to25, type = 'response'), fire.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [19, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.du6.lw.1to5.over25 <- glmer (pttype ~ fire_1to5yo + 
                                         fire_over25yo +
                                        (fire_1to5yo | uniqueID) +
                                        (fire_over25yo | uniqueID), 
                                      data = fire.data.du.6.lw, 
                                      family = binomial (link = "logit"),
                                      verbose = T,
                                      control = glmerControl (calc.derivs = FALSE,
                                                              optimizer = "nloptwrap",
                                                              optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [20, 1] <- "DU6"
table.aic [20, 2] <- "Late Winter"
table.aic [20, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [20, 4] <- "Burn1to5, Burnover25"
table.aic [20, 5] <- "(Burn1to5 | UniqueID), (Burnover25| UniqueID)"
table.aic [20, 6] <- AIC (model.lme.du6.lw.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.1to5.over25, type = 'response'), fire.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [20, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.du6.lw.6to25.over25 <- glmer (pttype ~ fire_6to25yo + 
                                         fire_over25yo +
                                         (fire_6to25yo | uniqueID) +
                                         (fire_over25yo | uniqueID), 
                                       data = fire.data.du.6.lw, 
                                       family = binomial (link = "logit"),
                                       verbose = T,
                                       control = glmerControl (calc.derivs = FALSE,
                                                               optimizer = "nloptwrap",
                                                               optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [21, 1] <- "DU6"
table.aic [21, 2] <- "Late Winter"
table.aic [21, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [21, 4] <- "Burn6to25, Burnover25"
table.aic [21, 5] <- "(Burn6to25 | UniqueID), (Burnover25| UniqueID)"
table.aic [21, 6] <- AIC (model.lme.du6.lw.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.6to25.over25, type = 'response'), fire.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [21, 8] <- auc.temp@y.values[[1]]

# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (fire.data.du.6.lw, pttype == 0)
fire_1to5yo_E <- tapply (sub$fire_1to5yo, sub$uniqueID, sum)
fire_6to25yo_E <- tapply (sub$fire_6to25yo, sub$uniqueID, sum)
fire_over25yo_E <- tapply (sub$fire_over25yo, sub$uniqueID, sum)
inds <- as.character (fire.data.du.6.lw$uniqueID)
fire.data.du.6.lw <- cbind (fire.data.du.6.lw, 
                            "fire_1to5yo_E" = fire_1to5yo_E [inds],
                            "fire_6to25yo_E" = fire_6to25yo_E [inds],
                            "fire_over25yo_E" = fire_over25yo_E [inds])
# Functional Responses
# All COVARS
model.lme.fxn.du6.lw.all <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo +
                                     fire_1to5yo_E + fire_6to25yo_E + fire_over25yo_E + 
                                     fire_1to5yo:fire_1to5yo_E +
                                     fire_6to25yo:fire_6to25yo_E +
                                     fire_over25yo:fire_over25yo_E +
                                     (1 | uniqueID), 
                                   data = fire.data.du.6.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [22, 1] <- "DU6"
table.aic [22, 2] <- "Late Winter"
table.aic [22, 3] <- "GLMM with Functional Response"
table.aic [22, 4] <- "Burn1to5, Burn6to25, Burnover25, A_Burn1to5, A_Burn6to25, A_Burnover25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [22, 5] <- "(1 | UniqueID)"
table.aic [22, 6] <- AIC (model.lme.fxn.du6.lw.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.all, type = 'response', newdata = fire.data.du.6.lw, allow.new.levels = TRUE), fire.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [22, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du6.lw.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                              fire_1to5yo_E + 
                                              fire_1to5yo:fire_1to5yo_E +
                                              (1 | uniqueID), 
                                   data = fire.data.du.6.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [23, 1] <- "DU6"
table.aic [23, 2] <- "Late Winter"
table.aic [23, 3] <- "GLMM with Functional Response"
table.aic [23, 4] <- "Burn1to5, A_Burn1to5, Burn1to5*A_Burn1to5"
table.aic [23, 5] <- "(1 | UniqueID)"
table.aic [23, 6] <- AIC (model.lme.fxn.du6.lw.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.1to5, type = 'response', newdata = fire.data.du.6.lw, allow.new.levels = TRUE), fire.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [23, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.fxn.du6.lw.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                       fire_6to25yo_E + 
                                       fire_6to25yo:fire_6to25yo_E +
                                      (1 | uniqueID), 
                                    data = fire.data.du.6.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap",
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [24, 1] <- "DU6"
table.aic [24, 2] <- "Late Winter"
table.aic [24, 3] <- "GLMM with Functional Response"
table.aic [24, 4] <- "Burn6to25, A_Burn6to25, Burn6to25*A_Burn6to25"
table.aic [24, 5] <- "(1 | UniqueID)"
table.aic [24, 6] <- AIC (model.lme.fxn.du6.lw.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.6to25, type = 'response', newdata = fire.data.du.6.lw, allow.new.levels = TRUE), fire.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [24, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.fxn.du6.lw.over25 <- glmer (pttype ~ fire_over25yo + 
                                        fire_over25yo_E + 
                                        fire_over25yo:fire_over25yo_E +
                                       (1 | uniqueID), 
                                     data = fire.data.du.6.lw, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, 
                                                             optimizer = "nloptwrap", 
                                                             optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [25, 1] <- "DU6"
table.aic [25, 2] <- "Late Winter"
table.aic [25, 3] <- "GLMM with Functional Response"
table.aic [25, 4] <- "Burnover25, A_Burnover25, Burnover25*A_Burnover25"
table.aic [25, 5] <- "(1 | UniqueID)"
table.aic [25, 6] <- AIC (model.lme.fxn.du6.lw.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.over25, type = 'response', newdata = fire.data.du.6.lw, allow.new.levels = TRUE), fire.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [25, 8] <- auc.temp@y.values[[1]]

# 1to5, 6to25
model.lme.fxn.du6.lw.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + 
                                                   fire_1to5yo_E + fire_6to25yo_E + 
                                                   fire_1to5yo:fire_1to5yo_E +
                                                   fire_6to25yo:fire_6to25yo_E +
                                                   (1 | uniqueID), 
                                      data = fire.data.du.6.lw, 
                                      family = binomial (link = "logit"),
                                      verbose = T,
                                      control = glmerControl (calc.derivs = FALSE, 
                                                              optimizer = "nloptwrap", 
                                                              optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [26, 1] <- "DU6"
table.aic [26, 2] <- "Late Winter"
table.aic [26, 3] <- "GLMM with Functional Response"
table.aic [26, 4] <- "Burn1to5, Burn6to25, A_Burn1to5, A_Burn6to25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25"
table.aic [26, 5] <- "(1 | UniqueID)"
table.aic [26, 6] <- AIC (model.lme.fxn.du6.lw.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.1to5.6to25, type = 'response', newdata = fire.data.du.6.lw, allow.new.levels = TRUE), fire.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [26, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.fxn.du6.lw.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo + 
                                                    fire_1to5yo_E + fire_over25yo_E + 
                                                    fire_1to5yo:fire_1to5yo_E +
                                                    fire_over25yo:fire_over25yo_E +
                                                    (1 | uniqueID), 
                                          data = fire.data.du.6.lw, 
                                          family = binomial (link = "logit"),
                                          verbose = T,
                                          control = glmerControl (calc.derivs = FALSE, 
                                                                  optimizer = "nloptwrap", 
                                                                  optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [27, 1] <- "DU6"
table.aic [27, 2] <- "Late Winter"
table.aic [27, 3] <- "GLMM with Functional Response"
table.aic [27, 4] <- "Burn1to5, Burnover25, A_Burn1to5, A_Burnover25, Burn1to5*A_Burn1to5, Burnover25*A_Burnover25"
table.aic [27, 5] <- "(1 | UniqueID)"
table.aic [27, 6] <- AIC (model.lme.fxn.du6.lw.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.1to5.over25, type = 'response', newdata = fire.data.du.6.lw, allow.new.levels = TRUE), fire.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [27, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.fxn.du6.lw.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo + 
                                                     fire_6to25yo_E + fire_over25yo_E + 
                                                     fire_6to25yo:fire_6to25yo_E +
                                                     fire_over25yo:fire_over25yo_E +
                                                    (1 | uniqueID), 
                                           data = fire.data.du.6.lw, 
                                           family = binomial (link = "logit"),
                                           verbose = T,
                                           control = glmerControl (calc.derivs = FALSE, 
                                                                   optimizer = "nloptwrap", 
                                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [28, 1] <- "DU6"
table.aic [28, 2] <- "Late Winter"
table.aic [28, 3] <- "GLMM with Functional Response"
table.aic [28, 4] <- "Burn6to25, Burnover25, A_Burn6to25, A_Burnover25, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [28, 5] <- "(1 | UniqueID)"
table.aic [28, 6] <- AIC (model.lme.fxn.du6.lw.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.6to25.over25, type = 'response', newdata = fire.data.du.6.lw, allow.new.levels = TRUE), fire.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [28, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [15, 6] - min (table.aic [15:28, 6])))), 
                    (exp (-0.5 * (table.aic [16, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [17, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [18, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [19, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [20, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [21, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [22, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [23, 6] - min (table.aic [15:28, 6])))), 
                    (exp (-0.5 * (table.aic [24, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [25, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [26, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [27, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [28, 6] - min (table.aic [15:28, 6])))))
table.aic [15, 7] <- round ((exp (-0.5 * (table.aic [15, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [16, 7] <- round ((exp (-0.5 * (table.aic [16, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [17, 7] <- round ((exp (-0.5 * (table.aic [17, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [18, 7] <- round ((exp (-0.5 * (table.aic [18, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [19, 7] <- round ((exp (-0.5 * (table.aic [19, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [20, 7] <- round ((exp (-0.5 * (table.aic [20, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [21, 7] <- round ((exp (-0.5 * (table.aic [21, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [22, 7] <- round ((exp (-0.5 * (table.aic [22, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [23, 7] <- round ((exp (-0.5 * (table.aic [23, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [24, 7] <- round ((exp (-0.5 * (table.aic [24, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [25, 7] <- round ((exp (-0.5 * (table.aic [25, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [26, 7] <- round ((exp (-0.5 * (table.aic [26, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [27, 7] <- round ((exp (-0.5 * (table.aic [27, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [28, 7] <- round ((exp (-0.5 * (table.aic [28, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_fire.csv", sep = ",")

# save the top model
save (model.lme.du6.lw, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\fire\\model_lme_du6_lw_top.rda")



### Summer
corr.fire.du.6.s <- round (cor (fire.data.du.6.s [10:12], method = "spearman"), 3)
ggcorrplot (corr.fire.du.6.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Fire Age Correlation DU6 Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_fire_corr_du_6_s.png")

### CART
cart.du.6.s <- rpart (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo,
                       data = fire.data.du.6.s, 
                       method = "class")
summary (cart.du.6.s)
print (cart.du.6.s)
plot (cart.du.6.s, uniform = T)
text (cart.du.6.s, use.n = T, splits = T, fancy = F)
post (cart.du.6.s, file = "", uniform = T)
# results indicate no partioning, suggesting no effect of fire

### VIF
model.glm.du6.s <- glm (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo, 
                         data = fire.data.du.6.s,
                         family = binomial (link = 'logit'))
vif (model.glm.du6.s) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du6.s <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo + 
                             (fire_1to5yo | uniqueID) + 
                             (fire_6to25yo | uniqueID) +
                             (fire_over25yo | uniqueID), 
                           data = fire.data.du.6.s, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5))) 

# AIC
table.aic [29, 1] <- "DU6"
table.aic [29, 2] <- "Summer"
table.aic [29, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [29, 4] <- "Burn1to5, Burn6to25, Burnover25"
table.aic [29, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [29, 6] <- AIC (model.lme.du6.s)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.s, type = 'response'), fire.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [29, 8] <- auc.temp@y.values[[1]]


# 1to5
model.lme.du6.s.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                  (fire_1to5yo | uniqueID), 
                          data = fire.data.du.6.s, 
                          family = binomial (link = "logit"),
                          verbose = T,
                          control = glmerControl (calc.derivs = FALSE, 
                                                  optimizer = "nloptwrap", 
                                                  optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [30, 1] <- "DU6"
table.aic [30, 2] <- "Summer"
table.aic [30, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [30, 4] <- "Burn1to5"
table.aic [30, 5] <- "(Burn1to5 | UniqueID)"
table.aic [30, 6] <- AIC (model.lme.du6.s.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.s.1to5, type = 'response'), fire.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [30, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.du6.s.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                 (fire_6to25yo | uniqueID), 
                               data = fire.data.du.6.s, 
                               family = binomial (link = "logit"),
                               verbose = T,
                               control = glmerControl (calc.derivs = FALSE, 
                                                       optimizer = "nloptwrap", 
                                                       optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [31, 1] <- "DU6"
table.aic [31, 2] <- "Summer"
table.aic [31, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [31, 4] <- "Burn6to25"
table.aic [31, 5] <- "(Burn6to25 | UniqueID)"
table.aic [31, 6] <- AIC (model.lme.du6.s.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.s.6to25, type = 'response'), fire.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [31, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.du6.s.over25 <- glmer (pttype ~ fire_over25yo + 
                                          (fire_over25yo | uniqueID), 
                                data = fire.data.du.6.s, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [32, 1] <- "DU6"
table.aic [32, 2] <- "Summer"
table.aic [32, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [32, 4] <- "Burnover25"
table.aic [32, 5] <- "(Burnover25 | UniqueID)"
table.aic [32, 6] <- AIC (model.lme.du6.s.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.s.over25, type = 'response'), fire.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [32, 8] <- auc.temp@y.values[[1]]



# 1to5, 6to25
model.lme.du6.s.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + 
                                             (fire_1to5yo | uniqueID) + 
                                             (fire_6to25yo | uniqueID), 
                                 data = fire.data.du.6.s, 
                                 family = binomial (link = "logit"),
                                 verbose = T,
                                 control = glmerControl (calc.derivs = FALSE, 
                                                         optimizer = "nloptwrap", 
                                                         optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [33, 1] <- "DU6"
table.aic [33, 2] <- "Summer"
table.aic [33, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [33, 4] <- "Burn1to5, Burn6to25"
table.aic [33, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID)"
table.aic [33, 6] <- AIC (model.lme.du6.s.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.s.1to5.6to25, type = 'response'), fire.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [33, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.du6.s.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo + 
                                       (fire_1to5yo | uniqueID) + 
                                       (fire_over25yo | uniqueID), 
                                     data = fire.data.du.6.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, 
                                                             optimizer = "nloptwrap", 
                                                             optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [34, 1] <- "DU6"
table.aic [34, 2] <- "Summer"
table.aic [34, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [34, 4] <- "Burn1to5, Burnover25"
table.aic [34, 5] <- "(Burn1to5 | UniqueID), (Burnover25 | UniqueID)"
table.aic [34, 6] <- AIC (model.lme.du6.s.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.s.1to5.over25, type = 'response'), fire.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [34, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.du6.s.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo + 
                                                (fire_6to25yo | uniqueID) + 
                                                (fire_over25yo | uniqueID), 
                                      data = fire.data.du.6.s, 
                                      family = binomial (link = "logit"),
                                      verbose = T,
                                      control = glmerControl (calc.derivs = FALSE, 
                                                              optimizer = "nloptwrap", 
                                                              optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [35, 1] <- "DU6"
table.aic [35, 2] <- "Summer"
table.aic [35, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [35, 4] <- "Burn6to25, Burnover25"
table.aic [35, 5] <- "(Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [35, 6] <- AIC (model.lme.du6.s.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.s.6to25.over25, type = 'response'), fire.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [35, 8] <- auc.temp@y.values[[1]]

# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (fire.data.du.6.s, pttype == 0)
fire_1to5yo_E <- tapply (sub$fire_1to5yo, sub$uniqueID, sum)
fire_6to25yo_E <- tapply (sub$fire_6to25yo, sub$uniqueID, sum)
fire_over25yo_E <- tapply (sub$fire_over25yo, sub$uniqueID, sum)
inds <- as.character (fire.data.du.6.s$uniqueID)
fire.data.du.6.s <- cbind (fire.data.du.6.s, 
                            "fire_1to5yo_E" = fire_1to5yo_E [inds],
                            "fire_6to25yo_E" = fire_6to25yo_E [inds],
                            "fire_over25yo_E" = fire_over25yo_E [inds])
# Functional Responses
# All COVARS
model.lme.fxn.du6.s.all <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo +
                                     fire_1to5yo_E + fire_6to25yo_E + fire_over25yo_E + 
                                     fire_1to5yo:fire_1to5yo_E +
                                     fire_6to25yo:fire_6to25yo_E +
                                     fire_over25yo:fire_over25yo_E +
                                     (1 | uniqueID), 
                                   data = fire.data.du.6.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [36, 1] <- "DU6"
table.aic [36, 2] <- "Summer"
table.aic [36, 3] <- "GLMM with Functional Response"
table.aic [36, 4] <- "Burn1to5, Burn6to25, Burnover25, A_Burn1to5, A_Burn6to25, A_Burnover25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [36, 5] <- "(1 | UniqueID)"
table.aic [36, 6] <- AIC (model.lme.fxn.du6.s.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.s.all, type = 'response'), fire.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [36, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du6.s.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                            fire_1to5yo_E + 
                                            fire_1to5yo:fire_1to5yo_E +
                                            (1 | uniqueID), 
                                  data = fire.data.du.6.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [37, 1] <- "DU6"
table.aic [37, 2] <- "Summer"
table.aic [37, 3] <- "GLMM with Functional Response"
table.aic [37, 4] <- "Burn1to5, A_Burn1to5, Burn1to5*A_Burn1to5"
table.aic [37, 5] <- "(1 | UniqueID)"
table.aic [37, 6] <- AIC (model.lme.fxn.du6.s.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.s.1to5, type = 'response'), fire.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [37, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.fxn.du6.s.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                              fire_6to25yo_E + 
                                              fire_6to25yo:fire_6to25yo_E +
                                     (1 | uniqueID), 
                                   data = fire.data.du.6.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [38, 1] <- "DU6"
table.aic [38, 2] <- "Summer"
table.aic [38, 3] <- "GLMM with Functional Response"
table.aic [38, 4] <- "Burn6to25, A_Burn6to25, Burn6to25*A_Burn6to25"
table.aic [38, 5] <- "(1 | UniqueID)"
table.aic [38, 6] <- AIC (model.lme.fxn.du6.s.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.s.6to25, type = 'response'), fire.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [38, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.fxn.du6.s.over25 <- glmer (pttype ~ fire_over25yo + 
                                               fire_over25yo_E + 
                                               fire_over25yo:fire_over25yo_E +
                                      (1 | uniqueID), 
                                    data = fire.data.du.6.s, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [39, 1] <- "DU6"
table.aic [39, 2] <- "Summer"
table.aic [39, 3] <- "GLMM with Functional Response"
table.aic [39, 4] <- "Burnover25, A_Burnover25, Burnover25*A_Burnover25"
table.aic [39, 5] <- "(1 | UniqueID)"
table.aic [39, 6] <- AIC (model.lme.fxn.du6.s.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.s.over25, type = 'response'), fire.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [39, 8] <- auc.temp@y.values[[1]]

#1to5, 6to25
model.lme.fxn.du6.s.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + 
                                                  fire_1to5yo_E + fire_6to25yo_E + 
                                                   fire_1to5yo:fire_1to5yo_E +
                                                   fire_6to25yo:fire_6to25yo_E +
                                                  (1 | uniqueID), 
                                     data = fire.data.du.6.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, 
                                                             optimizer = "nloptwrap", 
                                                             optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [40, 1] <- "DU6"
table.aic [40, 2] <- "Summer"
table.aic [40, 3] <- "GLMM with Functional Response"
table.aic [40, 4] <- "Burn1to5, Burn6to25, A_Burn1to5, A_Burn6to25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25"
table.aic [40, 5] <- "(1 | UniqueID)"
table.aic [40, 6] <- AIC (model.lme.fxn.du6.s.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.s.1to5.6to25, type = 'response'), fire.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [40, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.fxn.du6.s.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo + 
                                           fire_1to5yo_E + fire_over25yo_E + 
                                            fire_1to5yo:fire_1to5yo_E +
                                           fire_over25yo:fire_over25yo_E +
                                           (1 | uniqueID), 
                                         data = fire.data.du.6.s, 
                                         family = binomial (link = "logit"),
                                         verbose = T,
                                         control = glmerControl (calc.derivs = FALSE, 
                                                                 optimizer = "nloptwrap", 
                                                                 optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [41, 1] <- "DU6"
table.aic [41, 2] <- "Summer"
table.aic [41, 3] <- "GLMM with Functional Response"
table.aic [41, 4] <- "Burn1to5, Burnover25, A_Burn1to5, A_Burnover25, Burn1to5*A_Burn1to5, Burnover25*A_Burnover25"
table.aic [41, 5] <- "(1 | UniqueID)"
table.aic [41, 6] <- AIC (model.lme.fxn.du6.s.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.s.1to5.over25, type = 'response'), fire.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [41, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.fxn.du6.s.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo + 
                                                    fire_6to25yo_E + fire_over25yo_E + 
                                                    fire_6to25yo:fire_6to25yo_E +
                                                    fire_over25yo:fire_over25yo_E +
                                                    (1 | uniqueID), 
                                          data = fire.data.du.6.s, 
                                          family = binomial (link = "logit"),
                                          verbose = T,
                                          control = glmerControl (calc.derivs = FALSE, 
                                                                  optimizer = "nloptwrap", 
                                                                  optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [42, 1] <- "DU6"
table.aic [42, 2] <- "Summer"
table.aic [42, 3] <- "GLMM with Functional Response"
table.aic [42, 4] <- "Burn6to25, Burnover25, A_Burn6to25, A_Burnover25, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [42, 5] <- "(1 | UniqueID)"
table.aic [42, 6] <- AIC (model.lme.fxn.du6.s.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.s.6to25.over25, type = 'response'), fire.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [42, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [29, 6] - min (table.aic [29:42, 6])))), 
                    (exp (-0.5 * (table.aic [30, 6] - min (table.aic [29:42, 6])))),
                    (exp (-0.5 * (table.aic [31, 6] - min (table.aic [29:42, 6])))),
                    (exp (-0.5 * (table.aic [32, 6] - min (table.aic [29:42, 6])))),
                    (exp (-0.5 * (table.aic [33, 6] - min (table.aic [29:42, 6])))),
                    (exp (-0.5 * (table.aic [34, 6] - min (table.aic [29:42, 6])))),
                    (exp (-0.5 * (table.aic [35, 6] - min (table.aic [29:42, 6])))),
                    (exp (-0.5 * (table.aic [36, 6] - min (table.aic [29:42, 6])))),
                    (exp (-0.5 * (table.aic [37, 6] - min (table.aic [29:42, 6])))), 
                    (exp (-0.5 * (table.aic [38, 6] - min (table.aic [29:42, 6])))),
                    (exp (-0.5 * (table.aic [39, 6] - min (table.aic [29:42, 6])))),
                    (exp (-0.5 * (table.aic [40, 6] - min (table.aic [29:42, 6])))),
                    (exp (-0.5 * (table.aic [41, 6] - min (table.aic [29:42, 6])))),
                    (exp (-0.5 * (table.aic [42, 6] - min (table.aic [29:42, 6])))))
table.aic [29, 7] <- round ((exp (-0.5 * (table.aic [29, 6] - min (table.aic [29:42, 6])))) / sum (list.aic.like), 3)
table.aic [30, 7] <- round ((exp (-0.5 * (table.aic [30, 6] - min (table.aic [29:42, 6])))) / sum (list.aic.like), 3)
table.aic [31, 7] <- round ((exp (-0.5 * (table.aic [31, 6] - min (table.aic [29:42, 6])))) / sum (list.aic.like), 3)
table.aic [32, 7] <- round ((exp (-0.5 * (table.aic [32, 6] - min (table.aic [29:42, 6])))) / sum (list.aic.like), 3)
table.aic [33, 7] <- round ((exp (-0.5 * (table.aic [33, 6] - min (table.aic [29:42, 6])))) / sum (list.aic.like), 3)
table.aic [34, 7] <- round ((exp (-0.5 * (table.aic [34, 6] - min (table.aic [29:42, 6])))) / sum (list.aic.like), 3)
table.aic [35, 7] <- round ((exp (-0.5 * (table.aic [35, 6] - min (table.aic [29:42, 6])))) / sum (list.aic.like), 3)
table.aic [36, 7] <- round ((exp (-0.5 * (table.aic [36, 6] - min (table.aic [29:42, 6])))) / sum (list.aic.like), 3)
table.aic [37, 7] <- round ((exp (-0.5 * (table.aic [37, 6] - min (table.aic [29:42, 6])))) / sum (list.aic.like), 3)
table.aic [38, 7] <- round ((exp (-0.5 * (table.aic [38, 6] - min (table.aic [29:42, 6])))) / sum (list.aic.like), 3)
table.aic [39, 7] <- round ((exp (-0.5 * (table.aic [39, 6] - min (table.aic [29:42, 6])))) / sum (list.aic.like), 3)
table.aic [40, 7] <- round ((exp (-0.5 * (table.aic [40, 6] - min (table.aic [29:42, 6])))) / sum (list.aic.like), 3)
table.aic [41, 7] <- round ((exp (-0.5 * (table.aic [41, 6] - min (table.aic [29:42, 6])))) / sum (list.aic.like), 3)
table.aic [42, 7] <- round ((exp (-0.5 * (table.aic [42, 6] - min (table.aic [29:42, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_fire.csv", sep = ",")

# save the top model
save (model.lme.du6.s, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\fire\\model_lme_du6_s_top.rda")



#===============
## DU7 ##
#==============
## Early Winter
### Correlation
corr.fire.du.7.ew <- round (cor (fire.data.du.7.ew [10:12], method = "spearman"), 3)
ggcorrplot (corr.fire.du.7.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Fire Age Correlation DU7 Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_fire_corr_du_7_ew.png")

### VIF
model.glm.du7.ew <- glm (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo, 
                         data = fire.data.du.7.ew,
                         family = binomial (link = 'logit'))
vif (model.glm.du7.ew) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du7.ew <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo + 
                             (fire_1to5yo | uniqueID) + 
                             (fire_6to25yo | uniqueID) +
                             (fire_over25yo | uniqueID), 
                           data = fire.data.du.7.ew, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [43, 1] <- "DU7"
table.aic [43, 2] <- "Early Winter"
table.aic [43, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [43, 4] <- "Burn1to5, Burn6to25, Burnover25"
table.aic [43, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [43, 6] <- AIC (model.lme.du7.ew)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.ew, type = 'response'), fire.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [43, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du7.ew.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                        (fire_1to5yo | uniqueID), 
                           data = fire.data.du.7.ew, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5))) 

# AIC
table.aic [44, 1] <- "DU7"
table.aic [44, 2] <- "Early Winter"
table.aic [44, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [44, 4] <- "Burn1to5"
table.aic [44, 5] <- "(Burn1to5 | UniqueID)"
table.aic [44, 6] <- AIC (model.lme.du7.ew.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.ew.1to5, type = 'response'), fire.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [44, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.du7.ew.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                  (fire_6to25yo | uniqueID), 
                                data = fire.data.du.7.ew, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5))) 

# AIC
table.aic [45, 1] <- "DU7"
table.aic [45, 2] <- "Early Winter"
table.aic [45, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [45, 4] <- "Burn6to25"
table.aic [45, 5] <- "(Burn6to25 | UniqueID)"
table.aic [45, 6] <- AIC (model.lme.du7.ew.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.ew.6to25, type = 'response'), fire.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [45, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.du7.ew.over25 <- glmer (pttype ~ fire_over25yo + 
                                          (fire_over25yo | uniqueID), 
                                 data = fire.data.du.7.ew, 
                                 family = binomial (link = "logit"),
                                 verbose = T,
                                 control = glmerControl (calc.derivs = FALSE, 
                                                         optimizer = "nloptwrap", 
                                                         optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [46, 1] <- "DU7"
table.aic [46, 2] <- "Early Winter"
table.aic [46, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [46, 4] <- "Burnover25"
table.aic [46, 5] <- "(Burnover25 | UniqueID)"
table.aic [46, 6] <- AIC (model.lme.du7.ew.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.ew.over25, type = 'response'), fire.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [46, 8] <- auc.temp@y.values[[1]]

# 1to5, 6to25
model.lme.du7.ew.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo +
                                                (fire_1to5yo | uniqueID) +
                                                (fire_6to25yo | uniqueID), 
                                data = fire.data.du.7.ew, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5))) 

# AIC
table.aic [47, 1] <- "DU7"
table.aic [47, 2] <- "Early Winter"
table.aic [47, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [47, 4] <- "Burn1to5, Burn6to25"
table.aic [47, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID)"
table.aic [47, 6] <- AIC (model.lme.du7.ew.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.ew.1to5.6to25, type = 'response'), fire.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [47, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.du7.ew.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo +
                                        (fire_1to5yo | uniqueID) +
                                        (fire_over25yo | uniqueID), 
                                      data = fire.data.du.7.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T,
                                      control = glmerControl (calc.derivs = FALSE, 
                                                              optimizer = "nloptwrap", 
                                                              optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [48, 1] <- "DU7"
table.aic [48, 2] <- "Early Winter"
table.aic [48, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [48, 4] <- "Burn1to5, Burnover25"
table.aic [48, 5] <- "(Burn1to5 | UniqueID), (Burnover25 | UniqueID)"
table.aic [48, 6] <- AIC (model.lme.du7.ew.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.ew.1to5.over25, type = 'response'), fire.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [48, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.du7.ew.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo +
                                                 (fire_6to25yo | uniqueID) +
                                                 (fire_over25yo | uniqueID), 
                                       data = fire.data.du.7.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T,
                                       control = glmerControl (calc.derivs = FALSE, 
                                                               optimizer = "nloptwrap", 
                                                               optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [49, 1] <- "DU7"
table.aic [49, 2] <- "Early Winter"
table.aic [49, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [49, 4] <- "Burn6to25, Burnover25"
table.aic [49, 5] <- "(Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [49, 6] <- AIC (model.lme.du7.ew.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.ew.6to25.over25, type = 'response'), fire.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [49, 8] <- auc.temp@y.values[[1]]


# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (fire.data.du.7.ew, pttype == 0)
fire_1to5yo_E <- tapply (sub$fire_1to5yo, sub$uniqueID, sum)
fire_6to25yo_E <- tapply (sub$fire_6to25yo, sub$uniqueID, sum)
fire_over25yo_E <- tapply (sub$fire_over25yo, sub$uniqueID, sum)
inds <- as.character (fire.data.du.7.ew$uniqueID)
fire.data.du.7.ew <- cbind (fire.data.du.7.ew, 
                           "fire_1to5yo_E" = fire_1to5yo_E [inds],
                           "fire_6to25yo_E" = fire_6to25yo_E [inds],
                           "fire_over25yo_E" = fire_over25yo_E [inds])

# Functional Responses
# All COVARS
model.lme.fxn.du7.ew.all <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo +
                                    fire_1to5yo_E + fire_6to25yo_E + fire_over25yo_E + 
                                    fire_1to5yo:fire_1to5yo_E +
                                    fire_6to25yo:fire_6to25yo_E +
                                    fire_over25yo:fire_over25yo_E +
                                    (1 | uniqueID), 
                                  data = fire.data.du.7.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [50, 1] <- "DU7"
table.aic [50, 2] <- "Early Winter"
table.aic [50, 3] <- "GLMM with Functional Response"
table.aic [50, 4] <- "Burn1to5, Burn6to25, Burnover25, A_Burn1to5, A_Burn6to25, A_Burnover25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [50, 5] <- "(1 | UniqueID)"
table.aic [50, 6] <- AIC (model.lme.fxn.du7.ew.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.ew.all, type = 'response'), fire.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [50, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du7.ew.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                             fire_1to5yo_E + 
                                             fire_1to5yo:fire_1to5yo_E +
                                             (1 | uniqueID), 
                                  data = fire.data.du.7.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [51, 1] <- "DU7"
table.aic [51, 2] <- "Early Winter"
table.aic [51, 3] <- "GLMM with Functional Response"
table.aic [51, 4] <- "Burn1to5, A_Burn1to5, Burn1to5*A_Burn1to5"
table.aic [51, 5] <- "(1 | UniqueID)"
table.aic [51, 6] <- AIC (model.lme.fxn.du7.ew.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.ew.1to5, type = 'response'), fire.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [51, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.fxn.du7.ew.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                               fire_6to25yo_E + 
                                               fire_6to25yo:fire_6to25yo_E +
                                               (1 | uniqueID), 
                                    data = fire.data.du.7.ew, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [52, 1] <- "DU7"
table.aic [52, 2] <- "Early Winter"
table.aic [52, 3] <- "GLMM with Functional Response"
table.aic [52, 4] <- "Burn6to25, A_Burn6to25, Burn6to25*A_Burn6to25"
table.aic [52, 5] <- "(1 | UniqueID)"
table.aic [52, 6] <- AIC (model.lme.fxn.du7.ew.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.ew.6to25, type = 'response'), fire.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [52, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.fxn.du7.ew.over25 <- glmer (pttype ~ fire_over25yo + 
                                                fire_over25yo_E + 
                                                fire_over25yo:fire_over25yo_E +
                                                (1 | uniqueID), 
                                     data = fire.data.du.7.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, 
                                                             optimizer = "nloptwrap", 
                                                             optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [53, 1] <- "DU7"
table.aic [53, 2] <- "Early Winter"
table.aic [53, 3] <- "GLMM with Functional Response"
table.aic [53, 4] <- "Burnover25, A_Burnover25, Burnover25*A_Burnover25"
table.aic [53, 5] <- "(1 | UniqueID)"
table.aic [53, 6] <- AIC (model.lme.fxn.du7.ew.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.ew.over25, type = 'response'), fire.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [53, 8] <- auc.temp@y.values[[1]]

# 1to5, 6to25
model.lme.fxn.du7.ew.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + 
                                                   fire_1to5yo_E + fire_6to25yo_E + 
                                                    fire_1to5yo:fire_1to5yo_E +
                                                    fire_6to25yo:fire_6to25yo_E +
                                                    (1 | uniqueID), 
                                      data = fire.data.du.7.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T,
                                      control = glmerControl (calc.derivs = FALSE, 
                                                              optimizer = "nloptwrap", 
                                                              optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [54, 1] <- "DU7"
table.aic [54, 2] <- "Early Winter"
table.aic [54, 3] <- "GLMM with Functional Response"
table.aic [54, 4] <- "Burn1to5, Burn6to25, A_Burn1to5, A_Burn6to25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25"
table.aic [54, 5] <- "(1 | UniqueID)"
table.aic [54, 6] <- AIC (model.lme.fxn.du7.ew.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.ew.1to5.6to25, type = 'response'), fire.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [54, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.fxn.du7.ew.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo + 
                                                    fire_1to5yo_E + fire_over25yo_E + 
                                                    fire_1to5yo:fire_1to5yo_E +
                                                    fire_over25yo:fire_over25yo_E +
                                                    (1 | uniqueID), 
                                          data = fire.data.du.7.ew, 
                                          family = binomial (link = "logit"),
                                          verbose = T,
                                          control = glmerControl (calc.derivs = FALSE, 
                                                                  optimizer = "nloptwrap", 
                                                                  optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [55, 1] <- "DU7"
table.aic [55, 2] <- "Early Winter"
table.aic [55, 3] <- "GLMM with Functional Response"
table.aic [55, 4] <- "Burn1to5, Burnover25, A_Burn1to5, A_Burnover25, Burn1to5*A_Burn1to5, Burnover25*A_Burnover25"
table.aic [55, 5] <- "(1 | UniqueID)"
table.aic [55, 6] <- AIC (model.lme.fxn.du7.ew.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.ew.1to5.over25, type = 'response'), fire.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [55, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.fxn.du7.ew.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo + 
                                                     fire_6to25yo_E + fire_over25yo_E + 
                                                     fire_6to25yo:fire_6to25yo_E +
                                                     fire_over25yo:fire_over25yo_E +
                                                     (1 | uniqueID), 
                                           data = fire.data.du.7.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T,
                                           control = glmerControl (calc.derivs = FALSE, 
                                                                   optimizer = "nloptwrap", 
                                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [56, 1] <- "DU7"
table.aic [56, 2] <- "Early Winter"
table.aic [56, 3] <- "GLMM with Functional Response"
table.aic [56, 4] <- "Burn6to25, Burnover25, A_Burn6to25, A_Burnover25, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [56, 5] <- "(1 | UniqueID)"
table.aic [56, 6] <- AIC (model.lme.fxn.du7.ew.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.ew.6to25.over25, type = 'response'), fire.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [56, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [43, 6] - min (table.aic [43:56, 6])))), 
                    (exp (-0.5 * (table.aic [44, 6] - min (table.aic [43:56, 6])))),
                    (exp (-0.5 * (table.aic [45, 6] - min (table.aic [43:56, 6])))),
                    (exp (-0.5 * (table.aic [46, 6] - min (table.aic [43:56, 6])))),
                    (exp (-0.5 * (table.aic [47, 6] - min (table.aic [43:56, 6])))),
                    (exp (-0.5 * (table.aic [48, 6] - min (table.aic [43:56, 6])))),
                    (exp (-0.5 * (table.aic [49, 6] - min (table.aic [43:56, 6])))),
                    (exp (-0.5 * (table.aic [50, 6] - min (table.aic [43:56, 6])))),
                    (exp (-0.5 * (table.aic [51, 6] - min (table.aic [43:56, 6])))), 
                    (exp (-0.5 * (table.aic [52, 6] - min (table.aic [43:56, 6])))),
                    (exp (-0.5 * (table.aic [53, 6] - min (table.aic [43:56, 6])))),
                    (exp (-0.5 * (table.aic [54, 6] - min (table.aic [43:56, 6])))),
                    (exp (-0.5 * (table.aic [55, 6] - min (table.aic [43:56, 6])))),
                    (exp (-0.5 * (table.aic [56, 6] - min (table.aic [43:56, 6])))))
table.aic [43, 7] <- round ((exp (-0.5 * (table.aic [43, 6] - min (table.aic [43:56, 6])))) / sum (list.aic.like), 3)
table.aic [44, 7] <- round ((exp (-0.5 * (table.aic [44, 6] - min (table.aic [43:56, 6])))) / sum (list.aic.like), 3)
table.aic [45, 7] <- round ((exp (-0.5 * (table.aic [45, 6] - min (table.aic [43:56, 6])))) / sum (list.aic.like), 3)
table.aic [46, 7] <- round ((exp (-0.5 * (table.aic [46, 6] - min (table.aic [43:56, 6])))) / sum (list.aic.like), 3)
table.aic [47, 7] <- round ((exp (-0.5 * (table.aic [47, 6] - min (table.aic [43:56, 6])))) / sum (list.aic.like), 3)
table.aic [48, 7] <- round ((exp (-0.5 * (table.aic [48, 6] - min (table.aic [43:56, 6])))) / sum (list.aic.like), 3)
table.aic [49, 7] <- round ((exp (-0.5 * (table.aic [49, 6] - min (table.aic [43:56, 6])))) / sum (list.aic.like), 3)
table.aic [50, 7] <- round ((exp (-0.5 * (table.aic [50, 6] - min (table.aic [43:56, 6])))) / sum (list.aic.like), 3)
table.aic [51, 7] <- round ((exp (-0.5 * (table.aic [51, 6] - min (table.aic [43:56, 6])))) / sum (list.aic.like), 3)
table.aic [52, 7] <- round ((exp (-0.5 * (table.aic [52, 6] - min (table.aic [43:56, 6])))) / sum (list.aic.like), 3)
table.aic [53, 7] <- round ((exp (-0.5 * (table.aic [53, 6] - min (table.aic [43:56, 6])))) / sum (list.aic.like), 3)
table.aic [54, 7] <- round ((exp (-0.5 * (table.aic [54, 6] - min (table.aic [43:56, 6])))) / sum (list.aic.like), 3)
table.aic [55, 7] <- round ((exp (-0.5 * (table.aic [55, 6] - min (table.aic [43:56, 6])))) / sum (list.aic.like), 3)
table.aic [56, 7] <- round ((exp (-0.5 * (table.aic [56, 6] - min (table.aic [43:56, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_fire.csv", sep = ",")

# save the top model
save (model.lme.fxn.du7.ew.1to5.over25, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\fire\\model_lme_du7_ew_top1.rda")

save (model.lme.fxn.du7.ew.all, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\fire\\model_lme_du7_ew_top2.rda")


## Late Winter
### Correlation
corr.fire.du.7.lw <- round (cor (fire.data.du.7.lw [10:12], method = "spearman"), 3)
ggcorrplot (corr.fire.du.7.lw, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Fire Age Correlation DU7 Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_fire_corr_du_7_lw.png")

### VIF
model.glm.du7.lw <- glm (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo, 
                         data = fire.data.du.7.lw,
                         family = binomial (link = 'logit'))
vif (model.glm.du7.lw) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du7.lw <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo + 
                             (fire_1to5yo | uniqueID) + 
                             (fire_6to25yo | uniqueID) +
                             (fire_over25yo | uniqueID), 
                           data = fire.data.du.7.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [57, 1] <- "DU7"
table.aic [57, 2] <- "Late Winter"
table.aic [57, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [57, 4] <- "Burn1to5, Burn6to25, Burnover25"
table.aic [57, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [57, 6] <- AIC (model.lme.du7.lw)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.lw, type = 'response'), fire.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [57, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du7.lw.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                          (fire_1to5yo | uniqueID), 
                           data = fire.data.du.7.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [58, 1] <- "DU7"
table.aic [58, 2] <- "Late Winter"
table.aic [58, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [58, 4] <- "Burn1to5"
table.aic [58, 5] <- "(Burn1to5 | UniqueID)"
table.aic [58, 6] <- AIC (model.lme.du7.lw.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.lw.1to5, type = 'response'), fire.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [58, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.du7.lw.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                          (fire_6to25yo | uniqueID), 
                                data = fire.data.du.7.lw, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [59, 1] <- "DU7"
table.aic [59, 2] <- "Late Winter"
table.aic [59, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [59, 4] <- "Burn6to25"
table.aic [59, 5] <- "(Burn6to25 | UniqueID)"
table.aic [59, 6] <- AIC (model.lme.du7.lw.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.lw.6to25, type = 'response'), fire.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [59, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.du7.lw.over25 <- glmer (pttype ~ fire_over25yo + 
                                            (fire_over25yo | uniqueID), 
                                 data = fire.data.du.7.lw, 
                                 family = binomial (link = "logit"),
                                 verbose = T,
                                 control = glmerControl (calc.derivs = FALSE, 
                                                         optimizer = "nloptwrap", 
                                                         optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [60, 1] <- "DU7"
table.aic [60, 2] <- "Late Winter"
table.aic [60, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [60, 4] <- "Burnover25"
table.aic [60, 5] <- "(Burnover25 | UniqueID)"
table.aic [60, 6] <- AIC (model.lme.du7.lw.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.lw.over25, type = 'response'), fire.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [60, 8] <- auc.temp@y.values[[1]]

# 1to5, 6to25
model.lme.du7.lw.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + 
                                              (fire_1to5yo | uniqueID) + 
                                              (fire_6to25yo | uniqueID), 
                                  data = fire.data.du.7.lw, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [61, 1] <- "DU7"
table.aic [61, 2] <- "Late Winter"
table.aic [61, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [61, 4] <- "Burn1to5, Burn6to25"
table.aic [61, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID)"
table.aic [61, 6] <- AIC (model.lme.du7.lw.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.lw.1to5.6to25, type = 'response'), fire.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [61, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.du7.lw.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo + 
                                        (fire_1to5yo | uniqueID) + 
                                        (fire_over25yo | uniqueID), 
                                      data = fire.data.du.7.lw, 
                                      family = binomial (link = "logit"),
                                      verbose = T,
                                      control = glmerControl (calc.derivs = FALSE, 
                                                              optimizer = "nloptwrap", 
                                                              optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [62, 1] <- "DU7"
table.aic [62, 2] <- "Late Winter"
table.aic [62, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [62, 4] <- "Burn1to5, Burnover25"
table.aic [62, 5] <- "(Burn1to5 | UniqueID), (Burnover25 | UniqueID)"
table.aic [62, 6] <- AIC (model.lme.du7.lw.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.lw.1to5.over25, type = 'response'), fire.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [62, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.du7.lw.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo + 
                                                 (fire_6to25yo | uniqueID) + 
                                                 (fire_over25yo | uniqueID), 
                                       data = fire.data.du.7.lw, 
                                       family = binomial (link = "logit"),
                                       verbose = T,
                                       control = glmerControl (calc.derivs = FALSE, 
                                                               optimizer = "nloptwrap", 
                                                               optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [63, 1] <- "DU7"
table.aic [63, 2] <- "Late Winter"
table.aic [63, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [63, 4] <- "Burn6to25, Burnover25"
table.aic [63, 5] <- "(Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [63, 6] <- AIC (model.lme.du7.lw.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.lw.6to25.over25, type = 'response'), fire.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [63, 8] <- auc.temp@y.values[[1]]

# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (fire.data.du.7.lw, pttype == 0)
fire_1to5yo_E <- tapply (sub$fire_1to5yo, sub$uniqueID, sum)
fire_6to25yo_E <- tapply (sub$fire_6to25yo, sub$uniqueID, sum)
fire_over25yo_E <- tapply (sub$fire_over25yo, sub$uniqueID, sum)
inds <- as.character (fire.data.du.7.lw$uniqueID)
fire.data.du.7.lw <- cbind (fire.data.du.7.lw, 
                            "fire_1to5yo_E" = fire_1to5yo_E [inds],
                            "fire_6to25yo_E" = fire_6to25yo_E [inds],
                            "fire_over25yo_E" = fire_over25yo_E [inds])

# Functional Responses
# All COVARS
model.lme.fxn.du7.lw.all <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo +
                                             fire_1to5yo_E + fire_6to25yo_E + fire_over25yo_E + 
                                             fire_1to5yo:fire_1to5yo_E +
                                             fire_6to25yo:fire_6to25yo_E +
                                             fire_over25yo:fire_over25yo_E +
                                             (1 | uniqueID), 
                                   data = fire.data.du.7.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [64, 1] <- "DU7"
table.aic [64, 2] <- "Late Winter"
table.aic [64, 3] <- "GLMM with Functional Response"
table.aic [64, 4] <- "Burn1to5, Burn6to25, Burnover25, A_Burn1to5, A_Burn6to25, A_Burnover25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [64, 5] <- "(1 | UniqueID)"
table.aic [64, 6] <- AIC (model.lme.fxn.du7.lw.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.lw.all, type = 'response'), fire.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [64, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du7.lw.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                              fire_1to5yo_E + 
                                              fire_1to5yo:fire_1to5yo_E +
                                              (1 | uniqueID), 
                                   data = fire.data.du.7.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [65, 1] <- "DU7"
table.aic [65, 2] <- "Late Winter"
table.aic [65, 3] <- "GLMM with Functional Response"
table.aic [65, 4] <- "Burn1to5, A_Burn1to5, Burn1to5*A_Burn1to5"
table.aic [65, 5] <- "(1 | UniqueID)"
table.aic [65, 6] <- AIC (model.lme.fxn.du7.lw.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.lw.1to5, type = 'response'), fire.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [65, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.fxn.du7.lw.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                               fire_6to25yo_E + 
                                               fire_6to25yo:fire_6to25yo_E +
                                               (1 | uniqueID), 
                                    data = fire.data.du.7.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [66, 1] <- "DU7"
table.aic [66, 2] <- "Late Winter"
table.aic [66, 3] <- "GLMM with Functional Response"
table.aic [66, 4] <- "Burn6to25, A_Burn6to25, Burn6to25*A_Burn6to25"
table.aic [66, 5] <- "(1 | UniqueID)"
table.aic [66, 6] <- AIC (model.lme.fxn.du7.lw.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.lw.6to25, type = 'response'), fire.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [66, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.fxn.du7.lw.over25 <- glmer (pttype ~ fire_over25yo + 
                                                fire_over25yo_E + 
                                                fire_over25yo:fire_over25yo_E +
                                                (1 | uniqueID), 
                                     data = fire.data.du.7.lw, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, 
                                                             optimizer = "nloptwrap", 
                                                             optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [67, 1] <- "DU7"
table.aic [67, 2] <- "Late Winter"
table.aic [67, 3] <- "GLMM with Functional Response"
table.aic [67, 4] <- "Burnover25, A_Burnover25, Burnover25*A_Burnover25"
table.aic [67, 5] <- "(1 | UniqueID)"
table.aic [67, 6] <- AIC (model.lme.fxn.du7.lw.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.lw.over25, type = 'response'), fire.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [67, 8] <- auc.temp@y.values[[1]]


# 1to5, 6to25
model.lme.fxn.du7.lw.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo +
                                                    fire_1to5yo_E + fire_6to25yo_E +
                                                    fire_1to5yo:fire_1to5yo_E + fire_6to25yo:fire_6to25yo_E +
                                                    (1 | uniqueID), 
                                    data = fire.data.du.7.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [68, 1] <- "DU7"
table.aic [68, 2] <- "Late Winter"
table.aic [68, 3] <- "GLMM with Functional Response"
table.aic [68, 4] <- "Burn1to5, Burn6to25, A_Burn1to5, A_Burn6to25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25"
table.aic [68, 5] <- "(1 | UniqueID)"
table.aic [68, 6] <- AIC (model.lme.fxn.du7.lw.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.lw.1to5.6to25, type = 'response'), fire.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [68, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.fxn.du7.lw.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo +
                                                    fire_1to5yo_E + fire_over25yo_E +
                                                    fire_1to5yo:fire_1to5yo_E + fire_over25yo:fire_over25yo_E +
                                                    (1 | uniqueID), 
                                          data = fire.data.du.7.lw, 
                                          family = binomial (link = "logit"),
                                          verbose = T,
                                          control = glmerControl (calc.derivs = FALSE, 
                                                                  optimizer = "nloptwrap", 
                                                                  optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [69, 1] <- "DU7"
table.aic [69, 2] <- "Late Winter"
table.aic [69, 3] <- "GLMM with Functional Response"
table.aic [69, 4] <- "Burn1to5, Burnover25, A_Burn1to5, A_Burnover25, Burn1to5*A_Burn1to5, Burnover25*A_Burnover25"
table.aic [69, 5] <- "(1 | UniqueID)"
table.aic [69, 6] <- AIC (model.lme.fxn.du7.lw.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.lw.1to5.over25, type = 'response'), fire.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [69, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.fxn.du7.lw.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo +
                                                      fire_6to25yo_E + fire_over25yo_E +
                                                      fire_6to25yo:fire_6to25yo_E + fire_over25yo:fire_over25yo_E +
                                                      (1 | uniqueID), 
                                           data = fire.data.du.7.lw, 
                                           family = binomial (link = "logit"),
                                           verbose = T,
                                           control = glmerControl (calc.derivs = FALSE, 
                                                                   optimizer = "nloptwrap", 
                                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [70, 1] <- "DU7"
table.aic [70, 2] <- "Late Winter"
table.aic [70, 3] <- "GLMM with Functional Response"
table.aic [70, 4] <- "Burn6to25, Burnover25, A_Burn6to25, A_Burnover25, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [70, 5] <- "(1 | UniqueID)"
table.aic [70, 6] <- AIC (model.lme.fxn.du7.lw.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.lw.6to25.over25, type = 'response'), fire.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [70, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [57, 6] - min (table.aic [57:70, 6])))), 
                    (exp (-0.5 * (table.aic [58, 6] - min (table.aic [57:70, 6])))),
                    (exp (-0.5 * (table.aic [59, 6] - min (table.aic [57:70, 6])))),
                    (exp (-0.5 * (table.aic [60, 6] - min (table.aic [57:70, 6])))),
                    (exp (-0.5 * (table.aic [61, 6] - min (table.aic [57:70, 6])))),
                    (exp (-0.5 * (table.aic [62, 6] - min (table.aic [57:70, 6])))),
                    (exp (-0.5 * (table.aic [63, 6] - min (table.aic [57:70, 6])))),
                    (exp (-0.5 * (table.aic [64, 6] - min (table.aic [57:70, 6])))),
                    (exp (-0.5 * (table.aic [65, 6] - min (table.aic [57:70, 6])))), 
                    (exp (-0.5 * (table.aic [66, 6] - min (table.aic [57:70, 6])))),
                    (exp (-0.5 * (table.aic [67, 6] - min (table.aic [57:70, 6])))),
                    (exp (-0.5 * (table.aic [68, 6] - min (table.aic [57:70, 6])))),
                    (exp (-0.5 * (table.aic [69, 6] - min (table.aic [57:70, 6])))),
                    (exp (-0.5 * (table.aic [70, 6] - min (table.aic [57:70, 6])))))
table.aic [57, 7] <- round ((exp (-0.5 * (table.aic [57, 6] - min (table.aic [57:70, 6])))) / sum (list.aic.like), 3)
table.aic [58, 7] <- round ((exp (-0.5 * (table.aic [58, 6] - min (table.aic [57:70, 6])))) / sum (list.aic.like), 3)
table.aic [59, 7] <- round ((exp (-0.5 * (table.aic [59, 6] - min (table.aic [57:70, 6])))) / sum (list.aic.like), 3)
table.aic [60, 7] <- round ((exp (-0.5 * (table.aic [60, 6] - min (table.aic [57:70, 6])))) / sum (list.aic.like), 3)
table.aic [61, 7] <- round ((exp (-0.5 * (table.aic [61, 6] - min (table.aic [57:70, 6])))) / sum (list.aic.like), 3)
table.aic [62, 7] <- round ((exp (-0.5 * (table.aic [62, 6] - min (table.aic [57:70, 6])))) / sum (list.aic.like), 3)
table.aic [63, 7] <- round ((exp (-0.5 * (table.aic [63, 6] - min (table.aic [57:70, 6])))) / sum (list.aic.like), 3)
table.aic [64, 7] <- round ((exp (-0.5 * (table.aic [64, 6] - min (table.aic [57:70, 6])))) / sum (list.aic.like), 3)
table.aic [65, 7] <- round ((exp (-0.5 * (table.aic [65, 6] - min (table.aic [57:70, 6])))) / sum (list.aic.like), 3)
table.aic [66, 7] <- round ((exp (-0.5 * (table.aic [66, 6] - min (table.aic [57:70, 6])))) / sum (list.aic.like), 3)
table.aic [67, 7] <- round ((exp (-0.5 * (table.aic [67, 6] - min (table.aic [57:70, 6])))) / sum (list.aic.like), 3)
table.aic [68, 7] <- round ((exp (-0.5 * (table.aic [68, 6] - min (table.aic [57:70, 6])))) / sum (list.aic.like), 3)
table.aic [69, 7] <- round ((exp (-0.5 * (table.aic [69, 6] - min (table.aic [57:70, 6])))) / sum (list.aic.like), 3)
table.aic [70, 7] <- round ((exp (-0.5 * (table.aic [70, 6] - min (table.aic [57:70, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_fire.csv", sep = ",")

# save the top model
save (model.lme.du7.lw, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\fire\\model_lme_du7_lw_top.rda")


## Summer
### Correlation
corr.fire.du.7.s <- round (cor (fire.data.du.7.s [10:12], method = "spearman"), 3)
ggcorrplot (corr.fire.du.7.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Fire Age Correlation DU7 Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_fire_corr_du_7_s.png")

### VIF
model.glm.du7.s <- glm (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo, 
                         data = fire.data.du.7.s,
                         family = binomial (link = 'logit'))
vif (model.glm.du7.s) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du7.s <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo + 
                                       (fire_1to5yo | uniqueID) + 
                                       (fire_6to25yo | uniqueID) +
                                       (fire_over25yo | uniqueID), 
                           data = fire.data.du.7.s, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [71, 1] <- "DU7"
table.aic [71, 2] <- "Summer"
table.aic [71, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [71, 4] <- "Burn1to5, Burn6to25, Burnover25"
table.aic [71, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [71, 6] <- AIC (model.lme.du7.s)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.s, type = 'response'), fire.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [71, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du7.s.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                        (fire_1to5yo | uniqueID), 
                          data = fire.data.du.7.s, 
                          family = binomial (link = "logit"),
                          verbose = T,
                          control = glmerControl (calc.derivs = FALSE, 
                                                  optimizer = "nloptwrap", 
                                                  optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [72, 1] <- "DU7"
table.aic [72, 2] <- "Summer"
table.aic [72, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [72, 4] <- "Burn1to5"
table.aic [72, 5] <- "(Burn1to5 | UniqueID)"
table.aic [72, 6] <- AIC (model.lme.du7.s.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.s.1to5, type = 'response'), fire.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [72, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.du7.s.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                        (fire_6to25yo | uniqueID), 
                               data = fire.data.du.7.s, 
                               family = binomial (link = "logit"),
                               verbose = T,
                               control = glmerControl (calc.derivs = FALSE, 
                                                       optimizer = "nloptwrap", 
                                                       optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [73, 1] <- "DU7"
table.aic [73, 2] <- "Summer"
table.aic [73, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [73, 4] <- "Burn6to25"
table.aic [73, 5] <- "(Burn6to25 | UniqueID)"
table.aic [73, 6] <- AIC (model.lme.du7.s.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.s.6to25, type = 'response'), fire.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [73, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.du7.s.over25 <- glmer (pttype ~ fire_over25yo + 
                                          (fire_over25yo | uniqueID), 
                                data = fire.data.du.7.s, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [74, 1] <- "DU7"
table.aic [74, 2] <- "Summer"
table.aic [74, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [74, 4] <- "Burnover25"
table.aic [74, 5] <- "(Burnover25 | UniqueID)"
table.aic [74, 6] <- AIC (model.lme.du7.s.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.s.over25, type = 'response'), fire.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [74, 8] <- auc.temp@y.values[[1]]

# 1to5, 6to25
model.lme.du7.s.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + 
                                              (fire_1to5yo | uniqueID) + 
                                              (fire_6to25yo | uniqueID), 
                                 data = fire.data.du.7.s, 
                                 family = binomial (link = "logit"),
                                 verbose = T,
                                 control = glmerControl (calc.derivs = FALSE, 
                                                         optimizer = "nloptwrap", 
                                                         optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [75, 1] <- "DU7"
table.aic [75, 2] <- "Summer"
table.aic [75, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [75, 4] <- "Burn1to5, Burn6to25"
table.aic [75, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID)"
table.aic [75, 6] <- AIC (model.lme.du7.s.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.s.1to5.6to25, type = 'response'), fire.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [75, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.du7.s.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo + 
                                               (fire_1to5yo | uniqueID) + 
                                               (fire_over25yo | uniqueID), 
                                     data = fire.data.du.7.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, 
                                                             optimizer = "nloptwrap", 
                                                             optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [76, 1] <- "DU7"
table.aic [76, 2] <- "Summer"
table.aic [76, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [76, 4] <- "Burn1to5, Burnover25"
table.aic [76, 5] <- "(Burn1to5 | UniqueID), (Burnover25 | UniqueID)"
table.aic [76, 6] <- AIC (model.lme.du7.s.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.s.1to5.over25, type = 'response'), fire.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [76, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.du7.s.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo + 
                                                (fire_6to25yo | uniqueID) + 
                                                (fire_over25yo | uniqueID), 
                                      data = fire.data.du.7.s, 
                                      family = binomial (link = "logit"),
                                      verbose = T,
                                      control = glmerControl (calc.derivs = FALSE, 
                                                              optimizer = "nloptwrap", 
                                                              optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [77, 1] <- "DU7"
table.aic [77, 2] <- "Summer"
table.aic [77, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [77, 4] <- "Burn6to25, Burnover25"
table.aic [77, 5] <- "(Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [77, 6] <- AIC (model.lme.du7.s.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du7.s.6to25.over25, type = 'response'), fire.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [77, 8] <- auc.temp@y.values[[1]]


# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (fire.data.du.7.s, pttype == 0)
fire_1to5yo_E <- tapply (sub$fire_1to5yo, sub$uniqueID, sum)
fire_6to25yo_E <- tapply (sub$fire_6to25yo, sub$uniqueID, sum)
fire_over25yo_E <- tapply (sub$fire_over25yo, sub$uniqueID, sum)
inds <- as.character (fire.data.du.7.s$uniqueID)
fire.data.du.7.s <- cbind (fire.data.du.7.s, 
                            "fire_1to5yo_E" = fire_1to5yo_E [inds],
                            "fire_6to25yo_E" = fire_6to25yo_E [inds],
                            "fire_over25yo_E" = fire_over25yo_E [inds])

# Functional Responses
# All COVARS
model.lme.fxn.du7.s.all <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo +
                                           fire_1to5yo_E + fire_6to25yo_E + fire_over25yo_E + 
                                           fire_1to5yo:fire_1to5yo_E +
                                           fire_6to25yo:fire_6to25yo_E +
                                           fire_over25yo:fire_over25yo_E +
                                           (1 | uniqueID), 
                                   data = fire.data.du.7.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [78, 1] <- "DU7"
table.aic [78, 2] <- "Summer"
table.aic [78, 3] <- "GLMM with Functional Response"
table.aic [78, 4] <- "Burn1to5, Burn6to25, Burnover25, A_Burn1to5, A_Burn6to25, A_Burnover25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [78, 5] <- "(1 | UniqueID)"
table.aic [78, 6] <- AIC (model.lme.fxn.du7.s.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.s.all, type = 'response'), fire.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [78, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du7.s.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                            fire_1to5yo_E + 
                                            fire_1to5yo:fire_1to5yo_E +
                                            (1 | uniqueID), 
                                  data = fire.data.du.7.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [79, 1] <- "DU7"
table.aic [79, 2] <- "Summer"
table.aic [79, 3] <- "GLMM with Functional Response"
table.aic [79, 4] <- "Burn1to5, A_Burn1to5, Burn1to5*A_Burn1to5"
table.aic [79, 5] <- "(1 | UniqueID)"
table.aic [79, 6] <- AIC (model.lme.fxn.du7.s.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.s.1to5, type = 'response'), fire.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [79, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.fxn.du7.s.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                              fire_6to25yo_E + 
                                              fire_6to25yo:fire_6to25yo_E +
                                              (1 | uniqueID), 
                                   data = fire.data.du.7.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [80, 1] <- "DU7"
table.aic [80, 2] <- "Summer"
table.aic [80, 3] <- "GLMM with Functional Response"
table.aic [80, 4] <- "Burn6to25, A_Burn6to25, Burn6to25*A_Burn6to25"
table.aic [80, 5] <- "(1 | UniqueID)"
table.aic [80, 6] <- AIC (model.lme.fxn.du7.s.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.s.6to25, type = 'response'), fire.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [80, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.fxn.du7.s.over25 <- glmer (pttype ~ fire_over25yo + 
                                              fire_over25yo_E + 
                                              fire_over25yo:fire_over25yo_E +
                                              (1 | uniqueID), 
                                    data = fire.data.du.7.s, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [81, 1] <- "DU7"
table.aic [81, 2] <- "Summer"
table.aic [81, 3] <- "GLMM with Functional Response"
table.aic [81, 4] <- "Burnover25, A_Burnover25, Burnover25*A_Burnover25"
table.aic [81, 5] <- "(1 | UniqueID)"
table.aic [81, 6] <- AIC (model.lme.fxn.du7.s.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.s.over25, type = 'response'), fire.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [81, 8] <- auc.temp@y.values[[1]]

# 1to5, 6to25
model.lme.fxn.du7.s.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + 
                                                  fire_1to5yo_E + fire_6to25yo_E + 
                                                   fire_1to5yo:fire_1to5yo_E +
                                                   fire_6to25yo:fire_6to25yo_E +
                                                    (1 | uniqueID), 
                                     data = fire.data.du.7.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, 
                                                             optimizer = "nloptwrap", 
                                                             optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [82, 1] <- "DU7"
table.aic [82, 2] <- "Summer"
table.aic [82, 3] <- "GLMM with Functional Response"
table.aic [82, 4] <- "Burn1to5, Burn6to25, A_Burn1to5, A_Burn6to25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25"
table.aic [82, 5] <- "(1 | UniqueID)"
table.aic [82, 6] <- AIC (model.lme.fxn.du7.s.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.s.1to5.6to25, type = 'response'), fire.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [82, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.fxn.du7.s.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo + 
                                                   fire_1to5yo_E + fire_over25yo_E + 
                                                   fire_1to5yo:fire_1to5yo_E +
                                                   fire_over25yo:fire_over25yo_E +
                                                   (1 | uniqueID), 
                                         data = fire.data.du.7.s, 
                                         family = binomial (link = "logit"),
                                         verbose = T,
                                         control = glmerControl (calc.derivs = FALSE, 
                                                                 optimizer = "nloptwrap", 
                                                                 optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [83, 1] <- "DU7"
table.aic [83, 2] <- "Summer"
table.aic [83, 3] <- "GLMM with Functional Response"
table.aic [83, 4] <- "Burn1to5, Burnover25, A_Burn1to5, A_Burnover25, Burn1to5*A_Burn1to5, Burnover25*A_Burnover25"
table.aic [83, 5] <- "(1 | UniqueID)"
table.aic [83, 6] <- AIC (model.lme.fxn.du7.s.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.s.1to5.over25, type = 'response'), fire.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [83, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.fxn.du7.s.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo + 
                                                     fire_6to25yo_E + fire_over25yo_E + 
                                                     fire_6to25yo:fire_6to25yo_E +
                                                     fire_over25yo:fire_over25yo_E +
                                                     (1 | uniqueID), 
                                          data = fire.data.du.7.s, 
                                          family = binomial (link = "logit"),
                                          verbose = T,
                                          control = glmerControl (calc.derivs = FALSE, 
                                                                  optimizer = "nloptwrap", 
                                                                  optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [84, 1] <- "DU7"
table.aic [84, 2] <- "Summer"
table.aic [84, 3] <- "GLMM with Functional Response"
table.aic [84, 4] <- "Burn6to25, Burnover25, A_Burn6to25, A_Burnover25, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [84, 5] <- "(1 | UniqueID)"
table.aic [84, 6] <- AIC (model.lme.fxn.du7.s.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du7.s.6to25.over25, type = 'response'), fire.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [84, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [71, 6] - min (table.aic [71:84, 6])))), 
                    (exp (-0.5 * (table.aic [72, 6] - min (table.aic [71:84, 6])))),
                    (exp (-0.5 * (table.aic [73, 6] - min (table.aic [71:84, 6])))),
                    (exp (-0.5 * (table.aic [74, 6] - min (table.aic [71:84, 6])))),
                    (exp (-0.5 * (table.aic [75, 6] - min (table.aic [71:84, 6])))),
                    (exp (-0.5 * (table.aic [76, 6] - min (table.aic [71:84, 6])))),
                    (exp (-0.5 * (table.aic [77, 6] - min (table.aic [71:84, 6])))),
                    (exp (-0.5 * (table.aic [78, 6] - min (table.aic [71:84, 6])))),
                    (exp (-0.5 * (table.aic [79, 6] - min (table.aic [71:84, 6])))), 
                    (exp (-0.5 * (table.aic [80, 6] - min (table.aic [71:84, 6])))),
                    (exp (-0.5 * (table.aic [81, 6] - min (table.aic [71:84, 6])))),
                    (exp (-0.5 * (table.aic [82, 6] - min (table.aic [71:84, 6])))),
                    (exp (-0.5 * (table.aic [83, 6] - min (table.aic [71:84, 6])))),
                    (exp (-0.5 * (table.aic [84, 6] - min (table.aic [71:84, 6])))))
table.aic [71, 7] <- round ((exp (-0.5 * (table.aic [71, 6] - min (table.aic [71:84, 6])))) / sum (list.aic.like), 3)
table.aic [72, 7] <- round ((exp (-0.5 * (table.aic [72, 6] - min (table.aic [71:84, 6])))) / sum (list.aic.like), 3)
table.aic [73, 7] <- round ((exp (-0.5 * (table.aic [73, 6] - min (table.aic [71:84, 6])))) / sum (list.aic.like), 3)
table.aic [74, 7] <- round ((exp (-0.5 * (table.aic [74, 6] - min (table.aic [71:84, 6])))) / sum (list.aic.like), 3)
table.aic [75, 7] <- round ((exp (-0.5 * (table.aic [75, 6] - min (table.aic [71:84, 6])))) / sum (list.aic.like), 3)
table.aic [76, 7] <- round ((exp (-0.5 * (table.aic [76, 6] - min (table.aic [71:84, 6])))) / sum (list.aic.like), 3)
table.aic [77, 7] <- round ((exp (-0.5 * (table.aic [77, 6] - min (table.aic [71:84, 6])))) / sum (list.aic.like), 3)
table.aic [78, 7] <- round ((exp (-0.5 * (table.aic [78, 6] - min (table.aic [71:84, 6])))) / sum (list.aic.like), 3)
table.aic [79, 7] <- round ((exp (-0.5 * (table.aic [79, 6] - min (table.aic [71:84, 6])))) / sum (list.aic.like), 3)
table.aic [80, 7] <- round ((exp (-0.5 * (table.aic [80, 6] - min (table.aic [71:84, 6])))) / sum (list.aic.like), 3)
table.aic [81, 7] <- round ((exp (-0.5 * (table.aic [81, 6] - min (table.aic [71:84, 6])))) / sum (list.aic.like), 3)
table.aic [82, 7] <- round ((exp (-0.5 * (table.aic [82, 6] - min (table.aic [71:84, 6])))) / sum (list.aic.like), 3)
table.aic [83, 7] <- round ((exp (-0.5 * (table.aic [83, 6] - min (table.aic [71:84, 6])))) / sum (list.aic.like), 3)
table.aic [84, 7] <- round ((exp (-0.5 * (table.aic [84, 6] - min (table.aic [71:84, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_fire.csv", sep = ",")

# save the top model
save (model.lme.du7.s, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\fire\\model_lme_du7_s_top.rda")






#===============
## DU8 ##
#==============
## Early Winter
### Correlation
corr.fire.du.8.ew <- round (cor (fire.data.du.8.ew [10:12], method = "spearman"), 3)
ggcorrplot (corr.fire.du.8.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Fire Age Correlation DU8 Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_fire_corr_du_8_ew.png")

### VIF
model.glm.du8.ew <- glm (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo, 
                         data = fire.data.du.8.ew,
                         family = binomial (link = 'logit'))
vif (model.glm.du8.ew) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du8.ew <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo + 
                                     (fire_1to5yo | uniqueID) + 
                                     (fire_6to25yo | uniqueID) +
                                     (fire_over25yo | uniqueID), 
                           data = fire.data.du.8.ew, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [85, 1] <- "DU8"
table.aic [85, 2] <- "Early Winter"
table.aic [85, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [85, 4] <- "Burn1to5, Burn6to25, Burnover25"
table.aic [85, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [85, 6] <- AIC (model.lme.du8.ew)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.ew, type = 'response'), fire.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [85, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du8.ew.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                        (fire_1to5yo | uniqueID), 
                           data = fire.data.du.8.ew, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [86, 1] <- "DU8"
table.aic [86, 2] <- "Early Winter"
table.aic [86, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [86, 4] <- "Burn1to5"
table.aic [86, 5] <- "(Burn1to5 | UniqueID)"
table.aic [86, 6] <- AIC (model.lme.du8.ew.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.ew.1to5, type = 'response'), fire.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [86, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.du8.ew.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                          (fire_6to25yo | uniqueID), 
                                data = fire.data.du.8.ew, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [87, 1] <- "DU8"
table.aic [87, 2] <- "Early Winter"
table.aic [87, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [87, 4] <- "Burn6to25"
table.aic [87, 5] <- "(Burn6to25 | UniqueID)"
table.aic [87, 6] <- AIC (model.lme.du8.ew.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.ew.6to25, type = 'response'), fire.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [87, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.du8.ew.over25 <- glmer (pttype ~ fire_over25yo + 
                                          (fire_over25yo | uniqueID), 
                                 data = fire.data.du.8.ew, 
                                 family = binomial (link = "logit"),
                                 verbose = T,
                                 control = glmerControl (calc.derivs = FALSE, 
                                                         optimizer = "nloptwrap", 
                                                         optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [88, 1] <- "DU8"
table.aic [88, 2] <- "Early Winter"
table.aic [88, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [88, 4] <- "Burnover25"
table.aic [88, 5] <- "(Burnover25 | UniqueID)"
table.aic [88, 6] <- AIC (model.lme.du8.ew.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.ew.over25, type = 'response'), fire.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [88, 8] <- auc.temp@y.values[[1]]

# 1to5, 6to25
model.lme.du8.ew.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + 
                                                (fire_1to5yo | uniqueID) +
                                                (fire_6to25yo | uniqueID), 
                                  data = fire.data.du.8.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [89, 1] <- "DU8"
table.aic [89, 2] <- "Early Winter"
table.aic [89, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [89, 4] <- "Burn1to5, Burn6to25"
table.aic [89, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID)"
table.aic [89, 6] <- AIC (model.lme.du8.ew.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.ew.1to5.6to25, type = 'response'), fire.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [89, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.du8.ew.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo + 
                                                  (fire_1to5yo | uniqueID) +
                                                  (fire_over25yo | uniqueID), 
                                      data = fire.data.du.8.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T,
                                      control = glmerControl (calc.derivs = FALSE, 
                                                              optimizer = "nloptwrap", 
                                                              optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [90, 1] <- "DU8"
table.aic [90, 2] <- "Early Winter"
table.aic [90, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [90, 4] <- "Burn1to5, Burnover25"
table.aic [90, 5] <- "(Burn1to5 | UniqueID), (Burnover25 | UniqueID)"
table.aic [90, 6] <- AIC (model.lme.du8.ew.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.ew.1to5.over25, type = 'response'), fire.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [90, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.du8.ew.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo + 
                                                 (fire_6to25yo | uniqueID) +
                                                 (fire_over25yo | uniqueID), 
                                       data = fire.data.du.8.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T,
                                       control = glmerControl (calc.derivs = FALSE, 
                                                               optimizer = "nloptwrap", 
                                                               optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [91, 1] <- "DU8"
table.aic [91, 2] <- "Early Winter"
table.aic [91, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [91, 4] <- "Burn6to25, Burnover25"
table.aic [91, 5] <- "(Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [91, 6] <- AIC (model.lme.du8.ew.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.ew.6to25.over25, type = 'response'), fire.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [91, 8] <- auc.temp@y.values[[1]]


# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (fire.data.du.8.ew, pttype == 0)
fire_1to5yo_E <- tapply (sub$fire_1to5yo, sub$uniqueID, sum)
fire_6to25yo_E <- tapply (sub$fire_6to25yo, sub$uniqueID, sum)
fire_over25yo_E <- tapply (sub$fire_over25yo, sub$uniqueID, sum)
inds <- as.character (fire.data.du.8.ew$uniqueID)
fire.data.du.8.ew <- cbind (fire.data.du.8.ew, 
                           "fire_1to5yo_E" = fire_1to5yo_E [inds],
                           "fire_6to25yo_E" = fire_6to25yo_E [inds],
                           "fire_over25yo_E" = fire_over25yo_E [inds])

# Functional Responses
# All COVARS
model.lme.fxn.du8.ew.all <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo +
                                    fire_1to5yo_E + fire_6to25yo_E + fire_over25yo_E + 
                                    fire_1to5yo:fire_1to5yo_E +
                                    fire_6to25yo:fire_6to25yo_E +
                                    fire_over25yo:fire_over25yo_E +
                                    (1 | uniqueID), 
                                  data = fire.data.du.8.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [92, 1] <- "DU8"
table.aic [92, 2] <- "Early Winter"
table.aic [92, 3] <- "GLMM with Functional Response"
table.aic [92, 4] <- "Burn1to5, Burn6to25, Burnover25, A_Burn1to5, A_Burn6to25, A_Burnover25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [92, 5] <- "(1 | UniqueID)"
table.aic [92, 6] <- AIC (model.lme.fxn.du8.ew.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.ew.all, type = 'response'), fire.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [92, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du8.ew.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                             fire_1to5yo_E + 
                                             fire_1to5yo:fire_1to5yo_E +
                                             (1 | uniqueID), 
                                   data = fire.data.du.8.ew, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [93, 1] <- "DU8"
table.aic [93, 2] <- "Early Winter"
table.aic [93, 3] <- "GLMM with Functional Response"
table.aic [93, 4] <- "Burn1to5, A_Burn1to5, Burn1to5*A_Burn1to5"
table.aic [93, 5] <- "(1 | UniqueID)"
table.aic [93, 6] <- AIC (model.lme.fxn.du8.ew.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.ew.1to5, type = 'response'), fire.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [93, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.fxn.du8.ew.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                              fire_6to25yo_E + 
                                              fire_6to25yo:fire_6to25yo_E +
                                              (1 | uniqueID), 
                                    data = fire.data.du.8.ew, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [94, 1] <- "DU8"
table.aic [94, 2] <- "Early Winter"
table.aic [94, 3] <- "GLMM with Functional Response"
table.aic [94, 4] <- "Burn6to25, A_Burn6to25, Burn6to25*A_Burn6to25"
table.aic [94, 5] <- "(1 | UniqueID)"
table.aic [94, 6] <- AIC (model.lme.fxn.du8.ew.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.ew.6to25, type = 'response'), fire.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [94, 8] <- auc.temp@y.values[[1]]


# over25
model.lme.fxn.du8.ew.over25 <- glmer (pttype ~ fire_over25yo + 
                                                fire_over25yo_E + 
                                                fire_over25yo:fire_over25yo_E +
                                                (1 | uniqueID), 
                                     data = fire.data.du.8.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, 
                                                             optimizer = "nloptwrap", 
                                                             optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [95, 1] <- "DU8"
table.aic [95, 2] <- "Early Winter"
table.aic [95, 3] <- "GLMM with Functional Response"
table.aic [95, 4] <- "Burnover25, A_Burnover25, Burnover25*A_Burnover25"
table.aic [95, 5] <- "(1 | UniqueID)"
table.aic [95, 6] <- AIC (model.lme.fxn.du8.ew.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.ew.over25, type = 'response'), fire.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [95, 8] <- auc.temp@y.values[[1]]

# 1to5, 6to25
model.lme.fxn.du8.ew.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + 
                                                    fire_1to5yo_E + fire_6to25yo_E + 
                                                    fire_1to5yo:fire_1to5yo_E +
                                                    fire_6to25yo:fire_6to25yo_E +
                                                    (1 | uniqueID), 
                                      data = fire.data.du.8.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T,
                                      control = glmerControl (calc.derivs = FALSE, 
                                                              optimizer = "nloptwrap", 
                                                              optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [96, 1] <- "DU8"
table.aic [96, 2] <- "Early Winter"
table.aic [96, 3] <- "GLMM with Functional Response"
table.aic [96, 4] <- "Burn1to5, Burn6to25, A_Burn1to5, A_Burn6to25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25"
table.aic [96, 5] <- "(1 | UniqueID)"
table.aic [96, 6] <- AIC (model.lme.fxn.du8.ew.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.ew.1to5.6to25, type = 'response'), fire.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [96, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.fxn.du8.ew.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo + 
                                                    fire_1to5yo_E + fire_over25yo_E + 
                                                    fire_1to5yo:fire_1to5yo_E +
                                                    fire_over25yo:fire_over25yo_E +
                                                    (1 | uniqueID), 
                                          data = fire.data.du.8.ew, 
                                          family = binomial (link = "logit"),
                                          verbose = T,
                                          control = glmerControl (calc.derivs = FALSE, 
                                                                  optimizer = "nloptwrap", 
                                                                  optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [97, 1] <- "DU8"
table.aic [97, 2] <- "Early Winter"
table.aic [97, 3] <- "GLMM with Functional Response"
table.aic [97, 4] <- "Burn1to5, Burnover25, A_Burn1to5, A_Burnover25, Burn1to5*A_Burn1to5, Burnover25*A_Burnover25"
table.aic [97, 5] <- "(1 | UniqueID)"
table.aic [97, 6] <- AIC (model.lme.fxn.du8.ew.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.ew.1to5.over25, type = 'response'), fire.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [97, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.fxn.du8.ew.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo + 
                                                        fire_6to25yo_E + fire_over25yo_E + 
                                                        fire_6to25yo:fire_6to25yo_E +
                                                        fire_over25yo:fire_over25yo_E +
                                                       (1 | uniqueID), 
                                           data = fire.data.du.8.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T,
                                           control = glmerControl (calc.derivs = FALSE, 
                                                                   optimizer = "nloptwrap", 
                                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [98, 1] <- "DU8"
table.aic [98, 2] <- "Early Winter"
table.aic [98, 3] <- "GLMM with Functional Response"
table.aic [98, 4] <- "Burn6to25, Burnover25, A_Burn6to25, A_Burnover25, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [98, 5] <- "(1 | UniqueID)"
table.aic [98, 6] <- AIC (model.lme.fxn.du8.ew.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.ew.6to25.over25, type = 'response'), fire.data.du.8.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [98, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [85, 6] - min (table.aic [85:98, 6])))), 
                    (exp (-0.5 * (table.aic [86, 6] - min (table.aic [85:98, 6])))),
                    (exp (-0.5 * (table.aic [87, 6] - min (table.aic [85:98, 6])))),
                    (exp (-0.5 * (table.aic [88, 6] - min (table.aic [85:98, 6])))),
                    (exp (-0.5 * (table.aic [89, 6] - min (table.aic [85:98, 6])))),
                    (exp (-0.5 * (table.aic [90, 6] - min (table.aic [85:98, 6])))),
                    (exp (-0.5 * (table.aic [91, 6] - min (table.aic [85:98, 6])))),
                    (exp (-0.5 * (table.aic [92, 6] - min (table.aic [85:98, 6])))),
                    (exp (-0.5 * (table.aic [93, 6] - min (table.aic [85:98, 6])))), 
                    (exp (-0.5 * (table.aic [94, 6] - min (table.aic [85:98, 6])))),
                    (exp (-0.5 * (table.aic [95, 6] - min (table.aic [85:98, 6])))),
                    (exp (-0.5 * (table.aic [96, 6] - min (table.aic [85:98, 6])))),
                    (exp (-0.5 * (table.aic [97, 6] - min (table.aic [85:98, 6])))),
                    (exp (-0.5 * (table.aic [98, 6] - min (table.aic [85:98, 6])))))
table.aic [85, 7] <- round ((exp (-0.5 * (table.aic [85, 6] - min (table.aic [85:98, 6])))) / sum (list.aic.like), 3)
table.aic [86, 7] <- round ((exp (-0.5 * (table.aic [86, 6] - min (table.aic [85:98, 6])))) / sum (list.aic.like), 3)
table.aic [87, 7] <- round ((exp (-0.5 * (table.aic [87, 6] - min (table.aic [85:98, 6])))) / sum (list.aic.like), 3)
table.aic [88, 7] <- round ((exp (-0.5 * (table.aic [88, 6] - min (table.aic [85:98, 6])))) / sum (list.aic.like), 3)
table.aic [89, 7] <- round ((exp (-0.5 * (table.aic [89, 6] - min (table.aic [85:98, 6])))) / sum (list.aic.like), 3)
table.aic [90, 7] <- round ((exp (-0.5 * (table.aic [90, 6] - min (table.aic [85:98, 6])))) / sum (list.aic.like), 3)
table.aic [91, 7] <- round ((exp (-0.5 * (table.aic [91, 6] - min (table.aic [85:98, 6])))) / sum (list.aic.like), 3)
table.aic [92, 7] <- round ((exp (-0.5 * (table.aic [92, 6] - min (table.aic [85:98, 6])))) / sum (list.aic.like), 3)
table.aic [93, 7] <- round ((exp (-0.5 * (table.aic [93, 6] - min (table.aic [85:98, 6])))) / sum (list.aic.like), 3)
table.aic [94, 7] <- round ((exp (-0.5 * (table.aic [94, 6] - min (table.aic [85:98, 6])))) / sum (list.aic.like), 3)
table.aic [95, 7] <- round ((exp (-0.5 * (table.aic [95, 6] - min (table.aic [85:98, 6])))) / sum (list.aic.like), 3)
table.aic [96, 7] <- round ((exp (-0.5 * (table.aic [96, 6] - min (table.aic [85:98, 6])))) / sum (list.aic.like), 3)
table.aic [97, 7] <- round ((exp (-0.5 * (table.aic [97, 6] - min (table.aic [85:98, 6])))) / sum (list.aic.like), 3)
table.aic [98, 7] <- round ((exp (-0.5 * (table.aic [98, 6] - min (table.aic [85:98, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_fire.csv", sep = ",")

# save the top model
save (model.lme.fxn.du8.ew.all, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\fire\\model_lme_du8_ew_top.rda")


## Late Winter
### Correlation
corr.fire.du.8.lw <- round (cor (fire.data.du.8.lw [10:12], method = "spearman"), 3)
ggcorrplot (corr.fire.du.8.lw, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Fire Age Correlation DU8 Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_fire_corr_du_8_lw.png")

### VIF
model.glm.du8.lw <- glm (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo, 
                         data = fire.data.du.8.lw,
                         family = binomial (link = 'logit'))
vif (model.glm.du8.lw) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du8.lw <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo + 
                                     (fire_1to5yo | uniqueID) + 
                                     (fire_6to25yo | uniqueID) +
                                     (fire_over25yo | uniqueID), 
                           data = fire.data.du.8.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [99, 1] <- "DU8"
table.aic [99, 2] <- "Late Winter"
table.aic [99, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [99, 4] <- "Burn1to5, Burn6to25, Burnover25"
table.aic [99, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [99, 6] <- AIC (model.lme.du8.lw)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.lw, type = 'response'), fire.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [99, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du8.lw.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                        (fire_1to5yo | uniqueID), 
                           data = fire.data.du.8.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [100, 1] <- "DU8"
table.aic [100, 2] <- "Late Winter"
table.aic [100, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [100, 4] <- "Burn1to5"
table.aic [100, 5] <- "(Burn1to5 | UniqueID)"
table.aic [100, 6] <- AIC (model.lme.du8.lw.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.lw.1to5, type = 'response'), fire.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [100, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.du8.lw.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                          (fire_6to25yo | uniqueID), 
                                data = fire.data.du.8.lw, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [101, 1] <- "DU8"
table.aic [101, 2] <- "Late Winter"
table.aic [101, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [101, 4] <- "Burn6to25"
table.aic [101, 5] <- "(Burn6to25 | UniqueID)"
table.aic [101, 6] <- AIC (model.lme.du8.lw.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.lw.6to25, type = 'response'), fire.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [101, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.du8.lw.over25 <- glmer (pttype ~ fire_over25yo + 
                                          (fire_over25yo | uniqueID), 
                                 data = fire.data.du.8.lw, 
                                 family = binomial (link = "logit"),
                                 verbose = T,
                                 control = glmerControl (calc.derivs = FALSE, 
                                                         optimizer = "nloptwrap", 
                                                         optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [102, 1] <- "DU8"
table.aic [102, 2] <- "Late Winter"
table.aic [102, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [102, 4] <- "Burnover25"
table.aic [102, 5] <- "(Burnover25 | UniqueID)"
table.aic [102, 6] <- AIC (model.lme.du8.lw.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.lw.over25, type = 'response'), fire.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [102, 8] <- auc.temp@y.values[[1]]

# 1to5, 6to25
model.lme.du8.lw.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + 
                                              (fire_1to5yo | uniqueID) +
                                              (fire_6to25yo | uniqueID), 
                                  data = fire.data.du.8.lw, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [103, 1] <- "DU8"
table.aic [103, 2] <- "Late Winter"
table.aic [103, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [103, 4] <- "Burn1to5, Burn6to25"
table.aic [103, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID)"
table.aic [103, 6] <- AIC (model.lme.du8.lw.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.lw.1to5.6to25, type = 'response'), fire.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [103, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.du8.lw.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo + 
                                                (fire_1to5yo | uniqueID) +
                                                (fire_over25yo | uniqueID), 
                                      data = fire.data.du.8.lw, 
                                      family = binomial (link = "logit"),
                                      verbose = T,
                                      control = glmerControl (calc.derivs = FALSE, 
                                                              optimizer = "nloptwrap", 
                                                              optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [104, 1] <- "DU8"
table.aic [104, 2] <- "Late Winter"
table.aic [104, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [104, 4] <- "Burn1to5, Burnover25"
table.aic [104, 5] <- "(Burn1to5 | UniqueID), (Burnover25 | UniqueID)"
table.aic [104, 6] <- AIC (model.lme.du8.lw.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.lw.1to5.over25, type = 'response'), fire.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [104, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.du8.lw.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo + 
                                                 (fire_6to25yo | uniqueID) +
                                                 (fire_over25yo | uniqueID), 
                                       data = fire.data.du.8.lw, 
                                       family = binomial (link = "logit"),
                                       verbose = T,
                                       control = glmerControl (calc.derivs = FALSE, 
                                                               optimizer = "nloptwrap", 
                                                               optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [105, 1] <- "DU8"
table.aic [105, 2] <- "Late Winter"
table.aic [105, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [105, 4] <- "Burn6to25, Burnover25"
table.aic [105, 5] <- "(Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [105, 6] <- AIC (model.lme.du8.lw.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.lw.6to25.over25, type = 'response'), fire.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [105, 8] <- auc.temp@y.values[[1]]

# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (fire.data.du.8.lw, pttype == 0)
fire_1to5yo_E <- tapply (sub$fire_1to5yo, sub$uniqueID, sum)
fire_6to25yo_E <- tapply (sub$fire_6to25yo, sub$uniqueID, sum)
fire_over25yo_E <- tapply (sub$fire_over25yo, sub$uniqueID, sum)
inds <- as.character (fire.data.du.8.lw$uniqueID)
fire.data.du.8.lw <- cbind (fire.data.du.8.lw, 
                            "fire_1to5yo_E" = fire_1to5yo_E [inds],
                            "fire_6to25yo_E" = fire_6to25yo_E [inds],
                            "fire_over25yo_E" = fire_over25yo_E [inds])

# Functional Responses
# All COVARS
model.lme.fxn.du8.lw.all <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo +
                                             fire_1to5yo_E + fire_6to25yo_E + fire_over25yo_E + 
                                             fire_1to5yo:fire_1to5yo_E +
                                             fire_6to25yo:fire_6to25yo_E +
                                             fire_over25yo:fire_over25yo_E +
                                             (1 | uniqueID), 
                                   data = fire.data.du.8.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [106, 1] <- "DU8"
table.aic [106, 2] <- "Late Winter"
table.aic [106, 3] <- "GLMM with Functional Response"
table.aic [106, 4] <- "Burn1to5, Burn6to25, Burnover25, A_Burn1to5, A_Burn6to25, A_Burnover25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [106, 5] <- "(1 | UniqueID)"
table.aic [106, 6] <- AIC (model.lme.fxn.du8.lw.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.lw.all, type = 'response'), fire.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [106, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du8.lw.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                             fire_1to5yo_E + 
                                             fire_1to5yo:fire_1to5yo_E +
                                             (1 | uniqueID), 
                                   data = fire.data.du.8.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [107, 1] <- "DU8"
table.aic [107, 2] <- "Late Winter"
table.aic [107, 3] <- "GLMM with Functional Response"
table.aic [107, 4] <- "Burn1to5, A_Burn1to5, Burn1to5*A_Burn1to5"
table.aic [107, 5] <- "(1 | UniqueID)"
table.aic [107, 6] <- AIC (model.lme.fxn.du8.lw.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.lw.1to5, type = 'response'), fire.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [107, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.fxn.du8.lw.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                               fire_6to25yo_E + 
                                               fire_6to25yo:fire_6to25yo_E +
                                                (1 | uniqueID), 
                                    data = fire.data.du.8.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [108, 1] <- "DU8"
table.aic [108, 2] <- "Late Winter"
table.aic [108, 3] <- "GLMM with Functional Response"
table.aic [108, 4] <- "Burn6to25, A_Burn6to25, Burn6to25*A_Burn6to25"
table.aic [108, 5] <- "(1 | UniqueID)"
table.aic [108, 6] <- AIC (model.lme.fxn.du8.lw.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.lw.6to25, type = 'response'), fire.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [108, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.fxn.du8.lw.over25 <- glmer (pttype ~ fire_over25yo + 
                                                fire_over25yo_E + 
                                                fire_over25yo:fire_over25yo_E +
                                               (1 | uniqueID), 
                                     data = fire.data.du.8.lw, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, 
                                                             optimizer = "nloptwrap", 
                                                             optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [109, 1] <- "DU8"
table.aic [109, 2] <- "Late Winter"
table.aic [109, 3] <- "GLMM with Functional Response"
table.aic [109, 4] <- "Burnover25, A_Burnover25, Burnover25*A_Burnover25"
table.aic [109, 5] <- "(1 | UniqueID)"
table.aic [109, 6] <- AIC (model.lme.fxn.du8.lw.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.lw.over25, type = 'response'), fire.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [109, 8] <- auc.temp@y.values[[1]]

# 1to5, 6to25
model.lme.fxn.du8.lw.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + 
                                                    fire_1to5yo_E + fire_6to25yo_E + 
                                                    fire_1to5yo:fire_1to5yo_E +
                                                    fire_6to25yo:fire_6to25yo_E +
                                                    (1 | uniqueID), 
                                      data = fire.data.du.8.lw, 
                                      family = binomial (link = "logit"),
                                      verbose = T,
                                      control = glmerControl (calc.derivs = FALSE, 
                                                              optimizer = "nloptwrap", 
                                                              optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [110, 1] <- "DU8"
table.aic [110, 2] <- "Late Winter"
table.aic [110, 3] <- "GLMM with Functional Response"
table.aic [110, 4] <- "Burn1to5, Burn6to25, A_Burn1to5, A_Burn6to25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25"
table.aic [110, 5] <- "(1 | UniqueID)"
table.aic [110, 6] <- AIC (model.lme.fxn.du8.lw.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.lw.1to5.6to25, type = 'response'), fire.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [110, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.fxn.du8.lw.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo + 
                                                    fire_1to5yo_E + fire_over25yo_E + 
                                                    fire_1to5yo:fire_1to5yo_E +
                                                    fire_over25yo:fire_over25yo_E +
                                                    (1 | uniqueID), 
                                          data = fire.data.du.8.lw, 
                                          family = binomial (link = "logit"),
                                          verbose = T,
                                          control = glmerControl (calc.derivs = FALSE, 
                                                                  optimizer = "nloptwrap", 
                                                                  optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [111, 1] <- "DU8"
table.aic [111, 2] <- "Late Winter"
table.aic [111, 3] <- "GLMM with Functional Response"
table.aic [111, 4] <- "Burn1to5, Burnover25, A_Burn1to5, A_Burnover25, Burn1to5*A_Burn1to5, Burnover25*A_Burnover25"
table.aic [111, 5] <- "(1 | UniqueID)"
table.aic [111, 6] <- AIC (model.lme.fxn.du8.lw.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.lw.1to5.over25, type = 'response'), fire.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [111, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.fxn.du8.lw.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo + 
                                                      fire_6to25yo_E + fire_over25yo_E + 
                                                      fire_6to25yo:fire_6to25yo_E +
                                                      fire_over25yo:fire_over25yo_E +
                                                      (1 | uniqueID), 
                                           data = fire.data.du.8.lw, 
                                           family = binomial (link = "logit"),
                                           verbose = T,
                                           control = glmerControl (calc.derivs = FALSE, 
                                                                   optimizer = "nloptwrap", 
                                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [112, 1] <- "DU8"
table.aic [112, 2] <- "Late Winter"
table.aic [112, 3] <- "GLMM with Functional Response"
table.aic [112, 4] <- "Burn6to25, Burnover25, A_Burn6to25, A_Burnover25, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [112, 5] <- "(1 | UniqueID)"
table.aic [112, 6] <- AIC (model.lme.fxn.du8.lw.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.lw.6to25.over25, type = 'response'), fire.data.du.8.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [112, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [99, 6] - min (table.aic [99:112, 6])))), 
                    (exp (-0.5 * (table.aic [100, 6] - min (table.aic [99:112, 6])))),
                    (exp (-0.5 * (table.aic [101, 6] - min (table.aic [99:112, 6])))),
                    (exp (-0.5 * (table.aic [102, 6] - min (table.aic [99:112, 6])))),
                    (exp (-0.5 * (table.aic [103, 6] - min (table.aic [99:112, 6])))),
                    (exp (-0.5 * (table.aic [104, 6] - min (table.aic [99:112, 6])))),
                    (exp (-0.5 * (table.aic [105, 6] - min (table.aic [99:112, 6])))),
                    (exp (-0.5 * (table.aic [106, 6] - min (table.aic [99:112, 6])))),
                    (exp (-0.5 * (table.aic [107, 6] - min (table.aic [99:112, 6])))), 
                    (exp (-0.5 * (table.aic [108, 6] - min (table.aic [99:112, 6])))),
                    (exp (-0.5 * (table.aic [109, 6] - min (table.aic [99:112, 6])))),
                    (exp (-0.5 * (table.aic [110, 6] - min (table.aic [99:112, 6])))),
                    (exp (-0.5 * (table.aic [111, 6] - min (table.aic [99:112, 6])))),
                    (exp (-0.5 * (table.aic [112, 6] - min (table.aic [99:112, 6])))))
table.aic [99, 7] <- round ((exp (-0.5 * (table.aic [99, 6] - min (table.aic [99:112, 6])))) / sum (list.aic.like), 3)
table.aic [100, 7] <- round ((exp (-0.5 * (table.aic [100, 6] - min (table.aic [99:112, 6])))) / sum (list.aic.like), 3)
table.aic [101, 7] <- round ((exp (-0.5 * (table.aic [101, 6] - min (table.aic [99:112, 6])))) / sum (list.aic.like), 3)
table.aic [102, 7] <- round ((exp (-0.5 * (table.aic [102, 6] - min (table.aic [99:112, 6])))) / sum (list.aic.like), 3)
table.aic [103, 7] <- round ((exp (-0.5 * (table.aic [103, 6] - min (table.aic [99:112, 6])))) / sum (list.aic.like), 3)
table.aic [104, 7] <- round ((exp (-0.5 * (table.aic [104, 6] - min (table.aic [99:112, 6])))) / sum (list.aic.like), 3)
table.aic [105, 7] <- round ((exp (-0.5 * (table.aic [105, 6] - min (table.aic [99:112, 6])))) / sum (list.aic.like), 3)
table.aic [106, 7] <- round ((exp (-0.5 * (table.aic [106, 6] - min (table.aic [99:112, 6])))) / sum (list.aic.like), 3)
table.aic [107, 7] <- round ((exp (-0.5 * (table.aic [107, 6] - min (table.aic [99:112, 6])))) / sum (list.aic.like), 3)
table.aic [108, 7] <- round ((exp (-0.5 * (table.aic [108, 6] - min (table.aic [99:112, 6])))) / sum (list.aic.like), 3)
table.aic [109, 7] <- round ((exp (-0.5 * (table.aic [109, 6] - min (table.aic [99:112, 6])))) / sum (list.aic.like), 3)
table.aic [110, 7] <- round ((exp (-0.5 * (table.aic [110, 6] - min (table.aic [99:112, 6])))) / sum (list.aic.like), 3)
table.aic [111, 7] <- round ((exp (-0.5 * (table.aic [111, 6] - min (table.aic [99:112, 6])))) / sum (list.aic.like), 3)
table.aic [112, 7] <- round ((exp (-0.5 * (table.aic [112, 6] - min (table.aic [99:112, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_fire.csv", sep = ",")

# save the top model
save (model.lme.fxn.du8.ew.all, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\fire\\model_lme_du8_ew_top.rda")


## Summer
### Correlation
corr.fire.du.8.s <- round (cor (fire.data.du.8.s [10:12], method = "spearman"), 3)
ggcorrplot (corr.fire.du.8.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Fire Age Correlation DU8 Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_fire_corr_du_8_s.png")

### VIF
model.glm.du8.s <- glm (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo, 
                         data = fire.data.du.8.s,
                         family = binomial (link = 'logit'))
vif (model.glm.du8.s) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du8.s <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo + 
                                     (fire_1to5yo | uniqueID) + 
                                     (fire_6to25yo | uniqueID) +
                                     (fire_over25yo | uniqueID), 
                           data = fire.data.du.8.s, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [113, 1] <- "DU8"
table.aic [113, 2] <- "Summer"
table.aic [113, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [113, 4] <- "Burn1to5, Burn6to25, Burnover25"
table.aic [113, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [113, 6] <- AIC (model.lme.du8.s)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.s, type = 'response'), fire.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [113, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du8.s.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                        (fire_1to5yo | uniqueID), 
                          data = fire.data.du.8.s, 
                          family = binomial (link = "logit"),
                          verbose = T,
                          control = glmerControl (calc.derivs = FALSE, 
                                                  optimizer = "nloptwrap", 
                                                  optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [114, 1] <- "DU8"
table.aic [114, 2] <- "Summer"
table.aic [114, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [114, 4] <- "Burn1to5"
table.aic [114, 5] <- "(Burn1to5 | UniqueID)"
table.aic [114, 6] <- AIC (model.lme.du8.s.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.s.1to5, type = 'response'), fire.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [114, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.du8.s.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                        (fire_6to25yo | uniqueID), 
                               data = fire.data.du.8.s, 
                               family = binomial (link = "logit"),
                               verbose = T,
                               control = glmerControl (calc.derivs = FALSE, 
                                                       optimizer = "nloptwrap", 
                                                       optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [115, 1] <- "DU8"
table.aic [115, 2] <- "Summer"
table.aic [115, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [115, 4] <- "Burn6to25"
table.aic [115, 5] <- "(Burn6to25 | UniqueID)"
table.aic [115, 6] <- AIC (model.lme.du8.s.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.s.6to25, type = 'response'), fire.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [115, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.du8.s.over25 <- glmer (pttype ~ fire_over25yo + 
                                          (fire_over25yo | uniqueID), 
                                data = fire.data.du.8.s, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [116, 1] <- "DU8"
table.aic [116, 2] <- "Summer"
table.aic [116, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [116, 4] <- "Burnover25"
table.aic [116, 5] <- "(Burnover25 | UniqueID)"
table.aic [116, 6] <- AIC (model.lme.du8.s.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.s.over25, type = 'response'), fire.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [116, 8] <- auc.temp@y.values[[1]]

# 1to5, 6to25
model.lme.du8.s.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + 
                                             (fire_1to5yo | uniqueID) + 
                                             (fire_6to25yo | uniqueID), 
                                 data = fire.data.du.8.s, 
                                 family = binomial (link = "logit"),
                                 verbose = T,
                                 control = glmerControl (calc.derivs = FALSE, 
                                                         optimizer = "nloptwrap", 
                                                         optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [117, 1] <- "DU8"
table.aic [117, 2] <- "Summer"
table.aic [117, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [117, 4] <- "Burn1to5, Burn6to25"
table.aic [117, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID)"
table.aic [117, 6] <- AIC (model.lme.du8.s.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.s.1to5.6to25, type = 'response'), fire.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [117, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.du8.s.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo + 
                                               (fire_1to5yo | uniqueID) + 
                                               (fire_over25yo | uniqueID), 
                                     data = fire.data.du.8.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, 
                                                             optimizer = "nloptwrap", 
                                                             optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [118, 1] <- "DU8"
table.aic [118, 2] <- "Summer"
table.aic [118, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [118, 4] <- "Burn1to5, Burnover25"
table.aic [118, 5] <- "(Burn1to5 | UniqueID), (Burnover25 | UniqueID)"
table.aic [118, 6] <- AIC (model.lme.du8.s.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.s.1to5.over25, type = 'response'), fire.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [118, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.du8.s.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo + 
                                                (fire_6to25yo | uniqueID) + 
                                                (fire_over25yo | uniqueID), 
                                      data = fire.data.du.8.s, 
                                      family = binomial (link = "logit"),
                                      verbose = T,
                                      control = glmerControl (calc.derivs = FALSE, 
                                                              optimizer = "nloptwrap", 
                                                              optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [119, 1] <- "DU8"
table.aic [119, 2] <- "Summer"
table.aic [119, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [119, 4] <- "Burn6to25, Burnover25"
table.aic [119, 5] <- "(Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [119, 6] <- AIC (model.lme.du8.s.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du8.s.6to25.over25, type = 'response'), fire.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [119, 8] <- auc.temp@y.values[[1]]


# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (fire.data.du.8.s, pttype == 0)
fire_1to5yo_E <- tapply (sub$fire_1to5yo, sub$uniqueID, sum)
fire_6to25yo_E <- tapply (sub$fire_6to25yo, sub$uniqueID, sum)
fire_over25yo_E <- tapply (sub$fire_over25yo, sub$uniqueID, sum)
inds <- as.character (fire.data.du.8.s$uniqueID)
fire.data.du.8.s <- cbind (fire.data.du.8.s, 
                            "fire_1to5yo_E" = fire_1to5yo_E [inds],
                            "fire_6to25yo_E" = fire_6to25yo_E [inds],
                            "fire_over25yo_E" = fire_over25yo_E [inds])

# Functional Responses
# All COVARS
model.lme.fxn.du8.s.all <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo +
                                             fire_1to5yo_E + fire_6to25yo_E + fire_over25yo_E + 
                                             fire_1to5yo:fire_1to5yo_E +
                                             fire_6to25yo:fire_6to25yo_E +
                                             fire_over25yo:fire_over25yo_E +
                                             (1 | uniqueID), 
                                   data = fire.data.du.8.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [120, 1] <- "DU8"
table.aic [120, 2] <- "Summer"
table.aic [120, 3] <- "GLMM with Functional Response"
table.aic [120, 4] <- "Burn1to5, Burn6to25, Burnover25, A_Burn1to5, A_Burn6to25, A_Burnover25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [120, 5] <- "(1 | UniqueID)"
table.aic [120, 6] <- AIC (model.lme.fxn.du8.s.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.s.all, type = 'response'), fire.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [120, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du8.s.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                            fire_1to5yo_E + 
                                            fire_1to5yo:fire_1to5yo_E +
                                            (1 | uniqueID), 
                                  data = fire.data.du.8.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [121, 1] <- "DU8"
table.aic [121, 2] <- "Summer"
table.aic [121, 3] <- "GLMM with Functional Response"
table.aic [121, 4] <- "Burn1to5, A_Burn1to5, Burn1to5*A_Burn1to5"
table.aic [121, 5] <- "(1 | UniqueID)"
table.aic [121, 6] <- AIC (model.lme.fxn.du8.s.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.s.1to5, type = 'response'), fire.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [121, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.fxn.du8.s.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                              fire_6to25yo_E + 
                                              fire_6to25yo:fire_6to25yo_E +
                                              (1 | uniqueID), 
                                   data = fire.data.du.8.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [122, 1] <- "DU8"
table.aic [122, 2] <- "Summer"
table.aic [122, 3] <- "GLMM with Functional Response"
table.aic [122, 4] <- "Burn6to25, A_Burn6to25, Burn6to25*A_Burn6to25"
table.aic [122, 5] <- "(1 | UniqueID)"
table.aic [122, 6] <- AIC (model.lme.fxn.du8.s.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.s.6to25, type = 'response'), fire.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [122, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.fxn.du8.s.over25 <- glmer (pttype ~ fire_over25yo + 
                                               fire_over25yo_E + 
                                               fire_over25yo:fire_over25yo_E +
                                                (1 | uniqueID), 
                                    data = fire.data.du.8.s, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [123, 1] <- "DU8"
table.aic [123, 2] <- "Summer"
table.aic [123, 3] <- "GLMM with Functional Response"
table.aic [123, 4] <- "Burnover25, A_Burnover25, Burnover25*A_Burnover25"
table.aic [123, 5] <- "(1 | UniqueID)"
table.aic [123, 6] <- AIC (model.lme.fxn.du8.s.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.s.over25, type = 'response'), fire.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [123, 8] <- auc.temp@y.values[[1]]

# 1to5, 6to25
model.lme.fxn.du8.s.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + 
                                                  fire_1to5yo_E + fire_6to25yo_E  + 
                                                   fire_1to5yo:fire_1to5yo_E +
                                                   fire_6to25yo:fire_6to25yo_E +
                                                    (1 | uniqueID), 
                                     data = fire.data.du.8.s, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, 
                                                             optimizer = "nloptwrap", 
                                                             optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [124, 1] <- "DU8"
table.aic [124, 2] <- "Summer"
table.aic [124, 3] <- "GLMM with Functional Response"
table.aic [124, 4] <- "Burn1to5, Burn6to25, A_Burn1to5, A_Burn6to25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25"
table.aic [124, 5] <- "(1 | UniqueID)"
table.aic [124, 6] <- AIC (model.lme.fxn.du8.s.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.s.1to5.6to25, type = 'response'), fire.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [124, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.fxn.du8.s.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo + 
                                           fire_1to5yo_E + fire_over25yo_E  + 
                                           fire_1to5yo:fire_1to5yo_E +
                                            fire_over25yo:fire_over25yo_E +
                                           (1 | uniqueID), 
                                         data = fire.data.du.8.s, 
                                         family = binomial (link = "logit"),
                                         verbose = T,
                                         control = glmerControl (calc.derivs = FALSE, 
                                                                 optimizer = "nloptwrap", 
                                                                 optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [125, 1] <- "DU8"
table.aic [125, 2] <- "Summer"
table.aic [125, 3] <- "GLMM with Functional Response"
table.aic [125, 4] <- "Burn1to5, Burnover25, A_Burn1to5, A_Burnover25, Burn1to5*A_Burn1to5, Burnover25*A_Burnover25"
table.aic [125, 5] <- "(1 | UniqueID)"
table.aic [125, 6] <- AIC (model.lme.fxn.du8.s.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.s.1to5.over25, type = 'response'), fire.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [125, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.fxn.du8.s.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo + 
                                                     fire_6to25yo_E + fire_over25yo_E  + 
                                                     fire_6to25yo:fire_6to25yo_E +
                                                      fire_over25yo:fire_over25yo_E +
                                                      (1 | uniqueID), 
                                          data = fire.data.du.8.s, 
                                          family = binomial (link = "logit"),
                                          verbose = T,
                                          control = glmerControl (calc.derivs = FALSE, 
                                                                  optimizer = "nloptwrap", 
                                                                  optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [126, 1] <- "DU8"
table.aic [126, 2] <- "Summer"
table.aic [126, 3] <- "GLMM with Functional Response"
table.aic [126, 4] <- "Burn6to25, Burnover25, A_Burn6to25, A_Burnover25, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [126, 5] <- "(1 | UniqueID)"
table.aic [126, 6] <- AIC (model.lme.fxn.du8.s.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du8.s.6to25.over25, type = 'response'), fire.data.du.8.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [126, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [113, 6] - min (table.aic [113:126, 6])))), 
                    (exp (-0.5 * (table.aic [114, 6] - min (table.aic [113:126, 6])))),
                    (exp (-0.5 * (table.aic [115, 6] - min (table.aic [113:126, 6])))),
                    (exp (-0.5 * (table.aic [116, 6] - min (table.aic [113:126, 6])))),
                    (exp (-0.5 * (table.aic [117, 6] - min (table.aic [113:126, 6])))),
                    (exp (-0.5 * (table.aic [118, 6] - min (table.aic [113:126, 6])))),
                    (exp (-0.5 * (table.aic [119, 6] - min (table.aic [113:126, 6])))),
                    (exp (-0.5 * (table.aic [120, 6] - min (table.aic [113:126, 6])))),
                    (exp (-0.5 * (table.aic [121, 6] - min (table.aic [113:126, 6])))), 
                    (exp (-0.5 * (table.aic [122, 6] - min (table.aic [113:126, 6])))),
                    (exp (-0.5 * (table.aic [123, 6] - min (table.aic [113:126, 6])))),
                    (exp (-0.5 * (table.aic [124, 6] - min (table.aic [113:126, 6])))),
                    (exp (-0.5 * (table.aic [125, 6] - min (table.aic [113:126, 6])))),
                    (exp (-0.5 * (table.aic [126, 6] - min (table.aic [113:126, 6])))))
table.aic [113, 7] <- round ((exp (-0.5 * (table.aic [113, 6] - min (table.aic [113:126, 6])))) / sum (list.aic.like), 3)
table.aic [114, 7] <- round ((exp (-0.5 * (table.aic [114, 6] - min (table.aic [113:126, 6])))) / sum (list.aic.like), 3)
table.aic [115, 7] <- round ((exp (-0.5 * (table.aic [115, 6] - min (table.aic [113:126, 6])))) / sum (list.aic.like), 3)
table.aic [116, 7] <- round ((exp (-0.5 * (table.aic [116, 6] - min (table.aic [113:126, 6])))) / sum (list.aic.like), 3)
table.aic [117, 7] <- round ((exp (-0.5 * (table.aic [117, 6] - min (table.aic [113:126, 6])))) / sum (list.aic.like), 3)
table.aic [118, 7] <- round ((exp (-0.5 * (table.aic [118, 6] - min (table.aic [113:126, 6])))) / sum (list.aic.like), 3)
table.aic [119, 7] <- round ((exp (-0.5 * (table.aic [119, 6] - min (table.aic [113:126, 6])))) / sum (list.aic.like), 3)
table.aic [120, 7] <- round ((exp (-0.5 * (table.aic [120, 6] - min (table.aic [113:126, 6])))) / sum (list.aic.like), 3)
table.aic [121, 7] <- round ((exp (-0.5 * (table.aic [121, 6] - min (table.aic [113:126, 6])))) / sum (list.aic.like), 3)
table.aic [122, 7] <- round ((exp (-0.5 * (table.aic [122, 6] - min (table.aic [113:126, 6])))) / sum (list.aic.like), 3)
table.aic [123, 7] <- round ((exp (-0.5 * (table.aic [123, 6] - min (table.aic [113:126, 6])))) / sum (list.aic.like), 3)
table.aic [124, 7] <- round ((exp (-0.5 * (table.aic [124, 6] - min (table.aic [113:126, 6])))) / sum (list.aic.like), 3)
table.aic [125, 7] <- round ((exp (-0.5 * (table.aic [125, 6] - min (table.aic [113:126, 6])))) / sum (list.aic.like), 3)
table.aic [126, 7] <- round ((exp (-0.5 * (table.aic [126, 6] - min (table.aic [113:126, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_fire.csv", sep = ",")

# save the top model
save (model.lme.du8.s.6to25.over25, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\fire\\model_lme_du8_s_top.rda")




#===============
## DU9 ##
#==============
## Early Winter
### Correlation
corr.fire.du.9.ew <- round (cor (fire.data.du.9.ew [10:12], method = "spearman"), 3)
ggcorrplot (corr.fire.du.9.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Fire Age Correlation DU9 Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_fire_corr_du_9_ew.png")

### VIF
model.glm.du9.ew <- glm (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo, 
                         data = fire.data.du.9.ew,
                         family = binomial (link = 'logit'))
vif (model.glm.du9.ew) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du9.ew <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo + 
                                     (fire_1to5yo | uniqueID) + 
                                     (fire_6to25yo | uniqueID) +
                                     (fire_over25yo | uniqueID), 
                           data = fire.data.du.9.ew, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [127, 1] <- "DU9"
table.aic [127, 2] <- "Early Winter"
table.aic [127, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [127, 4] <- "Burn1to5, Burn6to25, Burnover25"
table.aic [127, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [127, 6] <- AIC (model.lme.du9.ew)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.ew, type = 'response'), fire.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [127, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.du9.ew.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                        (fire_1to5yo | uniqueID), 
                           data = fire.data.du.9.ew, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [128, 1] <- "DU9"
table.aic [128, 2] <- "Early Winter"
table.aic [128, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [128, 4] <- "Burn1to5"
table.aic [128, 5] <- "(Burn1to5 | UniqueID)"
table.aic [128, 6] <- AIC (model.lme.du9.ew.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.ew.1to5, type = 'response'), fire.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [128, 8] <- auc.temp@y.values[[1]]


# 6to25
model.lme.du9.ew.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                          (fire_6to25yo | uniqueID), 
                                data = fire.data.du.9.ew, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [129, 1] <- "DU9"
table.aic [129, 2] <- "Early Winter"
table.aic [129, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [129, 4] <- "Burn6to25"
table.aic [129, 5] <- "(Burn6to25 | UniqueID)"
table.aic [129, 6] <- AIC (model.lme.du9.ew.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.ew.6to25, type = 'response'), fire.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [129, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.du9.ew.over25 <- glmer (pttype ~ fire_over25yo + 
                                            (fire_over25yo | uniqueID), 
                                 data = fire.data.du.9.ew, 
                                 family = binomial (link = "logit"),
                                 verbose = T,
                                 control = glmerControl (calc.derivs = FALSE, 
                                                         optimizer = "nloptwrap", 
                                                         optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [130, 1] <- "DU9"
table.aic [130, 2] <- "Early Winter"
table.aic [130, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [130, 4] <- "Burnover25"
table.aic [130, 5] <- "(Burnover25 | UniqueID)"
table.aic [130, 6] <- AIC (model.lme.du9.ew.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.ew.over25, type = 'response'), fire.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [130, 8] <- auc.temp@y.values[[1]]

# 1to5, 6to25
model.lme.du9.ew.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + 
                                                (fire_1to5yo | uniqueID) + 
                                                (fire_6to25yo | uniqueID), 
                                  data = fire.data.du.9.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [131, 1] <- "DU9"
table.aic [131, 2] <- "Early Winter"
table.aic [131, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [131, 4] <- "Burn1to5, Burn6to25"
table.aic [131, 5] <- "(Burn1to5 | UniqueID), (Burn6to25 | UniqueID)"
table.aic [131, 6] <- AIC (model.lme.du9.ew.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.ew.1to5.6to25, type = 'response'), fire.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [131, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.du9.ew.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo + 
                                                (fire_1to5yo | uniqueID) + 
                                                (fire_over25yo | uniqueID), 
                                      data = fire.data.du.9.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T,
                                      control = glmerControl (calc.derivs = FALSE, 
                                                              optimizer = "nloptwrap", 
                                                              optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [132, 1] <- "DU9"
table.aic [132, 2] <- "Early Winter"
table.aic [132, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [132, 4] <- "Burn1to5, Burnover25"
table.aic [132, 5] <- "(Burn1to5 | UniqueID), (Burnover25 | UniqueID)"
table.aic [132, 6] <- AIC (model.lme.du9.ew.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.ew.1to5.over25, type = 'response'), fire.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [132, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.du9.ew.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo + 
                                                   (fire_6to25yo | uniqueID) + 
                                                   (fire_over25yo | uniqueID), 
                                       data = fire.data.du.9.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T,
                                       control = glmerControl (calc.derivs = FALSE, 
                                                               optimizer = "nloptwrap", 
                                                               optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [133, 1] <- "DU9"
table.aic [133, 2] <- "Early Winter"
table.aic [133, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [133, 4] <- "Burn6to25, Burnover25"
table.aic [133, 5] <- "(Burn6to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [133, 6] <- AIC (model.lme.du9.ew.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.ew.6to25.over25, type = 'response'), fire.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [133, 8] <- auc.temp@y.values[[1]]

# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (fire.data.du.9.ew, pttype == 0)
fire_1to5yo_E <- tapply (sub$fire_1to5yo, sub$uniqueID, sum)
fire_6to25yo_E <- tapply (sub$fire_6to25yo, sub$uniqueID, sum)
fire_over25yo_E <- tapply (sub$fire_over25yo, sub$uniqueID, sum)
inds <- as.character (fire.data.du.9.ew$uniqueID)
fire.data.du.9.ew <- cbind (fire.data.du.9.ew, 
                           "fire_1to5yo_E" = fire_1to5yo_E [inds],
                           "fire_6to25yo_E" = fire_6to25yo_E [inds],
                           "fire_over25yo_E" = fire_over25yo_E [inds])

# Functional Responses
# All COVARS
model.lme.fxn.du9.ew.all <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + fire_over25yo +
                                            fire_1to5yo_E + fire_6to25yo_E + fire_over25yo_E + 
                                            fire_1to5yo:fire_1to5yo_E +
                                            fire_6to25yo:fire_6to25yo_E +
                                            fire_over25yo:fire_over25yo_E +
                                            (1 | uniqueID), 
                                  data = fire.data.du.9.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [134, 1] <- "DU9"
table.aic [134, 2] <- "Early Winter"
table.aic [134, 3] <- "GLMM with Functional Response"
table.aic [134, 4] <- "Burn1to5, Burn6to25, Burnover25, A_Burn1to5, A_Burn6to25, A_Burnover25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [134, 5] <- "(1 | UniqueID)"
table.aic [134, 6] <- AIC (model.lme.fxn.du9.ew.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.ew.all, type = 'response'), fire.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [134, 8] <- auc.temp@y.values[[1]]

# 1to5
model.lme.fxn.du9.ew.1to5 <- glmer (pttype ~ fire_1to5yo + 
                                              fire_1to5yo_E + 
                                              fire_1to5yo:fire_1to5yo_E +
                                              (1 | uniqueID), 
                                   data = fire.data.du.9.ew, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [135, 1] <- "DU9"
table.aic [135, 2] <- "Early Winter"
table.aic [135, 3] <- "GLMM with Functional Response"
table.aic [135, 4] <- "Burn1to5, A_Burn1to5, Burn1to5*A_Burn1to5"
table.aic [135, 5] <- "(1 | UniqueID)"
table.aic [135, 6] <- AIC (model.lme.fxn.du9.ew.1to5)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.ew.1to5, type = 'response'), fire.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [135, 8] <- auc.temp@y.values[[1]]

# 6to25
model.lme.fxn.du9.ew.6to25 <- glmer (pttype ~ fire_6to25yo + 
                                               fire_6to25yo_E + 
                                               fire_6to25yo:fire_6to25yo_E +
                                               (1 | uniqueID), 
                                    data = fire.data.du.9.ew, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [136, 1] <- "DU9"
table.aic [136, 2] <- "Early Winter"
table.aic [136, 3] <- "GLMM with Functional Response"
table.aic [136, 4] <- "Burn6to25, A_Burn6to25, Burn6to25*A_Burn6to25"
table.aic [136, 5] <- "(1 | UniqueID)"
table.aic [136, 6] <- AIC (model.lme.fxn.du9.ew.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.ew.6to25, type = 'response'), fire.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [136, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.fxn.du9.ew.over25 <- glmer (pttype ~ fire_over25yo + 
                                                fire_over25yo_E + 
                                                fire_over25yo:fire_over25yo_E +
                                                (1 | uniqueID), 
                                     data = fire.data.du.9.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, 
                                                             optimizer = "nloptwrap", 
                                                             optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [137, 1] <- "DU9"
table.aic [137, 2] <- "Early Winter"
table.aic [137, 3] <- "GLMM with Functional Response"
table.aic [137, 4] <- "Burnover25, A_Burnover25, Burnover25*A_Burnover25"
table.aic [137, 5] <- "(1 | UniqueID)"
table.aic [137, 6] <- AIC (model.lme.fxn.du9.ew.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.ew.over25, type = 'response'), fire.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [137, 8] <- auc.temp@y.values[[1]]

# 1to5, 6to25
model.lme.fxn.du9.ew.1to5.6to25 <- glmer (pttype ~ fire_1to5yo + fire_6to25yo + 
                                                    fire_1to5yo_E + fire_6to25yo_E + 
                                                    fire_1to5yo:fire_1to5yo_E +
                                                    fire_6to25yo:fire_6to25yo_E +
                                                    (1 | uniqueID), 
                                      data = fire.data.du.9.ew, 
                                      family = binomial (link = "logit"),
                                      verbose = T,
                                      control = glmerControl (calc.derivs = FALSE, 
                                                              optimizer = "nloptwrap", 
                                                              optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [138, 1] <- "DU9"
table.aic [138, 2] <- "Early Winter"
table.aic [138, 3] <- "GLMM with Functional Response"
table.aic [138, 4] <- "Burn1to5, Burn6to25, A_Burn1to5, A_Burn6to25, Burn1to5*A_Burn1to5, Burn6to25*A_Burn6to25"
table.aic [138, 5] <- "(1 | UniqueID)"
table.aic [138, 6] <- AIC (model.lme.fxn.du9.ew.1to5.6to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.ew.1to5.6to25, type = 'response'), fire.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [138, 8] <- auc.temp@y.values[[1]]

# 1to5, over25
model.lme.fxn.du9.ew.1to5.over25 <- glmer (pttype ~ fire_1to5yo + fire_over25yo + 
                                                    fire_1to5yo_E + fire_over25yo_E + 
                                                    fire_1to5yo:fire_1to5yo_E +
                                                    fire_over25yo:fire_over25yo_E +
                                                    (1 | uniqueID), 
                                          data = fire.data.du.9.ew, 
                                          family = binomial (link = "logit"),
                                          verbose = T,
                                          control = glmerControl (calc.derivs = FALSE, 
                                                                  optimizer = "nloptwrap", 
                                                                  optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [139, 1] <- "DU9"
table.aic [139, 2] <- "Early Winter"
table.aic [139, 3] <- "GLMM with Functional Response"
table.aic [139, 4] <- "Burn1to5, Burnover25, A_Burn1to5, A_Burnover25, Burn1to5*A_Burn1to5, Burnover25*A_Burnover25"
table.aic [139, 5] <- "(1 | UniqueID)"
table.aic [139, 6] <- AIC (model.lme.fxn.du9.ew.1to5.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.ew.1to5.over25, type = 'response'), fire.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [139, 8] <- auc.temp@y.values[[1]]

# 6to25, over25
model.lme.fxn.du9.ew.6to25.over25 <- glmer (pttype ~ fire_6to25yo + fire_over25yo + 
                                                      fire_6to25yo_E + fire_over25yo_E + 
                                                      fire_6to25yo:fire_6to25yo_E +
                                                      fire_over25yo:fire_over25yo_E +
                                                      (1 | uniqueID), 
                                           data = fire.data.du.9.ew, 
                                           family = binomial (link = "logit"),
                                           verbose = T,
                                           control = glmerControl (calc.derivs = FALSE, 
                                                                   optimizer = "nloptwrap", 
                                                                   optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [140, 1] <- "DU9"
table.aic [140, 2] <- "Early Winter"
table.aic [140, 3] <- "GLMM with Functional Response"
table.aic [140, 4] <- "Burn6to25, Burnover25, A_Burn6to25, A_Burnover25, Burn6to25*A_Burn6to25, Burnover25*A_Burnover25"
table.aic [140, 5] <- "(1 | UniqueID)"
table.aic [140, 6] <- AIC (model.lme.fxn.du9.ew.6to25.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.ew.6to25.over25, type = 'response'), fire.data.du.9.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [140, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [127, 6] - min (table.aic [127:139, 6])))), 
                    (exp (-0.5 * (table.aic [128, 6] - min (table.aic [127:139, 6])))),
                    (exp (-0.5 * (table.aic [129, 6] - min (table.aic [127:139, 6])))),
                    (exp (-0.5 * (table.aic [130, 6] - min (table.aic [127:139, 6])))),
                    (exp (-0.5 * (table.aic [131, 6] - min (table.aic [127:139, 6])))),
                    (exp (-0.5 * (table.aic [132, 6] - min (table.aic [127:139, 6])))),
                    (exp (-0.5 * (table.aic [133, 6] - min (table.aic [127:139, 6])))),
                    (exp (-0.5 * (table.aic [134, 6] - min (table.aic [127:139, 6])))),
                    (exp (-0.5 * (table.aic [135, 6] - min (table.aic [127:139, 6])))), 
                    (exp (-0.5 * (table.aic [136, 6] - min (table.aic [127:139, 6])))),
                    (exp (-0.5 * (table.aic [137, 6] - min (table.aic [127:139, 6])))),
                    (exp (-0.5 * (table.aic [138, 6] - min (table.aic [127:139, 6])))),
                    (exp (-0.5 * (table.aic [139, 6] - min (table.aic [127:139, 6])))))
                   # (exp (-0.5 * (table.aic [126, 6] - min (table.aic [127:139, 6])))))
table.aic [127, 7] <- round ((exp (-0.5 * (table.aic [127, 6] - min (table.aic [127:139, 6])))) / sum (list.aic.like), 3)
table.aic [128, 7] <- round ((exp (-0.5 * (table.aic [128, 6] - min (table.aic [127:139, 6])))) / sum (list.aic.like), 3)
table.aic [129, 7] <- round ((exp (-0.5 * (table.aic [129, 6] - min (table.aic [127:139, 6])))) / sum (list.aic.like), 3)
table.aic [130, 7] <- round ((exp (-0.5 * (table.aic [130, 6] - min (table.aic [127:139, 6])))) / sum (list.aic.like), 3)
table.aic [131, 7] <- round ((exp (-0.5 * (table.aic [131, 6] - min (table.aic [127:139, 6])))) / sum (list.aic.like), 3)
table.aic [132, 7] <- round ((exp (-0.5 * (table.aic [132, 6] - min (table.aic [127:139, 6])))) / sum (list.aic.like), 3)
table.aic [133, 7] <- round ((exp (-0.5 * (table.aic [133, 6] - min (table.aic [127:139, 6])))) / sum (list.aic.like), 3)
table.aic [134, 7] <- round ((exp (-0.5 * (table.aic [134, 6] - min (table.aic [127:139, 6])))) / sum (list.aic.like), 3)
table.aic [135, 7] <- round ((exp (-0.5 * (table.aic [135, 6] - min (table.aic [127:139, 6])))) / sum (list.aic.like), 3)
table.aic [136, 7] <- round ((exp (-0.5 * (table.aic [136, 6] - min (table.aic [127:139, 6])))) / sum (list.aic.like), 3)
table.aic [137, 7] <- round ((exp (-0.5 * (table.aic [137, 6] - min (table.aic [127:139, 6])))) / sum (list.aic.like), 3)
table.aic [138, 7] <- round ((exp (-0.5 * (table.aic [138, 6] - min (table.aic [127:139, 6])))) / sum (list.aic.like), 3)
table.aic [139, 7] <- round ((exp (-0.5 * (table.aic [139, 6] - min (table.aic [127:139, 6])))) / sum (list.aic.like), 3)
table.aic [140, 7] <- NA

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_fire.csv", sep = ",")

# save the top model
save (model.lme.du8.s.6to25.over25, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\fire\\model_lme_du8_s_top.rda")



## Late Winter
### Correlation
corr.fire.du.9.lw <- round (cor (fire.data.du.9.lw [10:12], method = "spearman"), 3)
ggcorrplot (corr.fire.du.9.lw, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Fire Age Correlation DU9 Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_fire_corr_du_9_lw.png")


fire.data.du.9.lw$fire_1to25yo <- fire.data.du.9.lw$fire_1to5yo + fire.data.du.9.lw$fire_6to25yo
max (fire.data.du.9.lw$fire_1to25yo)

### VIF
model.glm.du9.lw <- glm (pttype ~ fire_1to25yo + fire_over25yo, 
                         data = fire.data.du.9.lw,
                         family = binomial (link = 'logit'))
vif (model.glm.du9.lw) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du9.lw <- glmer (pttype ~ fire_1to25yo +fire_over25yo + 
                                     (fire_1to25yo | uniqueID) +
                                     (fire_over25yo | uniqueID), 
                           data = fire.data.du.9.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [141, 1] <- "DU9"
table.aic [141, 2] <- "Late Winter"
table.aic [141, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [141, 4] <- "Burn1to25, Burnover25"
table.aic [141, 5] <- "(Burn1to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [141, 6] <- AIC (model.lme.du9.lw)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.lw, type = 'response'), fire.data.du.9.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [141, 8] <- auc.temp@y.values[[1]]

# 1to25
model.lme.du9.lw.1to25 <- glmer (pttype ~ fire_1to25yo +
                                          (fire_1to25yo | uniqueID), 
                           data = fire.data.du.9.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [142, 1] <- "DU9"
table.aic [142, 2] <- "Late Winter"
table.aic [142, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [142, 4] <- "Burn1to25"
table.aic [142, 5] <- "(Burn1to25 | UniqueID)"
table.aic [142, 6] <- AIC (model.lme.du9.lw.1to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.lw.1to25, type = 'response'), fire.data.du.9.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [142, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.du9.lw.over25 <- glmer (pttype ~ fire_over25yo +
                                          (fire_over25yo | uniqueID), 
                                 data = fire.data.du.9.lw, 
                                 family = binomial (link = "logit"),
                                 verbose = T,
                                 control = glmerControl (calc.derivs = FALSE, 
                                                         optimizer = "nloptwrap", 
                                                         optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [143, 1] <- "DU9"
table.aic [143, 2] <- "Late Winter"
table.aic [143, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [143, 4] <- "Burnover25"
table.aic [143, 5] <- "(Burnover25 | UniqueID)"
table.aic [143, 6] <- AIC (model.lme.du9.lw.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.lw.over25, type = 'response'), fire.data.du.9.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [143, 8] <- auc.temp@y.values[[1]]


# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (fire.data.du.9.lw, pttype == 0)
fire_1to25yo_E <- tapply (sub$fire_1to25yo, sub$uniqueID, sum)
fire_over25yo_E <- tapply (sub$fire_over25yo, sub$uniqueID, sum)
inds <- as.character (fire.data.du.9.lw$uniqueID)
fire.data.du.9.lw <- cbind (fire.data.du.9.lw, 
                            "fire_1to25yo_E" = fire_1to25yo_E [inds],
                            "fire_over25yo_E" = fire_over25yo_E [inds])

# Functional Responses
# All COVARS
model.lme.fxn.du9.lw.all <- glmer (pttype ~ fire_1to25yo + fire_over25yo +
                                            fire_1to25yo_E + fire_over25yo_E + 
                                             fire_1to25yo:fire_1to25yo_E +
                                             fire_over25yo:fire_over25yo_E +
                                             (1 | uniqueID), 
                                   data = fire.data.du.9.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [144, 1] <- "DU9"
table.aic [144, 2] <- "Late Winter"
table.aic [144, 3] <- "GLMM with Functional Response"
table.aic [144, 4] <- "Burn1to25, Burnover25, A_Burn1to25, A_Burnover25, Burn1to25*A_Burn1to25, Burnover25*A_Burnover25"
table.aic [144, 5] <- "(1 | UniqueID)"
table.aic [144, 6] <- AIC (model.lme.fxn.du9.lw.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.lw.all, type = 'response'), fire.data.du.9.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [144, 8] <- auc.temp@y.values[[1]]

# 1to25
model.lme.fxn.du9.lw.1to25 <- glmer (pttype ~ fire_1to25yo + 
                                              fire_1to25yo_E + 
                                              fire_1to25yo:fire_1to25yo_E +
                                              (1 | uniqueID), 
                                   data = fire.data.du.9.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [145, 1] <- "DU9"
table.aic [145, 2] <- "Late Winter"
table.aic [145, 3] <- "GLMM with Functional Response"
table.aic [145, 4] <- "Burn1to25, A_Burn1to25, Burn1to25*A_Burn1to25"
table.aic [145, 5] <- "(1 | UniqueID)"
table.aic [145, 6] <- AIC (model.lme.fxn.du9.lw.1to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.lw.1to25, type = 'response'), fire.data.du.9.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [145, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.fxn.du9.lw.over25 <- glmer (pttype ~ fire_over25yo + 
                                                fire_over25yo_E + 
                                                fire_over25yo:fire_over25yo_E +
                                                (1 | uniqueID), 
                                     data = fire.data.du.9.lw, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, 
                                                             optimizer = "nloptwrap", 
                                                             optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [146, 1] <- "DU9"
table.aic [146, 2] <- "Late Winter"
table.aic [146, 3] <- "GLMM with Functional Response"
table.aic [146, 4] <- "Burnover25, A_Burnover25, Burnover25*A_Burnover25"
table.aic [146, 5] <- "(1 | UniqueID)"
table.aic [146, 6] <- AIC (model.lme.fxn.du9.lw.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.lw.over25, type = 'response'), fire.data.du.9.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [146, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [141, 6] - min (table.aic [141:146, 6])))), 
                    (exp (-0.5 * (table.aic [142, 6] - min (table.aic [141:146, 6])))),
                    (exp (-0.5 * (table.aic [143, 6] - min (table.aic [141:146, 6])))),
                    (exp (-0.5 * (table.aic [144, 6] - min (table.aic [141:146, 6])))),
                    (exp (-0.5 * (table.aic [145, 6] - min (table.aic [141:146, 6])))),
                    (exp (-0.5 * (table.aic [146, 6] - min (table.aic [141:146, 6])))))
table.aic [141, 7] <- round ((exp (-0.5 * (table.aic [141, 6] - min (table.aic [141:146, 6])))) / sum (list.aic.like), 3)
table.aic [142, 7] <- round ((exp (-0.5 * (table.aic [142, 6] - min (table.aic [141:146, 6])))) / sum (list.aic.like), 3)
table.aic [143, 7] <- round ((exp (-0.5 * (table.aic [143, 6] - min (table.aic [141:146, 6])))) / sum (list.aic.like), 3)
table.aic [144, 7] <- round ((exp (-0.5 * (table.aic [144, 6] - min (table.aic [141:146, 6])))) / sum (list.aic.like), 3)
table.aic [145, 7] <- round ((exp (-0.5 * (table.aic [145, 6] - min (table.aic [141:146, 6])))) / sum (list.aic.like), 3)
table.aic [146, 7] <- round ((exp (-0.5 * (table.aic [146, 6] - min (table.aic [141:146, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_fire.csv", sep = ",")

# save the top model
save (model.lme.du8.s.6to25.over25, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\fire\\model_lme_du8_s_top.rda")


## Summer
### Correlation
corr.fire.du.9.s <- round (cor (fire.data.du.9.s [10:12], method = "spearman"), 3)
ggcorrplot (corr.fire.du.9.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Fire Age Correlation DU9 Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_fire_corr_du_9_s.png")

fire.data.du.9.s$fire_1to25yo <- fire.data.du.9.s$fire_1to5yo + fire.data.du.9.s$fire_6to25yo
max (fire.data.du.9.s$fire_1to25yo)

### VIF
model.glm.du9.s <- glm (pttype ~ fire_1to25yo + fire_over25yo, 
                         data = fire.data.du.9.s,
                         family = binomial (link = 'logit'))
vif (model.glm.du9.s) 

# Generalized Linear Mixed Models (GLMMs)
# ALL COVARS
model.lme.du9.s <- glmer (pttype ~ fire_1to25yo +fire_over25yo + 
                                   (fire_1to25yo | uniqueID) +
                                   (fire_over25yo | uniqueID), 
                           data = fire.data.du.9.s, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, 
                                                   optimizer = "nloptwrap", 
                                                   optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [147, 1] <- "DU9"
table.aic [147, 2] <- "Summer"
table.aic [147, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [147, 4] <- "Burn1to25, Burnover25"
table.aic [147, 5] <- "(Burn1to25 | UniqueID), (Burnover25 | UniqueID)"
table.aic [147, 6] <- AIC (model.lme.du9.s)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.s, type = 'response'), fire.data.du.9.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [147, 8] <- auc.temp@y.values[[1]]

# 1to25
model.lme.du9.s.1to25 <- glmer (pttype ~ fire_1to25yo + 
                                         (fire_1to25yo | uniqueID), 
                          data = fire.data.du.9.s, 
                          family = binomial (link = "logit"),
                          verbose = T,
                          control = glmerControl (calc.derivs = FALSE, 
                                                  optimizer = "nloptwrap", 
                                                  optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [148, 1] <- "DU9"
table.aic [148, 2] <- "Summer"
table.aic [148, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [148, 4] <- "Burn1to25"
table.aic [148, 5] <- "(Burn1to25 | UniqueID)"
table.aic [148, 6] <- AIC (model.lme.du9.s.1to25)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.s.1to25, type = 'response'), fire.data.du.9.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [148, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.du9.s.over25 <- glmer (pttype ~ fire_over25yo + 
                                          (fire_over25yo | uniqueID), 
                                data = fire.data.du.9.s, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, 
                                                        optimizer = "nloptwrap", 
                                                        optCtrl = list (maxfun = 2e5)))

# AIC
table.aic [149, 1] <- "DU9"
table.aic [149, 2] <- "Summer"
table.aic [149, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [149, 4] <- "Burnover25"
table.aic [149, 5] <- "(Burnover25 | UniqueID)"
table.aic [149, 6] <- AIC (model.lme.du9.s.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.du9.s.over25, type = 'response'), fire.data.du.9.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [149, 8] <- auc.temp@y.values[[1]]

# FUNCTIONAL RESPONSE
# All Covariates
sub <- subset (fire.data.du.9.s, pttype == 0)
fire_1to25yo_E <- tapply (sub$fire_1to25yo, sub$uniqueID, sum)
fire_over25yo_E <- tapply (sub$fire_over25yo, sub$uniqueID, sum)
inds <- as.character (fire.data.du.9.s$uniqueID)
fire.data.du.9.s <- cbind (fire.data.du.9.s, 
                            "fire_1to25yo_E" = fire_1to25yo_E [inds],
                            "fire_over25yo_E" = fire_over25yo_E [inds])

# Functional Responses
# All COVARS
model.lme.fxn.du9.s.all <- glmer (pttype ~ fire_1to25yo + fire_over25yo +
                                     fire_1to25yo_E + fire_over25yo_E + 
                                     fire_1to25yo:fire_1to25yo_E +
                                     fire_over25yo:fire_over25yo_E +
                                     (1 | uniqueID), 
                                   data = fire.data.du.9.s, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, 
                                                           optimizer = "nloptwrap", 
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [150, 1] <- "DU9"
table.aic [150, 2] <- "Summer"
table.aic [150, 3] <- "GLMM with Functional Response"
table.aic [150, 4] <- "Burn1to25, Burnover25, A_Burn1to25, A_Burnover25, Burn1to25*A_Burn1to25, Burnover25*A_Burnover25"
table.aic [150, 5] <- "(1 | UniqueID)"
table.aic [150, 6] <- AIC (model.lme.fxn.du9.s.all)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.s.all, type = 'response'), fire.data.du.9.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [150, 8] <- auc.temp@y.values[[1]]

# 1to25
model.lme.fxn.du9.s.1to25 <- glmer (pttype ~ fire_1to25yo + 
                                             fire_1to25yo_E + 
                                             fire_1to25yo:fire_1to25yo_E +
                                             (1 | uniqueID), 
                                  data = fire.data.du.9.s, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, 
                                                          optimizer = "nloptwrap", 
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [151, 1] <- "DU9"
table.aic [151, 2] <- "Summer"
table.aic [151, 3] <- "GLMM with Functional Response"
table.aic [151, 4] <- "Burn1to25, A_Burn1to25, Burn1to25*A_Burn1to25"
table.aic [151, 5] <- "(1 | UniqueID)"
table.aic [151, 6] <- AIC (model.lme.fxn.du9.s.1to25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.s.1to25, type = 'response'), fire.data.du.9.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [151, 8] <- auc.temp@y.values[[1]]

# over25
model.lme.fxn.du9.s.over25 <- glmer (pttype ~ fire_over25yo + 
                                               fire_over25yo_E + 
                                               fire_over25yo:fire_over25yo_E +
                                               (1 | uniqueID), 
                                    data = fire.data.du.9.s, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, 
                                                            optimizer = "nloptwrap", 
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [152, 1] <- "DU9"
table.aic [152, 2] <- "Summer"
table.aic [152, 3] <- "GLMM with Functional Response"
table.aic [152, 4] <- "Burnover25, A_Burnover25, Burnover25*A_Burnover25"
table.aic [152, 5] <- "(1 | UniqueID)"
table.aic [152, 6] <- AIC (model.lme.fxn.du9.s.over25)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du9.s.over25, type = 'response'), fire.data.du.9.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [152, 8] <- auc.temp@y.values[[1]]

# AIC comparison 
list.aic.like <- c ((exp (-0.5 * (table.aic [147, 6] - min (table.aic [147:152, 6])))), 
                    (exp (-0.5 * (table.aic [148, 6] - min (table.aic [147:152, 6])))),
                    (exp (-0.5 * (table.aic [149, 6] - min (table.aic [147:152, 6])))),
                    (exp (-0.5 * (table.aic [150, 6] - min (table.aic [147:152, 6])))),
                    (exp (-0.5 * (table.aic [151, 6] - min (table.aic [147:152, 6])))),
                    (exp (-0.5 * (table.aic [152, 6] - min (table.aic [147:152, 6])))))
table.aic [147, 7] <- round ((exp (-0.5 * (table.aic [147, 6] - min (table.aic [147:152, 6])))) / sum (list.aic.like), 3)
table.aic [148, 7] <- round ((exp (-0.5 * (table.aic [148, 6] - min (table.aic [147:152, 6])))) / sum (list.aic.like), 3)
table.aic [149, 7] <- round ((exp (-0.5 * (table.aic [149, 6] - min (table.aic [147:152, 6])))) / sum (list.aic.like), 3)
table.aic [150, 7] <- round ((exp (-0.5 * (table.aic [150, 6] - min (table.aic [147:152, 6])))) / sum (list.aic.like), 3)
table.aic [151, 7] <- round ((exp (-0.5 * (table.aic [151, 6] - min (table.aic [147:152, 6])))) / sum (list.aic.like), 3)
table.aic [152, 7] <- round ((exp (-0.5 * (table.aic [152, 6] - min (table.aic [147:152, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_fire.csv", sep = ",")

# save the top model
save (model.lme.du8.s.6to25.over25, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\fire\\model_lme_du8_s_top.rda")
