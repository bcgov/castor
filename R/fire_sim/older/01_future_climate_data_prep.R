#Information about MPI-ESM1-2-HR from http://www.glisaclimate.org/model-inventory/max-planck-institute-for-meteorology-earth-system-model-mr

# Temperature
# Mean Temperature Output Name: tas
# Mean Temperature Temporal Frequency: Daily
# Min/Max Temperature Output Name: tasmin/tasmax
# Min/Max Temperature Temporal Frequency: Daily
# Temperature Units: Kelvin
# 
# Precipitation
# Total Precipitation Output Name: pr
# Total Precipitation Temporal Frequency: Daily
# Convective Precipitation Output Name: prc
# Convective Precipitation Temporal Frequency: Daily
# Precipitation Units: kg m-2 s-1
# 
# Sea Level Pressure
# Sea Level Pressure Output Name: psl
# Sea Level Pressure Temporal Frequency: Daily
# Sea Level Pressure Units: Pascal (Pa)
# 
# Wind
# Wind Output Name: uas/vas
# Wind Temporal Frequency: Daily
# Wind Speed Units: m/s
# 
# Snow
# Snow Depth Output Name: snd
# Snow Depth Temporal Frequency: Monthly
# Snow Depth Units: meters
# Snowfall Flux Output Name: prsn
# Snowfall Flux Temporal Frequency: Daily
# Snowfall Flux Units: kg m-2 s-1



library(ncdf4) # package for netcdf manipulation
library(raster) # package for raster manipulation
library(rgdal) # package for geospatial analysis
library(ggplot2) # package for plotting
library(chron)

# set path and filename
ncrefpath <- "D:\\Fire\\fire_data\\raw_data\\Future_climate\\"
ncrefname <- "tasmax_mClimMean_PRISM_historical_19710101-20001231.nc"  
ncfrefname <- paste(ncrefpath, ncrefname, ".nc", sep="")
dname <- "tmax"  

#### REFERENCE DATA make this into a csv file ####
ncin_ref <- nc_open(ncfrefname)
print(ncin_ref)

# get longitude and latitude
lon <- ncvar_get(ncin_ref,"lon")
nlon <- dim(lon)
lat <- ncvar_get(ncin_ref,"lat")
nlat <- dim(lat)
time <- ncvar_get(ncin_ref,"time")
tunits <- ncatt_get(ncin_ref,"time","units")
nt <- dim(time)
# the time values are days since 01/01/1970
# convert time -- split the time units string into fields
tustr <- strsplit(tunits$value, " ")
tdstr <- strsplit(unlist(tustr)[3], "-")
tmonth <- as.integer(unlist(tdstr)[2])
tday <- as.integer(unlist(tdstr)[3])
tyear <- as.integer(unlist(tdstr)[1])
chron(time,origin=c(tmonth, tday, tyear))

tmax_reference_array <- ncvar_get(ncin_ref, "tmax") # store the data in a 3-dimensional array
# first change mising values in NA
fillvalue <- ncatt_get(ncin_ref, "tmax", "_FillValue")
tmax_reference_array[tmax_reference_array == fillvalue$value] <- NA
length(na.omit(as.vector(tmax_reference_array[,,1])))
dim(tmax_reference_array)

nc_close(ncin_ref) # close the nc file

# Plot Jan Tmax values (1st slice)
m=1
tmax.slice.ref <- tmax_reference_array[, , m] 
r <- raster(t(tmax.slice.ref), xmn=min(lon), xmx=max(lon), ymn=min(lat), ymx=max(lat), crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))
r <- flip(r, direction='y')
plot(r)

# create dataframe -- reshape data
# reshape the array into vector
tmax_vec_long <- as.vector(tmax_reference_array)
length(tmax_vec_long)
tmax_mat <- matrix(tmax_vec_long, nrow=nlon*nlat, ncol=nt)
dim(tmax_mat)
head(na.omit(tmax_mat))

# create a dataframe
lonlat <- as.matrix(expand.grid(lon,lat))
tmax_ref_df <- data.frame(cbind(lonlat,tmax_mat))
names(tmax_ref_df) <- c("lon","lat","tmax01","tmax02","tmax03","tmax04","tmax05","tmax06",
                     "tmax07","tmax08","tmax09","tmax10","tmax11","tmax12")
tmax_ref_df$year <- 1985
# options(width=96)
tail(na.omit(tmax_ref_df))

write.csv(tmax_ref_df,"D:\\Fire\\fire_data\\raw_data\\Future_climate\\csv_outputs\\tmax_ref.csv")

##############################
# Make future climate into csv files
##############################

#### Need to write this into a loop ####

# set path and filename
ncpath <- "D:\\Fire\\fire_data\\raw_data\\Future_climate\\MPI-ESM1-2-HR\\"
ncname <- "tasmax_Amon_MPI-ESM1-2-HR_historical_r1i1p1f1_gn_200001-200412"  
ncfname <- paste(ncpath, ncname, ".nc", sep="")
dname <- "tasmax"  # These temperature readings are in Kelvin (C = Kelvin - 273.15)

