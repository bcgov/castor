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

source(here::here("R/functions/R_Postgres.R"))

#Get dummy layer for projection 
lyr<-getSpatialQuery(paste("SELECT geom FROM public.gcbp_carib_polygon"))

#Make an empty provincial raster aligned with hectares BC
ProvRast <- raster(
  nrows = 15744, ncols = 17216, xmn = 159587.5, xmx = 1881187.5, ymn = 173787.5, ymx = 1748187.5, 
  crs = st_crs(lyr)$proj4string, resolution = c(100, 100), vals = 0
) # from https://github.com/bcgov/bc-raster-roads/blob/master/03_analysis.R


forest.tenure<-getSpatialQuery("SELECT * FROM forest_tenure") # get all TSA and TFL's for the entire province
forest.tenure<-st_transform(forest.tenure, 3005)
plot(forest.tenure[, "tsa_number"]) # check we got the whole province

tsa.rast<-fasterize::fasterize(sf= forest.tenure, raster = ProvRast , field = "objectid")

# change the raster to points and pull out the centre location
pts<-rasterToPoints(tsa.rast,spatial=TRUE)
dim(pts) # over 100 million points. This is really going to bog down ram when it writes the climateBC data to disk so Ill split this file into groups. 

# reproject sp object
geo.prj <- "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0" 
r.pts <- spTransform(pts, CRS(geo.prj)) 
proj4string(r.pts)

# Assign coordinates to @data slot, display first 6 rows of data.frame
r.pts@data <- data.frame(r.pts@data, lat=coordinates(r.pts)[,2],
                         long=coordinates(r.pts)[,1]) 
head(r.pts@data)
r.pts<- as.data.frame(r.pts@data)

r.pts <- r.pts %>% 
  rename(ID2=layer) # ID2 (layer) is the TSA number I think.
r.pts$ID1<- 1:length(r.pts$lat) # ID1 should correspond to the 
r.pts<- r.pts %>%
  select(ID1, ID2, lat, long)
r.pts$el <- "."
head(r.pts)
rm(ProvRast)
gc()

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


