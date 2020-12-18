# Data needed:
# 1.) Fire points files with year of ignition, cause of ignition and size of fire
# 2.) flammability layer. Ian and those guys just classify the landscape as flammable or  inflammable [1,0] according the landcover type. I could do the same or get classes of flammability according to species, vegetation density. Probably best to start simple i.e. just classify as [0,1]
# 3.) study area boundary e.g. ecoregion or some other deliniation to estimate the probability of ignition, escape and spread in.
# 4.) raster layer with grid size of desired scale e.g. 1ha blocks of province
# 5.) fireregimePolygons: these are areas within the study area where fire regime parameters are estimated. Ian does it by ecodistrict but we could do it by BEC or something like that. I think basically parameters are estimated for each ecodistrict because the climate, veg, elevation etc are different in these areas. its essentially a covariate in the model (I think)

#OUTPUTS

# 1.) cellsByZone: Cell by zone. basically each raster pixel is assigned to a specific zone with a lookup table
# 2.) flammableMap: A flammability map i.e. map of landscape flammability so we know which cells can or cannot burn
# 3.) landscapeAttr: Landscape attributes i.e. list of polygon attributes inc. area i.e. I guess this could include the elevation of the pixel, the drought code.
# 4.) fireRegimeRas: raster of polygons within different ecodistricts or BEC zones. 


# Get Study Area
source(here::here("R/functions/R_Postgres.R"))
library(dplyr)

connKyle <- dbConnect(drv = RPostgreSQL::PostgreSQL(), 
                      host = key_get('dbhost', keyring = 'postgreSQL'),
                      user = key_get('dbuser', keyring = 'postgreSQL'),
                      dbname = key_get('dbname', keyring = 'postgreSQL'),
                      password = key_get('dbpass', keyring = 'postgreSQL'),
                      port = "5432")
tsa_bounds <- sf::st_read  (dsn = connKyle, # connKyle
                               query = "SELECT * FROM public.tsa_aac_bounds_gbr")
dbDisconnect (connKyle)

study_area <-tsa_bounds %>% 
  filter (tsa_name == 'Williams_Lake_TSA')
bc.tsa <- st_transform (bc.tsa, 3005)

# 1.) Fire points
#Get fire points data from the https://catalogue.data.gov.bc.ca/dataset/fire-incident-locations-historical
firePoints <- sf::read_sf(dsn = "D:\\Fire\\fire_data\\raw_data\\PROT_HISTORICAL_FIRE_POLYS_SP\\H_FIRE_PLY_polygon.shp", stringsAsFactors = TRUE)

firePoints <- sf::as_Spatial(firePoints)
