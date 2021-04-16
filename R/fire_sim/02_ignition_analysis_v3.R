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

# Histogram of lightning caused fires
fire_ignitions1_new<- fire_ignitions1 %>%
  filter(fire_year >=2002) %>%
  filter(fire_cause=="Lightning")
fire_ignitions1_new$month<- as.numeric(fire_ignitions1_new$month)
hist(fire_ignitions1_new$month, xlab="Month", main="Histogram of lightning caused fires") # most lightning fires appear to occur between May - Sept, with a peak in July and August!

#Histogram of human caused fires
fire_ignitions1_person<- fire_ignitions1 %>%
  filter(fire_year >=2002) %>%
  filter(fire_cause=="Person")
fire_ignitions1_person$month<- as.numeric(fire_ignitions1_person$month)
hist(fire_ignitions1_person$month, xlab="Month", main="Histogram of person caused fires") # Person caused fires occur throughout the year but also peak in July and August!


table(fire_ignitions1_new$fire_year, fire_ignitions1_new$fire_cause)
table(fire_veg_data$fire_yr, fire_veg_data$fire_cs)
# some fire ignition locations get lost in the data processing. I checked this and I think most of them fall outside the BC boundary so when I clip the locations to BC it removes a bunch. 

fire_veg_data$fire_cs<- as.factor(fire_veg_data$fire_cs)
dim(fire_veg_data)

fire_veg_data2<- st_set_geometry(fire_veg_data, NULL)
# Some of the fire ignition locations seem to be inaccurate as they land on water, which is odd! Ill remove these, but it removes quite a few fire ignition locations (1166 to be precise, which seems like a lot)
ignition_pres_abs3 <-fire_veg_data2 %>%
  filter(bclcs_level_2!="W") %>%
  filter(bclcs_level_2!=" ")
table(ignition_pres_abs3$bclcs_level_2, ignition_pres_abs3$fire_cs) # T=treed, N =  non-treed and L = land.
table(ignition_pres_abs3$fire_yr, ignition_pres_abs3$fire_cs) 


#Creating new variable of vegetation type and a description of how open the vegetation is
# TB =  Treed broadleaf, TC = Treed Conifer, TM = Treed mixed, SL = short shrub, ST = tall shrubs, D = disturbed, O = open. I will combine tall and short shrub. We dont estimate shrub cover in our CLUS model so Im not sure how this will influence our results since I dont think I can track it over time. Maybe I should include it in Open or disturbed?

ignition_pres_abs3$bclcs_level_4<- as.factor(ignition_pres_abs3$bclcs_level_4)
ignition_pres_abs4<- ignition_pres_abs3 %>% drop_na(bclcs_level_4) # this only drops 18 locations so I think its ok to remove the NA's
unique(ignition_pres_abs4$bclcs_level_4)

ignition_pres_abs4$vegtype<-"OP" #setting anything that is not one of the categories below to Open.
ignition_pres_abs4 <- ignition_pres_abs4 %>%
  mutate(vegtype = if_else(bclcs_level_4=="TC","TC", # Treed coniferous
                           if_else(bclcs_level_4=="TM", "TM", # Treed mixed
                                   if_else(bclcs_level_4== "TB","TB", #Treed broadleaf
                                           if_else(bclcs_level_4=="SL", "S", # shrub
                                                   if_else(bclcs_level_4=="ST", "S", vegtype))))))
ignition_pres_abs4$vegtype[which(ignition_pres_abs4$proj_age_1 <16)]<-"D" # disturbed -  following Marchal et al 2017 I make anything that is younger than 15 years old to disturbed. This might be something I should check whether this assumption is ok.

#ignition_pres_abs4<- ignition_pres_abs4 %>% filter(fir_typ!="Nuisance Fire") 
table(ignition_pres_abs4$vegtype, ignition_pres_abs4$fire_cs)

# look at vegetaton height and age as we track these in CLUS. 
ignition_pres_abs4$proj_age_1<- as.numeric(ignition_pres_abs4$proj_age_1)
hist(ignition_pres_abs4$proj_age_1)
hist(ignition_pres_abs4$proj_height_1) # not sure we have height in CLUS, we do have volume though. So maybe I should include age and volume in my model. This might be a surrogate for height



