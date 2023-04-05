library(data.table)
library(sf)
library(bcdata)
library(ggplot2)
source("C:/Users/KLOCHHEA/castor/R/functions/R_Postgres.R")

#Get climate data for each year (1980-2021) and for each TSA
bc_grid <- data.table::fread("C:/Data/localApps/Climatebc_v730/bc_dem_frt_Kyle.csv")
bc_sf <- st_as_sf(bc_grid, coords = c("lon", "lat"), crs = 4326, agr = "constant")
bc_sf <- st_transform(bc_sf , crs = 3005)
bc_buffer <- st_buffer(bc_sf, 400)


if(FALSE){
  ProvRast <- raster(
  nrows = 15744, ncols = 17216, xmn = 159587.5, xmx = 1881187.5, ymn = 173787.5, ymx = 1748187.5, 
  crs = st_crs(getSpatialQuery("select * from bec_zone limit 1;"))$proj4string, resolution = c(100, 100), vals = 0
  )
  treed<-getSpatialQuery("SELECT 1 as treed, shape from veg_comp_lyr_r1_poly2021 where bclcs_level_2 = 'T';")
  treed.ras<-fasterize::fasterize(treed, raster=ProvRast, field="treed")
  writeRaster(treed.ras, "treed2021.tif") 
}
treed<-raster("treed2021.tif")
treed[is.na(treed[])]<-0
bc_buffer$treed<- exactextractr::exact_extract(treed,bc_buffer,c('sum'))
climate_treed<-bc_buffer[bc_buffer$treed>1,]$ID2


aoi<-getSpatialQuery("SELECT tsa_number, wkb_geometry from tsa;")
aoi_lut<-data.table(st_drop_geometry(aoi))[, tsa_index := 1:.N]
bc_points<-bc_sf[bc_sf $ID2 %in% climate_treed,]
tsa_pts<-st_intersects(bc_points, aoi)
tsa_pts2<-lapply(1:nrow(bc_points), function(x){ as.integer(tsa_pts[[x]][1]) })
bc_points$tsa_index<-unlist(tsa_pts2)

lut<-merge(data.table(st_drop_geometry(bc_points))[,c("ID2", "tsa_index")], aoi_lut, by.x = "tsa_index", by.y = "tsa_index", all.x =T)

climateData<-lapply(seq(1980, 2021, 1), function(x){
  message(x)
  data<-data.table::fread(paste0("C:/Data/localApps/Climatebc_v730/test", x, ".csv"))
  data<-data[ID2 %in% climate_treed, ]
  data<-data[, `:=`(CMI = rowMeans(.SD, na.rm=T)), .SDcols=c("CMI04","CMI05", "CMI06","CMI07","CMI08","CMI09")]
  data<-data[,c("ID2", "CMI")]
  data<-merge(data, lut, by.x = "ID2", by.y = "ID2", all.x = TRUE)
  data<-data[, .(CMI = mean(CMI, na.rm=T)), by = tsa_number]
  data$year<-x
  data
})
climateData<-rbindlist(climateData)

#Get fire data
fireData<-try(
  bcdc_query_geodata("WHSE_LAND_AND_NATURAL_RESOURCE.PROT_HISTORICAL_FIRE_POLYS_SP") %>%
    filter(FIRE_YEAR >= 1980) %>%
    collect()
)
fireData.nogeom<-data.table(st_drop_geometry(fireData))
ggplot(data =fireData.nogeom[FIRE_YEAR >= 1980, sum(FIRE_SIZE_HECTARES), by = month(FIRE_DATE)], aes(x = as.factor(month), y =V1)) + geom_bar(stat= "identity") +xlab("Month") + ylab("Area Burned (ha)")

fireSize<-lapply(seq(1980, 2021, 1), function(x){
  fireYear<-fireData[fireData$FIRE_YEAR == x, ]
  fireArea<-st_intersection(aoi, fireYear)
  fireArea$area<-st_area(fireArea)
  fireArea$area<-units::set_units(x = fireArea$area, value = ha)
  fireArea$area<-units::drop_units(x = fireArea$area)
  fireArea<- fireArea[fireArea$area >0, ]
  fireSummary<-data.table(st_drop_geometry(fireArea))[, c("FIRE_YEAR", "area", "tsa_number")]
  fireSummary
})
fireSize<-rbindlist(fireSize)
fireSize<-fireSize[, size:= round(area, 0)]
fireSize<-fireSize[, `:=` (total_area= sum(size, rm.na=T)), by =tsa_number]

thresholds_size<-lapply(unique(fireSize$tsa_number), function(x){
  fdata<-fireSize[tsa_number == x,]
  fdata<-fdata[order(-size)]
  data.table(tsa_number =x, thres_size = max(fdata[, cvalue:=cumsum(size)][, pct_contrib:=cvalue/total_area][pct_contrib > 0.9999, ]$size))
})
thresholds_size<-rbindlist(thresholds_size)


