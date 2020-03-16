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


#===================================================
# Cutblocks
#===================================================
rsf.data.cut <- read.csv ("C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_cutblock.csv")

rsf.data.cut$distance_to_cut_1yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2017, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_2016, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_2015, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_2014, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_2013, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_2012, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_2011, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_2010, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_2009, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_2008, rsf.data.cut$distance_to_cutblocks_2007))))))))))

rsf.data.cut$distance_to_cut_2yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2016, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_2015, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_2014, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_2013, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_2012, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_2011, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_2010, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_2009, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_2008, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_2007, rsf.data.cut$distance_to_cutblocks_2006))))))))))

rsf.data.cut$distance_to_cut_3yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2015, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_2014, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_2013, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_2012, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_2011, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_2010, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_2009, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_2008, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_2007, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_2006, rsf.data.cut$distance_to_cutblocks_2005))))))))))

rsf.data.cut$distance_to_cut_4yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2014, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_2013, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_2012, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_2011, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_2010, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_2009, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_2008, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_2007, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_2006, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_2005, rsf.data.cut$distance_to_cutblocks_2004))))))))))

rsf.data.cut$distance_to_cut_5yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2013, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_2012, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_2011, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_2010, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_2009, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_2008, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_2007, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_2006, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_2005, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_2004, rsf.data.cut$distance_to_cutblocks_2003))))))))))

rsf.data.cut$distance_to_cut_6yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2012, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_2011, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_2010, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_2009, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_2008, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_2007, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_2006, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_2005, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_2004, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_2003, rsf.data.cut$distance_to_cutblocks_2002))))))))))

rsf.data.cut$distance_to_cut_7yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2011, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_2010, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_2009, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_2008, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_2007, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_2006, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_2005, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_2004, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_2003, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_2002, rsf.data.cut$distance_to_cutblocks_2001))))))))))

rsf.data.cut$distance_to_cut_8yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2010, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_2009, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_2008, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_2007, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_2006, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_2005, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_2004, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_2003, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_2002, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_2001, rsf.data.cut$distance_to_cutblocks_2000))))))))))

rsf.data.cut$distance_to_cut_9yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2009, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_2008, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_2007, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_2006, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_2005, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_2004, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_2003, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_2002, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_2001, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_2000, rsf.data.cut$distance_to_cutblocks_1999))))))))))

rsf.data.cut$distance_to_cut_10yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2008, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_2007, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_2006, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_2005, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_2004, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_2003, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_2002, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_2001, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_2000, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1999, rsf.data.cut$distance_to_cutblocks_1998))))))))))

rsf.data.cut$distance_to_cut_11yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2007, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_2006, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_2005, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_2004, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_2003, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_2002, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_2001, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_2000, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1999, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1998, rsf.data.cut$distance_to_cutblocks_1997))))))))))

rsf.data.cut$distance_to_cut_12yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2006, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_2005, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_2004, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_2003, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_2002, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_2001, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_2000, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1999, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1998, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1997, rsf.data.cut$distance_to_cutblocks_1996))))))))))

rsf.data.cut$distance_to_cut_13yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2005, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_2004, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_2003, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_2002, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_2001, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_2000, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1999, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1998, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1997, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1996, rsf.data.cut$distance_to_cutblocks_1995))))))))))

rsf.data.cut$distance_to_cut_14yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2004, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_2003, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_2002, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_2001, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_2000, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1999, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1998, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1997, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1996, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1995, rsf.data.cut$distance_to_cutblocks_1994))))))))))

rsf.data.cut$distance_to_cut_15yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2003, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_2002, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_2001, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_2000, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1999, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1998, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1997, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1996, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1995, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1994, rsf.data.cut$distance_to_cutblocks_1993))))))))))

rsf.data.cut$distance_to_cut_16yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2002, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_2001, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_2000, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1999, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1998, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1997, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1996, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1995, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1994, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1993, rsf.data.cut$distance_to_cutblocks_1992))))))))))

rsf.data.cut$distance_to_cut_17yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2001, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_2000, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1999, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1998, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1997, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1996, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1995, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1994, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1993, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1992, rsf.data.cut$distance_to_cutblocks_1991))))))))))

