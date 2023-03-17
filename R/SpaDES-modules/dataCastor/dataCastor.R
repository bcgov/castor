# Copyright 2023 Province of British Columbia
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
  name = "dataCastor",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
    person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", dataCastor = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "dataCastor.Rmd"),
  reqdPkgs = list("sf", "rpostgis","DBI", "RSQLite", "data.table", "rpostgis", "sqldf"),
  parameters = rbind(
   defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant"),
    defineParameter("startTime", "numeric", start(sim), NA, NA, desc = "Simulation time at which to start"),
    defineParameter("endTime", "numeric", end(sim), NA, NA, desc = "Simulation time at which to end"),
    defineParameter("dbName", "character", "postgres", NA, NA, "The name of the postgres dataabse"),
    defineParameter("dbHost", "character", 'localhost', NA, NA, "The name of the postgres host"),
    defineParameter("dbPort", "character", '5432', NA, NA, "The name of the postgres port"),
    defineParameter("dbUser", "character", 'postgres', NA, NA, "The name of the postgres user"),
    defineParameter("dbPassword", "character", 'postgres', NA, NA, "The name of the postgres user password"),
  defineParameter("randomLandscape", "list", NA, NA, NA, desc = "The exent in a list ordered by: nrows, ncols, xmin, xmax, ymin, ymax"),
  defineParameter("randomLandscapeClusterLevel", "numeric", 1, 0.001, 1.999,"This describes the alpha parameter in RandomFields. alpha is [0,2]"),
  defineParameter("randomLandscapeZoneNumber", "integer", 1, 0, 10,"The number of zones using spades spread function"),
  defineParameter("randomLandscapeZoneConstraint", "data.table", NA, NA, NA, desc = "The constraint to be applied"),
    defineParameter("nameBoundaryFile", "character", "gcbp_carib_polygon", NA, NA, desc = "Name of the boundary file. Here we are using caribou herd boudaries, could be something else (e.g., TSA)."),
    defineParameter("nameBoundaryColumn", "character", "herd_name", NA, NA, desc = "Name of the column within the boundary file that has the boundary name. Here we are using the herd name column in the caribou herd spatial polygon file."),
    defineParameter("nameBoundary", "character", "Muskwa", NA, NA, desc = "Name of the boundary - a spatial polygon within the boundary file. Here we are using a caribou herd name to query the caribou herd spatial polygon data, but it could be something else (e.g., a TSA name to query a TSA spatial polygon file, or a group of herds or TSA's)."),
    defineParameter("nameBoundaryGeom", "character", "geom", NA, NA, desc = "Name of the geom column in the boundary file"),
    defineParameter("saveCastorDB", "logical", FALSE, NA, NA, desc = "Save the db to a file?"),
    defineParameter("useCastorDB", "character", "99999", NA, NA, desc = "Use an exising db? If no, set to 99999. IOf yes, put in the postgres database name here (e.g., castor)."),
    defineParameter("sqlite_dbname", "character", "test", NA, NA, desc = "Name of the castordb"),
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
    expectsInput(objectName ="scenario", objectClass ="data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName = "updateZoneConstraints", objectClass = "data.table", desc = "Table of query parameters for updating the constraints", sourceURL = NA)
    ),
  outputObjects = bind_rows(
    createsOutput("zone.length", objectClass ="integer", desc = NA), # the number of zones to constrain on
    createsOutput("zone.available", objectClass ="data.table", desc = NA), # the available zones of the castordb
    createsOutput("boundaryInfo", objectClass ="character", desc = NA),
    createsOutput("extent", objectClass ="list", desc = NA),
    createsOutput("castordb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates castor realted information"),
    createsOutput("ras", objectClass ="SpatRaster", desc = "Raster Layer of the cell index"),
    createsOutput(objectName = "pts", objectClass = "data.table", desc = "A data.table of X,Y locations - used to find distances"),
    createsOutput(objectName = "foreststate", objectClass = "data.table", desc = "A data.table of the current state of the aoi")
  )
))

