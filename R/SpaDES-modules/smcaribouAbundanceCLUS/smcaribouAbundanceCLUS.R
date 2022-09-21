#===========================================================================================#
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
#===========================================================================================#

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
    defineParameter ("nameRasSMCHerd", "character", "rast.smc_herd_habitat", NA, NA, "Name of the raster of the caribou subpopulation/herd habiat boundaries that is stored in the psql clusdb") 
    #defineParameter ("tableSMCCoeffs", "character", "vat.smc_coeffs", NA, NA, "The look up table that contains the model coefficients to estimate abundance from disturbance, for each caribou subpopulation/herd.")
  ),
  inputObjects = bind_rows(
    expectsInput (objectName = "clusdb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the model. This module needs the age variable from the pixels table in the clusdb.', sourceURL = NA),
    expectsInput(objectName ="scenario", objectClass ="data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName ="updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA),
    expectsInput (objectName = "table_smCoeffs", objectClass = "data.table", desc = "A data.table object.")
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
  if (nrow (data.table (dbGetQuery (sim$clusdb, "PRAGMA table_info(pixels)"))[name == 'herd_habitat_name',])== 0){
    dbExecute (sim$clusdb, "ALTER TABLE pixels ADD COLUMN subpop_name character")  
    dbExecute (sim$clusdb, "ALTER TABLE pixels ADD COLUMN habitat_type character")
    dbExecute (sim$clusdb, "ALTER TABLE pixels ADD COLUMN herd_habitat_name character")  
    
    herd_hab <- data.table (herd_habitat = RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                    srcRaster = P (sim, "nameRasSMCHerd", "smcaribouAbundanceCLUS") , 
                                    clipper = P (sim, "nameBoundaryFile", "dataLoaderCLUS"),  
                                    geom = P (sim, "nameBoundaryGeom", "dataLoaderCLUS"), 
                                    where_clause =  paste0 (P (sim, "nameBoundaryColumn", "dataLoaderCLUS"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                    conn = NULL)[])
    herd_hab [, herd_habitat := as.integer (herd_habitat)] 
    herd_hab [, pixelid := seq_len(.N)] 
    herd_hab <- merge (herd_hab [, .(pixelid, herd_habitat)], sim$table_smCoeffs [, .(value, herd_name, bc_habitat_type, herd_hab_name)], by.x = "herd_habitat", by.y = "value", all.x = TRUE) 
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
    # it does this by each herd/habitat area ('GROUP BY' statement)
  table.disturb.r50 <- data.table (dbGetQuery (sim$clusdb, paste0 ("SELECT AVG (CASE WHEN ((",time(sim)*sim$updateInterval, " - roadstatus < 80 AND (roadtype != 0 OR roadtype IS NULL)) OR roadtype = 0) THEN 1 ELSE 0 END) * 100 AS percent_r50disturb, herd_habitat_name, subpop_name, habitat_type FROM pixels WHERE herd_habitat_name IS NOT NULL AND treed = 1 GROUP BY herd_habitat_name;"))) 
  table.disturb.c80 <- data.table (dbGetQuery (sim$clusdb, "SELECT AVG (CASE WHEN blockid > 0 AND age >= 0 AND age <= 80 THEN 1 ELSE 0 END) * 100 AS percent_c80disturb, herd_habitat_name, subpop_name, habitat_type FROM pixels WHERE herd_habitat_name IS NOT NULL AND treed = 1 GROUP BY herd_habitat_name;")) 
  table.disturb.r50c80 <- data.table (dbGetQuery (sim$clusdb, paste0 ("SELECT AVG (CASE WHEN ((",time(sim)*sim$updateInterval, " - roadstatus < 80 AND (roadtype != 0 OR roadtype IS NULL)) OR roadtype = 0) OR blockid > 0 AND age >=0 AND age <= 80 THEN 1 ELSE 0 END) * 100 AS percent_r50c80disturb, herd_habitat_name, subpop_name, habitat_type FROM pixels WHERE herd_habitat_name IS NOT NULL AND treed = 1 GROUP BY herd_habitat_name;")))
   # reshape the table 
  table.disturb.r50 <- dcast (table.disturb.r50,
                              subpop_name ~ habitat_type, 
                              value.var = "percent_r50disturb")
  table.disturb.c80 <- dcast (table.disturb.c80, 
                              subpop_name ~ habitat_type, 
                              value.var = "percent_c80disturb")
  table.disturb.r50c80 <- dcast (table.disturb.r50c80, 
                              subpop_name ~ habitat_type, 
                              value.var = "percent_r50c80disturb")
  
  # The following equation estimates abundance in the subpop/herd area using the Lochhead et al. model 
  message("estimating abundance")
  coeffs <- as.data.table (unique (sim$table_smCoeffs, by = "herd_name"))
 
    coeffs1 <<- sim$table_smCoeffs
    coeff2s <<- as.data.table (unique (sim$table_smCoeffs, by = "herd_name"))
  
  coeffs <- coeffs [, c ("bc_habitat_type", "herd_hab_name", "value") := NULL]
  table.disturb.r50 <- merge (table.disturb.r50, coeffs, by.x = "subpop_name", by.y = "herd_name", all.x = TRUE) # add coeffs
  table.disturb.c80 <- merge (table.disturb.c80, coeffs, by.x = "subpop_name", by.y = "herd_name", all.x = TRUE) # add coeffs
  table.disturb.r50c80 <- merge (table.disturb.r50c80, coeffs, by.x = "subpop_name", by.y = "herd_name", all.x = TRUE) # add coeffs
  table.disturb.r50 [, abundance_r50 := exp((r50fe_int + r50re_int) + ((r50fe_core + r50fe_core) * core) + (r50fe_matrix * matrix))]
  table.disturb.r50c80 [, abundance_c80r50 := exp((c80r50fe_int + c80r50re_int) + ((c80r50fe_core + c80r50fe_core) * core) + (c80r50fe_matrix * matrix))]
  table.disturb.c80 [, abundance_c80 := exp((c80fe_int + c80re_int) + ((c80fe_core + c80fe_core) * core) + (c80fe_matrix * matrix))]
  table.disturb <- merge (merge (table.disturb.r50 [, .(subpop_name, abundance_r50)],
                                 table.disturb.c80 [, .(subpop_name, abundance_c80)],
                                 by = "subpop_name"),
                          table.disturb.r50c80 [, .(subpop_name, abundance_c80r50)],
                          by = "subpop_name")
  table.disturb [, abundance_avg := (abundance_r50 + abundance_c80r50 + abundance_c80)/3]
  sim$tableAbundanceReport <- table.disturb 
  sim$tableAbundanceReport [, c("timeperiod", "scenario") := list (time(sim)*sim$updateInterval, sim$scenario$name)  ] # add the time of the survival calc
  total_area <- data.table (dbGetQuery (sim$clusdb, "SELECT count(*)as area, subpop_name FROM pixels WHERE subpop_name IS NOT NULL AND age Is NOT NULL GROUP BY subpop_name;"))
  sim$tableAbundanceReport <- merge (sim$tableAbundanceReport, total_area, by.x = "subpop_name", by.y = "subpop_name", all.x = TRUE )
  sim$tableAbundanceReport <- sim$tableAbundanceReport [, c ("scenario", "subpop_name", "area", "abundance_r50", "abundance_c80r50", "abundance_c80", "abundance_avg")]
  return(invisible(sim))
}


predictAbundance <- function (sim) { # this function calculates survival rate at each time interval; same as on init, above
  
  message("estimating abundance")
  table.disturb.r50.new <- data.table (dbGetQuery (sim$clusdb, paste0 ("SELECT AVG (CASE WHEN ((", time(sim)*sim$updateInterval, " - roadstatus < 80 AND (roadtype != 0 OR roadtype IS NULL)) OR roadtype = 0) THEN 1 ELSE 0 END) * 100 AS percent_r50disturb, herd_habitat_name, subpop_name, habitat_type FROM pixels WHERE herd_habitat_name IS NOT NULL AND treed = 1 GROUP BY herd_habitat_name;"))) 
  table.disturb.c80.new <- data.table (dbGetQuery (sim$clusdb, "SELECT AVG (CASE WHEN blockid > 0 AND age >= 0 AND age <= 80 THEN 1 ELSE 0 END) * 100 AS percent_c80disturb, herd_habitat_name, subpop_name, habitat_type FROM pixels WHERE herd_habitat_name IS NOT NULL AND treed = 1 GROUP BY herd_habitat_name;")) 
  table.disturb.r50c80.new <- data.table (dbGetQuery (sim$clusdb, paste0 ("SELECT AVG (CASE WHEN ((", time(sim)*sim$updateInterval, " - roadstatus < 80 AND (roadtype != 0 OR roadtype IS NULL)) OR roadtype = 0) OR blockid > 0 AND age >=0 AND age <= 80 THEN 1 ELSE 0 END) * 100 AS percent_r50c80disturb, herd_habitat_name, subpop_name, habitat_type FROM pixels WHERE herd_habitat_name IS NOT NULL AND treed = 1 GROUP BY herd_habitat_name;"))) 
  # reshape the table 
  table.disturb.r50.new <- dcast (table.disturb.r50.new,
                                  subpop_name ~ habitat_type, 
                                  value.var = "percent_r50disturb")
  table.disturb.c80.new <- dcast (table.disturb.c80.new, 
                                  subpop_name ~ habitat_type, 
                                  value.var = "percent_c80disturb")
  table.disturb.r50c80.new <- dcast (table.disturb.r50c80.new, 
                                     subpop_name ~ habitat_type, 
                                     value.var = "percent_r50c80disturb")
  coeffs <- unique (sim$table_smCoeffs, by = "herd_name")
  coeffs <- coeffs [, c ("bc_habitat_type", "herd_hab_name", "value") := NULL]
  table.disturb.r50.new <- merge (table.disturb.r50.new, coeffs, by.x = "subpop_name", by.y = "herd_name", all.x = TRUE) 
  table.disturb.c80.new <- merge (table.disturb.c80.new, coeffs, by.x = "subpop_name", by.y = "herd_name", all.x = TRUE) 
  table.disturb.r50c80.new <- merge (table.disturb.r50c80.new, coeffs, by.x = "subpop_name", by.y = "herd_name", all.x = TRUE) 
  table.disturb.r50.new [, abundance_r50 := exp((r50fe_int + r50re_int) + ((r50fe_core + r50fe_core) * core) + (r50fe_matrix * matrix))]
  table.disturb.r50c80.new [, abundance_c80r50 := exp((c80r50fe_int + c80r50re_int) + ((c80r50fe_core + c80r50fe_core) * core) + (c80r50fe_matrix * matrix))]
  table.disturb.c80.new [, abundance_c80 := exp((c80fe_int + c80re_int) + ((c80fe_core + c80fe_core) * core) + (c80fe_matrix * matrix))]
  table.disturb.new <- merge (merge (table.disturb.r50.new [, .(subpop_name, abundance_r50)],
                                     table.disturb.c80.new [, .(subpop_name, abundance_c80)],
                                     by = "subpop_name"),
                              table.disturb.r50c80.new [, .(subpop_name, abundance_c80r50)],
                              by = "subpop_name")
  table.disturb.new [, abundance_avg := (abundance_r50 + abundance_c80r50 + abundance_c80)/3]
  table.disturb.new [, c("timeperiod", "scenario") := list (time(sim)*sim$updateInterval, sim$scenario$name)  ] # add the time of the calc
  table.disturb.new [, area := as.numeric ()]
  sim$tableAbundanceReport <- rbindlist (list(sim$tableAbundanceReport, table.disturb.new [, c ("scenario", "subpop_name", "area", "abundance_r50", "abundance_c80r50", "abundance_c80", "abundance_avg")])) # bind the new survival rate table to the existing table
  rm (table.disturb.new) # is this necessary? -- frees up memory
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
  
  sim$table_smCoeffs <- data.table (herd_name = c ("Barkerville", "Barkerville", "Burnt_Pine", "Graham", "Graham", "Groundhog", "Groundhog", "Moberly", "Moberly", "Monashee", "Monashee", "Narraway", "Burnt_Pine", "Central_Rockies", "Central_Rockies", "Narraway", "Quintette", "Quintette", "Rainbows", "Rainbows", "Telkwa", "Telkwa", "Tweedsmuir", "Tweedsmuir", "Narrow_Lake", "Narrow_Lake", "Itcha_Ilgachuz", "Itcha_Ilgachuz", "Central_Selkirks", "Central_Selkirks", "Charlotte_Alplands", "Charlotte_Alplands", "Columbia_North", "Columbia_North", "Columbia_South", "Columbia_South", "Frisby_Boulder", "Frisby_Boulder", "Hart_Ranges", "Hart_Ranges", "Kennedy_Siding", "Kennedy_Siding", "North_Cariboo", "North_Cariboo", "Purcell_Central", "Purcell_Central", "Purcells_South", "Purcells_South", "South_Selkirks", "South_Selkirks", "Wells_Gray_North", "Wells_Gray_North", "Wells_Gray_South", "Wells_Gray_South", "Redrock_Prairie_Creek", "Redrock_Prairie_Creek"),
                                    bc_habitat_type = c ("core","matrix","core","core","matrix","core","matrix","core","matrix","core","matrix","core","matrix","core","matrix","matrix","core","matrix","core","matrix","core","matrix","core","matrix","core","matrix","core","matrix","core","matrix","core","matrix","matrix","core","core","matrix","core","matrix","core","matrix","core","matrix","core", "matrix","core","matrix","core","matrix","core","matrix","core","matrix","core","matrix","core","matrix"),
                                    herd_hab_name = c ("Barkerville Core", "Barkerville Matrix", "Burnt_Pine Core", "Graham Core", "Graham Matrix", "Groundhog Core", "Groundhog Matrix", "Moberly Core", 'Moberly Matrix', "Monashee Core", "Monashee Matrix", "Narraway Core", "Burnt_Pine Matrix", "Central_Rockies Core", "Central_Rockies Matrix", "Narraway Matrix", "Quintette Core", "Quintette Matrix","Rainbows Core", "Rainbows Matrix", "Telkwa Core", "Telkwa Matrix", "Tweedsmuir Core", "Tweedsmuir Matrix", "Narrow_Lake Core", "Narrow_Lake Matrix", "Itcha_Ilgachuz Core", "Itcha_Ilgachuz Matrix", "Central_Selkirks Core", "Central_Selkirks Matrix", "Charlotte_Alplands Core", "Charlotte_Alplands Matrix", "Columbia_North Matrix", "Columbia_North Core", "Columbia_South Core", "Columbia_South Matrix", "Frisby_Boulder Core", "Frisby_Boulder Matrix", "Hart_Ranges Core", "Hart_Ranges Matrix", "Kennedy_Siding Core", "Kennedy_Siding Matrix", "North_Cariboo Core", "North_Cariboo Matrix", "Purcell_Central Core", "Purcell_Central Matrix", "Purcells_South Core", "Purcells_South Matrix", "South_Selkirks Core", "South_Selkirks Matrix", "Wells_Gray_North Core", "Wells_Gray_North Matrix", "Wells_Gray_South Core", "Wells_Gray_South Matrix", "Redrock_Prairie_Creek Core", "Redrock_Prairie_Creek Matrix"),
                                    value = c (1:56),
                                    r50fe_int = 7.689,
                                    r50fe_core = 0.108,
                                    r50fe_matrix = -0.551,
                                    c80r50fe_int = 7.389,
                                    c80r50fe_core = -0.109,
                                    c80r50fe_matrix = -0.093,
                                    c80fe_int = 7.14,
                                    c80fe_core = -0.122,
                                    c80fe_matrix = -0.102,
                                    r50re_int = c (-3.374, -3.374, 0, 0, 0, 0, 0, 0, 0, -2.484, -2.484, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2.493, 2.493, 0, 0, 1.429, 1.429, 0, 0, -0.67, -0.67, 1.239, 1.239, -1.499, -1.499, 1.523, 1.523, 0, 0, 1.686, 1.686, -2.719, -2.719, 0.818, 0.818, 0, 0, 1.558, 1.558, 0, 0, 0, 0),
                                    r50re_core = c (0.945, 0.945, 0, 0, 0, 0, 0, 0, 0, 0.636, 0.636, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -0.718, -0.718, 0, 0, -0.387, -0.387, 0,  0, 0.326, 0.326, -0.84, -0.84, 0.663, 0.663, -0.45, -0.45, 0, 0, -0.515, -0.515, 0.791, 0.791, -0.303, -0.303, 0, 0, -0.146, -0.146, 0, 0, 0, 0),
                                    c80r50re_int = c (-4.363, -4.363, 0, 0, 0, 0, 0, 0, 0, -3.749, -3.749, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4.919, 4.919, 0, 0, 1.212, 1.212, 0, 0, -0.563, -0.563, 0.917, 0.917, -0.483, -0.483, 1.25, 1.25, 0, 0, 2.492, 2.492, -3.979, -3.979, 1.334, 1.334, 0, 0, 1.013, 1.013, 0, 0, 0, 0),
                                    c80r50re_core = c (0.38, 0.38, 0, 0, 0, 0, 0, 0, 0, 0.243, 0.243, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -0.265, -0.265, 0, 0, -0.191, -0.191, 0, 0, 0.129, 0.129, -0.26, -0.26, 0.048, 0.048, -0.098, -0.098, 0, 0, -0.178, -0.178, .293, 0.293, -0.12, -0.12, 0, 0, 0.019, 0.019, 0, 0, 0, 0),
                                    c80re_int = c (-4.259, -4.259, 0, 0, 0, 0, 0, 0, 0, -3.438, -3.438, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4.205, 4.205, 0, 0, 1.215, 1.215, 0, 0, -0.46, -0.46, 0.772, 0.772, -0.441, -0.441, 1.467, 1.467, 0, 0, 2.685, 2.685, -3.949, -3.949, 1.176, 1.176, 0, 0, 1.027, 1.027, 0, 0, 0, 0),
                                    c80re_core = c (0.454, 0.454, 0, 0, 0, 0, 0, 0, 0, 0.209, 0.209, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -0.133, -0.133, 0, 0, -0.269, -0.269, 0, 0, 0.141, 0.141, -0.343, -0.343, 0.035, 0.035, -0.126, -0.126, 0, 0, -0.166, -0.166, 0.306, 0.306, -0.148, -0.148, 0, 0, 0.041, 0.041, 0, 0, 0, 0)
  )
  
  return(invisible(sim))
}
