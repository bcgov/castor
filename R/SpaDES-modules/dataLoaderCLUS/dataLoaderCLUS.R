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

#===========================================================================================#
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
  reqdPkgs = list("sf", "rpostgis","DBI", "RSQLite", "data.table"),
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
    defineParameter("nameYieldsCurrentRaster", "character", "99999", NA, NA, desc = "Name of the raster with id's for yield tables"),
    defineParameter("nameYieldsTransitionRaster", "character", "99999", NA, NA, desc = "Name of the raster with id's for yield tables that transition to a new table"),
    defineParameter("nameYieldTable", "character", "99999", NA, NA, desc = "Name of the table documenting the yields"),
    defineParameter("nameYieldCurrentTable", "character", "99999", NA, NA, desc = "Name of the table documenting the yields"),
    defineParameter("nameYieldTransitionTable", "character", "99999", NA, NA, desc = "Name of the table documenting the yields that transition"),
    defineParameter("nameOwnershipRaster", "character", "99999", NA, NA, desc = "Name of the raster from GENERALIZED FOREST OWNERSHIP"),
    defineParameter("nameForestInventoryTable", "character", "99999", NA, NA, desc = "Name of the veg comp table - the forest inventory"),
    defineParameter("nameForestInventoryRaster", "character", "99999", NA, NA, desc = "Name of the veg comp - the forest inventory raster of the primary key"),
    defineParameter("nameForestInventoryKey", "character", "99999", NA, NA, desc = "Name of the veg comp primary key that links the table to the raster"),
    defineParameter("nameForestInventoryAge", "character", "99999", NA, NA, desc = "Name of the veg comp age"),
    defineParameter("nameForestInventoryHeight", "character", "99999", NA, NA, desc = "Name of the veg comp height"),
    defineParameter("nameForestInventoryCrownClosure", "character", "99999", NA, NA, desc = "Name of the veg comp crown closure"),
    defineParameter("nameForestInventoryTreed", "character", "99999", NA, NA, desc = "Name of the veg treed layer"),
    defineParameter("nameForestInventoryQMD", "character", "99999", NA, NA, desc = "Name of the veg qmd layer"),
    defineParameter("nameForestInventoryBasalArea", "character", "99999", NA, NA, desc = "Name of the veg basal area layer"),
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
      sim$boundaryInfo <- list(P(sim,"nameBoundaryFile", "dataLoaderCLUS" ),P(sim,"nameBoundaryColumn","dataLoaderCLUS"),P(sim, "nameBoundary", "dataLoaderCLUS"), P(sim, "nameBoundaryGeom", "dataLoaderCLUS")) # list of boundary parameters to set the extent of where the model will be run; these parameters are expected inputs in dataLoader 
      sim$zone.length<-length(P(sim, "nameZoneRasters", "dataLoaderCLUS")) # used to define the number of different management constraint zones
      
      if(P(sim, "useCLUSdb", "dataLoaderCLUS") == "99999"){
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
        message(paste0("Loading existing db...", P(sim, "useCLUSdb", "dataLoaderCLUS")))
        #Make a copy of the db here so that the clusdb is in memory
        userdb <- dbConnect(RSQLite::SQLite(), dbname = P(sim, "useCLUSdb", "dataLoaderCLUS") ) # connext to pgdb
        sim$clusdb <- dbConnect(RSQLite::SQLite(), ":memory:") # save the pgdb in memory (object in sim)
        RSQLite::sqliteCopyDatabase(userdb, sim$clusdb)
        dbDisconnect(userdb)
        
        dbExecute(sim$clusdb, "PRAGMA synchronous = OFF") # update the database
        dbExecute(sim$clusdb, "PRAGMA journal_mode = OFF")
        
        ras.info<-dbGetQuery(sim$clusdb, "select * from raster_info where name = 'ras'") #Get the raster information
        sim$ras<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =1:ras.info$ncell)
        raster::crs(sim$ras)<-paste0("EPSG:", ras.info$crs)
        
        sim$pts <- data.table(xyFromCell(sim$ras,1:length(sim$ras))) # creates pts at centroids of raster boundary file; seems to be faster that rasterTopoints
        sim$pts <- sim$pts[, pixelid:= seq_len(.N)] #add in the pixelid which streams data in according to the cell number = pixelid
        
        #Get the available zones for other modules to query -- In forestryCLUS the zones that are not part of the scenario get deleted.
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
    con<-dbConnect(RSQLite::SQLite(), paste0(P(sim, 'sqlite_dbname', 'dataLoaderCLUS'), "_clusdb.sqlite"))
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
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS yields ( id integer PRIMARY KEY, yieldid integer, age integer, tvol numeric, dec_pcnt numeric, height numeric, qmd numeric default 0.0, basalarea numeric default 0.0, crownclosure numeric default 0.0, eca numeric)")
  #Note Zone table is created as a JOIN with zoneConstraints and zone
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS raster_info (name text, xmin numeric, xmax numeric, ymin numeric, ymax numeric, ncell integer, nrow integer, crs text)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS zone (zone_column text, reference_zone text)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS zoneConstraints ( id integer PRIMARY KEY, zoneid integer, reference_zone text, zone_column text, ndt integer, variable text, threshold numeric, type text, percentage numeric, denom text, multi_condition text, t_area numeric, start integer, stop integer)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS pixels ( pixelid integer PRIMARY KEY, compartid character, 
own integer, yieldid integer, yieldid_trans integer, zone_const integer DEFAULT 0, treed integer, thlb numeric , elv numeric DEFAULT 0, age numeric, vol numeric, dist numeric DEFAULT 0,
crownclosure numeric, height numeric, basalarea numeric, qmd numeric, siteindex numeric, dec_pcnt numeric, eca numeric, salvage_vol numeric default 0)")
  return(invisible(sim))
}