doEvent.dataCastor = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    init = { # initialization event
      
      #set Boundaries information object
      if(!is.na(P(sim,"randomLandscape", "dataCastor" )[[1]])){
        sim$extent = P(sim,"randomLandscape", "dataCastor" )
        sim$boundaryInfo <- NULL
        sim$zone.length <- 1
      }else{
        sim$extent <- NA
        sim$boundaryInfo <- list(P(sim,"nameBoundaryFile", "dataCastor" ),P(sim,"nameBoundaryColumn","dataCastor"),P(sim, "nameBoundary", "dataCastor"), P(sim, "nameBoundaryGeom", "dataCastor")) # list of boundary parameters to set the extent of where the model will be run; these parameters are expected inputs in dataCastor
        sim$zone.length <- length(P(sim, "nameZoneRasters", "dataCastor")) # used to define the number of different management constraint zones
      } 
      
      message("Build")
      if(P(sim, "useCastorDB", "dataCastor") == "99999"){ #build Castordb
          
        sim <- createCastorDB(sim) # function (below) that creates an SQLite database
        #populate castordb tables
        sim <- setTablesCastorDB(sim)
        sim <- setZoneConstraints(sim)
        sim <- setIndexesCastorDB(sim) # creates index to facilitate db querying?
        sim <- updateGS(sim) # update the forest attributes
        sim <- scheduleEvent(sim, eventTime = 0,  "dataCastor", "forestStateNetdown", eventPriority=90)
          
      }else{ #copy existing castordb
        sim$foreststate <- NULL
        message(paste0("Loading existing db...", P(sim, "useCastorDB", "dataCastor")))
        #Make a copy of the db so that the castordb is in memory
        userdb <- dbConnect(RSQLite::SQLite(), dbname = P(sim, "useCastorDB", "dataCastor") ) # connext to pgdb
        sim$castordb <- dbConnect(RSQLite::SQLite(), ":memory:") # save the pgdb in memory (object in sim)
        RSQLite::sqliteCopyDatabase(userdb, sim$castordb)
        dbDisconnect(userdb) #Disconnect from the original user provided db
          
        dbExecute(sim$castordb, "PRAGMA synchronous = OFF") # update the database
        dbExecute(sim$castordb, "PRAGMA journal_mode = OFF")
          
        ras.info<-dbGetQuery(sim$castordb, "select * from raster_info where name = 'ras'") #Get the raster information
        sim$ras<-terra::rast(terra::ext(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =1:ras.info$ncell)
        terra::crs(sim$ras)<-paste0("EPSG:", ras.info$crs) #set the raster projection
          
        sim$pts <- data.table(terra::xyFromCell(sim$ras,1:length(sim$ras[]))) # creates pts at centroids of raster boundary file; seems to be faster that rasterTopoints
        sim$pts <- sim$pts[, pixelid:= seq_len(.N)] #add in the pixelid which streams data in according to the cell number = pixelid
          
        #Get the available zones for other modules to query -- In forestryCastor the zones that are not part of the scenario get deleted.
        sim$zone.available<-data.table(dbGetQuery(sim$castordb, "SELECT * FROM zone;")) 
          
        #Alter the ZoneConstraints table with a data.table object that is created before the sim
        if(!is.null(sim$updateZoneConstraints)){
          message("updating zoneConstraints")
          sql<- paste0("UPDATE zoneconstraints SET type = :type, variable = :variable, percentage = :percentage where reference_zone = :reference_zone AND zoneid = :zoneid")  
          dbBegin(sim$castordb)
            rs<-dbSendQuery(sim$castordb, sql, sim$updateZoneConstraints[,c("type", "variable", "percentage", "reference_zone", "zoneid")])
          dbClearResult(rs)
          dbCommit(sim$castordb)
        }
      }
      sim <- scheduleEvent(sim, eventTime = end(sim),  "dataCastor", "removeCastorDB", eventPriority=99) #disconnect the db once the sim is over
      
    },
    forestStateNetdown={
      sim <- setForestState(sim)
    },
    removeCastorDB={
      sim <- disconnectCastorDB(sim)
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

disconnectCastorDB<- function(sim) {
  if(P(sim)$saveCastorDB){
    message('Saving castordb')
    con<-dbConnect(RSQLite::SQLite(), paste0(P(sim, 'sqlite_dbname', 'dataCastor'), "_castordb.sqlite"))
    RSQLite::sqliteCopyDatabase(sim$castordb, con)
    dbDisconnect(sim$castordb)
    dbDisconnect(con)
  }else{
    dbDisconnect(sim$castordb)
  }
    
  return(invisible(sim))
}

createCastorDB <- function(sim) {
  message ('create castordb')
  #build the castordb - a realtional database that tracks the interactions between spatial and temporal objectives
  sim$castordb <- dbConnect(RSQLite::SQLite(), ":memory:") #builds the db in memory; also resets any existing db! Can be set to store on disk
  #dbExecute(sim$castordb, "PRAGMA foreign_keys = ON;") #Turns the foreign key constraints on. 
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS yields ( id integer PRIMARY KEY, yieldid integer, age integer, tvol numeric, dec_pcnt numeric, height numeric, qmd numeric default 0.0, basalarea numeric default 0.0, crownclosure numeric default 0.0, eca numeric);")
  #Note Zone table is created as a JOIN with zoneConstraints and zone
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS raster_info (name text, xmin numeric, xmax numeric, ymin numeric, ymax numeric, ncell integer, nrow integer, crs text);")
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS zone (zone_column text, reference_zone text)")
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS zoneConstraints ( id integer PRIMARY KEY, zoneid integer, reference_zone text, zone_column text, ndt integer, variable text, threshold numeric, type text, percentage numeric, denom text, multi_condition text, t_area numeric, start integer, stop integer);")
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS pixels ( pixelid integer PRIMARY KEY, compartid character, 
own integer, yieldid integer, yieldid_trans integer, zone_const integer DEFAULT 0, treed integer, thlb numeric , elv numeric DEFAULT 0, age numeric, vol numeric, dist numeric DEFAULT 0,
crownclosure numeric, height numeric, basalarea numeric, qmd numeric, siteindex numeric, dec_pcnt numeric, eca numeric, salvage_vol numeric default 0, dual numeric);")
  return(invisible(sim))
}

setTablesCastorDB <- function(sim) {
  message('...setting data tables')
  ###------------------------#
  #Set the compartment IDs----
  ###------------------------#
  if(!(P(sim, "nameCompartmentRaster", "dataCastor") == "99999")){
    message(paste0('.....compartment ids: ', P(sim, "nameCompartmentRaster", "dataCastor")))
    sim$ras<-terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                          srcRaster= P(sim, "nameCompartmentRaster", "dataCastor"), 
                          clipper=sim$boundaryInfo[[1]], 
                          geom= sim$boundaryInfo[[4]], 
                          where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                          conn=NULL))

    sim$pts <- data.table(terra::xyFromCell(sim$ras,1:ncell(sim$ras))) #Seems to be faster than rasterTopoints
    sim$pts <- sim$pts[, pixelid:= seq_len(.N)] # add in the pixelid which streams data in according to the cell number = pixelid
    
    pixels <- data.table(V1 = as.integer(sim$ras[]))
    pixels[, pixelid := seq_len(.N)]
    
    #Set V1 to merge in the vat table values so that the column is character
    if(!(P(sim, "nameCompartmentTable", "dataCastor") == "99999")){
      compart_vat <- data.table(getTableQuery(glue::glue("SELECT * FROM  {P(sim)$nameCompartmentTable};")))
      pixels<- merge(pixels, compart_vat, by.x = "V1", by.y = "value", all.x = TRUE )
      pixels[, V1:= NULL]
      col_name<-data.table(colnames(compart_vat))[!V1 == "value"]
      setnames(pixels, col_name$V1 , "compartid")
      setorder(pixels, "pixelid")#sort the pixels table so that pixelid is in order.
    }else{
      pixels[, V1 := as.character(V1)]
      setnames(pixels, "V1", "compartid")
    }

    sim$ras[]<-pixels$pixelid
    #sim$rasVelo<-velox::velox(sim$ras)
    
    #Add the raster_info
    ras.extent<-terra::ext(sim$ras)
    #TODO: Hard coded for epsg 3005 need to convert to terra?
    dbExecute(sim$castordb, glue::glue("INSERT INTO raster_info (name, xmin, xmax, ymin, ymax, ncell, nrow, crs) values ('ras', {ras.extent[1]}, {ras.extent[2]}, {ras.extent[3]}, {ras.extent[4]}, {ncell(sim$ras)}, {nrow(sim$ras)}, '3005');"))
    
  }else{ #Set the empty table for values not supplied in the parameters
    
    message('.....compartment ids: default 1')
    
    sim$extent[[3]]<-sim$extent[[3]] + 1170000
    sim$extent[[4]]<-sim$extent[[4]]*sim$extent[[1]] + 1170000
    sim$extent[[5]]<-sim$extent[[5]] + 834000
    sim$extent[[6]]<-sim$extent[[6]]*sim$extent[[2]] + 834000
    
    randomRas<-randomRaster(sim$extent, P(sim, 'randomLandscapeClusterLevel', 'dataCastor'))
    
    sim$pts <- data.table(terra::xyFromCell(randomRas,1:length(randomRas[]))) #Seems to be faster than rasterTopoints
    sim$pts <- sim$pts[, pixelid:= seq_len(.N)] # add in the pixelid which streams data in according to the cell number = pixelid

    pixels <- data.table(age = as.integer(round(randomRas[]*200,0)))
    pixels[, pixelid := seq_len(.N)]
    pixels[, compartid := 'all']
    
    #Add the raster_info
    ras.extent<-terra::ext(randomRas)
    sim$ras<-terra::rast(nrows = sim$extent[[1]], ncols = sim$extent[[2]], xmin = sim$extent[[3]], xmax = sim$extent[[4]], ymin = sim$extent[[5]], ymax = sim$extent[[6]], vals = 0 )
    terra::crs(sim$ras)<-paste0("EPSG:3005") #set the raster projection
    sim$ras[]<-pixels$pixelid
    
    #upload raster metadata
    dbExecute(sim$castordb, glue::glue("INSERT INTO raster_info (name, xmin, xmax, ymin, ymax, ncell, nrow, crs) values ('ras', {ras.extent[1]}, {ras.extent[2]}, {ras.extent[3]}, {ras.extent[4]}, {ncell(sim$ras)}, {nrow(sim$ras)}, '3005');"))
    
  }
  
  aoi<-terra::ext(sim$ras) #need to check that each of the extents are the same
  
  #--------------------#
  #Set the Ownership----
  #--------------------#
  if(!(P(sim, "nameOwnershipRaster", "dataCastor") == "99999")){
    message(paste0('.....ownership: ',P(sim, "nameOwnershipRaster", "dataCastor")))
    ras.own<- terra::rast(RASTER_CLIP2(tmpRast =paste0('temp_', sample(1:10000, 1)), 
                           srcRaster= P(sim, "nameOwnershipRaster", "dataCastor"), 
                           clipper=sim$boundaryInfo[[1]], 
                           geom= sim$boundaryInfo[[4]], 
                           where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL))
    
    if(aoi == terra::ext(ras.own)){#need to check that each of the extents are the same
      pixels <- cbind(pixels, data.table(own = as.integer(ras.own[]))) # add the ownership to the pixels table
      rm(ras.own)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameOwnershipRaster", "dataCastor")))
    }
  }else{
    message('.....ownership: default 1')
    pixels[, own := 1] #every pixel gets ownership of 1
  }
  
  #-------------------#
  #Set the zone IDs----
  #-------------------#
  if(!(P(sim, "nameZoneRasters", "dataCastor")[1] == "99999")){
    message(paste0('.....zones: ',P(sim, "nameZoneRasters", "dataCastor")))
    zones_aoi<-data.table(zoneid='', zone_column='')
    
    #Add multiple zone columns - each will have its own raster. Attributed to that raster is a table of the thresholds by zone
    for(i in 1:sim$zone.length){
      ras.zone<-terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                             srcRaster= P(sim, "nameZoneRasters", "dataCastor")[i], 
                             clipper=sim$boundaryInfo[[1]], 
                             geom= sim$boundaryInfo[[4]], 
                             where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                             conn=NULL))
      if(aoi == terra::ext(ras.zone)){#need to check that each of the extents are the same
        pixels<-cbind(pixels, data.table(V1 = as.integer(ras.zone[])))
        setnames(pixels, "V1", paste0('zone',i))#SET zone NAMES to RASTER layer
        
        dbExecute(sim$castordb, glue::glue("ALTER TABLE pixels ADD COLUMN zone{i} numeric;")) # add the zone id column and populate it with the zone names
        dbExecute(sim$castordb, glue::glue("INSERT INTO zone (zone_column, reference_zone) values ( 'zone{i}', '{P(sim)$nameZoneRasters[i]}');" ))
  
        rm(ras.zone) #clean up
        gc()
      } else{
        stop(paste0("ERROR: extents are not the same check -", P(sim, "nameZoneRasters", "dataCastor")))
      }
    }
  } else{
    message(paste0('.....zone ids: randomly created: ' ,  P(sim, "randomLandscapeZoneNumber", "dataCastor")))
    if(P(sim, "randomLandscapeZoneNumber", "dataCastor") > 1){
      ras_dummy<-raster(extent(0,sim$extent[[1]],0, sim$extent[[2]]), ncols = sim$extent[[1]], nrows=sim$extent[[2]], vals = 0)
      pixels[, zone1:= randomPolygons(ras = ras_dummy, numTypes = P(sim, "randomLandscapeZoneNumber", "dataCastor"))[]]
    }else{
      pixels[, zone1:= 1]
    }
   
    dbExecute(sim$castordb, "ALTER TABLE pixels ADD COLUMN zone1 integer;")
    dbExecute(sim$castordb, "INSERT INTO zone (zone_column, reference_zone) values ( 'zone1', 'default');" )
  }
  
  #-----------------------------#
  #Set the zonePriorityRaster----
  #-----------------------------#
  if(!P(sim)$nameZonePriorityRaster == '99999'){
    nameZonePriorityRaster<-P(sim, "nameZonePriorityRaster", "dataCastor")
    #Check to see if the name of the zone priority raster is already in the zone table
    if(!nameZonePriorityRaster %in% dbGetQuery(sim$castordb, "SELECT reference_zone from zone;")$reference_zone){
      message(paste0('.....zone priority raster not in zones table...fetching: ',nameZonePriorityRaster))
      ras.zone.priority<- RASTER_CLIP2(tmpRast =paste0('temp_', sample(1:10000, 1)), 
                             srcRaster= nameZonePriorityRaster, 
                             clipper=sim$boundaryInfo[[1]], 
                             geom= sim$boundaryInfo[[4]], 
                             where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                             conn=NULL)
      if(aoi == extent(ras.zone.priority)){#need to check that each of the extents are the same
        pixels<-cbind(pixels, data.table(V1=ras.zone.priority[]))
        zone.priority<-paste0("zone", as.character(nrow(dbGetQuery(sim$castordb, "SELECT * FROM zone;")) + 1)) #find the max zone number
        setnames(pixels, "V1", zone.priority)#Add the column name to pixels 
        
        dbExecute(sim$castordb, glue::glue("INSERT INTO zone (zone_column, reference_zone) values ('{zone.priority}', '{nameZonePriorityRaster}');"))
        dbExecute(sim$castordb, glue::glue("ALTER TABLE pixels ADD COLUMN {zone.priority} integer;"))
    
        sim$zone.length<-sim$zone.length + 1 #Add to the zone.length needed when inserting the pixels table
        rm(ras.zone.priority,zone.priority) # clean up
        gc()
      }else{
        stop(paste0("ERROR: extents are not the same check -", P(sim, "nameZonePriorityRaster", "dataCastor")))
      }
    }
  }
  
  #---------------#
  #Set the THLB----
  #---------------#
  if(!(P(sim, "nameMaskHarvestLandbaseRaster", "dataCastor") == "99999")){
    message(paste0('.....thlb: ',P(sim, "nameMaskHarvestLandbaseRaster", "dataCastor")))
    ras.thlb<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                            srcRaster= P(sim, "nameMaskHarvestLandbaseRaster", "dataCastor"), 
                            clipper=sim$boundaryInfo[[1]], 
                            geom= sim$boundaryInfo[[4]], 
                            where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                            conn=NULL))
    if(aoi == terra::ext(ras.thlb)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(thlb=as.numeric(ras.thlb[])))
      rm(ras.thlb)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameMaskHarvestLandbaseRaster", "dataCastor")))
    }
    
  }else{
    message('.....thlb: default 1')
    pixels[!is.na(compartid), thlb := 1]
  }
  
  #--------------------#
  #Set the yield IDs----
  #--------------------#
  if(!(P(sim, "nameYieldsRaster", "dataCastor") == "99999")){
    message(paste0('.....yield ids: ',P(sim, "nameYieldsRaster", "dataCastor")))
    ras.ylds<-terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                           srcRaster= P(sim, "nameYieldsRaster", "dataCastor"), 
                           clipper=sim$boundaryInfo[[1]], 
                           geom= sim$boundaryInfo[[4]], 
                           where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL))
    if(aoi == terra::ext(ras.ylds)){ #need to check that each of the extents are the same
      pixels <- cbind(pixels, data.table(yieldid=as.integer(ras.ylds[])))
      rm(ras.ylds)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameYieldsRaster", "dataCastor")))
    }
    
    #Check there is a table to link the yield ids 
    if(P(sim, "nameYieldTable", "dataCastor") == "99999"){
      stop(paste0("Specify the nameYieldTable =", P(sim, "nameYieldTable", "dataCastor")))
    }
    
    yld.ids<-paste( unique(pixels[!is.na(yieldid),"yieldid"])$yieldid, sep=" ", collapse = ", ") #get the yieldids from pixels table
    
    #Check to see what yields are available
    testColumnNames<-getTableQuery(glue::glue("SELECT * FROM {P(sim)$nameYieldTable} LIMIT 1;"))
    colNames<- names(testColumnNames)[names(testColumnNames) %in% c("ycid", "age", "tvol", "dec_pcnt", "height", "eca", "basalarea", "qmd", "crownclosure")]
    colNamesYieldid <-colNames
    colNamesYieldid[colNamesYieldid=='ycid']<-"yieldid"
      
    #Set the yields table with yield curves that are only in the study area
    yields<-getTableQuery(glue::glue("SELECT ", glue::glue_collapse(colNames, sep = ", ")," FROM {P(sim)$nameYieldTable} where ycid IN ({yld.ids});"))
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, glue::glue("INSERT INTO yields (",glue::glue_collapse(colNamesYieldid, sep = ", "),") 
                      values (:",glue::glue_collapse(colNames, sep = ", :"),");"), yields)
    dbClearResult(rs)
    dbCommit(sim$castordb)
    
  }else{
    message('.....yield ids: default 1')
    pixels[!is.na(compartid), yieldid := 1]
    #Set the yields table with a dummy yield curve
    yields<-data.table(yieldid= 1, 
                       age= seq(from =0, to=250, by = 10), 
                       tvol = c(0, 0, 0, 24.2, 98.6, 192.9, 292.4, 382.1, 482.8, 574.5, 648, 706.6, 771.6, 833.7, 885.8, 924.2, 956.2, 982.6, 1004.2, 1023.1, 1038.7, 1051.1, 1060.5, 1067.6, 1072.5, 1075.6 ), 
                       dec_pcnt = NA, 
                       height = c(0, 2.7, 7.1, 11.4, 15.4, 18.9, 22, 24.7, 27.1, 29.2, 31, 32.5, 33.9, 35, 36, 36.9, 37.7, 38.3, 38.9, 39.3, 39.7, 40.1, 40.4, 40.6, 40.8, 41), 
                       eca = c(1, 1, 0.25, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1),
                       basalarea = c(0, 0, 1.3, 8.1, 18.6, 28.6, 37.7, 45.1, 52.7, 58.9, 63.7, 67.4, 71.1, 74.6, 77.4, 79.3, 80.8, 82.1, 83.1, 83.9, 84.5, 84.9, 85.2, 85.3, 85.4, 85.4),
                       qmd = c(0, 0.5, 5.7, 14.1, 21.5, 26.8, 30.9, 34, 36.8, 39, 40.7, 42.1, 43.4, 44.7, 45.8, 46.5, 47.2, 47.8, 48.3, 48.7, 49.1, 49.4, 49.7, 49.9, 50.1, 50.3),
                       crownclosure = c(0, 2.8, 25.6, 64.7, 79.6, 82.5, 82.5, 82, 81.6, 81.2, 80.8, 80.3, 79.9, 79.5, 79.1, 78.6, 78.2, 77.8, 77.4, 76.9, 76.5, 76.1, 75.7, 75.2, 74.8, 74.4)
    )
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, "INSERT INTO yields (yieldid, age, tvol, dec_pcnt, height, eca, basalarea, qmd, crownclosure ) 
                      values (:yieldid, :age, :tvol, :dec_pcnt, :height, :eca, :basalarea, :qmd, :crownclosure)", yields)
    dbClearResult(rs)
    dbCommit(sim$castordb)
  }
  
  #Set the current yield IDs-----#
  #------------------------------#
  if(!(P(sim, "nameYieldsCurrentRaster", "dataCastor") == "99999")){
    message(paste0('.....yield ids: ',P(sim, "nameYieldsCurrentRaster", "dataCastor")))
    ras.ylds.current<-terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                           srcRaster= P(sim, "nameYieldsCurrentRaster", "dataCastor"), 
                           clipper=sim$boundaryInfo[[1]], 
                           geom= sim$boundaryInfo[[4]], 
                           where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL))
    if(aoi == terra::ext(ras.ylds.current)){#need to check that each of the extents are the same
      updateToCurrent<-data.table(yieldid=as.integer(ras.ylds.current[]))
      pixels$current_yieldid <- updateToCurrent$yieldid
      pixels<-pixels[!(current_yieldid==0), yieldid := current_yieldid]
      pixels$current_yieldid <- NULL
      rm(ras.ylds.current)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameYieldsCurrentRaster", "dataCastor")))
    }
    
    #Check there is a table to link to
    if(P(sim, "nameYieldCurrentTable", "dataCastor") == "99999"){
      stop(paste0("Specify the nameYieldCurrentTable =", P(sim, "nameYieldCurrentTable", "dataCastor")))
    }
    
    yld.ids.current<-paste( unique(updateToCurrent[!is.na(yieldid),]$yieldid), sep=" ", collapse = ", ")
   
    #Check to see what yields are available
    testColumnNames<-getTableQuery(paste0("SELECT * FROM ",P(sim)$nameYieldCurrentTable , " LIMIT 1"))
    colNames<- names(testColumnNames)[names(testColumnNames) %in% c("ycid", "age", "tvol", "dec_pcnt", "height", "eca", "basalarea", "qmd", "crownclosure")]
    colNamesYieldid <-colNames
    colNamesYieldid[colNamesYieldid=='ycid']<-"yieldid"
    
    #Set the yields table with yield curves that are only in the study area
    yields.current<-getTableQuery(paste0("SELECT ",paste(colNames, collapse = ", ", sep = " ")," FROM ", P(sim)$nameYieldCurrentTable , " where ycid IN (", yld.ids.current , ");"))
    
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, glue::glue("INSERT INTO yields (",glue::glue_collapse(colNamesYieldid, sep = ", "),") 
                      values (:",glue::glue_collapse(colNames, sep = ", :"),");"), yields.current)
    dbClearResult(rs)
    dbCommit(sim$castordb)
  }
  
  #----------------------------#
  #---Set transition yields ----
  #----------------------------#
  if(!(P(sim, "nameYieldsTransitionRaster", "dataCastor") == "99999")){
    message(paste0('.....yield transition ids: ',P(sim, "nameYieldsTransitionRaster", "dataCastor")))
    
    ras.ylds_trans<-terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                           srcRaster= P(sim, "nameYieldsTransitionRaster", "dataCastor"), 
                           clipper=sim$boundaryInfo[[1]], 
                           geom= sim$boundaryInfo[[4]], 
                           where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL))
    if(aoi == terra::ext(ras.ylds_trans)){#need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(yieldid_trans= as.integer(ras.ylds_trans[])))
      rm(ras.ylds_trans)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameYieldsTransitionRaster", "dataCastor")))
    }
       #Check there is a table to link to
    if(P(sim, "nameYieldTransitionTable", "dataCastor") == "99999"){
      stop(paste0("Specify the nameYieldTransitionTable =", P(sim, "nameYieldTransitionTable", "dataCastor")))
    }
    
    yld.ids.trans<-paste( as.integer(unique(pixels[!is.na(yieldid_trans),"yieldid_trans"])$yieldid_trans), sep=" ", collapse = ", ")    
  
    #Check to see what yields are available
    testColumnNames<-getTableQuery(glue::glue("SELECT * FROM {P(sim)$nameYieldTransitionTable} LIMIT 1;"))
    colNames<- names(testColumnNames)[names(testColumnNames) %in% c("ycid", "age", "tvol", "dec_pcnt", "height", "eca", "basalarea", "qmd", "crownclosure")]
    colNamesYieldid <-colNames
    colNamesYieldid[colNamesYieldid=='ycid']<-"yieldid"
    
    #Set the yields table with yield curves that are only in the study area
    yields.trans<-getTableQuery(paste0("SELECT ", paste(colNames, collapse = ", ", sep = " ")," FROM ", P(sim)$nameYieldTransitionTable, " where ycid IN (", yld.ids.trans , ");"))
    
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, glue::glue("INSERT INTO yields (",glue::glue_collapse(colNamesYieldid, sep = ", "),") 
                      values (:",glue::glue_collapse(colNames, sep = ", :"),");"), yields.trans)
    dbClearResult(rs)
    dbCommit(sim$castordb)
    
    pixels[is.na(yieldid_trans) & !is.na(yieldid), yieldid_trans := yieldid] #assign the transition the same curve
    
  }else{
    message('.....yield trans ids: default 1')
    pixels[!is.na(compartid), yieldid_trans := 1]
  }
  
  #**************FOREST INVENTORY - VEGETATION VARIABLES*******************#
  #----------------------------#
  #----Set forest attributes----
  #----------------------------#
  if(!P(sim, "nameForestInventoryRaster","dataCastor") == '99999'){
    print("clipping inventory key")
    ras.fid<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                           srcRaster= P(sim, "nameForestInventoryRaster", "dataCastor"), 
                           clipper=sim$boundaryInfo[[1]], 
                           geom= sim$boundaryInfo[[4]], 
                           where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL))
    if(aoi == terra::ext(ras.fid)){ #need to check that each of the extents are the same
      inv_id<-data.table(fid = as.integer(ras.fid[]))
      inv_id[, pixelid:= seq_len(.N)]
      inv_id[, fid:= as.integer(fid)] #make sure the fid is an integer for merging later on
      rm(ras.fid)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameForestInventoryRaster", "dataCastor")))
    }
    
    if(!P(sim, "nameForestInventoryTable","dataCastor") == '99999'){ #Get the forest inventory variables and re assign there names to be more generic than VEGCOMP
      
      forest_attributes_castordb<-sapply(c("Treed","Age","Height", "CrownClosure", "SiteIndex", "QMD", "BasalArea"), function(x){
        if(!(P(sim, paste0("nameForestInventory", x), "dataCastor") == '99999')){
          return(paste0(P(sim, paste0("nameForestInventory", x), "dataCastor"), " as ", tolower(x)))
        }else{
          message(paste0("WARNING: Missing parameter nameForestInventory", x, " ---Defaulting to NA"))
        }
      })
      
      forest_attributes_castordb<-Filter(Negate(is.null), forest_attributes_castordb) #remove any nulls
      
      #If there is a multi variable constraint then add them to the query
      queryMulti<-dbGetQuery(sim$castordb, "SELECT distinct(variable) FROM zoneConstraints WHERE multi_condition is not null or multi_condition <> 'NA' ")

      if(nrow(queryMulti) > 0){ # there is a multi-condition constraint
        multiVars<-unlist(strsplit(paste(queryMulti$variable, collapse = ', ', sep = ','), ","))
        multiVars<-unique(gsub("[[:space:]]", "", multiVars))
        multiVars<-multiVars[!multiVars[] %in% c('proj_age_1', 'proj_height_1', 'crown_closure', 'site_index', 'blockid', 'age', 'height', 'siteindex', 'crownclosure', 'dist', 'bclcs_level_2', "basal_area", "quad_diam_125")]
        if(!identical(character(0), multiVars)){
          multiVars1<-multiVars #used for altering pixels table in castordb i.e., adding in the required information to run the query
          forest_attributes_castordb<-c(forest_attributes_castordb, multiVars) #Add the multivars to the pixels data table
          #format for pixels upload
          multiVars2<-multiVars
          multiVars2[1]<-paste0(', :',multiVars2[1])
          multiVars[1]<-paste0(', ',multiVars[1])
        }else{ # set defaults to blanks and null
          multiVars<-''
          multiVars2<-''
          multiVars1<-NULL
          }
        #Update the multi conditional constraints so the names match the dynamic variables
        dbExecute(sim$castordb, "UPDATE zoneConstraints set multi_condition = replace(multi_condition, 'proj_age_1', 'age') where multi_condition is not null;")
        dbExecute(sim$castordb, "UPDATE zoneConstraints set multi_condition = replace(multi_condition, 'proj_height_1', 'height') where multi_condition is not null;")
        dbExecute(sim$castordb, "UPDATE zoneConstraints set multi_condition = replace(multi_condition, 'site_index', 'siteindex') where multi_condition is not null;")
        dbExecute(sim$castordb, "UPDATE zoneConstraints set multi_condition = replace(multi_condition, 'crown_closure', 'crownclosure') where multi_condition is not null;")
        dbExecute(sim$castordb, "UPDATE zoneConstraints set multi_condition = replace(multi_condition, 'basal_area', 'basalarea') where multi_condition is not null;")
        dbExecute(sim$castordb, "UPDATE zoneConstraints set multi_condition = replace(multi_condition, 'quad_diam_125', 'qmd') where multi_condition is not null;")
        
        }else{ # set defaults to blanks and null
        multiVars<-''
        multiVars2<-''
        multiVars1<-NULL
        }
      
      if(length(forest_attributes_castordb) > 0){
        print(paste0("getting inventory attributes: ", paste(forest_attributes_castordb, collapse = ",")))
        fids<-unique(inv_id[!(is.na(fid)), fid])
        attrib_inv<-data.table(getTableQuery(paste0("SELECT " , P(sim, "nameForestInventoryKey", "dataCastor"), " as fid, ", paste(forest_attributes_castordb, collapse = ","), " FROM ",
                                                    P(sim, "nameForestInventoryTable","dataCastor"), " WHERE ", P(sim, "nameForestInventoryKey", "dataCastor") ," IN (",
                                                    paste(fids, collapse = ","),");" )))
        
        print("...merging with fid") #Merge this with the raster using fid which gives you the primary key -- pixelid
        inv<-merge(x=inv_id, y=attrib_inv, by.x = "fid", by.y = "fid", all.x = TRUE) 
        
        #Merge to pixels using the pixelid
        pixels<-merge(x = pixels, y =inv, by.x = "pixelid", by.y = "pixelid", all.x = TRUE)
        pixels<-pixels[, fid:=NULL] # remove the fid key
        
        #Change the VRI bclcs_level_2 which is the TREED parameter to a binary.
        pixels<-pixels[!treed == 'T', treed:=0][treed == 'T', treed:=1]
        
        if(!is.null(multiVars1)){
          for(var in multiVars1){
            if(is.character(pixels[, eval(parse(text =var))])){
              dbExecute(sim$castordb, glue::glue("ALTER TABLE pixels ADD COLUMN {var} text;"))
            }else{
              dbExecute(sim$castordb, glue::glue("ALTER TABLE pixels ADD COLUMN {var} numeric;"))
            }
          }
        }
        rm(inv, attrib_inv,inv_id, fids)
      }else{
        stop("No forest attributes from the inventory specified")
      }
    } else { 
      stop(paste0('nameForestInventoryTable = ', P(sim, "nameForestInventoryTable","dataCastor")))
    }  
  } else{
    multiVars<-''
    multiVars2<-''
    multiVars1<-NULL
  }
  
  #----------------#
  #Set the Treed----
  #----------------#
  if(!(P(sim, "nameTreedRaster", "dataCastor") == "99999") & P(sim, "nameForestInventoryTreed", "dataCastor") == "99999"){
    message(paste0('.....treed: ',P(sim, "nameTreedRaster", "dataCastor")))
    ras.treed<-terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                          srcRaster= P(sim, "nameTreedRaster", "dataCastor"), 
                          clipper=sim$boundaryInfo[[1]], 
                          geom= sim$boundaryInfo[[4]], 
                          where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                          conn=NULL))
    if(aoi == terra::ext(ras.treed)){ # need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(treed=as.numeric(ras.treed[])))
      rm(ras.treed)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameTreedRaster", "dataCastor")))
    }
  }
  
  if(P(sim, "nameTreedRaster", "dataCastor") == "99999" & P(sim, "nameForestInventoryTreed", "dataCastor") == "99999"){
    message('.....treed: default 1')
    pixels[!is.na(compartid), treed := 1]
  }
  
  #---------------#
  #Set the Age----- 
  #---------------#
  if(!(P(sim, "nameAgeRaster", "dataCastor") == "99999") & P(sim, "nameForestInventoryAge", "dataCastor") == "99999"){
    message(paste0('.....age: ',P(sim, "nameAgeRaster", "dataCastor")))
    ras.age<-terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                          srcRaster= P(sim, "nameAgeRaster", "dataCastor"), 
                          clipper=sim$boundaryInfo[[1]], 
                          geom= sim$boundaryInfo[[4]], 
                          where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                          conn=NULL))
    if(aoi == terra::ext(ras.age)){ # need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(age=as.numeric(ras.age[])))
      setnames(pixels, "V1", "age")
      rm(ras.age)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameAgeRaster", "dataCastor")))
    }
  }
  
  if(P(sim, "nameAgeRaster", "dataCastor") == "99999" && P(sim, "nameForestInventoryAge", "dataCastor") == "99999" && is.na(sim$extent[[1]])){
    message('.....age: random age')
    pixels[!is.na(compartid), age := as.integer(120 + runif(nrow(pixels[!is.na(compartid),]), -100, 100))]
  }
  
  #-------------------------#
  #Set the Crown Closure-----  
  #-------------------------#
  if(!(P(sim, "nameCrownClosureRaster", "dataCastor") == "99999") & P(sim, "nameForestInventoryCrownClosure", "dataCastor") == "99999"){
    message(paste0('.....crownclosure: ',P(sim, "nameCrownClosureRaster", "dataCastor")))
    ras.cc<-terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                         srcRaster=P(sim, "nameCrownClosureRaster", "dataCastor"), 
                         clipper=sim$boundaryInfo[[1]], 
                         geom= sim$boundaryInfo[[4]], 
                         where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                         conn=NULL))
    if(aoi == terra::ext(ras.cc)){ # need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(crownclosure=as.numeric(ras.cc[])))
      rm(ras.cc)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameCrownClosureRaster", "dataCastor")))
    }
  }
  if(P(sim, "nameCrownClosureRaster", "dataCastor") == "99999" & P(sim, "nameForestInventoryCrownClosure", "dataCastor") == "99999"){
    message('.....crown closure: default 60')
    pixels[!is.na(compartid), crownclosure := 60]
  }
    
  #-----------------#
  #Set the Height---- 
  #-----------------#
  if(!(P(sim, "nameHeightRaster", "dataCastor") == "99999") & P(sim, "nameForestInventoryHeight", "dataCastor") == "99999"){
    message(paste0('.....height: ',P(sim, "nameHeightRaster", "dataCastor")))
    ras.ht<-terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                         srcRaster=P(sim, "nameHeightRaster", "dataCastor"), 
                         clipper=sim$boundaryInfo[[1]], 
                         geom= sim$boundaryInfo[[4]], 
                         where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                         conn=NULL))
    if(aoi == terra::ext(ras.ht)){ # need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(height=as.numeric(ras.ht[])))
      rm(ras.ht)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameHeightRaster", "dataCastor")))
    }
  }
  if(P(sim, "nameHeightRaster", "dataCastor") == "99999" & P(sim, "nameForestInventoryHeight", "dataCastor") == "99999"){
    message('.....height: default 10')
    pixels[!is.na(compartid), height := 10]
  }
  
  #---------------------#
  #Set the Site Index----
  #---------------------#
  if(!(P(sim, "nameSiteIndexRaster", "dataCastor") == "99999") & P(sim, "nameForestInventorySiteIndex", "dataCastor") == "99999"){
    message(paste0('.....siteindex: ',P(sim, "nameSiteIndexRaster", "dataCastor")))
    ras.si<-terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                         srcRaster=P(sim, "nameSiteIndexRaster", "dataCastor"), 
                         clipper=sim$boundaryInfo[[1]], 
                         geom= sim$boundaryInfo[[4]], 
                         where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                         conn=NULL))
    if(aoi == terra::ext(ras.si)){ # need to check that each of the extents are the same
      pixels<-cbind(pixels, data.table(siteindex= as.numeric(ras.si[])))
      rm(ras.si)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameSiteIndexRaster", "dataCastor")))
    }
  }
  if(P(sim, "nameSiteIndexRaster", "dataCastor") == "99999" & P(sim, "nameForestInventorySiteIndex", "dataCastor") == "99999"){
    message('.....siteindex: default NA')
    pixels[, siteindex:= NA]
  }
  
  #----------------#
  #Set the BasalArea----
  #----------------#
  if(P(sim, "nameForestInventoryBasalArea", "dataCastor") == "99999"){
    pixels[, basalarea := NA]
  }
  
  #----------------#
  #Set the QMD----
  #----------------#
  if(P(sim, "nameForestInventoryQMD", "dataCastor") == "99999"){
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
  dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, qry, pixels )
    dbClearResult(rs)
  dbCommit(sim$castordb)
  
  rm(pixels)
  gc()
  return(invisible(sim))
}

