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

#=================================
#  Script Name: 02_fire_ignition_analysis.R
#  Script Version: 1.0
#  Script Purpose: Prepare data for provincial analysis of fire ignitions. This includes obtaining weather data from climate BC, vegetation data from the Vegetation Resource inventory, and fire ignitions from Fire Incident Locations hosted on the Data Catalogue
#  Script Author: Elizabeth Kleynhans, Ecological Modeling Specialist, Forest Analysis and Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#=================================


library(sf)
library(tidyverse)
library(ggplot2)
library (ggcorrplot)
library (RPostgreSQL)
library (rpostgis)
library (dplyr)
library (lme4)
library (arm)
library(ggpubr)
library(mgcv)
library(nlme)

source(here::here("R/functions/R_Postgres.R"))

# Import my vegetation, climate and presence/absence of fire data
connKyle <- dbConnect(drv = RPostgreSQL::PostgreSQL(), 
                      host = key_get('dbhost', keyring = 'postgreSQL'),
                      user = key_get('dbuser', keyring = 'postgreSQL'),
                      dbname = key_get('dbname', keyring = 'postgreSQL'),
                      password = key_get('dbpass', keyring = 'postgreSQL'),
                      port = "5432")
fire_veg_data <- sf::st_read  (dsn = connKyle, # connKyle
                               query = "SELECT * FROM public.fire_ignitions_veg_climate")
dbDisconnect (connKyle)

# Import the fire ignition data
conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")
fire_ignitions <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.bc_fire_ignition")
dbDisconnect (conn) # connKyle

fire_ignitions1<-st_set_geometry(fire_ignitions,NULL) # remove geometry column for dataset

# look at histogram of when fires were ignited per year
fire_ignitions1$month<- substring(fire_ignitions1$ign_date, 5, 6)

fire_ignitions1_new<- fire_ignitions1 %>%
  filter(fire_year >=2002)
fire_ignitions1_new$month<- as.numeric(fire_ignitions1_new$month)
hist(fire_ignitions1_new$month) # most fires appear to occur between May - Sept!
table(fire_ignitions1_new$fire_year, fire_ignitions1_new$fire_cause)
table(fire_ignitions1_new$fire_cause)

fire_ignitions2 <- fire_ignitions1_new %>%
  dplyr::select(fire_no, fire_year, fire_cause) %>%
  rename(id1=fire_no,
         year=fire_year)

ignition_pres_abs <- left_join(fire_veg_data, fire_ignitions2)
table(ignition_pres_abs$year, ignition_pres_abs$pttype)

ignition_pres_abs$fire_cause<- as.factor(ignition_pres_abs$fire_cause)
dim(ignition_pres_abs)

ignition_pres_abs$firecause<-0
ignition_pres_abs$firecause[which(is.na(ignition_pres_abs$fire_cause ))]<-"none"
ignition_pres_abs$firecause[which(ignition_pres_abs$fire_cause=="Person")]<-"Person"
ignition_pres_abs$firecause[which(ignition_pres_abs$fire_cause=="Lightning")]<-"Lightning"
ignition_pres_abs$firecause[which(ignition_pres_abs$fire_cause=="Unknown")]<-"Unknown"
table(ignition_pres_abs$firecause)

# pulling out locations where cause of fire is due to lightning. 
ignition_pres_abs1<- ignition_pres_abs %>%
  filter(firecause!="Person") 
ignition_pres_abs1<- ignition_pres_abs1 %>%
  filter(firecause!="Unknown") 
dim(ignition_pres_abs1)
table(ignition_pres_abs1$year, ignition_pres_abs1$pttype)

ignition_pres_abs1$allppt05<- ignition_pres_abs1$ppt05+ignition_pres_abs1$pas05/10
ignition_pres_abs1$allppt06<- ignition_pres_abs1$ppt06+ignition_pres_abs1$pas06/10
ignition_pres_abs1$allppt07<- ignition_pres_abs1$ppt07+ignition_pres_abs1$pas07/10
ignition_pres_abs1$allppt08<- ignition_pres_abs1$ppt08+ignition_pres_abs1$pas08/10
ignition_pres_abs1$allppt09<- ignition_pres_abs1$ppt09+ignition_pres_abs1$pas09/10


# ignition_pres_abs1 is the final dataset
##################
#### FIGURES ####
##################

# Plotting Probability of ignition versus drought code. Seems like similar trends are found in each month (June to August) but trend seems to get stronger in later months i.e. July and August.

p <- ggplot(ignition_pres_abs1, aes(mdc_08, as.numeric(pttype))) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("August MDC") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ year, nrow=3)

pdf("C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\Figures\\MDC08_allYears_gam.pdf")
print(p2)
dev.off()

p <- ggplot(ignition_pres_abs1, aes(mdc_08, as.numeric(pttype))) +
  stat_smooth(method="glm", formula=y~x,
              alpha=0.2, size=2) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("August MDC") + ylab("Pr (ignition)")

# Rainfall
p <- ggplot(ignition_pres_abs1, aes(allppt08, as.numeric(pttype))) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("All ppt in Aug") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ year, nrow=3)

pdf("C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\Figures\\PPT08_allYears_gam.pdf")
print(p2)
dev.off()

# Log precipitation
p <- ggplot(ignition_pres_abs1, aes(log(allppt08 + 0.0001), as.numeric(pttype))) +
  stat_smooth(method="glm", formula=y~x,
              alpha=0.2, size=2) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("Log of All ppt in Aug") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ year, nrow=3)

