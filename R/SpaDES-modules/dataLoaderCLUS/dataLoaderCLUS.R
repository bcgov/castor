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
  reqdPkgs = list("sf", "rpostgis","DBI", "RSQLite", "data.table"),
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
    defineParameter("save_clusdb", "logical", FALSE, NA, NA, desc = "Save the db to a file?"),
    defineParameter("useCLUSdb", "character", "99999", NA, NA, desc = "Use an exising db?"),
    defineParameter("nameZoneRasters", "character", "99999", NA, NA, desc = "Administrative boundary containing zones of management objectives"),
    defineParameter("nameCompartmentRaster", "character", "99999", NA, NA, desc = "Name of the raster in a pg db that represtents a compartment or supply block"),
    defineParameter("nameCompartmentTable", "character", "99999", NA, NA, desc = "Name of the table in a pg db that represtents a compartment or supply block value attribute look up"),
    defineParameter("nameMaskHarvestLandbaseRaster", "character", "99999", NA, NA, desc = "Administrative boundary related to operability of the the timber harvesting landbase. This mask is between 0 and 1, representing where its feasible to harvest"),
    defineParameter("nameAgeRaster", "character", "99999", NA, NA, desc = "Raster containing pixel age. Note this references the yield table. Thus, could be initially 0 if the yield curves reflect the age at 0 on the curve"),
    defineParameter("nameCrownClosureRaster", "character", "99999", NA, NA, desc = "Raster containing pixel crown closure. Note this could be a raster using VCF:http://glcf.umd.edu/data/vcf/"),
    defineParameter("nameHeightRaster", "character", "99999", NA, NA, desc = "Raster containing pixel height. EX. Canopy height model"),
    defineParameter("nameZoneTable", "character", "99999", NA, NA, desc = "Name of the table documenting the zone types"),
    defineParameter("nameYieldsRaster", "character", "99999", NA, NA, desc = "Name of the raster with id's for yield tables"),
    defineParameter("nameYieldTable", "character", "99999", NA, NA, desc = "Name of the table documenting the yields"),
    defineParameter("nameOwnershipRaster", "character", "99999", NA, NA, desc = "Name of the raster from GENERALIZED FOREST OWNERSHIP"),
    defineParameter("nameForestInventoryTable", "character", "99999", NA, NA, desc = "Name of the veg comp table - the forest inventory"),
    defineParameter("nameForestInventoryRaster", "character", "99999", NA, NA, desc = "Name of the veg comp - the forest inventory raster of the primary key"),
    defineParameter("nameForestInventoryKey", "character", "99999", NA, NA, desc = "Name of the veg comp primary key that links the table to the raster")
    ),
  inputObjects = bind_rows(
    #expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput("nameBoundaryFile", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundary", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundaryColumn", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("nameBoundaryGeom", objectClass ="character", desc = NA, sourceURL = NA)
    ),
  outputObjects = bind_rows(
    createsOutput("zone.length", objectClass ="numeric", desc = NA),
    createsOutput("boundaryInfo", objectClass ="character", desc = NA),
    createsOutput("bbox", objectClass ="numeric", desc = NA),
    createsOutput("clusdb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates clus realted information"),
    createsOutput("ras", objectClass ="RasterLayer", desc = "Raster Layer of the cell index"),
    createsOutput("rasVelo", objectClass ="VeloxRaster", desc = "Velox Raster Layer of the cell index - used in roadCLUS for snapping roads"),
    createsOutput(objectName = "pts", objectClass = "data.table", desc = "A data.table of X,Y locations - used to find distances")
  )
))

