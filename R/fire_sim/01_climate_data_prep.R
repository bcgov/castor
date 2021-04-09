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
#  Script Purpose: This script creates a raster of BC and samples locations in the centre of each 1ha raster pixel in lat and long. This list of lat, long coordinates are then manually used to extract monthly average climate variables from climateBC (http://climatebc.ca/) for all years 2002 to 2019. This range of dates was chosen because it is the years that we have VRI data for. The reason Im pulling out the climate data at a 1ha scale is to create a layer of climate for the entire province at the scale that we want it. ClimateBC provides a program that you can use to pull out the climate at specific locations but does not give me a raster map or shapefile of the province with climate data so I see this as the only way to get climate data for the whole province that I can query as I like to use for my fire model.
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
    
    sample_size<-dim(foo_ignit_small)[1]*2
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


# after these files are written manually extract the monthly climate data for each of the relevant years at each of the fire ignition and sample locations from climate BC (http://climatebc.ca/) and save the files as .csv's. Here I import them again.


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


  






# dilemma: should I just make a raster of locations where fires started and did not start and then pull out those locations and get the temperature and vegetation data for the same locations every year or should I filter by year and then randomly select areas taht were not burned in e.g. 2002 and were burned in 2002 i.e. creating a different dataset for each year. I guess i might have problems with temporal autorcorrelation if my locations are the same year after year. 
# What I did below Ithink is not neccessary. i.e. I was trying to put my fire ignition locations into a raster and then sample on the grid. But rather I can do what I did in the caribou_range_extension_data_prep file. Start here tomorrow!

sbs.rast<-fasterize::fasterize(sf=sbs , raster = ProvRast , field = "feature_class_skey") # sub-boreal-spruce
fire.ignition_2002<- fire.ignition_sbs %>% filter(fire_year==2002 & fire_cause=="Lightning")
fire.ignition_2002$fire_yes<- 1
fire.ignition_2002_sp<-as(fire.ignition_2002,Class="Spatial")
fire.ignition.rast.2002<-raster(fire.ignition_2002_sp, resolution=c(100,100),vals=1)
plot(fire.ignition.rast.2002)

sbs.ignition.rast.2002<- fasterize::fasterize(sf=fire.ignition_2002 , raster = sbs.rast , field = "fire_id") # sub-boreal-spruce






# change the raster to points and pull out the centre location
sbs.pts<-rasterToPoints(sbs.rast,spatial=TRUE)
dim(sbs.pts) 

# reproject sp object
geo.prj <- "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0" 
sbs_r.pts <- spTransform(sbs.pts, CRS(geo.prj)) # gets this into lat long coordinates 
proj4string(sbs_r.pts)

# Assign coordinates to @data slot, display first 6 rows of data.frame
sbs_r.pts@data <- data.frame(sbs_r.pts@data, lat=coordinates(sbs_r.pts)[,2],
                         long=coordinates(sbs_r.pts)[,1]) 
head(sbs_r.pts@data)
sbs_r.pts<- as.data.frame(sbs_r.pts@data)

sbs_r.pts <- sbs_r.pts %>% 
  rename(ID2=layer) # ID2 (layer) is the TSA number I think.
sbs_r.pts$ID1<- 1:length(sbs_r.pts$lat) # ID1 should correspond to the 
sbs_r.pts<- sbs_r.pts %>%
  select(ID1, ID2, lat, long)
sbs_r.pts$el <- "."
head(sbs_r.pts)

no.pts<-dim(sbs_r.pts)[1]/4
r.pts1<- sbs_r.pts[1:no.pts, ]
r.pts2<- sbs_r.pts[(no.pts+1):(no.pts*2), ]
tail(r.pts1)
head(r.pts2)

r.pts3<- sbs_r.pts[((no.pts*2)+1):(no.pts*3), ]
tail(r.pts2)
head(r.pts3)

r.pts4<- sbs_r.pts[((no.pts*3)+1) : dim(sbs_r.pts)[1], ]
tail(r.pts3)
head(r.pts4)
tail(r.pts4)

