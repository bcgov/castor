library(raster)
library(data.table)
library(sf)
library(tidyverse)
library(rgeos)

source(here::here("R/functions/R_Postgres.R"))

#Get dummy layer for projection (too lazy to write it) 
lyr<-getSpatialQuery(paste("SELECT geom FROM public.gcbp_carib_polygon"))

#Make an empty provincial raster aligned with hectares BC
ProvRast <- raster(
  nrows = 15744, ncols = 17216, xmn = 159587.5, xmx = 1881187.5, ymn = 173787.5, ymx = 1748187.5, 
  crs = st_crs(lyr)$proj4string, resolution = c(100, 100), vals = 0
) # from https://github.com/bcgov/bc-raster-roads/blob/master/03_analysis.R


forest.tenure<-getSpatialQuery("SELECT tsa_name, tsa_number, wkb_geometry FROM study_area_compart where tsa_name in ('MacKenzie TSA')")
forest.tenure<-st_transform(forest.tenure, 3005)

layer<-getSpatialQuery("SELECT feature_id, geometry FROM public.veg_comp_lyr_r1_poly2018")
veg <- st_transform (layer, 3005)
veg.mckenzie<-st_intersection(forest.tenure,veg)


forest.tenure.ras <-fasterize::fasterize(sf= forest.tenure, raster = ProvRast , field = "tsa_number")


point<-sampleRandom(forest.tenure.ras, size=1)
plot(forest.tenure.ras)
plot(point)

st_crs(forest.tenure)
plot(forest.tenure) #check 
forest.area<-sum(st_area(forest.tenure))  



######################
# find a vegetation layer to quantify the amount of forest i.e. burnable habitat. Presumably fires have only occured in forest habitat (check)

# This does not work, it runs out of memory! also tired to query this layer according to TSA but was not having luck. This is what I tried to do: 
# SELECT objectid, coast_interior_cd, bclcs_level_2, shape 
# FROM veg_comp_lyr_r1_poly2019 
# WHERE objectid IN (SELECT objectid, tsa_number FROM vri_tsa_att WHERE tsa_number = '16') but it turns out vri_tsa_att.tsa_number does not have any TSA numbers in it so Im not sure what to do. Will ask Kyle!

veg<-getSpatialQuery("SELECT bclcs_level_2, bclcs_level_3, polygon_area, geometry FROM public.vdyp_vri2018")
veg <- st_transform (veg, 3005)
veg.mckenzie<-st_intersection(forest.tenure,veg)
st_crs(veg)
#####################

### Import fire history layer obtained from (https://catalogue.data.gov.bc.ca/dataset/fire-perimeters-historical : WHSE_LAND_AND_NATURAL_RESOURCE_ PROT_HISTORICAL_FIRE_POLYS_SP)


fire.hist<-sf::st_read(dsn="C:\\work\\caribou\\clus_data\\Fire\\Fire_sim_data\\PROT_HISTORICAL_FIRE_POLYS_SP\\H_FIRE_PLY_polygon.shp")
fire.hist2 <- st_transform (fire.hist, 3005)
st_crs(fire.hist2)
plot(fire.hist2$FIRE_YEAR,fire.hist2$AREA_SQM)
p <- ggplot(fire.hist2, aes(x=log(AREA_SQM))) + 
  geom_histogram(aes(y=..density..), colour="black", fill="white")+
  geom_density(fill="lightblue", alpha=0.3) +
  xlim(0,21)
p


#Clip the fire layer to the MacKenzie TSA
fire.hist.mckenzie<-st_intersection(forest.tenure,fire.hist2)
plot(fire.hist.mckenzie["FIRE_YEAR"])

# density plot of fires in MacKenzie TSA
plot(fire.hist.mckenzie$FIRE_YEAR,fire.hist.mckenzie$AREA_SQM)
p <- ggplot(fire.hist.mckenzie, aes(x=log(AREA_SQM))) + 
  geom_histogram(aes(y=..density..), colour="black", fill="white")+
  geom_density(fill="lightblue", alpha=0.3) +
  xlim(0,25)
p


# fit a distribution to the fire data
library(fitdistrplus)
descdist((log(fire.hist.mckenzie$AREA_SQM)), boot=500)
fit_norm<-fitdist(log(fire.hist.mckenzie$AREA_SQM),"lnorm")
denscomp(fit_norm)
                  
study.years<-max(fire.hist.mckenzie$FIRE_YEAR)-min(fire.hist.mckenzie$FIRE_YEAR) # number of years on record of fire
fire.hist.area<-sum(st_area(fire.hist.mckenzie$wkb_geometry))
Percent.area.burned<-(fire.hist.area/10000)/3343918 # REPLACE THIS VALUE WITH TOTAL FOREST AREA
ave.area.burned.per.yer<-(fire.hist.area/10000)/study.years
rotation<- 3343918/ave.area.burned.per.yer # forested area / average area burned per year i.e. how long does it take for the entire TSA to burn
annual.rate<-1/rotation

# Sample random location for fire ignition

library(raster)
x<-raster(ncol=10,nrow=10)

x_samp<-sampleRandom(x,size=1)
x[x_samp]<-0
plot(x)






