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
#  Script Name: 01_data_prep_fire_ignition_v2.R
#  Script Version: 1.0
#  Script Purpose: Prepare data for provincial analysis of fire ignitions. This includes obtaining weather data from climate BC, vegetation data from the Vegetation Resource inventory, and fire ignitions from Fire Incident Locations hosted on the Data Catalogue
#  Script Author: Elizabeth Kleynhans, Ecological Modeling Specialist, Forest Analysis and Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#=================================


library(raster)
library(data.table)
library(sf)
library(tidyverse)
library(rgeos)
library(bcmaps)
library(ggplot2)
require (RPostgreSQL)
require (rpostgis)
require (fasterize)
require (dplyr)

source(here::here("R/functions/R_Postgres.R"))

#### Provincial boundary with fire ignitions clipped out of it. 
# The goal is to get climate, vegetation and fire ignition (presence or abscence) data together to run an statistical model to see if I can figure out places that fires are likely to start. In this file Im just pulling the data together.
# The fire ignition data I obtained from (https://catalogue.data.gov.bc.ca/dataset/fire-perimeters-historical : WHSE_LAND_AND_NATURAL_RESOURCE_ PROT_HISTORICAL_FIRE_POLYS_SP)
# I started by clipping out the fire ignition areas (buffered by 500m) across BC so that I could sample points across BC where fires had not started. Then I sample points on a grid across BC to get my data for places where fires did not start. 
bc.tsa <- st_read ( dsn = "C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\Ignition_clipped.shp", stringsAsFactors = T)# In QGIS I buffered the location where a fire started by 500m and then clipped out the buffered locations between the years 2002 - 2019 from the bc tsa boundaries.  I wanted to do this for each year separately but could not work out how to do this in QGIS and when I tried to do it in R, R crashed my whole computer so after trying 4 times I gave up. 
bc.tsa <-bc.tsa %>% 
  filter (administra != 'Queen Charlotte Timber Supply Area') %>%
  filter(administra != 'North Island Timber Supply Area') %>%
  filter(administra != 'Arrowsmith Timber Supply Area') %>%
  filter(administra != 'Pacific Timber Supply Area')
bc.tsa <- st_transform (bc.tsa, 3005)
tsa.points<- st_sample(bc.tsa, size=20000, type="regular")
tsa.points<-st_transform(tsa.points,3005)
tsa.points.transformed <- st_transform(tsa.points, "+proj=longlat +datum=NAD83 / BC Albers +no_defs")
st_crs(tsa.points.transformed)
tsa.points.transformed1<-as.data.frame(tsa.points.transformed)
# Try find a way to split the data up into 3 colums and the remove the brackets. 
tsa.points.transformed2<- tsa.points.transformed1 %>%
  separate(geometry, into = c("lon", "lat")," ")
tsa.points.transformed2$lon<- as.character(tsa.points.transformed2$lon)
tsa.points.transformed2$lon<- gsub(",", "", as.character(tsa.points.transformed2$lon) )
tsa.points.transformed2$lon<- substring(tsa.points.transformed2$lon, 3)
tsa.points.transformed2$lon<- as.numeric(tsa.points.transformed2$lon)
tsa.points.transformed2$lon<- round(tsa.points.transformed2$lon, digits=4)
tsa.points.transformed2$lat<- gsub(")", "", as.character(tsa.points.transformed2$lat) )
tsa.points.transformed2$lat<- as.numeric(tsa.points.transformed2$lat)
tsa.points.transformed2$lat<- round(tsa.points.transformed2$lat, digits=4)

# these are the sample points for where fires did not start.
sample.pts <- data.frame (matrix (ncol = 5, nrow = nrow (tsa.points.transformed1)))
colnames (sample.pts) <- c ("ID1","ID2", "lat", "long", "el")
sample.pts$ID1<- 1:length(tsa.points.transformed2$lon)
sample.pts$ID2 <- 0
sample.pts$lat <-as.numeric(tsa.points.transformed2$lat)
sample.pts$long <- as.numeric(tsa.points.transformed2$lon)
sample.pts$el <- "."

write_csv(sample.pts, path="C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\input\\sample_pts.csv")

