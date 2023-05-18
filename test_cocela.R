library(rJava) #Calling the rJava library instantiates the JVM. Note: cannot instantiate the same JVM on both the cores and the master. 
library(jdx)

.jinit(classpath= paste0(here::here(),"/Java/castor/bin"), parameters="-Xmx2g", force.init = TRUE) #instantiate the JVM
.jaddClassPath("C:/Users/klochhea/castor/Java/castor/sqlite-jdbc-3.41.2.1.jar")
jgc <- function() .jcall("java/lang/System", method = "gc")

cocelaClass<-.jnew("castor.CellularAutomata")
cocelaClass$setRParms(
  convertToJava(as.character("C:/Users/klochhea/castor/R/SpaDES-modules/dataCastor/test_castordb.sqlite")), # db_location
  convertToJava(as.integer(165000)), #harvMin
  convertToJava(as.integer(169000)), #harvMax
  .jfloat(0.8), #growstockPercentage 
  convertToJava(as.integer(100)), # ageThres
  convertToJava(as.integer(50)), # planHorizon
  convertToJava(as.integer(5)), # planLength
  .jfloat(as.numeric(150.0)),# minHarvestVolume 
  .jfloat(0.9), # ageClusterWeight
  .jfloat(0.0) # harvestCluster Weight
)
cocelaClass$getCastorData()
cocelaClass$coEvolutionaryCellularAutomata()
jgc()
rm(cocelaClass)
gc()


