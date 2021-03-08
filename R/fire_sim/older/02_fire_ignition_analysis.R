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
hist(fire_ignitions1_new$month) # most lightning fires appear to occur between May - Sept!
table(fire_veg_data$fire_yr, fire_veg_data$fire_cs)
table(fire_veg_data$fire_cs)

fire_veg_data$fire_cs<- as.factor(fire_veg_data$fire_cs)
dim(fire_veg_data)

# pulling out locations where cause of fire is due to lightning. 
fire_veg_data1<- fire_veg_data %>%
  filter(fire_cs!="Person") 
fire_veg_data1<- fire_veg_data1 %>%
  filter(fire_cs!="Unknown") 
table(fire_veg_data1$fire_cs)
table(fire_veg_data1$fire_yr, fire_veg_data1$fire_pres)

# fire_veg_data1 is the final data set

# Sub-boreal Spruce
sbs<- fire_veg_data1 %>% dplyr::filter(zone =="SBS")

##################
#### FIGURES ####
##################


  
# Plotting Probability of ignition versus drought code. Seems like similar trends are found in each month (June to August) but trend seems to get stronger in later months i.e. July and August.

p <- ggplot(sbs, aes(mdc_08, as.numeric(fire_pres))) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("August MDC") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ fire_yr, nrow=3)


p <- ggplot(sbs, aes(mdc_07, as.numeric(fire_pres))) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("July MDC") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ fire_yr, nrow=3)


# Climate moisture index
p <- ggplot(sbs, aes(cmi08, as.numeric(fire_pres))) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("August cmi") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ fire_yr, nrow=3)

# Maximum Temperature
#July
p <- ggplot(sbs, aes(tmax07, as.numeric(fire_pres))) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("July tmax") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ fire_yr, nrow=3)

# August
p <- ggplot(sbs, aes(tmax08, as.numeric(fire_pres))) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("August tmax") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ fire_yr, nrow=3)


##################
#### Analysis ####
##################

# To select the best single fire weather covariate I first conducted exploratory graphical analyses of the correlations between fire frequency and various fire weather variables. Then I fit generalized linear models for each fire weather variable (Eq. 1) using a binomial error structure with logarithmic link. Candidate variables were monthly average temperature, monthly maximum temperature, monthly precipitations and the six mean drought codes (MDC’s). I also added various two, three or fourth-month means of these values (e.g. for May, June, July and August) to test for seasonal effects (e.g. spring vs. summer).

names(sbs)

# correlation between max T and MDC. For sbs there is not high correlation between tmax and mdc, which seems odd since MDC is calculated using Tmax.
dist.cut.corr <- st_set_geometry(sbs [c (20:24, 40:44)], NULL)
corr <- round (cor (dist.cut.corr), 3)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Correlation between maximum temperature and MDC")

# But in SBS there is high correlation between total precipitation and MDC. Interesting!
dist.cut.corr <- st_set_geometry(sbs [c (30:34, 40:44)], NULL)
corr <- round (cor (dist.cut.corr), 3)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Correlation between total precipitation and MDC")

# Correlation between Tmax and total precipitation. 
dist.cut.corr <- st_set_geometry(sbs [c (20:24, 30:34)], NULL)
corr <- round (cor (dist.cut.corr), 3)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Correlation between total precipitation and Tmax")


######################################################################
#### Generation AIC tables to select best environmental predictors####
######################################################################
# creating amalgamations of variables
sbs_lightning2<- st_set_geometry(sbs, NULL)

sbs_lightning2$mean_tmax06_tmax07<- (sbs_lightning2$tmax06+ sbs_lightning2$tmax07)/2
sbs_lightning2$mean_tmax07_tmax08<- (sbs_lightning2$tmax07+ sbs_lightning2$tmax08)/2
sbs_lightning2$mean_tmax08_tmax09<- (sbs_lightning2$tmax08+ sbs_lightning2$tmax09)/2
sbs_lightning2$mean_tmax06_tmax07_tmax08<- (sbs_lightning2$tmax06+ sbs_lightning2$tmax07 + sbs_lightning2$tmax08)/3
sbs_lightning2$mean_tmax07_tmax08_tmax09<- (sbs_lightning2$tmax07+ sbs_lightning2$tmax08 + sbs_lightning2$tmax09)/3
sbs_lightning2$mean_tmax06_tmax07_tmax08_tmax09<- (sbs_lightning2$tmax06 + sbs_lightning2$tmax07+ sbs_lightning2$tmax08 + sbs_lightning2$tmax09)/4

