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
#===========================================================================================

#Purpose of this script is to develope a similarity raster -- for determining a quantifiable metric of similarity between adjacent pixels.
#The workflow follows as:
#1. Get bc thlb - as a mask for pixels to be included in the analysis
#2. Get 2003 VRI information of forest structure (Basal Area, Volume, Age)

source("R/functions/R_Postgres.R")
caribou_herd<-st_zm(getSpatialQuery("SELECT * FROM gcbp_carib_polygon WHERE herd_name = 'Muskwa';"))
plot(caribou_herd["herd_name"])
conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
geom<-dbGetQuery(conn, "SELECT ST_ASTEXT(ST_TRANSFORM(ST_Force2D(GEOM), 4326)) FROM gcbp_carib_polygon WHERE herd_name = 'Muskwa' ") 

conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
thlb<-RASTER_CLIP(srcRaster="ras_bc_thlb2018", clipper=geom, conn=conn) 

#VRI layers to use - AGE, Crown Closure and Height;
spp<-getSpatialQuery("SELECT bclcs_level_4, wkb_geometry FROM 
public.veg_comp_lyr_r1_poly_final_spatialv2_2003 where bclcs_level_2 = 'T'")
crownclosure<-getSpatialQuery("SELECT crown_closure, wkb_geometry FROM 
public.veg_comp_lyr_r1_poly_final_spatialv2_2003")

#Make an empty provincial raster aligned with hectares BC
ProvRast <- raster(
  nrows = 15744, ncols = 17216, xmn = 159587.5, xmx = 1881187.5, ymn = 173787.5, ymx = 1748187.5, 
  crs = st_crs(spp)$proj4string, resolution = c(100, 100), vals = 0
)
layer.ras <-fasterize::fasterize(sf= crownclosure, raster = ProvRast , field = "crown_closure")
writeRaster(layer.ras, file="crown_closure.tif", format="GTiff", overwrite=TRUE)
spp$bclcs_level_4<-factor(spp$bclcs_level_4, levels =c("TB", "TM", "TC", ""))
layer.ras <-fasterize::fasterize(sf= spp, raster = ProvRast , field = "bclcs_level_4")
writeRaster(layer.ras, file="bcovgrp.tif", format="GTiff", overwrite=TRUE)

library(data.table)
#convert each to a data.table
cc<-raster("crown_closure.tif")
cc.matrix<-raster::as.matrix(cc)#get the cost surface as a matrix using the raster package
cc_dt<-c(t(cc.matrix)) #transpose then vectorize which matches the same order as adj
cc_dt<-data.table(cc_dt)

spp<-raster("bcovgrp.tif")
spp.matrix<-raster::as.matrix(spp)#get the cost surface as a matrix using the raster package
spp_dt<-c(t(spp.matrix)) #transpose then vectorize which matches the same order as adj
spp_dt<-data.table(spp_dt)


dt<-cbind(spp_dt, cc_dt)
rm(cc.matrix)
rm(cc_dt)
rm(spp)
rm(cc)
rm(spp.matrix)
rm(spp_dt)
gc()

dt$id<-as.integer(row.names(dt))

dt2<-dt[complete.cases(dt)]
#calc the mahalanobis distance
dt2$m_dist <- mahalanobis(dt2[, 1:2], colMeans(dt2[, 1:2]), cov(dt2[, 1:2]))
gc()

out<-merge(dt[,3],dt2, by.x = "id", by.y = "id", all= TRUE)
bcovgrp<-raster("bcovgrp.tif")
ras.out<-bcovgrp
ras.out[]<- out$m_dist
plot(ras.out)
writeRaster(ras.out, file="similar.tif", format="GTiff", overwrite=TRUE)
