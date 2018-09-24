source("R/functions/functions.R") # get the functions used for database connectiviity
library(raster)

saList<-list("Barkerville",	"Central Rockies",	"Chase",	"Chinchaga",	"Columbia North",	"Finlay",	"Graham",	"Groundhog",	"Hart Ranges",	"Horseranch",	"Itcha-Ilgachuz",	"Moberly",	"Muskwa",	"Nakusp",	"Narraway",	"North Cariboo",	"Quintette",	"Rainbows",	"Scott",	"South Selkirks",	"Takla",	"Telkwa",	"Tweedsmuir",	"Wells Gray",	"Wolverine")
saList<-list("Barkerville")
list<-lapply(saList, function(saList) {
  
  sa.vec<-getSpatialQuery(paste0("SELECT geom FROM public.gcbp_carib_polygon WHERE herd_name = '",saList , "';" ))
  sa.vec$id<-1
  sa.mask<-fasterize::fasterize(sa.vec, raster(extent(sa.vec), crs = "+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs", 
                                              resolution = c(100, 100), vals = 0), field = "id")
  road.obs<-resample(getRasterQuery('ften_roads_ras', st_bbox(sa.mask)),sa.mask, method = 'bilinear')*sa.mask
  road.pre.obs<-resample(getRasterQuery('pre_roads_ras', st_bbox(sa.mask)),sa.mask, method = 'bilinear')*sa.mask
  road.obs<- road.obs + road.pre.obs
  road.obs[!road.obs[] == 0] <-1
  road.pred.snap<-resample(raster(paste0("R/outputs/",saList,"/",saList,"_snap_38.tif")),sa.mask, method = 'bilinear')*sa.mask
  road.pred.snap[!road.pred.snap[] ==0] <-1
  
  road.pred.lcp<-resample(raster(paste0("R/outputs/",saList,"/",saList,"_lcp_38.tif")),sa.mask, method = 'bilinear')*sa.mask
  road.pred.lcp[!road.pred.lcp[] == 0]<-1
 
  road.pred.mst<-resample(raster(paste0("R/outputs/",saList,"/",saList,"_mst_38.tif")),sa.mask, method = 'bilinear')*sa.mask
  road.pred.mst[!road.pred.mst[]==0]<-1
 
  err.pred.snap<-road.obs + road.pred.snap
  err.pred.snap[err.pred.snap[] == 1]<-0
  err.pred.snap[err.pred.snap[] == 2]<-1
  
  err.pred.lcp<-road.obs + road.pred.lcp
  err.pred.lcp[err.pred.lcp[] == 1]<-0
  err.pred.lcp[err.pred.lcp[] == 2]<-1
  
  err.pred.mst<-road.obs + road.pred.mst
  err.pred.mst[err.pred.mst[] == 1]<-0
  err.pred.mst[err.pred.mst[] == 2]<-1
  
  c(saList,cellStats(road.obs, 'sum'),cellStats(road.pred.snap, 'sum'), cellStats(road.pred.lcp, 'sum'),cellStats(road.pred.mst, 'sum'), cellStats(err.pred.snap, 'sum'),cellStats(err.pred.lcp, 'sum'),cellStats(err.pred.mst, 'sum'))
})

test<-as.data.frame(list)
write.csv(test,file = "R/validation_messy.csv")
