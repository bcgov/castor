library(raster)
library(RSQLite)
library(ggplot2)
library(terra)
library(sf)
library(stars)
library(data.table)
library(tidyterra)
source(paste0(here::here(), "/R/functions/R_Postgres.R"))
userdb<-dbConnect(RSQLite::SQLite(), dbname = paste0(here::here(), "/R/scenarios/boundary_fire/boundary_fire_castordb.sqlite") ) 
ras.info<-dbGetQuery(userdb, "Select * from raster_info limit 1;")
ras<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0, crs = 3005)
pixel10km<-data.table(dbGetQuery(userdb, "Select pixelid10km, pixelid from pixels;"))
climate.info<-dbGetQuery(userdb, "Select pixelid_climate, basalarea, pixelid from pixels order by pixelid;")
climate.cmi<-dbGetQuery(userdb, "Select pixelid_climate, cmi_05, tmax_06 from climate_mpi_esm1_2_hr_ssp370 where period = 2025 and run = 'r1i1p1f1';")
dbDisconnect(userdb)
ras[pixel10km$pixelid]<-pixel10km$pixelid10km
#create the grid. The grid is at a different extent for the province
ras.p10k<-rast('C:/Users/klochhea/castor/R/scenarios/boundary_fire/ani/pixelid10km.tif')
ras.p10k[!(ras.p10k[] %in% pixel10km$pixelid10km)]<-NA
mask.bounds<-ras.p10k > 1
ras.p10k.bounds <- crop(ras.p10k,mask.bounds)

bbox<-sf::st_bbox(c(xmin = 1479587.5, ymax=578187.5, ymin =468187.5, xmax = 1589587.5))
tenKgrid<-sf::st_make_grid(bbox, cellsize = c(10000,10000), square = TRUE)
tenKgrid<-st_as_sf(tenKgrid)

pix10km<- unique(terra::extract(ras.p10k.bounds, tenKgrid))
tenKgrid$pixelid10km<-pix10km$pixelid10km

boundary.10k<-tenKgrid[tenKgrid$pixelid10km %in% unique(pixel10km$pixelid10km),]
boundary.tsa<-getSpatialQuery("select * from tsa where tsnmbrdscr = 'Boundary_TSA'")
st_crs(boundary.tsa)=3005
st_crs(boundary.10k)=3005
st_crs(tenKgrid)=3005

prov.tsa<-getSpatialQuery("select * from tsa")
st_crs(prov.tsa)=3005
#First image is the province with a 10km grid
png(file="C:/Users/klochhea/castor/R/scenarios/boundary_fire/ani/01_boundary_grid_tsa.png", width=600, height=600)
ggplot() + 
  geom_sf(data =prov.tsa, fill = as.integer(as.factor(prov.tsa$tsnmbrdscr))) + 
  geom_sf(data =tenKgrid, fill = NA) + 
  labs(fill = "")
dev.off()

#second image is the boundary with a 10km grid
png(file="C:/Users/klochhea/castor/R/scenarios/boundary_fire/ani/02_boundary_grid.png", width=600, height=600)
ggplot() + 
  geom_sf(data =boundary.tsa, fill = "salmon") + 
  geom_sf(data =boundary.10k, fill = NA) + 
  labs(fill = "")
dev.off()

#third image the start of the simulation
climatemap<-merge(climate.info, climate.cmi, by.x = "pixelid_climate", by.y = "pixelid_climate", all.x =TRUE)
ras[]<-NA
ras[climatemap$pixelid]<-climatemap$cmi_05
png(file="C:/Users/klochhea/castor/R/scenarios/boundary_fire/ani/04_boundary_cmi05.png", width=600, height=600)
ggplot() + 
  geom_spatraster(data=rast(ras)) +
  geom_sf(data =boundary.10k, fill = NA) +
  geom_sf(data =boundary.tsa, fill = NA, linewidth =2, color="black") +
  theme( legend.position="none") +
  labs(fill = "")
dev.off()

#Fourth image the start of the simulation
ras[]<-NA
ras[climatemap$pixelid]<-climatemap$basalarea
png(file="C:/Users/klochhea/castor/R/scenarios/boundary_fire/ani/04_boundary_g.png", width=600, height=600)
ggplot() + 
  geom_spatraster(data=rast(ras)) +
  scale_fill_hypso_b(palette = "colombia_hypso", breaks =c(0,5,8,10,18,22,28,100)) +
  geom_sf(data =boundary.10k, fill = NA) + 
  geom_sf(data =boundary.tsa, fill = NA, linewidth =2, color="black") + 
  theme( legend.position="none") +
  labs(fill = "")
dev.off()

#Fith image is the boundary with prob of ignition
library(gamlss)
row <-1L
col <-1L
count<-0L
dat.list<-list()
for(x in 1:121){
  if(count >= 11) {
    row <- row + 1L
    count <- 0L
  }
  count <- count + 1L
  col <- count
  if(x %in% c(1,2,3,8,9,10,11,12,13,14,20,21,22,23,24,31,32,33,34,43,44,45,54,55,56,65,66,77,78,88,89,100, 111,120,121)){
    mu = exp(-15)
    color = NA
  }else{
    mu = exp(0.005*runif(1,-100,100))
    color = "salmon"
  }
  
  dat.list[[x]]<-data.table(prob.ignite = rNBI(100, mu = mu, sigma = exp(0.33)), row = row, col =col, pt =x, color =color)
}
dat.list<-rbindlist(dat.list)

png(file="C:/Users/klochhea/castor/R/scenarios/boundary_fire/ani/05_boundary_ignite_dist.png", width=600, height=600)
ggplot(data = dat.list, aes(x = prob.ignite, group = pt)) + 
  geom_histogram(binwidth = 1, aes(y = after_stat(density), fill =color)) +
  facet_grid(row~col) +
 scale_x_continuous(breaks=c(0, 5, 10))+
  theme( legend.position="none",
         panel.background = element_blank(),
         strip.background = element_blank(),
         strip.text.x = element_blank(),
         strip.text.y = element_blank(),
         
         panel.spacing = unit(0,'lines'), 
         panel.border = element_rect(color = "black", fill = NA),
         #axis.title.x=element_blank(),
         axis.text.x = element_text(size=8, angle=45),
         #axis.text.x=element_blank(),
         #axis.ticks.x=element_blank(),
         #axis.title.y=element_blank(),
         axis.text.y=element_blank(),
         axis.ticks.y=element_blank()) +
  xlab("Number of fires") +
  ylab("Density") 
dev.off()

##Sim fire-number of ignitions
cents<-st_centroid(tenKgrid)
firedisturbanceTable_37 <- readRDS("C:/Users/klochhea/castor/R/scenarios/boundary_fire/ani/firedisturbanceTable_37.rds")
perFireReport_37 <- readRDS("C:/Users/klochhea/castor/R/scenarios/boundary_fire/ani/perFireReport_37.rds")

t =1
  fires.t<-tenKgrid[tenKgrid$pixelid10km %in% as.integer(perFireReport_37[timeperiod ==t, ]$pixelid10km),]
  fires.t.lab<-perFireReport_37[timeperiod ==t, .(fnum = sum(.N)), by= pixelid10km ]
  fires.lab<-merge(cents, fires.t.lab, by= "pixelid10km")
  png(file=paste0("C:/Users/klochhea/castor/R/scenarios/boundary_fire/ani/06_boundary_ignite_",t,".png"), width=600, height=600)
  ggplot() + 
      geom_sf(data =boundary.10k, fill = NA) + 
      geom_sf(data =boundary.tsa, fill = NA, linewidth =2, color="black") + 
      geom_sf(data =fires.t, fill = 'red') +
      geom_sf_text(data = fires.lab, aes(label = fnum))+
      theme( legend.position="none") +
      labs(fill = "", title=paste0("Year ", t+2023))
  dev.off()

#Spatial ignition locations
p.escape<-rast("R/scenarios/boundary_fire/ani/Prob_escape_1.tif")
t =1
fires.t<-tenKgrid[tenKgrid$pixelid10km %in% as.integer(perFireReport_37[timeperiod ==t, ]$pixelid10km),]
closer.fires.t<-fires.t[9,]
closer.fires.t.lab<-perFireReport_37[timeperiod == t & pixelid10km==closer.fires.t$pixelid10km, .(fnum = sum(.N)), by= pixelid10km ]
closer.fires.lab<-merge(cents, closer.fires.t.lab, by= "pixelid10km")

png(file="C:/Users/klochhea/castor/R/scenarios/boundary_fire/ani/07_boundary_select_10k_pixel.png", width=600, height=600)
ggplot() + 
  geom_spatraster(data=p.escape) +
  scale_fill_whitebox_c(palette = "bl_yl_rd") +
  geom_sf(data =boundary.10k, fill = NA) + 
  geom_sf(data =boundary.tsa, fill = NA, linewidth =2, color="black") + 
  geom_sf(data =closer.fires.t, fill = NA, color = 'red', linewidth =1.2) + 
  geom_sf_text(data = closer.fires.lab, aes(label = fnum))+
  theme( legend.position="none") +
  labs(fill = "")
dev.off()

##Zoom on a single 10km pixel
closer.p.escape<-crop(p.escape, closer.fires.t)
coords<-data.table(xyFromCell(closer.p.escape, 2545))
fire = st_as_sf(coords, coords = c(1:2), crs = 3005)
png(file="C:/Users/klochhea/castor/R/scenarios/boundary_fire/ani/08_boundary_select_10k_fire_loc.png", width=600, height=600)
ggplot() + 
  geom_spatraster(data=closer.p.escape) +
  scale_fill_whitebox_c(palette = "bl_yl_rd") +
  geom_sf(data=fire, color = 'red', size =6)+
  geom_sf(data =closer.fires.t, fill = NA, color = 'red', linewidth =1.2) + 
  theme( legend.position="none") +
  labs(fill = "")
dev.off()

