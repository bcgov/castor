
### packages
library(rpostgis)
library(sf)
library(raster)
library(RPostgreSQL)
library(rgdal)
library(sqldf)
library(DBI)
library(sp)

#Simple database connectivity functions
getSpatialQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), 
                       host=keyring::key_get('dbhost', keyring = 'postgreSQL'), 
                       dbname = keyring::key_get('dbname', keyring = 'postgreSQL'), port='5432' ,
                       user=keyring::key_get('dbuser', keyring = 'postgreSQL') ,
                       password= keyring::key_get('dbpass', keyring = 'postgreSQL')
  )
  on.exit(dbDisconnect(conn))
  st_read(conn, query = sql)
}

#Get dummy layer for projection (too lazy to write it) 
lyr<-getSpatialQuery(paste("SELECT geom FROM public.gcbp_carib_polygon"))

#Make an empty provincial raster aligned with hectares BC
ProvRast <- raster(
  nrows = 15744, ncols = 17216, xmn = 159587.5, xmx = 1881187.5, ymn = 173787.5, ymx = 1748187.5, 
  crs = st_crs(lyr)$proj4string, resolution = c(100, 100), vals = 0
)

layer<-getSpatialQuery("SELECT feature_id, shape FROM public.veg_comp_lyr_r1_poly2021")

layer.ras <-fasterize::fasterize(sf= layer, raster = ProvRast , field = "feature_id")
rm(layer)
gc()

writeRaster(layer.ras, file="vri2021_id.tif", format="GTiff", overwrite=TRUE)