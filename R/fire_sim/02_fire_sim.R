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
    select(ID1, YEAR, Tmax05:Tmax09, Tave05:Tave09, PPT05:PPT09, PAS05:PAS09)
  
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


### Random point data
filenames2<-list()
for (i in 1: length(y2)){
  
  x<-eval(as.name(y2[i])) %>% 
    select(ID1, YEAR, Tmax05:Tmax09, Tave05:Tave09, PPT05:PPT09, PAS05:PAS09) %>%
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

DC_ignitions_and_sample_pts<- rbind(DC.ignitions, DC.sample.pts)

# upload reduced data set with locations and years to Postgres

# join the lat long location data to each of these samples and convert back to geometry for the vegetation query in postgres

fire.locations<- DC_ignitions_and_sample_pts %>% 
  select ("ID1", "YEAR")



##### NOW GET THE VEGETATION DATA!####

#### VEGETATION DATA #### 
#downloaded for years 2002 to 2019. These are the only years that VRI data exists, there is no earlier data.
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


















bc.tsa<-getSpatialQuery("SELECT administrative_area_name, shape 
                        FROM tsa_boundaries 
                        WHERE administrative_area_name != 'Queen Charlotte Timber Supply Area' AND administrative_area_name != 'North Island Timber Supply Area' AND administrative_area_name != 'Arrowsmith Timber Supply Area' AND administrative_area_name != 'Pacific Timber Supply Area'")
bc.tsa <- st_transform (bc.tsa, 3005)
bc.tsa_sp<-as(bc.tsa, "Spatial")
class(bc.tsa_sp)


# prov.bnd <- st_read ( dsn = "T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\admin_boundaries\\province\\gpr_000b11a_e.shp", stringsAsFactors = T)
# st_crs(prov.bnd)
# prov.bnd <- prov.bnd [prov.bnd$PRENAME == "British Columbia", ] 
# bc.bnd <- st_transform (prov.bnd, 3005)
# bc.bnd.valid<-st_make_valid(bc.bnd)


#### FIRE IGNITION DATA ####
fire.ignit.hist<-sf::st_read(dsn="C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\BCGW_7113060B_1600358424324_13780\\PROT_HISTORICAL_INCIDENTS_SP\\H_FIRE_PNT_point.shp")
st_crs(fire.ignit.hist)
head(fire.ignit.hist)
#lighting.hist<-fire.ignit.hist %>% filter(FIRE_CAUSE=="Lightning", FIRE_TYPE=="Fire")
fire.ignit.hist <- st_transform (fire.ignit.hist, 3005)
lightning_clipped<-fire.ignit.hist[bc.tsa,]

lightning_clipped2<- lightning_clipped %>% 
  filter (FIRE_YEAR>=2002, FIRE_TYPE=="Fire") %>%
  select(FIRE_ID, FIRE_YEAR : FIRE_CAUSE, FIRE_TYPE, SIZE_HA, geometry)


# what I think I need to do: clip out ignition locations then randomly sample points across bc for the available data. 
foo <- lightning_clipped2 %>%
  filter(FIRE_YEAR == 2002)
bc.tsa.points<- spsample(bc.tsa_sp, n=20000, type="regular")
foo.buffered<-st_buffer(foo, 500)

bc.tsa.clipped<- st_difference(bc.tsa, foo.buffered)
bc.tsa.clipped_sp<-as(bc.tsa.clipped, "Spatial")
bc.bnd.points<- spsample(bc.bnd.clipped_sp, n=20000, type="regular")

sample.pts <- data.frame (matrix (ncol = 4, nrow = nrow (bc.bnd.points@coords)))
colnames (sample.pts) <- c ("Year","pttype", "uniqueID", "FIRE_CAUSE")
sample.pts.start.data$pttype <- 0
sample.pts.start.data$uniqueID <- "du6_EarlyWinter_HSCEK077_2012"
id.points.out.all <- SpatialPointsDataFrame (sample.pts.start, data = sample.pts.start.data)

years<- c("2002", "2003", "2004", "2005", "2006", "2007", "2008", "2009", "2010", "2011", "2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019")
for (i in 1:length(years)) {
  foo <- lightning_clipped2 %>%
    filter(FIRE_YEAR == years[i])
  foo.buffered<-st_buffer(foo, 500)
  bc.bnd.clipped<- st_difference(bc.tsa, foo.buffered)
  bc.bnd.clipped_sp<-as(bc.bnd.clipped, "Spatial")
  bc.bnd.points<- spsample(bc.bnd.clipped_sp, n=20000, type="regular")
  
  
  
  
  
  
  
  
  
  
  
}



# Check the layers line up.
ggplot() +
  geom_sf(data=bc.tsa) +
  geom_sf(data=lightning_clipped)

head(lightning_clipped)




sample.pts.boreal <- spsample (caribou.boreal.sa, cellsize = c (2000, 2000), type = "regular")

#Make an empty provincial raster aligned with hectares BC
ProvRast <- raster(
  nrows = 15744, ncols = 17216, xmn = 159587.5, xmx = 1881187.5, ymn = 173787.5, ymx = 1748187.5, 
  crs = 3005, resolution = c(100, 100), vals = 0
) # from https://github.com/bcgov/bc-raster-roads/blob/master/03_analysis.R
bc.tsa.raster <- fasterize (bc.tsa, ProvRast, 
                            field = NULL,# raster cells that were cut get in 2017 get a value of 1
                            background = 0) # unharvested raster cells get value = 0 

st_write(lightning_clipped2, dsn = "C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\fire_ignitions.shp", delete_layer=TRUE)

# commit the shape file to postgres
# this works for loading the shape file onto Kyles Postgres. Run these sections of code below in R and fill in the details in the script for command prompt. Then run the ogr2ogr script in command prompt to get the table into postgres

host=keyring::key_get('dbhost', keyring = 'postgreSQL')
user=keyring::key_get('dbuser', keyring = 'postgreSQL')
dbname=keyring::key_get('dbname', keyring = 'postgreSQL')
password=keyring::key_get('dbpass', keyring = 'postgreSQL')

# Run this in terminal
#ogr2ogr -f PostgreSQL PG:"host= user= dbname= password= port=5432" C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\fire_ignitions.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI




