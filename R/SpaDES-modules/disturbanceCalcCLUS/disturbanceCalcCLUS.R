# Copyright 2020rsf_ Province of British Columbia
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

defineModule(sim, list(
  name = "disturbanceCalcCLUS",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", disturbanceCalcCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "disturbanceCalcCLUS.Rmd"),
  reqdPkgs = list("raster"),
  parameters = rbind(
    defineParameter("criticalHabitatTable", "character", '99999', NA, NA, "Value attribute table that links to the raster and describes the boundaries of the critical habitat"),
    defineParameter("criticalHabRaster", "character", '99999', NA, NA, "Raster that describes the boundaries of the critical habitat"),
    defineParameter("calculateInterval", "numeric", 1, NA, NA, "The simulation time at which disturbance indicators are calculated"),
    defineParameter("permDisturbanceRaster", "character", '99999', NA, NA, "Raster of permanent disturbances"),
    defineParameter("recovery", "numeric", 40, NA, NA, "The age of recovery for disturbances"),
    defineParameter("distBuffer", "integer", 500, NA, NA, "The buffer for disturbances"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput(objectName = "boundaryInfo", objectClass = "character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "clusdb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the RSF', sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "RasterLayer", desc = "A raster object created in dataLoaderCLUS. It is a raster defining the area of analysis (e.g., supply blocks/TSAs).", sourceURL = NA),
    expectsInput(objectName = "pts", objectClass = "data.table", desc = "Centroid x,y locations of the ras.", sourceURL = NA),
    expectsInput(objectName = "scenario", objectClass = "data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName ="updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA)
    #expectsInput(objectName ="harvestPixelList", objectClass ="data.table", desc = 'The list of pixels being harvesting in a time period', sourceURL = NA)
    ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput("disturbance", "data.table", "Disturbance table for every pixel"),
    createsOutput("disturbanceReport", "data.table", "Summary per simulation year of the disturbance indicators")
  )
))

doEvent.disturbanceCalcCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init (sim) # this function inits 
      sim <- scheduleEvent(sim, time(sim) , "disturbanceCalcCLUS", "analysis", 9)
    },
    analysis = {
      sim <- distAnalysis(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "disturbanceCalcCLUS", "calculateInterval"), "disturbanceCalcCLUS", "analysis", 9)
    },
    
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  sim$disturbanceReport<-data.table(scenario = character(), compartment = character(), 
                                    timeperiod= integer(), critical_hab = character(), 
                                    total_area = numeric(), cut20 = numeric(), cut40 = numeric(), 
                                    cut80 = numeric(), road50 = numeric(), road250 = numeric(), 
                                    road500 = numeric(), road750 = numeric(), c20r50 = numeric(), 
                                    c20r250=numeric(), c20r500=numeric(),  c20r750=numeric(),
                                    c40r50 = numeric(), c40r250=numeric(), c40r500=numeric(), 
                                    c40r750=numeric(), c80r50 = numeric(), c80r250=numeric(), 
                                    c80r500=numeric(),  c80r750=numeric(),
                                    c10_40r50=numeric(),  c10_40r500=numeric(), cut10_40=numeric() )
  sim$disturbance <- sim$pts
  message("...Get the critical habitat")
  if(P(sim, "disturbanceCalcCLUS", "criticalHabRaster") == '99999'){
    sim$disturbance[, critical_hab:= 1]
  }else{
    bounds <- data.table (c (t (raster::as.matrix( 
    RASTER_CLIP2(tmpRast = sim$boundaryInfo[[3]], 
                 srcRaster = P(sim, "disturbanceCalcCLUS", "criticalHabRaster"), 
                 clipper = sim$boundaryInfo[[1]],  # by the area of analysis (e.g., supply block/TSA)
                 geom = sim$boundaryInfo[[4]], 
                 where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                 conn = NULL)))))
    bounds[,pixelid:=seq_len(.N)] # make a unique id to ensure it merges correctly
    if(nrow(bounds[!is.na(V1),]) > 0){ #check to see if some of the aoi overlaps with the boundary
      if(!(P(sim, "disturbanceCalcCLUS", "criticalHabitatTable") == '99999')){
        crit_lu<-data.table(getTableQuery(paste0("SELECT cast(value as int) , crithab FROM ",P(sim, "disturbanceCalcCLUS", "criticalHabitatTable"))))
        bounds<-merge(bounds, crit_lu, by.x = "V1", by.y = "value", all.x = TRUE)
      }else{
        stop(paste0("ERROR: need to supply a lookup table: ", P(sim, "rsfCLUS", "criticalHabitatTable")))
      }
    }else{
      stop(paste0(P(sim, "disturbanceCalcCLUS", "criticalHabRaster"), "- does not overlap with aoi"))
    }
    setorder(bounds, pixelid) #sort the bounds
    sim$disturbance[, critical_hab:= bounds$crithab]
  }
  
  #get the permanent disturbance raster
  #check it a field already in sim$clusdb?
  if(dbGetQuery (sim$clusdb, "SELECT COUNT(*) as exists_check FROM pragma_table_info('pixels') WHERE name='perm_dist';")$exists_check == 0){
    # add in the column
    dbExecute(sim$clusdb, "ALTER TABLE pixels ADD COLUMN perm_dist integer DEFAULT 0")
    # add in the raster
    if(P(sim, "disturbanceCalcCLUS", "permDisturbanceRaster") == '99999'){
      message("WARNING: No permanent disturbance raster specified ... defaulting to no permanent disturbances")
      dbExecute(sim$clusdb, "Update pixels set perm_dist = 0;")
    }else{
    perm_dist <- data.table (c(t(raster::as.matrix( 
        RASTER_CLIP2(tmpRast = sim$boundaryInfo[[3]], 
                     srcRaster = P(sim, "disturbanceCalcCLUS", "permDisturbanceRaster"), 
                     clipper = sim$boundaryInfo[[1]],  # by the area of analysis (e.g., supply block/TSA)
                     geom = sim$boundaryInfo[[4]], 
                     where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                     conn = NULL)))))
    perm_dist[,pixelid:=seq_len(.N)]#make a unique id to ensure it merges correctly
    setnames(perm_dist, "V1", "perm_dist")
    #add to the clusdb
    dbBegin(sim$clusdb)
      rs<-dbSendQuery(sim$clusdb, "Update pixels set perm_dist = :perm_dist where pixelid = :pixelid", perm_dist)
    dbClearResult(rs)
    dbCommit(sim$clusdb)
    
    #clean up
    rm(perm_dist)
    gc()
    }
  }else{
    message("...using existing permanent disturbance raster")
  }
  
  return(invisible(sim))
}

