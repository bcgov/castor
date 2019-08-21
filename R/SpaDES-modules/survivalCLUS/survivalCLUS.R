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
  name = "survivalCLUS",
  description = "This module calculates adult female caribou survival rate in caribou herd ranges using the model developed by Wittmer et al. 2007.",
  keywords = c ("caribou", "survival", "southern mountain"), # c("insert key words here"),
  authors = c(person(c("Tyler", "Bryon"), "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", survivalCLUS = "0.0.1"),
  spatialExtent = raster::extent (rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list ("citation.bib"),
  documentation = list ("README.txt", "survivalCLUS.Rmd"),
  reqdPkgs = list(),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter ("caribou_herd_density", "numeric", 0.05, 0, 1, "This is the caribou herd density that the user defines. It is necessary to fit the survival model. For now, we are keeping it static, but in the future it could be made dynamic by linking to a population model."),
    # defineParameter (".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    # defineParameter (".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    # defineParameter (".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    # defineParameter (".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    # defineParameter (".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
    calculateInterval
    raster o fboundaries
  ),
  inputObjects = bind_rows(
    #expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput(objectName = "clusdb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the model. This module needs the age variable from the pixels table in the clusdb.', sourceURL = NA)
    ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    #createsOutput(objectName = NA, objectClass = NA, desc = NA)
    createsOutput (objectName = "tableSurvival", objectClass = "data.table", desc = "A data.table object created in the RSQLite clusdb. Consists of survival rate estimates for a herd from the scenario at each time step.")
  )
))

doEvent.survivalCLUS = function (sim, eventTime, eventType) {
  switch (
    eventType,
    init = { # init event: here I want to calculate survival rate at time 0 and save the survival rate estimate
      sim <- survivalCLUS.Init (sim) # this function creates the survival rate data table
      sim <- survivalCLUS.setTablesCLUSdb (sim)  # this function saves the survival rate data table in the clusdb
      sim <- scheduleEvent (sim, time(sim) + P(sim, "survivalCLUS", "calculateInterval"), "survivalCLUS", "calculateSurvival", 8) # schedule the next event 
      sim <- scheduleEvent (sim, end(sim) , "survivalCLUS", "survivalCLUS.setTablesCLUSdb", 8) # schedule the next event
    },
    
    calculateSurvival = { # event: here I want to calculate survival rate at each time interval and save the output
      sim <- survivalCLUS.PredictSurvival (sim) # this function predicts each unique RSF score at each applicable pixelid 
      sim <- survivalCLUS.setTablesCLUSdb (sim) # do I need to do this each time????
      sim <- scheduleEvent (sim, time(sim) + P(sim, "survivalCLUS", "calculateInterval"), "survivalCLUS", "calculateSurvival", 8) # schedule the next calculate RSF event 
    
    },
    
    warning (paste ("Undefined event type: '", current (sim) [1, "eventType", with = FALSE],
                    "' in module '", current (sim) [1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return (invisible (sim))
}

#######################
### event functions ##
######################

survivalCLUS.Init <- function(sim) { # this function creates the survival rate table, calculates survival rate at time = 0, and saves the table to the clusdb


  bounds <- data.table (c (t (raster::as.matrix( 
        RASTER_CLIP2 (srcRaster =P (sim, "survivalCLUS", "raster herd boundaries") , # for each unique herd clip a boundary raster
                      clipper = P (sim, "dataLoaderCLUS", "nameBoundaryFile"),  # by the herd area
                      geom = P (sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                      where_clause =  paste0 (P (sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                      conn = NULL)))))
  dbExecute(sim$clusdb, "ALTEr TABLE pixels ADD COLUMN survbounds integer")
  dbExecute(creat table, group itnger, proportion doulbe, 
  #add to the clusdb
  dbBegin(sim$clusdb)
  rs<-dbSendQuery(sim$clusdb, "Update pixels set survbounds = :V1", bounds)
  dbClearResult(rs)
  dbCommit(sim$clusdb)
       # take the clipped, transposed, raster of each clipped RSF area (default name defined as 'v1'), and create new column(s) in the survival table that indicates to which pixel each RSF applies (value = 1), or not (value = 0, NA)
 
  
 # SECOND: calculate the proportion of forest age 1 to 40 in each herd area - HOW DEFINE HERD AREA?
  sim$survtable <- data.table (dbGetQuery (sim$clusdb, # count the number of pixels of young forest
                                 "SELECT COUNT(*) as propyoungforest FROM pixels WHERE age BETWEEN 1 AND 40 GROUP BY survboiunds") / # divide by
                     dbGetQuery (sim$clusdb, # count the number of pixels in the study area
                                "SELECT COUNT(*) FROM pixels WHERE ???? = 1"))
  
  
  # THIRD: Calculate survival rate in the boundary area using the Wittmer et al. model 
  # The model is a threshold model; if propYoungForest is < 0.09, then forest age has no effect
  # hence the if/else statement below
  
  sim$survtable [propyoungforest < 0.09, survivalinit := 0.42 * P(sim)$caribou_herd_density ]
  sim$survtable [!(propyoungforest < 0.09), survivalinit := (1.91 - (propYoungForest * 0.59) + 
                                                                 (0.42 * P(sim)$caribou_herd_density) ]
  sim$survtable[, time := time(sim)]
  

  return(invisible(sim))
}


survivalCLUS.PredictSurvival <- function(sim) { # this function calculates survival rate at each time interval and saves the table to the clusdb
 
# FIRST: calculate the proportion of forest age 1 to 40 in each herd area - HOW DEFINE HERD AREA?
  new_survtable <- dbGetQuery (sim$clusdb, # count the number of pixels of young forest
                               "SELECT COUNT(*) FROM pixels WHERE age BETWEEN 1 AND 40 GROUP BY ????") / # divide by
                   dbGetQuery (sim$clusdb, # count the number of pixels in the study area
                               "SELECT COUNT(*) FROM pixels WHERE ???? = 1")
  new_survtable [propyoungforest < 0.09, survivalinit := 0.42 * P(sim)$caribou_herd_density ]
  new_survtable [!(propyoungforest < 0.09), survivalinit := (1.91 - (propYoungForest * 0.59) + 
                                                               (0.42 * P(sim)$caribou_herd_density) ]
  new_survtable[, time := time(sim)]

sim$survtable <- rbind(sim$survtable, new_survtable)
  return(invisible(sim))
}


survivalCLUS.setTablesCLUSdb <- function (sim) {
  
 # Set the survival table 

  dbBegin (sim$clusdb)
  rs < -dbSendQuery (sim$clusdb, "INSERT INTO survival (herdid, survivalrate, time) # new db table
                      values (:herdid, :survivalrate, :time)", sim$survival) # from sim object
  dbClearResult (rs)
  dbCommit (sim$clusdb)
  
  rm (rs)
  gc ()
  
}



.inputObjects <- function(sim) {
  
  #cacheTags <- c(currentModule(sim), "function:.inputObjects") ## uncomment this if Cache is being used
  dPath <- asPath(getOption("reproducible.destinationPath", dataPath(sim)), 1)
  message(currentModule(sim), ": using dataPath '", dPath, "'.")


  return(invisible(sim))
}
