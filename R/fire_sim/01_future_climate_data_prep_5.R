# ---
#   title: "01_future_climate_data_prep"
# author: "Elizabeth Kleynhans"
# date: "2021-03-29"
# output: 
#   html_document:
#   keep_md: yes
# ---
#   <!--
#   Copyright 2020 Province of British Columbia
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
# -->
#   

#### Introduction

# Here I am trying to downscale global climate change models to a 800 x 800m scale (or finer) so that they can be used to predict fire occurence in the future. ClimateBC has a little program that you can use to extract future climate values for any number of locations within BC, but manually extracting millions of locations for each year (2019 - 2100) and for multiple difference gcm's is time consuming and repetitive. Also, CMIP 5 is shortly going to be replaced with CMIP 6 but this data has not come out on climateBC yet. I chatted to Colin Mahony and he suggested I do the downscaling myself. He outlined the steps I should take and its pretty straight forward so thats the path Im following. 

#### Methods

# The delta downscaling approach is described in https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0156720#sec017, but basically is: 
# 1.	Start with your high-resolution observational climate normals (800m PRISM (https://www.pacificclimate.org/data/prism-climatology-and-monthly-timeseries-portal), or finer ClimateBC data) for a reference period (e.g., 1971-2000)
# 
# 2.	For each GCM, convert simulated values to deviations (anomalies) from the grand-mean reference period climate of multiple historical simulations.
# 2a. Each GCM has several historical runs from 1850 to 2014. For each month of each element (e.g., January Tmin), calculate the mean of each of these runs for the reference period (1971-2000). Then calculate the mean of these reference period means; that’s the grand mean. for each grid cell of each gcm, you will have one raster for jan Tmin, one for feb Tmin, etc. 
# 2b. then subtract this value from each GCM time series that you want to use. For precipitation, you divide instead of subtracting, using this value as the denominator. 
# 
# 3.	Bilinearly interpolate these anomaly rasters to the grid scale of the observational climate normals.
# 
# 4.	Add (or multiply for precipitation) these anomalies to the observational climate normals (PRISM data). 

#### Information about MPI-ESM1-2-HR from http://www.glisaclimate.org/model-inventory/max-planck-institute-for-meteorology-earth-system-model-mr

# Temperature
# Mean Temperature Output Name: tas
# Mean Temperature Temporal Frequency: Daily
# Min/Max Temperature Output Name: tasmin/tasmax
# Min/Max Temperature Temporal Frequency: Daily
# Temperature Units: Kelvin
# 
# Precipitation
# Total Precipitation Output Name: pr
# Total Precipitation Temporal Frequency: Daily
# Convective Precipitation Output Name: prc
# Convective Precipitation Temporal Frequency: Daily
# Precipitation Units: kg m-2 s-1

##########################################
#### try to get difference between reference layer and each year at raster scale of  the future climate ####
##########################################
#For each GCM, convert simulated values to deviations (anomalies) from the grand-mean reference period climate of multiple historical simulations. 

# one option is to get the ref climate data at the same resolution as the projected climate data and then extract the long lat locations (that need to be same as future climate locations) and then just subtract the values off the regular csv file. I.e. i do all the scale conversions on the reference layer (for now). Later I will do the downscaling of the future layers.

library(sf) 
library(ncdf4)
library(raster)
library(rasterVis)
library(RColorBrewer)
library(dplyr)
library(data.table)

# get outline of BC
prov.bnd <- st_read ( dsn = "T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\admin_boundaries\\province\\gpr_000b11a_e.shp", stringsAsFactors = T)
st_crs(prov.bnd)
prov.bnd <- prov.bnd [prov.bnd$PRENAME == "British Columbia", ]
prov.bnd <- as(st_geometry(prov.bnd), Class="Spatial")


#### PRISM REFERENCE DATA ####
# 1.	Start with your high-resolution observational climate normals (800m PRISM (https://www.pacificclimate.org/data/prism-climatology-and-monthly-timeseries-portal), or finer ClimateBC data) for a reference period (e.g., 1971-2000)

ncrefpath <- "D:\\Fire\\fire_data\\raw_data\\Future_climate\\"
ncrefname <- "tasmax_mClimMean_PRISM_historical_19710101-20001231.nc"  
ncfrefname <- paste(ncrefpath, ncrefname, ".nc", sep="")
dname <- "tmax"    
tmax_ref_raster <- brick(ncfrefname, varname=dname)
tmax_ref_raster; class(tmax_ref_raster)
 
# Get lat long locations of center of each pixel in reference climate
tmax_ref_01 <- raster(tmax_ref_raster, layer=1)
data_matrix <- rasterToPoints(tmax_ref_01, spatial=TRUE)
proj4string(data_matrix)
sppts <- spTransform(data_matrix, CRS("+proj=longlat +datum=WGS84 +no_defs"))

