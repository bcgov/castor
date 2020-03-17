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

---
  title: "Caribou habitat range scale model model at the scale of the range"
author: "Elizabeth Kleynhans"
date: "September 12, 2018"
output: word_document
#  Script Name: 04_caribou_habitat_model_telemetry_data_prep_doc.Rmd
#  Script Version: 1.0
#  Script Purpose: Prep telemtery data for habitat model analysis. 
---
  
  
#=================================
# Load Packages
#=================================
require (sf)
require (RPostgreSQL)
require (rpostgis)
require (fasterize)
require (raster)
require (dplyr)

## Introduction

#Here I document the process to generate the point location samples used to build a caribou resource selction fucntion model at the scale of the range. This includes documentation for how points were sampled in the home ranges i.e. 'used' sample points (i.e., the '1' dependent values in the binary logistic regression model). Also includes docuemntaion of how the 'available' sample (i.e., the '0' dependent values in the binary logistic regression model) was generated, by sampling points across the herd ranges definined by BC for 
#For review of source telemetry data, see 01_caribou_habtiat_download...  



## Methods
#List where data came from



#=================================
# Load Data
#=================================

conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")
hab_locations <- sf::st_read  (dsn = conn, # connKyle
                              query = "SELECT * FROM caribou.bc_caribou_samp_pnts_herd_boundaries")
dbDisconnect (conn) # connKyle

hab_locations$ID_number<-1:dim(hab_locations)[1]

#hab_locations <-  as (hab_locations, "Spatial")
hab_locations_st<-st_transform(hab_locations,3005)
hab_locations_sf<-st_as_sf(hab_locations_st)
hab_locations_sp<-as(hab_locations_sf,Class="Spatial")

#-----------------------
#Cutblock data
#-----------------------

# Cutblock data can be found here: PROJECTS/CLUS/DATA/cutblocks/cutblocks.tif
# batch process the cut rasters to get a distance surface in QGIS using the following command:
#"python3 -m gdal_proximity -srcband 1 -distunits PIXEL -values 1 -ot UInt32 -of GTiff C:/Work/caribou/clus_data/cutblock_tiffs/raster_cutblocks_2017.tif C:/Work/caribou/clus_data/cutblock_tiffs/dist_rast/dist_rast_cutblocks_2017.tif"

# Read in each distance raster file extract the locations and place them into new columns in a new file
## WARNING DONT RUN THIS CODE, UNLESS YOU WANT TO REBUILD THE TABLE
setwd('C:\\Work\\caribou\\clus_data\\cutblock_tiffs\\dist_rast\\')

rsf.large.scale.data<-hab_locations_st
x<-list.files(pattern=".tif", all.files=FALSE, full.names=FALSE)
y<-gsub(".tif","",x)

for (i in 1:length(x)){
  foo<-raster(x[i])
  foo2 <- raster::extract (foo, hab_locations_sp, method = 'simple',
                                          factors = T, df = T, sp = T)
  #names (rsf.large.locations) [7] <- y[i]
  
  rsf.large.scale.data <- dplyr::full_join (rsf.large.scale.data, foo2@data [c (6, 7)], 
                                            by = c ("ID_number" = "ID_number")) 
  rm (foo)
  rm(foo2)
  gc()
  print(i)
}

# save data 
conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")
st_write (obj = rsf.large.scale.data, 
          dsn = conn, 
          layer = c ("caribou", "dist_to_cutblocks_per_year"),
          overwrite=TRUE)
dbDisconnect (conn)  


#-----------------------
#Roads data
#-----------------------  

setwd("T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\Roads\\roads_ha_bc\\")
x<-list.files(pattern="dist_crds_", all.files=FALSE, full.names=FALSE)
x<-x[c(2,3,5,6,8,9,10)]

setwd('C:\\Work\\caribou\\clus_data\\cutblock_tiffs\\dist_rast\\')
y<-gsub(".tif","",x)

