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
              person("Tyler", "Muhley", email = "tyler.muhley@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.3", disturbanceCalcCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "disturbanceCalcCLUS.Rmd"),
  reqdPkgs = list(),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput(objectName = "roads", objectClass = "RasterLayer", desc = NA),
    expectsInput(objectName = "harvestUnits", objectClass = "RasterLayer", desc = NA)
  ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    
  )
))

## event types
#   - type `init` is required for initialiazation

doEvent.disturbanceCalcCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- scheduleEvent(sim, P(sim)$.plotInitialTime, "disturbanceCalcCLUS", "roads")
      sim <- scheduleEvent(sim, P(sim)$.saveInitialTime, "disturbanceCalcCLUS", "cutblocks")
    },
    roads = {
      sim <- scheduleEvent(sim, P(sim)$.plotInitialTime, "disturbanceCalcCLUS", "roads")
    },
    cutblocks = {
      sim <- scheduleEvent(sim, P(sim)$.saveInitialTime, "disturbanceCalcCLUS", "cutblocks")
    },
    
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  return(invisible(sim))
}

roads <- function(sim) {
  return(invisible(sim))
}
cutblocks <- function(sim) {
  return(invisible(sim))
}



.inputObjects <- function(sim) {
  
  if(!suppliedElsewhere("roads", sim)){
      sim$roads<-0
  }
  
  if(!suppliedElsewhere("harvestUnits", sim)){
    sim<-harvestUnits<-0
  }
  
  return(invisible(sim))
}

