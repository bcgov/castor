library(raster)
library(data.table)
library(sf)
library(tidyverse)
library(rgeos)
library(bcmaps)
library(ggplot2)
require (RPostgreSQL)
require (rpostgis)
require (fasterize)
require (dplyr)

source(here::here("R/functions/R_Postgres.R"))

#### Provincial boundary with fire ignitions
bc.tsa <- st_read ( dsn = "C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\Ignition_clipped.shp", stringsAsFactors = T)# In QGIS I buffered the location where a fire started by 500m and then clipped out the buffered locations between the years 2002 - 2019 from the bc tsa boundaries.  I wanted to do this for each year separately but could not work out how to do this in QGIS and when I tried to do it in R, R crashed my whole computer so after trying 4 times I gave up. 
bc.tsa <-bc.tsa %>% 
  filter (administra != 'Queen Charlotte Timber Supply Area') %>%
  filter(administra != 'North Island Timber Supply Area') %>%
  filter(administra != 'Arrowsmith Timber Supply Area') %>%
  filter(administra != 'Pacific Timber Supply Area')
bc.tsa <- st_transform (bc.tsa, 3005)
bc.tsa_sp<-as(bc.tsa, "Spatial")
bc.bnd.points<- spsample(bc.tsa_sp, n=20000, type="regular")
plot(bc.bnd.points, add=T,col="red")

sample.pts <- data.frame (matrix (ncol = 5, nrow = nrow (bc.bnd.points@coords)))
colnames (sample.pts) <- c ("ID1","ID2", "lat", "long", "el")
sample.pts$ID1<- 1:(length(bc.bnd.points@coords[,1]))
sample.pts$ID2 <- 0
sample.pts$lat <- bc.bnd.points@coords[,1]
sample.pts$long <- bc.bnd.points@coords[,2]
sample.pts$el <- "."

write_csv(sample.pts, path="C:\\Work\\caribou\\clus_data\\Fire\\Fire_ignition_years_csv\\input\\sample_pts.csv")












bc.tsa<-getSpatialQuery("SELECT administrative_area_name, shape 
                        FROM tsa_boundaries 
                        WHERE administrative_area_name != 'Queen Charlotte Timber Supply Area' AND administrative_area_name != 'North Island Timber Supply Area' AND administrative_area_name != 'Arrowsmith Timber Supply Area' AND administrative_area_name != 'Pacific Timber Supply Area'")
bc.tsa <- st_transform (bc.tsa, 3005)
bc.tsa_sp<-as(bc.tsa, "Spatial")
class(bc.tsa_sp)


# prov.bnd <- st_read ( dsn = "T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\admin_boundaries\\province\\gpr_000b11a_e.shp", stringsAsFactors = T)
# st_crs(prov.bnd)
# prov.bnd <- prov.bnd [prov.bnd$PRENAME == "British Columbia", ] 
# bc.bnd <- st_transform (prov.bnd, 3005)
# bc.bnd.valid<-st_make_valid(bc.bnd)


#### FIRE IGNITION DATA ####
fire.ignit.hist<-sf::st_read(dsn="C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\BCGW_7113060B_1600358424324_13780\\PROT_HISTORICAL_INCIDENTS_SP\\H_FIRE_PNT_point.shp")
st_crs(fire.ignit.hist)
head(fire.ignit.hist)
#lighting.hist<-fire.ignit.hist %>% filter(FIRE_CAUSE=="Lightning", FIRE_TYPE=="Fire")
fire.ignit.hist <- st_transform (fire.ignit.hist, 3005)
lightning_clipped<-fire.ignit.hist[bc.tsa,]

lightning_clipped2<- lightning_clipped %>% 
  filter (FIRE_YEAR>=2002, FIRE_TYPE=="Fire") %>%
  select(FIRE_ID, FIRE_YEAR : FIRE_CAUSE, FIRE_TYPE, SIZE_HA, geometry)


# what I think I need to do: clip out ignition locations then randomly sample points across bc for the available data. 
foo <- lightning_clipped2 %>%
  filter(FIRE_YEAR == 2002)
bc.tsa.points<- spsample(bc.tsa_sp, n=20000, type="regular")
foo.buffered<-st_buffer(foo, 500)

bc.tsa.clipped<- st_difference(bc.tsa, foo.buffered)
bc.tsa.clipped_sp<-as(bc.tsa.clipped, "Spatial")
bc.bnd.points<- spsample(bc.bnd.clipped_sp, n=20000, type="regular")

sample.pts <- data.frame (matrix (ncol = 4, nrow = nrow (bc.bnd.points@coords)))
colnames (sample.pts) <- c ("Year","pttype", "uniqueID", "FIRE_CAUSE")
sample.pts.start.data$pttype <- 0
sample.pts.start.data$uniqueID <- "du6_EarlyWinter_HSCEK077_2012"
id.points.out.all <- SpatialPointsDataFrame (sample.pts.start, data = sample.pts.start.data)

years<- c("2002", "2003", "2004", "2005", "2006", "2007", "2008", "2009", "2010", "2011", "2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019")
for (i in 1:length(years)) {
  foo <- lightning_clipped2 %>%
    filter(FIRE_YEAR == years[i])
  foo.buffered<-st_buffer(foo, 500)
  bc.bnd.clipped<- st_difference(bc.tsa, foo.buffered)
  bc.bnd.clipped_sp<-as(bc.bnd.clipped, "Spatial")
  bc.bnd.points<- spsample(bc.bnd.clipped_sp, n=20000, type="regular")
  
  
  
  
  
  
  
  
  
  
  
}



# Check the layers line up.
ggplot() +
  geom_sf(data=bc.tsa) +
  geom_sf(data=lightning_clipped)

head(lightning_clipped)




sample.pts.boreal <- spsample (caribou.boreal.sa, cellsize = c (2000, 2000), type = "regular")

#Make an empty provincial raster aligned with hectares BC
ProvRast <- raster(
  nrows = 15744, ncols = 17216, xmn = 159587.5, xmx = 1881187.5, ymn = 173787.5, ymx = 1748187.5, 
  crs = 3005, resolution = c(100, 100), vals = 0
) # from https://github.com/bcgov/bc-raster-roads/blob/master/03_analysis.R
bc.tsa.raster <- fasterize (bc.tsa, ProvRast, 
                            field = NULL,# raster cells that were cut get in 2017 get a value of 1
                            background = 0) # unharvested raster cells get value = 0 

st_write(lightning_clipped2, dsn = "C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\fire_ignitions.shp", delete_layer=TRUE)

# commit the shape file to postgres
# this works for loading the shape file onto Kyles Postgres. Run these sections of code below in R and fill in the details in the script for command prompt. Then run the ogr2ogr script in command prompt to get the table into postgres

host=keyring::key_get('dbhost', keyring = 'postgreSQL')
user=keyring::key_get('dbuser', keyring = 'postgreSQL')
dbname=keyring::key_get('dbname', keyring = 'postgreSQL')
password=keyring::key_get('dbpass', keyring = 'postgreSQL')

# Run this in terminal
#ogr2ogr -f PostgreSQL PG:"host=DC052586 user=clus_project dbname=clus password=clus port=5432" C:\\Work\\caribou\\clus_data\\Fire\\Fire_sim_data\\fire_inition_hist\\fire_ignitions.shp -overwrite -a_srs EPSG:3005 -progress --config PG_USE_COPY YES -nlt PROMOTE_TO_MULTI




