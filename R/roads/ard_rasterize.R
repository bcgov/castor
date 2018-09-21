
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
# extent of input layer
ProvBB <- st_bbox(ProvRast)

#Number of tile rows, number of columns will be the same
nTileRows <- 10

prov_grid <- st_make_grid(st_as_sfc(ProvBB), n = rep(nTileRows, 2))
prov_grid <- st_sf(tile_id = seq_along(prov_grid), 
                   geometry = prov_grid, crs = 3005)

# Plot grid and Prov bounding box just to check
plot(prov_grid)
ProvPlt <- st_as_sfc(ProvBB, crs = 3005)
layer_gridded <- st_intersection(layer, prov_grid)

#parallel registration
cl<-makeCluster(7) #change the 2 to your number of CPU cores
registerDoSNOW(cl)
clusterEvalQ(cl, library(sf))
clusterEvalQ(cl, library(raster))
clusterEvalQ(cl, library(DBI))
clusterEvalQ(cl, library(fasterize))

#run each tsa -- get the spatial file, rasterize, write it to disk
foreach(i= 1:100)  %dopar%  
{
  tryCatch({
    Pcc <- raster::extent(prov_grid[prov_grid$tile_id == i, ])
    DefaultRaster <- raster::raster(Pcc, crs = "+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs", 
                                    resolution = c(100, 100), vals = 0, ext = Pcc)
    
    TilePoly <- layer_gridded[layer_gridded$tile_id == i, ]
    #rasterize the polygons
    layer.ras <-fasterize::fasterize(sf= TilePoly, raster = DefaultRaster , field = "thlb_fact")
    fname <- file.path(tileOutDir, paste0("lyrTile_", i, ".tif"))
    raster::writeRaster(layer.ras, filename = fname, format = "GTiff", overwrite = TRUE)
    message(fname)
    rm(DefaultRaster, TilePoly, fname)
    gc()
    
    }, error = function(e) return(paste0("Grid '", i, "'", 
                                  " caused the error: '", e, "'")))
}
stopCluster(cl)

require(gdalUtils)
require(raster)
#Build list of all raster files you want to join (in your current working directory).
Tiles<- list.files(path=tileOutDir, pattern='lyrTile_')

#Make a template raster file to build onto
template<-ProvRast
writeRaster(template, file=file.path(tileOutDir,"prvLyr.tif"), format="GTiff", overwrite=TRUE)
#Merge all raster tiles into one big raster.
prvLyr<-mosaic_rasters(gdalfile=file.path(tileOutDir,Tiles),
                          dst_dataset=file.path(tileOutDir,"prvLyr.tif"),
                          of="GTiff",
                          output_Raster=TRUE)
gdalinfo(file.path(tileOutDir,"prvLyr.tif"))


# tsa.list<- file.path("C:/Users/KLOCHHEA/clus/R/tmp",list.files(path="C:/Users/KLOCHHEA/clus/R/tmp", pattern =".tif"))
# writeRaster(provRast, file="prov_layer.tif", format="GTiff", overwrite=TRUE)
# tsa.string<-c("C:/Users/KLOCHHEA/clus/R/tmp/prov_layer.tif", unlist(tsa.list))
# paste(unlist(tsa.string), collapse = " ")
# paste("gdal_merge -o C:/Users/KLOCHHEA/clus/R/tmp/prov_layer1.tif -of GTiff ", paste(unlist(tsa.string), collapse = " "))
# #mosaic_rasters(gdalfile= file.path("C:/Users/KLOCHHEA/clus/R/tmp",tsa.list), tsa.list, dst_dataset="prov_layer.tif", of="GTiff", output_Raster=TRUE)
