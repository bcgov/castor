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
#  Script Name: 02_Area_burned_per_herd_and_habitat.R
#  Script Version: 1.0
#  Script Purpose: Script estimates the area burned both as total area and an proportion of total area per herd home range and habitat type
#  Script Author: Elizabeth Kleynhans, Ecological Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#   
#  Script Date: 23 March 2020
#  R Version: 
#  R Packages: 
#  Data: 
#=================================

require(rgdal)
require(plyr)
require(dplyr)
require(sf)
require(ggplot2)
require(tidyr)
require(rgeos)
require(sp)
options(scipen=999)

#----------------------------------------------------------------
#calculating the total area burned and proportion burned for each herd and habitat type
#----------------------------------------------------------------


# read in caribou herds
BC_caribou_habitat<-st_read(dsn="T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\caribou\\bc_critical_habitat\\BC_caribou_core_matrix_habitat_v20190904_1_shp\\BC_caribou_core_matrix_habitat_v20190904_1\\BC_caribou_core_matrix_habitat_v20190904_1.shp", stringsAsFactors = T,quiet=TRUE)


# read in fire data
setwd("C:\\Work\\caribou\\clus_data\\Fire\\Results")
fire.bound<-read.csv("C:\\Work\\caribou\\clus_data\\Fire\\fire_sum_crithab.csv",header=FALSE,col.names=c("area_m2","HERD_NAME","habitat","year"))
head(fire.bound)

#Herd_name<-c("Central_Selkirks","Columbia_North","Groundhog", "Monashee", "Purcell_Central", "Purcell_South","South_Selkirks","Wells_Gray_South","Columbia_South","Hart_Ranges","North_Cariboo","Telkwa","Wells_Gray_North","Central_Rockies","Charlotte_Alplands","Itcha_Ilgachuz","Rainbows","Barkerville","Narrow_Lake","Frisby_Boulder","Redrock_Prairie_Creek")

Herd_name<-c("Wells_Gray_North","Charlotte_Alplands","Itcha_Ilgachuz","Rainbows","Barkerville")
Herd_name_bc<-c("Wells Gray North", "Charlotte Alplands", "Itcha-Ilgachuz", "Rainbows", "Barkerville")
Years<-1919:2018
habitat_types<-c("HEWSR","LESR","LEWR","Matrix")
fire.bound$count<-1
fire.bound$area_m2<-as.numeric(fire.bound$area_m2)
filenames<-list()


for (i in 1:length(Herd_name)){
  
  Herd_area<-BC_caribou_habitat %>% 
    filter(Herd_Name==Herd_name_bc[i]) %>%
    group_by(BCHab_code) %>%
    summarise(total.area=sum(Area_Ha)) %>%
    st_set_geometry(NULL)

  Fire_area<-fire.bound %>%
    filter(year>=1978, HERD_NAME==Herd_name[i]) 

  burn_per_area<- Fire_area %>%
    group_by(habitat) %>%
    summarise(mean_ha2=(mean(area_m2))/10000,
            median_ha2=(median(area_m2)/10000),
            max_ha2=(max(area_m2))/10000,
            CI_95_upper_ha2=(mean(area_m2)+(1.96*(sd(area_m2)/sqrt(sum(count)))))/10000,
            CI_90_upper_ha2=(mean(area_m2)+(1.64*(sd(area_m2)/sqrt(sum(count)))))/10000
  )
  
  
  for(j in 1:length(habitat_types)) {
    tab<-as.data.frame(burn_per_area %>% filter(habitat==habitat_types[j]))
    
    if (dim(tab)[1]>0) {
      
    tab2 <- as.data.frame(tab %>% 
        mutate(mean_area_percent=mean_ha2/(Herd_area$total.area[Herd_area$BCHab_code==habitat_types[j]])*100,
          median_area_percent = median_ha2/Herd_area$total.area[Herd_area$BCHab_code==habitat_types[j]]*100,     max_area_percent=max_ha2/Herd_area$total.area[Herd_area$BCHab_code==habitat_types[j]]*100,
          CI_90_percent=CI_90_upper_ha2/Herd_area$total.area[Herd_area$BCHab_code==habitat_types[j]]*100,
          CI_95_percent=CI_95_upper_ha2/Herd_area$total.area[Herd_area$BCHab_code==habitat_types[j]]*100))
  
  tab2$Herd_name<-Herd_name[i]
  
  nam<-paste(Herd_name[i],habitat_types[j],sep="_")
  assign(nam,tab2)
  filenames<-append(filenames,nam)
  
  
  
    }
  }
  
summary_table<- rbind(rbind(rbind(rbind(rbind(rbind(rbind(rbind(rbind(rbind(rbind(rbind(rbind(rbind(Wells_Gray_North_HEWSR,Wells_Gray_North_Matrix),Charlotte_Alplands_HEWSR),Charlotte_Alplands_LEWR),Charlotte_Alplands_Matrix),Itcha_Ilgachuz_HEWSR),Itcha_Ilgachuz_LESR),Itcha_Ilgachuz_LEWR),Itcha_Ilgachuz_Matrix),Rainbows_HEWSR),Rainbows_LESR),Rainbows_LEWR),Rainbows_Matrix),Barkerville_HEWSR),Barkerville_Matrix)

#write.csv(summary_table, "C:\\Work\\caribou\\clus_data\\Fire\\Results\\summary_table.csv")



# create plot for each herd and save it to file
plot<-ggplot(Fire_area, aes(x = area_m2/10000)) + 
  theme_bw() +
  theme(text = element_text(size=16))+
  geom_histogram(bins=50) +
  facet_grid(habitat~.) +
  labs(y="Frequency", x="Area burned (ha^2)")+ 
  geom_vline(data=burn_per_area, aes(xintercept=mean_ha2))+
  geom_vline(data=burn_per_area, aes(xintercept=CI_95_upper_ha2),
             linetype="dashed")

nam<-paste("Plot",Herd_name[i],"pdf",sep=".")
assign(nam,plot)

ggsave(nam)

}