for (i in 1:length(x)){
  foo<-raster(x[i])
  foo2 <- raster::extract (foo, hab_locations_sp, method = 'simple',
                           factors = T, df = T, sp = T)
  #names (rsf.large.locations) [7] <- y[i]
  
  rsf.large.scale.data <- dplyr::full_join (rsf.large.scale.data, foo2@data [c (6, 7)], 
                                            by = c ("ID_number" = "ID_number")) 
  rm (foo)
  rm(foo2)
  gc()
  print(i)
}

# save data 
conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")
st_write (obj = rsf.large.scale.data, 
          dsn = conn, 
          layer = c ("caribou", "dist_to_disturbance2"),
          overwrite=TRUE)
dbDisconnect (conn)  

write.csv (rsf.large.scale.data, "C:\\Work\\caribou\\clus_data\\rsf_large_scale_data.csv")

#===================================================
# Cutblocks
#===================================================

conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")
rsf.large.scale.data <- sf::st_read  (dsn = conn,
                                       query = "SELECT * FROM caribou.dist_to_disturbance2")
dbDisconnect (conn) # connKyle


rsf.large.scale.data$distance_to_cut_1yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2017, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_2016, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_2015, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_2014, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_2013, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_2012, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_2011, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_2010, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_2009, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_2008, rsf.large.scale.data$dist_rast_cutblocks_2007))))))))))

rsf.large.scale.data$distance_to_cut_2yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2016, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_2015, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_2014, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_2013, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_2012, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_2011, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_2010, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_2009, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_2008, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_2007, rsf.large.scale.data$dist_rast_cutblocks_2006))))))))))

rsf.large.scale.data$distance_to_cut_3yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2015, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_2014, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_2013, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_2012, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_2011, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_2010, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_2009, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_2008, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_2007, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_2006, rsf.large.scale.data$dist_rast_cutblocks_2005))))))))))

rsf.large.scale.data$distance_to_cut_4yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2014, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_2013, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_2012, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_2011, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_2010, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_2009, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_2008, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_2007, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_2006, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_2005, rsf.large.scale.data$dist_rast_cutblocks_2004))))))))))

rsf.large.scale.data$distance_to_cut_5yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2013, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_2012, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_2011, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_2010, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_2009, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_2008, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_2007, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_2006, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_2005, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_2004, rsf.large.scale.data$dist_rast_cutblocks_2003))))))))))

rsf.large.scale.data$distance_to_cut_6yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2012, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_2011, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_2010, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_2009, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_2008, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_2007, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_2006, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_2005, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_2004, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_2003, rsf.large.scale.data$dist_rast_cutblocks_2002))))))))))

rsf.large.scale.data$distance_to_cut_7yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2011, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_2010, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_2009, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_2008, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_2007, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_2006, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_2005, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_2004, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_2003, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_2002, rsf.large.scale.data$dist_rast_cutblocks_2001))))))))))

rsf.large.scale.data$distance_to_cut_8yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2010, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_2009, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_2008, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_2007, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_2006, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_2005, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_2004, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_2003, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_2002, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_2001, rsf.large.scale.data$dist_rast_cutblocks_2000))))))))))

rsf.large.scale.data$distance_to_cut_9yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2009, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_2008, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_2007, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_2006, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_2005, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_2004, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_2003, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_2002, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_2001, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_2000, rsf.large.scale.data$dist_rast_cutblocks_1999))))))))))

rsf.large.scale.data$distance_to_cut_10yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2008, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_2007, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_2006, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_2005, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_2004, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_2003, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_2002, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_2001, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_2000, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1999, rsf.large.scale.data$dist_rast_cutblocks_1998))))))))))

rsf.large.scale.data$distance_to_cut_11yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2007, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_2006, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_2005, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_2004, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_2003, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_2002, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_2001, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_2000, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1999, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1998, rsf.large.scale.data$dist_rast_cutblocks_1997))))))))))

rsf.large.scale.data$distance_to_cut_12yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2006, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_2005, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_2004, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_2003, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_2002, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_2001, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_2000, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1999, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1998, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1997, rsf.large.scale.data$dist_rast_cutblocks_1996))))))))))

