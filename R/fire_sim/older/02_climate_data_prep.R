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
#  Script Name: 02_climate_data_prep.R
#  Script Version: 1.0
#  Script Purpose: This script obtains the lat, long coordinates of fire ignition locations and samples locations where fires were not observed to start. It then creates a csv file with these locations that can be used to manually extract monthly average climate variables from climateBC (http://climatebc.ca/) for all years 2002 to 2020. This range of dates was chosen because it is the years that we have VRI data for. To extract the climate data I use the app that climateBC provides. The version I used of the app is climateBC_v700. This version was released on 27 April 2021 and includes 13 General Circulation Models from the CMIP6. It also has a different normal period (1991 - 2020).  After the climate data has been extracted from climateBC this data is reimported into this script and the mean monthly drought code for the months  May - September is calculated for each year. From this script I get the maximum temperature, minimum temperature, average temperature, total precipitation, and mean monthly drought code for the months May - September for each year 2002 - 2020 for all fire ignition locations and randomly sampled (available fire ignition locations (fire absence)) points on the landscape 
#  Script Author: Elizabeth Kleynhans, Ecological Modeling Specialist, Forest Analysis and Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#  Script Contributor: Cora Skaien, Ecological Modeling Specialist, Forest Analysis and Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#=================================

#Overview:
 # In this file (02), we determine determine the BEC boundaries and match this with our fire location data within the BC boundary, 
  # created 500 m buffer, selected GPS locations where fires did not start, combined fire and non-fire location data,
  # acquire the lat and long data to get ClimateBC information for each location, 
  # calculate the monthly drought code for each dataset, and then upload files to clus database.

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

#Get BEC data
bec<-getSpatialQuery("SELECT objectid, feature_class_skey, zone, subzone, natural_disturbance, zone_name, wkb_geometry FROM public.bec_zone")
st_crs(bec)

bec<-st_transform(bec, 3005) #transform coordinate system to 3005, which refers to BC, Canada
# EPSG:3005 Projected coordinate system for Canada - British Columbia. This CRS name may sometimes be used as an alias for NAD83(CSRS) / BC Albers.
#plot(bec[, "zone"]) # check we got the whole province
st_crs(bec)

# import fire ignition data
fire.ignition<-getSpatialQuery("SELECT * FROM public.bc_fire_ignition")# this file has historic and current year fires joined together. 
st_crs(fire.ignition)
fire.ignition<-st_transform(fire.ignition, 3005) #transform coordinate system to 3005 - that for BC, Canada

prov.bnd <- st_read ( dsn = "T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\admin_boundaries\\province\\gpr_000b11a_e.shp", stringsAsFactors = T) # Read simple features from file or database, or retrieve layer names and their geometry type(s)
st_crs(prov.bnd) #Retrieve coordinate reference system from sf or sfc object
prov.bnd <- prov.bnd [prov.bnd$PRENAME == "British Columbia", ] 
bc.bnd <- st_transform (prov.bnd, 3005) #Transform coordinate system
fire.ignition.clipped<-fire.ignition[bc.bnd,] # making sure all fire ignitions have coordinates within BC boundary
table(fire.ignition.clipped$fire_year) #Still have correct number for 2007 and 2008

st_write(fire.ignition.clipped, overwrite = TRUE,  dsn="C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_ignition_hist\\bc_fire_ignition_clipped.shp", delete_dsn = TRUE)
##Check clipped data on QGis. Clipped data has no physical outliers
# note clipping the fire locations to the BC boundary removes a few ignition points in several of the years

bec_sf<-st_as_sf(bec) #Convert foreign object to an sf object (collection of simple features that includes attributes and geometries in the form of a data frame. In other words, it is a data frame (or tibble) with rows of features, columns of attributes, and a special geometry column that contains the spatial aspects of the features)
bec_sf_buf<- st_buffer(bec_sf, 0) # encircles a geometry object at a specified distance and returns a geometry object that is the buffer that surrounds the source object. Set buffer to 0 here.
st_crs(bec_sf_buf)
st_write(bec_sf_buf, overwrite = TRUE,  dsn="C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_ignition_hist\\bec_sf_buf.shp", delete_dsn = TRUE)
#Boundaries look good


##If you bring BEC buffer back in, you may need to do the below for renaming. Remember to open the plyr library, but then ensure it is closed in the packages afterwards

#And we need BEC buffer info
bec_sf_buf<-st_read(dsn="C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_ignition_hist\\bec_sf_buf.shp")
names(bec_sf_buf)

#Must rename some variables because it was shortened when saved as a shape file
library(plyr)
names(bec_sf_buf)
bec_sf_buf<-rename(bec_sf_buf,
                   c("objectd"="objectid",
                     "ftr_cl_"="feature_class_skey",
                     "ntrl_ds"="natural_disturbance",
                     "zone_nm"="zone_name"))
names(bec_sf_buf)
## NOW UNCHECK PLYR LIBRARY IN PACKAGES WINDOW!

