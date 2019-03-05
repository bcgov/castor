
#Sections of this code are taken from bc_raster_roads (stephhazlitt)
library(sf)
library(dplyr)
library(readr)
library(rpostgis)
library(raster)
library(spex) # fast conversion of raster to polygons
# For parallel processing tiles to rasters
library(gdalUtils)
library(sf)
getSpatialQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='DC052586.idir.bcgov', dbname = 'clus', port='5432' ,user='postgres' ,password='postgres')
  on.exit(DBI::dbDisconnect(conn))
  sf::st_read(conn, query = sql)
}
#Get coast thlb 
layer<-getSpatialQuery(paste("SELECT tsa_number, geom FROM public.forest_tenure_compart"))

#Make an empty provincial raster aligned with hectares BC
ProvRast <- raster(
  nrows = 15744, ncols = 17216, xmn = 159587.5, xmx = 1881187.5, ymn = 173787.5, ymx = 1748187.5, 
  crs = st_crs(layer)$proj4string, resolution = c(100, 100), vals = 0
)
layer.ras <-fasterize::fasterize(sf= layer, raster = ProvRast , field = "tsa_number")
writeRaster(layer.ras, file="tsa.tif", format="GTiff", overwrite=TRUE)


#gdal_rasterize -tr 100 100 -te 159587.5 173787.5 1881187.5 1748187.5 -a tsa_number PG:" host='DC052586.idir.bcgov' dbname = 'clus' port='5432' user='postgres' password='postgres'" -sql "SELECT tsa_number, geom FROM public.forest_tenure_compart"  C:\Users\KLOCHHEA\tsa.tif
#gdal_rasterize -tr 100 100 -te 159587.5 173787.5 1881187.5 1748187.5 -a basal_area PG:" host='DC052586.idir.bcgov' dbname = 'clus' port='5432' user='postgres' password='postgres'" -sql "SELECT d.basal_area, g.wkb_geometry FROM (SELECT basal_area, gr_skey FROM public.tsa02_ar_table where basal_area > 0) d LEFT JOIN (SELECT wkb_geometry, gr_skey FROM public.tsa02_skey) g ON d.gr_skey = g.gr_skey"  C:\Users\KLOCHHEA\tsa02.tif

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


