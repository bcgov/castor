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

defineModule (sim, list(
  name = "survivalCLUS",
  description = "This module calculates adult female caribou survival rate in caribou herd ranges using the model developed by Wittmer et al. 2007.",
  keywords = c ("caribou", "survival", "southern mountain", "adult female"), # c("insert key words here"),
  authors = c (person (c("Tyler", "Bryon"), "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre")),
               person ("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character (0),
  version = list (SpaDES.core = "0.2.5", survivalCLUS = "0.0.1"),
  spatialExtent = raster::extent (rep (NA_real_, 4)),
  timeframe = as.POSIXlt (c (NA, NA)),
  timeunit = "year",
  citation = list ("citation.bib"),
  documentation = list ("README.txt", "survivalCLUS.Rmd"),
  reqdPkgs = list (),
  parameters = rbind (
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter ("calculateInterval", "numeric", 1, 1, 5, "The simulation time at which survival rates are calculated"),
    defineParameter ("caribou_herd_density", "numeric", 0.05, 0, 1, "This is the caribou herd density that the user defines. It is necessary to fit the survival model. For now, we are keeping it static, but in the future it could be made dynamic by linking to a population model."),
    #### future improvement here would be to create a parameter that is a table of caribou herd population numbers and/or densities that coudl be input here and applied to the relevant herd ranges in the analysis
    defineParameter ("nameRasCaribouHerd", "character", "ras.caribou_herd", NA, NA, "Name of the raster of the caribou herd boundaries that is stored in the psql clusdb. Created in Params\caribou_herd_raster.rmd.") # could be included in dataLoader instead for easier use in other modules?
    # defineParameter ("tableCaribouHerd", "character", "caribou_herd", NA, NA, "The look up table to convert raster values to caribou herd name labels. The two values required are raster_integer and herd_name. Created in Params\caribou_herd_raster.rmd. I don't think this is needed here? Can be called later as part of data summary?")
    # defineParameter (".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    # defineParameter (".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    # defineParameter (".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    # defineParameter (".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    # defineParameter (".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    #expectsInput ("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput (objectName = "clusdb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the model. This module needs the age variable from the pixels table in the clusdb.', sourceURL = NA)
    ),
  outputObjects = bind_rows(
    #createsOutput ("objectName", "objectClass", "output object description", ...),
    #createsOutput (objectName = NA, objectClass = NA, desc = NA)
    createsOutput (objectName = "tableSurvival", objectClass = "data.table", desc = "A data.table object created in the RSQLite clusdb. Consists of survival rate estimates for each herd in the study area at each time step.")
  )
))

doEvent.survivalCLUS = function (sim, eventTime, eventType) {
  switch (
    eventType,
    init = { # identify herds in the study area, calculate survival rate at time 0 for those herds and save the survival rate estimate
      sim <- survivalCLUS.Init (sim) # identify herds in the study area and calculate survival rate at time 0; instantiate a table to save the survial rate estimates
      sim <- scheduleEvent (sim, time(sim) + P(sim, "survivalCLUS", "calculateInterval"), "survivalCLUS", "calculateSurvival", 8) # schedule the next survival calculation event 
      sim <- scheduleEvent (sim, end(sim) , "survivalCLUS", "saveSurvival", 8) # schedule the save event at the end
    },
    
    calculateSurvival = { # calculate survival rate at each time interval 
      sim <- survivalCLUS.PredictSurvival (sim) # this function calculates survival rate
      sim <- scheduleEvent (sim, time(sim) + P(sim, "survivalCLUS", "calculateInterval"), "survivalCLUS", "calculateSurvival", 8) # schedule the next calculate RSF event 
    },
    
    saveSurvival = { # save the survival rate table to the db for use post-processing in data summary, etc.
      sim <- survivalCLUS.setTablesCLUSdb (sim) 
    },
    
    warning (paste ("Undefined event type: '", current (sim) [1, "eventType", with = FALSE],
                    "' in module '", current (sim) [1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return (invisible (sim))
}

#######################
### Event Functions ##
######################
survivalCLUS.Init <- function (sim) { # this function identifies the caribou herds in the 'study area' creates the survival rate table, calculates survival rate at time = 0, and saves the survival table in the clusdb

  dbExecute (sim$clusdb, "ALTER TABLE pixels ADD COLUMN herd_bounds integer") # add a column to the pixel table that will define the caribou herd area   
  dbExecute (sim$clusdb, "CREATE TABLE survival_caribou (herd_bounds integer, survival_rate double)") # create a new table that will hold the survival rate for each caribou herd
  
  herdbounds <- data.table (c (t (raster::as.matrix ( # clip caribou herd raster by the 'study area' set in dataLoader
                                  RASTER_CLIP2 (srcRaster = P (sim, "survivalCLUS", "nameRasCaribouHerd") , # clip the herd boundary raster; defined in parameters, above
                                                clipper = P (sim, "dataLoaderCLUS", "nameBoundaryFile"),  # by the study area; defined in parameters of dataLoaderCLUS
                                                geom = P (sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                                                where_clause =  paste0 (P (sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                conn = NULL)))))
    
  dbBegin (sim$clusdb) # fire up the db and add the herd boundary values to the pixels table column that was created above
  rs <- dbSendQuery (sim$clusdb, "Update pixels set herd_bounds = :V1", herdbounds) # the default name of the herdbounds column is 'V1'
  dbClearResult (rs)
  dbCommit (sim$clusdb) # commit the new column to the db

  # calculate the proportion of age 1 to 40 year old forest pixels in each herd area in the study area 
  # this SQL statement selects the average value of:
    # cases that meet the case criteria 'when' (case = 1) and
    # cases that do not meet the case criteria 'then' (case = 0)
    # So, if an area of 10 pixels has 4 pixels age 1 to 40, then the statement will return
    # a value of 0.4  = AVG (0,0,1,1,0,1,1,0,0,0)
    # it does this by each herd ('GROUP BY' statement)
  sim$survtable <- data.table (dbGetQuery (sim$clusdb, "SELECT AVG (CASE WHEN age BETWEEN 1 AND 40 THEN 1 ELSE 0 END) FROM pixels GROUP BY herd_bounds"))
  # what is the column name of the output; V1???
  
  # This equation calculates the survival rate in the herd area using the Wittmer et al. model 
  # The model is a threshold model; if the proportion of 1 to 40 year old forest is < 0.09, 
  # then forest age has no effect; hence the two statements below
  sim$survtable [V1 < 0.09, survival := 0.42 * P(sim)$caribou_herd_density ] # V1 here needs to be replaced with whatever the column name is that gets created in the above query
  sim$survtable [!(V1 < 0.09), survival := (1.91 - (V1 * 0.59) + (0.42 * P(sim)$caribou_herd_density))]
  sim$survtable [, time := time(sim)] # add the time of the survival calc
  
  ### Future version could include a table parameter input with caribou number or density by herd 
  ### that could be used in the model, rather than a single parameter for all herds, as currently 
  ### done
  
  return(invisible(sim))
}


survivalCLUS.PredictSurvival <- function (sim) { # this function calculates survival rate at each time interval; same as on init, above
 
  sim$new_survtable <- data.table (dbGetQuery (sim$clusdb, "SELECT AVG (CASE WHEN age BETWEEN 1 AND 40 THEN 1 ELSE 0 END) FROM pixels GROUP BY herd_bounds"))
  # what is the column name of the output; V1???
  
  sim$new_survtable [V1 < 0.09, survival_rate := 0.42 * P(sim)$caribou_herd_density ] # V1 needs to be replaced with whatever the column name is that gets created in the above query
  sim$new_survtable [!(V1 < 0.09), survival_rate := (1.91 - (V1 * 0.59) + (0.42 * P(sim)$caribou_herd_density))]
  sim$new_survtable [, time := time(sim)] # add the time of the survival calc
  
  sim$survtable <- rbind (sim$survtable, new_survtable) # bind the new survival rate table to the existing table
  rm (sim$new_survtable) # is this necessary?

  return(invisible(sim))
}


survivalCLUS.setTablesCLUSdb <- function (sim) { # this function saves the survival table to the clusdb
  
  dbBegin (sim$clusdb)
  rs <- dbSendQuery (sim$clusdb, "INSERT INTO survival_caribou (herd_bounds, survival_rate, time) values (:herd_bounds, :survival_rate, :time)", sim$survtable) # from sim object
  dbClearResult (rs)
  dbCommit (sim$clusdb)
  rm (rs)
  gc ()
  # another thing that could be done here is link the LUT herd name to the integer in the 
  # survival_caribou table, but maybe that is best done post processing, as part of data 
  # review and summary.
}




.inputObjects <- function(sim) {
  #cacheTags <- c(currentModule(sim), "function:.inputObjects") ## uncomment this if Cache is being used
  dPath <- asPath(getOption("reproducible.destinationPath", dataPath(sim)), 1)
  message(currentModule(sim), ": using dataPath '", dPath, "'.")
  return(invisible(sim))
}