sbs_lightning2$mean_cmi06_cmi07<- (sbs_lightning2$cmi06+ sbs_lightning2$cmi07)/2
sbs_lightning2$mean_cmi07_cmi08<- (sbs_lightning2$cmi07+ sbs_lightning2$cmi08)/2
sbs_lightning2$mean_cmi08_cmi09<- (sbs_lightning2$cmi08+ sbs_lightning2$cmi09)/2
sbs_lightning2$mean_cmi06_cmi07_cmi08<- (sbs_lightning2$cmi06+ sbs_lightning2$cmi07 + sbs_lightning2$cmi08)/3
sbs_lightning2$mean_cmi07_cmi08_cmi09<- (sbs_lightning2$cmi07+ sbs_lightning2$cmi08 + sbs_lightning2$cmi09)/3
sbs_lightning2$mean_cmi06_cmi07_cmi08_cmi09<- (sbs_lightning2$cmi06 + sbs_lightning2$cmi07+ sbs_lightning2$cmi08 + sbs_lightning2$cmi09)/4

sbs_lightning2$mean_ppt06_ppt07<- (sbs_lightning2$ppt06+ sbs_lightning2$ppt07)/2
sbs_lightning2$mean_ppt07_ppt08<- (sbs_lightning2$ppt07+ sbs_lightning2$ppt08)/2
sbs_lightning2$mean_ppt08_ppt09<- (sbs_lightning2$ppt08+ sbs_lightning2$ppt09)/2
sbs_lightning2$mean_ppt06_ppt07_ppt08<- (sbs_lightning2$ppt06+ sbs_lightning2$ppt07 + sbs_lightning2$ppt08)/3
sbs_lightning2$mean_ppt07_ppt08_ppt09<- (sbs_lightning2$ppt07+ sbs_lightning2$ppt08 + sbs_lightning2$ppt09)/3
sbs_lightning2$mean_ppt06_ppt07_ppt08_ppt09<- (sbs_lightning2$ppt06+ sbs_lightning2$ppt07 + sbs_lightning2$ppt08 + sbs_lightning2$ppt09)/4

sbs_lightning2$mean_mdc06_mdc07<- (sbs_lightning2$mdc_06+ sbs_lightning2$mdc_07)/2
sbs_lightning2$mean_mdc07_mdc08<- (sbs_lightning2$mdc_07+ sbs_lightning2$mdc_08)/2
sbs_lightning2$mean_mdc08_mdc09<- (sbs_lightning2$mdc_08+ sbs_lightning2$mdc_09)/2
sbs_lightning2$mean_mdc06_mdc07_mdc08<- (sbs_lightning2$mdc_06+ sbs_lightning2$mdc_07 + sbs_lightning2$mdc_08)/3
sbs_lightning2$mean_mdc07_mdc08_mdc09<- (sbs_lightning2$mdc_07+ sbs_lightning2$mdc_08 + sbs_lightning2$mdc_09)/3
sbs_lightning2$mean_mdc06_mdc07_mdc08_mdc09<- (sbs_lightning2$mdc_06+ sbs_lightning2$mdc_07 + sbs_lightning2$mdc_08 + sbs_lightning2$mdc_09)/4