pdf("C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\Figures\\Log_PPT08_allYears.pdf")
print(p2)
dev.off()


# Temperature
p <- ggplot(ignition_pres_abs1, aes(tmax08, as.numeric(pttype))) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("tmax08") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ year, nrow=3)

pdf("C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\Figures\\tmax08_allYears_gam.pdf")
print(p2)
dev.off()

# Average Temperature
p <- ggplot(ignition_pres_abs1, aes(tave08, as.numeric(pttype))) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("tmax08") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ year, nrow=3)

pdf("C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\Figures\\tave08_allYears_gam.pdf")
print(p2)
dev.off()



##################
#### Analysis ####
##################

# To select the best single fire weather covariate I first conducted exploratory graphical analyses of the correlations between fire frequency and various fire weather variables. Then I fit generalized linear models for each fire weather variable (Eq. 1) using a binomial error structure with logarithmic link. Candidate variables were monthly average temperature, monthly maximum temperature, monthly precipitations and the six MDC’s. I also added various two, three or fourth-month means of these values (e.g. for May, June, July and August) to test for seasonal effects (e.g. spring vs. summer).

names(ignition_pres_abs1)

# correlation between max T and MDC. Some things are a little correlated i.e. tmax08 and mdc09 are relatively correlated (0.73) which makes sense since MDC is calculated with max T.
dist.cut.corr <- st_set_geometry(ignition_pres_abs1 [c (15:19, 35:39)], NULL)
corr <- round (cor (dist.cut.corr), 3)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Correlation between maximum temperature and MDC")

# correlation between all precipitation and MDC. MDC is less correlated with precipitation, although MDC07 and precipitation 07 are still fairly correlated i.e. 0.69
dist.cut.corr <- st_set_geometry(ignition_pres_abs1 [c (35:39, 43:47)], NULL)
corr <- round (cor (dist.cut.corr), 3)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Correlation between all precipitation (snow + rain) and MDC")

# Correlation between Tmax and all precipitation. These are not hightly correlated at all. Highest correlation is -0.42
dist.cut.corr <- st_set_geometry(ignition_pres_abs1 [c (15:19, 43:47)], NULL)
corr <- round (cor (dist.cut.corr), 3)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "DU8 Distance to Cutblock Correlation")

# Correlation between Tave and MDC. less correlated than Tmax. Most correlated is 0.65 for Tave07 and mdc_08
dist.cut.corr <- st_set_geometry(ignition_pres_abs1 [c (20:24, 35:39)], NULL)
corr <- round (cor (dist.cut.corr), 3)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "DU8 Distance to Cutblock Correlation")

# Correlation between Tave and allPrecipitation. Hardly correlated at all most correlated is tave07 wih allppt07  is -0.33
dist.cut.corr <- st_set_geometry(ignition_pres_abs1 [c (20:24, 43:47)], NULL)
corr <- round (cor (dist.cut.corr), 3)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "DU8 Distance to Cutblock Correlation")

ignition_pres_abs2<- st_set_geometry(ignition_pres_abs1, NULL)


######################################################################
#### Generation AIC tables to select best environmental predictors####
######################################################################
# creating amalgamations of variables
ignition_pres_abs2$mean_tmax06_tmax07<- (ignition_pres_abs2$tmax06+ ignition_pres_abs2$tmax07)/2
ignition_pres_abs2$mean_tmax07_tmax08<- (ignition_pres_abs2$tmax07+ ignition_pres_abs2$tmax08)/2
ignition_pres_abs2$mean_tmax08_tmax09<- (ignition_pres_abs2$tmax08+ ignition_pres_abs2$tmax09)/2
ignition_pres_abs2$mean_tmax06_tmax07_tmax08<- (ignition_pres_abs2$tmax06+ ignition_pres_abs2$tmax07 + ignition_pres_abs2$tmax08)/3
ignition_pres_abs2$mean_tmax07_tmax08_tmax09<- (ignition_pres_abs2$tmax07+ ignition_pres_abs2$tmax08 + ignition_pres_abs2$tmax09)/3
ignition_pres_abs2$mean_tmax06_tmax07_tmax08_tmax09<- (ignition_pres_abs2$tmax06 + ignition_pres_abs2$tmax07+ ignition_pres_abs2$tmax08 + ignition_pres_abs2$tmax09)/4

ignition_pres_abs2$mean_tave06_tave07<- (ignition_pres_abs2$tave06+ ignition_pres_abs2$tave07)/2
ignition_pres_abs2$mean_tave07_tave08<- (ignition_pres_abs2$tave07+ ignition_pres_abs2$tave08)/2
ignition_pres_abs2$mean_tave08_tave09<- (ignition_pres_abs2$tave08+ ignition_pres_abs2$tave09)/2
ignition_pres_abs2$mean_tave06_tave07_tave08<- (ignition_pres_abs2$tave06+ ignition_pres_abs2$tave07 + ignition_pres_abs2$tave08)/3
ignition_pres_abs2$mean_tave07_tave08_tave09<- (ignition_pres_abs2$tave07+ ignition_pres_abs2$tave08 + ignition_pres_abs2$tave09)/3
ignition_pres_abs2$mean_tave06_tave07_tave08_tave09<- (ignition_pres_abs2$tave06 + ignition_pres_abs2$tave07+ ignition_pres_abs2$tave08 + ignition_pres_abs2$tave09)/4

