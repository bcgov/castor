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
  name = "dataLoaderCLUS",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
    person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", dataLoaderCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "dataLoaderCLUS.Rmd"),
  reqdPkgs = list("sf", "rpostgis","DBI", "RSQLite", "data.table", "velox"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant"),
    defineParameter("startTime", "numeric", start(sim), NA, NA, desc = "Simulation time at which to start"),
    defineParameter("endTime", "numeric", end(sim), NA, NA, desc = "Simulation time at which to end"),
    defineParameter("dbName", "character", "postgres", NA, NA, "The name of the postgres dataabse"),
    defineParameter("dbHost", "character", 'localhost', NA, NA, "The name of the postgres host"),
    defineParameter("dbPort", "character", '5432', NA, NA, "The name of the postgres port"),
    defineParameter("dbUser", "character", 'postgres', NA, NA, "The name of the postgres user"),
    defineParameter("dbPassword", "character", 'postgres', NA, NA, "The name of the postgres user password"),
    defineParameter("nameBoundaryFile", "character", "gcbp_carib_polygon", NA, NA, desc = "Name of the boundary file. Here we are using caribou herd boudaries, could be something else (e.g., TSA)."),
    defineParameter("nameBoundaryColumn", "character", "herd_name", NA, NA, desc = "Name of the column within the boundary file that has the boundary name. Here we are using the herd name column in the caribou herd spatial polygon file."),
    defineParameter("nameBoundary", "character", "Muskwa", NA, NA, desc = "Name of the boundary - a spatial polygon within the boundary file. Here we are using a caribou herd name to query the caribou herd spatial polygon data, but it could be something else (e.g., a TSA name to query a TSA spatial polygon file, or a group of herds or TSA's)."),
    defineParameter("nameBoundaryGeom", "character", "geom", NA, NA, desc = "Name of the geom column in the boundary file"),
    defineParameter("save_clusdb", "logical", FALSE, NA, NA, desc = "Save the db to a file?"),
    defineParameter("chilcotin_study_area", "character", "default_name", NA, NA, desc = "Nmae of the sqlite database to be saved"),
    defineParameter("useCLUSdb", "character", "99999", NA, NA, desc = "Use an exising db? If no, set to 99999. IOf yes, put in the postgres database name here (e.g., clus)."),
    defineParameter("nameZoneRasters", "character", "99999", NA, NA, desc = "Administrative boundary containing zones of management objectives"),
    defineParameter("nameZonePriorityRaster", "character", "99999", NA, NA, desc = "Boundary of zones where harvesting should be prioritized"),
    defineParameter("nameCompartmentRaster", "character", "99999", NA, NA, desc = "Name of the raster in a pg db that represents a compartment or supply block. Not currently in the pgdb?"),
    defineParameter("nameCompartmentTable", "character", "99999", NA, NA, desc = "Name of the table in a pg db that represents a compartment or supply block value attribute look up. CUrrently 'study_area_compart'?"),
    defineParameter("nameMaskHarvestLandbaseRaster", "character", "99999", NA, NA, desc = "Administrative boundary related to operability of the the timber harvesting landbase. This mask is between 0 and 1, representing where its feasible to harvest"),
    defineParameter("nameAgeRaster", "character", "99999", NA, NA, desc = "Raster containing pixel age. Note this references the yield table. Thus, could be initially 0 if the yield curves reflect the age at 0 on the curve"),
    defineParameter("nameTreedRaster", "character", "99999", NA, NA, desc = "Raster containing pixel classified as treed"),
    defineParameter("nameSiteIndexRaster", "character", "99999", NA, NA, desc = "Raster containing site index used in uncertainty model of yields"),
    defineParameter("nameCrownClosureRaster", "character", "99999", NA, NA, desc = "Raster containing pixel crown closure. Note this could be a raster using VCF:http://glcf.umd.edu/data/vcf/"),
    defineParameter("nameHeightRaster", "character", "99999", NA, NA, desc = "Raster containing pixel height. EX. Canopy height model"),
    defineParameter("nameZoneTable", "character", "99999", NA, NA, desc = "Name of the table documenting the zone types"),
    defineParameter("nameYieldsRaster", "character", "99999", NA, NA, desc = "Name of the raster with id's for yield tables"),
    defineParameter("nameYieldsTransitionRaster", "character", "99999", NA, NA, desc = "Name of the raster with id's for yield tables that transition to a new table"),
    defineParameter("nameYieldTable", "character", "99999", NA, NA, desc = "Name of the table documenting the yields"),
    defineParameter("nameYieldTransitionTable", "character", "99999", NA, NA, desc = "Name of the table documenting the yields that transition"),
    defineParameter("nameOwnershipRaster", "character", "99999", NA, NA, desc = "Name of the raster from GENERALIZED FOREST OWNERSHIP"),
    defineParameter("nameForestInventoryTable", "character", "99999", NA, NA, desc = "Name of the veg comp table - the forest inventory"),
    defineParameter("nameForestInventoryRaster", "character", "99999", NA, NA, desc = "Name of the veg comp - the forest inventory raster of the primary key"),
    defineParameter("nameForestInventoryKey", "character", "99999", NA, NA, desc = "Name of the veg comp primary key that links the table to the raster"),
    defineParameter("nameForestInventoryAge", "character", "99999", NA, NA, desc = "Name of the veg comp age"),
    defineParameter("nameForestInventoryHeight", "character", "99999", NA, NA, desc = "Name of the veg comp height"),
    defineParameter("nameForestInventoryCrownClosure", "character", "99999", NA, NA, desc = "Name of the veg comp crown closure"),
    defineParameter("nameForestInventoryTreed", "character", "99999", NA, NA, desc = "Name of the veg treed layer"),
    defineParameter("nameForestInventorySiteIndex", "character", "99999", NA, NA, desc = "Name of the veg comp site_index")
    ),
  inputObjects = bind_rows(
    #expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput("nameBoundaryFile", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundary", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundaryColumn", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundaryGeom", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "updateZoneConstraints", objectClass = "data.table", desc = "Table of query parameters for updating the constraints", sourceURL = NA)
    
    ),
  outputObjects = bind_rows(
    createsOutput("zone.length", objectClass ="integer", desc = NA), # the number of zones to constrain on
    createsOutput("zone.available", objectClass ="data.table", desc = NA), # the available zones of the clusdb
    createsOutput("boundaryInfo", objectClass ="character", desc = NA),
    createsOutput("clusdb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates clus realted information"),
    createsOutput("ras", objectClass ="RasterLayer", desc = "Raster Layer of the cell index"),
    #createsOutput("rasVelo", objectClass ="velox", desc = "Velox Raster Layer of the cell index - used in roadCLUS for snapping roads"),
    createsOutput(objectName = "pts", objectClass = "data.table", desc = "A data.table of X,Y locations - used to find distances"),
    createsOutput(objectName = "foreststate", objectClass = "data.table", desc = "A data.table of the current state of the aoi")
  )
))

