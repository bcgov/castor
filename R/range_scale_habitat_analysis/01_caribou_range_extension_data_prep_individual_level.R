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
require(plyr)
require(dplyr)
require(sf)
require(ggplot2)
require(tidyr)
require(rgeos)
require(sp)
require (kableExtra)
require(snow)
require(tmap)
require(maptools)


rsf_locations_caribou_bc<-st_read(dsn="C:\\Work\\caribou\\clus_data\\rsf_locations_caribou_bc.shp", stringsAsFactors = T)

#-------------------------
#TYLERS SAMPLED POINTS
#-------------------------
# Filter out Tyler's zero's and convert them to point type 1 i.e. used locations
points_used <- rsf_locations_caribou_bc %>% filter(pttype==0)
points_used$pttype<-1 

#-----------------------------------------
#Herd homeranges per year and herd name
#-----------------------------------------

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


#homerange.all does not have the herd name but does have the id of each animal tracked so I join homerange.all to points_used_df to get the herd name into homerange.all.

points_used_df<-st_drop_geometry(points_used)
points_used_df<-distinct(points_used_df[,c("uniqueID","ECOTYPE","HERD_NAME")])
homerange.all1<-merge(homerange.all,points_used_df,by.x="id",by.y="uniqueID",all.x=TRUE)

# pull out year, season and other id info and put it in separate columns
homerange.all1$uniqueID<-homerange.all1$id
homerange.all2 <- homerange.all1 %>% separate(id,c("du","season","individual","year"), sep="_")
homerange.all2 <- st_transform (homerange.all2, 3005)

#--------------------
#BC herd boundaries
#--------------------

# Read in BC herd boundaries
caribou.range <- st_read (dsn = "C:\\Work\\caribou\\clus_data\\BC_Caribou_Herds\\GCPB_CARIBOU_POPULATION_SP\\GCBP_CARIB_polygon.shp", stringsAsFactors = T)
# remove Haida Gwaii
caribou.range <- caribou.range [caribou.range$OBJECTID != 138, ]
caribou.range <- st_transform (caribou.range, 3005)
# NOTE: the polygon ID was obtained using ArcGIS; not sure how to get that using R 

prov.bnd <- st_read ( dsn = "T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\admin_boundaries\\province\\gpr_000b11a_e.shp", stringsAsFactors = T)
prov.bnd <- st_transform (prov.bnd, 3005)
prov.bnd <- prov.bnd [prov.bnd$PRENAME == "British Columbia", ]  

caribou.range.buff.25km<-st_buffer(caribou.range,dist=25000)
caribou.range.buff.25km.sf <- sf::st_as_sf(caribou.range.buff.25km) %>% st_cast("MULTIPOLYGON")

prov.bnd.bc<-sf::st_as_sf(prov.bnd) %>% st_combine() %>% st_sf() #flatten layer
caribou.range.buff.25km.sf.bc<-sf::st_intersection(caribou.range.buff.25km.sf,st_buffer(prov.bnd.bc,0))


# For each year and herd clip out herd locations (Tylers sample areas) from the buffer

years<-c("2008","2009","2010","2011","2012","2013","2014","2015","2016","2017","2018")
herds<-c("Snake-Sahtaneh", "Calendar", "Maxhamish","Parker","Chinchaga","Prophet", "Tweedsmuir","Itcha-Ilgachuz","Charlotte Alplands","Pink Mountain", "Muskwa","Frog","Chase","Spatsizi", "Finlay", "Graham", "Tsenaglode", "Telkwa", "Rainbows", "Kennedy Siding", "Narraway", "Quintette", "Moberly", "Scott", "Burnt Pine", "Hart Ranges", "Nakusp", "South Selkirks")

