# Copyright 2021 Province of British Columbia
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
#  Script Name: 01_climate_data_prep.R
#  Script Version: 1.0
#  Script Purpose: This script obtains the lat, long coordinates of fire ignition locations and samples locations where fires were not observed to start. It then creates a csv file with these locations that can be used to manually extract monthly average climate variables from climateBC (http://climatebc.ca/) for all years 2002 to 2019. This range of dates was chosen because it is the years that we have VRI data for. After the climate data has been extracted from climateBC this data is reimported into this script and the mean monthly drought code for the months  May - August is calculated for each year. From this script I get the maximum temperature, minimum temperature, average temperature, total precipitation, and mean monthly drought code for the months May - August for each year 2002 - 2019 for all fire ignition locations and randomly sampled (available fire ignition locations (fire absence)) points on the landscape 
#  Script Author: Elizabeth Kleynhans, Ecological Modeling Specialist, Forest Analysis and Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#=================================

library(raster)
library(data.table)
library(sf)
library(tidyverse)
library(rgeos)
library(cleangeo)
library(dplyr)
library(tidyr)
library(ggplot2)

source(here::here("R/functions/R_Postgres.R"))

bec<-getSpatialQuery("SELECT objectid, feature_class_skey, zone, subzone, natural_disturbance, zone_name, wkb_geometry FROM public.bec_zone")

bec<-st_transform(bec, 3005)
#plot(bec[, "zone"]) # check we got the whole province

# import fire ignition data
fire.ignition<-getSpatialQuery("SELECT * FROM public.bc_fire_ignition")# this file has historic and current year fires joined together. 
fire.ignition<-st_transform(fire.ignition, 3005)

prov.bnd <- st_read ( dsn = "T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\admin_boundaries\\province\\gpr_000b11a_e.shp", stringsAsFactors = T)
st_crs(prov.bnd)
prov.bnd <- prov.bnd [prov.bnd$PRENAME == "British Columbia", ] 
bc.bnd <- st_transform (prov.bnd, 3005)
fire.ignition.clipped<-fire.ignition[bc.bnd,] # making sure all fire ignitions have coordinates within BC boundary
# note clipping the fire locations to the BC boundary removes a few ignition points in several of the years


bec_sf<-st_as_sf(bec)
bec_sf_buf<- st_buffer(bec_sf, 0)
fire.ignition_sf<-st_as_sf(fire.ignition.clipped)

#doing st_intersection with the whole bec and fire ignition files is very very slow! 

fire.igni.bec<- st_intersection(fire.ignition_sf, bec_sf_buf)

#write samp_locations_df to file because it takes so long to make
# save data 
conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")
st_write (obj = fire.igni.bec, 
          dsn = conn, 
          layer = c ("public", "fire_ignit_by_bec"))
dbDisconnect (conn)

#import the fire ignition data
conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")
fire_igni_bec<- st_read (dsn = conn, 
          layer = c ("public", "fire_ignit_by_bec"))
dbDisconnect (conn)

#fire_igni_bec<-fire_igni_bec[bc.bnd,]

#getting long lat info
#geo.prj <- "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0" 
fire_igni_bec1 <- st_transform(fire_igni_bec, crs = "+proj=longlat +datum=NAD83 / BC Albers +no_defs")
st_crs(fire_igni_bec1)
fire_igni_bec2<-as.data.frame(fire_igni_bec1)
fire_igni_bec2<-fire_igni_bec2 %>% 
  dplyr::select(ogc_fid: fire_type, size_ha:wkb_geometry)
# Try find a way to split the data up into 3 colums and the remove the brackets. 
fire_igni_bec3<- fire_igni_bec2 %>%
  tidyr::separate(wkb_geometry, into = c("longitude", "latitude")," ")