doEvent.dataLoaderCLUS = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    init = { # initialization event
      #setBoundaries
      sim$boundaryInfo <- list(P(sim, "dataLoaderCLUS", "nameBoundaryFile"),P(sim, "dataLoaderCLUS", "nameBoundaryColumn"),P(sim, "dataLoaderCLUS", "nameBoundary"), P(sim, "dataLoaderCLUS", "nameBoundaryGeom")) # list of boundary parameters to set the extent of where the model will be run; these parameters are expected inputs in dataLoader 
      sim$zone.length<-length(P(sim, "dataLoaderCLUS", "nameZoneRasters")) # used to define the number of different management constraint zones
      
      if(P(sim, "dataLoaderCLUS", "useCLUSdb") == "99999"){
        #build clusdb
        sim <- createCLUSdb(sim) # function (below) that creates an SQLLite database
        #populate clusdb tables
        sim <- setTablesCLUSdb(sim)
        sim <- setZoneConstraints(sim)
        sim <- setIndexesCLUSdb(sim) # creates index to facilitate db querying?
        sim <- updateGS(sim) # update the forest attributes
        sim <- scheduleEvent(sim, eventTime = 0,  "dataLoaderCLUS", "forestStateNetdown", eventPriority=90)
        
       }else{
         #copy existing clusdb
        sim$foreststate<-NULL
        message(paste0("Loading existing db...", P(sim, "dataLoaderCLUS", "useCLUSdb")))
        #Make a copy of the db here so that the clusdb is in memory
        userdb <- dbConnect(RSQLite::SQLite(), dbname = P(sim, "dataLoaderCLUS", "useCLUSdb") ) # connext to pgdb
        sim$clusdb <- dbConnect(RSQLite::SQLite(), ":memory:") # save the pgdb in memory (object in sim)
        RSQLite::sqliteCopyDatabase(userdb, sim$clusdb)
        dbDisconnect(userdb)
        
        dbExecute(sim$clusdb, "PRAGMA synchronous = OFF") # update the database
        dbExecute(sim$clusdb, "PRAGMA journal_mode = OFF")
        
        sim$ras<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                              srcRaster= P(sim, "dataLoaderCLUS", "nameCompartmentRaster"), # function sourced from R_Postgres file
                              clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                              geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                              where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                              conn=NULL)
        
        sim$pts <- data.table(xyFromCell(sim$ras,1:length(sim$ras))) # creates pts at centroids of raster boundary file; seems to be faster that rasterTopoints
        sim$pts <- sim$pts[, pixelid:= seq_len(.N)] #add in the pixelid which streams data in according to the cell number = pixelid
        
        pixels <- data.table(c(t(raster::as.matrix(sim$ras)))) # turn raster into table of pixels and give them a sequential ID
        pixels[, pixelid := seq_len(.N)]
        
        sim$ras[] <- pixels$pixelid
        sim$rasVelo<-velox::velox(sim$ras) # convert raster to a Velox raster; velox package offers faster exraction and manipulation of rasters
        
       
        #TODO: REMOVE THIS OBJECT??? Get the available zones for other modules to query -- In forestryCLUS the zones that are not part of the scenario get deleted.
        sim$zone.available<-data.table(dbGetQuery(sim$clusdb, "SELECT * FROM zone;")) 
        
        #Alter the ZoneConstraints table with a data.table object?
        if(!is.null(sim$updateZoneConstraints)){
          message("updating zoneConstraints")
          sql<- paste0("UPDATE zoneconstraints SET type = :type, variable = :variable, percentage = :percentage where reference_zone = :reference_zone AND zoneid = :zoneid")  
          dbBegin(sim$clusdb)
          rs<-dbSendQuery(sim$clusdb, sql, sim$updateZoneConstraints[,c("type", "variable", "percentage", "reference_zone", "zoneid")])
          dbClearResult(rs)
          dbCommit(sim$clusdb)
        }
        #TODO: Remove NA pixels from the db? After sim$ras the complete.cases can be used for transforming back to tifs
      }
      #disconnect the db once the sim is over?
      sim <- scheduleEvent(sim, eventTime = end(sim),  "dataLoaderCLUS", "removeDbCLUS", eventPriority=99)
      
      },
    forestStateNetdown={
      sim <- calcForestState(sim)
    },
    removeDbCLUS={
      sim <- disconnectDbCLUS(sim)
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

disconnectDbCLUS<- function(sim) {
  if(P(sim)$save_clusdb){
    message('Saving clusdb')
    con<-dbConnect(RSQLite::SQLite(), paste0(P(sim, 'dataLoaderCLUS', 'sqlite_dbname'), "_clusdb.sqlite"))
    RSQLite::sqliteCopyDatabase(sim$clusdb, con)
    dbDisconnect(sim$clusdb)
    dbDisconnect(con)
  }else{
    dbDisconnect(sim$clusdb)
  }
    
  return(invisible(sim))
}

createCLUSdb <- function(sim) {
  message ('create clusdb')
  #build the clusdb - a realtional database that tracks the interactions between spatial and temporal objectives
  sim$clusdb <- dbConnect(RSQLite::SQLite(), ":memory:") #builds the db in memory; also resets any existing db! Can be set to store on disk
  #dbExecute(sim$clusdb, "PRAGMA foreign_keys = ON;") #Turns the foreign key constraints on. 
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS yields ( id integer PRIMARY KEY, yieldid integer, age integer, tvol numeric, dec_pcnt numeric, height numeric, eca numeric)")
  #Note Zone table is created as a JOIN with zoneConstraints and zone
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS raster_info (ncell integer, nrow integer)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS zone (zone_column text, reference_zone text)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS zoneConstraints ( id integer PRIMARY KEY, zoneid integer, reference_zone text, zone_column text, ndt integer, variable text, threshold numeric, type text, percentage numeric, denom text, multi_condition text, t_area numeric, start integer, stop integer)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS pixels ( pixelid integer PRIMARY KEY, compartid character, 
own integer, yieldid integer, yieldid_trans integer, zone_const integer DEFAULT 0, treed integer, thlb numeric , elv numeric DEFAULT 0, age numeric, vol numeric, dist numeric DEFAULT 0,
crownclosure numeric, height numeric, siteindex numeric, dec_pcnt numeric, eca numeric, roadyear integer)")
  return(invisible(sim))
}

setTablesCLUSdb <- function(sim) {
  message('...setting data tables')
  #-----------------------
  #Set the compartment IDS
  #-----------------------
  if(!(P(sim, "dataLoaderCLUS", "nameCompartmentRaster") == "99999")){
    message(paste0('.....compartment ids: ', P(sim, "dataLoaderCLUS", "nameCompartmentRaster")))
   sim$ras<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                          srcRaster= P(sim, "dataLoaderCLUS", "nameCompartmentRaster"), 
                          clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                          geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                          where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                          conn=NULL)

    sim$pts <- data.table(xyFromCell(sim$ras,1:length(sim$ras))) #Seems to be faster than rasterTopoints
    sim$pts <- sim$pts[, pixelid:= seq_len(.N)] # add in the pixelid which streams data in according to the cell number = pixelid
    
    pixels <- data.table(c(t(raster::as.matrix(sim$ras))))
    pixels[, pixelid := seq_len(.N)]
    
    #Set V1 to merge in the vat table values so that the column is character
    if(!(P(sim, "dataLoaderCLUS", "nameCompartmentTable") == "99999")){
      compart_vat <- data.table(getTableQuery(paste0("SELECT * FROM ", P(sim, "dataLoaderCLUS", "nameCompartmentTable"))))
      pixels<- merge(pixels, compart_vat, by.x = "V1", by.y = "value", all.x = TRUE )
      pixels[, V1:= NULL]
      col_name<-data.table(colnames(compart_vat))[!V1 == "value"]
      setnames(pixels, col_name$V1 , "compartid")
      #sort the pixels table so that pixelid is in order.
      setorder(pixels, "pixelid")
    }else{
      pixels[, V1 := as.character(V1)]
      setnames(pixels, "V1", "compartid")
    }

    sim$ras[]<-pixels$pixelid
    sim$rasVelo<-velox::velox(sim$ras)
    
    #Add the raster_info
    dbExecute(sim$clusdb, paste0("INSERT INTO raster_info (ncell, nrow) values (", ncell(sim$ras) , ", ", nrow(sim$ras),")"))
    
    #writeRaster(sim$ras, "ras.tif", overwrite = TRUE)
    
  }else{
    message('.....compartment ids: default 1')
    #Set the empty table for values not supplied in the parameters
    sim$ras<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                          srcRaster= 'rast.bc_bound', 
                          clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                          geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                          where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"), 
                          conn=NULL)
    
    sim$pts <-data.table(xyFromCell(sim$ras,1:length(sim$ras))) #Seems to be faster that rasterTopoints
    sim$pts<- sim$pts[, pixelid:= seq_len(.N)] #add in the pixelid which streams data in according to the cell number = pixelid
    
    pixels<-data.table(c(t(raster::as.matrix(sim$ras)))) #transpose then vectorize which matches the same order as adj
    pixels[, pixelid := seq_len(.N)]
    pixels[, compartid := 'all']
    pixels<-pixels[,2:3]
    
    sim$ras[]<-unlist(pixels[,"pixelid"], use.names = FALSE)
    sim$rasVelo<-velox::velox(sim$ras)
    
  }
  
  aoi<-extent(sim$ras)#need to check that each of the extents are the same
  
  #------------
  #Set the Ownership
  #------------
  if(!(P(sim, "dataLoaderCLUS", "nameOwnershipRaster") == "99999")){
    message(paste0('.....ownership: ',P(sim, "dataLoaderCLUS", "nameOwnershipRaster")))
    ras.own<- RASTER_CLIP2(tmpRast =paste0('temp_', sample(1:10000, 1)), 
                           srcRaster= P(sim, "dataLoaderCLUS", "nameOwnershipRaster"), 
                           clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                           geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                           where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL)
    
    if(aoi == extent(ras.own)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.own)))))
      setnames(pixels, "V1", "own")
      rm(ras.own)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "dataLoaderCLUS", "nameOwnershipRaster")))
    }
  }else{
    message('.....ownership: default 1')
    pixels[, own := 1]
  }
  
  #----------------
  #Set the zone IDs
  #----------------
  if(!(P(sim, "dataLoaderCLUS", "nameZoneRasters")[1] == "99999")){
    message(paste0('.....zones: ',P(sim, "dataLoaderCLUS", "nameZoneRasters")))
    zones_aoi<-data.table(zoneid='', zone_column='')
    #Add multiple zone columns - each will have its own raster. Attributed to that raster is a table of the thresholds by zone
    for(i in 1:sim$zone.length){
      ras.zone<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                             srcRaster= P(sim, "dataLoaderCLUS", "nameZoneRasters")[i], 
                             clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                             geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                             where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                             conn=NULL)
      if(aoi == extent(ras.zone)){#need to check that each of the extents are the same
        pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.zone)))))
        setnames(pixels, "V1", paste0('zone',i))#SET zone NAMES to RASTER layer
        dbExecute(sim$clusdb, paste0('ALTER TABLE pixels ADD COLUMN zone', i,' numeric')) # add the zone id column and populate it with the zone names
        dbExecute(sim$clusdb, paste0("INSERT INTO zone (zone_column, reference_zone) values ( 'zone", i, "', '", P(sim, "dataLoaderCLUS", "nameZoneRasters")[i], "')" ))
        # message(head(zones_aoi))
        rm(ras.zone)
        gc()
      } else{
        stop(paste0("ERROR: extents are not the same check -", P(sim, "dataLoaderCLUS", "nameZoneRasters")))
      }
    }
  } else{
    message('.....zone ids: default 1')
    sim$zone.length<-1
    pixels[, zone1:= 1]
    dbExecute(sim$clusdb, "ALTER TABLE pixels ADD COLUMN zone1 integer")
    dbExecute(sim$clusdb, paste0("INSERT INTO zone (zone_column, reference_zone) values ( 'zone1', 'default')" ))
  }
  #------------
  #Set the zonePriorityRaster
  #------------
  if(!P(sim)$nameZonePriorityRaster == '99999'){
    #Check to see if the name of the zone priority raster is already in the zone table
    if(!P(sim)$nameZonePriorityRaster %in% dbGetQuery(sim$clusdb, "SELECT reference_zone from zone")$reference_zone){
      message(paste0('.....zone priority raster not in zones table...fetching: ',P(sim, "dataLoaderCLUS", "nameZonePriorityRaster")))
      ras.zone.priority<- RASTER_CLIP2(tmpRast =paste0('temp_', sample(1:10000, 1)), 
                             srcRaster= P(sim, "dataLoaderCLUS", "nameZonePriorityRaster"), 
                             clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                             geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                             where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                             conn=NULL)
      if(aoi == extent(ras.zone.priority)){#need to check that each of the extents are the same
        pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.zone.priority)))))
        zone.priority<-paste0("zone", as.character(nrow(dbGetQuery(sim$clusdb, "SELECT * FROM zone")) + 1))
        setnames(pixels, "V1", zone.priority)
        #Add the zone priority column to the zone table
        dbExecute(sim$clusdb, paste0("INSERT INTO zone (zone_column, reference_zone) values ('",zone.priority, "', '",P(sim, "dataLoaderCLUS", "nameZonePriorityRaster"),"')"))
        #Add the column name to pixels
        dbExecute(sim$clusdb, paste0("ALTER TABLE pixels ADD COLUMN ",zone.priority," integer"))
        #Add to the zone.length needed when inserting the pixels table
        sim$zone.length<-sim$zone.length + 1
        rm(ras.zone.priority,zone.priority)
        gc()
      }else{
        stop(paste0("ERROR: extents are not the same check -", P(sim, "dataLoaderCLUS", "nameZonePriorityRaster")))
      }
    }
  }
  
  #------------
  #Set the THLB
  #------------
  if(!(P(sim, "dataLoaderCLUS", "nameMaskHarvestLandbaseRaster") == "99999")){
    message(paste0('.....thlb: ',P(sim, "dataLoaderCLUS", "nameMaskHarvestLandbaseRaster")))
    ras.thlb<- RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                            srcRaster= P(sim, "dataLoaderCLUS", "nameMaskHarvestLandbaseRaster"), 
                            clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                            geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                            where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                            conn=NULL)
    if(aoi == extent(ras.thlb)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.thlb)))))
      setnames(pixels, "V1", "thlb")
      rm(ras.thlb)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "dataLoaderCLUS", "nameMaskHarvestLandbaseRaster")))
    }
    
  }else{
    message('.....thlb: default 1')
    pixels[, thlb := 1]
  }
  
  
  #-----------------
  #Set the Yield IDS
  #-----------------
  if(!(P(sim, "dataLoaderCLUS", "nameYieldsRaster") == "99999")){
    message(paste0('.....yield ids: ',P(sim, "dataLoaderCLUS", "nameYieldsRaster")))
    ras.ylds<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                           srcRaster= P(sim, "dataLoaderCLUS", "nameYieldsRaster"), 
                           clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                           geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                           where_clause = paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL)
    if(aoi == extent(ras.ylds)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.ylds)))))
      setnames(pixels, "V1", "yieldid")
      rm(ras.ylds)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "dataLoaderCLUS", "nameYieldsRaster")))
    }
    
    #Check there is a table to link to
    if(P(sim, "dataLoaderCLUS", "nameYieldTable") == "99999"){
      stop(paste0("Specify the nameYieldTable =", P(sim, "dataLoaderCLUS", "nameYieldTable")))
    }
    
    yld.ids<-paste( unique(pixels[!is.na(yieldid),"yieldid"])$yieldid, sep=" ", collapse = ", ")
    
    #Set the yields table with yield curves that are only in the study area
    yields<-getTableQuery(paste0("SELECT ycid, age, tvol, dec_pcnt, height, eca FROM ", P(sim)$nameYieldTable, " where ycid IN (", yld.ids , ");"))
    
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "INSERT INTO yields (yieldid, age, tvol, dec_pcnt, height, eca) 
                      values (:ycid, :age, :tvol, :dec_pcnt, :height, :eca)", yields)
    dbClearResult(rs)
    dbCommit(sim$clusdb)
    
  }else{
    message('.....yield ids: default 1')
    pixels[, yieldid := 1]
    #Set the yields table
    yields<-data.table(yieldid= 1, age= seq(from =0, to=190, by = 10), 
                       tvol = seq(1:20)**2, 
                       dec_pcnt = 0, 
                       height = seq(1:20), 
                       eca = round(1-(seq(1:20)**2/20**2), 2))
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "INSERT INTO yields (yieldid, age, tvol, dec_pcnt, height, eca ) 
                      values (:yieldid, :age, :tvol, :dec_pcnt, :height, :eca)", yields)
    dbClearResult(rs)
    dbCommit(sim$clusdb)
  }
  
  #---Transitionary yields 
  if(!(P(sim, "dataLoaderCLUS", "nameYieldsTransitionRaster") == "99999")){
    message(paste0('.....yield transition ids: ',P(sim, "dataLoaderCLUS", "nameYieldsTransitionRaster")))
    
    ras.ylds_trans<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                           srcRaster= P(sim, "dataLoaderCLUS", "nameYieldsTransitionRaster"), 
                           clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                           geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                           where_clause = paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL)
    if(aoi == extent(ras.ylds_trans)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.ylds_trans)))))
      setnames(pixels, "V1", "yieldid_trans")
      
      rm(ras.ylds_trans)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "dataLoaderCLUS", "nameYieldsTransitionRaster")))
    }
       #Check there is a table to link to
    if(P(sim, "dataLoaderCLUS", "nameYieldTransitionTable") == "99999"){
      stop(paste0("Specify the nameYieldTransitionTable =", P(sim, "dataLoaderCLUS", "nameYieldTransitionTable")))
    }
    
    yld.ids.trans<-paste( as.integer(unique(pixels[!is.na(yieldid_trans),"yieldid_trans"])$yieldid_trans), sep=" ", collapse = ", ")    
  
    #Set the yields table with yield curves that are only in the study area
    yields.trans<-getTableQuery(paste0("SELECT ycid, age, tvol, dec_pcnt, height, eca FROM ", P(sim)$nameYieldTransitionTable, " where ycid IN (", yld.ids.trans , ");"))
    
    
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "INSERT INTO yields (yieldid, age, tvol, dec_pcnt, height, eca) 
                      values (:ycid, :age, :tvol, :dec_pcnt, :height, :eca)", yields.trans)
    dbClearResult(rs)
    dbCommit(sim$clusdb)
    
    pixels[is.na(yieldid_trans) & !is.na(yieldid), yieldid_trans := yieldid] #assign the transition the same curve
    
  }else{
    message('.....yield trans ids: default 1')
    pixels[, yieldid_trans := 1]
  }
  
  #**************FOREST INVENTORY - VEGETATION VARIABLES*******************#
  
  if(!P(sim,"dataLoaderCLUS", "nameForestInventoryRaster") == '99999'){
    print("clipping inventory key")
    #dbExecute(sim$clusdb, paste0('ALTER TABLE pixels ADD COLUMN fid integer'))
    #fid<-c('fid,',':fid,') # used in the query to set the pixels table
    ras.fid<- RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                           srcRaster= P(sim, "dataLoaderCLUS", "nameForestInventoryRaster"), 
                           clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                           geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                           where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL)
    if(aoi == extent(ras.fid)){#need to check that each of the extents are the same
      inv_id<-data.table(c(t(raster::as.matrix(ras.fid))))
      setnames(inv_id, "V1", "fid")
      inv_id[, pixelid:= seq_len(.N)]
      inv_id[, fid:= as.integer(fid)] #make sure the fid is an integer for merging later on
      rm(ras.fid)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "dataLoaderCLUS", "nameForestInventoryRaster")))
    }
    
    if(!P(sim,"dataLoaderCLUS", "nameForestInventoryTable") == '99999'){
      #Get the forest inventory variables and re assign there names to be more generic than VEGCOMP
      forest_attributes_clusdb<-sapply(c("Treed","Age","Height", "CrownClosure", "SiteIndex"), function(x){
        if(!(P(sim, "dataLoaderCLUS", paste0("nameForestInventory", x)) == '99999')){
          return(paste0(P(sim, "dataLoaderCLUS", paste0("nameForestInventory", x)), " as ", tolower(x)))
        }else{
          stop(paste0("ERROR: Missing parameter nameForestInventory", x))
        }
      })
      
      #If there is a multi variable condition add them to the query
      queryMulti<-dbGetQuery(sim$clusdb, "SELECT distinct(variable) FROM zoneConstraints where multi_condition is not null or multi_condition <> 'NA' ")

      if(nrow(queryMulti) > 0){
        multiVars<-unlist(strsplit(paste(queryMulti$variable, collapse = ', ', sep = ','), ","))
        multiVars<-unique(gsub("[[:space:]]", "", multiVars))
        multiVars<-multiVars[!multiVars[] %in% c('proj_age_1', 'proj_height_1', 'crown_closure', 'site_index', 'blockid', 'age', 'height', 'siteindex', 'crownclosure', 'dist', 'bclcs_level_2')]
        if(!identical(character(0), multiVars)){
          multiVars1<-multiVars #used for altering pixels table in clusdb i.e., adding in the required information to run the query
          #Add the multivars to the pixels data table
          forest_attributes_clusdb<-c(forest_attributes_clusdb, multiVars)
          #format for pixels upload
          multiVars2<-multiVars
          multiVars2[1]<-paste0(', :',multiVars2[1])
          multiVars[1]<-paste0(', ',multiVars[1])
        }else{
          multiVars<-''
          multiVars2<-''
          multiVars1<-NULL
          }
        #Update the multi conditional constraints so the names match the dynamic variables
        dbExecute(sim$clusdb, "UPDATE zoneConstraints set multi_condition = replace(multi_condition, 'proj_age_1', 'age') where multi_condition is not null;")
        dbExecute(sim$clusdb, "UPDATE zoneConstraints set multi_condition = replace(multi_condition, 'proj_height_1', 'height') where multi_condition is not null;")
        dbExecute(sim$clusdb, "UPDATE zoneConstraints set multi_condition = replace(multi_condition, 'site_index', 'siteindex') where multi_condition is not null;")
        dbExecute(sim$clusdb, "UPDATE zoneConstraints set multi_condition = replace(multi_condition, 'crown_closure', 'crownclosure') where multi_condition is not null;")
          
        
        }else{
        multiVars<-''
        multiVars2<-''
        multiVars1<-NULL
      }
      #print(forest_attributes_clusdb )
      if(length(forest_attributes_clusdb) > 0){
        print(paste0("getting inventory attributes: ", paste(forest_attributes_clusdb, collapse = ",")))
        fids<-unique(inv_id[!(is.na(fid)), fid])
        attrib_inv<-data.table(getTableQuery(paste0("SELECT " , P(sim, "dataLoaderCLUS", "nameForestInventoryKey"), " as fid, ", paste(forest_attributes_clusdb, collapse = ","), " FROM ",
                                                    P(sim,"dataLoaderCLUS", "nameForestInventoryTable"), " WHERE ", P(sim, "dataLoaderCLUS", "nameForestInventoryKey") ," IN (",
                                                    paste(fids, collapse = ","),");" )))
        #Merge this with the raster using fid which gives you the primary key -- pixelid
        print("...merging with fid")
        inv<-merge(x=inv_id, y=attrib_inv, by.x = "fid", by.y = "fid", all.x = TRUE) 
        
        #Merge to pixels using the pixelid
        pixels<-merge(x = pixels, y =inv, by.x = "pixelid", by.y = "pixelid", all.x = TRUE)
        pixels<-pixels[, fid:=NULL]#remove the fid key
        
        #Change the VRI bclcs_level_2 to a binary.
        pixels<-pixels[!treed == 'T', treed:=0][treed == 'T', treed:=1]
        
        if(!is.null(multiVars1)){
          for(var in multiVars1){
            if(is.character(pixels[, eval(parse(text =var))])){
              dbExecute(sim$clusdb, paste0("ALTER TABLE pixels ADD COLUMN ", var, " text;"))
            }else{
              dbExecute(sim$clusdb, paste0("ALTER TABLE pixels ADD COLUMN ", var, " numeric;"))
            }
          }
        }
        rm(inv, attrib_inv,inv_id, fids)
      }else{
        stop("No forest attributes from the inventory specified")
      }
    } else { 
      stop(paste0('nameForestInventoryTable = ', P(sim,"dataLoaderCLUS", "nameForestInventoryTable")))
    }  
  } else{
    multiVars<-''
    multiVars2<-''
    multiVars1<-NULL
  }
  #-----------
  #Set the Treed 
  #----------- 
  
  if(!(P(sim, "dataLoaderCLUS", "nameTreedRaster") == "99999") & P(sim, "dataLoaderCLUS", "nameForestInventoryTreed") == "99999"){
    message(paste0('.....treed: ',P(sim, "dataLoaderCLUS", "nameTreedRaster")))
    ras.treed<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                          srcRaster= P(sim, "dataLoaderCLUS", "nameTreedRaster"), 
                          clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                          geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                          where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                          conn=NULL)
    if(aoi == extent(ras.treed)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.treed)))))
      setnames(pixels, "V1", "treed")
      rm(ras.treed)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "dataLoaderCLUS", "nameTreedRaster")))
    }
  }
  
  if(P(sim, "dataLoaderCLUS", "nameTreedRaster") == "99999" & P(sim, "dataLoaderCLUS", "nameForestInventoryTreed") == "99999"){
    message('.....treed: default 1')
    pixels[, treed := 1]
  }
  
  #-----------
  #Set the Age 
  #-----------
  if(!(P(sim, "dataLoaderCLUS", "nameAgeRaster") == "99999") & P(sim, "dataLoaderCLUS", "nameForestInventoryAge") == "99999"){
    message(paste0('.....age: ',P(sim, "dataLoaderCLUS", "nameAgeRaster")))
    ras.age<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                          srcRaster= P(sim, "dataLoaderCLUS", "nameAgeRaster"), 
                            clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                            geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                            where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                            conn=NULL)
    if(aoi == extent(ras.age)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.age)))))
      setnames(pixels, "V1", "age")
      rm(ras.age)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "dataLoaderCLUS", "nameAgeRaster")))
    }
  }
  
  if(P(sim, "dataLoaderCLUS", "nameAgeRaster") == "99999" & P(sim, "dataLoaderCLUS", "nameForestInventoryAge") == "99999"){
    message('.....age: default 120')
    pixels[, age := 120]
  }
  
  #---------------------
  #Set the Crown Closure 
  #---------------------
  if(!(P(sim, "dataLoaderCLUS", "nameCrownClosureRaster") == "99999") & P(sim, "dataLoaderCLUS", "nameForestInventoryCrownClosure") == "99999"){
    message(paste0('.....crownclosure: ',P(sim, "dataLoaderCLUS", "nameCrownClosureRaster")))
    ras.cc<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                         srcRaster=P(sim, "dataLoaderCLUS", "nameCrownClosureRaster"), 
                           clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                           geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                           where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL)
    if(aoi == extent(ras.cc)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.cc)))))
      setnames(pixels, "V1", "crownclosure")
      rm(ras.cc)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "dataLoaderCLUS", "nameCrownClosureRaster")))
    }
  }
  if(P(sim, "dataLoaderCLUS", "nameCrownClosureRaster") == "99999" & P(sim, "dataLoaderCLUS", "nameForestInventoryCrownClosure") == "99999"){
    message('.....crown closure: default 60')
    pixels[, crownclosure := 60]
  }
    
  #---------------------
  #Set the Height 
  #---------------------
  if(!(P(sim, "dataLoaderCLUS", "nameHeightRaster") == "99999") & P(sim, "dataLoaderCLUS", "nameForestInventoryHeight") == "99999"){
    message(paste0('.....height: ',P(sim, "dataLoaderCLUS", "nameHeightRaster")))
    ras.ht<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                         srcRaster=P(sim, "dataLoaderCLUS", "nameHeightRaster"), 
                           clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                           geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                           where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL)
    if(aoi == extent(ras.ht)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.ht)))))
      setnames(pixels, "V1", "height")
      rm(ras.ht)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "dataLoaderCLUS", "nameHeightRaster")))
    }
  }
  if(P(sim, "dataLoaderCLUS", "nameHeightRaster") == "99999" & P(sim, "dataLoaderCLUS", "nameForestInventoryHeight") == "99999"){
    message('.....height: default 10')
    pixels[, height := 10]
  }
  
  #---------------------
  #Set the Site Index 
  #---------------------
  if(!(P(sim, "dataLoaderCLUS", "nameSiteIndexRaster") == "99999") & P(sim, "dataLoaderCLUS", "nameForestInventorySiteIndex") == "99999"){
    message(paste0('.....siteindex: ',P(sim, "dataLoaderCLUS", "nameSiteIndexRaster")))
    ras.si<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                         srcRaster=P(sim, "dataLoaderCLUS", "nameSiteIndexRaster"), 
                         clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                         geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                         where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                         conn=NULL)
    if(aoi == extent(ras.si)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.si)))))
      setnames(pixels, "V1", "siteindex")
      rm(ras.si)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "dataLoaderCLUS", "nameSiteIndexRaster")))
    }
  }
  if(P(sim, "dataLoaderCLUS", "nameSiteIndexRaster") == "99999" & P(sim, "dataLoaderCLUS", "nameForestInventorySiteIndex") == "99999"){
    message('.....siteindex: default 14')
    pixels[, siteindex:= 14]
  }
  
  
  #*************************#
  #--------------------------
  #Load the pixels in RSQLite
  #--------------------------
  qry<-paste0('INSERT INTO pixels (pixelid, compartid, yieldid, yieldid_trans, own, thlb, treed, age, crownclosure, height, siteindex, roadyear, dec_pcnt, zone',
              paste(as.character(seq(1:sim$zone.length)), sep="' '", collapse=", zone"),
              paste(multiVars, sep="' '", collapse=", "),' ) 
               values (:pixelid, :compartid, :yieldid, :yieldid_trans, :own,  :thlb, :treed, :age, :crownclosure, :height, :siteindex, NULL, 0, :zone', 
              paste(as.character(seq(1:sim$zone.length)), sep="' '", collapse=", :zone"),
              paste(multiVars2, sep="' '", collapse=", :"),')')
  

  #pixels table
  dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, qry, pixels )
    dbClearResult(rs)
  dbCommit(sim$clusdb)
  
  rm(pixels)
  gc()
  return(invisible(sim))
}
setIndexesCLUSdb <- function(sim) {
  
  dbExecute(sim$clusdb, "CREATE UNIQUE INDEX index_pixelid on pixels (pixelid)")
  dbExecute(sim$clusdb, "CREATE INDEX index_age on pixels (age)")
  
  zones<-dbGetQuery(sim$clusdb, "SELECT zone_column FROM zone")
  for(i in 1:nrow(zones)){
    dbExecute(sim$clusdb, paste0("CREATE INDEX index_zone",i," on pixels (",zones[[1]][i],")"))
  }
  
  dbExecute(sim$clusdb, "VACUUM;")
  message('...done')
  return(invisible(sim))
}

