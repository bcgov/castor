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
#  Script Name: 05_veg_model_fits_by_BEC.R
#  Script Version: 1.0
#  Script Purpose: HEre I run logistic regression models with both climate and vegetation information in each BEC zone. .
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
library(purrr)
library(tidyr)
library(caret)
library(pROC)


source(here::here("R/functions/R_Postgres.R"))

# Import my vegetation, climate and presence/absence of fire data
connKyle <- dbConnect(drv = RPostgreSQL::PostgreSQL(), 
                      host = key_get('dbhost', keyring = 'postgreSQL'),
                      user = key_get('dbuser', keyring = 'postgreSQL'),
                      dbname = key_get('dbname', keyring = 'postgreSQL'),
                      password = key_get('dbpass', keyring = 'postgreSQL'),
                      port = "5432")
fire_veg_data <- sf::st_read  (dsn = connKyle, # connKyle
                               query = "SELECT * FROM fire_ignitions_veg_climate_clean")
dbDisconnect (connKyle)

# For quite a few BEC zones there were quite a few variables with very similar AIC values. For these variables I pulled out the variables with AIC within 2 pts of the lowest AIC and then out of those I selected the variable with the highest predictive power as determined through the ROC and AUC analysis.
climate.aic <- read.csv ("D:/Fire/fire_data/raw_data/ClimateBC_Data/AIC_table.csv")

##################
#### Analysis ####
##################

fire_veg_data_forest<- fire_veg_data %>% dplyr::filter(bclcs_level_2=="T")

zones<-climate.aic$Zone
clim_vars<-climate.aic$Variable


###############################
#### BG ####
###############################

bg<- fire_veg_data_forest %>% dplyr::filter(zone =="BG")

bg_treed1 <- glm (fire_pres ~  proj_age_1 + mean_ppt05_ppt06,
               data=bg,
               family = binomial (link = "logit"))

bg_treed2 <- glm (fire_pres ~  proj_height_1  + mean_ppt05_ppt06,
                  data=bg,
                  family = binomial (link = "logit"))

bg_treed3 <- glm (fire_pres ~  live_stand_volume_125   + mean_ppt05_ppt06,
                  data=bg,
                  family = binomial (link = "logit"))

bg_treed4 <- glm (fire_pres ~  proj_age_1 + proj_height_1 + mean_ppt05_ppt06,
                  data=bg,
                  family = binomial (link = "logit"))

bg_treed5 <- glm (fire_pres ~  proj_age_1 + live_stand_volume_125 + mean_ppt05_ppt06,
                  data=bg,
                  family = binomial (link = "logit"))

bg_treed6 <- glm (fire_pres ~  proj_age_1 + live_stand_volume_125 + mean_ppt05_ppt06,
                  data=bg,
                  family = binomial (link = "logit"))