rsf.large.scale.data$distance_to_cut_13yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2005, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_2004, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_2003, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_2002, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_2001, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_2000, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1999, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1998, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1997, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1996, rsf.large.scale.data$dist_rast_cutblocks_1995))))))))))

rsf.large.scale.data$distance_to_cut_14yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2004, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_2003, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_2002, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_2001, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_2000, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1999, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1998, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1997, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1996, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1995, rsf.large.scale.data$dist_rast_cutblocks_1994))))))))))

rsf.large.scale.data$distance_to_cut_15yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2003, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_2002, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_2001, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_2000, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1999, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1998, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1997, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1996, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1995, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1994, rsf.large.scale.data$dist_rast_cutblocks_1993))))))))))

rsf.large.scale.data$distance_to_cut_16yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2002, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_2001, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_2000, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1999, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1998, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1997, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1996, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1995, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1994, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1993, rsf.large.scale.data$dist_rast_cutblocks_1992))))))))))

rsf.large.scale.data$distance_to_cut_17yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2001, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_2000, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1999, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1998, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1997, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1996, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1995, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1994, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1993, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1992, rsf.large.scale.data$dist_rast_cutblocks_1991))))))))))

rsf.large.scale.data$distance_to_cut_18yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_2000, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1999, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1998, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1997, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1996, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1995, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1994, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1993, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1992, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1991, rsf.large.scale.data$dist_rast_cutblocks_1990))))))))))

rsf.large.scale.data$distance_to_cut_19yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1999, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1998, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1997, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1996, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1995, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1994, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1993, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1992, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1991, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1990, rsf.large.scale.data$dist_rast_cutblocks_1989))))))))))

rsf.large.scale.data$distance_to_cut_20yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1998, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1997, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1996, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1995, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1994, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1993, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1992, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1991, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1990, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1989, rsf.large.scale.data$dist_rast_cutblocks_1988))))))))))

rsf.large.scale.data$distance_to_cut_21yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1997, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1996, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1995, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1994, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1993, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1992, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1991, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1990, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1989, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1988, rsf.large.scale.data$dist_rast_cutblocks_1987))))))))))

rsf.large.scale.data$distance_to_cut_22yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1996, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1995, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1994, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1993, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1992, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1991, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1990, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1989, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1988, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1987, rsf.large.scale.data$dist_rast_cutblocks_1986))))))))))

rsf.large.scale.data$distance_to_cut_23yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1995, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1994, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1993, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1992, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1991, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1990, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1989, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1988, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1987, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1986, rsf.large.scale.data$dist_rast_cutblocks_1985))))))))))

rsf.large.scale.data$distance_to_cut_24yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1994, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1993, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1992, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1991, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1990, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1989, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1988, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1987, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1986, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1985, rsf.large.scale.data$dist_rast_cutblocks_1984))))))))))

rsf.large.scale.data$distance_to_cut_25yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1993, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1992, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1991, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1990, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1989, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1988, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1987, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1986, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1985, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1984, rsf.large.scale.data$dist_rast_cutblocks_1983))))))))))

rsf.large.scale.data$distance_to_cut_26yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1992, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1991, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1990, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1989, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1988, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1987, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1986, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1985, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1984, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1983, rsf.large.scale.data$dist_rast_cutblocks_1982))))))))))

rsf.large.scale.data$distance_to_cut_27yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1991, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1990, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1989, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1988, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1987, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1986, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1985, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1984, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1983, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1982, rsf.large.scale.data$dist_rast_cutblocks_1981))))))))))

rsf.large.scale.data$distance_to_cut_28yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1990, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1989, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1988, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1987, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1986, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1985, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1984, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1983, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1982, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1981, rsf.large.scale.data$dist_rast_cutblocks_1980))))))))))

rsf.large.scale.data$distance_to_cut_29yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1989, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1988, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1987, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1986, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1985, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1984, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1983, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1982, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1981, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1980, rsf.large.scale.data$dist_rast_cutblocks_1979))))))))))

rsf.large.scale.data$distance_to_cut_30yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1988, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1987, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1986, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1985, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1984, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1983, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1982, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1981, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1980, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1979, rsf.large.scale.data$dist_rast_cutblocks_1978))))))))))