setIndexesCastorDB <- function(sim) { # making indexes helps with query speed for future querying
  dbExecute(sim$castordb, "CREATE UNIQUE INDEX index_pixelid on pixels (pixelid);")
  dbExecute(sim$castordb, "CREATE INDEX index_age on pixels (age);")
  
  zones<-dbGetQuery(sim$castordb, "SELECT zone_column FROM zone;")
  for(i in 1:nrow(zones)){
    dbExecute(sim$castordb, glue::glue("CREATE INDEX index_zone{i} on pixels ({zones[[1]][i]});"))
  }
  
  dbExecute(sim$castordb, "VACUUM;")
  message('...done')
  return(invisible(sim))
}

setZoneConstraints<-function(sim){
  message("... setting ZoneConstraints table")
  if(!P(sim)$nameZoneTable == '99999' && is.na(sim$extent[[1]])){ # zone_constraint table
    
    zone<-dbGetQuery(sim$castordb, "SELECT * FROM zone;") # select the name of the raster and its column name in pixels
    zone_const<-rbindlist(lapply(split(zone, seq(nrow(zone))) , function(x){
      if(nrow(dbGetQuery(sim$castordb, glue::glue("SELECT distinct({x$zone_column}) from pixels where {x$zone_column} is not null;")))>0){
        getTableQuery(glue::glue("SELECT * FROM {P(sim)$nameZoneTable} WHERE reference_zone = '{x$reference_zone}' AND zoneid IN(",paste(dbGetQuery(sim$castordb,glue::glue("SELECT distinct({x$zone_column}) as zoneid from pixels where {x$zone_column} is not null;"))$zoneid, sep ="", collapse ="," ),");"))
      }
    })
    )
     
    zone_list<-merge(zone_const, zone, by.x = 'reference_zone',by.y = 'reference_zone')
    
    #Split into two sections: one for denom values, the other for default denom which is the total area of the zone
    zone_const_default<-zone_list[is.na(denom),]
    zone_const_denom<-zone_list[!is.na(denom),]
    
    #Get total area of the zone
    if(nrow(zone_const_default)>0){
      t_area_default<-rbindlist(lapply(unique(zone_const_default$zone_column), function (x){
        dbGetQuery(sim$castordb, glue::glue("SELECT count() as t_area, {x} as zoneid, '{x}' as zone_column from pixels where {x} is not null group by {x};")) 
      }))
    }else{
      t_area_default<-data.table( t_area=as.numeric(), zoneid=as.integer(),zone_column=as.character())
    }
    #Get total area where some inequality holds
    if(nrow(zone_const_denom)>0){
      t_area_denomt<-rbindlist(lapply(split(zone_const_denom, seq(nrow(zone_const_denom))), function (x){
        dbGetQuery(sim$castordb, glue::glue("SELECT count() as t_area, {x$zone_column} as zoneid, '{x$zone_column}' as zone_column from pixels where {x$denom} and {x$zone_column}= {x$zoneid};")) 
      })) 
    }else{
      t_area_denomt<-data.table( t_area=as.numeric(), zoneid=as.integer(),zone_column=as.character())
    }
    
    t_area<-rbindlist(list(t_area_denomt,t_area_default))
    zones<-merge(zone_list, t_area, by.x = c("zone_column", "zoneid"), by.y = c("zone_column", "zoneid"))
    
    #TODO:REMOVE THIS CHECK
    if(nrow(t_area_denomt) > 0){
      dbBegin(sim$castordb)
      rs<-dbSendQuery(sim$castordb, "INSERT INTO zoneConstraints (zoneid, reference_zone, zone_column, ndt, variable, threshold, type ,percentage, multi_condition, t_area, denom, start , stop ) 
                      values (:zoneid, :reference_zone, :zone_column, :ndt, :variable, :threshold, :type, :percentage, :multi_condition, :t_area, :denom, :start, :stop);", zones)
      dbClearResult(rs)
      dbCommit(sim$castordb)
    }else{
        dbBegin(sim$castordb)
        rs<-dbSendQuery(sim$castordb, "INSERT INTO zoneConstraints (zoneid, reference_zone, zone_column, ndt, variable, threshold, type ,percentage, multi_condition, t_area, start, stop) 
                      values (:zoneid, :reference_zone, :zone_column, :ndt, :variable, :threshold, :type, :percentage, :multi_condition, :t_area, :start, :stop);", zones[,c('zoneid', 'zone_column', 'reference_zone', 'ndt','variable', 'threshold', 'type', 'percentage', 'multi_condition', 't_area', 'start', 'stop')])
        dbClearResult(rs)
        dbCommit(sim$castordb)
      }
  }else{
    paste0(P(sim)$nameZoneTable, "...nameZoneTable not supplied. WARNING: your simulation has no zone constraints")
  }
  
  #For randomly created landscapes:
  if(!is.na(sim$extent[[1]])){
    
    if(nrow(P(sim,"randomLandscapeZoneConstraint", "dataCastor")) != P(sim,"randomLandscapeZoneNumber", "dataCastor")){
      stop("The randomLandscapeZoneNumber does not equal number of randomLandscapeZoneConstraint")
    }
    
    message("... setting ZoneConstraints table using randomLandscapeZoneConstraint")

    randomLandscapeZoneConstraint<-P(sim, "randomLandscapeZoneConstraint", "dataCastor")
    randomLandscapeZoneConstraint<-merge(randomLandscapeZoneConstraint, dbGetQuery(sim$castordb, "select count(*) as t_area, zone1 as zoneid from pixels group by zone1;"), by.x = "zoneid", by.y = "zoneid", all.x =T)
    randomLandscapeZoneConstraint[, `:=` (zone_column = 'zone1',reference_zone='default', ndt =3, multi_condition = NA, denom = NA, start =0, stop = 250  )]
    
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, "INSERT INTO zoneConstraints (zoneid, reference_zone, zone_column, ndt, variable, threshold, type ,percentage, multi_condition, t_area, start, stop) 
                      values (:zoneid, :reference_zone, :zone_column, :ndt, :variable, :threshold, :type, :percentage, :multi_condition, :t_area, :start, :stop);", randomLandscapeZoneConstraint[,c('zoneid', 'zone_column', 'reference_zone', 'ndt','variable', 'threshold', 'type', 'percentage', 'multi_condition', 't_area', 'start', 'stop')])
    dbClearResult(rs)
    dbCommit(sim$castordb)
  }
  return(invisible(sim))
}

setForestState<-function(sim){ #Basic information about the state of the forest. TODO: modify this to make a more complete netdown
  sim$foreststate<- data.table(dbGetQuery(sim$castordb, paste0("SELECT compartid as compartment, sum(case when compartid is not null then 1 else 0 end) as total, 
           sum(thlb) as thlb, sum(case when age <= 40 and age >= 0 then 1 else 0 end) as early,
           sum(case when age > 40 and age < 140 then 1 else 0 end) as mature,
           sum(case when age >= 140 then 1 else 0 end) as old
           FROM pixels  where compartid 
              in('",paste(sim$boundaryInfo[[3]], sep = " ", collapse = "','"),"')
                         group by compartid;"))
            )

  if(dbGetQuery(sim$castordb, "SELECT COUNT(*) as exists_check FROM pragma_table_info('pixels') WHERE name='roadyear';")$exists_check == 0){
    sim$foreststate[,road:=0]
  }else{
    sim$foreststate[,road:= dbGetQuery(sim$castordb,"select count() as road from pixels where roadyear is not null;")$road]
  }
  return(invisible(sim))
}

updateGS<- function(sim) {
  #Note: See the SQLite approach to updating. The Update statement does not support JOIN
  #update the yields being tracked
  message("...update yields")
  if(length(dbGetQuery(sim$castordb, "SELECT variable FROM zoneConstraints WHERE variable = 'eca' LIMIT 1;")) > 0){
    #tab1[, eca:= lapply(.SD, function(x) {approx(dat[yieldid == .BY]$age, dat[yieldid == .BY]$eca,  xout=x, rule = 2)$y}), .SD = "age" , by=yieldid]
    tab1<-data.table(dbGetQuery(sim$castordb, "WITH t as (select pixelid, yieldid, age, height, crownclosure, dec_pcnt, basalarea, qmd, eca, vol from pixels where age > 0 and age <= 350) 
SELECT pixelid,
case when k.tvol is null then t.vol else (((k.tvol - y.tvol*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.tvol end as vol,
case when k.height is null then t.height else (((k.height - y.height*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.height end as ht,
case when k.eca is null then t.eca else (((k.eca - y.eca*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.eca end as eca,
case when k.dec_pcnt is null then t.dec_pcnt else (((k.dec_pcnt - y.dec_pcnt*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.dec_pcnt end as dec_pcnt,
case when k.crownclosure is null then t.crownclosure else (((k.crownclosure - y.crownclosure*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.crownclosure end as crownclosure,
case when k.basalarea is null then t.basalarea else (((k.basalarea - y.basalarea*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.basalarea end as basalarea,
case when k.qmd is null then t.qmd else (((k.qmd - y.qmd*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.qmd end as qmd
FROM t
LEFT JOIN yields y 
ON t.yieldid = y.yieldid AND CAST(t.age/10 AS INT)*10 = y.age
LEFT JOIN yields k 
ON t.yieldid = k.yieldid AND round(t.age/10+0.5)*10 = k.age;"))
    
    dbBegin(sim$castordb)

    rs<-dbSendQuery(sim$castordb, "UPDATE pixels SET vol = :vol, height = :ht, eca = :eca, dec_pcnt = :dec_pcnt, crownclosure = :crownclosure, qmd = :qmd, basalarea= :basalarea where pixelid = :pixelid;", tab1[,c("vol", "ht", "eca", "pixelid", "dec_pcnt", "crownclosure", "qmd", "basalarea")])
    dbClearResult(rs)
    dbCommit(sim$castordb)
    
  }else{
    tab1<-data.table(dbGetQuery(sim$castordb, "SELECT t.pixelid,
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
    ON t.yieldid = k.yieldid AND round(t.age/10+0.5)*10 = k.age WHERE t.age > 0;"))
    
    dbBegin(sim$castordb)
    
    rs<-dbSendQuery(sim$castordb, "UPDATE pixels SET vol = :vol, height = :ht,  dec_pcnt = :dec_pcnt, crownclosure = :crownclosure, qmd = :qmd, basalarea= :basalarea where pixelid = :pixelid;", tab1[,c("vol", "ht",  "pixelid", "dec_pcnt", "crownclosure", "qmd", "basalarea")])
    dbClearResult(rs)
    dbCommit(sim$castordb)
  }
  
  message("...create indexes")
  dbExecute(sim$castordb, "CREATE INDEX index_height on pixels (height);")
  rm(tab1)
  gc()
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  if(!suppliedElsewhere("updateZoneConstraints", sim)){ # this object adjusts the zone constraints before the sim is run
    sim$updateZoneConstraints<-NULL
  }

  return(invisible(sim))
}

randomRaster<-function(extent, clusterLevel){
  #RandomFields::RFoptions(spConform=FALSE)
  ras <- terra::rast(nrows = extent[[1]], ncols = extent[[2]], xmin = extent[[3]], xmax = extent[[4]], ymin = extent[[5]], ymax = extent[[6]], vals = 0 )
  model <- RandomFields::RMstable(scale = 300, var = 0.003,  alpha = clusterLevel)
  data.rv<-RandomFields::RFsimulate(model, y = 1:extent[[1]],  x = 1:extent[[2]], grid = TRUE)$variable1
  data.rv<-(data.rv - min(data.rv))/(max(data.rv)- min(data.rv))
  return(terra::setValues(ras, data.rv))
}


