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
    defineParameter("nameZoneRasters", "character", "99999", NA, NA, desc = "Name of the raster in a pg db that represents a zone"),
    defineParameter("nameCompartmentRaster", "character", "99999", NA, NA, desc = "Name of the raster in a pg db that represtents a compartment or supply block"),
    defineParameter("nameMaskHarvestLandbaseRaster", "character", "99999", NA, NA, desc = "Name of the raster representing THLB"),
    defineParameter("nameYieldsRaster", "character", "99999", NA, NA, desc = "Name of the raster representing yield ids"),
    defineParameter("nameAgeRaster", "character", "99999", NA, NA, desc = "Name of the raster represnting pixel age"),
    defineParameter("nameCrownClosureRaster", "character", "99999", NA, NA, desc = "Name of the raster representing pixel crown closure"),
    defineParameter("nameHeightRaster", "character", "99999", NA, NA, desc = "Name of the raster representing pixel height")
    ),
  inputObjects = bind_rows(
    #expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput("nameBoundaryFile", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundary", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundaryColumn", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundaryGeom", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameCompartmentRaster", objectClass ="character" , desc = "Administrative boundary for forest compartments or supply blocks", sourceURL = NA),
    expectsInput("nameZoneRasters", objectClass ="list", desc = "Administrative boundary containing zones of management objectives", sourceURL = NA),
    expectsInput("nameMaskHarvestLandbaseRaster", objectClass ="character", desc = "Administrative boundary related to operability of the the timber harvesting landbase. This mask is between 0 and 1, representing where its feasible to harvest", sourceURL = NA),
    expectsInput("nameYieldsRaster", objectClass ="character", desc = "Raster containing yield ids. These ids connect to the yields table", sourceURL = NA),
    expectsInput("nameAgeRaster", objectClass ="character", desc = "Raster containing pixel age. Note this references the yield table. Thus, could be initially 0 if the yield curves reflect the age at 0 on the curve", sourceURL = NA),
    expectsInput("nameCrownClosureRaster", objectClass ="character", desc = "Raster containing pixel crown closure. Note this could be a raster using VCF:http://glcf.umd.edu/data/vcf/", sourceURL = NA),
    expectsInput("nameHeightRaster", objectClass ="character", desc = "Raster containing pixel height. EX. Canopy height model", sourceURL = NA)
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
      sim <- scheduleEvent(sim, eventTime = end(sim),  "dataLoaderCLUS", "removeDbCLUS", eventPriority=99)
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
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS indicators (id integer PRIMARY KEY, year integer, schedHarvestflow numeric, simharvestflow numeric, schedharvestarea numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS compartment ( compartid integer PRIMARY KEY, tsa_number integer, zoneid integer, active integer, allocation numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS blocks ( blockid integer PRIMARY KEY, zoneid integer, state integer, regendelay integer, age integer, area numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS adjacentblocks ( id integer PRIMARY KEY, adjblockid integer, blockid integer)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS yields ( id integer PRIMARY KEY, yieldid integer, age integer, volume numeric, crownclosure numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS zone (zoneid integer PRIMARY KEY, compartid integer, oldgrowth numeric, earlyseral numeric, crownclosure numeric, roaddensity numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS constraints ( id integer PRIMARY KEY, zoneid integer, constraintsid integer, fromage integer, toage integer, minvalue numeric, maxvalue numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS pixels ( pixelid integer PRIMARY KEY, compartid integer, blockid integer, yieldid integer, thlb numeric , age numeric, crownclosure numeric, height numeric, roadyear integer)")
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
    sim$ras<-RASTER_CLIP2(srcRaster= P(sim, "dataLoaderCLUS", "nameCompartmentRaster"), clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", P(sim, "dataLoaderCLUS", "nameBoundary"),"'')"), conn=conn)
    dbDisconnect(conn)
    pixels<-data.table(c(t(raster::as.matrix(sim$ras))))
    pixels[, pixelid := seq_len(.N)]
    setnames(pixels, "V1", "compartid")
    sim$ras[]<-unlist(pixels[,2], use.names = FALSE)
    
  }else{
    print('.....compartment ids: default 1')
    #Set the empty table for values not supplied in the parmaters
    conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
    sim$ras<-RASTER_CLIP2(srcRaster= 'rast.bc_bound', clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", P(sim, "dataLoaderCLUS", "nameBoundary"),"'')"), conn=conn)
    dbDisconnect(conn)
    pixels<-data.table(c(t(raster::as.matrix(sim$ras)))) #transpose then vectorize which matches the same order as adj
    pixels[, pixelid := seq_len(.N)]
    pixels[, compartid := 1]
    pixels<-pixels[,2:3]
    sim$ras[]<-unlist(pixels[,"pixelid"], use.names = FALSE)
    sim$rasVelo<-velox::velox(sim$ras)
  }
  
  #----------------
  #Set the zone IDs
  #----------------
  print(P(sim, "dataLoaderCLUS", "nameZoneRasters"))
  if(!(P(sim, "dataLoaderCLUS", "nameZoneRasters")[1] == "99999")){ 
    print(paste0('.....zones: ',length(P(sim, "dataLoaderCLUS", "nameZoneRasters"))))
    #TODO: Need to add multiple zone columns - each will have its own raster. Attributed to that raster is a table of the thresholds by zone
    for(i in 1:length(P(sim, "dataLoaderCLUS", "nameZoneRasters"))){
      conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
      ras.zone<-RASTER_CLIP2(srcRaster= P(sim, "dataLoaderCLUS", "nameZoneRasters")[i], clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", P(sim, "dataLoaderCLUS", "nameBoundary"),"'')"), conn=conn)
      dbDisconnect(conn)
      
      pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.zone)))))
      setnames(pixels, "V1", paste0('zone',i))#SET NAMES to RASTER layer
      dbExecute(sim$clusdb, paste0('ALTER TABLE pixels ADD COLUMN zone', i,' numeric'))
    }
    rm(ras.zone)
    gc()
    qry<- paste0('INSERT INTO pixels (pixelid, compartid, yieldid, thlb, age, crownclosure, height, roadyear, zone',
                 paste(as.character(seq(1:length(P(sim, "dataLoaderCLUS", "nameZoneRasters")))), sep="' '", collapse=", zone"),') 
                values (:pixelid, :compartid, :yieldid, :thlb, :age, :crownclosure, :height, NULL, :zone', 
                 paste(as.character(seq(1:length(P(sim, "dataLoaderCLUS", "nameZoneRasters")))), sep="' '", collapse=", :zone"),')')
   
  } else{
    print('.....zone ids: default 1')
    pixels[, zone1:= 1]
    qry<- paste0('INSERT INTO pixels (pixelid, compartid, yieldid, thlb, age, crownclosure, height, roadyear, zone1) 
                values (:pixelid, :compartid, :yieldid, :thlb, :age, :crownclosure, :height, NULL, :zone1)')
    dbExecute(sim$clusdb, "ALTER TABLE pixels ADD COLUMN zone1 numeric")
    }

  #------------
  #Set the THLB
  #------------
  if(!(P(sim, "dataLoaderCLUS", "nameMaskHarvestLandbaseRaster") == "99999")){
    print(paste0('.....thlb: ',P(sim, "dataLoaderCLUS", "nameMaskHarvestLandbaseRaster")))
    
    conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
    ras.thlb<- RASTER_CLIP2(srcRaster= P(sim, "dataLoaderCLUS", "nameMaskHarvestLandbaseRaster"), clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", P(sim, "dataLoaderCLUS", "nameBoundary"),"'')"), conn=conn)
    dbDisconnect(conn)
    pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.thlb)))))
    setnames(pixels, "V1", "thlb")
    
    rm(ras.thlb)
    gc()
    
  }else{
    print('.....thlb: default 1')
    pixels[, thlb := 1]
  }
  
  #-----------------
  #Set the Yield IDS
  #-----------------
  if(!(P(sim, "dataLoaderCLUS", "nameYieldsRaster") == "99999")){
    print(paste0('.....yield ids: ',P(sim, "dataLoaderCLUS", "nameYieldsRaster")))
    conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
    ras.ylds<-RASTER_CLIP2(srcRaster= P(sim, "dataLoaderCLUS", "nameYieldsRaster"), clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", P(sim, "dataLoaderCLUS", "nameBoundary"),"'')"), conn=conn)
    dbDisconnect(conn)
    pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.ylds)))))
    setnames(pixels, "V1", "yieldid")
    rm(ras.ylds)
    gc()
    
  }else{
    print('.....yield ids: default 1')
    pixels[, yieldid := 1]
  }
  
  #-----------
  #Set the Age 
  #-----------
  if(!(P(sim, "dataLoaderCLUS", "nameAgeRaster") == "99999")){
    print(paste0('.....age: ',P(sim, "dataLoaderCLUS", "nameAgeRaster")))
    conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
    ras.age<-RASTER_CLIP2(srcRaster= P(sim, "dataLoaderCLUS", "nameAgeRaster"), clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", P(sim, "dataLoaderCLUS", "nameBoundary"),"'')"), conn=conn)
    dbDisconnect(conn)
    pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.age)))))
    setnames(pixels, "V1", "age")
    rm(ras.age)
    gc()
  }else{
    print('.....age: default 120')
    pixels[, age := 120]
  }
  
  #---------------------
  #Set the Crown Closure 
  #---------------------
  if(!(P(sim, "dataLoaderCLUS", "nameCrownClosureRaster") == "99999")){
    print(paste0('.....age: ',P(sim, "dataLoaderCLUS", "nameCrownClosureRaster")))
    conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
    ras.cc<-RASTER_CLIP2(srcRaster=P(sim, "dataLoaderCLUS", "nameCrownClosureRaster"), clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", P(sim, "dataLoaderCLUS", "nameBoundary"),"'')"), conn=conn)
    dbDisconnect(conn)
    pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.cc)))))
    setnames(pixels, "V1", "crownclosure")
    
    rm(ras.cc)
    gc()
    
  }else{
    print('.....crown closure: default 60')
    pixels[, crownclosure := 60]
  }
  #---------------------
  #Set the Height 
  #---------------------
  if(!(P(sim, "dataLoaderCLUS", "nameHeightRaster") == "99999")){
    print(paste0('.....age: ',P(sim, "dataLoaderCLUS", "nameHeightRaster")))
    conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
    ras.ht<-RASTER_CLIP2(srcRaster=P(sim, "dataLoaderCLUS", "nameHeightRaster"), clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", P(sim, "dataLoaderCLUS", "nameBoundary"),"'')"), conn=conn)
    dbDisconnect(conn)
    pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.ht)))))
    setnames(pixels, "V1", "height")
    
    rm(ras.ht)
    gc()
    
  }else{
    print('.....height: default 10')
    pixels[, height := 10]
  }
  

  #------------------------
  #Load the data in Rsqlite
  #------------------------
  dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, qry, pixels )
    dbClearResult(rs)
  dbCommit(sim$clusdb)

  rm(pixels)
  gc()
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

