#===========================================================================================#
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
  name = "forestryCastor",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.3", forestryCastor = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.md", "forestryCastor.Rmd"),
  reqdPkgs = list(),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant"),
    defineParameter("activeZoneConstraint", "character", "99999", NA, NA, desc = "Administrative boundary containing zones of management objectives"),
    defineParameter("adjacencyConstraint", "numeric", 9999, NA, NA, "Include Adjacency Constraint at the user specified height in metres"),
    defineParameter("growingStockConstraint", "numeric", 9999, NA, NA, "The percentage of standing merchantable timber that must be retained through out the planning horizon. values [0,1]"),
    defineParameter("harvestBlockPriority", "character", "age DESC", NA, NA, "This sets the order from which harvesting should be conducted at the block level. Greatest priority first. DESC is decending, ASC is ascending"),
    defineParameter("harvestZonePriority", "character", "99999", NA, NA, "This sets the order from which harvesting should be conducted at the zone level. Greatest priority first e.g., dist DESC. DESC is decending, ASC is ascending"),
    defineParameter("harvestZonePriorityInterval", "integer", 0L, NA, NA, "This sets the order from which harvesting should be conducted at the zone level. Greatest priority first e.g., dist DESC. DESC is decending, ASC is ascending"),
    defineParameter("salvageRaster", "character", '99999', NA, NA, "Raster that describe the salvage volume per ha.")
    
    ),
  inputObjects = bind_rows(
    expectsInput(objectName = "castordb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates castor realted information", sourceURL = NA),
    expectsInput(objectName ="dbCreds", objectClass ="list", desc = 'Credentials used to connect to users postgresql database', sourceURL = NA),
    expectsInput(objectName = "boundaryInfo", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "extent", objectClass ="list", desc = NA, sourceURL = NA),
    expectsInput(objectName = "harvestFlow", objectClass = "data.table", desc = "Time series table of the total targeted harvest in m3", sourceURL = NA),
    expectsInput(objectName = "growingStockReport", objectClass = "data.table", desc = NA, sourceURL = NA),
    expectsInput(objectName = "pts", objectClass = "data.table", desc = "A data.table of X,Y locations - used to find distances", sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "SpatRaster", desc = "A raster of the study area", sourceURL = NA),
    expectsInput(objectName = "harvestSchedule", objectClass = "SpatRaster", desc = "A raster of harvest units for each time period", sourceURL = NA),
    expectsInput(objectName = "scenario", objectClass ="data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName = "updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA)
    
    ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = "compartment_list", objectClass = "character", desc = NA),
    createsOutput(objectName = "landings", objectClass = "integer", desc = NA),
    createsOutput(objectName = "harvestPeriod", objectClass = "integer", desc = NA),
    createsOutput(objectName = "harvestReport", objectClass = "data.table", desc = NA),
    createsOutput(objectName = "harvestBlocks", objectClass = "SpatRaster", desc = NA),
    createsOutput(objectName = "harvestBlocksVolume", objectClass = "SpatRaster", desc = NA),
    createsOutput(objectName = "harvestBlockList", objectClass = "data.table", desc = NA),
    createsOutput(objectName = "harvestPixelList", objectClass = "data.table", desc = NA),
    createsOutput(objectName = "ras.zoneConstraint", objectClass = "SpatRaster", desc = NA),
    createsOutput(objectName = "zoneManagement", objectClass ="data.table", desc = '.'),
    createsOutput(objectName = "salvageReport", objectClass ="data.table", desc = "Summary per simulation period of the disturbance indicators")
    
  )
))

