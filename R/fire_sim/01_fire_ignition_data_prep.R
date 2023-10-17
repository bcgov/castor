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
# In this section (01), we select the available data for fires in BC from 2002 and 2020. Then we pull in the BEC data, Natural disturbance type and fire regime type and combine this data with the ignition data. 

library(bcdata)
require (dplyr)
require (RPostgreSQL)
require (rpostgis)
library(ggplot2)

library(keyring)

source(here::here("R/functions/R_Postgres.R"))

# Raw fire ignition point data from BCDC:
# https://cat.data.gov.bc.ca/dataset/fire-perimeters-historical/resource/61de892c-09f4-4440-b18f-09995801558f


# get latest data off BCGW
ignit<-try(
  bcdc_query_geodata("WHSE_LAND_AND_NATURAL_RESOURCE.PROT_HISTORICAL_INCIDENTS_SP") %>%
    filter(FIRE_YEAR > 2000) %>%
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

###
#Get natural disturbance data
# Collect the BEC and NDT zones from the BCGW or from postgres

#postgres (faster)
NDT<-getSpatialQuery("SELECT objectid, feature_class_skey, zone, subzone, natural_disturbance, zone_name, wkb_geometry FROM public.bec_zone")

#OR BCGW (slower)
# try(bcdc_describe_feature("WHSE_FOREST_VEGETATION.BEC_BIOGEOCLIMATIC_POLY"))
# 
# NDT<-try(
#   bcdc_query_geodata("WHSE_FOREST_VEGETATION.BEC_BIOGEOCLIMATIC_POLY") %>%
#     select(ZONE, ZONE_NAME, NATURAL_DISTURBANCE, NATURAL_DISTURBANCE_NAME, GEOMETRY, OBJECTID) %>% # keeping data from 2002 on because this is when the VRI data is available
#     collect()
# )
# 
# st_crs(NDT)
# NDT<-st_transform(NDT, 3005)


# An alternative to natural disturbance types is to use the fire regime units or zone outlined in Erni et al. 2020 Developing a two-level fire regime zonation system for Canada. I downloaded the shapefiles from https://zenodo.org/record/4458156#.YjTUVI_MJPY

frt <- st_read ( dsn = "D:\\Fire\\fire_data\\Fire_Regime_Types\\FRT\\FRT_Canada.shp", stringsAsFactors = T) # Read simple features from file or database, or retrieve layer names and their geometry type(s)
st_crs(frt) #Retrieve coordinate reference system from sf or sfc object
frt<-st_transform(frt, 3005) #transform coordinate system to 3005 - that for BC, Canada
# plot it
ggplot(data=frt) +
  geom_sf() +
  coord_sf()

#get provincial boundary for clipping the layers to the area of interest
prov.bnd <- st_read ( dsn = "T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CASTOR\\Data\\admin_boundaries\\province\\gpr_000b11a_e.shp", stringsAsFactors = T) # Read simple features from file or database, or retrieve layer names and their geometry type(s)
st_crs(prov.bnd) #Retrieve coordinate reference system from sf or sfc object
prov.bnd <- prov.bnd [prov.bnd$PRENAME == "British Columbia", ] 
crs(prov.bnd)# this one needs to be transformed to 3005
bc.bnd <- st_transform (prov.bnd, 3005) #Transform coordinate system
st_crs(bc.bnd)

# Clip NDT here
ndt_clipped<-st_intersection(bc.bnd, NDT)
#plot(st_geometry(ndt_clipped), col=sf.colors(10,categorical=TRUE))
ndt_sf<-st_as_sf(NDT)

#Clip FRT here
frt_clipped<-st_intersection(bc.bnd, frt)
#plot(st_geometry(frt_clipped), col=sf.colors(10,categorical=TRUE))
length(unique(frt_clipped$Cluster))
frt_sf<-st_as_sf(frt_clipped)

st_write(frt_sf, overwrite = TRUE,  dsn="C:\\Work\\caribou\\castor\\R\\fire_sim\\tmp\\frt_clipped.shp", delete_dsn = TRUE)

plot(frt_clipped)

ignit<-ignition2
crs(ignit)

##Check clipped data on QGis. Clipped data has no physical outliers
# note clipping the fire locations to the BC boundary removes a few ignition points in several of the years
fire.ignition.clipped<-ignit[bc.bnd,] # making sure all fire ignitions have coordinates within BC boundary
table(ignit$FIRE_YEAR)
table(fire.ignition.clipped$FIRE_YEAR) #We have lost a few but its not that many.

fire.ignition_sf<-st_as_sf(fire.ignition.clipped) #convert to sf object
st_crs(fire.ignition_sf)
table(fire.ignition_sf$FIRE_YEAR)


#doing st_intersection with the whole bec and fire ignition files is very very slow, but st_join is much faster! st_intersection should be used if you want to overlay two polygons and calculate something inside them e.g. road length. For points st_intersction and st_join are apparently the same but st_join seems to be much faster. 
# ST_Intersects is a function that takes two geometries and returns true if any part of those geometries is shared between the 2

fire.ignt.frt <- st_join(fire.ignition_sf, frt_sf)
fire.ignt.frt <- fire.ignt.frt %>% dplyr::select(id:ig_mnth, PRNAME, Cluster)
# fire.igni.frt.ndt<- st_join(fire.ignt.frt, ndt_sf)
# 
# table(fire.igni.frt.ndt$FIRE_YEAR, fire.igni.frt.ndt$Cluster)
# table(fire.igni.frt.ndt$FIRE_YEAR, fire.igni.frt.ndt$natural_disturbance, fire.igni.frt.ndt$Cluster )
# 
# table(fire.igni.frt.ndt$FIRE_YEAR, fire.igni.frt.ndt$Cluster, fire.igni.frt.ndt$FIRE_CAUSE)


#Write fire.igni.frt.ndt to file because it takes so long to make.


st_write(fire.ignt.frt, overwrite = TRUE,  dsn="C:\\Work\\caribou\\castor\\R\\fire_sim\\tmp\\bc_fire_ignition_clipped.shp", delete_dsn = TRUE)

# good fire is a point location



##Save via OsGeo4W Shell
##Below needs: (1) update to relevant credentials and (2) then enter into the OSGeo4W command line and hit enter. 
#ogr2ogr -f PostgreSQL PG:"host=localhost user=postgres dbname=postgres password=postgres port=5432" C:\\Work\\caribou\\castor\\R\\fire_sim\\tmp\\bc_fire_ignition_clipped.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI


# Below was not done 3 August 2022
## Load ignition data into postgres (either my local one or Kyles)
#host=keyring::key_get('dbhost', keyring = 'postgreSQL')
#user=keyring::key_get('dbuser', keyring = 'postgreSQL')
#dbname=keyring::key_get('dbname', keyring = 'postgreSQL')
#password=keyring::key_get('dbpass', keyring = 'postgreSQL')

##Below needs: (1) update to relevant credentials and (2) then enter into the OSGeo4W command line and hit enter. 
#ogr2ogr -f PostgreSQL PG:"host=localhost user=postgres dbname=postgres password=postgres port=5432" C:\\Work\\caribou\\castor_data\\Fire\\Fire_sim_data\\fire_ignition_hist\\bc_fire_ignition.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI

# https://gdal.org/programs/ogr2ogr.html

