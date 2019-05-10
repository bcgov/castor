
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
  name = "forestryCLUS",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhley", email = "tyler.muhley@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.3", forestryCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "forestryCLUS.Rmd"),
  reqdPkgs = list(),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant"),
    defineParameter("harvestPriority", "character", "age DESC", NA, NA, "This sets the order from which harvesting should be conducted. Greatest priority first. DESC is decending, ASC is ascending")
    
    ),
  inputObjects = bind_rows(
    expectsInput(objectName ="clusdb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates clus realted information", sourceURL = NA),
    expectsInput(objectName = "harvestFlow", objectClass = "data.table", desc = "Time series table of the total targeted harvest in m3", sourceURL = NA)
  ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = "compartment_list", objectClass = "character", desc = NA),
    createsOutput(objectName = "landings", objectClass = "SpatialPoints", desc = NA),
    createsOutput(objectName = "harvestPeriod", objectClass = "integer", desc = NA)
  )
))

doEvent.forestryCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- forestryCLUS.Init(sim) #note target flow is a data.table object-- dont need to get it.
      sim <- scheduleEvent(sim, time(sim), "forestryCLUS", "schedule")
    },
    schedule = {
      sim<-forestryCLUS.getHarvestQueue(sim) # This returns a candidate set of blocks or pixels that could be harvested
         
        #sim<-forestryCLUS.checkAreaConstraints(sim)
         #sim<-forestryCLUS.checkYieldConstraints(sim)
         #sim<-forestryCLUS.harvest(sim) # get the queue
         #sim<-forestryCLUS.checkAdjConstraints(sim)# check the constraints, removing from the queue adjacent blocks
      
      sim <- scheduleEvent(sim, time(sim) + sim$harvestPeriod, "forestryCLUS", "schedule")
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

forestryCLUS.Init <- function(sim) {
  sim$harvestPeriod <- 1
  sim$compartment_list<-unique(harvestFlow[, compartment])
  return(invisible(sim))
}


forestryCLUS.getHarvestQueue<- function(sim) {
  for(compart in sim$compartment_list){
    # Determine if there is volume to harvest
    harvestTarget<-harvestFlow[compartment == compart]$Flow[(time(sim) + sim$harvestPeriod)]
    
    if(harvestTarget > 0){
      partition<-harvestFlow[compartment==compart, partition][(time(sim) + sim$harvestPeriod)]
      #Queue pixels for harvesting
      queue<-dbGetQuery(sim$clusdb, paste0("SELECT pixelid, blockid FROM pixels where 
                                         compartid = ",compart ," AND thlb > 0 AND
                                         zone_const = 0 AND", 
                                         partition, " GROUP BY blockid ORDER BY ", 
                                         P(sim, "forestryCLUS", "harvestPriority")))
    }
  }
  return(invisible(sim))
}


forestryCLUS.checkZoneConstraints<- function(sim) {
  #Update Constraints
  #For each zone check if a constraint is violated
  #  assign a zone_const = 1
  
  #Have a generic query updated for each type of constraint
  #1. Area based constraints
  #2. Yield based constraints
  #3. Adjacency based constraints
  
  #UPDATE zone set area = (SELECT  COUNT(*) AS area FROM pixels WHERE age > 140 GROUP BY zoneid)
  
  #UPDATE pixels SET zone_const = 1 WHERE pixelid IN 
  #(SELECT pixelid FROM pixels WHERE age > 140 AND zoneid = 1 ORDER BY age limit 67 )    
  
  return(invisible(sim))
}

forestryCLUS.harvest<- function(sim) {
  target<-harvestFlow[, Flow][time(sim) + 1]
 
  return(invisible(sim))
}




.inputObjects <- function(sim) {
  return(invisible(sim))
}