# subsample the data since my sample sizes for the zeros are too large. 
# At least two different papers used 1.5 times the number of presence points as absences. See:
#Chang et al (2013) Predicting fire occurrence patterns with logistic regression in Heilongjiang Province, China. Landscape Ecology 28, 1989-2004 and
# Catry et al. (2009) Modeling and mapping wildfire ignition risk in Portugal. International Journal of Wildland Fire 18, 921-931.
# steps for subsampling
# first get sample sizes per habitat type and year for the 1's. Then sample 2x or some amount more than that value in each of those vegetation, year categories. 
# see https://jennybc.github.io/purrr-tutorial/ls12_different-sized-samples.html for an idea on how to do this.

pre<- ignition_pres_abs4 %>%
  filter(fire==1) %>%
  dplyr::select(fire_yr, fire, zone, subzone) %>%
  group_by(fire_yr, zone, subzone) %>%
  summarize(fire_n=n())

pre_checkpre<- ignition_pres_abs4 %>%
  filter(fire==0) %>%
  dplyr::select(fire_yr, fire, zone, subzone) %>%
  group_by(fire_yr, zone, subzone) %>%
  summarize(abs_n=n())

check<-left_join(pre, pre_checkpre)
check %>% print(n=100) # hmm there are some NA's in the 0 column. I should probably correct that.

abs_match <- ignition_pres_abs4 %>%
  filter(fire == 0) %>%
  group_by(fire_yr, zone, subzone) %>%   # prep for work by yr and veg type
  nest() %>%              # --> one row per yr and vegtype
  ungroup()

df<-left_join(check, abs_match) # make sure there are not veg year combinations taht are not also in the fire_pres==1 file


# there are several year, zone, subzone combinations with no data in the tibble.  This code below removes the Null values. I should increase my sample of fire abscences so that I dont have any combinations with zero data or sample it in a different way. TO DO!
df2 <- df %>% 
  filter(lengths(data)>0)

# here I sample from the tibble the number of data points I want for the abscences
# I should probably have replace = false but there are a few rows where there are more fire ignitions in that subzone than randomly sampled locations which is causing issues with this code. For now Ill leave it like this.
  sampled_df<- df2 %>% 
    mutate(samp = map2(data, ceiling(fire_n*1.5), sample_n, replace=TRUE)) %>%
    dplyr::select(-data) %>%
    unnest(samp) %>%
    dplyr::select(fire_yr, zone, subzone, feature_id:vegtype)
 
# joining my subsampled absence data back to the fire ignition presence data
pre1<- ignition_pres_abs4 %>%
  filter(fire==1)
dim(sampled_df) # 22715 rows
dim(pre1) # 14958 rows

dat<- rbind(pre1, as.data.frame(sampled_df))
dim(dat) # 37673 rows good this worked I think

#dat<-ignition_pres_abs4 # 

##################
#### Analysis ####
##################

# To select the best single fire weather covariate I first conducted exploratory graphical analyses of the correlations between fire frequency and various fire weather variables. Then I fit generalized linear models for each fire weather variable (Eq. 1) using a binomial error structure with logarithmic link. Candidate variables were monthly average temperature, monthly maximum temperature, monthly precipitations and the six mean drought codes (MDC’s). I also added various two, three or fourth-month means of these values (e.g. for May, June, July and August) to test for seasonal effects (e.g. spring vs. summer).


#### looking at correlations between variables####

# correlation between max T and MDC. Across all the data MDC and Tmax are correlated with values ranging between 0.78 and 0.15
dist.cut.corr <- dat [c (20:24, 35:39)]
corr <- round (cor (dist.cut.corr), 3)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Correlation between maximum temperature and MDC")

# Correlation between total precipitation and MDC. This is also pretty correlated with values between -0.75 and -0.18
dist.cut.corr <- dat [c (30:34, 35:39)]
corr <- round (cor (dist.cut.corr), 3)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Correlation between total precipitation and MDC")

# Correlation between Tmax and total precipitation. The correlation is very low, as would be expected (-0.02 to -0.57) 
dist.cut.corr <- dat [c (20:24, 30:34)]
corr <- round (cor (dist.cut.corr), 3)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Correlation between total precipitation and Tmax")


# Correlation between Tave and total precipitation. The correlation is very low, as would be expected (-0.02 to -0.44) 
dist.cut.corr <- dat [c (25:29, 30:34)]
corr <- round (cor (dist.cut.corr), 3)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Correlation between total precipitation and Tave")
#################################
# ANALYSIS OF CLIMATE VARIABLES
#################################