ignition_pres_abs2$mean_ppt06_ppt07<- (ignition_pres_abs2$ppt06+ ignition_pres_abs2$ppt07)/2
ignition_pres_abs2$mean_ppt07_ppt08<- (ignition_pres_abs2$ppt07+ ignition_pres_abs2$ppt08)/2
ignition_pres_abs2$mean_ppt08_ppt09<- (ignition_pres_abs2$ppt08+ ignition_pres_abs2$ppt09)/2
ignition_pres_abs2$mean_ppt06_ppt07_ppt08<- (ignition_pres_abs2$ppt06+ ignition_pres_abs2$ppt07 + ignition_pres_abs2$ppt08)/3
ignition_pres_abs2$mean_ppt07_ppt08_ppt09<- (ignition_pres_abs2$ppt07+ ignition_pres_abs2$ppt08 + ignition_pres_abs2$ppt09)/3
ignition_pres_abs2$mean_ppt06_ppt07_ppt08_ppt09<- (ignition_pres_abs2$ppt06+ ignition_pres_abs2$ppt07 + ignition_pres_abs2$ppt08 + ignition_pres_abs2$ppt09)/4

ignition_pres_abs2$mean_mdc06_mdc07<- (ignition_pres_abs2$mdc_06+ ignition_pres_abs2$mdc_07)/2
ignition_pres_abs2$mean_mdc07_mdc08<- (ignition_pres_abs2$mdc_07+ ignition_pres_abs2$mdc_08)/2
ignition_pres_abs2$mean_mdc08_mdc09<- (ignition_pres_abs2$mdc_08+ ignition_pres_abs2$mdc_09)/2
ignition_pres_abs2$mean_mdc06_mdc07_mdc08<- (ignition_pres_abs2$mdc_06+ ignition_pres_abs2$mdc_07 + ignition_pres_abs2$mdc_08)/3
ignition_pres_abs2$mean_mdc07_mdc08_mdc09<- (ignition_pres_abs2$mdc_07+ ignition_pres_abs2$mdc_08 + ignition_pres_abs2$mdc_09)/3
ignition_pres_abs2$mean_mdc06_mdc07_mdc08_mdc09<- (ignition_pres_abs2$mdc_06+ ignition_pres_abs2$mdc_07 + ignition_pres_abs2$mdc_08 + ignition_pres_abs2$mdc_09)/4

ignition_pres_abs2 <- ignition_pres_abs2 %>% 
  filter(firecause!="Unknown")
dim(ignition_pres_abs2)

variables<- c("tmax06", "tmax07", "tmax08", "tmax09", "mean_tmax06_tmax07", "mean_tmax07_tmax08", "mean_tmax08_tmax09", "mean_tmax06_tmax07_tmax08","mean_tmax07_tmax08_tmax09" , "mean_tmax06_tmax07_tmax08_tmax09", "tave06", "tave07", "tave08", "tave09", "mean_tave06_tave07", "mean_tave07_tave08", "mean_tave08_tave09", "mean_tave06_tave07_tave08", "mean_tave07_tave08_tave09", "mean_tave06_tave07_tave08_tave09","ppt06", "ppt07", "ppt08", "ppt09", "mean_ppt06_ppt07", "mean_ppt07_ppt08", "mean_ppt08_ppt09", "mean_ppt06_ppt07_ppt08", "mean_ppt07_ppt08_ppt09", "mean_ppt06_ppt07_ppt08_ppt09","mdc_06", "mdc_07", "mdc_08", "mdc_09", "mean_mdc06_mdc07", "mean_mdc07_mdc08", "mean_mdc08_mdc09", "mean_mdc06_mdc07_mdc08", "mean_mdc07_mdc08_mdc09", "mean_mdc06_mdc07_mdc08_mdc09")

variables1<-c("tmax06", "tmax07", "tmax08", "tmax09", "tave06", "tave07", "tave08", "tave09", "tave06", "tave07", "tave08", "tave09")
variables2<-c("ppt06", "ppt07", "ppt08", "ppt09", "ppt06", "ppt07", "ppt08", "ppt09", "mdc_06", "mdc_07", "mdc_08", "mdc_09")
              
              
#Create frame of AIC table
# summary table
table.glm.climate <- data.frame (matrix (ncol = 2, nrow = 0))
colnames (table.glm.climate) <- c ("Variable", "AIC")

# Creates AIC table with a model that that allows slope and intercept to vary
for (i in 1: length(variables)){
  print(i)
model1 <- glmer (ignition_pres_abs2$pttype ~ ignition_pres_abs2[, variables[i]] +
                   ignition_pres_abs2[, variables[i]]||ignition_pres_abs2$year,
                 family = binomial (link = "logit"),
                 verbose = TRUE)

table.glm.climate[i,1]<-variables[i]
table.glm.climate[i,2]<-extractAIC(model1)[2]
}

# This is an addition to the table above allowing combinations of temperature and precipitation

for (i in 1: length(variables1)){
  print(i)
  model2 <- glmer (ignition_pres_abs2$pttype ~ ignition_pres_abs2[, variables1[i]] + ignition_pres_abs2[, variables2[i]] +
                     (ignition_pres_abs2[, variables1[i]] + ignition_pres_abs2[, variables2[i]])||ignition_pres_abs2$year,
                   family = binomial (link = "logit"),
                   verbose = TRUE)

  table.glm.climate[(i+length(variables)),1]<-paste0(variables1[i],"+", variables2[i])
  table.glm.climate[(i+length(variables)),2]<-extractAIC(model2)[2]
}

