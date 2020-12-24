#===========================================================================================
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
  name = "forestryCLUS",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.3", forestryCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.md", "forestryCLUS.Rmd"),
  reqdPkgs = list(),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant"),
    defineParameter("adjacencyConstraint", "numeric", 9999, NA, NA, "Include Adjacency Constraint at the user specified height in metres"),
    defineParameter("growingStockConstraint", "numeric", 9999, NA, NA, "The percentage of standing merchantable timber that must be retained through out the planning horizon. values [0,1]"),
    defineParameter("harvestPriority", "character", "age DESC", NA, NA, "This sets the order from which harvesting should be conducted. Greatest priority first. DESC is decending, ASC is ascending"),
    defineParameter("accessPriority", "logical", FALSE, NA, NA, "This sets the order from which access zones should be prioritized.")
    
    ),
  inputObjects = bind_rows(
    expectsInput(objectName = "clusdb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates clus realted information", sourceURL = NA),
    expectsInput(objectName = "harvestFlow", objectClass = "data.table", desc = "Time series table of the total targeted harvest in m3", sourceURL = NA),
    expectsInput(objectName = "growingStockReport", objectClass = "data.table", desc = NA, sourceURL = NA),
    expectsInput(objectName = "pts", objectClass = "data.table", desc = "A data.table of X,Y locations - used to find distances", sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "raster", desc = "A raster of the study area", sourceURL = NA),
    expectsInput(objectName = "scenario", objectClass ="data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName = "updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA)
    
    ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = "compartment_list", objectClass = "character", desc = NA),
    createsOutput(objectName = "landings", objectClass = "SpatialPoints", desc = NA),
    createsOutput(objectName = "harvestPeriod", objectClass = "integer", desc = NA),
    createsOutput(objectName = "harvestReport", objectClass = "data.table", desc = NA),
    createsOutput(objectName = "harvestBlocks", objectClass = "raster", desc = NA),
    createsOutput(objectName = "harvestBlockList", objectClass = "data.table", desc = NA),
    createsOutput(objectName = "harvestPixelList", objectClass = "data.table", desc = NA),
    createsOutput(objectName = "ras.zoneConstraint", objectClass = "raster", desc = NA),
    createsOutput(objectName = "scenario", objectClass ="data.table", desc = 'A user supplied name and description of the scenario. The column heading are name and description.')
  )
))

doEvent.forestryCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init(sim) #note target flow is a data.table object-- dont need to get it.
      sim <- scheduleEvent(sim, time(sim)+ 1, "forestryCLUS", "schedule", 3)
      sim <- scheduleEvent(sim, end(sim) , "forestryCLUS", "save", 20)
    },
    schedule = {
      sim <- setConstraints(sim)
      sim <- getHarvestQueue(sim) # This returns a candidate set of blocks or pixels that could be harvested
      sim <- reportConstraints(sim)
      sim <- scheduleEvent(sim, time(sim) + 1, "forestryCLUS", "schedule", 3)
    },
    save = {
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
  
  sim$compartment_list<-unique(sim$harvestFlow[, compartment]) #Used in a few functions this calling it once here - its currently static throughout the sim
  sim$harvestReport <- data.table(scenario = character(), timeperiod = integer(), compartment = character(), target = numeric(), area= numeric(), volume = numeric(), age = numeric(), hsize = numeric(), avail_thlb= numeric(), transition_area = numeric(), transition_volume= numeric())
 
  #Remove zones as a scenario
  dbExecute(sim$clusdb, paste0("DELETE FROM zone WHERE reference_zone not in ('",paste(P(sim, "dataLoaderCLUS", "nameZoneRasters"), sep= ' ', collapse = "', '"),"')"))
  dbExecute(sim$clusdb, paste0("DELETE FROM zoneConstraints WHERE reference_zone not in ('",paste(P(sim, "dataLoaderCLUS", "nameZoneRasters"), sep= ' ', collapse = "', '"),"')"))
  
  #For the zone constraints of type 'nh' set thlb to zero so that they are removed from harvesting -- yet they will still contribute to other zonal constraints
  nhConstraints<-data.table(merge(dbGetQuery(sim$clusdb, paste0("SELECT  zoneid, reference_zone FROM zoneConstraints WHERE type ='nh'")),
                       dbGetQuery(sim$clusdb, "SELECT zone_column, reference_zone FROM zone"), 
                       by.x = "reference_zone", by.y = "reference_zone"))
  
  if(nrow(nhConstraints) > 0 ){
    nhConstraints[,qry:= paste( zone_column,'=',zoneid)]
    dbExecute(sim$clusdb, paste0("UPDATE pixels SET thlb = 0 WHERE ", paste(nhConstraints$qry, collapse = " OR ")))
  }
 
  #Create the zoneManagement table
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS zoneManagement (zoneid integer, reference_zone text, zone_column text, ndt integer, variable text, threshold numeric, type text, percentage numeric, multi_condition text, t_area numeric)")
  
  #For printing out rasters of harvest blocks
  sim$harvestBlocks<-sim$ras
  sim$harvestBlocks[]<-0
  
  #Set the zone contraint raster
  sim$ras.zoneConstraint<-sim$ras
  sim$ras.zoneConstraint[]<-0
  
  #Set the yield uncertainty covariate string to a blank
  sim$yieldUncertaintyCovar<-""
  
  return(invisible(sim))
}

