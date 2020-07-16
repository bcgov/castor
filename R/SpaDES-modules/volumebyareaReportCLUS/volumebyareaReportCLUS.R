# Copyright 2020 Province of British Columbia
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
  name = "volumebyareaReportCLUS",
  description = "This module reports out volume havrested by time step within an area of interest",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", volumebyareaReportCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "volumebyareaReportCLUS.Rmd"),
  reqdPkgs = list("raster", "data.table"),
  parameters = rbind(
    defineParameter("AreaofInterestTable", "character", '99999', NA, NA, "Value attribute table that links to the raster integer and describes each area of interest."),
    defineParameter("AreaofInterestRaster", "character", '99999', NA, NA, "Raster that describes the boundaries of each area of interest."),
    defineParameter("calculateInterval", "numeric", 1, NA, NA, "The simulation time at which volumes are calculated"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput(objectName = "boundaryInfo", objectClass = "character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "clusdb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the RSF', sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "RasterLayer", desc = "A raster object created in dataLoaderCLUS. It is a raster defining the area of analysis (e.g., supply blocks/TSAs).", sourceURL = NA),
    expectsInput(objectName = "pts", objectClass = "data.table", desc = "Centroid x,y locations of the ras.", sourceURL = NA),
    expectsInput(objectName = "scenario", objectClass = "data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName = "updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA),
    expectsInput(objectName = "harvestPixelList", objectClass ="data.table", desc = 'The list of pixels being harvesting in a time period.', sourceURL = NA)
    
    ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput("vol", "data.table", "Table of every pixel in the area of interest; gets joined to the harvestpixelList to create the volume report."),
    createsOutput("volumebyareaReport", "data.table", "Summary per simulation time step of the volume and area harvested in each area of interest.")
  )
))

doEvent.volumebyareaReportCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init (sim) # this function inits 
      sim <- scheduleEvent(sim, time(sim) , "volumebyareaReportCLUS", "analysis", 9)
    },
    analysis = {
      sim <- volAnalysis (sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "volumebyareaReportCLUS", "calculateInterval"), "volumebyareaReportCLUS", "analysis", 9)
    },
    
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  sim$volumebyareaReport <- data.table (scenario = character(), 
                                        compartment = character(), 
                                        timeperiod = integer(),
                                        area_of_interest = character(),
                                        volume_harvest = numeric(),
                                        area_harvest = numeric())
  sim$vol <- sim$pts
  
  #Get the area of interest
  if(P(sim, "volumebyareaReportCLUS", "AreaofInterestRaster") == '99999') {
    sim$vol[, aoi := 1]
    } else {
    aoi_bounds <- data.table (c (t (raster::as.matrix( 
    RASTER_CLIP2(tmpRast = sim$boundaryInfo[[3]], 
                 srcRaster = P(sim, "volumebyareaReportCLUS", "AreaofInterestRaster"), 
                 clipper = sim$boundaryInfo[[1]],  
                 geom = sim$boundaryInfo[[4]], 
                 where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                 conn = NULL)))))
    aoi_bounds [, pixelid := seq_len (.N)]
    if(nrow(aoi_bounds[!is.na(V1),]) > 0){
      if(!(P(sim, "volumebyareaReportCLUS", "AreaofInterestTable") == '99999')){
        aoi_lu <- data.table (getTableQuery (paste0 ("SELECT cast (value as int) , zone FROM ",P(sim, "volumebyareaReportCLUS", "AreaofInterestTable"))))
        aoi_bounds <- merge(aoi_bounds, aoi_lu, by.x = "V1", by.y = "value", all.x = TRUE)
      } else {
      stop(paste0(P(sim, "volumebyareaReportCLUS", "AreaofInterestRaster"), "- does not overlap with harvest unit"))
      }
    setorder(aoi_bounds, pixelid) #sort the bounds
    sim$vol [, aoi := aoi_bounds$zone]
    }
  }
}


# assign volume to area of interest
volAnalysis <- function(sim) {
 
  tempVolumeReport <- merge (sim$vol, sim$harvestPixelList, by = 'pixelid', all.x = TRUE) 
  tempVolumeReport [, .(tot_volume := sum (vol_h)), by = "aoi"]
  tempVolumeReport [, .(tot_area := uniqueN(.I)), by = "aoi"]
  tempVolumeReport [, c("scenario", "compartment", "timeperiod", "area_of_interest", "volume_harvest", "area_harvest") := list(scenario$name, 
                                                                                                                              sim$boundaryInfo[[3]],
                                                                                                                              time(sim)*sim$updateInterval, 
                                                                                                                              aoi, 
                                                                                                                              tot_volume, 
                                                                                                                              tot_area)]
  sim$volumebyareaReport <- rbindlist(list(sim$volumebyareaReport, tempVolumeReport), use.names = TRUE )

  return(invisible(sim))
}

.inputObjects <- function(sim) {
  
  return(invisible(sim))
}