doEvent.dataLoaderCLUS = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    init = {
      if(P(sim, "dataLoaderCLUS", "useCLUSdb") == "99999"){
        #build clusdb
        sim <- dataLoaderCLUS.createCLUSdb(sim)
        #setBoundaries
        #sim$boundary<-getSpatialQuery(paste0("SELECT * FROM ",  P(sim, "dataLoaderCLUS", "nameBoundaryFile"), " WHERE ",   P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), "= '",  P(sim, "dataLoaderCLUS", "nameBoundary"),"';" ))
        sim$boundaryInfo <- list(P(sim, "dataLoaderCLUS", "nameBoundaryFile"),P(sim, "dataLoaderCLUS", "nameBoundaryColumn"),P(sim, "dataLoaderCLUS", "nameBoundary"), P(sim, "dataLoaderCLUS", "nameBoundaryGeom"))
        #populate clusdb tables
        sim<-dataLoaderCLUS.setTablesCLUSdb(sim)
        #disconnect the db once the sim is over?
        sim <- scheduleEvent(sim, eventTime = end(sim),  "dataLoaderCLUS", "removeDbCLUS", eventPriority=99)
      }else{
        print(paste0("Loading existing db...", P(sim, "dataloaderCLUS", "clusdb")))
        sim$clusdb <- dbConnect(RSQLite::SQLite(), dbname = P(sim, "dataLoaderCLUS", "useCLUSdb") )
      }
      },
    removeDbCLUS={
      sim<- disconnectDbCLUS(sim)
      
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

disconnectDbCLUS<- function(sim) {
  if(P(sim)$save_clusdb){
    print('Saving clusdb')
    con<-dbConnect(RSQLite::SQLite(), "clusdb.sqlite")
    RSQLite::sqliteCopyDatabase(sim$clusdb, con)
    unlink("clusdb.sqlite")
  }
  
  dbDisconnect(sim$clusdb)
  
  return(invisible(sim))
}

dataLoaderCLUS.createCLUSdb <- function(sim) {
  print ('create clusdb')
  #build the clusdb - a realtional database that tracks the interactions between spatial and temporal objectives
  sim$clusdb <- dbConnect(RSQLite::SQLite(), ":memory:") #builds the db in memory; also resets any existing db! Can be set to store on disk
  #dbExecute(sim$clusdb, "PRAGMA foreign_keys = ON;") #Turns the foreign key constraints on. 
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS yields ( id integer PRIMARY KEY, yieldid integer, age integer, tvol numeric, con numeric, height numeric, eca numeric)")
  #Note Zone table is created as a JOIN with zoneConstraints and zone
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS zone (zone_column text, reference_zone text)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS zoneConstraints ( id integer PRIMARY KEY, zoneid integer, reference_zone text, zone_column text, variable text, threshold numeric, type text, percentage numeric, t_area numeric)")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS pixels ( pixelid integer PRIMARY KEY, compartid character, 
own integer, yieldid integer, zone_const integer, thlb numeric , age numeric, vol numeric,
crownclosure numeric, height numeric, roadyear integer)")
  return(invisible(sim))
}

