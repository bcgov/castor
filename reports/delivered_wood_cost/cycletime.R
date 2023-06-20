library(tidyverse)
library(sf)
library(terra)


data.dir <- "C:\\Work\\git\\castor\reports\\delivered_wood_cost\\data\\"

#get tifs and convert to SpatRasters using terra
dist2net <- rast (paste0 (data.dir, "Dist2Network.tif"))



dist2net <- rast(r"(C:\Data\mock-up\DTFolderStructure\STSM\STSM\TSA99\Outputs\Access\Scn1_1\grids\Dist2Network.tif)")
dist2exit <- rast(r"(C:\Data\mock-up\DTFolderStructure\STSM\STSM\TSA99\Outputs\Access\Scn1_1\grids\Dist2Exit.tif)")
road_state <- rast(r"(C:\Data\mock-up\DTFolderStructure\STSM\STSM\TSA99\Outputs\Access\Scn1_1\grids\RoadAccess_state.tif)")
rd_cls <- rast(r"(C:\Data\mock-up\DTFolderStructure\STSM\STSM\TSA99\gisData\grids\rd_cls.tif)")

#make template raster with mock-up extents
x <- rast(
  nrows = 564, ncols = 631, xmin = 999987.5, xmax = 1063087.5,
  ymin = 1166987.5, ymax = 1223387.5,
  crs = "epsg:3005",
  resolution = c(100, 100),
  val = 0
)


#### step 1: Cycletime##########################################

# use rd_cls and road_state to create a rd_order raster
tmp1 <- ifel(road_state == 2, 6, rd_cls) # rd_order
tmp2 <- ifel(dist2net > 0, 6, tmp1) # non-roaded order

# road speed list for reclassification
m <- c(
  0, 0,
  1, 70,
  2, 50,
  3, 50,
  4, 40,
  5, 40,
  6, 30
)
# create road speed matric

r <- matrix(m, ncol = 2, byrow = TRUE)
#assign road speed to road network
# reclassify tmp2 to road speed
road_speed <- classify(tmp2, r, include.lowest = TRUE) # km/hr
#convert dist2exit from metres to km
dist2exitKM <- dist2exit / 1000
#calculate hrs to exit using road speeds
hrs2exit <- dist2exitKM / road_speed # hrs
#claculate cycletime
cycle_time <- ((2 * hrs2exit) + 1) * 2.25 # time2exit there and back + 1 hr * $/m3
x<-values(cycle_time)
##### step 2 Harvest System by slope cut-off
slope <- rast(r"(C:\Data\mock-up\DTFolderStructure\STSM\STSM\TSA99\gisData\grids\SlopePct.tif)")
# create slope cut-off matrix for reclass using $/m3

s <- c(
  0, 25, 22.04,
  25, 35, 28.52,
  35, Inf, 34.77
)
hrv_cls <- matrix(s, ncol = 3, byrow = TRUE)
# reclassify slope by assigning system $/m3 values to cut-offs
hrv_sys <- classify(slope, hrv_cls, include.lowest = TRUE)
#visulaize
plot(hrv_sys)

##### step 3 Road Costs########################

# assume $5 per meter of new road constructed
# assume $2 per meter maintained
# cost of construction and future maintenance $7/m3 for areas > 300 m from network otherwise $3
dev_cost <- ifel(dist2net > 300, 7, 3)
#################### total cost

total_cost <- cycle_time + hrv_sys + dev_cost
# clean up using 99 percentile cut-off
total_cost <- ifel(total_cost > 60, 60, total_cost)
# get the min value for normalizing
z <- minmax(total_cost)
# normalize total cost and scale by 100
cost_index <- round(total_cost / z[1, ] * 100, 0)
# round to int
total_cost <- round(total_cost, 0)
cycle_time<-round(ifel(cycle_time > 12,12,cycle_time)*100,0)
# output rasters
index <- "C:\\Data\\mock-up\\DTFolderStructure\\tiff\\tsa99_cost_index.tif"
cost <- "C:\\Data\\mock-up\\DTFolderStructure\\tiff\\tsa99_total_cost.tif"
ctime<-"C:\\Data\\mock-up\\DTFolderStructure\\tiff\\tsa99_ctime.tif"

writeRaster(cycle_time,
  ctime,
  datatype = "INT4U",
  NAflag = 0, overwrite = TRUE
)
