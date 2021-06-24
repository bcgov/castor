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
#  Script Name: 03_vri_data_prep.R
#  Script Version: 1.0
#  Script Purpose: This script creates a table of 1ha x 1ha pixels with vegetation data taken from the VRI for each year for each location.  These locations line up with the locations that I collected climate data from. 
#  Script Author: Elizabeth Kleynhans, Ecological Modeling Specialist, Forest Analysis and Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#  Script Contributor: Cora Skaien, Ecological Modeling Specialist, Forest Analysis and Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#=================================

#Overview:
   # in this file, we acquire the VRI (Vegetation Resources Inventory) for each year by location from 2002 to 2020. This is likely already uploaded onto a network and may not need to be redone.
   # The final product will be a file with veg data along with ignition data and climate data (vegetation, climate and presence/absence of fire data).


#### VEGETATION DATA #### 
#2002 to 2019 are the only years that VRI data exists, there is no earlier data.

##This first section has been competed on this computer.
#from https://catalogue.data.gov.bc.ca/dataset/vri-historical-vegetation-resource-inventory-2002-2019-
# I then extracted this data and uploaded it into my local postgres database by running the command below in terminal. If running it in the R terminal does not work try run it in here: 
#C:\data\localApps\QGIS10.16\OSGeo4W (the terminal window)

## You may get a warning indicating that this will take a long time, or that databses are not supported. You should specify a specific item within the database.
#ogr2ogr -f "PostgreSQL" PG:"host=localhost user=postgres dbname=postgres password=postgres port=5432" C:\\Work\\caribou\\clus_data\\Fire\\VEG_COMP_POLY_AND_LAYER_2020.gdb -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI
#Above is run or each year 2002 to 2020 separately from the data

# rename the table in postgres if need be
#ALTER TABLE veg_comp_lyr_r1_poly RENAME TO veg_comp_lyr_r1_poly2017

# When the table name is changed the idx name is not so you might have to change that too so that more files can be uploaded into postgres by running the following command
#ALTER INDEX veg_comp_lyr_r1_poly_shape_geom_idx RENAME TO veg_comp_lyr_r1_poly2019_geometry_geom_idx;
# and if need be change the name of the geometry column from shape to geometry
#ALTER TABLE veg_comp_lyr_r1_poly2019 RENAME COLUMN shape TO geometry;

#### Join ignition data to VRI data ####
# Run following query in postgres for all years except 2007 and 2008. This will need to be done each time new data is generated for random points in file 02. This below code is fast
# CREATE TABLE fire_veg_2002 AS
# (SELECT feature_id, bclcs_level_2, bclcs_level_3, bclcs_level_4, bclcs_level_5,
#  harvest_date, proj_age_1, proj_ht_1, live_stand_volume_125,
#  fire.idno, fire.fire_yr, fire.fire_cs, fire.fir_typ, fire.size_ha, fire.fire,
#  fire.zone, fire.subzone, fire.ntrl_ds, fire.tmax05, fire.tmax06, fire.tmax07,
#  fire.tmax08, fire.tmax09, fire.tave05, fire.tave06, fire.tave07, fire.tave08,
#  fire.tave09, fire.ppt05, fire.ppt06, fire.ppt07, fire.ppt08, fire.ppt09,
#  fire.mdc_05, fire.mdc_06, fire.mdc_07, fire.mdc_08, fire.mdc_09,
#  veg_comp_lyr_r1_poly2002.geometry FROM veg_comp_lyr_r1_poly2002,
#  (SELECT wkb_geometry, idno, fire_yr, fire_cs, fir_typ, size_ha, fire, zone,
#   subzone, ntrl_ds, tmax05, tmax06, tmax07, tmax08, tmax09, tave05, tave06, tave07,
#   tave08, tave09, ppt05, ppt06, ppt07, ppt08, ppt09, mdc_05, mdc_06, mdc_07, mdc_08,
#   mdc_09 from dc_data where fire_yr = '2002') as fire where st_contains
#  (veg_comp_lyr_r1_poly2002.geometry, fire.wkb_geometry))


## See specifics of land cover types here: https://www2.gov.bc.ca/assets/gov/environment/natural-resource-stewardship/nr-laws-policy/risc/landcover-02.pdf
### bclcs_level_2: The second level of the BC land cover classification scheme classifies the polygon as to the land cover type:
   # treed or non-treed for vegetated polygons; land or water for non-vegetated polygons.
### bclcs_level_3: The location of the polygon relative to elevation and drainage, and is described as either alpine, wetland
   # or upland. In rare cases, the polygon may be alpine wetland.
### bclcs_level_4: Classifies the vegetation types and non-vegetated cover types (as described by the presence of distinct features
    # upon the land base within the polygon).
### bclcs_level_5: Classifies the vegetation density classes and Non-Vegetated categories.

###################
##FOR 2007 run this because some of the names for the VRI_2007 file are different to what they are in other years. In particular:
###################

# bclcs_level_2 = bclcs_lv_2 same for the other bclcs layers
#proj_height_1 = proj_ht_1
#harvest_date = upd_htdate
# live_stand_volume_125 does not exist

