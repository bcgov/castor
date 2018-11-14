
library(raster)
library(SpaDES.tools)

system.time({
r <- raster("//spatialfiles2.bcgov/archive/FOR/VIC/HTS/ANA/PROJECTS/CLUS/Data/Roads/roads_ha_bc/pre_roads.tif")
crs(r) = "+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0 +datum=NAD83
                          +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0"
#xy <- rasterToPoints(r, fun=function(x){x > 0})
d1 <- raster::distanceFromPoints(r, rasterToPoints(r, fun=function(x){x > 0})[,1:2]) 
})
