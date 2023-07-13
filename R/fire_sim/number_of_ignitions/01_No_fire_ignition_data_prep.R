source(here::here("R/functions/R_Postgres.R"))
library(data.table)
library(sf)
library(tidyverse)
library(rgeos)
library(rpostgis)
library(keyring)
library(bcdata)
library(raster)
library(RPostgreSQL)
library(rgdal)
library(sqldf)
library(DBI)
library(sp)

#Simple database connectivity functions to connect to local postgres
getlocalSpatialQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), 
                       host="localhost", 
                       dbname = "postgres", port='5432' ,
                       user="postgres",
                       password= "postgres"
  )
  on.exit(dbDisconnect(conn))
  st_read(conn, query = sql)
}

getLocalTableQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), 
                       host="localhost", 
                       dbname = "postgres", port='5432' ,
                       user="postgres",
                       password= "postgres"
  )
  on.exit(dbDisconnect(conn))
  dbGetQuery(conn, sql)
}


# Here we are trying to do the same as Marchal et al 2017. To estimate the number of ignitions per grid cell. But first I want to determine what grid cell size is the best. 

# get ignition data
ignit<-try(
  bcdc_query_geodata("WHSE_LAND_AND_NATURAL_RESOURCE.PROT_HISTORICAL_INCIDENTS_SP") %>%
    filter(FIRE_YEAR > 2001) %>%
    filter(FIRE_TYPE == "Fire") %>%
    collect()
)

head(ignit)
ignition2 <- st_transform (ignit, 3005)

##### READ THIS #######

# I realized that when I sample the VRI at the scale of the 10x10km grid cell its only giving me one feature_id. Im assuming the value it is giving me is the most common one. But the problem is that I actually want to determine the proportion of each vegetation type in the 10x10km grid cell. One solution I thought of was to create my regular raster with a resolution of 100 x 100m. With this raster I sample the vegetation and the climate. then I create a raster with a resolution of 10 x 10km grid cells and I calculate the proportion of each vegetation type using the data collected at the finer resolution. Im having some trouble with this though. Anyway, Im switching back to another project for a little while.


# create regular provincial raster at 100 x 100m resolution
prov.rast <- raster::raster ( # standardized provincial raster with no data in it
  nrows = 15744, ncols = 17216,
  xmn = 159587.5, xmx = 1881187.5,
  ymn = 173787.5, ymx = 1748187.5,
  crs = "+proj=aea +lat_0=45 +lon_0=-126 +lat_1=50 +lat_2=58.5 +x_0=1000000 +y_0=0 +datum=NAD83 +units=m +no_defs",
  resolution = c(100,100),
  vals = 0)

pixels <- data.table(V1 = as.integer(prov.rast[]))
pixels[, pixelid := seq_len(.N)]
setorder(pixels, "pixelid")#sort the pixels table so that pixelid is in order.

prov.rast[]<-pixels$pixelid


# create provincial raster with grid of larger size e.g. 10km x 10km
restest = c(10000, 10000)

prov.rast_10by10km <- raster::raster ( # standardized provincial raster with no data in it
  xmn = 159587.5, xmx = 1859587.5,
  ymn = 148187.5, ymx = 1748187.5,
  crs = "+proj=aea +lat_0=45 +lon_0=-126 +lat_1=50 +lat_2=58.5 +x_0=1000000 +y_0=0 +datum=NAD83 +units=m +no_defs",
  resolution = restest,
  vals = 0)

pixels2 <- data.table(V2 = as.character(prov.rast_10by10km[]))
pixels2[, pixelid2 := seq_len(.N)]
setorder(pixels2, "pixelid2")#sort the pixels table so that pixelid is in order.

prov.rast_10by10km[]<-pixels2$pixelid2
prov.rast_reduced<-crop(prov.rast_10by10km, prov.rast, touches=TRUE, extend=TRUE)

pol <- rasterToPolygons(prov.rast_10by10km, fun=function(x){x>0})

ras.prov.rast_10km <- fasterize::fasterize (pol, prov.rast, field = "layer")

x<-resample(prov.rast, prov.rast_10by10km, method=near)

Prov_rast_10x10_extent_match<-crop(prov.rast_10by10km, prov.rast) # the aggregated raster is a little larger than the prov.raster so clip it so their extents match.
#res(Dem_agregated)
#plot(Dem_agragated_2)

# combine pixelid's of the 100mx100m pixel size raster with that of the 10x10km raster.

if(terra::ext(prov.rast) == terra::ext(Prov_rast_10x10_extent_match)){ # need to check that each of the extents are the same
  pixels<-cbind(pixels, data.table(frt= as.numeric(prov.rast_10by10km[])))
  rm(ras.frt, frt)
  gc()
}else{
  stop(paste0("ERROR: extents are not the same check -"))
}








#---------------------#
#Get the FRT----
#---------------------#

frt<-getSpatialQuery("SELECT * FROM frt_canada")
ras.frt <- fasterize::fasterize (frt, prov.rast, field = "Cluster")

if(terra::ext(prov.rast) == terra::ext(ras.frt)){ # need to check that each of the extents are the same
  pixels<-cbind(pixels, data.table(frt= as.numeric(ras.frt[])))
  rm(ras.frt, frt)
  gc()
}else{
  stop(paste0("ERROR: extents are not the same check -"))
}

# Get Elevation and adjust its resolution to match 10 000  x 10 000m
#DEM <- raster("T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CASTOR\\Data\\dem\\all_bc\\dem.tif")

