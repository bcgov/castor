require(rgdal)
require(plyr)
require(dplyr)
require(sf)
require(ggplot2)
require(tidyr)
require(rgeos)
require(sp)
options(scipen=999)

#------------------------------------------------
# read in fire data
setwd("C:\\Work\\caribou\\clus_data\\Fire\\Results")
fire.bound<-read.csv("C:\\Work\\caribou\\clus_data\\Fire\\fire_sum_crithab.csv",header=FALSE,col.names=c("area_m2","HERD_NAME","habitat","year"))
head(fire.bound)

#Herd_name<-c("Central_Selkirks","Columbia_North","Groundhog", "Monashee", "Purcell_Central", "Purcell_South","South_Selkirks","Wells_Gray_South","Columbia_South","Hart_Ranges","North_Cariboo","Telkwa","Wells_Gray_North","Central_Rockies","Charlotte_Alplands","Itcha_Ilgachuz","Rainbows","Barkerville","Narrow_Lake","Frisby_Boulder","Redrock_Prairie_Creek")

Herd_name<-c("Wells_Gray_North","Charlotte_Alplands","Itcha_Ilgachuz","Rainbows","Barkerville")
Years<-1919:2018
habitat_types<-c("HEWSR","LESR","LEWR","Matrix")
fire.bound$count<-1
fire.bound$area_m2<-as.numeric(fire.bound$area_m2)

for (i in 1:length(Herd_name)){

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

#####
# Calculating the total area of each habitat type
## BC herd areas

BC_caribou_habitat<-st_read(dsn="T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\caribou\\bc_critical_habitat\\BC_caribou_core_matrix_habitat_v20190904_1_shp\\BC_caribou_core_matrix_habitat_v20190904_1\\BC_caribou_core_matrix_habitat_v20190904_1.shp", stringsAsFactors = T,quiet=TRUE)

plot(BC_caribou_habitat,max.plot=1)

Itcha<-BC_caribou_habitat %>% 
  filter(Herd_Name=="Itcha-Ilgachuz") %>%
  group_by(BCHab_code) %>%
  summarise(total.area=sum(Area_Ha)) %>%
  st_set_geometry(NULL)


for (i in 1:length(habitat_types)){
  
tab<-as.data.frame(Itcha_summary %>% filter(habitat==habitat_types[i]) %>%
  mutate(mean_area_percent=mean_ha2/(Itcha$total.area[Itcha$BCHab_code==habitat_types[i]])*100,
         median_area_percent = median_ha2/Itcha$total.area[Itcha$BCHab_code==habitat_types[i]]*100,
         max_area_percent=max_ha2/Itcha$total.area[Itcha$BCHab_code==habitat_types[i]]*100,
         min_area_percent=min_ha2/Itcha$total.area[Itcha$BCHab_code==habitat_types[i]]*100,
         CI_90_percent=CI_90_upper_ha2/Itcha$total.area[Itcha$BCHab_code==habitat_types[i]]*100,
         CI_95_percent=CI_95_upper_ha2/Itcha$total.area[Itcha$BCHab_code==habitat_types[i]]*100))
         
  
  nam1<-paste("area",habitat_types[i],sep=".") #defining the name

  assign(nam1,tab)
}

summary_area_burned<-rbind(area.HEWSR,area.Matrix,area.LEWR,area.LESR)
write.csv(summary_area_burned, "C:\\Work\\caribou\\clus_data\\Fire\\Results\\summary_area_burned.csv")
