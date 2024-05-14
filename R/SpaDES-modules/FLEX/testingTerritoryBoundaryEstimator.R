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
set.seed(111)
#Simulate a territory
out<-spread2(ras, spreadProb = 0.3, start =c(200, 3160, 5200), 
             exactSize = c(300,300, 300), asRaster =F)
ras[out$pixels]<-1
plot(ras)
#Get its XY coordinates
xy<-data.table(cbind(out, raster::xyFromCell(ras, out$pixels)))
#Keep its exterior pixels
test1<-xy[, keep_right:=max(x), by =c("y", "initialPixels") ][, keep_left:=min(x), by = c("y", "initialPixels")][, keep_above:= min(y), by = c("x", "initialPixels")][, keep_below:= max(y), by = c("x", "initialPixels")] [ keep_right == x | keep_left ==x | keep_above ==y | keep_below ==y,]
ras[]<-0
ras[test1$pixels]<-1
plot(ras)
#Convert to polygon
pts <- st_as_sf(test1, coords = c(4:5), agr ="initialPixels")
plot(pts["initialPixels"])
pts<-pts %>%
  group_by(initialPixels) %>% 
  summarize(geometry = st_union(geometry))  
plot(pts["initialPixels"])
poly <- st_convex_hull(pts) 
plot(poly)


#Visualize result
ras[]<-0
ras[out$pixels]<-out$initialPixels
plot(ras)
plot(poly, col = alpha(c("yellow", "blue", "green"), 0.2), add=T)

ras.mcp<-terra::rasterize(poly, ras, field = "initialPixels")
plot(ras.mcp)                 

dt.mcp<-data.table(initialPixels= ras.mcp[])[,pixelid := seq_len(.N)][!is.na(initialPixels),]
dt.mcp<-data.table(cbind(dt.mcp, raster::xyFromCell(ras, dt.mcp$pixelid)))
setnames(dt.mcp, c("x", "y"), c("X", "Y"))

test2<-merge(dt.mcp, test1[!is.na(keep_left), c("y", "initialPixels", "keep_left", "keep_right")], 
             by.x = c("Y", "initialPixels"), by.y = c( "y","initialPixels"), all.x=T, allow.cartesian=TRUE)
test3<-test2[X>=keep_left & X<=keep_right,]

test4<-merge(test3, test1[!is.na(keep_below), c("x", "initialPixels", "keep_above", "keep_below")],  by.x = c("X", "initialPixels"), by.y = c( "x","initialPixels"), all.x=T, allow.cartesian=TRUE)
test5<-test4[Y>=keep_above & Y<=keep_below,]
ras.mcp2<-ras.mcp
ras.mcp2[]<-0
ras.mcp2[test5$pixelid]<-test5$initialPixels
plot(ras.mcp2)