# CREATE TABLE fire_veg_2007 AS
# (SELECT feature_id, bclcs_lv_2, bclcs_lv_3, bclcs_lv_4, bclcs_lv_5,
#  upd_htdate, proj_age_1, proj_ht_1, COALESCE(volsp1_125,0)+COALESCE(volsp2_125,0)+COALESCE(volsp3_125,0)+COALESCE(volsp4_125,0)+COALESCE(volsp5_125,0) AS live_stand_volume_125,
#  fire.idno, fire.fire_yr, fire.fire_cs, fire.fir_typ, fire.size_ha, fire.fire,
#  fire.zone, fire.subzone, fire.ntrl_ds, fire.tmax05, fire.tmax06, fire.tmax07,
#  fire.tmax08, fire.tmax09, fire.tave05, fire.tave06, fire.tave07, fire.tave08,
#  fire.tave09, fire.ppt05, fire.ppt06, fire.ppt07, fire.ppt08, fire.ppt09,
#  fire.mdc_05, fire.mdc_06, fire.mdc_07, fire.mdc_08, fire.mdc_09,
#  veg_comp_lyr_r1_poly2007.geometry FROM veg_comp_lyr_r1_poly2007,
#  (SELECT wkb_geometry, idno, fire_yr, fire_cs, fir_typ, size_ha, fire, zone,
#   subzone, ntrl_ds, tmax05, tmax06, tmax07, tmax08, tmax09, tave05, tave06, tave07,
#   tave08, tave09, ppt05, ppt06, ppt07, ppt08, ppt09, mdc_05, mdc_06, mdc_07, mdc_08,
#   mdc_09 from dc_data where fire_yr = '2007') as fire where st_contains
#  (veg_comp_lyr_r1_poly2007.geometry, fire.wkb_geometry))

##############################
# FOR 2008 Run this code:
##############################
# CREATE TABLE fire_veg_2008 AS
# (SELECT feature_id, bclcs_level_2, bclcs_level_3, bclcs_level_4, bclcs_level_5,
#   harvest_date, proj_age_1, proj_height_1, COALESCE(vol_per_ha_spp1_125,0)+
#     COALESCE(vol_per_ha_spp2_125,0)+COALESCE(vol_per_ha_spp3_125,0)+COALESCE(vol_per_ha_spp4_125,0)
#   +COALESCE(vol_per_ha_spp5_125,0)+COALESCE(vol_per_ha_spp6_125,0) AS live_stand_volume_125,
#   fire.idno, fire.fire_yr, fire.fire_cs, fire.fir_typ, fire.size_ha, fire.fire,
#   fire.zone, fire.subzone, fire.ntrl_ds, fire.tmax05, fire.tmax06, fire.tmax07,
#   fire.tmax08, fire.tmax09, fire.tave05, fire.tave06, fire.tave07, fire.tave08,
#   fire.tave09, fire.ppt05, fire.ppt06, fire.ppt07, fire.ppt08, fire.ppt09,
#   fire.mdc_05, fire.mdc_06, fire.mdc_07, fire.mdc_08, fire.mdc_09,
#   veg_comp_lyr_r1_poly2008.geometry FROM veg_comp_lyr_r1_poly2008,
#   (SELECT wkb_geometry, idno, fire_yr, fire_cs, fir_typ, size_ha, fire, zone,
#    subzone, ntrl_ds, tmax05, tmax06, tmax07, tmax08, tmax09, tave05, tave06, tave07,
#    tave08, tave09, ppt05, ppt06, ppt07, ppt08, ppt09, mdc_05, mdc_06, mdc_07, mdc_08,
#    mdc_09 from dc_data where fire_yr = '2008') as fire where st_contains
#   (veg_comp_lyr_r1_poly2008.geometry, fire.wkb_geometry))

# note that the VRI for 2008 does not have live_stand_volume so I also tried to extract it from the 2009 VRI and put it in here -  assuming that a year would not make much difference to volume. Below is the code i used to try and do this (but note this does not seem to work.... )

#ALTER TABLE fire_veg_2008
#ADD COLUMN live_stand_volume_125 double precision;

# INSERT INTO fire_veg_2008
# SELECT live_stand_volume_125
# FROM veg_comp_lyr_r1_poly2009,
# (SELECT wkb_geometry from dc_data where fire_yr = '2008') as fire where st_contains
# (veg_comp_lyr_r1_poly2009.geometry, fire.wkb_geometry)


# Another problem is that fire_veg_2011 has a geometry column that is type MultiPolygonZ instead of MultiPolygon so this needs to be changed with the following query in postgres
# ALTER TABLE fire_veg_2011  
# ALTER COLUMN geometry TYPE geometry(MULTIPOLYGON, 3005) 
# USING ST_Force_2D(geometry);

library(dplyr)
library(keyring)
library(sf)

source(here::here("R/functions/R_Postgres.R"))

