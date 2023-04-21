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


if(TRUE){
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
climate_treed<-bc_buffer[bc_buffer$treed>1,]$ID1


aoi<-getSpatialQuery("SELECT tsa_number, wkb_geometry from tsa;")
aoi_lut<-data.table(st_drop_geometry(aoi))[, tsa_index := 1:.N]
bc_points<-bc_sf[bc_sf $ID1 %in% climate_treed,]
tsa_pts<-st_intersects(bc_points, aoi)
tsa_pts2<-lapply(1:nrow(bc_points), function(x){ as.integer(tsa_pts[[x]][1]) })
bc_points$tsa_index<-unlist(tsa_pts2)

lut<-merge(data.table(st_drop_geometry(bc_points))[,c("ID1", "tsa_index")], aoi_lut, by.x = "tsa_index", by.y = "tsa_index", all.x =T)

climateData<-lapply(seq(1980, 2040, 1), function(x){
  message(x)
  data<-data.table::fread(paste0("C:/Data/localApps/Climatebc_v730/test", x, ".csv"))
  data<-data[ID1 %in% climate_treed, ]
  data<-data[, `:=`(CMI = rowMeans(.SD, na.rm=T)), .SDcols=c("CMI04","CMI05", "CMI06","CMI07","CMI08","CMI09")]
  data<-data[, `:=`(TEMP = rowMeans(.SD, na.rm=T)), .SDcols=c("Tmax04","Tmax05", "Tmax06","Tmax07","Tmax08","Tmax09")]
  data<-data[,c("ID1", "CMI", "TEMP")]
  data<-merge(data, lut, by.x = "ID1", by.y = "ID1", all.x = TRUE)
  data<-data[, .(CMI = median(CMI, na.rm=T), TEMP = median(TEMP, na.rm=T)), by = tsa_number]
  data$year<-x
  data
})
climateData<-rbindlist(climateData)
ggplot( data = climateData[tsa_number %in% c(26,23,29)], aes(y = CMI, x = year, group = tsa_number)) + 
  geom_line(linetype = 1, data = climateData[tsa_number %in% c(26,23,29) & year <=2021,])+ 
  geom_line(linetype = 1, color = "red", data = climateData[tsa_number %in% c(26,23,29) & year >=2021,]) + 
  facet_wrap(~tsa_number, ncol = 1)

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
  data.table(tsa_number =x, thres_size = max(fdata[, cvalue:=cumsum(size)][, pct_contrib:=cvalue/total_area][pct_contrib > 0.99, ]$size))
})
thresholds_size<-rbindlist(thresholds_size)
thresholds_size$thres_size<-16

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

tsa_names <- as_labeller(
  c(`26` = "Quesnel", `29` = "Williams Lake", `23` = "100 Mile House", `14` = "Lakes", `24`= "Prince George", `11` = "Kamloops", `22` = "Okanagan", `16`= "MacKenzie", `18` ="Merrit"))
ggplot(data = fire_num[tsa_number %in% c("26","29","23", "14", "24", "11", "22", "16", "18" ) & year > 1980,] , aes(x =scale(CMI), y = count)) +
  geom_point() + 
  facet_wrap(~tsa_number, ncol = 3, labeller = tsa_names) + 
  geom_smooth(method='lm', formula= y~exp(-x))

#fill in the zero fire years
fill<-rbindlist(lapply (unique(fireSize$tsa_number), function(x){
  data.table(tsa_number = x,FIRE_YEAR = seq(1980, 2021, 1))
}))
dataSize<-merge(fill, fireSize, by.x = c("tsa_number", "FIRE_YEAR"),by.y = c("tsa_number", "FIRE_YEAR"), all.x =T)
dataSize<-dataSize[is.na(area), area:=0]