rsf.data.cut$distance_to_cut_18yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_2000, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1999, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1998, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1997, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1996, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1995, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1994, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1993, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1992, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1991, rsf.data.cut$distance_to_cutblocks_1990))))))))))

rsf.data.cut$distance_to_cut_19yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1999, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1998, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1997, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1996, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1995, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1994, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1993, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1992, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1991, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1990, rsf.data.cut$distance_to_cutblocks_1989))))))))))

rsf.data.cut$distance_to_cut_20yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1998, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1997, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1996, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1995, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1994, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1993, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1992, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1991, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1990, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1989, rsf.data.cut$distance_to_cutblocks_1988))))))))))

rsf.data.cut$distance_to_cut_21yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1997, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1996, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1995, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1994, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1993, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1992, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1991, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1990, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1989, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1988, rsf.data.cut$distance_to_cutblocks_1987))))))))))

rsf.data.cut$distance_to_cut_22yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1996, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1995, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1994, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1993, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1992, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1991, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1990, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1989, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1988, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1987, rsf.data.cut$distance_to_cutblocks_1986))))))))))

rsf.data.cut$distance_to_cut_23yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1995, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1994, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1993, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1992, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1991, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1990, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1989, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1988, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1987, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1986, rsf.data.cut$distance_to_cutblocks_1985))))))))))

rsf.data.cut$distance_to_cut_24yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1994, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1993, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1992, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1991, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1990, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1989, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1988, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1987, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1986, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1985, rsf.data.cut$distance_to_cutblocks_1984))))))))))

rsf.data.cut$distance_to_cut_25yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1993, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1992, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1991, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1990, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1989, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1988, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1987, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1986, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1985, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1984, rsf.data.cut$distance_to_cutblocks_1983))))))))))

rsf.data.cut$distance_to_cut_26yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1992, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1991, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1990, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1989, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1988, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1987, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1986, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1985, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1984, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1983, rsf.data.cut$distance_to_cutblocks_1982))))))))))

rsf.data.cut$distance_to_cut_27yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1991, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1990, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1989, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1988, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1987, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1986, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1985, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1984, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1983, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1982, rsf.data.cut$distance_to_cutblocks_1981))))))))))

rsf.data.cut$distance_to_cut_28yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1990, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1989, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1988, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1987, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1986, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1985, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1984, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1983, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1982, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1981, rsf.data.cut$distance_to_cutblocks_1980))))))))))

rsf.data.cut$distance_to_cut_29yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1989, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1988, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1987, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1986, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1985, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1984, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1983, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1982, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1981, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1980, rsf.data.cut$distance_to_cutblocks_1979))))))))))

rsf.data.cut$distance_to_cut_30yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1988, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1987, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1986, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1985, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1984, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1983, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1982, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1981, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1980, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1979, rsf.data.cut$distance_to_cutblocks_1978))))))))))

rsf.data.cut$distance_to_cut_31yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1987, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1986, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1985, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1984, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1983, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1982, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1981, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1980, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1979, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1978, rsf.data.cut$distance_to_cutblocks_1977))))))))))

rsf.data.cut$distance_to_cut_32yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1986, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1985, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1984, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1983, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1982, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1981, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1980, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1979, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1978, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1977, rsf.data.cut$distance_to_cutblocks_1976))))))))))

rsf.data.cut$distance_to_cut_33yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1985, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1984, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1983, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1982, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1981, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1980, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1979, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1978, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1977, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1976, rsf.data.cut$distance_to_cutblocks_1975))))))))))

rsf.data.cut$distance_to_cut_34yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1984, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1983, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1982, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1981, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1980, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1979, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1978, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1977, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1976, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1975, rsf.data.cut$distance_to_cutblocks_1974))))))))))

rsf.data.cut$distance_to_cut_35yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1983, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1982, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1981, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1980, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1979, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1978, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1977, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1976, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1975, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1974, rsf.data.cut$distance_to_cutblocks_1973))))))))))