#Archaic --keeping if needed at a later point in time
# setTHLB<-function(sim){
#   #For the zone constraints of type 'nh' set thlb to zero so that they are removed from harvesting -- yet they will still contribute to other zonal constraints
#   nhConstraints<-data.table(merge(dbGetQuery(sim$clusdb, paste0("SELECT  zoneid, reference_zone FROM zoneConstraints WHERE type ='nh'")),
#                                   dbGetQuery(sim$clusdb, "SELECT zone_column, reference_zone FROM zone"), 
#                                   by.x = "reference_zone", by.y = "reference_zone"))
#   if(nrow(nhConstraints) > 0 ){
#     nhConstraints[,qry:= paste( zone_column,'=',zoneid)]
#     dbExecute(sim$clusdb, paste0("UPDATE pixels SET thlb = 0 WHERE ", paste(nhConstraints$qry, collapse = " OR ")))
#   }
#   #thlb.ras<-sim$ras
#   #thlb.val<-dbGetQuery(sim$clusdb, "select thlb from pixels order by pixelid")
#   #thlb.ras[]<- thlb.val$thlb
#   #writeRaster(thlb.ras, "thlb.tif")
#   return(invisible(sim))
# }
setZoneConstraints<-function(sim){
  message("... setting ZoneConstraints table")
  # zone_constraint table
  if(!P(sim)$nameZoneTable == '99999'){
    zone<-dbGetQuery(sim$clusdb, "SELECT * FROM zone") # select the name of the raster and its column name in pixels
    zone_const<-rbindlist(lapply(split(zone, seq(nrow(zone))) , function(x){
      if(nrow(dbGetQuery(sim$clusdb, paste0("SELECT distinct(", x$zone_column,") from pixels where ", x$zone_column, " is not null")))>0){
        getTableQuery(paste0("SELECT * FROM ", P(sim)$nameZoneTable, " WHERE reference_zone = '", x$reference_zone,
                           "' AND zoneid IN(",paste(dbGetQuery(sim$clusdb, paste0("SELECT distinct(", x$zone_column,") as zoneid from pixels where ", x$zone_column, " is not null"))$zoneid, sep ="", collapse ="," ),");"))
      }
    }))
    
    zone_list<-merge(zone_const, zone, by.x = 'reference_zone',by.y = 'reference_zone')
    
    
    #Split into two sections: one for denom values, the other for default denom which is the total area of the zone
    zone_const_default<-zone_list[is.na(denom),]
    zone_const_denom<-zone_list[!is.na(denom),]
    
    #Get total area of the zone
    if(nrow(zone_const_default)>0){
      t_area_default<-rbindlist(lapply(unique(zone_const_default$zone_column), function (x){
        dbGetQuery(sim$clusdb, paste0("SELECT count() as t_area, ", x, " as zoneid, '", paste0(x), "' as zone_column from pixels where ", x, " is not null group by ", x)) 
      }))
    }else{
      t_area_default<-data.table( t_area=as.numeric(), zoneid=as.integer(),zone_column=as.character())
    }
    #Get total area where some inequality holds
    if(nrow(zone_const_denom)>0){
      t_area_denomt<-rbindlist(lapply(split(zone_const_denom, seq(nrow(zone_const_denom))), function (x){
        dbGetQuery(sim$clusdb, paste0("SELECT count() as t_area, ", x$zone_column, " as zoneid, '", paste0(x$zone_column), "' as zone_column from pixels where ", x$denom, " and ", x$zone_column, " = ", x$zoneid)) 
      })) 
    }else{
      t_area_denomt<-data.table( t_area=as.numeric(), zoneid=as.integer(),zone_column=as.character())
    }
    
    t_area<-rbindlist(list(t_area_denomt,t_area_default))
    zones<-merge(zone_list, t_area, by.x = c("zone_column", "zoneid"), by.y = c("zone_column", "zoneid"))
    
    #TODO:REMOVE THIS
    if(nrow(t_area_denomt) > 0){
      dbBegin(sim$clusdb)
      rs<-dbSendQuery(sim$clusdb, "INSERT INTO zoneConstraints (zoneid, reference_zone, zone_column, ndt, variable, threshold, type ,percentage, multi_condition, t_area, denom, start , stop ) 
                      values (:zoneid, :reference_zone, :zone_column, :ndt, :variable, :threshold, :type, :percentage, :multi_condition, :t_area, :denom, :start, :stop)", zones)
      dbClearResult(rs)
      dbCommit(sim$clusdb)
    }else{
        dbBegin(sim$clusdb)
        rs<-dbSendQuery(sim$clusdb, "INSERT INTO zoneConstraints (zoneid, reference_zone, zone_column, ndt, variable, threshold, type ,percentage, multi_condition, t_area, start, stop) 
                      values (:zoneid, :reference_zone, :zone_column, :ndt, :variable, :threshold, :type, :percentage, :multi_condition, :t_area, :start, :stop)", zones[,c('zoneid', 'zone_column', 'reference_zone', 'ndt','variable', 'threshold', 'type', 'percentage', 'multi_condition', 't_area', 'start', 'stop')])
        dbClearResult(rs)
        dbCommit(sim$clusdb)
      }
  }else{
    paste0(P(sim)$nameZoneTable, "...nameZoneTable not supplied. WARNING: your simulation has no zone constraints")
  }
  return(invisible(sim))
}
calcForestState<-function(sim){
sim$foreststate<- data.table(dbGetQuery(sim$clusdb, paste0("SELECT compartid as compartment, sum(case when compartid is not null then 1 else 0 end) as total, 
           sum(thlb) as thlb, sum(case when age <= 40 and age >= 0 then 1 else 0 end) as early,
           sum(case when age > 40 and age < 140 then 1 else 0 end) as mature,
           sum(case when age >= 140 then 1 else 0 end) as old,
           sum(case when roadyear >= -1  then 1 else 0 end) as road
           FROM pixels  where compartid 
              in('",paste(sim$boundaryInfo[[3]], sep = " ", collapse = "','"),"')
                         group by compartid;"))
            )

#test_roads<<-dbGetQuery(sim$clusdb, "select sum(case when roadyear >= -1  then 1 else 0 end) as road FROM pixels  where compartid is not null ")
  return(invisible(sim))
}

updateGS<- function(sim) {
  #Note: See the SQLite approach to updating. The Update statement does not support JOIN
  #update the yields being tracked
  message("...update yields")
  if(length(dbGetQuery(sim$clusdb, "SELECT variable FROM zoneConstraints WHERE variable = 'eca' LIMIT 1")) > 0){
    #tab1[, eca:= lapply(.SD, function(x) {approx(dat[yieldid == .BY]$age, dat[yieldid == .BY]$eca,  xout=x, rule = 2)$y}), .SD = "age" , by=yieldid]
    tab1<-data.table(dbGetQuery(sim$clusdb, "SELECT t.pixelid,
    (((k.tvol - y.tvol*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.tvol as vol,
    (((k.height - y.height*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.height as ht,
    (((k.eca - y.eca*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.eca as eca,
    (((k.dec_pcnt - y.dec_pcnt*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.dec_pcnt as dec_pcnt
    FROM pixels t
    LEFT JOIN yields y 
    ON t.yieldid = y.yieldid AND CAST(t.age/10 AS INT)*10 = y.age
    LEFT JOIN yields k 
    ON t.yieldid = k.yieldid AND round(t.age/10+0.5)*10 = k.age WHERE t.age > 0"))
    
    dbBegin(sim$clusdb)

    rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET vol = :vol, height = :ht, eca = :eca, dec_pcnt = :dec_pcnt where pixelid = :pixelid", tab1[,c("vol", "ht", "eca", "pixelid", "dec_pcnt")])
    dbClearResult(rs)
    dbCommit(sim$clusdb)
    
  }else{
    
    tab1<-data.table(dbGetQuery(sim$clusdb, "SELECT t.pixelid,
    (((k.tvol - y.tvol*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.tvol as vol,
    (((k.height - y.height*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.height as ht,
    (((k.dec_pcnt - y.dec_pcnt*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.dec_pcnt as dec_pcnt
    FROM pixels t
    LEFT JOIN yields y 
    ON t.yieldid = y.yieldid AND CAST(t.age/10 AS INT)*10 = y.age
    LEFT JOIN yields k 
    ON t.yieldid = k.yieldid AND round(t.age/10+0.5)*10 = k.age WHERE t.age > 0"))
    
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET vol = :vol, height = :ht, dec_pcnt = :dec_pcnt  where pixelid = :pixelid", tab1[,c("vol", "ht", "pixelid", "dec_pcnt")])
    dbClearResult(rs)
    dbCommit(sim$clusdb)  
  }
  
  message("...create indexes")
  dbExecute(sim$clusdb, "CREATE INDEX index_height on pixels (height)")
  rm(tab1)
  gc()
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  if(!suppliedElsewhere("updateZoneConstraints", sim)){
    sim$updateZoneConstraints<-NULL
  }
  return(invisible(sim))
}



