# Data needed:
# 1.) Fire points files with year of ignition, cause of ignition and size of fire
# 2.) flammability layer. Ian and those guys just classify the landscape as flammable or  inflammable [1,0] according the landcover type. I could do the same or get classes of flammability according to species, vegetation density. Probably best to start simple i.e. just classify as [0,1]
# 3.) Landscape attributes e.g. topography, elevation, soil type, climate such as drought code, maximum daily temperature, total precipitation (rain + snow).
# 3.) study area boundary e.g. ecoregion or some other deliniation to estimate the probability of ignition, escape and spread in. Another alternative is to include ecoregion as a covariate because fire ignitions, escape and spread likely vary by ecoregion
# 4.) raster layer with grid size of desired scale e.g. 1ha blocks of province
# 5.) fireregimePolygons: these are areas within the study area where fire regime parameters are estimated. Ian does it by ecodistrict but we could do it by BEC or something like that. I think basically parameters are estimated for each ecodistrict because the climate, veg, elevation etc are different in these areas. its essentially a covariate in the model (I think)

#OUTPUTS

# 1.) cellsByZone: Cell by zone. basically each raster pixel is assigned to a specific zone with a lookup table
# 2.) flammableMap: A flammability map i.e. map of landscape flammability so we know which cells can or cannot burn
# 3.) landscapeAttr: Landscape attributes i.e. list of polygon attributes inc. area i.e. I guess this could include the elevation of the pixel, the drought code.
# 4.) fireRegimeRas: raster of polygons within different ecodistricts or BEC zones. 

# The goal is to get climate, vegetation and fire ignition (presence or abscence) data together to run an statistical model to see if I can figure out places that fires are likely to start.I think there are two ways to do this and Im not sure which is better.
# 1.) sample ignition points and random other points on the landscape with associated vegetation and climate information collected for those points Then run a glm on the point data.
# OR 2.) do the same but as a raster stack i.e. summarize everything to the 1ha grid scale and run the glmer on this stuff. I wonder if it makes a difference between the two ways. As a start I'll do it using the vector data
# I was hoping to find a digital elevation map of BC. I spent a few hours looking around for a good one and came across several options but all will require a lot of work to get to the format I need. After thinking about it I think Ill ignore elevation because it seems other fire models do. The reason I thought elevation was important was because fires burn faster up slopes than down but maybe what I really need for this is a map of slopes. The other thing about elevation is that it should correlate with vegetation type and density so maybe it too correlated anyway.
# Here is the list of Elevation maps I came across: 
# https://catalogue.data.gov.bc.ca/dataset/7b4fef7e-7cae-4379-97b8-62b03e9ac83d
# this is a raster map of elevation. The problem with it is that it is split up into sections of the province i.e. map letter codes so will take quite a bit of time and memory to get this into a single layer for the entire province (if this is what I want).
#https://catalogue.data.gov.bc.ca/dataset/bc-spot-elevation-points-1-2-000-000-digital-baseline-mapping
#This map has elevations listed at points across the landscape. For a specific point on the landscape Im going ot likely have to somehow average the elevation across the nearest points but that seems complicated.
#https://www.nrcan.gc.ca/science-and-data/science-and-research/earth-sciences/geography/topographic-information/download-directory-documentation/17215
# there are quite a few options on this website. I looked at the canvec ones but I dont think they are quite what I want either. It has contour maps and it has spot locations with elevation. Neither seem totally ideal, although maybe this is the best option out of all of them. 
# anyway, Im putting this aside for the time being and will move on.



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
study_area <- st_transform (study_area, 3005)

# 1.) Fire points
#Get fire points data from the https://catalogue.data.gov.bc.ca/dataset/fire-incident-locations-historical
firePoints <- sf::read_sf(dsn = "D:\\Fire\\fire_data\\raw_data\\PROT_HISTORICAL_FIRE_POLYS_SP\\H_FIRE_PLY_polygon.shp", stringsAsFactors = TRUE)

firePoints <- sf::as_Spatial(firePoints)
