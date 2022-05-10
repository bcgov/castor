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
prov.bnd <- as(st_geometry(prov.bnd), Class="Spatial")

#### FUTURE CLIMATE DATA ####
ncpath <- "D:\\Fire\\fire_data\\raw_data\\Future_climate\\MPI-ESM1-2-HR\\"
ncname <- "tasmax_Amon_MPI-ESM1-2-HR_historical_r1i1p1f1_gn_200001-200412"  
ncfname <- paste(ncpath, ncname, ".nc", sep="")
dname <- "tasmax"  
tmax_raster <- brick(ncfname, varname=dname)
tmax_raster; class(tmax_raster)
tmax_raster_c<- tmax_raster - 273.15 # temperature is in Kelvin so converting it to C


# crop Future Data to BC extent
tmax_raster_c <- crop(tmax_raster_c, prov.bnd)

# Visualize one layer of the future climate layer
# rasterVis plot
tmax_00_01_16 <- raster(tmax_raster_c, layer=1)
plt <- levelplot(tmax_00_01_16, margin = F,  pretty=TRUE,
                 main="January temperature")
plt1<- plt + layer(sp.lines(prov.bnd, col="black", lwd=1.0))
plt1

# Get lat long locations of center of each pixel
data_matrix <- rasterToPoints(tmax_00_01_16, spatial=TRUE)
proj4string(data_matrix)
sppts <- spTransform(data_matrix, CRS("+proj=longlat +datum=WGS84 +no_defs"))

# plot to check points seem ok
plt1 + layer(sp.points(sppts, col="blue", pch=16, cex=0.5)) 

#### REFERENCE DATA ####
ncrefpath <- "D:\\Fire\\fire_data\\raw_data\\Future_climate\\"
ncrefname <- "tasmax_mClimMean_PRISM_historical_19710101-20001231.nc"  
ncfrefname <- paste(ncrefpath, ncrefname, ".nc", sep="")
dname <- "tmax"    
tmax_ref_raster <- brick(ncfrefname, varname=dname)
tmax_ref_raster; class(tmax_ref_raster)

# crop reference Data to BC extent
tmax_ref_raster <- crop(tmax_ref_raster, prov.bnd)

# Visualize one layer of the reference climate layer
# rasterVis plot
tmax_ref_01 <- raster(tmax_ref_raster, layer=1)
plt <- levelplot(tmax_ref_01, margin = F,  pretty=TRUE,
                 main="January temperature")
plt + layer(sp.lines(prov.bnd, col="black", lwd=1.0)) 
# Now plot future climate raster points on top of reference climate map
plt + layer(sp.points(sppts, col="blue", pch=16, cex=0.5)) 

# EXTRACT REFERENCE DATA AT TARGET POINTS
tmax_ref_pts <- extract(tmax_ref_raster, sppts, method="simple")
class(tmax_ref_pts)

tmax_ref_pts_df <- as.data.frame(tmax_ref_pts)
tmax_ref_pts_df<- cbind(as.data.frame(sppts)[2:3], tmax_ref_pts_df)

tmax_ref_pts_df <- tmax_ref_pts_df %>% dplyr::rename(lon=x, lat=y)
dim(tmax_ref_pts_df)

##############################################################
# 2.	For each GCM, convert simulated values to deviations (anomalies) from the grand-mean reference period climate of multiple historical simulations. 
# a.	Degrees Celsius for temperature and percentage change for precipitation

# make the future climate data into a df
future_tmax_pts <- rasterToPoints(tmax_raster_c, spatial=TRUE)
future_tmax_pts<- as.data.frame(future_tmax_pts)
dim(future_tmax_pts)

# joining reference df and future climate df pts together so that I can subtract the reference pts from the future pts
ref_future_tmax_pts<- cbind(tmax_ref_pts_df,future_tmax_pts)
ref_future_tmax_pts<-na.omit(ref_future_tmax_pts)
dim(ref_future_tmax_pts)

# # automate this process
# ref_future_tmax_pts$tmax_01_2000<- ref_future_tmax_pts[15]-ref_future_tmax_pts[3]
# ref_future_tmax_pts$tmax_01_2000<- ref_future_tmax_pts[15]-ref_future_tmax_pts[3]

ref_climate<-rep(3:14,5)
future_climate<- 15:74

month<- rep(1:12, 5)
year<- c(rep("2000", 12), rep("2001", 12), rep("2002", 12), rep("2003", 12), rep("2004",12))

for(i in 1:length(ref_climate)){
  ref_future_tmax_pts[, ncol(ref_future_tmax_pts) + 1] <- ref_future_tmax_pts[future_climate[i]]-ref_future_tmax_pts[ref_climate[i]]
  names(ref_future_tmax_pts)[ncol(ref_future_tmax_pts)] <- paste("delta", "tmax",month[i], year[i], sep="_")
}

# Check that the values that are being created make sense!!!