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

defineModule(sim, list(
  name = "disturbanceCalcCLUS",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.3", disturbanceCalcCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "disturbanceCalcCLUS.Rmd"),
  reqdPkgs = list("raster"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput(objectName = "roads", objectClass = "RasterLayer", desc = NA, sourceURL = NA),
    expectsInput(objectName = "harvestUnits", objectClass = "RasterLayer", desc = NA, sourceURL = NA)
  ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput("distInfo", "list", "Summary per simulation year of the disturbances")
  )
))

## event types
#   - type `init` is required for initialiazation

doEvent.disturbanceCalcCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim$distInfo <- list() #instantiate a new list
      sim <- scheduleEvent(sim, P(sim, "roadCLUS", "roadSeqInterval"), "disturbanceCalcCLUS", "roads")
      sim <- scheduleEvent(sim, P(sim, "blockingCLUS", "blockSeqInterval"), "disturbanceCalcCLUS", "cutblocks")
      sim <- scheduleEvent(sim, end(sim), "disturbanceCalcCLUS", "analysis", 50)
    },
    roads = {
      sim<- disturbanceCalcCLUS.roads(sim)
      sim <- scheduleEvent(sim, P(sim, "roadCLUS", "roadSeqInterval"), "disturbanceCalcCLUS", "roads")
    },
    cutblocks = {
      sim<- disturbanceCalcCLUS.cutblocks(sim)
      sim <- scheduleEvent(sim, P(sim, "blockingCLUS", "blockSeqInterval"), "disturbanceCalcCLUS", "cutblocks")
    },
    analysis = {
      sim<- disturbanceCalcCLUS.analysis(sim)
    },
    
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  return(invisible(sim))
}
disturbanceCalcCLUS.patch <- function(sim) {
  #calculates the patch size distributions
  #For each landscape unit that has a patch size constraint
  # Make a graph 
  # igraph::induce_subgraph based on a SELECT pixelids from pixels where age < 40
  # determine the number of distinct components using igraph::component_distribution
  return(invisible(sim))
}

disturbanceCalcCLUS.roads <- function(sim) {
  if(!is.null(sim$roads)){
    x<-sim$roads
    x[x[] > 0] <-1
    sim$distInfo$roads[[(time(sim))]]<- raster::cellStats(x, sum) 
  }
  return(invisible(sim))
}

disturbanceCalcCLUS.cutblocks <- function(sim) {
  if(!is.null(sim$harvestUnits)){
    x<-sim$harvestUnits
    x[x[] > 0] <-1
    sim$distInfo$cutblocks[[(time(sim))]]<- raster::cellStats(x, sum)
  }

  return(invisible(sim))
}

disturbanceCalcCLUS.analysis <- function(sim) {
  print(sim$distInfo)
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  
  if(!suppliedElsewhere("roads", sim)){
      sim$roads<-NULL
  }
  
  if(!suppliedElsewhere("harvestUnits", sim)){
    sim$harvestUnits<-NULL
  }
  
  return(invisible(sim))
}

