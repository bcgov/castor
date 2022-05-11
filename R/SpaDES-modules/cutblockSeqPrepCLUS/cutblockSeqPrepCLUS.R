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
#===========================================================================================

defineModule(sim, list(
  name = "cutblockSeqPrepCLUS",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", cutblockSeqPrepCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "cutblockSeqPrepCLUS.Rmd"),
  reqdPkgs = list("rpostgis", "sp","sf", "dplyr", "SpaDES.core"),
  parameters = rbind( 
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter("queryCutblocks", "character", "cutseq", NA, NA, "This describes the type of query for the cutblocks"),
    defineParameter("getArea", "logical", FALSE, NA, NA, "This describes if the area ha should be returned for each landing"),
    defineParameter("resetAge", "logical", FALSE, NA, NA, "Set this to TRUE to define roadyear and roadstatus as the time since the road was built/used. If FALSE then it returns the sequence that the road was built/used."),
    defineParameter("startHarvestYear", "numeric", 1980, NA, NA, "This describes the min year from which to query the cutblocks"),
    defineParameter("simulationTimeStep", "numeric", 1, NA, NA, "This describes the simulation time step interval"),
    defineParameter("startTime", "numeric", start(sim), NA, NA, desc = "Simulation time at which to start"),
    defineParameter("endTime", "numeric", end(sim), NA, NA, desc = "Simulation time at which to end"),
    defineParameter("cutblockSeqInterval", "numeric", 1, NA, NA, desc = "This describes the interval for the sequencing or scheduling of the cutblocks"),
    defineParameter("nameCutblockRaster", "character", "99999", NA, NA, desc = "Name of the raster with ID pertaining to cutlocks - consolidated cutblocks"),
    defineParameter("nameCutblockTable", "character", "99999", NA, NA, desc = "Name of the cutblocm attribution table with ID pertaining to cutlocks - consolidated cutblocks"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", 1, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput("boundaryInfo", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("harvestUnits", objectClass ="RasterLayer", desc = NA, sourceURL = NA),
    expectsInput(objectName ="clusdb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates clus realted information", sourceURL = NA)
    
  ),
  outputObjects = bind_rows(
    createsOutput("landings", "SpatialPoints", "This describes a series of point locations representing the cutblocks or their landings", ...),
    createsOutput("landingsArea", "numeric", "This creates a vector of area in ha for each landing", ...),
    createsOutput(objectName = "updateInterval", objectClass = "numeric", desc = NA)
    #createsOutput(objectName = NA, objectClass = NA, desc = NA)
  )
))

doEvent.cutblockSeqPrepCLUS = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    
    init = {
      sim<-Init(sim)
      sim <- getHistoricalLandings(sim) #Get the XY location of the historical cutblock landings
      
      if(nrow(dbGetQuery(sim$clusdb, "SELECT * FROM sqlite_master WHERE type = 'table' and name ='blocks'")) == 0){
        sim <- createBlocksTable(sim)#create blockid column blocks and adjacency table
        sim <- getExistingCutblocks(sim) #updates pixels to include existing blocks
        sim <- scheduleEvent(sim, time(sim) + P(sim)$cutblockSeqInterval,"cutblockSeqPrepCLUS", "updateAge",  7)
      }
      
      sim <- scheduleEvent(sim, time(sim) + P(sim)$cutblockSeqInterval, "cutblockSeqPrepCLUS", "cutblockSeqPrep", 6)
      sim <- scheduleEvent(sim, end(sim), "cutblockSeqPrepCLUS", "finalAge", 8)
      
    },
    
    cutblockSeqPrep = {
      sim <- getLandings(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim)$cutblockSeqInterval, "cutblockSeqPrepCLUS", "cutblockSeqPrep",6)
    },
    
    updateAge = {
      sim <- incrementAge(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim)$cutblockSeqInterval, "cutblockSeqPrepCLUS", "updateAge", 7)
    },
    
    finalAge = {
      sim <- finalAgeCalc(sim)
    },
    
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  sim$landings <- NULL
  sim$landingsArea <- NULL
  sim$updateInterval<- 1 #this object is defined in growingStockCLUS
  return(invisible(sim))
}

