library(raster)
library(SpaDES.tools)
library(data.table)
library(sf)
library(dplyr)
library(scales)
#Create a dummy example
ras<-raster(nrows=80, ncols=80)
ras[]<-0
plot(ras)
set.seed(123)
#Simulate a territory
out<-spread2(ras, spreadProb = 0.4, start =c(200, 3160, 5200), maxSize = c(300,300, 300), asRaster =F)
ras[out$pixels]<-1
plot(ras)
#Get its XY coordinates
xy<-data.table(cbind(out, raster::xyFromCell(ras, out$pixels)))
#Keep its exterior pixels
test1<-xy[, keep_right:=max(x), by =c("y", "initialPixels") ][, keep_left:=min(x), by = c("y", "initialPixels")][ keep_right == x | keep_left ==x,]
ras[]<-0
ras[test1$pixels]<-1
plot(ras)
#Convert to polygon
pts <- st_as_sf(test1, coords = c(4:5), agr ="initialPixels")
plot(pts)
pts<-pts %>%
  group_by(initialPixels) %>% 
  summarize(geometry = st_union(geometry))

poly <- st_convex_hull(pts) 
#Visualize result
ras[]<-0
ras[out$pixels]<-out$initialPixels
plot(ras)
plot(poly, col = alpha(c("yellow", "blue", "green"), 0.2), add=T)

                 