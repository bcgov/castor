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

defineModule(sim, list(
  name = "disturbanceCastor",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", disturbanceCastor = "1.0.0"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "disturbanceCastor.Rmd"),
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
    expectsInput(objectName = "disturbanceFlow", objectClass = "data.table", desc = "Time series table of annual area disturbed", sourceURL = NA),
    expectsInput(objectName = "boundaryInfo", objectClass = "character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "castordb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the RSF', sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "RasterLayer", desc = "A raster object created in dataCastor. It is a raster defining the area of analysis (e.g., supply blocks/TSAs).", sourceURL = NA),
    expectsInput(objectName = "pts", objectClass = "data.table", desc = "Centroid x,y locations of the ras.", sourceURL = NA),
    expectsInput(objectName = "scenario", objectClass = "data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName = "updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA)
    #expectsInput(objectName ="harvestPixelList", objectClass ="data.table", desc = 'The list of pixels being harvesting in a time period', sourceURL = NA)
    ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput("disturbance", "data.table", "Disturbance table for every pixel"),
    createsOutput("disturbanceReport", "data.table", "Summary per simulation period of the disturbance indicators")
  )
))

doEvent.disturbanceCastor = function (sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init (sim) # this function inits 
      sim <- scheduleEvent(sim, time(sim) , "disturbanceCastor", "analysis", 9)
      
      if(nrow(sim$disturbanceFlow) > 0){
         sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "disturbanceCastor") , "disturbanceCastor", "disturbProcess", 9)
      }
    },
    disturbProcess ={
      sim<-distProcess(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "disturbanceCastor"), "disturbanceCastor", "disturbProcess", 9)
      
    },
    analysis = {
      sim <- distAnalysis(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "disturbanceCastor"), "disturbanceCastor", "analysis", 9)
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
  
  if(!is.na(sim$extent[[1]])){ # if you don't have boundary data...
    # create some caribou herd bounds
    # intent here is to create the boundary in the top left (northwest) quadrant of the raster
    n.rows <-  c (0:(sim$extent[[1]]/2)) # divide 'width' of raster in two = start value of each row in raster
    bounds <- data.table (pixelid = as.integer (), # empty table to populate with data
                          value = as.numeric (),
                          critical_hab = as.character ())
    
    for (i in 1:length (n.rows)) { # loop through each row 

     temp <- data.table (pixelid = seq (from = as.integer (P (sim,"randomLandscape", "dataCastor" )[[3]] + (P(sim,"randomLandscape", "dataCastor" )[[1]]*n.rows[i]) + 1), # start at each value on left side of the raster
                                        to =  as.integer ((P(sim,"randomLandscape", "dataCastor" )[[2]]/2) + (P(sim,"randomLandscape", "dataCastor" )[[1]]*n.rows[i])), # to value in middle of the raster, for the top value of the raster
                                        by = 1),
                         value = 1,
                         critical_hab = "caribou_herd"
                         )
         
      bounds <- rbind (bounds, temp)
    }
    
    # join by pixelid
    sim$disturbance <- merge (sim$disturbance,
                              bounds,
                              by.x = "pixelid",
                              by.y = "pixelid", 
                              all.x = T)
    sim$disturbance [, compartment := dbGetQuery (sim$castordb, "SELECT compartid FROM pixels order by pixelid")$compartid]
    sim$disturbance [, treed := dbGetQuery (sim$castordb, "SELECT treed FROM pixels order by pixelid")$treed]
    
    # set permanent disturbance to none
    dbExecute (sim$castordb, "ALTER TABLE pixels ADD COLUMN perm_dist integer DEFAULT 0")

  }
  
  
  
  if(!is.null(sim$boundaryInfo)){ # if you have boundary data...
  
  if(P(sim, "criticalHabRaster", "disturbanceCastor") == '99999'){
    sim$disturbance[, attribute := 1]
  }else{
    bounds <- data.table (V1 = RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                          srcRaster = P (sim, "criticalHabRaster", "disturbanceCastor"), 
                          clipper = sim$boundaryInfo[[1]],  # by the area of analysis (e.g., supply block/TSA)
                          geom = sim$boundaryInfo[[4]], 
                          where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                          conn = NULL)[])
    bounds [, pixelid := seq_len(.N)] # make a unique id to ensure it merges correctly
    if(nrow(bounds[!is.na(V1),]) > 0){ #check to see if some of the aoi overlaps with the boundary
      if(!(P(sim, "criticalHabitatTable", "disturbanceCastor") == '99999')){
        crit_lu<-data.table(getTableQuery(paste0("SELECT cast(value as int) , attribute FROM ",P(sim, "criticalHabitatTable", "disturbanceCastor"))))
        bounds<-merge (bounds, crit_lu, by.x = "V1", by.y = "value", all.x = TRUE)
      }else{
        stop(paste0("ERROR: need to supply a lookup table: ", P(sim, "criticalHabitatTable", "disturbanceCastor")))
      }
    }else{
      stop(paste0(P(sim, "criticalHabRaster", "disturbanceCastor"), "- does not overlap with aoi"))
    }
    setorder(bounds, pixelid) #sort the bounds
    sim$disturbance[, critical_hab:= bounds$attribute]
    sim$disturbance[, compartment:= dbGetQuery(sim$castordb, "SELECT compartid FROM pixels order by pixelid")$compartid]
    sim$disturbance[, treed:= dbGetQuery(sim$castordb, "SELECT treed FROM pixels order by pixelid")$treed]
  }
  
  #get the permanent disturbance raster
  #check it a field already in sim$castordb?
  if(dbGetQuery (sim$castordb, "SELECT COUNT(*) as exists_check FROM pragma_table_info('pixels') WHERE name='perm_dist';")$exists_check == 0){
    # add in the column
    dbExecute(sim$castordb, "ALTER TABLE pixels ADD COLUMN perm_dist integer DEFAULT 0")
    # add in the raster
    if(P(sim, "permDisturbanceRaster", "disturbanceCastor") == '99999'){
      message("WARNING: No permanent disturbance raster specified ... defaulting to no permanent disturbances")
      dbExecute(sim$castordb, "Update pixels set perm_dist = 0;")
    }else{
    perm_dist <- data.table(perm_dist = RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                     srcRaster = P(sim, "permDisturbanceRaster", "disturbanceCastor"), 
                     clipper = sim$boundaryInfo[[1]],  # by the area of analysis (e.g., supply block/TSA)
                     geom = sim$boundaryInfo[[4]], 
                     where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                     conn = NULL)[])
    perm_dist[,pixelid:=seq_len(.N)]#make a unique id to ensure it merges correctly
    #add to the castordb
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, "Update pixels set perm_dist = :perm_dist where pixelid = :pixelid", perm_dist)
    dbClearResult(rs)
    dbCommit(sim$castordb)
    
    #clean up
    rm(perm_dist)
    gc()
    }
  }else{
    message("...using existing permanent disturbance raster")
  }
 } 
  
  return(invisible(sim))
}