#Import all fire_veg
conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")
fire_veg_2002 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2002")
fire_veg_2003 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2003")
fire_veg_2004 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2004")
fire_veg_2005 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2005")
fire_veg_2006 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2006")
fire_veg_2007 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2007")
fire_veg_2008 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2008")
fire_veg_2009 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2009")
fire_veg_2010 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2010")
fire_veg_2011 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2011")
fire_veg_2012 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2012")
fire_veg_2013 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2013")
fire_veg_2014 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2014")
fire_veg_2015 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2015")
fire_veg_2016 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2016")
fire_veg_2017 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2017")
fire_veg_2018 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2018")
fire_veg_2019 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2019")
fire_veg_2020 <- sf::st_read  (dsn = conn, # connKyle
                               query = "SELECT * FROM public.fire_veg_2020")


dbDisconnect (conn) # connKyle

# REMEMBER TO CHANGE THE 0 values in the 2007 and 2008 fire_veg datasets for volume to NULL.

# the VRI for 2007 had harvest_date named upd_htdate and proj_height_1, proj_height_2 as proj_ht_1, proj_ht_2. So I need to be renamed these columns
#fire_veg_2007$harvest_date <- NA
names(fire_veg_2007)
fire_veg_2007<- fire_veg_2007 %>% rename(
  bclcs_level_2=bclcs_lv_2,
  bclcs_level_3=bclcs_lv_3,
  bclcs_level_4=bclcs_lv_4,
  bclcs_level_5=bclcs_lv_5,
  proj_height_1=proj_ht_1, 
  harvest_date=upd_htdate)

# change the 0 values in live_stand_volume_125 to NULL for both 2007 and 2008 data

fire_veg_2007$live_stand_volume_125[fire_veg_2007$live_stand_volume_125 == 0] <- NA
fire_veg_2008$live_stand_volume_125[fire_veg_2008$live_stand_volume_125 == 0] <- NA

fire_veg_2020$proj_height_1<-NA
fire_veg_2020$proj_age_1<-NA
fire_veg_2020$live_stand_volume_125<-NA

###################################
#### Check that my solution to calculating volume for 2007 and 2008 is legitimate. Ill do this by comparing the sum of vol_per_ha_spp1_125 + vol_per_ha_spp2_125 + vol_per_ha_spp3_125 + vol_per_ha_spp4_125 + vol_per_ha_spp5_125 + vol_per_ha_spp6_125 is similar to the values in the column live_stand_volume_125
###################################

#Must create test file for below to work (fire_veg_2009_test does not yet exist)

names(fire_veg_2009_test)
plot(fire_veg_2009_test$live_stand_volume_125, fire_veg_2009_test$live_stand_volume_125_try)
names(fire_veg_2010_test)
plot(fire_veg_2010_test$live_stand_volume_125, fire_veg_2010_test$live_stand_volume_125_try)

# Excellent! Looks like a perfect correlation! YIPEEE



# join all fire_veg datasets together. This function is faster than a list of rbinds
filenames3<- c("fire_veg_2002", "fire_veg_2003", "fire_veg_2004","fire_veg_2005", "fire_veg_2006", "fire_veg_2007","fire_veg_2008", "fire_veg_2009", "fire_veg_2010","fire_veg_2011", "fire_veg_2012", "fire_veg_2013","fire_veg_2014", "fire_veg_2015", "fire_veg_2016","fire_veg_2017", "fire_veg_2018", "fire_veg_2019", "fire_veg_2020")
filenames3

mkFrameList <- function(nfiles) {
  d <- lapply(seq_len(nfiles),function(i) {
    eval(parse(text=filenames3[i])) # for new files lists change the name at filenames2
  })
  do.call(rbind,d)
}

n<-length(filenames3)
fire_veg_data<-mkFrameList(n)

table(fire_veg_data$fire_yr, fire_veg_data$fire_cs)
# hmmmm, a few fire ignition locations seem to have been thrown out when I joined the VRI data to the climate and fire ignition data. WHY?
# e.g. numbers to check 2002 -> 876 lightning strikes
#                       2007 -> 22 (all others were indicated as human caused)
#                       2008 -> 29 (all others were indicated as human caused)



##Check what data points are missing
#As of June 24, there should be 228-230 missing points (230 missing, but 2 gained somehow)



write.csv(fire_veg_data, file="D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\fire_ignitions_veg_climate.csv")

# write final fire ignitions, weather and vegetation types to postgres
# save data 
connKyle <- dbConnect(drv = RPostgreSQL::PostgreSQL(), 
                      host = key_get('dbhost', keyring = 'postgreSQL'),
                      user = key_get('dbuser', keyring = 'postgreSQL'),
                      dbname = key_get('dbname', keyring = 'postgreSQL'),
                      password = key_get('dbpass', keyring = 'postgreSQL'),
                      port = "5432")
st_write (obj = fire_veg_data, 
          dsn = connKyle, 
          layer = c ("public", "fire_ignitions_veg_climate"))
dbDisconnect (connKyle)


############## Now move on to file 04_ignition_climate_variable_selection#############