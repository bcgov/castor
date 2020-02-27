#===========================================
# Data sources and description of plan
#===========================================

# Tylers sampled points are here: C:\\Work\\caribou\\clus_data\\rsf_locations_caribou_bc.gpkg
# These are telemetry points for individual animals sampled per year. Using these telemetry points (his 1's) per year Tyler calculate the home range for each animal for every year and then sampled points within these areas (his 0's). Im using just the zeros but I need to use them per year.
#Tylers zeros were sampled from home ranges he calculated and these home ranges can be found here: VIC/HTS/ANA/PROJECTS/CLUS/Data/caribou/telemetry_habitat_model_20180904/homeranges.
 # I then need to compare Tylers home ranges to the ones on Data BC and sample points per year arounds Tylers home ranges 
# I must download the caribou home ranges from DataBC and then for every year sample points within the home range and within a 25km buffer zone that were not "used" (Tylers's zero's). These will be my ones. For now Ill analyze things at the herd scale i.e. all Tylers' zeros which I will convert to ones versus all my points per year. 
#For each point i need to calculate distance to nearest cutblock and road as a measure of disturbance.

#How Tyler calculated this distance can be found in 03_caribou_habitat_model_telemetry_data_prep_doc.Rmd line 5643


require (RPostgreSQL)
require(rgdal)
require(dplyr)
require(plyr)

# Cutblock data can be found here: PROJECTS/CLUS/DATA/cutblocks/cutblocks.tif
rsf_locations_caribou_bc<-st_read(dsn="C:\\Work\\caribou\\clus_data\\rsf_locations_caribou_bc.shp", stringsAsFactors = T)

# Filter out Tyler's zero's and convert them to point type 1 i.e. used locations
points_used <- rsf_locations_caribou_bc %>% filter(pttype==0)
points_used$pttype<-1 


# Read in each home range location and make the file name the "polygon name".
x<-list.files("T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\caribou\\telemetry_habitat_model_20180904\\homeranges", pattern=".shp", all.files=FALSE, full.names=FALSE)
y<-gsub(".shp","",x)

setwd('T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\caribou\\telemetry_habitat_model_20180904\\homeranges')
for (i in 1:length(x)){
  assign(paste0(y[i]),st_read (dsn=paste0(x[i])))
}

setwd('C://Work//caribou//clus_data')

# join all spatial files together
homerange.all <- rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (rbind (hr_ewinter_du6_h500, hr_lwinter_du6_h500), hr_summer_du6_h500), hr_lwinter_du7_h500), hr_ewinter_du7_muskwa_SCEK007b_h500), hr_ewinter_du7_muskwa_41241_h500), hr_ewinter_du7_muskwa_41247_h500), hr_ewinter_du7_muskwa_41248_h500), hr_ewinter_du7_muskwa_41250_h500), hr_ewinter_du7_muskwa_41251_h500), hr_ewinter_du7_ne_h500), hr_ewinter_du7_south_h500), hr_summer_du7_pink_41243_h500), hr_summer_du7_pink_41249_h500), hr_summer_du7_pink_41253_h500), hr_summer_du7_pink_41255_h500), hr_summer_du7_pink_41258_h500), hr_summer_du7_pink_41262_h500), hr_summer_du7_spat_C298T_h500), hr_summer_du7_spat_C301T_h500), hr_summer_du7_spat_C303T_h500), hr_summer_du7_ne_h500), hr_summer_du7_south_h500), hr_ewinter_du8_h500), hr_lwinter_du8_h500), hr_summer_du8_h500), hr_ewinter_du9_h500), hr_lwinter_du9_h500), hr_summer_du9_h500)


# pull out year, season and other id info and put it in separate columns
homerange.all2 <- homerange.all %>% separate(id,c("du","season","individual","year"), sep="_")

homerange.all2 %>% filter(du=="du6" & year==2012)

# Read in BC herd boundaries

# Load caribou range boundaries to identify ranges and Ecotypes 
caribou.range <- st_read (dsn = "C:\\Work\\caribou\\clus_data\\BC_Caribou_Herds\\GCPB_CARIBOU_POPULATION_SP\\GCBP_CARIB_polygon.shp", stringsAsFactors = T)
# remove Haida Gwaii
caribou.range <- caribou.range [caribou.range$OBJECTID != 138, ]
# NOTE: the polygon ID was obtained using ArcGIS; not sure how to get that using R 

prov.bnd <- st_read ( dsn = "T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\admin_boundaries\\province\\gpr_000b11a_e.shp", stringsAsFactors = T)
prov.bnd <- st_transform (prov.bnd, 3005)
prov.bnd <- prov.bnd [prov.bnd$PRENAME == "British Columbia", ]  
caribou.range <- caribou.range [prov.bnd, ] # clip locations to BC





sample.pts.boreal <- spsample (caribou.boreal.sa, cellsize = c (2000, 2000), type = "regular")
sample.pts.mtn <- spsample (caribou.mtn.sa, cellsize = c (2000, 2000), type = "regular")
