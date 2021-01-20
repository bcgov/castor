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
#downloaded for years 2002 to 2019. These are the only years that VRI data exists for there is no earlier data.
#from https://catalogue.data.gov.bc.ca/dataset/vri-historical-vegetation-resource-inventory-2002-2018-
# I then extracted this data and uploaded it into my local postgres database by running the command below in terminal. 

#ogr2ogr -f "PostgreSQL" PG:"host=localhost user=postgres dbname=postgres password=postgres port=5432" C:\\Work\\caribou\\clus_data\\Fire\\VRI_data\\veg_comp_lyr_r1_poly2003.gdb -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI

# rename the table in postgres if need be
#ALTER TABLE veg_comp_lyr_r1_poly RENAME TO veg_comp_lyr_r1_poly2017

# When the table name is changed the idx name is not so you might have to change that too so that more files can be uploaded into postgres by running the following command
#ALTER INDEX veg_comp_lyr_r1_poly_finalv4_geometry_geom_idx RENAME TO veg_comp_lyr_r1_poly2002_geometry_geom_idx

#### Join ignition data to VRI data ####
# Run following query in postgres. This is fast
#CREATE TABLE Fire_veg_2016 AS
#(SELECT feature_id, bclcs_level_2, bclcs_level_3, bclcs_level_4, bclcs_level_5, 
#  fire.fire_id, fire.fire_no, fire.fire_year, fire.fire_cause, fire.size_ha, veg_comp_lyr_r1_poly20# 16.geometry FROM veg_comp_lyr_r1_poly2016, (SELECT wkb_geometry, fire_id, fire_no, fire_year, fire_cause, size_ha  from bc_fire_ignition 
#  where fire_type = 'Fire' and fire_year = '2016') as fire 
#  where st_contains (veg_comp_lyr_r1_poly2016.geometry, fire.wkb_geometry));


# This also works but is super slow, dont run this one!
# CREATE TABLE Fire_veg_2002 AS (WITH ignit as 
#         (SELECT fire_no, fire_year, fire_cause, size_ha, wkb_geometry from bc_fire_ignition 
#         where fire_type = 'Fire' and fire_year = '2002'), 
#         veg as (SELECT bclcs_level_4, bclcs_level_5, geometry FROM veg_comp_lyr_r1_poly2002 where bclcs_level_2 = 'T') 
#         SELECT veg.geometry as geom, fire_no, fire_year, fire_cause, size_ha, bclcs_level_4, bclcs_level_5 
#         FROM ignit, veg WHERE st_intersects (ignit.wkb_geometry, veg.geometry));


#### Join ignition, VRI and climate data #### 





# Plot provincial boundary and lightning strikes. Looks good.
ggplot() +
  geom_sf(data=bc.bnd) +
  geom_sf(data=lightning_clipped)

st_write(lightning_clipped, dsn = "C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\lightning_strikes.shp", delete_layer=TRUE)

# commit the shape file to postgres
# this works for loading the shape file onto Kyles Postgres. Run these sections of code below in R and fill in the details in the script for command prompt. Then run the ogr2ogr script in command prompt to get the table into postgres

host=keyring::key_get('dbhost', keyring = 'postgreSQL')
user=keyring::key_get('dbuser', keyring = 'postgreSQL')
dbname=keyring::key_get('dbname', keyring = 'postgreSQL')
password=keyring::key_get('dbpass', keyring = 'postgreSQL')

# Run this in terminal
#ogr2ogr -f PostgreSQL PG:"host= user= dbname= password= port=5432" C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\lightning_strikes.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI






forest.tenure<-getSpatialQuery("SELECT * FROM tsa_aac_bounds")
forest.tenure <- st_transform (forest.tenure, 3005)
North<-forest.tenure %>% filter(tsa_name=="Fort_St_John_TSA"| tsa_name == "Fort_St_John_Core_TSA" | tsa_name == "Dawson_Creek_TSA" | tsa_name == "MacKenzie_TSA" | tsa_name == "TFL48" | tsa_name == "MacKenzie_SW_TSA")

lightning_clipped<-lighting.hist[North,]

ggplot() +
  #geom_sf(data=bc.bnd) +
  geom_sf(data=North) +
  geom_sf(data=lightning_clipped)

lightning_clipped$FIRE_MONTH<-substr(lightning_clipped$IGN_DATE,5,6)
lightning_clipped <- lightning_clipped[!is.na(lightning_clipped$FIRE_MONTH) ,]

# get vegetation layer
layer<-getSpatialQuery("SELECT object_id, geometry FROM public.veg_comp_lyr_r1_poly2018")
veg <- st_transform (layer, 3005)
veg.lightning<-st_intersection(lightning_clipped,veg)




forest.tenure.ras <-fasterize::fasterize(sf= forest.tenure, raster = ProvRast , field = "tsa_number")





for (j in 5 : 10) {
  
  x[[paste0("Em0",j)]]<- days_month[j]*((0.36*x[[paste0("Tmax0",j)]])+Lf[j])
  
  #dc_0 <- 15 # initial drought code value. Took this value from https://pacificclimate.org/sites/default/files/publications/evaluation_of_the_monthly_drought_code.pdf, who use it in their study and assumed it reset to 15 at the start of every May.
  dc_0<- if_else(j<6, 15, x[[paste0("MDC_0",j-1)]])
  print(dc_0)
  
  x[[paste0("DC_half_0",j)]]<- dc_0 + (0.25 * x[[paste0("Em0",j)]])
  x[[paste0("Qmr_0",j)]] <- (3.937 * 0.83 * (x[[paste0("PPT0",j)]] + x[[paste0("PAS0",j)]]/10))/(800 * exp(-dc_0/400))
  x[[paste0("DC_mr_0",j)]]<- x[[paste0("DC_half_0",j)]] - 400 * log(1+x[[paste0("Qmr_0",j)]])
  x[[paste0("MDC_m_0",j)]]<-x[[paste0("DC_mr_0",j)]] + (0.25 * x[[paste0("Em0",j)]])
  x[[paste0("MDC_0",j)]] <- (dc_0 + x[[paste0("MDC_m_0",j)]])/2
  
  
  
  