# CDF and BAFA have few fire ignitions (CHECK!), Im going to leave them out for the moment because there are not many fire ignition locations in these two.
filenames<-list()
  
  for (h in 1:length(zones)) {
    dat2<- fire_veg_data_forest %>% dplyr::filter(zone ==zones[h])
   if (nchar(clim_vars[3]) ==12) {
     clim1<- substr(clim_vars[3],1,6)
     clim2<-substr(clim_vars[3], 8, 12)
   } else {(clim1<-clim_cars[3])}
    
    variables<- c("fire_pres", paste(clim1), paste(clim2), "proj_age_1", "proj_height_1", "live_stand_volume_125")
    
    model_dat<- dat2 %>% dplyr::select(any_of(variables))
    #plot(model_dat$proj_age_1, model_dat$proj_height_1)
    
    
    #Create frame of AIC table
    # summary table
    table.glm.climate.simple <- data.frame (matrix (ncol = 4, nrow = 0))
    colnames (table.glm.climate.simple) <- c ("Zone", "Variable", "AIC", "AUC")
    
   # model_dat<- dat2 %>% dplyr::select(fire_pres)
    trainIndex <- createDataPartition(model_dat$fire_pres, p = prop,
                                      list = FALSE,
                                      times = 1)
    dat1 <- as.data.frame(model_dat[ trainIndex,])
    names(dat1)[1] <- "fire_pres"
    Valid <- as.data.frame(model_dat[-trainIndex,])
    names(Valid)[1] <- "fire_pres"
    
    if (dat1[2]==6) {
    
    model1 <- glm (fire_pres ~  ,
                   data=dat1,
                   family = binomial (link = "logit"))
    
    table.glm.climate.simple[1,1]<-zones[h]
    table.glm.climate.simple[1,2]<-"intercept"
    table.glm.climate.simple[1,3]<-extractAIC(model1)[2]
    
    # lets look at fit of the Valid (validation) dataset
    Valid$model1_predict <- predict.glm(model1,newdata = Valid,type="response")
    roc_obj <- roc(Valid$fire_pres, Valid$model1_predict)
    auc(roc_obj)
    table.glm.climate.simple[1,4]<-auc(roc_obj)
    
    rm(model_dat,dat1,Valid)
    
    for (i in 1: length(variables)){
      print(paste((variables[i]), (zones[h]), sep=" "))
      
      model_dat<- dat2 %>% dplyr::select(fire_pres, variables[i])
      # Creating training and testing datasets so that I can get a measure of how well the model actually predicts the data e.g. AUG
      trainIndex <- createDataPartition(model_dat$fire_pres, p = prop,
                                        list = FALSE,
                                        times = 1)
      dat1 <- model_dat[ trainIndex,]
      Valid <- model_dat[-trainIndex,]
      
      model1 <- glm (fire_pres ~ . ,
                     data=dat1,
                     family = binomial (link = "logit"))
      
      table.glm.climate.simple[i+1,1]<-zones[h]
      table.glm.climate.simple[i+1,2]<-variables[i]
      table.glm.climate.simple[i+1,3]<-extractAIC(model1)[2]
      
      # lets look at fit of the Valid (validation) dataset
      Valid$model1_predict <- predict.glm(model1,newdata = Valid,type="response")
      roc_obj <- roc(Valid$fire_pres, Valid$model1_predict)
      auc(roc_obj)
      table.glm.climate.simple[i+1,4]<-auc(roc_obj)
      
    }
    


variables<- c("proj_age_1", "proj_height_1", "live_stand_volume_125")

 variables1<-c("tmax05", "tmax06", "tmax07", "tmax08", "tmax09",
               "tave05", "tave06", "tave07", "tave08", "tave09"
#               "tmax05","tmax06", "tmax07", "tmax08", "tmax09",
#               "mdc_05", "mdc_06", "mdc_07", "mdc_08", "mdc_09"
)
variables2<-c("ppt05", "ppt06", "ppt07", "ppt08", "ppt09",
              "ppt05", "ppt06", "ppt07", "ppt08", "ppt09"
              # "mdc_05", "mdc_06", "mdc_07", "mdc_08", "mdc_09",
              # "ppt05", "ppt06", "ppt07", "ppt08", "ppt09"
) 
# precipitation and MDC and temperature and MDC are quite correlated so Im leaving this combination of variables out. 

fire_veg_data$fire_pres<-as.numeric(fire_veg_data$fire) 
table(fire_veg_data$fire_yr, fire_veg_data$fire_pres)
table(fire_veg_data$fire_yr, fire_veg_data$fire_cs, fire_veg_data$zone)


#################################
#### Running simple logistic regression model
#################################
# create loop to do variable selection of climate data
unique(dat$zone)
zones<- c("ICH", "ESSF", "CWH", "MH", "CMA", "MS", "PP", "IDF", "SBPS", "IMA", "BWBS", "BG", "SBS", "SWB") #"CDF", "BAFA"

# CDF and BAFA have few fire ignitions (CHECK!), Im going to leave them out for the moment because there are not many fire ignition locations in these two.
filenames<-list()
prop<-0.75

for (g in 1:100){

for (h in 1:length(zones)) {
  dat2<- dat %>% dplyr::filter(zone ==zones[h])
  
#Create frame of AIC table
# summary table
table.glm.climate.simple <- data.frame (matrix (ncol = 4, nrow = 0))
colnames (table.glm.climate.simple) <- c ("Zone", "Variable", "AIC", "AUC")

model_dat<- dat2 %>% dplyr::select(fire_pres)
trainIndex <- createDataPartition(model_dat$fire_pres, p = prop,
                                  list = FALSE,
                                  times = 1)
dat1 <- as.data.frame(model_dat[ trainIndex,])
names(dat1)[1] <- "fire_pres"
Valid <- as.data.frame(model_dat[-trainIndex,])
names(Valid)[1] <- "fire_pres"


model1 <- glm (fire_pres ~ 1 ,
               data=dat1,
               family = binomial (link = "logit"))

table.glm.climate.simple[1,1]<-zones[h]
table.glm.climate.simple[1,2]<-"intercept"
table.glm.climate.simple[1,3]<-extractAIC(model1)[2]

# lets look at fit of the Valid (validation) dataset
Valid$model1_predict <- predict.glm(model1,newdata = Valid,type="response")
roc_obj <- roc(Valid$fire_pres, Valid$model1_predict)
auc(roc_obj)
table.glm.climate.simple[1,4]<-auc(roc_obj)

rm(model_dat,dat1,Valid)

for (i in 1: length(variables)){
  print(paste((variables[i]), (zones[h]), sep=" "))
  
  model_dat<- dat2 %>% dplyr::select(fire_pres, variables[i])
  # Creating training and testing datasets so that I can get a measure of how well the model actually predicts the data e.g. AUG
  trainIndex <- createDataPartition(model_dat$fire_pres, p = prop,
                                    list = FALSE,
                                    times = 1)
  dat1 <- model_dat[ trainIndex,]
  Valid <- model_dat[-trainIndex,]
  
  model1 <- glm (fire_pres ~ . ,
                 data=dat1,
                 family = binomial (link = "logit"))
  
  table.glm.climate.simple[i+1,1]<-zones[h]
  table.glm.climate.simple[i+1,2]<-variables[i]
  table.glm.climate.simple[i+1,3]<-extractAIC(model1)[2]
  
  # lets look at fit of the Valid (validation) dataset
  Valid$model1_predict <- predict.glm(model1,newdata = Valid,type="response")
  roc_obj <- roc(Valid$fire_pres, Valid$model1_predict)
  auc(roc_obj)
  table.glm.climate.simple[i+1,4]<-auc(roc_obj)
  
}

# This is an addition to the table above allowing combinations of temperature and precipitation

for (i in 1: length(variables1)){
  print(paste((variables1[i]), variables2[i], (zones[h]), sep=" "))
  model_dat<- dat2 %>% dplyr::select(fire_pres, variables1[i], variables2[i])
  # Creating training and testing datasets so that I can get a measure of how well the model actually predicts the data e.g. AUG
  trainIndex <- createDataPartition(model_dat$fire_pres, p = prop,
                                    list = FALSE,
                                    times = 1)
  dat1 <- model_dat[ trainIndex,]
  Valid <- model_dat[-trainIndex,]
  
  model2 <- glm (fire_pres ~ . ,
                 data=dat1,
                 family = binomial (link = "logit"))
  
  table.glm.climate.simple[(i+length(variables))+1,1]<-zones[h]
  table.glm.climate.simple[(i+length(variables))+1,2]<-paste0(variables1[i],"+", variables2[i])
  table.glm.climate.simple[(i+length(variables))+1,3]<-extractAIC(model2)[2]
  
  Valid$model2_predict <- predict.glm(model2,newdata = Valid,type="response")
  roc_obj <- roc(Valid$fire_pres, Valid$model2_predict)
  auc(roc_obj)
  table.glm.climate.simple[(i+length(variables))+1,4]<-auc(roc_obj)
  
}

for (i in 1: length(variables1)){
  print(paste((variables1[i]), "x",variables2[i], (zones[h]), sep=" "))

  model_dat<- dat2 %>% dplyr::select(fire_pres, variables1[i], variables2[i])
  # Creating training and testing datasets so that I can get a measure of how well the model actually predicts the data e.g. AUG
  trainIndex <- createDataPartition(model_dat$fire_pres, p = prop,
                                    list = FALSE,
                                    times = 1)
  dat1 <- model_dat[ trainIndex,]
  Valid <- model_dat[-trainIndex,]

  model2 <- glm (fire_pres ~ (.)^2,
                 data=dat1,
                 family = binomial (link = "logit"))

  table.glm.climate.simple[(i+length(variables) +length(variables1) + 1),1]<-zones[h]
  table.glm.climate.simple[(i+length(variables) +length(variables1) + 1),2]<-paste0(variables1[i],"x", variables2[i])
  table.glm.climate.simple[(i+length(variables) +length(variables1) + 1),3]<-extractAIC(model2)[2]

  Valid$model2_predict <- predict.glm(model2,newdata = Valid,type="response")
  roc_obj <- roc(Valid$fire_pres, Valid$model2_predict)
  auc(roc_obj)
  table.glm.climate.simple[(i+length(variables) +length(variables1) + 1),4]<-auc(roc_obj)

}
table.glm.climate1<-table.glm.climate.simple %>% drop_na(AIC)


#assign file names to the work
nam1<-paste("AIC",zones[h],"run",g,sep="_") #defining the name
assign(nam1,table.glm.climate.simple)
filenames<-append(filenames,nam1)
}
}


mkFrameList <- function(nfiles) {
  d <- lapply(seq_len(nfiles),function(i) {
    eval(parse(text=filenames[i]))
  })
  do.call(rbind,d)
}

n<-length(filenames)
aic_bec<-mkFrameList(n) 

aic_bec_summary<- aic_bec %>%
  group_by(Zone, Variable) %>%
  summarise(meanAIC=mean(AIC),
            meanAUC=mean(AUC),
            sdAUC=sd(AUC),
            )

aic_bec_summary2<- aic_bec_summary %>%
  group_by(Zone) %>%
  mutate(deltaAIC=meanAIC-min(meanAIC))

write.csv(aic_bec_summary2, file="D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\climate_AIC_results_simple.csv")

connKyle <- dbConnect(drv = RPostgreSQL::PostgreSQL(), 
                      host = key_get('dbhost', keyring = 'postgreSQL'),
                      user = key_get('dbuser', keyring = 'postgreSQL'),
                      dbname = key_get('dbname', keyring = 'postgreSQL'),
                      password = key_get('dbpass', keyring = 'postgreSQL'),
                      port = "5432")
st_write (obj = dat, 
          dsn = connKyle, 
          layer = c ("public", "fire_ignitions_veg_climate_clean"))
dbDisconnect (connKyle)

