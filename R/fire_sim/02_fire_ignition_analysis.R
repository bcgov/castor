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
fire_ignitions2 <- fire_ignitions1 %>%
  dplyr::select(fire_no, fire_year, fire_cause) %>%
  rename(id1=fire_no,
         year=fire_year)

ignition_pres_abs <- left_join(fire_veg_data, fire_ignitions2)

# pulling out locations where cause of fire is either unknown or due to lightning. If I go with only lightning the number of locations gets very small i.e. ~600
ignition_pres_abs1<- ignition_pres_abs %>%
  filter(fire_cause!="Person") # not sure why this kicks out all the zero values. It seems to me it should just kick out the fires that are knownn to be human caused.

ignit_2005<- ignition_pres_abs1 %>% dplyr::filter(year=='2005')
table(ignit_2005$pttype)

no_ignit<- ignition_pres_abs %>%
  filter(pttype=="0", year!="2005")

ignition_pres_abs1<- rbind(ignition_pres_abs1, no_ignit)
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
  stat_smooth(method="loess", formula=y~x,
              alpha=0.2, size=2) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("August MDC") + ylab("Pr (ignition)")

p <- ggplot(ignition_pres_abs1, aes(mdc_09, as.numeric(pttype))) +
  stat_smooth(method="glm", formula=y~x,
              alpha=0.2, size=2) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("August MDC") + ylab("Pr (ignition)")


p2 <- p + facet_wrap(~ year, nrow=3)

# Rainfall
p <- ggplot(ignition_pres_abs1, aes(allppt08, as.numeric(pttype))) +
  stat_smooth(method="glm", formula=y~x,
              alpha=0.2, size=2) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("All ppt in Aug") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ year, nrow=3)

pdf("C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\Figures\\PPT08_allYears.pdf")
print(p2)
dev.off()

# Temperature
p <- ggplot(ignition_pres_abs1, aes(tmax08, as.numeric(pttype))) +
  stat_smooth(method="glm", formula=y~x,
              alpha=0.2, size=2) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("tmax08") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ year, nrow=3)

pdf("C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\Figures\\tmax08_allYears.pdf")
print(p2)
dev.off()

##################
#### Analysis ####
##################

# To select the best single fire weather covariate I first conducted exploratory graphical analyses of the correlations between fire frequency and various fire weather variables. Then I fit generalized linear models for each fire weather variable (Eq. 1) using a binomial error structure with logarithmic link. Candidate variables were monthly average temperature, monthly maximum temperature, monthly precipitations and the six MDC’s. I also added various two, three or fourth-month means of these values (e.g. for May, June, July and August) to test for seasonal effects (e.g. spring vs. summer).

names(ignition_pres_abs1)

# correlation between max T and MDC. Some things are a little correlated i.e. tmax08 and mdc09 are relatively correlated (0.73) which makes sense since MDC is calculated with max T.
dist.cut.corr <- st_set_geometry(ignition_pres_abs1 [c (12:16, 32:36)], NULL)
corr <- round (cor (dist.cut.corr), 3)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Correlation between maximum temperature and MDC")

dist.cut.corr <- st_set_geometry(ignition_pres_abs1 [c (12:16, 39:43)], NULL)
corr <- round (cor (dist.cut.corr), 3)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Correlation between maximum temperature and all precipitation (snow + rain)")

dist.cut.corr <- st_set_geometry(ignition_pres_abs1 [c (17:21, 32:36)], NULL)
corr <- round (cor (dist.cut.corr), 3)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "DU8 Distance to Cutblock Correlation")

dist.cut.corr <- st_set_geometry(ignition_pres_abs1 [c (22:26, 32:36)], NULL)
corr <- round (cor (dist.cut.corr), 3)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "DU8 Distance to Cutblock Correlation")

ignition_pres_abs2<- st_set_geometry(ignition_pres_abs1, NULL)

