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
  name = "blockingCLUS",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhley", email = "tyler.muhley@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.1.1", blockingCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "blockingCLUS.Rmd"),
  reqdPkgs = list(),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "numeric", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    #expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput(objectName ="blockMethod", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName ="nameBoundaryFile", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName ="nameBoundary",  objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName ="nameBoundaryColumn", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName ="nameBoundaryGeom", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "landings", objectClass = "SpatialPoints", desc = NA, sourceURL = NA)
  ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = NA, objectClass = NA, desc = NA),
    createsOutput(objectName = "blocks", objectClass = "RasterLayer", desc = NA)
  )
))

doEvent.blockingCLUS = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    init = {
      sim<-blockingCLUS.Init(sim)
      ## set seed
      #set.seed(sim$.seed)
      # schedule future event(s)
      #sim <- scheduleEvent(sim, eventTime = start(sim),  "blockingCLUS", "save.sim")
      sim <- scheduleEvent(sim, eventTime = start(sim), "blockingCLUS", "buildBlocks")

      #sim <- scheduleEvent(sim, P(sim)$.plotInitialTime, "blockingCLUS", "plot")
      #sim <- scheduleEvent(sim, P(sim)$.saveInitialTime, "blockingCLUS", "save")
    },
    plot = {
    },
    save = {
    },
    buildBlocks = {
      if(!is.null(sim$landings)){
        switch(P(sim)$blockMethod,
               pre= {
                 sim <- roadCLUS.spreadBlock(sim)
               } ,
               dynamic ={
               }
        )
        sim <- scheduleEvent(sim, time(sim) + P(sim)$roadSeqInterval, "roadCLUS", "buildBlocks")
      }else{
        sim <- scheduleEvent(sim, time(sim) + P(sim)$roadSeqInterval, "roadCLUS", "buildBlocks")
      }
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}


blockingCLUS.Init <- function(sim) {
  if(is.null(P(sim)$nameBoundaryFile)){
    sim<-blockingCLUS.getBounds(sim) # Get the boundary from which to confine other data
    sim<-blockingCLUS.getTHLB(sim) 
  } else {
    sim<-blockingCLUS.exampleData(sim) # When the user does not supply a spatial bounds
  }
  return(invisible(sim))
}

Save <- function(sim) {
  sim <- saveFiles(sim)
  return(invisible(sim))
}

Plot <- function(sim) {
  return(invisible(sim))
}

### template for your event1
Event1 <- function(sim) {
  return(invisible(sim))
}


.inputObjects <- function(sim) {
  # if (!('defaultColor' %in% sim$.userSuppliedObjNames)) {
  #  sim$defaultColor <- 'red'
  # }
  # ! ----- EDIT BELOW ----- ! #

  return(invisible(sim))
}
### add additional events as needed by copy/pasting from above