rsf.data.cut$distance_to_cut_36yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1982, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1981, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1980, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1979, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1978, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1977, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1976, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1975, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1974, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1973, rsf.data.cut$distance_to_cutblocks_1972))))))))))

rsf.data.cut$distance_to_cut_37yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1981, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1980, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1979, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1978, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1977, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1976, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1975, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1974, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1973, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1972, rsf.data.cut$distance_to_cutblocks_1971))))))))))

rsf.data.cut$distance_to_cut_38yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1980, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1979, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1978, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1977, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1976, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1975, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1974, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1973, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1972, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1971, rsf.data.cut$distance_to_cutblocks_1970))))))))))

rsf.data.cut$distance_to_cut_39yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1979, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1978, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1977, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1976, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1975, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1974, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1973, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1972, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1971, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1970, rsf.data.cut$distance_to_cutblocks_1969))))))))))

rsf.data.cut$distance_to_cut_40yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1978, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1977, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1976, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1975, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1974, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1973, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1972, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1971, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1970, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1969, rsf.data.cut$distance_to_cutblocks_1968))))))))))

rsf.data.cut$distance_to_cut_41yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1977, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1976, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1975, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1974, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1973, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1972, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1971, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1970, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1969, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1968, rsf.data.cut$distance_to_cutblocks_1967))))))))))

rsf.data.cut$distance_to_cut_42yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1976, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1975, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1974, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1973, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1972, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1971, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1970, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1969, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1968, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1967, rsf.data.cut$distance_to_cutblocks_1966))))))))))

rsf.data.cut$distance_to_cut_43yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1975, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1974, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1973, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1972, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1971, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1970, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1969, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1968, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1967, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1966, rsf.data.cut$distance_to_cutblocks_1965))))))))))

rsf.data.cut$distance_to_cut_44yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1974, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1973, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1972, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1971, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1970, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1969, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1968, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1967, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1966, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1965, rsf.data.cut$distance_to_cutblocks_1964))))))))))

rsf.data.cut$distance_to_cut_45yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1973, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1972, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1971, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1970, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1969, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1968, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1967, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1966, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1965, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1964, rsf.data.cut$distance_to_cutblocks_1963))))))))))

rsf.data.cut$distance_to_cut_46yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1972, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1971, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1970, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1969, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1968, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1967, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1966, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1965, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1964, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1963, rsf.data.cut$distance_to_cutblocks_1962))))))))))

rsf.data.cut$distance_to_cut_47yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1971, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1970, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1969, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1968, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1967, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1966, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1965, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1964, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1963, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1962, rsf.data.cut$distance_to_cutblocks_1961))))))))))

rsf.data.cut$distance_to_cut_48yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1970, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1969, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1968, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1967, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1966, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1965, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1964, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1963, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1962, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1961, rsf.data.cut$distance_to_cutblocks_1960))))))))))

rsf.data.cut$distance_to_cut_49yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1969, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1968, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1967, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1966, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1965, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1964, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1963, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1962, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1961, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1960, rsf.data.cut$distance_to_cutblocks_1959))))))))))

rsf.data.cut$distance_to_cut_50yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1968, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1967, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1966, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1965, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1964, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1963, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1962, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1961, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1960, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1959, rsf.data.cut$distance_to_cutblocks_1958))))))))))

rsf.data.cut$distance_to_cut_pre50yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$distance_to_cutblocks_1967, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$distance_to_cutblocks_1966, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$distance_to_cutblocks_1965, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$distance_to_cutblocks_1964, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$distance_to_cutblocks_1963, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$distance_to_cutblocks_1962, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$distance_to_cutblocks_1961, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$distance_to_cutblocks_1960, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$distance_to_cutblocks_1959, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$distance_to_cutblocks_1958, rsf.data.cut$distance_to_cutblocks_pre1957))))))))))

rsf.data.cut$cut_1yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2017, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_2016, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_2015, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_2014, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_2013, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_2012, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_2011, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_2010, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_2009, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_2008, rsf.data.cut$cutblocks_2007))))))))))