sample.pts.joined <- cbind(sample.pts,tsa.points.transformed1)


#### GET CLIMATE DATA FOR LOCATIONs WHERE FIRES STARTED ####
# First import the fire data
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

lightning_clipped<- st_read(dsn="C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\bc_fire_ignition.shp")

lightning_clipped <- st_transform (lightning_clipped, 3005)

# To get climate data Im pulling out the fires that started in the years 2002 : 2019 and writing them as a csv file so that I can go and extract the relevant weather data from climateBC (https://cfcg.forestry.ubc.ca/projects/climate-data/climatebcwna/). 

setwd("C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\input")

lightning_clipped$fire_year_new<-as.numeric(as.character(lightning_clipped$FIRE_YEAR))
x <- lightning_clipped %>% 
  filter(fire_year_new >= 2002) %>%
  dplyr::select(FIRE_ID, FIRE_YEAR, LATITUDE, LONGITUDE) %>%
  rename(ID1 = FIRE_ID, ID2 = FIRE_YEAR, lat = LATITUDE, long = LONGITUDE)

x$el<-"."
x2<-st_set_geometry(x,NULL)
write.csv(x2, file="Fire.Ignition.points.csv", row.names = FALSE)


# ID1 is the fire_id and ID2 is the year the fire occured in the file bc_fire_ignition 
#I then manually extract the monthly climate data for each of the relevant years at each of the fire ignition locations from climate BC (http://climatebc.ca/) and saved the files as .csv's. Here I import them again.

file.list1<-list.files("C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\output", pattern="ignition.", all.files=FALSE, full.names=FALSE)
y1<-gsub(".csv","",file.list1)

setwd("C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\output")
for (i in 1:length(file.list1)){
  assign(paste0(y1[i]),read.csv (file=paste0(file.list1[i])))
}

#### GET CLIMATE DATA FOR LOCATIONs WHERE FIRES DID NOT START ####
#I also manually extract the monthly climate data for each of the random locations within BC that I sampled for each year from climate BC (http://climatebc.ca/) and saved the files as .csv's. Here I import them again.

file.list2<-list.files("C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\output", pattern="sample_pts_Year", all.files=FALSE, full.names=FALSE)
y2<-gsub(".csv","",file.list2)

years<- c("2002", "2003", "2004", "2005", "2006", "2007", "2008", "2009", "2010", "2011", "2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019")

setwd("C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\output")
for (i in 1:length(file.list2)){
  x<-read.csv (file=paste0(file.list2[i]))
  x$YEAR<- years[i]
  assign(paste0(y2[i]),x)
}

# FOR EACH DATASET CALCULATE THE MONTHLY DROUGHT CODE

#######################################
#### Equations to calculate drought code ####
#######################################

days_month<- c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31) # number of days in each month starting in Jan
#### Daylength adjustment factor (Lf) [Development and Structure of the Canadian Forest Fire Weather Index System pg 15, https://d1ied5g1xfgpx8.cloudfront.net/pdfs/19927.pdf] ####
# Month <- Lf value
# LF[1] is the value for Jan
Lf<-c(-1.6, -1.6, -1.6, 0.9, 3.8, 5.8, 6.4, 5.0, 2.4, 0.4, -1.6, -1.6)
####

### Calculate drought code for Fire ignition data
filenames<-list()
for (i in 1: length(y1)){
  
  x<-eval(as.name(y1[i])) %>% 
    rename(YEAR=ID2) %>%
    dplyr::select(ID1, YEAR,Latitude, Longitude, Tmax05:Tmax09, Tave05:Tave09, PPT05:PPT09, PAS05:PAS09)
  
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
  nam1<-paste("DC.ignition",y2[i],sep="") #defining the name
  assign(nam1,x)
  filenames<-append(filenames,nam1)
}

# combind all the DC.ignition files together
mkFrameList <- function(nfiles) {
  d <- lapply(seq_len(nfiles),function(i) {
    eval(parse(text=filenames[i]))
  })
  do.call(rbind,d)
}

n<-length(filenames)
DC.ignitions<-mkFrameList(n) 
DC.ignitions$ID1<- as.factor(DC.ignitions$ID1)
DC.ignitions$pttype <- 1

