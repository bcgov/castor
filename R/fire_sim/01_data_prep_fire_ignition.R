library(raster)
library(data.table)
library(sf)
library(tidyverse)
library(rgeos)
library(bcmaps)
library(ggplot2)

source(here::here("R/functions/R_Postgres.R"))

# Layers needed:
# 1.) Fire ignition history, 2.) vegetation, 3.) Weather (monthly mean rainfall, monthly mean max temp, monthly average temp)

#bc<-bc_bound()

fire.ignit.hist<-sf::st_read(dsn="C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\BCGW_7113060B_1600358424324_13780\\PROT_HISTORICAL_INCIDENTS_SP\\H_FIRE_PNT_point.shp")
st_crs(fire.ignit.hist)
head(fire.ignit.hist)
#lighting.hist<-fire.ignit.hist %>% filter(FIRE_CAUSE=="Lightning", FIRE_TYPE=="Fire")
fire.ignit.hist <- st_transform (fire.ignit.hist, 3005)

prov.bnd <- st_read ( dsn = "T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\admin_boundaries\\province\\gpr_000b11a_e.shp", stringsAsFactors = T)
st_crs(prov.bnd)
prov.bnd <- prov.bnd [prov.bnd$PRENAME == "British Columbia", ] 
bc.bnd <- st_transform (prov.bnd, 3005)
lightning_clipped<-fire.ignit.hist[bc.bnd,]
str(lightning_clipped)
lightning_clipped$FIRE_YEAR <- as.character(lightning_clipped$FIRE_YEAR)
st_write(lightning_clipped, dsn="C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\bc_fire_ignition.shp")


ogr2ogr -f "PostgreSQL" PG:"host=localhost user=postgres dbname=postgres password=postgres port=5432" C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\bc_fire_ignition.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI



# To get temperature data Im pulling out the fires that started in the years 2002 : 2019 and writing them as a csv file so that I can go and extract the relevant weather data from climateBC (https://cfcg.forestry.ubc.ca/projects/climate-data/climatebcwna/). 

setwd("C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\input")

years<- c("2002", "2003", "2004", "2005", "2006", "2007", "2008", "2009", "2010", "2011", "2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019")

for (i in 1:length(years)) {
x<- lightning_clipped %>% 
  filter(FIRE_YEAR==years[i]) %>% 
  select(FIRE_NO, FIRE_YEAR, LATITUDE, LONGITUDE) %>%
  rename(ID1 = FIRE_NO, ID2 = FIRE_YEAR, lat = LATITUDE, long = LONGITUDE)
x$el<-"."
x2<-st_set_geometry(x,NULL)

name<-paste("ignitions", years[i], "csv", sep=".")
write.csv(x2, file = name, row.names = FALSE )

}

#I then manually extract the monthly climate data for each of the relevant years at each of the fire ignition locations and saved the files as .csv's. Here I import them again.

file.list<-list.files("C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\output", pattern=".csv", all.files=FALSE, full.names=FALSE)
y<-gsub(".csv","",file.list)

setwd("C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\output")
for (i in 1:length(file.list)){
  assign(paste0(y[i]),read.csv (file=paste0(file.list[i])))
}


## VEGETATION DATA downloaded for years 2002 to 2019
# now I need to get the relevant vegetation data which I downloaded from https://catalogue.data.gov.bc.ca/dataset/vri-historical-vegetation-resource-inventory-2002-2018-
# I then extracted this data and uploaded it into my local postgres database by running the command below in terminal. For some reason postgres would not let me upload all the files, maybe because their column names were the same. So Im going to try upload them one at a time. Query them and then delete them before moving on to the next. 

ogr2ogr -f "PostgreSQL" PG:"host=localhost user=postgres dbname=postgres password=postgres port=5432" C:\\Work\\caribou\\clus_data\\Fire\\VRI_data\\veg_comp_lyr_r1_poly2002.gdb -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI

