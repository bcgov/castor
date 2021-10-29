# Copyright 2020rsf_ Province of British Columbia
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
  name = "disturbanceCalcCLUS",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", disturbanceCalcCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "disturbanceCalcCLUS.Rmd"),
  reqdPkgs = list("raster"),
  parameters = rbind(
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
    expectsInput(objectName ="updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA)
    #expectsInput(objectName ="harvestPixelList", objectClass ="data.table", desc = 'The list of pixels being harvesting in a time period', sourceURL = NA)
    ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput("salvageReport", "data.table", "Summary per simulation year of the disturbance indicators")
  )
))

doEvent.disturbanceCalcCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init (sim) # this function inits 
      sim <- scheduleEvent(sim, time(sim) , "salvageCLUS", "analysis", 9)
    },
    analysis = {
      sim <- salvageAnalysis(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "salvageCLUS", "calculateInterval"), "salvageCLUS", "analysis", 9)
    },
    
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  sim$salvageReport<-data.table(scenario = character(), compartment = character(), 
                                    timeperiod= integer(), critical_hab = character(), 
                                    total_area = numeric() )
  
  message("...Get the critical habitat")
  if(P(sim, "salvageCLUS", "criticalHabRaster") == '99999'){
    sim$salvage[, critical_hab:= 1]
  }else{
    bounds <- data.table (c (t (raster::as.matrix( 
    RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                 srcRaster = P(sim, "salvageCLUS", "criticalHabRaster"), 
                 clipper = sim$boundaryInfo[[1]],  # by the area of analysis (e.g., supply block/TSA)
                 geom = sim$boundaryInfo[[4]], 
                 where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                 conn = NULL)))))
    bounds[,pixelid:=seq_len(.N)] # make a unique id to ensure it merges correctly
    if(nrow(bounds[!is.na(V1),]) > 0){ #check to see if some of the aoi overlaps with the boundary
      if(!(P(sim, "salvageCLUS", "criticalHabitatTable") == '99999')){
        crit_lu<-data.table(getTableQuery(paste0("SELECT cast(value as int) , crithab FROM ",P(sim, "salvageCLUS", "criticalHabitatTable"))))
        bounds<-merge(bounds, crit_lu, by.x = "V1", by.y = "value", all.x = TRUE)
      }else{
        stop(paste0("ERROR: need to supply a lookup table: ", P(sim, "rsfCLUS", "criticalHabitatTable")))
      }
    }else{
      stop(paste0(P(sim, "salvageCLUS", "criticalHabRaster"), "- does not overlap with aoi"))
    }
    setorder(bounds, pixelid) #sort the bounds
    sim$salvage[, critical_hab:= bounds$crithab]
    sim$salvage[, compartment:= dbGetQuery(sim$clusdb, "SELECT compartid FROM pixels order by pixelid")$compartid]
    sim$salvage[, treed:= dbGetQuery(sim$clusdb, "SELECT treed FROM pixels order by pixelid")$treed]
  }
  
  #get the salvage volume raster
  #check it a field already in sim$clusdb?
  if(dbGetQuery (sim$clusdb, "SELECT COUNT(*) as exists_check FROM pragma_table_info('pixels') WHERE name='perm_dist';")$exists_check == 0){
    # add in the column
    dbExecute(sim$clusdb, "ALTER TABLE pixels ADD COLUMN salvage_vol numeric DEFAULT 0")
    # add in the raster
    if(P(sim, "salvageCLUS", "salvageRaster") == '99999'){
      message("WARNING: No salvage raster specified ... defaulting to no salvage opportunities")
    }else{
      salvage_vol<- data.table (c(t(raster::as.matrix( 
        RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                     srcRaster = P(sim, "salvageCLUS", "salvageRaster"), 
                     clipper = sim$boundaryInfo[[1]],  # by the area of analysis (e.g., supply block/TSA)
                     geom = sim$boundaryInfo[[4]], 
                     where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                     conn = NULL)))))
    salvage_vol[,pixelid:=seq_len(.N)]#make a unique id to ensure it merges correctly
    setnames(perm_dist, "V1", "salvage_vol")
    #add to the clusdb
    dbBegin(sim$clusdb)
      rs<-dbSendQuery(sim$clusdb, "Update pixels set salvage_vol = :salvage_vol where pixelid = :pixelid", salvage_vol)
    dbClearResult(rs)
    dbCommit(sim$clusdb)
    
    #clean up
    rm(salvage_vol)
    gc()
    }
  }else{
    message("...using existing salvage raster")
  }
  
  return(invisible(sim))
}

salvageAnalysis <- function(sim) {
  
}



.inputObjects <- function(sim) {
  
  return(invisible(sim))
}