rsf.large.scale.data$distance_to_cut_31yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1987, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1986, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1985, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1984, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1983, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1982, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1981, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1980, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1979, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1978, rsf.large.scale.data$dist_rast_cutblocks_1977))))))))))

rsf.large.scale.data$distance_to_cut_32yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1986, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1985, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1984, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1983, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1982, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1981, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1980, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1979, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1978, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1977, rsf.large.scale.data$dist_rast_cutblocks_1976))))))))))

rsf.large.scale.data$distance_to_cut_33yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1985, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1984, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1983, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1982, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1981, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1980, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1979, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1978, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1977, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1976, rsf.large.scale.data$dist_rast_cutblocks_1975))))))))))

rsf.large.scale.data$distance_to_cut_34yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1984, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1983, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1982, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1981, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1980, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1979, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1978, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1977, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1976, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1975, rsf.large.scale.data$dist_rast_cutblocks_1974))))))))))

rsf.large.scale.data$distance_to_cut_35yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1983, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1982, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1981, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1980, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1979, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1978, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1977, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1976, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1975, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1974, rsf.large.scale.data$dist_rast_cutblocks_1973))))))))))

rsf.large.scale.data$distance_to_cut_36yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1982, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1981, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1980, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1979, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1978, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1977, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1976, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1975, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1974, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1973, rsf.large.scale.data$dist_rast_cutblocks_1972))))))))))

rsf.large.scale.data$distance_to_cut_37yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1981, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1980, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1979, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1978, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1977, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1976, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1975, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1974, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1973, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1972, rsf.large.scale.data$dist_rast_cutblocks_1971))))))))))

rsf.large.scale.data$distance_to_cut_38yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1980, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1979, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1978, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1977, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1976, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1975, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1974, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1973, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1972, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1971, rsf.large.scale.data$dist_rast_cutblocks_1970))))))))))

rsf.large.scale.data$distance_to_cut_39yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1979, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1978, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1977, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1976, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1975, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1974, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1973, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1972, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1971, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1970, rsf.large.scale.data$dist_rast_cutblocks_1969))))))))))

rsf.large.scale.data$distance_to_cut_40yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1978, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1977, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1976, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1975, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1974, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1973, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1972, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1971, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1970, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1969, rsf.large.scale.data$dist_rast_cutblocks_1968))))))))))

rsf.large.scale.data$distance_to_cut_41yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1977, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1976, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1975, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1974, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1973, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1972, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1971, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1970, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1969, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1968, rsf.large.scale.data$dist_rast_cutblocks_1967))))))))))

rsf.large.scale.data$distance_to_cut_42yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1976, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1975, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1974, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1973, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1972, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1971, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1970, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1969, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1968, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1967, rsf.large.scale.data$dist_rast_cutblocks_1966))))))))))

rsf.large.scale.data$distance_to_cut_43yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1975, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1974, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1973, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1972, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1971, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1970, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1969, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1968, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1967, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1966, rsf.large.scale.data$dist_rast_cutblocks_1965))))))))))

rsf.large.scale.data$distance_to_cut_44yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1974, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1973, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1972, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1971, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1970, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1969, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1968, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1967, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1966, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1965, rsf.large.scale.data$dist_rast_cutblocks_1964))))))))))

rsf.large.scale.data$distance_to_cut_45yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1973, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1972, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1971, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1970, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1969, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1968, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1967, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1966, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1965, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1964, rsf.large.scale.data$dist_rast_cutblocks_1963))))))))))

rsf.large.scale.data$distance_to_cut_46yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1972, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1971, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1970, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1969, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1968, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1967, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1966, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1965, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1964, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1963, rsf.large.scale.data$dist_rast_cutblocks_1962))))))))))

rsf.large.scale.data$distance_to_cut_47yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1971, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1970, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1969, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1968, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1967, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1966, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1965, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1964, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1963, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1962, rsf.large.scale.data$dist_rast_cutblocks_1961))))))))))