ncin<- nc_open(ncfname)
print(ncin)

# get longitude and latitude
lon <- ncvar_get(ncin,"lon")
nlon <- dim(lon)
lat <- ncvar_get(ncin,"lat")
nlat <- dim(lat)
time <- ncvar_get(ncin,"time")
tunits <- ncatt_get(ncin,"time","units")
nt <- dim(time)
# the time values are days since 01/01/1970
# convert time -- split the time units string into fields
tustr <- strsplit(tunits$value, " ")
tdstr <- strsplit(unlist(tustr)[3], "-")
tmonth <- as.integer(unlist(tdstr)[2])
tday <- as.integer(unlist(tdstr)[3])
tyear <- as.integer(unlist(tdstr)[1])
chron(time,origin=c(tmonth, tday, tyear))

tmax_array <- ncvar_get(ncin, dname) # store the data in a 3-dimensional array
# first change missing values in NA
fillvalue <- ncatt_get(ncin, dname, "_FillValue")
tmax_array[tmax_array == fillvalue$value] <- NA
length(na.omit(as.vector(tmax_array[,,1])))
dim(tmax_array)

m=1
tmax.slice <- tmax_array[, , m] 
r <- raster(t(tmax.slice), xmn=min(lon), xmx=max(lon), ymn=min(lat), ymx=max(lat), crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))
plot(r)


nc_close(ncif) # close the nc file

# create dataframe -- reshape data
# reshape the array into vector
tmax_vec_long <- as.vector(tmax_array)
length(tmax_vec_long)
tmax_mat <- matrix(tmax_vec_long, nrow=nlon*nlat, ncol=nt)
dim(tmax_mat)
head(na.omit(tmax_mat))

# create a dataframe
lonlat <- as.matrix(expand.grid(lon,lat))
tmax_df <- data.frame(cbind(lonlat,tmax_mat))
names(tmax_df) <- c("lon", "lat", paste0("tmax_", chron(time,origin=c(tmonth, tday, tyear))))
# options(width=96)
tail(na.omit(tmax_df))

write.csv(tmax_df,"D:\\Fire\\fire_data\\raw_data\\Future_climate\\csv_outputs\\tmax_00_04.csv")


##########################################
#### try to get difference between reference layer and each year at raster scale of  the future climate ####
##########################################
#For each GCM, convert simulated values to deviations (anomalies) from the grand-mean reference period climate of multiple historical simulations. 

# one option is to get the ref climate data at the same resolution as the projected climate data and then extract the long lat locations (that need to be same as future climate locations) and then just subtract the values off the regular csv file. I.e. i do all the scale conversions on the reference layer (for now). Later I will do the downscaling of the future layers.

library(sf) 
library(ncdf4)
library(raster)
library(rasterVis)
library(RColorBrewer)

# get outline of BC
prov.bnd <- st_read ( dsn = "T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\admin_boundaries\\province\\gpr_000b11a_e.shp", stringsAsFactors = T)
st_crs(prov.bnd)
prov.bnd <- prov.bnd [prov.bnd$PRENAME == "British Columbia", ] 
bc.bnd <- st_transform (prov.bnd, 3005)
prov.bnd <- as(st_geometry(prov.bnd), Class="Spatial")

ncpath <- "D:\\Fire\\fire_data\\raw_data\\Future_climate\\MPI-ESM1-2-HR\\"
ncname <- "tasmax_Amon_MPI-ESM1-2-HR_historical_r1i1p1f1_gn_200001-200412"  
ncfname <- paste(ncpath, ncname, ".nc", sep="")
dname <- "tasmax"  

#### REFERENCE DATA ####
tmax_raster <- brick(ncfname, varname=dname)
tmax_raster; class(tmax_raster)

tmax_00_01_16<- subset(tmax_raster, 1)-273.15



# rasterVis plot
plt <- levelplot(tmax_00_01_16, margin = F,  pretty=TRUE,
                 main="January temperature")
plt + layer(sp.lines(prov.bnd, col="black", lwd=1.0))


getValues(tmax_00_01_16)



library(sp)
library(sf)
library(rgdal)
library(data.table)
library(here)
library(fasterize)
source (paste0(here(),"/R/functions/R_Postgres.R"))

