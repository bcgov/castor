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
#  Script Purpose: Script estimates the area burned both as total area and a proportion of total area per herd home range and habitat type
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

Herd_name<-c("Central_Selkirks","Columbia_North","Groundhog", "Monashee", "Purcell_Central", "Purcell_South","South_Selkirks","Wells_Gray_South","Columbia_South","Hart_Ranges","North_Cariboo","Telkwa","Wells_Gray_North","Central_Rockies","Charlotte_Alplands","Itcha_Ilgachuz","Rainbows","Barkerville","Narrow_Lake","Frisby_Boulder","Redrock_Prairie_Creek")

#Herd_name<-c("Wells_Gray_North","Charlotte_Alplands","Itcha_Ilgachuz","Rainbows","Barkerville")
Herd_name_bc<-c("Central Selkirks","Columbia North","Groundhog", "Monashee", "Purcell Central", "Purcell South","South Selkirks","Wells Gray South","Columbia South","Hart Ranges","North Cariboo","Telkwa","Wells Gray North","Central Rockies","Charlotte Alplands","Itcha-Ilgachuz","Rainbows","Barkerville","Narrow Lake","Frisby Boulder","Redrock-Prairie Creek")
  
Years<-1919:2018
habitat_types<-c("HEWSR","LESR","LEWR","Matrix")
fire.bound$count<-1
fire.bound$area_m2<-as.numeric(fire.bound$area_m2)

Fire_results_tab <- data.frame (matrix (ncol = 10, nrow = 0))
colnames (Fire_results_tab) <- c ("herd_name","habitat","mean_ha2","max_ha2","min_ha2","cummulative_area_ha2","mean_area_percent", "max_area_percent", "min_area_percent","cummulative_area_percent" )


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
            max_ha2=(max(area_m2))/10000,
            min_ha2=min(area_m2)/10000,
            cummulative_area_ha2=tail(cumsum(area_m2/10000),n=1))
  
  
  for(j in 1:length(habitat_types)) {
    tab<-as.data.frame(burn_per_area %>% filter(habitat==habitat_types[j]))
    
    if (dim(tab)[1]>0) {
      
    tab2 <- as.data.frame(tab %>% 
        mutate(mean_area_percent=mean_ha2/(Herd_area$total.area[Herd_area$BCHab_code==habitat_types[j]])*100,
          max_area_percent=max_ha2/Herd_area$total.area[Herd_area$BCHab_code==habitat_types[j]]*100,
          min_area_percent=min_ha2/Herd_area$total.area[Herd_area$BCHab_code==habitat_types[j]]*100,
          cummulative_area_percent=cummulative_area_ha2/Herd_area$total.area[Herd_area$BCHab_code==habitat_types[j]]*100
          ))
  
  tab2$herd_name<-Herd_name_bc[i]
  
  Fire_results_tab<-rbind(Fire_results_tab,tab2)

    }
  }

}

Fire_results_tab<- data.table(Fire_results_tab)
Fire_results_tab[, herd_bounds:= paste(herd_name, habitat, sep=" ")]

# write data to the virtual machine
conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='206.12.91.188', dbname = 'clus', port='5432', user='appuser', password='sHcL5w9RTn8ZN3kc')
dbWriteTable(conn,c("public","firesummary"),Fire_results_tab, overwrite=T)
dbDisconnect(conn)



Burned<-fire.bound %>%
  filter(HERD_NAME==Herd_name[i]) 

# create plot for each herd and save it to file
plot<-ggplot(Burned, aes(x=year,y = area_m2/10000)) + 
  theme_bw() +
  theme(text = element_text(size=16))+
  geom_bar(stat="identity" ) +
  facet_grid(habitat~.) +
  labs(y="Area burned (ha2)", x="Year")
  #geom_vline(data=burn_per_area, aes(xintercept=mean_ha2)) 
  #geom_vline(data=burn_per_area, aes(xintercept=CI_95_upper_ha2),
             #linetype="dashed")
