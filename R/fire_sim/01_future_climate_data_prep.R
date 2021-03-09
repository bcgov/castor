library(ncdf4) # package for netcdf manipulation
library(raster) # package for raster manipulation
library(rgdal) # package for geospatial analysis
library(ggplot2) # package for plotting

nc_data <- nc_open('C:\\Users\\ekleynha\\Downloads\\tasmax_mClimMean_PRISM_historical_19710101-20001231.nc.nc')

# Save the print(nc) dump to a text file
sink('C:\\Users\\ekleynha\\Downloads\\tasmax_mClimMean_PRISM_historical_19710101-20001231.txt')
print(nc_data)
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
