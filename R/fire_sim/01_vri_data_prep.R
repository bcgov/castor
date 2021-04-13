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
#  Script Name: 01_vri_data_prep.R
#  Script Version: 1.0
#  Script Purpose: This script creates a table of 1ha x 1ha pixels with vegetation data taken from the VRI for each year for each location.  These locations line up with the locations that I collected climate data from. 
#  Script Author: Elizabeth Kleynhans, Ecological Modeling Specialist, Forest Analysis and Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#=================================


#### VEGETATION DATA #### 
#downloaded for years 2002 to 2019. These are the only years that VRI data exists, there is no earlier data.
#from https://catalogue.data.gov.bc.ca/dataset/vri-historical-vegetation-resource-inventory-2002-2018-
# I then extracted this data and uploaded it into my local postgres database by running the command below in terminal. 

#ogr2ogr -f "PostgreSQL" PG:"host=localhost user=postgres dbname=postgres password=postgres port=5432" C:\\Work\\caribou\\clus_data\\Fire\\VEG_COMP_LYR_R1_POLY.gdb -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI

# rename the table in postgres if need be
#ALTER TABLE veg_comp_lyr_r1_poly RENAME TO veg_comp_lyr_r1_poly2017

# When the table name is changed the idx name is not so you might have to change that too so that more files can be uploaded into postgres by running the following command
#ALTER INDEX veg_comp_lyr_r1_poly_shape_geom_idx RENAME TO veg_comp_lyr_r1_poly2019_geometry_geom_idx;
# and if need be change the name of the geometry column from shape to geometry
#ALTER TABLE veg_comp_lyr_r1_poly2019 RENAME COLUMN shape TO geometry;

#### Join ignition data to VRI data ####
# Run following query in postgres. This is fast
# CREATE TABLE fire_veg_2007 AS
# (SELECT feature_id, bclcs_level_2, bclcs_level_3, bclcs_level_4, bclcs_level_5,
#  harvest_date, proj_age_1, proj_age_2, proj_height_1, proj_height_2,
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


# One problem is that fire_veg_2011 has a geometry column that is type MultiPolygonZ instead of MultiPolygon so this needs to be changed with the following query in postgres
# ALTER TABLE fire_veg_2011  
# ALTER COLUMN geometry TYPE geometry(MULTIPOLYGON, 3005) 
# USING ST_Force_2D(geometry);

library(dplyr)

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

dbDisconnect (conn) # connKyle

# the VRI for 2007 had harvest_date named upd_htdate and proj_height_1, proj_height_2 as proj_ht_1, proj_ht_2. So I need to be renamed these columns
#fire_veg_2007$harvest_date <- NA
names(fire_veg_2007)
fire_veg_2007<- fire_veg_2007 %>% rename(proj_height_1=proj_ht_1, 
                                         proj_height_2=proj_ht_2, 
                                         harvest_date=upd_htdate)

# join all fire_veg datasets together. This function is faster than a list of rbinds
filenames3<- c("fire_veg_2002", "fire_veg_2003", "fire_veg_2004","fire_veg_2005", "fire_veg_2006", "fire_veg_2007","fire_veg_2008", "fire_veg_2009", "fire_veg_2010","fire_veg_2011", "fire_veg_2012", "fire_veg_2013","fire_veg_2014", "fire_veg_2015", "fire_veg_2016","fire_veg_2017", "fire_veg_2018", "fire_veg_2019")


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
#                       2007 -> 22
#                       2008 -> 29


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
