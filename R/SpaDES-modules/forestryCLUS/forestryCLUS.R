
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
  documentation = list("README.txt", "forestryCLUS.Rmd"),
  reqdPkgs = list(),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant"),
    defineParameter("harvestPriority", "character", "age DESC", NA, NA, "This sets the order from which harvesting should be conducted. Greatest priority first. DESC is decending, ASC is ascending")
    
    ),
  inputObjects = bind_rows(
    expectsInput(objectName ="clusdb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates clus realted information", sourceURL = NA),
    expectsInput(objectName = "harvestFlow", objectClass = "data.table", desc = "Time series table of the total targeted harvest in m3", sourceURL = NA),
    expectsInput(objectName ="growingStockReport", objectClass = "data.table", desc = NA, sourceURL = NA),
    expectsInput(objectName ="pts", objectClass = "data.table", desc = "A data.table of X,Y locations - used to find distances", sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "raster", desc = "A raster of the study area", sourceURL = NA),
    expectsInput(objectName ="scenario", objectClass ="data.table", desc = 'The name of the scenario and its description', sourceURL = NA)
    ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = "compartment_list", objectClass = "character", desc = NA),
    createsOutput(objectName = "landings", objectClass = "SpatialPoints", desc = NA),
    createsOutput(objectName = "harvestPeriod", objectClass = "integer", desc = NA),
    createsOutput(objectName = "harvestReport", objectClass = "data.table", desc = NA),
    createsOutput(objectName = "harvestBlocks", objectClass = "raster", desc = NA),
    createsOutput(objectName ="scenario", objectClass ="data.table", desc = 'A user supplied name and description of the scenario. The column heading are name and description.')
  )
))

doEvent.forestryCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- forestryCLUS.Init(sim) #note target flow is a data.table object-- dont need to get it.
      #sim <- forestryCLUS.setConstraints(sim) 
      sim <- scheduleEvent(sim, time(sim)+ sim$harvestPeriod, "forestryCLUS", "schedule", 5)
      sim <- scheduleEvent(sim, end(sim) , "forestryCLUS", "save", 20)
    },
    schedule = {
      sim <- forestryCLUS.setConstraints(sim)
      sim<-forestryCLUS.getHarvestQueue(sim) # This returns a candidate set of blocks or pixels that could be harvested
      #sim<-forestryCLUS.checkAdjConstraints(sim)# check the constraints, removing from the queue adjacent blocks
      
      sim <- scheduleEvent(sim, time(sim) + sim$harvestPeriod, "forestryCLUS", "schedule", 5)
      
    },
    save = {
      sim <- forestryCLUS.save(sim)
    },
    
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

forestryCLUS.Init <- function(sim) {
  if(nrow(scenario) == 0) { stop('Include a scenario description as a data.table object with columns name and description')}
  
  sim$harvestPeriod <- 1 #This will be able to change in the future to 5 year or decadal
  sim$compartment_list<-unique(harvestFlow[, compartment]) #Used in a few functions this calling it once here - its currently static throughout the sim
  sim$harvestReport <- data.table(time = integer(), compartment = character(), area= numeric(), volume = numeric())
  #dbExecute(sim$clusdb, "VACUUM;") #Clean the db before starting the simulation
  
  #For the zone constraints of type 'nh' set thlb to zero so that they are removed from harvesting -- yet they will still contribute to other zonal constraints
  nhConstraints<-data.table(merge(dbGetQuery(sim$clusdb, paste0("SELECT  zoneid, reference_zone FROM zoneConstraints WHERE type ='nh'")),
                       dbGetQuery(sim$clusdb, "SELECT zone_column, reference_zone FROM zone"), 
                       by.x = "reference_zone", by.y = "reference_zone"))
  if(nrow(nhConstraints) > 0 ){
    nhConstraints[,qry:= paste( zone_column,'=',zoneid)]
    dbExecute(sim$clusdb, paste0("UPDATE pixels SET thlb = 0 WHERE ", paste(nhConstraints$qry, collapse = " OR ")))
  }
  
  #For printing out rasters of harvest blocks
  sim$harvestBlocks<-sim$ras
  sim$harvestBlocks[]<-0
  
  return(invisible(sim))
}

forestryCLUS.save<- function(sim) {
  #write.csv(sim$harvestReport, "harvestReport.csv")
  return(invisible(sim))
}