setTablesCLUSdb <- function(sim) {
  message('...setting data tables')
  ###------------------------#
  #Set the compartment IDs----
  ###------------------------#
  if(!(P(sim, "nameCompartmentRaster", "dataLoaderCLUS") == "99999")){
    message(paste0('.....compartment ids: ', P(sim, "nameCompartmentRaster", "dataLoaderCLUS")))
    sim$ras<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                          srcRaster= P(sim, "nameCompartmentRaster", "dataLoaderCLUS"), 
                          clipper=sim$boundaryInfo[[1]], 
                          geom= sim$boundaryInfo[[4]], 
                          where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                          conn=NULL)

    sim$pts <- data.table(xyFromCell(sim$ras,1:length(sim$ras))) #Seems to be faster than rasterTopoints
    sim$pts <- sim$pts[, pixelid:= seq_len(.N)] # add in the pixelid which streams data in according to the cell number = pixelid
    
    pixels <- data.table(V1 = sim$ras[])
    pixels[, pixelid := seq_len(.N)]
    
    #Set V1 to merge in the vat table values so that the column is character
    if(!(P(sim, "nameCompartmentTable", "dataLoaderCLUS") == "99999")){
      compart_vat <- data.table(getTableQuery(paste0("SELECT * FROM ", P(sim, "nameCompartmentTable", "dataLoaderCLUS"))))
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
    #sim$rasVelo<-velox::velox(sim$ras)
    
    #Add the raster_info
    ras.extent<-extent(sim$ras)
    dbExecute(sim$clusdb, glue::glue("INSERT INTO raster_info (name, xmin, xmax, ymin, ymax, ncell, nrow, crs) values ('ras', {ras.extent[1]}, {ras.extent[2]}, {ras.extent[3]}, {ras.extent[4]}, {ncell(sim$ras)}, {nrow(sim$ras)}, '3005')"))
    
  }else{
    message('.....compartment ids: default 1')
    #Set the empty table for values not supplied in the parameters
    sim$ras<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                          srcRaster= 'rast.bc_bound', 
                          clipper=sim$boundaryInfo[[1]], 
                          geom= sim$boundaryInfo[[4]], 
                          where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                          conn=NULL)
    
    sim$pts <-data.table(xyFromCell(sim$ras,1:length(sim$ras))) #Seems to be faster that rasterTopoints
    sim$pts<- sim$pts[, pixelid:= seq_len(.N)] #add in the pixelid which streams data in according to the cell number = pixelid
    
    pixels<-data.table(pixelid=sim$ras[]) #transpose then vectorize which matches the same order as adj
    pixels[, pixelid := seq_len(.N)]
    pixels[, compartid := 'all']
    
    sim$ras[]<-pixels$pixelid
    #sim$rasVelo<-velox::velox(sim$ras)
    
  }
  
  aoi<-extent(sim$ras)#need to check that each of the extents are the same
  
  #--------------------#
  #Set the Ownership----
  #--------------------#
  if(!(P(sim, "nameOwnershipRaster", "dataLoaderCLUS") == "99999")){
    message(paste0('.....ownership: ',P(sim, "nameOwnershipRaster", "dataLoaderCLUS")))
    ras.own<- RASTER_CLIP2(tmpRast =paste0('temp_', sample(1:10000, 1)), 
                           srcRaster= P(sim, "nameOwnershipRaster", "dataLoaderCLUS"), 
                           clipper=sim$boundaryInfo[[1]], 
                           geom= sim$boundaryInfo[[4]], 
                           where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL)
    
    if(aoi == extent(ras.own)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(own = ras.own[]))
      rm(ras.own)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "dataLoaderCLUS", "nameOwnershipRaster")))
    }
  }else{
    message('.....ownership: default 1')
    pixels[, own := 1]
  }
  
  #-------------------#
  #Set the zone IDs----
  #-------------------#
  if(!(P(sim, "nameZoneRasters", "dataLoaderCLUS")[1] == "99999")){
    message(paste0('.....zones: ',P(sim, "nameZoneRasters", "dataLoaderCLUS")))
    zones_aoi<-data.table(zoneid='', zone_column='')
    #Add multiple zone columns - each will have its own raster. Attributed to that raster is a table of the thresholds by zone
    for(i in 1:sim$zone.length){
      ras.zone<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                             srcRaster= P(sim, "nameZoneRasters", "dataLoaderCLUS")[i], 
                             clipper=sim$boundaryInfo[[1]], 
                             geom= sim$boundaryInfo[[4]], 
                             where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                             conn=NULL)
      if(aoi == extent(ras.zone)){#need to check that each of the extents are the same
        pixels<-cbind(pixels, data.table(V1 = ras.zone[]))
        setnames(pixels, "V1", paste0('zone',i))#SET zone NAMES to RASTER layer
        dbExecute(sim$clusdb, glue::glue("ALTER TABLE pixels ADD COLUMN zone{i} numeric")) # add the zone id column and populate it with the zone names
        ref_zone <- P(sim, "nameZoneRasters", "dataLoaderCLUS")[i]
        dbExecute(sim$clusdb, glue::glue("INSERT INTO zone (zone_column, reference_zone) values ( 'zone{i}', '{ref_zone}')" ))
        # message(head(zones_aoi))
        rm(ras.zone, ref_zone)
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
    dbExecute(sim$clusdb, "INSERT INTO zone (zone_column, reference_zone) values ( 'zone1', 'default')" )
  }
  #-----------------------------#
  #Set the zonePriorityRaster----
  #-----------------------------#
  if(!P(sim)$nameZonePriorityRaster == '99999'){
    nameZonePriorityRaster<-P(sim, "dataLoaderCLUS", "nameZonePriorityRaster")
    #Check to see if the name of the zone priority raster is already in the zone table
    if(!nameZonePriorityRaster %in% dbGetQuery(sim$clusdb, "SELECT reference_zone from zone")$reference_zone){
      message(paste0('.....zone priority raster not in zones table...fetching: ',nameZonePriorityRaster))
      ras.zone.priority<- RASTER_CLIP2(tmpRast =paste0('temp_', sample(1:10000, 1)), 
                             srcRaster= nameZonePriorityRaster, 
                             clipper=sim$boundaryInfo[[1]], 
                             geom= sim$boundaryInfo[[4]], 
                             where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                             conn=NULL)
      if(aoi == extent(ras.zone.priority)){#need to check that each of the extents are the same
        pixels<-cbind(pixels, data.table(V1=ras.zone.priority[]))
        zone.priority<-paste0("zone", as.character(nrow(dbGetQuery(sim$clusdb, "SELECT * FROM zone")) + 1))
        setnames(pixels, "V1", zone.priority)
        #Add the zone priority column to the zone table
        dbExecute(sim$clusdb, glue::glue("INSERT INTO zone (zone_column, reference_zone) values ('{zone.priority}', '{nameZonePriorityRaster}')"))
        #Add the column name to pixels
        dbExecute(sim$clusdb, glue::glue("ALTER TABLE pixels ADD COLUMN {zone.priority} integer"))
        #Add to the zone.length needed when inserting the pixels table
        sim$zone.length<-sim$zone.length + 1
        rm(ras.zone.priority,zone.priority)
        gc()
      }else{
        stop(paste0("ERROR: extents are not the same check -", P(sim, "dataLoaderCLUS", "nameZonePriorityRaster")))
      }
    }
  }
  
  #---------------#
  #Set the THLB----
  #---------------#
  if(!(P(sim, "nameMaskHarvestLandbaseRaster", "dataLoaderCLUS") == "99999")){
    message(paste0('.....thlb: ',P(sim, "nameMaskHarvestLandbaseRaster", "dataLoaderCLUS")))
    ras.thlb<- RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                            srcRaster= P(sim, "nameMaskHarvestLandbaseRaster", "dataLoaderCLUS"), 
                            clipper=sim$boundaryInfo[[1]], 
                            geom= sim$boundaryInfo[[4]], 
                            where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                            conn=NULL)
    if(aoi == extent(ras.thlb)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(thlb=ras.thlb[]))
      rm(ras.thlb)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameMaskHarvestLandbaseRaster", "dataLoaderCLUS")))
    }
    
  }else{
    message('.....thlb: default 1')
    pixels[, thlb := 1]
  }
  
  
  #--------------------#
  #Set the yield IDs----
  #--------------------#
  if(!(P(sim, "nameYieldsRaster", "dataLoaderCLUS") == "99999")){
    message(paste0('.....yield ids: ',P(sim, "nameYieldsRaster", "dataLoaderCLUS")))
    ras.ylds<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                           srcRaster= P(sim, "nameYieldsRaster", "dataLoaderCLUS"), 
                           clipper=sim$boundaryInfo[[1]], 
                           geom= sim$boundaryInfo[[4]], 
                           where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL)
    if(aoi == extent(ras.ylds)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(yieldid=ras.ylds[]))
      rm(ras.ylds)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameYieldsRaster", "dataLoaderCLUS")))
    }
    
    #Check there is a table to link to
    if(P(sim, "nameYieldTable", "dataLoaderCLUS") == "99999"){
      stop(paste0("Specify the nameYieldTable =", P(sim, "nameYieldTable", "dataLoaderCLUS")))
    }
    
    yld.ids<-paste( unique(pixels[!is.na(yieldid),"yieldid"])$yieldid, sep=" ", collapse = ", ")
    
    #Check to see what yields are available
    testColumnNames<-getTableQuery(glue::glue("SELECT * FROM {P(sim)$nameYieldTable} LIMIT 1"))
    colNames<- names(testColumnNames)[names(testColumnNames) %in% c("ycid", "age", "tvol", "dec_pcnt", "height", "eca", "basalarea", "qmd", "crownclosure")]
    colNamesYieldid <-colNames
    colNamesYieldid[1]<-"yieldid"
      
    #Set the yields table with yield curves that are only in the study area
    #yields<-getTableQuery(paste0("SELECT ",paste(colNames, collapse = ", ", sep = " ")," FROM ", P(sim)$nameYieldTable, " where ycid IN (", yld.ids , ");"))
    yields<-getTableQuery(glue::glue("SELECT ", glue::glue_collapse(colNames, sep = ", ")," FROM {P(sim)$nameYieldTable} where ycid IN ({yld.ids});"))
    
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, glue::glue("INSERT INTO yields (",glue::glue_collapse(colNamesYieldid, sep = ", "),") 
                      values (:",glue::glue_collapse(colNames, sep = ", :"),");"), yields)
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
  
  #Set the current yield IDs-----#
  #------------------------------#
  if(!(P(sim, "nameYieldsCurrentRaster", "dataLoaderCLUS") == "99999")){
    message(paste0('.....yield ids: ',P(sim, "nameYieldsCurrentRaster", "dataLoaderCLUS")))
    ras.ylds.current<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                           srcRaster= P(sim, "nameYieldsCurrentRaster", "dataLoaderCLUS"), 
                           clipper=sim$boundaryInfo[[1]], 
                           geom= sim$boundaryInfo[[4]], 
                           where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL)
    if(aoi == extent(ras.ylds.current)){#need to check that each of the extents are the same
      updateToCurrent<-data.table(yieldid=ras.ylds.current[])
      
      pixels[, current_yieldid := updateToCurrent$yieldid]
      pixels<-pixels[current_yieldid > 0, yieldid := current_yieldid]
      pixels$current_yieldid <- NULL
      rm(ras.ylds.current)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameYieldsCurrentRaster", "dataLoaderCLUS")))
    }
    
    #Check there is a table to link to
    if(P(sim, "nameYieldCurrentTable", "dataLoaderCLUS") == "99999"){
      stop(paste0("Specify the nameYieldCurrentTable =", P(sim, "nameYieldCurrentTable", "dataLoaderCLUS")))
    }
    
    yld.ids.current<-paste( unique(updateToCurrent[!is.na(yieldid),]$yieldid), sep=" ", collapse = ", ")
    
    #Check to see what yields are available
    testColumnNames<-getTableQuery(paste0("SELECT * FROM ",P(sim)$nameYieldCurrentTable , " LIMIT 1"))
    colNames<- names(testColumnNames)[names(testColumnNames) %in% c("ycid", "age", "tvol", "dec_pcnt", "height", "eca", "basalarea", "qmd", "crownclosure")]
    colNamesYieldid <-colNames
    colNamesYieldid[1]<-"yieldid"
    
    #Set the yields table with yield curves that are only in the study area
    yields.current<-getTableQuery(paste0("SELECT ",paste(colNames, collapse = ", ", sep = " ")," FROM ", P(sim)$nameYieldCurrentTable , " where ycid IN (", yld.ids.current , ");"))
    
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, glue::glue("INSERT INTO yields (",glue::glue_collapse(colNamesYieldid, sep = ", "),") 
                      values (:",glue::glue_collapse(colNames, sep = ", :"),");"), yields.current)
    dbClearResult(rs)
    dbCommit(sim$clusdb)
    
  }
  
  #----------------------------#
  #---Set transition yields ----
  #----------------------------#
  if(!(P(sim, "nameYieldsTransitionRaster", "dataLoaderCLUS") == "99999")){
    message(paste0('.....yield transition ids: ',P(sim, "nameYieldsTransitionRaster", "dataLoaderCLUS")))
    
    ras.ylds_trans<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                           srcRaster= P(sim, "nameYieldsTransitionRaster", "dataLoaderCLUS"), 
                           clipper=sim$boundaryInfo[[1]], 
                           geom= sim$boundaryInfo[[4]], 
                           where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL)
    if(aoi == extent(ras.ylds_trans)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(yieldid_trans= ras.ylds_trans[]))
      rm(ras.ylds_trans)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameYieldsTransitionRaster", "dataLoaderCLUS")))
    }
       #Check there is a table to link to
    if(P(sim, "nameYieldTransitionTable", "dataLoaderCLUS") == "99999"){
      stop(paste0("Specify the nameYieldTransitionTable =", P(sim, "nameYieldTransitionTable", "dataLoaderCLUS")))
    }
    
    yld.ids.trans<-paste( as.integer(unique(pixels[!is.na(yieldid_trans),"yieldid_trans"])$yieldid_trans), sep=" ", collapse = ", ")    
  
    #Check to see what yields are available
    testColumnNames<-getTableQuery(paste0("SELECT * FROM ",P(sim)$nameYieldTransitionTable, " LIMIT 1"))
    colNames<- names(testColumnNames)[names(testColumnNames) %in% c("ycid", "age", "tvol", "dec_pcnt", "height", "eca", "basalarea", "qmd", "crownclosure")]
    colNamesYieldid <-colNames
    colNamesYieldid[1]<-"yieldid"
    
    #Set the yields table with yield curves that are only in the study area
    yields.trans<-getTableQuery(paste0("SELECT ", paste(colNames, collapse = ", ", sep = " ")," FROM ", P(sim)$nameYieldTransitionTable, " where ycid IN (", yld.ids.trans , ");"))
    
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, glue::glue("INSERT INTO yields (",glue::glue_collapse(colNamesYieldid, sep = ", "),") 
                      values (:",glue::glue_collapse(colNames, sep = ", :"),");"), yields.trans)
    dbClearResult(rs)
    dbCommit(sim$clusdb)
    
    pixels[is.na(yieldid_trans) & !is.na(yieldid), yieldid_trans := yieldid] #assign the transition the same curve
    
  }else{
    message('.....yield trans ids: default 1')
    pixels[, yieldid_trans := 1]
  }
  
  #**************FOREST INVENTORY - VEGETATION VARIABLES*******************#
  #----------------------------#
  #----Set forest attributes----
  #----------------------------#
  if(!P(sim, "nameForestInventoryRaster","dataLoaderCLUS") == '99999'){
    print("clipping inventory key")
    #dbExecute(sim$clusdb, paste0('ALTER TABLE pixels ADD COLUMN fid integer'))
    #fid<-c('fid,',':fid,') # used in the query to set the pixels table
    ras.fid<- RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                           srcRaster= P(sim, "nameForestInventoryRaster", "dataLoaderCLUS"), 
                           clipper=sim$boundaryInfo[[1]], 
                           geom= sim$boundaryInfo[[4]], 
                           where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL)
    if(aoi == extent(ras.fid)){#need to check that each of the extents are the same
      inv_id<-data.table(fid = ras.fid[])
      inv_id[, pixelid:= seq_len(.N)]
      inv_id[, fid:= as.integer(fid)] #make sure the fid is an integer for merging later on
      rm(ras.fid)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameForestInventoryRaster", "dataLoaderCLUS")))
    }
    
    if(!P(sim, "nameForestInventoryTable","dataLoaderCLUS") == '99999'){
      #Get the forest inventory variables and re assign there names to be more generic than VEGCOMP
      forest_attributes_clusdb<-sapply(c("Treed","Age","Height", "CrownClosure", "SiteIndex", "QMD", "BasalArea"), function(x){
        if(!(P(sim, paste0("nameForestInventory", x), "dataLoaderCLUS") == '99999')){
          return(paste0(P(sim, paste0("nameForestInventory", x), "dataLoaderCLUS"), " as ", tolower(x)))
        }else{
          message(paste0("WARNING: Missing parameter nameForestInventory", x, " ---Defaulting to NA"))
          #pixels<-pixels[, eval(tolower(x)):= NA]
        }
      })
      #remove any nulls
      forest_attributes_clusdb<-Filter(Negate(is.null), forest_attributes_clusdb)
      #If there is a multi variable condition add them to the query
      queryMulti<-dbGetQuery(sim$clusdb, "SELECT distinct(variable) FROM zoneConstraints where multi_condition is not null or multi_condition <> 'NA' ")

      if(nrow(queryMulti) > 0){
        multiVars<-unlist(strsplit(paste(queryMulti$variable, collapse = ', ', sep = ','), ","))
        multiVars<-unique(gsub("[[:space:]]", "", multiVars))
        multiVars<-multiVars[!multiVars[] %in% c('proj_age_1', 'proj_height_1', 'crown_closure', 'site_index', 'blockid', 'age', 'height', 'siteindex', 'crownclosure', 'dist', 'bclcs_level_2', "basal_area", "quad_diam_125")]
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
        dbExecute(sim$clusdb, "UPDATE zoneConstraints set multi_condition = replace(multi_condition, 'basal_area', 'basalarea') where multi_condition is not null;")
        dbExecute(sim$clusdb, "UPDATE zoneConstraints set multi_condition = replace(multi_condition, 'quad_diam_125', 'qmd') where multi_condition is not null;")
        
        
        }else{
        multiVars<-''
        multiVars2<-''
        multiVars1<-NULL
      }
      #print(forest_attributes_clusdb )
      if(length(forest_attributes_clusdb) > 0){
        print(paste0("getting inventory attributes: ", paste(forest_attributes_clusdb, collapse = ",")))
        fids<-unique(inv_id[!(is.na(fid)), fid])
        attrib_inv<-data.table(getTableQuery(paste0("SELECT " , P(sim, "nameForestInventoryKey", "dataLoaderCLUS"), " as fid, ", paste(forest_attributes_clusdb, collapse = ","), " FROM ",
                                                    P(sim, "nameForestInventoryTable","dataLoaderCLUS"), " WHERE ", P(sim, "nameForestInventoryKey", "dataLoaderCLUS") ," IN (",
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
              dbExecute(sim$clusdb, glue::glue("ALTER TABLE pixels ADD COLUMN {var} text;"))
            }else{
              dbExecute(sim$clusdb, glue::glue("ALTER TABLE pixels ADD COLUMN {var} numeric;"))
            }
          }
        }
        rm(inv, attrib_inv,inv_id, fids)
      }else{
        stop("No forest attributes from the inventory specified")
      }
    } else { 
      stop(paste0('nameForestInventoryTable = ', P(sim, "nameForestInventoryTable","dataLoaderCLUS")))
    }  
  } else{
    multiVars<-''
    multiVars2<-''
    multiVars1<-NULL
  }
  
  #----------------#
  #Set the Treed----
  #----------------#
  if(!(P(sim, "nameTreedRaster", "dataLoaderCLUS") == "99999") & P(sim, "nameForestInventoryTreed", "dataLoaderCLUS") == "99999"){
    message(paste0('.....treed: ',P(sim, "nameTreedRaster", "dataLoaderCLUS")))
    ras.treed<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                          srcRaster= P(sim, "nameTreedRaster", "dataLoaderCLUS"), 
                          clipper=sim$boundaryInfo[[1]], 
                          geom= sim$boundaryInfo[[4]], 
                          where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                          conn=NULL)
    if(aoi == extent(ras.treed)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(treed=ras.treed[]))
      rm(ras.treed)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameTreedRaster", "dataLoaderCLUS")))
    }
  }
  
  if(P(sim, "nameTreedRaster", "dataLoaderCLUS") == "99999" & P(sim, "nameForestInventoryTreed", "dataLoaderCLUS") == "99999"){
    message('.....treed: default 1')
    pixels[, treed := 1]
  }
  
  #---------------#
  #Set the Age----- 
  #---------------#
  if(!(P(sim, "nameAgeRaster", "dataLoaderCLUS") == "99999") & P(sim, "nameForestInventoryAge", "dataLoaderCLUS") == "99999"){
    message(paste0('.....age: ',P(sim, "nameAgeRaster", "dataLoaderCLUS")))
    ras.age<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                          srcRaster= P(sim, "nameAgeRaster", "dataLoaderCLUS"), 
                          clipper=sim$boundaryInfo[[1]], 
                          geom= sim$boundaryInfo[[4]], 
                          where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                          conn=NULL)
    if(aoi == extent(ras.age)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(age=ras.age[]))
      setnames(pixels, "V1", "age")
      rm(ras.age)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameAgeRaster", "dataLoaderCLUS")))
    }
  }
  
  if(P(sim, "nameAgeRaster", "dataLoaderCLUS") == "99999" & P(sim, "nameForestInventoryAge", "dataLoaderCLUS") == "99999"){
    message('.....age: default 120')
    pixels[, age := 120]
  }
  
  #-------------------------#
  #Set the Crown Closure-----  
  #-------------------------#
  if(!(P(sim, "nameCrownClosureRaster", "dataLoaderCLUS") == "99999") & P(sim, "nameForestInventoryCrownClosure", "dataLoaderCLUS") == "99999"){
    message(paste0('.....crownclosure: ',P(sim, "nameCrownClosureRaster", "dataLoaderCLUS")))
    ras.cc<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                         srcRaster=P(sim, "nameCrownClosureRaster", "dataLoaderCLUS"), 
                         clipper=sim$boundaryInfo[[1]], 
                         geom= sim$boundaryInfo[[4]], 
                         where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                         conn=NULL)
    if(aoi == extent(ras.cc)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(crownclosure=ras.cc[]))
      rm(ras.cc)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameCrownClosureRaster", "dataLoaderCLUS")))
    }
  }
  if(P(sim, "nameCrownClosureRaster", "dataLoaderCLUS") == "99999" & P(sim, "nameForestInventoryCrownClosure", "dataLoaderCLUS") == "99999"){
    message('.....crown closure: default 60')
    pixels[, crownclosure := 60]
  }
    
  #-----------------#
  #Set the Height---- 
  #-----------------#
  if(!(P(sim, "nameHeightRaster", "dataLoaderCLUS") == "99999") & P(sim, "nameForestInventoryHeight", "dataLoaderCLUS") == "99999"){
    message(paste0('.....height: ',P(sim, "nameHeightRaster", "dataLoaderCLUS")))
    ras.ht<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                         srcRaster=P(sim, "nameHeightRaster", "dataLoaderCLUS"), 
                         clipper=sim$boundaryInfo[[1]], 
                         geom= sim$boundaryInfo[[4]], 
                         where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                         conn=NULL)
    if(aoi == extent(ras.ht)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(height=ras.ht[]))
      rm(ras.ht)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameHeightRaster", "dataLoaderCLUS")))
    }
  }
  if(P(sim, "nameHeightRaster", "dataLoaderCLUS") == "99999" & P(sim, "nameForestInventoryHeight", "dataLoaderCLUS") == "99999"){
    message('.....height: default 10')
    pixels[, height := 10]
  }
  
  #---------------------#
  #Set the Site Index----
  #---------------------#
  if(!(P(sim, "nameSiteIndexRaster", "dataLoaderCLUS") == "99999") & P(sim, "nameForestInventorySiteIndex", "dataLoaderCLUS") == "99999"){
    message(paste0('.....siteindex: ',P(sim, "nameSiteIndexRaster", "dataLoaderCLUS")))
    ras.si<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                         srcRaster=P(sim, "nameSiteIndexRaster", "dataLoaderCLUS"), 
                         clipper=sim$boundaryInfo[[1]], 
                         geom= sim$boundaryInfo[[4]], 
                         where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                         conn=NULL)
    if(aoi == extent(ras.si)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(siteindex= ras.si[]))
      rm(ras.si)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameSiteIndexRaster", "dataLoaderCLUS")))
    }
  }
  if(P(sim, "nameSiteIndexRaster", "dataLoaderCLUS") == "99999" & P(sim, "nameForestInventorySiteIndex", "dataLoaderCLUS") == "99999"){
    message('.....siteindex: default 14')
    pixels[, siteindex:= 14]
  }
  
  #----------------#
  #Set the BasalArea----
  #----------------#
  if(P(sim, "nameForestInventoryBasalArea", "dataLoaderCLUS") == "99999"){
    pixels[, basalarea := NA]
  }
  
  #----------------#
  #Set the QMD----
  #----------------#
  if(P(sim, "nameForestInventoryQMD", "dataLoaderCLUS") == "99999"){
    pixels[, qmd := NA]
  }
  
  #-----------------------------#
  #Load the pixels in RSQLite----
  #-----------------------------#
  qry<-paste0('INSERT INTO pixels (pixelid, compartid, yieldid, yieldid_trans, own, thlb, treed, age, crownclosure, height, siteindex, basalarea, qmd, dec_pcnt, zone',
              paste(as.character(seq(1:sim$zone.length)), sep="' '", collapse=", zone"),
              paste(multiVars, sep="' '", collapse=", "),' ) 
               values (:pixelid, :compartid, :yieldid, :yieldid_trans, :own,  :thlb, :treed, :age, :crownclosure, :height, :siteindex, :basalarea, :qmd, 0, :zone', 
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
    dbExecute(sim$clusdb, glue::glue("CREATE INDEX index_zone{i} on pixels ({zones[[1]][i]})"))
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
      if(nrow(dbGetQuery(sim$clusdb, glue::glue("SELECT distinct({x$zone_column}) from pixels where {x$zone_column} is not null")))>0){
        getTableQuery(glue::glue("SELECT * FROM {P(sim)$nameZoneTable} WHERE reference_zone = '{x$reference_zone}' AND zoneid IN(",paste(dbGetQuery(sim$clusdb,glue::glue("SELECT distinct({x$zone_column}) as zoneid from pixels where {x$zone_column} is not null"))$zoneid, sep ="", collapse ="," ),");"))
      }
    }))
    
    zone_list<-merge(zone_const, zone, by.x = 'reference_zone',by.y = 'reference_zone')
    
    
    #Split into two sections: one for denom values, the other for default denom which is the total area of the zone
    zone_const_default<-zone_list[is.na(denom),]
    zone_const_denom<-zone_list[!is.na(denom),]
    
    #Get total area of the zone
    if(nrow(zone_const_default)>0){
      t_area_default<-rbindlist(lapply(unique(zone_const_default$zone_column), function (x){
        dbGetQuery(sim$clusdb, glue::glue("SELECT count() as t_area, {x} as zoneid, '{x}' as zone_column from pixels where {x} is not null group by {x}")) 
      }))
    }else{
      t_area_default<-data.table( t_area=as.numeric(), zoneid=as.integer(),zone_column=as.character())
    }
    #Get total area where some inequality holds
    if(nrow(zone_const_denom)>0){
      t_area_denomt<-rbindlist(lapply(split(zone_const_denom, seq(nrow(zone_const_denom))), function (x){
        dbGetQuery(sim$clusdb, glue::glue("SELECT count() as t_area, {x$zone_column} as zoneid, '{x$zone_column}' as zone_column from pixels where {x$denom} and {x$zone_column}= {x$zoneid};")) 
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
           sum(case when age >= 140 then 1 else 0 end) as old
           FROM pixels  where compartid 
              in('",paste(sim$boundaryInfo[[3]], sep = " ", collapse = "','"),"')
                         group by compartid;"))
            )

  if(dbGetQuery(sim$clusdb, "SELECT COUNT(*) as exists_check FROM pragma_table_info('pixels') WHERE name='roadyear';")$exists_check == 0){
    sim$foreststate[,road:=0]
  }else{
    sim$foreststate[,road:= dbGetQuery(sim$clusdb,"select count() as road from pixels where roadyear = 0")$road]
  }
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
    (((k.dec_pcnt - y.dec_pcnt*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.dec_pcnt as dec_pcnt,
    (((k.crownclosure - y.crownclosure*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.crownclosure as crownclosure,
    (((k.basalarea - y.basalarea*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.basalarea as basalarea,
    (((k.qmd - y.qmd*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.qmd as qmd
    FROM pixels t
    LEFT JOIN yields y 
    ON t.yieldid = y.yieldid AND CAST(t.age/10 AS INT)*10 = y.age
    LEFT JOIN yields k 
    ON t.yieldid = k.yieldid AND round(t.age/10+0.5)*10 = k.age WHERE t.age > 0"))
    
    dbBegin(sim$clusdb)

    rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET vol = :vol, height = :ht, eca = :eca, dec_pcnt = :dec_pcnt, crownclosure = :crownclosure, qmd = :qmd, basalarea= :basalarea where pixelid = :pixelid", tab1[,c("vol", "ht", "eca", "pixelid", "dec_pcnt", "crownclosure", "qmd", "basalarea")])
    dbClearResult(rs)
    dbCommit(sim$clusdb)
    
  }else{
    tab1<-data.table(dbGetQuery(sim$clusdb, "SELECT t.pixelid,
    (((k.tvol - y.tvol*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.tvol as vol,
    (((k.height - y.height*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.height as ht,
    (((k.dec_pcnt - y.dec_pcnt*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.dec_pcnt as dec_pcnt,
    (((k.crownclosure - y.crownclosure*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.crownclosure as crownclosure,
    (((k.basalarea - y.basalarea*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.basalarea as basalarea,
    (((k.qmd - y.qmd*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.qmd as qmd
    FROM pixels t
    LEFT JOIN yields y 
    ON t.yieldid = y.yieldid AND CAST(t.age/10 AS INT)*10 = y.age
    LEFT JOIN yields k 
    ON t.yieldid = k.yieldid AND round(t.age/10+0.5)*10 = k.age WHERE t.age > 0"))
    
    dbBegin(sim$clusdb)
    
    rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET vol = :vol, height = :ht,  dec_pcnt = :dec_pcnt, crownclosure = :crownclosure, qmd = :qmd, basalarea= :basalarea where pixelid = :pixelid", tab1[,c("vol", "ht",  "pixelid", "dec_pcnt", "crownclosure", "qmd", "basalarea")])
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



