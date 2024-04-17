setwd('C:/Users/klochhea/castor/R/scenarios/tutorial')
con = dbConnect(RSQLite::SQLite(), dbname = "bulkley_castordb.sqlite")
ras.info<-dbGetQuery(con, "SELECT * FROM raster_info where name = 'ras';")
print(ras.info)
ras<-rast(xmin= ras.info$xmin, xmax=ras.info$xmax, ymin=ras.info$ymin, ymax=ras.info$ymax, nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow)
crs(ras) <-st_crs(as.integer(ras.info$crs))$wkt