# Loosely following the methods of Marchal et al. (2017) Ecography (https://onlinelibrary.wiley.com/doi/full/10.1111/ecog.01849) Supporting Information Appendix 1 I try to figure out which is the best climate variable or climate variables to include in my model. I run simple models of the form:
# logb(p/1-p) = B0 + B1x1 or logb(p/1-p) = B0 + B1x1 + B2x2
#and extract the AIC as a means for comparison. I also calculate the AUC by splitting the data into a training and validation data set. Finally I repeat the analysis calculating the AIC and AUC using traing and validation data sets 10 times taking the average of both the AIC and AUC values. These are the values that I spit out into a csv file so that I can examine which climate variable is best for each BEC zone. 

### creating amalgamations of variables to test different combinations of variables.##
dat$mean_tmax05_tmax06<- (dat$tmax05+ dat$tmax06)/2
dat$mean_tmax06_tmax07<- (dat$tmax06+ dat$tmax07)/2
dat$mean_tmax07_tmax08<- (dat$tmax07+ dat$tmax08)/2
dat$mean_tmax08_tmax09<- (dat$tmax08+ dat$tmax09)/2
dat$mean_tmax05_tmax06_tmax07<- (dat$tmax05+ dat$tmax06 + dat$tmax07)/3
dat$mean_tmax06_tmax07_tmax08<- (dat$tmax06+ dat$tmax07 + dat$tmax08)/3
dat$mean_tmax07_tmax08_tmax09<- (dat$tmax07+ dat$tmax08 + dat$tmax09)/3
dat$mean_tmax05_tmax06_tmax07_tmax08<- (dat$tmax05 + dat$tmax06+ dat$tmax07 + dat$tmax08)/4
dat$mean_tmax06_tmax07_tmax08_tmax09<- (dat$tmax06 + dat$tmax07+ dat$tmax08 + dat$tmax09)/4
dat$mean_tmax05_tmax06_tmax07_tmax08_tmax09<- (dat$tmax05 + dat$tmax06 + dat$tmax07+ dat$tmax08 + dat$tmax09)/5

dat$mean_tave05_tave06<- (dat$tave05+ dat$tave06)/2
dat$mean_tave06_tave07<- (dat$tave06+ dat$tave07)/2
dat$mean_tave07_tave08<- (dat$tave07+ dat$tave08)/2
dat$mean_tave08_tave09<- (dat$tave08+ dat$tave09)/2
dat$mean_tave05_tave06_tave07<- (dat$tave05+ dat$tave06 + dat$tave07)/3
dat$mean_tave06_tave07_tave08<- (dat$tave06+ dat$tave07 + dat$tave08)/3
dat$mean_tave07_tave08_tave09<- (dat$tave07+ dat$tave08 + dat$tave09)/3
dat$mean_tave05_tave06_tave07_tave08<- (dat$tave05 + dat$tave06+ dat$tave07 + dat$tave08)/4
dat$mean_tave06_tave07_tave08_tave09<- (dat$tave06 + dat$tave07+ dat$tave08 + dat$tave09)/4
dat$mean_tave05_tave06_tave07_tave08_tave09<- (dat$tave05 + dat$tave06 + dat$tave07+ dat$tave08 + dat$tave09)/5


dat$mean_ppt05_ppt06<- (dat$ppt05+ dat$ppt06)/2
dat$mean_ppt06_ppt07<- (dat$ppt06+ dat$ppt07)/2
dat$mean_ppt07_ppt08<- (dat$ppt07+ dat$ppt08)/2
dat$mean_ppt08_ppt09<- (dat$ppt08+ dat$ppt09)/2
dat$mean_ppt05_ppt06_ppt07<- (dat$ppt05+ dat$ppt06 + dat$ppt07)/3
dat$mean_ppt06_ppt07_ppt08<- (dat$ppt06+ dat$ppt07 + dat$ppt08)/3
dat$mean_ppt07_ppt08_ppt09<- (dat$ppt07+ dat$ppt08 + dat$ppt09)/3
dat$mean_ppt05_ppt06_ppt07_ppt08<- (dat$ppt05+ dat$ppt06 + dat$ppt07 + dat$ppt08)/4
dat$mean_ppt06_ppt07_ppt08_ppt09<- (dat$ppt06+ dat$ppt07 + dat$ppt08 + dat$ppt09)/4
dat$mean_ppt05_ppt06_ppt07_ppt08_ppt09<- (dat$ppt05 + dat$ppt06 + dat$ppt07 + dat$ppt08 + dat$ppt09)/5