variables<- c("tmax06", "tmax07", "tmax08", "tmax09", "mean_tmax06_tmax07", "mean_tmax07_tmax08", "mean_tmax08_tmax09", "mean_tmax06_tmax07_tmax08","mean_tmax07_tmax08_tmax09" , "mean_tmax06_tmax07_tmax08_tmax09", "cmi06", "cmi07", "cmi08", "cmi09", "mean_cmi06_cmi07", "mean_cmi07_cmi08", "mean_cmi08_cmi09", "mean_cmi06_cmi07_cmi08", "mean_cmi07_cmi08_cmi09", "mean_cmi06_cmi07_cmi08_cmi09","ppt06", "ppt07", "ppt08", "ppt09", "mean_ppt06_ppt07", "mean_ppt07_ppt08", "mean_ppt08_ppt09", "mean_ppt06_ppt07_ppt08", "mean_ppt07_ppt08_ppt09", "mean_ppt06_ppt07_ppt08_ppt09","mdc_06", "mdc_07", "mdc_08", "mdc_09", "mean_mdc06_mdc07", "mean_mdc07_mdc08", "mean_mdc08_mdc09", "mean_mdc06_mdc07_mdc08", "mean_mdc07_mdc08_mdc09", "mean_mdc06_mdc07_mdc08_mdc09")

variables1<-c("tmax06", "tmax07", "tmax08", "tmax09",
              "tmax06", "tmax07", "tmax08", "tmax09",
              "tmax06", "tmax07", "tmax08", "tmax09",
              "cmi06", "cmi07", "cmi08", "cmi09",
              "cmi06", "cmi07", "cmi08", "cmi09"
              )
variables2<-c("ppt06", "ppt07", "ppt08", "ppt09",
              "mdc_06", "mdc_07", "mdc_08", "mdc_09",
              "cmi06", "cmi07", "cmi08", "cmi09",
              "ppt06", "ppt07", "ppt08", "ppt09",
              "mdc_06", "mdc_07", "mdc_08", "mdc_09"
              )

sbs_lightning2$fire_pres<-as.numeric(sbs_lightning2$fire_pres)              
              
#Create frame of AIC table
# summary table
table.glm.climate <- data.frame (matrix (ncol = 2, nrow = 0))
colnames (table.glm.climate) <- c ("Variable", "AIC")

# Creates AIC table with a model that that allows slope and intercept to vary
for (i in 1: length(variables)){
  print(i)
model1 <- glmer (sbs_lightning2$fire_pres ~ sbs_lightning2[, variables[i]] +
                   sbs_lightning2[, variables[i]]||sbs_lightning2$fire_yr,
                 family = binomial (link = "logit"),
                 verbose = TRUE)

table.glm.climate[i,1]<-variables[i]
table.glm.climate[i,2]<-extractAIC(model1)[2]
}

# This is an addition to the table above allowing combinations of temperature and precipitation

for (i in 1: length(variables1)){
  print(i)
  model2 <- glmer (sbs_lightning2$fire_pres ~ sbs_lightning2[, variables1[i]] + sbs_lightning2[, variables2[i]] +
                     (sbs_lightning2[, variables1[i]] + sbs_lightning2[, variables2[i]])||sbs_lightning2$fire_yr,
                   family = binomial (link = "logit"),
                   verbose = TRUE)

  table.glm.climate[(i+length(variables)),1]<-paste0(variables1[i],"+", variables2[i])
  table.glm.climate[(i+length(variables)),2]<-extractAIC(model2)[2]
}

for (i in 1: length(variables1)){
  print(i)
  model2 <- glmer (sbs_lightning2$fire_pres ~ sbs_lightning2[, variables1[i]] * sbs_lightning2[, variables2[i]] +
                     (sbs_lightning2[, variables1[i]] + sbs_lightning2[, variables2[i]])||sbs_lightning2$fire_yr,
                   family = binomial (link = "logit"),
                   verbose = TRUE)
  
  table.glm.climate[(i+length(variables) +length(variables1)),1]<-paste0(variables1[i],"X", variables2[i])
  table.glm.climate[(i+length(variables) +length(variables1)),2]<-extractAIC(model2)[2]
}
table.glm.climate1<-table.glm.climate %>% drop_na(AIC)

table.glm.climate1$deltaAIC<-table.glm.climate1$AIC- min(table.glm.climate1$AIC)

write.csv(table.glm.climate1, file="D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\climate_AIC_results.csv")


##############################################################
# Trying with simplest model of no random effects only fixed effects. 