fire.ignition_sf<-st_as_sf(fire.ignition.clipped) #convert to sf object
st_crs(fire.ignition_sf)
st_write(fire.ignition_sf, overwrite = TRUE,  dsn="C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_ignition_hist\\bc_fire_ignition_sf.shp", delete_dsn = TRUE)
#Boundaries look good
table(fire.ignition_sf$fire_year)

#doing st_intersection with the whole bec and fire ignition files is very very slow! 

fire.igni.bec<- st_intersection(fire.ignition_sf, bec_sf_buf) # ST_Intersects is a function that takes two geometries and returns true if any part of those geometries is shared between the 2
#fire.igni.bec<- st_intersection(fire.ignition_sf, st_buffer(bec_sf, 0)) #Alternative code
# ST_Intersection in conjunction with ST_Intersects is very useful for clipping geometries such as in bounding box, buffer, region queries where you only want to return that portion of a geometry that sits in a country or region of interest
# Note: on June 21, 2021, when the above is run, 10 points get physically placed in the middle of the ocean despite having correct GPS points. Unknown why.
table(fire.igni.bec$fire_year)


#write fire.igni.bec to file because it takes so long to make
st_write(fire.igni.bec, overwrite = TRUE,  dsn="C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_ignition_hist\\fire_ignit_by_bec.shp", delete_dsn = TRUE)


##Below will not work because it is a shape file

# save data 
#conn <- dbConnect (dbDriver ("PostgreSQL"), 
#                   host = "",
#                   user = "postgres",
#                   dbname = "postgres",
#                   password = "postgres",
#                   port = "5432")

##Can use keyring
#conn <- DBI::dbConnect (dbDriver ("PostgreSQL"), 
#                        host = keyring::key_get('dbhost', keyring = 'postgreSQL'), 
#                        dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), 
#                        port = '5432',
#                        user = keyring::key_get('dbuser', keyring = 'postgreSQL'),
#                        password = keyring::key_get('dbpass', keyring = 'postgreSQL'))


#st_write (obj = fire.igni.bec, 
#          dsn = conn, 
#          layer = c ("public", "fire_ignit_by_bec"))
#dbDisconnect (conn)


##Save via OsGeo4W Shell
##Below needs: (1) update to relevant credentials and (2) then enter into the OSGeo4W command line and hit enter. 
#ogr2ogr -f PostgreSQL PG:"host=localhost user=postgres dbname=postgres password=postgres port=5432" C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_ignition_hist\\fire_ignit_by_bec.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI



#import the fire ignition data
conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")


##Can use keyring
conn <- DBI::dbConnect (dbDriver ("PostgreSQL"), 
                        host = keyring::key_get('dbhost', keyring = 'postgreSQL'), 
                        dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), 
                        port = '5432',
                        user = keyring::key_get('dbuser', keyring = 'postgreSQL'),
                        password = keyring::key_get('dbpass', keyring = 'postgreSQL'))

fire_igni_bec<- st_read (dsn = conn, 
          layer = c ("public", "fire_ignit_by_bec"))
dbDisconnect (conn)

##Or from local device
# fire_igni_bec <-st.read(dsn="C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_ignition_hist\\fire_ignit_by_bec.shp")

#fire_igni_bec<-fire_igni_bec[bc.bnd,]

head(fire_igni_bec)

#getting long lat info
#geo.prj <- "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0" 
fire_igni_bec1 <- st_transform(fire_igni_bec, crs = "+proj=longlat +datum=NAD83 / BC Albers +no_defs")
st_crs(fire_igni_bec1) #Retrieve coordinate reference system to check
fire_igni_bec2<-as.data.frame(fire_igni_bec1)
fire_igni_bec2<-fire_igni_bec2 %>% 
  dplyr::select(ogc_fid: fire_type, size_ha:wkb_geometry)
# Try find a way to split the data up into 3 columns and then remove the brackets. 
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

# Now I'll buffer each fire location by 500m and then within each BEC Zone I'll sample locations where fires did not start and combine those locations with locations where the fires did start.
# Buffer is so that the area is less likely to have been fire affected.

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
    
    sample_size<-dim(foo_ignit_small)[1]*10 # here 10 is the number of points I sample in correlation with the number of ignition points in that BEC zone. 
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

#sampled_points_2020<- sampled_points_2020 %>% filter(fire_year==2020)


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
st_crs(samp_locations_sf)
head(samp_locations_sf) #Note, wkb_geometry is in different coordinate system for this data
table(is.na(samp_locations_sf$ogc_fid))

##Check data
table(samp_locations_sf$fire_cause) #Half are lightning, half are NA
table(samp_locations_sf$fire_type) #Half are Fire and Nuisance Fire, half are NA
table(samp_locations_sf$subzone)
table(samp_locations_sf$fire_year) 

table(fire_igni_bec_new$fire_year, fire_igni_bec_new$fire_cause) #Most 2007 and 2008 were people caused and not lightning!
# low numbers 2007 and 2008 are correct


