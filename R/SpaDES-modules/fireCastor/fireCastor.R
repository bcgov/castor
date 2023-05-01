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
  name = "fireCastor",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Elizabeth", "Kleynhans", email = "elizabeth.kleynhans@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", fireCastor = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "fireCastor.Rmd"),
  reqdPkgs = list("sf", "rpostgis","DBI", "RSQLite", "data.table", "sqldf", "dplyr", "raster"),
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
    #defineParameter("randomLandscapeZoneNumber", "integer", 1, 0, 10,"The number of zones using spades spread function"),
    #defineParameter("randomLandscapeZoneConstraint", "data.table", NA, NA, NA, desc = "The constraint to be applied"),
    defineParameter("nameBoundaryFile", "character", "gcbp_carib_polygon", NA, NA, desc = "Name of the boundary file. Here we are using caribou herd boudaries, could be something else (e.g., TSA)."),
    defineParameter("nameBoundaryColumn", "character", "herd_name", NA, NA, desc = "Name of the column within the boundary file that has the boundary name. Here we are using the herd name column in the caribou herd spatial polygon file."),
    defineParameter("nameBoundary", "character", "Muskwa", NA, NA, desc = "Name of the boundary - a spatial polygon within the boundary file. Here we are using a caribou herd name to query the caribou herd spatial polygon data, but it could be something else (e.g., a TSA name to query a TSA spatial polygon file, or a group of herds or TSA's)."),
    defineParameter("nameBoundaryGeom", "character", "geom", NA, NA, desc = "Name of the geom column in the boundary file"),
    defineParameter("saveCastorDB", "logical", FALSE, NA, NA, desc = "Save the db to a file?"),
    defineParameter("useCastorDB", "character", "99999", NA, NA, desc = "Use an exising db? If no, set to 99999. IOf yes, put in the postgres database name here (e.g., castor)."),
    defineParameter("sqlite_dbname", "character", "test", NA, NA, desc = "Name of the castordb"),
    defineParameter("nameCompartmentRaster", "character", "99999", NA, NA, desc = "Name of the raster in a pg db that represents a compartment or supply block. Not currently in the pgdb?"),
    defineParameter("nameCompartmentTable", "character", "99999", NA, NA, desc = "Name of the table in a pg db that represents a compartment or supply block value attribute look up. CUrrently 'study_area_compart'?"),
    defineParameter("nameFrtRaster", "character", "99999", NA, NA, desc = "Name of the raster in a pg db that represents the fire regime type (frt)"),
    defineParameter("namesDemRast", "character", "99999", NA, NA, desc = "Name of the raster in a pg db that represents the elevation"),
    defineParameter("namesSlopeRast", "character", "99999", NA, NA, desc = "Name of the raster in a pg db that represents the slope"),
    defineParameter("namesAspectRast", "character", "99999", NA, NA, desc = "Name of the raster in a pg db that represents the aspect"),
    defineParameter("namesInfrastructureRast", "character", "99999", NA, NA, desc = "Name of the raster in a pg db that represents the distance to the closest infrastructure"),
    defineParameter("namesSummerWindRast", "character", "99999", NA, NA, desc = "Name of the raster in a pg db that represents the strength of wind in summer"),
    defineParameter("namesSpringWindRast", "character", "99999", NA, NA, desc = "Name of the raster in a pg db that represents the strength of wind in spring")
  ),
  
  inputObjects = bind_rows(
    expectsInput(objectName ="scenario", objectClass ="data.table", desc = 'The name of the scenario and its description', sourceURL = NA)
  ),
  
  outputObjects = bind_rows(
    createsOutput("boundaryInfo", objectClass ="character", desc = NA),
    createsOutput("extent", objectClass ="list", desc = NA),
    createsOutput("castordb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates castor realted information"),
    createsOutput("ras", objectClass ="SpatRaster", desc = "Raster Layer of the cell index"),
    createsOutput(objectName = "pts", objectClass = "data.table", desc = "A data.table of X,Y locations - used to find distances")
    #createsOutput(objectName = "pixels_fire", objectClass = "data.table", desc = "A data.table of the values of the constant coefficients for lightning and human caused ignitions, fire escape and fire spread")
  )
))