#aggregate from 100x100 resolution to 10 000 10 000 (factor = 1000)
#Dem_agregated <- aggregate(DEM, fact=100, fun=mean, na.rm=TRUE)
#Dem_agragated_2<-crop(Dem_agregated, prov.rast) # the aggregated raster is a little larger than the prov.raster so clip it so their extents match.
#res(Dem_agregated)
#plot(Dem_agragated_2)

# if(terra::ext(prov.rast) == terra::ext(Dem_agragated_2)){#need to check that each of the extents are the same
#   pixels <- cbind(pixels, data.table(dem = as.integer(Dem_agragated_2[])))
#   rm(DEM)
#   gc()
# }else{
#   stop(paste0("ERROR: extents are not the same check -"))
# }

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

years<- 2002:2022
vri_layers<-c("public.vri_2002_geom_fix", "public.vri_2003_geom_fix", "public.vri_2004_geom_fix", "public.vri_2005_geom_fix", "public.vri_2006_geom_fix", "public.vri_2006_geom_fix", "public.vri_2008_geom_fix", "public.vri_2009_geom_fix", "public.vri_2010_geom_fix", "public.vri_2011_geom_fix", "public.vri_2012_geom_fix", "public.vri_2013_geom_fix", "public.vri_2014_geom_fix", "public.vri_2015_geom_fix", "public.vri_2016_geom_fix", "public.vri_2017_geom_fix", "public.vri_2018_geom_fix", "public.vri_2019_geom_fix", "public.vri_2020_geom_fix", "public.vri_2021_geom_fix", "public.vri_2022_geom_fix")

veg_attributes<-c('bclcs_level_1', 'bclcs_level_2', 'bclcs_level_3',  'bclcs_level_5','species_cd_1','species_pct_1','species_cd_2', 'species_pct_2', 'species_cd_3', 'species_pct_3','species_cd_4','species_pct_4', 'species_cd_5', 'species_pct_5', 'species_cd_6', 'species_pct_6')


for (i in 1:length(years)) {

pixels[,FIRE_YEAR := years[i]]
dat<-pixels[, c("pixelid", "FIRE_YEAR", "frt")]
#assign(paste0("pixels_", years[1]), pixels[, c("pixelid", "FIRE_YEAR", "frt", "dem")])

layer<-getlocalSpatialQuery(paste0("SELECT feature_id, geom FROM ", vri_layers[i]))

#plot(layer)
layer.ras <-fasterize::fasterize(sf= layer, raster = prov.rast , field = "feature_id")
rm(layer)
gc()

if(terra::ext(prov.rast) == terra::ext(layer.ras)){#need to check that each of the extents are the same
  dat <- cbind(dat, data.table(feature_id = as.integer(layer.ras[])))
  rm(layer.ras)
  gc()
}else{
  stop(paste0("ERROR: extents are not the same check -"))
}

fids<-unique(dat[!(is.na(feature_id)), feature_id])

attrib_inv<-data.table(getLocalTableQuery(paste0("SELECT " , "feature_id", " as feature_id, ", paste(veg_attributes, collapse = ","), " FROM ", vri_layers[i], " WHERE ", "feature_id" ," IN (", paste(fids, collapse = ","),");" )))
  
  print("...merging with fid") #Merge this with the raster using fid which gives you the primary key -- pixelid
  dat<-merge(x=dat, y=attrib_inv, by.x = "feature_id", by.y = "feature_id", all.x = TRUE) 
  
  assign(paste0("pixels_", years[i]), dat)
  
  rm(dat, attrib_inv, fids)
  gc()
}

pixels_by_yr<-do.call("rbind", list(pixels_2002, pixels_2003, pixels_2004, pixels_2005, pixels_2006, pixels_2007, pixels_2008, pixels_2009, pixels_2010, pixels_2011, pixels_2012, pixels_2013, pixels_2014,pixels_2015, pixels_2016, pixels_2017, pixels_2018, pixels_2019, pixels_2020, pixels_2021, pixels_2022))
  
pixels_by_yr<-merge(pixels_by_yr, lightning, by.x=c("pixelid", "FIRE_YEAR"), by.y=c("pixelid", "FIRE_YEAR"), all.x=TRUE)

pixels_by_yr[is.na(count), count:=0]

pixels_by_yr1<-pixels_by_yr[!is.na(dem),]
pixels_by_yr1<-pixels_by_yr1[!is.na(frt),]

# look at it
setorder(pixels_by_yr1, "pixelid")
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

ggplot(pixels_by_yr1, aes(x=count))+
  geom_histogram()+
  facet_wrap(FIRE_YEAR ~ .)


#############################
###Now get vegetation data
##############################




#Get dummy layer for projection (too lazy to write it) 
lyr<-getSpatialQuery(paste("SELECT geom FROM public.forest_tenure limit 1") )

#Make an empty provincial raster aligned with hectares BC
ProvRast <- raster(
  nrows = 15744, ncols = 17216, xmn = 159587.5, xmx = 1881187.5, ymn = 173787.5, ymx = 1748187.5, 
  crs = st_crs(lyr)$proj4string, resolution = c(100, 100), vals = 0
)

layer<-getSpatialQuery("SELECT feature_id, shape FROM public.veg_comp_lyr_r1_poly2021")

layer.ras <-fasterize::fasterize(sf= layer, raster = ProvRast , field = "feature_id")
rm(layer)
gc()