dat$mean_mdc05_mdc06<- (dat$mdc_05+ dat$mdc_06)/2
dat$mean_mdc06_mdc07<- (dat$mdc_06+ dat$mdc_07)/2
dat$mean_mdc07_mdc08<- (dat$mdc_07+ dat$mdc_08)/2
dat$mean_mdc08_mdc09<- (dat$mdc_08+ dat$mdc_09)/2
dat$mean_mdc05_mdc06_mdc07<- (dat$mdc_05+ dat$mdc_06 + dat$mdc_07)/3
dat$mean_mdc06_mdc07_mdc08<- (dat$mdc_06+ dat$mdc_07 + dat$mdc_08)/3
dat$mean_mdc07_mdc08_mdc09<- (dat$mdc_07+ dat$mdc_08 + dat$mdc_09)/3
dat$mean_mdc05_mdc06_mdc07_mdc08<- (dat$mdc_05+ dat$mdc_06 + dat$mdc_07 + dat$mdc_08)/4
dat$mean_mdc06_mdc07_mdc08_mdc09<- (dat$mdc_06+ dat$mdc_07 + dat$mdc_08 + dat$mdc_09)/4
dat$mean_mdc05_mdc06_mdc07_mdc08_mdc09<- (dat$mdc_05 + dat$mdc_06+ dat$mdc_07 + dat$mdc_08 + dat$mdc_09)/5



variables<- c("tmax05","tmax06", "tmax07", "tmax08", "tmax09", 
              "mean_tmax05_tmax06","mean_tmax06_tmax07", "mean_tmax07_tmax08", "mean_tmax08_tmax09", 
              "mean_tmax05_tmax06_tmax07", "mean_tmax06_tmax07_tmax08","mean_tmax07_tmax08_tmax09", 
              "mean_tmax05_tmax06_tmax07_tmax08", "mean_tmax06_tmax07_tmax08_tmax09", "mean_tmax05_tmax06_tmax07_tmax08_tmax09",
              
              "tave05","tave06", "tave07", "tave08", "tave09", 
              "mean_tave05_tave06","mean_tave06_tave07", "mean_tave07_tave08", "mean_tave08_tave09", 
              "mean_tave05_tave06_tave07", "mean_tave06_tave07_tave08","mean_tave07_tave08_tave09", 
              "mean_tave05_tave06_tave07_tave08", "mean_tave06_tave07_tave08_tave09", "mean_tave05_tave06_tave07_tave08_tave09",
              
              "ppt05","ppt06", "ppt07", "ppt08", "ppt09",
              "mean_ppt05_ppt06", "mean_ppt06_ppt07", "mean_ppt07_ppt08", "mean_ppt08_ppt09", 
              "mean_ppt05_ppt06_ppt07","mean_ppt06_ppt07_ppt08", "mean_ppt07_ppt08_ppt09",
              "mean_ppt05_ppt06_ppt07_ppt08", "mean_ppt06_ppt07_ppt08_ppt09",
              "mean_ppt05_ppt06_ppt07_ppt08_ppt09",
              
              "mdc_05","mdc_06", "mdc_07", "mdc_08", "mdc_09",
              "mean_mdc05_mdc06", "mean_mdc06_mdc07", "mean_mdc07_mdc08", "mean_mdc08_mdc09", 
              "mean_mdc05_mdc06_mdc07", "mean_mdc06_mdc07_mdc08", "mean_mdc07_mdc08_mdc09", 
              "mean_mdc05_mdc06_mdc07_mdc08", "mean_mdc06_mdc07_mdc08_mdc09",
              "mean_mdc05_mdc06_mdc07_mdc08_mdc09")

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

dat$fire_pres<-as.numeric(dat$fire) 
table(dat$fire_yr, dat$fire_pres)
table(dat$fire_yr, dat$fire_cs, dat$zone)