doEvent.forestryCastor = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init(sim) #note target flow is a data.table object-- dont need to get it.
      if(!is.null(sim$harvestSchedule)){
        sim <- scheduleEvent(sim, time(sim)+ 1, "forestryCastor", "followSchedule", 3)
        sim <- scheduleEvent(sim, end(sim) , "forestryCastor", "save", 9)
      }else{
        sim <- scheduleEvent(sim, time(sim)+ 1, "forestryCastor", "schedule", 3)
        sim <- scheduleEvent(sim, end(sim) , "forestryCastor", "save", 9)
      }
      
      if(P(sim, "harvestZonePriorityInterval", "forestryCastor") > 0){
        sim <- scheduleEvent(sim, time(sim)+ 1 , "forestryCastor", "updateZonePriority", 10)
      }
    },
    schedule = {
      sim <- setConstraints(sim)
      sim <- getHarvestQueue(sim) # This returns a candidate set of blocks or pixels that could be harvested
      sim <- scheduleEvent(sim, time(sim) + 1, "forestryCastor", "schedule", 3)
    },
    followSchedule = {
      sim <- simHarvestQueue(sim)
      sim <- scheduleEvent(sim, time(sim) + 1, "forestryCastor", "followSchedule", 3)
    },
    updateZonePriority={
      sim <- updateZonePriorityTable(sim)
      sim <- scheduleEvent(sim, time(sim)+ P(sim, "harvestZonePriorityInterval", "forestryCastor") , "forestryCastor", "updateZonePriority", 10)
    },
    save = {
      sim <- reportConstraints(sim) 
      sim <- saveForestry(sim)
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  
  #Check to see if a scenario object has been instantiated
  if(nrow(sim$scenario) == 0) { stop('Include a scenario description as a data.table object with columns name and description')}
  
  if(!is.null(sim$harvestFlow)){
    sim$compartment_list<-unique(sim$harvestFlow[, compartment]) #Used in a few functions this calling it once here - its currently static throughout the sim
    #sim$compartment_list<-unique(harvestFlow[, c("compartment", "partition")]) #For looping in partitions
    }
  sim$harvestReport <- data.table(scenario = character(), timeperiod = integer(), compartment = character(), target = numeric(), area= numeric(), volume = numeric(), age = numeric(), hsize = numeric(), avail_thlb= numeric(), transition_area = numeric(), transition_volume= numeric()) # , harvest_type = character()
 
  #Remove zones as a scenario
  dbExecute(sim$castordb, paste0("DELETE FROM zoneConstraints WHERE reference_zone not in ('",paste(P(sim, "activeZoneConstraint", "forestryCastor"), sep= ' ', collapse = "', '"),"')"))
  
 
  #Create the zoneManagement table used for reporting the harvesting constraints throughout the simulation
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS zoneManagement (scenario text, zoneid integer, reference_zone text, zone_column text, variable text, threshold numeric, type text, percentage numeric, multi_condition text, t_area numeric, denom text, start integer, stop integer, percent numeric, timeperiod integer)")
  
  
  #Create the zonePriority table used for spatially adjusting the harvest queue
  if(!P(sim, "harvestZonePriority", "forestryCastor") == '99999'){
    pzone<-dbGetQuery(sim$castordb, paste0("SELECT zone_column from zone where reference_zone = '", P(sim, "nameZonePriorityRaster", "dataCastor"),"'"))[[1]]
    dbExecute(sim$castordb, paste0("CREATE TABLE zonePriority as SELECT ", pzone,", ", pzone," as zoneid, avg(age) as age, avg(dist) as dist, avg(vol*thlb) as vol FROM pixels WHERE thlb > 0 GROUP BY ", 
                                 pzone))
  }
  
  #Needed for printing out rasters of harvest blocks
  sim$harvestBlocks<-sim$ras
  sim$harvestBlocks[]<-0
  sim$harvestBlocksVolume<-sim$harvestBlocks
  
  #Set the zone contraint raster which maps out the number of time periods a pixel is constrained
  sim$ras.zoneConstraint<-sim$ras
  sim$ras.zoneConstraint[]<-0
  
  #Set the yield uncertainty covariate string to a blank
  sim$yieldUncertaintyCovar<-""
  
  #Set the culmination priority
  if(dbGetQuery (sim$castordb, "SELECT COUNT(*) as exists_check FROM pragma_table_info('pixels') WHERE name='culvar';")$exists_check == 0){
    # add in the column
    dbExecute(sim$castordb, "ALTER TABLE pixels ADD COLUMN culvar numeric DEFAULT 0")
    dbExecute(sim$castordb, "create table culvar as  select yieldid, max(tvol/age) as cmai, tvol, age from yields group by yieldid;")
    dbExecute(sim$castordb, "Update pixels set culvar = culvar.tvol from culvar where culvar.yieldid = pixels.yieldid;")
  }
  
  #Set the salvage opportunities
  ##get the salvage volume raster
  ##check it a field already in sim$castordb?
  if(dbGetQuery (sim$castordb, "SELECT COUNT(*) as exists_check FROM pragma_table_info('pixels') WHERE name='salvage_vol';")$exists_check == 0){
    # add in the column
    dbExecute(sim$castordb, "ALTER TABLE pixels ADD COLUMN salvage_vol numeric DEFAULT 0")
  }
    # add in the raster
  if(P(sim, "salvageRaster", "forestryCastor") == '99999'){
    message("WARNING: No salvage raster specified ... defaulting to no salvage opportunities")
  }else{
    message("...getting salvage opportunities")
    sim$salvageReport<-data.table(scenario = character(), compartment = character(), 
                                    timeperiod= integer(), salvage_area = numeric(), salvage_vol = numeric() )
    
    salvage_vol<- data.table (salvage_vol =  RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                     srcRaster = P(sim, "salvageRaster", "forestryCastor"), 
                     clipper = sim$boundaryInfo[[1]],  # by the area of analysis (e.g., supply block/TSA)
                     geom = sim$boundaryInfo[[4]], 
                     where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                     conn=sim$dbCreds)[])
    salvage_vol[,pixelid:=seq_len(.N)]#make a unique id to ensure it merges correctly
    
    #add to the castordb
    dbBegin(sim$castordb)
      rs<-dbSendQuery(sim$castordb, "Update pixels set salvage_vol = :salvage_vol where pixelid = :pixelid", salvage_vol)
    dbClearResult(rs)
    dbCommit(sim$castordb)
      
      #clean up
    rm(salvage_vol)
    gc()
  }
  
  return(invisible(sim))
}

saveForestry<- function(sim) {
  message("Write rasters")
  #write.csv(sim$harvestReport, "harvestReport.csv")
  terra::writeRaster(sim$harvestBlocks, paste0(sim$scenario$name, "_",sim$boundaryInfo[[3]][[1]], "_harvestBlocks.tif"), overwrite=TRUE)#write the blocks to a raster?
  #terra::writeRaster(sim$ras.zoneConstraint, paste0(sim$scenario$name, "_",sim$boundaryInfo[[3]][[1]],"_constraints.tif"), overwrite=TRUE)
  return(invisible(sim))
}

