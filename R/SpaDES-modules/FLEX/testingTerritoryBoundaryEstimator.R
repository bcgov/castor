library(raster)
library(SpaDES.tools)
library(data.table)
library(sf)

#Create a dummy example
ras<-raster(nrows=100, ncols=100)
ras[]<-0
plot(ras)
set.seed(11)
#Simulate a territory
out<-spread2(ras, maxSize = 3000, asRaster =F)
ras[out$pixels]<-1
plot(ras)
#Get its XY coordinates
xy<-data.table(cbind(out, raster::xyFromCell(ras, out$pixels)))
#Keep its exterior pixels
test1<-xy[, keep_right:=max(x), by =y ][, keep_left:=min(x), by = y][ keep_right == x | keep_left ==x,]
ras[]<-0
ras[test1$pixels]<-1
plot(ras)
#Convert to polygon
pts <- st_as_sf(test1, coords = c(4:5))
plot(pts)
poly <- st_convex_hull(st_union(pts)) 
#Visualize result
ras[]<-0
ras[out$pixels]<-1
plot(ras)
plot(poly, add=T)

                 