# creating amalgamations of variables
ignition_pres_abs2$mean_tmax06_tmax07<- (ignition_pres_abs2$tmax06+ ignition_pres_abs2$tmax07)/2
ignition_pres_abs2$mean_tmax07_tmax08<- (ignition_pres_abs2$tmax07+ ignition_pres_abs2$tmax08)/2
ignition_pres_abs2$mean_tmax08_tmax09<- (ignition_pres_abs2$tmax08+ ignition_pres_abs2$tmax09)/2
ignition_pres_abs2$mean_tmax06_tmax07_tmax08<- (ignition_pres_abs2$tmax06+ ignition_pres_abs2$tmax07 + ignition_pres_abs2$tmax08)/3
ignition_pres_abs2$mean_tmax07_tmax08_tmax09<- (ignition_pres_abs2$tmax07+ ignition_pres_abs2$tmax08 + ignition_pres_abs2$tmax09)/3
ignition_pres_abs2$mean_tmax06_tmax07_tmax08_tmax09<- (ignition_pres_abs2$tmax06 + ignition_pres_abs2$tmax07+ ignition_pres_abs2$tmax08 + ignition_pres_abs2$tmax09)/4

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



variables<- c("tmax06", "tmax07", "tmax08", "tmax09", "mean_tmax06_tmax07", "mean_tmax07_tmax08", "mean_tmax08_tmax09", "mean_tmax06_tmax07_tmax08","mean_tmax07_tmax08_tmax09" , "mean_tmax06_tmax07_tmax08_tmax09","ppt06", "ppt07", "ppt08", "ppt09", "mean_ppt06_ppt07", "mean_ppt07_ppt08", "mean_ppt08_ppt09", "mean_ppt06_ppt07_ppt08", "mean_ppt07_ppt08_ppt09", "mean_ppt06_ppt07_ppt08_ppt09","mdc_06", "mdc_07", "mdc_08", "mdc_09", "mean_mdc06_mdc07", "mean_mdc07_mdc08", "mean_mdc08_mdc09", "mean_mdc06_mdc07_mdc08", "mean_mdc07_mdc08_mdc09", "mean_mdc06_mdc07_mdc08_mdc09")
              
              
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

  table.glm.climate[(i+31),1]<-variables[i]
  table.glm.climate[(i+31),2]<-extractAIC(model2)[2]
}

table.glm.climate$deltaAIC<-table.glm.climate$AIC- min(table.glm.climate$AIC)

# Trying with simpler model of varying intecept only for year
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
  
  table.glm.climate_simple[(i + 30),1]<-paste0(variables1[i], "_",variables2[i])
  table.glm.climate_simple[(i + 30),2]<-extractAIC(model4)[2]
}

table.glm.climate_simple$deltaAIC<-table.glm.climate_simple$AIC- min(table.glm.climate_simple$AIC)

# From the above analysis it seems the best combination of variables is the maximum temperature in August + the total precipitation in August.

plot(ignition_pres_abs2$tmax08, ignition_pres_abs2$allppt08)


# assembling landscape variables 

names(ignition_pres_abs1)

# remove points that landed on water (obviously ignitions will not start there)
ignition_pres_abs3 <-ignition_pres_abs1 %>%
  filter(bclcs_level_2!="W") %>%
  filter(bclcs_level_2!=" ")

#Creating new variable of vegetation type and a description of how open the vegetation is
# TB =  Treed broadleaf, TC = Treed Conifer, TM = Treed mixed, SL = short shrub, TC = tall shrubs, D = disturbed, O = open
ignition_pres_abs3$bclcs_level_4<- as.factor(ignition_pres_abs3$bclcs_level_4)
ignition_pres_abs3$bclcs_level_5<- as.factor(ignition_pres_abs3$bclcs_level_5)
ignition_pres_abs3$proj_age_1<- as.numeric(ignition_pres_abs3$proj_age_1)

ignition_pres_abs3$vegtype<-"0"
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