table.glm.climate_simplest <- data.frame (matrix (ncol = 2, nrow = 0))
colnames (table.glm.climate_simplest) <- c ("Variable", "AIC")
for (i in 1: length(variables)){
  print(i)
  model3 <- glm (sbs_lightning2$fire_pres ~ sbs_lightning2[, variables[i]] + sbs_lightning2$fire_yr,
                   family = binomial (link = "logit"))
  
  table.glm.climate_simplest[i,1]<-variables[i]
  table.glm.climate_simplest[i,2]<-extractAIC(model3)[2]
}



for (i in 1: length(variables1)){
  print(i)
  model4 <- glm (sbs_lightning2$fire_pres ~ 
                   sbs_lightning2[, variables1[i]] +
                     sbs_lightning2[, variables2[i]] +
                     sbs_lightning2$fire_yr,
                   family = binomial (link = "logit"))
  
  table.glm.climate_simplest[(i + length(variables)),1]<-paste0(variables1[i], "+",variables2[i])
  table.glm.climate_simplest[(i + length(variables)),2]<-extractAIC(model4)[2]
}

for (i in 1: length(variables1)){
  print(i)
  model4 <- glm (sbs_lightning2$fire_pres ~ 
                   sbs_lightning2[, variables1[i]] *
                   sbs_lightning2[, variables2[i]] +
                   sbs_lightning2$fire_yr,
                 family = binomial (link = "logit"))
  
  table.glm.climate_simplest[(i + length(variables) + length(variables1)),1]<-paste0(variables1[i], "*",variables2[i])
  table.glm.climate_simplest[(i + length(variables) + length(variables1)),2]<-extractAIC(model4)[2]
}

model4 <- glm (sbs_lightning2$fire_pres ~
                 sbs_lightning2$fire_yr,
               family = binomial (link = "logit"))

table.glm.climate_simplest[81,1]<-paste0("Year only")
table.glm.climate_simplest[81,2]<-extractAIC(model4)[2]

table.glm.climate_simplest$deltaAIC<-table.glm.climate_simplest$AIC- min(table.glm.climate_simplest$AIC)

# Model with lowest AIC was tmax08 x cmi08 deltaAIC=0, then with deltaAIC=2.8 points more was tmax08 + ppt08, followed by tmax08 x ppt08 with deltaAIC=4.1 points.


###############################################################

# From the above analysis it seems the best combination of variables is the maximum temperature in July * the total precipitation in July

plot(sbs_lightning2$tmax08, sbs_lightning2$ppt08)


# assembling landscape variables 

names(sbs_lightning2)

# remove points that landed on water (obviously ignitions will not start there)
table(ignition_pres_abs3$bclcs_level_2) # T=treed, N =  non-treed and L = land.
ignition_pres_abs3 <-sbs_lightning2 %>%
  filter(bclcs_level_2!="W") %>%
  filter(bclcs_level_2!=" ")

#Creating new variable of vegetation type and a description of how open the vegetation is
# TB =  Treed broadleaf, TC = Treed Conifer, TM = Treed mixed, SL = short shrub, ST = tall shrubs, D = disturbed, O = open
ignition_pres_abs3$bclcs_level_4<- as.factor(ignition_pres_abs3$bclcs_level_4)
ignition_pres_abs4<- ignition_pres_abs3 %>% drop_na(bclcs_level_4)
unique(ignition_pres_abs4$bclcs_level_4)
ignition_pres_abs4$proj_age_1<- as.numeric(ignition_pres_abs4$proj_age_1)

ignition_pres_abs4$vegtype<-"OP" # open
ignition_pres_abs4 <- ignition_pres_abs4 %>%
  mutate(vegtype = if_else(bclcs_level_4=="TC","TC", # Treed coniferous
                       if_else(bclcs_level_4=="TM", "TM", # Treed mixed
                               if_else(bclcs_level_4== "TB","TB", #Treed broadleaf
                                       if_else(bclcs_level_4=="SL", "S", # shrub
                                               if_else(bclcs_level_4=="ST", "S", vegtype))))))
ignition_pres_abs4$vegtype[which(ignition_pres_abs4$proj_age_1 <16)]<-"D" # disturbed

table(ignition_pres_abs4$vegtype)

# whats the relationship between vegetation type and probabilty of ignition

