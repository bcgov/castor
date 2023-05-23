library(rJava) #Calling the rJava library instantiates the JVM. Note: cannot instantiate the same JVM on both the cores and the master. 
#library(jdx)

.jinit(classpath= paste0(here::here(),"/Java/castor/bin"), parameters="-Xmx2g", force.init = TRUE) #instantiate the JVM
.jaddClassPath(paste0(here::here(), "/Java/castor/sqlite-jdbc-3.41.2.1.jar"))
jgc <- function() .jcall("java/lang/System", method = "gc")

cocelaClass<-.jnew("castor.CellularAutomata")
cocelaClass$setRParms(
  as.character(paste0(here::here(),"/R/SpaDES-modules/dataCastor/test_castordb.sqlite")), # db_location
  as.integer(165000), #harvMin
  as.integer(169000), #harvMax
  .jfloat(0.8), #growstockPercentage 
  as.integer(100), # ageThres
  as.integer(50), # planHorizon
  as.integer(5), # planLength
  .jfloat(150.0),# minHarvestVolume 
  .jfloat(0.9), # ageClusterWeight
  .jfloat(0.0) # harvestCluster Weight
)
cocelaClass$getCastorData()
cocelaClass$coEvolutionaryCellularAutomata()
jgc()
rm(cocelaClass)
gc()