write.csv(r.pts1, file="D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\sbs_Climate_points1.csv", row.names = FALSE)
write.csv(r.pts2, file="D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\sbs_Climate_points2.csv", row.names = FALSE)
write.csv(r.pts3, file="D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\sbs_Climate_points3.csv", row.names = FALSE)
write.csv(r.pts4, file="D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\sbs_Climate_points4.csv", row.names = FALSE)

# change the pts to a shapefile so that i can use the same points to get the VRI data
r.pts <- spTransform(pts, CRS(st_crs(lyr)$proj4string)) 
vri.pts<-st_as_sf(r.pts)
vri.pts<- st_transform(vri.pts, 3005)

ggplot() +
  geom_sf(data=forest.tenure, col='red')+
  geom_sf(data=vri.pts, col='black') # Im not sure, I hope this is ok

st_write(vri.pts, dsn = "D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\Williams_lake_pts.shp", delete_layer=TRUE)

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








# for the entire province use this code below to break the datafram into chuncks.
no.pts<-dim(r.pts)[1]/10
r.pts1<- r.pts[1:no.pts, ]
r.pts2<- r.pts[(no.pts+1):(no.pts*2), ]
tail(r.pts1)
head(r.pts2)

r.pts3<- r.pts[((no.pts*2)):(no.pts*3), ]
tail(r.pts2)
head(r.pts3)

r.pts4<- r.pts[(no.pts*3) : (no.pts*4), ]
tail(r.pts3)
head(r.pts4)
r.pts5<- r.pts[((no.pts*4)+1) : (no.pts*5), ]
tail(r.pts4)
head(r.pts5)
r.pts6<- r.pts[((no.pts*5)) : (no.pts*6), ]
tail(r.pts5)
head(r.pts6)
r.pts7<- r.pts[((no.pts*6)) : (no.pts*7), ]
tail(r.pts6)
head(r.pts7)
r.pts8<- r.pts[((no.pts*7)+1) : (no.pts*8), ]
tail(r.pts7)
head(r.pts8)
r.pts9<- r.pts[((no.pts*8)) : (no.pts*9), ]
tail(r.pts8)
head(r.pts9)
r.pts10<- r.pts[((no.pts*9)) : (dim(r.pts)[1]), ]
tail(r.pts9)
head(r.pts10)
tail(r.pts10)

write.csv(r.pts1, file="D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\Climate_points1.csv", row.names = FALSE)
write.csv(r.pts2, file="D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\Climate_points2.csv", row.names = FALSE)
write.csv(r.pts3, file="D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\Climate_points3.csv", row.names = FALSE)
write.csv(r.pts4, file="D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\Climate_points4.csv", row.names = FALSE)
write.csv(r.pts5, file="D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\Climate_points5.csv", row.names = FALSE)
write.csv(r.pts6, file="D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\Climate_points6.csv", row.names = FALSE)
write.csv(r.pts7, file="D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\Climate_points7.csv", row.names = FALSE)
write.csv(r.pts8, file="D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\Climate_points8.csv", row.names = FALSE)
write.csv(r.pts9, file="D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\Climate_points9.csv", row.names = FALSE)
write.csv(r.pts10, file="D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\Climate_points10.csv", row.names = FALSE)

####################################################
#OUTPUT
####################################################

#### GET CLIMATE DATA FOR LOCATIONs WHERE FIRES DID NOT START ####
#I also manually extract the monthly climate data for each of the random locations within BC that I sampled for each year from climate BC (http://climatebc.ca/) and saved the files as .csv's. Here I import them again.

file.list2<-list.files("D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\output", pattern="sample_pts_Year", all.files=FALSE, full.names=FALSE)
y2<-gsub(".csv","",file.list2)

years<- c("2002", "2003", "2004", "2005", "2006", "2007", "2008", "2009", "2010", "2011", "2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019")

setwd("D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\output")
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



#Get dummy layer for projection 
lyr<-getSpatialQuery(paste("SELECT geom FROM public.gcbp_carib_polygon"))

#Make an empty provincial raster aligned with hectares BC
ProvRast <- raster(
  nrows = 15744, ncols = 17216, xmn = 159587.5, xmx = 1881187.5, ymn = 173787.5, ymx = 1748187.5, 
  crs = st_crs(lyr)$proj4string, resolution = c(100, 100), vals = 0
) # from https://github.com/bcgov/bc-raster-roads/blob/master/03_analysis.R
