# Here I was trying to see the most common ignition month per FRT and also the total area burned per FRT for the spread data. I cant pull this information out from my actual spread script because of all the extra points i sample etc and also I drop fire size and igniton month somwhere along the way. 
library(bcdata)

fire_bounds_hist<-try(
  bcdc_query_geodata("WHSE_LAND_AND_NATURAL_RESOURCE.PROT_HISTORICAL_FIRE_POLYS_SP") %>%
    filter(FIRE_YEAR > 2001) %>%
    collect()
)

table(fire_bounds_hist$FIRE_YEAR)
fire_bounds_hist$ig_mnth<-stringi::stri_sub(fire_bounds_hist$FIRE_DATE,6,7)
fire_bounds_hist <- st_transform (fire_bounds_hist, 3005)

frt <- st_read ( dsn = "D:\\Fire\\fire_data\\Fire_Regime_Types\\FRT\\FRT_Canada.shp", stringsAsFactors = T) # Read simple features from file or database, or retrieve layer names and their geometry type(s)
st_crs(frt) #Retrieve coordinate reference system from sf or sfc object
frt<-st_transform(frt, 3005) #transform coordinate system to 3005 - that for BC, Canada

#get provincial boundary for clipping the layers to the area of interest
prov.bnd <- st_read ( dsn = "T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CASTOR\\Data\\admin_boundaries\\province\\gpr_000b11a_e.shp", stringsAsFactors = T) # Read simple features from file or database, or retrieve layer names and their geometry type(s)
st_crs(prov.bnd) #Retrieve coordinate reference system from sf or sfc object
prov.bnd <- prov.bnd [prov.bnd$PRENAME == "British Columbia", ] 
crs(prov.bnd)# this one needs to be transformed to 3005
bc.bnd <- st_transform (prov.bnd, 3005) #Transform coordinate system
st_crs(bc.bnd)

#Clip FRT here
frt_clipped<-st_intersection(bc.bnd, frt)
#plot(st_geometry(frt_clipped), col=sf.colors(10,categorical=TRUE))
length(unique(frt_clipped$Cluster))
frt_sf<-st_as_sf(frt_clipped)

fire.ignt.frt <- st_join(fire_bounds_hist, frt_sf)

spread_5<- fire.ignt.frt %>% filter(Cluster=="5")
hist(spread_5$ig_mnth)
spread_5$ig_mnth<-as.numeric(spread_5$ig_mnth)
hist(spread_5$ig_mnth)
table(spread_5$ig_mnth)

spread_size<-spread_5 %>% group_by(ig_mnth) %>%
  summarize(area_burned = sum(FIRE_SIZE_HECTARES))

### FRT 7 
spread_7<- fire.ignt.frt %>% filter(Cluster=="7")
spread_7$ig_mnth<-as.numeric(spread_7$ig_mnth)
hist(spread_7$ig_mnth)
table(spread_7$ig_mnth)

spread_size<-spread_7 %>% group_by(ig_mnth) %>%
  summarize(area_burned = sum(FIRE_SIZE_HECTARES))

plot(spread_size$ig_mnth, spread_size$area_burned, type = "l")

#### FRT 9
spread_9<- fire.ignt.frt %>% filter(Cluster=="9")
spread_9$ig_mnth<-as.numeric(spread_9$ig_mnth)
hist(spread_9$ig_mnth)
table(spread_9$ig_mnth)

spread_size<-spread_9 %>% group_by(ig_mnth) %>%
  summarize(area_burned = sum(FIRE_SIZE_HECTARES))

plot(spread_size$ig_mnth, spread_size$area_burned, type = "l")

#### FRT 10
spread_10<- fire.ignt.frt %>% filter(Cluster=="10")
spread_10$ig_mnth<-as.numeric(spread_10$ig_mnth)
hist(spread_10$ig_mnth)
table(spread_10$ig_mnth)

spread_size<-spread_10 %>% group_by(ig_mnth) %>%
  summarize(area_burned = sum(FIRE_SIZE_HECTARES))

plot(spread_size$ig_mnth, spread_size$area_burned, type = "l")

#### FRT 11
spread_11<- fire.ignt.frt %>% filter(Cluster=="11")
spread_11$ig_mnth<-as.numeric(spread_11$ig_mnth)
hist(spread_11$ig_mnth)
table(spread_11$ig_mnth)

spread_size<-spread_11 %>% group_by(ig_mnth) %>%
  summarize(area_burned = sum(FIRE_SIZE_HECTARES))

plot(spread_size$ig_mnth, spread_size$area_burned, type = "l")

#### FRT 12
spread_12<- fire.ignt.frt %>% filter(Cluster=="12")
spread_12$ig_mnth<-as.numeric(spread_12$ig_mnth)
hist(spread_12$ig_mnth)
table(spread_12$ig_mnth)

spread_size<-spread_12 %>% group_by(ig_mnth) %>%
  summarize(area_burned = sum(FIRE_SIZE_HECTARES))

plot(spread_size$ig_mnth, spread_size$area_burned, type = "l")

#### FRT 13
spread_13<- fire.ignt.frt %>% filter(Cluster=="13")
spread_13$ig_mnth<-as.numeric(spread_13$ig_mnth)
hist(spread_13$ig_mnth)
table(spread_13$ig_mnth)

spread_13<-spread_13 %>% st_drop_geometry()

spread_size<-spread_13 %>% group_by(ig_mnth) %>%
  summarize(area_burned = sum(FIRE_SIZE_HECTARES))

plot(spread_size$ig_mnth, spread_size$area_burned, type = "l")


#### FRT 14
spread_14<- fire.ignt.frt %>% filter(Cluster=="14")
spread_14$ig_mnth<-as.numeric(spread_14$ig_mnth)
hist(spread_14$ig_mnth)
table(spread_14$ig_mnth)

spread_14<-spread_14 %>% st_drop_geometry()

spread_size<-spread_14 %>% group_by(ig_mnth) %>%
  summarize(area_burned = sum(FIRE_SIZE_HECTARES))

plot(spread_size$ig_mnth, spread_size$area_burned, type = "l")

#### FRT 15
spread_15<- fire.ignt.frt %>% filter(Cluster=="15")
spread_15$ig_mnth<-as.numeric(spread_15$ig_mnth)
hist(spread_15$ig_mnth)
table(spread_15$ig_mnth)

spread_15<-spread_15 %>% st_drop_geometry()

spread_size<-spread_15 %>% group_by(ig_mnth) %>%
  summarize(area_burned = sum(FIRE_SIZE_HECTARES))

plot(spread_size$ig_mnth, spread_size$area_burned, type = "l")