dim(DC.ignitions) # should have 57984 rows.
names(DC.ignitions)
DC.ignitions1<- DC.ignitions %>% rename(FIRE_NO=ID1) 
lightning_clipped$FIRE_NO <- as.factor(as.character(lightning_clipped$FIRE_NO))
lightning_clipped$FIRE_YEAR <- as.numeric(as.character(lightning_clipped$FIRE_YEAR))
lightning_clipped_red<- lightning_clipped %>% 
  #filter(FIRE_CAUSE!="Person") %>%
  filter(FIRE_YEAR >=2002) %>%
  rename(YEAR=FIRE_YEAR)

# Now join DC.ignitions back with the original fire ignition dataset
ignition_weather<-left_join(DC.ignitions1, lightning_clipped_red)
head(ignition_weather)
dim(ignition_weather) # should have 57984 rows
st_crs(ignition_weather)
ignition_weather_crs <- st_as_sf(ignition_weather)
crs(ignition_weather_crs)
ignition_weather_crs<- st_transform(ignition_weather_crs, 3005)

# Check the points line up with BC boundaries!
ggplot() +
  geom_sf(data=bc.tsa, col='red') +
  geom_sf(data=ignition_weather_crs, col='black') # looks good!



### Calculate the drought code for all Random point data i.e. where ignitions did not occur
filenames2<-list()
for (i in 1: length(y2)){
  
  x<-eval(as.name(y2[i])) %>% 
    dplyr::select(ID1, YEAR, Latitude, Longitude, Tmax05:Tmax09, Tave05:Tave09, PPT05:PPT09, PAS05:PAS09) %>%
    filter(Tmax05 != -9999)
  
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
  nam1<-paste("DC_",y2[i],sep="") #defining the name
  assign(nam1,x)
  filenames2<-append(filenames2,nam1)
}

# combind all the DC_sample_pts files together
mkFrameList <- function(nfiles) {
  d <- lapply(seq_len(nfiles),function(i) {
    eval(parse(text=filenames2[i])) # for new files lists change the name at filenames2
  })
  do.call(rbind,d)
}

rm(n)
n<-length(filenames2)
DC.sample.pts<-mkFrameList(n)
DC.sample.pts$ID1<- as.factor(DC.sample.pts$ID1)
DC.sample.pts$pttype <- 0

tsa.points1<- st_sf(tsa.points)
tsa.points1$ID1<-1:dim(tsa.points1)[1]
st_crs(tsa.points1)
attr (tsa.points1, "tsa.points") <- "GEOMETRY"
tsa.points2 <- tsa.points1 %>% rename(geometry=tsa.points)

# join DC.sample.pts to the original sf object I created to sample the points. I do this to get the geometry column into DC.sample.pts
tsa.points2$ID1<- as.factor(as.character(tsa.points2$ID1))

sample.pts<-left_join(DC.sample.pts,tsa.points2)

sample.pts_crs <- st_as_sf(sample.pts)
crs(sample.pts_crs)
sample.pts_crs<- st_transform(sample.pts_crs, 3005)

#Checking sample points line up with BC boundary
sample.pts_crs_2002<-sample.pts_crs %>% filter(YEAR=="2002")
ggplot() +
  geom_sf(data=bc.tsa, col='red')+
  geom_sf(data=sample.pts_crs_2002, col='black') # Im not sure, I hope this is ok
   
# make sample points and ignition points have same columns so I can join them
sample.pts_crs$FIRE_CAUSE<-NA
sample.pts_crs1<- sample.pts_crs %>%
  dplyr::select(ID1, YEAR, Tmax05:pttype, FIRE_CAUSE, geometry) 

ignition_weather_crs1<- ignition_weather_crs %>%
  dplyr::select(FIRE_NO, YEAR, Tmax05:pttype, FIRE_CAUSE, geometry)%>%
  rename(ID1=FIRE_NO)

DC_ignitions_and_sample_pts<- rbind(ignition_weather_crs1, sample.pts_crs1)
head(DC_ignitions_and_sample_pts)