rsf.data.cut$cut_2yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2016, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_2015, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_2014, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_2013, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_2012, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_2011, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_2010, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_2009, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_2008, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_2007, rsf.data.cut$cutblocks_2006))))))))))

rsf.data.cut$cut_3yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2015, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_2014, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_2013, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_2012, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_2011, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_2010, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_2009, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_2008, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_2007, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_2006, rsf.data.cut$cutblocks_2005))))))))))

rsf.data.cut$cut_4yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2014, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_2013, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_2012, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_2011, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_2010, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_2009, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_2008, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_2007, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_2006, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_2005, rsf.data.cut$cutblocks_2004))))))))))

rsf.data.cut$cut_5yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2013, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_2012, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_2011, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_2010, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_2009, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_2008, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_2007, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_2006, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_2005, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_2004, rsf.data.cut$cutblocks_2003))))))))))

rsf.data.cut$cut_6yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2012, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_2011, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_2010, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_2009, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_2008, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_2007, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_2006, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_2005, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_2004, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_2003, rsf.data.cut$cutblocks_2002))))))))))

rsf.data.cut$cut_7yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2011, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_2010, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_2009, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_2008, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_2007, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_2006, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_2005, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_2004, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_2003, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_2002, rsf.data.cut$cutblocks_2001))))))))))

rsf.data.cut$cut_8yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2010, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_2009, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_2008, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_2007, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_2006, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_2005, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_2004, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_2003, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_2002, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_2001, rsf.data.cut$cutblocks_2000))))))))))

rsf.data.cut$cut_9yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2009, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_2008, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_2007, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_2006, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_2005, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_2004, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_2003, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_2002, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_2001, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_2000, rsf.data.cut$cutblocks_1999))))))))))

rsf.data.cut$cut_10yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2008, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_2007, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_2006, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_2005, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_2004, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_2003, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_2002, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_2001, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_2000, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1999, rsf.data.cut$cutblocks_1998))))))))))

rsf.data.cut$cut_11yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2007, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_2006, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_2005, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_2004, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_2003, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_2002, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_2001, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_2000, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1999, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1998, rsf.data.cut$cutblocks_1997))))))))))

rsf.data.cut$cut_12yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2006, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_2005, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_2004, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_2003, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_2002, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_2001, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_2000, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1999, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1998, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1997, rsf.data.cut$cutblocks_1996))))))))))

rsf.data.cut$cut_13yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2005, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_2004, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_2003, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_2002, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_2001, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_2000, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1999, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1998, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1997, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1996, rsf.data.cut$cutblocks_1995))))))))))

rsf.data.cut$cut_14yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2004, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_2003, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_2002, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_2001, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_2000, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1999, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1998, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1997, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1996, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1995, rsf.data.cut$cutblocks_1994))))))))))

rsf.data.cut$cut_15yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2003, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_2002, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_2001, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_2000, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1999, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1998, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1997, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1996, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1995, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1994, rsf.data.cut$cutblocks_1993))))))))))

rsf.data.cut$cut_16yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2002, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_2001, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_2000, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1999, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1998, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1997, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1996, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1995, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1994, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1993, rsf.data.cut$cutblocks_1992))))))))))

rsf.data.cut$cut_17yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2001, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_2000, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1999, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1998, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1997, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1996, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1995, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1994, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1993, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1992, rsf.data.cut$cutblocks_1991))))))))))

rsf.data.cut$cut_18yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_2000, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1999, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1998, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1997, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1996, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1995, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1994, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1993, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1992, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1991, rsf.data.cut$cutblocks_1990))))))))))

rsf.data.cut$cut_19yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1999, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1998, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1997, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1996, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1995, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1994, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1993, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1992, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1991, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1990, rsf.data.cut$cutblocks_1989))))))))))

rsf.data.cut$cut_20yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1998, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1997, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1996, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1995, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1994, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1993, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1992, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1991, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1990, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1989, rsf.data.cut$cutblocks_1988))))))))))

rsf.data.cut$cut_21yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1997, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1996, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1995, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1994, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1993, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1992, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1991, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1990, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1989, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1988, rsf.data.cut$cutblocks_1987))))))))))