#################################
#### Running simple logistic regression model
#################################
# create loop to do variable selection of climate data
unique(dat$zone)
zones<- c("ICH", "ESSF", "CWH", "MH", "CMA", "MS", "PP", "IDF", "SBPS", "IMA", "BWBS", "BG", "SBS", "SWB") #"CDF", "BAFA"

# CDF and BAFA have few fire ignitions (CHECK!), Im going to leave them out for the moment because there are not many fire ignition locations in these two.
filenames<-list()
for (g in 1:10){

for (h in 1:length(zones)) {
  dat2<- dat %>% dplyr::filter(zone ==zones[h])
  
#Create frame of AIC table
# summary table
table.glm.climate.simple <- data.frame (matrix (ncol = 4, nrow = 0))
colnames (table.glm.climate.simple) <- c ("Zone", "Variable", "AIC", "AUC")

model_dat<- dat2 %>% dplyr::select(fire_pres)
trainIndex <- createDataPartition(model_dat$fire_pres, p = .7,
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
#MUST STILL DO THIS
Valid$model1_predict <- predict.glm(model1,newdata = Valid,type="response")
roc_obj <- roc(Valid$fire_pres, Valid$model1_predict)
auc(roc_obj)
table.glm.climate.simple[1,4]<-auc(roc_obj)

rm(model_dat,dat1,Valid)

for (i in 1: length(variables)){
  print(paste((variables[i]), (zones[h]), sep=" "))
  
  model_dat<- dat2 %>% dplyr::select(fire_pres, variables[i])
  # Creating training and testing datasets so that I can get a measure of how well the model actually predicts the data e.g. AUG
  trainIndex <- createDataPartition(model_dat$fire_pres, p = .7,
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
  trainIndex <- createDataPartition(model_dat$fire_pres, p = .7,
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
  trainIndex <- createDataPartition(model_dat$fire_pres, p = .7,
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
#table.glm.climate1<-table.glm.climate %>% drop_na(AIC)


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


# As a proof of concept I will model fire within one BEC Zone to start.
###############################################
#### Run model for Sub-Boreal Spruce (SBS)
###############################################


##################
#### FIGURES ####
##################
# top climatic variables for SBS were tave08 + ppt08
sbs<- dat %>%
  filter(zone=="SBS")

# Plotting Probability of ignition versus temp and precipitation.
p <- ggplot(sbs, aes(tave08, as.numeric(fire_pres))) +
  geom_smooth(method="glm", formula=y~x,
              method.args=list(family="binomial"),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("Tmax_08") + ylab("Pr (ignition)")
p
p2 <- p + facet_wrap(~ fire_yr, nrow=3)
p2


p <- ggplot(sbs, aes(ppt08, as.numeric(fire_pres))) +
  geom_smooth(method="glm", formula=y~x,
              method.args=list(family="binomial"),
              alpha=0.3, size=1) +
  geom_point(position=position_jitter(height=0.03, width=0)) +
  xlab("ppt08") + ylab("Pr (ignition)")
p

hist(sbs$ppt08)
hist(sbs$tave08)

plot(sbs$tave08, sbs$ppt08)

################################
#### Fitting statistical models
################################

glm1<- glm(fire_pres ~ tmax08 + ppt08, 
           data= sbs,
           family = binomial,
           na.action=na.omit)
summary(glm1)

table.glm <- data.frame (matrix (ncol = 3, nrow = 0))
colnames (table.glm) <- c ("Model", "Variable", "AIC")
table.glm[1,1]<-"glm1"
table.glm[1,2]<-"tmax08 + ppt08"
table.glm[1,3]<-AIC(glm1)
binnedplot (fitted(glm1), 
            residuals(glm1), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm1")

glm2<- glm(fire_pres ~ tmax08 + ppt08 +
             vegtype, 
           data= sbs,
           family = binomial,
           na.action=na.omit)
summary(glm2)

i=2
table.glm[i,1]<-"glm2"
table.glm[i,2]<-"tmax08 + ppt08 + vegtype"
table.glm[i,3]<-AIC(glm2)
binnedplot (fitted(glm2), 
            residuals(glm2), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm2")


glm3<- glm(fire_pres ~tmax08 +
             ppt08 +
             fire_yr, 
           data= sbs,
           family = binomial,
           na.action=na.omit)
summary(glm3)
i=3
table.glm[i,1]<-"glm3"
table.glm[i,2]<-"tmax08 + ppt08 + year"
table.glm[i,3]<-AIC(glm3)
binnedplot (fitted(glm3), 
            residuals(glm3), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm3")

glm4<- glm(fire_pres ~tmax08 +
             ppt08 + 
             subzone, 
           data= sbs,
           family = binomial,
           na.action=na.omit)
summary(glm4)
i=4
table.glm[i,1]<-"glm4"
table.glm[i,2]<-"tmax08 + ppt08 + subzone"
table.glm[i,3]<-AIC(glm4)
binnedplot (fitted(glm4), 
            residuals(glm4), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm4")

glm5<- glm(fire_pres ~ tmax08 + ppt08 +
             vegtype +
             subzone, 
           data= sbs,
           family = binomial,
           na.action=na.omit)
summary(glm2)

i=5
table.glm[i,1]<-paste0("glm",i)
table.glm[i,2]<-"tmax08 + ppt08 + vegtype"
table.glm[i,3]<-AIC(glm5)
binnedplot (fitted(glm5), 
            residuals(glm5), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = paste("Binned Residual Plot - glm", i))


glm6<- glm(fire_pres ~tmax08 +
             cmi08 +
             fire_yr + 
             subzone, 
           data= Train,
           family = binomial,
           na.action=na.omit)
summary(glm6)
i=6
table.glm[i,1]<-paste0("glm",i)
table.glm[i,2]<-"tmax08 + ppt08 + vegtype"
table.glm[i,3]<-AIC(glm5)
binnedplot (fitted(glm5), 
            residuals(glm5), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = paste("Binned Residual Plot - glm", i))

Train$tmax08c<-Train$tmax08-mean(Train$tmax08)
Train$cmi08c<-Train$cmi08-mean(Train$cmi08)


glmer7<- glmer(fire_pres ~ tmax08 +
                 cmi08 +
                 (1|fire_yr), 
           data= Train,
           family = binomial,
           na.action=na.omit)
summary(glmer7)
i=7
table.glm[i,1]<-"glmer7"
table.glm[i,2]<-"tmax08 + ppt08 + 1|yr"
table.glm[i,3]<-AIC(glmer7)
table.glm[i,4]<-summary(glmer7)$adj.r.squared
binnedplot (predict(glmer7), 
            resid(glmer7), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm2")

glmer8<- glmer(fire_pres ~ tmax08 +
                 cmi08 +
                 subzone +
                 (1|fire_yr), 
               data= Train,
               family = binomial,
               na.action=na.omit)
summary(glmer8)
i=8
table.glm[i,1]<-"glmer8"
table.glm[i,2]<-"tmax08 + ppt08 + subzone + 1|yr"
table.glm[i,3]<-AIC(glmer8)
table.glm[i,4]<-summary(glmer8)$adj.r.squared
binnedplot (invlogit(predict(glmer8)), 
            residuals(glmer8), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm6"
            )

glmer8<- glmer(fire_pres ~ tmax08c +
                 cmi08c +
                 subzone +
                 (1|fire_yr), 
               data= Train,
               family = binomial,
               na.action=na.omit)
summary(glmer8)
i=8
table.glm[i,1]<-"glmer8"
table.glm[i,2]<-"tmax08 + ppt08 + subzone + 1|yr"
table.glm[i,3]<-AIC(glmer8)
table.glm[i,4]<-summary(glmer8)$adj.r.squared
binnedplot (invlogit(predict(glmer8)), 
            residuals(glmer8), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glmer8"
)

glmer9<- glmer(fire_pres ~ tmax08c +
                 cmi08c +
                 subzone +
                 vegtype +
                 (1|fire_yr), 
               data= Train,
               family = binomial,
               na.action=na.omit)
summary(glmer9)
i=9
table.glm[i,1]<-"glmer9"
table.glm[i,2]<-"tmax08 + ppt08 + subzone + vegtype + 1|yr"
table.glm[i,3]<-AIC(glmer9)
table.glm[i,4]<-summary(glmer9)$adj.r.squared
binnedplot (invlogit(predict(glmer9)), 
            residuals(glmer9), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm6"
)

glmer10<- glmer(fire_pres ~ tmax08 +
                 cmi08 +
                 subzone +
                 (subzone||fire_yr), 
               data= Train,
               family = binomial,
               na.action=na.omit)
summary(glmer10)
i=10
table.glm[i,1]<-"glmer10"
table.glm[i,2]<-"tmax08 + ppt08 + subzone + subzone||yr"
table.glm[i,3]<-AIC(glmer10)
table.glm[i,4]<-summary(glmer10)$adj.r.squared
binnedplot (invlogit(predict(glmer10)), 
            residuals(glmer9), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm6"
)

glmer11<- glmer(fire_pres ~ tmax08c +
                 cmi08c +
                 vegtype +
                 (1|fire_yr), 
               data= Train,
               family = binomial,
               na.action=na.omit)
summary(glmer11)
i=11
table.glm[i,1]<-"glmer11"
table.glm[i,2]<-"tmax08 + ppt08 + vegtype + 1|yr"
table.glm[i,3]<-AIC(glmer11)
table.glm[i,4]<-summary(glmer1)$adj.r.squared
binnedplot (invlogit(predict(glmer11)), 
            residuals(glmer11), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glmer11"
)


# best model seems to be glmer8 or glmer9 they both have the same AIC values but glmer8 is simpler so Ill stick with that one.


dat1$tmax08c<-dat1$tmax08-mean(dat1$tmax08)
dat1$cmi08c<-dat1$cmi08-mean(dat1$cmi08)
glmer8<- glmer(fire_pres ~ tmax08 +
                 cmi08 +
                 vegtype +
                 (1|fire_yr), 
               data= dat1,
               family = binomial,
               na.action=na.omit)
summary(glmer8)
binnedplot (invlogit(predict(glmer8)), 
            residuals(glmer8), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glmer8"
)

binnedplot (Train$tmax08c, 
            resid(glmer8), 
            nclass = NULL, 
            xlab = "centered cmi08", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm6"
)

binnedplot (Train$cmi08c, 
            resid(glmer8), 
            nclass = NULL, 
            xlab = "centered cmi08", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm6"
) # it mostly looks pretty good!



# lets look at fit of the Valid (validation) dataset
#MUST STILL DO THIS
Valid$GLMER_predict8 <- predict(glmer8,newdata = Valid,type="response")
Valid$GLMER_predict9 <- predict(glmer9,newdata = Valid,type="response")
valid_dat<-Valid %>% 
  dplyr::select(idno, fire_pres, GLMER_predict8 ) %>%
  rename(ID=idno,
         Observed=fire_pres)
valid_dat$Observed<-as.numeric(as.character(valid_dat$Observed))
library(PresenceAbsence)
auc (as.data.frame(valid_dat)) # Get the AUC value. You can specify the sd. 
auc.roc.plot (valid_dat) # Plot the ROC


LR_predict_bin <- ifelse(LR_predict > 0.6,1,0)
cm_lr <- table(Valid,LR_predict_bin) #Accuracy 
accuracy <- (sum(diag(cm_lr))/sum(cm_lr)) 
accuracy



hist(ignition_pres_abs4$cmi08) #the data is right skewed. Possible transformations include sqrt, log or cuberoot, but because cmi has negative values Ill try cuberoot

ignition_pres_abs4$cmi08c<-as.numeric(ignition_pres_abs4$cmi08c)
ignition_pres_abs4$cmi08_cr<-kader:::cuberoot(x = ignition_pres_abs4$cmi08c)
hist((ignition_pres_abs4$cmi08_cr)) # this did not help.

# ok maybe shift the distribution so that no values are negative .
ignition_pres_abs4$cmi08_shifted<-ignition_pres_abs4$cmi08+10
hist(ignition_pres_abs4$cmi08_shifted)
hist(log(ignition_pres_abs4$cmi08_shifted))

glmer_final<- glmer(fire_pres ~ tmax08c +
                 cmi08_shifted +
                 subzone +
                 (1|fire_yr), 
               data= ignition_pres_abs4,
               family = binomial,
               na.action=na.omit)
summary(glmer8)
binnedplot (invlogit(predict(glmer8)), 
            residuals(glmer8), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm6"
)

binnedplot (ignition_pres_abs4$cmi08_shifted, 
            resid(glmer8), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual", 
            main = "Binned Residual Plot - glm6"
)

# obtain predictive equation from the final model

# I should probably run an AUC on a portion of the data that I hold back from the analysis.





# could try bam, but I think Ill leave it because the glmer seems to work pretty well.
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