herds_new_name<-c("Snake_Sahtaneh", "Calendar", "Maxhamish","Parker","Chinchaga","Prophet", "Tweedsmuir","Itcha_Ilgachuz","Charlotte_Alplands","Pink_Mountain", "Muskwa","Frog","Chase","Spatsizi", "Finlay", "Graham", "Tsenaglode", "Telkwa", "Rainbows", "Kennedy_Siding", "Narraway", "Quintette", "Moberly", "Scott", "Burnt_Pine", "Hart_Ranges", "Nakusp", "South_Selkirks") # make herd names simpler as R does not seem to like the "-"

filenames<-list()

# 15 May 2020 Previously I tried sampling points every 750m but my glmer's had really crazy structure and it seems like the structure is coming from something related to the landscape so I decided to test this by sampling points at a different scale. Here I chose to try sampling points every 500m. Fingers crossed this helps.

for (j in 1:length(herds)) {
  
  focal.herd<-caribou.range.buff.25km.sf.bc %>%
    filter(HERD_NAME==herds[j])
  
  #First clip out the bc herd ranges that overlap with the buffer
  foobar<-caribou.range %>% 
    filter(HERD_NAME!=herds[j])
  foobar2<-sf::st_as_sf(foobar) %>% st_combine() %>% st_sf()
  clipped<-sf::st_difference(focal.herd,st_buffer(foobar2,0))
  
  for (i in 1:length(years)) {
    #Second clip out home ranges sampled for Tylers points
    foo<-homerange.all2 %>%
      filter(year==years[i] & HERD_NAME==herds[j])
    
    if(dim(foo)[1]>0) {
      
      foo2<-sf::st_as_sf(foo) %>% st_combine() %>% st_sf() #flatten layer
      foo3<-sf::st_difference(clipped,st_buffer(foo2,0))
      
      #Third sample points in each year for each herd
      # change sf feature to a SpatialPolygonDataFrame
      foo3_sp<-as(foo3, "Spatial")
      class(foo3_sp)
      samp_points <- spsample (foo3_sp, cellsize = c (2000, 2000), type = "regular")
      samp_points_new <- data.frame (matrix (ncol = 5, nrow = nrow (samp_points@coords))) # add 'data' to the points
      colnames (samp_points_new) <- c ("pttype", "avail.ecotype","year","HERD_NAME","du")
      samp_points_new$pttype <- 0
      #samp_points_new$ptID <- 1:dim(samp_points@coords)[1]
      samp_points_new$avail.ecotype <- foo$ECOTYPE[1]
      samp_points_new$year<-years[i]
      samp_points_new$HERD_NAME<-herds[j]
      samp_points_new$du<-foo$du[1]
      sampled_points <- SpatialPointsDataFrame (samp_points, data = samp_points_new)
      sampled_points_sf<-st_as_sf(sampled_points)
      
      #assign file names to the work
      nam1<-paste("sampled.points",years[i],herds_new_name[j],sep=".") #defining the name
      nam2<-paste("homerange.all.clipped",years[i],herds_new_name[j],"sf",sep=".")
      assign(nam1,sampled_points_sf)
      assign(nam2,foo3)
      filenames<-append(filenames,nam1)
    }
  }
}

mkFrameList <- function(nfiles) {
  d <- lapply(seq_len(nfiles),function(i) {
    eval(parse(text=filenames[i]))
  })
  do.call(rbind,d)
}


n<-length(filenames)
samp_locations_df<-mkFrameList(n) # total number of files is 146.


#----------------------------------------
# For the used locations (1's in the analysis), I have two options: 1.) use Tylers available (0's) sample points, or 2.) sample my own points in the individual animals home ranges calculated by Tyler. I chose to do the latter (sample new points) because Tyler had more points than I thought I needed and this made my sample sizes in the glmer analyses enormous and the analysis very slow.

#Sample points out of Tylers home ranges
#----------------------------------------

years<-c("2008","2009","2010","2011","2012","2013","2014","2015","2016","2017","2018")
herds<-c("Snake-Sahtaneh", "Calendar", "Maxhamish","Parker","Chinchaga","Prophet", "Tweedsmuir","Itcha-Ilgachuz","Charlotte Alplands","Pink Mountain", "Muskwa","Frog","Chase","Spatsizi", "Finlay", "Graham", "Tsenaglode", "Telkwa", "Rainbows", "Kennedy Siding", "Narraway", "Quintette", "Moberly", "Scott", "Burnt Pine", "Hart Ranges", "Nakusp", "South Selkirks")

