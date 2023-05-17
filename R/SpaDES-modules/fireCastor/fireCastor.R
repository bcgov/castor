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
  name = "fireCastor",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Elizabeth", "Kleynhans", email = "elizabeth.kleynhans@gov.bc.ca", role = c("aut", "cre")),
              person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", fireCastor = "1.0.0"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "fireCastor.Rmd"),
  reqdPkgs = list("here","data.table", "raster", "SpaDES.tools", "tidyr"),
  parameters = rbind(
    
    defineParameter("simulationTimeStep", "numeric", 1, NA, NA, "This describes the simulation time step interval"),
    defineParameters("ignitionProbRaster", "numeric", NA, NA, NA, "Raster of the probability of ignition, both lighting and human caused"),
    defineParameters("escapeProbRaster", "numeric", NA, NA, NA, "Raster of the probability of escape"),
    defineParameters("spreadProbRaster", "numeric", NA, NA, NA, "Raster of the probability of spread across the landscape"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    #expectsInput(objectName = "disturbanceFlow", objectClass = "data.table", desc = "Time series table of annual area disturbed", sourceURL = NA),
    expectsInput(objectName = "boundaryInfo", objectClass = "character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "castordb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the RSF', sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "RasterLayer", desc = "A raster object created in dataCastor. It is a raster defining the area of analysis (e.g., supply blocks/TSAs).", sourceURL = NA),
    expectsInput(objectName = "pts", objectClass = "data.table", desc = "Centroid x,y locations of the ras.", sourceURL = NA),
    expectsInput(objectName = "scenario", objectClass = "data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName = "road_distance", objectClass = "data.table", desc = 'The euclidian distance to the nearest road', sourceURL = NA)
  ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput("firedisturbance", "data.table", "Disturbance by fire table for every pixel"),
    createsOutput("fireReport", "data.table", "Summary per simulation period of the fire indicators")
  )
))

doEvent.fireCastor = function(sim, eventTime, eventType, debug = FALSE){
  switch(
    eventType,
    init = {
      sim <- Init (sim) # this function inits 
      sim <- getStaticFireVariables(sim) # create table with static fire variables to calculate probability of ignition, escape, spread
      
      if(nrow(sim$road_distance) < 1){
        sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor") , "fireCastor", "roadDistanceCalc", 9)
      }
      
      roadDistanceCalc ={
        sim <- roadDistCalc(sim)
        sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor"), "fireCastor", "roadDistance", 9)
      }
      
      sim <- getDistanceToRoad(sim)
      sim <- getClimateVariables (sim)
      sim <- getVegetationVariables(sim)
      sim <- calculateProbIgnitEscapeSpread(sim) #inserts values into the probability of ignition, escape, spread table
      sim <- scheduleEvent(sim, time(sim) , "fireCastor", "analysis", 9)

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
  
  sim$fireReport<-data.table(scenario = character(), compartment = character(), 
                             timeperiod= integer(), critical_hab = character(), 
                             pixelid = integer(), number_sims = numeric(), 
                             number_times_burned = numeric())
  sim$firedisturbance <- sim$pts
  
  message("create empty table of fire variables needed to calculate probabilities")
  
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS firevariables (pixelid integer, frt integer, ignitstaticlightning numeric, ignitstatichuman numeric, escapestatic numeric, spreadstatic numeric, distancetoroads numeric, )")
  
  return(invisible(sim))
  
}

getStaticFireVariables<-function(sim){
  
  message("get fire regime type")
  #constant coefficients
  ras.frt<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                                srcRaster= P(sim, "nameFrtRaster", "fireCastor"), 
                                                clipper=sim$boundaryInfo[1] , 
                                                geom= sim$boundaryInfo[4] , 
                                                where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                conn=NULL))
  if(terra::ext(sim$ras) == terra::ext(ras.frt)){
    frt_id<-data.table(frt = as.integer(ras.frt[]))
    frt_id[, pixelid := seq_len(.N)][, frt := as.integer(frt)]
    frt_id<-frt_id[frt > 0, ]
  
  #add to the castordb
  dbBegin(sim$castordb)
  rs<-dbSendQuery(sim$castordb, "UPDATE firevariables set frt = :frt where pixelid = :pixelid", frt_id)
  dbClearResult(rs)
  dbCommit(sim$castordb)
  
  rm(ras.frt,frt_id)
  gc()
  }else{
    stop(paste0("ERROR: extents are not the same check -", P(sim, "nameFrtRaster", "fireCastor")))
  }
  
  message("get static fire variables")
  #constant coefficients
  ras.ignitlightning<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                     srcRaster= P(sim, "nameStaticLightningIgnitRaster", "fireCastor"), 
                                     clipper=sim$boundaryInfo[1] , 
                                     geom= sim$boundaryInfo[4] , 
                                     where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                     conn=NULL))
  if(terra::ext(sim$ras) == terra::ext(ras.ignitlightning)){
    ignit_lightning_static<-data.table(ignitstaticlightning = as.numeric(ras.ignitlightning[]))
    ignit_lightning_static[, pixelid := seq_len(.N)][, ignitstaticlightning := as.numeric(ignitstaticlightning)]
    ignit_lightning_static<-ignit_lightning_static[ignitstaticlightning > -200, ]
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameStaticLightningIgnitRaster", "fireCastor")))
}

    # ignition human    
    ras.ignithuman<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                                  srcRaster= P(sim, "nameStaticHumanIgnitRaster", "fireCastor"), 
                                                  clipper=sim$boundaryInfo[1] , 
                                                  geom= sim$boundaryInfo[4] , 
                                                  where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                  conn=NULL))
    if(terra::ext(sim$ras) == terra::ext(ras.ignithuman)){
      ignit_human_static<-data.table(ignitstatichuman = as.numeric(ras.ignithuman[]))
      ignit_human_static[, pixelid := seq_len(.N)][, ignitstatichuman := as.numeric(ignitstatichuman)]
      ignit_human_static<-ignit_human_static[ignitstatichuman > -200, ]
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameStaticHumanIgnitRaster", "fireCastor")))
    }
    
    # TO DO : THere must be NA's in the escape and spreaad data e.g. for wind or for slope, aspect and elevation. I know this because escape_static and spread_static are smaller than ignit_human_static or ignit_lightning_static. Go back and give the NA values the average value for that FRT and then re-run the script so that there are no holes!!!
    
    # Escape  
      ras.escape<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                                    srcRaster= P(sim, "nameStaticEscapeRaster", "fireCastor"), 
                                                    clipper=sim$boundaryInfo[1] , 
                                                    geom= sim$boundaryInfo[4] , 
                                                    where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                    conn=NULL))
      if(terra::ext(sim$ras) == terra::ext(ras.escape)){
        escape_static<-data.table(escapestatic = as.numeric(ras.escape[]))
        escape_static[, pixelid := seq_len(.N)][, escapestatic := as.numeric(escapestatic)]
        escape_static<-escape_static[escapestatic > -2000, ]
      }else{
        stop(paste0("ERROR: extents are not the same check -", P(sim, "nameStaticEscapeRaster", "fireCastor")))
      }
      
   # spread     
        ras.spread<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                                      srcRaster= P(sim, "nameStaticSpreadRaster", "fireCastor"), 
                                                      clipper=sim$boundaryInfo[1] , 
                                                      geom= sim$boundaryInfo[4] , 
                                                      where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                      conn=NULL))
        if(terra::ext(sim$ras) == terra::ext(ras.spread)){
          spread_static<-data.table(spreadstatic = as.numeric(ras.spread[]))
          spread_static[, pixelid := seq_len(.N)][, spreadstatic := as.numeric(spreadstatic)]
          spread_static<-spread_static[spreadstatic > -200, ]
        }else{
          stop(paste0("ERROR: extents are not the same check -", P(sim, "nameStaticSpreadRaster", "fireCastor")))
        }
        
    fire_static<-merge(ignit_lightning_static,ignit_human_static)
    fire_static<-merge(fire_static,escape_static)
    fire_static<-merge(fire_static,spread_static)
    
    
    #add to the castordb
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, "UPDATE firevariables set ignitstaticlightning = :ignitstaticlightning, ignitstatichuman = :ignitstatichuman, escapestatic = :escapestatic, spreadstatic = :spreadstatic where pixelid = :pixelid", fire_static)
    dbClearResult(rs)
    dbCommit(sim$castordb)
    
    rm(ras.ignitlightning,ignit_lightning_static, ras.ignithuman, ignit_human_static, ras.escape, escape_static, ras.spread, spread_static, fire_static)
    gc()
    
    return(invisible(sim)) 
    
}