fire_igni_bec3$longitude<- gsub(",", "", as.character(fire_igni_bec3$longitude) )
fire_igni_bec3$longitude<- substring(fire_igni_bec3$longitude, 3)
fire_igni_bec3$longitude<- as.numeric(fire_igni_bec3$longitude)
fire_igni_bec3$longitude<- round(fire_igni_bec3$longitude, digits=4)
fire_igni_bec3$latitude<- gsub(")", "", as.character(fire_igni_bec3$latitude) )
fire_igni_bec3$latitude<- as.numeric(fire_igni_bec3$latitude)
fire_igni_bec3$latitude<- round(fire_igni_bec3$latitude, digits=4)

fire_igni_bec_new<-fire_igni_bec %>% dplyr::select(ogc_fid: fire_type, size_ha: wkb_geometry)

fire_igni_bec_new$longitude<-fire_igni_bec3$longitude
fire_igni_bec_new$latitude<-fire_igni_bec3$latitude

# Now Ill buffer each fire location by 500m and then within each Bec Zone Ill sample locations where fires did not start and combine those locations with locations where the fires did start.

years<-c("2002", "2003", "2004", "2005", "2006", "2007","2008","2009","2010","2011","2012","2013","2014","2015","2016","2017","2018", "2019", "2020")
beczone<- c("SWB", "SBS", "ICH", "ESSF", "MH", "CWH", "BAFA", "CMA", "SBPS", "IMA", "MS", "PP", "IDF", "BWBS", "BG", "CDF")
filenames<-list()

for (i in 1:length(years)) {
  print(years[i])
  foo<- fire_igni_bec_new %>% filter(fire_year==years[i], fire_cause=="Lightning")
  foo_ignit_sf<- st_as_sf(foo)
  
  all_sample_points <- data.frame (matrix (ncol = 18, nrow = 0)) # add 'data' to the points
  colnames (all_sample_points) <- c ("ogc_fid", "fire_no", "fire_year", "ign_date", "fire_cause", "fire_id", "fire_type", "latitude", "longitude", "size_ha", "objectid", "feature_class_skey", "zone", "subzone", "natural_disturbance", "zone_name", "fire", "wkb_geometry")
  
  for (j in 1:length(beczone)) {
    print(beczone[j])
    
    foo_ignit_small<- foo_ignit_sf %>% filter(zone==beczone[j])
    
    if (dim(foo_ignit_small)[1]>0) {
    foo_ignit_small$fire<-1
    foo.ignit.buffered<- st_buffer(foo_ignit_small, dist=500) # buffering fire ignition locations by 500m. I decided to do this because I dont think the recorded locations are likely very accurate so I hope this helps
    foo.ignit.buffered<-foo.ignit.buffered %>% 
      dplyr::select(ogc_fid, fire_no, fire_id, zone, subzone, wkb_geometry)
    foo.ignit.buf.union<-st_union(foo.ignit.buffered)
    
    bec_foo<- bec_sf_buf %>% filter(zone==beczone[j])
    clipped<-st_difference(bec_foo, foo.ignit.buf.union)
    #clipped<-rmapshaper::ms_erase(target=bec_foo, erase=foo.ignit.buffered) # clips out buffered areas I think.But it crashes a lot!
    
    sample_size<-dim(foo_ignit_small)[1]*5 # here 5 is the number of points I sample in correlation with the number of ignition points in that BEC zone. 
    samp_points <- st_sample(clipped, size=sample_size)
    samp_points_sf = st_sf(samp_points)
    samp_joined = st_join(samp_points_sf, clipped) # joining attributes back to the sample points
    samp_joined<- st_transform(samp_joined, 3005)
    samp_joined$ogc_fid<-"NA"
    samp_joined$fire_no<-"NA"
    samp_joined$fire_year<- years[i]
    samp_joined$ign_date<-"NA"
    samp_joined$fire_cause<-"NA"
    samp_joined$fire_id<-"NA"
    samp_joined$fire_type<-"NA"
    samp_joined$size_ha<-"NA"
    samp_joined$fire<-0
    
    #getting long lat info
    #geo.prj <- "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0" 
    sample.p.trans <- st_transform(samp_joined, crs = "+proj=longlat +datum=NAD83 / BC Albers +no_defs")
    #st_crs(sample.p.trans)
    sample.p.trans1<-as.data.frame(sample.p.trans)
    # Try find a way to split the data up into 3 colums and the remove the brackets. 
    samp_joined2<- sample.p.trans1 %>%
      tidyr::separate(geometry, into = c("longitude", "latitude")," ")
    samp_joined2$longitude<- gsub(",", "", as.character(samp_joined2$longitude) )
    samp_joined2$longitude<- substring(samp_joined2$longitude, 3)
    samp_joined2$longitude<- as.numeric(samp_joined2$longitude)
    samp_joined2$longitude<- round(samp_joined2$longitude, digits=4)
    samp_joined2$latitude<- gsub(")", "", as.character(samp_joined2$latitude) )
    samp_joined2$latitude<- as.numeric(samp_joined2$latitude)
    samp_joined2$latitude<- round(samp_joined2$latitude, digits=4)
    
    samp_joined$longitude<-samp_joined2$longitude
    samp_joined$latitude<-samp_joined2$latitude
    samp_joined_new<- samp_joined %>% 
      rename(wkb_geometry=geometry) %>%
      dplyr::select(ogc_fid, fire_no, fire_year, ign_date, fire_cause, fire_id, fire_type, latitude, longitude, size_ha, objectid, feature_class_skey, zone, subzone, natural_disturbance,zone_name, wkb_geometry, fire)
    
    pnts<- rbind(samp_joined_new, foo_ignit_small)
    
    all_sample_points<- rbind(all_sample_points, pnts)
    
    
    } 
    
  }
  
  #assign file names to the work
  nam1<-paste("sampled_points",years[i],sep="_") #defining the name
  assign(nam1,all_sample_points)
  filenames<-append(filenames,nam1)
}

