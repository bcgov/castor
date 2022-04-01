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
# In this section (01), we select the available data for fires in BC from 2002 and 2020 and upload these files to the clus database.

library(bcdata)

library(raster)
library(data.table)
library(sf)
library(tidyverse)
library(rgeos)
require (RPostgreSQL)
require (rpostgis)
require (fasterize)
require (dplyr)
library(keyring)

source(here::here("R/functions/R_Postgres.R"))

# Raw fire ignition point data from BCDC:
# https://cat.data.gov.bc.ca/dataset/fire-perimeters-historical/resource/61de892c-09f4-4440-b18f-09995801558f


# get latest data off BCGW
ignit<-try(
  bcdc_query_geodata("WHSE_LAND_AND_NATURAL_RESOURCE.PROT_HISTORICAL_INCIDENTS_SP") %>%
    filter(FIRE_YEAR > 2001) %>%
    filter(FIRE_TYPE == "Fire") %>%
    collect()
)


head(ignit)
ignit$FIRE_NUMBER<-as.factor(ignit$FIRE_NUMBER)
table(ignit$FIRE_YEAR) # yipee Looking at https://www2.gov.bc.ca/gov/content/safety/wildfire-status/about-bcws/wildfire-statistics/wildfire-averages and comparing the values I get to these looks correct with all years present after 2001. 
table(ignit$FIRE_YEAR, ignit$FIRE_CAUSE) #But notice that there is lots of fire cause data missing. Which is a problem. I've had discussions with the curator on BCGW about this and they think that im loosing this data when I filter. I cant work out how this is happening though. Anyway, because I need these records Im joining this table back to the data we downloaded in 2021. 

ignit2<-frt <- st_read ( dsn = "D:\\Fire\\fire_data\\raw_data\\Historical_Fire_Ignition_point_locations\\PROT_HISTORICAL_INCIDENTS_SP\\H_FIRE_PNT_point.shp", stringsAsFactors = T)
head(ignit2)
ignit2$FIRE_NO<-as.factor(ignit2$FIRE_NO)

ignit2<- ignit2 %>%
  filter(FIRE_YEAR>2001) %>%
  filter(FIRE_TYPE == "Fire") %>%
  select(FIRE_NO, FIRE_YEAR, FIRE_CAUSE) %>%
  rename(FIRE_CAUSE2=FIRE_CAUSE,
         FIRE_NUMBER=FIRE_NO) 

table(ignit2$FIRE_YEAR, ignit2$FIRE_CAUSE)
  
ignit2$FIRE_YEAR2<-ignit2$FIRE_YEAR
ignit2<-as.data.frame(ignit2)
ignit2<-ignit2[,c(1:3,5)]


ignition<-ignit %>% left_join(ignit2)
ignition %>% select(FIRE_YEAR,FIRE_YEAR2, FIRE_NUMBER, FIRE_CAUSE,FIRE_CAUSE2) %>% print(n=100)

# now that the two dataframes are linked Im going to change all the Unknown values in FIRE_CAUSE colum to NA. Then Im going to use the coalesce function to match the columns FIRE_CAUSE and FIRE_CAUSE to pull out any inform to so that I get as much data about fire cause as possible and then change the NA values back to Unknown.

ignition2 <- ignition %>%
  mutate(FIRE_CAUSE = na_if(FIRE_CAUSE, "Unknown")) %>%
  mutate(FIRE_CAUSE3 = coalesce(FIRE_CAUSE, FIRE_CAUSE2)) %>%
  mutate(FIRE_CAUSE3 = coalesce (FIRE_CAUSE3,"Unknown"))
table(ignition2$FIRE_YEAR, ignition2$FIRE_CAUSE3)

# This is better. Im still missing quite a few fire locations with data especially for the years 2007 - 2009. But with out bugging Devona again this is the best I can do for now.

ignition2 <- st_transform (ignit, 3005)


st_write(ignition2, overwrite = TRUE,  dsn="C:\\Work\\caribou\\clus\\R\\fire_sim\\data\\bc_fire_ignition.shp", delete_dsn = TRUE)

## Load ignition data into postgres (either my local one or Kyles)
#host=keyring::key_get('dbhost', keyring = 'postgreSQL')
#user=keyring::key_get('dbuser', keyring = 'postgreSQL')
#dbname=keyring::key_get('dbname', keyring = 'postgreSQL')
#password=keyring::key_get('dbpass', keyring = 'postgreSQL')

##Below needs: (1) update to relevant credentials and (2) then enter into the OSGeo4W command line and hit enter. 
#ogr2ogr -f PostgreSQL PG:"host=localhost user=postgres dbname=postgres password=postgres port=5432" C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_ignition_hist\\bc_fire_ignition.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI

# I wrote this to both places KylesClus and my local postgres
# https://gdal.org/programs/ogr2ogr.html

