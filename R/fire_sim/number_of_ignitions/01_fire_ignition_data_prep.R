source(here::here("R/functions/R_Postgres.R"))
library(data.table)
library(sf)
library(tidyverse)
library(rgeos)
library(rpostgis)
library(keyring)
library(bcdata)

# get ignition data
ignit<-try(
  bcdc_query_geodata("WHSE_LAND_AND_NATURAL_RESOURCE.PROT_HISTORICAL_INCIDENTS_SP") %>%
    filter(FIRE_YEAR > 2001) %>%
    filter(FIRE_TYPE == "Fire") %>%
    filter(CURRENT_SIZE >= 10) %>%
    filter(FIRE_CAUSE >= "Lightning") %>%
    collect()
)


head(ignit)
ignition2 <- st_transform (ignit, 3005)


# create provincial raster with grid of speficied size
restest = c(10000, 10000)

prov.rast <- raster::raster ( # standardized provincial raster with no data in it
  nrows = 15744, ncols = 17216,
  xmn = 159587.5, xmx = 1881187.5,
  ymn = 173787.5, ymx = 1748187.5,
  crs = "+proj=aea +lat_0=45 +lon_0=-126 +lat_1=50 +lat_2=58.5 +x_0=1000000 +y_0=0 +datum=NAD83 +units=m +no_defs",
  resolution = restest,
  vals = 0)

pixels <- data.table(V1 = as.integer(prov.rast[]))
pixels[, pixelid := seq_len(.N)]
setorder(pixels, "pixelid")#sort the pixels table so that pixelid is in order.

prov.rast[]<-pixels$pixelid

#---------------------#
#Get the FRT----
#---------------------#

frt<-getSpatialQuery("SELECT * FROM frt_canada")
ras.frt <- fasterize::fasterize (frt, prov.rast, field = "Cluster")

if(terra::ext(prov.rast) == terra::ext(ras.frt)){ # need to check that each of the extents are the same
  pixels<-cbind(pixels, data.table(frt= as.numeric(ras.frt[])))
  rm(ras.frt)
  gc()
}else{
  stop(paste0("ERROR: extents are not the same check -"))
}

# Get Elevation and adjust its resolution to match 10 000  x 10 000m
DEM <- raster("T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CASTOR\\Data\\dem\\all_bc\\dem.tif")

#aggregate from 100x100 resolution to 10 000 10 000 (factor = 1000)
Dem_agregated <- aggregate(DEM, fact=100, fun=mean, na.rm=TRUE)
Dem_agragated_2<-crop(Dem_agregated, prov.rast) # the aggregated raster is a little larger than the prov.raster so clip it so their extents match.
res(Dem_agregated)
plot(Dem_agragated_2)

if(terra::ext(prov.rast) == terra::ext(Dem_agragated_2)){#need to check that each of the extents are the same
  pixels <- cbind(pixels, data.table(dem = as.integer(Dem_agragated_2[])))
  rm(DEM)
  gc()
}else{
  stop(paste0("ERROR: extents are not the same check -"))
}

######################################################
#Join provincial raster data to the ignition data
# try extract pixel id's of each fire location and cbind it to the igntion data

pixelid <- terra::extract(prov.rast, ignition2)
ignition2<-cbind(ignition2, pixelid)
ignition2<-data.table(ignition2)

# LIghtning fires
lightning<-ignition2[FIRE_CAUSE=="Lightning", .(count=.N), by = c("pixelid", "FIRE_YEAR")]
human<-ignition2[FIRE_CAUSE=="Person", .(count=.N), by = c("pixelid", "FIRE_YEAR")]
all<-ignition2[FIRE_TYPE=="Fire", .(count=.N), by = c("pixelid", "FIRE_YEAR")]

# make a table of the pixel ids with year and then slot in the lightning ignition data
pixels[,FIRE_YEAR := 2002]
pixels02<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2003]
pixels03<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2004]
pixels04<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2005]
pixels05<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2006]
pixels06<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2007]
pixels07<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2008]
pixels08<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2009]
pixels09<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2010]
pixels10<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2011]
pixels11<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2012]
pixels12<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2013]
pixels13<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2014]
pixels14<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2015]
pixels15<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2016]
pixels16<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2017]
pixels17<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2018]
pixels18<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2019]
pixels19<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2020]
pixels20<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2021]
pixels21<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]
pixels[,FIRE_YEAR := 2022]
pixels22<-pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")]

pixels_by_yr<-do.call("rbind", list(pixels02, pixels03, pixels04, pixels05, pixels06, pixels07, pixels08, pixels09, pixels10, pixels11, pixels12, pixels13, pixels14,pixels15, pixels16, pixels17, pixels18, pixels19, pixels20, pixels21, pixels22))


pixels_by_yr<-merge(pixels_by_yr, lightning, by.x=c("pixelid", "FIRE_YEAR"), by.y=c("pixelid", "FIRE_YEAR"), all.x=TRUE)

pixels_by_yr[is.na(count), count:=0]

# look at it
setorder(pixels_by_yr, "pixelid")
prov.rast[]<-pixels_by_yr[FIRE_YEAR=="2002", count]
plot(prov.rast)
hist(pixels_by_yr[FIRE_YEAR=="2002", count])


prov.rast[]<-pixels_by_yr[FIRE_YEAR=="2018", count]
plot(prov.rast)
hist(pixels_by_yr[FIRE_YEAR=="2018", count])

# Lots of zeros. How is it by FRT does that help for some areas i.e. reduce zero inflation

ggplot(pixels_by_yr[frt=="15"], aes(x=count))+
  geom_histogram()+
  facet_wrap(FIRE_YEAR ~ .)




#############################
###Now get vegetation, climate data to go with it
##############################