distAnalysis <- function(sim) {
  #dt_select<-data.table(dbGetQuery(sim$clusdb, paste0("SELECT pixelid FROM pixels WHERE perm_dist > 0 or (roadyear >= ", max(0,as.integer(time(sim) - P(sim, "disturbanceCalcCLUS", "recovery"))),")  or (blockid > 0 and age BETWEEN 0 AND ",P(sim, "disturbanceCalcCLUS", "recovery"),")"))) # 
  #dt_select<-data.table(dbGetQuery(sim$clusdb, paste0("SELECT pixelid FROM pixels WHERE perm_dist > 0 or roadyear >= 0 or (blockid > 0 and age BETWEEN 0 AND ", P(sim, "disturbanceCalcCLUS", "recovery"),")"))) # 
  all.dist<-data.table(dbGetQuery(sim$clusdb, "SELECT age, blockid, roadyear, pixelid FROM pixels WHERE (blockid > 0 and age >= 0) or roadyear >=0;"))
  #sim.disturbance<<-sim$disturbance
  #sim.ras<<-sim$ras
  #stop()
  if(nrow(all.dist) > 0){
    outPts<-merge(sim$disturbance, all.dist, by = 'pixelid', all.x =TRUE) 
    message("Get the cutblock summaries")
    cutblock_summary<-Reduce(merge,
    list(outPts[, .(total_area = uniqueN(.I)), by = "critical_hab"],
         outPts[blockid > 0 & age >= 0 & age <= 20 & !is.na(critical_hab), .(cut20 = uniqueN(.I)), by = "critical_hab"],
         outPts[blockid > 0 & age >= 0 & age <= 40 & !is.na(critical_hab), .(cut40 = uniqueN(.I)), by = "critical_hab"],
         outPts[blockid > 0 & age >= 0 & age <= 80 & !is.na(critical_hab), .(cut80 = uniqueN(.I)), by = "critical_hab"],
         outPts[blockid > 0 & age >= 10 & age <= 40 & !is.na(critical_hab), .(cut10_40 = uniqueN(.I)), by = "critical_hab"]
    ))
    
    message("Get the Road summaries")
    outPts[roadyear >=0, field:=0]
    nearNeigh_rds<-RANN::nn2(outPts[field == 0 & !is.na(critical_hab), c('x', 'y')], 
                       outPts[is.na(field) & !is.na(critical_hab), c('x', 'y')], 
                       k = 1)
  
    outPts<-outPts[is.na(field)  & !is.na(critical_hab), rds_dist:=nearNeigh_rds$nn.dists] # assign the distances
    outPts[is.na(rds_dist) & !is.na(critical_hab), rds_dist:=0] # those that are the distance to pixels, assign 
    road_summary<-Reduce(merge,
                             list(outPts[rds_dist == 0  & !is.na(critical_hab), .(road50 = uniqueN(.I)), by = "critical_hab"],
                                  outPts[rds_dist <= 250 & !is.na(critical_hab), .(road250 = uniqueN(.I)), by = "critical_hab"],
                                  outPts[rds_dist <= 500 & !is.na(critical_hab), .(road500  = uniqueN(.I)), by = "critical_hab"],
                                  outPts[rds_dist <= 750 & !is.na(critical_hab), .(road750  = uniqueN(.I)), by = "critical_hab"]
                             ))
    outPts<-outPts[,c("rds_dist","field") := list(NULL, NA)]
    
    message("Cutblocks and roads combined")
    outPts[roadyear >= 0 | (blockid > 0 & age >=0 & age <= 40), field:=0]
    nearNeigh<-RANN::nn2(outPts[ field ==0 & !is.na(critical_hab), c('x', 'y')], 
                         outPts[is.na(field) & !is.na(critical_hab), c('x', 'y')], 
                         k = 1)
    
    outPts<-outPts[is.na(field) & !is.na(critical_hab), dist:=nearNeigh$nn.dists] # assign the distances
    outPts[is.na(dist) & !is.na(critical_hab), dist:=0] # those that are the distance to pixels, assign 
    c40r<-Reduce(merge,
                         list(outPts[dist == 0  & !is.na(critical_hab), .(c40r50 = uniqueN(.I)), by = "critical_hab"],
                              outPts[dist <= 250 & !is.na(critical_hab), .(c40r250 = uniqueN(.I)), by = "critical_hab"],
                              outPts[dist <= 500 & !is.na(critical_hab), .(c40r500  = uniqueN(.I)), by = "critical_hab"],
                              outPts[dist <= 750 & !is.na(critical_hab), .(c40r750  = uniqueN(.I)), by = "critical_hab"]
                         ))
    
    outPts<-outPts[,c("dist","field") := list(NULL, NA)]
    
    outPts[roadyear >= 0 | (blockid > 0 & age >=10 & age <= 40), field:=0]
    nearNeigh<-RANN::nn2(outPts[ field ==0 & !is.na(critical_hab), c('x', 'y')], 
                         outPts[is.na(field) & !is.na(critical_hab), c('x', 'y')], 
                         k = 1)
    
    outPts<-outPts[is.na(field) & !is.na(critical_hab), dist:=nearNeigh$nn.dists] # assign the distances
    outPts[is.na(dist) & !is.na(critical_hab), dist:=0] # those that are the distance to pixels, assign 
    c10_40r<-Reduce(merge,
                 list(outPts[dist == 0  & !is.na(critical_hab), .(c10_40r50 = uniqueN(.I)), by = "critical_hab"],
                      outPts[dist <= 500 & !is.na(critical_hab), .(c10_40r500  = uniqueN(.I)), by = "critical_hab"]
                 ))
    
    outPts<-outPts[,c("dist","field") := list(NULL, NA)]
    
    outPts[roadyear >=0 | (blockid > 0 & age >=0 & age <= 20), field:=0]
    nearNeigh<-RANN::nn2(outPts[ field == 0 & !is.na(critical_hab), c('x', 'y')], 
                         outPts[is.na(field) & !is.na(critical_hab), c('x', 'y')], 
                         k = 1)
    
    outPts<-outPts[is.na(field) & !is.na(critical_hab), dist:=nearNeigh$nn.dists] # assign the distances
    outPts[is.na(dist) & !is.na(critical_hab), dist:=0] # those that are the distance to pixels, assign 
    c20r<-Reduce(merge,
                 list(outPts[dist == 0  & !is.na(critical_hab), .(c20r50 = uniqueN(.I)), by = "critical_hab"],
                      outPts[dist < 250 & !is.na(critical_hab), .(c20r250 = uniqueN(.I)), by = "critical_hab"],
                      outPts[dist < 500 & !is.na(critical_hab), .(c20r500  = uniqueN(.I)), by = "critical_hab"],
                      outPts[dist < 750 & !is.na(critical_hab), .(c20r750  = uniqueN(.I)), by = "critical_hab"]
                 ))
    outPts<-outPts[,c("dist","field") := list(NULL, NA)]
    
    outPts[roadyear >=0 | (blockid > 0 & age >=0 & age <= 80), field:=0]
    nearNeigh<-RANN::nn2(outPts[ field ==0 & !is.na(critical_hab), c('x', 'y')], 
                         outPts[is.na(field) & !is.na(critical_hab), c('x', 'y')], 
                         k = 1)
    
    outPts<-outPts[is.na(field) & !is.na(critical_hab), dist:=nearNeigh$nn.dists] # assign the distances
    outPts[is.na(dist) & !is.na(critical_hab), dist:=0] # those that are the distance to pixels, assign 
    
    c80r<-Reduce(merge,
                 list(outPts[dist == 0  & !is.na(critical_hab), .(c80r50 = uniqueN(.I)), by = "critical_hab"],
                      outPts[dist <= 250 & !is.na(critical_hab), .(c80r250 = uniqueN(.I)), by = "critical_hab"],
                      outPts[dist <= 500 & !is.na(critical_hab), .(c80r500  = uniqueN(.I)), by = "critical_hab"],
                      outPts[dist <= 750 & !is.na(critical_hab), .(c80r750  = uniqueN(.I)), by = "critical_hab"]
                 ))
    sim$disturbance<-merge(sim$disturbance, outPts[,c("pixelid","dist")], by = 'pixelid', all.x =TRUE) #sim$rsfcovar contains: pixelid, x,y, population
    
    #update the pixels table
    dbBegin(sim$clusdb)
      rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET dist = :dist WHERE pixelid = :pixelid;", outPts[,c("pixelid","dist")])
    dbClearResult(rs)
    dbCommit(sim$clusdb)
  
  }else{
    sim$disturbance$dist<-501
  }

  #out.ras<-sim$ras
  #out.ras[]<-sim$disturbance$dist
  #writeRaster(out.ras, paste0("dist",time(sim), ".tif"), overwrite = TRUE)
  
  #TODO:Add the volume from harvestPixelList; but see volumebyareaReportCLUS
  tempDisturbanceReport<-Reduce(merge,list(cutblock_summary, road_summary, c80r,c40r,c20r, c10_40r)
  )
  
  tempDisturbanceReport[, c("scenario", "compartment", "timeperiod") := 
                          list(scenario$name,sim$boundaryInfo[[3]],time(sim)*sim$updateInterval)]
  
  sim$disturbanceReport<-rbindlist(list(sim$disturbanceReport, tempDisturbanceReport), use.names=TRUE )
  sim$disturbance[, dist:=NULL]
  
  return(invisible(sim))
}

patchAnalysis <- function(sim) {
  #calculates the patch size distributions
  #For each landscape unit that has a patch size constraint
  # Make a graph 
  # igraph::induce_subgraph based on a SELECT pixelids from pixels where age < 40
  # determine the number of distinct components using igraph::component_distribution
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  
  return(invisible(sim))
}

