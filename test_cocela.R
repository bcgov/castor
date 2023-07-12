library(rJava) #Calling the rJava library instantiates the JVM. Note: cannot instantiate the same JVM on both the cores and the master. 
library(DBI)
library(raster)
#library(jdx)

.jinit(classpath= paste0(here::here(),"/Java/castor/bin"), parameters="-Xmx2g", force.init = TRUE) #instantiate the JVM
.jaddClassPath(paste0(here::here(), "/Java/castor/sqlite-jdbc-3.41.2.1.jar"))
jgc <- function() .jcall("java/lang/System", method = "gc")

cocelaClass<-.jnew("castor.CellularAutomata")
cocelaClass$setRParms(
  as.character(paste0(here::here(),"/R/SpaDES-modules/disturbanceCastor/test_castordb.sqlite")), # db_location
  as.integer(290000), #harvMin
  as.integer(309000), #harvMaxm
  .jfloat(0.85), #growstockPercentage 
  as.integer(110), # ageThres
  as.integer(50), # planHorizon
  as.integer(5), # planLength
  .jfloat(150.0),# minHarvestVolume 
  .jfloat(0.001), # ageClusterWeight
  .jfloat(0.95) # harvestCluster Weight
)
cocelaClass$getCastorData()
cocelaClass$coEvolutionaryCellularAutomata()
jgc()
rm(cocelaClass)
gc()
test()

test<-function(){
userdb <- dbConnect(RSQLite::SQLite(), dbname = paste0(here::here(), "/R/SpaDES-modules/disturbanceCastor/test_castordb.sqlite") ) 
ras.info<-dbGetQuery(userdb, "Select * from raster_info limit 1;")
ras<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0, crs = 3005)
ca<-dbGetQuery(userdb, "select * from ca_result_age order by pixelid;")
dbDisconnect(userdb)

ras[]<-ca$t1
plot(ras)
title("year:5")
ras[]<-ca$t2
plot(ras)
title("year:10")
ras[]<-ca$t3
plot(ras)
title("year:15")
ras[]<-ca$t4
plot(ras)
title("year:20")
ras[]<-ca$t5
plot(ras)
title("year:25")
ras[]<-ca$t6
plot(ras)
title("year:30")
ras[]<-ca$t7
plot(ras)
title("year:35")
ras[]<-ca$t8
plot(ras)
title("year:40")
ras[]<-ca$t9
plot(ras)
title("year:45")
}
test()
