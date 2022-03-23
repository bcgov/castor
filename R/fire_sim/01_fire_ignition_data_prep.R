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
#  Script Name: 01_fire_ignition_data_prep.R
#  Script Version: 1.0
#  Script Purpose: This script combines historic fire ignition point locations (https://catalogue.data.gov.bc.ca/dataset/fire-incident-locations-historical) with current fire ignition point locations (https://catalogue.data.gov.bc.ca/dataset/fire-locations-current). It also removes unneccessary data such as locations where ignitions were observed before 2002, ignition locations where smoke was observed but no fire was seen and fires for which the cause is unknown. 
#  Script Author: Elizabeth Kleynhans, Ecological Modeling Specialist, Forest Analysis and Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#  Script Contributor: Cora Skaien, Ecological Modeling Specialist, Forest Analysis and Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#=================================

##Overview
# In this section (01), we select the available data for fires in BC from 2002 and 2020 (2002-2019 historic; 2020 current),
 # combine data into one, and upload these files to the clus database.

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
library(keyring)

source(here::here("R/functions/R_Postgres.R"))

#Below is currently on the D-drive of my computer. Will need to be in clusdb eventually.
historic.ignit <- st_read ( dsn = "D:\\Fire\\fire_data\\raw_data\\Historical_Fire_Ignition_point_locations\\PROT_HISTORICAL_INCIDENTS_SP\\H_FIRE_PNT_point.shp", stringsAsFactors = T)

current.ignit <- st_read ( dsn = "D:\\Fire\\fire_data\\raw_data\\Current_Fire_Ignition_point_locations\\PROT_CURRENT_FIRE_PNTS_SP\\C_FIRE_PNT_point.shp", stringsAsFactors = T)

head(historic.ignit)
head(current.ignit)

historic.ignit <- st_transform (historic.ignit, 3005)
current.ignit <- st_transform (current.ignit, 3005)

historic.ignit<- historic.ignit %>% 
  dplyr::select(FIRE_NO, FIRE_YEAR, IGN_DATE, FIRE_CAUSE, FIRE_ID, FIRE_TYPE, LATITUDE, LONGITUDE, SIZE_HA, geometry)

current.ignit<- current.ignit %>% 
  dplyr::select(FIRE_NO, FIRE_YEAR, IGN_DATE, FIRE_CAUSE, FIRE_ID, FIRE_TYPE, LATITUDE, LONGITUDE, SIZE_HA, geometry)

ignition<- rbind(historic.ignit, current.ignit)

ignition1 <- ignition %>% 
  filter(FIRE_YEAR>2001) %>% ##Select for years 2002 beyond
  filter(FIRE_TYPE == "Fire" | FIRE_TYPE=="Nuisance Fire") #Select fire type for ones desired
table(ignition1$FIRE_YEAR) # Looking at https://www2.gov.bc.ca/gov/content/safety/wildfire-status/about-bcws/wildfire-statistics/wildfire-averages and comparing the values I get to these in the table I think I should filter only by "Fire" and not "Nuisance Fire" but this removes many fire locations particularly for the years 2007 and 2008. 

st_crs(ignition1)

st_write(ignition1, overwrite = TRUE,  dsn="C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_ignition_hist\\bc_fire_ignition.shp", delete_dsn = TRUE)
table(ignition1$FIRE_YEAR) 




## Load ignition data into postgres (either my local one or Kyles)
#host=keyring::key_get('dbhost', keyring = 'postgreSQL')
#user=keyring::key_get('dbuser', keyring = 'postgreSQL')
#dbname=keyring::key_get('dbname', keyring = 'postgreSQL')
#password=keyring::key_get('dbpass', keyring = 'postgreSQL')

##Below needs: (1) update to relevant credentials and (2) then enter into the OSGeo4W command line and hit enter. 
#ogr2ogr -f PostgreSQL PG:"host=localhost user=postgres dbname=postgres password=postgres port=5432" C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_ignition_hist\\bc_fire_ignition.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI

# I wrote this to both places KylesClus and my local postgres
# https://gdal.org/programs/ogr2ogr.html