#create fire number data set
fire_size<-merge(dataSize, climateData, by.x = c("tsa_number", "FIRE_YEAR"), by.y = c("tsa_number", "year"), all.x= T)
df<-fire_size[tsa_number %in% c("26","29","23", "14", "24", "11", "22", "16", "18" ) & FIRE_YEAR > 1980,]
ggplot(df)+
  geom_point(aes(x =scale(CMI), y = scale(area))) + 
  scale_y_continuous(limits = c(-1, 2))+
  facet_wrap(~tsa_number, labeller = tsa_names ) + 
  geom_smooth(aes(x =scale(CMI), y = scale(area)),method='lm', formula= y~exp(-x))


### Models
library(gamlss.nl)
tsas_not_intrest<-c(25,21,10,44,38,45,37,48,39,47)

#### Number of fires
test_tsa_num<-fire_num[tsa_number == 26,]
num0<-gamlss(count ~ CMI,
       sigma.formula = ~TEMP,
       #sigma.formula = ~1,
       sigma.link = "log",
       family = NBI(), 
       data =  na.omit(test_tsa_num), 
       control = gamlss.control(c.crit = 0.001), method=CG())
summary(num0)
acfResid(num0)
fittedPlot(num0, x= test_tsa_num$CMI)
centiles.fan(num0, points =T)
Rsq(num0)
num0_predict<-predictAll(num0)
plot(num0_predict$mu, num0_predict$y) 
abline(0,1)
test_tsa_num$mu_nbi<-num0_predict$mu
test_tsa_num$sigma_nbi<-num0_predict$sigma

#### Size of fire
test_tsa<-fire_size[tsa_number == 26 & area > 0,]
n0<-gamlss(area ~ CMI*TEMP,
           sigma.formula = ~ CMI+TEMP ,
           #sigma.formula = ~ 1,
           sigma.link = "log",
           family = GA(), 
           data =  na.omit(test_tsa), 
           control = gamlss.control(c.crit = 0.001), method=CG())
summary(n0)
acfResid(n0)
fittedPlot(n0, x= test_tsa[!is.na(CMI),]$CMI)
centiles.fan(n0, points =T)
Rsq(n0)
n0_predict<-predictAll(n0)
plot(n0_predict$mu, n0_predict$y) 
abline(0,1)
test_tsa$mu_ga<-n0_predict$mu
test_tsa$sigma_ga<-n0_predict$sigma

test_aab<-test_tsa[, .(obs =sum(area), mu_ga =max(mu_ga), sigma_ga = max(sigma_ga)), by = FIRE_YEAR]
test_aab<-merge(test_aab, test_tsa_num, by.x = "FIRE_YEAR", by.y = "year")
sim_out<-lapply(1:nrow(test_aab), function(x){
  num_fires<-data.table(num_f = rNBI(100, test_aab$mu_nbi[x], test_aab$sigma_nbi[x]))
  for(n in 1:nrow(num_fires)){
    if(num_fires[n,]$num_f == 0){
      num_fires[n, aab:=0]
    }else{
      num_fires[n, aab:=sum(rGA(num_fires[n,]$num_f, test_aab$mu_ga[x], test_aab$sigma_ga[x]))]
    }
  }
  data.table(year = test_aab[x]$FIRE_YEAR, mean = quantile(num_fires$aab, 0.5), p66 = quantile(num_fires$aab, 0.66), p33 = quantile(num_fires$aab, 0.33))
  
})

sim_out<-rbindlist(sim_out)
compare<-merge(test_aab, sim_out, by.x = "FIRE_YEAR", by.y = "year")
ggplot(data= compare) +
  geom_bar(aes(x = FIRE_YEAR,y = obs), fill = "blue", stat = "identity", col = "blue") +
  geom_line(aes(x = FIRE_YEAR, y = mean), col = "red") +
  geom_line(aes(x = FIRE_YEAR, y = p33), col = "red", linetype =2) +
  geom_line(aes(x = FIRE_YEAR, y = p66), col = "red", linetype =2)
  
median(compare$mean)  
median(compare$obs)