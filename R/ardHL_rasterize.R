
#Sections of this code are taken from bc_raster_roads (stephhazlitt)
library(sf)
library(dplyr)
library(readr)
library(rpostgis)
library(raster)
library(spex) # fast conversion of raster to polygons
# For parallel processing tiles to rasters
library(doSNOW)
library(foreach)
library(gdalUtils)

setwd("C:/Users/KLOCHHEA/clus/R/tmp")
TmpDir <- 'tmp'
OutDir <- 'out'
DataDir <- 'data'
dataOutDir <- file.path(OutDir,'data')
tileOutDir <- file.path(dataOutDir,'tile')

dir.create(TmpDir, showWarnings = FALSE)
dir.create(OutDir, showWarnings = FALSE)
dir.create(DataDir, showWarnings = FALSE)
dir.create(file.path(dataOutDir), showWarnings = FALSE)
dir.create(file.path(tileOutDir), showWarnings = FALSE)

getSpatialQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='DC052586.idir.bcgov', dbname = 'clus', port='5432' ,user='postgres' ,password='postgres')
  on.exit(DBI::dbDisconnect(conn))
  sf::st_read(conn, query = sql)
}
#Get data 
layer<-getSpatialQuery(paste("SELECT thlb_fact, wkb_geometry FROM public.bc_thlb"))
#Make an empty provincial raster aligned with hectares BC
ProvRast <- raster(
  nrows = 15744, ncols = 17216, xmn = 159587.5, xmx = 1881187.5, ymn = 173787.5, ymx = 1748187.5, 
  crs = st_crs(layer)$proj4string, resolution = c(100, 100), vals = 0
)
layer.ras <-fasterize::fasterize(sf= layer, raster =ProvRast , field = "thlb_fact")
writeRaster(layer.ras, file="prov_layer.tif", format="GTiff", overwrite=TRUE)