distAnalysis <- function(sim) {
  
  all.dist<-data.table(dbGetQuery(sim$castordb, paste0("SELECT age, blockid, (case when ((",time(sim)*sim$updateInterval, " - roadstatus < ",P(sim, "recovery", "disturbanceCastor")," AND (roadtype != 0 OR roadtype IS NULL)) OR roadtype = 0) then 1 else 0 end) as road_dist, pixelid FROM pixels WHERE perm_dist > 0 OR (blockid > 0 and age >= 0) OR (",time(sim)*sim$updateInterval, " - roadstatus < ", P(sim, "recovery", "disturbanceCastor")," AND (roadtype != 0 OR roadtype IS NULL)) OR roadtype = 0;")))
  
  if(nrow(all.dist) > 0){
    outPts <- merge (sim$disturbance, all.dist, by = 'pixelid', all.x =TRUE) 
    message("Get the cutblock summaries")
    cutblock_summary<-Filter(function(x) dim(x)[1] > 0,
         list(outPts[treed == 1 & !is.na(critical_hab), .(total_area = uniqueN(.I)), by = c("compartment","critical_hab")],
              outPts[blockid > 0 & age >= 0 & age <= 20 & !is.na(critical_hab), .(cut20 = uniqueN(.I)), by = c("compartment","critical_hab")],
              outPts[blockid > 0 & age >= 0 & age <= 40 & !is.na(critical_hab), .(cut40 = uniqueN(.I)), by = c("compartment","critical_hab")],
              outPts[blockid > 0 & age >= 0 & age <= 80 & !is.na(critical_hab), .(cut80 = uniqueN(.I)), by = c("compartment","critical_hab")],
              outPts[blockid > 0 & age >= 10 & age <= 40 & !is.na(critical_hab), .(cut10_40 = uniqueN(.I)), by = c("compartment","critical_hab")]
    ))  %>%
      Reduce(function(dtf1,dtf2) full_join(dtf1,dtf2, by=c("compartment","critical_hab")), .)
    
    message("Get the Road summaries")
    outPts [road_dist > 0, field := 0] #note that outside critical_hab roads will impact this.
    nearNeigh_rds <- RANN::nn2(outPts[field == 0, c('x', 'y')], 
                               outPts[is.na(field), c('x', 'y')], 
                               k = 1)
  
    outPts<-outPts[is.na(field) , rds_dist := nearNeigh_rds$nn.dists] # assign the distances
    outPts[is.na(rds_dist), rds_dist:=0] # those that are the distance to pixels, assign 
    road_summary<-Filter(function(x) dim(x)[1] > 0,
                             list(outPts[rds_dist == 0  & !is.na(critical_hab), .(road50 = uniqueN(.I)), by = c("compartment","critical_hab")],
                                  outPts[rds_dist <= 250 & !is.na(critical_hab), .(road250 = uniqueN(.I)), by = c("compartment","critical_hab")],
                                  outPts[rds_dist <= 500 & !is.na(critical_hab), .(road500  = uniqueN(.I)), by = c("compartment","critical_hab")],
                                  outPts[rds_dist <= 750 & !is.na(critical_hab), .(road750  = uniqueN(.I)), by = c("compartment","critical_hab")]
                             )) %>%
      Reduce(function(dtf1,dtf2) full_join(dtf1,dtf2, by=c("compartment","critical_hab")), .)
    outPts<-outPts[,c("rds_dist","field") := list(NULL, NA)]
    
    message("Cutblocks and roads combined")
    outPts[road_dist > 0 | (blockid > 0 & age >=0 & age <= 40), field:=0]
    nearNeigh<-RANN::nn2(outPts[ field ==0, c('x', 'y')], 
                         outPts[is.na(field), c('x', 'y')], 
                         k = 1)
    
    outPts<-outPts[is.na(field), dist:=nearNeigh$nn.dists] # assign the distances
    outPts[is.na(dist), dist:=0] # those that are the distance to pixels, assign 
    c40r<-Filter(function(x) dim(x)[1] > 0,
                         list(outPts[dist == 0  & !is.na(critical_hab), .(c40r50 = uniqueN(.I)), by = c("compartment","critical_hab")],
                              outPts[dist <= 250 & !is.na(critical_hab), .(c40r250 = uniqueN(.I)), by = c("compartment","critical_hab")],
                              outPts[dist <= 500 & !is.na(critical_hab), .(c40r500  = uniqueN(.I)), by = c("compartment","critical_hab")],
                              outPts[dist <= 750 & !is.na(critical_hab), .(c40r750  = uniqueN(.I)), by = c("compartment","critical_hab")]
                         )) %>%
      Reduce(function(dtf1,dtf2) full_join(dtf1,dtf2, by=c("compartment","critical_hab")), .)
    
    outPts<-outPts[,c("dist","field") := list(NULL, NA)]
    
    outPts[road_dist > 0 | (blockid > 0 & age >=10 & age <= 40), field:=0]
    nearNeigh<-RANN::nn2(outPts[ field ==0, c('x', 'y')], 
                         outPts[is.na(field), c('x', 'y')], 
                         k = 1)
    
    outPts<-outPts[is.na(field), dist:=nearNeigh$nn.dists] # assign the distances
    outPts[is.na(dist), dist:=0] # those that are the distance to pixels, assign 
    c10_40r<-Filter(function(x) dim(x)[1] > 0,
                 list(outPts[dist == 0  & !is.na(critical_hab), .(c10_40r50 = uniqueN(.I)), by =c("compartment","critical_hab")],
                      outPts[dist <= 500 & !is.na(critical_hab), .(c10_40r500  = uniqueN(.I)), by = c("compartment","critical_hab")]
                 )) %>%
      Reduce(function(dtf1,dtf2) full_join(dtf1,dtf2, by=c("compartment","critical_hab")), .)
    
    outPts<-outPts[,c("dist","field") := list(NULL, NA)]
    
    outPts[road_dist > 0 | (blockid > 0 & age >=0 & age <= 20), field:=0]
    nearNeigh<-RANN::nn2(outPts[ field == 0, c('x', 'y')], 
                         outPts[is.na(field), c('x', 'y')], 
                         k = 1)
    
    outPts<-outPts[is.na(field), dist:=nearNeigh$nn.dists] # assign the distances
    outPts[is.na(dist), dist:=0] # those that are the distance to pixels, assign 
    c20r<-Filter(function(x) dim(x)[1] > 0,
                 list(outPts[dist == 0  & !is.na(critical_hab), .(c20r50 = uniqueN(.I)), by = c("compartment","critical_hab")],
                      outPts[dist < 250 & !is.na(critical_hab), .(c20r250 = uniqueN(.I)), by = c("compartment","critical_hab")],
                      outPts[dist < 500 & !is.na(critical_hab), .(c20r500  = uniqueN(.I)), by = c("compartment","critical_hab")],
                      outPts[dist < 750 & !is.na(critical_hab), .(c20r750  = uniqueN(.I)), by = c("compartment","critical_hab")]
                 )) %>%
      Reduce(function(dtf1,dtf2) full_join(dtf1,dtf2, by=c("compartment","critical_hab")), .)
    outPts<-outPts[,c("dist","field") := list(NULL, NA)]
    
    outPts[road_dist > 0 | (blockid > 0 & age >=0 & age <= 80), field:=0]
    nearNeigh<-RANN::nn2(outPts[ field ==0, c('x', 'y')], 
                         outPts[is.na(field), c('x', 'y')], 
                         k = 1)
    
    outPts<-outPts[is.na(field), dist:=nearNeigh$nn.dists] # assign the distances
    outPts[is.na(dist), dist:=0] # those that are the distance to pixels, assign 
    
    c80r<-Filter(function(x) dim(x)[1] > 0,
                 list(outPts[dist == 0  & !is.na(critical_hab), .(c80r50 = uniqueN(.I)), by = c("compartment","critical_hab")],
                      outPts[dist <= 250 & !is.na(critical_hab), .(c80r250 = uniqueN(.I)), by = c("compartment","critical_hab")],
                      outPts[dist <= 500 & !is.na(critical_hab), .(c80r500  = uniqueN(.I)), by = c("compartment","critical_hab")],
                      outPts[dist <= 750 & !is.na(critical_hab), .(c80r750  = uniqueN(.I)), by = c("compartment","critical_hab")]
                 )) %>%
      Reduce(function(dtf1,dtf2) full_join(dtf1,dtf2, by=c("compartment","critical_hab")), .)
    sim$disturbance<-merge(sim$disturbance, outPts[,c("pixelid","dist")], by = 'pixelid', all.x =TRUE) #sim$rsfcovar contains: pixelid, x,y, population
    
    #update the pixels table
    dbBegin(sim$castordb)
      rs<-dbSendQuery(sim$castordb, "UPDATE pixels SET dist = :dist WHERE pixelid = :pixelid;", outPts[,c("pixelid","dist")])
    dbClearResult(rs)
    dbCommit(sim$castordb)
  
  }else{
    sim$disturbance$dist<-501
  }
  
  #TODO:Add the volume from harvestPixelList; but see volumebyareaReportCastor
  tempDisturbanceReport<-data.table(Filter(function(x) !is.null(x),
                                list (cutblock_summary, road_summary, c80r, c40r, c20r, c10_40r)) %>%
                                  Reduce(function(dtf1,dtf2) full_join(dtf1,dtf2, by=c("compartment","critical_hab")), .))
  
  
  tempDisturbanceReport[, c ("scenario", "timeperiod") := 
                          list(sim$scenario$name,time(sim)*sim$updateInterval)]
  
  sim$disturbanceReport <- rbindlist (list (sim$disturbanceReport, tempDisturbanceReport), use.names=TRUE, 
                                      fill = TRUE )
  sim$disturbance [, dist := NULL]
  
  return(invisible(sim))
}