DC_ignitions_and_sample_pts %>% group_by(YEAR, pttype) %>% count (YEAR)
lightning_clipped %>% filter(FIRE_YEAR>=2002) %>% group_by(FIRE_YEAR) %>% count (FIRE_YEAR)

######################
# This looks good but make sure the way Im changing the dataframe into a shapefile is correct and check the points are falling where I think they should!
#######################
  
  

st_write(DC_ignitions_and_sample_pts, dsn = "C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\DC_data.shp", delete_layer=TRUE)

# commit the shape file to postgres
# this works for loading the shape file onto Kyles Postgres. Run these sections of code below in R and fill in the details in the script for command prompt. Then run the ogr2ogr script in command prompt to get the table into postgres

# To Kyles Clus
#host=keyring::key_get('dbhost', keyring = 'postgreSQL')
#user=keyring::key_get('dbuser', keyring = 'postgreSQL')
#dbname=keyring::key_get('dbname', keyring = 'postgreSQL')
#password=keyring::key_get('dbpass', keyring = 'postgreSQL')

# Run this in terminal
#ogr2ogr -f PostgreSQL PG:"host= user= dbname= password= port=5432" C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\fire_ignitions.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI

# OR my local machine

# ogr2ogr -f "PostgreSQL" PG:"host=localhost user=postgres dbname=postgres password=postgres port=5432" C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\DC_data.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI

##### NOW GET THE VEGETATION DATA!####

#### VEGETATION DATA #### 
#downloaded for years 2002 to 2019. These are the only years that VRI data exists, there is no earlier data.
#from https://catalogue.data.gov.bc.ca/dataset/vri-historical-vegetation-resource-inventory-2002-2018-
# I then extracted this data and uploaded it into my local postgres database by running the command below in terminal. 

#ogr2ogr -f "PostgreSQL" PG:"host=localhost user=postgres dbname=postgres password=postgres port=5432" C:\\Work\\caribou\\clus_data\\Fire\\VEG_COMP_LYR_R1_POLY.gdb -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI

# rename the table in postgres if need be
#ALTER TABLE veg_comp_lyr_r1_poly RENAME TO veg_comp_lyr_r1_poly2017

# When the table name is changed the idx name is not so you might have to change that too so that more files can be uploaded into postgres by running the following command
#ALTER INDEX veg_comp_lyr_r1_poly_shape_geom_idx RENAME TO veg_comp_lyr_r1_poly2019_geometry_geom_idx;
# and if need be change the name of the geometry column from shape to geometry
#ALTER TABLE veg_comp_lyr_r1_poly2019 RENAME COLUMN shape TO geometry;

#### Join ignition data to VRI data ####
# Run following query in postgres. This is fast
# CREATE TABLE fire_veg_2002 AS
# (SELECT feature_id, bclcs_level_2, bclcs_level_3, bclcs_level_4, bclcs_level_5,bec_zone_code, bec_subzone, bec_variant, harvest_date, age_1, age_2,
# fire.id1, fire.pttype, fire.year, fire.tmax05, fire.tmax06, fire.tmax07, fire.tmax08, fire.tmax09, fire.tave05, fire.tave06, fire.tave07, fire.tave08, fire.tave09, fire.ppt05, fire.ppt06, fire.ppt07, fire.ppt08, fire.ppt09, fire.pas05, fire.pas06, fire.pas07, fire.pas08, fire.pas09, fire.mdc_05, fire.mdc_06, fire.mdc_07,  fire.mdc_08, fire.mdc_09,
#   veg_comp_lyr_r1_poly2002.geometry FROM veg_comp_lyr_r1_poly2002, (SELECT wkb_geometry, id1, pttype, year, tmax05, tmax06, tmax07, tmax08, tmax09, tave05, tave06, tave07, tave08, tave09, ppt05, ppt06, ppt07, ppt08, ppt09, pas05, pas06, pas07, pas08, pas09, mdc_05, mdc_06, mdc_07,  mdc_08, mdc_09
#       from dc_data where year = '2002') as fire
#   where st_contains (veg_comp_lyr_r1_poly2002.geometry, fire.wkb_geometry));


#Import all fire_veg
conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")
fire_veg_2002 <- sf::st_read  (dsn = conn, # connKyle
                              query = "SELECT * FROM public.fire_veg_2002")