# save data - not working with "overwrite" included, but can work without it.
conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")

##Can use keyring
conn <- DBI::dbConnect (dbDriver ("PostgreSQL"), 
                        host = keyring::key_get('dbhost', keyring = 'postgreSQL'), 
                        dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), 
                        port = '5432',
                        user = keyring::key_get('dbuser', keyring = 'postgreSQL'),
                        password = keyring::key_get('dbpass', keyring = 'postgreSQL'))


st_write (obj = samp_locations_sf, 
          dsn = conn, 
          layer = c ("public", "samp_locations_fire"))

dbDisconnect (conn)

# or save it as a shape file
st_write(samp_locations_sf, dsn = "D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\samp_locations_fire.shp", delete_dsn = TRUE, overwrite = TRUE)
table(samp_locations_sf$fire_year, samp_locations_sf$fire_type) # There are 10% as many fires as no fire locations

# If an error message appears when you run these csv files in climateBC make sure that when the csv was written an extra column was not added. row.names=FALSE should prevent this.




########### Acquiring and Appending Climate Data ########
# Each time the above is ran, below will need to be repated.
### See http://climatebc.ca/Help for how to use ClimateBC to get the climate data. 
# You will need to download ClimateBC (http://climatebc.ca/downloads/download.html) and use the files generated in the first code chunk below.
# In the Multi-Location section, select "Annual Data" and select the appropriate year for each individual file. In the bootm drop down menu, select "monthly variables". 
# Then upload each year, one at a time, and specify an output file location.
## Note that 2007 and 2008 each have 200-300 points whereas other years have 15,000. This is becausemost fires in these 2 years were designated as human caused as opposed to lightning.
# 2007 and 2008 have almost exclusively nuisance fires, which makes me think that data is missing


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


# after these files are written, manually extract the monthly climate data for each of the relevant years at each of the fire ignition and sample locations from climate BC (http://climatebc.ca/) and save the files as .csv's. Here I import them again. Or use the downscaled climate data and extract that (I have not done this, I probably should!)
## this is as per above instructions for CLimateBC


###############################
#Import climate data per ignition and sample location
###############################

#Depending on where you saved your output, you may need to update the directory below
file.list1<-list.files("D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\output_ClimateBC", pattern="sampled.points", all.files=FALSE, full.names=FALSE)
y1<-gsub(".csv","",file.list1)
the_dir <- "D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\output_ClimateBC"

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

# combined all the DC.ignition files together
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
head(ignition_weather) #Lat -Longs match
dim(ignition_weather) 
st_crs(ignition_weather) #Answer NA
head(ignition_weather) #Note, there are 2 Lat/Long columns, and they have different values for some reason
ignition_weather_crs <- st_as_sf(ignition_weather)
crs(ignition_weather_crs)
ignition_weather_crs<- st_transform(ignition_weather_crs, 3005)
crs(ignition_weather_crs)

# Check the points line up with BC boundaries!
ggplot() +
  geom_sf(data=bc.bnd, col='red') +
  geom_sf(data=ignition_weather_crs, col='black') #looks good
#If random points appear in middle of ocean, open in QGIS to get points.


# A check of the fire ignition counts per year line up with the original data. So the number of fire ignitions seem good. 

st_write(ignition_weather_crs, dsn = "D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\DC_data.shp", delete_layer=TRUE)
##Open in QGis to assess; see one physical outlier in middle of ocean

##Get 2002 data and visualize in QGis
ignition_weather_crs_2002<-subset(ignition_weather_crs,ignition_weather_crs$fire_year==2002)
head(ignition_weather_crs_2002)
st_write(ignition_weather_crs_2002, dsn = "D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\DC_data_2002.shp", delete_layer=TRUE)


# commit the shape file to postgres
# this works for loading the shape file onto Kyles Postgres. Run these sections of code below in R and fill in the details in the script for command prompt. Then run the ogr2ogr script in command prompt to get the table into postgres

# To Kyles Clus
#host=keyring::key_get('dbhost', keyring = 'postgreSQL')
#user=keyring::key_get('dbuser', keyring = 'postgreSQL')
#dbname=keyring::key_get('dbname', keyring = 'postgreSQL')
#password=keyring::key_get('dbpass', keyring = 'postgreSQL')

##Below needs: (1) update to relevant credentials and (2) then enter into the OSGeo4W command line and hit enter. 
#ogr2ogr -f PostgreSQL PG:"host= user= dbname= password= port=5432" D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\DC_data.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI
##Above does not work because ogc_fid is NA or not right character type, and the code is trying to set this as the FID when uploading.

# OR my local machine

# ogr2ogr -f "PostgreSQL" PG:"host=localhost user=postgres dbname=postgres password=postgres port=5432" D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\DC_data.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI



#########################################
#### FINISHED NOW GO TO 03_DEM_data_prep####
#########################################