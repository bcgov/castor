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
require (dplyr)
require (RPostgreSQL)
require (rpostgis)

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
table(ignit$FIRE_YEAR) # yipee Looking at https://www2.gov.bc.ca/gov/content/safety/wildfire-status/about-bcws/wildfire-statistics/wildfire-averages and comparing the values I get to these looks correct with all years present after 2001. 
table(ignit$FIRE_YEAR, ignit$FIRE_CAUSE) 
ignit$ig_mnth<-stringi::stri_sub(ignit$IGNITION_DATE,6,7)


ignition <- ignit %>%
  mutate(FIRE_CAUSE2 = na_if(FIRE_CAUSE, "Unknown")) 
table(ignition$FIRE_YEAR, ignition$FIRE_CAUSE2)



ignition2 <- st_transform (ignit, 3005)


#st_write(ignition2, overwrite = TRUE,  dsn="C:\\Work\\caribou\\clus\\R\\fire_sim\\data\\bc_fire_ignition.shp", delete_dsn = TRUE)

## Load ignition data into postgres (either my local one or Kyles)
#host=keyring::key_get('dbhost', keyring = 'postgreSQL')
#user=keyring::key_get('dbuser', keyring = 'postgreSQL')
#dbname=keyring::key_get('dbname', keyring = 'postgreSQL')
#password=keyring::key_get('dbpass', keyring = 'postgreSQL')

##Below needs: (1) update to relevant credentials and (2) then enter into the OSGeo4W command line and hit enter. 
#ogr2ogr -f PostgreSQL PG:"host=localhost user=postgres dbname=postgres password=postgres port=5432" C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_ignition_hist\\bc_fire_ignition.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI

# I wrote this to both places KylesClus and my local postgres
# https://gdal.org/programs/ogr2ogr.html