fire_veg_2003 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2003")
fire_veg_2004 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2004")
fire_veg_2005 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2005")
fire_veg_2006 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2006")
fire_veg_2007 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2007")
fire_veg_2008 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2008")
fire_veg_2009 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2009")
fire_veg_2010 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2010")
fire_veg_2011 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2011")
fire_veg_2012 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2012")
fire_veg_2013 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2013")
fire_veg_2014 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2014")
fire_veg_2015 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2015")
fire_veg_2016 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2016")
fire_veg_2017 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2017")
fire_veg_2018 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2018")
fire_veg_2019 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2019")

dbDisconnect (conn) # connKyle

# the VRI for 2007 did not have a column for harvest_data, bec_zone_code, bec_subzone, or bec_variant so Ill just add them in here
fire_veg_2007$harvest_date <- NA
fire_veg_2007$bec_zone_code <- NA
fire_veg_2007$bec_subzone <- NA
fire_veg_2007$bec_variant <- NA

# the VRI for 2008 also was missing the fields bec_subzone, and bec_variant
fire_veg_2008$bec_subzone <-NA
fire_veg_2008$bec_variant <-NA

# I also need to change the names of the columns age_1 and age_2 to proj_age_1 and proj_age_2 this is because the naming convention for this colum changed across the years of the VRI

fire_veg_2002 <- fire_veg_2002 %>%
  rename(proj_age_1=age_1,
         proj_age_2=age_2)
fire_veg_2003 <- fire_veg_2003 %>%
  rename(proj_age_1=age_1,
         proj_age_2=age_2)
fire_veg_2004 <- fire_veg_2004 %>%
  rename(proj_age_1=age_1,
         proj_age_2=age_2)
fire_veg_2005 <- fire_veg_2005 %>%
  rename(proj_age_1=age_1,
         proj_age_2=age_2)
fire_veg_2006 <- fire_veg_2006 %>%
  rename(proj_age_1=age_1,
         proj_age_2=age_2)
fire_veg_2007 <- fire_veg_2007 %>%
  rename(proj_age_1=age_1,
         proj_age_2=age_2)

# Another problem is that fire_veg_2011 has a geometry column that is type MultiPolygonZ instead of MultiPolygon so this needs to be changed with the following query in postgres
# ALTER TABLE fire_veg_2011  
# ALTER COLUMN geometry TYPE geometry(MULTIPOLYGON, 3005) 
# USING ST_Force_2D(geometry);


# join all fire_veg datasets together. This function is faster than a list of rbinds
filenames3<- c("fire_veg_2002", "fire_veg_2003", "fire_veg_2004","fire_veg_2005", "fire_veg_2006", "fire_veg_2007","fire_veg_2008", "fire_veg_2009", "fire_veg_2010","fire_veg_2011", "fire_veg_2012", "fire_veg_2013","fire_veg_2014", "fire_veg_2015", "fire_veg_2016","fire_veg_2017", "fire_veg_2018", "fire_veg_2019")

mkFrameList <- function(nfiles) {
  d <- lapply(seq_len(nfiles),function(i) {
    eval(parse(text=filenames3[i])) # for new files lists change the name at filenames2
  })
  do.call(rbind,d)
}

n<-length(filenames3)
fire_veg_data<-mkFrameList(n)

# write final fire ignitions, weather and vegetation types to postgres

# save data 
connKyle <- dbConnect(drv = RPostgreSQL::PostgreSQL(), 
                      host = key_get('dbhost', keyring = 'postgreSQL'),
                      user = key_get('dbuser', keyring = 'postgreSQL'),
                      dbname = key_get('dbname', keyring = 'postgreSQL'),
                      password = key_get('dbpass', keyring = 'postgreSQL'),
                      port = "5432")
st_write (obj = fire_veg_data, 
          dsn = connKyle, 
          layer = c ("public", "fire_ignitions_veg_climate"))
dbDisconnect (connKyle)




# Check the layers line up.
ggplot() +
  geom_sf(data=bc.tsa) +
  geom_sf(data=lightning_clipped)

head(lightning_clipped)