rsf.large.scale.data$distance_to_cut_48yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1970, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1969, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1968, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1967, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1966, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1965, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1964, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1963, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1962, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1961, rsf.large.scale.data$dist_rast_cutblocks_1960))))))))))

rsf.large.scale.data$distance_to_cut_49yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1969, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1968, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1967, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1966, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1965, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1964, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1963, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1962, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1961, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1960, rsf.large.scale.data$dist_rast_cutblocks_1959))))))))))

rsf.large.scale.data$distance_to_cut_50yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1968, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1967, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1966, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1965, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1964, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1963, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1962, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1961, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1960, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1959, rsf.large.scale.data$dist_rast_cutblocks_1958))))))))))

#rsf.large.scale.data$distance_to_cut_pre50yo <- ifelse (rsf.large.scale.data$year == 2018, rsf.large.scale.data$dist_rast_cutblocks_1967, ifelse (rsf.large.scale.data$year == 2017, rsf.large.scale.data$dist_rast_cutblocks_1966, ifelse (rsf.large.scale.data$year == 2016, rsf.large.scale.data$dist_rast_cutblocks_1965, ifelse (rsf.large.scale.data$year == 2015, rsf.large.scale.data$dist_rast_cutblocks_1964, ifelse (rsf.large.scale.data$year == 2014, rsf.large.scale.data$dist_rast_cutblocks_1963, ifelse (rsf.large.scale.data$year == 2013, rsf.large.scale.data$dist_rast_cutblocks_1962, ifelse (rsf.large.scale.data$year == 2012, rsf.large.scale.data$dist_rast_cutblocks_1961, ifelse (rsf.large.scale.data$year == 2011, rsf.large.scale.data$dist_rast_cutblocks_1960, ifelse (rsf.large.scale.data$year == 2010, rsf.large.scale.data$dist_rast_cutblocks_1959, ifelse (rsf.large.scale.data$year == 2009, rsf.large.scale.data$dist_rast_cutblocks_1958, rsf.large.scale.data$dist_rast_cutblocks_pre1957))))))))))


rsf.large.scale.data.age <- rsf.large.scale.data [, c (1:6, 68:125)]

# save data 
conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")
st_write (obj = rsf.large.scale.data.age, 
          dsn = conn, 
          layer = c ("caribou", "dist_to_disturbance_summary"),
          overwrite=TRUE)
dbDisconnect (conn)  


write.table (rsf.large.scale.data.age, "C:\\Work\\caribou\\clus_data\\disturbance\\rsf_data_cutblock_age_and_roads.csv", sep = ",")








#_______________________________________________________________-





writeCutblockRaster <- function (harvest.year) {
  writeRaster (
    fasterize (
      dplyr::filter (
        cutblocks, 
        HARVEST_YEAR == harvest.year
      ), 
      ProvRast,  
      field = NULL, 
      background = 0
    ),
    filename = paste0 ("cutblocks\\cutblock_tiffs\\raster_cutblocks_", harvest.year, ".tiff"),
    format = "GTiff", 
    datatype = 'INT1U'
  )
}


#=================================
# Set data directory
#=================================
setwd ('C:\\Work\\caribou\\clus_data\\')
options (scipen = 999)

#===================================================
# Create functions and empty ha BC raster
#==================================================
conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")

writeRasterQuery <- function (schemaraster, rasterR) {
  conn <- dbConnect (dbDriver ("PostgreSQL"), 
                     host = "",
                     user = "postgres",
                     dbname = "postgres",
                     password = "postgres",
                     port = "5432")
  on.exit (dbDisconnect (conn))
  pgWriteRast (conn, schemaraster, rasterR, overwrite = TRUE)
}


writeTableQuery <- function (dataR, tablename){
  conn <- dbConnect (dbDriver("PostgreSQL"), 
                     host = "",
                     user = "postgres",
                     dbname = "postgres",
                     password = "postgres",
                     port = "5432")
  on.exit (dbDisconnect (conn))
  st_write (obj = dataR, dsn = conn, layer = tablename)
}