distProcess <- function(sim) {
  
  ras.info<-dbGetQuery(sim$castordb, "Select * from raster_info limit 1;")
  spreadRas<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0)
  spreadRas[]<-dbGetQuery(sim$castordb, "Select treed from pixels order by pixelid;")$treed
  
  for(compart in sim$compartment_list){
    
    ndTarget<-sim$disturbanceFlow[compartment == compart & period == time(sim) & flow > 0,]$flow
    ndStartAreas<-sim$disturbanceFlow[compartment == compart &  period == time(sim) & flow > 0,]$partition
    
    if(length(ndTarget) > 0){
      distStarts<-data.table(size = as.integer(rlnorm(1000, meanlog = 4.75, sdlog = 2.47)))[, cvalue:=cumsum(size)][cvalue <= ndTarget,]
      distStarts$starts <- sample(dbGetQuery(sim$castordb, paste0("select pixelid from pixels where ", ndStartAreas))$pixelid, nrow(distStarts), replace = FALSE)
       
      if(nrow(distStarts) > 0){
        out <- spread2(landscape = spreadRas, start = distStarts$starts, exactSize = distStarts$size, spreadProbRel = spreadRas, asRaster = FALSE)
        dbBegin(sim$castordb)
          rs<-dbSendQuery(sim$castordb, "UPDATE pixels SET age = 0, vol = 0, salvage_vol = 0 WHERE pixelid = :pixels", out[, "pixels"])
        dbClearResult(rs)
        dbCommit(sim$castordb)
      }
     
    }
    
  }
  
  
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
  if(!suppliedElsewhere("disturbanceFlow", sim)){
    sim$disturbanceFlow<-data.table(compartment = as.character(),
                                    partition  = as.character(), 
                                    period  = as.integer(), 
                                    flow = as.numeric())
  }
  return(invisible(sim))
}