# EXTRACT PRISM REFERENCE DATA AT TARGET POINTS
tmax_ref_raster_croped<- crop(tmax_ref_raster, prov.bnd)
tmax_ref_pts <- extract(tmax_ref_raster_croped, sppts, method="simple")
tmax_ref_pts_df <- as.data.frame(tmax_ref_pts)
tmax_ref_pts_df<- cbind(as.data.frame(sppts)[2:3], tmax_ref_pts_df)
tmax_ref_pts_df <- tmax_ref_pts_df %>% dplyr::rename(lon=x, lat=y)
dim(tmax_ref_pts_df)

####CALCULATE GRAND-MEAN REFERENCE PERIOD DATA (19710101-20001231) ####
# 2a. Each GCM has several historical runs from 1850 to 2014. For each month of each element (e.g., January Tmin), calculate the mean of each of these runs for the reference period (1971-2000). Then calculate the mean of these reference period means; that’s the grand mean. for each grid cell of each gcm, you will have one raster for jan Tmin, one for feb Tmin, etc. 

ncpath <- "D:\\Fire\\fire_data\\raw_data\\Future_climate\\MPI-ESM1-2-HR\\"
ncname <- c("tasmax_Amon_MPI-ESM1-2-HR_historical_r1i1p1f1_gn_200001-200412", "tasmax_Amon_MPI-ESM1-2-HR_historical_r1i1p1f1_gn_200501-200912","tasmax_Amon_MPI-ESM1-2-HR_historical_r1i1p1f1_gn_201001-201412")  
dname <- "tasmax"  # These temperature readings are in Kelvin (C = Kelvin - 273.15)
tmax_fc_pts_df<- as.data.frame(sppts)[2:3]
tmax_fc_pts_df <- tmax_fc_pts_df %>% dplyr::rename(lon=x, lat=y)

monthdays <- c(31, 28.25, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
monthcodes <- c("01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12")

dirs <- list.dirs("D:\\Fire\\fire_data\\raw_data\\Future_climate")
gcms <- unique(sapply(strsplit(dirs, "/"), "[", 2))
select <- c(3)
gcms[select]

i=1
for(i in select[1:length(select)]){
  gcm <- gcms[3]
  
  #process the climate elements
  dir <- paste("D:\\Fire\\fire_data\\raw_data\\Future_climate", gcm, sep="\\")
  files <- list.files(dir)
  element.list <- sapply(strsplit(files, "_"), "[", 1)
  scenario.list <- sapply(strsplit(files, "_"), "[", 4)
  #year.list<-sapply(strsplit(files, "_"),"[",7)
  #year.list1<-sapply(strsplit(year.list, "-"),"[",1)
  ripf.list <- sapply(strsplit(files, "_"), "[", 5)
  run.list <- paste(scenario.list, ripf.list, sep="_")
  elements <- unique(element.list)[c(3,4,1)]
  runs <- unique(run.list)
  years<- c("197001", "197501", "198001", "198501", "199001", "199501", "200001")
  
  # units of pr are in mm/s
  # library(ncdf4)
  # element="pr"
  # data <- nc_open(paste(dir, files.run[grep(element, files.run)], sep="\\"))
  # print(data)
  
  run=runs[2]
  for(run in runs){
    files.run <- files[grep(run, files)] # get all files from a specific GCM run e.g. historical_r1i1p1f1
    
    element=elements[1]
    for(element in elements){
      files.element <- files.run[grep(element, files.run)] # get all tasmax/tasmin/pr files from the specific GCM run
      
      for(year in 1:length(years)){
        files.years<-files.element[grep(years[year], files.element)] # get the 
       #did this rather than stack import becuase it preserves the variable (month) names
        temp2 <- brick(paste(dir, files.years, sep="\\"))
        temp <- if(year==1) temp2 else brick(c(temp, temp2))
        print(year)
      }
      
      m=1
      for(m in 1:12){
        r <- temp[[which(substr(names(temp),7,8)==monthcodes[m])]] # get all Januaries or Februaries etc
        if(element=="pr") r <- r*86400*monthdays[m] else r <- r-273.15  #convert units to /month (86400 seconds / day) and to degrees C
        
        r1<- r[[1:31]] # select columns 1970 - 2000
        r.mean<- mean(r1)
        plot(r.mean)
            }
      
     
      }
    }
    names(gcm.ts) <- names(obs.ts)
    write.csv(gcm.ts,paste("outputs\\ts.", gcm, ".", run, ".csv", sep=""), row.names=FALSE)
    print(run)
  }
  
}





