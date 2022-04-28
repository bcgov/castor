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
  name = "smcaribouAbundanceCLUS",
  description = "This module estimates habitat disturbance and abundance in caribou subpopulations/herd ranges using the model developed by Locchead et al. 2021.",
  keywords = c ("caribou", "survival", "southern mountain", "adult female"), 
  authors = c (person ("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre")),
               person ("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character (0),
  version = list (SpaDES.core = "0.2.5", smcaribouAbundanceCLUS = "0.0.1"),
  spatialExtent = raster::extent (rep (NA_real_, 4)),
  timeframe = as.POSIXlt (c (NA, NA)),
  timeunit = "year",
  citation = list ("citation.bib"),
  documentation = list ("README.md", "smcaribouAbundanceCLUS.Rmd"),
  reqdPkgs = list (),
  parameters = rbind (
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter ("calculateInterval", "numeric", 1, 1, 5, "The simulation time at which survival rates are calculated"),
    defineParameter ("nameRasSMCHerd", "character", "rast.smc_herd_habitat", NA, NA, "Name of the raster of the caribou subpopulation/herd habiat boundaries that is stored in the psql clusdb"), 
    defineParameter ("tableSMCCoeffs", "character", "vat.smc_coeffs", NA, NA, "The look up table that contains the model coefficients to estimate abundance from disturbance, for each caribou subpopulation/herd.")
  ),
  inputObjects = bind_rows(
    expectsInput (objectName = "clusdb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the model. This module needs the age variable from the pixels table in the clusdb.', sourceURL = NA),
    expectsInput(objectName ="scenario", objectClass ="data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName ="updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA)
  ),
  outputObjects = bind_rows(
    createsOutput (objectName = "tableAbundanceReport", objectClass = "data.table", desc = "A data.table object. Consists of abundance and disturbance estimates for each subpopulation/herd in the study area at each time step. Gets saved in the 'outputs' folder of the module.")
  )
)
)