writeCutblockRaster <- function (harvest.year) {
  writeRaster (
    fasterize (
      dplyr::filter (
        cutblocks, 
        HARVEST_YEAR == harvest.year
      ), 
      ProvRast,  
      field = NULL, 
      background = 0
    ),
    filename = paste0 ("cutblocks\\cutblock_tiffs\\raster_cutblocks_", harvest.year, ".tiff"),
    format = "GTiff", 
    datatype = 'INT1U'
  )
}

#===================================================
# Cutblocks
#==================================================
# idea here is to create rasters of cutblocks by year (similar to what STSM models output), 
# then explicitly test for effects of age on caribou selection using regression models
cutblocks <- sf::st_read (dsn = "caribou_habitat_model\\caribou_habitat_model.gdb", 
                          layer = "cutblocks_20180725") 
writeTableQuery (cutblocks, c ("human", "cutblocks_20180725"))

cut.years <- sort (unique (cutblocks$HARVEST_YEAR)) # identify the cutblock years
cut.years.for.raster <- cut.years[50:107]

# need to filter data by year because unable to run functions (see below) on full dataset
cutblocks.2017 <- dplyr::filter (cutblocks, HARVEST_YEAR == 2017)
ras.cutblocks.2017 <- fasterize (cutblocks.2017, ProvRast, 
                                 field = NULL,# raster cells that were cut get in 2017 get a value of 1
                                 background = 0) # unharvested raster cells get value = 0 
raster::writeRaster (ras.cutblocks.2017, 
                     filename = "cutblocks\\cutblock_tiffs\\raster_cutblocks_2017.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U')
# there appears to be memory issues with saivng to postgres, so saving as TIFFs for now
# writeRasterQuery (c ("human", "raster_cutblocks_2017"), ras.cutblocks.2017) 
rm (cutblocks.2017, ras.cutblocks.2017)
gc () # free up some RAM
# 2017 done as test, the rest done with the writeCutblockRaster function 
writeCutblockRaster (2016) # testing fucntion
gc ()
system.time (writeCutblockRaster (2015))
gc ()

for (i in cut.years.for.raster) { # run through list for 1957 to 2014
  writeCutblockRaster (i)
  gc ()
}

cutblocks.pre.1957 <- dplyr::filter (cutblocks, HARVEST_YEAR < 1957) # do one for all pre 1957 cutblocks
ras.cutblocks.pre.1957 <- fasterize (cutblocks.pre.1957, ProvRast, 
                                     field = NULL,# raster cells that were cut get in 2017 get a value of 1
                                     background = 0) # unharvested raster cells get value = 0 
raster::writeRaster (ras.cutblocks.pre.1957, 
                     filename = "cutblocks\\cutblock_tiffs\\raster_cutblocks_pre1957.tiff", 
                     format = "GTiff", 
                     datatype = 'INT1U')

# calculate last year the raster was cut
# ras.cutblocks <- fasterize (cutblocks, ProvRast, field = "HARVEST_YEAR" , 
#                            fun = "last",
#                            background = 0) # unharvested rasters get value = 0 



# Cutblocks 
cutblocks40 <- cutblocks [cutblocks@data$HARVESTYR > 1977, ]  
# subset last 40 years
cutblocks40 <- spTransform (cutblocks40, CRS = ras.crs)
ras.cutblocks <- rasterize (cutblocks40, empty.raster, getCover = T)
sample.pts.cut <- raster::extract (ras.cutblocks, sample.pts.ras.prj, 
                                   method = 'bilinear',
                                   factors = F, df = T) 
sample.pts.cut$ptID <- 1:131054
sample.pts.ras.prj@data <- dplyr::full_join (sample.pts.ras.prj@data, sample.pts.cut, 
                                             by = c ("ptID" = "ptID")) 
names (sample.pts.ras.prj@data) [104] <- "cut.prop" 
# writeRaster (ras.cutblocks, "cutblocks\\raster\\cut_rast.tif", format = "GTiff", prj = T)
# ras.cutblocks <- raster ("cutblocks\\raster\\cut_rast.tif")
# test1 <- sample.pts.ras.prj@data [sample.pts.ras.prj@data$ptID == 200000, ]