rsf.data.cut$cut_22yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1996, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1995, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1994, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1993, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1992, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1991, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1990, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1989, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1988, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1987, rsf.data.cut$cutblocks_1986))))))))))

rsf.data.cut$cut_23yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1995, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1994, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1993, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1992, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1991, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1990, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1989, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1988, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1987, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1986, rsf.data.cut$cutblocks_1985))))))))))

rsf.data.cut$cut_24yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1994, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1993, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1992, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1991, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1990, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1989, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1988, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1987, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1986, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1985, rsf.data.cut$cutblocks_1984))))))))))

rsf.data.cut$cut_25yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1993, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1992, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1991, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1990, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1989, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1988, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1987, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1986, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1985, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1984, rsf.data.cut$cutblocks_1983))))))))))

rsf.data.cut$cut_26yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1992, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1991, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1990, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1989, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1988, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1987, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1986, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1985, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1984, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1983, rsf.data.cut$cutblocks_1982))))))))))

rsf.data.cut$cut_27yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1991, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1990, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1989, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1988, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1987, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1986, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1985, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1984, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1983, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1982, rsf.data.cut$cutblocks_1981))))))))))

rsf.data.cut$cut_28yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1990, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1989, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1988, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1987, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1986, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1985, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1984, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1983, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1982, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1981, rsf.data.cut$cutblocks_1980))))))))))

rsf.data.cut$cut_29yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1989, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1988, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1987, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1986, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1985, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1984, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1983, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1982, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1981, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1980, rsf.data.cut$cutblocks_1979))))))))))

rsf.data.cut$cut_30yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1988, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1987, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1986, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1985, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1984, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1983, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1982, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1981, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1980, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1979, rsf.data.cut$cutblocks_1978))))))))))

rsf.data.cut$cut_31yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1987, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1986, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1985, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1984, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1983, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1982, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1981, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1980, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1979, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1978, rsf.data.cut$cutblocks_1977))))))))))

rsf.data.cut$cut_32yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1986, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1985, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1984, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1983, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1982, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1981, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1980, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1979, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1978, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1977, rsf.data.cut$cutblocks_1976))))))))))

rsf.data.cut$cut_33yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1985, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1984, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1983, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1982, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1981, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1980, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1979, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1978, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1977, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1976, rsf.data.cut$cutblocks_1975))))))))))

rsf.data.cut$cut_34yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1984, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1983, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1982, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1981, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1980, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1979, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1978, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1977, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1976, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1975, rsf.data.cut$cutblocks_1974))))))))))

rsf.data.cut$cut_35yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1983, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1982, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1981, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1980, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1979, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1978, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1977, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1976, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1975, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1974, rsf.data.cut$cutblocks_1973))))))))))

rsf.data.cut$cut_36yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1982, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1981, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1980, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1979, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1978, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1977, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1976, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1975, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1974, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1973, rsf.data.cut$cutblocks_1972))))))))))

rsf.data.cut$cut_37yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1981, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1980, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1979, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1978, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1977, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1976, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1975, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1974, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1973, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1972, rsf.data.cut$cutblocks_1971))))))))))

rsf.data.cut$cut_38yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1980, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1979, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1978, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1977, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1976, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1975, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1974, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1973, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1972, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1971, rsf.data.cut$cutblocks_1970))))))))))

rsf.data.cut$cut_39yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1979, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1978, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1977, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1976, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1975, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1974, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1973, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1972, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1971, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1970, rsf.data.cut$cutblocks_1969))))))))))

rsf.data.cut$cut_40yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1978, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1977, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1976, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1975, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1974, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1973, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1972, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1971, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1970, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1969, rsf.data.cut$cutblocks_1968))))))))))

rsf.data.cut$cut_41yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1977, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1976, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1975, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1974, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1973, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1972, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1971, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1970, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1969, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1968, rsf.data.cut$cutblocks_1967))))))))))

rsf.data.cut$cut_42yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1976, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1975, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1974, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1973, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1972, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1971, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1970, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1969, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1968, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1967, rsf.data.cut$cutblocks_1966))))))))))