herds_new_name<-c("Snake_Sahtaneh", "Calendar", "Maxhamish","Parker","Chinchaga","Prophet", "Tweedsmuir","Itcha_Ilgachuz","Charlotte_Alplands","Pink_Mountain", "Muskwa","Frog","Chase","Spatsizi", "Finlay", "Graham", "Tsenaglode", "Telkwa", "Rainbows", "Kennedy_Siding", "Narraway", "Quintette", "Moberly", "Scott", "Burnt_Pine", "Hart_Ranges", "Nakusp", "South_Selkirks") # make herd names simpler as R does not seem to like the "-"

homerange.all2$individual <- sub(" ",".",homerange.all2$individual )
filenames<-list()

for (j in 1:length(herds)) {
  
  focal.herd.tyler<-homerange.all2 %>%
    filter(HERD_NAME==herds[j])
  
  for (i in 1:length(years)) {
    
    foo<-focal.herd.tyler %>%
      filter(year==years[i])
    
    if(dim(foo)[1]>0) {
      foo_sp_f<-gUnionCascaded(foo_sp)
      
      for (k in 1: length(unique(foo$individual))){
        foo_individ<- foo %>% filter(individual==unique(foo$individual)[k])
        foo_sp<-as(foo_individ,"Spatial")
        foo_sp_f<-gUnionCascaded(foo_sp)
        samp_points <- spsample (foo_sp_f, cellsize = c (2000, 2000), type = "regular")
        samp_points_new <- data.frame (matrix (ncol = 6, nrow = nrow (samp_points@coords))) # add 'data' to the points
      colnames (samp_points_new) <- c ("pttype", "avail.ecotype","year","HERD_NAME","du", "individual")
      samp_points_new$pttype <- 1
    #samp_points_new$ptID <- 1:dim(samp_points@coords)[1]
      samp_points_new$avail.ecotype <- foo_sp$ECOTYPE[1]
      samp_points_new$year<-years[i]
      samp_points_new$HERD_NAME<-herds[j]
      samp_points_new$du<-foo_sp$du[1]
      samp_points_new$individual<-unique(foo$individual)[k]
      
      sampled_points <- SpatialPointsDataFrame (samp_points, data = samp_points_new)
      sampled_points_sf<-st_as_sf(sampled_points)

#assign file names to the work
      nam1<-paste("tyler.sampled.points",years[i],herds_new_name[j],unique(foo$individual)[k],sep=".") #defining the name
      assign(nam1,sampled_points_sf)
      filenames<-append(filenames,nam1)
      }
    }
  }
}

n<-length(filenames)
samp_locations_Tyler_points_df<-mkFrameList(n) # total number of files is 146.



# Join the used and available sample points
samp_locations_df$individual<-"na"
all.samp.points<-rbind(samp_locations_df,samp_locations_Tyler_points_df)
all.samp.points$ptID<-1:(length(all.samp.points$year))



# save data 
conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")
st_write (obj = all.samp.points2, 
          dsn = conn, 
          layer = c ("caribou", "bc_caribou_samp_pnts_herd_boundaries"),
          overwrite=TRUE)
dbDisconnect (conn)

# or save it as a shape file
st_write(samp_locations_df, dsn = "bc_caribou_samp_pnts_herd_boundaries2.shp", layer = "samp_locations_df.shp", driver = "ESRI Shapefile")



# rough work making plots to test that clipping was happening as I intended
plot(st_geometry(foo3)) 
plot(st_geometry(samp_points), add=TRUE)

tm_shape(clipped) +
  tm_borders(col="green") +
tm_shape(foo2) +
  tm_fill(col="grey") +
tm_shape(foo3) +
  tm_borders(col="red") +
tm_shape(samp_points)



