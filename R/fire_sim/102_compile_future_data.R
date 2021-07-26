library(raster)
library(data.table)
library(sf)
library(tidyverse)
library(rgeos)
library(dplyr)
library(tidyr)
library(ggplot2)
source(here::here("R/functions/R_Postgres.R"))


# Assemble future data for province. Im going to do this at a scale of 800 x 800m. This is what Colin suggested was about the smallest size that would work for the climate data. He thought going smaller than this was not a great idea. I can always scale it smaller later through interpolation or something.

# Get boundary of the area, e.g. a TSA,  that you are interested in 

#Create a provincial raster
layeraoi<-getSpatialQuery("SELECT * FROM study_area_compart limit 1")

prov.rast <- raster::raster(
  nrows = 15744, ncols = 17216, xmn = 159587.5, xmx = 1881187.5, ymn = 173787.5, ymx = 1748187.5, 
  crs = st_crs(layeraoi)$proj4string, resolution = c(800, 800), vals = 0)

# get area of interest data
forest.tenure<-getSpatialQuery("SELECT tsa_name,tsa_number, wkb_geometry FROM study_area_compart where tsa_name in ('Quesnel TSA')")

forest.tenure2<-forest.tenure %>% group_by ( tsa_name, tsa_number) %>% summarise()
st_crs(forest.tenure2)
plot(forest.tenure2["tsa_name"]) #check 
forest.tenure3<-st_cast(forest.tenure2, "MULTIPOLYGON")

#RAsterize 
ras.forest.tenure <-fasterize::fasterize(st_cast(forest.tenure2, "MULTIPOLYGON"), prov.rast, field = "tsa_number") 
raster::plot(ras.forest.tenure)
# Get lat long locations of center of each pixel in reference climate
data_matrix <- rasterToPoints(ras.forest.tenure, spatial=TRUE)
proj4string(data_matrix)
aoipts <- spTransform(data_matrix, CRS("+proj=aea +lat_0=45 +lon_0=-126 +lat_1=50 +lat_2=58.5 +x_0=1000000 +y_0=0 +datum=NAD83 +units=m +no_defs"))

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

filenames<-list()

element=elements[2]
for(element in elements){
  files.element <- files[grep(element,files)] # get all tasmax/tasmin/pr files from the specific GCM run  
  for(year in 1:length(years)){
    files.years<-files.element[grep(years[year], files.element)] # get the 
    #did this rather than stack import because it preserves the variable (month) names
    temp2 <- brick(paste(dir, files.years[1], sep="\\"))
    temp3 <- projectRaster(temp2,crs = crs(ras.forest.tenure))
    
    # EXTRACT REFERENCE DATA AT TARGET POINTS
    clim_raster_croped<- crop(temp3, extent(forest.tenure3))
    clim_raster_croped <- mask(clim_raster_croped, forest.tenure3)
    #plot(clim_raster_croped[[2]])
    
    clim_ref_pts <- raster::extract(clim_raster_croped, aoipts, df=TRUE)
    clim_ref_pts_df <- as.data.frame(clim_ref_pts)
    #clim_ref_pts1<- cbind(as.data.frame(aoipts)[2:3], clim_ref_pts_df)
    clim_ref_pts2 <- if (year==1) clim_ref_pts_df[,c(1, 5:11)] else clim_ref_pts[,c(5:11)]
    
    temp <- if(year==1) clim_ref_pts2 else cbind(temp, clim_ref_pts2)
    print(year)
  }
  print(element)
  write.csv(temp, paste("D:\\Fire\\fire_data\\raw_data\\Future_climate\\outputs\\", element,"_","Quesnel","_", gcm, "_",years[1],"_",years[length(years)], ".csv", sep=""))
  #assign file names to the work
  #nam1<-paste("sampled_points",element,sep="_") #defining the name
  #assign(nam1,temp)
  #filenames<-append(filenames,nam1)
  
}

# after extracting the climate data for each pixel in the area of interest, I need to reshape the file into long format.

dir <- paste("D:\\Fire\\fire_data\\raw_data\\Future_climate\\outputs", , sep="\\")
files <- list.files(dir)


for(element in elements){
  files.element <- files[grep(element,files)] # get all tasmax/tasmin/pr files from the specific GCM run  
  for(year in 1:length(years))}
    
precip<-read.csv("D:\\Fire\\fire_data\\raw_data\\Future_climate\\outputs\\pr_Quesnel_MPI-ESM1-2-HR_adjusted_values_2001_2100.csv")


years<-substr(names(element))
substr(names(precip),7,8)