rsf.data.cut$cut_43yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1975, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1974, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1973, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1972, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1971, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1970, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1969, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1968, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1967, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1966, rsf.data.cut$cutblocks_1965))))))))))

rsf.data.cut$cut_44yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1974, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1973, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1972, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1971, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1970, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1969, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1968, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1967, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1966, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1965, rsf.data.cut$cutblocks_1964))))))))))

rsf.data.cut$cut_45yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1973, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1972, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1971, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1970, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1969, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1968, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1967, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1966, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1965, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1964, rsf.data.cut$cutblocks_1963))))))))))

rsf.data.cut$cut_46yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1972, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1971, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1970, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1969, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1968, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1967, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1966, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1965, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1964, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1963, rsf.data.cut$cutblocks_1962))))))))))

rsf.data.cut$cut_47yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1971, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1970, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1969, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1968, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1967, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1966, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1965, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1964, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1963, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1962, rsf.data.cut$cutblocks_1961))))))))))

rsf.data.cut$cut_48yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1970, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1969, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1968, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1967, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1966, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1965, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1964, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1963, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1962, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1961, rsf.data.cut$cutblocks_1960))))))))))

rsf.data.cut$cut_49yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1969, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1968, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1967, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1966, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1965, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1964, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1963, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1962, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1961, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1960, rsf.data.cut$cutblocks_1959))))))))))

rsf.data.cut$cut_50yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1968, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1967, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1966, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1965, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1964, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1963, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1962, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1961, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1960, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1959, rsf.data.cut$cutblocks_1958))))))))))

rsf.data.cut$cut_pre50yo <- ifelse (rsf.data.cut$year == 2018, rsf.data.cut$cutblocks_1967, ifelse (rsf.data.cut$year == 2017, rsf.data.cut$cutblocks_1966, ifelse (rsf.data.cut$year == 2016, rsf.data.cut$cutblocks_1965, ifelse (rsf.data.cut$year == 2015, rsf.data.cut$cutblocks_1964, ifelse (rsf.data.cut$year == 2014, rsf.data.cut$cutblocks_1963, ifelse (rsf.data.cut$year == 2013, rsf.data.cut$cutblocks_1962, ifelse (rsf.data.cut$year == 2012, rsf.data.cut$cutblocks_1961, ifelse (rsf.data.cut$year == 2011, rsf.data.cut$cutblocks_1960, ifelse (rsf.data.cut$year == 2010, rsf.data.cut$cutblocks_1959, ifelse (rsf.data.cut$year == 2009, rsf.data.cut$cutblocks_1958, rsf.data.cut$cutblocks_pre1957))))))))))

rsf.data.cut.age <- rsf.data.cut [, c (1:9, 133:234)]

write.table (rsf.data.cut.age, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_cutblock_age.csv", sep = ",")


```


now we need to filter out soem covaraiets in the interest of identifying parsimonius model.do this by bulding 'sub-models' by them

Sub-divided data into similar themes:
  - terrain (elevation, aspect, slope)
- forestry cutblock (distacne to cutblock across multipel years)
- human footprint (non-cutblock)
- beetle
- fire
- climate
- vegetation



```{r, back-up to Kyle's postgres db, warning = F, include = F, message = F}

connKyle <- dbConnect(drv = RPostgreSQL::PostgreSQL(), 
                      host = key_get('dbhost', keyring = 'postgreSQL'),
                      user = key_get('dbuser', keyring = 'postgreSQL'),
                      dbname = key_get('dbname', keyring = 'postgreSQL'),
                      password = key_get('dbpass', keyring = 'postgreSQL'),
                      port = "5432")
st_write (obj = rsf.locations, 
          dsn = connKyle, 
          layer = c ("public", "rsf_locations_caribou_bc"))
st_write (obj = locs.caribou, 
          dsn = connKyle, 
          layer = c ("public", "telemetry_caribou_bc_final"))
st_write (obj = id.points.out.all.sf, 
          dsn = connKyle, 
          layer = c ("public", "available_locations_caribou_bc"))
dbDisconnect (connKyle) 
```










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