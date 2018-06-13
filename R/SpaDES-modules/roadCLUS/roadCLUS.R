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
    defineParameter("roadingInterval", "numeric", 10, NA, NA, "This describes the simulation time at which roads should be build"),
    defineParameter(".plotInitialTime", "numeric", start(sim), NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", 1, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "numeric", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    #expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput(objectName = c("landscape", "landings"), objectClass = c("RasterStack", "SpatialPoints"), desc = NA, sourceURL = NA)
  ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = NA, objectClass = NA, desc = NA)
  )
))

## event types
#   - type `init` is required for initialiazation

doEvent.roadCLUS = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    init = {
      ### check for more detailed object dependencies:
      checkObject(sim, name = "landscape")
      ## set seed
      set.seed(sim$.seed)
      # schedule future event(s)
      sim <- scheduleEvent(sim, P(sim)$startTime, "roadCLUS", "plot.init")
      sim <- scheduleEvent(sim, P(sim)$startTime, "roadCLUS", "buildRoads")
    },
    plot.init = {
      plot(raster(sim$landscape,1), main = "Initial Road Network")
      plot(raster(sim$landscape,4), col = "blue", add=TRUE, legend= FALSE)
      plot(SpatialPoints(sim$landings), add=TRUE, pch =20, col = "red", cex = 1.5)
      sim <- scheduleEvent(sim, time(sim) +  P(sim)$.plotInterval, "roadCLUS", "plot.sim")
    },
    plot.sim = {
      # do stuff for this event
      dev.new()
      plot(raster(sim$landscape,1), main = "Simulated Roads")
      plot(raster(sim$landscape,4), add=TRUE, legend=FALSE, col = "black")
      plot(SpatialPoints(sim$landings), add=TRUE, pch=20, col="red", cex = 1.5)
      sim <- scheduleEvent(sim, time(sim) + P(sim)$.plotInterval, "roadCLUS", "plot.sim")
    },
    buildRoads = {
      sim <- sim$roadCLUS.getCostSurface(sim)
      sim <- sim$roadCLUS.getMST(sim)
      sim <- sim$roadCLUS.buildRoads(sim)
      sim <- scheduleEvent(sim, P(sim)$roadingInterval, "roadCLUS", "buildRoads")
    },
    save = {

    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

## event functions
#   - follow the naming convention `modulenameEventtype()`;
#   - `modulenameInit()` function is required for initiliazation;
#   - keep event functions short and clean, modularize by calling subroutines from section below.

### template for save events
Save <- function(sim) {
  sim <- saveFiles(sim)
  return(invisible(sim))
}

### template for plot events
Plot <- function(sim) {
  return(invisible(sim))
}

roadCLUS.getMST = function(sim){
  #CalcCostDistances from gDistance
  cDist<-costDistance(sim$trCost, sim$landings)
  G = graph.adjacency(as.matrix(cDist),weighted=TRUE,mode="upper")
  sim$T = mst(G,weighted=TRUE)
  return(invisible(sim))
}
roadCLUS.getCostSurface<- function(sim){
  rclmat <- matrix(c(1, 1, 0), ncol=3, byrow=TRUE)
  cost<-raster::reclassify(x=raster::raster(sim$landscape,4), rcl=rclmat, include.lowest =TRUE,right =NA)
  cost[is.na(cost)]<-cellStats(raster::raster(sim$landscape,1), stat=max)
  costNew<-raster(sim$landscape,1)+cost^1.2
  ## Need a better function for a cost surface - Toblers? Economics?
  #sim$landscape<- stack(raster(sim$landscape,1),raster(sim$landscape,2),raster(sim$landscape,3),raster(sim$landscape,1)+cost^1.2)
  ## Produce transition matrices, and correct because 8 directions
  sim$trCost <- transition(1/costNew, mean, directions=8)
  sim$trCost <- geoCorrection(sim$trCost, type="c")
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
  allRoads<-raster::merge(raster(sim$landscape ,4), newRoads)
  sim$landscape<-raster::dropLayer(sim$landscape,4)
  sim$landscape<-raster::addLayer(sim$landscape,allRoads)
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  if(is.null(sim$landscape)){
    crs <- CRS("+proj=utm +zone=48 +datum=WGS84")
    ras = raster::raster(extent(0, 50, 0, 50),res =1, vals =0, crs = crs )
    set.seed(536)
    DEM<-gaussMap(ras, scale = 50, var = 0.1, speedup = 1)*50000
    forestAge <- gaussMap(ras, scale = 10, var = 0.1, speedup = 1)
    forestAge[] <- round(getValues(forestAge)/3, 1) * 110
    habitatQuality <- (DEM + 10 + (forestAge + 2.5) * 10) / 100
    sim$landscape <-stack(DEM, forestAge, habitatQuality)
    ##Get the transition matrix
    sim$trCost <- gdistance::transition(1/raster(sim$landscape,1), mean, directions=8 )
    sim$trCost <- gdistance::geoCorrection(sim$trCost, type="c")
    ##Create a fake road system
    pts <- cbind(x=as.integer(runif(5,0,50)), y=as.integer(runif(5,0,50)))
    t0<-raster(shortestPath(trCost, c(0,0), pts[2,]))
    t1<-raster(shortestPath(trCost, pts[1,], pts[2,])) 
    t2<-raster(shortestPath(trCost, pts[2,], pts[3,])) 
    t3<-raster(shortestPath(trCost, pts[1,], pts[4,])) 
    t4<-raster(shortestPath(trCost, pts[1,], pts[5,])) 
    sim$landscape = stack(sim$landscape, raster::merge(t0, t2 , t1 , t3, t4 ) )
    names(sim$landscape)<-c("DEM", "forestAge", "habitatQuality", "paths")
  }
  if(is.null(sim$landings)){
    ##Get example landing locations
    sim$landings <- xyFromCell(raster(sim$landscape,1), as.integer(sample(1:ncell(raster(sim$landscape,1)), 5)), spatial=FALSE)
  }
  if(is.null(sim$costSurface)){
    sim$costSurface<-raster(sim$landscape,1) 
    #
  }
  
  return(invisible(sim))
}
### add additional events as needed by copy/pasting from above