# plot lines of probability of ignition versus maximum temperature in August with different colours for each year, according to each vegetation type.

p <- ggplot(ignition_pres_abs4, aes(tmax08, as.numeric(fire_pres), color=fire_yr)) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  scale_x_continuous(limits = c(10,32)) +
  xlab("Maximum Temperature in August") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ vegtype, nrow=3)

# same plot as above but for precipitation
p <- ggplot(ignition_pres_abs4, aes(ppt08, as.numeric(fire_pres), color=fire_yr)) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.01, width=0)) +
  scale_x_continuous(limits = c(0,500)) +
  xlab("Total precipitation in August") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ vegtype, nrow=3)

# same plot as above but for climate moisture index
p <- ggplot(ignition_pres_abs4, aes(cmi08, as.numeric(fire_pres), color=fire_yr)) +
  geom_smooth(method="gam", formula=y~s(x),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.01, width=0)) +
  xlab("Climate moisture index in August") + ylab("Pr (ignition)")

p2 <- p + facet_wrap(~ vegtype, nrow=3)

# now run the model on this dataset
Zeros<- ignition_pres_abs3 %>% filter(pttype==0)
Ones<- ignition_pres_abs3 %>% filter(pttype==1)
Zeros<-Zeros[sample(nrow(Zeros), size = 10000, replace= FALSE), ]
dat<- rbind(Zeros, Ones)


library(mgcv)

# start simple
glm1<- glm(fire_pres ~tmax08 +
             ppt08, 
           data= ignition_pres_abs4,
           family = binomial,
           na.action=na.omit)
summary(glm1)

table.glm <- data.frame (matrix (ncol = 4, nrow = 0))
colnames (table.glm) <- c ("Model", "Variable", "AIC","adjusted R sqr")
table.glm[1,1]<-"glm1"
table.glm[1,2]<-"tmax08 + ppt08"
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



glm2<- glm(fire_pres ~tmax08 +
             ppt08 +
             vegtype, 
           data= ignition_pres_abs4,
           family = binomial,
           na.action=na.omit)
summary(glm2)
table.glm[2,1]<-"glm2"
table.glm[2,2]<-"tmax08 + allppt08 + vegtype"
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

glm3<- glm(fire_pres ~tmax08 +
             ppt08 +
             vegtype + 
             fire_yr, 
           data= ignition_pres_abs4,
           family = binomial,
           na.action=na.omit)
summary(glm3)
i=3
table.glm[i,1]<-"glm3"
table.glm[i,2]<-"tmax08 + ppt08 + vegtype + year"
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

glm4<- glm(fire_pres ~tmax08 +
             ppt08 +
             vegtype +
             subzone +
             fire_yr, 
           data= ignition_pres_abs4,
           family = binomial,
           na.action=na.omit)
summary(glm4)
i=4
table.glm[i,1]<-"glm4"
table.glm[i,2]<-"tmax08 + ppt08 + vegtype + year + subzone"
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

glmer5<- glmer(fire_pres ~ tmax08 +
                 ppt08 +
                 vegtype +
                 subzone +
                 (1|fire_yr), 
           data= ignition_pres_abs4,
           family = binomial,
           na.action=na.omit)
summary(glmer5)
i=5
table.glm[i,1]<-"glmer5"
table.glm[i,2]<-"tmax08 + ppt08 + vegtype + subzone + 1|yr"
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

glmer6<- glmer(fire_pres ~ scale(tmax08) + 
                 scale(ppt08) + 
                 vegtype + 
                 (1|fire_yr), 
               data= ignition_pres_abs4,
               family = binomial,
               na.action=na.omit)
summary(glmer6)
i=6
table.glm[i,1]<-"glmer6"
table.glm[i,2]<-"tmax08 + ppt08 + vegtype + 1|yr"
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

glmer7<- glmer(fire_pres ~ scale(tmax08) + 
                 vegtype + 
                 (1|fire_yr), 
               data= ignition_pres_abs4,
               family = binomial,
               na.action=na.omit)
summary(glmer7)
i=7
table.glm[i,1]<-"glmer7"
table.glm[i,2]<-"scale(tmax08) + vegtype + (1|fire_yr)"
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

