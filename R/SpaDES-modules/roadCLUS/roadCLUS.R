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
# Everything in this file gets sourced during simInit, and all functions and objects
# are put into the simList. To use objects, use sim$xxx, and are thus globally available
# to all modules. Functions can be used without sim$ as they are namespaced, like functions
# in R packages. If exact location is required, functions will be: sim$<moduleName>$FunctionName
defineModule(sim, list(
  name = "roadCLUS",
  description = NA, #"Simulates strategic roads using a single target access problem following Anderson and Nelson 2004",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhley", email = "tyler.muhley@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.1.1", harvestCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "roadCLUS.Rmd"),
  reqdPkgs = list("raster","gdistance", "sp", "latticeExtra"),
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
    defineParameter("nameCostSurfaceRas", "character", NULL, NA, NA, desc = "Name of the cost surface raster"),
    defineParameter("nameRoads", "character", NULL, NA, NA, desc = "Name of the pre-roads raster and schema"),
    defineParameter("roadSeqInterval", "numeric", 1, NA, NA, "This describes the simulation time at which roads should be build"),
    defineParameter(".plotInitialTime", "numeric", 1, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", 1, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "numeric", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    #expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput("nameBoundaryFile", "character", "The boundary table in the db to mask the extent", sourceURL = NA),
    expectsInput("nameBoundary", "character", "The boundary name in the boundary file to include in the analysis", sourceURL = NA),
    expectsInput("nameBoundaryColumn", "character", "The column name in the boundary file to query on", sourceURL = NA),
    expectsInput("nameBoundaryGeom", "character", "The name of the geometry column in the boundary file", sourceURL = NA),
    expectsInput("nameRoads", "character", "The name of the road table in the postgres db", sourceURL = NA),
    expectsInput("nameCostSurfaceRas", "character", "The boundary name in the boundary file to include in the analysis", sourceURL = NA),
    expectsInput(objectName = "landings", objectClass = "SpatialPoints", desc = NA, sourceURL = NA)
  ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = "roads", objectClass = "RasterLayer", desc = NA)
  )
))

## event types
#   - type `init` is required for initialiazation