### Set the list of the cutblock locations
getHistoricalLandings <- function(sim) {
  sim$histLandings <- getTableQuery(paste0("SELECT harvestyr, x, y, areaha from ", P(sim)$queryCutblocks , ", (Select ", sim$boundaryInfo[[4]], " FROM ", sim$boundaryInfo[[1]] , " WHERE ", sim$boundaryInfo[[2]] ," IN ('", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "', '") ,"')", ") as h
              WHERE h.", sim$boundaryInfo[[4]] ," && ",  P(sim)$queryCutblocks, ".point 
                                         AND ST_Contains(h.", sim$boundaryInfo[[4]]," ,",P(sim)$queryCutblocks,".point) ORDER BY harvestyr"))
  
  if(length(sim$histLandings)==0){ 
    message("histLandings is NULL")
    sim$histLandings <- NULL
  }else{
    landings <- sim$histLandings %>% dplyr::filter(harvestyr <= P(sim)$startHarvestYear) 
    if(nrow(landings) > 0){
      message('geting pre landings')
      #TO DO: remove the labelling of column and rows with numbers like c(2,3) should be c("x", "y")
      sim$landings <- SpatialPoints(coords = as.matrix(landings[,c(2,3)]), proj4string = CRS("+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0 +datum=NAD83
                          +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0"))
      sim$landingsArea <- NULL
    }else{
      print('NO pre landings in: ')
      sim$landings <- NULL
      sim$landingsArea <- NULL
    }
  }
  
  return(invisible(sim))
}

### Set a list of cutblock locations as a Spatial Points object
getLandings <- function(sim) {
  message("get landings")
  if(!is.null(sim$histLandings)){
    landings <- sim$histLandings %>% dplyr::filter(harvestyr == time(sim) + P(sim)$startHarvestYear) 
    if(nrow(landings) > 0){
      print(paste0('geting landings in: ', time(sim)))
      #TO DO: remove the labelling of column and rows with numbers like c(2,3) should be c("x", "y")
      sim$landings<- SpatialPoints(coords = as.matrix(landings[,c(2,3)]), proj4string = CRS("+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0 +datum=NAD83
                          +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0"))
      #TODO: put a unique statement here? so that there aren't duplicate of the same landing location
      if(P(sim)$getArea){sim$landingsArea<-landings[,4]}else {sim$landingsArea<-NULL}
      
    }else{
      print(paste0('NO landings in: ', time(sim)))
      sim$landings <- NULL
      sim$landingsArea <- NULL
    }
  }
  return(invisible(sim))
}

createBlocksTable<-function(sim){
  message("create blockid, blocks and adjacentBlocks")
  dbExecute(sim$clusdb, "ALTER TABLE pixels ADD COLUMN blockid integer DEFAULT 0")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS blocks ( blockid integer DEFAULT 0, age integer, height numeric, vol numeric, salvage_vol numeric, dist numeric DEFAULT 0, landing integer)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS adjacentBlocks ( id integer PRIMARY KEY, adjblockid integer, blockid integer)")
  return(invisible(sim)) 
}


getExistingCutblocks<-function(sim){
  if(!(P(sim, "nameCutblockRaster", "cutblockSeqPrepCLUS") == '99999')){
    message(paste0('..getting cutblocks: ',P(sim, "nameCutblockRaster", "cutblockSeqPrepCLUS")))
    ras.blk<- RASTER_CLIP2(srcRaster= P(sim, "nameCutblockRaster", "cutblockSeqPrepCLUS"),
                           tmpRast = paste0('temp_', sample(1:10000, 1)),
                           clipper=sim$boundaryInfo[1] , 
                           geom= sim$boundaryInfo[4] , 
                           where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL)
    if(extent(sim$ras) == extent(ras.blk)){
      exist_cutblocks<-data.table(blockid = ras.blk[])
      exist_cutblocks[, pixelid := seq_len(.N)][, blockid := as.integer(blockid)]
      exist_cutblocks<-exist_cutblocks[blockid > 0, ]
      
      #add to the clusdb
      message('...updating blockids')
      dbBegin(sim$clusdb)
        rs <- dbSendQuery(sim$clusdb, "Update pixels set blockid = :blockid where pixelid = :pixelid", exist_cutblocks)
      dbClearResult(rs)
      dbCommit(sim$clusdb)
      
      message('...getting age')
      blocks.age<-getTableQuery(paste0("SELECT (", P(sim)$startHarvestYear, " - harvestyr) as age, cutblockid as blockid from ", P(sim, "nameCutblockTable", "cutblockSeqPrepCLUS"), 
                                       " where cutblockid in ('",paste(unique(exist_cutblocks$blockid), collapse = "', '"), "');"))
      
      dbExecute(sim$clusdb, "CREATE INDEX index_blockid on pixels (blockid)")
      #Set the age
      message('...updating age')
      dbBegin(sim$clusdb)
        rs <- dbSendQuery(sim$clusdb, "Update pixels set age = :age where blockid = :blockid", blocks.age)
      dbClearResult(rs)
      dbCommit(sim$clusdb)
      
      rm(ras.blk,exist_cutblocks, blocks.age)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameCutblockRaster", "blockingCLUS")))
    }
  }
  return(invisible(sim))
}


incrementAge <- function(sim) {
  message("...increment age")
  dbExecute(sim$clusdb, "DROP INDEX index_age")
  #Update the pixels table
  dbBegin(sim$clusdb)
  rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET age = age + 1")
  dbClearResult(rs)
  dbCommit(sim$clusdb)
  dbExecute(sim$clusdb, "CREATE INDEX index_age on pixels (age)")
  
  #message("...write Raster")
  #sim$age<-sim$ras
  #sim$age[]<-unlist(c(dbGetQuery(sim$clusdb, "SELECT age FROM pixels order by pixelid")), use.names =FALSE)
  #writeRaster(sim$age, file=paste0(P(sim)$outputPath,  sim$boundaryInfo[[3]][[1]],"_age_", time(sim), ".tif"), format="GTiff", overwrite=TRUE)
  
  return(invisible(sim))
}


setBlocksTable <- function(sim) {
  message("set the blocks table")
  dbExecute(sim$clusdb, paste0("INSERT INTO blocks (blockid, age) 
                    SELECT blockid, round(AVG(age),0) as age
                                       FROM pixels WHERE blockid > 0 GROUP BY blockid "))
  
  dbExecute(sim$clusdb, "CREATE INDEX index_blockid on blocks (blockid)")
  return(invisible(sim))
}


.inputObjects <- function(sim) {
  if(!suppliedElsewhere("boundaryInfo", sim)){
    sim$boundaryInfo<-c("gcbp_carib_polygon","herd_name","Muskwa","geom")
  }
  return(invisible(sim))
}

finalAgeCalc <- function (sim) { # this function inverts the roadstatus and roadyear from the time it was built/used in the backcast to its age (i.e., end time - year it was built/used)
  if(P(sim)$resetAge) { # if TRUE
    message("Setting roadyear and roadstatus as negative age.")
    
    # update the db
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, paste0("UPDATE pixels SET roadstatus = (",  end(sim), " - roadstatus) * -1,  roadyear = (",  end(sim), " - roadyear) * -1 WHERE roadtype != 0 OR roadtype IS NULL"))    
    dbClearResult(rs)
    dbCommit(sim$clusdb)
    # then update the rasters
    sim$road.year<-sim$ras
    sim$road.year[]<-dbGetQuery(sim$clusdb, 'SELECT roadyear FROM pixels')$roadyear
    sim$road.status<-sim$ras
    sim$road.status[]<-dbGetQuery(sim$clusdb, 'SELECT roadstatus FROM pixels')$roadstatus
    
    
    
  } else { # if FALSE
    message("Keeping roadyear and roadstatus as sequence.")
  }
  
  return(invisible(sim))
}