fireAAB<-lapply(seq(1980, 2021, 1), function(x){
  fireYear<-fireData[fireData$FIRE_YEAR == x, ]
  fireArea<-st_intersection(aoi, fireYear)
  fireArea$area<-st_area(fireArea)
  fireArea$area<-units::set_units(x = fireArea$area, value = ha)
  fireArea$area<-units::drop_units(x = fireArea$area)
  fireArea<- merge(fireArea, thresholds_size, by.x = "tsa_number", by.y = "tsa_number")
  fireSummary<-data.table(st_drop_geometry(fireArea))[area >= thres_size, .(area_burned = sum(area), count = .N), by = tsa_number]
  fireSummary$year<-x
  fireSummary
})
fireAAB<-rbindlist(fireAAB)

fireSize<-lapply(seq(1980, 2021, 1), function(x){
  fireYear<-fireData[fireData$FIRE_YEAR == x, ]
  fireArea<-st_intersection(aoi, fireYear)
  fireArea$area<-st_area(fireArea)
  fireArea$area<-units::set_units(x = fireArea$area, value = ha)
  fireArea$area<-units::drop_units(x = fireArea$area)
  fireArea<- merge(fireArea, thresholds_size, by.x = "tsa_number", by.y = "tsa_number")
  fireSummary<-data.table(st_drop_geometry(fireArea))[area >= thres_size, c("FIRE_YEAR", "area", "tsa_number")]
  fireSummary
})
fireSize<-rbindlist(fireSize)

library(ggplot2)
library(units)
ggplot(data=fireAAB[tsa_number %in% c(23,29,26)], aes(x =year, y = area_burned)) +
geom_bar(stat='identity') +
xlab("Year") +
ylab("Area Burned (ha)") +
facet_wrap(~tsa_number, ncol = 1)

library(dplyr)
climateData_scaled <- climateData[tsa_number %in% c("26","29","23") & year <= 2000,][, .(avg = mean (CMI), sd = sd(CMI)), by = tsa_number] 
climateData2<-merge(climateData, climateData_scaled, by = "tsa_number")
climateData2<-climateData2[, p1:=(CMI-avg)/sd]

fireAAB_scaled <- fireAAB[tsa_number %in% c("26","29","23") & year <= 2000,][, .(avg = mean (area_burned), sd = sd(area_burned)), by = tsa_number] 
fireAAB2<-merge(fireAAB, fireAAB_scaled, by = "tsa_number")
fireAAB2<-fireAAB2[, p2:=(area_burned-avg)/sd]
fireAAB2$p2<-units::drop_units(fireAAB2$p2)
fireAAB2<-fireAAB2[p2>5, p2:=5]

ggplot(data = climateData2 , aes(x = year, y = p1)) +
  geom_line() + 
  facet_wrap(~tsa_number, ncol = 3) + 
  geom_smooth() + 
  geom_bar(data = fireAAB2, stat= "identity", aes(y= p2)) +
  scale_y_continuous(name="Area Burned (ha)", sec.axis=sec_axis(~., name="CMI")) + ylim(-3,5) 


#fill in the zero fire years
fill<-rbindlist(lapply (unique(fireAAB$tsa_number), function(x){
  data.table(tsa_number = x,year = seq(1980, 2021, 1))
  }))
data<-merge(fill, fireAAB, by.x = c("tsa_number", "year"),by.y = c("tsa_number", "year"), all.x =T)
data<-data[is.na(area_burned), area_burned :=0]
data<-data[is.na(count), count :=0]

#create fire number data set
fire_num<-merge(data, climateData, by.x = c("tsa_number", "year"), by.y = c("tsa_number", "year"), all.x= T)
hndrd_mile<-fire_num[tsa_number == 23,]
  
ggplot(data = fire_num[tsa_number %in% c("26","29","23" ) & year > 1980,] , aes(x = scale(CMI), y = count)) +
  geom_point() + 
  facet_wrap(~tsa_number, ncol = 3) + 
  geom_smooth()

hndrd_mile$lCMI<-lag(hndrd_mile$CMI)
hndrd_mile$llCMI<-lag(hndrd_mile$lCMI)
ggplot(data = hndrd_mile[ year >= 1980,] , aes(x = CMI, y = count)) +
  geom_point() + 
  geom_smooth()

m0<-lm( count~ 1, data = hndrd_mile)
library(nlme)
plot(hndrd_mile[!is.na(lCMI),c("CMI", "count")])
curve(7.746/(1 + exp(3.158+1.283*x)), from=min(hndrd_mile$CMI), to= max(hndrd_mile$CMI), add=T)

m1<-nls(count~ t/(1+exp(b*CMI)) ,start=list(t=8, a=3.4,b=1.2), data=hndrd_mile[!is.na(lCMI),])
m2<- nlme(count~ t/(1+exp(a + b*CMI)), fixed =list(t~1,b~1,a~1),random= t~1|tsa_number, 
          start =list(fixed=c(t=8, a=3.4,b=1.2)), 
          data = hndrd_mile[!is.na(lCMI),], method = 'ML', 
          control = c(maxIter = 100000))

nlo<-nl.obj(formula=~ t/(1+exp(a + b*CMI)), start=c(8, 3.4,1.2), data=hndrd_mile[!is.na(lCMI),])

nlgamlss(count~ t/(1+exp(a + b*CMI)), sigma.formula = ~ 1,
        family = PO(),data = hndrd_mile[!is.na(lCMI),])
