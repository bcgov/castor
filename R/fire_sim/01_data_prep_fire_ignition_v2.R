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

#### Provincial boundary with fire ignitions
bc.tsa <- st_read ( dsn = "C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\Ignition_clipped.shp", stringsAsFactors = T)# In QGIS I buffered the location where a fire started by 500m and then clipped out the buffered locations between the years 2002 - 2019 from the bc tsa boundaries.  I wanted to do this for each year separately but could not work out how to do this in QGIS and when I tried to do it in R, R crashed my whole computer so after trying 4 times I gave up. 
bc.tsa <-bc.tsa %>% 
  filter (administra != 'Queen Charlotte Timber Supply Area') %>%
  filter(administra != 'North Island Timber Supply Area') %>%
  filter(administra != 'Arrowsmith Timber Supply Area') %>%
  filter(administra != 'Pacific Timber Supply Area')
bc.tsa <- st_transform (bc.tsa, 3005)
tsa.points<- st_sample(bc.tsa, size=20000, type="regular")
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


sample.pts <- data.frame (matrix (ncol = 5, nrow = nrow (tsa.points.transformed1)))
colnames (sample.pts) <- c ("ID1","ID2", "lat", "long", "el")
sample.pts$ID1<- 1:length(tsa.points.transformed2$lon)
sample.pts$ID2 <- 0
sample.pts$lat <-as.numeric(tsa.points.transformed2$lat)
sample.pts$long <- as.numeric(tsa.points.transformed2$lon)
sample.pts$el <- "."

write_csv(sample.pts, path="C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\input\\sample_pts.csv")


#### GET CLIMATE DATA FOR EACH LOCATION ####
#I then manually extract the monthly climate data for each of the relevant years at each of the fire ignition locations from climate BC (http://climatebc.ca/) and saved the files as .csv's. Here I import them again.

file.list1<-list.files("C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\output", pattern="ignition.", all.files=FALSE, full.names=FALSE)
y1<-gsub(".csv","",file.list1)

setwd("C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\output")
for (i in 1:length(file.list1)){
  assign(paste0(y1[i]),read.csv (file=paste0(file.list1[i])))
}


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

## calculate the drought code for each month

#######################################
#### Equations to calculate drought code ####
#######################################
# Parameters to calculate monthly drought code (DC)

days_month<- c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31) # number of days in each month starting in Jan
#### Daylength adjustment factor (Lf) [Development and Structure of the Canadian Forest Fire Weather Index System pg 15, https://d1ied5g1xfgpx8.cloudfront.net/pdfs/19927.pdf] ####
# Month <- Lf value
# LF[1] is the value for Jan
Lf<-c(-1.6, -1.6, -1.6, 0.9, 3.8, 5.8, 6.4, 5.0, 2.4, 0.4, -1.6, -1.6)
####

### Fire ignition data
filenames<-list()
for (i in 1: length(y1)){
  
  x<-eval(as.name(y1[i])) %>% 
    rename(YEAR=ID2) %>%
    select(ID1, YEAR,Latitude, Longitude, Tmax05:Tmax09, Tave05:Tave09, PPT05:PPT09, PAS05:PAS09)
  
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


### Random point data
filenames2<-list()
for (i in 1: length(y2)){
  
  x<-eval(as.name(y2[i])) %>% 
    select(ID1, YEAR, Latitude, Longitude, Tmax05:Tmax09, Tave05:Tave09, PPT05:PPT09, PAS05:PAS09) %>%
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

DC_ignitions_and_sample_pts<- rbind(DC.ignitions, DC.sample.pts)

DC_sf = st_as_sf(DC_ignitions_and_sample_pts, coords = c("Longitude", "Latitude"))
DC_sf1 <- st_set_crs (DC_sf, 4326)
DC_sf2<- transform_bc_albers(DC_sf1)
DC_sf_clipped<-DC_sf2[bc.tsa,]
DC_sf_clipped %>% group_by(YEAR) %>% count (YEAR)

# check that it looks ok, it does.
ggplot() +
  geom_sf(data=bc.tsa, col='red') +
  geom_sf(data=DC_sf2)
  

st_write(DC_sf_clipped, dsn = "C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\DC_data.shp", delete_layer=TRUE)

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
# CREATE TABLE fire_veg_2006 AS
# (SELECT feature_id, bclcs_level_2, bclcs_level_3, bclcs_level_4, bclcs_level_5, 
#   fire.id1, fire.pttype, fire.year, fire.tmax05, fire.tmax06, fire.tmax07, fire.tmax08, fire.tmax09, fire.tave05, fire.tave06, fire.tave07, fire.tave08, fire.tave09, fire.ppt05, fire.ppt06, fire.ppt07, fire.ppt08, fire.ppt09, fire.pas05, fire.pas06, fire.pas07, fire.pas08, fire.pas09, fire.mdc_05, fire.mdc_06, fire.mdc_07,  fire.mdc_08, fire.mdc_09, 
#   veg_comp_lyr_r1_poly2006.shape FROM veg_comp_lyr_r1_poly2006, (SELECT wkb_geometry, id1, pttype, year, tmax05, tmax06, tmax07, tmax08, tmax09, tave05, tave06, tave07, tave08, tave09, ppt05, ppt06, ppt07, ppt08, ppt09, pas05, pas06, pas07, pas08, pas09, mdc_05, mdc_06, mdc_07,  mdc_08, mdc_09  
#       from dc_data where year = '2006') as fire 
#   where st_contains (veg_comp_lyr_r1_poly2006.shape, fire.wkb_geometry));


# This also works but is super slow, dont run this one!
# CREATE TABLE Fire_veg_2002 AS (WITH ignit as 
#         (SELECT fire_no, fire_year, fire_cause, size_ha, wkb_geometry from bc_fire_ignition 
#         where fire_type = 'Fire' and fire_year = '2002'), 
#         veg as (SELECT bclcs_level_4, bclcs_level_5, geometry FROM veg_comp_lyr_r1_poly2002 where bclcs_level_2 = 'T') 
#         SELECT veg.geometry as geom, fire_no, fire_year, fire_cause, size_ha, bclcs_level_4, bclcs_level_5 
#         FROM ignit, veg WHERE st_intersects (ignit.wkb_geometry, veg.geometry));

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
