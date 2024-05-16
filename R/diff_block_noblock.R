library(data.table)
library(raster)
source("C:/Users/klochhea/castor/R/functions/R_Postgres.R")


withblock <- dbConnect(RSQLite::SQLite(), dbname = "C:/Users/klochhea/castor/stsm_compare_blocks_noroads_castordb.sqlite")
noblock <- dbConnect(RSQLite::SQLite(), dbname = "C:/Users/klochhea/castor/stsm_compare_noroads_noblocks_castordb_age0.sqlite")  
ras.info<-dbGetQuery(withblock, "Select * from raster_info limit 1;")
ras<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0, crs = 3005)


wb<-data.table(dbGetQuery(withblock, "select pixelid, vol as volwb from pixels order by pixelid"))
nb<-data.table(dbGetQuery(noblock, "select pixelid, vol as volnb from pixels order by pixelid"))


all<-merge(wb,nb, by = "pixelid")
diff<-all[ volwb != volnb,]
ras2<-ras
ras2[diff$pixelid]<- 1
writeRaster(ras2, "rasmissing.tif")  

diffwblock<-dbGetQuery(withblock, paste0("select * from pixels where pixelid in(", paste(diff$pixelid, sep = "", collapse = ","), ");"))
