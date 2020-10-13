library(raster)
library(data.table)
library(sf)
library(tidyverse)
library(rgeos)
library(bcmaps)
library(ggplot2)

source(here::here("R/functions/R_Postgres.R"))

# Layers needed:
# 1.) Fire ignition history, 2.) vegetation, 3.) Weather (monthly mean rainfall, monthly mean max temp, monthly average temp)

#### FIRE IGNITION DATA ####
fire.ignit.hist<-sf::st_read(dsn="C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\BCGW_7113060B_1600358424324_13780\\PROT_HISTORICAL_INCIDENTS_SP\\H_FIRE_PNT_point.shp")
st_crs(fire.ignit.hist)
head(fire.ignit.hist)
#lighting.hist<-fire.ignit.hist %>% filter(FIRE_CAUSE=="Lightning", FIRE_TYPE=="Fire")
fire.ignit.hist <- st_transform (fire.ignit.hist, 3005)

prov.bnd <- st_read ( dsn = "T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\admin_boundaries\\province\\gpr_000b11a_e.shp", stringsAsFactors = T)
st_crs(prov.bnd)
prov.bnd <- prov.bnd [prov.bnd$PRENAME == "British Columbia", ] 
bc.bnd <- st_transform (prov.bnd, 3005)
lightning_clipped<-fire.ignit.hist[bc.bnd,]
str(lightning_clipped)
lightning_clipped$FIRE_YEAR <- as.character(lightning_clipped$FIRE_YEAR)
st_write(lightning_clipped, dsn="C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\bc_fire_ignition.shp")

## Load ignigition data into postgres (either my local one or Kyles)
host=keyring::key_get('dbhost', keyring = 'postgreSQL')
user=keyring::key_get('dbuser', keyring = 'postgreSQL')
dbname=keyring::key_get('dbname', keyring = 'postgreSQL')
password=keyring::key_get('dbpass', keyring = 'postgreSQL')

ogr2ogr -f "PostgreSQL" PG:"host=localhost user=postgres dbname=postgres password=postgres port=5432" C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\bc_fire_ignition.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI


#### TEMPERATURE DATA ####
# To get temperature data Im pulling out the fires that started in the years 2002 : 2019 and writing them as a csv file so that I can go and extract the relevant weather data from climateBC (https://cfcg.forestry.ubc.ca/projects/climate-data/climatebcwna/). 

setwd("C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\input")

lightning_clipped$FIRE_YEAR<-as.numeric(lightning_clipped$FIRE_YEAR)
x <- lightning_clipped %>% 
  filter(FIRE_YEAR >= 2002)%>%
  select(FIRE_ID, FIRE_YEAR, LATITUDE, LONGITUDE) %>%
  rename(ID1 = FIRE_ID, ID2 = FIRE_YEAR, lat = LATITUDE, long = LONGITUDE)

  x$el<-"."
  x2<-st_set_geometry(x,NULL)
  write.csv(x2, file="Fire.Ignition.points.csv", row.names = FALSE)

#years<- c("2002", "2003", "2004", "2005", "2006", "2007", "2008", "2009", "2010", "2011", "2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019")
# for (i in 1:length(years)) {
# x<- lightning_clipped %>% 
#   filter(FIRE_YEAR==years[i]) %>% 
#   select(FIRE_NO, FIRE_YEAR, LATITUDE, LONGITUDE) %>%
#   rename(ID1 = FIRE_NO, ID2 = FIRE_YEAR, lat = LATITUDE, long = LONGITUDE)
# x$el<-"."
# x2<-st_set_geometry(x,NULL)
# 
# name<-paste("ignitions", years[i], "csv", sep=".")
# write.csv(x2, file = name, row.names = FALSE )
# 
# }

#I then manually extract the monthly climate data for each of the relevant years at each of the fire ignition locations and saved the files as .csv's. Here I import them again.

file.list<-list.files("C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\output", pattern=".csv", all.files=FALSE, full.names=FALSE)
y<-gsub(".csv","",file.list)

setwd("C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\output")
for (i in 1:length(file.list)){
  assign(paste0(y[i]),read.csv (file=paste0(file.list[i])))
}

## calculate the drought code for each month

##############
# Equations
##############
years<- c("2002", "2003", "2004", "2005", "2006", "2007", "2008", "2009", "2010", "2011", "2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019")

file.list<-list.files("C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\output", pattern=".csv", all.files=FALSE, full.names=FALSE)
y<-gsub("M.csv","",file.list)
y2 <- gsub("Fire.Ignition.points_", "", y)

# Read in weather data
setwd("C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\output")
for (i in 1:length(file.list)){
  assign(paste0(y2[i]),read.csv (file=paste0(file.list[i])))
}

lightning_clipped2<- lightning_clipped %>% 
  filter (FIRE_YEAR>=2002, FIRE_TYPE=="Fire") %>%
  select(FIRE_ID, FIRE_YEAR : FIRE_CAUSE, FIRE_TYPE, SIZE_HA, geometry)