for (i in 1: length(variables1)){
  print(i)
  model2 <- glmer (ignition_pres_abs2$pttype ~ ignition_pres_abs2[, variables1[i]] + ignition_pres_abs2[, variables2[i]] *
                     (ignition_pres_abs2[, variables1[i]] + ignition_pres_abs2[, variables2[i]])||ignition_pres_abs2$year,
                   family = binomial (link = "logit"),
                   verbose = TRUE)
  
  table.glm.climate[(i+length(variables) +length(variables1)),1]<-paste0(variables1[i],"X", variables2[i])
  table.glm.climate[(i+length(variables) +length(variables1)),2]<-extractAIC(model2)[2]
}

table.glm.climate$deltaAIC<-table.glm.climate$AIC- min(table.glm.climate$AIC)

# Trying with simpler model of varying intecept only for year. Odd thing is this model seems to run more slowly
table.glm.climate_simple <- data.frame (matrix (ncol = 2, nrow = 0))
colnames (table.glm.climate_simple) <- c ("Variable", "AIC")
for (i in 1: length(variables)){
  print(i)
  model3 <- glmer (ignition_pres_abs2$pttype ~ ignition_pres_abs2[, variables[i]] +
                     1|ignition_pres_abs2$year,
                   family = binomial (link = "logit"), 
                   nAGQ=0,
                   control=glmerControl(optimizer = "nloptwrap"))
  
  table.glm.climate_simple[i,1]<-variables[i]
  table.glm.climate_simple[i,2]<-extractAIC(model3)[2]
}



for (i in 1: length(variables1)){
  print(i)
  model4 <- glmer (ignition_pres_abs2$pttype ~ ignition_pres_abs2[, variables1[i]] +
                     ignition_pres_abs2[, variables2[i]] + 
                     1|ignition_pres_abs2$year,
                   family = binomial (link = "logit"), 
                   nAGQ=0,
                   control=glmerControl(optimizer = "nloptwrap"))
  
  table.glm.climate_simple[(i + length(variables)),1]<-paste0(variables1[i], "_",variables2[i])
  table.glm.climate_simple[(i + length(variables)),2]<-extractAIC(model4)[2]
}

table.glm.climate_simple$deltaAIC<-table.glm.climate_simple$AIC- min(table.glm.climate_simple$AIC)

##############################################################
# Trying with simplest model of no random effects only fixed effects. 

table.glm.climate_simplest <- data.frame (matrix (ncol = 2, nrow = 0))
colnames (table.glm.climate_simplest) <- c ("Variable", "AIC")
for (i in 1: length(variables)){
  print(i)
  model3 <- glm (ignition_pres_abs2$pttype ~ ignition_pres_abs2[, variables[i]] + ignition_pres_abs2$year,
                   family = binomial (link = "logit"))
  
  table.glm.climate_simplest[i,1]<-variables[i]
  table.glm.climate_simplest[i,2]<-extractAIC(model3)[2]
}



for (i in 1: length(variables1)){
  print(i)
  model4 <- glm (ignition_pres_abs2$pttype ~ 
                   ignition_pres_abs2[, variables1[i]] +
                     ignition_pres_abs2[, variables2[i]] +
                     ignition_pres_abs2$year,
                   family = binomial (link = "logit"))
  
  table.glm.climate_simplest[(i + length(variables)),1]<-paste0(variables1[i], "+",variables2[i])
  table.glm.climate_simplest[(i + length(variables)),2]<-extractAIC(model4)[2]
}

for (i in 1: length(variables1)){
  print(i)
  model4 <- glm (ignition_pres_abs2$pttype ~ 
                   ignition_pres_abs2[, variables1[i]] *
                   ignition_pres_abs2[, variables2[i]] +
                   ignition_pres_abs2$year,
                 family = binomial (link = "logit"))
  
  table.glm.climate_simplest[(i + length(variables) + length(variables1)),1]<-paste0(variables1[i], "*",variables2[i])
  table.glm.climate_simplest[(i + length(variables) + length(variables1)),2]<-extractAIC(model4)[2]
}

model4 <- glm (ignition_pres_abs2$pttype ~
                 ignition_pres_abs2$year,
               family = binomial (link = "logit"))

table.glm.climate_simplest[65,1]<-paste0("Year only")
table.glm.climate_simplest[65,2]<-extractAIC(model4)[2]

table.glm.climate_simplest$deltaAIC<-table.glm.climate_simplest$AIC- min(table.glm.climate_simplest$AIC)

# Model with lowest AIC has tmax08 * ppt08


###############################################################

# From the above analysis it seems the best combination of variables is the maximum temperature in August + the total precipitation in August.

plot(ignition_pres_abs2$tmax08, ignition_pres_abs2$allppt08)


# assembling landscape variables 

names(ignition_pres_abs2)

# remove points that landed on water (obviously ignitions will not start there)
ignition_pres_abs3 <-ignition_pres_abs2 %>%
  filter(bclcs_level_2!="W") %>%
  filter(bclcs_level_2!=" ")

#Creating new variable of vegetation type and a description of how open the vegetation is
# TB =  Treed broadleaf, TC = Treed Conifer, TM = Treed mixed, SL = short shrub, ST = tall shrubs, D = disturbed, O = open
ignition_pres_abs3$bclcs_level_4<- as.factor(ignition_pres_abs3$bclcs_level_4)
ignition_pres_abs3$bclcs_level_5<- as.factor(ignition_pres_abs3$bclcs_level_5)
ignition_pres_abs3$proj_age_1<- as.numeric(ignition_pres_abs3$proj_age_1)