getDistanceToRoad<-function(sim){
  
  message("get distance to roads")
  
    road_distance <- sim$road_distance # this step maybe unneccessary. ##CHECK: could check it both ways by putting sim$road_distance into the query instead of road_distance
    
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, 'UPDATE firevariables SET distancetoroads  = :road_distance WHERE pixelid = :pixelid', road_distance) # I dont know if ending this with sim$road_distance will work.
    dbClearResult(rs)
    dbCommit(sim$castordb)  

    return(invisible(sim)) 
}
    

roadDistCalc <- function(sim) { 
  
  road.dist<-data.table(dbGetQuery(sim$castordb, paste0("SELECT (case when ((",time(sim)*sim$updateInterval, " - roadstatus < ",P(sim, "recovery", "fireCastor")," AND (roadtype != 0 OR roadtype IS NULL)) OR roadtype = 0) then 1 else 0 end) as road_dist, pixelid FROM pixels")))
  
  if(exists("road.dist")){
    outPts <- merge (sim$firedisturbance, road.dist, by = 'pixelid', all.x =TRUE) 
    outPts [road_dist > 0, field := 0] 
    nearNeigh_rds <- RANN::nn2(outPts[field == 0, c('x', 'y')], 
                               outPts[is.na(field), c('x', 'y')], 
                               k = 1)
    
    outPts<-outPts[is.na(field) , rds_dist := nearNeigh_rds$nn.dists] # assign the distances
    outPts[is.na(rds_dist), rds_dist:=0] # those that are the distance to pixels, assign 
    sim$road_distance<-outPts[, c("pixelid", "rds_dist")]
    
    #CHECK: Do I need to update the firevariables table? 
    
  } else {
    message("missing roadCastor input defaulting to static roads from user specified layer")
    
    dbExecute(sim$castordb, "ALTER TABLE pixels ADD COLUMN roadtype numeric;")
    
    sim$road.type<-terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                            srcRaster= P(sim, "nameRoads", "fireCastor"), # this will likely be rast.ce_road_2019
                                            clipper=sim$boundaryInfo[[1]], 
                                            geom= sim$boundaryInfo[[4]], 
                                            where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                            conn = NULL))
    
    #Update the pixels table to set the roaded pixels
    roadUpdate<-data.table(V1= as.numeric(sim$road.type[])) #transpose then vectorize which matches the same order as adj
    roadUpdate[, pixelid := seq_len(.N)]
    roadUpdate<-roadUpdate[V1 >= 0,]
    
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, 'UPDATE pixels SET roadtype = :V1 WHERE pixelid = :pixelid', roadUpdate)
    dbClearResult(rs)
    dbCommit(sim$castordb)  
    
    road.dist<-data.table(dbGetQuery(sim$castordb, paste0("SELECT (case when ((roadtype != 0 OR roadtype IS NULL) OR roadtype = 0) then 1 else 0 end) as road_dist, pixelid FROM pixels")))
      outPts <- merge (sim$firedisturbance, road.dist, by = 'pixelid', all.x =TRUE) 
      outPts [road_dist > 0, field := 0] 
      nearNeigh_rds <- RANN::nn2(outPts[field == 0, c('x', 'y')], 
                                 outPts[is.na(field), c('x', 'y')], 
                                 k = 1)
      
      outPts<-outPts[is.na(field) , rds_dist := nearNeigh_rds$nn.dists] # assign the distances
      outPts[is.na(rds_dist), rds_dist:=0] # those that are the distance to pixels, assign 
      sim$road_distance<-outPts[, c("pixelid", "rds_dist")]
      
      #CHECK: Do I need to update the firevariables table? 
    
  }
  
  return(invisible(sim)) 
  
}