# Parameters to calculate monthly drought code (DC)

days_month<- c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31) # number of days in each month starting in Jan
#### Daylength adjustment factor (Lf) [Development and Structure of the Canadian Forest Fire Weather Index System pg 15, https://d1ied5g1xfgpx8.cloudfront.net/pdfs/19927.pdf] ####
# Month <- Lf value
# LF[1] is the value for Jan
Lf<-c(-1.6, -1.6, -1.6, 0.9, 3.8, 5.8, 6.4, 5.0, 2.4, 0.4, -1.6, -1.6)
####


filenames<-list()
for (i in 1: length(y2)){
  
  x<-eval(as.name(y2[i])) %>% 
    rename(FIRE_ID=ID1, FIRE_YEAR=ID2) %>%
    select(FIRE_ID, FIRE_YEAR, Tmax05:Tmax09, Tave05:Tave09, PPT05:PPT09, PAS05:PAS09)
  
  for (j in 5 : 9) {
    
    x$MDC_04<-15
    
    Em<- days_month[j]*((0.36*x[[paste0("Tmax0",j)]])+Lf[j])
    Em <- ifelse(Em<0, 0, Em)
    DC_half<- x[[paste0("MDC_0",j-1)]] + (0.25 * Em)
    RMeff<-(0.83 * (x[[paste0("PPT0",j)]] + (x[[paste0("PAS0",j)]]/10)))
    Qmr<- (800 * exp(-(DC_half)/400)) + (3.937 * RMeff)
    Qmr2 <- ifelse(Qmr>800, 800, Qmr)
    MDC_m <- 400 * log(800/Qmr2) + 0.25*Em
    x[[paste0("MDC_0",j)]] <- (x[[paste0("MDC_0",j-1)]] + MDC_m)/2
    x[[paste0("MDC_0",j)]] <- ifelse(x[[paste0("MDC_0",j)]] <15, 15, x[[paste0("MDC_0",j)]])
    
    
  }
  
  nam1<-paste("DC",y2[i],sep=".") #defining the name
  assign(nam1,x)
  filenames<-append(filenames,nam1)
}
  
  
  
  
  
  
  
  
  x2<-left_join(lightning_clipped2, x, by= c("FIRE_ID", "FIRE_YEAR"))
  nam1<-paste("Fire_weather",y2[i],sep="_") #defining the name
  assign(nam1,x2)
  filenames<-append(filenames,nam1)
}




lightning_weather2$Em_04 <- days_month[[5]] * ((0.36*lightning_weather2$Tmax01)+Lf[[5]])

dc_0<-15 # initial drought code value. Took this value from https://pacificclimate.org/sites/default/files/publications/evaluation_of_the_monthly_drought_code.pdf, who use it in their study and assumed it reset to 15 at the start of every May.

lightning_weather2$DC_half_04<- dc_0 + (0.25*lightning_weather2$Em_04)
lightning_weather2$Qmr_04<- (3.937 * 0.83 * (lightning_weather2$PPT04 + lightning_weather2$PAS04/10))/(800 * exp(-dc_0/400))
lightning_weather2$DC_mr_04<-lightning_weather2$DC_half_04 - 400 * log(1+lightning_weather2$Qmr_04)
lightning_weather2$MDC_m_04<-lightning_weather2$DC_mr_04 + (0.25 * lightning_weather2$Em_04)

lightning_weather2$MDC_04 <- (dc_0 + lightning_weather2$MDC_m_04)/2








data<- lightning_weather %>%
  filter(FIRE_YEAR >= 2002)



 



#### VEGETATION DATA #### 
#downloaded for years 2002 to 2019. These are the only years that VRI data exists for there is no earlier data.
#from https://catalogue.data.gov.bc.ca/dataset/vri-historical-vegetation-resource-inventory-2002-2018-
# I then extracted this data and uploaded it into my local postgres database by running the command below in terminal. 

#ogr2ogr -f "PostgreSQL" PG:"host=localhost user=postgres dbname=postgres password=postgres port=5432" C:\\Work\\caribou\\clus_data\\Fire\\VRI_data\\veg_comp_lyr_r1_poly2003.gdb -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI

# rename the table in postgres if need be
#ALTER TABLE veg_comp_lyr_r1_poly RENAME TO veg_comp_lyr_r1_poly2017

# When the table name is changed the idx name is not so you might have to change that too so that more files can be uploaded into postgres by running the following command
#ALTER INDEX veg_comp_lyr_r1_poly_finalv4_geometry_geom_idx RENAME TO veg_comp_lyr_r1_poly2002_geometry_geom_idx