ignition_pres_abs3$vegtype<-"OP"
ignition_pres_abs3 <- ignition_pres_abs3 %>%
  mutate(vegtype = if_else(bclcs_level_4=="TC","TC",
                       if_else(bclcs_level_4=="TM", "TM",
                               if_else(bclcs_level_4== "TB","TB",
                                       if_else(bclcs_level_4=="SL", "SL",
                                               if_else(bclcs_level_4=="ST", "ST", vegtype))))))
ignition_pres_abs3$vegtype[which(ignition_pres_abs3$proj_age_1 <16)]<-"D"

table(ignition_pres_abs3$vegtype)

unique(ignition_pres_abs3$bclcs_level_5)

ignition_pres_abs3$veg_openess<- "NA"
ignition_pres_abs3<- ignition_pres_abs3 %>%
  mutate(veg_openess = if_else(bclcs_level_5 == "DE", 'DE',
                               if_else(bclcs_level_5 == "OP", "OP",
                                       if_else(bclcs_level_5 == "SP", "SP", "NA"))))
ignition_pres_abs3$veg_openess[which(ignition_pres_abs3$vegtype == "0")]<-"0"
table(ignition_pres_abs3$veg_openess)

# whats the relationship between vegetation type and probabilty of ignition

# plot lines of probability of ignition versus maximum temperature in August with different colours for each year, according to each vegetation type.

p <- ggplot(ignition_pres_abs3, aes(tmax08, as.numeric(pttype), color=year)) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  scale_x_continuous(limits = c(10,32)) +
  xlab("Maximum Temperature in August") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ vegtype, nrow=3)

pdf("C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\Figures\\tmax08_allYears_by_vegType_gam.pdf")
print(p2)
dev.off()

# same plot as above but for precipitation
p <- ggplot(ignition_pres_abs3, aes(allppt08, as.numeric(pttype), color=year)) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.01, width=0)) +
  scale_x_continuous(limits = c(0,500)) +
  xlab("Total precipitation in August") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ vegtype, nrow=3)

pdf("C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\Figures\\ppt08_allYears_by_vegType_loess.pdf")
print(p2)
dev.off()

# Whats the impact of vegetation density?
x<- ignition_pres_abs3 %>%
  drop_na(veg_openess) %>%
  filter(veg_openess!="NA")

p <- ggplot(x, aes(tmax08, as.numeric(pttype), color=year)) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("Maximum Temperature in August") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ veg_openess, nrow=3)

pdf("C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\Figures\\tmax08_allYears_by_vegOpenenss_loess.pdf")
print(p2)
dev.off()

p1<-ggplot (ignition_pres_abs3, aes (x = as.factor(pttype), y = tmax08)) +
  geom_boxplot (outlier.colour = "red") +
  labs (x = "Probability of ignition",
        y = "Max Temp in Aug") +
  facet_grid (. ~ vegtype, scales='free_x', space='free_x') +
  theme (strip.text.x = element_text (size = 8),
         plot.title = element_text (size = 12))

# Observations from plots. It does not look like including vegetation density has much impact. So ill leave it out of the model. the other think I observe is that Open landscapes and landscapes with short shrubs seem to respond in much the same way to the probability of ignition so Im going to lump those two categories as well.
ignition_pres_abs3$vegtype<-as.character(ignition_pres_abs3$vegtype)

ignition_pres_abs3 <- ignition_pres_abs3 %>%
  mutate(vegtype2=if_else(vegtype=="SL", "OP", vegtype))
table(ignition_pres_abs3$vegtype)
table(ignition_pres_abs3$vegtype2)

# what happens is if I bin rainfall. What I want to see is if there is an interaction between rainfall and temperature on the probability of ignition. If there is an interaction
names(ignition_pres_abs3)
summary(ignition_pres_abs3$allppt08)

tags <- c("(0 - 32)", "(32-65)", "(65-82)", "(82 - 1428)")

v <- ignition_pres_abs3 %>% 
  mutate(precip_class = case_when(
    allppt08 < 32 ~ tags[1],
    allppt08 >= 32 & allppt08 < 64 ~ tags[2],
    allppt08 >= 64 & allppt08 < 82 ~ tags[3],
    allppt08 >=82 ~ tags[4]))
v$precip_class <- factor(v$precip_class,
                     levels = tags,
                     ordered = FALSE)
summary(v$precip_class)

low<-v %>% filter(precip_class == "(0 - 32)")
med<-v %>% filter(precip_class == "(32-65)")
high<-v %>% filter(precip_class == "(65-82)")
v.high<-v %>% filter(precip_class == "(82 - 1428)")

# I tried plotting this with loess but it crashes R, so I gave up. glm shows the general trend. It seems that the probability of ignition increases after 20C regardless of how much rain there is except that the line gets shallower with more rain.
p1 <- ggplot(low, aes(tmax08, as.numeric(pttype))) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.01, width=0)) +
  xlab("Maximum Temperature in August") + ylab("Pr (ignition) with low precipitation (0 - 32mm)")

p2 <- ggplot(med, aes(tmax08, as.numeric(pttype))) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.01, width=0)) +
  xlab("Maximum Temperature in August") + ylab("Pr (ignition) with med precipitation (32-65mm)")

p3 <- ggplot(high, aes(tmax08, as.numeric(pttype))) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.01, width=0)) +
  xlab("Maximum Temperature in August") + ylab("Pr (ignition) with high precipitation ((65-82)mm)")

