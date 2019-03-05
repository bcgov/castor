
#Sections of this code are taken from bc_raster_roads (stephhazlitt)
library(sf)
library(dplyr)
library(readr)
library(rpostgis)
library(raster)
library(spex) # fast conversion of raster to polygons
# For parallel processing tiles to rasters
library(gdalUtils)
library(data.table)

getSpatialQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='DC052586.idir.bcgov', dbname = 'clus', port='5432' ,user='postgres' ,password='postgres')
  on.exit(DBI::dbDisconnect(conn))
  sf::st_read(conn, query = sql)
}
#Get coast thlb 
layer<-getSpatialQuery(paste("SELECT thlb_fact, wkb_geometry FROM public.thlb_data_rco"))

#Make an empty provincial raster aligned with hectares BC
ProvRast <- raster(
  nrows = 15744, ncols = 17216, xmn = 159587.5, xmx = 1881187.5, ymn = 173787.5, ymx = 1748187.5, 
  crs = st_crs(lyr)$proj4string, resolution = c(100, 100), vals = 0
)


layer.ras <-fasterize::fasterize(sf= layer, raster = ProvRast , field = "thlb_fact")
writeRaster(layer.ras, file="thlb_rco_Lyr.tif", format="GTiff", overwrite=TRUE)


#Get southern interior data 
layer<-getSpatialQuery(paste("SELECT thlb_fact, wkb_geometry FROM public.thlb_data_sir"))
layer.ras <-fasterize::fasterize(sf= layer, raster = ProvRast , field = "thlb_fact")
writeRaster(layer.ras, file="thlb_sir_Lyr.tif", format="GTiff", overwrite=TRUE)


#Get northern interior data 
layer<-getSpatialQuery(paste("SELECT thlb_fact, wkb_geometry FROM public.thlb_data_nir"))
layer.ras <-fasterize::fasterize(sf= layer, raster = ProvRast , field = "thlb_fact")
writeRaster(layer.ras, file="thlb_nir_Lyr.tif", format="GTiff", overwrite=TRUE)

#Get thlb 2018 data 
layer<-getSpatialQuery(paste("SELECT thlb_fact, wkb_geometry FROM public.bc_thlb"))
layer.ras <-fasterize::fasterize(sf= layer, raster = ProvRast , field = "thlb_fact")
writeRaster(layer.ras, file="thlb2018", format="GTiff", overwrite=TRUE)