doEvent.fireCastor = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    init = { # initialization event
      
      #set Boundaries information object
      if(!is.na(P(sim,"randomLandscape", "fireCastor" )[[1]])){
        sim$extent = P(sim,"randomLandscape", "fireCastor" )
        sim$boundaryInfo <- NULL
        #sim$zone.length <- 1
      }else{
        sim$extent <- NA
        sim$boundaryInfo <- list(P(sim,"nameBoundaryFile", "fireCastor" ),P(sim,"nameBoundaryColumn","fireCastor"),P(sim, "nameBoundary", "fireCastor"), P(sim, "nameBoundaryGeom", "fireCastor")) # list of boundary parameters to set the extent of where the model will be run; these parameters are expected inputs in dataCastor
        #sim$zone.length <- length(P(sim, "nameZoneRasters", "dataCastor")) # used to define the number of different management constraint zones
      } 
      
      message("Build")
      if(P(sim, "useCastorDB", "fireCastor") == "99999"){ #build Castordb
        
        sim <- createCastorDB(sim) # function (below) that creates an SQLite database
        #populate castordb tables
        sim <- setTablesCastorDB(sim)
        # sim <- setZoneConstraints(sim)
        sim <- setIndexesCastorDB(sim) # creates index to facilitate db querying?
        
      }else{ #copy existing castordb
        #sim$foreststate <- NULL
        message(paste0("Loading existing db...", P(sim, "useCastorDB", "fireCastor")))
        #Make a copy of the db so that the castordb is in memory
        userdb <- dbConnect(RSQLite::SQLite(), dbname = P(sim, "useCastorDB", "fireCastor") ) # connext to pgdb
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
        
        
        #Alter the ZoneConstraints table with a data.table object that is created before the sim
      }
      sim <- scheduleEvent(sim, eventTime = end(sim),  "fireCastor", "removeCastorDB", eventPriority=99) #disconnect the db once the sim is over
      
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
    con<-dbConnect(RSQLite::SQLite(), paste0(P(sim, 'sqlite_dbname', 'fireCastor'), "_castordb.sqlite"))
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
  castordb <- dbConnect(RSQLite::SQLite(), ":memory:") #builds the db in memory; also resets any existing db! Can be set to store on disk
  #dbExecute(sim$castordb, "PRAGMA foreign_keys = ON;") #Turns the foreign key constraints on. 
  dbExecute(castordb, "CREATE TABLE IF NOT EXISTS raster_info (name text, xmin numeric, xmax numeric, ymin numeric, ymax numeric, ncell integer, nrow integer, crs text);")
  dbExecute(castordb, "CREATE TABLE IF NOT EXISTS pixels_fire ( pixelid integer PRIMARY KEY,compartid character,frt numeric, dem numeric DEFAULT 0, slope numeric, aspect numeric, distinfrastructure numeric, springwind numeric, summerwind numeric) ;") #, logit_P_lightning_coef_const numeric, logit_P_person_coef_const numeric, logit_P_escape_coef_const numeric, logit_P_spread_coef_const numeric);")
  return(invisible(sim))
  
}

