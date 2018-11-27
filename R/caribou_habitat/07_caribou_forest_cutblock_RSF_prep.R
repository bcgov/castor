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
#  Script Name: 07_caribou_forest_cutblock_RSF_prep_full_script.R
#  Script Version: 1.0
#  Script Purpose: Script exploring/analysing distance to forest cutblock data to identify covariates to 
#                 include in RSF model.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 16 November 2018
#  R Version: 
#  R Packages: sf, RPostgreSQL, rpostgis, fasterize, raster, dplyr
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
# Cutblocks Data
#===============
rsf.data.cut.age <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_cutblock_age.csv")

#=================================
# Data exploration/visualization
#=================================
# Correlations
# broke into 10 year chunks;
# first 10 years
dist.cut.1.10.corr <- rsf.data.cut.age [c (10:19)]
corr.1.10 <- round (cor (dist.cut.1.10.corr, method = "spearman"), 3)
p.mat.1.10 <- round (cor_pmat (dist.cut.1.10.corr), 2)
ggcorrplot (corr.1.10, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Distance to Cutblock Correlation Years 1 to 10")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_1_10.png")
# ggcorrplot (corr, type = "lower", p.mat = p.mat, insig = "blank")

# 10-20  years
dist.cut.11.20.corr <- rsf.data.cut.age [c (20:29)]
corr.11.20 <- round (cor (dist.cut.11.20.corr, method = "spearman"), 3)
p.mat.11.20 <- round (cor_pmat (dist.cut.11.20.corr), 2)
ggcorrplot (corr.11.20, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Distance to Cutblock Correlation Years 11 to 20")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_11_20.png")

# 21-30  years
dist.cut.21.30.corr <- rsf.data.cut.age [c (30:39)]
corr.21.30 <- round (cor (dist.cut.21.30.corr, method = "spearman"), 3)
p.mat.21.30 <- round (cor_pmat (dist.cut.21.30.corr), 2)
ggcorrplot (corr.21.30, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Distance to Cutblock Correlation Years 21 to 30")

# 31-40  years
dist.cut.31.40.corr <- rsf.data.cut.age [c (40:49)]
corr.31.40 <- round (cor (dist.cut.31.40.corr, method = "spearman"), 3)
p.mat.31.40 <- round (cor_pmat (dist.cut.31.40.corr), 2)
ggcorrplot (corr.31.40, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Distance to Cutblock Correlation Years 31 to 40")

# >41  years
dist.cut.41.50.corr <- rsf.data.cut.age [c (50:60)]
corr.41.50 <- round (cor (dist.cut.41.50.corr, method = "spearman"), 3)
p.mat.41.50 <- round (cor_pmat (dist.cut.41.50.corr), 2)
ggcorrplot (corr.41.50, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Distance to Cutblock Correlation Years 41 to >50")

#########
## DU6 ## 
#########
dist.cut.corr.du.6 <- rsf.data.cut.age %>%
  dplyr::filter (du == "du6")

dist.cut.1.10.corr.du.6 <- dist.cut.corr.du.6 [c (10:19)]
corr.1.10.du6 <- round (cor (dist.cut.1.10.corr.du.6, method = "spearman"), 3)
p.mat.1.10 <- round (cor_pmat (corr.1.10.du6), 2)
ggcorrplot (corr.1.10.du6, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU6 Distance to Cutblock Correlation Years 1 to 10")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_1_10_du6.png")

dist.cut.11.20.corr.du.6 <- dist.cut.corr.du.6 [c (20:29)]
corr.11.20.du6 <- round (cor (dist.cut.11.20.corr.du.6, method = "spearman"), 3)
p.mat.11.20 <- round (cor_pmat (corr.11.20.du6), 2)
ggcorrplot (corr.11.20.du6, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU6 Distance to Cutblock Correlation Years 11 to 20")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_11_20_du6.png")

dist.cut.21.30.corr.du.6 <- dist.cut.corr.du.6 [c (30:39)]
corr.21.30.du6 <- round (cor (dist.cut.21.30.corr.du.6, method = "spearman"), 3)
p.mat.21.30 <- round (cor_pmat (corr.21.30.du6), 2)
ggcorrplot (corr.21.30.du6, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU6 Distance to Cutblock Correlation Years 21 to 30")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_21_30_du6.png")

dist.cut.31.40.corr.du.6 <- dist.cut.corr.du.6 [c (40:49)]
corr.31.40.du6 <- round (cor (dist.cut.31.40.corr.du.6, method = "spearman"), 3)
p.mat.31.40 <- round (cor_pmat (corr.31.40.du6), 2)
ggcorrplot (corr.31.40.du6, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU6 Distance to Cutblock Correlation Years 31 to 40")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_31_40_du6.png")

dist.cut.41.50.corr.du.6 <- dist.cut.corr.du.6 [c (50:60)]
corr.41.50.du6 <- round (cor (dist.cut.41.50.corr.du.6, method = "spearman"), 3)
p.mat.41.50 <- round (cor_pmat (corr.41.50.du6), 2)
ggcorrplot (corr.41.50.du6, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU6 Distance to Cutblock Correlation Years 41 to >50")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_41_50_du6.png")

#########
## DU7 ## 
#########
dist.cut.corr.du.7 <- rsf.data.cut.age %>%
  dplyr::filter (du == "du7")

dist.cut.1.10.corr.du.7 <- dist.cut.corr.du.7 [c (10:19)]
corr.1.10.du7 <- round (cor (dist.cut.1.10.corr.du.7, method = "spearman"), 3)
p.mat.1.10 <- round (cor_pmat (corr.1.10.du7), 2)
ggcorrplot (corr.1.10.du7, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU7 Distance to Cutblock Correlation Years 1 to 10")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_1_10_du7.png")

dist.cut.11.20.corr.du.7 <- dist.cut.corr.du.7 [c (20:29)]
corr.11.20.du7 <- round (cor (dist.cut.11.20.corr.du.7, method = "spearman"), 3)
p.mat.11.20 <- round (cor_pmat (corr.11.20.du7), 2)
ggcorrplot (corr.11.20.du7, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU7 Distance to Cutblock Correlation Years 11 to 20")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_11_20_du7.png")

dist.cut.21.30.corr.du.7 <- dist.cut.corr.du.7 [c (30:39)]
corr.21.30.du7 <- round (cor (dist.cut.21.30.corr.du.7, method = "spearman"), 3)
p.mat.21.30 <- round (cor_pmat (corr.21.30.du7), 2)
ggcorrplot (corr.21.30.du7, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU7 Distance to Cutblock Correlation Years 21 to 30")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_21_30_du7.png")

dist.cut.31.40.corr.du.7 <- dist.cut.corr.du.7 [c (40:49)]
corr.31.40.du7 <- round (cor (dist.cut.31.40.corr.du.7, method = "spearman"), 3)
p.mat.31.40 <- round (cor_pmat (corr.31.40.du7), 2)
ggcorrplot (corr.31.40.du7, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU7 Distance to Cutblock Correlation Years 31 to 40")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_31_40_du7.png")

dist.cut.41.50.corr.du.7 <- dist.cut.corr.du.7 [c (50:60)]
corr.41.50.du7 <- round (cor (dist.cut.41.50.corr.du.7, method = "spearman"), 3)
p.mat.41.50 <- round (cor_pmat (corr.41.50.du7), 2)
ggcorrplot (corr.41.50.du7, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU7 Distance to Cutblock Correlation Years 41 to >50")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_41_50_du7.png")

#########
## DU8 ## 
#########
dist.cut.corr.du.8 <- rsf.data.cut.age %>%
  dplyr::filter (du == "du8")

dist.cut.1.10.corr.du.8 <- dist.cut.corr.du.8 [c (10:19)]
corr.1.10.du8 <- round (cor (dist.cut.1.10.corr.du.8, method = "spearman"), 3)
p.mat.1.10 <- round (cor_pmat (corr.1.10.du8), 2)
ggcorrplot (corr.1.10.du8, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU8 Distance to Cutblock Correlation Years 1 to 10")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_1_10_du8.png")

dist.cut.11.20.corr.du.8 <- dist.cut.corr.du.8 [c (20:29)]
corr.11.20.du8 <- round (cor (dist.cut.11.20.corr.du.8, method = "spearman"), 3)
p.mat.11.20 <- round (cor_pmat (corr.11.20.du8), 2)
ggcorrplot (corr.11.20.du8, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU8 Distance to Cutblock Correlation Years 11 to 20")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_11_20_du8.png")

dist.cut.21.30.corr.du.8 <- dist.cut.corr.du.8 [c (30:39)]
corr.21.30.du8 <- round (cor (dist.cut.21.30.corr.du.8, method = "spearman"), 3)
p.mat.21.30 <- round (cor_pmat (corr.21.30.du8), 2)
ggcorrplot (corr.21.30.du8, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU8 Distance to Cutblock Correlation Years 21 to 30")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_21_30_du8.png")

dist.cut.31.40.corr.du.8 <- dist.cut.corr.du.8 [c (40:49)]
corr.31.40.du8 <- round (cor (dist.cut.31.40.corr.du.8, method = "spearman"), 3)
p.mat.31.40 <- round (cor_pmat (corr.31.40.du8), 2)
ggcorrplot (corr.31.40.du8, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU8 Distance to Cutblock Correlation Years 31 to 40")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_31_40_du8.png")

dist.cut.41.50.corr.du.8 <- dist.cut.corr.du.8 [c (50:60)]
corr.41.50.du8 <- round (cor (dist.cut.41.50.corr.du.8, method = "spearman"), 3)
p.mat.41.50 <- round (cor_pmat (corr.41.50.du8), 2)
ggcorrplot (corr.41.50.du8, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU8 Distance to Cutblock Correlation Years 41 to >50")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_41_50_du8.png")

#########
## DU9 ## 
#########
dist.cut.corr.du.9 <- rsf.data.cut.age %>%
  dplyr::filter (du == "du9")

dist.cut.1.10.corr.du.9 <- dist.cut.corr.du.9 [c (10:19)]
corr.1.10.du9 <- round (cor (dist.cut.1.10.corr.du.9, method = "spearman"), 3)
p.mat.1.10 <- round (cor_pmat (corr.1.10.du9), 2)
ggcorrplot (corr.1.10.du9, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU9 Distance to Cutblock Correlation Years 1 to 10")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_1_10_du9.png")

dist.cut.11.20.corr.du.9 <- dist.cut.corr.du.9 [c (20:29)]
corr.11.20.du9 <- round (cor (dist.cut.11.20.corr.du.9, method = "spearman"), 3)
p.mat.11.20 <- round (cor_pmat (corr.11.20.du9), 2)
ggcorrplot (corr.11.20.du9, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU9 Distance to Cutblock Correlation Years 11 to 20")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_11_20_du9.png")

dist.cut.21.30.corr.du.9 <- dist.cut.corr.du.9 [c (30:39)]
corr.21.30.du9 <- round (cor (dist.cut.21.30.corr.du.9, method = "spearman"), 3)
p.mat.21.30 <- round (cor_pmat (corr.21.30.du9), 2)
ggcorrplot (corr.21.30.du9, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU9 Distance to Cutblock Correlation Years 21 to 30")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_21_30_du9.png")

dist.cut.31.40.corr.du.9 <- dist.cut.corr.du.9 [c (40:49)]
corr.31.40.du9 <- round (cor (dist.cut.31.40.corr.du.9, method = "spearman"), 3)
p.mat.31.40 <- round (cor_pmat (corr.31.40.du9), 2)
ggcorrplot (corr.31.40.du9, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU9 Distance to Cutblock Correlation Years 31 to 40")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_31_40_du9.png")

dist.cut.41.50.corr.du.9 <- dist.cut.corr.du.9 [c (50:60)]
corr.41.50.du9 <- round (cor (dist.cut.41.50.corr.du.9, method = "spearman"), 3)
p.mat.41.50 <- round (cor_pmat (corr.41.50.du9), 2)
ggcorrplot (corr.41.50.du9, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU9 Distance to Cutblock Correlation Years 41 to >50")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_41_50_du9.png")

#=============================================================================
# Classification and regression trees to see how the covariates relate to use
#=============================================================================
dist.cut.data <- rsf.data.cut.age [c (1, 10:60)]

cart.dist.cut <- rpart (pttype ~ distance_to_cut_1yo + distance_to_cut_2yo + distance_to_cut_3yo + 
                          distance_to_cut_4yo + distance_to_cut_5yo + distance_to_cut_6yo + 
                          distance_to_cut_7yo + distance_to_cut_8yo + distance_to_cut_9yo + 
                          distance_to_cut_10yo + distance_to_cut_11yo + distance_to_cut_12yo + 
                          distance_to_cut_13yo + distance_to_cut_14yo + distance_to_cut_15yo + 
                          distance_to_cut_16yo + distance_to_cut_17yo + distance_to_cut_18yo + 
                          distance_to_cut_19yo + distance_to_cut_20yo + distance_to_cut_21yo + 
                          distance_to_cut_22yo + distance_to_cut_23yo + distance_to_cut_24yo + 
                          distance_to_cut_25yo + distance_to_cut_26yo + distance_to_cut_27yo + 
                          distance_to_cut_28yo + distance_to_cut_29yo + distance_to_cut_30yo + 
                          distance_to_cut_31yo + distance_to_cut_32yo + distance_to_cut_33yo + 
                          distance_to_cut_34yo + distance_to_cut_35yo + distance_to_cut_36yo + 
                          distance_to_cut_37yo + distance_to_cut_38yo + distance_to_cut_39yo + 
                          distance_to_cut_40yo + distance_to_cut_41yo + distance_to_cut_42yo + 
                          distance_to_cut_43yo + distance_to_cut_44yo + distance_to_cut_45yo + 
                          distance_to_cut_46yo + distance_to_cut_47yo + distance_to_cut_48yo + 
                          distance_to_cut_49yo + distance_to_cut_50yo + distance_to_cut_pre50yo,
                        data = dist.cut.data, 
                        method = "class")
summary (cart.dist.cut)
print (cart.dist.cut)
plot (cart.dist.cut, uniform = T)
text (cart.dist.cut, use.n = T, splits = T, fancy = F)
post (cart.dist.cut, file = "", uniform = T)
# DIDN'T USE THESE RESULTS

#====================================
# GLMs, by year
#===================================
dist.cut.data <- rsf.data.cut.age [c (1, 3:4, 10:60)] # cutblock data only

# filter data by DU and season
dist.cut.data.du.6.ew <- dist.cut.data %>%
  dplyr::filter (du == "du6") %>% 
  dplyr::filter (season == "EarlyWinter")
dist.cut.data.du.6.lw <- dist.cut.data %>%
  dplyr::filter (du == "du6") %>% 
  dplyr::filter (season == "LateWinter")
dist.cut.data.du.6.s <- dist.cut.data %>%
  dplyr::filter (du == "du6") %>% 
  dplyr::filter (season == "Summer")

dist.cut.data.du.7.ew <- dist.cut.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "EarlyWinter")
dist.cut.data.du.7.lw <- dist.cut.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "LateWinter")
dist.cut.data.du.7.s <- dist.cut.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "Summer")

dist.cut.data.du.8.ew <- dist.cut.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "EarlyWinter")
dist.cut.data.du.8.lw <- dist.cut.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "LateWinter")
dist.cut.data.du.8.s <- dist.cut.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "Summer")

dist.cut.data.du.9.ew <- dist.cut.data %>%
  dplyr::filter (du == "du9") %>% 
  dplyr::filter (season == "EarlyWinter")
dist.cut.data.du.9.lw <- dist.cut.data %>%
  dplyr::filter (du == "du9") %>% 
  dplyr::filter (season == "LateWinter")
dist.cut.data.du.9.s <- dist.cut.data %>%
  dplyr::filter (du == "du9") %>% 
  dplyr::filter (season == "Summer")

# summry table
table.glm.summary <- data.frame (matrix (ncol = 5, nrow = 0))
colnames (table.glm.summary) <- c ("DU", "Season", "Years Old", "Coefficient", "p-values")
table.glm.summary [1:153, 1] <- "6"
table.glm.summary [1:51, 2] <- "Early Winter"
table.glm.summary [52:102, 2] <- "Late Winter"
table.glm.summary [103:153, 2] <- "Summer"
table.glm.summary [1:51, 3] <- c (1:50, ">50")
table.glm.summary [52:102, 3] <- c (1:50, ">50")
table.glm.summary [103:153, 3] <- c (1:50, ">50")

table.glm.summary [154:306, 1] <- "7"
table.glm.summary [154:204, 2] <- "Early Winter"
table.glm.summary [205:255, 2] <- "Late Winter"
table.glm.summary [256:306, 2] <- "Summer"
table.glm.summary [154:204, 3] <- c (1:50, ">50")
table.glm.summary [205:255, 3] <- c (1:50, ">50")
table.glm.summary [256:306, 3] <- c (1:50, ">50")

table.glm.summary [307:459, 1] <- "8"
table.glm.summary [307:357, 2] <- "Early Winter"
table.glm.summary [358:408, 2] <- "Late Winter"
table.glm.summary [409:459, 2] <- "Summer"
table.glm.summary [307:357, 3] <- c (1:50, ">50")
table.glm.summary [358:408, 3] <- c (1:50, ">50")
table.glm.summary [409:459, 3] <- c (1:50, ">50")

table.glm.summary [460:612, 1] <- "9"
table.glm.summary [460:510, 2] <- "Early Winter"
table.glm.summary [511:561, 2] <- "Late Winter"
table.glm.summary [562:612, 2] <- "Summer"
table.glm.summary [460:510, 3] <- c (1:50, ">50")
table.glm.summary [511:561, 3] <- c (1:50, ">50")
table.glm.summary [562:612, 3] <- c (1:50, ">50")

## DU6 ###
## Early Winter ##
glm.du.6.ew.1yo <- glm (pttype ~ distance_to_cut_1yo, 
                        data = dist.cut.data.du.6.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [1, 4] <- glm.du.6.ew.1yo$coefficients [[2]]
table.glm.summary [1, 5] <- summary(glm.du.6.ew.1yo)$coefficients[2,4] # p-value
rm (glm.du.6.ew.1yo)
gc ()

glm.du.6.ew.2yo <- glm (pttype ~ distance_to_cut_2yo, 
                        data = dist.cut.data.du.6.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [2, 4] <- glm.du.6.ew.2yo$coefficients [[2]]
table.glm.summary [2, 5] <- summary(glm.du.6.ew.2yo)$coefficients[2,4]
rm (glm.du.6.ew.2yo)
gc ()

glm.du.6.ew.3yo <- glm (pttype ~ distance_to_cut_3yo, 
                        data = dist.cut.data.du.6.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [3, 4] <- glm.du.6.ew.3yo$coefficients [[2]]
table.glm.summary [3, 5] <- summary(glm.du.6.ew.3yo)$coefficients[2,4]
rm (glm.du.6.ew.3yo)
gc ()

glm.du.6.ew.4yo <- glm (pttype ~ distance_to_cut_4yo, 
                        data = dist.cut.data.du.6.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [4, 4] <- glm.du.6.ew.4yo$coefficients [[2]]
table.glm.summary [4, 5] <- summary(glm.du.6.ew.4yo)$coefficients [2,4]
rm (glm.du.6.ew.4yo)
gc ()

glm.du.6.ew.5yo <- glm (pttype ~ distance_to_cut_5yo, 
                        data = dist.cut.data.du.6.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [5, 4] <- glm.du.6.ew.5yo$coefficients [[2]]
table.glm.summary [5, 5] <- summary(glm.du.6.ew.5yo)$coefficients [2,4]
rm (glm.du.6.ew.5yo)
gc ()

glm.du.6.ew.6yo <- glm (pttype ~ distance_to_cut_6yo, 
                        data = dist.cut.data.du.6.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [6, 4] <- glm.du.6.ew.6yo$coefficients [[2]]
table.glm.summary [6, 5] <- summary(glm.du.6.ew.6yo)$coefficients [2,4]
rm (glm.du.6.ew.6yo)
gc ()

glm.du.6.ew.7yo <- glm (pttype ~ distance_to_cut_7yo, 
                        data = dist.cut.data.du.6.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [7, 4] <- glm.du.6.ew.7yo$coefficients [[2]]
table.glm.summary [7, 5] <- summary(glm.du.6.ew.7yo)$coefficients [2,4]
rm (glm.du.6.ew.7yo)
gc ()

glm.du.6.ew.8yo <- glm (pttype ~ distance_to_cut_8yo, 
                        data = dist.cut.data.du.6.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [8, 4] <- glm.du.6.ew.8yo$coefficients [[2]]
table.glm.summary [8, 5] <- summary(glm.du.6.ew.8yo)$coefficients [2,4]
rm (glm.du.6.ew.8yo)
gc ()

glm.du.6.ew.9yo <- glm (pttype ~ distance_to_cut_9yo, 
                        data = dist.cut.data.du.6.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [9, 4] <- glm.du.6.ew.9yo$coefficients [[2]]
table.glm.summary [9, 5] <- summary(glm.du.6.ew.9yo)$coefficients [2,4]
rm (glm.du.6.ew.9yo)
gc ()

glm.du.6.ew.10yo <- glm (pttype ~ distance_to_cut_10yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [10, 4] <- glm.du.6.ew.10yo$coefficients [[2]]
table.glm.summary [10, 5] <- summary(glm.du.6.ew.10yo)$coefficients [2,4]
rm (glm.du.6.ew.10yo)
gc ()

glm.du.6.ew.11yo <- glm (pttype ~ distance_to_cut_11yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [11, 4] <- glm.du.6.ew.11yo$coefficients [[2]]
table.glm.summary [11, 5] <- summary(glm.du.6.ew.11yo)$coefficients [2,4]
rm (glm.du.6.ew.11yo)
gc ()

glm.du.6.ew.12yo <- glm (pttype ~ distance_to_cut_12yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [12, 4] <- glm.du.6.ew.12yo$coefficients [[2]]
table.glm.summary [12, 5] <- summary(glm.du.6.ew.12yo)$coefficients [2,4]
rm (glm.du.6.ew.12yo)
gc ()

glm.du.6.ew.13yo <- glm (pttype ~ distance_to_cut_13yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [13, 4] <- glm.du.6.ew.13yo$coefficients [[2]]
table.glm.summary [13, 5] <- summary(glm.du.6.ew.13yo)$coefficients [2,4]
rm (glm.du.6.ew.13yo)
gc ()

glm.du.6.ew.14yo <- glm (pttype ~ distance_to_cut_14yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [14, 4] <- glm.du.6.ew.14yo$coefficients [[2]]
table.glm.summary [14, 5] <- summary(glm.du.6.ew.14yo)$coefficients [2,4]
rm (glm.du.6.ew.14yo)
gc ()

glm.du.6.ew.15yo <- glm (pttype ~ distance_to_cut_15yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [15, 4] <- glm.du.6.ew.15yo$coefficients [[2]]
table.glm.summary [15, 5] <- summary(glm.du.6.ew.15yo)$coefficients [2,4]
rm (glm.du.6.ew.15yo)
gc ()

glm.du.6.ew.16yo <- glm (pttype ~ distance_to_cut_16yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [16, 4] <- glm.du.6.ew.16yo$coefficients [[2]]
table.glm.summary [16, 5] <- summary(glm.du.6.ew.16yo)$coefficients [2,4]
rm (glm.du.6.ew.16yo)
gc ()

glm.du.6.ew.17yo <- glm (pttype ~ distance_to_cut_17yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [17, 4] <- glm.du.6.ew.17yo$coefficients [[2]]
table.glm.summary [17, 5] <- summary(glm.du.6.ew.17yo)$coefficients [2,4]
rm (glm.du.6.ew.17yo)
gc ()

glm.du.6.ew.18yo <- glm (pttype ~ distance_to_cut_18yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [18, 4] <- glm.du.6.ew.18yo$coefficients [[2]]
table.glm.summary [18, 5] <- summary(glm.du.6.ew.18yo)$coefficients [2,4]
rm (glm.du.6.ew.18yo)
gc ()

glm.du.6.ew.19yo <- glm (pttype ~ distance_to_cut_19yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [19, 4] <- glm.du.6.ew.19yo$coefficients [[2]]
table.glm.summary [19, 5] <- summary(glm.du.6.ew.19yo)$coefficients [2,4]
rm (glm.du.6.ew.19yo)
gc ()

glm.du.6.ew.20yo <- glm (pttype ~ distance_to_cut_20yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [20, 4] <- glm.du.6.ew.20yo$coefficients [[2]]
table.glm.summary [20, 5] <- summary(glm.du.6.ew.20yo)$coefficients [2,4]
rm (glm.du.6.ew.20yo)
gc ()

glm.du.6.ew.21yo <- glm (pttype ~ distance_to_cut_21yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [21, 4] <- glm.du.6.ew.21yo$coefficients [[2]]
table.glm.summary [21, 5] <- summary(glm.du.6.ew.21yo)$coefficients [2,4]
rm (glm.du.6.ew.21yo)
gc ()

glm.du.6.ew.22yo <- glm (pttype ~ distance_to_cut_22yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [22, 4] <- glm.du.6.ew.22yo$coefficients [[2]]
table.glm.summary [22, 5] <- summary(glm.du.6.ew.22yo)$coefficients [2,4]
rm (glm.du.6.ew.22yo)
gc ()

glm.du.6.ew.23yo <- glm (pttype ~ distance_to_cut_23yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [23, 4] <- glm.du.6.ew.23yo$coefficients [[2]]
table.glm.summary [23, 5] <- summary(glm.du.6.ew.23yo)$coefficients [2,4]
rm (glm.du.6.ew.23yo)
gc ()

glm.du.6.ew.24yo <- glm (pttype ~ distance_to_cut_24yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [24, 4] <- glm.du.6.ew.24yo$coefficients [[2]]
table.glm.summary [24, 5] <- summary(glm.du.6.ew.24yo)$coefficients [2,4]
rm (glm.du.6.ew.24yo)
gc ()

glm.du.6.ew.25yo <- glm (pttype ~ distance_to_cut_25yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [25, 4] <- glm.du.6.ew.25yo$coefficients [[2]]
table.glm.summary [25, 5] <- summary(glm.du.6.ew.25yo)$coefficients [2,4]
rm (glm.du.6.ew.25yo)
gc ()

glm.du.6.ew.26yo <- glm (pttype ~ distance_to_cut_26yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [26, 4] <- glm.du.6.ew.26yo$coefficients [[2]]
table.glm.summary [26, 5] <- summary(glm.du.6.ew.26yo)$coefficients [2,4]
rm (glm.du.6.ew.26yo)
gc ()

glm.du.6.ew.27yo <- glm (pttype ~ distance_to_cut_27yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [27, 4] <- glm.du.6.ew.27yo$coefficients [[2]]
table.glm.summary [27, 5] <- summary(glm.du.6.ew.27yo)$coefficients [2,4]
rm (glm.du.6.ew.27yo)
gc ()

glm.du.6.ew.28yo <- glm (pttype ~ distance_to_cut_28yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [28, 4] <- glm.du.6.ew.28yo$coefficients [[2]]
table.glm.summary [28, 5] <- summary(glm.du.6.ew.28yo)$coefficients [2,4]
rm (glm.du.6.ew.28yo)
gc ()

glm.du.6.ew.29yo <- glm (pttype ~ distance_to_cut_29yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [29, 4] <- glm.du.6.ew.29yo$coefficients [[2]]
table.glm.summary [29, 5] <- summary(glm.du.6.ew.29yo)$coefficients [2,4]
rm (glm.du.6.ew.29yo)
gc ()

glm.du.6.ew.30yo <- glm (pttype ~ distance_to_cut_30yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [30, 4] <- glm.du.6.ew.30yo$coefficients [[2]]
table.glm.summary [30, 5] <- summary(glm.du.6.ew.30yo)$coefficients [2,4]
rm (glm.du.6.ew.30yo)
gc ()

glm.du.6.ew.31yo <- glm (pttype ~ distance_to_cut_31yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [31, 4] <- glm.du.6.ew.31yo$coefficients [[2]]
table.glm.summary [31, 5] <- summary(glm.du.6.ew.31yo)$coefficients [2,4]
rm (glm.du.6.ew.31yo)
gc ()

glm.du.6.ew.32yo <- glm (pttype ~ distance_to_cut_32yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [32, 4] <- glm.du.6.ew.32yo$coefficients [[2]]
table.glm.summary [32, 5] <- summary(glm.du.6.ew.32yo)$coefficients [2,4]
rm (glm.du.6.ew.32yo)
gc ()

glm.du.6.ew.33yo <- glm (pttype ~ distance_to_cut_33yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [33, 4] <- glm.du.6.ew.33yo$coefficients [[2]]
table.glm.summary [33, 5] <- summary(glm.du.6.ew.33yo)$coefficients [2,4]
rm (glm.du.6.ew.33yo)
gc ()

glm.du.6.ew.34yo <- glm (pttype ~ distance_to_cut_34yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [34, 4] <- glm.du.6.ew.34yo$coefficients [[2]]
table.glm.summary [34, 5] <- summary(glm.du.6.ew.34yo)$coefficients [2,4]
rm (glm.du.6.ew.34yo)
gc ()

glm.du.6.ew.35yo <- glm (pttype ~ distance_to_cut_35yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [35, 4] <- glm.du.6.ew.35yo$coefficients [[2]]
table.glm.summary [35, 5] <- summary(glm.du.6.ew.35yo)$coefficients [2,4]
rm (glm.du.6.ew.35yo)
gc ()

glm.du.6.ew.36yo <- glm (pttype ~ distance_to_cut_36yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [36, 4] <- glm.du.6.ew.36yo$coefficients [[2]]
table.glm.summary [36, 5] <- summary(glm.du.6.ew.36yo)$coefficients [2,4]
rm (glm.du.6.ew.36yo)
gc ()

glm.du.6.ew.37yo <- glm (pttype ~ distance_to_cut_37yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [37, 4] <- glm.du.6.ew.37yo$coefficients [[2]]
table.glm.summary [37, 5] <- summary(glm.du.6.ew.37yo)$coefficients [2,4]
rm (glm.du.6.ew.37yo)
gc ()

glm.du.6.ew.38yo <- glm (pttype ~ distance_to_cut_38yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [38, 4] <- glm.du.6.ew.38yo$coefficients [[2]]
table.glm.summary [38, 5] <- summary(glm.du.6.ew.38yo)$coefficients [2,4]
rm (glm.du.6.ew.38yo)
gc ()

glm.du.6.ew.39yo <- glm (pttype ~ distance_to_cut_39yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [39, 4] <- glm.du.6.ew.39yo$coefficients [[2]]
table.glm.summary [39, 5] <- summary(glm.du.6.ew.39yo)$coefficients [2,4]
rm (glm.du.6.ew.39yo)
gc ()

glm.du.6.ew.40yo <- glm (pttype ~ distance_to_cut_40yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [40, 4] <- glm.du.6.ew.40yo$coefficients [[2]]
table.glm.summary [40, 5] <- summary(glm.du.6.ew.40yo)$coefficients [2,4]
rm (glm.du.6.ew.40yo)
gc ()

glm.du.6.ew.41yo <- glm (pttype ~ distance_to_cut_41yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [41, 4] <- glm.du.6.ew.41yo$coefficients [[2]]
table.glm.summary [41, 5] <- summary(glm.du.6.ew.41yo)$coefficients [2,4]
rm (glm.du.6.ew.41yo)
gc ()

glm.du.6.ew.42yo <- glm (pttype ~ distance_to_cut_42yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [42, 4] <- glm.du.6.ew.42yo$coefficients [[2]]
table.glm.summary [42, 5] <- summary(glm.du.6.ew.42yo)$coefficients [2,4]
rm (glm.du.6.ew.42yo)
gc ()

glm.du.6.ew.43yo <- glm (pttype ~ distance_to_cut_43yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [43, 4] <- glm.du.6.ew.43yo$coefficients [[2]]
table.glm.summary [43, 5] <- summary(glm.du.6.ew.43yo)$coefficients [2,4]
rm (glm.du.6.ew.43yo)
gc ()

glm.du.6.ew.44yo <- glm (pttype ~ distance_to_cut_44yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [44, 4] <- glm.du.6.ew.44yo$coefficients [[2]]
table.glm.summary [44, 5] <- summary(glm.du.6.ew.44yo)$coefficients [2,4]
rm (glm.du.6.ew.44yo)
gc ()

glm.du.6.ew.45yo <- glm (pttype ~ distance_to_cut_45yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [45, 4] <- glm.du.6.ew.45yo$coefficients [[2]]
table.glm.summary [45, 5] <- summary(glm.du.6.ew.45yo)$coefficients [2,4]
rm (glm.du.6.ew.45yo)
gc ()

glm.du.6.ew.46yo <- glm (pttype ~ distance_to_cut_46yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [46, 4] <- glm.du.6.ew.46yo$coefficients [[2]]
table.glm.summary [46, 5] <- summary(glm.du.6.ew.46yo)$coefficients [2,4]
rm (glm.du.6.ew.46yo)
gc ()

glm.du.6.ew.47yo <- glm (pttype ~ distance_to_cut_47yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [47, 4] <- glm.du.6.ew.47yo$coefficients [[2]]
table.glm.summary [47, 5] <- summary(glm.du.6.ew.47yo)$coefficients [2,4]
rm (glm.du.6.ew.47yo)
gc ()

glm.du.6.ew.48yo <- glm (pttype ~ distance_to_cut_48yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [48, 4] <- glm.du.6.ew.48yo$coefficients [[2]]
table.glm.summary [48, 5] <- summary(glm.du.6.ew.48yo)$coefficients [2,4]
rm (glm.du.6.ew.48yo)
gc ()

glm.du.6.ew.49yo <- glm (pttype ~ distance_to_cut_49yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [49, 4] <- glm.du.6.ew.49yo$coefficients [[2]]
table.glm.summary [49, 5] <- summary(glm.du.6.ew.49yo)$coefficients [2,4]
rm (glm.du.6.ew.49yo)
gc ()

glm.du.6.ew.50yo <- glm (pttype ~ distance_to_cut_50yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [50, 4] <- glm.du.6.ew.50yo$coefficients [[2]]
table.glm.summary [50, 5] <- summary(glm.du.6.ew.50yo)$coefficients [2,4]
rm (glm.du.6.ew.50yo)
gc ()

glm.du.6.ew.51yo <- glm (pttype ~ distance_to_cut_pre50yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [51, 4] <- glm.du.6.ew.51yo$coefficients [[2]]
table.glm.summary [51, 5] <- summary(glm.du.6.ew.51yo)$coefficients [2,4]
rm (glm.du.6.ew.51yo)
gc ()

## Late Winter ##
glm.du.6.lw.1yo <- glm (pttype ~ distance_to_cut_1yo, 
                        data = dist.cut.data.du.6.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [52, 4] <- glm.du.6.lw.1yo$coefficients [[2]]
table.glm.summary [52, 5] <- summary(glm.du.6.lw.1yo)$coefficients[2,4] # p-value
rm (glm.du.6.lw.1yo)
gc ()

glm.du.6.lw.2yo <- glm (pttype ~ distance_to_cut_2yo, 
                        data = dist.cut.data.du.6.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [53, 4] <- glm.du.6.lw.2yo$coefficients [[2]]
table.glm.summary [53, 5] <- summary(glm.du.6.lw.2yo)$coefficients[2,4]
rm (glm.du.6.lw.2yo)
gc ()

glm.du.6.lw.3yo <- glm (pttype ~ distance_to_cut_3yo, 
                        data = dist.cut.data.du.6.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [54, 4] <- glm.du.6.lw.3yo$coefficients [[2]]
table.glm.summary [54, 5] <- summary(glm.du.6.lw.3yo)$coefficients[2,4]
rm (glm.du.6.lw.3yo)
gc ()

glm.du.6.lw.4yo <- glm (pttype ~ distance_to_cut_4yo, 
                        data = dist.cut.data.du.6.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [55, 4] <- glm.du.6.lw.4yo$coefficients [[2]]
table.glm.summary [55, 5] <- summary(glm.du.6.lw.4yo)$coefficients [2,4]
rm (glm.du.6.lw.4yo)
gc ()

glm.du.6.lw.5yo <- glm (pttype ~ distance_to_cut_5yo, 
                        data = dist.cut.data.du.6.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [56, 4] <- glm.du.6.lw.5yo$coefficients [[2]]
table.glm.summary [56, 5] <- summary(glm.du.6.lw.5yo)$coefficients [2,4]
rm (glm.du.6.lw.5yo)
gc ()

glm.du.6.lw.6yo <- glm (pttype ~ distance_to_cut_6yo, 
                        data = dist.cut.data.du.6.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [57, 4] <- glm.du.6.lw.6yo$coefficients [[2]]
table.glm.summary [57, 5] <- summary(glm.du.6.lw.6yo)$coefficients [2,4]
rm (glm.du.6.lw.6yo)
gc ()

glm.du.6.lw.7yo <- glm (pttype ~ distance_to_cut_7yo, 
                        data = dist.cut.data.du.6.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [58, 4] <- glm.du.6.lw.7yo$coefficients [[2]]
table.glm.summary [58, 5] <- summary(glm.du.6.lw.7yo)$coefficients [2,4]
rm (glm.du.6.lw.7yo)
gc ()

glm.du.6.lw.8yo <- glm (pttype ~ distance_to_cut_8yo, 
                        data = dist.cut.data.du.6.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [59, 4] <- glm.du.6.lw.8yo$coefficients [[2]]
table.glm.summary [59, 5] <- summary(glm.du.6.lw.8yo)$coefficients [2,4]
rm (glm.du.6.lw.8yo)
gc ()

glm.du.6.lw.9yo <- glm (pttype ~ distance_to_cut_9yo, 
                        data = dist.cut.data.du.6.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [60, 4] <- glm.du.6.lw.9yo$coefficients [[2]]
table.glm.summary [60, 5] <- summary(glm.du.6.lw.9yo)$coefficients [2,4]
rm (glm.du.6.lw.9yo)
gc ()

glm.du.6.lw.10yo <- glm (pttype ~ distance_to_cut_10yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [61, 4] <- glm.du.6.lw.10yo$coefficients [[2]]
table.glm.summary [61, 5] <- summary(glm.du.6.lw.10yo)$coefficients [2,4]
rm (glm.du.6.lw.10yo)
gc ()

glm.du.6.lw.11yo <- glm (pttype ~ distance_to_cut_11yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [62, 4] <- glm.du.6.lw.11yo$coefficients [[2]]
table.glm.summary [62, 5] <- summary(glm.du.6.lw.11yo)$coefficients [2,4]
rm (glm.du.6.lw.11yo)
gc ()

glm.du.6.lw.12yo <- glm (pttype ~ distance_to_cut_12yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [63, 4] <- glm.du.6.lw.12yo$coefficients [[2]]
table.glm.summary [63, 5] <- summary(glm.du.6.lw.12yo)$coefficients [2,4]
rm (glm.du.6.lw.12yo)
gc ()

glm.du.6.lw.13yo <- glm (pttype ~ distance_to_cut_13yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [64, 4] <- glm.du.6.lw.13yo$coefficients [[2]]
table.glm.summary [64, 5] <- summary(glm.du.6.lw.13yo)$coefficients [2,4]
rm (glm.du.6.lw.13yo)
gc ()

glm.du.6.lw.14yo <- glm (pttype ~ distance_to_cut_14yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [65, 4] <- glm.du.6.lw.14yo$coefficients [[2]]
table.glm.summary [65, 5] <- summary(glm.du.6.lw.14yo)$coefficients [2,4]
rm (glm.du.6.lw.14yo)
gc ()

glm.du.6.lw.15yo <- glm (pttype ~ distance_to_cut_15yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [66, 4] <- glm.du.6.lw.15yo$coefficients [[2]]
table.glm.summary [66, 5] <- summary(glm.du.6.lw.15yo)$coefficients [2,4]
rm (glm.du.6.lw.15yo)
gc ()

glm.du.6.lw.16yo <- glm (pttype ~ distance_to_cut_16yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [67, 4] <- glm.du.6.lw.16yo$coefficients [[2]]
table.glm.summary [67, 5] <- summary(glm.du.6.lw.16yo)$coefficients [2,4]
rm (glm.du.6.lw.16yo)
gc ()

glm.du.6.lw.17yo <- glm (pttype ~ distance_to_cut_17yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [68, 4] <- glm.du.6.lw.17yo$coefficients [[2]]
table.glm.summary [68, 5] <- summary(glm.du.6.lw.17yo)$coefficients [2,4]
rm (glm.du.6.lw.17yo)
gc ()

glm.du.6.lw.18yo <- glm (pttype ~ distance_to_cut_18yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [69, 4] <- glm.du.6.lw.18yo$coefficients [[2]]
table.glm.summary [69, 5] <- summary(glm.du.6.lw.18yo)$coefficients [2,4]
rm (glm.du.6.lw.18yo)
gc ()

glm.du.6.lw.19yo <- glm (pttype ~ distance_to_cut_19yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [70, 4] <- glm.du.6.lw.19yo$coefficients [[2]]
table.glm.summary [70, 5] <- summary(glm.du.6.lw.19yo)$coefficients [2,4]
rm (glm.du.6.lw.19yo)
gc ()

glm.du.6.lw.20yo <- glm (pttype ~ distance_to_cut_20yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [71, 4] <- glm.du.6.lw.20yo$coefficients [[2]]
table.glm.summary [71, 5] <- summary(glm.du.6.lw.20yo)$coefficients [2,4]
rm (glm.du.6.lw.20yo)
gc ()

glm.du.6.lw.21yo <- glm (pttype ~ distance_to_cut_21yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [72, 4] <- glm.du.6.lw.21yo$coefficients [[2]]
table.glm.summary [72, 5] <- summary(glm.du.6.lw.21yo)$coefficients [2,4]
rm (glm.du.6.lw.21yo)
gc ()

glm.du.6.lw.22yo <- glm (pttype ~ distance_to_cut_22yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [73, 4] <- glm.du.6.lw.22yo$coefficients [[2]]
table.glm.summary [73, 5] <- summary(glm.du.6.lw.22yo)$coefficients [2,4]
rm (glm.du.6.lw.22yo)
gc ()

glm.du.6.lw.23yo <- glm (pttype ~ distance_to_cut_23yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [74, 4] <- glm.du.6.lw.23yo$coefficients [[2]]
table.glm.summary [74, 5] <- summary(glm.du.6.lw.23yo)$coefficients [2,4]
rm (glm.du.6.lw.23yo)
gc ()

glm.du.6.lw.24yo <- glm (pttype ~ distance_to_cut_24yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [75, 4] <- glm.du.6.lw.24yo$coefficients [[2]]
table.glm.summary [75, 5] <- summary(glm.du.6.lw.24yo)$coefficients [2,4]
rm (glm.du.6.lw.24yo)
gc ()

glm.du.6.lw.25yo <- glm (pttype ~ distance_to_cut_25yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [76, 4] <- glm.du.6.lw.25yo$coefficients [[2]]
table.glm.summary [76, 5] <- summary(glm.du.6.lw.25yo)$coefficients [2,4]
rm (glm.du.6.lw.25yo)
gc ()

glm.du.6.lw.26yo <- glm (pttype ~ distance_to_cut_26yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [77, 4] <- glm.du.6.lw.26yo$coefficients [[2]]
table.glm.summary [77, 5] <- summary(glm.du.6.lw.26yo)$coefficients [2,4]
rm (glm.du.6.lw.26yo)
gc ()

glm.du.6.lw.27yo <- glm (pttype ~ distance_to_cut_27yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [78, 4] <- glm.du.6.lw.27yo$coefficients [[2]]
table.glm.summary [78, 5] <- summary(glm.du.6.lw.27yo)$coefficients [2,4]
rm (glm.du.6.lw.27yo)
gc ()

glm.du.6.lw.28yo <- glm (pttype ~ distance_to_cut_28yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [79, 4] <- glm.du.6.lw.28yo$coefficients [[2]]
table.glm.summary [79, 5] <- summary(glm.du.6.lw.28yo)$coefficients [2,4]
rm (glm.du.6.lw.28yo)
gc ()

glm.du.6.lw.29yo <- glm (pttype ~ distance_to_cut_29yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [80, 4] <- glm.du.6.lw.29yo$coefficients [[2]]
table.glm.summary [80, 5] <- summary(glm.du.6.lw.29yo)$coefficients [2,4]
rm (glm.du.6.lw.29yo)
gc ()

glm.du.6.lw.30yo <- glm (pttype ~ distance_to_cut_30yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [81, 4] <- glm.du.6.lw.30yo$coefficients [[2]]
table.glm.summary [81, 5] <- summary(glm.du.6.lw.30yo)$coefficients [2,4]
rm (glm.du.6.lw.30yo)
gc ()

glm.du.6.lw.31yo <- glm (pttype ~ distance_to_cut_31yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [82, 4] <- glm.du.6.lw.31yo$coefficients [[2]]
table.glm.summary [82, 5] <- summary(glm.du.6.lw.31yo)$coefficients [2,4]
rm (glm.du.6.lw.31yo)
gc ()

glm.du.6.lw.32yo <- glm (pttype ~ distance_to_cut_32yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [83, 4] <- glm.du.6.lw.32yo$coefficients [[2]]
table.glm.summary [83, 5] <- summary(glm.du.6.lw.32yo)$coefficients [2,4]
rm (glm.du.6.lw.32yo)
gc ()

glm.du.6.lw.33yo <- glm (pttype ~ distance_to_cut_33yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [84, 4] <- glm.du.6.lw.33yo$coefficients [[2]]
table.glm.summary [84, 5] <- summary(glm.du.6.lw.33yo)$coefficients [2,4]
rm (glm.du.6.lw.33yo)
gc ()

glm.du.6.lw.34yo <- glm (pttype ~ distance_to_cut_34yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [85, 4] <- glm.du.6.lw.34yo$coefficients [[2]]
table.glm.summary [85, 5] <- summary(glm.du.6.lw.34yo)$coefficients [2,4]
rm (glm.du.6.lw.34yo)
gc ()

glm.du.6.lw.35yo <- glm (pttype ~ distance_to_cut_35yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [86, 4] <- glm.du.6.lw.35yo$coefficients [[2]]
table.glm.summary [86, 5] <- summary(glm.du.6.lw.35yo)$coefficients [2,4]
rm (glm.du.6.lw.35yo)
gc ()

glm.du.6.lw.36yo <- glm (pttype ~ distance_to_cut_36yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [87, 4] <- glm.du.6.lw.36yo$coefficients [[2]]
table.glm.summary [87, 5] <- summary(glm.du.6.lw.36yo)$coefficients [2,4]
rm (glm.du.6.lw.36yo)
gc ()

glm.du.6.lw.37yo <- glm (pttype ~ distance_to_cut_37yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [88, 4] <- glm.du.6.lw.37yo$coefficients [[2]]
table.glm.summary [88, 5] <- summary(glm.du.6.lw.37yo)$coefficients [2,4]
rm (glm.du.6.lw.37yo)
gc ()

glm.du.6.lw.38yo <- glm (pttype ~ distance_to_cut_38yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [89, 4] <- glm.du.6.lw.38yo$coefficients [[2]]
table.glm.summary [89, 5] <- summary(glm.du.6.lw.38yo)$coefficients [2,4]
rm (glm.du.6.lw.38yo)
gc ()

glm.du.6.lw.39yo <- glm (pttype ~ distance_to_cut_39yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [90, 4] <- glm.du.6.lw.39yo$coefficients [[2]]
table.glm.summary [90, 5] <- summary(glm.du.6.lw.39yo)$coefficients [2,4]
rm (glm.du.6.lw.39yo)
gc ()

glm.du.6.lw.40yo <- glm (pttype ~ distance_to_cut_40yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [91, 4] <- glm.du.6.lw.40yo$coefficients [[2]]
table.glm.summary [91, 5] <- summary(glm.du.6.lw.40yo)$coefficients [2,4]
rm (glm.du.6.lw.40yo)
gc ()

glm.du.6.lw.41yo <- glm (pttype ~ distance_to_cut_41yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [92, 4] <- glm.du.6.lw.41yo$coefficients [[2]]
table.glm.summary [92, 5] <- summary(glm.du.6.lw.41yo)$coefficients [2,4]
rm (glm.du.6.lw.41yo)
gc ()

glm.du.6.lw.42yo <- glm (pttype ~ distance_to_cut_42yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [93, 4] <- glm.du.6.lw.42yo$coefficients [[2]]
table.glm.summary [93, 5] <- summary(glm.du.6.lw.42yo)$coefficients [2,4]
rm (glm.du.6.lw.42yo)
gc ()

glm.du.6.lw.43yo <- glm (pttype ~ distance_to_cut_43yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [94, 4] <- glm.du.6.lw.43yo$coefficients [[2]]
table.glm.summary [94, 5] <- summary(glm.du.6.lw.43yo)$coefficients [2,4]
rm (glm.du.6.lw.43yo)
gc ()

glm.du.6.lw.44yo <- glm (pttype ~ distance_to_cut_44yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [95, 4] <- glm.du.6.lw.44yo$coefficients [[2]]
table.glm.summary [95, 5] <- summary(glm.du.6.lw.44yo)$coefficients [2,4]
rm (glm.du.6.lw.44yo)
gc ()

glm.du.6.lw.45yo <- glm (pttype ~ distance_to_cut_45yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [96, 4] <- glm.du.6.lw.45yo$coefficients [[2]]
table.glm.summary [96, 5] <- summary(glm.du.6.lw.45yo)$coefficients [2,4]
rm (glm.du.6.lw.45yo)
gc ()

glm.du.6.lw.46yo <- glm (pttype ~ distance_to_cut_46yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [97, 4] <- glm.du.6.lw.46yo$coefficients [[2]]
table.glm.summary [97, 5] <- summary(glm.du.6.lw.46yo)$coefficients [2,4]
rm (glm.du.6.lw.46yo)
gc ()

glm.du.6.lw.47yo <- glm (pttype ~ distance_to_cut_47yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [98, 4] <- glm.du.6.lw.47yo$coefficients [[2]]
table.glm.summary [98, 5] <- summary(glm.du.6.lw.47yo)$coefficients [2,4]
rm (glm.du.6.lw.47yo)
gc ()

glm.du.6.lw.48yo <- glm (pttype ~ distance_to_cut_48yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [99, 4] <- glm.du.6.lw.48yo$coefficients [[2]]
table.glm.summary [99, 5] <- summary(glm.du.6.lw.48yo)$coefficients [2,4]
rm (glm.du.6.lw.48yo)
gc ()

glm.du.6.lw.49yo <- glm (pttype ~ distance_to_cut_49yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [100, 4] <- glm.du.6.lw.49yo$coefficients [[2]]
table.glm.summary [100, 5] <- summary(glm.du.6.lw.49yo)$coefficients [2,4]
rm (glm.du.6.lw.49yo)
gc ()

glm.du.6.lw.50yo <- glm (pttype ~ distance_to_cut_50yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [101, 4] <- glm.du.6.lw.50yo$coefficients [[2]]
table.glm.summary [101, 5] <- summary(glm.du.6.lw.50yo)$coefficients [2,4]
rm (glm.du.6.lw.50yo)
gc ()

glm.du.6.lw.51yo <- glm (pttype ~ distance_to_cut_pre50yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [102, 4] <- glm.du.6.lw.51yo$coefficients [[2]]
table.glm.summary [102, 5] <- summary(glm.du.6.lw.51yo)$coefficients [2,4]
rm (glm.du.6.lw.51yo)
gc ()

## Summer ##
glm.du.6.s.1yo <- glm (pttype ~ distance_to_cut_1yo, 
                       data = dist.cut.data.du.6.s,
                       family = binomial (link = 'logit'))
table.glm.summary [103, 4] <- glm.du.6.s.1yo$coefficients [[2]]
table.glm.summary [103, 5] <- summary(glm.du.6.s.1yo)$coefficients[2,4] # p-value
rm (glm.du.6.s.1yo)
gc ()

glm.du.6.s.2yo <- glm (pttype ~ distance_to_cut_2yo, 
                       data = dist.cut.data.du.6.s,
                       family = binomial (link = 'logit'))
table.glm.summary [104, 4] <- glm.du.6.s.2yo$coefficients [[2]]
table.glm.summary [104, 5] <- summary(glm.du.6.s.2yo)$coefficients[2,4]
rm (glm.du.6.s.2yo)
gc ()

glm.du.6.s.3yo <- glm (pttype ~ distance_to_cut_3yo, 
                       data = dist.cut.data.du.6.s,
                       family = binomial (link = 'logit'))
table.glm.summary [105, 4] <- glm.du.6.s.3yo$coefficients [[2]]
table.glm.summary [105, 5] <- summary(glm.du.6.s.3yo)$coefficients[2,4]
rm (glm.du.6.s.3yo)
gc ()

glm.du.6.s.4yo <- glm (pttype ~ distance_to_cut_4yo, 
                       data = dist.cut.data.du.6.s,
                       family = binomial (link = 'logit'))
table.glm.summary [106, 4] <- glm.du.6.s.4yo$coefficients [[2]]
table.glm.summary [106, 5] <- summary(glm.du.6.s.4yo)$coefficients [2,4]
rm (glm.du.6.s.4yo)
gc ()

glm.du.6.s.5yo <- glm (pttype ~ distance_to_cut_5yo, 
                       data = dist.cut.data.du.6.s,
                       family = binomial (link = 'logit'))
table.glm.summary [107, 4] <- glm.du.6.s.5yo$coefficients [[2]]
table.glm.summary [107, 5] <- summary(glm.du.6.s.5yo)$coefficients [2,4]
rm (glm.du.6.s.5yo)
gc ()

glm.du.6.s.6yo <- glm (pttype ~ distance_to_cut_6yo, 
                       data = dist.cut.data.du.6.s,
                       family = binomial (link = 'logit'))
table.glm.summary [108, 4] <- glm.du.6.s.6yo$coefficients [[2]]
table.glm.summary [108, 5] <- summary(glm.du.6.s.6yo)$coefficients [2,4]
rm (glm.du.6.s.6yo)
gc ()

glm.du.6.s.7yo <- glm (pttype ~ distance_to_cut_7yo, 
                       data = dist.cut.data.du.6.s,
                       family = binomial (link = 'logit'))
table.glm.summary [109, 4] <- glm.du.6.s.7yo$coefficients [[2]]
table.glm.summary [109, 5] <- summary(glm.du.6.s.7yo)$coefficients [2,4]
rm (glm.du.6.s.7yo)
gc ()

glm.du.6.s.8yo <- glm (pttype ~ distance_to_cut_8yo, 
                       data = dist.cut.data.du.6.s,
                       family = binomial (link = 'logit'))
table.glm.summary [110, 4] <- glm.du.6.s.8yo$coefficients [[2]]
table.glm.summary [110, 5] <- summary(glm.du.6.s.8yo)$coefficients [2,4]
rm (glm.du.6.s.8yo)
gc ()

glm.du.6.s.9yo <- glm (pttype ~ distance_to_cut_9yo, 
                       data = dist.cut.data.du.6.s,
                       family = binomial (link = 'logit'))
table.glm.summary [111, 4] <- glm.du.6.s.9yo$coefficients [[2]]
table.glm.summary [111, 5] <- summary(glm.du.6.s.9yo)$coefficients [2,4]
rm (glm.du.6.s.9yo)
gc ()

glm.du.6.s.10yo <- glm (pttype ~ distance_to_cut_10yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [112, 4] <- glm.du.6.s.10yo$coefficients [[2]]
table.glm.summary [112, 5] <- summary(glm.du.6.s.10yo)$coefficients [2,4]
rm (glm.du.6.s.10yo)
gc ()

glm.du.6.s.11yo <- glm (pttype ~ distance_to_cut_11yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [113, 4] <- glm.du.6.s.11yo$coefficients [[2]]
table.glm.summary [113, 5] <- summary(glm.du.6.s.11yo)$coefficients [2,4]
rm (glm.du.6.s.11yo)
gc ()

glm.du.6.s.12yo <- glm (pttype ~ distance_to_cut_12yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [114, 4] <- glm.du.6.s.12yo$coefficients [[2]]
table.glm.summary [114, 5] <- summary(glm.du.6.s.12yo)$coefficients [2,4]
rm (glm.du.6.s.12yo)
gc ()

glm.du.6.s.13yo <- glm (pttype ~ distance_to_cut_13yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [115, 4] <- glm.du.6.s.13yo$coefficients [[2]]
table.glm.summary [115, 5] <- summary(glm.du.6.s.13yo)$coefficients [2,4]
rm (glm.du.6.s.13yo)
gc ()

glm.du.6.s.14yo <- glm (pttype ~ distance_to_cut_14yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [116, 4] <- glm.du.6.s.14yo$coefficients [[2]]
table.glm.summary [116, 5] <- summary(glm.du.6.s.14yo)$coefficients [2,4]
rm (glm.du.6.s.14yo)
gc ()

glm.du.6.s.15yo <- glm (pttype ~ distance_to_cut_15yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [117, 4] <- glm.du.6.s.15yo$coefficients [[2]]
table.glm.summary [117, 5] <- summary(glm.du.6.s.15yo)$coefficients [2,4]
rm (glm.du.6.s.15yo)
gc ()

glm.du.6.s.16yo <- glm (pttype ~ distance_to_cut_16yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [118, 4] <- glm.du.6.s.16yo$coefficients [[2]]
table.glm.summary [118, 5] <- summary(glm.du.6.s.16yo)$coefficients [2,4]
rm (glm.du.6.s.16yo)
gc ()

glm.du.6.s.17yo <- glm (pttype ~ distance_to_cut_17yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [119, 4] <- glm.du.6.s.17yo$coefficients [[2]]
table.glm.summary [119, 5] <- summary(glm.du.6.s.17yo)$coefficients [2,4]
rm (glm.du.6.s.17yo)
gc ()

glm.du.6.s.18yo <- glm (pttype ~ distance_to_cut_18yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [120, 4] <- glm.du.6.s.18yo$coefficients [[2]]
table.glm.summary [120, 5] <- summary(glm.du.6.s.18yo)$coefficients [2,4]
rm (glm.du.6.s.18yo)
gc ()

glm.du.6.s.19yo <- glm (pttype ~ distance_to_cut_19yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [121, 4] <- glm.du.6.s.19yo$coefficients [[2]]
table.glm.summary [121, 5] <- summary(glm.du.6.s.19yo)$coefficients [2,4]
rm (glm.du.6.s.19yo)
gc ()

glm.du.6.s.20yo <- glm (pttype ~ distance_to_cut_20yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [122, 4] <- glm.du.6.s.20yo$coefficients [[2]]
table.glm.summary [122, 5] <- summary(glm.du.6.s.20yo)$coefficients [2,4]
rm (glm.du.6.s.20yo)
gc ()

glm.du.6.s.21yo <- glm (pttype ~ distance_to_cut_21yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [123, 4] <- glm.du.6.s.21yo$coefficients [[2]]
table.glm.summary [123, 5] <- summary(glm.du.6.s.21yo)$coefficients [2,4]
rm (glm.du.6.s.21yo)
gc ()

glm.du.6.s.22yo <- glm (pttype ~ distance_to_cut_22yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [124, 4] <- glm.du.6.s.22yo$coefficients [[2]]
table.glm.summary [124, 5] <- summary(glm.du.6.s.22yo)$coefficients [2,4]
rm (glm.du.6.s.22yo)
gc ()

glm.du.6.s.23yo <- glm (pttype ~ distance_to_cut_23yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [125, 4] <- glm.du.6.s.23yo$coefficients [[2]]
table.glm.summary [125, 5] <- summary(glm.du.6.s.23yo)$coefficients [2,4]
rm (glm.du.6.s.23yo)
gc ()

glm.du.6.s.24yo <- glm (pttype ~ distance_to_cut_24yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [126, 4] <- glm.du.6.s.24yo$coefficients [[2]]
table.glm.summary [126, 5] <- summary(glm.du.6.s.24yo)$coefficients [2,4]
rm (glm.du.6.s.24yo)
gc ()

glm.du.6.s.25yo <- glm (pttype ~ distance_to_cut_25yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [127, 4] <- glm.du.6.s.25yo$coefficients [[2]]
table.glm.summary [127, 5] <- summary(glm.du.6.s.25yo)$coefficients [2,4]
rm (glm.du.6.s.25yo)
gc ()

glm.du.6.s.26yo <- glm (pttype ~ distance_to_cut_26yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [128, 4] <- glm.du.6.s.26yo$coefficients [[2]]
table.glm.summary [128, 5] <- summary(glm.du.6.s.26yo)$coefficients [2,4]
rm (glm.du.6.s.26yo)
gc ()

glm.du.6.s.27yo <- glm (pttype ~ distance_to_cut_27yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [129, 4] <- glm.du.6.s.27yo$coefficients [[2]]
table.glm.summary [129, 5] <- summary(glm.du.6.s.27yo)$coefficients [2,4]
rm (glm.du.6.s.27yo)
gc ()

glm.du.6.s.28yo <- glm (pttype ~ distance_to_cut_28yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [130, 4] <- glm.du.6.s.28yo$coefficients [[2]]
table.glm.summary [130, 5] <- summary(glm.du.6.s.28yo)$coefficients [2,4]
rm (glm.du.6.s.28yo)
gc ()

glm.du.6.s.29yo <- glm (pttype ~ distance_to_cut_29yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [131, 4] <- glm.du.6.s.29yo$coefficients [[2]]
table.glm.summary [131, 5] <- summary(glm.du.6.s.29yo)$coefficients [2,4]
rm (glm.du.6.s.29yo)
gc ()

glm.du.6.s.30yo <- glm (pttype ~ distance_to_cut_30yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [132, 4] <- glm.du.6.s.30yo$coefficients [[2]]
table.glm.summary [132, 5] <- summary(glm.du.6.s.30yo)$coefficients [2,4]
rm (glm.du.6.s.30yo)
gc ()

glm.du.6.s.31yo <- glm (pttype ~ distance_to_cut_31yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [133, 4] <- glm.du.6.s.31yo$coefficients [[2]]
table.glm.summary [133, 5] <- summary(glm.du.6.s.31yo)$coefficients [2,4]
rm (glm.du.6.s.31yo)
gc ()

glm.du.6.s.32yo <- glm (pttype ~ distance_to_cut_32yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [134, 4] <- glm.du.6.s.32yo$coefficients [[2]]
table.glm.summary [134, 5] <- summary(glm.du.6.s.32yo)$coefficients [2,4]
rm (glm.du.6.s.32yo)
gc ()

glm.du.6.s.33yo <- glm (pttype ~ distance_to_cut_33yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [135, 4] <- glm.du.6.s.33yo$coefficients [[2]]
table.glm.summary [135, 5] <- summary(glm.du.6.s.33yo)$coefficients [2,4]
rm (glm.du.6.s.33yo)
gc ()

glm.du.6.s.34yo <- glm (pttype ~ distance_to_cut_34yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [136, 4] <- glm.du.6.s.34yo$coefficients [[2]]
table.glm.summary [136, 5] <- summary(glm.du.6.s.34yo)$coefficients [2,4]
rm (glm.du.6.s.34yo)
gc ()

glm.du.6.s.35yo <- glm (pttype ~ distance_to_cut_35yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [137, 4] <- glm.du.6.s.35yo$coefficients [[2]]
table.glm.summary [137, 5] <- summary(glm.du.6.s.35yo)$coefficients [2,4]
rm (glm.du.6.s.35yo)
gc ()

glm.du.6.s.36yo <- glm (pttype ~ distance_to_cut_36yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [138, 4] <- glm.du.6.s.36yo$coefficients [[2]]
table.glm.summary [138, 5] <- summary(glm.du.6.s.36yo)$coefficients [2,4]
rm (glm.du.6.s.36yo)
gc ()

glm.du.6.s.37yo <- glm (pttype ~ distance_to_cut_37yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [139, 4] <- glm.du.6.s.37yo$coefficients [[2]]
table.glm.summary [139, 5] <- summary(glm.du.6.s.37yo)$coefficients [2,4]
rm (glm.du.6.s.37yo)
gc ()

glm.du.6.s.38yo <- glm (pttype ~ distance_to_cut_38yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [140, 4] <- glm.du.6.s.38yo$coefficients [[2]]
table.glm.summary [140, 5] <- summary(glm.du.6.s.38yo)$coefficients [2,4]
rm (glm.du.6.s.38yo)
gc ()

glm.du.6.s.39yo <- glm (pttype ~ distance_to_cut_39yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [141, 4] <- glm.du.6.s.39yo$coefficients [[2]]
table.glm.summary [141, 5] <- summary(glm.du.6.s.39yo)$coefficients [2,4]
rm (glm.du.6.s.39yo)
gc ()

glm.du.6.s.40yo <- glm (pttype ~ distance_to_cut_40yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [142, 4] <- glm.du.6.s.40yo$coefficients [[2]]
table.glm.summary [142, 5] <- summary(glm.du.6.s.40yo)$coefficients [2,4]
rm (glm.du.6.s.40yo)
gc ()

glm.du.6.s.41yo <- glm (pttype ~ distance_to_cut_41yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [143, 4] <- glm.du.6.s.41yo$coefficients [[2]]
table.glm.summary [143, 5] <- summary(glm.du.6.s.41yo)$coefficients [2,4]
rm (glm.du.6.s.41yo)
gc ()

glm.du.6.s.42yo <- glm (pttype ~ distance_to_cut_42yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [144, 4] <- glm.du.6.s.42yo$coefficients [[2]]
table.glm.summary [144, 5] <- summary(glm.du.6.s.42yo)$coefficients [2,4]
rm (glm.du.6.s.42yo)
gc ()

glm.du.6.s.43yo <- glm (pttype ~ distance_to_cut_43yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [145, 4] <- glm.du.6.s.43yo$coefficients [[2]]
table.glm.summary [145, 5] <- summary(glm.du.6.s.43yo)$coefficients [2,4]
rm (glm.du.6.s.43yo)
gc ()

glm.du.6.s.44yo <- glm (pttype ~ distance_to_cut_44yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [146, 4] <- glm.du.6.s.44yo$coefficients [[2]]
table.glm.summary [146, 5] <- summary(glm.du.6.s.44yo)$coefficients [2,4]
rm (glm.du.6.s.44yo)
gc ()

glm.du.6.s.45yo <- glm (pttype ~ distance_to_cut_45yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [147, 4] <- glm.du.6.s.45yo$coefficients [[2]]
table.glm.summary [147, 5] <- summary(glm.du.6.s.45yo)$coefficients [2,4]
rm (glm.du.6.s.45yo)
gc ()

glm.du.6.s.46yo <- glm (pttype ~ distance_to_cut_46yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [148, 4] <- glm.du.6.s.46yo$coefficients [[2]]
table.glm.summary [148, 5] <- summary(glm.du.6.s.46yo)$coefficients [2,4]
rm (glm.du.6.s.46yo)
gc ()

glm.du.6.s.47yo <- glm (pttype ~ distance_to_cut_47yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [149, 4] <- glm.du.6.s.47yo$coefficients [[2]]
table.glm.summary [149, 5] <- summary(glm.du.6.s.47yo)$coefficients [2,4]
rm (glm.du.6.s.47yo)
gc ()

glm.du.6.s.48yo <- glm (pttype ~ distance_to_cut_48yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [150, 4] <- glm.du.6.s.48yo$coefficients [[2]]
table.glm.summary [150, 5] <- summary(glm.du.6.s.48yo)$coefficients [2,4]
rm (glm.du.6.s.48yo)
gc ()

glm.du.6.s.49yo <- glm (pttype ~ distance_to_cut_49yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [151, 4] <- glm.du.6.s.49yo$coefficients [[2]]
table.glm.summary [151, 5] <- summary(glm.du.6.s.49yo)$coefficients [2,4]
rm (glm.du.6.s.49yo)
gc ()

glm.du.6.s.50yo <- glm (pttype ~ distance_to_cut_50yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [152, 4] <- glm.du.6.s.50yo$coefficients [[2]]
table.glm.summary [152, 5] <- summary(glm.du.6.s.50yo)$coefficients [2,4]
rm (glm.du.6.s.50yo)
gc ()

glm.du.6.s.51yo <- glm (pttype ~ distance_to_cut_pre50yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [153, 4] <- glm.du.6.s.51yo$coefficients [[2]]
table.glm.summary [153, 5] <- summary(glm.du.6.s.51yo)$coefficients [2,4]
rm (glm.du.6.s.51yo)
gc ()

## DU7 ###
## Early Winter ##
glm.du.7.ew.1yo <- glm (pttype ~ distance_to_cut_1yo, 
                        data = dist.cut.data.du.7.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [154, 4] <- glm.du.7.ew.1yo$coefficients [[2]]
table.glm.summary [154, 5] <- summary(glm.du.7.ew.1yo)$coefficients[2,4] # p-value
rm (glm.du.7.ew.1yo)
gc ()

glm.du.7.ew.2yo <- glm (pttype ~ distance_to_cut_2yo, 
                        data = dist.cut.data.du.7.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [155, 4] <- glm.du.7.ew.2yo$coefficients [[2]]
table.glm.summary [155, 5] <- summary(glm.du.7.ew.2yo)$coefficients[2,4]
rm (glm.du.7.ew.2yo)
gc ()

glm.du.7.ew.3yo <- glm (pttype ~ distance_to_cut_3yo, 
                        data = dist.cut.data.du.7.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [156, 4] <- glm.du.7.ew.3yo$coefficients [[2]]
table.glm.summary [156, 5] <- summary(glm.du.7.ew.3yo)$coefficients[2,4]
rm (glm.du.7.ew.3yo)
gc ()

glm.du.7.ew.4yo <- glm (pttype ~ distance_to_cut_4yo, 
                        data = dist.cut.data.du.7.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [157, 4] <- glm.du.7.ew.4yo$coefficients [[2]]
table.glm.summary [157, 5] <- summary(glm.du.7.ew.4yo)$coefficients [2,4]
rm (glm.du.7.ew.4yo)
gc ()

glm.du.7.ew.5yo <- glm (pttype ~ distance_to_cut_5yo, 
                        data = dist.cut.data.du.7.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [158, 4] <- glm.du.7.ew.5yo$coefficients [[2]]
table.glm.summary [158, 5] <- summary(glm.du.7.ew.5yo)$coefficients [2,4]
rm (glm.du.7.ew.5yo)
gc ()

glm.du.7.ew.6yo <- glm (pttype ~ distance_to_cut_6yo, 
                        data = dist.cut.data.du.7.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [159, 4] <- glm.du.7.ew.6yo$coefficients [[2]]
table.glm.summary [159, 5] <- summary(glm.du.7.ew.6yo)$coefficients [2,4]
rm (glm.du.7.ew.6yo)
gc ()

glm.du.7.ew.7yo <- glm (pttype ~ distance_to_cut_7yo, 
                        data = dist.cut.data.du.7.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [160, 4] <- glm.du.7.ew.7yo$coefficients [[2]]
table.glm.summary [160, 5] <- summary(glm.du.7.ew.7yo)$coefficients [2,4]
rm (glm.du.7.ew.7yo)
gc ()

glm.du.7.ew.8yo <- glm (pttype ~ distance_to_cut_8yo, 
                        data = dist.cut.data.du.7.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [161, 4] <- glm.du.7.ew.8yo$coefficients [[2]]
table.glm.summary [161, 5] <- summary(glm.du.7.ew.8yo)$coefficients [2,4]
rm (glm.du.7.ew.8yo)
gc ()

glm.du.7.ew.9yo <- glm (pttype ~ distance_to_cut_9yo, 
                        data = dist.cut.data.du.7.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [162, 4] <- glm.du.7.ew.9yo$coefficients [[2]]
table.glm.summary [162, 5] <- summary(glm.du.7.ew.9yo)$coefficients [2,4]
rm (glm.du.7.ew.9yo)
gc ()

glm.du.7.ew.10yo <- glm (pttype ~ distance_to_cut_10yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [163, 4] <- glm.du.7.ew.10yo$coefficients [[2]]
table.glm.summary [163, 5] <- summary(glm.du.7.ew.10yo)$coefficients [2,4]
rm (glm.du.7.ew.10yo)
gc ()

glm.du.7.ew.11yo <- glm (pttype ~ distance_to_cut_11yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [164, 4] <- glm.du.7.ew.11yo$coefficients [[2]]
table.glm.summary [164, 5] <- summary(glm.du.7.ew.11yo)$coefficients [2,4]
rm (glm.du.7.ew.11yo)
gc ()

glm.du.7.ew.12yo <- glm (pttype ~ distance_to_cut_12yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [165, 4] <- glm.du.7.ew.12yo$coefficients [[2]]
table.glm.summary [165, 5] <- summary(glm.du.7.ew.12yo)$coefficients [2,4]
rm (glm.du.7.ew.12yo)
gc ()

glm.du.7.ew.13yo <- glm (pttype ~ distance_to_cut_13yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [166, 4] <- glm.du.7.ew.13yo$coefficients [[2]]
table.glm.summary [166, 5] <- summary(glm.du.7.ew.13yo)$coefficients [2,4]
rm (glm.du.7.ew.13yo)
gc ()

glm.du.7.ew.14yo <- glm (pttype ~ distance_to_cut_14yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [167, 4] <- glm.du.7.ew.14yo$coefficients [[2]]
table.glm.summary [167, 5] <- summary(glm.du.7.ew.14yo)$coefficients [2,4]
rm (glm.du.7.ew.14yo)
gc ()

glm.du.7.ew.15yo <- glm (pttype ~ distance_to_cut_15yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [168, 4] <- glm.du.7.ew.15yo$coefficients [[2]]
table.glm.summary [168, 5] <- summary(glm.du.7.ew.15yo)$coefficients [2,4]
rm (glm.du.7.ew.15yo)
gc ()

glm.du.7.ew.16yo <- glm (pttype ~ distance_to_cut_16yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [169, 4] <- glm.du.7.ew.16yo$coefficients [[2]]
table.glm.summary [169, 5] <- summary(glm.du.7.ew.16yo)$coefficients [2,4]
rm (glm.du.7.ew.16yo)
gc ()

glm.du.7.ew.17yo <- glm (pttype ~ distance_to_cut_17yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [170, 4] <- glm.du.7.ew.17yo$coefficients [[2]]
table.glm.summary [170, 5] <- summary(glm.du.7.ew.17yo)$coefficients [2,4]
rm (glm.du.7.ew.17yo)
gc ()

glm.du.7.ew.18yo <- glm (pttype ~ distance_to_cut_18yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [171, 4] <- glm.du.7.ew.18yo$coefficients [[2]]
table.glm.summary [171, 5] <- summary(glm.du.7.ew.18yo)$coefficients [2,4]
rm (glm.du.7.ew.18yo)
gc ()

glm.du.7.ew.19yo <- glm (pttype ~ distance_to_cut_19yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [172, 4] <- glm.du.7.ew.19yo$coefficients [[2]]
table.glm.summary [172, 5] <- summary(glm.du.7.ew.19yo)$coefficients [2,4]
rm (glm.du.7.ew.19yo)
gc ()

glm.du.7.ew.20yo <- glm (pttype ~ distance_to_cut_20yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [173, 4] <- glm.du.7.ew.20yo$coefficients [[2]]
table.glm.summary [173, 5] <- summary(glm.du.7.ew.20yo)$coefficients [2,4]
rm (glm.du.7.ew.20yo)
gc ()

glm.du.7.ew.21yo <- glm (pttype ~ distance_to_cut_21yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [174, 4] <- glm.du.7.ew.21yo$coefficients [[2]]
table.glm.summary [174, 5] <- summary(glm.du.7.ew.21yo)$coefficients [2,4]
rm (glm.du.7.ew.21yo)
gc ()

glm.du.7.ew.22yo <- glm (pttype ~ distance_to_cut_22yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [175, 4] <- glm.du.7.ew.22yo$coefficients [[2]]
table.glm.summary [175, 5] <- summary(glm.du.7.ew.22yo)$coefficients [2,4]
rm (glm.du.7.ew.22yo)
gc ()

glm.du.7.ew.23yo <- glm (pttype ~ distance_to_cut_23yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [176, 4] <- glm.du.7.ew.23yo$coefficients [[2]]
table.glm.summary [176, 5] <- summary(glm.du.7.ew.23yo)$coefficients [2,4]
rm (glm.du.7.ew.23yo)
gc ()

glm.du.7.ew.24yo <- glm (pttype ~ distance_to_cut_24yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [177, 4] <- glm.du.7.ew.24yo$coefficients [[2]]
table.glm.summary [177, 5] <- summary(glm.du.7.ew.24yo)$coefficients [2,4]
rm (glm.du.7.ew.24yo)
gc ()

glm.du.7.ew.25yo <- glm (pttype ~ distance_to_cut_25yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [178, 4] <- glm.du.7.ew.25yo$coefficients [[2]]
table.glm.summary [178, 5] <- summary(glm.du.7.ew.25yo)$coefficients [2,4]
rm (glm.du.7.ew.25yo)
gc ()

glm.du.7.ew.26yo <- glm (pttype ~ distance_to_cut_26yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [179, 4] <- glm.du.7.ew.26yo$coefficients [[2]]
table.glm.summary [179, 5] <- summary(glm.du.7.ew.26yo)$coefficients [2,4]
rm (glm.du.7.ew.26yo)
gc ()

glm.du.7.ew.27yo <- glm (pttype ~ distance_to_cut_27yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [180, 4] <- glm.du.7.ew.27yo$coefficients [[2]]
table.glm.summary [180, 5] <- summary(glm.du.7.ew.27yo)$coefficients [2,4]
rm (glm.du.7.ew.27yo)
gc ()

glm.du.7.ew.28yo <- glm (pttype ~ distance_to_cut_28yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [181, 4] <- glm.du.7.ew.28yo$coefficients [[2]]
table.glm.summary [181, 5] <- summary(glm.du.7.ew.28yo)$coefficients [2,4]
rm (glm.du.7.ew.28yo)
gc ()

glm.du.7.ew.29yo <- glm (pttype ~ distance_to_cut_29yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [182, 4] <- glm.du.7.ew.29yo$coefficients [[2]]
table.glm.summary [182, 5] <- summary(glm.du.7.ew.29yo)$coefficients [2,4]
rm (glm.du.7.ew.29yo)
gc ()

glm.du.7.ew.30yo <- glm (pttype ~ distance_to_cut_30yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [183, 4] <- glm.du.7.ew.30yo$coefficients [[2]]
table.glm.summary [183, 5] <- summary(glm.du.7.ew.30yo)$coefficients [2,4]
rm (glm.du.7.ew.30yo)
gc ()

glm.du.7.ew.31yo <- glm (pttype ~ distance_to_cut_31yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [184, 4] <- glm.du.7.ew.31yo$coefficients [[2]]
table.glm.summary [184, 5] <- summary(glm.du.7.ew.31yo)$coefficients [2,4]
rm (glm.du.7.ew.31yo)
gc ()

glm.du.7.ew.32yo <- glm (pttype ~ distance_to_cut_32yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [185, 4] <- glm.du.7.ew.32yo$coefficients [[2]]
table.glm.summary [185, 5] <- summary(glm.du.7.ew.32yo)$coefficients [2,4]
rm (glm.du.7.ew.32yo)
gc ()

glm.du.7.ew.33yo <- glm (pttype ~ distance_to_cut_33yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [186, 4] <- glm.du.7.ew.33yo$coefficients [[2]]
table.glm.summary [186, 5] <- summary(glm.du.7.ew.33yo)$coefficients [2,4]
rm (glm.du.7.ew.33yo)
gc ()

glm.du.7.ew.34yo <- glm (pttype ~ distance_to_cut_34yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [187, 4] <- glm.du.7.ew.34yo$coefficients [[2]]
table.glm.summary [187, 5] <- summary(glm.du.7.ew.34yo)$coefficients [2,4]
rm (glm.du.7.ew.34yo)
gc ()

glm.du.7.ew.35yo <- glm (pttype ~ distance_to_cut_35yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [188, 4] <- glm.du.7.ew.35yo$coefficients [[2]]
table.glm.summary [188, 5] <- summary(glm.du.7.ew.35yo)$coefficients [2,4]
rm (glm.du.7.ew.35yo)
gc ()

glm.du.7.ew.36yo <- glm (pttype ~ distance_to_cut_36yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [189, 4] <- glm.du.7.ew.36yo$coefficients [[2]]
table.glm.summary [189, 5] <- summary(glm.du.7.ew.36yo)$coefficients [2,4]
rm (glm.du.7.ew.36yo)
gc ()

glm.du.7.ew.37yo <- glm (pttype ~ distance_to_cut_37yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [190, 4] <- glm.du.7.ew.37yo$coefficients [[2]]
table.glm.summary [190, 5] <- summary(glm.du.7.ew.37yo)$coefficients [2,4]
rm (glm.du.7.ew.37yo)
gc ()

glm.du.7.ew.38yo <- glm (pttype ~ distance_to_cut_38yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [191, 4] <- glm.du.7.ew.38yo$coefficients [[2]]
table.glm.summary [191, 5] <- summary(glm.du.7.ew.38yo)$coefficients [2,4]
rm (glm.du.7.ew.38yo)
gc ()

glm.du.7.ew.39yo <- glm (pttype ~ distance_to_cut_39yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [192, 4] <- glm.du.7.ew.39yo$coefficients [[2]]
table.glm.summary [192, 5] <- summary(glm.du.7.ew.39yo)$coefficients [2,4]
rm (glm.du.7.ew.39yo)
gc ()

glm.du.7.ew.40yo <- glm (pttype ~ distance_to_cut_40yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [193, 4] <- glm.du.7.ew.40yo$coefficients [[2]]
table.glm.summary [193, 5] <- summary(glm.du.7.ew.40yo)$coefficients [2,4]
rm (glm.du.7.ew.40yo)
gc ()

glm.du.7.ew.41yo <- glm (pttype ~ distance_to_cut_41yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [194, 4] <- glm.du.7.ew.41yo$coefficients [[2]]
table.glm.summary [194, 5] <- summary(glm.du.7.ew.41yo)$coefficients [2,4]
rm (glm.du.7.ew.41yo)
gc ()

glm.du.7.ew.42yo <- glm (pttype ~ distance_to_cut_42yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [195, 4] <- glm.du.7.ew.42yo$coefficients [[2]]
table.glm.summary [195, 5] <- summary(glm.du.7.ew.42yo)$coefficients [2,4]
rm (glm.du.7.ew.42yo)
gc ()

glm.du.7.ew.43yo <- glm (pttype ~ distance_to_cut_43yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [196, 4] <- glm.du.7.ew.43yo$coefficients [[2]]
table.glm.summary [196, 5] <- summary(glm.du.7.ew.43yo)$coefficients [2,4]
rm (glm.du.7.ew.43yo)
gc ()

glm.du.7.ew.44yo <- glm (pttype ~ distance_to_cut_44yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [197, 4] <- glm.du.7.ew.44yo$coefficients [[2]]
table.glm.summary [197, 5] <- summary(glm.du.7.ew.44yo)$coefficients [2,4]
rm (glm.du.7.ew.44yo)
gc ()

glm.du.7.ew.45yo <- glm (pttype ~ distance_to_cut_45yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [198, 4] <- glm.du.7.ew.45yo$coefficients [[2]]
table.glm.summary [198, 5] <- summary(glm.du.7.ew.45yo)$coefficients [2,4]
rm (glm.du.7.ew.45yo)
gc ()

glm.du.7.ew.46yo <- glm (pttype ~ distance_to_cut_46yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [199, 4] <- glm.du.7.ew.46yo$coefficients [[2]]
table.glm.summary [199, 5] <- summary(glm.du.7.ew.46yo)$coefficients [2,4]
rm (glm.du.7.ew.46yo)
gc ()

glm.du.7.ew.47yo <- glm (pttype ~ distance_to_cut_47yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [200, 4] <- glm.du.7.ew.47yo$coefficients [[2]]
table.glm.summary [200, 5] <- summary(glm.du.7.ew.47yo)$coefficients [2,4]
rm (glm.du.7.ew.47yo)
gc ()

glm.du.7.ew.48yo <- glm (pttype ~ distance_to_cut_48yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [201, 4] <- glm.du.7.ew.48yo$coefficients [[2]]
table.glm.summary [201, 5] <- summary(glm.du.7.ew.48yo)$coefficients [2,4]
rm (glm.du.7.ew.48yo)
gc ()

glm.du.7.ew.49yo <- glm (pttype ~ distance_to_cut_49yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [202, 4] <- glm.du.7.ew.49yo$coefficients [[2]]
table.glm.summary [202, 5] <- summary(glm.du.7.ew.49yo)$coefficients [2,4]
rm (glm.du.7.ew.49yo)
gc ()

glm.du.7.ew.50yo <- glm (pttype ~ distance_to_cut_50yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [203, 4] <- glm.du.7.ew.50yo$coefficients [[2]]
table.glm.summary [203, 5] <- summary(glm.du.7.ew.50yo)$coefficients [2,4]
rm (glm.du.7.ew.50yo)
gc ()

glm.du.7.ew.51yo <- glm (pttype ~ distance_to_cut_pre50yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [204, 4] <- glm.du.7.ew.51yo$coefficients [[2]]
table.glm.summary [204, 5] <- summary(glm.du.7.ew.51yo)$coefficients [2,4]
rm (glm.du.7.ew.51yo)
gc ()

## Late Winter ##
glm.du.7.lw.1yo <- glm (pttype ~ distance_to_cut_1yo, 
                        data = dist.cut.data.du.7.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [205, 4] <- glm.du.7.lw.1yo$coefficients [[2]]
table.glm.summary [205, 5] <- summary(glm.du.7.lw.1yo)$coefficients[2,4] # p-value
rm (glm.du.7.lw.1yo)
gc ()

glm.du.7.lw.2yo <- glm (pttype ~ distance_to_cut_2yo, 
                        data = dist.cut.data.du.7.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [206, 4] <- glm.du.7.lw.2yo$coefficients [[2]]
table.glm.summary [206, 5] <- summary(glm.du.7.lw.2yo)$coefficients[2,4]
rm (glm.du.7.lw.2yo)
gc ()

glm.du.7.lw.3yo <- glm (pttype ~ distance_to_cut_3yo, 
                        data = dist.cut.data.du.7.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [207, 4] <- glm.du.7.lw.3yo$coefficients [[2]]
table.glm.summary [207, 5] <- summary(glm.du.7.lw.3yo)$coefficients[2,4]
rm (glm.du.7.lw.3yo)
gc ()

glm.du.7.lw.4yo <- glm (pttype ~ distance_to_cut_4yo, 
                        data = dist.cut.data.du.7.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [208, 4] <- glm.du.7.lw.4yo$coefficients [[2]]
table.glm.summary [208, 5] <- summary(glm.du.7.lw.4yo)$coefficients [2,4]
rm (glm.du.7.lw.4yo)
gc ()

glm.du.7.lw.5yo <- glm (pttype ~ distance_to_cut_5yo, 
                        data = dist.cut.data.du.7.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [209, 4] <- glm.du.7.lw.5yo$coefficients [[2]]
table.glm.summary [209, 5] <- summary(glm.du.7.lw.5yo)$coefficients [2,4]
rm (glm.du.7.lw.5yo)
gc ()

glm.du.7.lw.6yo <- glm (pttype ~ distance_to_cut_6yo, 
                        data = dist.cut.data.du.7.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [210, 4] <- glm.du.7.lw.6yo$coefficients [[2]]
table.glm.summary [210, 5] <- summary(glm.du.7.lw.6yo)$coefficients [2,4]
rm (glm.du.7.lw.6yo)
gc ()

glm.du.7.lw.7yo <- glm (pttype ~ distance_to_cut_7yo, 
                        data = dist.cut.data.du.7.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [211, 4] <- glm.du.7.lw.7yo$coefficients [[2]]
table.glm.summary [211, 5] <- summary(glm.du.7.lw.7yo)$coefficients [2,4]
rm (glm.du.7.lw.7yo)
gc ()

glm.du.7.lw.8yo <- glm (pttype ~ distance_to_cut_8yo, 
                        data = dist.cut.data.du.7.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [212, 4] <- glm.du.7.lw.8yo$coefficients [[2]]
table.glm.summary [212, 5] <- summary(glm.du.7.lw.8yo)$coefficients [2,4]
rm (glm.du.7.lw.8yo)
gc ()

glm.du.7.lw.9yo <- glm (pttype ~ distance_to_cut_9yo, 
                        data = dist.cut.data.du.7.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [213, 4] <- glm.du.7.lw.9yo$coefficients [[2]]
table.glm.summary [213, 5] <- summary(glm.du.7.lw.9yo)$coefficients [2,4]
rm (glm.du.7.lw.9yo)
gc ()

glm.du.7.lw.10yo <- glm (pttype ~ distance_to_cut_10yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [214, 4] <- glm.du.7.lw.10yo$coefficients [[2]]
table.glm.summary [214, 5] <- summary(glm.du.7.lw.10yo)$coefficients [2,4]
rm (glm.du.7.lw.10yo)
gc ()

glm.du.7.lw.11yo <- glm (pttype ~ distance_to_cut_11yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [215, 4] <- glm.du.7.lw.11yo$coefficients [[2]]
table.glm.summary [215, 5] <- summary(glm.du.7.lw.11yo)$coefficients [2,4]
rm (glm.du.7.lw.11yo)
gc ()

glm.du.7.lw.12yo <- glm (pttype ~ distance_to_cut_12yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [216, 4] <- glm.du.7.lw.12yo$coefficients [[2]]
table.glm.summary [216, 5] <- summary(glm.du.7.lw.12yo)$coefficients [2,4]
rm (glm.du.7.lw.12yo)
gc ()

glm.du.7.lw.13yo <- glm (pttype ~ distance_to_cut_13yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [217, 4] <- glm.du.7.lw.13yo$coefficients [[2]]
table.glm.summary [217, 5] <- summary(glm.du.7.lw.13yo)$coefficients [2,4]
rm (glm.du.7.lw.13yo)
gc ()

glm.du.7.lw.14yo <- glm (pttype ~ distance_to_cut_14yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [218, 4] <- glm.du.7.lw.14yo$coefficients [[2]]
table.glm.summary [218, 5] <- summary(glm.du.7.lw.14yo)$coefficients [2,4]
rm (glm.du.7.lw.14yo)
gc ()

glm.du.7.lw.15yo <- glm (pttype ~ distance_to_cut_15yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [219, 4] <- glm.du.7.lw.15yo$coefficients [[2]]
table.glm.summary [219, 5] <- summary(glm.du.7.lw.15yo)$coefficients [2,4]
rm (glm.du.7.lw.15yo)
gc ()

glm.du.7.lw.16yo <- glm (pttype ~ distance_to_cut_16yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [220, 4] <- glm.du.7.lw.16yo$coefficients [[2]]
table.glm.summary [220, 5] <- summary(glm.du.7.lw.16yo)$coefficients [2,4]
rm (glm.du.7.lw.16yo)
gc ()

glm.du.7.lw.17yo <- glm (pttype ~ distance_to_cut_17yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [221, 4] <- glm.du.7.lw.17yo$coefficients [[2]]
table.glm.summary [221, 5] <- summary(glm.du.7.lw.17yo)$coefficients [2,4]
rm (glm.du.7.lw.17yo)
gc ()

glm.du.7.lw.18yo <- glm (pttype ~ distance_to_cut_18yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [222, 4] <- glm.du.7.lw.18yo$coefficients [[2]]
table.glm.summary [222, 5] <- summary(glm.du.7.lw.18yo)$coefficients [2,4]
rm (glm.du.7.lw.18yo)
gc ()

glm.du.7.lw.19yo <- glm (pttype ~ distance_to_cut_19yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [223, 4] <- glm.du.7.lw.19yo$coefficients [[2]]
table.glm.summary [223, 5] <- summary(glm.du.7.lw.19yo)$coefficients [2,4]
rm (glm.du.7.lw.19yo)
gc ()

glm.du.7.lw.20yo <- glm (pttype ~ distance_to_cut_20yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [224, 4] <- glm.du.7.lw.20yo$coefficients [[2]]
table.glm.summary [224, 5] <- summary(glm.du.7.lw.20yo)$coefficients [2,4]
rm (glm.du.7.lw.20yo)
gc ()

glm.du.7.lw.21yo <- glm (pttype ~ distance_to_cut_21yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [225, 4] <- glm.du.7.lw.21yo$coefficients [[2]]
table.glm.summary [225, 5] <- summary(glm.du.7.lw.21yo)$coefficients [2,4]
rm (glm.du.7.lw.21yo)
gc ()

glm.du.7.lw.22yo <- glm (pttype ~ distance_to_cut_22yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [226, 4] <- glm.du.7.lw.22yo$coefficients [[2]]
table.glm.summary [226, 5] <- summary(glm.du.7.lw.22yo)$coefficients [2,4]
rm (glm.du.7.lw.22yo)
gc ()

glm.du.7.lw.23yo <- glm (pttype ~ distance_to_cut_23yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [227, 4] <- glm.du.7.lw.23yo$coefficients [[2]]
table.glm.summary [227, 5] <- summary(glm.du.7.lw.23yo)$coefficients [2,4]
rm (glm.du.7.lw.23yo)
gc ()

glm.du.7.lw.24yo <- glm (pttype ~ distance_to_cut_24yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [228, 4] <- glm.du.7.lw.24yo$coefficients [[2]]
table.glm.summary [228, 5] <- summary(glm.du.7.lw.24yo)$coefficients [2,4]
rm (glm.du.7.lw.24yo)
gc ()

glm.du.7.lw.25yo <- glm (pttype ~ distance_to_cut_25yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [229, 4] <- glm.du.7.lw.25yo$coefficients [[2]]
table.glm.summary [229, 5] <- summary(glm.du.7.lw.25yo)$coefficients [2,4]
rm (glm.du.7.lw.25yo)
gc ()

glm.du.7.lw.26yo <- glm (pttype ~ distance_to_cut_26yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [230, 4] <- glm.du.7.lw.26yo$coefficients [[2]]
table.glm.summary [230, 5] <- summary(glm.du.7.lw.26yo)$coefficients [2,4]
rm (glm.du.7.lw.26yo)
gc ()

glm.du.7.lw.27yo <- glm (pttype ~ distance_to_cut_27yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [231, 4] <- glm.du.7.lw.27yo$coefficients [[2]]
table.glm.summary [231, 5] <- summary(glm.du.7.lw.27yo)$coefficients [2,4]
rm (glm.du.7.lw.27yo)
gc ()

glm.du.7.lw.28yo <- glm (pttype ~ distance_to_cut_28yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [232, 4] <- glm.du.7.lw.28yo$coefficients [[2]]
table.glm.summary [232, 5] <- summary(glm.du.7.lw.28yo)$coefficients [2,4]
rm (glm.du.7.lw.28yo)
gc ()

glm.du.7.lw.29yo <- glm (pttype ~ distance_to_cut_29yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [233, 4] <- glm.du.7.lw.29yo$coefficients [[2]]
table.glm.summary [233, 5] <- summary(glm.du.7.lw.29yo)$coefficients [2,4]
rm (glm.du.7.lw.29yo)
gc ()

glm.du.7.lw.30yo <- glm (pttype ~ distance_to_cut_30yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [234, 4] <- glm.du.7.lw.30yo$coefficients [[2]]
table.glm.summary [234, 5] <- summary(glm.du.7.lw.30yo)$coefficients [2,4]
rm (glm.du.7.lw.30yo)
gc ()

glm.du.7.lw.31yo <- glm (pttype ~ distance_to_cut_31yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [235, 4] <- glm.du.7.lw.31yo$coefficients [[2]]
table.glm.summary [235, 5] <- summary(glm.du.7.lw.31yo)$coefficients [2,4]
rm (glm.du.7.lw.31yo)
gc ()

glm.du.7.lw.32yo <- glm (pttype ~ distance_to_cut_32yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [236, 4] <- glm.du.7.lw.32yo$coefficients [[2]]
table.glm.summary [236, 5] <- summary(glm.du.7.lw.32yo)$coefficients [2,4]
rm (glm.du.7.lw.32yo)
gc ()

glm.du.7.lw.33yo <- glm (pttype ~ distance_to_cut_33yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [237, 4] <- glm.du.7.lw.33yo$coefficients [[2]]
table.glm.summary [237, 5] <- summary(glm.du.7.lw.33yo)$coefficients [2,4]
rm (glm.du.7.lw.33yo)
gc ()

glm.du.7.lw.34yo <- glm (pttype ~ distance_to_cut_34yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [238, 4] <- glm.du.7.lw.34yo$coefficients [[2]]
table.glm.summary [238, 5] <- summary(glm.du.7.lw.34yo)$coefficients [2,4]
rm (glm.du.7.lw.34yo)
gc ()

glm.du.7.lw.35yo <- glm (pttype ~ distance_to_cut_35yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [239, 4] <- glm.du.7.lw.35yo$coefficients [[2]]
table.glm.summary [239, 5] <- summary(glm.du.7.lw.35yo)$coefficients [2,4]
rm (glm.du.7.lw.35yo)
gc ()

glm.du.7.lw.36yo <- glm (pttype ~ distance_to_cut_36yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [240, 4] <- glm.du.7.lw.36yo$coefficients [[2]]
table.glm.summary [240, 5] <- summary(glm.du.7.lw.36yo)$coefficients [2,4]
rm (glm.du.7.lw.36yo)
gc ()

glm.du.7.lw.37yo <- glm (pttype ~ distance_to_cut_37yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [241, 4] <- glm.du.7.lw.37yo$coefficients [[2]]
table.glm.summary [241, 5] <- summary(glm.du.7.lw.37yo)$coefficients [2,4]
rm (glm.du.7.lw.37yo)
gc ()

glm.du.7.lw.38yo <- glm (pttype ~ distance_to_cut_38yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [242, 4] <- glm.du.7.lw.38yo$coefficients [[2]]
table.glm.summary [242, 5] <- summary(glm.du.7.lw.38yo)$coefficients [2,4]
rm (glm.du.7.lw.38yo)
gc ()

glm.du.7.lw.39yo <- glm (pttype ~ distance_to_cut_39yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [243, 4] <- glm.du.7.lw.39yo$coefficients [[2]]
table.glm.summary [243, 5] <- summary(glm.du.7.lw.39yo)$coefficients [2,4]
rm (glm.du.7.lw.39yo)
gc ()

glm.du.7.lw.40yo <- glm (pttype ~ distance_to_cut_40yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [244, 4] <- glm.du.7.lw.40yo$coefficients [[2]]
table.glm.summary [244, 5] <- summary(glm.du.7.lw.40yo)$coefficients [2,4]
rm (glm.du.7.lw.40yo)
gc ()

glm.du.7.lw.41yo <- glm (pttype ~ distance_to_cut_41yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [245, 4] <- glm.du.7.lw.41yo$coefficients [[2]]
table.glm.summary [245, 5] <- summary(glm.du.7.lw.41yo)$coefficients [2,4]
rm (glm.du.7.lw.41yo)
gc ()

glm.du.7.lw.42yo <- glm (pttype ~ distance_to_cut_42yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [246, 4] <- glm.du.7.lw.42yo$coefficients [[2]]
table.glm.summary [246, 5] <- summary(glm.du.7.lw.42yo)$coefficients [2,4]
rm (glm.du.7.lw.42yo)
gc ()

glm.du.7.lw.43yo <- glm (pttype ~ distance_to_cut_43yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [247, 4] <- glm.du.7.lw.43yo$coefficients [[2]]
table.glm.summary [247, 5] <- summary(glm.du.7.lw.43yo)$coefficients [2,4]
rm (glm.du.7.lw.43yo)
gc ()

glm.du.7.lw.44yo <- glm (pttype ~ distance_to_cut_44yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [248, 4] <- glm.du.7.lw.44yo$coefficients [[2]]
table.glm.summary [248, 5] <- summary(glm.du.7.lw.44yo)$coefficients [2,4]
rm (glm.du.7.lw.44yo)
gc ()

glm.du.7.lw.45yo <- glm (pttype ~ distance_to_cut_45yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [249, 4] <- glm.du.7.lw.45yo$coefficients [[2]]
table.glm.summary [249, 5] <- summary(glm.du.7.lw.45yo)$coefficients [2,4]
rm (glm.du.7.lw.45yo)
gc ()

glm.du.7.lw.46yo <- glm (pttype ~ distance_to_cut_46yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [250, 4] <- glm.du.7.lw.46yo$coefficients [[2]]
table.glm.summary [250, 5] <- summary(glm.du.7.lw.46yo)$coefficients [2,4]
rm (glm.du.7.lw.46yo)
gc ()

glm.du.7.lw.47yo <- glm (pttype ~ distance_to_cut_47yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [251, 4] <- glm.du.7.lw.47yo$coefficients [[2]]
table.glm.summary [251, 5] <- summary(glm.du.7.lw.47yo)$coefficients [2,4]
rm (glm.du.7.lw.47yo)
gc ()

glm.du.7.lw.48yo <- glm (pttype ~ distance_to_cut_48yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [252, 4] <- glm.du.7.lw.48yo$coefficients [[2]]
table.glm.summary [252, 5] <- summary(glm.du.7.lw.48yo)$coefficients [2,4]
rm (glm.du.7.lw.48yo)
gc ()

glm.du.7.lw.49yo <- glm (pttype ~ distance_to_cut_49yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [253, 4] <- glm.du.7.lw.49yo$coefficients [[2]]
table.glm.summary [253, 5] <- summary(glm.du.7.lw.49yo)$coefficients [2,4]
rm (glm.du.7.lw.49yo)
gc ()

glm.du.7.lw.50yo <- glm (pttype ~ distance_to_cut_50yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [254, 4] <- glm.du.7.lw.50yo$coefficients [[2]]
table.glm.summary [254, 5] <- summary(glm.du.7.lw.50yo)$coefficients [2,4]
rm (glm.du.7.lw.50yo)
gc ()

glm.du.7.lw.51yo <- glm (pttype ~ distance_to_cut_pre50yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [255, 4] <- glm.du.7.lw.51yo$coefficients [[2]]
table.glm.summary [255, 5] <- summary(glm.du.7.lw.51yo)$coefficients [2,4]
rm (glm.du.7.lw.51yo)
gc ()

## Summer ##
glm.du.7.s.1yo <- glm (pttype ~ distance_to_cut_1yo, 
                       data = dist.cut.data.du.7.s,
                       family = binomial (link = 'logit'))
table.glm.summary [256, 4] <- glm.du.7.s.1yo$coefficients [[2]]
table.glm.summary [256, 5] <- summary(glm.du.7.s.1yo)$coefficients[2,4] # p-value
rm (glm.du.7.s.1yo)
gc ()

glm.du.7.s.2yo <- glm (pttype ~ distance_to_cut_2yo, 
                       data = dist.cut.data.du.7.s,
                       family = binomial (link = 'logit'))
table.glm.summary [257, 4] <- glm.du.7.s.2yo$coefficients [[2]]
table.glm.summary [257, 5] <- summary(glm.du.7.s.2yo)$coefficients[2,4]
rm (glm.du.7.s.2yo)
gc ()

glm.du.7.s.3yo <- glm (pttype ~ distance_to_cut_3yo, 
                       data = dist.cut.data.du.7.s,
                       family = binomial (link = 'logit'))
table.glm.summary [258, 4] <- glm.du.7.s.3yo$coefficients [[2]]
table.glm.summary [258, 5] <- summary(glm.du.7.s.3yo)$coefficients[2,4]
rm (glm.du.7.s.3yo)
gc ()

glm.du.7.s.4yo <- glm (pttype ~ distance_to_cut_4yo, 
                       data = dist.cut.data.du.7.s,
                       family = binomial (link = 'logit'))
table.glm.summary [259, 4] <- glm.du.7.s.4yo$coefficients [[2]]
table.glm.summary [259, 5] <- summary(glm.du.7.s.4yo)$coefficients [2,4]
rm (glm.du.7.s.4yo)
gc ()

glm.du.7.s.5yo <- glm (pttype ~ distance_to_cut_5yo, 
                       data = dist.cut.data.du.7.s,
                       family = binomial (link = 'logit'))
table.glm.summary [260, 4] <- glm.du.7.s.5yo$coefficients [[2]]
table.glm.summary [260, 5] <- summary(glm.du.7.s.5yo)$coefficients [2,4]
rm (glm.du.7.s.5yo)
gc ()

glm.du.7.s.6yo <- glm (pttype ~ distance_to_cut_6yo, 
                       data = dist.cut.data.du.7.s,
                       family = binomial (link = 'logit'))
table.glm.summary [261, 4] <- glm.du.7.s.6yo$coefficients [[2]]
table.glm.summary [261, 5] <- summary(glm.du.7.s.6yo)$coefficients [2,4]
rm (glm.du.7.s.6yo)
gc ()

glm.du.7.s.7yo <- glm (pttype ~ distance_to_cut_7yo, 
                       data = dist.cut.data.du.7.s,
                       family = binomial (link = 'logit'))
table.glm.summary [262, 4] <- glm.du.7.s.7yo$coefficients [[2]]
table.glm.summary [262, 5] <- summary(glm.du.7.s.7yo)$coefficients [2,4]
rm (glm.du.7.s.7yo)
gc ()

glm.du.7.s.8yo <- glm (pttype ~ distance_to_cut_8yo, 
                       data = dist.cut.data.du.7.s,
                       family = binomial (link = 'logit'))
table.glm.summary [263, 4] <- glm.du.7.s.8yo$coefficients [[2]]
table.glm.summary [263, 5] <- summary(glm.du.7.s.8yo)$coefficients [2,4]
rm (glm.du.7.s.8yo)
gc ()

glm.du.7.s.9yo <- glm (pttype ~ distance_to_cut_9yo, 
                       data = dist.cut.data.du.7.s,
                       family = binomial (link = 'logit'))
table.glm.summary [264, 4] <- glm.du.7.s.9yo$coefficients [[2]]
table.glm.summary [264, 5] <- summary(glm.du.7.s.9yo)$coefficients [2,4]
rm (glm.du.7.s.9yo)
gc ()

glm.du.7.s.10yo <- glm (pttype ~ distance_to_cut_10yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [265, 4] <- glm.du.7.s.10yo$coefficients [[2]]
table.glm.summary [265, 5] <- summary(glm.du.7.s.10yo)$coefficients [2,4]
rm (glm.du.7.s.10yo)
gc ()

glm.du.7.s.11yo <- glm (pttype ~ distance_to_cut_11yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [266, 4] <- glm.du.7.s.11yo$coefficients [[2]]
table.glm.summary [266, 5] <- summary(glm.du.7.s.11yo)$coefficients [2,4]
rm (glm.du.7.s.11yo)
gc ()

glm.du.7.s.12yo <- glm (pttype ~ distance_to_cut_12yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [267, 4] <- glm.du.7.s.12yo$coefficients [[2]]
table.glm.summary [267, 5] <- summary(glm.du.7.s.12yo)$coefficients [2,4]
rm (glm.du.7.s.12yo)
gc ()

glm.du.7.s.13yo <- glm (pttype ~ distance_to_cut_13yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [268, 4] <- glm.du.7.s.13yo$coefficients [[2]]
table.glm.summary [268, 5] <- summary(glm.du.7.s.13yo)$coefficients [2,4]
rm (glm.du.7.s.13yo)
gc ()

glm.du.7.s.14yo <- glm (pttype ~ distance_to_cut_14yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [269, 4] <- glm.du.7.s.14yo$coefficients [[2]]
table.glm.summary [269, 5] <- summary(glm.du.7.s.14yo)$coefficients [2,4]
rm (glm.du.7.s.14yo)
gc ()

glm.du.7.s.15yo <- glm (pttype ~ distance_to_cut_15yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [270, 4] <- glm.du.7.s.15yo$coefficients [[2]]
table.glm.summary [270, 5] <- summary(glm.du.7.s.15yo)$coefficients [2,4]
rm (glm.du.7.s.15yo)
gc ()

glm.du.7.s.16yo <- glm (pttype ~ distance_to_cut_16yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [271, 4] <- glm.du.7.s.16yo$coefficients [[2]]
table.glm.summary [271, 5] <- summary(glm.du.7.s.16yo)$coefficients [2,4]
rm (glm.du.7.s.16yo)
gc ()

glm.du.7.s.17yo <- glm (pttype ~ distance_to_cut_17yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [272, 4] <- glm.du.7.s.17yo$coefficients [[2]]
table.glm.summary [272, 5] <- summary(glm.du.7.s.17yo)$coefficients [2,4]
rm (glm.du.7.s.17yo)
gc ()

glm.du.7.s.18yo <- glm (pttype ~ distance_to_cut_18yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [273, 4] <- glm.du.7.s.18yo$coefficients [[2]]
table.glm.summary [273, 5] <- summary(glm.du.7.s.18yo)$coefficients [2,4]
rm (glm.du.7.s.18yo)
gc ()

glm.du.7.s.19yo <- glm (pttype ~ distance_to_cut_19yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [274, 4] <- glm.du.7.s.19yo$coefficients [[2]]
table.glm.summary [274, 5] <- summary(glm.du.7.s.19yo)$coefficients [2,4]
rm (glm.du.7.s.19yo)
gc ()

glm.du.7.s.20yo <- glm (pttype ~ distance_to_cut_20yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [275, 4] <- glm.du.7.s.20yo$coefficients [[2]]
table.glm.summary [275, 5] <- summary(glm.du.7.s.20yo)$coefficients [2,4]
rm (glm.du.7.s.20yo)
gc ()

glm.du.7.s.21yo <- glm (pttype ~ distance_to_cut_21yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [276, 4] <- glm.du.7.s.21yo$coefficients [[2]]
table.glm.summary [276, 5] <- summary(glm.du.7.s.21yo)$coefficients [2,4]
rm (glm.du.7.s.21yo)
gc ()

glm.du.7.s.22yo <- glm (pttype ~ distance_to_cut_22yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [277, 4] <- glm.du.7.s.22yo$coefficients [[2]]
table.glm.summary [277, 5] <- summary(glm.du.7.s.22yo)$coefficients [2,4]
rm (glm.du.7.s.22yo)
gc ()

glm.du.7.s.23yo <- glm (pttype ~ distance_to_cut_23yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [278, 4] <- glm.du.7.s.23yo$coefficients [[2]]
table.glm.summary [278, 5] <- summary(glm.du.7.s.23yo)$coefficients [2,4]
rm (glm.du.7.s.23yo)
gc ()

glm.du.7.s.24yo <- glm (pttype ~ distance_to_cut_24yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [279, 4] <- glm.du.7.s.24yo$coefficients [[2]]
table.glm.summary [279, 5] <- summary(glm.du.7.s.24yo)$coefficients [2,4]
rm (glm.du.7.s.24yo)
gc ()

glm.du.7.s.25yo <- glm (pttype ~ distance_to_cut_25yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [280, 4] <- glm.du.7.s.25yo$coefficients [[2]]
table.glm.summary [280, 5] <- summary(glm.du.7.s.25yo)$coefficients [2,4]
rm (glm.du.7.s.25yo)
gc ()

glm.du.7.s.26yo <- glm (pttype ~ distance_to_cut_26yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [281, 4] <- glm.du.7.s.26yo$coefficients [[2]]
table.glm.summary [281, 5] <- summary(glm.du.7.s.26yo)$coefficients [2,4]
rm (glm.du.7.s.26yo)
gc ()

glm.du.7.s.27yo <- glm (pttype ~ distance_to_cut_27yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [282, 4] <- glm.du.7.s.27yo$coefficients [[2]]
table.glm.summary [282, 5] <- summary(glm.du.7.s.27yo)$coefficients [2,4]
rm (glm.du.7.s.27yo)
gc ()

glm.du.7.s.28yo <- glm (pttype ~ distance_to_cut_28yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [283, 4] <- glm.du.7.s.28yo$coefficients [[2]]
table.glm.summary [283, 5] <- summary(glm.du.7.s.28yo)$coefficients [2,4]
rm (glm.du.7.s.28yo)
gc ()

glm.du.7.s.29yo <- glm (pttype ~ distance_to_cut_29yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [284, 4] <- glm.du.7.s.29yo$coefficients [[2]]
table.glm.summary [284, 5] <- summary(glm.du.7.s.29yo)$coefficients [2,4]
rm (glm.du.7.s.29yo)
gc ()

glm.du.7.s.30yo <- glm (pttype ~ distance_to_cut_30yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [285, 4] <- glm.du.7.s.30yo$coefficients [[2]]
table.glm.summary [285, 5] <- summary(glm.du.7.s.30yo)$coefficients [2,4]
rm (glm.du.7.s.30yo)
gc ()

glm.du.7.s.31yo <- glm (pttype ~ distance_to_cut_31yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [286, 4] <- glm.du.7.s.31yo$coefficients [[2]]
table.glm.summary [286, 5] <- summary(glm.du.7.s.31yo)$coefficients [2,4]
rm (glm.du.7.s.31yo)
gc ()

glm.du.7.s.32yo <- glm (pttype ~ distance_to_cut_32yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [287, 4] <- glm.du.7.s.32yo$coefficients [[2]]
table.glm.summary [287, 5] <- summary(glm.du.7.s.32yo)$coefficients [2,4]
rm (glm.du.7.s.32yo)
gc ()

glm.du.7.s.33yo <- glm (pttype ~ distance_to_cut_33yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [288, 4] <- glm.du.7.s.33yo$coefficients [[2]]
table.glm.summary [288, 5] <- summary(glm.du.7.s.33yo)$coefficients [2,4]
rm (glm.du.7.s.33yo)
gc ()

glm.du.7.s.34yo <- glm (pttype ~ distance_to_cut_34yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [289, 4] <- glm.du.7.s.34yo$coefficients [[2]]
table.glm.summary [289, 5] <- summary(glm.du.7.s.34yo)$coefficients [2,4]
rm (glm.du.7.s.34yo)
gc ()

glm.du.7.s.35yo <- glm (pttype ~ distance_to_cut_35yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [290, 4] <- glm.du.7.s.35yo$coefficients [[2]]
table.glm.summary [290, 5] <- summary(glm.du.7.s.35yo)$coefficients [2,4]
rm (glm.du.7.s.35yo)
gc ()

glm.du.7.s.36yo <- glm (pttype ~ distance_to_cut_36yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [291, 4] <- glm.du.7.s.36yo$coefficients [[2]]
table.glm.summary [291, 5] <- summary(glm.du.7.s.36yo)$coefficients [2,4]
rm (glm.du.7.s.36yo)
gc ()

glm.du.7.s.37yo <- glm (pttype ~ distance_to_cut_37yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [292, 4] <- glm.du.7.s.37yo$coefficients [[2]]
table.glm.summary [292, 5] <- summary(glm.du.7.s.37yo)$coefficients [2,4]
rm (glm.du.7.s.37yo)
gc ()

glm.du.7.s.38yo <- glm (pttype ~ distance_to_cut_38yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [293, 4] <- glm.du.7.s.38yo$coefficients [[2]]
table.glm.summary [293, 5] <- summary(glm.du.7.s.38yo)$coefficients [2,4]
rm (glm.du.7.s.38yo)
gc ()

glm.du.7.s.39yo <- glm (pttype ~ distance_to_cut_39yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [294, 4] <- glm.du.7.s.39yo$coefficients [[2]]
table.glm.summary [294, 5] <- summary(glm.du.7.s.39yo)$coefficients [2,4]
rm (glm.du.7.s.39yo)
gc ()

glm.du.7.s.40yo <- glm (pttype ~ distance_to_cut_40yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [295, 4] <- glm.du.7.s.40yo$coefficients [[2]]
table.glm.summary [295, 5] <- summary(glm.du.7.s.40yo)$coefficients [2,4]
rm (glm.du.7.s.40yo)
gc ()

glm.du.7.s.41yo <- glm (pttype ~ distance_to_cut_41yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [296, 4] <- glm.du.7.s.41yo$coefficients [[2]]
table.glm.summary [296, 5] <- summary(glm.du.7.s.41yo)$coefficients [2,4]
rm (glm.du.7.s.41yo)
gc ()

glm.du.7.s.42yo <- glm (pttype ~ distance_to_cut_42yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [297, 4] <- glm.du.7.s.42yo$coefficients [[2]]
table.glm.summary [297, 5] <- summary(glm.du.7.s.42yo)$coefficients [2,4]
rm (glm.du.7.s.42yo)
gc ()

glm.du.7.s.43yo <- glm (pttype ~ distance_to_cut_43yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [298, 4] <- glm.du.7.s.43yo$coefficients [[2]]
table.glm.summary [298, 5] <- summary(glm.du.7.s.43yo)$coefficients [2,4]
rm (glm.du.7.s.43yo)
gc ()

glm.du.7.s.44yo <- glm (pttype ~ distance_to_cut_44yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [299, 4] <- glm.du.7.s.44yo$coefficients [[2]]
table.glm.summary [299, 5] <- summary(glm.du.7.s.44yo)$coefficients [2,4]
rm (glm.du.7.s.44yo)
gc ()

glm.du.7.s.45yo <- glm (pttype ~ distance_to_cut_45yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [300, 4] <- glm.du.7.s.45yo$coefficients [[2]]
table.glm.summary [300, 5] <- summary(glm.du.7.s.45yo)$coefficients [2,4]
rm (glm.du.7.s.45yo)
gc ()

glm.du.7.s.46yo <- glm (pttype ~ distance_to_cut_46yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [301, 4] <- glm.du.7.s.46yo$coefficients [[2]]
table.glm.summary [301, 5] <- summary(glm.du.7.s.46yo)$coefficients [2,4]
rm (glm.du.7.s.46yo)
gc ()

glm.du.7.s.47yo <- glm (pttype ~ distance_to_cut_47yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [302, 4] <- glm.du.7.s.47yo$coefficients [[2]]
table.glm.summary [302, 5] <- summary(glm.du.7.s.47yo)$coefficients [2,4]
rm (glm.du.7.s.47yo)
gc ()

glm.du.7.s.48yo <- glm (pttype ~ distance_to_cut_48yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [303, 4] <- glm.du.7.s.48yo$coefficients [[2]]
table.glm.summary [303, 5] <- summary(glm.du.7.s.48yo)$coefficients [2,4]
rm (glm.du.7.s.48yo)
gc ()

glm.du.7.s.49yo <- glm (pttype ~ distance_to_cut_49yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [304, 4] <- glm.du.7.s.49yo$coefficients [[2]]
table.glm.summary [304, 5] <- summary(glm.du.7.s.49yo)$coefficients [2,4]
rm (glm.du.7.s.49yo)
gc ()

glm.du.7.s.50yo <- glm (pttype ~ distance_to_cut_50yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [305, 4] <- glm.du.7.s.50yo$coefficients [[2]]
table.glm.summary [305, 5] <- summary(glm.du.7.s.50yo)$coefficients [2,4]
rm (glm.du.7.s.50yo)
gc ()

glm.du.7.s.51yo <- glm (pttype ~ distance_to_cut_pre50yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [306, 4] <- glm.du.7.s.51yo$coefficients [[2]]
table.glm.summary [306, 5] <- summary(glm.du.7.s.51yo)$coefficients [2,4]
rm (glm.du.7.s.51yo)
gc ()

## DU8 ###
## Early Winter ##
glm.du.8.ew.1yo <- glm (pttype ~ distance_to_cut_1yo, 
                        data = dist.cut.data.du.8.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [307, 4] <- glm.du.8.ew.1yo$coefficients [[2]]
table.glm.summary [307, 5] <- summary(glm.du.8.ew.1yo)$coefficients[2,4] # p-value
rm (glm.du.8.ew.1yo)
gc ()

glm.du.8.ew.2yo <- glm (pttype ~ distance_to_cut_2yo, 
                        data = dist.cut.data.du.8.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [308, 4] <- glm.du.8.ew.2yo$coefficients [[2]]
table.glm.summary [308, 5] <- summary(glm.du.8.ew.2yo)$coefficients[2,4]
rm (glm.du.8.ew.2yo)
gc ()

glm.du.8.ew.3yo <- glm (pttype ~ distance_to_cut_3yo, 
                        data = dist.cut.data.du.8.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [309, 4] <- glm.du.8.ew.3yo$coefficients [[2]]
table.glm.summary [309, 5] <- summary(glm.du.8.ew.3yo)$coefficients[2,4]
rm (glm.du.8.ew.3yo)
gc ()

glm.du.8.ew.4yo <- glm (pttype ~ distance_to_cut_4yo, 
                        data = dist.cut.data.du.8.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [310, 4] <- glm.du.8.ew.4yo$coefficients [[2]]
table.glm.summary [310, 5] <- summary(glm.du.8.ew.4yo)$coefficients [2,4]
rm (glm.du.8.ew.4yo)
gc ()

glm.du.8.ew.5yo <- glm (pttype ~ distance_to_cut_5yo, 
                        data = dist.cut.data.du.8.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [311, 4] <- glm.du.8.ew.5yo$coefficients [[2]]
table.glm.summary [311, 5] <- summary(glm.du.8.ew.5yo)$coefficients [2,4]
rm (glm.du.8.ew.5yo)
gc ()

glm.du.8.ew.6yo <- glm (pttype ~ distance_to_cut_6yo, 
                        data = dist.cut.data.du.8.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [312, 4] <- glm.du.8.ew.6yo$coefficients [[2]]
table.glm.summary [312, 5] <- summary(glm.du.8.ew.6yo)$coefficients [2,4]
rm (glm.du.8.ew.6yo)
gc ()

glm.du.8.ew.7yo <- glm (pttype ~ distance_to_cut_7yo, 
                        data = dist.cut.data.du.8.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [313, 4] <- glm.du.8.ew.7yo$coefficients [[2]]
table.glm.summary [313, 5] <- summary(glm.du.8.ew.7yo)$coefficients [2,4]
rm (glm.du.8.ew.7yo)
gc ()

glm.du.8.ew.8yo <- glm (pttype ~ distance_to_cut_8yo, 
                        data = dist.cut.data.du.8.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [314, 4] <- glm.du.8.ew.8yo$coefficients [[2]]
table.glm.summary [314, 5] <- summary(glm.du.8.ew.8yo)$coefficients [2,4]
rm (glm.du.8.ew.8yo)
gc ()

glm.du.8.ew.9yo <- glm (pttype ~ distance_to_cut_9yo, 
                        data = dist.cut.data.du.8.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [315, 4] <- glm.du.8.ew.9yo$coefficients [[2]]
table.glm.summary [315, 5] <- summary(glm.du.8.ew.9yo)$coefficients [2,4]
rm (glm.du.8.ew.9yo)
gc ()

glm.du.8.ew.10yo <- glm (pttype ~ distance_to_cut_10yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [316, 4] <- glm.du.8.ew.10yo$coefficients [[2]]
table.glm.summary [316, 5] <- summary(glm.du.8.ew.10yo)$coefficients [2,4]
rm (glm.du.8.ew.10yo)
gc ()

glm.du.8.ew.11yo <- glm (pttype ~ distance_to_cut_11yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [317, 4] <- glm.du.8.ew.11yo$coefficients [[2]]
table.glm.summary [317, 5] <- summary(glm.du.8.ew.11yo)$coefficients [2,4]
rm (glm.du.8.ew.11yo)
gc ()

glm.du.8.ew.12yo <- glm (pttype ~ distance_to_cut_12yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [318, 4] <- glm.du.8.ew.12yo$coefficients [[2]]
table.glm.summary [318, 5] <- summary(glm.du.8.ew.12yo)$coefficients [2,4]
rm (glm.du.8.ew.12yo)
gc ()

glm.du.8.ew.13yo <- glm (pttype ~ distance_to_cut_13yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [319, 4] <- glm.du.8.ew.13yo$coefficients [[2]]
table.glm.summary [319, 5] <- summary(glm.du.8.ew.13yo)$coefficients [2,4]
rm (glm.du.8.ew.13yo)
gc ()

glm.du.8.ew.14yo <- glm (pttype ~ distance_to_cut_14yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [320, 4] <- glm.du.8.ew.14yo$coefficients [[2]]
table.glm.summary [320, 5] <- summary(glm.du.8.ew.14yo)$coefficients [2,4]
rm (glm.du.8.ew.14yo)
gc ()

glm.du.8.ew.15yo <- glm (pttype ~ distance_to_cut_15yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [321, 4] <- glm.du.8.ew.15yo$coefficients [[2]]
table.glm.summary [321, 5] <- summary(glm.du.8.ew.15yo)$coefficients [2,4]
rm (glm.du.8.ew.15yo)
gc ()

glm.du.8.ew.16yo <- glm (pttype ~ distance_to_cut_16yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [322, 4] <- glm.du.8.ew.16yo$coefficients [[2]]
table.glm.summary [322, 5] <- summary(glm.du.8.ew.16yo)$coefficients [2,4]
rm (glm.du.8.ew.16yo)
gc ()

glm.du.8.ew.17yo <- glm (pttype ~ distance_to_cut_17yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [323, 4] <- glm.du.8.ew.17yo$coefficients [[2]]
table.glm.summary [323, 5] <- summary(glm.du.8.ew.17yo)$coefficients [2,4]
rm (glm.du.8.ew.17yo)
gc ()

glm.du.8.ew.18yo <- glm (pttype ~ distance_to_cut_18yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [324, 4] <- glm.du.8.ew.18yo$coefficients [[2]]
table.glm.summary [324, 5] <- summary(glm.du.8.ew.18yo)$coefficients [2,4]
rm (glm.du.8.ew.18yo)
gc ()

glm.du.8.ew.19yo <- glm (pttype ~ distance_to_cut_19yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [325, 4] <- glm.du.8.ew.19yo$coefficients [[2]]
table.glm.summary [325, 5] <- summary(glm.du.8.ew.19yo)$coefficients [2,4]
rm (glm.du.8.ew.19yo)
gc ()

glm.du.8.ew.20yo <- glm (pttype ~ distance_to_cut_20yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [326, 4] <- glm.du.8.ew.20yo$coefficients [[2]]
table.glm.summary [326, 5] <- summary(glm.du.8.ew.20yo)$coefficients [2,4]
rm (glm.du.8.ew.20yo)
gc ()

glm.du.8.ew.21yo <- glm (pttype ~ distance_to_cut_21yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [327, 4] <- glm.du.8.ew.21yo$coefficients [[2]]
table.glm.summary [327, 5] <- summary(glm.du.8.ew.21yo)$coefficients [2,4]
rm (glm.du.8.ew.21yo)
gc ()

glm.du.8.ew.22yo <- glm (pttype ~ distance_to_cut_22yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [328, 4] <- glm.du.8.ew.22yo$coefficients [[2]]
table.glm.summary [328, 5] <- summary(glm.du.8.ew.22yo)$coefficients [2,4]
rm (glm.du.8.ew.22yo)
gc ()

glm.du.8.ew.23yo <- glm (pttype ~ distance_to_cut_23yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [329, 4] <- glm.du.8.ew.23yo$coefficients [[2]]
table.glm.summary [329, 5] <- summary(glm.du.8.ew.23yo)$coefficients [2,4]
rm (glm.du.8.ew.23yo)
gc ()

glm.du.8.ew.24yo <- glm (pttype ~ distance_to_cut_24yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [330, 4] <- glm.du.8.ew.24yo$coefficients [[2]]
table.glm.summary [330, 5] <- summary(glm.du.8.ew.24yo)$coefficients [2,4]
rm (glm.du.8.ew.24yo)
gc ()

glm.du.8.ew.25yo <- glm (pttype ~ distance_to_cut_25yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [331, 4] <- glm.du.8.ew.25yo$coefficients [[2]]
table.glm.summary [331, 5] <- summary(glm.du.8.ew.25yo)$coefficients [2,4]
rm (glm.du.8.ew.25yo)
gc ()

glm.du.8.ew.26yo <- glm (pttype ~ distance_to_cut_26yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [332, 4] <- glm.du.8.ew.26yo$coefficients [[2]]
table.glm.summary [332, 5] <- summary(glm.du.8.ew.26yo)$coefficients [2,4]
rm (glm.du.8.ew.26yo)
gc ()

glm.du.8.ew.27yo <- glm (pttype ~ distance_to_cut_27yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [333, 4] <- glm.du.8.ew.27yo$coefficients [[2]]
table.glm.summary [333, 5] <- summary(glm.du.8.ew.27yo)$coefficients [2,4]
rm (glm.du.8.ew.27yo)
gc ()

glm.du.8.ew.28yo <- glm (pttype ~ distance_to_cut_28yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [334, 4] <- glm.du.8.ew.28yo$coefficients [[2]]
table.glm.summary [334, 5] <- summary(glm.du.8.ew.28yo)$coefficients [2,4]
rm (glm.du.8.ew.28yo)
gc ()

glm.du.8.ew.29yo <- glm (pttype ~ distance_to_cut_29yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [335, 4] <- glm.du.8.ew.29yo$coefficients [[2]]
table.glm.summary [335, 5] <- summary(glm.du.8.ew.29yo)$coefficients [2,4]
rm (glm.du.8.ew.29yo)
gc ()

glm.du.8.ew.30yo <- glm (pttype ~ distance_to_cut_30yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [336, 4] <- glm.du.8.ew.30yo$coefficients [[2]]
table.glm.summary [336, 5] <- summary(glm.du.8.ew.30yo)$coefficients [2,4]
rm (glm.du.8.ew.30yo)
gc ()

glm.du.8.ew.31yo <- glm (pttype ~ distance_to_cut_31yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [337, 4] <- glm.du.8.ew.31yo$coefficients [[2]]
table.glm.summary [337, 5] <- summary(glm.du.8.ew.31yo)$coefficients [2,4]
rm (glm.du.8.ew.31yo)
gc ()

glm.du.8.ew.32yo <- glm (pttype ~ distance_to_cut_32yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [338, 4] <- glm.du.8.ew.32yo$coefficients [[2]]
table.glm.summary [338, 5] <- summary(glm.du.8.ew.32yo)$coefficients [2,4]
rm (glm.du.8.ew.32yo)
gc ()

glm.du.8.ew.33yo <- glm (pttype ~ distance_to_cut_33yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [339, 4] <- glm.du.8.ew.33yo$coefficients [[2]]
table.glm.summary [339, 5] <- summary(glm.du.8.ew.33yo)$coefficients [2,4]
rm (glm.du.8.ew.33yo)
gc ()

glm.du.8.ew.34yo <- glm (pttype ~ distance_to_cut_34yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [340, 4] <- glm.du.8.ew.34yo$coefficients [[2]]
table.glm.summary [340, 5] <- summary(glm.du.8.ew.34yo)$coefficients [2,4]
rm (glm.du.8.ew.34yo)
gc ()

glm.du.8.ew.35yo <- glm (pttype ~ distance_to_cut_35yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [341, 4] <- glm.du.8.ew.35yo$coefficients [[2]]
table.glm.summary [341, 5] <- summary(glm.du.8.ew.35yo)$coefficients [2,4]
rm (glm.du.8.ew.35yo)
gc ()

glm.du.8.ew.36yo <- glm (pttype ~ distance_to_cut_36yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [342, 4] <- glm.du.8.ew.36yo$coefficients [[2]]
table.glm.summary [342, 5] <- summary(glm.du.8.ew.36yo)$coefficients [2,4]
rm (glm.du.8.ew.36yo)
gc ()

glm.du.8.ew.37yo <- glm (pttype ~ distance_to_cut_37yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [343, 4] <- glm.du.8.ew.37yo$coefficients [[2]]
table.glm.summary [343, 5] <- summary(glm.du.8.ew.37yo)$coefficients [2,4]
rm (glm.du.8.ew.37yo)
gc ()

glm.du.8.ew.38yo <- glm (pttype ~ distance_to_cut_38yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [344, 4] <- glm.du.8.ew.38yo$coefficients [[2]]
table.glm.summary [344, 5] <- summary(glm.du.8.ew.38yo)$coefficients [2,4]
rm (glm.du.8.ew.38yo)
gc ()

glm.du.8.ew.39yo <- glm (pttype ~ distance_to_cut_39yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [345, 4] <- glm.du.8.ew.39yo$coefficients [[2]]
table.glm.summary [345, 5] <- summary(glm.du.8.ew.39yo)$coefficients [2,4]
rm (glm.du.8.ew.39yo)
gc ()

glm.du.8.ew.40yo <- glm (pttype ~ distance_to_cut_40yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [346, 4] <- glm.du.8.ew.40yo$coefficients [[2]]
table.glm.summary [346, 5] <- summary(glm.du.8.ew.40yo)$coefficients [2,4]
rm (glm.du.8.ew.40yo)
gc ()

glm.du.8.ew.41yo <- glm (pttype ~ distance_to_cut_41yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [347, 4] <- glm.du.8.ew.41yo$coefficients [[2]]
table.glm.summary [347, 5] <- summary(glm.du.8.ew.41yo)$coefficients [2,4]
rm (glm.du.8.ew.41yo)
gc ()

glm.du.8.ew.42yo <- glm (pttype ~ distance_to_cut_42yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [348, 4] <- glm.du.8.ew.42yo$coefficients [[2]]
table.glm.summary [348, 5] <- summary(glm.du.8.ew.42yo)$coefficients [2,4]
rm (glm.du.8.ew.42yo)
gc ()

glm.du.8.ew.43yo <- glm (pttype ~ distance_to_cut_43yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [349, 4] <- glm.du.8.ew.43yo$coefficients [[2]]
table.glm.summary [349, 5] <- summary(glm.du.8.ew.43yo)$coefficients [2,4]
rm (glm.du.8.ew.43yo)
gc ()

glm.du.8.ew.44yo <- glm (pttype ~ distance_to_cut_44yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [350, 4] <- glm.du.8.ew.44yo$coefficients [[2]]
table.glm.summary [350, 5] <- summary(glm.du.8.ew.44yo)$coefficients [2,4]
rm (glm.du.8.ew.44yo)
gc ()

glm.du.8.ew.45yo <- glm (pttype ~ distance_to_cut_45yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [351, 4] <- glm.du.8.ew.45yo$coefficients [[2]]
table.glm.summary [351, 5] <- summary(glm.du.8.ew.45yo)$coefficients [2,4]
rm (glm.du.8.ew.45yo)
gc ()

glm.du.8.ew.46yo <- glm (pttype ~ distance_to_cut_46yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [352, 4] <- glm.du.8.ew.46yo$coefficients [[2]]
table.glm.summary [352, 5] <- summary(glm.du.8.ew.46yo)$coefficients [2,4]
rm (glm.du.8.ew.46yo)
gc ()

glm.du.8.ew.47yo <- glm (pttype ~ distance_to_cut_47yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [353, 4] <- glm.du.8.ew.47yo$coefficients [[2]]
table.glm.summary [353, 5] <- summary(glm.du.8.ew.47yo)$coefficients [2,4]
rm (glm.du.8.ew.47yo)
gc ()

glm.du.8.ew.48yo <- glm (pttype ~ distance_to_cut_48yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [354, 4] <- glm.du.8.ew.48yo$coefficients [[2]]
table.glm.summary [354, 5] <- summary(glm.du.8.ew.48yo)$coefficients [2,4]
rm (glm.du.8.ew.48yo)
gc ()

glm.du.8.ew.49yo <- glm (pttype ~ distance_to_cut_49yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [355, 4] <- glm.du.8.ew.49yo$coefficients [[2]]
table.glm.summary [355, 5] <- summary(glm.du.8.ew.49yo)$coefficients [2,4]
rm (glm.du.8.ew.49yo)
gc ()

glm.du.8.ew.50yo <- glm (pttype ~ distance_to_cut_50yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [356, 4] <- glm.du.8.ew.50yo$coefficients [[2]]
table.glm.summary [356, 5] <- summary(glm.du.8.ew.50yo)$coefficients [2,4]
rm (glm.du.8.ew.50yo)
gc ()

glm.du.8.ew.51yo <- glm (pttype ~ distance_to_cut_pre50yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [357, 4] <- glm.du.8.ew.51yo$coefficients [[2]]
table.glm.summary [357, 5] <- summary(glm.du.8.ew.51yo)$coefficients [2,4]
rm (glm.du.8.ew.51yo)
gc ()

## Late Winter ##
glm.du.8.lw.1yo <- glm (pttype ~ distance_to_cut_1yo, 
                        data = dist.cut.data.du.8.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [358, 4] <- glm.du.8.lw.1yo$coefficients [[2]]
table.glm.summary [358, 5] <- summary(glm.du.8.lw.1yo)$coefficients[2,4] # p-value
rm (glm.du.8.lw.1yo)
gc ()

glm.du.8.lw.2yo <- glm (pttype ~ distance_to_cut_2yo, 
                        data = dist.cut.data.du.8.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [359, 4] <- glm.du.8.lw.2yo$coefficients [[2]]
table.glm.summary [359, 5] <- summary(glm.du.8.lw.2yo)$coefficients[2,4]
rm (glm.du.8.lw.2yo)
gc ()

glm.du.8.lw.3yo <- glm (pttype ~ distance_to_cut_3yo, 
                        data = dist.cut.data.du.8.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [360, 4] <- glm.du.8.lw.3yo$coefficients [[2]]
table.glm.summary [360, 5] <- summary(glm.du.8.lw.3yo)$coefficients[2,4]
rm (glm.du.8.lw.3yo)
gc ()

glm.du.8.lw.4yo <- glm (pttype ~ distance_to_cut_4yo, 
                        data = dist.cut.data.du.8.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [361, 4] <- glm.du.8.lw.4yo$coefficients [[2]]
table.glm.summary [361, 5] <- summary(glm.du.8.lw.4yo)$coefficients [2,4]
rm (glm.du.8.lw.4yo)
gc ()

glm.du.8.lw.5yo <- glm (pttype ~ distance_to_cut_5yo, 
                        data = dist.cut.data.du.8.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [362, 4] <- glm.du.8.lw.5yo$coefficients [[2]]
table.glm.summary [362, 5] <- summary(glm.du.8.lw.5yo)$coefficients [2,4]
rm (glm.du.8.lw.5yo)
gc ()

glm.du.8.lw.6yo <- glm (pttype ~ distance_to_cut_6yo, 
                        data = dist.cut.data.du.8.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [363, 4] <- glm.du.8.lw.6yo$coefficients [[2]]
table.glm.summary [363, 5] <- summary(glm.du.8.lw.6yo)$coefficients [2,4]
rm (glm.du.8.lw.6yo)
gc ()

glm.du.8.lw.7yo <- glm (pttype ~ distance_to_cut_7yo, 
                        data = dist.cut.data.du.8.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [364, 4] <- glm.du.8.lw.7yo$coefficients [[2]]
table.glm.summary [364, 5] <- summary(glm.du.8.lw.7yo)$coefficients [2,4]
rm (glm.du.8.lw.7yo)
gc ()

glm.du.8.lw.8yo <- glm (pttype ~ distance_to_cut_8yo, 
                        data = dist.cut.data.du.8.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [365, 4] <- glm.du.8.lw.8yo$coefficients [[2]]
table.glm.summary [365, 5] <- summary(glm.du.8.lw.8yo)$coefficients [2,4]
rm (glm.du.8.lw.8yo)
gc ()

glm.du.8.lw.9yo <- glm (pttype ~ distance_to_cut_9yo, 
                        data = dist.cut.data.du.8.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [366, 4] <- glm.du.8.lw.9yo$coefficients [[2]]
table.glm.summary [366, 5] <- summary(glm.du.8.lw.9yo)$coefficients [2,4]
rm (glm.du.8.lw.9yo)
gc ()

glm.du.8.lw.10yo <- glm (pttype ~ distance_to_cut_10yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [367, 4] <- glm.du.8.lw.10yo$coefficients [[2]]
table.glm.summary [367, 5] <- summary(glm.du.8.lw.10yo)$coefficients [2,4]
rm (glm.du.8.lw.10yo)
gc ()

glm.du.8.lw.11yo <- glm (pttype ~ distance_to_cut_11yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [368, 4] <- glm.du.8.lw.11yo$coefficients [[2]]
table.glm.summary [368, 5] <- summary(glm.du.8.lw.11yo)$coefficients [2,4]
rm (glm.du.8.lw.11yo)
gc ()

glm.du.8.lw.12yo <- glm (pttype ~ distance_to_cut_12yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [369, 4] <- glm.du.8.lw.12yo$coefficients [[2]]
table.glm.summary [369, 5] <- summary(glm.du.8.lw.12yo)$coefficients [2,4]
rm (glm.du.8.lw.12yo)
gc ()

glm.du.8.lw.13yo <- glm (pttype ~ distance_to_cut_13yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [370, 4] <- glm.du.8.lw.13yo$coefficients [[2]]
table.glm.summary [370, 5] <- summary(glm.du.8.lw.13yo)$coefficients [2,4]
rm (glm.du.8.lw.13yo)
gc ()

glm.du.8.lw.14yo <- glm (pttype ~ distance_to_cut_14yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [371, 4] <- glm.du.8.lw.14yo$coefficients [[2]]
table.glm.summary [371, 5] <- summary(glm.du.8.lw.14yo)$coefficients [2,4]
rm (glm.du.8.lw.14yo)
gc ()

glm.du.8.lw.15yo <- glm (pttype ~ distance_to_cut_15yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [372, 4] <- glm.du.8.lw.15yo$coefficients [[2]]
table.glm.summary [372, 5] <- summary(glm.du.8.lw.15yo)$coefficients [2,4]
rm (glm.du.8.lw.15yo)
gc ()

glm.du.8.lw.16yo <- glm (pttype ~ distance_to_cut_16yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [373, 4] <- glm.du.8.lw.16yo$coefficients [[2]]
table.glm.summary [373, 5] <- summary(glm.du.8.lw.16yo)$coefficients [2,4]
rm (glm.du.8.lw.16yo)
gc ()

glm.du.8.lw.17yo <- glm (pttype ~ distance_to_cut_17yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [374, 4] <- glm.du.8.lw.17yo$coefficients [[2]]
table.glm.summary [374, 5] <- summary(glm.du.8.lw.17yo)$coefficients [2,4]
rm (glm.du.8.lw.17yo)
gc ()

glm.du.8.lw.18yo <- glm (pttype ~ distance_to_cut_18yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [375, 4] <- glm.du.8.lw.18yo$coefficients [[2]]
table.glm.summary [375, 5] <- summary(glm.du.8.lw.18yo)$coefficients [2,4]
rm (glm.du.8.lw.18yo)
gc ()

glm.du.8.lw.19yo <- glm (pttype ~ distance_to_cut_19yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [376, 4] <- glm.du.8.lw.19yo$coefficients [[2]]
table.glm.summary [376, 5] <- summary(glm.du.8.lw.19yo)$coefficients [2,4]
rm (glm.du.8.lw.19yo)
gc ()

glm.du.8.lw.20yo <- glm (pttype ~ distance_to_cut_20yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [377, 4] <- glm.du.8.lw.20yo$coefficients [[2]]
table.glm.summary [377, 5] <- summary(glm.du.8.lw.20yo)$coefficients [2,4]
rm (glm.du.8.lw.20yo)
gc ()

glm.du.8.lw.21yo <- glm (pttype ~ distance_to_cut_21yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [378, 4] <- glm.du.8.lw.21yo$coefficients [[2]]
table.glm.summary [378, 5] <- summary(glm.du.8.lw.21yo)$coefficients [2,4]
rm (glm.du.8.lw.21yo)
gc ()

glm.du.8.lw.22yo <- glm (pttype ~ distance_to_cut_22yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [379, 4] <- glm.du.8.lw.22yo$coefficients [[2]]
table.glm.summary [379, 5] <- summary(glm.du.8.lw.22yo)$coefficients [2,4]
rm (glm.du.8.lw.22yo)
gc ()

glm.du.8.lw.23yo <- glm (pttype ~ distance_to_cut_23yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [380, 4] <- glm.du.8.lw.23yo$coefficients [[2]]
table.glm.summary [380, 5] <- summary(glm.du.8.lw.23yo)$coefficients [2,4]
rm (glm.du.8.lw.23yo)
gc ()

glm.du.8.lw.24yo <- glm (pttype ~ distance_to_cut_24yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [381, 4] <- glm.du.8.lw.24yo$coefficients [[2]]
table.glm.summary [381, 5] <- summary(glm.du.8.lw.24yo)$coefficients [2,4]
rm (glm.du.8.lw.24yo)
gc ()

glm.du.8.lw.25yo <- glm (pttype ~ distance_to_cut_25yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [382, 4] <- glm.du.8.lw.25yo$coefficients [[2]]
table.glm.summary [382, 5] <- summary(glm.du.8.lw.25yo)$coefficients [2,4]
rm (glm.du.8.lw.25yo)
gc ()

glm.du.8.lw.26yo <- glm (pttype ~ distance_to_cut_26yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [383, 4] <- glm.du.8.lw.26yo$coefficients [[2]]
table.glm.summary [383, 5] <- summary(glm.du.8.lw.26yo)$coefficients [2,4]
rm (glm.du.8.lw.26yo)
gc ()

glm.du.8.lw.27yo <- glm (pttype ~ distance_to_cut_27yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [384, 4] <- glm.du.8.lw.27yo$coefficients [[2]]
table.glm.summary [384, 5] <- summary(glm.du.8.lw.27yo)$coefficients [2,4]
rm (glm.du.8.lw.27yo)
gc ()

glm.du.8.lw.28yo <- glm (pttype ~ distance_to_cut_28yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [385, 4] <- glm.du.8.lw.28yo$coefficients [[2]]
table.glm.summary [385, 5] <- summary(glm.du.8.lw.28yo)$coefficients [2,4]
rm (glm.du.8.lw.28yo)
gc ()

glm.du.8.lw.29yo <- glm (pttype ~ distance_to_cut_29yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [386, 4] <- glm.du.8.lw.29yo$coefficients [[2]]
table.glm.summary [386, 5] <- summary(glm.du.8.lw.29yo)$coefficients [2,4]
rm (glm.du.8.lw.29yo)
gc ()

glm.du.8.lw.30yo <- glm (pttype ~ distance_to_cut_30yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [387, 4] <- glm.du.8.lw.30yo$coefficients [[2]]
table.glm.summary [387, 5] <- summary(glm.du.8.lw.30yo)$coefficients [2,4]
rm (glm.du.8.lw.30yo)
gc ()

glm.du.8.lw.31yo <- glm (pttype ~ distance_to_cut_31yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [388, 4] <- glm.du.8.lw.31yo$coefficients [[2]]
table.glm.summary [388, 5] <- summary(glm.du.8.lw.31yo)$coefficients [2,4]
rm (glm.du.8.lw.31yo)
gc ()

glm.du.8.lw.32yo <- glm (pttype ~ distance_to_cut_32yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [389, 4] <- glm.du.8.lw.32yo$coefficients [[2]]
table.glm.summary [389, 5] <- summary(glm.du.8.lw.32yo)$coefficients [2,4]
rm (glm.du.8.lw.32yo)
gc ()

glm.du.8.lw.33yo <- glm (pttype ~ distance_to_cut_33yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [390, 4] <- glm.du.8.lw.33yo$coefficients [[2]]
table.glm.summary [390, 5] <- summary(glm.du.8.lw.33yo)$coefficients [2,4]
rm (glm.du.8.lw.33yo)
gc ()

glm.du.8.lw.34yo <- glm (pttype ~ distance_to_cut_34yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [391, 4] <- glm.du.8.lw.34yo$coefficients [[2]]
table.glm.summary [391, 5] <- summary(glm.du.8.lw.34yo)$coefficients [2,4]
rm (glm.du.8.lw.34yo)
gc ()

glm.du.8.lw.35yo <- glm (pttype ~ distance_to_cut_35yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [392, 4] <- glm.du.8.lw.35yo$coefficients [[2]]
table.glm.summary [392, 5] <- summary(glm.du.8.lw.35yo)$coefficients [2,4]
rm (glm.du.8.lw.35yo)
gc ()

glm.du.8.lw.36yo <- glm (pttype ~ distance_to_cut_36yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [393, 4] <- glm.du.8.lw.36yo$coefficients [[2]]
table.glm.summary [393, 5] <- summary(glm.du.8.lw.36yo)$coefficients [2,4]
rm (glm.du.8.lw.36yo)
gc ()

glm.du.8.lw.37yo <- glm (pttype ~ distance_to_cut_37yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [394, 4] <- glm.du.8.lw.37yo$coefficients [[2]]
table.glm.summary [394, 5] <- summary(glm.du.8.lw.37yo)$coefficients [2,4]
rm (glm.du.8.lw.37yo)
gc ()

glm.du.8.lw.38yo <- glm (pttype ~ distance_to_cut_38yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [395, 4] <- glm.du.8.lw.38yo$coefficients [[2]]
table.glm.summary [395, 5] <- summary(glm.du.8.lw.38yo)$coefficients [2,4]
rm (glm.du.8.lw.38yo)
gc ()

glm.du.8.lw.39yo <- glm (pttype ~ distance_to_cut_39yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [396, 4] <- glm.du.8.lw.39yo$coefficients [[2]]
table.glm.summary [396, 5] <- summary(glm.du.8.lw.39yo)$coefficients [2,4]
rm (glm.du.8.lw.39yo)
gc ()

glm.du.8.lw.40yo <- glm (pttype ~ distance_to_cut_40yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [397, 4] <- glm.du.8.lw.40yo$coefficients [[2]]
table.glm.summary [397, 5] <- summary(glm.du.8.lw.40yo)$coefficients [2,4]
rm (glm.du.8.lw.40yo)
gc ()

glm.du.8.lw.41yo <- glm (pttype ~ distance_to_cut_41yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [398, 4] <- glm.du.8.lw.41yo$coefficients [[2]]
table.glm.summary [398, 5] <- summary(glm.du.8.lw.41yo)$coefficients [2,4]
rm (glm.du.8.lw.41yo)
gc ()

glm.du.8.lw.42yo <- glm (pttype ~ distance_to_cut_42yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [399, 4] <- glm.du.8.lw.42yo$coefficients [[2]]
table.glm.summary [399, 5] <- summary(glm.du.8.lw.42yo)$coefficients [2,4]
rm (glm.du.8.lw.42yo)
gc ()

glm.du.8.lw.43yo <- glm (pttype ~ distance_to_cut_43yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [400, 4] <- glm.du.8.lw.43yo$coefficients [[2]]
table.glm.summary [400, 5] <- summary(glm.du.8.lw.43yo)$coefficients [2,4]
rm (glm.du.8.lw.43yo)
gc ()

glm.du.8.lw.44yo <- glm (pttype ~ distance_to_cut_44yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [401, 4] <- glm.du.8.lw.44yo$coefficients [[2]]
table.glm.summary [401, 5] <- summary(glm.du.8.lw.44yo)$coefficients [2,4]
rm (glm.du.8.lw.44yo)
gc ()

glm.du.8.lw.45yo <- glm (pttype ~ distance_to_cut_45yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [402, 4] <- glm.du.8.lw.45yo$coefficients [[2]]
table.glm.summary [402, 5] <- summary(glm.du.8.lw.45yo)$coefficients [2,4]
rm (glm.du.8.lw.45yo)
gc ()

glm.du.8.lw.46yo <- glm (pttype ~ distance_to_cut_46yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [403, 4] <- glm.du.8.lw.46yo$coefficients [[2]]
table.glm.summary [403, 5] <- summary(glm.du.8.lw.46yo)$coefficients [2,4]
rm (glm.du.8.lw.46yo)
gc ()

glm.du.8.lw.47yo <- glm (pttype ~ distance_to_cut_47yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [404, 4] <- glm.du.8.lw.47yo$coefficients [[2]]
table.glm.summary [404, 5] <- summary(glm.du.8.lw.47yo)$coefficients [2,4]
rm (glm.du.8.lw.47yo)
gc ()

glm.du.8.lw.48yo <- glm (pttype ~ distance_to_cut_48yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [405, 4] <- glm.du.8.lw.48yo$coefficients [[2]]
table.glm.summary [405, 5] <- summary(glm.du.8.lw.48yo)$coefficients [2,4]
rm (glm.du.8.lw.48yo)
gc ()

glm.du.8.lw.49yo <- glm (pttype ~ distance_to_cut_49yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [406, 4] <- glm.du.8.lw.49yo$coefficients [[2]]
table.glm.summary [406, 5] <- summary(glm.du.8.lw.49yo)$coefficients [2,4]
rm (glm.du.8.lw.49yo)
gc ()

glm.du.8.lw.50yo <- glm (pttype ~ distance_to_cut_50yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [407, 4] <- glm.du.8.lw.50yo$coefficients [[2]]
table.glm.summary [407, 5] <- summary(glm.du.8.lw.50yo)$coefficients [2,4]
rm (glm.du.8.lw.50yo)
gc ()

glm.du.8.lw.51yo <- glm (pttype ~ distance_to_cut_pre50yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [408, 4] <- glm.du.8.lw.51yo$coefficients [[2]]
table.glm.summary [408, 5] <- summary(glm.du.8.lw.51yo)$coefficients [2,4]
rm (glm.du.8.lw.51yo)
gc ()

## Summer ##
glm.du.8.s.1yo <- glm (pttype ~ distance_to_cut_1yo, 
                       data = dist.cut.data.du.8.s,
                       family = binomial (link = 'logit'))
table.glm.summary [409, 4] <- glm.du.8.s.1yo$coefficients [[2]]
table.glm.summary [409, 5] <- summary(glm.du.8.s.1yo)$coefficients[2,4] # p-value
rm (glm.du.8.s.1yo)
gc ()

glm.du.8.s.2yo <- glm (pttype ~ distance_to_cut_2yo, 
                       data = dist.cut.data.du.8.s,
                       family = binomial (link = 'logit'))
table.glm.summary [410, 4] <- glm.du.8.s.2yo$coefficients [[2]]
table.glm.summary [410, 5] <- summary(glm.du.8.s.2yo)$coefficients[2,4]
rm (glm.du.8.s.2yo)
gc ()

glm.du.8.s.3yo <- glm (pttype ~ distance_to_cut_3yo, 
                       data = dist.cut.data.du.8.s,
                       family = binomial (link = 'logit'))
table.glm.summary [411, 4] <- glm.du.8.s.3yo$coefficients [[2]]
table.glm.summary [411, 5] <- summary(glm.du.8.s.3yo)$coefficients[2,4]
rm (glm.du.8.s.3yo)
gc ()

glm.du.8.s.4yo <- glm (pttype ~ distance_to_cut_4yo, 
                       data = dist.cut.data.du.8.s,
                       family = binomial (link = 'logit'))
table.glm.summary [412, 4] <- glm.du.8.s.4yo$coefficients [[2]]
table.glm.summary [412, 5] <- summary(glm.du.8.s.4yo)$coefficients [2,4]
rm (glm.du.8.s.4yo)
gc ()

glm.du.8.s.5yo <- glm (pttype ~ distance_to_cut_5yo, 
                       data = dist.cut.data.du.8.s,
                       family = binomial (link = 'logit'))
table.glm.summary [413, 4] <- glm.du.8.s.5yo$coefficients [[2]]
table.glm.summary [413, 5] <- summary(glm.du.8.s.5yo)$coefficients [2,4]
rm (glm.du.8.s.5yo)
gc ()

glm.du.8.s.6yo <- glm (pttype ~ distance_to_cut_6yo, 
                       data = dist.cut.data.du.8.s,
                       family = binomial (link = 'logit'))
table.glm.summary [414, 4] <- glm.du.8.s.6yo$coefficients [[2]]
table.glm.summary [414, 5] <- summary(glm.du.8.s.6yo)$coefficients [2,4]
rm (glm.du.8.s.6yo)
gc ()

glm.du.8.s.7yo <- glm (pttype ~ distance_to_cut_7yo, 
                       data = dist.cut.data.du.8.s,
                       family = binomial (link = 'logit'))
table.glm.summary [415, 4] <- glm.du.8.s.7yo$coefficients [[2]]
table.glm.summary [415, 5] <- summary(glm.du.8.s.7yo)$coefficients [2,4]
rm (glm.du.8.s.7yo)
gc ()

glm.du.8.s.8yo <- glm (pttype ~ distance_to_cut_8yo, 
                       data = dist.cut.data.du.8.s,
                       family = binomial (link = 'logit'))
table.glm.summary [416, 4] <- glm.du.8.s.8yo$coefficients [[2]]
table.glm.summary [416, 5] <- summary(glm.du.8.s.8yo)$coefficients [2,4]
rm (glm.du.8.s.8yo)
gc ()

glm.du.8.s.9yo <- glm (pttype ~ distance_to_cut_9yo, 
                       data = dist.cut.data.du.8.s,
                       family = binomial (link = 'logit'))
table.glm.summary [417, 4] <- glm.du.8.s.9yo$coefficients [[2]]
table.glm.summary [417, 5] <- summary(glm.du.8.s.9yo)$coefficients [2,4]
rm (glm.du.8.s.9yo)
gc ()

glm.du.8.s.10yo <- glm (pttype ~ distance_to_cut_10yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [418, 4] <- glm.du.8.s.10yo$coefficients [[2]]
table.glm.summary [418, 5] <- summary(glm.du.8.s.10yo)$coefficients [2,4]
rm (glm.du.8.s.10yo)
gc ()

glm.du.8.s.11yo <- glm (pttype ~ distance_to_cut_11yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [419, 4] <- glm.du.8.s.11yo$coefficients [[2]]
table.glm.summary [419, 5] <- summary(glm.du.8.s.11yo)$coefficients [2,4]
rm (glm.du.8.s.11yo)
gc ()

glm.du.8.s.12yo <- glm (pttype ~ distance_to_cut_12yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [420, 4] <- glm.du.8.s.12yo$coefficients [[2]]
table.glm.summary [420, 5] <- summary(glm.du.8.s.12yo)$coefficients [2,4]
rm (glm.du.8.s.12yo)
gc ()

glm.du.8.s.13yo <- glm (pttype ~ distance_to_cut_13yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [421, 4] <- glm.du.8.s.13yo$coefficients [[2]]
table.glm.summary [421, 5] <- summary(glm.du.8.s.13yo)$coefficients [2,4]
rm (glm.du.8.s.13yo)
gc ()

glm.du.8.s.14yo <- glm (pttype ~ distance_to_cut_14yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [422, 4] <- glm.du.8.s.14yo$coefficients [[2]]
table.glm.summary [422, 5] <- summary(glm.du.8.s.14yo)$coefficients [2,4]
rm (glm.du.8.s.14yo)
gc ()

glm.du.8.s.15yo <- glm (pttype ~ distance_to_cut_15yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [423, 4] <- glm.du.8.s.15yo$coefficients [[2]]
table.glm.summary [423, 5] <- summary(glm.du.8.s.15yo)$coefficients [2,4]
rm (glm.du.8.s.15yo)
gc ()

glm.du.8.s.16yo <- glm (pttype ~ distance_to_cut_16yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [424, 4] <- glm.du.8.s.16yo$coefficients [[2]]
table.glm.summary [424, 5] <- summary(glm.du.8.s.16yo)$coefficients [2,4]
rm (glm.du.8.s.16yo)
gc ()

glm.du.8.s.17yo <- glm (pttype ~ distance_to_cut_17yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [425, 4] <- glm.du.8.s.17yo$coefficients [[2]]
table.glm.summary [425, 5] <- summary(glm.du.8.s.17yo)$coefficients [2,4]
rm (glm.du.8.s.17yo)
gc ()

glm.du.8.s.18yo <- glm (pttype ~ distance_to_cut_18yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [426, 4] <- glm.du.8.s.18yo$coefficients [[2]]
table.glm.summary [426, 5] <- summary(glm.du.8.s.18yo)$coefficients [2,4]
rm (glm.du.8.s.18yo)
gc ()

glm.du.8.s.19yo <- glm (pttype ~ distance_to_cut_19yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [427, 4] <- glm.du.8.s.19yo$coefficients [[2]]
table.glm.summary [427, 5] <- summary(glm.du.8.s.19yo)$coefficients [2,4]
rm (glm.du.8.s.19yo)
gc ()

glm.du.8.s.20yo <- glm (pttype ~ distance_to_cut_20yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [428, 4] <- glm.du.8.s.20yo$coefficients [[2]]
table.glm.summary [428, 5] <- summary(glm.du.8.s.20yo)$coefficients [2,4]
rm (glm.du.8.s.20yo)
gc ()

glm.du.8.s.21yo <- glm (pttype ~ distance_to_cut_21yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [429, 4] <- glm.du.8.s.21yo$coefficients [[2]]
table.glm.summary [429, 5] <- summary(glm.du.8.s.21yo)$coefficients [2,4]
rm (glm.du.8.s.21yo)
gc ()

glm.du.8.s.22yo <- glm (pttype ~ distance_to_cut_22yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [430, 4] <- glm.du.8.s.22yo$coefficients [[2]]
table.glm.summary [430, 5] <- summary(glm.du.8.s.22yo)$coefficients [2,4]
rm (glm.du.8.s.22yo)
gc ()

glm.du.8.s.23yo <- glm (pttype ~ distance_to_cut_23yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [431, 4] <- glm.du.8.s.23yo$coefficients [[2]]
table.glm.summary [431, 5] <- summary(glm.du.8.s.23yo)$coefficients [2,4]
rm (glm.du.8.s.23yo)
gc ()

glm.du.8.s.24yo <- glm (pttype ~ distance_to_cut_24yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [432, 4] <- glm.du.8.s.24yo$coefficients [[2]]
table.glm.summary [432, 5] <- summary(glm.du.8.s.24yo)$coefficients [2,4]
rm (glm.du.8.s.24yo)
gc ()

glm.du.8.s.25yo <- glm (pttype ~ distance_to_cut_25yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [433, 4] <- glm.du.8.s.25yo$coefficients [[2]]
table.glm.summary [433, 5] <- summary(glm.du.8.s.25yo)$coefficients [2,4]
rm (glm.du.8.s.25yo)
gc ()

glm.du.8.s.26yo <- glm (pttype ~ distance_to_cut_26yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [434, 4] <- glm.du.8.s.26yo$coefficients [[2]]
table.glm.summary [434, 5] <- summary(glm.du.8.s.26yo)$coefficients [2,4]
rm (glm.du.8.s.26yo)
gc ()

glm.du.8.s.27yo <- glm (pttype ~ distance_to_cut_27yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [435, 4] <- glm.du.8.s.27yo$coefficients [[2]]
table.glm.summary [435, 5] <- summary(glm.du.8.s.27yo)$coefficients [2,4]
rm (glm.du.8.s.27yo)
gc ()

glm.du.8.s.28yo <- glm (pttype ~ distance_to_cut_28yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [436, 4] <- glm.du.8.s.28yo$coefficients [[2]]
table.glm.summary [436, 5] <- summary(glm.du.8.s.28yo)$coefficients [2,4]
rm (glm.du.8.s.28yo)
gc ()

glm.du.8.s.29yo <- glm (pttype ~ distance_to_cut_29yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [437, 4] <- glm.du.8.s.29yo$coefficients [[2]]
table.glm.summary [437, 5] <- summary(glm.du.8.s.29yo)$coefficients [2,4]
rm (glm.du.8.s.29yo)
gc ()

glm.du.8.s.30yo <- glm (pttype ~ distance_to_cut_30yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [438, 4] <- glm.du.8.s.30yo$coefficients [[2]]
table.glm.summary [438, 5] <- summary(glm.du.8.s.30yo)$coefficients [2,4]
rm (glm.du.8.s.30yo)
gc ()

glm.du.8.s.31yo <- glm (pttype ~ distance_to_cut_31yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [439, 4] <- glm.du.8.s.31yo$coefficients [[2]]
table.glm.summary [439, 5] <- summary(glm.du.8.s.31yo)$coefficients [2,4]
rm (glm.du.8.s.31yo)
gc ()

glm.du.8.s.32yo <- glm (pttype ~ distance_to_cut_32yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [440, 4] <- glm.du.8.s.32yo$coefficients [[2]]
table.glm.summary [440, 5] <- summary(glm.du.8.s.32yo)$coefficients [2,4]
rm (glm.du.8.s.32yo)
gc ()

glm.du.8.s.33yo <- glm (pttype ~ distance_to_cut_33yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [441, 4] <- glm.du.8.s.33yo$coefficients [[2]]
table.glm.summary [441, 5] <- summary(glm.du.8.s.33yo)$coefficients [2,4]
rm (glm.du.8.s.33yo)
gc ()

glm.du.8.s.34yo <- glm (pttype ~ distance_to_cut_34yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [442, 4] <- glm.du.8.s.34yo$coefficients [[2]]
table.glm.summary [442, 5] <- summary(glm.du.8.s.34yo)$coefficients [2,4]
rm (glm.du.8.s.34yo)
gc ()

glm.du.8.s.35yo <- glm (pttype ~ distance_to_cut_35yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [443, 4] <- glm.du.8.s.35yo$coefficients [[2]]
table.glm.summary [443, 5] <- summary(glm.du.8.s.35yo)$coefficients [2,4]
rm (glm.du.8.s.35yo)
gc ()

glm.du.8.s.36yo <- glm (pttype ~ distance_to_cut_36yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [444, 4] <- glm.du.8.s.36yo$coefficients [[2]]
table.glm.summary [444, 5] <- summary(glm.du.8.s.36yo)$coefficients [2,4]
rm (glm.du.8.s.36yo)
gc ()

glm.du.8.s.37yo <- glm (pttype ~ distance_to_cut_37yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [445, 4] <- glm.du.8.s.37yo$coefficients [[2]]
table.glm.summary [445, 5] <- summary(glm.du.8.s.37yo)$coefficients [2,4]
rm (glm.du.8.s.37yo)
gc ()

glm.du.8.s.38yo <- glm (pttype ~ distance_to_cut_38yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [446, 4] <- glm.du.8.s.38yo$coefficients [[2]]
table.glm.summary [446, 5] <- summary(glm.du.8.s.38yo)$coefficients [2,4]
rm (glm.du.8.s.38yo)
gc ()

glm.du.8.s.39yo <- glm (pttype ~ distance_to_cut_39yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [447, 4] <- glm.du.8.s.39yo$coefficients [[2]]
table.glm.summary [447, 5] <- summary(glm.du.8.s.39yo)$coefficients [2,4]
rm (glm.du.8.s.39yo)
gc ()

glm.du.8.s.40yo <- glm (pttype ~ distance_to_cut_40yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [448, 4] <- glm.du.8.s.40yo$coefficients [[2]]
table.glm.summary [448, 5] <- summary(glm.du.8.s.40yo)$coefficients [2,4]
rm (glm.du.8.s.40yo)
gc ()

glm.du.8.s.41yo <- glm (pttype ~ distance_to_cut_41yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [449, 4] <- glm.du.8.s.41yo$coefficients [[2]]
table.glm.summary [449, 5] <- summary(glm.du.8.s.41yo)$coefficients [2,4]
rm (glm.du.8.s.41yo)
gc ()

glm.du.8.s.42yo <- glm (pttype ~ distance_to_cut_42yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [450, 4] <- glm.du.8.s.42yo$coefficients [[2]]
table.glm.summary [450, 5] <- summary(glm.du.8.s.42yo)$coefficients [2,4]
rm (glm.du.8.s.42yo)
gc ()

glm.du.8.s.43yo <- glm (pttype ~ distance_to_cut_43yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [451, 4] <- glm.du.8.s.43yo$coefficients [[2]]
table.glm.summary [451, 5] <- summary(glm.du.8.s.43yo)$coefficients [2,4]
rm (glm.du.8.s.43yo)
gc ()

glm.du.8.s.44yo <- glm (pttype ~ distance_to_cut_44yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [452, 4] <- glm.du.8.s.44yo$coefficients [[2]]
table.glm.summary [452, 5] <- summary(glm.du.8.s.44yo)$coefficients [2,4]
rm (glm.du.8.s.44yo)
gc ()

glm.du.8.s.45yo <- glm (pttype ~ distance_to_cut_45yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [453, 4] <- glm.du.8.s.45yo$coefficients [[2]]
table.glm.summary [453, 5] <- summary(glm.du.8.s.45yo)$coefficients [2,4]
rm (glm.du.8.s.45yo)
gc ()

glm.du.8.s.46yo <- glm (pttype ~ distance_to_cut_46yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [454, 4] <- glm.du.8.s.46yo$coefficients [[2]]
table.glm.summary [454, 5] <- summary(glm.du.8.s.46yo)$coefficients [2,4]
rm (glm.du.8.s.46yo)
gc ()

glm.du.8.s.47yo <- glm (pttype ~ distance_to_cut_47yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [455, 4] <- glm.du.8.s.47yo$coefficients [[2]]
table.glm.summary [455, 5] <- summary(glm.du.8.s.47yo)$coefficients [2,4]
rm (glm.du.8.s.47yo)
gc ()

glm.du.8.s.48yo <- glm (pttype ~ distance_to_cut_48yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [456, 4] <- glm.du.8.s.48yo$coefficients [[2]]
table.glm.summary [456, 5] <- summary(glm.du.8.s.48yo)$coefficients [2,4]
rm (glm.du.8.s.48yo)
gc ()

glm.du.8.s.49yo <- glm (pttype ~ distance_to_cut_49yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [457, 4] <- glm.du.8.s.49yo$coefficients [[2]]
table.glm.summary [457, 5] <- summary(glm.du.8.s.49yo)$coefficients [2,4]
rm (glm.du.8.s.49yo)
gc ()

glm.du.8.s.50yo <- glm (pttype ~ distance_to_cut_50yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [458, 4] <- glm.du.8.s.50yo$coefficients [[2]]
table.glm.summary [458, 5] <- summary(glm.du.8.s.50yo)$coefficients [2,4]
rm (glm.du.8.s.50yo)
gc ()

glm.du.8.s.51yo <- glm (pttype ~ distance_to_cut_pre50yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [459, 4] <- glm.du.8.s.51yo$coefficients [[2]]
table.glm.summary [459, 5] <- summary(glm.du.8.s.51yo)$coefficients [2,4]
rm (glm.du.8.s.51yo)
gc ()


## DU9 ###
## Early Winter ##
glm.du.9.ew.1yo <- glm (pttype ~ distance_to_cut_1yo, 
                        data = dist.cut.data.du.9.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [460, 4] <- glm.du.9.ew.1yo$coefficients [[2]]
table.glm.summary [460, 5] <- summary(glm.du.9.ew.1yo)$coefficients[2,4] # p-value
rm (glm.du.9.ew.1yo)
gc ()

glm.du.9.ew.2yo <- glm (pttype ~ distance_to_cut_2yo, 
                        data = dist.cut.data.du.9.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [461, 4] <- glm.du.9.ew.2yo$coefficients [[2]]
table.glm.summary [461, 5] <- summary(glm.du.9.ew.2yo)$coefficients[2,4]
rm (glm.du.9.ew.2yo)
gc ()

glm.du.9.ew.3yo <- glm (pttype ~ distance_to_cut_3yo, 
                        data = dist.cut.data.du.9.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [462, 4] <- glm.du.9.ew.3yo$coefficients [[2]]
table.glm.summary [462, 5] <- summary(glm.du.9.ew.3yo)$coefficients[2,4]
rm (glm.du.9.ew.3yo)
gc ()

glm.du.9.ew.4yo <- glm (pttype ~ distance_to_cut_4yo, 
                        data = dist.cut.data.du.9.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [463, 4] <- glm.du.9.ew.4yo$coefficients [[2]]
table.glm.summary [463, 5] <- summary(glm.du.9.ew.4yo)$coefficients [2,4]
rm (glm.du.9.ew.4yo)
gc ()

glm.du.9.ew.5yo <- glm (pttype ~ distance_to_cut_5yo, 
                        data = dist.cut.data.du.9.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [464, 4] <- glm.du.9.ew.5yo$coefficients [[2]]
table.glm.summary [464, 5] <- summary(glm.du.9.ew.5yo)$coefficients [2,4]
rm (glm.du.9.ew.5yo)
gc ()

glm.du.9.ew.6yo <- glm (pttype ~ distance_to_cut_6yo, 
                        data = dist.cut.data.du.9.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [465, 4] <- glm.du.9.ew.6yo$coefficients [[2]]
table.glm.summary [465, 5] <- summary(glm.du.9.ew.6yo)$coefficients [2,4]
rm (glm.du.9.ew.6yo)
gc ()

glm.du.9.ew.7yo <- glm (pttype ~ distance_to_cut_7yo, 
                        data = dist.cut.data.du.9.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [466, 4] <- glm.du.9.ew.7yo$coefficients [[2]]
table.glm.summary [466, 5] <- summary(glm.du.9.ew.7yo)$coefficients [2,4]
rm (glm.du.9.ew.7yo)
gc ()

glm.du.9.ew.8yo <- glm (pttype ~ distance_to_cut_8yo, 
                        data = dist.cut.data.du.9.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [467, 4] <- glm.du.9.ew.8yo$coefficients [[2]]
table.glm.summary [467, 5] <- summary(glm.du.9.ew.8yo)$coefficients [2,4]
rm (glm.du.9.ew.8yo)
gc ()

glm.du.9.ew.9yo <- glm (pttype ~ distance_to_cut_9yo, 
                        data = dist.cut.data.du.9.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [468, 4] <- glm.du.9.ew.9yo$coefficients [[2]]
table.glm.summary [468, 5] <- summary(glm.du.9.ew.9yo)$coefficients [2,4]
rm (glm.du.9.ew.9yo)
gc ()

glm.du.9.ew.10yo <- glm (pttype ~ distance_to_cut_10yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [469, 4] <- glm.du.9.ew.10yo$coefficients [[2]]
table.glm.summary [469, 5] <- summary(glm.du.9.ew.10yo)$coefficients [2,4]
rm (glm.du.9.ew.10yo)
gc ()

glm.du.9.ew.11yo <- glm (pttype ~ distance_to_cut_11yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [470, 4] <- glm.du.9.ew.11yo$coefficients [[2]]
table.glm.summary [470, 5] <- summary(glm.du.9.ew.11yo)$coefficients [2,4]
rm (glm.du.9.ew.11yo)
gc ()

glm.du.9.ew.12yo <- glm (pttype ~ distance_to_cut_12yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [471, 4] <- glm.du.9.ew.12yo$coefficients [[2]]
table.glm.summary [471, 5] <- summary(glm.du.9.ew.12yo)$coefficients [2,4]
rm (glm.du.9.ew.12yo)
gc ()

glm.du.9.ew.13yo <- glm (pttype ~ distance_to_cut_13yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [472, 4] <- glm.du.9.ew.13yo$coefficients [[2]]
table.glm.summary [472, 5] <- summary(glm.du.9.ew.13yo)$coefficients [2,4]
rm (glm.du.9.ew.13yo)
gc ()

glm.du.9.ew.14yo <- glm (pttype ~ distance_to_cut_14yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [473, 4] <- glm.du.9.ew.14yo$coefficients [[2]]
table.glm.summary [473, 5] <- summary(glm.du.9.ew.14yo)$coefficients [2,4]
rm (glm.du.9.ew.14yo)
gc ()

glm.du.9.ew.15yo <- glm (pttype ~ distance_to_cut_15yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [474, 4] <- glm.du.9.ew.15yo$coefficients [[2]]
table.glm.summary [474, 5] <- summary(glm.du.9.ew.15yo)$coefficients [2,4]
rm (glm.du.9.ew.15yo)
gc ()

glm.du.9.ew.16yo <- glm (pttype ~ distance_to_cut_16yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [475, 4] <- glm.du.9.ew.16yo$coefficients [[2]]
table.glm.summary [475, 5] <- summary(glm.du.9.ew.16yo)$coefficients [2,4]
rm (glm.du.9.ew.16yo)
gc ()

glm.du.9.ew.17yo <- glm (pttype ~ distance_to_cut_17yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [476, 4] <- glm.du.9.ew.17yo$coefficients [[2]]
table.glm.summary [476, 5] <- summary(glm.du.9.ew.17yo)$coefficients [2,4]
rm (glm.du.9.ew.17yo)
gc ()

glm.du.9.ew.18yo <- glm (pttype ~ distance_to_cut_18yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [477, 4] <- glm.du.9.ew.18yo$coefficients [[2]]
table.glm.summary [477, 5] <- summary(glm.du.9.ew.18yo)$coefficients [2,4]
rm (glm.du.9.ew.18yo)
gc ()

glm.du.9.ew.19yo <- glm (pttype ~ distance_to_cut_19yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [478, 4] <- glm.du.9.ew.19yo$coefficients [[2]]
table.glm.summary [478, 5] <- summary(glm.du.9.ew.19yo)$coefficients [2,4]
rm (glm.du.9.ew.19yo)
gc ()

glm.du.9.ew.20yo <- glm (pttype ~ distance_to_cut_20yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [479, 4] <- glm.du.9.ew.20yo$coefficients [[2]]
table.glm.summary [479, 5] <- summary(glm.du.9.ew.20yo)$coefficients [2,4]
rm (glm.du.9.ew.20yo)
gc ()

glm.du.9.ew.21yo <- glm (pttype ~ distance_to_cut_21yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [480, 4] <- glm.du.9.ew.21yo$coefficients [[2]]
table.glm.summary [480, 5] <- summary(glm.du.9.ew.21yo)$coefficients [2,4]
rm (glm.du.9.ew.21yo)
gc ()

glm.du.9.ew.22yo <- glm (pttype ~ distance_to_cut_22yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [481, 4] <- glm.du.9.ew.22yo$coefficients [[2]]
table.glm.summary [481, 5] <- summary(glm.du.9.ew.22yo)$coefficients [2,4]
rm (glm.du.9.ew.22yo)
gc ()

glm.du.9.ew.23yo <- glm (pttype ~ distance_to_cut_23yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [482, 4] <- glm.du.9.ew.23yo$coefficients [[2]]
table.glm.summary [482, 5] <- summary(glm.du.9.ew.23yo)$coefficients [2,4]
rm (glm.du.9.ew.23yo)
gc ()

glm.du.9.ew.24yo <- glm (pttype ~ distance_to_cut_24yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [483, 4] <- glm.du.9.ew.24yo$coefficients [[2]]
table.glm.summary [483, 5] <- summary(glm.du.9.ew.24yo)$coefficients [2,4]
rm (glm.du.9.ew.24yo)
gc ()

glm.du.9.ew.25yo <- glm (pttype ~ distance_to_cut_25yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [484, 4] <- glm.du.9.ew.25yo$coefficients [[2]]
table.glm.summary [484, 5] <- summary(glm.du.9.ew.25yo)$coefficients [2,4]
rm (glm.du.9.ew.25yo)
gc ()

glm.du.9.ew.26yo <- glm (pttype ~ distance_to_cut_26yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [485, 4] <- glm.du.9.ew.26yo$coefficients [[2]]
table.glm.summary [485, 5] <- summary(glm.du.9.ew.26yo)$coefficients [2,4]
rm (glm.du.9.ew.26yo)
gc ()

glm.du.9.ew.27yo <- glm (pttype ~ distance_to_cut_27yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [486, 4] <- glm.du.9.ew.27yo$coefficients [[2]]
table.glm.summary [486, 5] <- summary(glm.du.9.ew.27yo)$coefficients [2,4]
rm (glm.du.9.ew.27yo)
gc ()

glm.du.9.ew.28yo <- glm (pttype ~ distance_to_cut_28yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [487, 4] <- glm.du.9.ew.28yo$coefficients [[2]]
table.glm.summary [487, 5] <- summary(glm.du.9.ew.28yo)$coefficients [2,4]
rm (glm.du.9.ew.28yo)
gc ()

glm.du.9.ew.29yo <- glm (pttype ~ distance_to_cut_29yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [488, 4] <- glm.du.9.ew.29yo$coefficients [[2]]
table.glm.summary [488, 5] <- summary(glm.du.9.ew.29yo)$coefficients [2,4]
rm (glm.du.9.ew.29yo)
gc ()

glm.du.9.ew.30yo <- glm (pttype ~ distance_to_cut_30yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [489, 4] <- glm.du.9.ew.30yo$coefficients [[2]]
table.glm.summary [489, 5] <- summary(glm.du.9.ew.30yo)$coefficients [2,4]
rm (glm.du.9.ew.30yo)
gc ()

glm.du.9.ew.31yo <- glm (pttype ~ distance_to_cut_31yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [490, 4] <- glm.du.9.ew.31yo$coefficients [[2]]
table.glm.summary [490, 5] <- summary(glm.du.9.ew.31yo)$coefficients [2,4]
rm (glm.du.9.ew.31yo)
gc ()

glm.du.9.ew.32yo <- glm (pttype ~ distance_to_cut_32yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [491, 4] <- glm.du.9.ew.32yo$coefficients [[2]]
table.glm.summary [491, 5] <- summary(glm.du.9.ew.32yo)$coefficients [2,4]
rm (glm.du.9.ew.32yo)
gc ()

glm.du.9.ew.33yo <- glm (pttype ~ distance_to_cut_33yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [492, 4] <- glm.du.9.ew.33yo$coefficients [[2]]
table.glm.summary [492, 5] <- summary(glm.du.9.ew.33yo)$coefficients [2,4]
rm (glm.du.9.ew.33yo)
gc ()

glm.du.9.ew.34yo <- glm (pttype ~ distance_to_cut_34yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [493, 4] <- glm.du.9.ew.34yo$coefficients [[2]]
table.glm.summary [493, 5] <- summary(glm.du.9.ew.34yo)$coefficients [2,4]
rm (glm.du.9.ew.34yo)
gc ()

glm.du.9.ew.35yo <- glm (pttype ~ distance_to_cut_35yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [494, 4] <- glm.du.9.ew.35yo$coefficients [[2]]
table.glm.summary [494, 5] <- summary(glm.du.9.ew.35yo)$coefficients [2,4]
rm (glm.du.9.ew.35yo)
gc ()

glm.du.9.ew.36yo <- glm (pttype ~ distance_to_cut_36yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [495, 4] <- glm.du.9.ew.36yo$coefficients [[2]]
table.glm.summary [495, 5] <- summary(glm.du.9.ew.36yo)$coefficients [2,4]
rm (glm.du.9.ew.36yo)
gc ()

glm.du.9.ew.37yo <- glm (pttype ~ distance_to_cut_37yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [496, 4] <- glm.du.9.ew.37yo$coefficients [[2]]
table.glm.summary [496, 5] <- summary(glm.du.9.ew.37yo)$coefficients [2,4]
rm (glm.du.9.ew.37yo)
gc ()

glm.du.9.ew.38yo <- glm (pttype ~ distance_to_cut_38yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [497, 4] <- glm.du.9.ew.38yo$coefficients [[2]]
table.glm.summary [497, 5] <- summary(glm.du.9.ew.38yo)$coefficients [2,4]
rm (glm.du.9.ew.38yo)
gc ()

glm.du.9.ew.39yo <- glm (pttype ~ distance_to_cut_39yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [498, 4] <- glm.du.9.ew.39yo$coefficients [[2]]
table.glm.summary [498, 5] <- summary(glm.du.9.ew.39yo)$coefficients [2,4]
rm (glm.du.9.ew.39yo)
gc ()

glm.du.9.ew.40yo <- glm (pttype ~ distance_to_cut_40yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [499, 4] <- glm.du.9.ew.40yo$coefficients [[2]]
table.glm.summary [499, 5] <- summary(glm.du.9.ew.40yo)$coefficients [2,4]
rm (glm.du.9.ew.40yo)
gc ()

glm.du.9.ew.41yo <- glm (pttype ~ distance_to_cut_41yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [500, 4] <- glm.du.9.ew.41yo$coefficients [[2]]
table.glm.summary [500, 5] <- summary(glm.du.9.ew.41yo)$coefficients [2,4]
rm (glm.du.9.ew.41yo)
gc ()

glm.du.9.ew.42yo <- glm (pttype ~ distance_to_cut_42yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [501, 4] <- glm.du.9.ew.42yo$coefficients [[2]]
table.glm.summary [501, 5] <- summary(glm.du.9.ew.42yo)$coefficients [2,4]
rm (glm.du.9.ew.42yo)
gc ()

glm.du.9.ew.43yo <- glm (pttype ~ distance_to_cut_43yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [502, 4] <- glm.du.9.ew.43yo$coefficients [[2]]
table.glm.summary [502, 5] <- summary(glm.du.9.ew.43yo)$coefficients [2,4]
rm (glm.du.9.ew.43yo)
gc ()

glm.du.9.ew.44yo <- glm (pttype ~ distance_to_cut_44yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [503, 4] <- glm.du.9.ew.44yo$coefficients [[2]]
table.glm.summary [503, 5] <- summary(glm.du.9.ew.44yo)$coefficients [2,4]
rm (glm.du.9.ew.44yo)
gc ()

glm.du.9.ew.45yo <- glm (pttype ~ distance_to_cut_45yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [504, 4] <- glm.du.9.ew.45yo$coefficients [[2]]
table.glm.summary [504, 5] <- summary(glm.du.9.ew.45yo)$coefficients [2,4]
rm (glm.du.9.ew.45yo)
gc ()

glm.du.9.ew.46yo <- glm (pttype ~ distance_to_cut_46yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [505, 4] <- glm.du.9.ew.46yo$coefficients [[2]]
table.glm.summary [505, 5] <- summary(glm.du.9.ew.46yo)$coefficients [2,4]
rm (glm.du.9.ew.46yo)
gc ()

glm.du.9.ew.47yo <- glm (pttype ~ distance_to_cut_47yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [506, 4] <- glm.du.9.ew.47yo$coefficients [[2]]
table.glm.summary [506, 5] <- summary(glm.du.9.ew.47yo)$coefficients [2,4]
rm (glm.du.9.ew.47yo)
gc ()

glm.du.9.ew.48yo <- glm (pttype ~ distance_to_cut_48yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [507, 4] <- glm.du.9.ew.48yo$coefficients [[2]]
table.glm.summary [507, 5] <- summary(glm.du.9.ew.48yo)$coefficients [2,4]
rm (glm.du.9.ew.48yo)
gc ()

glm.du.9.ew.49yo <- glm (pttype ~ distance_to_cut_49yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [508, 4] <- glm.du.9.ew.49yo$coefficients [[2]]
table.glm.summary [508, 5] <- summary(glm.du.9.ew.49yo)$coefficients [2,4]
rm (glm.du.9.ew.49yo)
gc ()

glm.du.9.ew.50yo <- glm (pttype ~ distance_to_cut_50yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [509, 4] <- glm.du.9.ew.50yo$coefficients [[2]]
table.glm.summary [509, 5] <- summary(glm.du.9.ew.50yo)$coefficients [2,4]
rm (glm.du.9.ew.50yo)
gc ()

glm.du.9.ew.51yo <- glm (pttype ~ distance_to_cut_pre50yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [510, 4] <- glm.du.9.ew.51yo$coefficients [[2]]
table.glm.summary [510, 5] <- summary(glm.du.9.ew.51yo)$coefficients [2,4]
rm (glm.du.9.ew.51yo)
gc ()

## Late Winter ##
glm.du.9.lw.1yo <- glm (pttype ~ distance_to_cut_1yo, 
                        data = dist.cut.data.du.9.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [511, 4] <- glm.du.9.lw.1yo$coefficients [[2]]
table.glm.summary [511, 5] <- summary(glm.du.9.lw.1yo)$coefficients[2,4] # p-value
rm (glm.du.9.lw.1yo)
gc ()

glm.du.9.lw.2yo <- glm (pttype ~ distance_to_cut_2yo, 
                        data = dist.cut.data.du.9.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [512, 4] <- glm.du.9.lw.2yo$coefficients [[2]]
table.glm.summary [512, 5] <- summary(glm.du.9.lw.2yo)$coefficients[2,4]
rm (glm.du.9.lw.2yo)
gc ()

glm.du.9.lw.3yo <- glm (pttype ~ distance_to_cut_3yo, 
                        data = dist.cut.data.du.9.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [513, 4] <- glm.du.9.lw.3yo$coefficients [[2]]
table.glm.summary [513, 5] <- summary(glm.du.9.lw.3yo)$coefficients[2,4]
rm (glm.du.9.lw.3yo)
gc ()

glm.du.9.lw.4yo <- glm (pttype ~ distance_to_cut_4yo, 
                        data = dist.cut.data.du.9.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [514, 4] <- glm.du.9.lw.4yo$coefficients [[2]]
table.glm.summary [514, 5] <- summary(glm.du.9.lw.4yo)$coefficients [2,4]
rm (glm.du.9.lw.4yo)
gc ()

glm.du.9.lw.5yo <- glm (pttype ~ distance_to_cut_5yo, 
                        data = dist.cut.data.du.9.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [515, 4] <- glm.du.9.lw.5yo$coefficients [[2]]
table.glm.summary [515, 5] <- summary(glm.du.9.lw.5yo)$coefficients [2,4]
rm (glm.du.9.lw.5yo)
gc ()

glm.du.9.lw.6yo <- glm (pttype ~ distance_to_cut_6yo, 
                        data = dist.cut.data.du.9.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [516, 4] <- glm.du.9.lw.6yo$coefficients [[2]]
table.glm.summary [516, 5] <- summary(glm.du.9.lw.6yo)$coefficients [2,4]
rm (glm.du.9.lw.6yo)
gc ()

glm.du.9.lw.7yo <- glm (pttype ~ distance_to_cut_7yo, 
                        data = dist.cut.data.du.9.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [517, 4] <- glm.du.9.lw.7yo$coefficients [[2]]
table.glm.summary [517, 5] <- summary(glm.du.9.lw.7yo)$coefficients [2,4]
rm (glm.du.9.lw.7yo)
gc ()

glm.du.9.lw.8yo <- glm (pttype ~ distance_to_cut_8yo, 
                        data = dist.cut.data.du.9.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [518, 4] <- glm.du.9.lw.8yo$coefficients [[2]]
table.glm.summary [518, 5] <- summary(glm.du.9.lw.8yo)$coefficients [2,4]
rm (glm.du.9.lw.8yo)
gc ()

glm.du.9.lw.9yo <- glm (pttype ~ distance_to_cut_9yo, 
                        data = dist.cut.data.du.9.lw,
                        family = binomial (link = 'logit'))
table.glm.summary [519, 4] <- glm.du.9.lw.9yo$coefficients [[2]]
table.glm.summary [519, 5] <- summary(glm.du.9.lw.9yo)$coefficients [2,4]
rm (glm.du.9.lw.9yo)
gc ()

glm.du.9.lw.10yo <- glm (pttype ~ distance_to_cut_10yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [520, 4] <- glm.du.9.lw.10yo$coefficients [[2]]
table.glm.summary [520, 5] <- summary(glm.du.9.lw.10yo)$coefficients [2,4]
rm (glm.du.9.lw.10yo)
gc ()

glm.du.9.lw.11yo <- glm (pttype ~ distance_to_cut_11yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [521, 4] <- glm.du.9.lw.11yo$coefficients [[2]]
table.glm.summary [521, 5] <- summary(glm.du.9.lw.11yo)$coefficients [2,4]
rm (glm.du.9.lw.11yo)
gc ()

glm.du.9.lw.12yo <- glm (pttype ~ distance_to_cut_12yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [522, 4] <- glm.du.9.lw.12yo$coefficients [[2]]
table.glm.summary [522, 5] <- summary(glm.du.9.lw.12yo)$coefficients [2,4]
rm (glm.du.9.lw.12yo)
gc ()

glm.du.9.lw.13yo <- glm (pttype ~ distance_to_cut_13yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [523, 4] <- glm.du.9.lw.13yo$coefficients [[2]]
table.glm.summary [523, 5] <- summary(glm.du.9.lw.13yo)$coefficients [2,4]
rm (glm.du.9.lw.13yo)
gc ()

glm.du.9.lw.14yo <- glm (pttype ~ distance_to_cut_14yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [524, 4] <- glm.du.9.lw.14yo$coefficients [[2]]
table.glm.summary [524, 5] <- summary(glm.du.9.lw.14yo)$coefficients [2,4]
rm (glm.du.9.lw.14yo)
gc ()

glm.du.9.lw.15yo <- glm (pttype ~ distance_to_cut_15yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [525, 4] <- glm.du.9.lw.15yo$coefficients [[2]]
table.glm.summary [525, 5] <- summary(glm.du.9.lw.15yo)$coefficients [2,4]
rm (glm.du.9.lw.15yo)
gc ()

glm.du.9.lw.16yo <- glm (pttype ~ distance_to_cut_16yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [526, 4] <- glm.du.9.lw.16yo$coefficients [[2]]
table.glm.summary [526, 5] <- summary(glm.du.9.lw.16yo)$coefficients [2,4]
rm (glm.du.9.lw.16yo)
gc ()

glm.du.9.lw.17yo <- glm (pttype ~ distance_to_cut_17yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [527, 4] <- glm.du.9.lw.17yo$coefficients [[2]]
table.glm.summary [527, 5] <- summary(glm.du.9.lw.17yo)$coefficients [2,4]
rm (glm.du.9.lw.17yo)
gc ()

glm.du.9.lw.18yo <- glm (pttype ~ distance_to_cut_18yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [528, 4] <- glm.du.9.lw.18yo$coefficients [[2]]
table.glm.summary [528, 5] <- summary(glm.du.9.lw.18yo)$coefficients [2,4]
rm (glm.du.9.lw.18yo)
gc ()

glm.du.9.lw.19yo <- glm (pttype ~ distance_to_cut_19yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [529, 4] <- glm.du.9.lw.19yo$coefficients [[2]]
table.glm.summary [529, 5] <- summary(glm.du.9.lw.19yo)$coefficients [2,4]
rm (glm.du.9.lw.19yo)
gc ()

glm.du.9.lw.20yo <- glm (pttype ~ distance_to_cut_20yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [530, 4] <- glm.du.9.lw.20yo$coefficients [[2]]
table.glm.summary [530, 5] <- summary(glm.du.9.lw.20yo)$coefficients [2,4]
rm (glm.du.9.lw.20yo)
gc ()

glm.du.9.lw.21yo <- glm (pttype ~ distance_to_cut_21yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [531, 4] <- glm.du.9.lw.21yo$coefficients [[2]]
table.glm.summary [531, 5] <- summary(glm.du.9.lw.21yo)$coefficients [2,4]
rm (glm.du.9.lw.21yo)
gc ()

glm.du.9.lw.22yo <- glm (pttype ~ distance_to_cut_22yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [532, 4] <- glm.du.9.lw.22yo$coefficients [[2]]
table.glm.summary [532, 5] <- summary(glm.du.9.lw.22yo)$coefficients [2,4]
rm (glm.du.9.lw.22yo)
gc ()

glm.du.9.lw.23yo <- glm (pttype ~ distance_to_cut_23yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [533, 4] <- glm.du.9.lw.23yo$coefficients [[2]]
table.glm.summary [533, 5] <- summary(glm.du.9.lw.23yo)$coefficients [2,4]
rm (glm.du.9.lw.23yo)
gc ()

glm.du.9.lw.24yo <- glm (pttype ~ distance_to_cut_24yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [534, 4] <- glm.du.9.lw.24yo$coefficients [[2]]
table.glm.summary [534, 5] <- summary(glm.du.9.lw.24yo)$coefficients [2,4]
rm (glm.du.9.lw.24yo)
gc ()

glm.du.9.lw.25yo <- glm (pttype ~ distance_to_cut_25yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [535, 4] <- glm.du.9.lw.25yo$coefficients [[2]]
table.glm.summary [535, 5] <- summary(glm.du.9.lw.25yo)$coefficients [2,4]
rm (glm.du.9.lw.25yo)
gc ()

glm.du.9.lw.26yo <- glm (pttype ~ distance_to_cut_26yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [536, 4] <- glm.du.9.lw.26yo$coefficients [[2]]
table.glm.summary [536, 5] <- summary(glm.du.9.lw.26yo)$coefficients [2,4]
rm (glm.du.9.lw.26yo)
gc ()

glm.du.9.lw.27yo <- glm (pttype ~ distance_to_cut_27yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [537, 4] <- glm.du.9.lw.27yo$coefficients [[2]]
table.glm.summary [537, 5] <- summary(glm.du.9.lw.27yo)$coefficients [2,4]
rm (glm.du.9.lw.27yo)
gc ()

glm.du.9.lw.28yo <- glm (pttype ~ distance_to_cut_28yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [538, 4] <- glm.du.9.lw.28yo$coefficients [[2]]
table.glm.summary [538, 5] <- summary(glm.du.9.lw.28yo)$coefficients [2,4]
rm (glm.du.9.lw.28yo)
gc ()

glm.du.9.lw.29yo <- glm (pttype ~ distance_to_cut_29yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [539, 4] <- glm.du.9.lw.29yo$coefficients [[2]]
table.glm.summary [539, 5] <- summary(glm.du.9.lw.29yo)$coefficients [2,4]
rm (glm.du.9.lw.29yo)
gc ()

glm.du.9.lw.30yo <- glm (pttype ~ distance_to_cut_30yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [540, 4] <- glm.du.9.lw.30yo$coefficients [[2]]
table.glm.summary [540, 5] <- summary(glm.du.9.lw.30yo)$coefficients [2,4]
rm (glm.du.9.lw.30yo)
gc ()

glm.du.9.lw.31yo <- glm (pttype ~ distance_to_cut_31yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [541, 4] <- glm.du.9.lw.31yo$coefficients [[2]]
table.glm.summary [541, 5] <- summary(glm.du.9.lw.31yo)$coefficients [2,4]
rm (glm.du.9.lw.31yo)
gc ()

glm.du.9.lw.32yo <- glm (pttype ~ distance_to_cut_32yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [542, 4] <- glm.du.9.lw.32yo$coefficients [[2]]
table.glm.summary [542, 5] <- summary(glm.du.9.lw.32yo)$coefficients [2,4]
rm (glm.du.9.lw.32yo)
gc ()

glm.du.9.lw.33yo <- glm (pttype ~ distance_to_cut_33yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [543, 4] <- glm.du.9.lw.33yo$coefficients [[2]]
table.glm.summary [543, 5] <- summary(glm.du.9.lw.33yo)$coefficients [2,4]
rm (glm.du.9.lw.33yo)
gc ()

glm.du.9.lw.34yo <- glm (pttype ~ distance_to_cut_34yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [544, 4] <- glm.du.9.lw.34yo$coefficients [[2]]
table.glm.summary [544, 5] <- summary(glm.du.9.lw.34yo)$coefficients [2,4]
rm (glm.du.9.lw.34yo)
gc ()

glm.du.9.lw.35yo <- glm (pttype ~ distance_to_cut_35yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [545, 4] <- glm.du.9.lw.35yo$coefficients [[2]]
table.glm.summary [545, 5] <- summary(glm.du.9.lw.35yo)$coefficients [2,4]
rm (glm.du.9.lw.35yo)
gc ()

glm.du.9.lw.36yo <- glm (pttype ~ distance_to_cut_36yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [546, 4] <- glm.du.9.lw.36yo$coefficients [[2]]
table.glm.summary [546, 5] <- summary(glm.du.9.lw.36yo)$coefficients [2,4]
rm (glm.du.9.lw.36yo)
gc ()

glm.du.9.lw.37yo <- glm (pttype ~ distance_to_cut_37yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [547, 4] <- glm.du.9.lw.37yo$coefficients [[2]]
table.glm.summary [547, 5] <- summary(glm.du.9.lw.37yo)$coefficients [2,4]
rm (glm.du.9.lw.37yo)
gc ()

glm.du.9.lw.38yo <- glm (pttype ~ distance_to_cut_38yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [548, 4] <- glm.du.9.lw.38yo$coefficients [[2]]
table.glm.summary [548, 5] <- summary(glm.du.9.lw.38yo)$coefficients [2,4]
rm (glm.du.9.lw.38yo)
gc ()

glm.du.9.lw.39yo <- glm (pttype ~ distance_to_cut_39yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [549, 4] <- glm.du.9.lw.39yo$coefficients [[2]]
table.glm.summary [549, 5] <- summary(glm.du.9.lw.39yo)$coefficients [2,4]
rm (glm.du.9.lw.39yo)
gc ()

glm.du.9.lw.40yo <- glm (pttype ~ distance_to_cut_40yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [550, 4] <- glm.du.9.lw.40yo$coefficients [[2]]
table.glm.summary [550, 5] <- summary(glm.du.9.lw.40yo)$coefficients [2,4]
rm (glm.du.9.lw.40yo)
gc ()

glm.du.9.lw.41yo <- glm (pttype ~ distance_to_cut_41yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [551, 4] <- glm.du.9.lw.41yo$coefficients [[2]]
table.glm.summary [551, 5] <- summary(glm.du.9.lw.41yo)$coefficients [2,4]
rm (glm.du.9.lw.41yo)
gc ()

glm.du.9.lw.42yo <- glm (pttype ~ distance_to_cut_42yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [552, 4] <- glm.du.9.lw.42yo$coefficients [[2]]
table.glm.summary [552, 5] <- summary(glm.du.9.lw.42yo)$coefficients [2,4]
rm (glm.du.9.lw.42yo)
gc ()

glm.du.9.lw.43yo <- glm (pttype ~ distance_to_cut_43yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [553, 4] <- glm.du.9.lw.43yo$coefficients [[2]]
table.glm.summary [553, 5] <- summary(glm.du.9.lw.43yo)$coefficients [2,4]
rm (glm.du.9.lw.43yo)
gc ()

glm.du.9.lw.44yo <- glm (pttype ~ distance_to_cut_44yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [554, 4] <- glm.du.9.lw.44yo$coefficients [[2]]
table.glm.summary [554, 5] <- summary(glm.du.9.lw.44yo)$coefficients [2,4]
rm (glm.du.9.lw.44yo)
gc ()

glm.du.9.lw.45yo <- glm (pttype ~ distance_to_cut_45yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [555, 4] <- glm.du.9.lw.45yo$coefficients [[2]]
table.glm.summary [555, 5] <- summary(glm.du.9.lw.45yo)$coefficients [2,4]
rm (glm.du.9.lw.45yo)
gc ()

glm.du.9.lw.46yo <- glm (pttype ~ distance_to_cut_46yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [556, 4] <- glm.du.9.lw.46yo$coefficients [[2]]
table.glm.summary [556, 5] <- summary(glm.du.9.lw.46yo)$coefficients [2,4]
rm (glm.du.9.lw.46yo)
gc ()

glm.du.9.lw.47yo <- glm (pttype ~ distance_to_cut_47yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [557, 4] <- glm.du.9.lw.47yo$coefficients [[2]]
table.glm.summary [557, 5] <- summary(glm.du.9.lw.47yo)$coefficients [2,4]
rm (glm.du.9.lw.47yo)
gc ()

glm.du.9.lw.48yo <- glm (pttype ~ distance_to_cut_48yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [558, 4] <- glm.du.9.lw.48yo$coefficients [[2]]
table.glm.summary [558, 5] <- summary(glm.du.9.lw.48yo)$coefficients [2,4]
rm (glm.du.9.lw.48yo)
gc ()

glm.du.9.lw.49yo <- glm (pttype ~ distance_to_cut_49yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [559, 4] <- glm.du.9.lw.49yo$coefficients [[2]]
table.glm.summary [559, 5] <- summary(glm.du.9.lw.49yo)$coefficients [2,4]
rm (glm.du.9.lw.49yo)
gc ()

glm.du.9.lw.50yo <- glm (pttype ~ distance_to_cut_50yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [560, 4] <- glm.du.9.lw.50yo$coefficients [[2]]
table.glm.summary [560, 5] <- summary(glm.du.9.lw.50yo)$coefficients [2,4]
rm (glm.du.9.lw.50yo)
gc ()

glm.du.9.lw.51yo <- glm (pttype ~ distance_to_cut_pre50yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [561, 4] <- glm.du.9.lw.51yo$coefficients [[2]]
table.glm.summary [561, 5] <- summary(glm.du.9.lw.51yo)$coefficients [2,4]
rm (glm.du.9.lw.51yo)
gc ()

## Summer ##
glm.du.9.s.1yo <- glm (pttype ~ distance_to_cut_1yo, 
                       data = dist.cut.data.du.9.s,
                       family = binomial (link = 'logit'))
table.glm.summary [562, 4] <- glm.du.9.s.1yo$coefficients [[2]]
table.glm.summary [562, 5] <- summary(glm.du.9.s.1yo)$coefficients[2,4] # p-value
rm (glm.du.9.s.1yo)
gc ()

glm.du.9.s.2yo <- glm (pttype ~ distance_to_cut_2yo, 
                       data = dist.cut.data.du.9.s,
                       family = binomial (link = 'logit'))
table.glm.summary [563, 4] <- glm.du.9.s.2yo$coefficients [[2]]
table.glm.summary [563, 5] <- summary(glm.du.9.s.2yo)$coefficients[2,4]
rm (glm.du.9.s.2yo)
gc ()

glm.du.9.s.3yo <- glm (pttype ~ distance_to_cut_3yo, 
                       data = dist.cut.data.du.9.s,
                       family = binomial (link = 'logit'))
table.glm.summary [564, 4] <- glm.du.9.s.3yo$coefficients [[2]]
table.glm.summary [564, 5] <- summary(glm.du.9.s.3yo)$coefficients[2,4]
rm (glm.du.9.s.3yo)
gc ()

glm.du.9.s.4yo <- glm (pttype ~ distance_to_cut_4yo, 
                       data = dist.cut.data.du.9.s,
                       family = binomial (link = 'logit'))
table.glm.summary [565, 4] <- glm.du.9.s.4yo$coefficients [[2]]
table.glm.summary [565, 5] <- summary(glm.du.9.s.4yo)$coefficients [2,4]
rm (glm.du.9.s.4yo)
gc ()

glm.du.9.s.5yo <- glm (pttype ~ distance_to_cut_5yo, 
                       data = dist.cut.data.du.9.s,
                       family = binomial (link = 'logit'))
table.glm.summary [566, 4] <- glm.du.9.s.5yo$coefficients [[2]]
table.glm.summary [566, 5] <- summary(glm.du.9.s.5yo)$coefficients [2,4]
rm (glm.du.9.s.5yo)
gc ()

glm.du.9.s.6yo <- glm (pttype ~ distance_to_cut_6yo, 
                       data = dist.cut.data.du.9.s,
                       family = binomial (link = 'logit'))
table.glm.summary [567, 4] <- glm.du.9.s.6yo$coefficients [[2]]
table.glm.summary [567, 5] <- summary(glm.du.9.s.6yo)$coefficients [2,4]
rm (glm.du.9.s.6yo)
gc ()

glm.du.9.s.7yo <- glm (pttype ~ distance_to_cut_7yo, 
                       data = dist.cut.data.du.9.s,
                       family = binomial (link = 'logit'))
table.glm.summary [568, 4] <- glm.du.9.s.7yo$coefficients [[2]]
table.glm.summary [568, 5] <- summary(glm.du.9.s.7yo)$coefficients [2,4]
rm (glm.du.9.s.7yo)
gc ()

glm.du.9.s.8yo <- glm (pttype ~ distance_to_cut_8yo, 
                       data = dist.cut.data.du.9.s,
                       family = binomial (link = 'logit'))
table.glm.summary [569, 4] <- glm.du.9.s.8yo$coefficients [[2]]
table.glm.summary [569, 5] <- summary(glm.du.9.s.8yo)$coefficients [2,4]
rm (glm.du.9.s.8yo)
gc ()

glm.du.9.s.9yo <- glm (pttype ~ distance_to_cut_9yo, 
                       data = dist.cut.data.du.9.s,
                       family = binomial (link = 'logit'))
table.glm.summary [570, 4] <- glm.du.9.s.9yo$coefficients [[2]]
table.glm.summary [570, 5] <- summary(glm.du.9.s.9yo)$coefficients [2,4]
rm (glm.du.9.s.9yo)
gc ()

glm.du.9.s.10yo <- glm (pttype ~ distance_to_cut_10yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [571, 4] <- glm.du.9.s.10yo$coefficients [[2]]
table.glm.summary [571, 5] <- summary(glm.du.9.s.10yo)$coefficients [2,4]
rm (glm.du.9.s.10yo)
gc ()

glm.du.9.s.11yo <- glm (pttype ~ distance_to_cut_11yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [572, 4] <- glm.du.9.s.11yo$coefficients [[2]]
table.glm.summary [572, 5] <- summary(glm.du.9.s.11yo)$coefficients [2,4]
rm (glm.du.9.s.11yo)
gc ()

glm.du.9.s.12yo <- glm (pttype ~ distance_to_cut_12yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [573, 4] <- glm.du.9.s.12yo$coefficients [[2]]
table.glm.summary [573, 5] <- summary(glm.du.9.s.12yo)$coefficients [2,4]
rm (glm.du.9.s.12yo)
gc ()

glm.du.9.s.13yo <- glm (pttype ~ distance_to_cut_13yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [574, 4] <- glm.du.9.s.13yo$coefficients [[2]]
table.glm.summary [574, 5] <- summary(glm.du.9.s.13yo)$coefficients [2,4]
rm (glm.du.9.s.13yo)
gc ()

glm.du.9.s.14yo <- glm (pttype ~ distance_to_cut_14yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [575, 4] <- glm.du.9.s.14yo$coefficients [[2]]
table.glm.summary [575, 5] <- summary(glm.du.9.s.14yo)$coefficients [2,4]
rm (glm.du.9.s.14yo)
gc ()

glm.du.9.s.15yo <- glm (pttype ~ distance_to_cut_15yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [576, 4] <- glm.du.9.s.15yo$coefficients [[2]]
table.glm.summary [576, 5] <- summary(glm.du.9.s.15yo)$coefficients [2,4]
rm (glm.du.9.s.15yo)
gc ()

glm.du.9.s.16yo <- glm (pttype ~ distance_to_cut_16yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [577, 4] <- glm.du.9.s.16yo$coefficients [[2]]
table.glm.summary [577, 5] <- summary(glm.du.9.s.16yo)$coefficients [2,4]
rm (glm.du.9.s.16yo)
gc ()

glm.du.9.s.17yo <- glm (pttype ~ distance_to_cut_17yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [578, 4] <- glm.du.9.s.17yo$coefficients [[2]]
table.glm.summary [578, 5] <- summary(glm.du.9.s.17yo)$coefficients [2,4]
rm (glm.du.9.s.17yo)
gc ()

glm.du.9.s.18yo <- glm (pttype ~ distance_to_cut_18yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [579, 4] <- glm.du.9.s.18yo$coefficients [[2]]
table.glm.summary [579, 5] <- summary(glm.du.9.s.18yo)$coefficients [2,4]
rm (glm.du.9.s.18yo)
gc ()

glm.du.9.s.19yo <- glm (pttype ~ distance_to_cut_19yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [580, 4] <- glm.du.9.s.19yo$coefficients [[2]]
table.glm.summary [580, 5] <- summary(glm.du.9.s.19yo)$coefficients [2,4]
rm (glm.du.9.s.19yo)
gc ()

glm.du.9.s.20yo <- glm (pttype ~ distance_to_cut_20yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [581, 4] <- glm.du.9.s.20yo$coefficients [[2]]
table.glm.summary [581, 5] <- summary(glm.du.9.s.20yo)$coefficients [2,4]
rm (glm.du.9.s.20yo)
gc ()

glm.du.9.s.21yo <- glm (pttype ~ distance_to_cut_21yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [582, 4] <- glm.du.9.s.21yo$coefficients [[2]]
table.glm.summary [582, 5] <- summary(glm.du.9.s.21yo)$coefficients [2,4]
rm (glm.du.9.s.21yo)
gc ()

glm.du.9.s.22yo <- glm (pttype ~ distance_to_cut_22yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [583, 4] <- glm.du.9.s.22yo$coefficients [[2]]
table.glm.summary [583, 5] <- summary(glm.du.9.s.22yo)$coefficients [2,4]
rm (glm.du.9.s.22yo)
gc ()

glm.du.9.s.23yo <- glm (pttype ~ distance_to_cut_23yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [584, 4] <- glm.du.9.s.23yo$coefficients [[2]]
table.glm.summary [584, 5] <- summary(glm.du.9.s.23yo)$coefficients [2,4]
rm (glm.du.9.s.23yo)
gc ()

glm.du.9.s.24yo <- glm (pttype ~ distance_to_cut_24yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [585, 4] <- glm.du.9.s.24yo$coefficients [[2]]
table.glm.summary [585, 5] <- summary(glm.du.9.s.24yo)$coefficients [2,4]
rm (glm.du.9.s.24yo)
gc ()

glm.du.9.s.25yo <- glm (pttype ~ distance_to_cut_25yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [586, 4] <- glm.du.9.s.25yo$coefficients [[2]]
table.glm.summary [586, 5] <- summary(glm.du.9.s.25yo)$coefficients [2,4]
rm (glm.du.9.s.25yo)
gc ()

glm.du.9.s.26yo <- glm (pttype ~ distance_to_cut_26yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [587, 4] <- glm.du.9.s.26yo$coefficients [[2]]
table.glm.summary [587, 5] <- summary(glm.du.9.s.26yo)$coefficients [2,4]
rm (glm.du.9.s.26yo)
gc ()

glm.du.9.s.27yo <- glm (pttype ~ distance_to_cut_27yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [588, 4] <- glm.du.9.s.27yo$coefficients [[2]]
table.glm.summary [588, 5] <- summary(glm.du.9.s.27yo)$coefficients [2,4]
rm (glm.du.9.s.27yo)
gc ()

glm.du.9.s.28yo <- glm (pttype ~ distance_to_cut_28yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [589, 4] <- glm.du.9.s.28yo$coefficients [[2]]
table.glm.summary [589, 5] <- summary(glm.du.9.s.28yo)$coefficients [2,4]
rm (glm.du.9.s.28yo)
gc ()

glm.du.9.s.29yo <- glm (pttype ~ distance_to_cut_29yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [590, 4] <- glm.du.9.s.29yo$coefficients [[2]]
table.glm.summary [590, 5] <- summary(glm.du.9.s.29yo)$coefficients [2,4]
rm (glm.du.9.s.29yo)
gc ()

glm.du.9.s.30yo <- glm (pttype ~ distance_to_cut_30yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [591, 4] <- glm.du.9.s.30yo$coefficients [[2]]
table.glm.summary [591, 5] <- summary(glm.du.9.s.30yo)$coefficients [2,4]
rm (glm.du.9.s.30yo)
gc ()

glm.du.9.s.31yo <- glm (pttype ~ distance_to_cut_31yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [592, 4] <- glm.du.9.s.31yo$coefficients [[2]]
table.glm.summary [592, 5] <- summary(glm.du.9.s.31yo)$coefficients [2,4]
rm (glm.du.9.s.31yo)
gc ()

glm.du.9.s.32yo <- glm (pttype ~ distance_to_cut_32yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [593, 4] <- glm.du.9.s.32yo$coefficients [[2]]
table.glm.summary [593, 5] <- summary(glm.du.9.s.32yo)$coefficients [2,4]
rm (glm.du.9.s.32yo)
gc ()

glm.du.9.s.33yo <- glm (pttype ~ distance_to_cut_33yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [594, 4] <- glm.du.9.s.33yo$coefficients [[2]]
table.glm.summary [594, 5] <- summary(glm.du.9.s.33yo)$coefficients [2,4]
rm (glm.du.9.s.33yo)
gc ()

glm.du.9.s.34yo <- glm (pttype ~ distance_to_cut_34yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [595, 4] <- glm.du.9.s.34yo$coefficients [[2]]
table.glm.summary [595, 5] <- summary(glm.du.9.s.34yo)$coefficients [2,4]
rm (glm.du.9.s.34yo)
gc ()

glm.du.9.s.35yo <- glm (pttype ~ distance_to_cut_35yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [596, 4] <- glm.du.9.s.35yo$coefficients [[2]]
table.glm.summary [596, 5] <- summary(glm.du.9.s.35yo)$coefficients [2,4]
rm (glm.du.9.s.35yo)
gc ()

glm.du.9.s.36yo <- glm (pttype ~ distance_to_cut_36yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [597, 4] <- glm.du.9.s.36yo$coefficients [[2]]
table.glm.summary [597, 5] <- summary(glm.du.9.s.36yo)$coefficients [2,4]
rm (glm.du.9.s.36yo)
gc ()

glm.du.9.s.37yo <- glm (pttype ~ distance_to_cut_37yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [598, 4] <- glm.du.9.s.37yo$coefficients [[2]]
table.glm.summary [598, 5] <- summary(glm.du.9.s.37yo)$coefficients [2,4]
rm (glm.du.9.s.37yo)
gc ()

glm.du.9.s.38yo <- glm (pttype ~ distance_to_cut_38yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [599, 4] <- glm.du.9.s.38yo$coefficients [[2]]
table.glm.summary [599, 5] <- summary(glm.du.9.s.38yo)$coefficients [2,4]
rm (glm.du.9.s.38yo)
gc ()

glm.du.9.s.39yo <- glm (pttype ~ distance_to_cut_39yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [600, 4] <- glm.du.9.s.39yo$coefficients [[2]]
table.glm.summary [600, 5] <- summary(glm.du.9.s.39yo)$coefficients [2,4]
rm (glm.du.9.s.39yo)
gc ()

glm.du.9.s.40yo <- glm (pttype ~ distance_to_cut_40yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [601, 4] <- glm.du.9.s.40yo$coefficients [[2]]
table.glm.summary [601, 5] <- summary(glm.du.9.s.40yo)$coefficients [2,4]
rm (glm.du.9.s.40yo)
gc ()

glm.du.9.s.41yo <- glm (pttype ~ distance_to_cut_41yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [602, 4] <- glm.du.9.s.41yo$coefficients [[2]]
table.glm.summary [602, 5] <- summary(glm.du.9.s.41yo)$coefficients [2,4]
rm (glm.du.9.s.41yo)
gc ()

glm.du.9.s.42yo <- glm (pttype ~ distance_to_cut_42yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [603, 4] <- glm.du.9.s.42yo$coefficients [[2]]
table.glm.summary [603, 5] <- summary(glm.du.9.s.42yo)$coefficients [2,4]
rm (glm.du.9.s.42yo)
gc ()

glm.du.9.s.43yo <- glm (pttype ~ distance_to_cut_43yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [604, 4] <- glm.du.9.s.43yo$coefficients [[2]]
table.glm.summary [604, 5] <- summary(glm.du.9.s.43yo)$coefficients [2,4]
rm (glm.du.9.s.43yo)
gc ()

glm.du.9.s.44yo <- glm (pttype ~ distance_to_cut_44yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [605, 4] <- glm.du.9.s.44yo$coefficients [[2]]
table.glm.summary [605, 5] <- summary(glm.du.9.s.44yo)$coefficients [2,4]
rm (glm.du.9.s.44yo)
gc ()

glm.du.9.s.45yo <- glm (pttype ~ distance_to_cut_45yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [606, 4] <- glm.du.9.s.45yo$coefficients [[2]]
table.glm.summary [606, 5] <- summary(glm.du.9.s.45yo)$coefficients [2,4]
rm (glm.du.9.s.45yo)
gc ()

glm.du.9.s.46yo <- glm (pttype ~ distance_to_cut_46yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [607, 4] <- glm.du.9.s.46yo$coefficients [[2]]
table.glm.summary [607, 5] <- summary(glm.du.9.s.46yo)$coefficients [2,4]
rm (glm.du.9.s.46yo)
gc ()

glm.du.9.s.47yo <- glm (pttype ~ distance_to_cut_47yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [608, 4] <- glm.du.9.s.47yo$coefficients [[2]]
table.glm.summary [608, 5] <- summary(glm.du.9.s.47yo)$coefficients [2,4]
rm (glm.du.9.s.47yo)
gc ()

glm.du.9.s.48yo <- glm (pttype ~ distance_to_cut_48yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [609, 4] <- glm.du.9.s.48yo$coefficients [[2]]
table.glm.summary [609, 5] <- summary(glm.du.9.s.48yo)$coefficients [2,4]
rm (glm.du.9.s.48yo)
gc ()

glm.du.9.s.49yo <- glm (pttype ~ distance_to_cut_49yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [610, 4] <- glm.du.9.s.49yo$coefficients [[2]]
table.glm.summary [610, 5] <- summary(glm.du.9.s.49yo)$coefficients [2,4]
rm (glm.du.9.s.49yo)
gc ()

glm.du.9.s.50yo <- glm (pttype ~ distance_to_cut_50yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [611, 4] <- glm.du.9.s.50yo$coefficients [[2]]
table.glm.summary [611, 5] <- summary(glm.du.9.s.50yo)$coefficients [2,4]
rm (glm.du.9.s.50yo)
gc ()

glm.du.9.s.51yo <- glm (pttype ~ distance_to_cut_pre50yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [612, 4] <- glm.du.9.s.51yo$coefficients [[2]]
table.glm.summary [612, 5] <- summary(glm.du.9.s.51yo)$coefficients [2,4]
rm (glm.du.9.s.51yo)
gc ()

# save table
table.glm.summary$coefficent.km <- table.glm.summary$Coefficient * 1000 # divide coeffs by 1,000 to make easier to read table
table.glm.summary$years <- as.character (table.glm.summary$Years.Old)
table.glm.summary [c (51, 102, 153, 204, 255, 306, 357, 408, 459, 510, 561, 612), 7] <- 51
table.glm.summary$years <- as.numeric (table.glm.summary$years)
write.table (table.glm.summary, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_glm_summary_forestry.csv", sep = ",")

table.glm.summary <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_glm_summary_forestry.csv")
table.glm.summary$DU <- as.factor (table.glm.summary$DU )

# plot of coefficents
ggplot (data = table.glm.summary, 
        aes (years, coefficent.km)) +
  geom_line (aes (group = interaction (DU, Season),
                  colour = DU,
                  linetype = Season)) +
  ggtitle ("Beta coefficient values of distance to cutblock \n by year, season and caribou designatable unit (DU).") +
  xlab ("Years since harvest") + 
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
  scale_y_continuous (limits = c (-0.055, 0.055), breaks = seq (-0.055, 0.055, by = 0.01))



table.glm.summary.du6 <- table.glm.summary %>%
  filter (DU == 6)
ggplot (data = table.glm.summary.du6, 
        aes (years, coefficent.km)) +
  geom_line (aes (colour = Season)) +
  ggtitle ("Beta coefficient values of distance to cutblock \n by year and season for caribou designatable unit (DU) 6.") +
  xlab ("Years since harvest") + 
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
  scale_y_continuous (limits = c (-0.005, 0.005), breaks = seq (-0.005, 0.005, by = 0.001))


table.glm.summary.du7 <- table.glm.summary %>%
  filter (DU == 7)
ggplot (data = table.glm.summary.du7, 
        aes (years, coefficent.km)) +
  geom_line (aes (colour = Season)) +
  ggtitle ("Beta coefficient values of distance to cutblock \n by year and season for caribou designatable unit (DU) 7.") +
  xlab ("Years since harvest") + 
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
  scale_y_continuous (limits = c (-0.012, 0.012), breaks = seq (-0.012, 0.012, by = 0.003))


table.glm.summary.du8 <- table.glm.summary %>%
  filter (DU == 8)
ggplot (data = table.glm.summary.du8, 
        aes (years, coefficent.km)) +
  geom_line (aes (colour = Season)) +
  ggtitle ("Beta coefficient values of distance to cutblock \n by year and season for caribou designatable unit (DU) 8.") +
  xlab ("Years since harvest") + 
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
  scale_y_continuous (limits = c (-0.025, 0.025), breaks = seq (-0.025, 0.025, by = 0.005))


table.glm.summary.du9 <- table.glm.summary %>%
  filter (DU == 9)
ggplot (data = table.glm.summary.du9, 
        aes (years, coefficent.km)) +
  geom_line (aes (colour = Season)) +
  ggtitle ("Beta coefficient values of distance to cutblock \n by year and season for caribou designatable unit (DU) 9.") +
  xlab ("Years since harvest") + 
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
  scale_y_continuous (limits = c (-0.025, 0.055), breaks = seq (-0.025, 0.055, by = 0.01))

#=======================================================================
# re-categorize forestry data and test correlations, beta coeffs again
#=====================================================================
rsf.data.cut.age <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_cutblock_age.csv")
rsf.data.cut.age <- dplyr::mutate (rsf.data.cut.age, distance_to_cut_1to4yo = pmin (distance_to_cut_1yo, distance_to_cut_2yo, distance_to_cut_3yo, distance_to_cut_4yo))
rsf.data.cut.age <- dplyr::mutate (rsf.data.cut.age, distance_to_cut_5to9yo = pmin (distance_to_cut_5yo, distance_to_cut_6yo, distance_to_cut_7yo, distance_to_cut_8yo, distance_to_cut_9yo))
rsf.data.cut.age <- dplyr::mutate (rsf.data.cut.age, distance_to_cut_10to29yo = pmin (distance_to_cut_10yo, distance_to_cut_11yo, distance_to_cut_12yo, distance_to_cut_13yo, distance_to_cut_14yo, distance_to_cut_15yo,distance_to_cut_16yo, distance_to_cut_17yo, distance_to_cut_18yo, distance_to_cut_19yo, distance_to_cut_20yo, distance_to_cut_21yo, distance_to_cut_22yo, distance_to_cut_23yo, distance_to_cut_24yo, distance_to_cut_25yo, distance_to_cut_26yo, distance_to_cut_27yo, distance_to_cut_28yo, distance_to_cut_29yo))
rsf.data.cut.age <- dplyr::mutate (rsf.data.cut.age, distance_to_cut_30orOveryo = pmin (distance_to_cut_30yo, distance_to_cut_31yo, distance_to_cut_32yo, distance_to_cut_33yo, distance_to_cut_34yo, distance_to_cut_35yo, distance_to_cut_36yo, distance_to_cut_37yo, distance_to_cut_38yo, distance_to_cut_39yo, distance_to_cut_40yo, distance_to_cut_41yo, distance_to_cut_42yo, distance_to_cut_43yo, distance_to_cut_44yo, distance_to_cut_45yo, distance_to_cut_46yo, distance_to_cut_47yo, distance_to_cut_48yo, distance_to_cut_49yo, distance_to_cut_50yo, distance_to_cut_pre50yo))
rsf.data.cut.age <- dplyr::mutate (rsf.data.cut.age, cut_1to4yo = cut_1yo + cut_2yo + cut_3yo + cut_4yo)
rsf.data.cut.age$cut_1to4yo [rsf.data.cut.age$cut_1to4yo > 0] <- 1
rsf.data.cut.age <- dplyr::mutate (rsf.data.cut.age, cut_5to9yo = cut_5yo + cut_6yo + cut_7yo + cut_8yo + cut_9yo)
rsf.data.cut.age$cut_5to9yo [rsf.data.cut.age$cut_5to9yo > 0] <- 1
rsf.data.cut.age <- dplyr::mutate (rsf.data.cut.age, cut_10to29yo = cut_10yo + cut_11yo + cut_12yo + cut_13yo + cut_14yo + cut_15yo,cut_16yo + cut_17yo + cut_18yo + cut_19yo + cut_20yo + cut_21yo + cut_22yo + cut_23yo + cut_24yo + cut_25yo + cut_26yo + cut_27yo + cut_28yo + cut_29yo)
rsf.data.cut.age$cut_10to29yo [rsf.data.cut.age$cut_10to29yo > 0] <- 1
rsf.data.cut.age <- dplyr::mutate (rsf.data.cut.age, cut_30orOveryo = cut_30yo + cut_31yo + cut_32yo + cut_33yo + cut_34yo + cut_35yo + cut_36yo + cut_37yo + cut_38yo + cut_39yo + cut_40yo + cut_41yo + cut_42yo + cut_43yo + cut_44yo + cut_45yo + cut_46yo + cut_47yo + cut_48yo + cut_49yo + cut_50yo + cut_pre50yo)
rsf.data.cut.age$cut_30orOveryo [rsf.data.cut.age$cut_30orOveryo > 0] <- 1

# write.table (rsf.data.cut.age, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_cutblock_age.csv", sep = ",")

# Correlations
dist.cut.corr <- rsf.data.cut.age [c (112:115)]
corr <- round (cor (dist.cut.corr), 3)
p.mat <- round (cor_pmat (dist.cut.corr), 2)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Distance to Cutblock Correlation")
# ggcorrplot (corr, type = "lower", p.mat = p.mat, insig = "blank")

#########
## DU6 ## 
#########
dist.cut.corr.du.6 <- rsf.data.cut.age %>%
  dplyr::filter (du == "du6")
dist.cut.corr.du.6 <- dist.cut.corr.du.6 [c (112:115)]
corr.du6 <- round (cor (dist.cut.corr.du.6), 3)
p.mat <- round (cor_pmat (corr.du6), 2)
ggcorrplot (corr.du6, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU6 Distance to Cutblock Correlation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_dist_cut_corr_class_du6.png")

########
## DU7 ## 
#########
dist.cut.corr.du.7 <- rsf.data.cut.age %>%
  dplyr::filter (du == "du7")
dist.cut.corr.du.7 <- dist.cut.corr.du.7 [c (112:115)]
corr.du7 <- round (cor (dist.cut.corr.du.7), 3)
p.mat <- round (cor_pmat (corr.du7), 2)
ggcorrplot (corr.du7, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU7 Distance to Cutblock Correlation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_dist_cut_corr_class_du7.png")

#########
## DU8 ## 
#########
dist.cut.corr.du.8 <- rsf.data.cut.age %>%
  dplyr::filter (du == "du8")
dist.cut.corr.du.8 <- dist.cut.corr.du.8 [c (112:115)]
corr.du8 <- round (cor (dist.cut.corr.du.8), 3)
p.mat <- round (cor_pmat (corr.du8), 2)
ggcorrplot (corr.du8, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU8 Distance to Cutblock Correlation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_dist_cut_corr_class_du8.png")

#########
## DU9 ## 
#########
dist.cut.corr.du.9 <- rsf.data.cut.age %>%
  dplyr::filter (du == "du9")
dist.cut.corr.du.9 <- dist.cut.corr.du.9 [c (112:115)]
corr.du9 <- round (cor (dist.cut.corr.du.9), 3)
p.mat <- round (cor_pmat (corr.du9), 2)
ggcorrplot (corr.du9, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU9 Distance to Cutblock Correlation")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_dist_cut_corr_class_du9.png")

#================================
# GLMs with new age categories
#================================
dist.cut.data <- rsf.data.cut.age [c (1, 3:4, 112:119)] # cutblock data only

# filter data by DU and season
dist.cut.data.du.6.ew <- dist.cut.data %>%
  dplyr::filter (du == "du6") %>% 
  dplyr::filter (season == "EarlyWinter")
dist.cut.data.du.6.lw <- dist.cut.data %>%
  dplyr::filter (du == "du6") %>% 
  dplyr::filter (season == "LateWinter")
dist.cut.data.du.6.s <- dist.cut.data %>%
  dplyr::filter (du == "du6") %>% 
  dplyr::filter (season == "Summer")

dist.cut.data.du.7.ew <- dist.cut.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "EarlyWinter")
dist.cut.data.du.7.lw <- dist.cut.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "LateWinter")
dist.cut.data.du.7.s <- dist.cut.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "Summer")

dist.cut.data.du.8.ew <- dist.cut.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "EarlyWinter")
dist.cut.data.du.8.lw <- dist.cut.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "LateWinter")
dist.cut.data.du.8.s <- dist.cut.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "Summer")

dist.cut.data.du.9.ew <- dist.cut.data %>%
  dplyr::filter (du == "du9") %>% 
  dplyr::filter (season == "EarlyWinter")
dist.cut.data.du.9.lw <- dist.cut.data %>%
  dplyr::filter (du == "du9") %>% 
  dplyr::filter (season == "LateWinter")
dist.cut.data.du.9.s <- dist.cut.data %>%
  dplyr::filter (du == "du9") %>% 
  dplyr::filter (season == "Summer")

# summary table
table.glm.summary <- data.frame (matrix (ncol = 5, nrow = 0))
colnames (table.glm.summary) <- c ("DU", "Season", "Years Old", "Coefficient", "p-values")
table.glm.summary [1:12, 1] <- "6"
table.glm.summary [1:4, 2] <- "Early Winter"
table.glm.summary [5:8, 2] <- "Late Winter"
table.glm.summary [9:12, 2] <- "Summer"
table.glm.summary [1:4, 3] <- c ("distance_to_cut_1to4yo", "distance_to_cut_5to9yo", "distance_to_cut_10to29yo", "distance_to_cut_30orOveryo")
table.glm.summary [5:8, 3] <- c ("distance_to_cut_1to4yo", "distance_to_cut_5to9yo", "distance_to_cut_10to29yo", "distance_to_cut_30orOveryo")
table.glm.summary [9:12, 3] <- c ("distance_to_cut_1to4yo", "distance_to_cut_5to9yo", "distance_to_cut_10to29yo", "distance_to_cut_30orOveryo")

table.glm.summary [13:24, 1] <- "7"
table.glm.summary [13:16, 2] <- "Early Winter"
table.glm.summary [17:20, 2] <- "Late Winter"
table.glm.summary [21:24, 2] <- "Summer"
table.glm.summary [13:16, 3] <- c ("distance_to_cut_1to4yo", "distance_to_cut_5to9yo", "distance_to_cut_10to29yo", "distance_to_cut_30orOveryo")
table.glm.summary [17:20, 3] <- c ("distance_to_cut_1to4yo", "distance_to_cut_5to9yo", "distance_to_cut_10to29yo", "distance_to_cut_30orOveryo")
table.glm.summary [21:24, 3] <- c ("distance_to_cut_1to4yo", "distance_to_cut_5to9yo", "distance_to_cut_10to29yo", "distance_to_cut_30orOveryo")

table.glm.summary [25:36, 1] <- "8"
table.glm.summary [25:28, 2] <- "Early Winter"
table.glm.summary [29:32, 2] <- "Late Winter"
table.glm.summary [33:36, 2] <- "Summer"
table.glm.summary [25:28, 3] <- c ("distance_to_cut_1to4yo", "distance_to_cut_5to9yo", "distance_to_cut_10to29yo", "distance_to_cut_30orOveryo")
table.glm.summary [29:32, 3] <- c ("distance_to_cut_1to4yo", "distance_to_cut_5to9yo", "distance_to_cut_10to29yo", "distance_to_cut_30orOveryo")
table.glm.summary [33:36, 3] <- c ("distance_to_cut_1to4yo", "distance_to_cut_5to9yo", "distance_to_cut_10to29yo", "distance_to_cut_30orOveryo")

table.glm.summary [37:48, 1] <- "9"
table.glm.summary [37:40, 2] <- "Early Winter"
table.glm.summary [41:44, 2] <- "Late Winter"
table.glm.summary [45:48, 2] <- "Summer"
table.glm.summary [37:40, 3] <- c ("distance_to_cut_1to4yo", "distance_to_cut_5to9yo", "distance_to_cut_10to29yo", "distance_to_cut_30orOveryo")
table.glm.summary [41:44, 3] <- c ("distance_to_cut_1to4yo", "distance_to_cut_5to9yo", "distance_to_cut_10to29yo", "distance_to_cut_30orOveryo")
table.glm.summary [45:48, 3] <- c ("distance_to_cut_1to4yo", "distance_to_cut_5to9yo", "distance_to_cut_10to29yo", "distance_to_cut_30orOveryo")

## DU6 ###
## Early Winter ##
glm.du.6.ew.1to4 <- glm (pttype ~ distance_to_cut_1to4yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [1, 4] <- glm.du.6.ew.1to4$coefficients [[2]]
table.glm.summary [1, 5] <- summary(glm.du.6.ew.1to4)$coefficients[2,4] # p-value
rm (glm.du.6.ew.1to4)
gc ()

glm.du.6.ew.5to9 <- glm (pttype ~ distance_to_cut_5to9yo, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [2, 4] <- glm.du.6.ew.5to9$coefficients [[2]]
table.glm.summary [2, 5] <- summary(glm.du.6.ew.5to9)$coefficients[2,4] # p-value
rm (glm.du.6.ew.5to9)
gc ()

glm.du.6.ew.10to29 <- glm (pttype ~ distance_to_cut_10to29yo, 
                           data = dist.cut.data.du.6.ew,
                           family = binomial (link = 'logit'))
table.glm.summary [3, 4] <- glm.du.6.ew.10to29$coefficients [[2]]
table.glm.summary [3, 5] <- summary(glm.du.6.ew.10to29)$coefficients[2,4] # p-value
rm (glm.du.6.ew.10to29)
gc ()

glm.du.6.ew.30orOver <- glm (pttype ~ distance_to_cut_30orOveryo, 
                             data = dist.cut.data.du.6.ew,
                             family = binomial (link = 'logit'))
table.glm.summary [4, 4] <- glm.du.6.ew.30orOver$coefficients [[2]]
table.glm.summary [4, 5] <- summary(glm.du.6.ew.30orOver)$coefficients[2,4] # p-value
rm (glm.du.6.ew.30orOver)
gc ()

## Late Winter ##
glm.du.6.lw.1to4 <- glm (pttype ~ distance_to_cut_1to4yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [5, 4] <- glm.du.6.lw.1to4$coefficients [[2]]
table.glm.summary [5, 5] <- summary(glm.du.6.lw.1to4)$coefficients[2,4] # p-value
rm (glm.du.6.lw.1to4)
gc ()

glm.du.6.lw.5to9 <- glm (pttype ~ distance_to_cut_5to9yo, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [6, 4] <- glm.du.6.lw.5to9$coefficients [[2]]
table.glm.summary [6, 5] <- summary(glm.du.6.lw.5to9)$coefficients[2,4] # p-value
rm (glm.du.6.lw.5to9)
gc ()

glm.du.6.lw.10to29 <- glm (pttype ~ distance_to_cut_10to29yo, 
                           data = dist.cut.data.du.6.lw,
                           family = binomial (link = 'logit'))
table.glm.summary [7, 4] <- glm.du.6.lw.10to29$coefficients [[2]]
table.glm.summary [7, 5] <- summary(glm.du.6.lw.10to29)$coefficients[2,4] # p-value
rm (glm.du.6.lw.10to29)
gc ()

glm.du.6.lw.30orOver <- glm (pttype ~ distance_to_cut_30orOveryo, 
                             data = dist.cut.data.du.6.lw,
                             family = binomial (link = 'logit'))
table.glm.summary [8, 4] <- glm.du.6.lw.30orOver$coefficients [[2]]
table.glm.summary [8, 5] <- summary(glm.du.6.lw.30orOver)$coefficients[2,4] # p-value
rm (glm.du.6.lw.30orOver)
gc ()

## Summer ##
glm.du.6.s.1to4 <- glm (pttype ~ distance_to_cut_1to4yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [9, 4] <- glm.du.6.s.1to4$coefficients [[2]]
table.glm.summary [9, 5] <- summary(glm.du.6.s.1to4)$coefficients[2,4] # p-value
rm (glm.du.6.s.1to4)
gc ()

glm.du.6.s.5to9 <- glm (pttype ~ distance_to_cut_5to9yo, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
table.glm.summary [10, 4] <- glm.du.6.s.5to9$coefficients [[2]]
table.glm.summary [10, 5] <- summary(glm.du.6.s.5to9)$coefficients[2,4] # p-value
rm (glm.du.6.s.5to9)
gc ()

glm.du.6.s.10to29 <- glm (pttype ~ distance_to_cut_10to29yo, 
                          data = dist.cut.data.du.6.s,
                          family = binomial (link = 'logit'))
table.glm.summary [11, 4] <- glm.du.6.s.10to29$coefficients [[2]]
table.glm.summary [11, 5] <- summary(glm.du.6.s.10to29)$coefficients[2,4] # p-value
rm (glm.du.6.s.10to29)
gc ()

glm.du.6.s.30orOver <- glm (pttype ~ distance_to_cut_30orOveryo, 
                            data = dist.cut.data.du.6.s,
                            family = binomial (link = 'logit'))
table.glm.summary [12, 4] <- glm.du.6.s.30orOver$coefficients [[2]]
table.glm.summary [12, 5] <- summary(glm.du.6.s.30orOver)$coefficients[2,4] # p-value
rm (glm.du.6.s.30orOver)
gc ()

## DU7 ###
## Early Winter ##
glm.du.7.ew.1to4 <- glm (pttype ~ distance_to_cut_1to4yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [13, 4] <- glm.du.7.ew.1to4$coefficients [[2]]
table.glm.summary [13, 5] <- summary(glm.du.7.ew.1to4)$coefficients[2,4] # p-value
rm (glm.du.7.ew.1to4)
gc ()

glm.du.7.ew.5to9 <- glm (pttype ~ distance_to_cut_5to9yo, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [14, 4] <- glm.du.7.ew.5to9$coefficients [[2]]
table.glm.summary [14, 5] <- summary(glm.du.7.ew.5to9)$coefficients[2,4] # p-value
rm (glm.du.7.ew.5to9)
gc ()

glm.du.7.ew.10to29 <- glm (pttype ~ distance_to_cut_10to29yo, 
                           data = dist.cut.data.du.7.ew,
                           family = binomial (link = 'logit'))
table.glm.summary [15, 4] <- glm.du.7.ew.10to29$coefficients [[2]]
table.glm.summary [15, 5] <- summary(glm.du.7.ew.10to29)$coefficients[2,4] # p-value
rm (glm.du.7.ew.10to29)
gc ()

glm.du.7.ew.30orOver <- glm (pttype ~ distance_to_cut_30orOveryo, 
                             data = dist.cut.data.du.7.ew,
                             family = binomial (link = 'logit'))
table.glm.summary [16, 4] <- glm.du.7.ew.30orOver$coefficients [[2]]
table.glm.summary [16, 5] <- summary(glm.du.7.ew.30orOver)$coefficients[2,4] # p-value
rm (glm.du.7.ew.30orOver)
gc ()

## Late Winter ##
glm.du.7.lw.1to4 <- glm (pttype ~ distance_to_cut_1to4yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [17, 4] <- glm.du.7.lw.1to4$coefficients [[2]]
table.glm.summary [17, 5] <- summary(glm.du.7.lw.1to4)$coefficients[2,4] # p-value
rm (glm.du.7.lw.1to4)
gc ()

glm.du.7.lw.5to9 <- glm (pttype ~ distance_to_cut_5to9yo, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [18, 4] <- glm.du.7.lw.5to9$coefficients [[2]]
table.glm.summary [18, 5] <- summary(glm.du.7.lw.5to9)$coefficients[2,4] # p-value
rm (glm.du.7.lw.5to9)
gc ()

glm.du.7.lw.10to29 <- glm (pttype ~ distance_to_cut_10to29yo, 
                           data = dist.cut.data.du.7.lw,
                           family = binomial (link = 'logit'))
table.glm.summary [19, 4] <- glm.du.7.lw.10to29$coefficients [[2]]
table.glm.summary [19, 5] <- summary(glm.du.7.lw.10to29)$coefficients[2,4] # p-value
rm (glm.du.7.lw.10to29)
gc ()

glm.du.7.lw.30orOver <- glm (pttype ~ distance_to_cut_30orOveryo, 
                             data = dist.cut.data.du.7.lw,
                             family = binomial (link = 'logit'))
table.glm.summary [20, 4] <- glm.du.7.lw.30orOver$coefficients [[2]]
table.glm.summary [20, 5] <- summary(glm.du.7.lw.30orOver)$coefficients[2,4] # p-value
rm (glm.du.7.lw.30orOver)
gc ()

## Summer ##
glm.du.7.s.1to4 <- glm (pttype ~ distance_to_cut_1to4yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [21, 4] <- glm.du.7.s.1to4$coefficients [[2]]
table.glm.summary [21, 5] <- summary(glm.du.7.s.1to4)$coefficients[2,4] # p-value
rm (glm.du.7.s.1to4)
gc ()

glm.du.7.s.5to9 <- glm (pttype ~ distance_to_cut_5to9yo, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
table.glm.summary [22, 4] <- glm.du.7.s.5to9$coefficients [[2]]
table.glm.summary [22, 5] <- summary(glm.du.7.s.5to9)$coefficients[2,4] # p-value
rm (glm.du.7.s.5to9)
gc ()

glm.du.7.s.10to29 <- glm (pttype ~ distance_to_cut_10to29yo, 
                          data = dist.cut.data.du.7.s,
                          family = binomial (link = 'logit'))
table.glm.summary [23, 4] <- glm.du.7.s.10to29$coefficients [[2]]
table.glm.summary [23, 5] <- summary(glm.du.7.s.10to29)$coefficients[2,4] # p-value
rm (glm.du.7.s.10to29)
gc ()

glm.du.7.s.30orOver <- glm (pttype ~ distance_to_cut_30orOveryo, 
                            data = dist.cut.data.du.7.s,
                            family = binomial (link = 'logit'))
table.glm.summary [24, 4] <- glm.du.7.s.30orOver$coefficients [[2]]
table.glm.summary [24, 5] <- summary(glm.du.7.s.30orOver)$coefficients[2,4] # p-value
rm (glm.du.7.s.30orOver)
gc ()


## DU8 ###
## Early Winter ##
glm.du.8.ew.1to4 <- glm (pttype ~ distance_to_cut_1to4yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [25, 4] <- glm.du.8.ew.1to4$coefficients [[2]]
table.glm.summary [25, 5] <- summary(glm.du.8.ew.1to4)$coefficients[2,4] # p-value
rm (glm.du.8.ew.1to4)
gc ()

glm.du.8.ew.5to9 <- glm (pttype ~ distance_to_cut_5to9yo, 
                         data = dist.cut.data.du.8.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [26, 4] <- glm.du.8.ew.5to9$coefficients [[2]]
table.glm.summary [26, 5] <- summary(glm.du.8.ew.5to9)$coefficients[2,4] # p-value
rm (glm.du.8.ew.5to9)
gc ()

glm.du.8.ew.10to29 <- glm (pttype ~ distance_to_cut_10to29yo, 
                           data = dist.cut.data.du.8.ew,
                           family = binomial (link = 'logit'))
table.glm.summary [27, 4] <- glm.du.8.ew.10to29$coefficients [[2]]
table.glm.summary [27, 5] <- summary(glm.du.8.ew.10to29)$coefficients[2,4] # p-value
rm (glm.du.8.ew.10to29)
gc ()

glm.du.8.ew.30orOver <- glm (pttype ~ distance_to_cut_30orOveryo, 
                             data = dist.cut.data.du.8.ew,
                             family = binomial (link = 'logit'))
table.glm.summary [28, 4] <- glm.du.8.ew.30orOver$coefficients [[2]]
table.glm.summary [28, 5] <- summary(glm.du.8.ew.30orOver)$coefficients[2,4] # p-value
rm (glm.du.8.ew.30orOver)
gc ()

## Late Winter ##
glm.du.8.lw.1to4 <- glm (pttype ~ distance_to_cut_1to4yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [29, 4] <- glm.du.8.lw.1to4$coefficients [[2]]
table.glm.summary [29, 5] <- summary(glm.du.8.lw.1to4)$coefficients[2,4] # p-value
rm (glm.du.8.lw.1to4)
gc ()

glm.du.8.lw.5to9 <- glm (pttype ~ distance_to_cut_5to9yo, 
                         data = dist.cut.data.du.8.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [30, 4] <- glm.du.8.lw.5to9$coefficients [[2]]
table.glm.summary [30, 5] <- summary(glm.du.8.lw.5to9)$coefficients[2,4] # p-value
rm (glm.du.8.lw.5to9)
gc ()

glm.du.8.lw.10to29 <- glm (pttype ~ distance_to_cut_10to29yo, 
                           data = dist.cut.data.du.8.lw,
                           family = binomial (link = 'logit'))
table.glm.summary [31, 4] <- glm.du.8.lw.10to29$coefficients [[2]]
table.glm.summary [31, 5] <- summary(glm.du.8.lw.10to29)$coefficients[2,4] # p-value
rm (glm.du.8.lw.10to29)
gc ()

glm.du.8.lw.30orOver <- glm (pttype ~ distance_to_cut_30orOveryo, 
                             data = dist.cut.data.du.8.lw,
                             family = binomial (link = 'logit'))
table.glm.summary [32, 4] <- glm.du.8.lw.30orOver$coefficients [[2]]
table.glm.summary [32, 5] <- summary(glm.du.8.lw.30orOver)$coefficients[2,4] # p-value
rm (glm.du.8.lw.30orOver)
gc ()

## Summer ##
glm.du.8.s.1to4 <- glm (pttype ~ distance_to_cut_1to4yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [33, 4] <- glm.du.8.s.1to4$coefficients [[2]]
table.glm.summary [33, 5] <- summary(glm.du.8.s.1to4)$coefficients[2,4] # p-value
rm (glm.du.8.s.1to4)
gc ()

glm.du.8.s.5to9 <- glm (pttype ~ distance_to_cut_5to9yo, 
                        data = dist.cut.data.du.8.s,
                        family = binomial (link = 'logit'))
table.glm.summary [34, 4] <- glm.du.8.s.5to9$coefficients [[2]]
table.glm.summary [34, 5] <- summary(glm.du.8.s.5to9)$coefficients[2,4] # p-value
rm (glm.du.8.s.5to9)
gc ()

glm.du.8.s.10to29 <- glm (pttype ~ distance_to_cut_10to29yo, 
                          data = dist.cut.data.du.8.s,
                          family = binomial (link = 'logit'))
table.glm.summary [35, 4] <- glm.du.8.s.10to29$coefficients [[2]]
table.glm.summary [35, 5] <- summary(glm.du.8.s.10to29)$coefficients[2,4] # p-value
rm (glm.du.8.s.10to29)
gc ()

glm.du.8.s.30orOver <- glm (pttype ~ distance_to_cut_30orOveryo, 
                            data = dist.cut.data.du.8.s,
                            family = binomial (link = 'logit'))
table.glm.summary [36, 4] <- glm.du.8.s.30orOver$coefficients [[2]]
table.glm.summary [36, 5] <- summary(glm.du.8.s.30orOver)$coefficients[2,4] # p-value
rm (glm.du.8.s.30orOver)
gc ()


## DU9 ###
## Early Winter ##
glm.du.9.ew.1to4 <- glm (pttype ~ distance_to_cut_1to4yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [37, 4] <- glm.du.9.ew.1to4$coefficients [[2]]
table.glm.summary [37, 5] <- summary(glm.du.9.ew.1to4)$coefficients[2,4] # p-value
rm (glm.du.9.ew.1to4)
gc ()

glm.du.9.ew.5to9 <- glm (pttype ~ distance_to_cut_5to9yo, 
                         data = dist.cut.data.du.9.ew,
                         family = binomial (link = 'logit'))
table.glm.summary [38, 4] <- glm.du.9.ew.5to9$coefficients [[2]]
table.glm.summary [38, 5] <- summary(glm.du.9.ew.5to9)$coefficients[2,4] # p-value
rm (glm.du.9.ew.5to9)
gc ()

glm.du.9.ew.10to29 <- glm (pttype ~ distance_to_cut_10to29yo, 
                           data = dist.cut.data.du.9.ew,
                           family = binomial (link = 'logit'))
table.glm.summary [39, 4] <- glm.du.9.ew.10to29$coefficients [[2]]
table.glm.summary [39, 5] <- summary(glm.du.9.ew.10to29)$coefficients[2,4] # p-value
rm (glm.du.9.ew.10to29)
gc ()

glm.du.9.ew.30orOver <- glm (pttype ~ distance_to_cut_30orOveryo, 
                             data = dist.cut.data.du.9.ew,
                             family = binomial (link = 'logit'))
table.glm.summary [40, 4] <- glm.du.9.ew.30orOver$coefficients [[2]]
table.glm.summary [40, 5] <- summary(glm.du.9.ew.30orOver)$coefficients[2,4] # p-value
rm (glm.du.9.ew.30orOver)
gc ()

## Late Winter ##
glm.du.9.lw.1to4 <- glm (pttype ~ distance_to_cut_1to4yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [41, 4] <- glm.du.9.lw.1to4$coefficients [[2]]
table.glm.summary [41, 5] <- summary(glm.du.9.lw.1to4)$coefficients[2,4] # p-value
rm (glm.du.9.lw.1to4)
gc ()

glm.du.9.lw.5to9 <- glm (pttype ~ distance_to_cut_5to9yo, 
                         data = dist.cut.data.du.9.lw,
                         family = binomial (link = 'logit'))
table.glm.summary [42, 4] <- glm.du.9.lw.5to9$coefficients [[2]]
table.glm.summary [42, 5] <- summary(glm.du.9.lw.5to9)$coefficients[2,4] # p-value
rm (glm.du.9.lw.5to9)
gc ()

glm.du.9.lw.10to29 <- glm (pttype ~ distance_to_cut_10to29yo, 
                           data = dist.cut.data.du.9.lw,
                           family = binomial (link = 'logit'))
table.glm.summary [43, 4] <- glm.du.9.lw.10to29$coefficients [[2]]
table.glm.summary [43, 5] <- summary(glm.du.9.lw.10to29)$coefficients[2,4] # p-value
rm (glm.du.9.lw.10to29)
gc ()

glm.du.9.lw.30orOver <- glm (pttype ~ distance_to_cut_30orOveryo, 
                             data = dist.cut.data.du.9.lw,
                             family = binomial (link = 'logit'))
table.glm.summary [44, 4] <- glm.du.9.lw.30orOver$coefficients [[2]]
table.glm.summary [44, 5] <- summary(glm.du.9.lw.30orOver)$coefficients[2,4] # p-value
rm (glm.du.9.lw.30orOver)
gc ()

## Summer ##
glm.du.9.s.1to4 <- glm (pttype ~ distance_to_cut_1to4yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [45, 4] <- glm.du.9.s.1to4$coefficients [[2]]
table.glm.summary [45, 5] <- summary(glm.du.9.s.1to4)$coefficients[2,4] # p-value
rm (glm.du.9.s.1to4)
gc ()

glm.du.9.s.5to9 <- glm (pttype ~ distance_to_cut_5to9yo, 
                        data = dist.cut.data.du.9.s,
                        family = binomial (link = 'logit'))
table.glm.summary [46, 4] <- glm.du.9.s.5to9$coefficients [[2]]
table.glm.summary [46, 5] <- summary(glm.du.9.s.5to9)$coefficients[2,4] # p-value
rm (glm.du.9.s.5to9)
gc ()

glm.du.9.s.10to29 <- glm (pttype ~ distance_to_cut_10to29yo, 
                          data = dist.cut.data.du.9.s,
                          family = binomial (link = 'logit'))
table.glm.summary [47, 4] <- glm.du.9.s.10to29$coefficients [[2]]
table.glm.summary [47, 5] <- summary(glm.du.9.s.10to29)$coefficients[2,4] # p-value
rm (glm.du.9.s.10to29)
gc ()

glm.du.9.s.30orOver <- glm (pttype ~ distance_to_cut_30orOveryo, 
                            data = dist.cut.data.du.9.s,
                            family = binomial (link = 'logit'))
table.glm.summary [48, 4] <- glm.du.9.s.30orOver$coefficients [[2]]
table.glm.summary [48, 5] <- summary(glm.du.9.s.30orOver)$coefficients[2,4] # p-value
rm (glm.du.9.s.30orOver)
gc ()

write.table (table.glm.summary, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_glm_summary_forestry_lean.csv", sep = ",")

table.glm.summary$years <- as.factor (table.glm.summary$"Years Old")
table.glm.summary$coefficent.km <- table.glm.summary$Coefficient * 1000

# table.glm.summary <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_glm_summary_forestry_lean.csv")
table.glm.summary$years <- factor (table.glm.summary$years, levels = c ("distance_to_cut_1to4yo", "distance_to_cut_5to9yo", "distance_to_cut_10to29yo", "distance_to_cut_30orOveryo"))
levels (table.glm.summary$years) <- c ("1 to 4 years old", "5 to 9 years old", "10 to 29 years old", "over 29 years old")
table.glm.summary$Season <- as.factor (table.glm.summary$Season)


#===================================================
### PLOTS of GLM outputs and distance to values ####
#==================================================
rsf.data.cut.age <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_cutblock_age.csv")

### DU6 ###
# box plot of values
rsf.data.data.cut.age.du6 <- rsf.data.cut.age %>%
  filter (du == "du6")
rsf.data.data.cut.age.du6 <- rsf.data.data.cut.age.du6 %>%
  dplyr::select (pttype, season, distance_to_cut_1to4yo, 
                 distance_to_cut_5to9yo, distance_to_cut_10to29yo, 
                 distance_to_cut_30orOveryo)
rsf.data.data.cut.age.du6 <- melt (rsf.data.data.cut.age.du6, 
                                   measure.vars = c ("distance_to_cut_1to4yo", 
                                                     "distance_to_cut_5to9yo",
                                                     "distance_to_cut_10to29yo",
                                                     "distance_to_cut_30orOveryo"),
                                   value.name = "distance_to_cut", 
                                   variable.name = "time_since_cut")
levels (rsf.data.data.cut.age.du6$time_since_cut) <- c ("1 to 4 years old", "5 to 9 years old", "10 to 29 years old", "over 29 years old")
rsf.data.data.cut.age.du6 <- rsf.data.data.cut.age.du6 %>%
  filter (pttype == 1)
rsf.data.data.cut.age.du6$distance_to_cut_km <- rsf.data.data.cut.age.du6$distance_to_cut / 1000

ggplot (data = rsf.data.data.cut.age.du6, 
        aes (time_since_cut, distance_to_cut_km)) +
  geom_boxplot (aes (colour = season)) +
  ggtitle ("Distance to cutblock by years since harvest \n and season for caribou designatable unit (DU) 6.") +
  xlab ("Years since harvest") + 
  ylab ("Distance to Cutblock (km)") +
  theme (plot.title = element_text(hjust = 0.5),
         axis.text = element_text (size = 10),
         axis.title = element_text (size = 12),
         axis.line.x = element_line (size = 1),
         axis.line.y = element_line (size = 1),
         panel.grid.minor = element_blank (),
         panel.border = element_blank (),
         panel.background = element_blank ()) +
  scale_y_continuous (limits = c (0, 300), breaks = seq (0, 300, by = 25))

# plot of coefficents
table.glm.summary.du6 <- table.glm.summary %>%
  filter (DU == 6)
ggplot (data = table.glm.summary.du6, 
        aes (years, coefficent.km)) +
  geom_point (aes (colour = Season),
              size = 4) +
  ggtitle ("Beta coefficient values of distance to cutblock \n by year and season for caribou designatable unit (DU) 6.") +
  xlab ("Years since harvest") + 
  ylab ("Beta coefficient") +
  theme (plot.title = element_text(hjust = 0.5),
         axis.text = element_text (size = 10),
         axis.title = element_text (size = 12),
         axis.line.x = element_line (size = 1),
         axis.line.y = element_line (size = 1),
         panel.grid.minor = element_blank (),
         panel.border = element_blank (),
         panel.background = element_blank ()) +
  scale_y_continuous (limits = c (-0.0035, 0.0025), breaks = seq (-0.0035, 0.0025, by = 0.0005))

### DU7 ###
# box plot of values
rsf.data.data.cut.age.du7 <- rsf.data.cut.age %>%
  filter (du == "du7")
rsf.data.data.cut.age.du7 <- rsf.data.data.cut.age.du7 %>%
  dplyr::select (pttype, season, distance_to_cut_1to4yo, 
                 distance_to_cut_5to9yo, distance_to_cut_10to29yo, 
                 distance_to_cut_30orOveryo)
rsf.data.data.cut.age.du7 <- melt (rsf.data.data.cut.age.du7, 
                                   measure.vars = c ("distance_to_cut_1to4yo", 
                                                     "distance_to_cut_5to9yo",
                                                     "distance_to_cut_10to29yo",
                                                     "distance_to_cut_30orOveryo"),
                                   value.name = "distance_to_cut", 
                                   variable.name = "time_since_cut")
levels (rsf.data.data.cut.age.du7$time_since_cut) <- c ("1 to 4 years old", "5 to 9 years old", "10 to 29 years old", "over 29 years old")
rsf.data.data.cut.age.du7 <- rsf.data.data.cut.age.du7 %>%
  filter (pttype == 1)
rsf.data.data.cut.age.du7$distance_to_cut_km <- rsf.data.data.cut.age.du7$distance_to_cut / 1000

ggplot (data = rsf.data.data.cut.age.du7, 
        aes (time_since_cut, distance_to_cut_km)) +
  geom_boxplot (aes (colour = season)) +
  ggtitle ("Distance to cutblock by years since harvest \n and season for caribou designatable unit (DU) 7.") +
  xlab ("Years since harvest") + 
  ylab ("Distance to Cutblock (km)") +
  theme (plot.title = element_text(hjust = 0.5),
         axis.text = element_text (size = 10),
         axis.title = element_text (size = 12),
         axis.line.x = element_line (size = 1),
         axis.line.y = element_line (size = 1),
         panel.grid.minor = element_blank (),
         panel.border = element_blank (),
         panel.background = element_blank ()) +
  scale_y_continuous (limits = c (0, 350), breaks = seq (0, 350, by = 25))

# plot of coefficents
table.glm.summary.du7 <- table.glm.summary %>%
  filter (DU == 7)
ggplot (data = table.glm.summary.du7, 
        aes (years, coefficent.km)) +
  geom_point (aes (colour = Season),
              size = 4) +
  ggtitle ("Beta coefficient values of distance to cutblock \n by year and season for caribou designatable unit (DU) 7.") +
  xlab ("Years since harvest") + 
  ylab ("Beta coefficient") +
  theme (plot.title = element_text(hjust = 0.5),
         axis.text = element_text (size = 10),
         axis.title = element_text (size = 12),
         axis.line.x = element_line (size = 1),
         axis.line.y = element_line (size = 1),
         panel.grid.minor = element_blank (),
         panel.border = element_blank (),
         panel.background = element_blank ()) +
  scale_y_continuous (limits = c (-0.0125, 0.001), breaks = seq (-0.0125, 0.001, by = 0.0025))

### DU8 ###
# box plot of values
rsf.data.data.cut.age.du8 <- rsf.data.cut.age %>%
  filter (du == "du8")
rsf.data.data.cut.age.du8 <- rsf.data.data.cut.age.du8 %>%
  dplyr::select (pttype, season, distance_to_cut_1to4yo, 
                 distance_to_cut_5to9yo, distance_to_cut_10to29yo, 
                 distance_to_cut_30orOveryo)
rsf.data.data.cut.age.du8 <- melt (rsf.data.data.cut.age.du8, 
                                   measure.vars = c ("distance_to_cut_1to4yo", 
                                                     "distance_to_cut_5to9yo",
                                                     "distance_to_cut_10to29yo",
                                                     "distance_to_cut_30orOveryo"),
                                   value.name = "distance_to_cut", 
                                   variable.name = "time_since_cut")
levels (rsf.data.data.cut.age.du8$time_since_cut) <- c ("1 to 4 years old", "5 to 9 years old", "10 to 29 years old", "over 29 years old")
rsf.data.data.cut.age.du8 <- rsf.data.data.cut.age.du8 %>%
  filter (pttype == 1)
rsf.data.data.cut.age.du8$distance_to_cut_km <- rsf.data.data.cut.age.du8$distance_to_cut / 1000

ggplot (data = rsf.data.data.cut.age.du8, 
        aes (time_since_cut, distance_to_cut_km)) +
  geom_boxplot (aes (colour = season)) +
  ggtitle ("Distance to cutblock by years since harvest \n and season for caribou designatable unit (DU) 8.") +
  xlab ("Years since harvest") + 
  ylab ("Distance to Cutblock (km)") +
  theme (plot.title = element_text(hjust = 0.5),
         axis.text = element_text (size = 10),
         axis.title = element_text (size = 12),
         axis.line.x = element_line (size = 1),
         axis.line.y = element_line (size = 1),
         panel.grid.minor = element_blank (),
         panel.border = element_blank (),
         panel.background = element_blank ()) +
  scale_y_continuous (limits = c (0, 50), breaks = seq (0, 50, by = 10))

# plot of coefficents
table.glm.summary.du8 <- table.glm.summary %>%
  filter (DU == 8)
ggplot (data = table.glm.summary.du8, 
        aes (years, coefficent.km)) +
  geom_point (aes (colour = Season),
              size = 4) +
  ggtitle ("Beta coefficient values of distance to cutblock \n by year and season for caribou designatable unit (DU) 8.") +
  xlab ("Years since harvest") + 
  ylab ("Beta coefficient") +
  theme (plot.title = element_text(hjust = 0.5),
         axis.text = element_text (size = 10),
         axis.title = element_text (size = 12),
         axis.line.x = element_line (size = 1),
         axis.line.y = element_line (size = 1),
         panel.grid.minor = element_blank (),
         panel.border = element_blank (),
         panel.background = element_blank ()) +
  scale_y_continuous (limits = c (-0.04, 0.03), breaks = seq (-0.04, 0.03, by = 0.01))


### DU9 ###
# box plot of values
rsf.data.data.cut.age.du9 <- rsf.data.cut.age %>%
  filter (du == "du9")
rsf.data.data.cut.age.du9 <- rsf.data.data.cut.age.du9 %>%
  dplyr::select (pttype, season, distance_to_cut_1to4yo, 
                 distance_to_cut_5to9yo, distance_to_cut_10to29yo, 
                 distance_to_cut_30orOveryo)
rsf.data.data.cut.age.du9 <- melt (rsf.data.data.cut.age.du9, 
                                   measure.vars = c ("distance_to_cut_1to4yo", 
                                                     "distance_to_cut_5to9yo",
                                                     "distance_to_cut_10to29yo",
                                                     "distance_to_cut_30orOveryo"),
                                   value.name = "distance_to_cut", 
                                   variable.name = "time_since_cut")
levels (rsf.data.data.cut.age.du9$time_since_cut) <- c ("1 to 4 years old", "5 to 9 years old", "10 to 29 years old", "over 29 years old")
rsf.data.data.cut.age.du9 <- rsf.data.data.cut.age.du9 %>%
  filter (pttype == 1)
rsf.data.data.cut.age.du9$distance_to_cut_km <- rsf.data.data.cut.age.du9$distance_to_cut / 1000

ggplot (data = rsf.data.data.cut.age.du9, 
        aes (time_since_cut, distance_to_cut_km)) +
  geom_boxplot (aes (colour = season)) +
  ggtitle ("Distance to cutblock by years since harvest \n and season for caribou designatable unit (DU) 9.") +
  xlab ("Years since harvest") + 
  ylab ("Distance to Cutblock (km)") +
  theme (plot.title = element_text(hjust = 0.5),
         axis.text = element_text (size = 10),
         axis.title = element_text (size = 12),
         axis.line.x = element_line (size = 1),
         axis.line.y = element_line (size = 1),
         panel.grid.minor = element_blank (),
         panel.border = element_blank (),
         panel.background = element_blank ()) +
  scale_y_continuous (limits = c (0, 40), breaks = seq (0, 40, by = 10))

# plot of coefficents
table.glm.summary.du9 <- table.glm.summary %>%
  filter (DU == 9)
ggplot (data = table.glm.summary.du9, 
        aes (years, coefficent.km)) +
  geom_point (aes (colour = Season),
              size = 4) +
  ggtitle ("Beta coefficient values of distance to cutblock \n by year and season for caribou designatable unit (DU) 9.") +
  xlab ("Years since harvest") + 
  ylab ("Beta coefficient") +
  theme (plot.title = element_text(hjust = 0.5),
         axis.text = element_text (size = 10),
         axis.title = element_text (size = 12),
         axis.line.x = element_line (size = 1),
         axis.line.y = element_line (size = 1),
         panel.grid.minor = element_blank (),
         panel.border = element_blank (),
         panel.background = element_blank ()) +
  scale_y_continuous (limits = c (-0.01, 0.08), breaks = seq (-0.01, 0.08, by = 0.01))













#=================================================
# Model selection Process by DU and Season 
#================================================
# load data
rsf.data.cut.age <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_cutblock_age.csv")
dist.cut.data <- rsf.data.cut.age [c (1:9, 112:115, 120)] # cutblock age class data only

# filter by DU, Season 
dist.cut.data.du.6.ew <- dist.cut.data %>%
  dplyr::filter (du == "du6") %>% 
  dplyr::filter (season == "EarlyWinter")
dist.cut.data.du.6.lw <- dist.cut.data %>%
  dplyr::filter (du == "du6") %>% 
  dplyr::filter (season == "LateWinter")
dist.cut.data.du.6.s <- dist.cut.data %>%
  dplyr::filter (du == "du6") %>% 
  dplyr::filter (season == "Summer")

dist.cut.data.du.7.ew <- dist.cut.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "EarlyWinter")
dist.cut.data.du.7.lw <- dist.cut.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "LateWinter")
dist.cut.data.du.7.s <- dist.cut.data %>%
  dplyr::filter (du == "du7") %>% 
  dplyr::filter (season == "Summer")

dist.cut.data.du.8.ew <- dist.cut.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "EarlyWinter")
dist.cut.data.du.8.lw <- dist.cut.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "LateWinter")
dist.cut.data.du.8.s <- dist.cut.data %>%
  dplyr::filter (du == "du8") %>% 
  dplyr::filter (season == "Summer")

dist.cut.data.du.9.ew <- dist.cut.data %>%
  dplyr::filter (du == "du9") %>% 
  dplyr::filter (season == "EarlyWinter")
dist.cut.data.du.9.lw <- dist.cut.data %>%
  dplyr::filter (du == "du9") %>% 
  dplyr::filter (season == "LateWinter")
dist.cut.data.du.9.s <- dist.cut.data %>%
  dplyr::filter (du == "du9") %>% 
  dplyr::filter (season == "Summer")

#================================
# GLMs
#================================
## Build an AIC and AUC Table
table.aic <- data.frame (matrix (ncol = 8, nrow = 0))
colnames (table.aic) <- c ("DU", "Season", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw", "AUC")

#============================
## DU6 ##
#==============
## Early Winter ##
### Corrletion
corr.dist.cut.du.6.ew <- round (cor (dist.cut.data.du.6.ew [10:13], method = "spearman"), 3)
ggcorrplot (corr.dist.cut.du.6.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Distance to Cutblock Correlation DU6 Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_dist_cut_corr_du_6_ew.png")

# distance to cutblocks 10 to 29 years old and 30 or over years old were highly correlated
# grouped together
# dist.cut.data.du.6.ew <- dplyr::mutate (dist.cut.data.du.6.ew, distance_to_cut_10yoorOver = pmin (distance_to_cut_10to29yo, distance_to_cut_30orOveryo))

### CART
cart.du.6.ew <- rpart (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                       distance_to_cut_10yoorOver,
                       data = dist.cut.data.du.6.ew, 
                       method = "class")
summary (cart.du.6.ew)
print (cart.du.6.ew)
plot (cart.du.6.ew, uniform = T)
text (cart.du.6.ew, use.n = T, splits = T, fancy = F)
post (cart.du.6.ew, file = "", uniform = T)
# results indicate no partioning, suggesting no effect of cutblocks

### VIF
model.glm.du6.ew <- glm (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                          distance_to_cut_10yoorOver, 
                         data = dist.cut.data.du.6.ew,
                         family = binomial (link = 'logit'))
vif (model.glm.du6.ew) 


# Generalized Linear Mixed Models (GLMMs)
# standardize covariates  (helps with model convergence)
dist.cut.data.du.6.ew$std.distance_to_cut_1to4yo <- (dist.cut.data.du.6.ew$distance_to_cut_1to4yo - mean (dist.cut.data.du.6.ew$distance_to_cut_1to4yo)) / sd (dist.cut.data.du.6.ew$distance_to_cut_1to4yo)
dist.cut.data.du.6.ew$std.distance_to_cut_5to9yo <- (dist.cut.data.du.6.ew$distance_to_cut_5to9yo - mean (dist.cut.data.du.6.ew$distance_to_cut_5to9yo)) / sd (dist.cut.data.du.6.ew$distance_to_cut_5to9yo)
dist.cut.data.du.6.ew$std.distance_to_cut_10yoorOver <- (dist.cut.data.du.6.ew$distance_to_cut_10yoorOver - mean (dist.cut.data.du.6.ew$distance_to_cut_10yoorOver)) / sd (dist.cut.data.du.6.ew$distance_to_cut_10yoorOver)

### fit corr random effects models
# ALL COVARS
model.lme.du6.ew <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                            std.distance_to_cut_10yoorOver + 
                            (std.distance_to_cut_1to4yo | uniqueID) + 
                            (std.distance_to_cut_5to9yo | uniqueID) +
                            (std.distance_to_cut_10yoorOver | uniqueID), 
                          data = dist.cut.data.du.6.ew, 
                          family = binomial (link = "logit"),
                          verbose = T,
                          control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                  optimizer = "nloptwrap", # these settings should provide results quicker
                                                  optCtrl = list (maxfun = 2e5))) # 20,000 iterations)
summary (model.lme.du6.ew)
anova (model.lme.du6.ew)
plot (model.lme.du6.ew) # should be mostly a straight line

dist.cut.data.du.6.ew$preds.lme.re <- predict (model.lme.du6.ew, type = 'response') 
dist.cut.data.du.6.ew$preds.lme.re.fe <- predict (model.lme.du6.ew, type = 'response', 
                                                  re.form = NA,
                                                  newdata = dist.cut.data.du.6.ew) 
plot (dist.cut.data.du.6.ew$distance_to_cut_1to4yo, dist.cut.data.du.6.ew$preds.lme.re.fe) # fixed effect predictions against covariate value
plot (dist.cut.data.du.6.ew$std.distance_to_cut_5to9yo, dist.cut.data.du.6.ew$preds.lme.re.fe) 
plot (dist.cut.data.du.6.ew$std.distance_to_cut_10yoorOver, dist.cut.data.du.6.ew$preds.lme.re.fe) 

save (model.lme.du6.ew, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_lme_du6_ew.rda")
# sjp.lmer (model.lme.du6.ew, type = "pred", vars = "std.distance_to_cut_1to4yo")
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "Early Winter"
table.aic [1, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 4] <- "DC1to4, DC5to9, DCover9"
table.aic [1, 5] <- "(DC1to4 | UniqueID), (DC5to9 | UniqueID), (DCover9 | UniqueID)"
table.aic [1, 6] <- AIC (model.lme.du6.ew)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [1, 8] <- auc.temp@y.values[[1]]

# AGE 1to4
model.lme.du6.ew.14 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                             (std.distance_to_cut_1to4yo | uniqueID), 
                           data = dist.cut.data.du.6.ew, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                   optimizer = "nloptwrap", # these settings should provide results quicker
                                                   optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [2, 1] <- "DU6"
table.aic [2, 2] <- "Early Winter"
table.aic [2, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [2, 4] <- "DC1to4"
table.aic [2, 5] <- "(DC1to4 | UniqueID)"
table.aic [2, 6] <- AIC (model.lme.du6.ew.14)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew.14, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [2, 8] <- auc.temp@y.values[[1]]

# AGE 5to9
model.lme.du6.ew.59 <- glmer (pttype ~ std.distance_to_cut_5to9yo + 
                                (std.distance_to_cut_5to9yo | uniqueID), 
                              data = dist.cut.data.du.6.ew, 
                              family = binomial (link = "logit"),
                              verbose = T,
                              control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                      optimizer = "nloptwrap", # these settings should provide results quicker
                                                      optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [3, 1] <- "DU6"
table.aic [3, 2] <- "Early Winter"
table.aic [3, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [3, 4] <- "DC5to9"
table.aic [3, 5] <- "(DC5to9 | UniqueID)"
table.aic [3, 6] <- AIC (model.lme.du6.ew.59)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew.59, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [3, 8] <- auc.temp@y.values[[1]]

# AGE >9
model.lme.du6.ew.over9 <- glmer (pttype ~ std.distance_to_cut_10yoorOver + 
                                (std.distance_to_cut_10yoorOver | uniqueID), 
                              data = dist.cut.data.du.6.ew, 
                              family = binomial (link = "logit"),
                              verbose = T,
                              control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                      optimizer = "nloptwrap", # these settings should provide results quicker
                                                      optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [4, 1] <- "DU6"
table.aic [4, 2] <- "Early Winter"
table.aic [4, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [4, 4] <- "DCover9"
table.aic [4, 5] <- "(DCover9 | UniqueID)"
table.aic [4, 6] <- AIC (model.lme.du6.ew.over9)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew.over9, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [4, 8] <- auc.temp@y.values[[1]]

# AGE 1to4, 5to9
model.lme.du6.ew.1459 <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                                  (std.distance_to_cut_1to4yo | uniqueID) + 
                                  (std.distance_to_cut_5to9yo | uniqueID), 
                                 data = dist.cut.data.du.6.ew, 
                                 family = binomial (link = "logit"),
                                 verbose = T,
                                 control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                         optimizer = "nloptwrap", # these settings should provide results quicker
                                                         optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [5, 1] <- "DU6"
table.aic [5, 2] <- "Early Winter"
table.aic [5, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [5, 4] <- "DC1to4, DC5to9"
table.aic [5, 5] <- "(DC1to4 | UniqueID), (DC5to9 | UniqueID)"
table.aic [5, 6] <- AIC (model.lme.du6.ew.1459)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew.1459, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [5, 8] <- auc.temp@y.values[[1]]

# AGE 1to4, over9
model.lme.du6.ew.14over9 <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_10yoorOver + 
                                  (std.distance_to_cut_1to4yo | uniqueID) + 
                                  (std.distance_to_cut_10yoorOver | uniqueID), 
                                data = dist.cut.data.du.6.ew, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                        optimizer = "nloptwrap", # these settings should provide results quicker
                                                        optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [6, 1] <- "DU6"
table.aic [6, 2] <- "Early Winter"
table.aic [6, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [6, 4] <- "DC1to4, DCover9"
table.aic [6, 5] <- "(DC1to4 | UniqueID), (DCover9 | UniqueID)"
table.aic [6, 6] <- AIC (model.lme.du6.ew.14over9)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew.14over9, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [6, 8] <- auc.temp@y.values[[1]]

# AGE 5to9, over9
model.lme.du6.ew.59over9 <- glmer (pttype ~ std.distance_to_cut_5to9yo + std.distance_to_cut_10yoorOver +
                                     (std.distance_to_cut_5to9yo | uniqueID) + 
                                     (std.distance_to_cut_10yoorOver  | uniqueID), 
                                   data = dist.cut.data.du.6.ew, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                           optimizer = "nloptwrap", # these settings should provide results quicker
                                                           optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [7, 1] <- "DU6"
table.aic [7, 2] <- "Early Winter"
table.aic [7, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [7, 4] <- "DC5to9, DCover9"
table.aic [7, 5] <- "(DC5to9 | UniqueID), (DCover9 | UniqueID)"
table.aic [7, 6] <- AIC (model.lme.du6.ew.59over9)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew.14over9, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [7, 8] <- auc.temp@y.values[[1]]

### Fit model with functional responses
# Calculating dataframe with covariate expectations
sub <- subset (dist.cut.data.du.6.ew, pttype == 0)
std.distance_to_cut_1to4yo_E <- tapply (sub$std.distance_to_cut_1to4yo, sub$uniqueID, mean)
std.distance_to_cut_5to9yo_E <- tapply (sub$std.distance_to_cut_5to9yo, sub$uniqueID, mean)
std.distance_to_cut_10yoorOver_E <- tapply (sub$std.distance_to_cut_10yoorOver, sub$uniqueID, mean)
inds <- as.character (dist.cut.data.du.6.ew$uniqueID)
dist.cut.data.du.6.ew <- cbind (dist.cut.data.du.6.ew, 
                                "std.distance_to_cut_1to4yo_E" = std.distance_to_cut_1to4yo_E [inds],
                                "std.distance_to_cut_5to9yo_E" = std.distance_to_cut_5to9yo_E [inds],
                                "std.distance_to_cut_10yoorOver_E" = std.distance_to_cut_10yoorOver_E [inds])

# ALL COVARS
model.lme.fxn.du6.ew <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                               std.distance_to_cut_10yoorOver + std.distance_to_cut_1to4yo_E +
                               std.distance_to_cut_5to9yo_E + std.distance_to_cut_10yoorOver_E +
                               std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                               std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                               std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                               (1 | uniqueID), 
                               data = dist.cut.data.du.6.ew, 
                               family = binomial (link = "logit"),
                               verbose = T,
                               control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                       optimizer = "nloptwrap", # these settings should provide results quicker
                                                       optCtrl = list (maxfun = 2e5)))
summary (model.lme.fxn.du6.ew)
anova (model.lme.fxn.du6.ew)
plot (model.lme.fxn.du6.ew) # should be mostly a straight line

dist.cut.data.du.6.ew$preds.lme.re.fxn <- predict (model.lme.fxn.du6.ew, type = 'response') 
dist.cut.data.du.6.ew$preds.lme.re.fe.fxn <- predict (model.lme.fxn.du6.ew, type = 'response', 
                                                      re.form = NA,
                                                      newdata = dist.cut.data.du.6.ew) 
plot (dist.cut.data.du.6.ew$distance_to_cut_1to4yo, dist.cut.data.du.6.ew$preds.lme.re.fe.fxn) # fixed effect predictions against covariate value
plot (dist.cut.data.du.6.ew$std.distance_to_cut_5to9yo, dist.cut.data.du.6.ew$preds.lme.re.fe.fxn) 
plot (dist.cut.data.du.6.ew$std.distance_to_cut_10yoorOver, dist.cut.data.du.6.ew$preds.lme.re.fe.fxn) 
save (model.lme.du6.ew, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_lme_fxn_du6_ew.rda")
# sjp.lmer (model.lme.du6.ew, type = "pred", vars = "std.distance_to_cut_1to4yo")
# AIC
table.aic [8, 1] <- "DU6"
table.aic [8, 2] <- "Early Winter"
table.aic [8, 3] <- "GLMM with Functional Response"
table.aic [8, 4] <- "DC1to4, DC5to9, DCover9, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DCover9"
table.aic [8, 5] <- "(1 | UniqueID)"
table.aic [8, 6] <- AIC (model.lme.fxn.du6.ew)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [8, 8] <- auc.temp@y.values[[1]]

# Age 1to4
model.lme.fxn.du6.ew.1to4 <- glmer (pttype ~ std.distance_to_cut_1to4yo +
                                      std.distance_to_cut_1to4yo_E +
                                      std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                      (1 | uniqueID), 
                               data = dist.cut.data.du.6.ew, 
                               family = binomial (link = "logit"),
                               verbose = T,
                               control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                       optimizer = "nloptwrap", # these settings should provide results quicker
                                                       optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [9, 1] <- "DU6"
table.aic [9, 2] <- "Early Winter"
table.aic [9, 3] <- "GLMM with Functional Response"
table.aic [9, 4] <- "DC1to4, A_DC1to4, DC1to4*A_DC1to4"
table.aic [9, 5] <- "(1 | UniqueID)"
table.aic [9, 6] <- AIC (model.lme.fxn.du6.ew.1to4)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew.14over9, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [9, 8] <- auc.temp@y.values[[1]]

# Age 5to9
model.lme.fxn.du6.ew.59 <- glmer (pttype ~ std.distance_to_cut_5to9yo +
                                    std.distance_to_cut_5to9yo_E +
                                    std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                    (1 | uniqueID), 
                                    data = dist.cut.data.du.6.ew, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                            optimizer = "nloptwrap", # these settings should provide results quicker
                                                           optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [10, 1] <- "DU6"
table.aic [10, 2] <- "Early Winter"
table.aic [10, 3] <- "GLMM with Functional Response"
table.aic [10, 4] <- "DC5to9, A_DC5to9, DC5to9*A_DC5to9"
table.aic [10, 5] <- "(1 | UniqueID)"
table.aic [10, 6] <- AIC (model.lme.fxn.du6.ew.59)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.59, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [10, 8] <- auc.temp@y.values[[1]]

# Age over9
model.lme.fxn.du6.ew.over9 <- glmer (pttype ~ std.distance_to_cut_10yoorOver +
                                       std.distance_to_cut_10yoorOver_E +
                                       std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                    (1 | uniqueID), 
                                  data = dist.cut.data.du.6.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                          optimizer = "nloptwrap", # these settings should provide results quicker
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [11, 1] <- "DU6"
table.aic [11, 2] <- "Early Winter"
table.aic [11, 3] <- "GLMM with Functional Response"
table.aic [11, 4] <- "DCover9, A_DCover9, DCover9*A_DCover9"
table.aic [11, 5] <- "(1 | UniqueID)"
table.aic [11, 6] <- AIC (model.lme.fxn.du6.ew.over9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.59, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [11, 8] <- auc.temp@y.values[[1]]

# Age 1to4, 5to9
model.lme.fxn.du6.ew.1459 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                       std.distance_to_cut_5to9yo +
                                       std.distance_to_cut_1to4yo_E +
                                       std.distance_to_cut_5to9yo_E +
                                       std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                       std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                       (1 | uniqueID), 
                                     data = dist.cut.data.du.6.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                             optimizer = "nloptwrap", # these settings should provide results quicker
                                                             optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [12, 1] <- "DU6"
table.aic [12, 2] <- "Early Winter"
table.aic [12, 3] <- "GLMM with Functional Response"
table.aic [12, 4] <- "DC1to4, DC5to9, A_DC1to4, A_DC5to9, DC1to4*A_DC1to4, DC5to9*A_DC5to9"
table.aic [12, 5] <- "(1 | UniqueID)"
table.aic [12, 6] <- AIC (model.lme.fxn.du6.ew.1459)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.1459, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [12, 8] <- auc.temp@y.values[[1]]

# Age 1to4, over9
model.lme.fxn.du6.ew.14over9 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                      std.distance_to_cut_10yoorOver +
                                      std.distance_to_cut_1to4yo_E +
                                      std.distance_to_cut_10yoorOver_E +
                                      std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                      std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                      (1 | uniqueID), 
                                    data = dist.cut.data.du.6.ew, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                            optimizer = "nloptwrap", # these settings should provide results quicker
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [13, 1] <- "DU6"
table.aic [13, 2] <- "Early Winter"
table.aic [13, 3] <- "GLMM with Functional Response"
table.aic [13, 4] <- "DC1to4, DCover9, A_DC1to4, A_DCover9, DC1to4*A_DC1to4, DCover9*A_DCover9"
table.aic [13, 5] <- "(1 | UniqueID)"
table.aic [13, 6] <- AIC (model.lme.fxn.du6.ew.14over9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.14over9, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [13, 8] <- auc.temp@y.values[[1]]

# Age 5to9, over9
model.lme.fxn.du6.ew.59over9 <- glmer (pttype ~ std.distance_to_cut_5to9yo  + 
                                         std.distance_to_cut_10yoorOver +
                                         std.distance_to_cut_5to9yo_E +
                                         std.distance_to_cut_10yoorOver_E +
                                         std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                         std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                         (1 | uniqueID), 
                                       data = dist.cut.data.du.6.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T,
                                       control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                               optimizer = "nloptwrap", # these settings should provide results quicker
                                                               optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [14, 1] <- "DU6"
table.aic [14, 2] <- "Early Winter"
table.aic [14, 3] <- "GLMM with Functional Response"
table.aic [14, 4] <- "DC5to9, DCover9, A_DC5to9, A_DCover9, DC5to9*A_DC5to9, DCover9*A_DCover9"
table.aic [14, 5] <- "(1 | UniqueID)"
table.aic [14, 6] <- AIC (model.lme.fxn.du6.ew.59over9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.59over9, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [14, 8] <- auc.temp@y.values[[1]]

# AIC comparison DU6 early winter
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

# save the top model
save (model.lme.du6.ew.59over9, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_lme_du6_ew_top.rda")

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_forestry.csv", sep = ",")

#============================================
## Late Winter ##
### Corrletion
corr.dist.cut.du.6.lw <- round (cor (dist.cut.data.du.6.lw [10:13], method = "spearman"), 3)
ggcorrplot (corr.dist.cut.du.6.lw, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Distance to Cutblock Correlation DU6 Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_dist_cut_corr_du_6_lw.png")

# distance to cutblocks 10 to 29 years old and 30 or over years old were highly correlated
# grouped together
dist.cut.data.du.6.lw <- dplyr::mutate (dist.cut.data.du.6.lw, distance_to_cut_10yoorOver = pmin (distance_to_cut_10to29yo, distance_to_cut_30orOveryo))

### CART
cart.du.6.lw <- rpart (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                         distance_to_cut_10yoorOver,
                       data = dist.cut.data.du.6.lw, 
                       method = "class")
summary (cart.du.6.lw)
print (cart.du.6.lw)
plot (cart.du.6.lw, uniform = T)
text (cart.du.6.lw, use.n = T, splits = T, fancy = F)
post (cart.du.6.lw, file = "", uniform = T)
# results indicate no partioning, suggesting no effect of cutblocks

### VIF
model.glm.du6.lw <- glm (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                           distance_to_cut_10yoorOver, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
vif (model.glm.du6.lw) 

# Generalized Linear Mixed Models (GLMMs)
# standardize covariates  (helps with model convergence)
dist.cut.data.du.6.lw$std.distance_to_cut_1to4yo <- (dist.cut.data.du.6.lw$distance_to_cut_1to4yo - mean (dist.cut.data.du.6.lw$distance_to_cut_1to4yo)) / sd (dist.cut.data.du.6.lw$distance_to_cut_1to4yo)
dist.cut.data.du.6.lw$std.distance_to_cut_5to9yo <- (dist.cut.data.du.6.lw$distance_to_cut_5to9yo - mean (dist.cut.data.du.6.lw$distance_to_cut_5to9yo)) / sd (dist.cut.data.du.6.lw$distance_to_cut_5to9yo)
dist.cut.data.du.6.lw$std.distance_to_cut_10yoorOver <- (dist.cut.data.du.6.lw$distance_to_cut_10yoorOver - mean (dist.cut.data.du.6.lw$distance_to_cut_10yoorOver)) / sd (dist.cut.data.du.6.lw$distance_to_cut_10yoorOver)

### fit corr random effects model
model.lme.du6.lw <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                             std.distance_to_cut_10yoorOver + 
                             (std.distance_to_cut_1to4yo | uniqueID) + 
                             (std.distance_to_cut_5to9yo | uniqueID) +
                             (std.distance_to_cut_10yoorOver | uniqueID), 
                           data = dist.cut.data.du.6.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                   optimizer = "nloptwrap", # these settings should provide results quicker
                                                   optCtrl = list (maxfun = 2e5))) # 20,000 iterations)
summary (model.lme.du6.lw)
anova (model.lme.du6.lw)
plot (model.lme.du6.lw) # should be mostly a straight line

dist.cut.data.du.6.lw$preds.lme.re <- predict (model.lme.du6.lw, type = 'response') 
dist.cut.data.du.6.lw$preds.lme.re.fe <- predict (model.lme.du6.lw, type = 'response', 
                                                  re.form = NA,
                                                  newdata = dist.cut.data.du.6.lw) 
plot (dist.cut.data.du.6.lw$distance_to_cut_1to4yo, dist.cut.data.du.6.lw$preds.lme.re.fe) # fixed effect predictions against covariate value
plot (dist.cut.data.du.6.lw$std.distance_to_cut_5to9yo, dist.cut.data.du.6.lw$preds.lme.re.fe) 
plot (dist.cut.data.du.6.lw$std.distance_to_cut_10yoorOver, dist.cut.data.du.6.lw$preds.lme.re.fe) 
# sjp.lmer (model.lme.du6.lw, type = "pred", vars = "std.distance_to_cut_1to4yo")
# AIC
table.aic [15, 1] <- "DU6"
table.aic [15, 2] <- "Late Winter"
table.aic [15, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [15, 4] <- "DC1to4, DC5to9, DCover9"
table.aic [15, 5] <- "(DC1to4 | UniqueID), (DC5to9 | UniqueID), (DCover9 | UniqueID)"
table.aic [15, 6] <- AIC (model.lme.du6.lw)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [15, 8] <- auc.temp@y.values[[1]]

# AGE 1to4
model.lme.du6.lw.14 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                (std.distance_to_cut_1to4yo | uniqueID), 
                              data = dist.cut.data.du.6.lw, 
                              family = binomial (link = "logit"),
                              verbose = T,
                              control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                      optimizer = "nloptwrap", # these settings should provide results quicker
                                                      optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [16, 1] <- "DU6"
table.aic [16, 2] <- "Late Winter"
table.aic [16, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [16, 4] <- "DC1to4"
table.aic [16, 5] <- "(DC1to4 | UniqueID)"
table.aic [16, 6] <- AIC (model.lme.du6.lw.14)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.14, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [16, 8] <- auc.temp@y.values[[1]]

# AGE 5to9
model.lme.du6.lw.59 <- glmer (pttype ~ std.distance_to_cut_5to9yo  + 
                                (std.distance_to_cut_5to9yo  | uniqueID), 
                              data = dist.cut.data.du.6.lw, 
                              family = binomial (link = "logit"),
                              verbose = T,
                              control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                      optimizer = "nloptwrap", # these settings should provide results quicker
                                                      optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [17, 1] <- "DU6"
table.aic [17, 2] <- "Late Winter"
table.aic [17, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [17, 4] <- "DC5to9"
table.aic [17, 5] <- "(DC5to9 | UniqueID)"
table.aic [17, 6] <- AIC (model.lme.du6.lw.59)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.59, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [17, 8] <- auc.temp@y.values[[1]]

# AGE over9
model.lme.du6.lw.over9 <- glmer (pttype ~ std.distance_to_cut_10yoorOver  + 
                                (std.distance_to_cut_10yoorOver  | uniqueID), 
                              data = dist.cut.data.du.6.lw, 
                              family = binomial (link = "logit"),
                              verbose = T,
                              control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                      optimizer = "nloptwrap", # these settings should provide results quicker
                                                      optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [18, 1] <- "DU6"
table.aic [18, 2] <- "Late Winter"
table.aic [18, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [18, 4] <- "DCover9"
table.aic [18, 5] <- "(DCover9 | UniqueID)"
table.aic [18, 6] <- AIC (model.lme.du6.lw.over9)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.over9, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [18, 8] <- auc.temp@y.values[[1]]

# AGE 1to4, 5to9
model.lme.du6.lw.1459 <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                                   (std.distance_to_cut_1to4yo | uniqueID) +
                                   (std.distance_to_cut_5to9yo | uniqueID), 
                                 data = dist.cut.data.du.6.lw, 
                                 family = binomial (link = "logit"),
                                 verbose = T,
                                 control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                         optimizer = "nloptwrap", # these settings should provide results quicker
                                                         optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [19, 1] <- "DU6"
table.aic [19, 2] <- "Late Winter"
table.aic [19, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [19, 4] <- "DC1to4, DC5to9"
table.aic [19, 5] <- "(DC1to4 | UniqueID), (DC5to9 | UniqueID)"
table.aic [19, 6] <- AIC (model.lme.du6.lw.1459)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.over9, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [19, 8] <- auc.temp@y.values[[1]]

# AGE 1to4, over9
model.lme.du6.lw.14over9 <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_10yoorOver + 
                                  (std.distance_to_cut_1to4yo | uniqueID) +
                                  (std.distance_to_cut_10yoorOver | uniqueID), 
                                data = dist.cut.data.du.6.lw, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                        optimizer = "nloptwrap", # these settings should provide results quicker
                                                        optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [20, 1] <- "DU6"
table.aic [20, 2] <- "Late Winter"
table.aic [20, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [20, 4] <- "DC1to4, DCover9"
table.aic [20, 5] <- "(DC1to4 | UniqueID), (DCover9 | UniqueID)"
table.aic [20, 6] <- AIC (model.lme.du6.lw.14over9)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.14over9, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [20, 8] <- auc.temp@y.values[[1]]

# AGE 5to9, over9
model.lme.du6.lw.59over9 <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo  + 
                                     (std.distance_to_cut_1to4yo | uniqueID) +
                                     (std.distance_to_cut_5to9yo  | uniqueID), 
                                   data = dist.cut.data.du.6.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                           optimizer = "nloptwrap", # these settings should provide results quicker
                                                           optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [21, 1] <- "DU6"
table.aic [21, 2] <- "Late Winter"
table.aic [21, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [21, 4] <- "DC5to9, DCover9"
table.aic [21, 5] <- "(DC5to9 | UniqueID), (DCover9 | UniqueID)"
table.aic [21, 6] <- AIC (model.lme.du6.lw.59over9)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.59over9, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [21, 8] <- auc.temp@y.values[[1]]

### Fit model with functional responses
# Calculating dataframe with covariate expectations
sub <- subset (dist.cut.data.du.6.lw, pttype == 0)
std.distance_to_cut_1to4yo_E <- tapply (sub$std.distance_to_cut_1to4yo, sub$uniqueID, mean)
std.distance_to_cut_5to9yo_E <- tapply (sub$std.distance_to_cut_5to9yo, sub$uniqueID, mean)
std.distance_to_cut_10yoorOver_E <- tapply (sub$std.distance_to_cut_10yoorOver, sub$uniqueID, mean)
inds <- as.character (dist.cut.data.du.6.lw$uniqueID)
dist.cut.data.du.6.lw <- cbind (dist.cut.data.du.6.lw, 
                                "std.distance_to_cut_1to4yo_E" = std.distance_to_cut_1to4yo_E [inds],
                                "std.distance_to_cut_5to9yo_E" = std.distance_to_cut_5to9yo_E [inds],
                                "std.distance_to_cut_10yoorOver_E" = std.distance_to_cut_10yoorOver_E [inds])
# All COVARS
model.lme.fxn.du6.lw <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                                 std.distance_to_cut_10yoorOver + std.distance_to_cut_1to4yo_E +
                                 std.distance_to_cut_5to9yo_E + std.distance_to_cut_10yoorOver_E +
                                 std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                 std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                 std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                 (1 | uniqueID), 
                               data = dist.cut.data.du.6.lw, 
                               family = binomial (link = "logit"),
                               verbose = T,
                               control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                       optimizer = "nloptwrap", # these settings should provide results quicker
                                                       optCtrl = list (maxfun = 2e5)))
summary (model.lme.fxn.du6.lw)
anova (model.lme.fxn.du6.lw)
plot (model.lme.fxn.du6.lw) # should be mostly a straight line

dist.cut.data.du.6.lw$preds.lme.re.fxn <- predict (model.lme.fxn.du6.lw, type = 'response') 
dist.cut.data.du.6.lw$preds.lme.re.fe.fxn <- predict (model.lme.fxn.du6.lw, type = 'response', 
                                                      re.form = NA,
                                                      newdata = dist.cut.data.du.6.lw) 
plot (dist.cut.data.du.6.lw$distance_to_cut_1to4yo, dist.cut.data.du.6.lw$preds.lme.re.fe.fxn) # fixed effect predictions against covariate value
plot (dist.cut.data.du.6.lw$std.distance_to_cut_5to9yo, dist.cut.data.du.6.lw$preds.lme.re.fe.fxn) 
plot (dist.cut.data.du.6.lw$std.distance_to_cut_10yoorOver, dist.cut.data.du.6.lw$preds.lme.re.fe.fxn) 
# sjp.lmer (model.lme.du6.lw, type = "pred", vars = "std.distance_to_cut_1to4yo")

# AIC
table.aic [22, 1] <- "DU6"
table.aic [22, 2] <- "Late Winter"
table.aic [22, 3] <- "GLMM with Functional Response"
table.aic [22, 4] <- "DC1to4, DC5to9, DCover9, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DCover9"
table.aic [22, 5] <- "(1 | UniqueID)"
table.aic [22, 6] <- AIC (model.lme.fxn.du6.lw)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [22, 8] <- auc.temp@y.values[[1]]

# 1to4
model.lme.fxn.du6.lw.1to4 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                    std.distance_to_cut_1to4yo_E +
                                    std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                    (1 | uniqueID), 
                               data = dist.cut.data.du.6.lw, 
                               family = binomial (link = "logit"),
                               verbose = T,
                               control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                       optimizer = "nloptwrap", # these settings should provide results quicker
                                                       optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [23, 1] <- "DU6"
table.aic [23, 2] <- "Late Winter"
table.aic [23, 3] <- "GLMM with Functional Response"
table.aic [23, 4] <- "DC1to4, A_DC1to4, DC1to4*A_DC1to4"
table.aic [23, 5] <- "(1 | UniqueID)"
table.aic [23, 6] <- AIC (model.lme.fxn.du6.lw.1to4)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.1to4, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [23, 8] <- auc.temp@y.values[[1]]

# 5to9
model.lme.fxn.du6.lw.5to9 <- glmer (pttype ~ std.distance_to_cut_5to9yo  + 
                                      std.distance_to_cut_5to9yo_E  +
                                      std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                      (1 | uniqueID), 
                                    data = dist.cut.data.du.6.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                            optimizer = "nloptwrap", # these settings should provide results quicker
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [24, 1] <- "DU6"
table.aic [24, 2] <- "Late Winter"
table.aic [24, 3] <- "GLMM with Functional Response"
table.aic [24, 4] <- "DC5to9, A_DC5to9, DC5to9*A_DC5to9"
table.aic [24, 5] <- "(1 | UniqueID)"
table.aic [24, 6] <- AIC (model.lme.fxn.du6.lw.5to9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.5to9, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [24, 8] <- auc.temp@y.values[[1]]

# over9
model.lme.fxn.du6.lw.over9 <- glmer (pttype ~ std.distance_to_cut_10yoorOver  + 
                                       std.distance_to_cut_10yoorOver_E   +
                                       std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                      (1 | uniqueID), 
                                    data = dist.cut.data.du.6.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                            optimizer = "nloptwrap", # these settings should provide results quicker
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [25, 1] <- "DU6"
table.aic [25, 2] <- "Late Winter"
table.aic [25, 3] <- "GLMM with Functional Response"
table.aic [25, 4] <- "DCover9, A_DCover9, DCover9*A_DCover9"
table.aic [25, 5] <- "(1 | UniqueID)"
table.aic [25, 6] <- AIC (model.lme.fxn.du6.lw.over9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.over9, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [25, 8] <- auc.temp@y.values[[1]]

# 1to4, 5to9
model.lme.fxn.du6.lw.1459 <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                      std.distance_to_cut_1to4yo_E +
                                      std.distance_to_cut_5to9yo_E +
                                      std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                      std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                       (1 | uniqueID), 
                                     data = dist.cut.data.du.6.lw, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                             optimizer = "nloptwrap", # these settings should provide results quicker
                                                             optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [26, 1] <- "DU6"
table.aic [26, 2] <- "Late Winter"
table.aic [26, 3] <- "GLMM with Functional Response"
table.aic [26, 4] <- "DC1to4, DC5to9, A_DC1to4, A_DC5to9, DC1to4*A_DC1to4, DC5to9*A_DC5to9"
table.aic [26, 5] <- "(1 | UniqueID)"
table.aic [26, 6] <- AIC (model.lme.fxn.du6.lw.1459)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.1459, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [26, 8] <- auc.temp@y.values[[1]]

# 1to4, over9
model.lme.fxn.du6.lw.14over9 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                         std.distance_to_cut_10yoorOver +
                                        std.distance_to_cut_1to4yo_E +
                                        std.distance_to_cut_10yoorOver_E  +
                                        std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                        std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                      (1 | uniqueID), 
                                    data = dist.cut.data.du.6.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                            optimizer = "nloptwrap", # these settings should provide results quicker
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [27, 1] <- "DU6"
table.aic [27, 2] <- "Late Winter"
table.aic [27, 3] <- "GLMM with Functional Response"
table.aic [27, 4] <- "DC1to4, DCover9, A_DC1to4, A_DCover9, DC1to4*A_DC1to4, DCover9*A_DCover9"
table.aic [27, 5] <- "(1 | UniqueID)"
table.aic [27, 6] <- AIC (model.lme.fxn.du6.lw.14over9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.14over9, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [27, 8] <- auc.temp@y.values[[1]]

# 5to9, over9
model.lme.fxn.du6.lw.59over9 <- glmer (pttype ~ std.distance_to_cut_5to9yo + 
                                         std.distance_to_cut_10yoorOver +
                                         std.distance_to_cut_5to9yo_E +
                                         std.distance_to_cut_10yoorOver_E  +
                                         std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                         std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                         (1 | uniqueID), 
                                       data = dist.cut.data.du.6.lw, 
                                       family = binomial (link = "logit"),
                                       verbose = T,
                                       control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                               optimizer = "nloptwrap", # these settings should provide results quicker
                                                               optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [28, 1] <- "DU6"
table.aic [28, 2] <- "Late Winter"
table.aic [28, 3] <- "GLMM with Functional Response"
table.aic [28, 4] <- "DC5to9, DCover9, A_DC5to9, A_DCover9, DC5to9*A_DC5to9, DCover9*A_DCover9"
table.aic [28, 5] <- "(1 | UniqueID)"
table.aic [28, 6] <- AIC (model.lme.fxn.du6.lw.59over9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.59over9, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [28, 8] <- auc.temp@y.values[[1]]


# AIC comparison DU6 early winter
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
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_forestry.csv", sep = ",")

# save the top model
save (model.lme.du6.lw, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_lme_du6_lw_top.rda")

#============================================
## Summer ##
### Correlation
corr.dist.cut.du.6.s <- round (cor (dist.cut.data.du.6.s [10:13], method = "spearman"), 3)
ggcorrplot (corr.dist.cut.du.6.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Distance to Cutblock Correlation DU6 Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_dist_cut_corr_du_6_s.png")

# distance to cutblocks 10 to 29 years old and 30 or over years old were highly correlated
# grouped together
dist.cut.data.du.6.s <- dplyr::mutate (dist.cut.data.du.6.s, distance_to_cut_10yoorOver = pmin (distance_to_cut_10to29yo, distance_to_cut_30orOveryo))

### CART
cart.du.6.s <- rpart (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                         distance_to_cut_10yoorOver,
                       data = dist.cut.data.du.6.s, 
                       method = "class")
summary (cart.du.6.s)
print (cart.du.6.s)
plot (cart.du.6.s, uniform = T)
text (cart.du.6.s, use.n = T, splits = T, fancy = F)
post (cart.du.6.s, file = "", uniform = T)
# results indicate no partioning, suggesting no effect of cutblocks

### VIF
model.glm.du6.s <- glm (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                           distance_to_cut_10yoorOver, 
                         data = dist.cut.data.du.6.s,
                         family = binomial (link = 'logit'))
vif (model.glm.du6.s) 

# Generalized Linear Mixed Models (GLMMs)
# standardize covariates  (helps with model convergence)
dist.cut.data.du.6.s$std.distance_to_cut_1to4yo <- (dist.cut.data.du.6.s$distance_to_cut_1to4yo - mean (dist.cut.data.du.6.s$distance_to_cut_1to4yo)) / sd (dist.cut.data.du.6.s$distance_to_cut_1to4yo)
dist.cut.data.du.6.s$std.distance_to_cut_5to9yo <- (dist.cut.data.du.6.s$distance_to_cut_5to9yo - mean (dist.cut.data.du.6.s$distance_to_cut_5to9yo)) / sd (dist.cut.data.du.6.s$distance_to_cut_5to9yo)
dist.cut.data.du.6.s$std.distance_to_cut_10yoorOver <- (dist.cut.data.du.6.s$distance_to_cut_10yoorOver - mean (dist.cut.data.du.6.s$distance_to_cut_10yoorOver)) / sd (dist.cut.data.du.6.s$distance_to_cut_10yoorOver)

### fit corr random effects model
model.lme.du6.s <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                             std.distance_to_cut_10yoorOver + 
                             (std.distance_to_cut_1to4yo | uniqueID) + 
                             (std.distance_to_cut_5to9yo | uniqueID) +
                             (std.distance_to_cut_10yoorOver | uniqueID), 
                           data = dist.cut.data.du.6.s, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                   optimizer = "nloptwrap", # these settings should provide results quicker
                                                   optCtrl = list (maxfun = 2e5))) # 20,000 iterations)
summary (model.lme.du6.s)
anova (model.lme.du6.s)
plot (model.lme.du6.s) # should be mostly a straight line

# AIC
table.aic [29, 1] <- "DU6"
table.aic [29, 2] <- "Summer"
table.aic [29, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [29, 4] <- "DC1to4, DC5to9, DCover9"
table.aic [29, 5] <- "(DC1to4 | UniqueID), (DC5to9 | UniqueID), (DCover9 | UniqueID)"
table.aic [29, 6] <- AIC (model.lme.du6.s)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.s, type = 'response'), dist.cut.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [29, 8] <- auc.temp@y.values[[1]]

# AGE 1to4
model.lme.du6.s.14 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                  (std.distance_to_cut_1to4yo | uniqueID), 
                                data = dist.cut.data.du.6.s, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                        optimizer = "nloptwrap", # these settings should provide results quicker
                                                        optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [30, 1] <- "DU6"
table.aic [30, 2] <- "Summer"
table.aic [30, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [30, 4] <- "DC1to4"
table.aic [30, 5] <- "(DC1to4 | UniqueID)"
table.aic [30, 6] <- AIC (model.lme.du6.s.14)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.s.14, type = 'response'), dist.cut.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [30, 8] <- auc.temp@y.values[[1]]

# AGE 5to9
model.lme.du6.s.59 <- glmer (pttype ~ std.distance_to_cut_5to9yo + 
                               (std.distance_to_cut_5to9yo | uniqueID), 
                             data = dist.cut.data.du.6.s, 
                             family = binomial (link = "logit"),
                             verbose = T,
                             control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                     optimizer = "nloptwrap", # these settings should provide results quicker
                                                     optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [31, 1] <- "DU6"
table.aic [31, 2] <- "Summer"
table.aic [31, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [31, 4] <- "DC5to9"
table.aic [31, 5] <- "(DC5to9 | UniqueID)"
table.aic [31, 6] <- AIC (model.lme.du6.s.59)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.s.59, type = 'response'), dist.cut.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [31, 8] <- auc.temp@y.values[[1]]


# AGE over9
model.lme.du6.s.over9 <- glmer (pttype ~ std.distance_to_cut_10yoorOver + 
                               (std.distance_to_cut_10yoorOver | uniqueID), 
                             data = dist.cut.data.du.6.s, 
                             family = binomial (link = "logit"),
                             verbose = T,
                             control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                     optimizer = "nloptwrap", # these settings should provide results quicker
                                                     optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [32, 1] <- "DU6"
table.aic [32, 2] <- "Summer"
table.aic [32, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [32, 4] <- "DCover9"
table.aic [32, 5] <- "(DCover9 | UniqueID)"
table.aic [32, 6] <- AIC (model.lme.du6.s.over9)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.s.over9, type = 'response'), dist.cut.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [32, 8] <- auc.temp@y.values[[1]]















### Fit model with functional responses
# Calculating dataframe with covariate expectations
sub <- subset (dist.cut.data.du.6.s, pttype == 0)
std.distance_to_cut_1to4yo_E <- tapply (sub$std.distance_to_cut_1to4yo, sub$uniqueID, mean)
std.distance_to_cut_5to9yo_E <- tapply (sub$std.distance_to_cut_5to9yo, sub$uniqueID, mean)
std.distance_to_cut_10yoorOver_E <- tapply (sub$std.distance_to_cut_10yoorOver, sub$uniqueID, mean)
inds <- as.character (dist.cut.data.du.6.s$uniqueID)
dist.cut.data.du.6.s <- cbind (dist.cut.data.du.6.s, 
                                "std.distance_to_cut_1to4yo_E" = std.distance_to_cut_1to4yo_E [inds],
                                "std.distance_to_cut_5to9yo_E" = std.distance_to_cut_5to9yo_E [inds],
                                "std.distance_to_cut_10yoorOver_E" = std.distance_to_cut_10yoorOver_E [inds])

model.lme.fxn.du6.s <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                                 std.distance_to_cut_10yoorOver + std.distance_to_cut_1to4yo_E +
                                 std.distance_to_cut_5to9yo_E + std.distance_to_cut_10yoorOver_E +
                                 std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                 std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                 std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                 (1 | uniqueID), 
                               data = dist.cut.data.du.6.s, 
                               family = binomial (link = "logit"),
                               verbose = T,
                               control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                       optimizer = "nloptwrap", # these settings should provide results quicker
                                                       optCtrl = list (maxfun = 2e5)))
summary (model.lme.fxn.du6.s)
anova (model.lme.fxn.du6.s)
plot (model.lme.fxn.du6.s) # should be mostly a straight line

dist.cut.data.du.6.s$preds.lme.re.fxn <- predict (model.lme.fxn.du6.s, type = 'response') 
dist.cut.data.du.6.s$preds.lme.re.fe.fxn <- predict (model.lme.fxn.du6.s, type = 'response', 
                                                      re.form = NA,
                                                      newdata = dist.cut.data.du.6.s) 
plot (dist.cut.data.du.6.s$distance_to_cut_1to4yo, dist.cut.data.du.6.s$preds.lme.re.fe.fxn) # fixed effect predictions against covariate value
plot (dist.cut.data.du.6.s$std.distance_to_cut_5to9yo, dist.cut.data.du.6.s$preds.lme.re.fe.fxn) 
plot (dist.cut.data.du.6.s$std.distance_to_cut_10yoorOver, dist.cut.data.du.6.s$preds.lme.re.fe.fxn) 
save (model.lme.du6.s, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_lme_fxn_du6_ew.rda")
# sjp.lmer (model.lme.du6.s, type = "pred", vars = "std.distance_to_cut_1to4yo")
# AIC
table.aic [6, 6] <- AIC (model.lme.fxn.du6.s)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.s, type = 'response'), dist.cut.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [6, 8] <- auc.temp@y.values[[1]]

list.aic.like <- c ((exp (-0.5 * (table.aic [5, 6] - min (table.aic [5:6, 6])))), 
                    (exp (-0.5 * (table.aic [6, 6] - min (table.aic [3:4, 6])))))
table.aic [5, 7] <- round ((exp (-0.5 * (table.aic [5, 6] - min (table.aic [5:6, 6])))) / sum (list.aic.like), 3)
table.aic [6, 7] <- round ((exp (-0.5 * (table.aic [6, 6] - min (table.aic [5:6, 6])))) / sum (list.aic.like), 3)
# write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_forestry.csv", sep = ",")

#============================
## DU7 ##
#==============
## Early Winter ##
### Correlation
corr.dist.cut.du.7.ew <- round (cor (dist.cut.data.du.7.ew [10:13], method = "spearman"), 3)
ggcorrplot (corr.dist.cut.du.7.ew, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Distance to Cutblock Correlation DU7 Early Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_dist_cut_corr_du_7_ew.png")

# distance to cutblocks 10 to 29 years old and 30 or over years old were highly correlated
# grouped together
# dist.cut.data.du.7.ew <- dplyr::mutate (dist.cut.data.du.7.ew, distance_to_cut_10yoorOver = pmin (distance_to_cut_10to29yo, distance_to_cut_30orOveryo))

### CART
cart.du.7.ew <- rpart (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                         distance_to_cut_10yoorOver,
                       data = dist.cut.data.du.7.ew, 
                       method = "class")
summary (cart.du.7.ew)
print (cart.du.7.ew)
plot (cart.du.7.ew, uniform = T)
text (cart.du.7.ew, use.n = T, splits = T, fancy = F)
post (cart.du.7.ew, file = "", uniform = T)
# results indicate no partioning, suggesting no effect of cutblocks

### VIF
model.glm.DU7.ew <- glm (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                           distance_to_cut_10yoorOver, 
                         data = dist.cut.data.du.7.ew,
                         family = binomial (link = 'logit'))
vif (model.glm.DU7.ew) 

# Generalized Linear Mixed Models (GLMMs)
# standardize covariates  (helps with model convergence)
dist.cut.data.du.7.ew$std.distance_to_cut_1to4yo <- (dist.cut.data.du.7.ew$distance_to_cut_1to4yo - mean (dist.cut.data.du.7.ew$distance_to_cut_1to4yo)) / sd (dist.cut.data.du.7.ew$distance_to_cut_1to4yo)
dist.cut.data.du.7.ew$std.distance_to_cut_5to9yo <- (dist.cut.data.du.7.ew$distance_to_cut_5to9yo - mean (dist.cut.data.du.7.ew$distance_to_cut_5to9yo)) / sd (dist.cut.data.du.7.ew$distance_to_cut_5to9yo)
dist.cut.data.du.7.ew$std.distance_to_cut_10yoorOver <- (dist.cut.data.du.7.ew$distance_to_cut_10yoorOver - mean (dist.cut.data.du.7.ew$distance_to_cut_10yoorOver)) / sd (dist.cut.data.du.7.ew$distance_to_cut_10yoorOver)

### fit corr random effects model
model.lme.DU7.ew <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                             std.distance_to_cut_10yoorOver + 
                             (std.distance_to_cut_1to4yo | uniqueID) + 
                             (std.distance_to_cut_5to9yo | uniqueID) +
                             (std.distance_to_cut_10yoorOver | uniqueID), 
                           data = dist.cut.data.du.7.ew, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                   optimizer = "nloptwrap", # these settings should provide results quicker
                                                   optCtrl = list (maxfun = 2e5))) # 20,000 iterations)
summary (model.lme.DU7.ew)
anova (model.lme.DU7.ew)
plot (model.lme.DU7.ew) # should be mostly a straight line

dist.cut.data.du.7.ew$preds.lme.re <- predict (model.lme.DU7.ew, type = 'response') 
dist.cut.data.du.7.ew$preds.lme.re.fe <- predict (model.lme.DU7.ew, type = 'response', 
                                                  re.form = NA,
                                                  newdata = dist.cut.data.du.7.ew) 
plot (dist.cut.data.du.7.ew$distance_to_cut_1to4yo, dist.cut.data.du.7.ew$preds.lme.re.fe) # fixed effect predictions against covariate value
plot (dist.cut.data.du.7.ew$std.distance_to_cut_5to9yo, dist.cut.data.du.7.ew$preds.lme.re.fe) 
plot (dist.cut.data.du.7.ew$std.distance_to_cut_10yoorOver, dist.cut.data.du.7.ew$preds.lme.re.fe) 
save (model.lme.DU7.ew, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_lme_DU7_ew.rda")
# sjp.lmer (model.lme.DU7.ew, type = "pred", vars = "std.distance_to_cut_1to4yo")
# AIC
table.aic [7, 6] <- AIC (model.lme.DU7.ew)

# AUC 
pr.temp <- prediction (predict (model.lme.DU7.ew, type = 'response'), dist.cut.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [7, 8] <- auc.temp@y.values[[1]]

### Fit model with functional responses
# Calculating dataframe with covariate expectations
sub <- subset (dist.cut.data.du.7.ew, pttype == 0)
std.distance_to_cut_1to4yo_E <- tapply (sub$std.distance_to_cut_1to4yo, sub$uniqueID, mean)
std.distance_to_cut_5to9yo_E <- tapply (sub$std.distance_to_cut_5to9yo, sub$uniqueID, mean)
std.distance_to_cut_10yoorOver_E <- tapply (sub$std.distance_to_cut_10yoorOver, sub$uniqueID, mean)
inds <- as.character (dist.cut.data.du.7.ew$uniqueID)
dist.cut.data.du.7.ew <- cbind (dist.cut.data.du.7.ew, 
                                "std.distance_to_cut_1to4yo_E" = std.distance_to_cut_1to4yo_E [inds],
                                "std.distance_to_cut_5to9yo_E" = std.distance_to_cut_5to9yo_E [inds],
                                "std.distance_to_cut_10yoorOver_E" = std.distance_to_cut_10yoorOver_E [inds])

model.lme.fxn.DU7.ew <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                                 std.distance_to_cut_10yoorOver + std.distance_to_cut_1to4yo_E +
                                 std.distance_to_cut_5to9yo_E + std.distance_to_cut_10yoorOver_E +
                                 std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                 std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                 std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                 (1 | uniqueID), 
                               data = dist.cut.data.du.7.ew, 
                               family = binomial (link = "logit"),
                               verbose = T,
                               control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                       optimizer = "nloptwrap", # these settings should provide results quicker
                                                       optCtrl = list (maxfun = 2e5)))
summary (model.lme.fxn.DU7.ew)
anova (model.lme.fxn.DU7.ew)
plot (model.lme.fxn.DU7.ew) # should be mostly a straight line

dist.cut.data.du.7.ew$preds.lme.re.fxn <- predict (model.lme.fxn.DU7.ew, type = 'response') 
dist.cut.data.du.7.ew$preds.lme.re.fe.fxn <- predict (model.lme.fxn.DU7.ew, type = 'response', 
                                                      re.form = NA,
                                                      newdata = dist.cut.data.du.7.ew) 
plot (dist.cut.data.du.7.ew$distance_to_cut_1to4yo, dist.cut.data.du.7.ew$preds.lme.re.fe.fxn) # fixed effect predictions against covariate value
plot (dist.cut.data.du.7.ew$distance_to_cut_5to9yo, dist.cut.data.du.7.ew$preds.lme.re.fe.fxn) 
plot (dist.cut.data.du.7.ew$distance_to_cut_10yoorOver, dist.cut.data.du.7.ew$preds.lme.re.fe.fxn) 
save (model.lme.DU7.ew, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_lme_fxn_DU7_ew.rda")
# sjp.lmer (model.lme.DU7.ew, type = "pred", vars = "std.distance_to_cut_1to4yo")
# AIC
table.aic [8, 6] <- AIC (model.lme.fxn.DU7.ew)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.DU7.ew, type = 'response'), dist.cut.data.du.7.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [8, 8] <- auc.temp@y.values[[1]]

list.aic.like <- c ((exp (-0.5 * (table.aic [7, 6] - min (table.aic [7:8, 6])))), 
                    (exp (-0.5 * (table.aic [8, 6] - min (table.aic [7:8, 6])))))
table.aic [7, 7] <- round ((exp (-0.5 * (table.aic [7, 6] - min (table.aic [7:8, 6])))) / sum (list.aic.like), 3)
table.aic [8, 7] <- round ((exp (-0.5 * (table.aic [8, 6] - min (table.aic [7:8, 6])))) / sum (list.aic.like), 3)

# write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_forestry.csv", sep = ",")

#============================================
## Late Winter ##
### Corrletion
corr.dist.cut.du.7.lw <- round (cor (dist.cut.data.du.7.lw [10:13], method = "spearman"), 3)
ggcorrplot (corr.dist.cut.du.7.lw, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Distance to Cutblock Correlation DU7 Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_dist_cut_corr_du_7_lw.png")

# distance to cutblocks 10 to 29 years old and 30 or over years old were highly correlated
# grouped together
dist.cut.data.du.7.lw <- dplyr::mutate (dist.cut.data.du.7.lw, distance_to_cut_5yoorOver = pmin (distance_to_cut_5to9yo, distance_to_cut_10to29yo, distance_to_cut_30orOveryo))

### CART
cart.du.7.lw <- rpart (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5yoorOver,
                       data = dist.cut.data.du.7.lw, 
                       method = "class")
summary (cart.du.7.lw)
print (cart.du.7.lw)
plot (cart.du.7.lw, uniform = T)
text (cart.du.7.lw, use.n = T, splits = T, fancy = F)
post (cart.du.7.lw, file = "", uniform = T)
# results indicate no partioning, suggesting no effect of cutblocks

### VIF
model.glm.DU7.lw <- glm (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5yoorOver, 
                         data = dist.cut.data.du.7.lw,
                         family = binomial (link = 'logit'))
vif (model.glm.DU7.lw) 

# Generalized Linear Mixed Models (GLMMs)
# standardize covariates  (helps with model convergence)
dist.cut.data.du.7.lw$std.distance_to_cut_1to4yo <- (dist.cut.data.du.7.lw$distance_to_cut_1to4yo - mean (dist.cut.data.du.7.lw$distance_to_cut_1to4yo)) / sd (dist.cut.data.du.7.lw$distance_to_cut_1to4yo)
dist.cut.data.du.7.lw$std.distance_to_cut_5yoorOver <- (dist.cut.data.du.7.lw$distance_to_cut_5yoorOver - mean (dist.cut.data.du.7.lw$distance_to_cut_5yoorOver)) / sd (dist.cut.data.du.7.lw$distance_to_cut_5yoorOver)

### fit corr random effects model
model.lme.DU7.lw <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5yoorOver + 
                             (std.distance_to_cut_1to4yo | uniqueID) + 
                             (std.distance_to_cut_5yoorOver | uniqueID) , 
                           data = dist.cut.data.du.7.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                   optimizer = "nloptwrap", # these settings should provide results quicker
                                                   optCtrl = list (maxfun = 2e5))) # 20,000 iterations)
summary (model.lme.DU7.lw)
anova (model.lme.DU7.lw)
plot (model.lme.DU7.lw) # should be mostly a straight line

dist.cut.data.du.7.lw$preds.lme.re <- predict (model.lme.DU7.lw, type = 'response') 
dist.cut.data.du.7.lw$preds.lme.re.fe <- predict (model.lme.DU7.lw, type = 'response', 
                                                  re.form = NA,
                                                  newdata = dist.cut.data.du.7.lw) 
plot (dist.cut.data.du.7.lw$distance_to_cut_1to4yo, dist.cut.data.du.7.lw$preds.lme.re.fe) # fixed effect predictions against covariate value
plot (dist.cut.data.du.7.lw$distance_to_cut_5yoorOver, dist.cut.data.du.7.lw$preds.lme.re.fe) 
save (model.lme.DU7.lw, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_lme_DU7_lw.rda")
# sjp.lmer (model.lme.DU7.lw, type = "pred", vars = "std.distance_to_cut_1to4yo")
# AIC
table.aic [9, 6] <- AIC (model.lme.DU7.lw)

# AUC 
pr.temp <- prediction (predict (model.lme.DU7.lw, type = 'response'), dist.cut.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [9, 8] <- auc.temp@y.values[[1]]

### Fit model with functional responses
# Calculating dataframe with covariate expectations
sub <- subset (dist.cut.data.du.7.lw, pttype == 0)
std.distance_to_cut_1to4yo_E <- tapply (sub$std.distance_to_cut_1to4yo, sub$uniqueID, mean)
std.distance_to_cut_5yoorOver_E <- tapply (sub$std.distance_to_cut_5yoorOver, sub$uniqueID, mean)
inds <- as.character (dist.cut.data.du.7.lw$uniqueID)
dist.cut.data.du.7.lw <- cbind (dist.cut.data.du.7.lw, 
                                "std.distance_to_cut_1to4yo_E" = std.distance_to_cut_1to4yo_E [inds],
                                "std.distance_to_cut_5yoorOver_E" = std.distance_to_cut_5yoorOver_E [inds])

model.lme.fxn.DU7.lw <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5yoorOver + 
                                 std.distance_to_cut_1to4yo_E +std.distance_to_cut_5yoorOver_E + 
                                 std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                 std.distance_to_cut_5yoorOver:std.distance_to_cut_5yoorOver_E +
                                 (1 | uniqueID), 
                               data = dist.cut.data.du.7.lw, 
                               family = binomial (link = "logit"),
                               verbose = T,
                               control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                       optimizer = "nloptwrap", # these settings should provide results quicker
                                                       optCtrl = list (maxfun = 2e5)))
summary (model.lme.fxn.DU7.lw)
anova (model.lme.fxn.DU7.lw)
plot (model.lme.fxn.DU7.lw) # should be mostly a straight line

dist.cut.data.du.7.lw$preds.lme.re.fxn <- predict (model.lme.fxn.DU7.lw, type = 'response') 
dist.cut.data.du.7.lw$preds.lme.re.fe.fxn <- predict (model.lme.fxn.DU7.lw, type = 'response', 
                                                      re.form = NA,
                                                      newdata = dist.cut.data.du.7.lw) 
plot (dist.cut.data.du.7.lw$distance_to_cut_1to4yo, dist.cut.data.du.7.lw$preds.lme.re.fe.fxn) # fixed effect predictions against covariate value
plot (dist.cut.data.du.7.lw$distance_to_cut_5yoorOver, dist.cut.data.du.7.lw$preds.lme.re.fe.fxn) 
save (model.lme.DU7.lw, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_lme_fxn_DU7_ew.rda")
# sjp.lmer (model.lme.DU7.lw, type = "pred", vars = "std.distance_to_cut_1to4yo")
# AIC
table.aic [10, 6] <- AIC (model.lme.fxn.DU7.lw)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.DU7.lw, type = 'response'), dist.cut.data.du.7.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [10, 8] <- auc.temp@y.values[[1]]

list.aic.like <- c ((exp (-0.5 * (table.aic [9, 6] - min (table.aic [9:10, 6])))), 
                    (exp (-0.5 * (table.aic [10, 6] - min (table.aic [9:10, 6])))))
table.aic [9, 7] <- round ((exp (-0.5 * (table.aic [9, 6] - min (table.aic [9:10, 6])))) / sum (list.aic.like), 3)
table.aic [10, 7] <- round ((exp (-0.5 * (table.aic [10, 6] - min (table.aic [9:10, 6])))) / sum (list.aic.like), 3)
# write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_forestry.csv", sep = ",")

#============================================
## Summer ##
### Corrletion
corr.dist.cut.du.7.s <- round (cor (dist.cut.data.du.7.s [10:13], method = "spearman"), 3)
ggcorrplot (corr.dist.cut.du.7.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Distance to Cutblock Correlation DU7 Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_dist_cut_corr_du_7_s.png")

# distance to cutblocks 10 to 29 years old and 30 or over years old were highly correlated
# grouped together
dist.cut.data.du.7.s <- dplyr::mutate (dist.cut.data.du.7.s, distance_to_cut_5yoorOver = pmin (distance_to_cut_5to9yo, distance_to_cut_10to29yo, distance_to_cut_30orOveryo))

### CART
cart.du.7.s <- rpart (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5yoorOver,
                      data = dist.cut.data.du.7.s, 
                      method = "class")
summary (cart.du.7.s)
print (cart.du.7.s)
plot (cart.du.7.s, uniform = T)
text (cart.du.7.s, use.n = T, splits = T, fancy = F)
post (cart.du.7.s, file = "", uniform = T)
# results indicate no partioning, suggesting no effect of cutblocks

### VIF
model.glm.DU7.s <- glm (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5yoorOver, 
                        data = dist.cut.data.du.7.s,
                        family = binomial (link = 'logit'))
vif (model.glm.DU7.s) 

# Generalized Linear Mixed Models (GLMMs)
# standardize covariates  (helps with model convergence)
dist.cut.data.du.7.s$std.distance_to_cut_1to4yo <- (dist.cut.data.du.7.s$distance_to_cut_1to4yo - mean (dist.cut.data.du.7.s$distance_to_cut_1to4yo)) / sd (dist.cut.data.du.7.s$distance_to_cut_1to4yo)
dist.cut.data.du.7.s$std.distance_to_cut_5yoorOver <- (dist.cut.data.du.7.s$distance_to_cut_5yoorOver - mean (dist.cut.data.du.7.s$distance_to_cut_5yoorOver)) / sd (dist.cut.data.du.7.s$distance_to_cut_5yoorOver)

### fit corr random effects model
model.lme.DU7.s <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5yoorOver + 
                            (std.distance_to_cut_1to4yo | uniqueID) + 
                            (std.distance_to_cut_5yoorOver | uniqueID), 
                          data = dist.cut.data.du.7.s, 
                          family = binomial (link = "logit"),
                          verbose = T,
                          control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                  optimizer = "nloptwrap", # these settings should provide results quicker
                                                  optCtrl = list (maxfun = 2e5))) # 20,000 iterations)
summary (model.lme.DU7.s)
anova (model.lme.DU7.s)
plot (model.lme.DU7.s) # should be mostly a straight line

dist.cut.data.du.7.s$preds.lme.re <- predict (model.lme.DU7.s, type = 'response') 
dist.cut.data.du.7.s$preds.lme.re.fe <- predict (model.lme.DU7.s, type = 'response', 
                                                 re.form = NA,
                                                 newdata = dist.cut.data.du.7.s) 
plot (dist.cut.data.du.7.s$distance_to_cut_1to4yo, dist.cut.data.du.7.s$preds.lme.re.fe) # fixed effect predictions against covariate value
plot (dist.cut.data.du.7.s$distance_to_cut_5yoorOver, dist.cut.data.du.7.s$preds.lme.re.fe) 

save (model.lme.DU7.s, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_lme_DU7_s.rda")
# sjp.lmer (model.lme.DU7.s, type = "pred", vars = "std.distance_to_cut_1to4yo")
# AIC
table.aic [5, 6] <- AIC (model.lme.DU7.s)

# AUC 
pr.temp <- prediction (predict (model.lme.DU7.s, type = 'response'), dist.cut.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [5, 8] <- auc.temp@y.values[[1]]

### Fit model with functional responses
# Calculating dataframe with covariate expectations
sub <- subset (dist.cut.data.du.7.s, pttype == 0)
std.distance_to_cut_1to4yo_E <- tapply (sub$std.distance_to_cut_1to4yo, sub$uniqueID, mean)
std.distance_to_cut_5to9yo_E <- tapply (sub$std.distance_to_cut_5to9yo, sub$uniqueID, mean)
std.distance_to_cut_10yoorOver_E <- tapply (sub$std.distance_to_cut_10yoorOver, sub$uniqueID, mean)
inds <- as.character (dist.cut.data.du.7.s$uniqueID)
dist.cut.data.du.7.s <- cbind (dist.cut.data.du.7.s, 
                               "std.distance_to_cut_1to4yo_E" = std.distance_to_cut_1to4yo_E [inds],
                               "std.distance_to_cut_5to9yo_E" = std.distance_to_cut_5to9yo_E [inds],
                               "std.distance_to_cut_10yoorOver_E" = std.distance_to_cut_10yoorOver_E [inds])

model.lme.fxn.DU7.s <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                                std.distance_to_cut_10yoorOver + std.distance_to_cut_1to4yo_E +
                                std.distance_to_cut_5to9yo_E + std.distance_to_cut_10yoorOver_E +
                                std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                (1 | uniqueID), 
                              data = dist.cut.data.du.7.s, 
                              family = binomial (link = "logit"),
                              verbose = T,
                              control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                      optimizer = "nloptwrap", # these settings should provide results quicker
                                                      optCtrl = list (maxfun = 2e5)))
summary (model.lme.fxn.DU7.s)
anova (model.lme.fxn.DU7.s)
plot (model.lme.fxn.DU7.s) # should be mostly a straight line

dist.cut.data.du.7.s$preds.lme.re.fxn <- predict (model.lme.fxn.DU7.s, type = 'response') 
dist.cut.data.du.7.s$preds.lme.re.fe.fxn <- predict (model.lme.fxn.DU7.s, type = 'response', 
                                                     re.form = NA,
                                                     newdata = dist.cut.data.du.7.s) 
plot (dist.cut.data.du.7.s$distance_to_cut_1to4yo, dist.cut.data.du.7.s$preds.lme.re.fe.fxn) # fixed effect predictions against covariate value
plot (dist.cut.data.du.7.s$std.distance_to_cut_5to9yo, dist.cut.data.du.7.s$preds.lme.re.fe.fxn) 
plot (dist.cut.data.du.7.s$std.distance_to_cut_10yoorOver, dist.cut.data.du.7.s$preds.lme.re.fe.fxn) 
save (model.lme.DU7.s, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_lme_fxn_DU7_ew.rda")
# sjp.lmer (model.lme.DU7.s, type = "pred", vars = "std.distance_to_cut_1to4yo")
# AIC
table.aic [6, 6] <- AIC (model.lme.fxn.DU7.s)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.DU7.s, type = 'response'), dist.cut.data.du.7.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [6, 8] <- auc.temp@y.values[[1]]

list.aic.like <- c ((exp (-0.5 * (table.aic [5, 6] - min (table.aic [5:6, 6])))), 
                    (exp (-0.5 * (table.aic [6, 6] - min (table.aic [3:4, 6])))))
table.aic [5, 7] <- round ((exp (-0.5 * (table.aic [5, 6] - min (table.aic [5:6, 6])))) / sum (list.aic.like), 3)
table.aic [6, 7] <- round ((exp (-0.5 * (table.aic [6, 6] - min (table.aic [5:6, 6])))) / sum (list.aic.like), 3)
# write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_forestry.csv", sep = ",")