sampled_points_2020<- sampled_points_2020 %>% filter(fire_year==2020)

mkFrameList <- function(nfiles) {
  d <- lapply(seq_len(nfiles),function(i) {
    eval(parse(text=filenames[i]))
  })
  do.call(rbind,d)
}

n<-length(filenames)
samp_locations<-mkFrameList(n) 
samp_locations$idno<-1:length(samp_locations$fire_year)
samp_locations_sf<-st_as_sf(samp_locations)

# save data - not working not sure why not
conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")
st_write (obj = samp_locations_sf, 
          dsn = conn, 
          layer = c ("public", "samp_locations_fire"),
          overwrite=TRUE)
dbDisconnect (conn)

# or save it as a shape file
st_write(samp_locations_sf, dsn = "D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\samp_locations_fire.shp")

# If an error message appears when you run these csv files in climateBC make sure that when the csv was written an extra column was not added. row.names=FALSE should prevent this.

for (i in 1: length(years)) {
  dat<- samp_locations_sf %>% filter(fire_year==years[i])
  sample.pts <- data.frame (matrix (ncol = 5, nrow = nrow (dat)))
  colnames (sample.pts) <- c ("ID1","ID2", "lat", "long", "el")
  sample.pts$ID1<- dat$idno
  sample.pts$ID2 <- dat$fire_year
  sample.pts$lat <-as.numeric(dat$latitude)
  sample.pts$long <- as.numeric(dat$longitude)
  sample.pts$el <- "."
  
  nam1<-paste("sampled.points",years[i], "csv",sep=".")
  the_dir <- "D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data"
  write.csv(sample.pts, file = paste0(the_dir, "\\", basename(nam1)), row.names=FALSE)
}


# after these files are written manually extract the monthly climate data for each of the relevant years at each of the fire ignition and sample locations from climate BC (http://climatebc.ca/) and save the files as .csv's. Here I import them again. Or use the downscaled climate data and extract that (I have not done this, I probably should!)


###############################
#Import climate data per ignition and sample location
###############################

file.list1<-list.files("D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\output", pattern="sampled.points", all.files=FALSE, full.names=FALSE)
y1<-gsub(".csv","",file.list1)
the_dir <- "D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\output"

