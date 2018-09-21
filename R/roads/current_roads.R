# Copyright 2018 Province of British Columbia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.


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
  conn<-dbConnect(dbDriver("PostgreSQL"), host='localhost', dbname = 'clus', port='5432' ,user='app_user' ,password='clus')
  on.exit(dbDisconnect(conn))
  st_read(conn, query = sql)
}

#roads_sf <- getSpatialQuery("SELECT wkb_geometry FROM public.integrated_roads where road_surface = 'paved' and (road_class <> 'water' or road_class <> 'pedestrian');")
#roads_sf <- getSpatialQuery("SELECT wkb_geometry FROM public.integrated_roads where road_surface = 'loose' and (road_class <> 'proposed');")
#roads_sf <- getSpatialQuery("SELECT wkb_geometry FROM public.integrated_roads where (road_surface = 'rough' or road_surface = 'seasonal') and (road_class <> 'proposed');")
#roads_sf <- getSpatialQuery("SELECT wkb_geometry FROM public.integrated_roads where (road_surface = 'unknown') and (road_class <> 'proposed');")
#roads_sf <- getSpatialQuery("select wkb_geometry FROM public.integrated_roads where bcgw_source = 'WHSE_BASEMAPPING.TRIM_TRANSPORTATION_LINES'")

#roads_sf <- getSpatialQuery("select wkb_geometry FROM public.integrated_roads where bcgw_source = 'WHSE_MINERAL_TENURE.OG_PETRLM_DEV_RDS_PRE06_PUB_SP' or
#bcgw_source = 'WHSE_MINERAL_TENURE.OG_PETRLM_ACCESS_ROADS_PUB_SP' or bcgw_source = 'WHSE_MINERAL_TENURE.OG_PETRLM_DEV_ROADS_PUB_SP'")

roads_sf <- getSpatialQuery("select wkb_geometry FROM public.integrated_roads where bcgw_source = 'WHSE_FOREST_VEGETATION.RSLT_FOREST_COVER_INV_SVW' or
bcgw_source = 'WHSE_FOREST_TENURE.FTEN_ROAD_SECTION_LINES_SVW' or bcgw_source = 'WHSE_FOREST_TENURE.ABR_ROAD_SECTION_LINE'")


# Set up Provincial raster based on hectares BC extent, 1ha resolution and projection
ProvRast <- raster(
  nrows = 15744, ncols = 17216, xmn = 159587.5, xmx = 1881187.5, ymn = 173787.5, ymx = 1748187.5, 
  crs = st_crs(roads_sf)$proj4string, resolution = c(100, 100), vals = 0
)

#---------------------
#split Province into tiles for processing

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

# Chop the roads up by the 10x10 tile grid. This takes a while but you only have to 
# do it once.
roads_gridded <- st_intersection(roads_sf, prov_grid)

# Loop through each tile and calculate road density for each 1ha cell.
# Choose number of cores to use in parallel carefully... too many and
# it will fill up memory and grind to a halt.
#registerDoParallel(cores=2)

#foreach(i=1:3) %dopar% sqrt(i)

ptm <- proc.time()

cl<-makeCluster(7) #change the 2 to your number of CPU cores
registerDoSNOW(cl)
clusterEvalQ(cl, library(sf))
clusterEvalQ(cl, library(raster))
system.time({
foreach(i= 1:100) %dopar% {
  Pcc <- raster::extent(prov_grid[prov_grid$tile_id == i, ])
  DefaultRaster <- raster::raster(Pcc, crs = "+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs", 
                          resolution = c(100, 100), vals = 0, ext = Pcc)

  ## Use the roads layer that has already been chopped into tiles
  TilePoly <- roads_gridded[roads_gridded$tile_id == i, ]

  if (nrow(TilePoly) > 0) {
    
    ##  This calculates lengths more directly than psp method...
    DefaultRaster[] <- 1:ncell(DefaultRaster)
    rsp <- spex::polygonize(DefaultRaster) # spex pkg for quickly making polygons from raster
    # Split tile poly into grid by the polygonized raster
    rp1 <- sf::st_intersection(TilePoly[,1], rsp)
    rp1$rd_len <- as.numeric(sf::st_length(rp1)) # road length in m for each grid cell
    # Sum of road lengths in each grid cell
    x <- tapply(rp1$rd_len, rp1$layer, sum, na.rm = TRUE)
    # Create raster and populate with sum of road lengths
    roadlengthT <- raster::raster(DefaultRaster)
    roadlengthT[as.integer(names(x))] <- x
    roadlengthT[is.na(roadlengthT)] <- 0
    rm(rsp, rp1, x)
    #plot(roadlengthT)
  } else {
    roadlengthT <- DefaultRaster
  }
  fname <- file.path(tileOutDir, paste0("rdTile_", i, ".tif"))
  raster::writeRaster(roadlengthT, filename = fname, format = "GTiff", overwrite = TRUE)
  message(fname)
  rm(DefaultRaster, TilePoly, roadlengthT, fname)
  gc()
}
stopCluster(cl)
})
require(gdalUtils)
require(raster)
#Build list of all raster files you want to join (in your current working directory).
Tiles<- list.files(path=tileOutDir, pattern='rdTile_')

#Make a template raster file to build onto
template<-ProvRast
writeRaster(template, file=file.path(tileOutDir,"RoadDensR.tif"), format="GTiff", overwrite=TRUE)
#Merge all raster tiles into one big raster.
RoadDensR<-mosaic_rasters(gdalfile=file.path(tileOutDir,Tiles),
                          dst_dataset=file.path(tileOutDir,"RoadDensR.tif"),
                          of="GTiff",
                          output_Raster=TRUE)
gdalinfo(file.path(tileOutDir,"RoadDensR.tif"))
#Plot to test
plot(RoadDensR)
projection(RoadDensR)
nprj<-'+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0'
RoadDensR2<-projectRaster(RoadDensR,nprj )

