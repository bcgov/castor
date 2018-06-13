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
  reqdPkgs = list("rpostgis", "sp","sf","rgdal"),
  parameters = rbind( 
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter("dbName", "character", "postgres", NA, NA, "The name of the postgres dataabse"),
    defineParameter("dbHost", "character", 'localhost', NA, NA, "The name of the postgres host"),
    defineParameter("dbPort", "character", '5432', NA, NA, "The name of the postgres port"),
    defineParameter("dbUser", "character", 'postgres', NA, NA, "The name of the postgres user"),
    defineParameter("dbPassword", "character", 'postgres', NA, NA, "The name of the postgres user password"),
    defineParameter("dbGeom", "character", 'geom', NA, NA, "The name of the postgres file geom column"),
    defineParameter("nameBoundary", "character", 'name', NA, NA, desc = "Name of the boundary file"),
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
    expectsInput("herd", "character", "The herd boundaries to include in the analysis", sourceURL = NA),
    expectsInput("tsa", "list", "The list of tsa's to include in the analysis", sourceURL = NA)
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
      #get the gdal interface
      #install_github("JoshOBrien/gdalUtilities")
      
      sim <- sim$cutblockSeqPrepCLUSdbConnect(sim)
      sim <- scheduleEvent(sim, P(sim)$end, "cutblockSeqPrepCLUS", "endConnect")
      sim <- sim$cutblockSeqPrepCLUSgetBoundaries(sim)
      sim<-sim$cutblockSeqPrepCLUSgetRoads(sim)
      sim <- scheduleEvent(sim, P(sim)$cutblockSeqInterval, "cutblockSeqPrepCLUS", "cutblockSeqPrep")
      sim$landings<-c(1,2)
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

cutblockSeqPrepCLUSdbConnect <- function(sim) {
  sim$conn<-dbConnect("PostgreSQL",dbname= P(sim)$dbName, host=P(sim)$dbHost, port=P(sim)$dbPort ,user=P(sim)$dbUser, password=P(sim)$dbPassword)
  return(invisible(sim))
}

cutblockSeqPrepCLUSdbDisconnect <- function(sim) {
  dbDisconnect(sim$conn)
  return(invisible(sim))
}

cutblockSeqPrepCLUSgetBoundaries <- function(sim) {
  #check to see if the file exists in the output directory. If not make it from the postgres db
  if(!file.exists(paste0(outputDir, "bounds.shp"))){
     tryCatch( {
      boundaries<- pgGetGeom(sim$conn, name=P(sim)$nameBoundary,  geom = P(sim)$dbGeom)
      boundaries<-subset(boundaries , herd_name == P(sim)$herd )
      rgdal::writeOGR(obj=boundaries, dsn=outputDir, layer="bounds", driver="ESRI Shapefile")
      }, error=function(e) 1)
  } else (boundaries<-readOGR(dsn=paste0(outputDir, "/bounds.shp")) )

  #get the extents of the SpatialPolygonsDataFrame
  ext<-extent(boundaries)
  #create blank raster: TOdO change the res as an input by the user? or to match an existing resolution?
  ras<-raster(ext, res =100)
  #rasterize the boundaires
  sim$bounds <- raster::rasterize(boundaries, ras, field=1)
  raster::writeRaster(sim$bounds, filename=paste0(outputDir, "/bounds.tif"), options="INTERLEAVE=BAND", overwrite=TRUE)

  return(invisible(sim))
}

cutblockSeqPrepCLUSgetRoads <- function(sim) {
  #check to see if the file exists in the output directory. If not make it from the postgres db
  if(!file.exists(paste0(outputDir, "bounds.shp"))){
    tryCatch( {
      existingRoads<-pgGetGeom(sim$conn, name=c("public","clus_introads_tsa44"),  geom="wkb_geometry")
      rgdal::writeOGR(obj=existingRoads, dsn=outputDir, layer="roads", driver="ESRI Shapefile")
    }, error=function(e) 1)
  } else (existingRoads<-readOGR(dsn=paste0(outputDir, "/roads.shp")) )
  
  #get the extents of the SpatialPolygonsDataFrame
  ext<-extent(existingRoads)
  #create blank raster: TOdO change the res as an input by the user? or to match an existing resolution?
  ras<-raster(ext, res =100)
  #rasterize the boundaires
  sim$existingRoads <- raster::rasterize(existingRoads, ras, field=1)
  raster::writeRaster(sim$existingRoads, filename=paste0(outputDir, "/roads.tif"), options="INTERLEAVE=BAND", overwrite=TRUE)
  #plot(sim$boundaries)
  plot(sim$existingRoads)
  return(invisible(sim))
}

.inputObjects <- function(sim) {

  # if (!('defaultColor' %in% sim$.userSuppliedObjNames)) {
  #  sim$defaultColor <- 'red'
  # }

  return(invisible(sim))
}
