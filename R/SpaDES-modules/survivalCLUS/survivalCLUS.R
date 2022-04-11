# Copyright 2021 Province of British Columbia
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

defineModule (sim, list (
  name = "survivalCLUS",
  description = "This module calculates adult female caribou survival rate in caribou herd ranges using the model developed by Wittmer et al. 2007.",
  keywords = c ("caribou", "survival", "southern mountain", "adult female"), 
  authors = c (person ("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre")),
               person ("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character (0),
  version = list (SpaDES.core = "0.2.5", survivalCLUS = "0.0.1"),
  spatialExtent = raster::extent (rep (NA_real_, 4)),
  timeframe = as.POSIXlt (c (NA, NA)),
  timeunit = "year",
  citation = list ("citation.bib"),
  documentation = list ("README.md", "survivalCLUS.Rmd"),
  reqdPkgs = list (),
  parameters = rbind (
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter ("calculateInterval", "numeric", 1, 1, 5, "The simulation time at which survival rates are calculated"),
    defineParameter ("caribou_herd_density", "numeric", 0.05, 0, 1, "This is the caribou herd density that the user defines. It is necessary to fit the survival model. For now, we are keeping it static, but in the future it could be made dynamic by linking to a population model."),
    defineParameter ("nameRasCaribouHerd", "character", "rast.caribou_herd", NA, NA, "Name of the raster of the caribou herd boundaries raster that is stored in the psql clusdb. Created in Params/caribou_herd_raster.rmd."), # could be included in dataLoader instead for easier use in other modules?
    defineParameter ("tableCaribouHerd", "character", "public.caribou_herd", NA, NA, "The look up table to convert raster values to caribou herd name labels. The two values required are value and herd_name. Created in Params/caribou_herd_raster.rmd")
  ),
  inputObjects = bind_rows(
    expectsInput (objectName = "clusdb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the model. This module needs the age variable from the pixels table in the clusdb.', sourceURL = NA),
    expectsInput(objectName ="scenario", objectClass ="data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName = "boundaryInfo", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName ="updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA)
    ),
  outputObjects = bind_rows(
    createsOutput (objectName = "tableSurvivalReport", objectClass = "data.table", desc = "A data.table object. Consists of survival rate estimates for each herd in the study area at each time step. Gets saved in the 'outputs' folder of the module.")
    )
  )
)

doEvent.survivalCLUS = function (sim, eventTime, eventType) {
  switch (
    eventType,
    init = { # identify herds in the study area, calculate survival rate at time 0 for those herds and save the survival rate estimate
      sim <- Init (sim) # identify herds in the study area and calculate survival rate at time 0; instantiate a table to save the survival rate estimates
      sim <- scheduleEvent (sim, time(sim) + P(sim, "calculateInterval", "survivalCLUS"), "survivalCLUS", "calculateSurvival", 8) # schedule the next survival calculation event 
      sim <- scheduleEvent (sim, end(sim), "survivalCLUS", "adjustSurvivalTable", 9) 
    },
    
    calculateSurvival = { # calculate survival rate at each time interval 
      sim <- predictSurvival (sim) # this function calculates survival rate
      sim <- scheduleEvent (sim, time(sim) + P(sim, "calculateInterval", "survivalCLUS"), "survivalCLUS", "calculateSurvival", 8) # schedule the next survival calculation event  
    },
    adjustSurvivalTable ={ # calucalte the total area from which the proportions and survival rate applies
      sim <- adjustSurvivalTable (sim)
    },
    
    warning (paste ("Undefined event type: '", current (sim) [1, "eventType", with = FALSE],
                    "' in module '", current (sim) [1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return (invisible (sim))
}

Init <- function (sim) { # this function identifies the caribou herds in the 'study area' creates the survival rate table, calculates survival rate at time = 0, and saves the survival table in the clusdb
  #Added a condition here in those cases where the dataLoaderCLUS has already ran
  if(nrow(data.table(dbGetQuery(sim$clusdb, "PRAGMA table_info(pixels)"))[name == 'herd_bounds',])== 0){
    dbExecute (sim$clusdb, "ALTER TABLE pixels ADD COLUMN herd_bounds character") # add a column to the pixel table that will define the caribou herd area   
  
    herdbounds <- data.table (c (t (raster::as.matrix ( # clip caribou herd raster by the 'study area' set in dataLoader
                                    RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                      srcRaster = P (sim, "nameRasCaribouHerd", "survivalCLUS") , # clip the herd boundary raster; defined in parameters, above
                                      clipper=sim$boundaryInfo[[1]], 
                                      geom= sim$boundaryInfo[[4]], 
                                      where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                      conn = NULL)))))
    
    setnames (herdbounds, "V1", "herd_bounds") # rename the default column name
    herdbounds [, herd_bounds := as.integer (herd_bounds)] # add the herd boudnary value from the raster and make the value an integer
    herdbounds [, pixelid := seq_len(.N)] # add pixelid value
    
    vat_table <- data.table(getTableQuery(paste0("SELECT * FROM ", P(sim)$tableCaribouHerd))) # get the herd name attribute table that corresponds to the integer values
    # print(vat_table)
    # print(herdbounds)
    herdbounds <- merge (herdbounds, vat_table, by.x = "herd_bounds", by.y = "value", all.x = TRUE) # left join the herd name to the intger
    herdbounds [, herd_bounds := NULL] # drop the integer value 
    
    colnames(herdbounds) <- c("pixelid", "herd_bounds") # rename the herd boundary column
    setorder (herdbounds, "pixelid") # this helps speed up processing?
  
    dbBegin (sim$clusdb) # fire up the db and add the herd boundary values to the pixels table 
    rs <- dbSendQuery (sim$clusdb, "Update pixels set herd_bounds = :herd_bounds where pixelid = :pixelid", herdbounds) 
    dbClearResult (rs)
    dbCommit (sim$clusdb) # commit the new column to the db
  }
  # The following calculates the proportion of age 1 to 40 year old forest pixels in each herd area 
  # in the study area 
   # the SQL statement selects the average value of:
    # cases that meet the case criteria 'when' (case = 1) and
    # cases that do not meet the case criteria 'then' (case = 0)
    # So, if an area of 10 pixels has 4 pixels age 1 to 40, then the statement will return
    # a value of 0.4  = AVG (0,0,1,1,0,1,1,0,0,0)
    # it does this by each herd ('GROUP BY' statement)
    # the IS NOT NULL statements drop out the non-forested areas from the calculation, i.e., the denominator is the area of forest, not all land
  sim$tableSurvivalReport <- data.table (dbGetQuery (sim$clusdb, "SELECT AVG (CASE WHEN age BETWEEN 0 AND 40 THEN 1  ELSE 0 END) AS prop_age, AVG (CASE WHEN age BETWEEN 80 AND 120 THEN 1  ELSE 0 END) AS prop_mature, AVG (CASE WHEN age > 120 THEN 1  ELSE 0 END) AS prop_old, herd_bounds FROM pixels WHERE herd_bounds IS NOT NULL AND age Is NOT NULL GROUP BY herd_bounds;"))

    # alternate way to specify the query: SELECT AVG (CASE WHEN age IS NOT NULL AND age BETWEEN 0 AND 40 THEN 1 WHEN age IS NOT NULL THEN 0 ELSE NULL END) AS prop_age, herd_bounds FROM pixels WHERE herd_bounds IS NOT NULL GROUP BY herd_bounds;

  # The following equation calculates the survival rate in the herd area using the Wittmer et al. model 
    # The model is a threshold model; if the proportion of 1 to 40 year old forest is < 0.09, 
    # then forest age has no effect; hence the two statements below
    # Wittmer standardized his covariates; I was able to get his original spreadsheet (See C:\Work\caribou\clus_github\R\SpaDES-modules\survivalCLUS\data\Wittmer_Figure_3.xls)
    # Coefficents are standardized using the values from the spreadsheet
    # Model was a logit function, so here I back-calculate to get survival rates exp(fxn)/(1+exp(fxn))
  sim$tableSurvivalReport[prop_age < 0.09, survival_rate := (exp(1.91 + (0.42 * ((P(sim)$caribou_herd_density - 0.0515)/0.0413))))/(1+(exp(1.91 + (0.42 * ((P(sim)$caribou_herd_density - 0.0515)/0.0413)))))] 
  sim$tableSurvivalReport[!(prop_age < 0.09), survival_rate := (exp(1.91 - (0.59 * (((prop_age * 100) - 9.2220)/3.8932)) + (0.42 * ((P(sim)$caribou_herd_density - 0.0515)/0.0413))))/(1+(exp(1.91 - (0.59 * (((prop_age * 100) - 9.2220)/3.8932)) + (0.42 * ((P(sim)$caribou_herd_density - 0.0515)/0.0413)))))]
  sim$tableSurvivalReport[, c("timeperiod", "scenario") := list (time(sim)*sim$updateInterval, sim$scenario$name) ] # add the time of the survival calc
  
  #print(sim$tableSurvivalReport)
  ### Future version could include a table parameter input with caribou number or density by herd 
  ### that could be used in the model, rather than a single parameter for all herds, as currently 
  ### done
  
  return(invisible(sim))
}


predictSurvival <- function (sim) { # this function calculates survival rate at each time interval; same as on init, above
 
  new_tableSurvivalReport <- data.table (dbGetQuery (sim$clusdb, "SELECT AVG (CASE WHEN age BETWEEN 0 AND 40 THEN 1  ELSE 0 END) AS prop_age, AVG (CASE WHEN age BETWEEN 80 AND 120 THEN 1  ELSE 0 END) AS prop_mature, AVG (CASE WHEN age > 120 THEN 1  ELSE 0 END) AS prop_old, herd_bounds FROM pixels WHERE herd_bounds IS NOT NULL AND age Is NOT NULL GROUP BY herd_bounds;"))

  new_tableSurvivalReport[prop_age < 0.09, survival_rate := (exp(1.91 + (0.42 * ((P(sim)$caribou_herd_density - 0.0515)/0.0413))))/(1+(exp(1.91 + (0.42 * ((P(sim)$caribou_herd_density - 0.0515)/0.0413)))))] # V1 needs to be replaced with whatever the column name is that gets created in the above query
  new_tableSurvivalReport[!(prop_age  < 0.09), survival_rate := (exp(1.91 - (0.59 * (((prop_age * 100) - 9.2220)/3.8932)) + (0.42 * ((P(sim)$caribou_herd_density - 0.0515)/0.0413))))/(1+(exp(1.91 - (0.59 * (((prop_age * 100) - 9.2220)/3.8932)) + (0.42 * ((P(sim)$caribou_herd_density - 0.0515)/0.0413)))))]
  new_tableSurvivalReport[, c("timeperiod", "scenario") := list (time(sim)*sim$updateInterval, sim$scenario$name) ] # add the time of the survival calc
  
  sim$tableSurvivalReport <- rbindlist (list(sim$tableSurvivalReport, new_tableSurvivalReport)) # bind the new survival rate table to the existing table
  rm (new_tableSurvivalReport) # is this necessary? -- frees up memory
  return (invisible(sim))
}

adjustSurvivalTable <- function (sim) { # this function adds the total area of the herd_bounds to be used for weighting in the dashboard
  total_area<-data.table(dbGetQuery (sim$clusdb, "SELECT count(*)as area, herd_bounds FROM pixels WHERE herd_bounds IS NOT NULL AND age Is NOT NULL GROUP BY herd_bounds;"))
  sim$tableSurvivalReport<-merge(sim$tableSurvivalReport, total_area, by.x = "herd_bounds", by.y = "herd_bounds", all.x = TRUE )
  return (invisible(sim))
}


.inputObjects <- function(sim) {
  #cacheTags <- c(currentModule(sim), "function:.inputObjects") ## uncomment this if Cache is being used
  dPath <- asPath(getOption("reproducible.destinationPath", dataPath(sim)), 1)
  message(currentModule(sim), ": using dataPath '", dPath, "'.")
  return(invisible(sim))
}