doEvent.smcaribouAbundanceCLUS = function (sim, eventTime, eventType) {
  switch (
    eventType,
    init = { 
      sim <- Init (sim) 
      sim <- scheduleEvent (sim, time(sim) + P(sim, "calculateInterval", "smcaribouAbundanceCLUS"), "smcaribouAbundanceCLUS", "calculateAbundance", 8) 
      sim <- scheduleEvent (sim, end(sim), "smcaribouAbundanceCLUS", "adjustAbundanceTable", 9) 
    },
    
    calculateAbundance = { # calculate survival rate at each time interval 
      sim <- predictAbundance (sim) 
      sim <- scheduleEvent (sim, time(sim) + P(sim, "calculateInterval", "smcaribouAbundanceCLUS"), "smcaribouAbundanceCLUS", "calculateAbundance", 8) 
    },
    adjustAbundanceTable ={ 
      sim <- adjustAbundanceTable (sim)
    },
    
    warning (paste ("Undefined event type: '", current (sim) [1, "eventType", with = FALSE],
                    "' in module '", current (sim) [1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return (invisible (sim))
}

Init <- function (sim) { 
  if(nrow(data.table(dbGetQuery(sim$clusdb, "PRAGMA table_info(pixels)"))[name == 'herd_habitat_name',])== 0){
    dbExecute (sim$clusdb, "ALTER TABLE pixels ADD COLUMN subpop_name character")  
    dbExecute (sim$clusdb, "ALTER TABLE pixels ADD COLUMN habitat_type character")
    dbExecute (sim$clusdb, "ALTER TABLE pixels ADD COLUMN herd_habitat_name character")  
    
    herd_hab <- data.table (c (t (raster::as.matrix ( 
                      RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                    srcRaster = P (sim, "nameRasSMCHerd", "smcaribouAbundanceCLUS") , 
                                    clipper = P (sim, "nameBoundaryFile", "dataLoaderCLUS"),  
                                    geom = P (sim, "nameBoundaryGeom", "dataLoaderCLUS"), 
                                    where_clause =  paste0 (P (sim, "nameBoundaryColumn", "dataLoaderCLUS"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                    conn = NULL)))))
    
    setnames (herd_hab, "V1", "herd_habitat") 
    herd_hab [, herd_habitat := as.integer (herd_habitat)] 
    herd_hab [, pixelid := seq_len(.N)] 
    
    vat_table <- data.table(getTableQuery(paste0("SELECT * FROM ", P(sim)$tableSMCCoeffs))) 
    
    herd_hab <- merge (herd_hab, vat_table, by.x = "herd_habitat", by.y = "value", all.x = TRUE) 
    #herd_hab [, herd_habitat := NULL] # drop the integer value 
    #colnames(herd_habitat) <- c("pixelid", "herd_habitat") 
    herd_hab <- herd_hab [, .(pixelid, herd_name, bc_habitat_type, herd_hab_name)]
    setorder (herd_hab, "pixelid") 
    
    dbBegin (sim$clusdb) # add the herd  and habitat boundary values to the pixels table 
    rs <- dbSendQuery (sim$clusdb, "UPDATE pixels SET herd_habitat_name = :herd_hab_name, subpop_name = :herd_name, habitat_type = :bc_habitat_type WHERE pixelid = :pixelid", herd_hab) 
    dbClearResult (rs)
    dbCommit (sim$clusdb) # commit the new column to the db
  }
  
  # The following calculates the proportion of 'disturbed' forested pixels in each subpop/herd core and matrix habitat area 
  # the SQL statement selects the average value of:
  # cases that meet the case criteria 'when' (case = 1) and
  # cases that do not meet the case criteria 'then' (case = 0)
  # So, if an area of 10 pixels has 4 'dsiturbed' pixels (age 1 to 40)i.e., distance to disturbance = 0, then the statement will return
  # a value of 0.4  = AVG (0,0,1,1,0,1,1,0,0,0)
  # it does this by each herd/habitat area ('GROUP BY' statement)
  # the IS NOT NULL statements drop out the non-forested areas from the calculation, i.e., the denominator is the area of forest, not all land
  table.disturb <- data.table (dbGetQuery (sim$clusdb, "SELECT AVG (CASE WHEN roadyear >= 0 OR blockid > 0 AND age >=0 AND age <= 40 THEN 1 ELSE 0 END) * 100 AS percent_disturb, herd_habitat_name, subpop_name, habitat_type FROM pixels WHERE herd_habitat_name IS NOT NULL AND age Is NOT NULL GROUP BY herd_habitat_name;")) 
  
  # The following equation estimates abundance in the subpop/herd area using the Lochhead et al. model 
  message("estimating abundance")
  table.disturb <- dcast(table.disturb, # reshape the table 
                         subpop_name ~ habitat_type, 
                         value.var="percent_disturb")
  vat_table <- data.table(getTableQuery(paste0("SELECT * FROM ", P(sim)$tableSMCCoeffs))) 
  coeffs <- unique(vat_table, by = "herd_name")
  coeffs <- coeffs [, c ("bc_habitat_type", "herd_hab_name", "value") := NULL]
  table.disturb <- merge (table.disturb , coeffs, by.x = "subpop_name", by.y = "herd_name", all.x = TRUE) # add coeffs
  
  setnames(table.disturb, "Core", "core") # make these lower case
  setnames(table.disturb, "Matrix", "matrix")

  table.disturb [, abundance_r50 := exp((r50fe_int + r50re_int) + ((r50fe_core + r50fe_core) * core) + (r50fe_matrix * matrix))]
  table.disturb [, abundance_c80r50 := exp((c80r50fe_int + c80r50re_int) + ((c80r50fe_core + c80r50fe_core) * core) + (c80r50fe_matrix * matrix))]
  table.disturb [, abundance_c80 := exp((c80fe_int + c80re_int) + ((c80fe_core + c80fe_core) * core) + (c80fe_matrix * matrix))]
  table.disturb [, abundance_avg := (abundance_r50 + abundance_c80r50 + abundance_c80)/3]
  sim$tableAbundanceReport <- table.disturb 
  sim$tableAbundanceReport [, c("timeperiod", "scenario") := list (time(sim)*sim$updateInterval, sim$scenario$name)  ] # add the time of the survival calc
  
  return(invisible(sim))
}


predictAbundance <- function (sim) { # this function calculates survival rate at each time interval; same as on init, above
  
  message("estimating abundance")
  new_tableAbundanceReport <- data.table (dbGetQuery (sim$clusdb, "SELECT AVG (CASE WHEN roadyear >= 0 OR blockid > 0 AND age >=0 AND age <= 40 THEN 1 ELSE 0 END) * 100 AS percent_disturb, herd_habitat_name, subpop_name, habitat_type FROM pixels WHERE herd_habitat_name IS NOT NULL AND age Is NOT NULL GROUP BY herd_habitat_name;")) 
  new_tableAbundanceReport <- dcast(new_tableAbundanceReport, # reshape the table 
                                     subpop_name ~ habitat_type, 
                                     value.var="percent_disturb")
  vat_table <- data.table(getTableQuery(paste0("SELECT * FROM ", P(sim)$tableSMCCoeffs)))
  coeffs <- unique(vat_table, by = "herd_name")
  coeffs <- coeffs [, c ("bc_habitat_type", "herd_hab_name", "value") := NULL]
  new_tableAbundanceReport <- merge (new_tableAbundanceReport , coeffs, by.x = "subpop_name", by.y = "herd_name", all.x = TRUE) # add coeffs
  
  setnames(new_tableAbundanceReport, "Core", "core") # make these lower case
  setnames(new_tableAbundanceReport, "Matrix", "matrix")

  new_tableAbundanceReport [, abundance_r50 := exp((r50fe_int + r50re_int) + ((r50fe_core + r50fe_core) * core) + (r50fe_matrix * matrix))]
  new_tableAbundanceReport [, abundance_c80r50 := exp((c80r50fe_int + c80r50re_int) + ((c80r50fe_core + c80r50fe_core) * core) + (c80r50fe_matrix * matrix))]
  new_tableAbundanceReport [, abundance_c80 := exp((c80fe_int + c80re_int) + ((c80fe_core + c80fe_core) * core) + (c80fe_matrix * matrix))]
  new_tableAbundanceReport [, abundance_avg := (abundance_r50 + abundance_c80r50 + abundance_c80)/3]
  new_tableAbundanceReport [, c("timeperiod", "scenario") := list (time(sim)*sim$updateInterval, sim$scenario$name)  ] # add the time of the calc
  
  sim$tableAbundanceReport <- rbindlist (list(sim$tableAbundanceReport, new_tableAbundanceReport)) # bind the new survival rate table to the existing table
  rm (new_tableAbundanceReport) # is this necessary? -- frees up memory
  return (invisible(sim))
}

adjustAbundanceTable <- function (sim) { # this function adds the total area of the herds to be used for weighting in the dashboard
  total_area <- data.table(dbGetQuery (sim$clusdb, "SELECT count(*)as area, subpop_name FROM pixels WHERE subpop_name IS NOT NULL AND age Is NOT NULL GROUP BY subpop_name;"))
  sim$tableAbundanceReport<-merge(sim$tableAbundanceReport, total_area, by.x = "subpop_name", by.y = "subpop_name", all.x = TRUE )
  return (invisible(sim))
}


.inputObjects <- function(sim) {
  #cacheTags <- c(currentModule(sim), "function:.inputObjects") ## uncomment this if Cache is being used
  dPath <- asPath(getOption("reproducible.destinationPath", dataPath(sim)), 1)
  message(currentModule(sim), ": using dataPath '", dPath, "'.")
  return(invisible(sim))
}
