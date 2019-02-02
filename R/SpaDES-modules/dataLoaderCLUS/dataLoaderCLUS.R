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
  reqdPkgs = list("sf", "rpostgis"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "numeric", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant"),
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
    defineParameter("nameCompartmentRaster", "character", "99999", NA, NA, desc = "Name of the raster in a pg db that represtents a compartment or supply block")
    ),
  inputObjects = bind_rows(
    #expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput("nameBoundaryFile", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundary", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundaryColumn", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundaryGeom", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameCompartmentRaster", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameZoneRaster", objectClass ="character", desc = NA, sourceURL = NA)
  ),
  outputObjects = bind_rows(
    createsOutput("boundaryInfo", objectClass ="character", desc = NA),
    createsOutput("bbox", objectClass ="numeric", desc = NA),
    createsOutput("boundary", objectClass ="sf", desc = NA),
    createsOutput("clusdb", objectClass ="SQLiteConnection", desc = "A rsql database that stores, organizes and manipulates clus realted information")
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
      sim<-dataLoaderCLUS.setCLUSdb(sim)
      
      },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

dataLoaderCLUS.createCLUSdb <- function(sim) {
  #build the clusdb - a realtional database that tracks the interactions between spatial and temporal objectives
  sim$clusdb <- dbConnect(RSQLite::SQLite(), ":memory:") #builds the db in memory; also resets any existing db!
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS indicators (id integer PRIMARY KEY, year integer, schedHarvestFlow numeric, simHarvestFlow numeric, schedHarvestArea numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS compartment ( compartid integer PRIMARY KEY, tsa_number integer, zoneID integer, active integer, allocation numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS blocks ( blockID integer PRIMARY KEY, zoneID integer, yieldID integer, active integer, state integer, adjID integer, age integer, area numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS adjacentBlocks ( id integer PRIMARY KEY, adjblockID integer, blocks integer)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS yields ( id integer PRIMARY KEY, yieldID integer, age integer, volume numeric, crowncover numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS adjacentblocks ( id integer PRIMARY KEY, adjblockID integer, blockID integer)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS zone (zoneid integer PRIMARY KEY, constraintID integer, oldgrowth numeric, earlyseral numeric, crowncover numeric, roaddensity numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS constraints ( constraintid integer PRIMARY KEY, fromage integer, toage integer, minvalue numeric, maxvalue numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS pixels ( pixelid integer PRIMARY KEY, compartid integer, zoneid integer, blockid integer )")
  return(invisible(sim))
}

dataLoaderCLUS.setCLUSdb <- function(sim) {
  
  if(!(P(sim, "dataLoaderCLUS", "nameZoneRaster") = "99999" & P(sim, "dataLoaderCLUS", "nameCompartmentRaster") = "99999")){
    #clip the boundary with the provincial similarity raste
    conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
    geom<-dbGetQuery(conn, paste0("SELECT ST_ASTEXT(ST_TRANSFORM(ST_Force2D(ST_UNION(GEOM)), 4326)) FROM ", P(sim, "dataLoaderCLUS", "nameBoundaryFile")," WHERE ",P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " = '",  P(sim, "dataLoaderCLUS", "nameBoundary"), "';"))
    ras.zone<-RASTER_CLIP(srcRaster= P(sim, "blockingCLUS", "nameZoneRaster"), clipper=geom, conn=conn)
    dbDisconnect(conn)

    conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
    geom<-dbGetQuery(conn, paste0("SELECT ST_ASTEXT(ST_TRANSFORM(ST_Force2D(ST_UNION(GEOM)), 4326)) FROM ", P(sim, "dataLoaderCLUS", "nameBoundaryFile")," WHERE ",P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " = '",  P(sim, "dataLoaderCLUS", "nameBoundary"), "';"))
    ras.compartment<-RASTER_CLIP(srcRaster= P(sim, "blockingCLUS", "nameCompartmentRaster"), clipper=geom, conn=conn)
    dbDisconnect(conn)
    
    pixels<-data.table(cbind(c(t(raster::as.matrix(ras.zone))),c(t(raster::as.matrix(ras.compartment))))) #transpose then vectorize which matches the same order as adj
    pixels[, id := seq_len(.N)]
    
    dbBegin(clusdb)
      rs<-dbSendQuery(clusdb, 'INSERT INTO pixels (pixelid, compartid, zoneid) values (:id, pixel )', pixels )
      dbClearResult(rs)
    dbCommit(clusdb)
    
    rm(ras.zone)
    
  }else{
    pixels<-data.table(c(t(raster::as.matrix(sim$boundary)))) #transpose then vectorize which matches the same order as adj
    pixels[, id := seq_len(.N)]
    
    dbBegin(clusdb)
      rs<-dbSendQuery(clusdb, 'INSERT INTO pixels (pixelid, compartid, zoneid) values (:id, 1, 1 )', pixels )
      dbClearResult(rs)
    dbCommit(clusdb)
  }

  rm(pixels)
  gc()
  
  return(invisible(sim))
}
.inputObjects <- function(sim) {
  bio_old<-data.frame(
    nat = c(1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3,3,3),
    bec =c('CWH', 'ICH', 'ESSF', "MH", 'CWH', 'CDF', 'ICH', 'SBS', 'ESSF', 'SWB', 'BWBS', 'SBPS', 'BWBS', 'SBS', 'MS', 'ESSF', 'ICH', 'CWH', 'ICH', 'IDF', 'PP'),
    Age = c(250,250,250,250, 250, 250, 250, 250,250,250,140,140,140,140,140,140,140,140, 250,250,250),
    low = c(13,13,19,19, 9,9,9,9,9,9,13,7,11,11,14,14,14,11, 13,13,13),
    intermediate = c(13,13,19,19, 9,9,9,9,9,9,13,7,11,11,14,14,14,11, 13,13,13),
    high = c(19,19,28,28,13,13,13,13,13,13,19,10,16,16,21,21,21,16,19,19,19)
  ) 
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

