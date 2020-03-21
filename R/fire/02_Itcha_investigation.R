require(rgdal)
require(plyr)
require(dplyr)
require(sf)
require(ggplot2)
require(tidyr)
require(rgeos)
require(sp)
options(scipen=999)

# read in fire data
fire.bound<-read.csv("C:\\Work\\caribou\\clus_data\\Fire\\fire_sum_crithab.csv",header=FALSE,col.names=c("area_m2","HERD_NAME","habitat","year"))
head(fire.bound)

Herd_name<-c("Central_Selkirks","Columbia_North","Groundhog", "Monashee", "Purcell_Central", "Purcell_South","South_Selkirks","Wells_Gray_South","Columbia_South","Hart_Ranges","North_Cariboo","Telkwa","Wells_Gray_North","Central_Rockies","Charlotte_Alplands","Itcha_Ilgachuz","Rainbows","Barkerville","Narrow_Lake","Frisby_Boulder","Redrock_Prairie_Creek")
Years<-1919:2018
habitat_types<-c("HEWSR","Matrix","LEWR","LESR")
window_size<-40

Itcha_fire<-fire.bound %>%
  filter(year>=1978, HERD_NAME=="Itcha_Ilgachuz")

mu <- ddply(Itcha_fire, "habitat", summarise, grp.mean=mean(area_m2))
# calculating 95% confidence interval . Used Whitlock and Schluter pg 309 (CI for mean of normal distribution. Probably not right so should consider this further.But for now...)
habitat<-c("Matrix","HEWSR","LESR", "LEWR")
grp.95.CI<-c(14076+2.04*(56011/sqrt(32)),2376+2.31*(3154/sqrt(9)), 5746+2.31*(12521/sqrt(9)),5136+2.05*(19078/sqrt(28)))
grp.90.CI<-c(14076+1.7*(56011/sqrt(32)),2376+1.86*(3154/sqrt(9)), 5746+1.86*(12521/sqrt(9)),5136+1.7*(19078/sqrt(28)))
m4<-as.data.frame(cbind(habitat,grp.95.CI,grp.90.CI))
m4$grp.95.CI<-as.numeric(as.character(m4$grp.95.CI))
m4$grp.90.CI<-as.numeric(as.character(m4$grp.90.CI))

head(mu)

ggplot(Itcha_fire, aes(x = area_m2/10000)) + 
  theme_bw() +
  theme(text = element_text(size=18))+
  geom_histogram(bins=60) +
    facet_grid(habitat~.) +
  geom_vline(data=mu, aes(xintercept=grp.mean/10000 ,color="red"),
             linetype="dashed")+
  labs(y="Frequency", x="Area burned (ha^2)")+ 
  geom_vline(data=mu4, aes(xintercept=grp.95.CI/10000))
  

fire.bound$count<-1
Itcha_summary<-fire.bound %>%
  filter(year>=1978, HERD_NAME=="Itcha_Ilgachuz") %>%
  group_by(habitat) %>%
  summarise(mean_ha2=mean(area_m2/10000),
          median_ha2=median(area_m2/10000),
          max_ha2=max(area_m2/10000),
          min_ha2=min(area_m2/10000),
          #sd_ha=sd(area_m2/10000),
         # number=sum(count))
          #CI_95_upper_ha2=mean(area_m2/10000)+(1.96*(sd(area_m2/10000)/sqrt(sum(count)))),
          #CI_90_upper_ha2=mean(area_m2/10000)+(1.64*(sd(area_m2/10000)/sqrt(sum(count))))
          )


## BC herd areas

BC_caribou_habitat<-st_read(dsn="T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\caribou\\bc_critical_habitat\\BC_caribou_core_matrix_habitat_v20190904_1_shp\\BC_caribou_core_matrix_habitat_v20190904_1\\BC_caribou_core_matrix_habitat_v20190904_1.shp", stringsAsFactors = T,quiet=TRUE)

plot(BC_caribou_habitat,max.plot=1)

Itcha<-BC_caribou_habitat %>% 
  filter(Herd_Name=="Itcha-Ilgachuz") %>%
  group_by(BCHab_code) %>%
  summarise(total.area<-sum(Area_Ha)) %>%
  st_set_geometry(NULL)

Areas<-c(143883,874604,746573,210420)

for (i in 1:length(habitat_types)){
  
tab<-as.data.frame(Itcha_summary %>% filter(habitat==habitat_types[i]) %>%
  mutate(mean_area_percent=mean_ha2/Areas[i]*100,
         median_area_percent = median_ha2/Areas[i] *100,
         max_area_percent=max_ha2/Areas[i]*100,
         min_area_percent=min_ha2/Areas[i]*100))
         
  tab2<- as.data.frame(m4 %>% filter(habitat==habitat_types[i]) %>%
   mutate(CI_90_percent=grp.90.CI/Areas[i]*100,
          CI_95_percent=grp.95.CI/Areas[i]*100))
    
    tab3<-join(tab,tab2)

  
  nam1<-paste("area",habitat_types[i],sep=".") #defining the name

  assign(nam1,tab3)
}

summary_area_burned<-rbind(area.HEWSR,area.Matrix,area.LEWR,area.LESR)
write.csv(summary_area_burned, "C:\\Work\\caribou\\clus_data\\Fire\\Results\\summary_area_burned.csv")
