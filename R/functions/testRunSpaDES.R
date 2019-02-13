
library(SpaDES.core)
source("C:/Users/KLOCHHEA/clus/R/functions/R_Postgres.R")

moduleDir <- file.path("C:/Users/KLOCHHEA/clus/R/SpaDES-modules")
inputDir <- file.path("C:/Users/KLOCHHEA/clus/R") %>% reproducible::checkPath(create = TRUE)
outputDir <- file.path("C:/Users/KLOCHHEA/clus/R")
cacheDir <- file.path("C:/Users/KLOCHHEA/clus/R")
times <- list(start = 0, end = 15)
parameters <- list(
  .progress = list(type = NA, interval = NA),
  .globals = list(),
  dataLoaderCLUS = list(nameBoundaryFile = "gcbp_carib_polygon", nameBoundaryColumn = "herd_name",
                        dbName = 'clus', nameBoundary ='Telkwa', nameBoundaryGeom = 'geom'),
  blockingCLUS = list(blockMethod = 'dynamic', nameSimilarityRas = 'ras_similar_vri2003', useLandingsArea = TRUE, useSpreadProbRas = TRUE),
  cutblockSeqPrepCLUS = list(queryCutblocks = 'cutseq_centroid', startHarvestYear = 2004, 
                             getArea =TRUE),
  roadCLUS = list(roadMethod = 'mst', nameCostSurfaceRas = 'rd_cost_surface', nameRoads =  'pre_roads_ras')
)
modules <- list("dataLoaderCLUS","cutblockSeqPrepCLUS", "blockingCLUS", "roadCLUS")
objects <- list()
paths <- list(
  cachePath = cacheDir,
  modulePath = moduleDir,
  inputPath = inputDir,
  outputPath = outputDir
)

mySim <- simInit(times = times, params = parameters, modules = modules,
                 objects = objects, paths = paths)


mysimout<-spades(mySim)  