saveForestry<- function(sim) {
  #write.csv(sim$harvestReport, "harvestReport.csv")
  writeRaster(sim$harvestBlocks, paste0(sim$scenario$name, "_",P(sim, "dataLoaderCLUS", "nameBoundary"), "_harvestBlocks.tif"), overwrite=TRUE)#write the blocks to a raster?
  writeRaster(sim$ras.zoneConstraint, paste0(sim$scenario$name, "_", P(sim, "dataLoaderCLUS", "nameBoundary"), "_constraints.tif"), overwrite=TRUE)
  return(invisible(sim))
}

setConstraints<- function(sim) {
  message("...setting constraints")
  dbExecute(sim$clusdb, "UPDATE pixels SET zone_const = 0 WHERE zone_const = 1")
  
  message("....assigning zone_const")
  zones<-dbGetQuery(sim$clusdb, "SELECT zone_column FROM zone")
  for(i in 1:nrow(zones)){ #for each of the specified zone rasters
    numConstraints<-dbGetQuery(sim$clusdb, paste0("SELECT DISTINCT variable, type FROM zoneConstraints WHERE
                               zone_column = '",  zones[[1]][i] ,"' AND type IN ('ge', 'le')"))
    
    if(nrow(numConstraints) > 0){
      for(k in 1:nrow(numConstraints)){
        query_parms<-data.table(dbGetQuery(sim$clusdb, paste0("SELECT t_area, type, zoneid, variable, zone_column, percentage, threshold, multi_condition, 
                                                        CASE WHEN type = 'ge' THEN ROUND((percentage*1.0/100)*t_area, 0)
                                                             ELSE ROUND((1-(percentage*1.0/100))*t_area, 0)
                                                        END AS limits
                                                        FROM zoneConstraints WHERE zone_column = '", zones[[1]][i],"' AND variable = '", 
                                                            numConstraints[[1]][k],"' AND type = '",numConstraints[[2]][k] ,"';")))
        query_parms<-query_parms[!is.na(limits) | limits > 0, ]
    
       switch(
          as.character(query_parms[1, "type"]),
            ge = {
              if(as.character(query_parms[1, "variable"]) == 'dist' ){
                sql<-paste0("UPDATE pixels SET zone_const = 1
                        WHERE pixelid IN ( 
                        SELECT pixelid FROM pixels WHERE own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid", 
                        " ORDER BY CASE WHEN ", as.character(query_parms[1, "variable"]),"> :threshold then 0 else 1 end, ",as.character(query_parms[1, "variable"])," DESC,  age DESC
                        LIMIT :limits);")
                dbBegin(sim$clusdb)
                rs<-dbSendQuery(sim$clusdb, sql, query_parms[,c("zoneid", "threshold", "limits")])
                dbClearResult(rs)
                dbCommit(sim$clusdb)
              }else if(!is.na(query_parms[1, "multi_condition"])){ #Allow user to write own constraints according to many fields - right now only one variable
                sql<-paste0("UPDATE pixels SET zone_const = 1
                        WHERE pixelid IN ( 
                        SELECT pixelid FROM pixels WHERE own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid", 
                            " ORDER BY CASE WHEN ", as.character(query_parms[1, "multi_condition"])," then 0 ELSE 1 END,  thlb, zone_const DESC, age DESC
                        LIMIT :limits);")
                dbBegin(sim$clusdb)
                rs<-dbSendQuery(sim$clusdb, sql, query_parms[,c("zoneid", "limits")])
                dbClearResult(rs)
                dbCommit(sim$clusdb)
              }else{
                sql<-paste0("UPDATE pixels 
                        SET zone_const = 1
                        WHERE pixelid IN ( 
                        SELECT pixelid FROM pixels WHERE own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid", 
                            " ORDER BY CASE WHEN ",as.character(query_parms[1, "variable"])," > :threshold  THEN 0 ELSE 1 END, thlb, zone_const DESC, ", as.character(query_parms[1, "variable"])," DESC
                        LIMIT :limits);")
                dbBegin(sim$clusdb)
                rs<-dbSendQuery(sim$clusdb, sql, query_parms[,c("zoneid", "threshold", "limits")])
                dbClearResult(rs)
                dbCommit(sim$clusdb)
              }
            },
            le = {
              if(as.character(query_parms[1, "variable"]) == 'eca' ){
                
                #get the correct limits -- currently assuming the entire area is at the threshold
                eca_current<-data.table(dbGetQuery(sim$clusdb, paste0("SELECT ",as.character(query_parms[1, "zone_column"]),", sum(eca*thlb) as eca FROM pixels WHERE ",
                                                         as.character(query_parms[1, "zone_column"]), " IN (",
                                                         paste(query_parms$zoneid, collapse=", "),") GROUP BY ",as.character(query_parms[1, "zone_column"]), 
                                                         " ORDER BY ",as.character(query_parms[1, "zone_column"])) ))
                
                
                query_parms<-merge(query_parms, eca_current, by.x ="zoneid", by.y =as.character(query_parms[1, "zone_column"]) , all.x =TRUE )
                query_parms[,limits:=as.integer((1-(threshold/100 - eca/t_area))*t_area)]
                sql<-paste0("UPDATE pixels 
                      SET zone_const = 1
                            WHERE pixelid IN ( 
                            SELECT pixelid FROM pixels WHERE own = 1 AND ",  as.character(query_parms[1, "zone_column"])," = :zoneid",
                            " ORDER BY thlb, zone_const DESC, eca DESC 
                            LIMIT :limits);") #limits = the area that needs preservation 
                
                #query_parms<-query_parms[, limits := as.integer (limits)]
                
                dbBegin(sim$clusdb)
                rs<-dbSendQuery(sim$clusdb, sql, query_parms[!is.na (limits), c("zoneid", "limits")])
                dbClearResult(rs)
                dbCommit(sim$clusdb)
                
              }else if(!is.na(query_parms[1, "multi_condition"])){ #Allow user to write own constraints according to many fields - right now only one variable
                  sql<-paste0("UPDATE pixels SET zone_const = 1
                        WHERE pixelid IN ( 
                        SELECT pixelid FROM pixels WHERE own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid", 
                              " ORDER BY CASE WHEN ", as.character(query_parms[1, "multi_condition"])," then 1 ELSE 0 END,  thlb, zone_const DESC, age
                        LIMIT :limits);")
    
                  dbBegin(sim$clusdb)
                  rs<-dbSendQuery(sim$clusdb, sql, query_parms[,c("zoneid", "limits")])
                  dbClearResult(rs)
                  dbCommit(sim$clusdb)  
              }else{
                sql<-paste0("UPDATE pixels 
                      SET zone_const = 1
                      WHERE pixelid IN ( 
                      SELECT pixelid FROM pixels WHERE own = 1 AND ",  as.character(query_parms[1, "zone_column"])," = :zoneid",
                      " ORDER BY CASE WHEN ",as.character(query_parms[1, "variable"])," < :threshold THEN 1 ELSE 0 END, thlb, zone_const DESC,", as.character(query_parms[1, "variable"])," 
                      LIMIT :limits);") 
                
                #Update pixels in clusdb for zonal constraints
                dbBegin(sim$clusdb)
                rs<-dbSendQuery(sim$clusdb, sql, query_parms[,c("zoneid", "threshold", "limits")])
                dbClearResult(rs)
                dbCommit(sim$clusdb)
              }
            }, 
            warning(paste0("Undefined 'type' in zoneConstraints: ", query_parms[1, "type"]))
        )
      } 
    } 
  }
  
  if(!(P(sim, "forestryCLUS", "adjacencyConstraint") == 9999)){
    #Update pixels in clusdb for adjacency constraints
    message("...Adjacency")
    query_parms<-data.table(dbGetQuery(sim$clusdb, paste0("SELECT pixelid FROM pixels WHERE blockid IN 
                                                            (SELECT blockid FROM blocks WHERE blockid > 0 AND height >= 0 AND height <= ",P(sim, "forestryCLUS", "adjacencyConstraint") ,
                                                            " UNION 
                                                            SELECT b.adjblockid FROM 
                                                            (SELECT blockid FROM blocks WHERE blockid > 0 AND height >= 0 AND height <= ",P(sim, "forestryCLUS", "adjacencyConstraint"),") a 
                                                            LEFT JOIN adjacentBlocks b ON a.blockid = b.blockid ); ")))
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "UPDATE pixels set zone_const = 1 WHERE pixelid = :pixelid; ", query_parms)
    dbClearResult(rs)
    dbCommit(sim$clusdb)
  }

  #write the constraint raster
  const<-sim$ras
  datat<-dbGetQuery(sim$clusdb, "SELECT zone_const FROM pixels ORDER BY pixelid;")
  const[]<-datat$zone_const
  
  sim$ras.zoneConstraint<-sim$ras.zoneConstraint + const
  
  rm(const)
  return(invisible(sim))
}

getHarvestQueue<- function(sim) {
  #Right now its looping by compartment -- So far it will be serializable at the aoi level then
  for(compart in sim$compartment_list){
    
    #TODO: Need to figure out the harvest period mid point to reduce bias in reporting? --Not important for 1 year time steps
    harvestTarget<-sim$harvestFlow[compartment == compart,]$flow[time(sim)]
    
    if(length(harvestTarget)>0){# Determine if there is a demand for timber volume 
      message(paste0(compart, " harvest Target: ", harvestTarget))
      partition<-sim$harvestFlow[compartment==compart, "partition"][time(sim)]
      
      #Queue pixels for harvesting. Use a nested query so that all of the block will be selected -- meet patch size objectives
      if(P(sim,"forestryCLUS", "accessPriority")){
        message("accessPriority")
        sql<-paste0("SELECT pixelid, p.blockid, compartid, yieldid, height, elv, (age*thlb) as age_h, thlb, (thlb*vol) as vol_h
FROM pixels p
INNER JOIN 
(SELECT blockid, ROW_NUMBER() OVER ( 
		ORDER BY ", P(sim, "forestryCLUS", "harvestPriority"), ") as block_rank FROM blocks) b
on p.blockid = b.blockid
INNER JOIN 
(SELECT zone1, ROW_NUMBER() OVER ( 
		ORDER BY ", P(sim, "forestryCLUS", "harvestPriority"), ") as compartment_rank FROM compartment) a
on p.zone1 = a.zone1
WHERE compartid = '", compart ,"' AND zone_const = 0 AND p.blockid > 0 AND ", partition, "
ORDER by compartment_rank, block_rank, ", P(sim, "forestryCLUS", "harvestPriority"), "
                           LIMIT ", as.integer(harvestTarget/50))
      }else{
        sql<-paste0("SELECT pixelid, p.blockid as blockid, compartid, yieldid, height, elv, (age*thlb) as age_h, thlb, (thlb*vol) as vol_h
FROM pixels p
INNER JOIN 
(SELECT blockid, ROW_NUMBER() OVER ( 
		ORDER BY ", P(sim, "forestryCLUS", "harvestPriority"), ") as block_rank FROM blocks) b
on p.blockid = b.blockid
WHERE compartid = '", compart ,"' AND zone_const = 0 AND thlb > 0 AND p.blockid > 0 AND ", partition, "
ORDER by block_rank, ", P(sim, "forestryCLUS", "harvestPriority"), "
                           LIMIT ", as.integer(harvestTarget/50))
        
      }
      queue<-data.table(dbGetQuery(sim$clusdb, sql))
      
      if(nrow(queue) == 0) {
        message("No stands to harvest")
        land_coord <- NULL
          next #no cutblocks in the queue go to the next compartment
      }else{
        
        #Adjust the harvestFlow based on the growing stock constraint
        if(!(P(sim, "forestryCLUS", "growingStockConstraint") == 9999)){
          harvestTarget<- min(max(0, sim$growingStockReport[timeperiod == time(sim)*sim$updateInterval, m_gs] - sim$growingStockReport[timeperiod == 0, m_gs]*P(sim, "forestryCLUS", "growingStockConstraint")), harvestTarget)
          print(paste0("Adjust harvest flow | gs constraint: ", harvestTarget))
        }
        
        queue<-queue[, cvalue:=cumsum(vol_h)][cvalue <= harvestTarget,]
        
        #Update the pixels table
        dbBegin(sim$clusdb)
          rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET age = 0, yieldid = yieldid_trans, vol =0 WHERE pixelid = :pixelid", queue[, "pixelid"])
          #rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET age = 0 WHERE pixelid = :pixelid", queue[, "pixelid"])
        dbClearResult(rs)
        dbCommit(sim$clusdb)
        
        sim$harvestPixelList<-queue

        #Save the harvesting raster
        sim$harvestBlocks[queue$pixelid]<-time(sim)*sim$updateInterval
        
        #Create landings. pixelid is the cell label that corresponds to pts. To get the landings need a pixel within the blockid so just grab a pixelid for each blockid
        #land_pixels<-queue[, .SD[which.max(vol_h)], by=blockid]$pixelid
        land_pixels<-data.table(dbGetQuery(sim$clusdb, paste0("select landing from blocks where blockid in (",
                                paste(unique(queue$blockid), collapse = ", "), ");")))
        
        land_coord<-sim$pts[pixelid %in% land_pixels$landing, ]
        setnames(land_coord,c("x", "y"), c("X", "Y"))
        
        #Create proj_vol for uncertainty in yields
        temp.harvestBlockList<-queue[, list(sum(vol_h), mean(height), mean(elv)), by = c("blockid", "compartid")]
        setnames(temp.harvestBlockList, c("V1", "V2", "V3"), c("proj_vol", "proj_height_1", "elv"))
        sim$harvestBlockList<- rbindlist(list(sim$harvestBlockList, temp.harvestBlockList))
    

        #Set the harvesting report
        temp_harvest_report<-data.table(scenario= sim$scenario$name, timeperiod = time(sim)*sim$updateInterval, compartment = compart, target = harvestTarget/sim$updateInterval , area= sum(queue$thlb)/sim$updateInterval , volume = sum(queue$vol_h)/sim$updateInterval, age = sum(queue$age_h)/sim$updateInterval, hsize = nrow(temp.harvestBlockList),transition_area  = queue[yieldid > 0, sum(thlb)]/sim$updateInterval,  transition_volume  = queue[yieldid > 0, sum(vol_h)]/sim$updateInterval)
        temp_harvest_report<-temp_harvest_report[, age:=age/area][, hsize:=area/hsize][, avail_thlb:=as.numeric(dbGetQuery(sim$clusdb, paste0("SELECT sum(thlb) from pixels where zone_const = 0 and ", partition )))]
        sim$harvestReport<- rbindlist(list(sim$harvestReport, temp_harvest_report), use.names = TRUE)
      
        #clean up
        rm(land_pixels, queue, temp_harvest_report, temp.harvestBlockList)
      }
    } else{
      message("No volume demanded")
      next #No volume demanded in this compartment
    }
  }
  
  #convert to class SpatialPoints needed for roadsCLUS
  if(!is.null(land_coord)){
    sim$landings <- SpatialPoints(land_coord[,c("X", "Y")],crs(sim$ras))
  }else{
    message("no landings")
    sim$landings <- NULL
  }
  
  return(invisible(sim))
}

reportConstraints<- function(sim) {
  message("....reporting zone constraints")
  zones<-dbGetQuery(sim$clusdb, "SELECT zone_column FROM zone")
  for(i in 1:nrow(zones)){ #for each of the specified zone rasters
    numConstraints<-dbGetQuery(sim$clusdb, paste0("SELECT DISTINCT variable, type FROM zoneConstraints WHERE
                               zone_column = '",  zones[[1]][i] ,"' AND type IN ('ge', 'le')"))
    
    if(nrow(numConstraints) > 0){
      for(k in 1:nrow(numConstraints)){
        query_parms<-data.table(dbGetQuery(sim$clusdb, paste0("SELECT t_area, type, zoneid, variable, zone_column, percentage, threshold, multi_condition
                                                        FROM zoneConstraints WHERE zone_column = '", zones[[1]][i],"' AND variable = '", 
                                                              numConstraints[[1]][k],"' AND type = '",numConstraints[[2]][k] ,"';")))
        switch(
          as.character(query_parms[1, "type"]),
          ge = {
            sql<- paste0("INSERT INTO zoneManagement SELECT AVG(case when", numConstraints[[1]][k]  ," > :threshold then 1 else 0 end) as percent, zone1, ", as.integer(time(sim)) ," as timeperiod  from pixels group by zone1")
            
            dbBegin(sim$clusdb)
            rs<-dbSendQuery(sim$clusdb, sql, query_parms[,c("zoneid")])
            dbClearResult(rs)
            dbCommit(sim$clusdb)
          },
          le = {
            sql<- paste0("INSERT INTO zoneManagement SELECT AVG(case when", numConstraints[[1]][k]  ," < :threshold then 1 else 0 end) as percent, zone1, ", as.integer(time(sim)) ," as timeperiod  from pixels group by zone1")
            
            dbBegin(sim$clusdb)
            rs<-dbSendQuery(sim$clusdb, sql, query_parms[,c("zoneid", "limits")])
            dbClearResult(rs)
            dbCommit(sim$clusdb)
          }
        )
      }
    }
  }
  
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  return(invisible(sim))
}