#### FUTURE CLIMATE DATA 2000 to 2004 - this takes a long time to run ####
ncpath <- "D:\\Fire\\fire_data\\raw_data\\Future_climate\\MPI-ESM1-2-HR\\"
ncname <- c("tasmax_Amon_MPI-ESM1-2-HR_historical_r1i1p1f1_gn_200001-200412", "tasmax_Amon_MPI-ESM1-2-HR_historical_r1i1p1f1_gn_200501-200912","tasmax_Amon_MPI-ESM1-2-HR_historical_r1i1p1f1_gn_201001-201412")  
dname <- "tasmax"  # These temperature readings are in Kelvin (C = Kelvin - 273.15)
tmax_fc_pts_df<- as.data.frame(sppts)[2:3]
tmax_fc_pts_df <- tmax_fc_pts_df %>% dplyr::rename(lon=x, lat=y)


for(i in 1:length(ncname)){
ncfname <- paste(ncpath, ncname[i], ".nc", sep="")
tmax_fc_raster <- brick(ncfname, varname=dname)
tmax_fc_raster; class(tmax_fc_raster)

tmax_fc_raster_c<- tmax_fc_raster-273.15 # changing temperature from Kelvin to Celcius

# Bilinearly interpolate the future climate values to match the grid scale of the reference climate
tmax_fc_raster_resampled<-resample(tmax_fc_raster_c, tmax_ref_01, method='bilinear')

# EXTRACT FUTURE CLIMATE DATA AT TARGET POINTS
tmax_fc_raster_resampled_croped<- crop(tmax_fc_raster_resampled, prov.bnd) #Cropping hopefully speeds up the extract command. I crop after interpolation because I want the edges of BC to be more accurate.
tmax_fc_pts <- extract(tmax_fc_raster_resampled_croped, sppts, method="simple")
tmax_fc_pts1 <- as.data.frame(tmax_fc_pts)
tmax_fc_pts_df<- cbind(tmax_fc_pts_df, tmax_fc_pts1)
dim(tmax_fc_pts_df)
}


##############################################################
# 2.	For each GCM, convert simulated values to deviations (anomalies) from the grand-mean reference period climate of multiple historical simulations. 
# a.	Degrees Celsius for temperature and percentage change for precipitation


# joining reference df and future climate df pts together so that I can subtract the reference pts from the future pts
ref_future_tmax_pts1<- left_join(tmax_ref_pts_df,tmax_fc_pts_df)
ref_future_tmax_pts<-na.omit(ref_future_tmax_pts1)

dim(ref_future_tmax_pts)
names(ref_future_tmax_pts)

ref_climate<-rep(3:14,15)
future_climate<- 15:194

month<- rep(1:12, 15)
year<- c(rep("2000", 12), rep("2001", 12), rep("2002", 12), rep("2003", 12), rep("2004",12), rep("2005",12),rep("2006",12),rep("2007",12),rep("2008",12),rep("2009",12),rep("2010",12),rep("2011",12),rep("2012",12),rep("2013",12),rep("2014",12), rep("2015",12))

for(i in 1:length(ref_climate)){
  ref_future_tmax_pts[, ncol(ref_future_tmax_pts) + 1] <- ref_future_tmax_pts[future_climate[i]]-ref_future_tmax_pts[ref_climate[i]]
  names(ref_future_tmax_pts)[ncol(ref_future_tmax_pts)] <- paste("delta", "tmax",month[i], year[i], sep="_")
}

# Check that the values that are being created make sense!!! I dont know its a bit weird because the GCM values are mostly less than the reference period. What I think is going on is that I have not accounted for elevation and so areas that are low or high are getting in accurate temperatures when I interpolate at the 60km grid scale. Im not sure how to fix this or how how it usually gets fixed in climate models. 
summary_future_clim<- ref_future_tmax_pts %>%
  dplyr::select(delta_tmax_1_2000:delta_tmax_12_2014) 
plot(colMeans(summary_future_clim), type="l")

tmax_2000_to_2014<-ref_future_tmax_pts %>%
  dplyr::select(lon:X1985.12.15 ,delta_tmax_1_2000:delta_tmax_12_2014) 

spg <- ref_future_tmax_pts %>%
  dplyr::select(lon, lat, delta_tmax_5_2000)
coordinates(spg) <- ~ lon + lat
# coerce to SpatialPixelsDataFrame
gridded(spg) <- TRUE
# coerce to raster
rasterDF <- raster(spg)
plot(rasterDF)

fwrite(ref_future_tmax_pts, "D:\\Fire\\fire_data\\raw_data\\Future_climate\\csv_outputs\\tmax_MPI-ESM1-2-HR_r1i1p1f1_refPeriod_2000_2004.csv") # fwrite turns out to be much faster than write.csv!!!


sample_locations<-ref_future_tmax_pts %>%
  dplyr::select(lon, lat) %>%
  rename(long=lon)

sample_locations$ID1<-1:length(sample_locations$long)
sample_locations$ID2<-2019
sample_locations$el<-"."

fwrite(sample_locations, "D:\\Fire\\fire_data\\raw_data\\Future_climate\\csv_outputs\\sample_locations_2019.csv")
