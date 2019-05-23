
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
    expectsInput(objectName = "harvestFlow", objectClass = "data.table", desc = "Time series table of the total targeted harvest in m3", sourceURL = NA),
    expectsInput(objectName ="growingStockReport", objectClass = "data.table", desc = NA, sourceURL = NA)
    
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
      sim <- forestryCLUS.setConstraints(sim) 
      sim <- scheduleEvent(sim, time(sim), "forestryCLUS", "schedule")
    },
    schedule = {
      #sim<-forestryCLUS.getHarvestQueue(sim) # This returns a candidate set of blocks or pixels that could be harvested
      #sim<-forestryCLUS.checkAreaConstraints(sim)
      #sim<-forestryCLUS.checkAdjConstraints(sim)# check the constraints, removing from the queue adjacent blocks
      
      sim <- scheduleEvent(sim, time(sim) + sim$harvestPeriod, "forestryCLUS", "schedule")
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

forestryCLUS.Init <- function(sim) {
  sim$harvestPeriod <- 1 #This will be able to change in the future to 5 year or decadal
  sim$compartment_list<-unique(harvestFlow[, compartment]) #Used in a few functions this calling it once here - its currently static throughout the sim
  dbExecute(sim$clusdb, "VACUUM;") #Clean the db before starting the simulation
  return(invisible(sim))
}

forestryCLUS.setConstraints<- function(sim) {
  print("...setting constraints")
  dbExecute(sim$clusdb, "UPDATE pixels SET zone_const = 0 WHERE zone_const = 1")
  print("....assigning zone_const")
  zones<-dbGetQuery(sim$clusdb, "SELECT zone_column FROM zone")
  for(i in 1:nrow(zones)){
      query_parms<-data.table(dbGetQuery(sim$clusdb, paste0("SELECT t_area, type, zoneid, variable, zone_column, percentage, threshold, 
                                                        CASE WHEN type = 'ge' THEN ROUND((percentage*1.0/100)*t_area, 0) ELSE 
                                                        ROUND((1-(percentage*1.0/100))*t_area, 0) END AS limits
                                                        FROM zoneConstraints WHERE zone_column = '", zones[[1]][i],"' AND percentage < 10;")))
      switch(
        as.character(query_parms[1, "type"]),
        ge = {
          
          sql<-paste0("UPDATE pixels 
                      SET zone_const = 1
                      WHERE pixelid IN ( 
                      SELECT pixelid FROM pixels WHERE own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid", 
                      " ORDER BY CASE WHEN ",as.character(query_parms[1, "variable"])," > :threshold THEN 0 ELSE 1 END, thlb, zone_const DESC, ", as.character(query_parms[1, "variable"])," DESC
                      LIMIT :limits);")
          
        },
        le = {
          sql<-paste0("UPDATE pixels 
                      SET zone_const = 1
                      WHERE pixelid IN ( 
                      SELECT pixelid FROM pixels WHERE own = 1 AND ",  as.character(query_parms[1, "zone_column"])," = :zoneid",
                      " ORDER BY CASE WHEN ",as.character(query_parms[1, "variable"])," < :threshold THEN 1 ELSE 0 END, thlb, zone_const DESC,", as.character(query_parms[1, "variable"])," 
                      LIMIT :limits);")
          
        },
        warning(paste("Undefined 'type' in zoneConstraints"))
      )
      #Update clusdb
      dbBegin(sim$clusdb)
        rs<-dbSendQuery(sim$clusdb, sql, query_parms[,c("zoneid", "threshold", "limits")])
      dbClearResult(rs)
      dbCommit(sim$clusdb)
  }
  
  #TODO: Check that a WITH pixels() INSERT Or REPLACE INTO pixels (zone_const) cte could work?
  return(invisible(sim))
}

forestryCLUS.getHarvestQueue<- function(sim) {
  #Right now its looping by compartment -- could have it parallel?
  for(compart in sim$compartment_list){
    
    #TODO: Need to figure out the harvest period mid point to reduce bias in reporting
    harvestTarget<-harvestFlow[compartment == compart]$Flow[(time(sim) + sim$harvestPeriod)]
    
    if(harvestTarget > 0){# Determine if there is a demand for volume to harvest
      
      partition<-harvestFlow[compartment==compart, partition][(time(sim) + sim$harvestPeriod)]
      harvestPriority<-harvestFlow[compartment==compart, partition][(time(sim) + sim$harvestPeriod)]
      #Queue pixels for harvesting
      queue<-as.list(unlist(dbGetQuery(sim$clusdb, paste0("SELECT pixelid, blockid FROM pixels WHERE 
                                         compartid = ", compart ," AND 
                                         zone_const = 0 AND  ", 
                                         partition, " ORDER BY ", 
                                         harvestPriority, ", blockid")), use.names = FALSE))
    if(nrow(queue) == 0) {
        next #no cutblocks in the queue
    }else{
        if(queue[2] > 0 ){
          #If the blockid is in the adjaceny list?
        }else{
          #create a landing to harvest from
          #Use the spread function
        }
      }
    }
  }
  return(invisible(sim))
}

forestryCLUS.harvest<- function(sim) {
  target<-harvestFlow[, Flow][time(sim) + 1]
 
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  return(invisible(sim))
}

