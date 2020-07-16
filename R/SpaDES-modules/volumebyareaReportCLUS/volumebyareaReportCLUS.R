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
  description = "This module reports otu volume havrested by time tep within an area of itnerest", #"insert module description here",
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
  reqdPkgs = list("raster"),
  parameters = rbind(
    defineParameter("harvestPixelList", "character", '99999', NA, NA, "Table of blocks harvested "),
    defineParameter("AreaofInterestTable", "character", '99999', NA, NA, "Value attribute table that links to the raster and describes the boundaries of the critical habitat"),
    defineParameter("AreaofInterestRaster", "character", '99999', NA, NA, "Raster that describes the boundaries of the critical habitat"),
    
    
    
    
    
    defineParameter("calculateInterval", "numeric", 1, NA, NA, "The simulation time at which disturbance indicators are calculated"),
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
    expectsInput(objectName = "harvestPixelList", objectClass ="data.table", desc = 'Table of harvest queue cut at each time interval.', sourceURL = NA)
    
    ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput("vol", "data.table", "Volume table for every pixel in the area of interest"),
    createsOutput("volumebyareaReport", "data.table", "Summary per simulation time step of the volume and area harvested inare of interest.")
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
      sim <- volAnalysis(sim)
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
    sim$vol[, area_of_interest := 1]
    } else {
    bounds <- data.table (c (t (raster::as.matrix( 
    RASTER_CLIP2(tmpRast = sim$boundaryInfo[[3]], 
                 srcRaster = P(sim, "volumebyareaReportCLUS", "AreaofInterestRaster"), 
                 clipper = sim$boundaryInfo[[1]],  # by the area of analysis (e.g., supply block/TSA)
                 geom = sim$boundaryInfo[[4]], 
                 where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                 conn = NULL)))))
    bounds[,pixelid:=seq_len(.N)]#make a unique id to ensure it merges correctly
    if(nrow(bounds[!is.na(V1),]) > 0){ #check to see if some of the aoi overlaps with the boundary
      if(!(P(sim, "volumebyareaReportCLUS", "AreaofInterestTable") == '99999')){
        crit_lu<-data.table(getTableQuery(paste0("SELECT cast(value as int) , aoi FROM ",P(sim, "volumebyareaReportCLUS", "AreaofInterestTable"))))
        bounds<-merge(bounds, crit_lu, by.x = "V1", by.y = "value", all.x = TRUE)
      } else {
      stop(paste0(P(sim, "volumebyareaReportCLUS", "AreaofInterestRaster"), "- does not overlap with harvest unit"))
      }
    setorder(bounds, pixelid) #sort the bounds
    sim$vol[, area_of_interest:= bounds$aoi]
    }
  }
}


# assign volume to area of interest
volAnalysis <- function(sim) {
  dt_select<-data.table(dbGetQuery(sim$clusdb, 
                                   paste0("SELECT pixelid and volume FROM harvestPixelList"))) # 
  if(nrow(dt_select) > 0){
    dt_select[, field := 0]
    outPts<-merge(sim$vol, dt_select, by = 'pixelid', all.x =TRUE) 
    sim$vol<-merge(sim$vol, outPts[,c("pixelid","volume")], by = 'pixelid', all.x =TRUE)
    
  }

  # Sum the volume 
  tempVolumeReport <- merge(tempVolumeReport, sim$vol[, .(tot_volume = sum (volume)), by = "area_of_interest"])
  tempVolumeReport[, .(tot_area := uniqueN(.I)), by = "area_of_interest"]
  tempVolumeReport[, c("scenario", "compartment", "timeperiod", "area_of_interest", "volume_harvest", "area_harvest") := list(scenario$name, sim$boundaryInfo[[3]],time(sim)*sim$updateInterval, area_of_interest, tot_volume, tot_area)]

  sim$volReport <- rbindlist(list(sim$volumebyareaReport, tempVolumeReport), use.names=TRUE )

  return(invisible(sim))
}

.inputObjects <- function(sim) {
  
  return(invisible(sim))
}

