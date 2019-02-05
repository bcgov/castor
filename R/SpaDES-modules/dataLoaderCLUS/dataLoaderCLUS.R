# Copyright 2018 Province of British Columbia
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
              person("Tyler", "Muhley", email = "tyler.muhley@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.1.1", dataLoaderCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "dataLoaderCLUS.Rmd"),
  reqdPkgs = list("sf", "rpostgis","DBI", "RSQLite"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "numeric", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant"),
    defineParameter("startTime", "numeric", start(sim), NA, NA, desc = "Simulation time at which to start"),
    defineParameter("endTime", "numeric", end(sim), NA, NA, desc = "Simulation time at which to end"),
    defineParameter("dbName", "character", "postgres", NA, NA, "The name of the postgres dataabse"),
    defineParameter("dbHost", "character", 'localhost', NA, NA, "The name of the postgres host"),
    defineParameter("dbPort", "character", '5432', NA, NA, "The name of the postgres port"),
    defineParameter("dbUser", "character", 'postgres', NA, NA, "The name of the postgres user"),
    defineParameter("dbPassword", "character", 'postgres', NA, NA, "The name of the postgres user password"),
    defineParameter("nameBoundaryFile", "character", "gcbp_carib_polygon", NA, NA, desc = "Name of the boundary file"),
    defineParameter("nameBoundaryColumn", "character", "herd_name", NA, NA, desc = "Name of the column within the boundary file that has the boundary name"),
    defineParameter("nameBoundary", "character", "Muskwa", NA, NA, desc = "Name of the boundary - a spatial polygon within the boundary file"),
    defineParameter("nameBoundaryGeom", "character", "geom", NA, NA, desc = "Name of the geom column in the boundary file"),
    defineParameter("nameZoneRaster", "character", "99999", NA, NA, desc = "Name of the raster in a pg db that represents a zone"),
    defineParameter("nameCompartmentRaster", "character", "99999", NA, NA, desc = "Name of the raster in a pg db that represtents a compartment or supply block"),
    defineParameter("nameMaskHarvestLandbaseRaster", "character", "99999", NA, NA, desc = "Name of the raster representing THLB"),
    defineParameter("nameYieldsRaster", "character", "99999", NA, NA, desc = "Name of the raster representing yield ids"),
    defineParameter("nameAgeRaster", "character", "99999", NA, NA, desc = "Name of the raster represnting pixel age"),
    defineParameter("nameCrownClosureRaster", "character", "99999", NA, NA, desc = "Name of the raster representing pixel crown closure")
    ),
  inputObjects = bind_rows(
    #expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput("nameBoundaryFile", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundary", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundaryColumn", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundaryGeom", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameCompartmentRaster", objectClass ="character" , desc = "Administrative boundary for forest compartments or supply blocks", sourceURL = NA),
    expectsInput("nameZoneRaster", objectClass ="character", desc = "Administrative boundary containing zones of management objectives", sourceURL = NA),
    expectsInput("nameMaskHarvestLandbaseRaster", objectClass ="character", desc = "Administrative boundary related to operability of the the timber harvesting landbase. This mask is between 0 and 1, representing where its feasible to harvest", sourceURL = NA),
    expectsInput("nameYieldsRaster", objectClass ="character", desc = "Biophysical boundary containing yield ids. These ids connect to the yields table", sourceURL = NA),
    expectsInput("nameAgeRaster", objectClass ="character", desc = "Biophysical boundary containing pixel age. Note this references the yield table. Thus, could be initially 0 if the yield curves reflect the age at 0 on the curve", sourceURL = NA),
    expectsInput("nameCrownClosureRaster", objectClass ="character", desc = "Biophysical boundary containing pixel crown closure. Note this could be a raster using VCF:http://glcf.umd.edu/data/vcf/", sourceURL = NA)
     ),
  outputObjects = bind_rows(
    createsOutput("boundaryInfo", objectClass ="character", desc = NA),
    createsOutput("bbox", objectClass ="numeric", desc = NA),
    createsOutput("boundary", objectClass ="sf", desc = NA),
    createsOutput("clusdb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates clus realted information")
  )
))