#### Join ignition data to VRI data ####
# Run following query in postgres. This is fast
#CREATE TABLE Fire_veg_2016 AS
#(SELECT feature_id, bclcs_level_2, bclcs_level_3, bclcs_level_4, bclcs_level_5, 
#  fire.fire_id, fire.fire_no, fire.fire_year, fire.fire_cause, fire.size_ha, veg_comp_lyr_r1_poly20# 16.geometry FROM veg_comp_lyr_r1_poly2016, (SELECT wkb_geometry, fire_id, fire_no, fire_year, fire_cause, size_ha  from bc_fire_ignition 
#  where fire_type = 'Fire' and fire_year = '2016') as fire 
#  where st_contains (veg_comp_lyr_r1_poly2016.geometry, fire.wkb_geometry));


# This also works but is super slow, dont run this one!
# CREATE TABLE Fire_veg_2002 AS (WITH ignit as 
#         (SELECT fire_no, fire_year, fire_cause, size_ha, wkb_geometry from bc_fire_ignition 
#         where fire_type = 'Fire' and fire_year = '2002'), 
#         veg as (SELECT bclcs_level_4, bclcs_level_5, geometry FROM veg_comp_lyr_r1_poly2002 where bclcs_level_2 = 'T') 
#         SELECT veg.geometry as geom, fire_no, fire_year, fire_cause, size_ha, bclcs_level_4, bclcs_level_5 
#         FROM ignit, veg WHERE st_intersects (ignit.wkb_geometry, veg.geometry));


#### Join ignition, VRI and climate data #### 





# Plot provincial boundary and lightning strikes. Looks good.
ggplot() +
  geom_sf(data=bc.bnd) +
  geom_sf(data=lightning_clipped)

st_write(lightning_clipped, dsn = "C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\lightning_strikes.shp", delete_layer=TRUE)

# commit the shape file to postgres
# this works for loading the shape file onto Kyles Postgres. Run these sections of code below in R and fill in the details in the script for command prompt. Then run the ogr2ogr script in command prompt to get the table into postgres

host=keyring::key_get('dbhost', keyring = 'postgreSQL')
user=keyring::key_get('dbuser', keyring = 'postgreSQL')
dbname=keyring::key_get('dbname', keyring = 'postgreSQL')
password=keyring::key_get('dbpass', keyring = 'postgreSQL')

# Run this in terminal
#ogr2ogr -f PostgreSQL PG:"host= user= dbname= password= port=5432" C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\lightning_strikes.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI






forest.tenure<-getSpatialQuery("SELECT * FROM tsa_aac_bounds")
forest.tenure <- st_transform (forest.tenure, 3005)
North<-forest.tenure %>% filter(tsa_name=="Fort_St_John_TSA"| tsa_name == "Fort_St_John_Core_TSA" | tsa_name == "Dawson_Creek_TSA" | tsa_name == "MacKenzie_TSA" | tsa_name == "TFL48" | tsa_name == "MacKenzie_SW_TSA")

lightning_clipped<-lighting.hist[North,]

ggplot() +
  #geom_sf(data=bc.bnd) +
  geom_sf(data=North) +
  geom_sf(data=lightning_clipped)

lightning_clipped$FIRE_MONTH<-substr(lightning_clipped$IGN_DATE,5,6)
lightning_clipped <- lightning_clipped[!is.na(lightning_clipped$FIRE_MONTH) ,]

# get vegetation layer
layer<-getSpatialQuery("SELECT object_id, geometry FROM public.veg_comp_lyr_r1_poly2018")
veg <- st_transform (layer, 3005)
veg.lightning<-st_intersection(lightning_clipped,veg)




forest.tenure.ras <-fasterize::fasterize(sf= forest.tenure, raster = ProvRast , field = "tsa_number")





for (j in 5 : 10) {
  
  x[[paste0("Em0",j)]]<- days_month[j]*((0.36*x[[paste0("Tmax0",j)]])+Lf[j])
  
  #dc_0 <- 15 # initial drought code value. Took this value from https://pacificclimate.org/sites/default/files/publications/evaluation_of_the_monthly_drought_code.pdf, who use it in their study and assumed it reset to 15 at the start of every May.
  dc_0<- if_else(j<6, 15, x[[paste0("MDC_0",j-1)]])
  print(dc_0)
  
  x[[paste0("DC_half_0",j)]]<- dc_0 + (0.25 * x[[paste0("Em0",j)]])
  x[[paste0("Qmr_0",j)]] <- (3.937 * 0.83 * (x[[paste0("PPT0",j)]] + x[[paste0("PAS0",j)]]/10))/(800 * exp(-dc_0/400))
  x[[paste0("DC_mr_0",j)]]<- x[[paste0("DC_half_0",j)]] - 400 * log(1+x[[paste0("Qmr_0",j)]])
  x[[paste0("MDC_m_0",j)]]<-x[[paste0("DC_mr_0",j)]] + (0.25 * x[[paste0("Em0",j)]])
  x[[paste0("MDC_0",j)]] <- (dc_0 + x[[paste0("MDC_m_0",j)]])/2
  