forestryCLUS.setConstraints<- function(sim) {
  message("...setting constraints")
  dbExecute(sim$clusdb, "UPDATE pixels SET zone_const = 0 WHERE zone_const = 1")
  message("....assigning zone_const")
  zones<-dbGetQuery(sim$clusdb, "SELECT zone_column FROM zone")
  for(i in 1:nrow(zones)){ #for each of the specified zone rasters
    numConstraints<-dbGetQuery(sim$clusdb, paste0("SELECT DISTINCT variable, type FROM zoneConstraints WHERE
                               zone_column = '",  zones[[1]][i] ,"' AND type IN ('ge', 'le')"))
    if(nrow(numConstraints) > 0){
      for(k in 1:nrow(numConstraints)){
        query_parms<-data.table(dbGetQuery(sim$clusdb, paste0("SELECT t_area, type, zoneid, variable, zone_column, percentage, threshold, 
                                                        CASE WHEN type = 'ge' THEN ROUND((percentage*1.0/100)*t_area, 0)
                                                             ELSE ROUND((1-(percentage*1.0/100))*t_area, 0)
                                                        END AS limits
                                                        FROM zoneConstraints WHERE zone_column = '", zones[[1]][i],"' AND variable = '", 
                                                            numConstraints[[1]][k],"' AND type = '",numConstraints[[2]][k] ,"';")))
       #TODO: Allow user to write own constraints according to many fields - right now only one variable
       switch(
          as.character(query_parms[1, "type"]),
            ge = {
              sql<-paste0("UPDATE pixels 
                      SET zone_const = 1
                      WHERE pixelid IN ( 
                      SELECT pixelid FROM pixels WHERE own = 1 AND ", as.character(query_parms[1, "zone_column"])," = :zoneid", 
                      " ORDER BY CASE WHEN ",as.character(query_parms[1, "variable"])," > :threshold  THEN 0 ELSE 1 END, thlb, zone_const DESC, ", as.character(query_parms[1, "variable"])," DESC
                      LIMIT :limits);")
              
              #Update pixels in clusdb for zonal constraints
              dbBegin(sim$clusdb)
              rs<-dbSendQuery(sim$clusdb, sql, query_parms[,c("zoneid", "threshold", "limits")])
              dbClearResult(rs)
              dbCommit(sim$clusdb)
          
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
                            LIMIT :limits);") #limits equal the area that needs preservation 
                #Preserve the non thlb, and areas already zone constrainted
                #Update pixels in clusdb for zonal constraints
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
  #Update pixels in clusdb for adjacency constraints
  query_parms<-data.table(dbGetQuery(sim$clusdb, paste0("SELECT pixelid FROM pixels WHERE blockid IN 
                                                            (SELECT blockid FROM blocks WHERE blockid > 0 AND age >= 0 AND age < 20 
                                                            UNION 
                                                            SELECT b.adjblockid FROM 
                                                            (SELECT blockid FROM blocks WHERE blockid > 0 AND age >= 0 AND age < 20 ) a 
                                                            LEFT JOIN adjacentBlocks b ON a.blockid = b.blockid ); ")))
  dbBegin(sim$clusdb)
  rs<-dbSendQuery(sim$clusdb, "UPDATE pixels set zone_const = 1 WHERE pixelid = :pixelid; ", query_parms)
  dbClearResult(rs)
  dbCommit(sim$clusdb)
  
  dbExecute(sim$clusdb, "VACUUM;")
  return(invisible(sim))
}

forestryCLUS.getHarvestQueue<- function(sim) {
  #Right now its looping by compartment -- could have it parallel?
  for(compart in sim$compartment_list){
    
    #TODO: Need to figure out the harvest period mid point to reduce bias in reporting?
    harvestTarget<-harvestFlow[compartment == compart,]$flow[time(sim)]
    if(!is.na(harvestTarget)){# Determine if there is a demand for volume to harvest
      message(paste0(compart, " harvest Target: ", harvestTarget))
      partition<-harvestFlow[compartment==compart, "partition"][time(sim)]
      harvestPriority<-harvestFlow[compartment==compart, partition][time(sim)]
      
      #Queue pixels for harvesting. Use a nested query so that all of the block will be selected -- meet patch size objectives
      sql<-paste0("SELECT pixelid, blockid, thlb, (thlb*vol) as vol_h FROM pixels WHERE blockid IN 
                   (SELECT distinct(blockid) FROM pixels WHERE 
                  compartid = '", compart ,"' AND zone_const = 0 AND ", partition, "
                  ORDER BY ", harvestPriority, " LIMIT ", as.integer(harvestTarget/60), ") 
                  AND thlb > 0 AND zone_const = 0 AND ", partition, 
                  " ORDER BY blockid ")
  
      queue<-data.table(dbGetQuery(sim$clusdb, sql))
      
      if(nrow(queue) == 0) {
        message("No stands to harvest")
          next #no cutblocks in the queue go to the next compartment
      }else{
        queue<-queue[, cvalue:=cumsum(vol_h)][cvalue <= harvestTarget,]
        
        #Update the pixels table
        dbBegin(sim$clusdb)
          rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET age = 0 WHERE pixelid = :pixelid", queue[, "pixelid"])
        dbClearResult(rs)
        dbCommit(sim$clusdb)
        
        #Save the harvesting raster
        sim$harvestBlocks[queue$pixelid]<-time(sim)
        writeRaster(sim$harvestBlocks, "harvestBlocks.tif", overwrite=TRUE)
        
        #Set the harvesting report
        sim$harvestReport<- rbindlist(list(sim$harvestReport, list(time(sim), compart, sum(queue$thlb) , sum(queue$vol_h))))
      
        #Create landings
        #pixelid is the cell label that corresponds to pts. To get the landings need a pixel within the blockid so just grab a pixelid for each blockid
        land_pixels<-queue[, .SD[which.max(vol_h)], by=blockid]$pixelid
        land_coord<-sim$pts[pixelid %in% land_pixels, ]
        
        #convert to class SpatialPoints
        sim$landings <- SpatialPoints(land_coord[,c("x", "y")],crs(sim$ras))
        
        #clean up
        rm(land_coord, land_pixels, queue)
      }
    } else{
      next #No volume demanded in this compartment
    }
  }
  return(invisible(sim))
}
forestryCLUS.calcUncertainty <-function(sim) {
  #Create a data.frame that houses the distribution of simulated achieved annual volume (aac)
  #aac.sim<-sapply(1:1000,
  #       function(x)
  #         with(to.cut[base$cut.me == 1,],
  #              sum(rGA(sum(base$cut.me), # if n = 1 then randoms are correlated!
  #                      mu = mu.hat,
  #                      sigma = sigma.hat)))) / 1000
  
  #the mean expected return?
  mean(aac.sim)
  
  #the probability of achieving the mean objective?
  mean(aac.sim > 1000000)
  
  #the 90% prediction interval?
  quantile(aac.sim, p = c(0.05, 0.95))
  return(invisible(sim))
}


.inputObjects <- function(sim) {
  return(invisible(sim))
}