doEvent.roadCLUS = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    init = {
      ### check for more detailed object dependencies:
      sim<-roadCLUS.Init(sim)
      ## set seed
      #set.seed(sim$.seed)
      # schedule future event(s)
      sim <- scheduleEvent(sim, eventTime = start(sim), "roadCLUS", "buildRoads")
      sim <- scheduleEvent(sim, eventTime = P(sim)$.plotInitialTime, "roadCLUS", "plot.sim")
      
    },
    plot.sim = {
      # do stuff for this event
      sim<-roadCLUS.roadsPlot(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim)$.plotInterval, "roadCLUS", "plot.sim", eventPriority = .normal()+1)
    },
    
    buildRoads = {
      if(!is.null(sim$landings)){
        print(paste0('simulating roads in: ', time(sim)))
        sim <- roadCLUS.updateCostSurface(sim)
        #sim <- sim$roadCLUS.getMST(sim)
        #sim <- sim$roadCLUS.buildRoads(sim)
        sim <- scheduleEvent(sim, time(sim) + P(sim)$roadSeqInterval, "roadCLUS", "buildRoads")
      }else{
        sim <- scheduleEvent(sim, time(sim) + P(sim)$roadSeqInterval, "roadCLUS", "buildRoads")
      }
    },
    save = {

    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

roadCLUS.Init <- function(sim) {
  if(!is.null(P(sim)$nameRoads) && !is.null(P(sim)$nameCostSurfaceRas)){
    #Get the boundary from which to confine the roads
    sim<-roadCLUS.getBounds(sim)
    #Get the existing roads
    sim<-roadCLUS.getRoads(sim)
    #Get the cost surface
    sim<-roadCLUS.getCostSurface(sim)
  } else{
    #When the user does not supply a roads or cost surface table - use the example data
    sim<-roadCLUS.exampleData(sim)
  }
  return(invisible(sim))
}

roadCLUS.roadsPlot<-function(sim){
  Plot(sim$roads, title = "Simulated Roads")
  return(invisible(sim))
}

### Get the boundary raster object and the bounding box extent 
roadCLUS.getBounds<-function(sim){
  #The boundary may exist from previous modules?
  if(is.null(sim$boundary)){
    sim$boundary<-getSpatialQuery(paste0("SELECT * FROM ", P(sim)$nameBoundaryFile, " WHERE ",  P(sim)$nameBoundaryColumn, "= '", P(sim)$nameBoundary,"';" ))
    sim$bbox<-st_bbox(sim$boundary)
  }else{
    sim$bbox<-st_bbox(sim$boundary)
  }
  return(invisible(sim))
}

### Get the rasterized roads layer
roadCLUS.getRoads <- function(sim) {
    sim$roads<-getRasterQuery(P(sim)$nameRoads, sim$bbox)
  return(invisible(sim))
}

### Get the rasterized cost surface
roadCLUS.getCostSurface<- function(sim){
  sim$costSurface<-getRasterQuery(P(sim)$nameCostSurfaceRas, sim$bbox)
  return(invisible(sim))
}

### Set the cost surface used for road projections
roadCLUS.updateCostSurface<- function(sim){
  rclmat <- matrix(c(1, 1, 0), ncol=3, byrow=TRUE)
  print(extent(sim$roads))
  cost<-raster::reclassify(x=sim$roads, rcl=rclmat, include.lowest =TRUE,right =NA)
  print(extent(sim$costSurface))
  cost[is.na(cost)]<-cellStats(sim$costSurface, stat=max)
  costNew<-sim$costSurface+cost^1.2
  ## Need a better function for a cost surface - Toblers? Economics?
  sim$trCost <- transition(1/costNew, mean, directions=8)
  sim$trCost <- geoCorrection(sim$trCost, type="c")
  return(invisible(sim))
}

roadCLUS.getMST = function(sim){
  #CalcCostDistances from gDistance
  cDist<-costDistance(sim$trCost, sim$landings)
  G = graph.adjacency(as.matrix(cDist),weighted=TRUE,mode="upper")
  sim$T = mst(G,weighted=TRUE)
  return(invisible(sim))
}

roadCLUS.buildRoads = function(sim){
  e.T<-get.edges(sim$T,1:ecount(sim$T))
  t.len<-length(e.T)/2
  for(i in 1:t.len){
    #print(sim$landings[e.T[i,1],] )
    p<-shortestPath(sim$trCost, sim$landings[e.T[i,1],], sim$landings[e.T[i,2],])
    newRoad<-raster::raster(p)
    if(i==1){
      newRoads<-newRoad
    } 
    else {
      newRoads<- raster::merge(newRoads, newRoad)
    }
  }
  #Add the new roads back to the paths layer
  sim$roads<-raster::merge(sim$roads, newRoads)
  return(invisible(sim))
}

### Example data for the module to run when user does not supply roads or costSurface information
roadCLUS.exampleData <- function(sim) {
    crs <- CRS("+init=epsg:3005")
    #Match the same extent as the cutblockSeqPrepCLUS module
    ras = raster::raster(sim$bbox, res =100, vals =0, crs = CRS("+init=epsg:3005"))
    sim$costSurface<-gaussMap(ras, scale = 50, var = 0.1, speedup = 1)*50000
    ##Get the transition matrix
    sim$trCost <- gdistance::transition(1/raster(sim$landscape,1), mean, directions=8 )
    sim$trCost <- gdistance::geoCorrection(sim$trCost, type="c")
    ##Create an example road system
    pts <- sim$landings
    t0<-raster(shortestPath(trCost, c(0,0), pts[2,]))
    t1<-raster(shortestPath(trCost, pts[1,], pts[2,])) 
    t2<-raster(shortestPath(trCost, pts[2,], pts[3,])) 
    t3<-raster(shortestPath(trCost, pts[1,], pts[4,])) 
    t4<-raster(shortestPath(trCost, pts[1,], pts[5,])) 
    sim$roads = raster::merge(t0, t2 , t1 , t3, t4 ) 
  return(invisible(sim))
}

### additional functions
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

getRasterQuery<-function(name, bb){
  conn<-dbConnect(dbDriver("PostgreSQL"), host='DC052586.idir.bcgov', dbname = 'clus', port='5432' ,user='app_user' ,password='clus')
  on.exit(dbDisconnect(conn))
  pgGetRast(conn, name, boundary = c(bb[4],bb[2],bb[3],bb[1]))
}