setTablesCastorDB <- function(sim) {
  message('...setting data tables')
  ###------------------------#
  #Set the compartment IDs----
  ###------------------------#
  
  
  if(!(P(sim, "nameCompartmentRaster", "fireCastor") == "99999")){
    message(paste0('.....compartment ids: ', P(sim, "nameCompartmentRaster", "fireCastor")))
    sim$ras<-terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                      srcRaster= P(sim, "nameCompartmentRaster", "fireCastor"), 
                                      clipper=sim$boundaryInfo[[1]], 
                                      geom= sim$boundaryInfo[[4]], 
                                      where_clause =  paste0(sim$boundaryInfo[[3]]),
                                      conn=NULL))
    
    # nameCompartmentRaster - I have to fix this. Not sure what to put
    
    sim$pts <- data.table(terra::xyFromCell(sim$ras,1:ncell(sim$ras))) #Seems to be faster than rasterTopoints
    sim$pts <- sim$pts[, pixelid:= seq_len(.N)] # add in the pixelid which streams data in according to the cell number = pixelid
    
    #message(print(sim$pts))
    
    pixels_fire <- data.table(V1 = as.integer(sim$ras[]))
    pixels_fire[, pixelid := seq_len(.N)]
    
    #Set V1 to merge in the vat table values so that the column is character
    if(!(P(sim, "nameCompartmentTable", "fireCastor") == "99999")){
      compart_vat <- data.table(getTableQuery(glue::glue("SELECT * FROM  {P(sim)$nameCompartmentTable};")))
      pixels_fire<- merge(pixels_fire, compart_vat, by.x = "V1", by.y = "value", all.x = TRUE )
      pixels_fire[, V1:= NULL]
      col_name<-data.table(colnames(compart_vat))[!V1 == "value"]
      setnames(pixels_fire, col_name$V1 , "compartid")
      setorder(pixels_fire, "pixelid")#sort the pixels_fire table so that pixelid is in order.
    }else{
      pixels_fire[, V1 := as.character(V1)]
      setnames(pixels_fire, "V1", "compartid")
    }
    
    #message(print(pixels_fire))
    
    sim$ras[]<-pixels_fire$pixelid
    #sim$rasVelo<-velox::velox(sim$ras)
    
    #Add the raster_info
    ras.extent<-terra::ext(sim$ras)
    
    message(print(ras.extent))
    
    browser()
    print( paste0("INSERT INTO raster_info (name, xmin, xmax, ymin, ymax, ncell, nrow, crs) values ('ras2', ",ras.extent[1],", ",ras.extent[2],", ", ras.extent[3], ", ",ras.extent[4], ", ",ncell(sim$ras), ", ",nrow(sim$ras),", '3005');"))
    #TODO: Hard coded for epsg 3005 need to convert to terra?
    DBI::dbExecute(sim$castordb, paste0("INSERT INTO raster_info (name, xmin, xmax, ymin, ymax, ncell, nrow, crs) values ('ras2', ",ras.extent[1],", ",ras.extent[2],", ", ras.extent[3], ", ",ras.extent[4], ", ",ncell(sim$ras), ", ",nrow(sim$ras),", '3005');"))
    
  }else{ #Set the empty table for values not supplied in the parameters
    
    message('.....compartment ids: default 1')
    
    sim$extent[[3]]<-sim$extent[[3]] + 1170000
    sim$extent[[4]]<-sim$extent[[4]]*sim$extent[[1]] + 1170000
    sim$extent[[5]]<-sim$extent[[5]] + 834000
    sim$extent[[6]]<-sim$extent[[6]]*sim$extent[[2]] + 834000
    
    randomRas<-randomRaster(sim$extent, P(sim, 'randomLandscapeClusterLevel', 'fireCastor'))
    
    sim$pts <- data.table(terra::xyFromCell(randomRas,1:length(randomRas[]))) #Seems to be faster than rasterTopoints
    sim$pts <- sim$pts[, pixelid:= seq_len(.N)] # add in the pixelid which streams data in according to the cell number = pixelid
    
    pixels_fire <- data.table(age = as.integer(round(randomRas[]*200,0)))
    pixels_fire[, pixelid := seq_len(.N)]
    pixels_fire[, compartid := 'all']
    
    #Add the raster_info
    ras.extent<-terra::ext(randomRas)
    sim$ras<-terra::rast(nrows = sim$extent[[1]], ncols = sim$extent[[2]], xmin = sim$extent[[3]], xmax = sim$extent[[4]], ymin = sim$extent[[5]], ymax = sim$extent[[6]], vals = 0 )
    terra::crs(sim$ras)<-paste0("EPSG:3005") #set the raster projection
    sim$ras[]<-pixels_fire$pixelid
    
    #upload raster metadata
    dbExecute(sim$castordb, glue::glue("INSERT INTO raster_info (name, xmin, xmax, ymin, ymax, ncell, nrow, crs) values ('ras', {ras.extent[1]}, {ras.extent[2]}, {ras.extent[3]}, {ras.extent[4]}, {ncell(sim$ras)}, {nrow(sim$ras)}, '3005');"))
    
  }
  
  aoi<-terra::ext(sim$ras) #need to check that each of the extents are the same
  
  #---------------#
  #Set the FRT----
  #---------------#
  if(!(P(sim, "nameFrtRaster", "fireCastor") == "99999")){
    message(paste0('.....frt: ',P(sim, "nameFrtRaster", "fireCastor")))
    ras.frt<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                       srcRaster= P(sim, "nameFrtRaster", "fireCastor"), 
                                       clipper=sim$boundaryInfo[[1]], 
                                       geom= sim$boundaryInfo[[4]], 
                                       where_clause =  paste0(sim$boundaryInfo[[3]]),
                                       conn=NULL))
    if(aoi == terra::ext(ras.frt)){#need to check that each of the extents are the same
      pixels_fire<-cbind(pixels_fire, data.table(frt=as.numeric(ras.frt[])))
      
      message(print(pixels_fire))
      rm(ras.frt)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameFrtRaster", "fireCastor")))
    }
    
  }else{
    message('.....frt: default 1')
    pixels_fire[!is.na(compartid), frt := 1]
  } 
  
  
  #---------------#
  #Set the elevation----
  #---------------#
  if(!(P(sim, "namesDemRast", "fireCastor") == "99999")){
    message(paste0('.....dem: ',P(sim, "namesDemRast", "fireCastor")))
    ras.dem<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                       srcRaster= P(sim, "namesDemRast", "fireCastor"), 
                                       clipper=sim$boundaryInfo[[1]], 
                                       geom= sim$boundaryInfo[[4]], 
                                       where_clause =  paste0(sim$boundaryInfo[[3]]),
                                       conn=NULL))
    if(aoi == terra::ext(ras.dem)){#need to check that each of the extents are the same
      pixels_fire<-cbind(pixels_fire, data.table(dem=as.numeric(ras.dem[])))
      rm(ras.dem)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "namesDemRast", "fireCastor")))
    }
    
  }else{
    message('.....dem: default 0')
    pixels_fire[!is.na(compartid), dem := 0]
  } 
  
  #---------------#
  #Set the slope----
  #---------------#
  if(!(P(sim, "namesSlopeRast", "fireCastor") == "99999")){
    message(paste0('.....slope: ',P(sim, "namesSlopeRast", "fireCastor")))
    ras.slope<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                         srcRaster= P(sim, "namesSlopeRast", "fireCastor"), 
                                         clipper=sim$boundaryInfo[[1]], 
                                         geom= sim$boundaryInfo[[4]], 
                                         where_clause =  paste0(sim$boundaryInfo[[3]]),
                                         conn=NULL))
    if(aoi == terra::ext(ras.slope)){#need to check that each of the extents are the same
      pixels_fire<-cbind(pixels_fire, data.table(slope=as.numeric(ras.slope[])))
      rm(ras.slope)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "namesSlopeRast", "fireCastor")))
    }
    
  }else{
    message('.....slope: default 0')
    pixels_fire[!is.na(compartid), slope := 0]
  } 
  
  #---------------#
  #Set the aspect----
  #---------------#
  if(!(P(sim, "namesAspectRast", "fireCastor") == "99999")){
    message(paste0('.....aspect: ',P(sim, "namesAspectRast", "fireCastor")))
    ras.aspect<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                          srcRaster= P(sim, "namesAspectRast", "fireCastor"), 
                                          clipper=sim$boundaryInfo[[1]], 
                                          geom= sim$boundaryInfo[[4]], 
                                          where_clause =  paste0(sim$boundaryInfo[[3]]),
                                          conn=NULL))
    if(aoi == terra::ext(ras.aspect)){#need to check that each of the extents are the same
      pixels_fire<-cbind(pixels_fire, data.table(aspect=as.numeric(ras.aspect[])))
      rm(ras.aspect)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "namesAspectRast", "fireCastor")))
    }
    
  }else{
    message('.....aspect: default 0')
    pixels_fire[!is.na(compartid), aspect := 0]
  } 
  
  
  #--------------------------------------#
  #Set the distance to Infrastructure----
  #--------------------------------------#
  if(!(P(sim, "namesInfrastructureRast", "fireCastor") == "99999")){
    message(paste0('..........distanceInfrastructure: ',P(sim, "namesInfrastructureRast", "fireCastor")))
    ras.infra<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                         srcRaster= P(sim, "namesInfrastructureRast", "fireCastor"), 
                                         clipper=sim$boundaryInfo[[1]], 
                                         geom= sim$boundaryInfo[[4]], 
                                         where_clause =  paste0(sim$boundaryInfo[[3]]),
                                         conn=NULL))
    if(aoi == terra::ext(ras.infra)){#need to check that each of the extents are the same
      pixels_fire<-cbind(pixels_fire, data.table(distinfra=as.numeric(ras.infra[])))
      rm(ras.infra)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "namesInfrastructureRast", "fireCastor")))
    }
    
  }else{
    message('.....distanceInfrastructure: default 1')
    pixels_fire[!is.na(compartid), distinfra := 1]
  } 
  
  #---------------#
  #Set the summer wind----
  #---------------#
  if(!(P(sim, "namesSummerWindRast", "fireCastor") == "99999")){
    message(paste0('.....summerwind: ',P(sim, "namesSummerWindRast", "fireCastor")))
    ras.summerwind<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                              srcRaster= P(sim, "namesSummerWindRast", "fireCastor"), 
                                              clipper=sim$boundaryInfo[[1]], 
                                              geom= sim$boundaryInfo[[4]], 
                                              where_clause =  paste0(sim$boundaryInfo[[3]]),
                                              conn=NULL))
    if(aoi == terra::ext(ras.summerwind)){#need to check that each of the extents are the same
      pixels_fire<-cbind(pixels_fire, data.table(summerwind=as.numeric(ras.summerwind[])))
      rm(ras.summerwind)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "namesSummerWindRast", "fireCastor")))
    }
    
  }else{
    message('.....summerwind: default 0')
    pixels_fire[!is.na(compartid), summerwind := 0]
  }   
  
  #---------------#
  #Set the spring wind----
  #---------------#
  if(!(P(sim, "namesSpringWindRast", "fireCastor") == "99999")){
    message(paste0('.....springwind: ',P(sim, "namesSpringWindRast", "fireCastor")))
    ras.springwind<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                              srcRaster= P(sim, "namesSpringWindRast", "fireCastor"), 
                                              clipper=sim$boundaryInfo[[1]], 
                                              geom= sim$boundaryInfo[[4]], 
                                              where_clause =  paste0(sim$boundaryInfo[[3]]),
                                              conn=NULL))
    if(aoi == terra::ext(ras.springwind)){#need to check that each of the extents are the same
      pixels_fire<-cbind(pixels_fire, data.table(springwind=as.numeric(ras.springwind[])))
      rm(ras.springwind)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "namesSpringWindRast", "fireCastor")))
    }
    
  }else{
    message('.....springwind: default 0')
    pixels_fire[!is.na(compartid), springwind := 0]
  } 
  
  #-----------------------------#
  #Load the pixels_fire in RSQLite----
  #-----------------------------#
  
  dbBegin(castordb)
  rs<-dbSendQuery(castordb, "INSERT INTO pixels_fire (pixelid, compartid, frt, dem, slope, aspect, distinfrastructure, springwind, summerwind) 
                      values (:pixelid, :compartid, :frt, :dem, :slope, :aspect, :distinfrastructure, :springwind, :summerwind)", pixels_fire)
  dbClearResult(rs)
  dbCommit(castordb)
  
  
  rm(pixels_fire)
  gc()
  return(invisible(sim))
}

setIndexesCastorDB <- function(sim) { # making indexes helps with query speed for future querying
  dbExecute(sim$castordb, "CREATE UNIQUE INDEX index_pixelid on pixels_fire (pixelid);")
  
  dbExecute(sim$castordb, "VACUUM;")
  message('...done')
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