getClimateVariables <- function(sim) {

  message("get climate variables")
  #constant coefficients
  ras.ignitlightning<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                                srcRaster= P(sim, "nameStaticLightningIgnitRaster", "fireCastor"), 
                                                clipper=sim$boundaryInfo[1] , 
                                                geom= sim$boundaryInfo[4] , 
                                                where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                conn=NULL))
  if(terra::ext(sim$ras) == terra::ext(ras.ignitlightning)){
    ignit_lightning_static<-data.table(ignitstaticlightning = as.numeric(ras.ignitlightning[]))
    ignit_lightning_static[, pixelid := seq_len(.N)][, ignitstaticlightning := as.numeric(ignitstaticlightning)]
    ignit_lightning_static<-ignit_lightning_static[ignitstaticlightning > -200, ]
  }else{
    stop(paste0("ERROR: extents are not the same check -", P(sim, "nameStaticLightningIgnitRaster", "fireCastor")))
  }  
  
  
  return(invisible(sim))
}

  
  
  
  
  
  
  
  
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS fire (pixelid integer, frt integer, bclcs_level_2 character, proj_age_1 numeric, proj_height numeric, crown_closure numeric, pct_dead numeric, 
            inventory_standard_cd character, non_productive_cd character,coast_interior_cd character, bclcs_level_1 character,  bclcs_level_3 character,  bclcs_level_5 character, land_cover_class_cd_1 character, bec_zone_code character, bec_subzone character, earliest_nonlogging_dist_type character, earliest_nonlogging_dist_date timestamp, )")
 
  
 
.inputObjects <- function(sim) {
  if(!suppliedElsewhere("road_distance", sim)){
    sim$road_distance<- data.table(pixelid= as.integer(), 
                                   road.dist = as.numeric())
  }
  return(invisible(sim))
}