for (i in 1:length(file.list1)){
  assign(paste0(y1[i]),read.csv (file=paste0(the_dir, "\\", file.list1[i])))
}

# FOR EACH DATASET CALCULATE THE MONTHLY DROUGHT CODE

#############################################
#### Equations to calculate drought code ####
#############################################

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
    dplyr::select(ID1, YEAR,Latitude, Longitude, Tmax05:Tmax09, Tave05:Tave09, PPT05:PPT09)
  
  x2<- x %>% filter(Tmax05 != -9999) # there are some locations that did not have climate data, probably because they were over the ocean, so Im removing these here.
  
  for (j in 5 : 9) {
    
    x2$MDC_04<-15
    
    Em<- days_month[j]*((0.36*x2[[paste0("Tmax0",j)]])+Lf[j])
    Em2 <- ifelse(Em<0, 0, Em)
    DC_half<- x2[[paste0("MDC_0",j-1)]] + (0.25 * Em2)
    precip<-x2[[paste0("PPT0",j)]]
    RMeff<-(0.83 * (x2[[paste0("PPT0",j)]]))
    Qmr<- (800 * exp((-(DC_half))/400)) + (3.937 * RMeff)
    Qmr2 <- ifelse(Qmr>800, 800, Qmr)
    MDC_m <- (400 * log(800/Qmr2)) + 0.25*Em2
    x2[[paste0("MDC_0",j)]] <- (x2[[paste0("MDC_0",j-1)]] + MDC_m)/2
    x2[[paste0("MDC_0",j)]] <- ifelse(x2[[paste0("MDC_0",j)]] <15, 15, x2[[paste0("MDC_0",j)]])
  }
  nam1<-paste("DC.",y1[i],sep="") #defining the name
  assign(nam1,x2)
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

dim(DC.ignitions) 
names(DC.ignitions)
names(samp_locations_sf)

DC.ignitions1<- DC.ignitions %>% rename(idno=ID1,
                                        fire_year=YEAR) 
samp_locations_sf$idno <- as.factor(as.character(samp_locations_sf$idno))
samp_locations_sf$fire_year <- as.numeric(as.character(samp_locations_sf$fire_year))

# Now join DC.ignitions back with the original fire ignition dataset
ignition_weather<-left_join(DC.ignitions1, samp_locations_sf)
head(ignition_weather)
dim(ignition_weather) 
st_crs(ignition_weather)
ignition_weather_crs <- st_as_sf(ignition_weather)
crs(ignition_weather_crs)
ignition_weather_crs<- st_transform(ignition_weather_crs, 3005)

# Check the points line up with BC boundaries!
ggplot() +
  geom_sf(data=bc.bnd, col='red') +
  geom_sf(data=ignition_weather_crs, col='black') # looks good!

# A check of the fire ignition counts per year line up with the original data. So the number of fire ignitions seem good. 

st_write(ignition_weather_crs, dsn = "D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\DC_data.shp", delete_layer=TRUE)



# commit the shape file to postgres
# this works for loading the shape file onto Kyles Postgres. Run these sections of code below in R and fill in the details in the script for command prompt. Then run the ogr2ogr script in command prompt to get the table into postgres

# To Kyles Clus
#host=keyring::key_get('dbhost', keyring = 'postgreSQL')
#user=keyring::key_get('dbuser', keyring = 'postgreSQL')
#dbname=keyring::key_get('dbname', keyring = 'postgreSQL')
#password=keyring::key_get('dbpass', keyring = 'postgreSQL')

# Run this in terminal
#ogr2ogr -f PostgreSQL PG:"host= user= dbname= password= port=5432" D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\DC_data.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI

# OR my local machine

# ogr2ogr -f "PostgreSQL" PG:"host=localhost user=postgres dbname=postgres password=postgres port=5432" D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\DC_data.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI

#########################################
#### FINISHED NOW GO TO 01_vri_data_prep####
#########################################