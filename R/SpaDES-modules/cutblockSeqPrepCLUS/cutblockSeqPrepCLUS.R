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
  reqdPkgs = list("rpostgis", "sp","sf", "dplyr"),
  parameters = rbind( 
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter("simulationTimeStep", "numeric", 1, NA, NA, "This describes the simulation time step interval"),
    defineParameter("dbName", "character", "postgres", NA, NA, "The name of the postgres dataabse"),
    defineParameter("dbHost", "character", 'localhost', NA, NA, "The name of the postgres host"),
    defineParameter("dbPort", "character", '5432', NA, NA, "The name of the postgres port"),
    defineParameter("dbUser", "character", 'postgres', NA, NA, "The name of the postgres user"),
    defineParameter("dbPassword", "character", 'postgres', NA, NA, "The name of the postgres user password"),
    defineParameter("nameBoundaryFile", "character", NULL, NA, NA, desc = "Name of the boundary file"),
    defineParameter("nameBoundaryColumn", "character", NULL, NA, NA, desc = "Name of the column within the boundary file that has the boundary name"),
    defineParameter("nameBoundary", "character", NULL, NA, NA, desc = "Name of the boundary - a spatial polygon within the boundary file"),
    defineParameter("nameBoundaryGeom", "character", NULL, NA, NA, desc = "Name of the geom column in the boundary file"),
    defineParameter("startTime", "numeric", start(sim), NA, NA, desc = "Simulation time at which to start"),
    defineParameter("endTime", "numeric", end(sim), NA, NA, desc = "Simulation time at which to end"),
    defineParameter("cutblockSeqInterval", "numeric", 1, NA, NA, desc = "This describes the interval for the sequencing or scheduling of the cutblocks"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", 1, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "numeric", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput("nameBoundaryFile", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundary", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundaryColumn", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundaryGeom", objectClass ="character", desc = NA, sourceURL = NA)
    #expectsInput(objectName = NA, objectClass = NA, desc = NA, sourceURL = NA)
  ),
  outputObjects = bind_rows(
    createsOutput("landings", "SpatialPoints", "This describes a series of point locations representing the cutblocks or their landings", ...)
    #createsOutput(objectName = NA, objectClass = NA, desc = NA)
  )
))

doEvent.cutblockSeqPrepCLUS = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    
    init = {
      sim<-cutblockSeqPrepCLUS.Init(sim)
      sim <- scheduleEvent(sim, start(sim), "cutblockSeqPrepCLUS", "cutblockSeqPrep")
    },
    
    cutblockSeqPrep = {
      sim<-cutblockSeqPrepCLUS.getLandings(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim)$cutblockSeqInterval, "cutblockSeqPrepCLUS", "cutblockSeqPrep")
    },
    
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

cutblockSeqPrepCLUS.Init <- function(sim) {
  #Get the XY location of the historical cutblock landings
  sim<-cutblockSeqPrepCLUS.getHistoricalLandings(sim)
  return(invisible(sim))
}

### Set the list of the cutblock locations
cutblockSeqPrepCLUS.getHistoricalLandings <- function(sim) {
  sim$histLandings<-getTableQuery(paste0("SELECT harvestyr, x, y from cutseq, 
              (Select ", params(sim)$.globals$nameBoundaryGeom, " FROM ", params(sim)$.globals$nameBoundaryFile, " WHERE ", params(sim)$.globals$nameBoundaryColumn," = '", params(sim)$.globals$nameBoundary,"') as h
              WHERE h.",params(sim)$.globals$nameBoundaryGeom," && cutseq.point 
              AND ST_Contains(h.",params(sim)$.globals$nameBoundaryGeom ," ,cutseq.point)
              ORDER BY harvestyr"))
  if(length(sim$histLandings)==0){ sim$histLandings<-NULL}
  return(invisible(sim))
}

### Set a list of cutblock locations as a Spatial Points object
cutblockSeqPrepCLUS.getLandings <- function(sim) {
  if(!is.null(sim$histLandings)){
    landings<-sim$histLandings %>% dplyr::filter(harvestyr == time(sim) + 1980) ##starting at 1980
    if(nrow(landings)>0){
      print(paste0('geting landings in: ', time(sim)))
      sim$landings<- SpatialPoints(coords = as.matrix(landings[,c(2,3)]), proj4string = CRS("+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0 +datum=NAD83
                          +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0"))
    }else{
      print(paste0('NO landings in: ', time(sim)))
    }
    sim$landingsSimulated<-SpatialPoints(coords = as.matrix(sim$histLandings[,c(2,3)]), proj4string = CRS("+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0 +datum=NAD83
                          +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0"))
  }else{
    #ras =raster(sim$bbox, res =100, vals =0, crs = CRS("+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0 +datum=NAD83
    #                      +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0") )
    #sim$landings<- xyFromCell(ras, as.integer(sample(1:ncell(ras), 5)), spatial=TRUE)
  }
  return(invisible(sim))
}

getTableQuery<-function(sql){
  conn<-dbConnect(dbDriver("PostgreSQL"), host='localhost', dbname = 'clus', port='5432' ,user='app_user' ,password='clus')
  on.exit(dbDisconnect(conn))
  dbGetQuery(conn, sql)
}

