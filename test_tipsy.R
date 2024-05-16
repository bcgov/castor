userdb <- dbConnect(RSQLite::SQLite(), dbname = paste0(here::here(), "/R/scenarios/test_Bulkley/Bulkley_TSA_clusdb.sqlite") ) 
yt<-dbGetQuery(userdb, " select distinct(yieldid) from yields;")
#pix<-dbGetQuery(userdb, "select distinct(yieldid) from pixels;")$yieldid

pix<-dbGetQuery(userdb, "select distinct(yieldid_trans) from pixels;")$yieldid_trans
dbDisconnect(userdb)
pix<-data.table(yc=pix)
pix<-pix[!is.na(yc),]
outs<-unique(pix[!(yc %in% yt$yieldid),])

ras.info<-dbGetQuery(userdb, "select * from raster_info where name = 'ras'") #Get the raster information
ras<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =1:ras.info$ncell)
raster::crs(ras)<-paste0("EPSG:", ras.info$crs) #set the raster projection


ras[]<-NA
pixels<-dbGetQuery(userdb, paste0("select pixelid from pixels where yieldid_trans in (", paste(outs$yc, collapse = ', '), ");"))
ras[pixels$pixelid]<-1
writeRaster(ras, "test.tif", overwrite = TRUE)