setConstraints<- function(sim) {
  message("...assigning zonal constraints")
  dbExecute(sim$castordb, "UPDATE pixels SET zone_const = 0 WHERE zone_const = 1")

  #For the zone constraints of type 'nh' set zone_const =1 so they are removed from harvesting -- yet they will still contribute to other zonal constraints
  nhConstraints<-data.table(merge(dbGetQuery(sim$castordb, paste0("SELECT  zoneid, reference_zone FROM zoneConstraints WHERE type ='nh' and start <= ", time(sim)*sim$updateInterval, " and stop >= ", time(sim)*sim$updateInterval)),
                                  dbGetQuery(sim$castordb, "SELECT zone_column, reference_zone FROM zone"), 
                                  by.x = "reference_zone", by.y = "reference_zone"))
  
  if(nrow(nhConstraints) > 0 ){
    nhConstraints[,qry:= paste( zone_column,'=',zoneid)]
    dbExecute(sim$castordb, paste0("UPDATE pixels SET zone_const = 1 WHERE ", paste(nhConstraints$qry, collapse = " OR ")))
  }
  
  if(nrow(dbGetQuery(sim$castordb, "SELECT * FROM sqlite_master WHERE type = 'table' and name ='zonePrescription'")) > 0){
    nhPrescriptions<-data.table(merge(dbGetQuery(sim$castordb, paste0("SELECT  zoneid, reference_zone, minHarvestVariable, minHarvestThreshold FROM zonePrescription WHERE start <= ", time(sim)*sim$updateInterval, " and stop >= ", time(sim)*sim$updateInterval)),
                                    dbGetQuery(sim$castordb, "SELECT zone_column, reference_zone FROM zone"), 
                                    by.x = "reference_zone", by.y = "reference_zone"))#For each zone, zoneid, variable
    
    nhPrescriptions<-nhPrescriptions[complete.cases(nhPrescriptions),]#Remove rows that have NA
    if(nrow(nhPrescriptions) > 0 ){
      #set up a parameterized query need a list by zone_column, minHarvestVariable
      nhPrescriptions[, id:= paste0(zone_column, minHarvestVariable)]
      setPrescriptions<-split(nhPrescriptions, nhPrescriptions$id)
      rs_batch<-lapply(setPrescriptions, function(x){
        sql <- paste0("UPDATE pixels SET zone_const = 1 where ", x$zone_column[1], " = :zoneid and ", x$minHarvestVariable[1], " < :minHarvestThreshold")
        dbBegin(sim$castordb)
        rs<-dbSendQuery(sim$castordb, sql, x[,c("zoneid", "minHarvestThreshold")])
        dbClearResult(rs)
        dbCommit(sim$castordb)
      })
    }
  }
  
  #Get the zones that are listed for this specific scenario
  zones<-dbGetQuery(sim$castordb, paste0("SELECT zone_column FROM zone WHERE reference_zone in ('",paste(P(sim, "activeZoneConstraint", "forestryCastor"), sep= ' ', collapse = "', '"),"')"))
  for(i in 1:nrow(zones)){ #for each of the specified zone rasters
    numConstraints<-dbGetQuery(sim$castordb, paste0("SELECT DISTINCT variable, type, denom FROM zoneConstraints WHERE
                               zone_column = '",  zones[[1]][i] ,"' AND type IN ('ge', 'le') and start <= ", time(sim)*sim$updateInterval, " and stop >= ", time(sim)*sim$updateInterval ))
    #numConstraints contains unqiue combinations of variable, type and denom (as the columns)
    if(nrow(numConstraints) > 0){
      for(k in 1:nrow(numConstraints)){
        if(is.na(numConstraints[[3]][k])){ #colum 3 is the denom column
          query_parms<-data.table(dbGetQuery(sim$castordb, paste0("SELECT t_area, type, zoneid, reference_zone, variable, zone_column, percentage, threshold, multi_condition, denom, start, stop,
                                                        CASE WHEN type = 'ge' THEN ROUND((percentage*1.0/100)*t_area, 0)
                                                             ELSE ROUND((1-(percentage*1.0/100))*t_area, 0)
                                                        END AS limits
                                                        FROM zoneConstraints WHERE zone_column = '", zones[[1]][i],"' AND variable = '", 
                                                                 numConstraints[[1]][k],"' AND type = '",numConstraints[[2]][k] ,"' and denom is null and start <= ", time(sim)*sim$updateInterval, " and stop >= ", time(sim)*sim$updateInterval )))
          query_parms<-query_parms[is.na(denom), denom := ''] #Add a blank so that the denom is not used in teh query string
        }else{ #when the denom column is not blank--meaning there is a change in the denominator
          query_parms<-data.table(dbGetQuery(sim$castordb, paste0("SELECT t_area, type, zoneid, reference_zone, variable, zone_column, percentage, threshold, multi_condition, denom, start, stop,
                                                        CASE WHEN type = 'ge' THEN ROUND((percentage*1.0/100)*t_area, 0)
                                                             ELSE ROUND((1-(percentage*1.0/100))*t_area, 0)
                                                        END AS limits
                                                        FROM zoneConstraints WHERE zone_column = '", zones[[1]][i],"' AND variable = '", 
                                                                 numConstraints[[1]][k],"' AND type = '",numConstraints[[2]][k] ,"' and denom = '",numConstraints[[3]][k] ,"' and start <= ", time(sim)*sim$updateInterval, " and stop >= ", time(sim)*sim$updateInterval )))
          query_parms<-query_parms[!is.na(denom), denom := paste(denom, " AND ")] #Add an 'AND' so that the query will be seemlessly added to the sql
        }
 
       query_parms<-query_parms[!is.na(limits) | limits > 0, ] [multi_condition == "NA", multi_condition := NA] #remove any constraints that don't have any limits or cells to constrain on
       #The query_parms object can have many zoneid's wihtin a zone that have the 'same' structure of the query - lets take advantage of that and set up all the queries in a single transaction --aka 'a parameterized query'
       switch(
          as.character(query_parms[1, "type"]), #The reason only the 1st row is needed because all remaining rows will have the same configuration of the query
            ge = {
              if(as.character(query_parms[1, "variable"]) == 'dist' ){
                sql<-paste0("UPDATE pixels SET zone_const = 1
                        WHERE pixelid IN ( 
                        SELECT pixelid FROM pixels WHERE ",as.character(query_parms[1, "denom"])," own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid", 
                        " ORDER BY CASE WHEN ", as.character(query_parms[1, "variable"]),">= :threshold then 0 else 1 end, ",as.character(query_parms[1, "variable"])," DESC,  age DESC
                        LIMIT :limits);")
                dbBegin(sim$castordb)
                rs<-dbSendQuery(sim$castordb, sql, query_parms[,c("zoneid", "threshold", "limits")])
                dbClearResult(rs)
                dbCommit(sim$castordb)
                
                sql<- paste0("INSERT INTO zoneManagement SELECT '",sim$scenario$name,"' as scenario, :zoneid as zoneid, :reference_zone as reference_zone, :zone_column as zone_column, :variable as variable, :threshold as threshold, :type as type, :percentage as percentage, :multi_condition as multi_condition, :t_area as t_area, :denom as denom, :start as start, :stop as stop, 
                           avg(case when ", as.character(query_parms[1, "variable"])  ," >= :threshold then 1 else 0 end)*100 as percent, ", as.integer(time(sim)) ," as timeperiod  from pixels WHERE ",as.character(query_parms[1, "denom"])," own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid")
                
                dbBegin(sim$castordb)
                  rs<-dbSendQuery(sim$castordb, sql, query_parms[,c("zoneid", "reference_zone", "zone_column", "variable", "threshold", "type", "percentage", "multi_condition", "t_area", "denom", "start", "stop")])
                dbClearResult(rs)
                dbCommit(sim$castordb)
                
              }else if(!is.na(query_parms[1, "multi_condition"])){ #Allow user to write own constraints according to many fields - right now only one variable
                
                print (query_parms)
                
                sql<-paste0("UPDATE pixels SET zone_const = 1
                        WHERE pixelid IN ( 
                        SELECT pixelid FROM pixels WHERE ",as.character(query_parms[1, "denom"])," own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid", 
                            " ORDER BY CASE WHEN ", as.character(query_parms[1, "multi_condition"])," then 0 ELSE 1 END,  thlb, zone_const DESC, age DESC
                        LIMIT :limits);")
                
                print (sql)
                
                dbBegin(sim$castordb)
                rs<-dbSendQuery(sim$castordb, sql, query_parms[,c("zoneid", "limits")])
                dbClearResult(rs)
                dbCommit(sim$castordb)
                
                sql<- paste0("INSERT INTO zoneManagement SELECT '",sim$scenario$name,"' as scenario, :zoneid as zoneid, :reference_zone as reference_zone, :zone_column as zone_column, :variable as variable, :threshold as threshold, :type as type, :percentage as percentage, :multi_condition as multi_condition, :t_area as t_area, :denom as denom, :start as start, :stop as stop, 
                           avg(case when ", as.character(query_parms[1, "multi_condition"])  ," then 1 else 0 end)*100 as percent, ", as.integer(time(sim)) ," as timeperiod  from pixels  WHERE ",as.character(query_parms[1, "denom"])," own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid")
                
                dbBegin(sim$castordb)
                  rs<-dbSendQuery(sim$castordb, sql, query_parms[,c("zoneid", "reference_zone", "zone_column", "variable", "threshold", "type", "percentage", "multi_condition", "t_area", "denom", "start", "stop")])
                dbClearResult(rs)
                dbCommit(sim$castordb)
                
              }else{
                sql<-paste0("UPDATE pixels 
                        SET zone_const = 1
                        WHERE pixelid IN ( 
                        SELECT pixelid FROM pixels WHERE ",as.character(query_parms[1, "denom"])," own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid", 
                            " ORDER BY CASE WHEN ",as.character(query_parms[1, "variable"])," >= :threshold  THEN 0 ELSE 1 END, thlb, zone_const DESC, ", as.character(query_parms[1, "variable"])," DESC
                        LIMIT :limits);")
                dbBegin(sim$castordb)
                  rs<-dbSendQuery(sim$castordb, sql, query_parms[,c("zoneid", "threshold", "limits")])
                dbClearResult(rs)
                dbCommit(sim$castordb)
                
                sql<- paste0("INSERT INTO zoneManagement SELECT '",sim$scenario$name,"' as scenario, :zoneid as zoneid, :reference_zone as reference_zone, :zone_column as zone_column, :variable as variable, :threshold as threshold, :type as type, :percentage as percentage, :multi_condition as multi_condition, :t_area as t_area, :denom as denom,  :start as start, :stop as stop,
                           avg(case when ", as.character(query_parms[1, "variable"])  ," >= :threshold then 1 else 0 end)*100 as percent, ", as.integer(time(sim)) ," as timeperiod  from pixels WHERE ",as.character(query_parms[1, "denom"])," own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid")
               
                
                dbBegin(sim$castordb)
                  rs<-dbSendQuery(sim$castordb, sql, query_parms[,c("zoneid", "reference_zone", "zone_column", "variable", "threshold", "type", "percentage", "multi_condition", "t_area", "denom", "start", "stop")])
                dbClearResult(rs)
                dbCommit(sim$castordb) 
              }
            },
            le = {
              if(as.character(query_parms[1, "variable"]) == 'eca' ){
                #get the correct limits -- currently assuming the entire area is at the threshold
                eca_current<-data.table(dbGetQuery(sim$castordb, paste0("SELECT ",as.character(query_parms[1, "zone_column"]),", sum(eca*thlb) as eca FROM pixels WHERE ",
                                                         as.character(query_parms[1, "zone_column"]), " IN (",
                                                         paste(query_parms$zoneid, collapse=", "),") GROUP BY ",as.character(query_parms[1, "zone_column"]), 
                                                         " ORDER BY ",as.character(query_parms[1, "zone_column"])) ))
                
                
                query_parms<-merge(query_parms, eca_current, by.x ="zoneid", by.y =as.character(query_parms[1, "zone_column"]) , all.x =TRUE )
                query_parms[,limits:=as.integer((1-(threshold/100 - eca/t_area))*t_area)]
                sql<-paste0("UPDATE pixels 
                      SET zone_const = 1
                            WHERE pixelid IN ( 
                            SELECT pixelid FROM pixels WHERE ",as.character(query_parms[1, "denom"])," own = 1 AND ",  as.character(query_parms[1, "zone_column"])," = :zoneid",
                            " ORDER BY thlb, zone_const DESC, eca DESC 
                            LIMIT :limits);") #limits = the area that needs preservation 
                
                #query_parms<-query_parms[, limits := as.integer (limits)]
                
                dbBegin(sim$castordb)
                rs<-dbSendQuery(sim$castordb, sql, query_parms[!is.na (limits), c("zoneid", "limits")])
                dbClearResult(rs)
                dbCommit(sim$castordb)
                
                sql<- paste0("INSERT INTO zoneManagement SELECT '",sim$scenario$name,"' as scenario, :zoneid as zoneid, :reference_zone as reference_zone, :zone_column as zone_column, :variable as variable, :threshold as threshold, :type as type, :percentage as percentage, :multi_condition as multi_condition, :t_area as t_area, :denom as denom, :start as start, :stop as stop, 
                           (sum(eca*thlb)/:t_area)*100 as percent, ", as.integer(time(sim)) ," as timeperiod  from pixels WHERE ",as.character(query_parms[1, "denom"])," own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid")
                
                
                dbBegin(sim$castordb)
                  rs<-dbSendQuery(sim$castordb, sql, query_parms[,c("zoneid", "reference_zone", "zone_column", "variable", "threshold", "type", "percentage", "multi_condition", "t_area", "denom", "start", "stop")])
                dbClearResult(rs)
                dbCommit(sim$castordb) 
                
                
              }else if(as.character(query_parms[1, "variable"]) == 'dist' ){
                sql<-paste0("UPDATE pixels SET zone_const = 1
                        WHERE pixelid IN ( 
                        SELECT pixelid FROM pixels WHERE ",as.character(query_parms[1, "denom"])," own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid", 
                            " ORDER BY CASE WHEN dist <= :threshold then 1 else 0 end, thlb, zone_const DESC, dist DESC
                        LIMIT :limits);")
                dbBegin(sim$castordb)
                  rs<-dbSendQuery(sim$castordb, sql, query_parms[,c("zoneid", "threshold", "limits")])
                dbClearResult(rs)
                dbCommit(sim$castordb)
                
                sql<- paste0("INSERT INTO zoneManagement SELECT '",sim$scenario$name,"' as scenario, :zoneid as zoneid, :reference_zone as reference_zone, :zone_column as zone_column, :variable as variable, :threshold as threshold, :type as type, :percentage as percentage, :multi_condition as multi_condition, :t_area as t_area, :denom as denom, :start as start, :stop as stop,
                           avg(case when ", as.character(query_parms[1, "variable"])  ," <= :threshold then 1 else 0 end)*100 as percent, ", as.integer(time(sim)) ," as timeperiod  from pixels WHERE ",as.character(query_parms[1, "denom"])," own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid")
                
                dbBegin(sim$castordb)
                  rs<-dbSendQuery(sim$castordb, sql, query_parms[,c("zoneid", "reference_zone", "zone_column", "variable", "threshold", "type", "percentage", "multi_condition", "t_area", "denom", "start", "stop")])
                dbClearResult(rs)
                dbCommit(sim$castordb) 
                
              }else if(!is.na(query_parms[1, "multi_condition"])){ #Allow user to write own constraints according to many fields - right now only one variable
                sql<-paste0("UPDATE pixels SET zone_const = 1
                        WHERE pixelid IN ( 
                        SELECT pixelid FROM pixels WHERE ",as.character(query_parms[1, "denom"])," own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid", 
                              " ORDER BY CASE WHEN ", as.character(query_parms[1, "multi_condition"])," then 1 ELSE 0 END,  thlb, zone_const DESC, age
                        LIMIT :limits);")
    
                dbBegin(sim$castordb)
                  rs<-dbSendQuery(sim$castordb, sql, query_parms[,c("zoneid", "limits")])
                dbClearResult(rs)
                dbCommit(sim$castordb)
                  
                sql<- paste0("INSERT INTO zoneManagement SELECT '",sim$scenario$name,"' as scenario, :zoneid as zoneid, :reference_zone as reference_zone, :zone_column as zone_column, :variable as variable, :threshold as threshold, :type as type, :percentage as percentage, :multi_condition as multi_condition, :t_area as t_area, :denom as denom, :start as start, :stop as stop, 
                           avg(case when ", as.character(query_parms[1, "multi_condition"])  ," then 1 else 0 end)*100 as percent, ", as.integer(time(sim)) ," as timeperiod  from pixels  WHERE ",as.character(query_parms[1, "denom"])," own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid")
                  
                dbBegin(sim$castordb)
                  rs<-dbSendQuery(sim$castordb, sql, query_parms[,c("zoneid", "reference_zone", "zone_column", "variable", "threshold", "type", "percentage", "multi_condition", "t_area", "denom", "start", "stop")])
                dbClearResult(rs)
                dbCommit(sim$castordb) 
                  
              }else{
                sql<-paste0("UPDATE pixels 
                      SET zone_const = 1
                      WHERE pixelid IN ( 
                      SELECT pixelid FROM pixels WHERE ",as.character(query_parms[1, "denom"])," own = 1 AND ",  as.character(query_parms[1, "zone_column"])," = :zoneid",
                      " ORDER BY CASE WHEN ",as.character(query_parms[1, "variable"])," <= :threshold THEN 1 ELSE 0 END, thlb, zone_const DESC,", as.character(query_parms[1, "variable"])," 
                      LIMIT :limits);") 
                #Update pixels in castordb for zonal constraints
                dbBegin(sim$castordb)
                rs<-dbSendQuery(sim$castordb, sql, query_parms[,c("zoneid", "threshold", "limits")])
                dbClearResult(rs)
                dbCommit(sim$castordb)
                
                sql<- paste0("INSERT INTO zoneManagement SELECT '",sim$scenario$name,"' as scenario, :zoneid as zoneid, :reference_zone as reference_zone, :zone_column as zone_column, :variable as variable, :threshold as threshold, :type as type, :percentage as percentage, :multi_condition as multi_condition, :t_area as t_area, :denom as denom, :start as start, :stop as stop, 
                           avg(case when ", as.character(query_parms[1, "variable"])  ," <= :threshold then 1 else 0 end)*100 as percent, ", as.integer(time(sim)) ," as timeperiod  from pixels WHERE ",as.character(query_parms[1, "denom"])," own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid")
                
                dbBegin(sim$castordb)
                rs<-dbSendQuery(sim$castordb, sql, query_parms[,c("zoneid", "reference_zone", "zone_column", "variable", "threshold", "type", "percentage", "multi_condition", "t_area", "denom", "start", "stop")])
                dbClearResult(rs)
                dbCommit(sim$castordb) 
              }
            }, 
            warning(paste0("Undefined 'type' in zoneConstraints: ", as.character(query_parms[1, "type"])))
        )
      } 
    } 
  }
  
  if(!(P(sim, "adjacencyConstraint", "forestryCastor") == 9999)){
    #Update pixels in castordb for adjacency constraints
    message("...assigning adjacency constraint")
    query_parms<-data.table(dbGetQuery(sim$castordb, paste0("SELECT pixelid FROM pixels WHERE blockid IN 
                                                            (SELECT blockid FROM blocks WHERE blockid > 0 AND height >= 0 AND height <= ",P(sim, "adjacencyConstraint", "forestryCastor") ,
                                                            " UNION 
                                                            SELECT b.adjblockid FROM 
                                                            (SELECT blockid FROM blocks WHERE blockid > 0 AND height >= 0 AND height <= ",P(sim, "adjacencyConstraint", "forestryCastor"),") a 
                                                            LEFT JOIN adjacentBlocks b ON a.blockid = b.blockid ); ")))
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, "UPDATE pixels set zone_const = 1 WHERE pixelid = :pixelid; ", query_parms)
    dbClearResult(rs)
    dbCommit(sim$castordb)
  }

  #write the constraint raster
  const<-sim$ras
  datat<-dbGetQuery(sim$castordb, "SELECT zone_const FROM pixels ORDER BY pixelid;")
  const[]<-datat$zone_const
  
  sim$ras.zoneConstraint<-sim$ras.zoneConstraint + const
  
  rm(const)
  return(invisible(sim))
}

simHarvestQueue <- function(sim) {
  #Objects that need appending 
  sim$harvestPixelList <- data.table()
  land_pixels <- data.table()
  
  ras.h.blocks<-sim$harvestSchedule[[paste0("hsq_", time(sim)*sim$updateInterval)]]
  h.blocks<-data.table(blockid = ras.h.blocks[])[, pixelid:=seq_len(.N)]
  setnames(h.blocks, c("blockid", "pixelid"))
  h.blocks<-h.blocks[!is.na(blockid),]
  
  h.blocks.attributes<-merge(h.blocks, data.table(dbGetQuery(sim$castordb, paste0("select compartid, pixelid, vol as vol_h, height, thlb, age, dist, elv from pixels where pixelid in (", paste(unique(h.blocks$pixelid), collapse = ", "), ");"))), by.x = "pixelid", by.y ="pixelid", all.x=T)
  sim$harvestPixelList <-  rbindlist(list(sim$harvestPixelList, h.blocks.attributes[,c("blockid", "pixelid", "dist", "vol_h")]), use.names = TRUE ) 
  
  h.blocks.attributes[ ,tot_thlb:=sum(thlb), by= "compartid"]
  
  temp.harvestBlockList<-h.blocks.attributes[, list(sum(vol_h*thlb), mean(height), mean(elv)), by = c("blockid", "compartid")]
  setnames(temp.harvestBlockList, c("V1", "V2", "V3"), c("proj_vol", "proj_height_1", "elv"))
  sim$harvestBlockList<- rbindlist(list(sim$harvestBlockList, temp.harvestBlockList))
  
  h.blocks.summary<-h.blocks.attributes[, list(sum(thlb, na.rm =T), sum(vol_h*thlb, na.rm =T), sum(age*(thlb/tot_thlb), na.rm =T)), by = "compartid"]
  temp_harvest_report<-data.table(scenario= sim$scenario$name, timeperiod = time(sim)*sim$updateInterval, compartment = h.blocks.summary$compartid, 
                                  target = h.blocks.summary$V2/sim$updateInterval , 
                                  area= h.blocks.summary$V1/sim$updateInterval , 
                                  volume = h.blocks.summary$V2/sim$updateInterval, 
                                  age = h.blocks.summary$V3, 
                                  hsize = nrow(temp.harvestBlockList)/sim$updateInterval,
                                  transition_area  = NA,  
                                  transition_volume  = NA,
                                  avail_thlb = NA) #,  harvest_type = 'live'
  
  sim$harvestReport<- rbindlist(list(sim$harvestReport, temp_harvest_report), use.names = TRUE)
  
  
  dbBegin(sim$castordb)
  rs<-dbSendQuery(sim$castordb, "UPDATE pixels SET age = 0, yieldid = yieldid_trans, vol = 0, salvage_vol = 0 WHERE pixelid = :pixelid", h.blocks[, "pixelid"])
  dbClearResult(rs)
  dbCommit(sim$castordb)
  
  #Save the harvesting raster
  sim$harvestBlocks[h.blocks$pixelid]<-time(sim)*sim$updateInterval
  sim$harvestBlocksVolume[h.blocks$pixelid]<-h.blocks.attributes$vol
  
  #Create landings. pixelid is the cell label that corresponds to pts. To get the landings need a pixel within the blockid so just grab a pixelid for each blockid
  land_pixels<-rbindlist(list(land_pixels, data.table(dbGetQuery(sim$castordb, paste0("select landing from blocks where blockid in (",
                                                                                      paste(unique(h.blocks$blockid), collapse = ", "), ");")))))
  #convert to class SpatialPoints needed for roadCastor
  if(length(land_pixels) > 0){
    sim$landings <- land_pixels$landing
  }else{
    message("no landings")
    sim$landings <- NULL
  }
  
  #stop()
  return(invisible(sim))
}

getHarvestQueue <- function(sim) {
  #Objects that need appending 
  sim$harvestPixelList <- data.table()
  land_pixels <- data.table()
  
  #Right now its looping by compartment -- it will be serializable at the aoi level then
  for(compart in sim$compartment_list){
     harvestTarget<-sim$harvestFlow[compartment == compart & period == time(sim) & flow > 0,]$flow
     harvestType<-sim$harvestFlow[compartment == compart & period == time(sim) & flow > 0,]$partition_type
  
    if(length(harvestTarget)>0 ){# Determine if there is a demand for timber volume 
      message(paste0(compart, " harvest Target: ", harvestTarget, " "))
      ##Partitions will be evaluated simultaneously as an 'OR'
      if(length(harvestTarget)>1){
        partition_raw<-sim$harvestFlow[compartment==compart & period == time(sim) & flow > 0,]$partition
        partition_sql<-paste(sim$harvestFlow[compartment==compart & period == time(sim) & flow > 0,]$partition, sep = " ", collapse = " OR ")
        partition_case<-paste0(", ", paste(apply(cbind(1:length(harvestTarget), partition_raw), 1, FUN=function(x){paste0("(CASE WHEN ", x[2], " THEN 1 ELSE 0 END) as part",x[1])}) , sep = "", collapse = ", "))
      }else{
        partition_sql<-sim$harvestFlow[compartment==compart & period == time(sim),]$partition
        partition_case<-""
      }
      
      #Queue pixels for harvesting. Use a nested query so that all of the block will be selected -- meet patch size objectives
      if(!P(sim, "harvestZonePriority","forestryCastor")== '99999'){
        message(paste0("Using zone priority: ",P(sim, "harvestZonePriority","forestryCastor") ))
        name.zone.priority<-dbGetQuery(sim$castordb, paste0("SELECT zone_column from zone where reference_zone = '", P(sim, "nameZonePriorityRaster", "dataCastor"),"'"))$zone_column
        
        sql<-paste0("SELECT pixelid, p.blockid, compartid, yieldid, height, elv, dist, (age*thlb) as age_h, thlb, (thlb*vol) as vol_h, (thlb*salvage_vol) as salvage_vol ", partition_case, " 
FROM pixels p
INNER JOIN 
(SELECT blockid, ROW_NUMBER() OVER ( 
		ORDER BY ", P(sim, "harvestBlockPriority", "forestryCastor"), ") as block_rank FROM blocks) b
on p.blockid = b.blockid
INNER JOIN 
(SELECT ", name.zone.priority,", ROW_NUMBER() OVER ( 
		ORDER BY ", P(sim, "harvestZonePriority", "forestryCastor"), ") as zone_rank FROM zonePriority) a
on p.",name.zone.priority," = a.",name.zone.priority,"
WHERE compartid = '", compart ,"' AND zone_const = 0 AND p.blockid > 0 AND thlb > 0 AND (", partition_sql, ")
ORDER by zone_rank, block_rank, ", P(sim, "harvestBlockPriority", "forestryCastor"), "
                           LIMIT ", as.integer(sum(harvestTarget)/50))
       
      }else{
        message("Using block priority")
        
        sql<-paste0("SELECT pixelid, p.blockid as blockid, compartid, yieldid, height, elv, dist, (age*thlb) as age_h, thlb, (thlb*vol) as vol_h, (thlb*salvage_vol) as salvage_vol ", partition_case, "
FROM pixels p
INNER JOIN 
(SELECT blockid, ROW_NUMBER() OVER ( 
		ORDER BY ", P(sim, "harvestBlockPriority", "forestryCastor"), ") as block_rank FROM blocks) b
on p.blockid = b.blockid
WHERE compartid = '", compart ,"' AND zone_const = 0 AND thlb > 0 AND p.blockid > 0 AND (", partition_sql, ")
ORDER by block_rank, ", P(sim, "harvestBlockPriority", "forestryCastor"), "
                           LIMIT ", as.integer(sum(harvestTarget)/50))
          
      }

      queue<-data.table(dbGetQuery(sim$castordb, sql))
    
      if(nrow(queue) == 0) {
        message("No stands to harvest")
        land_coord <- NULL
          next #no cutblocks in the queue go to the next compartment
      }else{
        
        #Adjust the harvestFlow based on the growing stock constraint
        if(!(P(sim, "growingStockConstraint", "forestryCastor") == 9999)){
          harvestTarget<- min(max(0, sim$growingStockReport[timeperiod == time(sim)*sim$updateInterval, m_gs] - sim$growingStockReport[timeperiod == 0, m_gs]*P(sim, "growingStockConstraint", "forestryCastor")), harvestTarget)
          print(paste0("Adjust harvest flow | gs constraint: ", harvestTarget))
        }
        
        queue<-queue[is.na(vol_h), vol_h:=0][, seqid := seq_len(.N)]
        
        if(length(harvestTarget)>1){
          h_pixels<-lapply(c(1:length(harvestTarget)), function(x){
            if(harvestType[x] == 'dead'){
              dead <-queue[eval(parse(text=paste("part", x, sep = ""))) == 1, ]
              dead[, cvalue:=cumsum(salvage_vol*eval(parse(text=paste("part", x, sep = ""))))][cvalue <= harvestTarget[x],]$pixelid
            }else{
              live <-queue[eval(parse(text=paste("part", x, sep = ""))) == 1, ]
              live[, cvalue:=cumsum(vol_h*eval(parse(text=paste("part", x, sep = ""))))][cvalue <= harvestTarget[x],]$pixelid
            }
          })
        }else{
          
          if(harvestType == 'dead'){
              h_pixels<-queue[, cvalue:=cumsum(salvage_vol)][cvalue <= harvestTarget,]$pixelid
          }else{
              h_pixels<-queue[, cvalue:=cumsum(vol_h)][cvalue <= harvestTarget,]$pixelid
            }
        }
        
        queue <- queue[pixelid %in% unique(unlist(h_pixels)),]
        #queue [, timeperiod := as.integer(time(sim)*sim$updateInterval)]
        sim$harvestPixelList <-  rbindlist(list(sim$harvestPixelList, queue), use.names = TRUE ) 
        
        #Update the pixels table
        if(length(harvestType) > 1){
          for(i in 1:length(harvestType)){
            if(harvestType[i] == 'live'){
              print("live")
              out<-queue[eval(parse(text=paste("part", i, sep = "")))==1, ]
              
              dbBegin(sim$castordb)
              rs<-dbSendQuery(sim$castordb, "UPDATE pixels SET age = 0, yieldid = yieldid_trans, vol = 0, salvage_vol = 0 WHERE pixelid = :pixelid", out[, "pixelid"])
              dbClearResult(rs)
              dbCommit(sim$castordb)
              
              dbExecute(sim$castordb, paste0("Update pixels set culvar = culvar.tvol from culvar where culvar.yieldid = pixels.yieldid AND pixelid in(",paste(out$pixelid, collapse = ", "),");"))
              
              temp.harvestBlockList<-out[, list(sum(vol_h), mean(height), mean(elv)), by = c("blockid", "compartid")]
              setnames(temp.harvestBlockList, c("V1", "V2", "V3"), c("proj_vol", "proj_height_1", "elv"))
              sim$harvestBlockList<- rbindlist(list(sim$harvestBlockList, temp.harvestBlockList))
              
              temp_harvest_report<-data.table(scenario= sim$scenario$name, timeperiod = time(sim)*sim$updateInterval, compartment = compart, target = harvestTarget[i]/sim$updateInterval , area= sum(out$thlb)/sim$updateInterval , volume = sum(out$vol_h)/sim$updateInterval, age = sum(out$age_h)/sim$updateInterval, hsize = nrow(temp.harvestBlockList),transition_area  = out[yieldid > 0, sum(thlb)]/sim$updateInterval,  transition_volume  = out[yieldid > 0, sum(vol_h)]/sim$updateInterval) #,  harvest_type = 'live'
              temp_harvest_report<-temp_harvest_report[, age:=age/area][, hsize:=area/hsize][, avail_thlb:=as.numeric(dbGetQuery(sim$castordb, paste0("SELECT sum(thlb) from pixels where zone_const = 0 and ", partition_raw[i] )))]
              sim$harvestReport<- rbindlist(list(sim$harvestReport, temp_harvest_report), use.names = TRUE)
              
              
            }else{
              print("dead")
              out<-queue[eval(parse(text=paste("part", i, sep = "")))==1, ]
              
              dbBegin(sim$castordb)
              rs<-dbSendQuery(sim$castordb, "UPDATE pixels SET age = 0, vol = 0, salvage_vol = 0 WHERE pixelid = :pixelid", out[, "pixelid"])
              dbClearResult(rs)
              dbCommit(sim$castordb)
              
              dbExecute(sim$castordb, paste0("Update pixels set culvar = culvar.tvol from culvar where culvar.yieldid = pixels.yieldid AND pixelid in(",paste(out$pixelid, collapse = ", "),");"))
              
              temp.harvestBlockList<-out[, list(sum(salvage_vol), mean(height), mean(elv)), by = c("blockid", "compartid")]
              setnames(temp.harvestBlockList, c("V1", "V2", "V3"), c("proj_vol", "proj_height_1", "elv"))
              sim$harvestBlockList<- rbindlist(list(sim$harvestBlockList, temp.harvestBlockList))
              
              temp_harvest_report<-data.table(scenario= sim$scenario$name, timeperiod = time(sim)*sim$updateInterval, compartment = compart, target = harvestTarget[i]/sim$updateInterval , area= sum(out$thlb)/sim$updateInterval , volume = sum(out$salvage_vol)/sim$updateInterval, age = sum(out$age_h)/sim$updateInterval, hsize = nrow(temp.harvestBlockList),transition_area  = out[yieldid > 0, sum(thlb)]/sim$updateInterval,  transition_volume  = out[yieldid > 0, sum(salvage_vol)]/sim$updateInterval) # , harvest_type = 'dead'
              temp_harvest_report<-temp_harvest_report[, age:=age/area][, hsize:=area/hsize][, avail_thlb:=as.numeric(dbGetQuery(sim$castordb, paste0("SELECT sum(thlb) from pixels where zone_const = 0 and ", partition_raw[i] )))]
              sim$harvestReport<- rbindlist(list(sim$harvestReport, temp_harvest_report), use.names = TRUE)
              
            }
          }
        }else{
          
         if(harvestType == 'dead'){
           
           dbBegin(sim$castordb)
           rs<-dbSendQuery(sim$castordb, "UPDATE pixels SET age = 0, vol = 0, salvage_vol = 0 WHERE pixelid = :pixelid", queue[, "pixelid"])
           dbClearResult(rs)
           dbCommit(sim$castordb)
           
           dbExecute(sim$castordb, paste0("Update pixels set culvar = culvar.tvol from culvar where culvar.yieldid = pixels.yieldid AND pixelid in(",paste(queue$pixelid, collapse = ", "),");"))
           
            temp.harvestBlockList<-queue[, list(sum(salvage_vol), mean(height), mean(elv)), by = c("blockid", "compartid")]
            setnames(temp.harvestBlockList, c("V1", "V2", "V3"), c("proj_vol", "proj_height_1", "elv"))
            sim$harvestBlockList<- rbindlist(list(sim$harvestBlockList, temp.harvestBlockList))
            
            
            temp_harvest_report<-data.table(scenario= sim$scenario$name, timeperiod = time(sim)*sim$updateInterval, compartment = compart, target = harvestTarget/sim$updateInterval , area= sum(queue$thlb)/sim$updateInterval , volume = sum(queue$salvage_vol)/sim$updateInterval, age = sum(queue$age_h)/sim$updateInterval, hsize = nrow(temp.harvestBlockList),transition_area  = queue[yieldid > 0, sum(thlb)]/sim$updateInterval,  transition_volume  = queue[yieldid > 0, sum(salvage_vol)]/sim$updateInterval) # , harvest_type = 'dead'
            temp_harvest_report<-temp_harvest_report[, age:=age/area][, hsize:=area/hsize][, avail_thlb:=as.numeric(dbGetQuery(sim$castordb, paste0("SELECT sum(thlb) from pixels where zone_const = 0 and ", partition_sql )))]
            sim$harvestReport<- rbindlist(list(sim$harvestReport, temp_harvest_report), use.names = TRUE)
            
          }else{
            
            dbBegin(sim$castordb)
            rs<-dbSendQuery(sim$castordb, "UPDATE pixels SET age = 0, yieldid = yieldid_trans, vol = 0, salvage_vol = 0 WHERE pixelid = :pixelid", queue[, "pixelid"])
            dbClearResult(rs)
            dbCommit(sim$castordb)
            
            dbExecute(sim$castordb, paste0("Update pixels set culvar = culvar.tvol from culvar where culvar.yieldid = pixels.yieldid AND pixelid in(",paste(queue$pixelid, collapse = ", "),");"))
            
            temp.harvestBlockList<-queue[, list(sum(vol_h), mean(height), mean(elv)), by = c("blockid", "compartid")]
            setnames(temp.harvestBlockList, c("V1", "V2", "V3"), c("proj_vol", "proj_height_1", "elv"))
            sim$harvestBlockList<- rbindlist(list(sim$harvestBlockList, temp.harvestBlockList))
            
            temp_harvest_report<-data.table(scenario= sim$scenario$name, timeperiod = time(sim)*sim$updateInterval, compartment = compart, target = harvestTarget/sim$updateInterval , area= sum(queue$thlb)/sim$updateInterval , volume = sum(queue$vol_h)/sim$updateInterval, age = sum(queue$age_h)/sim$updateInterval, hsize = nrow(temp.harvestBlockList),transition_area  = queue[yieldid > 0, sum(thlb)]/sim$updateInterval,  transition_volume  = queue[yieldid > 0, sum(vol_h)]/sim$updateInterval) # , harvest_type = 'live'
            temp_harvest_report<-temp_harvest_report[, age:=age/area][, hsize:=area/hsize][, avail_thlb:=as.numeric(dbGetQuery(sim$castordb, paste0("SELECT sum(thlb) from pixels where zone_const = 0 and ", partition_sql )))]
            sim$harvestReport<- rbindlist(list(sim$harvestReport, temp_harvest_report), use.names = TRUE)
            
          }
        }
        
        #Save the harvesting raster
        sim$harvestBlocks[queue$pixelid]<-time(sim)*sim$updateInterval
        sim$harvestBlocksVolume[queue$pixelid]<-queue$vol_h
        
        #Create landings. pixelid is the cell label that corresponds to pts. To get the landings need a pixel within the blockid so just grab a pixelid for each blockid
        land_pixels<-rbindlist(list(land_pixels, data.table(dbGetQuery(sim$castordb, paste0("select landing from blocks where blockid in (",
                                paste(unique(queue$blockid), collapse = ", "), ");")))))
        
        
        message(paste0(compart, " harvest Achieved: ", temp_harvest_report$volume, " "))
        #clean up
        rm(queue, temp_harvest_report, temp.harvestBlockList)
      }
    } else{
      message(paste0("No volume demanded in ", compart))
      next #No volume demanded in this compartment
    }
  }
 
  #convert to class SpatialPoints needed for roadCastor
  if(length(land_pixels) > 0){
    sim$landings <- land_pixels$landing
  }else{
    message("no landings")
    sim$landings <- NULL
  }
  
  #stop()
  return(invisible(sim))
}

reportConstraints<- function(sim) {
  message("write constraints report")
  sim$zoneManagement<-data.table(dbGetQuery(sim$castordb, "SELECT * FROM zoneManagement"))
  return(invisible(sim))
}


updateZonePriorityTable<-function(sim) {
  dbExecute(sim$castordb, "DROP TABLE zonePriority")
  pzone<-dbGetQuery(sim$castordb, paste0("SELECT zone_column from zone where reference_zone = '", P(sim, "nameZonePriorityRaster", "dataCastor"),"'"))[[1]]
  dbExecute(sim$castordb, paste0("CREATE TABLE zonePriority as SELECT ", pzone,", ", pzone," as zoneid, avg(age) as age, avg(dist) as dist, avg(vol*thlb) as vol FROM pixels WHERE thlb > 0 GROUP BY ", 
                               pzone))
  return(invisible(sim))
}

runCoCela<-function(sim){
  library(rJava) #Calling the rJava library instantiates the JVM. Note: cannot instantiate the same JVM on both the cores and the master. 
  library(jdx)
  .jinit(classpath= paste0(here::here(),"/Java/castor/bin"), parameters="-Xmx2g", force.init = TRUE) #instantiate the JVM
  .jaddClassPath(paste0(here::here(), "/Java/castor/sqlite-jdbc-3.41.2.1.jar"))
  fhClass<-.jnew("castor.CellularAutomata")
  fhClass$getCastorData()
  fhClass$coEvolutionaryCellularAutomata()
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  if(!suppliedElsewhere("harvestSequence", sim)){
    harvestSequence <- NULL
  }
  
  if(!suppliedElsewhere("harvestFlow", sim)){
    harvestFlow <- NULL
  }
  
  if(!suppliedElsewhere("harvestSchedule", sim)){
    harvestSchedule <- NULL
  }
  return(invisible(sim))
}