lu<-getSpatialQuery("SELECT wkb_geometry 
FROM public.rmp_lu_sp_polygon limit 1")

tmax_ref_sf <- st_as_sf(x = tmax_ref_df, 
                        coords = c("lon", "lat"),
                        crs = st_crs(lu)$proj4string)
tmax_ref_sp <- as(tmax_ref_sf, "Spatial")

r<- raster(tmax_ref_sf)
rast.tmax05_ref<-fasterize(tmax_ref_sp, r, field="tmax05")
plot(r)


ProvRast <- raster(
  nrows = 15744, ncols = 17216, xmn = 159587.5, xmx = 1881187.5, ymn = 173787.5, ymx = 1748187.5, 
  crs = st_crs(lu)$proj4string, resolution = c(800, 800), vals = 0
)

#Rasterize the average retention targets
art.ras<-fasterize::fasterize(sf=spdf , raster = ProvRast , field = "art_fid")




coordinates(na.omit(tmax_ref_df))

#getting long lat info
#geo.prj <- "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0" 
tmax_ref_df1 <- st_transform(tmax_ref_df, crs = "+proj=longlat +datum=NAD83 / BC Albers +no_defs")
st_crs(fire_igni_bec1)


proj4string(tmax_ref_df)=CRS("+init=epsg:4326") # set it to lat-long
pts = spTransform(pts,CRS("insert your proj4 string here"))



#### Tmax for future periods ####

tmax_00_04_1<-nc_open('D:\\Fire\\fire_data\\raw_data\\Future_climate\\MPI-ESM1-2-HR\\tasmax_Amon_MPI-ESM1-2-HR_historical_r1i1p1f1_gn_200001-200412.nc')
tmax_00_04_1_array <- ncvar_get(tmax_00_04_1, "tasmax") # store the data in a 3-dimensional array
# first change mising values in NA
fillvalue <- ncatt_get(tmax_00_04_1, "tasmax", "_FillValue")
tmax_00_04_1_array[tmax_00_04_1_array == fillvalue$value] <- NA

tmax_00_04_1_slice <- tmax_00_04_1_array[, , 1] 
r <- raster(t(tmax_00_04_1_slice), xmn=min(lon), xmx=max(lon), ymn=min(lat), ymx=max(lat), crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))
plot(r)







tmax_00_04_2<-nc_open('D:\\Fire\\fire_data\\raw_data\\Future_climate\\MPI-ESM1-2-HR\\tasmax_Amon_MPI-ESM1-2-HR_historical_r2i1p1f1_gn_200001-200412.nc')
tmax_00_04_3<-nc_open('D:\\Fire\\fire_data\\raw_data\\Future_climate\\MPI-ESM1-2-HR\\tasmax_Amon_MPI-ESM1-2-HR_historical_r3i1p1f1_gn_200001-200412.nc')
tmax_00_04_4<-nc_open('D:\\Fire\\fire_data\\raw_data\\Future_climate\\MPI-ESM1-2-HR\\tasmax_Amon_MPI-ESM1-2-HR_historical_r4i1p1f1_gn_200001-200412.nc')



# Save the print(nc) dump to a text file
sink('C:\\Users\\ekleynha\\Downloads\\tasmax_mClimMean_PRISM_historical_19710101-20001231.txt')
print(tmax_reference)
sink()
  
lon <- ncvar_get(nc_data, "lon")
lat <- ncvar_get(nc_data, "lat", verbose = F)
t <- ncvar_get(nc_data, "time")
tmax.array <- ncvar_get(nc_data, "tmax") # store the data in a 3-dimensional array
dim(tmax.array) 

# the time values are days since 01/01/1970
# 5493 = 15 Jan 1985
# 5524 = 15 Feb 1985
# 5552 = 15 March 1985
# 5583 = 15 April 1985

fillvalue <- ncatt_get(nc_data, "tmax", "_FillValue")
fillvalue

# replace all those pesky fill values with the R-standard ‘NA
tmax.array[tmax.array == fillvalue$value] <- NA
tmax.slice <- tmax.array[, , 1] 
r <- raster(t(tmax.slice), xmn=min(lon), xmx=max(lon), ymn=min(lat), ymx=max(lat), crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))
r <- flip(r, direction='y')
plot(r)

# create raster brick to get time series data at the same location
r_brick <- brick(tmax.array, xmn=min(lat), xmx=max(lat), ymn=min(lon), ymx=max(lon), crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))

# note that you may have to play around with the transpose (the t() function) and flip() before the data are oriented correctly. In this example, the netcdf file recorded latitude on the X and longitude on the Y, so both a transpose and a flip in the y direction were required.
r_brick <- flip(t(r_brick), direction='y')



tmax_reference <- nc_open('C:\\Users\\ekleynha\\Downloads\\tasmax_mClimMean_PRISM_historical_19710101-20001231.nc.nc')

tmax_reference_array <- ncvar_get(tmax_reference, "tmax") # store the data in a 3-dimensional array
# first change mising values in NA
fillvalue <- ncatt_get(tmax_reference, "tmax", "_FillValue")
tmax_reference_array[tmax_reference_array == fillvalue$value] <- NA

tmax.slice.ref <- tmax_reference_array[, , 1] 
r <- raster(t(tmax.slice.ref), xmn=min(lon), xmx=max(lon), ymn=min(lat), ymx=max(lat), crs=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0"))
r <- flip(r, direction='y')
plot(r)
