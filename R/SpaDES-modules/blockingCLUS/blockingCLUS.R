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
  reqdPkgs = list("rJava","jdx","igraph","data.table", "raster"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter("blockSeqInterval", "numeric", 1, NA, NA, "This describes the simulation time at which blocking should be done if dynamically blocked"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "numeric", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    #expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput(objectName ="blockMethod", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName ="boundaryInfo", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName ="landings", objectClass = "SpatialPoints", desc = NA, sourceURL = NA)
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
      switch(P(sim)$blockMethod,
             pre= {
               sim <- blockingCLUS.preBlock(sim)
             } ,
             dynamic ={
               sim <- scheduleEvent(sim, time(sim) + P(sim)$blockSeqInterval, "blockingCLUS", "buildBlocks")
             }
      )
    },
    buildBlocks = {
        sim <- blockingCLUS.spreadBlock(sim)
        sim <- scheduleEvent(sim, time(sim) + P(sim)$blockSeqInterval, "blockingCLUS", "buildBlocks")
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Save <- function(sim) {
  sim <- saveFiles(sim)
  return(invisible(sim))
}

Plot <- function(sim) {
  return(invisible(sim))
}

blockingCLUS.Init <- function(sim) {
  sim<-blockingCLUS.getBounds(sim) # Get the boundary from which to confine the blocking
  #Get the similarity matrix 
  
  
  return(invisible(sim))
}

blockingCLUS.preBlock <- function(sim) {
  print("preBlock")
  .jinit(classpath= paste0(getwd(),"/Java/bin"), parameters="-Xmx5g", force.init = TRUE)
  d<-convertToJava(degree)
  h<-convertToJava(histogram)
  h<-rJava::.jcast(histogram, getJavaClassName(h), convert.array = TRUE)
  to<-.jarray(as.matrix(paths.matrix[,1]))
  from<-.jarray(as.matrix(paths.matrix[,2]))
  weight<-.jarray(as.matrix(paths.matrix[,3]))
  fhClass<-.jnew("forest_hierarchy.Forest_Hierarchy") # creates a forest hierarchy object
  fhClass$setRParms(to, from, weight, d, h) # sets the R parameters <Edges> <Degree> <Histogram>
  fhClass$blockEdges() # creates the blocks
  return(invisible(sim))
}

blockingCLUS.spreadBlock<- function(sim) {
  return(invisible(sim))
}
blockingCLUS.getBounds<-function(sim){
  #The boundary may exist from previous modules?
  if(!suppliedElsewhere("bbox", sim)){
    sim$boundary<-getSpatialQuery(paste0("SELECT * FROM ",  P(sim, "dataLoaderCLUS", "nameBoundaryFile"), " WHERE ",   P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), "= '",  P(sim, "dataLoaderCLUS", "nameBoundary"),"';" ))
    sim$bbox<-st_bbox(sim$boundary)
  }
  return(invisible(sim))
}
### additional functions
source("R/functions/functions.R")