doEvent.dataLoaderCLUS = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    init = {
      #build clusdb
      sim<-dataLoaderCLUS.createCLUSdb(sim)
      #setBoundaries
      sim$boundary<-getSpatialQuery(paste0("SELECT * FROM ",  P(sim, "dataLoaderCLUS", "nameBoundaryFile"), " WHERE ",   P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), "= '",  P(sim, "dataLoaderCLUS", "nameBoundary"),"';" ))
      sim$bbox<-st_bbox(sim$boundary)
      sim$boundaryInfo <- c(P(sim, "dataLoaderCLUS", "nameBoundaryFile"),P(sim, "dataLoaderCLUS", "nameBoundaryColumn"),P(sim, "dataLoaderCLUS", "nameBoundary"), P(sim, "dataLoaderCLUS", "nameBoundaryGeom"))
      #populate clusdb tables
      sim<-dataLoaderCLUS.setTablesCLUSdb(sim)
      
      #disconnect the db once the sim is over?
      sim <- scheduleEvent(sim, eventTime = end(sim),  "dataLoaderCLUS", "removeDbCLUS")
      },
    removeDbCLUS={
      sim<-disconnectDbCLUS(sim)
      
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}
disconnectDbCLUS<- function(sim) {
  dbDisconnect(sim$clusdb)
  return(invisible(sim))
}
dataLoaderCLUS.createCLUSdb <- function(sim) {
  print ('create clusdb')
  #build the clusdb - a realtional database that tracks the interactions between spatial and temporal objectives
  sim$clusdb <- dbConnect(RSQLite::SQLite(), ":memory:") #builds the db in memory; also resets any existing db! Can be set to store on disk
  #dbExecute(sim$clusdb, "PRAGMA foreign_keys = ON;") #Turns the foreign key constraints on. 
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS indicators (id integer PRIMARY KEY, year integer, schedHarvestFlow numeric, simHarvestFlow numeric, schedHarvestArea numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS compartment ( compartid integer PRIMARY KEY, tsa_number integer, zoneid integer, active integer, allocation numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS blocks ( blockID integer PRIMARY KEY, zoneid integer, yieldid integer, active integer, state integer, adjid integer, age integer, area numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS adjacentBlocks ( id integer PRIMARY KEY, adjblockid integer, blocks integer)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS yields ( id integer PRIMARY KEY, yieldid integer, age integer, volume numeric, crownclosure numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS zone (zoneid integer PRIMARY KEY, constraintid integer, oldgrowth numeric, earlyseral numeric, crownclosure numeric, roaddensity numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS constraints ( constraintid integer PRIMARY KEY, fromage integer, toage integer, minvalue numeric, maxvalue numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS pixels ( pixelid integer PRIMARY KEY, compartid integer, zoneid integer, blockid integer, yieldid integer, thlb numeric , age numeric, crownclosure numeric, roadyear integer)")
  return(invisible(sim))
}

dataLoaderCLUS.setTablesCLUSdb <- function(sim) {
  print('...setting data tables')
  #-----------------------
  #Set the compartment IDS
  #-----------------------
  if(!(P(sim, "dataLoaderCLUS", "nameCompartmentRaster") == "99999")){
    print(paste0('.....compartment ids: ', P(sim, "dataLoaderCLUS", "nameCompartmentRaster")))
    conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
    geom<-dbGetQuery(conn, paste0("SELECT ST_ASTEXT(ST_TRANSFORM(ST_Force2D(ST_UNION(GEOM)), 4326)) FROM ", P(sim, "dataLoaderCLUS", "nameBoundaryFile")," WHERE ",P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " = '",  P(sim, "dataLoaderCLUS", "nameBoundary"), "';"))
    ras.compartment<-RASTER_CLIP(srcRaster= P(sim, "blockingCLUS", "nameCompartmentRaster"), clipper=geom, conn=conn)
    dbDisconnect(conn)
    
    pixels<-data.table(c(t(raster::as.matrix(ras.compartment))))
    
    dbBegin(sim$clusdb)
      rs<-dbSendQuery(sim$clusdb, 'INSERT INTO pixels (compartid) values ( :V1 )', pixels )
      dbClearResult(rs)
    dbCommit(sim$clusdb)
    
    rm(ras.compartment)
    gc()
    
  }else{
    print('.....compartment ids: default 1')
    #Set the empty table for values not supplied in the parmaters
    pixelsEmpty<-data.table(c(t(raster::as.matrix(sim$boundary)))) #transpose then vectorize which matches the same order as adj
    pixelsEmpty[, id := seq_len(.N)]
    
    dbBegin(sim$clusdb) 
      rs<-dbSendQuery(sim$clusdb, 'INSERT INTO pixels (pixelid, compartid) values (:id, 1 )', pixelsEmpty[,2]) #Assigns a default of 1 to every pixel
      dbClearResult(rs)
    dbCommit(sim$clusdb)
  }
  
  #----------------
  #Set the zone IDs
  #----------------
  if(!(P(sim, "dataLoaderCLUS", "nameZoneRaster") == "99999")){ 
    print(paste0('.....zone ids: ',P(sim, "dataLoaderCLUS", "nameZoneRaster")))
    conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
    geom<-dbGetQuery(conn, paste0("SELECT ST_ASTEXT(ST_TRANSFORM(ST_Force2D(ST_UNION(GEOM)), 4326)) FROM ", P(sim, "dataLoaderCLUS", "nameBoundaryFile")," WHERE ",P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " = '",  P(sim, "dataLoaderCLUS", "nameBoundary"), "';"))
    ras.zone<-RASTER_CLIP(srcRaster= P(sim, "blockingCLUS", "nameZoneRaster"), clipper=geom, conn=conn)
    dbDisconnect(conn)
    
    pixels<-data.table(c(t(raster::as.matrix(ras.zone))))
    
    dbBegin(sim$clusdb)
      rs<-dbSendQuery(sim$clusdb, 'INSERT INTO pixels ( zoneid ) values ( :V1 )', pixels )
      dbClearResult(rs)
    dbCommit(sim$clusdb)
    
    rm(ras.zone)
    gc()
    
  } else{
    print('.....zone ids: default 1')
    dbBegin(sim$clusdb) #Note dbExecute() could be used but returns the number of records updated.
      rs<-dbSendQuery(sim$clusdb, 'UPDATE pixels set zoneid = 1')
      dbClearResult(rs)
    dbCommit(sim$clusdb)
  }

  #------------
  #Set the THLB
  #------------
  if(!(P(sim, "dataLoaderCLUS", "nameMaskHarvestLandbaseRaster") == "99999")){
    print(paste0('.....thlb: ',P(sim, "dataLoaderCLUS", "nameMaskHarvestLandbaseRaster")))
    conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
    geom<-dbGetQuery(conn, paste0("SELECT ST_ASTEXT(ST_TRANSFORM(ST_Force2D(ST_UNION(GEOM)), 4326)) FROM ", P(sim, "dataLoaderCLUS", "nameBoundaryFile")," WHERE ",P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " = '",  P(sim, "dataLoaderCLUS", "nameBoundary"), "';"))
    ras.thlb<-RASTER_CLIP(srcRaster= P(sim, "blockingCLUS", "nameMaskHarvestLandbaseRaster"), clipper=geom, conn=conn)
    dbDisconnect(conn)
    
    pixels<-data.table(c(t(raster::as.matrix(ras.thlb))))
    
    dbBegin(sim$clusdb)
      rs<-dbSendQuery(sim$clusdb, 'INSERT INTO pixels (thlb) values ( :V1 )', pixels )
      dbClearResult(rs)
    dbCommit(sim$clusdb)
    
    rm(ras.thlb)
    gc()
    
  }else{
    print('.....thlb: default 1')
    dbBegin(sim$clusdb)
      rs<-dbSendQuery(sim$clusdb, 'Update pixels SET thlb = 1') #Assigns a 1 for every pixel - meaning available for harvest
      dbClearResult(rs)
    dbCommit(sim$clusdb)
  }
  
  #-----------------
  #Set the Yield IDS
  #-----------------
  if(!(P(sim, "dataLoaderCLUS", "nameYieldsRaster") == "99999")){
    print(paste0('.....yield ids: ',P(sim, "dataLoaderCLUS", "nameYieldsRaster")))
    conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
    geom<-dbGetQuery(conn, paste0("SELECT ST_ASTEXT(ST_TRANSFORM(ST_Force2D(ST_UNION(GEOM)), 4326)) FROM ", P(sim, "dataLoaderCLUS", "nameBoundaryFile")," WHERE ",P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " = '",  P(sim, "dataLoaderCLUS", "nameBoundary"), "';"))
    ras.ylds<-RASTER_CLIP(srcRaster= P(sim, "blockingCLUS", "nameYieldsRaster"), clipper=geom, conn=conn)
    dbDisconnect(conn)
    
    pixels<-data.table(c(t(raster::as.matrix(ras.ylds))))
    
    dbBegin(sim$clusdb)
      rs<-dbSendQuery(sim$clusdb, 'INSERT INTO pixels (yieldid) values ( :V1 )', pixels )
      dbClearResult(rs)
    dbCommit(sim$clusdb)
    
    rm(ras.ylds)
    gc()
    
  }else{
    print('.....yield ids: default 1')
    dbBegin(sim$clusdb)
      rs<-dbSendQuery(sim$clusdb, 'Update pixels SET yieldid = 1') #Assigns a 1 for every pixel
      dbClearResult(rs)
    dbCommit(sim$clusdb)
  }
  
  #-----------
  #Set the Age 
  #-----------
  if(!(P(sim, "dataLoaderCLUS", "nameAgeRaster") == "99999")){
    print(paste0('.....age: ',P(sim, "dataLoaderCLUS", "nameAgeRaster")))
    conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
    geom<-dbGetQuery(conn, paste0("SELECT ST_ASTEXT(ST_TRANSFORM(ST_Force2D(ST_UNION(GEOM)), 4326)) FROM ", P(sim, "dataLoaderCLUS", "nameBoundaryFile")," WHERE ",P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " = '",  P(sim, "dataLoaderCLUS", "nameBoundary"), "';"))
    ras.age<-RASTER_CLIP(srcRaster= P(sim, "blockingCLUS", "nameAgeRaster"), clipper=geom, conn=conn)
    dbDisconnect(conn)
    
    pixels<-data.table(c(t(raster::as.matrix(ras.age))))
    
    dbBegin(sim$clusdb)
      rs<-dbSendQuery(sim$clusdb, 'INSERT INTO pixels (age) values ( :V1 )', pixels )
      dbClearResult(rs)
    dbCommit(sim$clusdb)
    
    rm(ras.age)
    gc()
    
  }else{
    print('.....age: default 120')
    dbBegin(sim$clusdb)
      rs<-dbSendQuery(sim$clusdb, 'Update pixels SET age = 120') #Assigns a 0
      dbClearResult(rs)
    dbCommit(sim$clusdb)
  }
  
  #---------------------
  #Set the Crown Closure 
  #---------------------
  if(!(P(sim, "dataLoaderCLUS", "nameCrownClosureRaster") == "99999")){
    print(paste0('.....age: ',P(sim, "dataLoaderCLUS", "nameCrownClosureRaster")))
    conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
    geom<-dbGetQuery(conn, paste0("SELECT ST_ASTEXT(ST_TRANSFORM(ST_Force2D(ST_UNION(GEOM)), 4326)) FROM ", P(sim, "dataLoaderCLUS", "nameBoundaryFile")," WHERE ",P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " = '",  P(sim, "dataLoaderCLUS", "nameBoundary"), "';"))
    ras.cc<-RASTER_CLIP(srcRaster= P(sim, "blockingCLUS", "nameCrownClosureRaster"), clipper=geom, conn=conn)
    dbDisconnect(conn)
    
    pixels<-data.table(c(t(raster::as.matrix(ras.cc))))
    
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, 'INSERT INTO pixels ( crownclosure ) values ( :V1 )', pixels )
    dbClearResult(rs)
    dbCommit(sim$clusdb)
    
    rm(ras.cc)
    gc()
    
  }else{
    print('.....crown closure: default 60')
    dbBegin(sim$clusdb)
      rs<-dbSendQuery(sim$clusdb, 'UPDATE pixels SET crownclosure = 60') #Assigns a 0
      dbClearResult(rs)
    dbCommit(sim$clusdb)
  }
  
  return(invisible(sim))
}

.inputObjects <- function(sim) {

  return(invisible(sim))
}

#Useful functions
getSpatialQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='localhost', dbname = 'clus', port='5432' ,user='app_user' ,password='clus')
  on.exit(dbDisconnect(conn))
  st_read(conn, query = sql)
}

getTableQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='localhost', dbname = 'clus', port='5432' ,user='app_user' ,password='clus')
  on.exit(dbDisconnect(conn))
  dbGetQuery(conn, sql)
}

getRasterQuery<-function(name, bb){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='localhost', dbname = 'clus', port='5432' ,user='app_user' ,password='clus')
  on.exit(dbDisconnect(conn))
  pgGetRast(conn, name, boundary = c(bb[4],bb[2],bb[3],bb[1]))
}

