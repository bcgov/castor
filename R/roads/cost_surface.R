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

#Cost Surface for igraph
library(sf)
library(rpostgis)
library(dplyr)
library(raster)

getSpatialQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='localhost', dbname = 'clus', port='5432' ,user='postgres' ,password='postgres')
  on.exit(dbDisconnect(conn))
  st_read(conn, query = sql)
}
getRasterQuery<-function(name){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='localhost', dbname = 'clus', port='5432' ,user='app_user' ,password='clus')
  on.exit(dbDisconnect(conn))
  pgGetRast(conn, name)
}

roadCost.lookUp<-read.table("C:/Users/KLOCHHEA/clus/roadCostTSA.csv", sep = ",", head = TRUE)

tsa<-getSpatialQuery("SELECT * FROM public.forest_tenure;")
tsa.rc<-tsa %>% 
        right_join(roadCost.lookUp, by = "tsa_number")
#build a default provincial raster
prov.rast <- raster::raster(
  nrows = 15744, ncols = 17216, xmn = 159587.5, xmx = 1881187.5, ymn = 173787.5, ymx = 1748187.5, 
  crs = st_crs(tsa.rc)$proj4string, resolution = c(100, 100), vals = 0)

#assing road group 1 to any TSA outside the polygons
tsa.rc$Road_Cost[is.na(tsa.rc$Road_Cost)] <- 1
tsa.rc$Inter[is.na(tsa.rc$Inter)] <- 37130
tsa.rc$SlpCoef[is.na(tsa.rc$SlpCoef)] <- 156.68
tsa.rc$ESSFCoef[is.na(tsa.rc$ESSFCoef)] <- 0
#---check
plot(tsa.rc["SlpCoef"])
slope.rc10<-tsa.rc[tsa.rc$Road_Cost == 10,]

ras.slope.rc10<-fasterize::fasterize(slope.rc10, prov.rast, field = "Road_Cost")
tsa.ras.int<-fasterize::fasterize(tsa.rc, prov.rast, field = "Inter")
tsa.ras.slpCoef<-fasterize::fasterize(tsa.rc, prov.rast, field = "SlpCoef")
tsa.ras.essfCoef<-fasterize::fasterize(tsa.rc, prov.rast, field = "ESSFCoef")

#mask for road group 10 -- it has slope**2
ras.slope.rc10[ras.slope.rc10[]== 10]<-1
ras.slope.rc10[is.na(ras.slope.rc10[])]<-0
#plot(ras.slope.rc10)

# get the slope
slope<-raster("//spatialfiles2.bcgov/archive/FOR/VIC/HTS/ANA/PROJECTS/CLUS/Data/dem/all_bc/bc_ha_slope.tif")
ras.slope.rc10<-resample(ras.slope.rc10, slope, method = 'bilinear')

rc10.slope<-slope*ras.slope.rc10
rc10.slope2<-rc10.slope*rc10.slope

rc10.mask<-ras.slope.rc10
rc10.mask[ras.slope.rc10[]==1]<-0
rc10.mask[ras.slope.rc10[]==0]<-1

plot(rc10.mask)
slope.cost<- rc10.mask*slope + rc10.slope2
#writeRaster(slope.cost, file="//spatialfiles2.bcgov/archive/FOR/VIC/HTS/ANA/PROJECTS/CLUS/Data/Roads/slope_rc10.tif", format="GTiff", overwrite=TRUE)
#free up some memory
rm(rc10.inv,rc10,rc10.slope2,rc10.slope,slope2,ras.slope2)

#pipeline crossings
pipelines <-raster("//spatialfiles2.bcgov/archive/FOR/VIC/HTS/ANA/PROJECTS/CLUS/Data/pipelines/raster_pipelines_20180815.tif") 
pipe.cost<- pipelines*1911 #cost to cross a multiple pipeline per pipe

#watercrossings
waterx <-raster("//spatialfiles2.bcgov/archive/FOR/VIC/HTS/ANA/PROJECTS/CLUS/Data/water/raster_watercourses_20180816.tif") 
waterx.cost<-waterx*2130 #assuming a 0.8 diameter at 14 m

#Lake barriers
lake <-raster("//spatialfiles2.bcgov/archive/FOR/VIC/HTS/ANA/PROJECTS/CLUS/Data/water/raster_lakes_20180816.tif") 

#ESSF
#Call Mikes raster functions???
essf<-getSpatialQuery("SELECT * FROM public.bec_zone WHERE zone = 'ESSF'")
essf$zoneInt<-1
essf.ras<- fasterize::fasterize(essf, prov.rast, field = "zoneInt")

#Calcualte the road cost
tsa.ras.slpCoef2<-resample(tsa.ras.slpCoef, slope.cost, method = 'bilinear')
tsa.ras.int2<-resample(tsa.ras.int, slope.cost, method = 'bilinear')
tsa.ras.essfCoef2<-resample(tsa.ras.essfCoef, slope.cost, method = 'bilinear')
lake2<-resample(lake, slope.cost, method = 'bilinear')
pipe.cost2<-resample(pipe.cost, slope.cost, method = 'bilinear')
waterx.cost2<-resample(waterx.cost, slope.cost, method = 'bilinear')
essf2<-resample(essf.ras, slope.cost, method = 'bilinear')
essf2[is.na(essf2[])]<-0

cost.surface<-waterx.cost2 + pipe.cost2 + tsa.ras.int2 + slope.cost*tsa.ras.slpCoef2 + tsa.ras.essfCoef2*essf2 
plot(cost.surface)
cost.surface2<-cost.surface
cost.surface2[lake2==1]<-NA
writeRaster(cost.surface2, file="//spatialfiles2.bcgov/archive/FOR/VIC/HTS/ANA/PROJECTS/CLUS/Data/Roads/cost_surface.tif", format="GTiff", overwrite=TRUE)
#pgWriteRast(conn=DBI::dbConnect(dbDriver("PostgreSQL"), host='localhost', dbname = 'clus', port='5432' ,user='postgres' ,password='postgres'), name =c("public", "cost_surface"), raster = cost.surface2)