p4 <- ggplot(v.high, aes(tmax08, as.numeric(pttype))) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.01, width=0)) +
  xlab("Maximum Temperature in August") + ylab("Pr (ignition) with v.high precipitation (82 - 1428mm)")


figure <- ggarrange(p1, p2, p3, p4,
                    labels = c("A", "B", "C", "D"),
                    ncol = 2, nrow = 2)

pdf("C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\Figures\\binned_rainfall_and_tmax_gam_separate.pdf")
print(figure)
dev.off()

p1 <- ggplot(low, aes(tmax08, as.numeric(pttype))) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.01, width=0)) +
  xlab("Maximum Temperature in August") + ylab("Pr (ignition) with low precipitation (0 - 32mm)")


# How many NA's are there and remove them.
sum(is.na(ignition_pres_abs3$vegtype))
ignition_pres_abs3<- ignition_pres_abs3 %>% drop_na(vegtype)

ignition_pres_abs3<- st_set_geometry(ignition_pres_abs3, NULL)
ignition_pres_abs3$vegtype2 <-as.factor(ignition_pres_abs3$vegtype2)
ignition_pres_abs3$veg_openess <-as.factor(ignition_pres_abs3$veg_openess)
ignition_pres_abs3$year<-as.factor(ignition_pres_abs3$year)
str(levels(ignition_pres_abs3$year))

# now run the model on this dataset
Zeros<- ignition_pres_abs3 %>% filter(pttype==0)
Ones<- ignition_pres_abs3 %>% filter(pttype==1)
Zeros<-Zeros[sample(nrow(Zeros), size = 10000, replace= FALSE), ]
dat<- rbind(Zeros, Ones)


library(mgcv)

# start simple
glm1<- glm(pttype ~tmax08 +
             allppt08, 
           data= dat,
           family = binomial,
           na.action=na.omit)
summary(glm1)