##Zoom out and show spread
p.spread<-rast("R/scenarios/boundary_fire/ani/Prob_spread_1.tif")
png(file="C:/Users/klochhea/castor/R/scenarios/boundary_fire/ani/09_boundary_fire_spread.png", width=600, height=600)
ggplot() + 
  geom_spatraster(data=p.spread) +
  scale_fill_whitebox_c(palette = "bl_yl_rd") +
  geom_sf(data =boundary.10k, fill = NA) + 
  geom_sf(data =closer.fires.t, fill = NA, color = 'red', linewidth =1.2) + 
  geom_sf(data=fire, color = 'red', size =2)+
  geom_sf(data =closer.fires.t, fill = NA, color = 'red', linewidth =1.2) + 
  geom_sf(data =boundary.tsa, fill = NA, linewidth =2, color="black") + 
  theme( legend.position="none") +
  labs(fill = "")
dev.off()

##Show mixture model
library(gamlss.mx)
png(file="C:/Users/klochhea/castor/R/scenarios/boundary_fire/ani/10_fire_dist.png", width=600, height=600)
fyWEI<-dMX(y=seq(0,13,0.01), mu=list(exp(0.6339),exp(1.73)), sigma=list(exp(0.2357), exp(0.9831)), pi=list(0.5821746, 0.4178254 ), family=list("WEI3","WEI3") )
plot(fyWEI~seq(0,13,.01), type="l", ylab = 'Density', xlab = 'log(Fire Size (ha))')
curve(0.5821746*dWEI3(x, mu= exp(0.6339), sigma = exp(0.2357)), from = 0, to = 13, col = "orange", lwd =2, ylim =c(0,.4), add=T)
curve(0.4178254*dWEI3(x, mu = exp(1.73), sigma = exp(0.9831)), from = 0, to = 13, col = "green", lwd =2, add=T)
dev.off()

##Select the exact size

row <-1L
col <-1L
count<-0L
dat.list<-list()
for(x in 1:121){
  if(count >= 11) {
    row <- row + 1L
    count <- 0L
  }
  count <- count + 1L
  col <- count
  if(x %in% c(1,2,3,8,9,10,11,12,13,14,20,21,22,23,24,31,32,33,34,43,44,45,54,55,56,65,66,77,78,88,89,100, 111,120,121)){
    mu = NA
    sigma = NA
    color = NA
    dat.list[[x]]<-data.table(size = 0, row = row, col =col, pt =x, color =color)
  
  }else{
    what_fire = rbinom(1, size =1, prob = 0.5821746)
    if(what_fire == 1){
      mu= exp(1.6339)
      sigma = exp(0.2357)
      dat.list[[x]]<-data.table(size = rWEI(1000, mu = mu, sigma = sigma), row = row, col =col, pt =x, color =color)
      
    }else{
      mu = exp(3.73)
      sigma = exp(0.9831)
      dat.list[[x]]<-data.table(size = rWEI(1000, mu = mu, sigma = sigma), row = row, col =col, pt =x, color =color)
      
    }
    color = "salmon"
  }
  
  }
dat.list<-rbindlist(dat.list)
png(file="C:/Users/klochhea/castor/R/scenarios/boundary_fire/ani/10_boundary_fire_size.png", width=600, height=600)
ggplot(data = dat.list, aes(x = size)) + 
  geom_histogram() +
  facet_grid(row~col) +
  theme( legend.position="none",
         panel.background = element_blank(),
         strip.background = element_blank(),
         strip.text.x = element_blank(),
         strip.text.y = element_blank(),
         
         panel.spacing = unit(0,'lines'), 
         panel.border = element_rect(color = "black", fill = NA),
         #axis.title.x=element_blank(),
         #axis.text.x = element_text(size=8, angle=45),
         axis.text.x=element_blank(),
         axis.ticks.x=element_blank(),
         #axis.title.y=element_blank(),
         axis.text.y=element_blank(),
         axis.ticks.y=element_blank()) +
  xlab("Fires size (ha)") +
  ylab("Density") 
dev.off()
##spread the fire
start.cell<-cellFromXY(p.spread, coords)
fire.spread<-SpaDES.tools::spread2(landscape = p.spread, start = start.cell, spreadProb =  p.spread[], exactSize =  10000, asRaster = TRUE, circle = FALSE)
png(file="C:/Users/klochhea/castor/R/scenarios/boundary_fire/ani/11_boundary_fire.png", width=600, height=600)
ggplot() + 
  geom_spatraster(data=p.spread) +
  scale_fill_whitebox_c(palette = "bl_yl_rd") +
  geom_spatraster(data=fire.spread, color = 'orange') +
  geom_sf(data =boundary.10k, fill = NA) + 
  #geom_sf(data =closer.fires.t, fill = NA, color = 'red', linewidth =1.2) + 
  geom_sf(data=fire, color = 'red', size =2)+
  #geom_sf(data =closer.fires.t, fill = NA, color = 'red', linewidth =1.2) + 
  geom_sf(data =boundary.tsa, fill = NA, linewidth =2, color="black") + 
  theme( legend.position="none") +
  labs(fill = "")
dev.off()