# and rename the table in postgres if need be
#ALTER TABLE veg_comp_lyr_r1_poly RENAME TO veg_comp_lyr_r1_poly2017

# now query
WITH ignit as (SELECT fire_no, fire_year, fire_cause, size_ha, wkb_geometry 
               FROM bc_fire_ignition WHERE fire_type = 'Fire' and fire_year = '2002'),
veg as (SELECT bclcs_level_1, bclcs_level_2, bclcs_level_4, bclcs_level_5, crown_closure, geometry 
        FROM veg_comp_lyr_r1_poly2002) 
SELECT st_intersection (ignit.wkb_geometry, veg.geometry) 
as geom from ignit, veg where st_intersects (ignit.wkb_geometry, veg.geometry);


WITH ignit as (SELECT fire_no, fire_year, fire_cause, size_ha, wkb_geometry FROM bc_fire_ignition WHERE fire_type = "Fire" and fire_year = "2002"), veg as (SELECT bclcs_level_1, bclcs_level2, bclcs_level_4, bclcs_level_5, crown_closure, geometry FROM veg_comp_lyr_r1_poly2002) SELECT st_intersection (ignit.wkb_geometry, veg.geometry) as geom, fire_no, fire_year, fire_cause, size_ha from ignit, bclcs_level_1, bclcs_level2, bclcs_level_4, bclcs_level_5, crown_closure from veg where st_intersects (ignit.geom, veg.geom);

with core as (SELECT herd_name, wkb_geometry from bc_caribou_linework_v20200507_shp_core_matrix where bc_habitat = 'Core' and herd_name in ('Barkerville', 'Wells_Gray_South','Wells_Gray_North','Central_Selkirks','Columbia_North','Columbia_South', 'Groundhog', 'Hart_Ranges', 'Narrow_Lake', 'North_Cariboo', 'Purcell_Central', 'Purcells_South', 'South_Selkirks' )), nohab as (SELECT shape from veg_comp_lyr_r1_poly2019 WHERE bclcs_level_5 in ('GL', 'TA') or non_productive_descriptor_cd in ('ICE', 'L', 'RIV'))  select sum(st_area(st_intersection(core.wkb_geometry, nohab.shape))/10000) as area, core.herd_name from core, nohab where st_intersects(core.wkb_geometry, nohab.shape) group by core.herd_name ;

WITH tsa as (SELECT geom from tsa_table where tsa = 'Quesnel'), veg as ( SELECT geom, species_cd_1 from veg_comp where bclcs_level_1 = 'T') Select st_intersection(tsa.geom, veg.geom) as geom, species_cd_1 from tsa, veg where st_intersects (tsa.geom, veg.geom);



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

# Now query Postgres database
WITH tsa as (SELECT tsa_name, wkb_geometry from tsa_aac_bounds_gbr where tsa_name = 'Arrow_TSA') , veg as (SELECT shape, species_cd_1 from veg_comp_lyr_r1_poly2019 where bclcs_level_1 = 'V') Select veg.geom as shape, species_cd_1 from tsa, veg where st_intersects (tsa.geom, veg.geom);


with core as (SELECT herd_name, wkb_geometry from bc_caribou_linework_v20200507_shp_core_matrix where bc_habitat = 'Core' and herd_name in ('Barkerville', 'Wells_Gray_South','Wells_Gray_North','Central_Selkirks','Columbia_North','Columbia_South', 'Groundhog', 'Hart_Ranges', 'Narrow_Lake', 'North_Cariboo', 'Purcell_Central', 'Purcells_South', 'South_Selkirks' )), nohab as (SELECT shape from veg_comp_lyr_r1_poly2019 WHERE bclcs_level_5 in ('GL', 'TA') or non_productive_descriptor_cd in ('ICE', 'L', 'RIV'))  select sum(st_area(st_intersection(core.wkb_geometry, nohab.shape))/10000) as area, core.herd_name from core, nohab where st_intersects(core.wkb_geometry, nohab.shape) group by core.herd_name ; 











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