table.glm <- data.frame (matrix (ncol = 4, nrow = 0))
colnames (table.glm) <- c ("Model", "Variable", "AIC","adjusted R sqr")
table.glm[1,1]<-"glm1"
table.glm[1,2]<-"tmax08 + allppt08"
table.glm[1,3]<-AIC(glm1)
table.glm[1,4]<-summary(glm1)$adj.r.squared
binnedplot (fitted(glm1), 
            residuals(glm1), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm1", 
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")



glm2<- glm(pttype ~tmax08 *
             allppt08, 
           data= dat,
           family = binomial,
           na.action=na.omit)
summary(glm2)
table.glm[2,1]<-"glm2"
table.glm[2,2]<-"tmax08 * allppt08"
table.glm[2,3]<-AIC(glm2)
table.glm[2,4]<-summary(glm2)$adj.r.squared
binnedplot (fitted(glm2), 
            residuals(glm2), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm2", 
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

glm3<- glm(pttype ~year, 
           data= dat,
           family = binomial,
           na.action=na.omit)
summary(glm3)
i=3
table.glm[i,1]<-"glm3"
table.glm[i,2]<-"year"
table.glm[i,3]<-AIC(glm3)
table.glm[i,4]<-summary(glm3)$adj.r.squared
binnedplot (fitted(glm3), 
            residuals(glm3), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm2", 
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

glm4<- glm(pttype ~tave08 * mdc_08, 
           data= dat,
           family = binomial,
           na.action=na.omit)
summary(glm4)
i=4
table.glm[i,1]<-"glm4"
table.glm[i,2]<-"tave08 * mdc08"
table.glm[i,3]<-AIC(glm4)
table.glm[i,4]<-summary(glm4)$adj.r.squared
binnedplot (fitted(glm4), 
            residuals(glm4), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm2", 
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

glmer5<- glmer(pttype ~scale(tave08) * scale(mdc_08) + (1|year), 
           data= dat,
           family = binomial,
           na.action=na.omit)
summary(glmer5)
i=5
table.glm[i,1]<-"glmer5"
table.glm[i,2]<-"scale(tave08) * scale(mdc08)"
table.glm[i,3]<-AIC(glmer5)
table.glm[i,4]<-summary(glmer5)$adj.r.squared
binnedplot (fitted(glmer5), 
            residuals(glmer5), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm2", 
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

glmer6<- glmer(pttype ~scale(tmax08) * scale(allppt08) + (1|year), 
               data= dat,
               family = binomial,
               na.action=na.omit)
summary(glmer6)
i=6
table.glm[i,1]<-"glmer6"
table.glm[i,2]<-"scale(tmax08) * scale(allppt08)"
table.glm[i,3]<-AIC(glmer6)
table.glm[i,4]<-summary(glmer6)$adj.r.squared
binnedplot (fitted(glmer6), 
            residuals(glmer6), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm6", 
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

glmer7<- glmer(pttype ~scale(tmax08) * scale(allppt08) + vegtype2 + (1|year), 
               data= dat,
               family = binomial,
               na.action=na.omit)
summary(glmer7)
i=7
table.glm[i,1]<-"glmer7"
table.glm[i,2]<-"scale(tmax08) * scale(allppt08)"
table.glm[i,3]<-AIC(glmer7)
table.glm[i,4]<-summary(glmer7)$adj.r.squared
binnedplot (fitted(glmer7), 
            residuals(glmer7), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm7", 
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

glmer8<- glmer(pttype ~(tmax08) * (allppt08) + vegtype2 + (1|year) + (vegtype2|year), 
               data= dat,
               family = binomial,
               na.action=na.omit,
               verbose=TRUE)
summary(glmer8)
i=8
table.glm[i,1]<-"glmer8"
table.glm[i,2]<-"scale(tmax08) * scale(allppt08) + vegtype+1|year + vegtype|year"
table.glm[i,3]<-AIC(glmer8)
table.glm[i,4]<-summary(glmer8)$adj.r.squared
binnedplot (fitted(glmer8), 
            residuals(glmer8), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glmer8", 
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

glmer9<- glmer(pttype ~scale(tmax08) * scale(allppt08) + vegtype2 + (1|year) + (tmax08|year), 
               data= dat,
               family = binomial,
               na.action=na.omit,
               verbose=TRUE)
summary(glmer9)
i=9
table.glm[i,1]<-"glmer9"
table.glm[i,2]<-"scale(tmax08) * scale(allppt08) + vegtype2 + (1|year) + (tmax08|year)"
table.glm[i,3]<-AIC(glmer9)
table.glm[i,4]<-summary(glmer9)$adj.r.squared
binnedplot (fitted(glmer9), 
            residuals(glmer9), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glmer9", 
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")



bam2<- bam(pttype ~tmax08 +
             allppt08 +
             tmax08:allppt08, 
           data= ignition_pres_abs3,
           family = binomial,
           na.action=na.omit,
           discrete = TRUE)
summary(bam2)

table.bam[2,1]<-"tmax08 : allppt08"
table.bam[2,2]<-AIC(bam2)
table.bam[2,3]<-summary(bam2)$sp.criterion
table.bam[2,4]<-summary(bam2)$r.sq

bam3<- bam(pttype ~tmax08 +
             allppt08 +
             vegtype2, 
           data= ignition_pres_abs3,
           family = binomial,
           na.action=na.omit,
           discrete = TRUE)
summary(bam3)

table.bam[3,1]<-"tmax08+allppt08+vegtype"
table.bam[3,2]<-AIC(bam3)
table.bam[3,3]<-summary(bam3)$sp.criterion
table.bam[3,4]<-summary(bam3)$r.sq

bam4<- bam(pttype ~tmax08:allppt08 +
             vegtype2, 
           data= ignition_pres_abs3,
           family = binomial,
           na.action=na.omit,
           discrete = TRUE)
summary(bam4)

table.bam[4,1]<-"tmax08:allppt08+vegtype"
table.bam[4,2]<-AIC(bam4)
table.bam[4,3]<-summary(bam4)$sp.criterion
table.bam[4,4]<-summary(bam4)$r.sq

bam5<- bam(pttype ~tmax08:allppt08 +
             veg_openess, 
           data= ignition_pres_abs3,
           family = binomial,
           na.action=na.omit,
           discrete = TRUE)
summary(bam5)

table.bam[5,1]<-"tmax08:allppt08+vegopeness"
table.bam[5,2]<-AIC(bam5)
table.bam[5,3]<-summary(v)$sp.criterion
table.bam[5,4]<-summary(bam5)$r.sq

bam6<- bam(pttype ~tmax08:allppt08 +
             s(year, bs="re"), 
           data= ignition_pres_abs3,
           family = binomial,
           na.action=na.omit,
           discrete = TRUE)
summary(bam6)

table.bam[6,1]<-"tmax08:allppt08+s(year, bs=re)"
table.bam[6,2]<-AIC(bam6)
table.bam[6,3]<-summary(bam6)$sp.criterion
table.bam[6,4]<-summary(bam6)$r.sq

bam7<- bam(pttype ~tmax08:allppt08 +
             s(vegtype2, bs="re"), 
           data= ignition_pres_abs3,
           family = binomial,
           na.action=na.omit,
           discrete = TRUE)
summary(bam7)

table.bam[7,1]<-"tmax08:allppt08+s(vegtype, bs=re)"
table.bam[7,2]<-AIC(bam7)
table.bam[7,3]<-summary(bam7)$sp.criterion
table.bam[7,4]<-summary(bam7)$r.sq

bam8<- bam(pttype ~te(tmax08, allppt08), 
           data= ignition_pres_abs3,
           family = binomial,
           na.action=na.omit,
           discrete = TRUE)
summary(bam8)

table.bam[8,1]<-"te(tmax08, allppt08)"
table.bam[8,2]<-AIC(bam8)
table.bam[8,3]<-summary(bam8)$sp.criterion
table.bam[8,4]<-summary(bam8)$r.sq

bam9<- bam(pttype ~te(tmax08, allppt08) + vegtype2, 
           data= ignition_pres_abs3,
           family = binomial,
           na.action=na.omit,
           discrete = TRUE)
summary(bam9)

table.bam[9,1]<-"te(tmax08, allppt08) + vegtype2"
table.bam[9,2]<-AIC(bam9)
table.bam[9,3]<-summary(bam9)$sp.criterion
table.bam[9,4]<-summary(bam9)$r.sq

bam10<- bam(pttype ~te(tmax08, allppt08) +
              vegtype2 + 
              s(year, bs="re"), 
           data= ignition_pres_abs3,
           family = binomial,
           na.action=na.omit,
           discrete = TRUE)
summary(bam10)

table.bam[10,1]<-"te(tmax08, allppt08)+vegtype2+s(year,bs=re)"
table.bam[10,2]<-AIC(bam10)
table.bam[10,3]<-summary(bam10)$sp.criterion
table.bam[10,4]<-summary(bam10)$r.sq

bam11<- bam(pttype ~te(tmax08, allppt08) +
              vegtype2 + 
              s(year, bs="re") +
              s(vegtype2, year, bs="re"), 
            data= ignition_pres_abs3,
            family = binomial,
            na.action=na.omit,
            discrete = TRUE)
summary(bam11)

table.bam[11,1]<-"te(tmax08, allppt08)+vegtype2+s(year,bs=re)+s(vegtype2,year,bs=re)"
table.bam[11,2]<-AIC(bam1)
table.bam[11,3]<-summary(bam11)$sp.criterion
table.bam[11,4]<-summary(bam11)$r.sq


bam12<- bam(pttype ~tmax08 + 
              allppt08 +
              tmax08:allppt08 +
              vegtype2 + 
              s(year, bs="re"), 
            data= ignition_pres_abs3,
            family = binomial,
            na.action=na.omit,
            discrete = TRUE)
summary(bam12)

table.bam[12,1]<-"tmax08:allppt08+vegtype2+s(year,bs=re)"
table.bam[12,2]<-AIC(bam12)
table.bam[12,3]<-summary(bam12)$sp.criterion
table.bam[12,4]<-summary(bam12)$r.sq

bam13<- bam(pttype ~tmax08 + 
              allppt08 +
              tmax08:allppt08 +
              vegtype2 + 
              s(year, bs="re",k=20) +
              s(vegtype2, year, bs="re"), 
            data= ignition_pres_abs3,
            family = binomial,
            na.action=na.omit,
            discrete = TRUE)
summary(bam13)

table.bam[13,1]<-"tmax08:allppt08+vegtype2+s(year,bs=re)+s(vegtype2,year,bs=re)"
table.bam[13,2]<-AIC(bam13)
table.bam[13,3]<-summary(bam13)$sp.criterion
table.bam[13,4]<-summary(bam13)$r.sq

par(mfrow=c(2,2))
gam.check(bam13)
residuals(bam13)
concurvity(bam13)

binnedplot (fitted(bam12), 
            residuals(bam12), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - bam11", 
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")
library(ResourceSelection)
hoslem.test(ignition_pres_abs3$pttype, fitted(bam11))

m1<-glm(pttype ~tmax08 + log(allppt08+0.001),binomial, data=ignition_pres_abs3)
binnedplot (fitted(m1), 
            residuals(m1), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - m1", 
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")








glmer13<- glmer(pttype ~tmax08 + 
              allppt08 +
              tmax08:allppt08 +
              vegtype2 + 
              (1|year), 
            data= ignition_pres_abs3,
            family = binomial,
            na.action=na.omit,
            verbose=TRUE)
summary(glmer13)
binnedplot (fitted(glmer13), 
            residuals(glmer13), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glmer", 
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

lightning<-ignition_pres_abs3 %>% 
  filter(fire_cause=="Lightning")






bam1 <- bam (pttype ~ s(tmax08) + 
                              allppt08 +
                              tmax08:allppt08 +
                              vegtype2 +
                              s(year, bs="re") +
                              s(vegtype2, year, bs="re"),
                            data= ignition_pres_abs3,
                            family = binomial,
                            na.action=na.omit,
                            discrete = TRUE)
summary(bam1)
AIC(bam1)

bam2 <- bam (pttype ~ tmax08 + 
                            allppt08 +
                            tmax08:allppt08 +
                            vegtype2 +
                            s(year, bs="re"),
                            #s(vegtype2, year, bs="re"),
                          data= ignition_pres_abs3,
                          family = binomial,
                          na.action=na.omit,
                          discrete = TRUE)
summary(bam2)
AIC(bam2)

anova(bam1, bam2, test="Chisq")
par(mfrow=c(2,2))
gam.check(bam1) # plots diagnostic plots, although not that useful for a binomial thing
model_matrix<- predict(bam1, type)




system.time({model5 <- bam (pttype ~ tmax08 + 
                 allppt08 +
                 tmax08:allppt08 +
                 vegtype +
                 veg_openess +
                 vegtype:veg_openess +
                 tmax08:vegtype +
                 allppt08:vegtype +
                 s(year, bs="re") + 
                 s(tmax08, year, bs="re"),
                 data= ignition_pres_abs3,
                 family = binomial,
                 na.action=na.omit,
               discrete = TRUE)
})

summary(model5)

model6 <- bam (pttype ~ te(tmax08, allppt08),
               data= ignition_pres_abs3,
               family = binomial,
               na.action=na.omit,
               discrete = TRUE)
summary(model6)
vis.gam(model6, type="response", plot.type='persp', phi=30,theta=30, n.grid=500, border=NA)
library(visreg)
visreg2d(model6, xvar="tmax08", yvar="allppt08", scale="response")


fire.hist<-sf::st_read(dsn="C:\\Users\\ekleynha\\Downloads\\PROT_HISTORICAL_FIRE_POLYS_SP\\H_FIRE_PLY_polygon.shp")
fire.hist2 <- st_transform (fire.hist, 3005)
st_crs(fire.hist2)
plot(fire.hist2$FIRE_YEAR,fire.hist2$AREA_SQM)

fire.hist2<- fire.hist %>%
  filter(FIRE_YEAR>=2002)

table(fire.hist2$FIRE_CAUSE)

p <- ggplot(fire.hist2, aes(x=log(AREA_SQM))) + 
  geom_histogram(aes(y=..density..), colour="black", fill="white")+
  geom_density(fill="lightblue", alpha=0.3) +
  xlim(0,21)
p

