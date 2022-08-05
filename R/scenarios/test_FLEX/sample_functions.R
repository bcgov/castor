## test some functions for ABM
##-----------
library(SpaDES.tools)
## Make a dummy aoi, some denning sites, denning habitat and movement habitat
aoi<-raster(vals = 0, extent(0, 100, 0, 100), res= 1)
denning<-aoi
denningSites<-sample(1:ncell(aoi), 20)
denning[denningSites]<-1 #Choose 20 random pixels as denning habitat
movement<-aoi
movement[sample(1:ncell(aoi), 4000)]<-1 #Choose 4000 random pixels as movement habitat (40% of aoi)
fisherLocation<-sample(denningSites, 2, replace =F) #these are the cellIndex in the raster -- use cellFromXY if need be

## Tables in the Simulation
pixels<-data.table(den=denning[], mov=movement[])[,pixelid:=seq_len(.N)]
fisherAgent<-data.table(location =fisherLocation, sex = 'F', age = 4)

## create the search areas
fisherSearchArea<-SpaDES.tools::spread2(aoi, 
                                   start = fisherLocation, 
                                   spreadProb = 1, 
                                   maxSize = 1000, 
                                   allowOverlap = T, 
                                   returnDistances = T, # Does not work?
                                   asRaster = F)

#### Get the distance to between each pixel and the denning site
fisherSearchArea<-cbind(fisherSearchArea, xyFromCell(aoi, fisherSearchArea$pixels))
fisherSearchArea[!(pixels %in% fisherLocation),dist:=RANN::nn2(fisherSearchArea[pixels %in% fisherLocation, c("x","y")], fisherSearchArea[!(pixels %in% fisherLocation), c("x","y")], k =1)$nn.dists]
fisherSearchArea[is.na(dist), dist:= 0]
## Write the query for creating the territory via habitat features
### first convert these R objects to sqlite rdms
clusdb<-dbConnect(RSQLite::SQLite(), ":memory:")
dbExecute(clusdb, "CREATE TABLE IF NOT EXISTS pixels ( pixelid integer PRIMARY KEY, den integer, mov integer);")
qry<-paste0("INSERT INTO pixels (pixelid, den, mov) values(:pixelid, :den, :mov);")

##### pixels table
dbBegin(clusdb)
rs<-dbSendQuery(clusdb, qry, pixels )
dbClearResult(rs)
dbCommit(clusdb)

dbExecute(clusdb, "CREATE TABLE IF NOT EXISTS fisherSearchArea ( fisherLocation integer, searchArea integer, dist numeric);")
qry<-paste0("INSERT INTO fisherSearchArea (fisherLocation, searchArea, dist) values(:initialPixels, :pixels, :dist);")

##### fisherSearchArea table
dbBegin(clusdb)
rs<-dbSendQuery(clusdb, qry, fisherSearchArea[,c("initialPixels", "pixels", "dist")] )
dbClearResult(rs)
dbCommit(clusdb)

### create territory query
territory<-dbGetQuery(clusdb, glue::glue("with 
search as (select fisherLocation, searchArea, dist from fisherSearchArea ),
habitat as (select pixelid, den, mov from pixels where den = 1 or mov =1)
select fisherLocation, searchArea, den, mov, dist from search 
left join habitat on searchArea = habitat.pixelid
where dist < 50 and (den = 1 or mov = 1) order by fisherLocation, dist;"))