dataLoaderCLUS.setTablesCLUSdb <- function(sim) {
  print('...setting data tables')
  #-----------------------
  #Set the compartment IDS
  #-----------------------
  if(!(P(sim, "dataLoaderCLUS", "nameCompartmentRaster") == "99999")){
    print(paste0('.....compartment ids: ', P(sim, "dataLoaderCLUS", "nameCompartmentRaster")))
    sim$ras<-RASTER_CLIP2(srcRaster= P(sim, "dataLoaderCLUS", "nameCompartmentRaster"), 
                          clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                          geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                          where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                          conn=NULL)
    
    sim$pts <-data.table(xyFromCell(sim$ras,1:length(sim$ras))) #Seems to be faster that rasterTopoints
    sim$pts<- sim$pts[, pixelid:= seq_len(.N)] #add in the pixelid which streams data in according to the cell number = pixelid
    
    pixels<-data.table(c(t(raster::as.matrix(sim$ras))))
    pixels[, pixelid := seq_len(.N)]
    
    #Set V1 to merge in the vat table values so that the column is character
    if(!(P(sim, "dataLoaderCLUS", "nameCompartmentTable") == "99999")){
      compart_vat <- data.table(getTableQuery(paste0("SELECT * FROM ", P(sim, "dataLoaderCLUS", "nameCompartmentTable"))))
      pixels<- merge(pixels, compart_vat, by.x = "V1", by.y = "value", all.x = TRUE )
      pixels[,V1:= NULL]
      col_name<-data.table(colnames(compart_vat))[!V1 == "value"]
      setnames(pixels, col_name$V1 , "compartid")
    }else{
      pixels[, V1 := as.character(V1)]
      setnames(pixels, "V1", "compartid")
    }

    sim$ras[]<-unlist(pixels[,"pixelid"], use.names = FALSE)
    sim$rasVelo<-velox::velox(sim$ras)
    
  }else{
    print('.....compartment ids: default 1')
    #Set the empty table for values not supplied in the parmaters
    sim$ras<-RASTER_CLIP2(srcRaster= 'rast.bc_bound', 
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
  
  #----------------
  #Set the zone IDs
  #----------------
  if(!(P(sim, "dataLoaderCLUS", "nameZoneRasters")[1] == "99999")){
    sim$zone.length<-length(P(sim, "dataLoaderCLUS", "nameZoneRasters"))
    print(paste0('.....zones: ',sim$zone.length))
    zones_aoi<-data.table(zoneid='', zone_column='')
    #Add multiple zone columns - each will have its own raster. Attributed to that raster is a table of the thresholds by zone
    for(i in 1:sim$zone.length){
      ras.zone<-RASTER_CLIP2(srcRaster= P(sim, "dataLoaderCLUS", "nameZoneRasters")[i], 
                             clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                             geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                             where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                             conn=NULL)
      pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.zone)))))
      setnames(pixels, "V1", paste0('zone',i))#SET NAMES to RASTER layer
      dbExecute(sim$clusdb, paste0('ALTER TABLE pixels ADD COLUMN zone', i,' numeric'))
      dbExecute(sim$clusdb, paste0("INSERT INTO zone (zone_column, reference_zone) values ( 'zone", i, "', '", P(sim, "dataLoaderCLUS", "nameZoneRasters")[i], "')" ))

      #print(head(zones_aoi))
      rm(ras.zone)
      gc()
      
    }
    #create the unique zones. Don't need a unique zone because management zones are applied mutually exlusive
    #pixels[, zone_unique := do.call(paste, c(.SD, sep = "_")), .SDcols = paste0("zone",as.character(seq(1:sim$zone.length)))]
    
    #zone_constraint table
    if(!P(sim)$nameZoneTable == '99999'){
      
      zone_const<-getTableQuery(paste0("SELECT * FROM ", P(sim)$nameZoneTable))
      zone<-dbGetQuery(sim$clusdb, "SELECT * FROM zone")
      zone_const<-merge(zone_const, zone, by = 'reference_zone')
      #Need to select only those constraints that pertain to the study area
      
      
      zones<-lapply(zone$zone_column, function (x){
        distinct_zones<-pixels[, .(t_area=uniqueN(pixelid)), by = x]
        distinct_zones[, zone_column:= x]
        setnames(distinct_zones, x, "zoneid")
        distinct_zones
      })
      zones<-rbindlist(zones) #unlist the list of data.tables
      
      zones<-zones[!is.na(zoneid),] #remove the NA (border pixels)
      zones<-merge(zones, zone_const, by.x = c("zone_column", "zoneid"), by.y = c("zone_column", "zoneid"))
      
      dbBegin(sim$clusdb)
      rs<-dbSendQuery(sim$clusdb, "INSERT INTO zoneConstraints (zoneid, reference_zone, zone_column, variable, threshold, type ,percentage, t_area ) 
                      values (:zoneid, :reference_zone, :zone_column, :variable, :threshold, :type, :percentage, :t_area)", zones)
      dbClearResult(rs)
      dbCommit(sim$clusdb)
    }
  } else{
    print('.....zone ids: default 1')
    sim$zone.length<-1
    pixels[, zone1:= 1]
    dbExecute(sim$clusdb, "ALTER TABLE pixels ADD COLUMN zone1 integer")
    dbExecute(sim$clusdb, paste0("INSERT INTO zone (zone_column, reference_zone) values ( 'zone1', 'default')" ))
  }
  
  #------------
  #Set the THLB
  #------------
  if(!(P(sim, "dataLoaderCLUS", "nameMaskHarvestLandbaseRaster") == "99999")){
    print(paste0('.....thlb: ',P(sim, "dataLoaderCLUS", "nameMaskHarvestLandbaseRaster")))
    ras.thlb<- RASTER_CLIP2(srcRaster= P(sim, "dataLoaderCLUS", "nameMaskHarvestLandbaseRaster"), 
                            clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                            geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                            where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                            conn=NULL)
    pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.thlb)))))
    setnames(pixels, "V1", "thlb")
    rm(ras.thlb)
    gc()
    
  }else{
    print('.....thlb: default 1')
    pixels[, thlb := 1]
  }
  #------------
  #Set the Ownership
  #------------
  if(!(P(sim, "dataLoaderCLUS", "nameOwnershipRaster") == "99999")){
    print(paste0('.....ownership: ',P(sim, "dataLoaderCLUS", "nameOwnershipRaster")))
    ras.own<- RASTER_CLIP2(srcRaster= P(sim, "dataLoaderCLUS", "nameOwnershipRaster"), 
                           clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                           geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                           where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL)
    pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.own)))))
    setnames(pixels, "V1", "own")
    rm(ras.own)
    gc()
  }else{
    print('.....ownership: default 1')
    pixels[, own := 1]
  }
  
  #-----------------
  #Set the Yield IDS
  #-----------------
  if(!(P(sim, "dataLoaderCLUS", "nameYieldsRaster") == "99999")){
    print(paste0('.....yield ids: ',P(sim, "dataLoaderCLUS", "nameYieldsRaster")))
    ras.ylds<-RASTER_CLIP2(srcRaster= P(sim, "dataLoaderCLUS", "nameYieldsRaster"), 
                           clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                           geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                           where_clause = paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL)
    pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.ylds)))))
    setnames(pixels, "V1", "yieldid")
    rm(ras.ylds)
    gc()
  
    #Set the yields table
    yields<-getTableQuery(paste0("SELECT * FROM ", P(sim)$nameYieldTable))
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "INSERT INTO yields (yieldid, age, tvol, con, height, eca) 
                      values (:yieldid, :age, :tvol, :con, :height, :eca)", yields)
    dbClearResult(rs)
    dbCommit(sim$clusdb)
    
  }else{
    print('.....yield ids: default 1')
    pixels[, yieldid := 1]
    
    #Set the yields table
    yields<-data.table(yieldid= 1, age= seq(from =0, to=190, by = 10), 
                       tvol = seq(1:20)**2, 
                       con = 100, 
                       height = seq(1:20), 
                       eca = 0)
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "INSERT INTO yields (yieldid, age, tvol, con, height, eca ) 
                      values (:yieldid, :age, :tvol, :con, :height, :eca)", yields)
    dbClearResult(rs)
    dbCommit(sim$clusdb)
  }
  
  #**************FOREST INVENTORY - VEGETATION VARIABLES*******************#
  
  if(!P(sim,"dataLoaderCLUS", "nameForestInventoryRaster") == '99999'){
    dbExecute(sim$clusdb, paste0('ALTER TABLE pixels ADD COLUMN fid integer'))
    fid<-c('fid,',':fid,') # used in the query to set the pixels table
    ras.fid<- RASTER_CLIP2(srcRaster= P(sim, "dataLoaderCLUS", "nameForestInventoryRaster"), 
                           clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                           geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                           where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL)
    pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.fid)))))
    setnames(pixels, "V1", "fid")
    rm(ras.fid)
    gc()
    if(!P(sim,"dataLoaderCLUS", "nameForestInventoryTable") == '99999'){
      test<-getTableQuery(paste0("SELECT " , P(sim, "dataLoaderCLUS", "nameForestInventoryKey"), " age, height, crownclosure FROM ",
             P(sim,"dataLoaderCLUS", "nameForestInventoryTable")))
        
      } else { 
        print('No inventory table')
      }  
  } else {
    
    fid<-c('','')
    #----------------
    #Set the blockids see blockingCLUS
    #----------------
      #blockid table
      #if(!(P(sim, "dataLoaderCLUS", "nameCutblockTable") == "99999")){
       # print('......getting blocks information')
       # blocks<- getTableQuery(paste0("SELECT t.blockid, t.area, openingid, (1) as state, (20-(2018 - harvestyr)) as regendelay FROM 
       # (SELECT (col1).value::int as blockid, (col1).count::int as area  FROM (
       #                               SELECT ST_ValueCount(st_union(ST_Clip(rast, 1, foo.",P(sim, "dataLoaderCLUS", "nameBoundaryGeom") ,", -9999, true)),1,true)  as col1 FROM 
        #                              (SELECT st_union(rast) as rast, ",P(sim, "dataLoaderCLUS", "nameBoundaryGeom")," FROM ",P(sim, "dataLoaderCLUS", "nameCutblockRaster"),", ",P(sim, "dataLoaderCLUS", "nameBoundaryFile"),
        #                              " WHERE ",P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " IN ('", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "', '"),"')" ," AND ST_Intersects(rast, ",P(sim, "dataLoaderCLUS", "nameBoundaryGeom"),") group by ",P(sim, "dataLoaderCLUS", "nameBoundaryGeom")," ) as foo) as k) as t
        #                              INNER JOIN ",P(sim, "dataLoaderCLUS", "nameCutblockTable"),"
        #                              ON t.blockid = ",P(sim, "dataLoaderCLUS", "nameCutblockTable"),".cutblockid;"))
        #
        #Set the table in clusdb
        #dbBegin(sim$clusdb)
        #rs<-dbSendQuery(sim$clusdb, "INSERT INTO blocks (blockid, openingid, state, regendelay, t_area) 
        #                values (:blockid, :openingid, :state, :regendelay, :area)", blocks)
        #dbClearResult(rs)
        #dbCommit(sim$clusdb)
      #}else{
      #  print('nameCutblockTable = 99999 ')
      #}
      

    #-----------
    #Set the Age 
    #-----------
    if(!(P(sim, "dataLoaderCLUS", "nameAgeRaster") == "99999")){
      print(paste0('.....age: ',P(sim, "dataLoaderCLUS", "nameAgeRaster")))
      ras.age<-RASTER_CLIP2(srcRaster= P(sim, "dataLoaderCLUS", "nameAgeRaster"), 
                            clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                            geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                            where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                            conn=NULL)
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
      ras.cc<-RASTER_CLIP2(srcRaster=P(sim, "dataLoaderCLUS", "nameCrownClosureRaster"), 
                           clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                           geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                           where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL)
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
      ras.ht<-RASTER_CLIP2(srcRaster=P(sim, "dataLoaderCLUS", "nameHeightRaster"), 
                           clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                           geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                           where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=NULL)
      pixels<-cbind(pixels, data.table(c(t(raster::as.matrix(ras.ht)))))
      setnames(pixels, "V1", "height")
      rm(ras.ht)
      gc()
      
    }else{
      print('.....height: default 10')
      pixels[, height := 10]
    }
  }
  #*************************#
  #--------------------------
  #Load the pixels in RSQLite
  #--------------------------
  qry<- paste0('INSERT INTO pixels (pixelid, compartid, yieldid, own, thlb, ', fid[1] , ' age, crownclosure, height, roadyear, zone',
               paste(as.character(seq(1:sim$zone.length)), sep="' '", collapse=", zone"),' ) 
               values (:pixelid, :compartid, :yieldid, :own, :thlb, ', fid[2], ' :age, :crownclosure, :height, NULL, :zone', 
               paste(as.character(seq(1:sim$zone.length)), sep="' '", collapse=", :zone"),')')
  
  #pixels table
  dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, qry, pixels )
    dbClearResult(rs)
  dbCommit(sim$clusdb)
  
  rm(pixels)
  gc()
  
  print('...done')
  
  #print(head(dbGetQuery(sim$clusdb, 'SELECT * FROM pixels WHERE thlb > 0 limit 5 ')))
  return(invisible(sim))
}

.inputObjects <- function(sim) {

  return(invisible(sim))
}



