library(sf)
library(tidyverse)
library(ggplot2)
library (RPostgreSQL)
library (rpostgis)
library (dplyr)

source(here::here("R/functions/R_Postgres.R"))

# Import my vegetation, climate and presence/absence of fire data
connKyle <- dbConnect(drv = RPostgreSQL::PostgreSQL(), 
                      host = key_get('dbhost', keyring = 'postgreSQL'),
                      user = key_get('dbuser', keyring = 'postgreSQL'),
                      dbname = key_get('dbname', keyring = 'postgreSQL'),
                      password = key_get('dbpass', keyring = 'postgreSQL'),
                      port = "5432")
fire_veg_data <- sf::st_read  (dsn = connKyle, # connKyle
                               query = "SELECT * FROM public.fire_ignitions_veg_climate")

dbDisconnect (connKyle)

library(raster)
library(rgdal)

# To Kyles Clus
#host=keyring::key_get('dbhost', keyring = 'postgreSQL')
#user=keyring::key_get('dbuser', keyring = 'postgreSQL')
#dbname=keyring::key_get('dbname', keyring = 'postgreSQL')
#password=keyring::key_get('dbpass', keyring = 'postgreSQL')

# Run this in terminal
#ogr2ogr -f PostgreSQL PG:"host= user= dbname= password= port=5432" D:\\Fire\\fire_data\\raw_data\\ClimateBC_Data\\DC_data.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI



dsn="PG:dbname='plots' host=localhost user='test' password='test' port=5432 schema='rast' table='dem' mode=2"

ras <- readGDAL(dsn) # Get your file as SpatialGridDataFrame
ras2 <- raster(ras,1) # Convert the first Band to Raster
plot(ras2)