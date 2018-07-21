# Copyright 2018 Province of British Columbia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

#===========================================================================================
defineModule(sim, list(
  name = "cutblockSeqPrepCLUS",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = person("First", "Last", email = "first.last@example.com", role = c("aut", "cre")),
  childModules = character(0),
  version = list(SpaDES.core = "0.1.1", cutblockSeqPrepCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "cutblockSeqPrepCLUS.Rmd"),
  reqdPkgs = list("rpostgis", "sp","sf","rgdal", "spex"),
  parameters = rbind( 
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter("dbName", "character", "postgres", NA, NA, "The name of the postgres dataabse"),
    defineParameter("dbHost", "character", 'localhost', NA, NA, "The name of the postgres host"),
    defineParameter("dbPort", "character", '5432', NA, NA, "The name of the postgres port"),
    defineParameter("dbUser", "character", 'postgres', NA, NA, "The name of the postgres user"),
    defineParameter("dbPassword", "character", 'postgres', NA, NA, "The name of the postgres user password"),
    defineParameter("dbGeom", "character", 'geom', NA, NA, "The name of the postgres file geom column"),
    defineParameter("nameBoundaryFile", "character", 'name', NA, NA, desc = "Name of the boundary file"),
    defineParameter("nameBoundaryColumn", "character", 'name', NA, NA, desc = "Name of the column within the boundary file that has the boundary name"),
    defineParameter("nameBoundary", "character", 'name', NA, NA, desc = "Name of the boundary - a spatial polygon within the boundary file"),
    defineParameter("nameBoundaryGeom", "character", 'name', NA, NA, desc = "Name of the geom column in the boundary file"),
    defineParameter("startTime", "numeric", start(sim), NA, NA, desc = "Simulation time at which to start"),
    defineParameter("endTime", "numeric", end(sim), NA, NA, desc = "Simulation time at which to end"),
    defineParameter("cutblockSeqInterval", "numeric", 1, NA, NA, desc = "This describes the interval for the sequencing or scheduling of the cutblocks"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "numeric", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput("nameBoundaryFile", "character", "The boundaries file to include in the analysis", sourceURL = NA),
    expectsInput("nameBoundary", "character", "The boundaries to include in the analysis", sourceURL = NA),
    expectsInput("nameBoundaryColumn", "character", "The column name in the boundary file to query on", sourceURL = NA),
    expectsInput("nameBoundaryGeom", "character", "The name of the geometry column within the boundary file", sourceURL = NA)
    #expectsInput(objectName = NA, objectClass = NA, desc = NA, sourceURL = NA)
  ),
  outputObjects = bind_rows(
    createsOutput("landings", "SpatialPoint", "This describes a series of point locations representing the cutblocks or their landings", ...)
    #createsOutput(objectName = NA, objectClass = NA, desc = NA)
  )
))

doEvent.cutblockSeqPrepCLUS = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    init = {
      sim <- scheduleEvent(sim, P(sim)$cutblockSeqInterval, "cutblockSeqPrepCLUS", "cutblockSeqPrep")
      # schedule future event(s)
      #sim <- scheduleEvent(sim, P(sim)$.plotInitialTime, "cutblockSeqPrepCLUS", "plot")
      #sim <- scheduleEvent(sim, P(sim)$.saveInitialTime, "cutblockSeqPrepCLUS", "save")
    },
    cutblockSeqPrep = {
      #plot(sim$landings)
      #sim <- scheduleEvent(sim, P(sim)$cutblockSeqInterval, "cutblockSeqPrepCLUS", "cutblockSeqPrep")
    },
    endConnect = {
      sim <- sim$cutblockSeqPrepCLUSdbDisconnect(sim)
    },    
    save = {
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}
Init <- function(sim) {
  return(invisible(sim))
}

### template for save events
Save <- function(sim) {
  sim <- saveFiles(sim)
  return(invisible(sim))
}

cutblockSeqPrepCLUSgetHistoricalLandings <- function(sim) {
  boundaries<-getSpatialQuery(paste0("SELECT harvestyr, x, y, point from cutseq, 
              (Select ", P(sim)$nameBoundaryGeom, " FROM ", P(sim)$nameBoundaryFile, " WHERE ", P(sim)$nameBoundaryColumn," = '", P(sim)$nameBoundary,"') as h
              WHERE h.",P(sim)$nameBoundaryGeom," && cutseq.point 
              AND ST_Contains(h.",P(sim)$nameBoundaryGeom ," ,cutseq.point)
              ORDER BY harvestyr"))
  #keep the landings as points - maybe this will change later?
  sim$landings<-boundaries
}

cutblockSeqPrepCLUSgetRoads <- function(sim) {
  roads<-getSpatialQuery(paste0("SELECT clus_road_class, wkb_geometry FROM pre_roads, 
          (SELECT ", P(sim)$nameBoundaryGeom, " FROM ", P(sim)$nameBoundaryFile, " WHERE ", P(sim)$nameBoundaryColumn , " = '", P(sim)$nameBoundary, "') as h 
          WHERE h.",P(sim)$nameBoundaryGeom,"  && pre_roads.wkb_geometry 
          AND ST_Contains(h.", P(sim)$nameBoundaryGeom, ", pre_roads.wkb_geometry);"))
  #Convert to polygons 
  roads<-st_buffer(getSpatialQuery("SELECT clus_road_class, wkb_geometry FROM pre_roads,(SELECT geom FROM gcbp_carib_polygon 
                         WHERE herd_name = 'Hart Ranges') as h 
                         WHERE h.geom  && pre_roads.wkb_geometry 
                         AND ST_Contains(h.geom, pre_roads.wkb_geometry);"), 10)
  
  plot(roads)
  ras.temp<-raster(roads, resolutio = c(100,100), vals =0)
  ras.temp[] <- 1:ncell(ras.temp)
  rsp <- spex::polygonize(ras.temp)
  
  plot(rsp)
  
  library(fasterize)
  library(spex)
  
  
  
  roads_sp<-fasterize(st_buffer(roads,10), ras.temp)
  crs(roads_sp)
  plot(roads_sp)
  roads.raster<-raster()
  extent(roads.raster)<-extent(roads_sp)
  res(roads.raster)<-100
  system.time({ roads.r<-rasterize(roads_sp, roads.raster, field='length_km', fun='sum')})
  plot(roads.r)
  library(mapview)
  mapview(roads_sp)
registerDoMC(3)
  library('parallel')
  library(raster)
  library(sf)
    # Calculate the number of cores
  no_cores <- detectCores() - 1
  # Number of polygons features in SPDF
  features <- 1:nrow(roads_sp[,])
  
  # Split features in n parts
  n <- 2
  parts <- split(features, cut(features, n))
  cl <- makeCluster(no_cores)
  roads_sp<-as_Spatial(st_buffer(roads,10))
  roads.raster<-raster()
  extent(roads.raster)<-extent(roads_sp)
  res(roads.raster)<-100
  # Parallelize rasterize function
  clusterExport(cl, "roads_sp")
  clusterExport(cl, "parts")
  clusterExport(cl, "roads.raster")
  system.time(rParts <- parLapply(cl = cl, X = 1:n, fun = function(x) raster::rasterize(roads_sp[parts[[x]],], roads.raster, field='length_km', fun='sum')))
  stopCluster(cl)
  rMerge <- do.call(merge, rParts)
  plot(rMerge)
  writeRaster(roads.r, filename="C:/Users/KLOCHHEA/landscape.tif", options="INTERLEAVE=BAND", overwrite=TRUE)

  sim$preRoads<-test
}

.inputObjects <- function(sim) {
  # if (!('defaultColor' %in% sim$.userSuppliedObjNames)) {
  #  sim$defaultColor <- 'red'
  # }
  if(is.null(sim$landings)){
    cutblockSeqPrepCLUSgetHistoricalLandings(sim)
  }
  if(is.null(sim$existingRoads)){
    cutblockSeqPrepCLUSgetRoads(sim)
  }
  return(invisible(sim))
}

getSpatialQuery<-function(sql){
  conn<-dbConnect(dbDriver("PostgreSQL"), host='DC052586.idir.bcgov', dbname = 'clus', port='5432' ,user='app_user' ,password='clus')
  on.exit(dbDisconnect(conn))
  st_read(conn, query = sql)
}

getTableQuery<-function(sql){
  conn<-dbConnect(dbDriver("PostgreSQL"), host='DC052586.idir.bcgov', dbname = 'clus', port='5432' ,user='app_user' ,password='clus')
  on.exit(dbDisconnect(conn))
  dbGetQuery(conn, sql)
}

getRasterQuery<-function(sql){
  conn<-dbConnect(dbDriver("PostgreSQL"), host='DC052586.idir.bcgov', dbname = 'clus', port='5432' ,user='app_user' ,password='clus')
  on.exit(dbDisconnect(conn))
  pgGetRast(conn, sql)
}
