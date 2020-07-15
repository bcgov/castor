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
#  Script Name: 01_fire.R
#  Script Version: 1.0
#  Script Purpose:  This script creates the data table for the figures and the script to create the figures in the shiny app section fire. It plots proportion of the herd home range and habitat type burned between 1919 and 2018 and creates a second figure of the cummulative area burned during the previous 40 years. 
#           
#  Script Author: Elizabeth Kleynhans, Ecological Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#   
#  Script Date: 19 March 2020
#  R Version: 
#  R Packages: 
#  Data: 
#=================================


require (dplyr)
require (tidyr)
require(ggplot2)
options(scipen=999)


# read in caribou herds
BC_caribou_habitat<-st_read(dsn="T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\caribou\\bc_critical_habitat\\BC_caribou_core_matrix_habitat_v20190904_1_shp\\BC_caribou_core_matrix_habitat_v20190904_1\\BC_caribou_core_matrix_habitat_v20190904_1.shp", stringsAsFactors = T,quiet=TRUE)

BC_caribou_habitat<- BC_caribou_habitat %>% st_set_geometry(NULL)
#BC_caribou_habitat<- data.table(BC_caribou_habitat)
BC_caribou_habitat$Herd_Name<-sub("_", " ", BC_caribou_habitat$Herd_Name)
BC_caribou_habitat <- BC_caribou_habitat %>% 
  unite(herd_bounds, c(Herd_Name, BCHab_code), sep=" ",remove=FALSE)

#BC_caribou_habitat[, herd_bounds:= paste(Herd_Name, BCHab_code, sep=" ")]

BC_caribou_habitat2<-BC_caribou_habitat %>% 
  group_by(herd_bounds) %>%
  summarise(total.area.ha=sum(Area_Ha)) 

# read in fire data
fire.bound<-read.csv("C:\\Work\\caribou\\clus_data\\Fire\\fire_sum_crithab.csv",header=FALSE,col.names=c("area_m2","HERD_NAME","habitat","year"))
head(fire.bound)
fire.bound$Herd_name<-fire.bound$HERD_NAME
fire.bound$Herd_name<-sub("_", " ", fire.bound$Herd_name) # this replaces the first instance of "_" it finds with " "
fire.bound$Herd_name<-sub("_", " ", fire.bound$Herd_name) # this replaces the 2nd instance

fire.bound<- fire.bound %>% mutate(Herd_name = if_else(Herd_name == "Itcha Ilgachuz","Itcha-Ilgachuz",
                                                       if_else(Herd_name=="Redrock Prairie Creek","Redrock-Prairie Creek", Herd_name)))
fire.bound <- fire.bound %>% 
  unite(herd_bounds, c(Herd_name, habitat), sep=" ",remove=FALSE)
fire.bound$area_ha<-fire.bound$area_m2/10000
fire.bound.dt<-fire.bound %>% select(c("herd_bounds","Herd_name","habitat","year","area_ha"))
fire<-left_join(fire.bound.dt,BC_caribou_habitat2)

fire$proportion.burn<-(fire$area_ha/fire$total.area.ha)*100
fire$herd_bounds=as.factor(fire$herd_bounds)
fire$proportion.burn<-as.numeric(fire$proportion.burn)


Itcha<-fire %>% filter(herd_bounds=="Itcha-Ilgachuz Matrix")

ggplot(Itcha, aes (x=year, y=proportion.burn)) +
  facet_wrap(.~herd_bounds, ncol = 4)+
  #geom_line (col="grey") +
  #geom_point()+
  geom_bar(stat="identity", width=2.5) +
  xlab ("Year") +
  ylab ("Proportion of area burned") +
  scale_x_continuous(limits = c(1925, 2025), breaks = seq(1930, 2020, by = 40)) +
  scale_y_continuous(limits =c(0,40),breaks=seq(0,70, by=40)) +
  theme_bw()+
  theme (legend.title = element_blank())


##--------------------------------------
##Creating loop to calculate the area burned over a 40 year moving window for each herd across each habitat type 
##--------------------------------------

Years<-1919:2018
window_size<-40

Fire_cummulative <- data.frame (matrix (ncol = 3, nrow = 0))
colnames (Fire_cummulative) <- c ("herd_bounds","cummulative.area.burned","year")

for (i in 1:(length(Years)-window_size)) {
fire.summary<-fire %>% filter(year >= Years[i] & year<=(Years[i]+window_size)) %>% 
           group_by (herd_bounds) %>% 
             summarize(cummulative.area.burned=sum(proportion.burn))
fire.summary$year<-Years[i]+window_size

Fire_cummulative<-rbind(Fire_cummulative,as.data.frame(fire.summary))
}

tail(Fire_cummulative,100)

Itcha<-Fire_cummulative %>% filter(herd_bounds=="Itcha-Ilgachuz Matrix")

ggplot(Itcha, aes (x=year, y=cummulative.area.burned)) +
  facet_wrap(.~herd_bounds, ncol = 4)+
  #geom_line (col="grey") +
  #geom_point()+
  geom_bar(stat="identity", width=1) +
  xlab ("Year") +
  ylab ("Cummulative proportion of area burned over 40 yrs") +
  scale_x_continuous(limits = c(1960, 2020), breaks = seq(1960, 2020, by = 30)) +
  scale_y_continuous(limits =c(0,70),breaks=seq(0,70, by=20)) +
  theme_bw()+
  theme (legend.title = element_blank())

