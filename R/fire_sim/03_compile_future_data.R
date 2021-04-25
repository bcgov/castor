# Assemble future data for province. Im going to do this at a scale of 800 x 800m. This is what Colin suggested was about the smallest size that would work for the climate data. He thought going smaller than this was not a great idea. I can always scale it smaller later through interpolation or something.

# get outline of BC
prov.bnd <- st_read ( dsn = "T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\admin_boundaries\\province\\gpr_000b11a_e.shp", stringsAsFactors = T)
st_crs(prov.bnd)
prov.bnd <- prov.bnd [prov.bnd$PRENAME == "British Columbia", ]
prov.bnd <- as(st_geometry(prov.bnd), Class="Spatial")


#### REFERENCE DATA ####
ncrefpath <- "D:\\Fire\\fire_data\\raw_data\\Future_climate\\"
ncrefname <- "tasmax_mClimMean_PRISM_historical_19710101-20001231.nc"  
ncfrefname <- paste(ncrefpath, ncrefname, ".nc", sep="")
dname <- "tmax"    
tmax_ref_raster <- brick(ncfrefname, varname=dname)
tmax_ref_raster; class(tmax_ref_raster)

# Get lat long locations of center of each pixel in reference climate
tmax_ref_01 <- raster(tmax_ref_raster, layer=1)
data_matrix <- rasterToPoints(tmax_ref_01, spatial=TRUE)
proj4string(data_matrix)
sppts <- spTransform(data_matrix, CRS("+proj=longlat +datum=WGS84 +no_defs"))

# EXTRACT REFERENCE DATA AT TARGET POINTS
tmax_ref_raster_croped<- crop(tmax_ref_raster, prov.bnd)
tmax_ref_pts <- extract(tmax_ref_raster_croped, sppts, method="simple")
tmax_ref_pts_df <- as.data.frame(tmax_ref_pts)
tmax_ref_pts_df<- cbind(as.data.frame(sppts)[2:3], tmax_ref_pts_df)
tmax_ref_pts_df <- tmax_ref_pts_df %>% dplyr::rename(lon=x, lat=y)
dim(tmax_ref_pts_df)


# step 1: gather climate data for every 800 x 800m pixel with in BC from now to 2100. 

dirs <- list.dirs("D:\\Fire\\fire_data\\raw_data\\Future_climate\\outputs")
gcms <- unique(sapply(strsplit(dirs, "/"), "[", 2))
select <- c(4)
gcms[select]

#process the climate elements
gcm <- gcms[4]
dir <- paste("D:\\Fire\\fire_data\\raw_data\\Future_climate\\outputs", gcm, sep="\\")
files <- list.files(dir)
element.list <- sapply(strsplit(files, "_"), "[", 1)
elements <- unique(element.list)
year.list <- sapply(strsplit(files, "_"), "[", 4)
years<- unique(sapply(strsplit(year.list, "[.]"),"[", 1))
ripf.list <- sapply(strsplit(files, "_"), "[", 3)
scenario.list<-sapply(strsplit(files, "_"), "[", 2)
run.list <- paste(scenario.list, ripf.list, sep="_")
runs2 <- unique(run.list)



element=elements[1]
for(element in elements){
  files.element <- files[grep(element,files)] # get all tasmax/tasmin/pr files from the specific GCM run  
  for(year in 1:length(years)){
    files.years<-files.element[grep(years[year], files.element)] # get the 
    #did this rather than stack import becuase it preserves the variable (month) names
    temp2 <- brick(paste(dir, files.years[1], sep="\\"))
    #temp <- if(year==1) temp2 else brick(c(temp, temp2))
    
    #print(year)
  }
}

