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
  reqdPkgs = list("here","data.table", "raster", "SpaDES.tools", "tidyr", "climRdev", "pool"),
  parameters = rbind(
    
    #defineParameter("simulationTimeStep", "numeric", 1, NA, NA, "This describes the simulation time step interval"),
    defineParameter("calculateInterval", "numeric", 1, NA, NA, "The simulation time at which disturbance indicators are calculated"),
    defineParameter("nameFrtRaster", "numeric", NA, NA, NA, "Raster of the fire regime types across Canada"),
    defineParameter("nameStaticLightningIgnitRaster", "numeric", NA, NA, NA, "Raster with the values of the coefficients that are constant (e.g. intercept + b1*elevation) in the lightning ignition model"),
    defineParameter("nameStaticHumanIgnitRaster", "numeric", NA, NA, NA, "Raster with the values of the coefficients that are constant (e.g. intercept + b1*elevation + b2*distance_to_infrastructure) in the human ignition model"),
    defineParameter("nameStaticEscapeRaster", "numeric", NA, NA, NA, "Raster with the values of the coefficients that are constant (e.g. intercept + b1*elevation + b2*distance_to_infrastructure) in the fire escape model"),
    defineParameter("nameStaticSpreadRaster", "numeric", NA, NA, NA, "Raster with the values of the coefficients that are constant (e.g. intercept + b1*elevation + b2*distance_to_infrastructure + b3*spring_wind) in the spread model"),
    defineParameter("nameRoadsRast", "numeric", NA, NA, NA, "Raster of roads across BC. This is here incase roadsCastor is not run"),
    defineParameter("nameElevationRaster", "numeric", NA, NA, NA, "Digital elevation map of BC This is here incase elevation data is not supplied in another module"),
    defineParameter("simStartYear", "numeric", 2020, NA, NA, "The simulation year at which fire spread is first simulated"),
    defineParameter("simEndYear", "numeric", 2100, NA, NA, "The simulation year at which fire spread is first simulated"),
    defineParameter("nameBecRast", "numeric", NA, NA, NA, "Raster of bec zones across BC."),
    defineParameter("nameBecTable", "character", '99999', NA, NA, "Value attribute table that links to the raster and describes the bec zone and bec subzone information"),
    defineParameter("gcm", "character", '99999', NA, NA, "Global climate model from which to get future climate data e.g. ACCESS-ESM1-5"),
    defineParameter("ssp", "character", '99999', NA, NA, "Climate projection from which to get future climate data e.g. ssp370"),
    defineParameter("maxRun", "integer", '99999', NA, NA, "Maximum number of model runs to include. A value of 0 is ensembleMean only."),
    defineParameter("run", "character", '99999', NA, NA, "The run of the climate projection from which to get future climate data e.g. r1i1p1f1"),
    defineParameter("nameForestInventoryRaster", "numeric", NA, NA, NA, "Raster of VRI feature id"),
    defineParameter("nameForestInventoryTable2", "character", "99999", NA, NA, desc = "Name of the veg comp table - the forest inventory"),
    defineParameter("nameForestInventoryKey", "character", "99999", NA, NA, desc = "Name of the veg comp primary key that links the table to the raster"),
    defineParameter("numberFireReps", "numerical", "99999", NA, NA, desc = "value with the number of fire simulation repetitions needed"),
    defineParameter("firemodelcoeftbl", "character", "99999", NA, NA, desc = "Table with coefficient values to parameterze models for each fire regime type"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput(objectName = "castordb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the RSF', sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "RasterLayer", desc = "A raster object created in dataCastor. It is a raster defining the area of analysis (e.g., supply blocks/TSAs).", sourceURL = NA),
    expectsInput(objectName = "pts", objectClass = "data.table", desc = "Centroid x,y locations of the ras.", sourceURL = NA),
    expectsInput(objectName = "scenario", objectClass = "data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName = "updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA),
    expectsInput(objectName = "simStartYear", objectClass ="numeric", desc = 'The calendar year of the first simulation', sourceURL = NA),
    expectsInput(objectName = "road_distance", objectClass = "data.table", desc = 'The euclidian distance to the nearest road', sourceURL = NA)
  ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput("firedisturbanceTable", "data.table", "Disturbance by fire table for every pixel i.e. every time a pixel is burned it is updated by one so that at the end of the simulation time period we know how many times each pixel was burned"),
    createsOutput("fireReport", "data.table", "Summary per simulation period of the fire indicators i.e. total area burned, number of fire starts"),
    createsOutput("ras.frt", "raster", "Raster of fire regime types (maybe not needed)"),
    createsOutput("frt_id", "data.table", "List of fire regime types (maybe not needed)"),
    createsOutput("veg3", "data.table", "Table with pixelid and fuel type category. This table gets passed to calcProbFire"),
    createsOutput("coefficients", "data.table", "Table of coefficient values for variables that vary e.g. climate, fuel type and distance to roads. This table is used to calculate the probability rasters at every simulation time step."),
    createsOutput("fire_static", "data.table", "Table of static values for model parameters and variables that dont change across the simulation. These values are sampled from rasters produced for the whole province with a different value for each pixel according to each model e.g. lightning, person, escape, spread.  e.g. P(person) = intercept + B1*elevation + B2 * distance. "),
    createsOutput("probFireRasts", "data.table", "Table of calculated probability values for ignition, escape and spread for every pixel"),
    createsOutput("inv", "data.table", "Table of vegetation variables collected from the VRI. These variables are passed to calcFuelTypes to calculate the fuel type categories"),
    createsOutput("out", "data.table", "Table of starting location of fires and pixel id's of locations burned during the simulation"),
    createsOutput("ras.elev", "raster", "Raster of elevation for aoi"),
    createsOutput("samp.pts", "data.table", "Table of latitude, longitude, and elevation of points at a scale of 800m x 800m across the area of interest for climate data extraction"),
    createsOutput("fit_g", "vector", "Shape and rate parameters for the gamma distribution used to fit the distribution of ignition points"),
    createsOutput("min_ignit", "value", "Minimum number of fires observed"),
    createsOutput("max_ignit", "value", "Maximum number of ignitions observed multiplied by 5. I oversample the initial number of ignition locations and then select from the list of locations the ones that have a probability of ignition greater than a randomly drawn value until the number of drawn ignition locations is the same as the number I sampled from the gamma distribution.")
  )
))


doEvent.fireCastor = function(sim, eventTime, eventType, debug = FALSE){
  switch(
    eventType,
    init = {
      sim <- Init (sim) # this function inits 
      sim <- scheduleEvent(sim, time(sim), "fireCastor", "getStaticFireVariables", 11)
      sim <- scheduleEvent(sim, time(sim), "fireCastor", "roadDistanceCalc", 11)
      sim <- scheduleEvent(sim, time(sim), "fireCastor", "getClimateFireVariables", 11)
      sim <- scheduleEvent(sim, time(sim), "fireCastor", "getVegVariables", 11)
      sim <- scheduleEvent(sim, time(sim), "fireCastor", "determineFuelTypes", 12)
      sim <- scheduleEvent(sim, time(sim), "fireCastor", "calcProbabilityFire", 13)
      
      if (!suppliedElsewhere(sim$fit_g)) {
        sim <- numberStarts(sim) 
        #sim <- scheduleEvent(sim, time(sim), "fireCastor", "getIgnitionDistribution", 15)
      }
     
      #if (suppliedElsewhere(sim$probFireRasts)) {

     # sim$fireReport<-data.table(timeperiod= integer(), numberstarts = integer(), numberescaped = integer(), totalareaburned = integer(), thlbburned = integer())
      
     # sim$firedisturbanceTable<-data.table(scenario = scenario$name, numberFireReps = numberFireReps, pixelid = pts$pixelid, numberTimesBurned = as.integer(0))

        sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor") , "fireCastor", "simulateFire", 5)
        sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor") , "fireCastor", "saveFireRasters", 6)
     # }
        
        
    },
      
getStaticFireVariables = {
      sim <- getStaticVariables(sim) # create table with static fire variables to calculate probability of ignition, escape, spread. Dont reschedule because I only need this once
},

roadDistanceCalc ={
  sim <- roadDistCalc(sim) # if there is no road data then do this, and dont reschedule as because roading is not happening so I dont need to recalculate distance to roads.
  sim <- scheduleEvent(sim, time(sim) +P(sim, "calculateInterval", "fireCastor") , "fireCastor", "roadDistanceCalc", 11)
  },

getClimateFireVariables = {
    sim <- getClimateVariables (sim)
    sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor"), "fireCastor", "getClimateFireVariables", 11)
},

getVegVariables = {
  if(!suppliedElsewhere(sim$inv)){
        message('need to get vegetation attributes ')
        
      sim <- createVegetationTable(sim)
      #sim <- scheduleEvent(sim, eventTime = time(sim),  "fireCastor", "getVegVariables", eventPriority=8) # 
      # I did not schedule this again because this table gets updated during the disturbanceProcess parts of the simulation but does not need to be calculated again. 
      
  }
},
  
determineFuelTypes = {
      sim <- calcFuelTypes(sim)
      sim <- scheduleEvent(sim, eventTime = time(sim) + P(sim, "calculateInterval", "fireCastor"),  "fireCastor", "determineFuelTypes", eventPriority=12) # 
},

calcProbabilityFire = {
      sim <- calcProbFire(sim) 
      sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor") , "fireCastor", "calcProbabilityFire", 13)
},

getIgnitionDistribution = {
  sim <- numberStarts(sim) # create table with static fire variables to calculate probability of ignition, escape, spread. Dont reschedule because I only need this once
},

simulateFire ={
  sim<-distProcess(sim)
  sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor"), "fireCastor", "simulateFire", 5)
  },

saveFireRasters = {
  sim<-savefirerast(sim)
  sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor"), "fireCastor", "saveFireRasters", 6)
  
},


warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
              "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  
  #sim$firedisturbance <- sim$pts
  #sim$ras.info<-dbGetQuery(sim$castordb, "Select * from raster_info limit 1;")
  
  sim$firedisturbanceTable<-data.table(scenario = scenario$name, numberFireReps = P(sim, "numberFireReps", "fireCastor"), pixelid = sim$pts$pixelid, numberTimesBurned = as.integer(0))
  
  #sim$firedisturbanceTable<-data.table(scenario = as.character(), numberFireReps = as.numeric(), pixelid = as.numeric(), numberTimesBurned = as.integer())
  
  sim$fireReport<-data.table(timeperiod= integer(), numberstarts = integer(), numberescaped = integer(), totalareaburned = integer(), thlbburned = integer())
  
  
  
  return(invisible(sim))
  
}

getStaticVariables<-function(sim){
  if(!suppliedElsewhere(sim$fire_static)){
  
  message("get fire regime type")
  #constant coefficients
  sim$ras.frt<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                                srcRaster= P(sim, "nameFrtRaster", "fireCastor"), 
                                                clipper=sim$boundaryInfo[1] , 
                                                geom= sim$boundaryInfo[4] , 
                                                where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                conn=NULL))
  if(terra::ext(sim$ras) == terra::ext(sim$ras.frt)){
    sim$frt_id<-data.table(frt = as.integer(sim$ras.frt[]))
    sim$frt_id[, pixelid := seq_len(.N)][, frt := as.integer(frt)]
    sim$frt_id<-sim$frt_id[frt > 0, ]
  
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
        
    fire_static<-merge(ignit_lightning_static,ignit_human_static, by.x="pixelid", by.y="pixelid", all.x=TRUE)
    fire_static<-merge(fire_static,escape_static, by.x="pixelid", by.y="pixelid", all.x=TRUE)
    fire_static<-merge(fire_static,spread_static, by.x="pixelid", by.y="pixelid", all.x=TRUE)
    sim$fire_static<-merge(fire_static, sim$frt_id, by.x="pixelid", by.y="pixelid", all.x=TRUE)
    
    #add to the castordb
    # dbBegin(sim$castordb)
    # rs<-dbSendQuery(sim$castordb, "INSERT INTO firevariables (pixelid, frt, ignitstaticlightning, ignitstatichuman, escapestatic, spreadstatic) values (:pixelid, :frt, :ignitstaticlightning, :ignitstatichuman, :escapestatic, :spreadstatic)", fire_static)
    # dbClearResult(rs)
    # dbCommit(sim$castordb)
  
    rm(ras.ignitlightning, ignit_lightning_static, ras.ignithuman, ignit_human_static, ras.escape, escape_static, ras.spread, spread_static)
    gc()
  } else {
    print("using pre-existing fire_static variables")
  }
    
    return(invisible(sim)) 
    
}

# Maybe I dont need this??
# getDistanceToRoad<-function(sim){
#   
#   message("get distance to roads")
#   
#     #road_distance <- sim$road_distance # this step maybe unneccessary. ##CHECK: could check it both ways by putting sim$road_distance into the query instead of road_distance
#     
#     dbBegin(sim$castordb)
#     rs<-dbSendQuery(sim$castordb, 'UPDATE firevariables SET distancetoroads  = :road_distance WHERE pixelid = :pixelid', sim$road_distance) # I dont know if ending this with sim$road_distance will work.
#     dbClearResult(rs)
#     dbCommit(sim$castordb)  
# 
#     return(invisible(sim)) 
# }
    

roadDistCalc <- function(sim) { 
  
  road.dist<-data.table(dbGetQuery(sim$castordb, paste0("SELECT (case when ((",time(sim)*sim$updateInterval, " - roadstatus < ",P(sim, "recovery", "disturbanceCastor")," AND (roadtype != 0 OR roadtype IS NULL)) OR roadtype = 0) then 1 else 0 end) as road_dist, pixelid FROM pixels")))
  
  if(exists("road.dist")){
    outPts <- merge (sim$pts, road.dist, by = 'pixelid', all.x =TRUE) 
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
                                            srcRaster= P(sim, "nameRoadsRast", "fireCastor"), # this will likely be rast.ce_road_2019
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
      outPts <- merge (sim$pts, road.dist, by = 'pixelid', all.x =TRUE) 
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
  
  qry<-paste0("SELECT COUNT(*) as exists_check FROM sqlite_master WHERE type='table' AND name='climate_", time(sim)*sim$updateInterval + P(sim, "simStartYear", "fireCastor"),"_",P(sim, "gcmName", "fireCastor"),"_",P(sim, "ssp", "fireCastor"), "';")
  
  if(dbGetQuery(sim$castordb, qry)$exists_check==0) {
  
  message(paste0("create empty table of climate variables for year ", time(sim)*sim$updateInterval + P(sim, "simStartYear", "fireCastor")))
  
  qry<-paste0("CREATE TABLE IF NOT EXISTS climate_", time(sim)*sim$updateInterval + P(sim, "simStartYear", "fireCastor"),"_",P(sim, "gcmName", "fireCastor"),"_",P(sim, "ssp", "fireCastor")," (pixelid integer,  year integer, climate1lightning numeric, climate2lightning numeric, climate1person numeric, climate2person numeric, climate1escape numeric, climate2escape numeric, climate1spread numeric, climate2spread numeric)")
  
  dbExecute(sim$castordb, qry)
  
  message("extract elevation raster")
  
  #We need elevation because climate BC adjusts the climate according to the elevation of the sampling location. 
  
  #### get elevation and frt rasters ####
  sim$ras.elev<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                      srcRaster= P(sim, "nameElevationRaster", "fireCastor"), 
                                      clipper=sim$boundaryInfo[1] , 
                                      geom= sim$boundaryInfo[4] , 
                                      where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                      conn=NULL))
  
  if ((dbGetQuery(sim$castordb, paste0("SELECT MAX(elv) FROM pixels"))) < 2 ) {
    
    message("Passing elevation to pixels table as seems to be missing")
  
  if(terra::ext(sim$ras) == terra::ext(sim$ras.elev)){
    elev<-data.table(elv = as.numeric(sim$ras.elev[]))
    elev[, pixelid := seq_len(.N)][, elv := as.numeric(elv)]
    elev<-elev[elv > -10, ]
    
    #add to the castordb
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, "UPDATE pixels set elv = :elv where pixelid = :pixelid", elev)
    dbClearResult(rs)
    dbCommit(sim$castordb)
    gc()
  }else{
    stop(paste0("ERROR: extents are not the same check -", P(sim, "nameElevationRaster", "fireCastor")))
  }
  } else {
    message("elevation already in pixels table ... extracting")
    elev<-dbGetQuery(sim$castordb, paste0("SELECT elv, pixelid FROM pixels"))
    }
  
  message("change data format for download of climate data and save sample points")
    
    #a<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, crs="+proj=longlat +datum=WGS84")
    
    #ras2 <- terra::project(sim$ras, a)
  #### reproject lat long points ####
  
  ras2<-terra::project(sim$ras, "EPSG:4326")
  lat_lon_pts<-data.table(terra::xyFromCell(ras2,1:length(ras2[])))
  lat_lon_pts <- lat_lon_pts[, pixelid:= seq_len(.N)]
  
  sample.pts<-merge (lat_lon_pts, elev, by = 'pixelid', all.x =TRUE)
  
  #rm(ras2, lat_lon_pts)
  gc()
  
 colnames(sample.pts)[colnames(sample.pts) == "y"] <- "lat"
 colnames(sample.pts)[colnames(sample.pts) == "x"] <- "long"
 colnames(sample.pts)[colnames(sample.pts) == "elv"] <- "el"
 
 # I dont think climR works with more than three rows in the data.frame so Im removing the ID column
 sim$samp.pts<-sample.pts[,c("long", "lat", "el")]
  #} else {
   # message("climate sample points already extracted")
   #}
  
#  if (!file.exists(paste0(here::here(), "/R/SpaDES-modules/fireCastor/outputs/", scenario$name, time(sim)*sim$updateInterval + P(sim, "simStartYear", "fireCastor"),'_M.csv'))) {
 
 #### climR data collection####
message("Downloading climate data from climateBC ...")  

if (!exists("dbCon")){
  dbCon <- climRdev::data_connect() ##connect to database
  } else { message("connection to dbCon already made")}

    thebb <- get_bb(sim$samp.pts) ##get bounding box based on input points
    #dbCon <- climRdev::data_connect() ##connect to database
    normal <- normal_input_postgis(dbCon = dbCon, bbox = thebb, cache = TRUE) ##get normal data and lapse rates
    gcm_ts <- gcm_ts_input(dbCon, bbox = thebb, 
                           gcm = (P(sim, "gcm", "fireCastor")), 
                           ssp = (P(sim, "ssp", "fireCastor")),# c("ssp370"), 
                           years = time(sim)*sim$updateInterval + P(sim, "simStartYear", "fireCastor"),
                           max_run = (P(sim, "maxRun", "fireCastor")),
                           cache = TRUE)
    
    lat_lon_pts2<-data.table(terra::xyFromCell(normal[[1]],1:ncell(normal[[1]])))
    lat_lon_pts2 <- lat_lon_pts2[, pixelid_clim:= seq_len(.N)] # add in the pixelid which streams data in according to the 
    
    ras.frt2<-terra::project(sim$ras.frt, normal[[1]], method="near")
    ras.elev2<-terra::project(sim$ras.elev, normal[[1]])
    
    if(terra::ext(normal[[1]]) == terra::ext(ras.elev2)){
      elev<-data.table(elv = as.numeric(ras.elev2[]))
      elev[, pixelid_clim := seq_len(.N)][, elv := as.numeric(elv)]
      
      frt<-data.table(frt = as.numeric(ras.frt2[]))
      frt[, pixelid_clim := seq_len(.N)][, frt := as.numeric(frt)]
      
      dat<-merge(lat_lon_pts2, elev, by="pixelid_clim")
      colnames(dat)[colnames(dat) == "y"] <- "lat"
      colnames(dat)[colnames(dat) == "x"] <- "long"
      colnames(dat)[colnames(dat) == "elv"] <- "el"
      #dat2<-dat[el>-10,]
      dat3<-dat[,c("long","lat", "el")]
      
    }
    
    message("downscale Tmax")
    results_Tmax <- downscale(
      xyz = as.data.frame(dat3),
      normal = normal,
      gcm_ts = gcm_ts,
      vars = sprintf(c("Tmax%02d"),1:11)
    )
    
    message("downscale PPT")
    results_PPT <- downscale(
      xyz = as.data.frame(dat3),
      normal = normal,
      gcm_ts = gcm_ts,
      vars = sprintf(c("PPT%02d"),1:11)
    )
    
    message("downscale Tave")
    results_Tave <-downscale(
      xyz = as.data.frame(dat3),
      normal = normal,
      gcm_ts = gcm_ts,
      vars = sprintf(c("Tave%02d"),4:10)
    )
    
    message("downscale CMD")
    results_CMD <-downscale(
      xyz = as.data.frame(dat3),
      normal = normal,
      gcm_ts = gcm_ts,
      vars = sprintf(c("CMD%02d"),2:10)
    )
    
    #message("downscale RH")
    # results_RH <-downscale(
    #   xyz = as.data.frame(dat3),
    #   normal = normal,
    #   gcm_ts = gcm_ts,
    #   vars = sprintf(c("RH%02d"),2:10)
    # )
   
    results<-merge(results_Tmax, results_PPT, by.x = c("ID", "GCM", "SSP", "RUN", "PERIOD"), by.y=c("ID", "GCM", "SSP", "RUN", "PERIOD"))
    results<-merge(results, results_Tave, by.x = c("ID", "GCM", "SSP", "RUN", "PERIOD"), by.y=c("ID", "GCM", "SSP", "RUN", "PERIOD"))
    #results<-merge(results, results_RH, by.x = c("ID", "GCM", "SSP", "RUN", "PERIOD"), by.y=c("ID", "GCM", "SSP", "RUN", "PERIOD"))
    results<-merge(results, results_CMD, by.x = c("ID", "GCM", "SSP", "RUN", "PERIOD"), by.y=c("ID", "GCM", "SSP", "RUN", "PERIOD"))
    
    # Why do I do the step at results 3 or results 2. DOUBLE CHECK
    
    results2<-merge(dat[,c("long","lat", "pixelid_clim", "el")], results, by.x="pixelid_clim", by.y="ID")
    results4<-merge(results2, frt, by.x="pixelid_clim", by.y="pixelid_clim")
    
    results4<-results4[RUN == (P(sim, "run", "fireCastor")),]
    # 
    
  message("... done")
  message("...calculating MDC and assimilating climate variables by frt")
  
  
  # FOR EACH DATASET CALCULATE THE MONTHLY DROUGHT CODE Following Girardin & Wotton (2009)
  
  #_-------------------------------------------#
  #### Calculate drought code ####
  #____________________________________________#
  months<- c("01","02", "03", "04", "05", "06", "07", "08", "09", "10", "11")
  
  days_month<- c(27,31, 30, 31, 30, 31, 31, 30, 31, 30) # number of days in each month starting in Jan
 
  # Daylength adjustment factor (Lf) [Development and Structure of the Canadian Forest Fire Weather Index System pg 15, https://d1ied5g1xfgpx8.cloudfront.net/pdfs/19927.pdf]
  # Month <- Lf value
  # LF[1] is the value for March
  Lf<-c(-1.6,-1.6, 0.9, 3.8, 5.8, 6.4, 5.0, 2.4, 0.4, -1.6)
  
  ### Calculate drought code for Fire ignition data

    #x2<- climate2 %>% dplyr::filter(Tmax05 != -9999) # there are some locations that did not have climate data, probably because they were over the ocean, so Im removing these here.
  
  message("calculate monthly drought code")
    
    for (j in 1 : length(Lf)) {
      
      
      results4$MDC_01<-15 # the MDC value for Feb This assumes that the ground is saturated at the start of the season. Maybe not true for all locations... may need to think about this a little more.
      
      Em<- days_month[j]*((0.36*results4[[paste0("Tmax",months[j+1])]])+Lf[j])
      Em2 <- ifelse(Em<0, 0, Em)
      DC_half<- results4[[paste0("MDC_",months[j])]] + (0.25 * Em2)
      precip<-results4[[paste0("PPT",months[j+1])]]
      RMeff<-(0.83 * (results4[[paste0("PPT",months[j+1])]]))
      Qmr<- (800 * exp((-(DC_half))/400)) + (3.937 * RMeff)
      Qmr2 <- ifelse(Qmr>800, 800, Qmr)
      MDC_m <- (400 * log(800/Qmr2)) + 0.25*Em2
      results4[[paste0("MDC_",months[j+1])]] <- (results4[[paste0("MDC_",months[j])]] + MDC_m)/2
      results4[[paste0("MDC_",months[j+1])]] <- ifelse(results4[[paste0("MDC_",months[j+1])]] <15, 15, results4[[paste0("MDC_",months[j+1])]])
    }
  
  
  
  # Lightning climate variables
  #climate_variables_lightning<-read.csv("C:/Work/caribou/castor_data/Fire/Fire_sim_data/data/climate_AIC_results_lightning_FRT_summary.csv")  
  
  results4[frt=="5",climate1_lightning:=(Tave05 + Tave06 + Tave07 + Tave08)/4]
  results4[frt=="5",climate2_lightning:=(PPT05 + PPT06 + PPT07 + PPT08)/4]
  results4[frt=="7", climate1_lightning:=(Tmax03 + Tmax04 + Tmax05 + Tmax06 + Tmax07 + Tmax08)/6]
  results4[frt=="9", climate1_lightning:=(Tave04 + Tave05 + Tave06 +Tave07 +Tave08 + Tave09)/6]
  results4[frt=="10", climate1_lightning:=(Tave08 + Tave09)/2]
  results4[frt=="10", climate2_lightning:=(PPT07 + PPT08)/2]
  results4[frt=="11", climate1_lightning:=(Tave03 + Tave04 + Tave05 + Tave06 + Tave07 + Tave08)/6]
  results4[frt=="12", climate1_lightning:=(Tmax07 + Tmax08)/2]
  results4[frt=="13", climate1_lightning:=Tave07]
  results4[frt=="13", climate2_lightning:=PPT07]
  results4[frt=="14", climate1_lightning:=CMD07]
  results4[frt=="15", climate1_lightning:=(Tave07 + Tave08)/2]
  results4[frt=="15", climate2_lightning:=(PPT07 + PPT08)/2]
  
  
  # Person Climate variables not included in lightning
  #climate_variables_person<-read.csv("C:/Work/caribou/castor_data/Fire/Fire_sim_data/data/climate_AIC_results_person_FRT_summary.csv")
  
  results4[frt==5, climate1_person:=(PPT06+PPT07)/2]
  results4[frt==7, climate1_person:=(Tmax05+Tmax06+Tmax07+Tmax08)/4]
  results4[frt==9, climate1_person:=(Tave04+Tave05+Tave06+Tave07)/4]
  results4[frt==9, climate2_person:=(PPT04+PPT05+PPT06+PPT07)/4]
  results4[frt==10, climate1_person:=(CMD06 + CMD07 + CMD08 + CMD09)/4]
  results4[frt==11, climate1_person:=(Tmax04+ Tmax05 + Tmax06+ Tmax07)/4]
  results4[frt==11, climate2_person:=(PPT04+ PPT05 + PPT06+ PPT07)/4]
  results4[frt==12, climate1_person:=(Tmax04+ Tmax05 + Tmax06+ Tmax07 + Tmax08 +Tmax09)/6]
  results4[frt==13, climate1_person:=(Tmax04+ Tmax05 + Tmax06+ Tmax07 + Tmax08 +Tmax09)/6]
  results4[frt==14, climate1_person:=(Tmax04+ Tmax05 + Tmax06+ Tmax07 + Tmax08 +Tmax09)/6]
  results4[frt==15, climate1_person:=(Tave06+ Tave07 + Tave08)/3]
  results4[frt==15, climate2_person:=(PPT06+ PPT07 + PPT08)/3]
  
  # escape variables not listed above
  #climate_escape<-read.csv("C:\\Work\\caribou\\castor_data\\Fire\\Fire_sim_data\\data\\climate_AIC_results_escape_summary_Oct23.csv")
  results4<-results4 %>%
    dplyr::mutate(climate1_escape = dplyr::case_when(
      frt == "5" ~ as.numeric(PPT05) ,
      frt == "7" ~ as.numeric(PPT06),
      frt == "9" ~ Tave05,
      frt == "10" ~ as.numeric((PPT04 + PPT05 + PPT06)/3),
      frt == "11" ~ MDC_06,
      frt == "12" ~ (Tmax07 + Tmax08 + Tmax09)/3,
      frt == "13" ~ (Tmax07 + Tmax08 + Tmax09)/3,
      frt == "14" ~ as.numeric((MDC_05 + MDC_06 + MDC_07 + MDC_08)/4),
      frt == "15" ~ (Tave07 + Tave08 + Tave09)/3 ,
      TRUE ~ NA_real_))
  
  results4<-results4 %>%
    dplyr::mutate(climate2_escape = dplyr::case_when(
      frt == "7" ~ Tave06,
      frt == "12" ~ as.numeric((PPT07 + PPT08 + PPT09)/3) ,
      frt == "13" ~ as.numeric((PPT07 + PPT08 + PPT09)/3),
      frt == "15" ~ as.numeric((PPT07 + PPT08 + PPT09)/3),
      TRUE ~ NA_real_))
  
  # spread variables not listed above
  # climate_spread<-read.csv("C:\\Work\\caribou\\castor_data\\Fire\\Fire_sim_data\\data\\climate_AIC_results_spread_summary_March2023.csv")
  results4<-results4 %>%
    dplyr::mutate(climate1_spread = dplyr::case_when(
      frt == "5" ~ Tmax07 ,
      frt == "7" ~ (Tmax07 + Tmax08 + Tmax09)/3,
      frt == "9" ~ (Tave04 + Tave05 + Tave06)/3,
      frt == "10" ~ as.numeric((RH05 + RH06 + RH07 + RH08)/4),
      frt == "11" ~ as.numeric(RH08),
      frt == "12" ~  (Tave05 + Tave06 + Tave07 +Tave08)/4,
      frt == "13" ~  (Tave05 + Tave06 + Tave07 +Tave08)/4,
      frt == "14" ~  (Tave05 + Tave06 + Tave07)/3,
      frt == "15" ~ Tave05,
      TRUE ~ NA_real_))
  
  #Repeat for climate 2
  
  results4<-results4 %>%
    dplyr::mutate(climate2_spread = dplyr::case_when(
      frt == "5" ~ as.numeric(PPT07),
      frt == "7" ~ as.numeric((PPT07 + PPT08 + PPT09)/3),
      frt == "9" ~ as.numeric((PPT04 + PPT05 + PPT06)/3),
      frt == "10" ~ as.numeric((PPT05 + PPT06 +PPT07 + PPT08)/4) ,
      frt == "11" ~ as.numeric(PPT08),
      frt == "12" ~ as.numeric((PPT05 + PPT06 +PPT07 + PPT08)/4) ,
      frt == "13" ~ as.numeric((PPT05 + PPT06 +PPT07 + PPT08)/4) ,
      frt == "14" ~ as.numeric((PPT05 + PPT06 +PPT07)/3) ,
      frt == "15" ~ as.numeric(PPT05),
      TRUE ~ NA_real_))
  
 # climate2[, year:=time(sim)*sim$updateInterval + P(sim, "simStartYear", "fireCastor")]
  
  #### change extent of climate variables back ####
  
  # extract pixelid values for larger raster and relate it to the pixel values of the 100x 100m landscape. Then I can join fire variable data back to the original data through the pixelid of the larger area raster. I tried to do this but it kept messing up so eventually I gave up. 
  
  rast_id<-raster(extent(ext(normal[[1]])[1], ext(normal[[1]])[2], ext(normal[[1]])[3], ext(normal[[1]])[4]), nrow = dim(normal[[1]])[1], ncol = dim(normal[[1]])[2], vals =0)
  
  rast_id[]<-results4$climate1_lightning
  crs(rast_id) <- CRS('+init=EPSG:4326')
  rast_id<-rast(rast_id)
  rast_id2<-terra::project(rast_id, "EPSG:3005", method="near")
  rast_id2<-raster(rast_id2)
  
 pts<-as.data.frame(sim$pts[,c("x", "y", "pixelid")])
  sp<-SpatialPointsDataFrame(pts[,c("x","y")], proj4string=rast_id2@crs, pts)
  
  #lightning1
  lightning1<-raster::extract(rast_id2, sp,  method='simple', buffer=NULL, df=TRUE)
  lightning1$pixelid<-sp$pixelid
  names(lightning1) <- c('ID','climate1_lightning','pixelid')
  lightning1<-lightning1[,c('climate1_lightning','pixelid')]
  
  rm(rast_id, rast_id2)
  
  
  # lightning2
  rast_id<-raster(extent(ext(normal[[1]])[1], ext(normal[[1]])[2], ext(normal[[1]])[3], ext(normal[[1]])[4]), nrow = dim(normal[[1]])[1], ncol = dim(normal[[1]])[2], vals =0)
  
  rast_id[]<-results4$climate2_lightning
  crs(rast_id) <- CRS('+init=EPSG:4326')
  rast_id<-rast(rast_id)
  rast_id2<-terra::project(rast_id, "EPSG:3005", method="near")
  rast_id2<-raster(rast_id2)
  lightning2<-raster::extract(rast_id2, sp,  method='simple', buffer=NULL, df=TRUE)
  lightning2$pixelid<-sp$pixelid
  names(lightning2) <- c('ID','climate2_lightning','pixelid')
  lightning2<-lightning2[,c('climate2_lightning','pixelid')]
  rm(rast_id, rast_id2)
  
  # person1
  rast_id<-raster(extent(ext(normal[[1]])[1], ext(normal[[1]])[2], ext(normal[[1]])[3], ext(normal[[1]])[4]), nrow = dim(normal[[1]])[1], ncol = dim(normal[[1]])[2], vals =0)
  
  rast_id[]<-results4$climate1_person
  crs(rast_id) <- CRS('+init=EPSG:4326')
  rast_id<-rast(rast_id)
  rast_id2<-terra::project(rast_id, "EPSG:3005", method="near")
  rast_id2<-raster(rast_id2)
  person1<-raster::extract(rast_id2, sp,  method='simple', buffer=NULL, df=TRUE)
  person1$pixelid<-sp$pixelid
  names(person1) <- c('ID','climate1_person','pixelid')
  person1<-person1[,c('climate1_person','pixelid')]
  
  rm(rast_id, rast_id2)
  
  # person2
  rast_id<-raster(extent(ext(normal[[1]])[1], ext(normal[[1]])[2], ext(normal[[1]])[3], ext(normal[[1]])[4]), nrow = dim(normal[[1]])[1], ncol = dim(normal[[1]])[2], vals =0)
  
  rast_id[]<-results4$climate2_person
  crs(rast_id) <- CRS('+init=EPSG:4326')
  rast_id<-rast(rast_id)
  rast_id2<-terra::project(rast_id, "EPSG:3005", method="near")
  rast_id2<-raster(rast_id2)
  person2<-raster::extract(rast_id2, sp,  method='simple', buffer=NULL, df=TRUE)
  person2$pixelid<-sp$pixelid
  names(person2) <- c('ID','climate2_person','pixelid')
  person2<-person2[,c('climate2_person','pixelid')]
  rm(rast_id, rast_id2)

  # escape1
  rast_id<-raster(extent(ext(normal[[1]])[1], ext(normal[[1]])[2], ext(normal[[1]])[3], ext(normal[[1]])[4]), nrow = dim(normal[[1]])[1], ncol = dim(normal[[1]])[2], vals =0)
  
  rast_id[]<-results4$climate1_escape
  crs(rast_id) <- CRS('+init=EPSG:4326')
  rast_id<-rast(rast_id)
  rast_id2<-terra::project(rast_id, "EPSG:3005", method="near")
  rast_id2<-raster(rast_id2)
  escape1<-raster::extract(rast_id2, sp,  method='simple', buffer=NULL, df=TRUE)
  escape1$pixelid<-sp$pixelid
  names(escape1) <- c('ID','climate1_escape','pixelid')
  escape1<-escape1[,c('climate1_escape','pixelid')]
  rm(rast_id, rast_id2)
  
  # escape2
  rast_id<-raster(extent(ext(normal[[1]])[1], ext(normal[[1]])[2], ext(normal[[1]])[3], ext(normal[[1]])[4]), nrow = dim(normal[[1]])[1], ncol = dim(normal[[1]])[2], vals =0)
  
  rast_id[]<-results4$climate2_escape
  crs(rast_id) <- CRS('+init=EPSG:4326')
  rast_id<-rast(rast_id)
  rast_id2<-terra::project(rast_id, "EPSG:3005", method="near")
  rast_id2<-raster(rast_id2)
  escape2<-raster::extract(rast_id2, sp,  method='simple', buffer=NULL, df=TRUE)
  escape2$pixelid<-sp$pixelid
  names(escape2) <- c('ID','climate2_escape','pixelid')
  escape2<-escape2[,c('climate2_escape','pixelid')]
  rm(rast_id, rast_id2)
  
  # spread 1
  rast_id<-raster(extent(ext(normal[[1]])[1], ext(normal[[1]])[2], ext(normal[[1]])[3], ext(normal[[1]])[4]), nrow = dim(normal[[1]])[1], ncol = dim(normal[[1]])[2], vals =0)
  
  rast_id[]<-results4$climate1_spread
  crs(rast_id) <- CRS('+init=EPSG:4326')
  rast_id<-rast(rast_id)
  rast_id2<-terra::project(rast_id, "EPSG:3005", method="near")
  rast_id2<-raster(rast_id2)
  spread1<-raster::extract(rast_id2, sp,  method='simple', buffer=NULL, df=TRUE)
  spread1$pixelid<-sp$pixelid
  names(spread1) <- c('ID','climate1_spread','pixelid')
  spread1<-spread1[,c('climate1_spread','pixelid')]
  rm(rast_id, rast_id2)
  
  # spread 2
  rast_id<-raster(extent(ext(normal[[1]])[1], ext(normal[[1]])[2], ext(normal[[1]])[3], ext(normal[[1]])[4]), nrow = dim(normal[[1]])[1], ncol = dim(normal[[1]])[2], vals =0)
  
  rast_id[]<-results4$climate2_spread
  crs(rast_id) <- CRS('+init=EPSG:4326')
  rast_id<-rast(rast_id)
  rast_id2<-terra::project(rast_id, "EPSG:3005", method="near")
  rast_id2<-raster(rast_id2)
  spread2<-raster::extract(rast_id2, sp,  method='simple', buffer=NULL, df=TRUE)
  spread2$pixelid<-sp$pixelid
  names(spread2) <- c('ID','climate2_spread','pixelid')
  spread2<-spread2[,c('climate2_spread','pixelid')]
  
  #sim$results4<-results4
  
  # Merge the dataframes
  #library(tidyverse)
  df_list <- list(lightning1, lightning2, person1, person2, escape1, escape2, spread1, spread2)
  
  #merge all data frames in list
  clim_dat<-df_list %>% purrr::reduce(dplyr::full_join, by='pixelid')
  clim_dat$year<-time(sim)*sim$updateInterval + P(sim, "simStartYear", "fireCastor")
  

  #CHECK it looks ok
  # ras.info<-dbGetQuery(mySim$castordb, "Select * from raster_info limit 1;")
  # clim<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0)
  # 
  # clim[]<-clim_dat$climate1_spread
  # plot(clim)

  qry<-paste0("INSERT INTO climate_", time(sim)*sim$updateInterval + P(sim, "simStartYear", "fireCastor"),"_",P(sim, "gcmName", "fireCastor"),"_",P(sim, "ssp", "fireCastor"), " (pixelid, year, climate1lightning, climate2lightning, climate1person, climate2person, climate1escape, climate2escape, climate1spread, climate2spread) VALUES (:pixelid, :year, :climate1_lightning, :climate2_lightning, :climate1_person, :climate2_person, :climate1_escape, :climate2_escape, :climate1_spread, :climate2_spread)")
              
   dbBegin(sim$castordb)
   rs<-dbSendQuery(sim$castordb, qry, clim_dat)
   dbClearResult(rs)
   dbCommit(sim$castordb)
   
  rm(clim_dat, rast_id,rast_id2, days_month, DC_half, Em, Em2, MDC_m, precip, Qmr, Qmr2, RMeff)
  gc()
  } else {
    "climate variable table already exists"}
  
  return(invisible(sim))
  
  #} else {message ("climate data already collected")}
}

createVegetationTable <- function(sim) {
  
  message("create fuel types table")
  
  #dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS fueltype (pixelid integer, bclcs_level_1 character, bclcs_level_2 character, bclcs_level_3 character,  bclcs_level_5 character, inventory_standard_cd character, non_productive_cd character, coast_interior_cd character,  land_cover_class_cd_1 character, zone character, subzone character, earliest_nonlogging_dist_type character,earliest_nonlogging_dist_date, integer years_since_nonlogging_dist integer, vri_live_stems_per_ha numeric, vri_dead_stems_per_ha numeric, species_cd_1 character, species_pct_1 numeric, species_cd_2 character, species_pct_2 numeric, dominant_conifer character, conifer_pct_cover_total numeric)")
  
  # Get bec zone and bec subzone
  
  message("getting BEC information")
  
  ras.bec<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                     srcRaster= P(sim, "nameBecRast", "fireCastor"), 
                                     clipper=sim$boundaryInfo[1] , 
                                     geom= sim$boundaryInfo[4] , 
                                     where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                     conn=NULL))
  
  if(terra::ext(sim$ras) == terra::ext(ras.bec)){ #need to check that each of the extents are the same
    bec_id<-data.table(idkey = as.integer(ras.bec[]))
    bec_id[, pixelid := seq_len(.N)][, idkey := as.integer(idkey)]
    rm(ras.bec)
    gc()
  }else{
    stop(paste0("ERROR: extents are not the same check -", P(sim, "nameBecRast", "fireCastor")))
  }
  
  bec_id_key<-unique(bec_id[!(is.na(idkey)), idkey])
  bec_key<-data.table(getTableQuery(paste0("SELECT idkey, zone, subzone FROM ",P(sim, "nameBecTable","fireCastor"), " WHERE idkey IN (", paste(bec_id_key, collapse = ","),");")))
  
  bec<-merge(x=bec_id, y=bec_key, by.x = "idkey", by.y = "idkey", all.x = TRUE) 
  bec<-bec[, idkey:=NULL] # remove the fid key
  

  #**************FOREST INVENTORY - VEGETATION VARIABLES*******************#
  #----------------------------#
  #----Set forest attributes----
  #----------------------------#
  if(!P(sim, "nameForestInventoryRaster","dataCastor") == '99999'){
    message("clipping inventory key")
    ras.fid<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                       srcRaster= P(sim, "nameForestInventoryRaster", "dataCastor"), 
                                       clipper=sim$boundaryInfo[[1]], 
                                       geom= sim$boundaryInfo[[4]], 
                                       where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                       conn=NULL))
    if(terra::ext(sim$ras) == terra::ext(ras.fid)){ #need to check that each of the extents are the same
      inv_id<-data.table(fid = as.integer(ras.fid[]))
      inv_id[, pixelid:= seq_len(.N)]
      inv_id[, fid:= as.integer(fid)] #make sure the fid is an integer for merging later on
      rm(ras.fid)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameForestInventoryRaster", "dataCastor")))
    }
    
    
    if(!P(sim, "nameForestInventoryTable2","fireCastor") == '99999'){ #Get the forest inventory variables 
      
      fuel_attributes_castordb<-c('bclcs_level_1', 'bclcs_level_2', 'bclcs_level_3',  'bclcs_level_5', 'inventory_standard_cd', 'non_productive_cd', 'coast_interior_cd',  'land_cover_class_cd_1', 'earliest_nonlogging_dist_type', 'earliest_nonlogging_dist_date','vri_live_stems_per_ha', 'vri_dead_stems_per_ha','species_cd_1','species_pct_1','species_cd_2', 'species_pct_2', 'species_cd_3', 'species_pct_3','species_cd_4','species_pct_4', 'species_cd_5', 'species_pct_5', 'species_cd_6', 'species_pct_6')
      
      if(length(fuel_attributes_castordb) > 0){
        print(paste0("getting inventory attributes to create fuel types: ", paste(fuel_attributes_castordb, collapse = ",")))
        fids<-unique(inv_id[!(is.na(fid)), fid])
        attrib_inv<-data.table(getTableQuery(paste0("SELECT " , "feature_id", " as fid, ", paste(fuel_attributes_castordb, collapse = ","), " FROM ",P(sim, "nameForestInventoryTable2","fireCastor"), " WHERE ", "feature_id" ," IN (",
                                                    paste(fids, collapse = ","),");" )))
        
        
        message("...merging with fid") #Merge this with the raster using fid which gives you the primary key -- pixelid
        inv<-merge(x=inv_id, y=attrib_inv, by.x = "fid", by.y = "fid", all.x = TRUE) 
        inv<-inv[, fid:=NULL] # remove the fid key
        
        inv<-merge(x=inv, y=bec, by.x="pixelid", by.y="pixelid", all.x=TRUE)
        
        inv[, earliest_nonlogging_dist_date := substr(earliest_nonlogging_dist_date,1,4)]
        inv[, earliest_nonlogging_dist_date := as.integer(earliest_nonlogging_dist_date)]
      
      
        message("calculating % conifer and dominant conifer species")
        
        conifer<-c("C","CW","Y","YC","F","FD","FDC","FDI","B","BB","BA","BG","BL","H","HM","HW","HXM","J","JR","JS","P","PJ","PF","PL","PR","PLI","PXJ","PY","PLC","PW","PA","S","SB","SE","SS","SW","SX","SXW","SXL","SXS","T","TW","X", "XC","XH", "ZC")
        
        inv[, pct1:=0][species_cd_1 %in% conifer, pct1:=species_pct_1]
        inv[, pct2:=0][species_cd_2 %in% conifer, pct2:=species_pct_2]
        inv[, pct3:=0][species_cd_3 %in% conifer, pct3:=species_pct_3]
        inv[, pct4:=0][species_cd_4 %in% conifer, pct4:=species_pct_4]
        inv[, pct5:=0][species_cd_5 %in% conifer, pct5:=species_pct_5]
        inv[, pct6:=0][species_cd_6 %in% conifer, pct6:=species_pct_6]
        
        # create dominant conifer column and populate
        inv[, dominant_conifer:="none"]
        inv[species_cd_1 %in% conifer, dominant_conifer:=species_cd_1]
        inv[!(species_cd_1 %in% conifer) & species_cd_2 %in% conifer, dominant_conifer:=species_cd_2]
        inv[!(species_cd_1 %in% conifer) & !(species_cd_2 %in% conifer) & species_cd_3 %in% conifer, dominant_conifer:=species_cd_3]
        inv[!(species_cd_1 %in% conifer) & !(species_cd_2 %in% conifer) & !(species_cd_3 %in% conifer) & species_cd_4 %in% conifer, dominant_conifer:=species_cd_4]
        inv[!(species_cd_1 %in% conifer) & !(species_cd_2 %in% conifer) & !(species_cd_3 %in% conifer) & !(species_cd_4 %in% conifer) & species_cd_5 %in% conifer, dominant_conifer:=species_cd_5]
        inv[!(species_cd_1 %in% conifer) & !(species_cd_2 %in% conifer) & !(species_cd_3 %in% conifer) & !(species_cd_4 %in% conifer) & !(species_cd_5 %in% conifer) & species_cd_6 %in% conifer, dominant_conifer:=species_cd_6]
        
        #determing total percent cover of conifer species
        inv[,conifer_pct_cover_total:=pct1+pct2+pct3+pct4+pct5+pct6]
        
        # remove extra unneccesary columns
        inv<-inv[, c("species_cd_3", "species_cd_4", "species_cd_5", "species_cd_6", "species_pct_3", "species_pct_4", "species_pct_5", "species_pct_6","pct1", "pct2", "pct3", "pct4", "pct5", "pct6"):=NULL] 
        
        sim$inv<-inv
        rm(inv_id, attrib_inv)
        gc()
    
  
    ###Note in forestryCastor it looks like he updates harvest by setting age and volume to zero. Maybe I can use this somehow for my vegetation types because I think I need the field harvest date. 
      } else {
        message("no vegetation attributes supplied to determine fuel types")
      } 
      
    }else {
      message("no VRI shapefile supplied")
    }
    
  } else {
    message("no feature id key raster supplied for VRI")
  }
  
  return(invisible(sim)) 
}


calcFuelTypes<- function(sim) {
  
  conifer<-c("C","CW","Y","YC","F","FD","FDC","FDI","B","BB","BA","BG","BL","H","HM","HW","HXM","J","JR","JS","P","PJ","PF","PL","PR","PLI","PXJ","PY","PLC","PW","PA","S","SB","SE","SS","SW","SX","SXW","SXL","SXS","T","TW","X", "XC","XH", "ZC")
  
  deciduous<-c("L", "LA", "LT", "LW", "D", "DR", "U", "UP", "A", "AC", "ACB", "ACT", "AX", "AT", "R", "RA", "E", "EA", "EXP", "EP", "EW", "K", "KC", "V", "VB", "VV", "VP", "G", "M", "MB", "MV", "Q", "QG", "W", "WB", "WP", "WA", "WD", "WS", "WT", "XH", "ZH")
  
  wet<-c("mc", "mcp", "mh", "mk", "mkp", "mks", "mm", "mmp", "mmw", "ms", "mv", "mvp", "mw", "mwp", "mww", "vc", "vcp", "vcw", "vh", "vk", "vks", "vm", "wc", "wcp", "wcw", "wh", "whp", "wk", "wm", "wmp", "wmu", "ws", "wv", "wvp", "ww")
  
  burn<-c("B","BE", "BG", "BR", "BW", "NB")
  
  ## extract data from BEC instead of pulling it off the vri. I think it will be better!
message("getting vegetation data")

# if (nrow(sim$inv)<1){
#   sim$inv<-data.table(dbGetQuery(sim$castordb, "SELECT * FROM fueltype"))
# }

  veg_attributes<- data.table(dbGetQuery(sim$castordb, "SELECT pixelid, crownclosure, age, vol, height, dec_pcnt, blockid FROM pixels"))
  
  veg2<-merge(sim$inv, veg_attributes, by.x="pixelid", by.y = "pixelid", all.x=TRUE)
  
  rm(veg_attributes)
  gc()

  message("calculating time since disturbance")

  veg2[, years_since_nonlogging_dist:=NA_integer_]
  veg2[, years_since_nonlogging_dist:=(time(sim)*sim$updateInterval) + P(sim, "simStartYear","fireCastor") - earliest_nonlogging_dist_date]
  
  message("categorizing data into fuel types")
  
  #### Calculate fuel types ####
  
  # running the query from least specific to most specific so that I dont overwrite fuel types
  #veg2[, fwveg:="none"]
  
  # limited vegetation information  but has bec designation
 
  veg2[bclcs_level_5 %in% c("GL","LA"), bclcs_level_2 == "W"]
  
  veg2[bclcs_level_1=="N", fwveg:="N"]
  veg2[bclcs_level_2=="W", fwveg:="W"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & zone %in% c("CMA", "IMA"), fwveg:="N"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone == "BAFA", fwveg:="D-1/2"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone=="CWH", fwveg:="M-1/2"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone == "CWH" & subzone %in% wet, fwveg:="C-5"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone == "BWBS", fwveg:="C-2"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone == "SWB", fwveg:="M-1/2"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone == "SBS", fwveg:="C-3"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone == "SBPS", fwveg:="C-7"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone == "MS", fwveg:="C-3"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone == "IDF", fwveg:="C-7"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone=="IDF" & subzone %in% wet, fwveg:="M-1/2"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone == "PP", fwveg:="C-7"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone == "BG", fwveg:="O-1a/b"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone=="MH", fwveg:="C-5"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone=="ESSF", fwveg:="C-3"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone == "CDF", fwveg:="C-7"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone=="CDF" & subzone %in% wet, fwveg:="C-5"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone == "ICH", fwveg:="M-1/2"]
  veg2[is.na(bclcs_level_1) & is.na(species_cd_1) & is.na(species_cd_2) & zone == "ICH" & subzone %in% wet, fwveg:="C-5"]
  

  ##--------------------------##
  #### bclcs_level_1 == "N" ####
  ##--------------------------##
    
  # not logged and not recently burned  & bclcs_level_1 =="N"
  veg2[bclcs_level_1=="N" & (bclcs_level_2=="L" | is.na(bclcs_level_2)) & species_pct_1 > 0, fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="N" & (bclcs_level_2=="L" | is.na(bclcs_level_2)) &  species_pct_1 > 0 & zone %in% c("CWH", "MH", "ICH"), fwveg:="D-1/2"] 
  
  #logged less than 6 yrs before  & bclcs_level_1 =="N"
  veg2[bclcs_level_1=="N" & blockid>0 & age<= 6 & coast_interior_cd=="C", fwveg:="S-3"]
  veg2[bclcs_level_1=="N" & blockid>0 & age<= 6 & coast_interior_cd =="I",fwveg:="S-1"]
  
  # harvest date 7-24 & bclcs_level_1 =="N"
  veg2[bclcs_level_1=="N" & blockid>0 & (age %between% c(7,24)), fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="N" & blockid>0 & (age %between% c(7,24)) & zone %in% c("CWH","MH","ICH"), fwveg:="D-1/2"]
       
  # harvest date > 25 & bclcs_level_1 =="N"
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone %in% c("CMA","IMA"), fwveg:="N"]
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone=="BAFA", fwveg:= "D-1/2"]
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone=="CWH" & (subzone %in% wet), fwveg:="C-5"]
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone=="CWH" & !(subzone %in% wet), fwveg:="M-1/2"]
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone=="BWBS", fwveg:="C-2"]
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone=="SWB", fwveg:="M-1/2"]
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone=="SBS", fwveg:="C-3"]
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone=="SBPS", fwveg:="C-7"]
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone=="MS", fwveg:="C-7"]
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone=="IDF" & (subzone %in% wet), fwveg:="C-3"]
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone=="IDF" & !(subzone %in% wet), fwveg:="C-7"]
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone %in% c("PP","BG"), fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone=="MH", fwveg:="D-1/2"]
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone=="ESSF", fwveg:="C-7"]
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone=="CDF" & (subzone %in% wet), fwveg:="C-5"]
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone=="CDF" & !(subzone %in% wet), fwveg:="C-7"]
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone=="ICH" & (subzone %in% wet), fwveg:="C-5"]
  veg2[bclcs_level_1=="N" & blockid>0 & age>=25 & zone=="ICH" & !(subzone %in% wet), fwveg:="C-3"]
  
  # not vegetated, not logged, but burned fairly recently
  veg2[bclcs_level_1=="N" & earliest_nonlogging_dist_type %in% burn & years_since_nonlogging_dist  <=3, fwveg:="N"]
  veg2[bclcs_level_1=="N" & earliest_nonlogging_dist_type %in% burn & (years_since_nonlogging_dist >=4 & years_since_nonlogging_dist <= 6), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="N" & earliest_nonlogging_dist_type %in% burn & (years_since_nonlogging_dist >= 7 & years_since_nonlogging_dist <=10), fwveg:="O-1a/b"]
      
  ##------------------------------------------------##
  #### bclcs_level_1 == "V" & bclcs_level_2 =="N" ####
  ##------------------------------------------------##
  
  ### non-forested bclcs_level_2==N recently burned
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & earliest_nonlogging_dist_type %in% burn & years_since_nonlogging_dist < 2, fwveg:="N"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & earliest_nonlogging_dist_type %in% burn & (years_since_nonlogging_dist >=2 & years_since_nonlogging_dist<= 3), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & earliest_nonlogging_dist_type %in% burn & (years_since_nonlogging_dist >=4 & years_since_nonlogging_dist<= 10), fwveg:="O-1a/b"]
  
  ### logged
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age<=7, fwveg:="S-1"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age<=7 & species_cd_1 %in% c("P","PJ","PF","PL","PR","PLI","PXJ","PY","PLC","PW","PA"), fwveg:="S-1"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age <=7 & species_cd_1 %in% c("B","BB","BA","BG","BL","S","SB","SE","SS","SW","SX","SXW","SXL","SXS"), fwveg:="S-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age<=7 & species_cd_1 %in% c("CW","YC","H","HM","HW","HXM"), fwveg:="S-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age<=7 & species_cd_1 == "FD" & zone %in% c("CWH", "ICH"), fwveg:="S-3"]
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age %between% c(8, 24) & zone %in% c("CWH", "MH"), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age %between% c(8, 24) & zone == "ICH" & subzone %in% wet, fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age %between% c(8, 24), fwveg:="O-1a/b"]
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age>=25 & zone %in% c("CMA", "IMA"), fwveg:="N"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age >=25 & zone == "BAFA", fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age >=25 & zone == "CWH", fwveg:="M-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age >=25 & zone == "CWH" & subzone %in% wet, fwveg:="C-5"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age >=25 & zone == "BWBS", fwveg:="C-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age >=25 & zone=="SWB", fwveg:="M-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age >=25 & zone=="SBS", fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age >=25 & zone=="SBPS", fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & age >=25 & zone %in% c("MS", "ESSF"), fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age >=25 & zone %in% c("IDF", "CDF"), fwveg:= "C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age >=25 & zone=="IDF" & subzone %in% wet, fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age >=25 & zone %in% c("PP", "BG"), fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age >=25 & zone=="MH", fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age >=25 & zone=="ICH", fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid>0 & age >=25 & zone %in% c("CDF", "ICH") & subzone %in% wet, fwveg:="C-5"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age <=5, fwveg:="S-1"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age %between% c(6, 24), fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age %between% c(6, 24) & zone %in% c("CWH", "MH", "ICH"), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age >= 25 & zone %in% c("CMA", "IMA"), fwveg:="N"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age >= 25 & zone=="BAFA", fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age >= 25 & zone=="CWH", fwveg:="M-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age >= 25 & zone=="CWH" & subzone %in% wet, fwveg:="C-5"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age >= 25 & zone=="BWBS", fwveg:="C-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age >= 25 & zone=="SWB", fwveg:="M-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age >= 25 & zone=="SBS", fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age >= 25 & zone=="SBPS", fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age >= 25 & zone=="MS", fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age >= 25 & zone=="IDF" & subzone %in% wet, fwveg:="M-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age >= 25 & zone=="IDF", fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age >= 25 & zone %in% c("PP", "BG"), fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age >= 25 & zone=="MH", fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age >= 25 & zone %in% c("ESSF", "CDF"), fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age >= 25 & zone=="ICH", fwveg:="M-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & is.na(species_cd_1) & blockid>0 & age >= 25 & zone %in% c("CDF", "ICH") & subzone %in% wet, fwveg:="C-5"]
 
  
  #### Unlogged

  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & !is.na(species_cd_1), fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & !is.na(species_cd_1) & zone %in% c("CMA", "IMA"), fwveg:="N"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & !is.na(species_cd_1) & zone %in% c("CWH", "MH", "ICH", "BAFA"), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & is.na(species_cd_1) & inventory_standard_cd=="F" & non_productive_cd %between% c(11, 14) & zone %in% c("CWH", "MH", "ICH"), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & is.na(species_cd_1) & inventory_standard_cd=="F" & non_productive_cd %between% c(10, 14), fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & is.na(species_cd_1) & inventory_standard_cd=="F" & non_productive_cd ==35, fwveg:="W"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & is.na(species_cd_1) & inventory_standard_cd=="F" & non_productive_cd ==42, fwveg:="N"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & is.na(species_cd_1) & inventory_standard_cd=="F" & (non_productive_cd == 60 |non_productive_cd == 62 | non_productive_cd == 63), fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & is.na(species_cd_1) & inventory_standard_cd=="F" &  zone %in% c("CMA","IMA"), fwveg:="N"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & is.na(species_cd_1) & inventory_standard_cd=="F" & zone %in% c("CWH","MH", "ICH", "BAFA"), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & is.na(species_cd_1) & inventory_standard_cd=="F" & is.na(non_productive_cd), fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & is.na(species_cd_1) & inventory_standard_cd=="F", fwveg:="N"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & is.na(species_cd_1) & inventory_standard_cd %in% c("V", "I") & land_cover_class_cd_1 %in% c("LA", "RE","RL","OC"), fwveg:="W"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & is.na(species_cd_1) & inventory_standard_cd %in% c("V", "I") & land_cover_class_cd_1=="HG", fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & is.na(species_cd_1) & inventory_standard_cd %in% c("V", "I") & land_cover_class_cd_1 %in% c("BY", "BM","BL"), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & is.na(species_cd_1) & inventory_standard_cd %in% c("V", "I") & (land_cover_class_cd_1 %in% c("SL", "ST","HE","HF") |is.na(land_cover_class_cd_1)) & zone %in% c("CMA", "IMA"), fwveg:="N"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & is.na(species_cd_1) & inventory_standard_cd %in% c("V", "I") & (land_cover_class_cd_1 %in% c("SL", "ST","HE","HF") |is.na(land_cover_class_cd_1)) & zone %in% c("CWH", "MH", "ICH"), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & is.na(species_cd_1) & inventory_standard_cd %in% c("V", "I") & (land_cover_class_cd_1 %in% c("SL", "ST","HE","HF") |is.na(land_cover_class_cd_1)), fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & blockid==0 & is.na(species_cd_1) & inventory_standard_cd %in% c("V", "I") & land_cover_class_cd_1 %in% c("SI", "GL","PN","RO", "BR", "TA", "BI", "MZ", "LB", "EL", "RS", "ES", "LS", "RM", "BE", "LL", "BU", "RZ", "MU", "CB", "MN", "GP", "TZ", "RN", "UR", "AP", "MI", "OT", "LA", "RE", "RI", "OC"), fwveg:="N"]
  
  ##--------------------------------------------##
  ####bclcs_level_1=="V" & bclcs_level_2=="T" ####
  ##--------------------------------------------##
  
  ####Pure lodgepole or jack pine or undefined pine species.#### 
  
  #Also I just included unknown conifer species (XC) here because lodgepole and jack and undefined pines are the most common conifer species.
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & conifer_pct_cover_total>=60 & crownclosure > 40 & earliest_nonlogging_dist_type %in% "burn" & years_since_nonlogging_dist  < 4, fwveg:="N"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & conifer_pct_cover_total>=60 & crownclosure > 40 & earliest_nonlogging_dist_type %in% "burn" & (years_since_nonlogging_dist >= 4 & years_since_nonlogging_dist <= 6), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & conifer_pct_cover_total>=60 & crownclosure > 40 & earliest_nonlogging_dist_type %in% "burn" & (years_since_nonlogging_dist  >= 7 & years_since_nonlogging_dist <= 10), fwveg:= "C-5"]
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P", "XC"), fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & bclcs_level_5=="SP" & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P", "XC"), fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & crownclosure <= 40 & earliest_nonlogging_dist_type %in% "burn" & years_since_nonlogging_dist < 2, fwveg:="N"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & conifer_pct_cover_total>=60 & crownclosure <= 40 & earliest_nonlogging_dist_type %in% "burn" & (years_since_nonlogging_dist  >= 2 & years_since_nonlogging_dist <=6), fwveg:= "D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & conifer_pct_cover_total>=60 & crownclosure <= 40 & earliest_nonlogging_dist_type %in% "burn" & (years_since_nonlogging_dist >= 7 & years_since_nonlogging_dist<= 10), fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & conifer_pct_cover_total<60 &  earliest_nonlogging_dist_type %in% "burn" & years_since_nonlogging_dist  < 2, fwveg:="N"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & conifer_pct_cover_total<60 &  earliest_nonlogging_dist_type %in% "burn" & (years_since_nonlogging_dist >=2 & years_since_nonlogging_dist <= 10), fwveg:="D-1/2"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P", "XC") & blockid>0 & age<=7, fwveg:="S-1"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P", "XC") & bclcs_level_5=="SP" & zone=="ICH" & subzone %in% wet, fwveg:= "D-1/2"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P", "XC") & bclcs_level_5=="SP" & zone %in% c("CWH", "CDF", "MH"), fwveg:="D-1/2"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 &  bclcs_level_5 %in% c("DE", "OP") & height<=4 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P", "XC"), fwveg:="O-1a/b"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & bclcs_level_5 %in% c("DE", "OP") & height %between% c(4, 12) & (vri_live_stems_per_ha+vri_dead_stems_per_ha) > 8000 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P", "XC"), fwveg:="C-4"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & bclcs_level_5 %in% c("DE", "OP") & height %between% c(4,12) & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P", "XC"), fwveg:="C-3"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & bclcs_level_5 %in% c("DE", "OP") & height >12 & crownclosure <40 & zone %in% c("BG", "PP", "IDF", "MS") & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P", "XC"), fwveg:="C-7"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & bclcs_level_5 %in% c("DE", "OP") & height >12 & crownclosure <40 & zone %in% c("CWH", "MH", "ICH") & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P", "XC"), fwveg:="C-5"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & bclcs_level_5 %in% c("DE", "OP") & height >12 & crownclosure <40 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P", "XC"), fwveg:="C-3"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & earliest_nonlogging_dist_type=="IBM" & years_since_nonlogging_dist <=5 & dec_pcnt >50 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P", "XC"), fwveg:="M-3"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & earliest_nonlogging_dist_type=="IBM" & years_since_nonlogging_dist <=5 & dec_pcnt  %between% c(25, 50)  & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P", "XC"), fwveg:="C-2"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & earliest_nonlogging_dist_type=="IBM" & years_since_nonlogging_dist <=5 & dec_pcnt < 25 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P", "XC"), fwveg:="C-3"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & earliest_nonlogging_dist_type=="IBM" & years_since_nonlogging_dist > 5 & dec_pcnt > 50 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P", "XC"), fwveg:="C-2"]
  
  
  #### Pure ponderosa pine ####
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1>= 80 & species_cd_1 == "PY" & bclcs_level_5 %in% c("DE","OP") & blockid>0 & age<=10, fwveg:="S-1"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 == "PY" & bclcs_level_5 %in% c("DE","OP") & height < 4 & fwveg == "none", fwveg:="O-1a/b"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 == "PY" & bclcs_level_5 %in% c("DE","OP") & height %between% c(4, 12) & (vri_live_stems_per_ha+vri_dead_stems_per_ha)>8000 & fwveg == "none", fwveg:="C-4"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 == "PY" & bclcs_level_5 %in% c("DE","OP") & height %between% c(4,12) & (vri_live_stems_per_ha+vri_dead_stems_per_ha) %between% c(3000, 8000) & fwveg == "none", fwveg:="C-3"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 > 79 & species_cd_1 == "PY" & bclcs_level_5 %in% c("DE","OP") & height %between% c(4,12) & ((vri_live_stems_per_ha+vri_dead_stems_per_ha)<3000 | is.na(vri_live_stems_per_ha+vri_dead_stems_per_ha)) & fwveg == "none", fwveg:="C-7"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 == "PY" & height %between% c(12, 17) & fwveg == "none", fwveg:="C-7"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 > 79 & species_cd_1 == "PY" & bclcs_level_5 =="DE" & height %between% c(12, 17) & fwveg == "none", fwveg:="C-3"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 == "PY" & height >17, fwveg:="C-7"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 == "PY" & bclcs_level_5 =="SP", fwveg:="C-7"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 == "PY" & bclcs_level_5 =="SP" & dec_pcnt >=40, fwveg:="O-1a/b"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 == "PY" & bclcs_level_5 =="SP" & blockid>0 & age<=10, fwveg:="S-1"]
   
  
  # PA, PF, PW
  
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("PA", "PF", "PW"), fwveg:="C-5"]
   veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("PA", "PF", "PW") & bclcs_level_5 =="DE", fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("PA", "PF", "PW") & (vri_live_stems_per_ha+vri_dead_stems_per_ha)>=900, fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("PA", "PF", "PW") & (vri_live_stems_per_ha+vri_dead_stems_per_ha) %between% c(600,900), fwveg:="C-7"]
  
  
  #### Pure douglas fir ####
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI")  & blockid>0 & age<=6, fwveg:="S-1"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI")  & blockid>0 & age<=6 & zone %in% c("CWH", "MH", "CDF"), fwveg:="S-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI")  & blockid>0 & age<=6 & zone=="ICH" & subzone %in% wet, fwveg:="S-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI") & height < 4 & (blockid==0 | (blockid>0 & age>6)), fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI") & zone %in% c("CWH", "MH", "CDF") & height < 4 & (blockid==0 | (blockid>0 & age>6)), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI") & zone =="ICH" & subzone %in% wet & height < 4 & (blockid==0 | (blockid>0 & age>6)), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 > 79 & dominant_conifer %in% c("F","FD","FDC","FDI") & zone %in% c("CWH", "MH", "CDF") & height %between% c(4, 12) & (blockid==0 | (blockid>0 & age>6)) & crownclosure >= 55, fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI") & zone =="ICH" & subzone %in% wet & height %between% c(4, 12) & crownclosure > 55  & (blockid==0 | (blockid>0 & age>6)), fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI") & height %between% c(4,12) & crownclosure > 55 & dec_pcnt > 34  & (blockid==0 | (blockid>0 & age>6)), fwveg:="C-4"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI") & height %between% c(4,12) & crownclosure > 55  & (blockid==0 | (blockid>0 & age>6)), fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI") & crownclosure<26, fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI") & height>12 & crownclosure > 55, fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI") & zone %in% c("CWH", "MH", "CDF") & height>12 & crownclosure > 55, fwveg:="C-5"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI") & zone=="ICH" & subzone %in% wet & crownclosure > 55 & height>12, fwveg:="C-5"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI") & zone %in% c("CWH", "MH", "CDF") & crownclosure %between% c(26,55), fwveg:="C-5"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI") & zone=="ICH" & subzone %in% wet & crownclosure %between% c(26, 55), fwveg:="C-5"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI") & crownclosure %between% c(26, 55), fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI") & zone %in% c("CWH", "MH", "CDF") & crownclosure<26, fwveg:= "D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("F","FD","FDC","FDI") & zone =="ICH" & subzone %in% wet & crownclosure<26, fwveg:="D-1/2"]
  
  
  # Pure spruce 
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 == "SE", fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 == "SE" & bclcs_level_5=="SP", fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 == "SE" & bclcs_level_5=="DE", fwveg:="C-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 == "SE" & blockid>0 & age<=10, fwveg:="S-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" &  species_pct_1> 79 & species_cd_1 == "SS" & bclcs_level_5=="SP", fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 == "SS" & bclcs_level_5 %in% c("DE","OP"), fwveg:="C-5"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 == "SS"  & blockid>0 & age<=6, fwveg:="S-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("SB", "SW"), fwveg:="M-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("SB", "SW")  & blockid>0 & age<=10, fwveg:="S-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1  %in% c("SB", "SW") & bclcs_level_5 %in% c("DE","OP"), fwveg:="C-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("SB", "SW") & zone %in% c("BWBS", "SWB"), fwveg:="C-1"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("S","SX","SXW","SXL","SXS")  & height < 4, fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("S","SX","SXW","SXL","SXS")  & height >= 4 & bclcs_level_5 == "OP", fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("S","SX","SXW","SXL","SXS") & height >= 4, fwveg:="C-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("S","SX","SXW","SXL","SXS")  & blockid>0 & age<=7, fwveg:="S-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("S","SX","SXW","SXL","SXS")  &  zone %in% c("BWBS", "SWB") & bclcs_level_5 %in% c("DE", "OP"), fwveg:="C-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("S","SX","SXW","SXL","SXS")  &  zone %in% c("BWBS", "SWB"), fwveg:="C-1"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("S","SX","SXW","SXL","SXS")  &  !(zone %in% c("BWBS", "SWB")) & bclcs_level_5 =="SP", fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("S","SX","SXW","SXL","SXS")  &  zone %in% c("CWH", "CDF"), fwveg:="C-5"]
  

  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("H","HM", "HW", "C","CW", "Y", "YC"),fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("H","HM", "HW", "C","CW", "Y", "YC")  & bclcs_level_5 %in% c("OP","DE"), fwveg:="C-5"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("H","HM", "HW", "C","CW", "Y", "YC")  & bclcs_level_5=="DE" & age < 60, fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("H","HM", "HW", "C","CW", "Y", "YC")  & bclcs_level_5=="DE" & age %between% c(60, 99), fwveg:="M-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("H","HM", "HW", "C","CW", "Y", "YC")  & bclcs_level_5=="DE" & height < 4, fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("H","HM", "HW", "C","CW", "Y", "YC")  & bclcs_level_5=="DE" & height %between% c(4, 15), fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("H","HM", "HW", "C","CW", "Y", "YC")  & blockid>0 & age<=6, fwveg:="S-3"]
  
  # True fir
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 == "BG", fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 == "BA", fwveg:="M-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("B", "BB", "BL"), fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("B", "BB", "BL")  & bclcs_level_5=="SP", fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in%  c("T","TW"), fwveg:="C-5"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("J","JR","JS"), fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% deciduous, fwveg:="D-1/2"]
  
  
  #### Mixed species stand ####
 
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 <80 & conifer_pct_cover_total<=20, fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1<80 & conifer_pct_cover_total %between% c(21, 40), fwveg:="M-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1<80 & blockid>0 & age<=6 & conifer_pct_cover_total %between% c(21, 80), fwveg:="S-1"]
  
  # note for below I made the assumption that  on pg 39 of Perrakis et al. (2018) there were refering to the dominant conifer species  when they listed specific species. That is why only the first occurrence of a conifer gets the specific species  
  
  ## conifer cover 41 - 65%
 veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1<80 & dominant_conifer %in% c("T","TW") & conifer_pct_cover_total %between% c(41, 65), fwveg:="C-5"]
 veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1<80 & (conifer_pct_cover_total > 40 & conifer_pct_cover_total<66) & dominant_conifer %in% c("J","JR","JS"), fwveg:="O-1a/b"]
 veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1<80 & (conifer_pct_cover_total > 40 & conifer_pct_cover_total<66) & dominant_conifer %in% c("P","PJ","PF","PL","PLI","PY","PLC","PW","PA","F","FD","FDC","FDI","SE","S","SB","SS","SW","SX","SXW","SXL","SXS","C","CW","Y","YC","H","HM","HW","HXM","B","BB","BA","BG","BL"), fwveg:="M-1/2"] # removed PXJ & PR 
  
  
  ## conifer cover 65-80% 
 veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1<80 & conifer_pct_cover_total %between% c(66, 80), fwveg:="M-1/2"] 
 veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1<80 & conifer_pct_cover_total %between% c(66, 80) & dominant_conifer %in% c("PL", "PLI", "PLC", "PJ", "P"), fwveg:="M-1/2"]
veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1<80 & conifer_pct_cover_total %between% c(66, 80) & dominant_conifer =="PY", fwveg:="C-7"]
veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1<80 & conifer_pct_cover_total %between% c(66, 80) & dominant_conifer %in% c("PA", "PF", "PW"), fwveg:="C-5"]
veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1<80 & conifer_pct_cover_total %between% c(66, 80) & dominant_conifer %in% c("F","FD","FDC"), fwveg:="C-7"]
veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1<80 & zone %in% c("CWH", "CDF") & conifer_pct_cover_total %between% c(66, 80) & dominant_conifer %in% c("F","FD","FDC"), fwveg:="C-5"]
veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1<80 & zone %in% c("ICH") & subzone %in% wet & conifer_pct_cover_total %between% c(66, 80) & dominant_conifer %in% c("F","FD","FDC"), fwveg:="C-5"]
veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1<80 & bclcs_level_5=="DE" & conifer_pct_cover_total %between% c(66, 80) & dominant_conifer %in% c("F","FD","FDC"), fwveg:="M-1/2"]
veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1<80 & conifer_pct_cover_total %between% c(66, 80) & dominant_conifer %in% c("SS"), fwveg:="C-5"]
veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total %between% c(66, 80) & dominant_conifer %in% c("SE","S","SB","SS","SW","SX","SXW","SXL","SXS"), fwveg:="M-1/2"]
veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1<80 & conifer_pct_cover_total %between% c(66, 80) & dominant_conifer %in% c("C","CW","Y","YC","H","HM","HW","HXM","T","TW"), fwveg:="C-5"]
veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1<80 & conifer_pct_cover_total %between% c(66, 80) & dominant_conifer %in% c("B","BB","BA","BG","BL","J","JR","JS"), fwveg:="C-7"]

  ## conifer cover 81-100 %            

  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & bclcs_level_5 == "SP" & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P"), fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & bclcs_level_5 == "SP" & zone %in% c("CWH", "CDF", "MH"), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & bclcs_level_5 == "SP" & zone %in% c("ICH") & subzone %in% wet, fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & bclcs_level_5 %in% c("DE", "OP") & height<4, fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & blockid>0 & age<=7, fwveg:="S-1"]
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & species_cd_2 %in% c("B","BB","BA","BG","BL","SE","S","SB","SS","SW","SX","SXW","SXL","SXS")  & height %between% c(4, 12) & (vri_live_stems_per_ha+vri_dead_stems_per_ha)>8000, fwveg:="C-4"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & species_cd_2 %in% c("B","BB","BA","BG","BL","SE","S","SB","SS","SW","SX","SXW","SXL","SXS") & height %between% c(4, 12), fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & species_cd_2 %in% c("B","BB","BA","BG","BL","SE","S","SB","SS","SW","SX","SXW","SXL","SXS")  & height > 12, fwveg:= "C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & species_cd_2 %in% c("B","BB","BA","BG","BL","SE","S","SB","SS","SW","SX","SXW","SXL","SXS") & height > 12 & crownclosure<40, fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & species_cd_2 %in% c("B","BB","BA","BG","BL","SE","S","SB","SS","SW","SX","SXW","SXL","SXS") & height > 12 & crownclosure<40 & zone %in% c("BG", "PP", "IDF", "MS"), fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & species_cd_2 %in% c("B","BB","BA","BG","BL","SE","S","SB","SS","SW","SX","SXW","SXL","SXS") & height > 12 & crownclosure<40 & zone %in% c("CWH", "MH", "ICH"), fwveg:="C-5"]

  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & species_cd_2 %in% c("B","BB","BA","BG","BL","SE","S","SB","SS","SW","SX","SXW","SXL","SXS")  & height > 12 & earliest_nonlogging_dist_type=="IBM" & years_since_nonlogging_dist<=5 &  dec_pcnt < 25, fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & species_cd_2 %in% c("B","BB","BA","BG","BL","SE","S","SB","SS","SW","SX","SXW","SXL","SXS") & bclcs_level_5=="DE" & height > 12 & earliest_nonlogging_dist_type=="IBM" & years_since_nonlogging_dist<=5 &  dec_pcnt < 25, fwveg:="C-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & species_cd_2 %in% c("B","BB","BA","BG","BL","SE","S","SB","SS","SW","SX","SXW","SXL","SXS") & height > 12 & earliest_nonlogging_dist_type=="IBM" & years_since_nonlogging_dist<=5 &  dec_pcnt > 50, fwveg:="M-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & species_cd_2 %in% c("B","BB","BA","BG","BL","SE","S","SB","SS","SW","SX","SXW","SXL","SXS") & height > 12 & earliest_nonlogging_dist_type=="IBM" & years_since_nonlogging_dist<=5 &  dec_pcnt %between% c(25, 50), fwveg:="C-2"]
  
  # years since IBM attack > 5
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & species_cd_2 %in% c("B","BB","BA","BG","BL","SE","S","SB","SS","SW","SX","SXW","SXL","SXS")  & height > 12 & earliest_nonlogging_dist_type=="IBM" & years_since_nonlogging_dist > 5 &  dec_pcnt >50, fwveg:= "C-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & species_cd_2 %in% c("B","BB","BA","BG","BL","SE","S","SB","SS","SW","SX","SXW","SXL","SXS")  & height > 12 & earliest_nonlogging_dist_type=="IBM" & years_since_nonlogging_dist > 5 &  dec_pcnt >= 25 & dec_pcnt <= 50  & bclcs_level_5 == "DE", fwveg:= "C-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & species_cd_2 %in% c("B","BB","BA","BG","BL","SE","S","SB","SS","SW","SX","SXW","SXL","SXS")  & height > 12 & earliest_nonlogging_dist_type=="IBM" & years_since_nonlogging_dist > 5 &  dec_pcnt >= 25 & dec_pcnt <= 50, fwveg:= "C-3"]

  # no IBM
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & !(species_cd_2 %in% c("B","BB","BA","BG","BL","SE","S","SB","SS","SW","SX","SXW","SXL","SXS")), fwveg:= "C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P")  & !(species_cd_2 %in% c("B","BB","BA","BG","BL","SE","S","SB","SS","SW","SX","SXW","SXL","SXS")) & crownclosure <40 & zone %in% c("IDF", "PP", "BG", "SBPW", "MS"), fwveg:= "C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P") & !(species_cd_2 %in% c("B","BB","BA","BG","BL","SE","S","SB","SS","SW","SX","SXW","SXL","SXS")) & crownclosure <40 & zone %in% c("CWH", "CDF", "ICH"), fwveg:= "C-5"]
  
# sp. 1 py
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 =="PY" & blockid>0 & age<=7, fwveg:= "S-1"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 =="PY" & ((blockid > 0 & age>7) | blockid==0) & height < 4, fwveg:= "O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 =="PY" & bclcs_level_5=="DE" & height>=4, fwveg:= "C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 =="PY"  & height>=4 & ((blockid>0 & age>7) | blockid==0) & bclcs_level_5 !="DE", fwveg:= "C-7"]
  
  # Pa, Pf, Pw
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PA", "PF", "PW"), fwveg:= "C-5"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PA", "PF", "PW") & bclcs_level_5=="DE", fwveg:= "C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PA", "PF", "PW") & (vri_live_stems_per_ha+vri_dead_stems_per_ha)>=900, fwveg:= "C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 80 & species_cd_1 %in% c("PA", "PF", "PW") & (vri_live_stems_per_ha+vri_dead_stems_per_ha) %between% c(600, 900), fwveg:= "C-7"]
 

  #sp. 1 Fd or any F 
 
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI") & blockid>0 & age<=6, fwveg:= "S-1"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total >20 & species_cd_1 %in% c("F","FD","FDC","FDI") & blockid>0 & age<=6 & zone %in% c("CWH", "MH","CDF"), fwveg:= "S-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI") & blockid>0 & age<=6 & zone %in% c("ICH") & subzone %in% wet, fwveg:= "S-3"]

  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI") & height < 4, fwveg:= "O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI") & height < 4 & zone %in% c("CWH", "MH", "CDF"), fwveg:= "D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI") & height < 4 & zone %in% c("ICH") & subzone %in% wet, fwveg:= "D-1/2"]

  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI") & height %between% c(4, 12) & crownclosure>55 & zone %in% c("CWH", "MH", "CDF"), fwveg:= "C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI") & height %between% c(4, 12) & crownclosure>55 & zone %in% c("ICH") & subzone %in% wet, fwveg:= "C-3"]
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI") & height %between% c(4, 12) & crownclosure>55, fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI") & species_cd_2=="PY" & height %between% c(4, 12) & crownclosure>55, fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI") & height %between% c(4, 12) & crownclosure>55 & dec_pcnt >34, fwveg:="C-4"]
  
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI")  & height >12 & crownclosure>55, fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI")  & height >12 & crownclosure>55 & zone %in% c("CWH", "MH", "CDF"), fwveg:="C-5"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI")  & height >12 & crownclosure>55 & zone %in% c("ICH") & subzone %in% wet, fwveg:= "C-5"]
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI")  & (crownclosure %between% c(26, 55) | is.na(crownclosure)), fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI")  & (crownclosure %between% c(26, 55) | is.na(crownclosure)) & zone %in% c("CWH", "MH", "CDF"), fwveg:="C-5"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI")  & (crownclosure %between% c(26, 55) | is.na(crownclosure)) & zone %in% c("ICH") & subzone %in% wet, fwveg:="C-5"]
  
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI")  & crownclosure < 26, fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI")  & crownclosure < 26 & zone %in% c("CWH", "MH", "CDF"), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("F","FD","FDC","FDI")  & crownclosure < 26 & zone %in% c("ICH") & subzone %in% wet, fwveg:="D-1/2"]
  
  
  #Sp1 S(any) 

  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 == "SE" & (blockid>0 & age>6 | blockid == 0), fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 == "SE" & bclcs_level_5=="SP" & (blockid>0 & age>6 | blockid == 0), fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 == "SE" & species_cd_2 %in% c("BL", "B", "PL", "P", "PLI") & bclcs_level_5=="DE" & (blockid>0 & age>6 | blockid == 0), fwveg:="C-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 == "SE" & species_cd_2 %in% c("BL", "B", "PL", "P", "PLI") & (blockid>0 & age>6 | blockid == 0), fwveg:= "C-3"]
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 == "SE" & (blockid>0 & age>6 | blockid == 0), fwveg:= "C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 == "SE" & species_cd_2 %in% c("HW", "HM", "CW", "YC") & (blockid>0 & age>6 | blockid == 0), fwveg:="C-5"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 == "SE" & species_cd_2 %in% c("HW", "HM", "CW", "YC") & bclcs_level_5=="DE" & (blockid>0 & age>6 | blockid == 0), fwveg:="C-3"]
  
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 == "SS" & (blockid>0 & age>6 | blockid == 0), fwveg:="C-5"]
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 == "SB" & (blockid>0 & age>6 | blockid == 0), fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 == "SB" & zone=="BWBS" & (blockid>0 & age>6 | blockid == 0), fwveg:="C-1"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 == "SB" & bclcs_level_5 %in% c("DE","OP") & (blockid>0 & age>6 | blockid == 0), fwveg:= "C-2"]
  
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("S","SW","SX","SXW","SXL","SXS") & zone=="BWBS", fwveg:= "C-1"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("S","SW","SX","SXW","SXL","SXS") & bclcs_level_5 == "OP" & zone=="BWBS", fwveg:= "C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("S","SW","SX","SXW","SXL","SXS") & bclcs_level_5 == "DE" & zone=="BWBS", fwveg:= "C-2"]
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("S","SW","SX","SXW","SXL","SXS") & zone %in% c("CWH","MH","CDF") & species_cd_2 %in% c("BL", "B", "P","PJ","PF","PL","PR","PLI","PXJ","PY","PLC","PW","PA"), fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("S","SW","SX","SXW","SXL","SXS") & zone %in% c("CWH","MH","CDF") & species_cd_2 %in% c("BL", "B", "P","PJ","PF","PL","PR","PLI","PXJ","PY","PLC","PW","PA") & bclcs_level_5=="SP", fwveg:="C-7"]
  
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("S","SW","SX","SXW","SXL","SXS") & zone %in% c("CWH","MH","CDF"), fwveg:= "C-5"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("S","SW","SX","SXW","SXL","SXS") & coast_interior_cd=="I" & bclcs_level_5=="SP", fwveg:= "C-7"]
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("S","SW","SX","SXW","SXL","SXS") & coast_interior_cd=="I" & bclcs_level_5=="DE" & !(zone %in% c("CWH","MH","CDF", "BWBS")) & (blockid>0 & age>6 | blockid == 0), fwveg:= "C-2"]
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("S","SW","SX","SXW","SXL","SXS") & coast_interior_cd=="I" & dec_pcnt>34 & !(zone %in% c("CWH","MH","CDF", "BWBS")), fwveg:= "C-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("S","SW","SX","SXW","SXL","SXS") & coast_interior_cd=="I" & species_cd_2 %in% c("PL","PLI","P"), fwveg:= "C-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & (dec_pcnt<=34 | is.na(dec_pcnt)) & species_cd_1 %in% c("S","SW","SX","SXW","SXL","SXS") & !(species_cd_2 %in% c("PL","PLI","P")), fwveg:= "C-3"]
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("S","SB","SE","SS","SW","SX","SXW","SXL","SXS") & blockid>0 & age<=6, fwveg:= "S-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("S","SB","SE","SS","SW","SX","SXW","SXL","SXS") & blockid>0 & age<=6 & zone %in% c("CWH", "MH","CDF"), fwveg:="S-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("S","SB","SE","SS","SW","SX","SXW","SXL","SXS") & blockid>0 & age<=6 & zone %in% c("ICH") & subzone %in% wet, fwveg:="S-3"]
  
  
  #H(any), C(any), Y(any) 

  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("C","CW","Y","YC","H","HM","HW","HXM"), fwveg:="C-5"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("C","CW","Y","YC","H","HM","HW","HXM") & bclcs_level_5=="DE" & age<60 & height > 15, fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("C","CW","Y","YC","H","HM","HW","HXM") & bclcs_level_5=="DE" & age %between% c(60,99) & height > 15, fwveg:="M-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("C","CW","Y","YC","H","HM","HW","HXM") & !(bclcs_level_5 %in% c("DE", "OP")), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("C","CW","Y","YC","H","HM","HW","HXM") & bclcs_level_5=="DE" & height<4, fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("C","CW","Y","YC","H","HM","HW","HXM") & bclcs_level_5=="DE" & height %between% c(4, 15), fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("C","CW","Y","YC","H","HM","HW","HXM") & blockid>0 & age<=6, fwveg:="S-3"]
       
  # BG, BA, B etc also T and J 
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1=="BG", fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1=="BA", fwveg:="M-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1=="BA" & species_cd_2 %in% c("SE", "SW", "S"), fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("B","BB","BL") & coast_interior_cd=="C", fwveg:="M-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("B","BB","BL") & bclcs_level_5=="SP" & coast_interior_cd!="C", fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("B","BB","BL") & coast_interior_cd !="C"& bclcs_level_5=="DE" & species_cd_2 %in% c("SE", "SW", "S"), fwveg:="C-2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("B","BB","BL") & !(species_cd_2 %in% c("SE", "SW", "S")) & coast_interior_cd !="C" & bclcs_level_5 != "SP", fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("T","TW"), fwveg:="C-5"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1 < 80 & conifer_pct_cover_total > 20 & species_cd_1 %in% c("J","JR","JS"), fwveg:="C-7"]
  
  veg2[bclcs_level_5 %in% c("GL","LA"), fwveg := "W"]
  veg2[bclcs_level_2=="W", fwveg:="W"]
  
 # veg2[, c("crownclosure", "age", "vol", "height", "dec_pcnt", "blockid", "years_since_nonlogging_dist"):=NULL]
  
  sim$veg3<-veg2[,c("pixelid", "fwveg")]
  
  rm(veg2)
  gc()
  

  #### uploading fueltype layer  ####
  
 # message("updating fueltype table with fwveg data") 
  
  # for some reason updating the fueltype table takes for ever. So Ill drop the fueltype table and add it back. That's faster. Chat to Kyle about this later to find better solution.
  
#  dbExecute(sim$castordb, "DROP TABLE fueltype")
  
#  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS fueltype (pixelid integer, bclcs_level_1 character, bclcs_level_2 character, bclcs_level_3 character,  bclcs_level_5 character, inventory_standard_cd character, non_productive_cd character, coast_interior_cd character,  land_cover_class_cd_1 character, zone character, subzone character, earliest_nonlogging_dist_type character, earliest_nonlogging_dist_date integer, vri_live_stems_per_ha numeric, vri_dead_stems_per_ha numeric, species_cd_1 character, species_pct_1 numeric, species_cd_2 character, species_pct_2 numeric, dominant_conifer character, conifer_pct_cover_total numeric, fwveg character)")
  
#  qry<-paste0('INSERT INTO fueltype (pixelid, bclcs_level_1, bclcs_level_2, bclcs_level_3, bclcs_level_5, inventory_standard_cd, non_productive_cd, coast_interior_cd, land_cover_class_cd_1,  earliest_nonlogging_dist_type, vri_live_stems_per_ha, vri_dead_stems_per_ha, species_cd_1, species_pct_1, species_cd_2, species_pct_2, zone, subzone,earliest_nonlogging_dist_date, dominant_conifer, conifer_pct_cover_total, fwveg) values (:pixelid, :bclcs_level_1, :bclcs_level_2, :bclcs_level_3, :bclcs_level_5, :inventory_standard_cd, :non_productive_cd, :coast_interior_cd, :land_cover_class_cd_1, :earliest_nonlogging_dist_type, :vri_live_stems_per_ha, :vri_dead_stems_per_ha, :species_cd_1, :species_pct_1, :species_cd_2, :species_pct_2,:zone, :subzone, :earliest_nonlogging_dist_date, :dominant_conifer, :conifer_pct_cover_total, :fwveg)')
  
  #fueltype table
  # dbBegin(sim$castordb)
  # rs<-dbSendQuery(sim$castordb, qry, veg2)
  # dbClearResult(rs)
  # dbCommit(sim$castordb)
  # 
  # dbExecute(sim$castordb, "CREATE INDEX index_pixelid on fueltype (pixelid)")
  
  
  #older code
  #  if(dbGetQuery (sim$castordb, "SELECT COUNT(*) as exists_check FROM pragma_table_info('fueltype') WHERE name='fwveg';")$exists_check == 0){
  # #   # add in the column
  #  dbExecute (sim$castordb, "ALTER TABLE fueltype ADD COLUMN fwveg character DEFAULT none") }
  # 
 #    dbExecute(sim$castordb, "CREATE INDEX index_pixelid on fueltype (pixelid)")
  #    
  #  dbBegin(sim$castordb)
  #  rs<-dbSendQuery(sim$castordb, "UPDATE fueltype SET fwveg = :fwveg WHERE pixelid = :pixelid", veg2[, c("pixelid", "fwveg")])
  #  dbClearResult(rs)
  #  dbCommit(sim$castordb)
  # } else {
  #   dbBegin(sim$castordb)
  #   rs<-dbSendQuery(sim$castordb, "UPDATE fueltype SET fwveg = :fwveg WHERE pixelid = :pixelid", veg3)
  #   dbClearResult(rs)
  #   dbCommit(sim$castordb)
  #   
  # }
  # 

  return(invisible(sim)) 
  
}

calcProbFire<-function(sim){
  
  
 # fwveg<-dbGetQuery(sim$castordb, "SELECT pixelid, fwveg from fueltype")
  
  
  qry<-paste0("SELECT * from climate_", time(sim)*sim$updateInterval + P(sim, "simStartYear", "fireCastor"),"_",P(sim, "gcmName", "fireCastor"),"_",P(sim, "ssp", "fireCastor"))
  
  climate_variables<-dbGetQuery(sim$castordb, qry)
  
  dat<-merge(sim$veg3, climate_variables, by.x="pixelid", by.y="pixelid", all.x=TRUE)
  dat<-merge(dat, sim$road_distance, by.x="pixelid", by.y="pixelid", all.x=TRUE)
  #dat<-merge(dat, sim$elev, by.x="pixelid", by.y="pixelid", all.x=TRUE)
  
  dat<-merge(dat,sim$fire_static, all.x=TRUE)
  
  message("get coefficient table")
  
  #if (!suppliedElsewhere(sim$coefficients)) {
  sim$coefficients<-as.data.table(getTableQuery(paste0("SELECT * FROM " ,P(sim, "firemodelcoeftbl","fireCastor"), ";")))
 # } else { print("coefficient table already loaded")}
  
  # create dummy variables for fwveg
  dat$veg_C1 <- ifelse(dat$fwveg == 'C-1', 1, 0)
  dat$veg_C2 <- ifelse(dat$fwveg == 'C-2', 1, 0)
  dat$veg_C3 <- ifelse(dat$fwveg == 'C-3', 1, 0)
  dat$veg_C4 <- ifelse(dat$fwveg == 'C-4', 1, 0)
  dat$veg_C5 <- ifelse(dat$fwveg == 'C-5', 1, 0)
  dat$veg_C7 <- ifelse(dat$fwveg == 'C-7', 1, 0)
  dat$veg_D12 <- ifelse(dat$fwveg == 'D-1/2', 1, 0)
  dat$veg_M12 <- ifelse(dat$fwveg == 'M-1/2', 1, 0)
  dat$veg_M3 <- ifelse(dat$fwveg == 'M-3', 1, 0)
  dat$veg_N <- ifelse(dat$fwveg == 'N', 1, 0)
  dat$veg_O1ab <- ifelse(dat$fwveg == 'O-1a/b', 1, 0)
  dat$veg_S1 <- ifelse(dat$fwveg == 'S-1', 1, 0)
  dat$veg_S2 <- ifelse(dat$fwveg == 'S-2', 1, 0)
  dat$veg_S3 <- ifelse(dat$fwveg == 'S-3', 1, 0)
  dat$veg_W <- ifelse(dat$fwveg == 'W', 1, 0)
  
  dat<-as.data.table(dat)
  
  
  # there aer values in climate that are null values e.g. -9999
  
  dat[climate1lightning==-9999, climate1lightning:=NA]
  dat[climate2lightning==-9999, climate2lightning:=NA]
  dat[climate1person ==-9999, climate1person:=NA]
  dat[climate2person ==-9999, climate2person:=NA]
  dat[climate1escape ==-9999, climate1escape:=NA]
  dat[climate2escape ==-9999, climate2escape:=NA]
  dat[climate1spread ==-9999, climate1spread :=NA]
  dat[climate2spread ==-9999, climate2spread :=NA]
  
  #---------#
  #### FRT 5  ####
  #---------#
  if (nrow(dat[frt==5,])>0) {
  frt5<- dat[frt==5, ]
  head(frt5)
  
  #NOTE C-2 is the intercept
  frt5[fwveg == "C-5", veg_C7 :=1]
  frt5[fwveg == "C-4", veg_C2 :=1]
  frt5[fwveg == "S-1", veg_M12 :=1]
  frt5[fwveg == "S-2", veg_C7 :=1]
  
  # put coefficients into model formula
  #logit(p) = b0+b1X1+b2X2+b3X3….+bkXk
  frt5[, logit_P_lightning := ignitstaticlightning * all + 
         sim$coefficients[cause == "Lightning" & frt==5,]$coef_climate_2 * climate2lightning + 
         sim$coefficients[cause == "Lightning" & frt==5,]$coef_c1 * veg_C1 +
         sim$coefficients[cause == "Lightning" & frt==5,]$coef_c3 * veg_C3 +
         sim$coefficients[cause == "Lightning" & frt==5,]$coef_c7 * veg_C7 +
         sim$coefficients[cause == "Lightning" & frt==5,]$coef_d12 * veg_D12 +
         sim$coefficients[cause == "Lightning" & frt==5,]$coef_m12 * veg_M12 +
         sim$coefficients[cause == "Lightning" & frt==5,]$coef_o1ab * veg_O1ab]
  
  head(frt5)
  # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
  frt5[, prob_ignition_lightning := exp(logit_P_lightning)/(1+exp(logit_P_lightnin))]
  
  # PErson ignitions
  #model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT5_person.csv")
  frt5[, logit_P_human := ignitstatichuman  * all + 
         sim$coefficients[cause == 'person' & frt == "5", ]$coef_climate_1 * climate1person + 
         sim$coefficients[cause == 'person' & frt==5,]$coef_log_road_dist  * log(rds_dist+1)]
       
  frt5[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
       
  # Fire Escape
 # model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt5_escape.csv")
  
  # reset the veg categories
  frt5[, veg_C7 := 0]
  frt5[fwveg == "C-7", veg_C7 := 1]
  frt5[, veg_C2 := 0]
  frt5[fwveg == "C-2", veg_C2 := 1]
  frt5[, veg_M12 := 0]
  frt5[fwveg == "M-1/2", veg_M12 := 1]
  
  # change veg categories to ones that we have coefficients
  frt5[fwveg == "C-5", veg_D12 := 1]
  frt5[fwveg == "C-4", veg_C2 := 1]
  frt5[fwveg == "C-7", veg_D12 := 1]
  frt5[fwveg == "S-1", veg_M12 := 1]
  frt5[fwveg == "S-2", veg_M12 := 1]
  
  
  frt5[, logit_P_escape := escapestatic * all + 
         sim$coefficients[cause == 'escape' & frt==5,]$coef_climate_1 * climate1escape +
         sim$coefficients[cause == 'escape' & frt==5,]$coef_c2 * veg_C2 +
         sim$coefficients[cause == 'escape' & frt==5,]$coef_c3 * veg_C3 +
         sim$coefficients[cause == 'escape' & frt==5,]$coef_d12 * veg_D12 +
         sim$coefficients[cause == 'escape' & frt==5,]$coef_m12 * veg_M12 +
         sim$coefficients[cause == 'escape' & frt==5,]$coef_N * veg_N +
         sim$coefficients[cause == 'escape' & frt==5,]$coef_o1ab * veg_O1ab]
       
  frt5[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]

  # Spread
#  model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt5_spread.csv")
  
  # reset the veg categories
  frt5[, veg_D12 := 0]
  frt5[fwveg == "D-1/2", veg_D12 := 1]
  frt5[, veg_C2 := 0]
  frt5[fwveg == "C-2", veg_C2 := 1]
  frt5[, veg_M12 := 0]
  frt5[fwveg == "M-1/2", veg_M12 := 1]
  
  # change veg categories to ones that we have coefficients
  frt5[fwveg == "C-4", veg_C2 := 1]
  frt5[fwveg == "S-1", veg_M12 := 1]
  
  frt5[, logit_P_spread := spreadstatic * all + 
         sim$coefficients[cause == 'spread' & frt==5,]$coef_climate_2 * climate2spread+
         sim$coefficients[cause == 'spread' & frt==5,]$coef_c2 * veg_C2 +
         sim$coefficients[cause == 'spread' & frt==5,]$coef_c3 * veg_C3 +
         sim$coefficients[cause == 'spread' & frt==5,]$coef_c5 * veg_C5 +
         sim$coefficients[cause == 'spread' & frt==5,]$coef_c7 * veg_C7 +
         sim$coefficients[cause == 'spread' & frt==5,]$coef_d12 * veg_D12 +
         sim$coefficients[cause == 'spread' & frt==5,]$coef_m12 * veg_M12 +
         sim$coefficients[cause == 'spread' & frt==5,]$coef_m3 * veg_M3 +
         sim$coefficients[cause == 'spread' & frt==5,]$coef_N * veg_N +
         sim$coefficients[cause == 'spread' & frt==5,]$coef_o1ab * veg_O1ab +
         sim$coefficients[cause == 'spread' & frt==5,]$coef_s2 * veg_S2 +
         sim$coefficients[cause == 'spread' & frt==5,]$coef_road_dist * rds_dist]
  
  frt5[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
  
  
  # currently I weight the total probability of ignition by the frequency of each cause.But I calculated this once and assume its static. Probably I should actually calculate this once during the simulation for my AOI and then assume it does not change over time. Or I should use that equation that weights them equally since we dont know whats going to happen inthe future.
  
  frt5[, prob_tot_ignit := prob_ignition_lightning*0.84 + prob_ignition_person*0.16]
  
  frt5[veg_W==1,prog_tot_ignit:=0]
  frt5[veg_W==1,prob_ignition_lightning:=0]
  frt5[veg_W==1,prob_ignition_person:=0]
  frt5[veg_W==1,prob_ignition_escape:=0]
  frt5[veg_W==1,prob_ignition_spread:=0]
  
  
  frt5<-frt5[, c("pixelid","frt", "prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]
  
  } else {
    
    print("no data for FRT 5")
    
    frt5<-data.table(pixelid=as.numeric(),
                     frt = as.numeric(),
                     prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(),
                     prob_ignition_escape = as.integer(),
                     prob_ignition_spread = as.integer(),
                     prob_tot_ignit = as.integer())
  }
  
  #### FRT7 #### 
  if (nrow(dat[frt==7,])>0) {
  frt7<- dat[frt==7,]
  
  #NOTE C-2 is the intercept
  frt7[fwveg == "C-4", veg_C2 :=1]
  frt7[fwveg == "C-7", veg_M12:=1]
  frt7[fwveg == "C-5", veg_M12:=1]
  frt7[fwveg == "S-1", veg_M12:=1]
  frt7[fwveg == "S-2", veg_M12:=1]
  
  frt7[pixelid>0, all:=1]
  
  #model_coef_table_lightning<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt7_lightning.csv")
  
  frt7[, logit_P_lightning := ignitstaticlightning * all + 
    sim$coefficients[cause=="Lightning" & frt==7,]$coef_climate_1 * climate1lightning + 
    sim$coefficients[cause=="Lightning" & frt==7,]$coef_c1 * veg_C1 +
    sim$coefficients[cause=="Lightning" & frt==7,]$coef_c3 * veg_C3 +
    sim$coefficients[cause=="Lightning" & frt==7,]$coef_d12 * veg_D12 +
    sim$coefficients[cause=="Lightning" & frt==7,]$coef_m12 * veg_M12 +
    sim$coefficients[cause=="Lightning" & frt==7,]$coef_o1ab * veg_O1ab]

  # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
  frt7[, prob_ignition_lightning:=exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
  
  # Person caused fires
 # model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT7_person.csv")
  
  frt7[, veg_M12 := 0]
  frt7[fwveg == "M-1/2", veg_M12 := 1]
  frt7[, veg_C2 := 0]
  frt7[fwveg == "C-2", veg_C2 := 1]
  
  frt7[fwveg == "C-4", veg_C2 :=1]
  frt7[fwveg == "C-5", veg_C7:=1]
  frt7[fwveg == "S-1", veg_M12:=1]
  frt7[fwveg == "S-2", veg_M12:=1]

  frt7[, logit_P_human := ignitstatichuman  * all + 
      sim$coefficients[cause == 'person' & frt == 7, ]$coef_climate_1 * climate1person + 
      sim$coefficients[cause == 'person' & frt==7,]$coef_c2*veg_C2 +
      sim$coefficients[cause == 'person' & frt==7,]$coef_c3*veg_C3 +
      sim$coefficients[cause == 'person' & frt==7,]$coef_c7*veg_C7 +
      sim$coefficients[cause == 'person' & frt==7,]$coef_d12*veg_D12 +
      sim$coefficients[cause == 'person' & frt==7,]$coef_m12*veg_M12 +
      sim$coefficients[cause == 'person' & frt==7,]$coef_m3*veg_M3 +
      sim$coefficients[cause == 'person' & frt==7,]$coef_N*veg_N +
      sim$coefficients[cause == 'person' & frt==7,]$coef_o1ab*veg_O1ab +
      sim$coefficients[cause == 'person' & frt==7,]$coef_log_road_dist  * log(rds_dist+1)]
       
       frt7[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
       
    # Fire Escape
#model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt7_escape.csv")
       
       # reset the veg categories

  frt7[, veg_C2 := 0]
  frt7[fwveg == "C-2", veg_C2 := 1]
  frt7[, veg_C7 := 0]
  frt7[fwveg == "C-7", veg_C7 := 1]
  frt7[, veg_M12 := 0]
  frt7[fwveg == "M-1/2", veg_M12 := 1]
       
  # change veg categories to ones that we have sim$coefficients
  frt7[fwveg == "C-4", veg_C2 := 1]
  frt7[fwveg == "C-5", veg_D12 := 1]
  frt7[fwveg == "C-7", veg_D12 := 1]
  frt7[fwveg == "S-1", veg_M12 := 1]
  frt7[fwveg == "S-2", veg_M12 := 1]
       
       
  frt7[, logit_P_escape := escapestatic * all + 
    sim$coefficients[cause == 'escape' & frt==7,]$coef_climate_2 * climate2escape +
    sim$coefficients[cause == 'escape' & frt==7,]$coef_c1 * veg_C1 +
    sim$coefficients[cause == 'escape' & frt==7,]$coef_c3 * veg_C3 +
    sim$coefficients[cause == 'escape' & frt==7,]$coef_d12 * veg_D12 +
    sim$coefficients[cause == 'escape' & frt==7,]$coef_m12 * veg_M12 +
    sim$coefficients[cause == 'escape' & frt==7,]$coef_N * veg_N +
    sim$coefficients[cause == 'escape' & frt==7,]$coef_o1ab * veg_O1ab]
       
  frt7[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
       
       # Spread
 #      model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt7_spread.csv")
       
       # reset the veg categories
       frt7[, veg_D12 := 0]
       frt7[fwveg == "D-1/2", veg_D12 := 1]
       frt7[, veg_C2 := 0]
       frt7[fwveg == "C-2", veg_C2 := 1]
       frt7[, veg_M12 := 0]
       frt7[fwveg == "M-1/2", veg_M12 := 1]
       
       # change veg categories to ones that we have sim$coefficients
       frt7[fwveg == "C-5", veg_C7 := 1]
       frt7[fwveg == "M-3", veg_O1ab := 1]
       
    frt7[, logit_P_spread := spreadstatic * all + 
      sim$coefficients[cause == 'spread' & frt==7,]$coef_climate_1 * climate1spread+
      sim$coefficients[cause == 'spread' & frt==7,]$coef_climate_2 * climate2spread+
      sim$coefficients[cause == 'spread' & frt==7,]$coef_c2 * veg_C2 +
      sim$coefficients[cause == 'spread' & frt==7,]$coef_c3 * veg_C3 +
      sim$coefficients[cause == 'spread' & frt==7,]$coef_c7 * veg_C7 +
      sim$coefficients[cause == 'spread' & frt==7,]$coef_d12 * veg_D12 +
      sim$coefficients[cause == 'spread' & frt==7,]$coef_m12 * veg_M12 +
      sim$coefficients[cause == 'spread' & frt==7,]$coef_N * veg_N +
      sim$coefficients[cause == 'spread' & frt==7,]$coef_o1ab * veg_O1ab +
      sim$coefficients[cause == 'spread' & frt==7,]$coef_s1 * veg_S1 +
      sim$coefficients[cause == 'spread' & frt==7,]$coef_s2 * veg_S2 +
      sim$coefficients[cause == 'spread' & frt==7,]$coef_log_road_dist * log(rds_dist+1)]
       
       frt7[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
       
       frt7[, prob_tot_ignit := prob_ignition_lightning*0.16 + (prob_ignition_person*0.84)]
       frt7[veg_W==1,prog_tot_ignit:=0]
       frt7[veg_W==1,prob_ignition_lightning:=0]
       frt7[veg_W==1,prob_ignition_person:=0]
       frt7[veg_W==1,prob_ignition_escape:=0]
       frt7[veg_W==1,prob_ignition_spread:=0]
       
      frt7<-frt7[, c("pixelid","frt","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]
      
  } else {
    
    print("no data for FRT 7")
    
    frt7<-data.table(pixelid=as.numeric(),
                     frt = as.numeric(),
                     prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(), 
                     prob_ignition_escape = as.integer(),
                     prob_ignition_spread = as.integer(),
                     prob_tot_ignit = as.integer())
  }
  
  #### FRT9 #### 
  if (nrow(dat[frt==9,])>0) {
    frt9<- dat[frt==9,]
    
    ##Lightning
    
    #NOTE C-2 is the intercept
    frt9[fwveg == "C-4", veg_C2 :=1]
    frt9[fwveg == "D-1/2", veg_C7:=1]
    frt9[fwveg == "C-5", veg_C7:=1]
    frt9[fwveg == "S-1", veg_M12:=1]
    
    frt9[pixelid>0, all:=1]
    
 #   model_coef_table_lightning<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt9_lightning.csv")
    
  frt9[, logit_P_lightning := ignitstaticlightning * all + 
    sim$coefficients[cause == "Lightning" & frt==9,]$coef_climate_1*climate1lightning + 
    sim$coefficients[cause == "Lightning" & frt==9,]$coef_c1 * veg_C1 +
    sim$coefficients[cause == "Lightning" & frt==9,]$coef_c2 * veg_C2 +
    sim$coefficients[cause == "Lightning" & frt==9,]$coef_c7 * veg_C7 +
    sim$coefficients[cause == "Lightning" & frt==9,]$coef_m12 * veg_M12 +
    sim$coefficients[cause == "Lightning" & frt==9,]$coef_n * veg_N +
    sim$coefficients[cause == "Lightning" & frt==9,]$coef_o1ab * veg_O1ab]
    
    # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
    frt9[, prob_ignition_lightning<-exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
    
  # Person caused fires
  # model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT9_person.csv")
  frt9[, logit_P_human := ignitstatichuman  * all + 
      sim$coefficients[cause == 'person' & frt == 9, ]$coef_climate_1 * climate1person]
         
         frt9[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
         
  # Fire Escape
#  model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt9_escape.csv")
         
  frt9[, logit_P_escape := escapestatic * all + 
        sim$coefficients[cause == 'escape' & frt==9,]$coef_climate_1 * climate1escape +
        sim$coefficients[cause == 'escape' & frt==9,]$coef_log_road_dist * log(rds_dist+1)]
         
  frt9[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
         
         # Spread
 #  model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt9_spread.csv")
         
         # reset the veg categories
    frt9[, veg_C7 := 0]
    frt9[fwveg == "C-7", veg_C7 := 1]
    frt9[, veg_C2 := 0]
    frt9[fwveg == "C-2", veg_C2 := 1]
    frt9[, veg_M12 := 0]
    frt9[fwveg == "M-1/2", veg_M12 := 1]
         
         # change veg categories to ones that we have sim$coefficients
    frt9[fwveg == "C-4", veg_C2 := 1]
    frt9[fwveg == "C-5", veg_C7 := 1]
    frt9[fwveg == "S-1", veg_M12 := 1]
         
    frt9[, logit_P_spread := spreadstatic * all + 
        sim$coefficients[cause == 'spread' & frt==9,]$coef_climate_1 * climate1spread+
        sim$coefficients[cause == 'spread' & frt==9,]$coef_climate_2 * climate2spread+
        sim$coefficients[cause == 'spread' & frt==9,]$coef_c2 * veg_C2 +
        sim$coefficients[cause == 'spread' & frt==9,]$coef_c3 * veg_C3 +
        sim$coefficients[cause == 'spread' & frt==9,]$coef_c7 * veg_C7 +
        sim$coefficients[cause == 'spread' & frt==9,]$coef_d12 * veg_D12 +
        sim$coefficients[cause == 'spread' & frt==9,]$coef_m12 * veg_M12 +
        sim$coefficients[cause == 'spread' & frt==9,]$coef_N * veg_N +
        sim$coefficients[cause == 'spread' & frt==9,]$coef_o1ab * veg_O1ab +
        sim$coefficients[cause == 'spread' & frt==9,]$coef_log_road_dist * log(rds_dist+1)]
         
  frt9[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
  
  frt9[, prob_tot_ignit := (prob_ignition_lightning*0.7) + (prob_ignition_person*0.3)]
  
  frt9[veg_W==1,prog_tot_ignit:=0]
  frt9[veg_W==1,prob_ignition_lightning:=0]
  frt9[veg_W==1,prob_ignition_person:=0]
  frt9[veg_W==1,prob_ignition_escape:=0]
  frt9[veg_W==1,prob_ignition_spread:=0]
  
  
  
  frt9<-frt9[, c("pixelid","frt","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]
  } else {
    
    print("no data for FRT 9")
    
    frt9<-data.table(pixelid=as.numeric(),
                     frt = as.numeric(),
                     prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(), 
                     prob_ignition_escape = as.integer(),
                     prob_ignition_spread = as.integer(),
                     prob_tot_ignit = as.integer())
    
      
  }
  
  #### FRT10 #### 
  if (nrow(dat[frt==10,])>0) {
    frt10<- dat[frt==10,]
    
    #NOTE C-2 is the intercept
    frt10[fwveg == "C-1", veg_C3 :=1]
    frt10[fwveg == "C-4", veg_C2:=1]
    frt10[fwveg == "S-1", veg_M12:=1]
    frt10[fwveg == "S-2", veg_M12:=1]
    
    frt10[pixelid>0, all:=1]
    
 #   model_coef_table_lightning<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt10_lightning.csv")
    
    frt10[, logit_P_lightning := ignitstaticlightning * all + 
      sim$coefficients[cause == 'Lightning' & frt==10,]$coef_climate_1*climate1lightning + 
      sim$coefficients[cause == 'Lightning' & frt==10,]$coef_climate_2*climate2lightning + 
      sim$coefficients[cause == 'Lightning' & frt==10,]$coef_c3 * veg_C3 +
      sim$coefficients[cause == 'Lightning' & frt==10,]$coef_c5 * veg_C5 +
      sim$coefficients[cause == 'Lightning' & frt==10,]$coef_c7 * veg_C7 +
      sim$coefficients[cause == 'Lightning' & frt==10,]$coef_d12 * veg_D12 +
      sim$coefficients[cause == 'Lightning' & frt==10,]$coef_m12 * veg_M12 +
      sim$coefficients[cause == 'Lightning' & frt==10,]$coef_N * veg_N +
      sim$coefficients[cause == 'Lightning' & frt==10,]$coef_o1ab * veg_O1ab]
    
    # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
    frt10[, prob_ignition_lightning := exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
    
    # Person caused fires
 #    model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT10_person.csv")
    
    frt10[, veg_M12 := 0]
    frt10[fwveg == "M-1/2", veg_M12 := 1]
    
    frt10[fwveg == "C-1", veg_C3 :=1]
    frt10[fwveg == "C-4", veg_C2:=1]
    frt10[fwveg == "S-1", veg_C4:=1]
    frt10[fwveg == "S-2", veg_C7:=1]
    frt10[fwveg == "M-1/2", veg_C5:=1]
    frt10[fwveg == "O-1a/b", veg_C3:=1]
    
    
    frt10[, logit_P_human := ignitstatichuman  * all + 
      sim$coefficients[cause == 'person' & frt == 10, ]$coef_climate_1 * climate1person + 
      sim$coefficients[cause == 'person' & frt == 10, ]$coef_c3 * veg_C3 +
      sim$coefficients[cause == 'person' & frt == 10, ]$coef_c5 * veg_C5 +
      sim$coefficients[cause == 'person' & frt == 10, ]$coef_c7 * veg_C7 +
      sim$coefficients[cause == 'person' & frt == 10, ]$coef_N * veg_N +
      sim$coefficients[cause == 'person' & frt == 10, ]$coef_log_road_dist * log(rds_dist+1) ]
         
         frt10[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
         
         # Fire Escape
   #  model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt10_escape.csv")
         
    frt10[, logit_P_escape := escapestatic * all + 
        sim$coefficients[cause == 'escape' & frt==10,]$coef_climate_1 * climate1escape +
        sim$coefficients[cause == 'escape' & frt==10,]$coef_road_dist * rds_dist]
         
         frt10[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
         
         # Spread
 #   model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt10_spread.csv")
    
    frt10[, veg_C3 := 0]
    frt10[fwveg == "C-3", veg_C3 := 1]
    frt10[, veg_C4 := 0]
    frt10[fwveg == "C-4", veg_C4 := 1]
    frt10[, veg_C5 := 0]
    frt10[fwveg == "C-5", veg_C5 := 1]
    
    
    frt10[fwveg == "C-4", veg_C2 :=1]
    frt10[fwveg == "S-2", veg_C7:=1]
    frt10[fwveg == "M-3", veg_O1ab:=1]
    
    
    frt10[, logit_P_spread := spreadstatic * all + 
        sim$coefficients[cause == 'spread' & frt==10,]$coef_climate_1 * climate1spread+
        sim$coefficients[cause == 'spread' & frt==10,]$coef_climate_2 * climate2spread+
        sim$coefficients[cause == 'spread' & frt==10,]$coef_c2 * veg_C2 +
        sim$coefficients[cause == 'spread' & frt==10,]$coef_c3 * veg_C3 +
        sim$coefficients[cause == 'spread' & frt==10,]$coef_c5 * veg_C5 +
        sim$coefficients[cause == 'spread' & frt==10,]$coef_c7 * veg_C7 +
        sim$coefficients[cause == 'spread' & frt==10,]$coef_d12 * veg_D12 +
        sim$coefficients[cause == 'spread' & frt==10,]$coef_m12 * veg_M12 +
        sim$coefficients[cause == 'spread' & frt==10,]$coef_m3 * veg_M3 +
        sim$coefficients[cause == 'spread' & frt==10,]$coef_N * veg_N +
        sim$coefficients[cause == 'spread' & frt==10,]$coef_o1ab * veg_O1ab +
        sim$coefficients[cause == 'spread' & frt==10,]$coef_s1 * veg_S1]
         
    frt10[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
    
    
    frt10[, prob_tot_ignit := (prob_ignition_lightning*0.86) + (prob_ignition_person*0.14)]
    
    frt10[veg_W==1,prog_tot_ignit:=0]
    frt10[veg_W==1,prob_ignition_lightning:=0]
    frt10[veg_W==1,prob_ignition_person:=0]
    frt10[veg_W==1,prob_ignition_escape:=0]
    frt10[veg_W==1,prob_ignition_spread:=0]
    

    
    frt10<-frt10[, c("pixelid","frt","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]
  } else {
    
    print("no data for FRT 10")
    
    frt10<-data.table(pixelid=as.numeric(),
                      frt = as.numeric(),
                      prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(), 
                     prob_ignition_escape = as.integer(),
                     prob_ignition_spread = as.integer(),
                     prob_tot_ignit = as.integer())
    
    
  }

  #### FRT11 #### 
  if (nrow(dat[frt==11,])>0) {
    frt11<- dat[frt==11,]
    
    frt11[fwveg == "C-5", veg_C7 :=1]
    frt11[fwveg == "D-1/2", veg_C7:=1]
    frt11[fwveg == "S-1", veg_M12:=1]
    frt11[fwveg == "S-2", veg_M12:=1]
    frt11[fwveg == "S-3", veg_M12:=1]
    frt11[fwveg == "O-1a/b", veg_C3:=1]
    
    frt11[pixelid>0, all:=1]
    
   # model_coef_table_lightning<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt11_lightning.csv")
    
    frt11[, logit_P_lightning := ignitstaticlightning * all + 
      sim$coefficients[cause == 'Lightning' & frt==11,]$coef_climate_1 * climate1lightning + 
      sim$coefficients[cause == 'Lightning' & frt==11,]$coef_climate_2 * climate2lightning + 
      sim$coefficients[cause == 'Lightning' & frt==11,]$coef_c1 * veg_C1 +
      sim$coefficients[cause == 'Lightning' & frt==11,]$coef_c2 * veg_C2 +
      sim$coefficients[cause == 'Lightning' & frt==11,]$coef_c7 * veg_C7 +
      sim$coefficients[cause == 'Lightning' & frt==11,]$coef_m12 * veg_M12 +
      sim$coefficients[cause == 'Lightning' & frt==11,]$coef_N * veg_N]
    
    # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
    frt11[, prob_ignition_lightning<-exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
    
    
    # Person caused fires
#   model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT11_person.csv")
    frt11[, logit_P_human := ignitstatichuman  * all + 
            sim$coefficients[cause == 'person' & frt == 11, ]$coef_climate_1 * climate1person +
            sim$coefficients[cause == 'person' & frt == 11, ]$coef_log_road_dist * log(rds_dist+1) ]
    
    frt11[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
    
    # Fire Escape
 #   model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt11_escape.csv")
    
    frt11[, logit_P_escape := escapestatic * all + 
            sim$coefficients[cause == 'escape' & frt==11,]$coef_climate_1 * climate1escape]
    
    frt11[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
    
    # Spread
#   model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt11_spread.csv")
    
    frt11[, veg_C7 := 0]
    frt11[fwveg == "C-7", veg_C7 := 1]
    frt11[, veg_M12 := 0]
    frt11[fwveg == "M-1/2", veg_M12 := 1]
    frt11[, veg_C3 := 0]
    frt11[fwveg == "C-3", veg_C3 := 1]

    frt11[fwveg == "S-1", veg_M12 :=1]
    frt11[fwveg == "S-2", veg_C7:=1]
    frt11[fwveg == "S-3", veg_M12:=1]
    
  frt11[, logit_P_spread := spreadstatic * all + 
        sim$coefficients[cause == 'spread' & frt==11,]$coef_climate_2 * climate2spread +
        sim$coefficients[cause == 'spread' & frt==11,]$coef_c2 * veg_C2 +
        sim$coefficients[cause == 'spread' & frt==11,]$coef_c3 * veg_C3 +
        sim$coefficients[cause == 'spread' & frt==11,]$coef_c5 * veg_C5 +
        sim$coefficients[cause == 'spread' & frt==11,]$coef_c7 * veg_C7 +
        sim$coefficients[cause == 'spread' & frt==11,]$coef_d12 * veg_D12 +
        sim$coefficients[cause == 'spread' & frt==11,]$coef_m12 * veg_M12 +
        sim$coefficients[cause == 'spread' & frt==11,]$coef_N * veg_N +
        sim$coefficients[cause == 'spread' & frt==11,]$coef_o1ab * veg_O1ab +
        sim$coefficients[cause == 'spread' & frt==11,]$coef_road_dist * rds_dist]
    
  frt11[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
  
  frt11[, prob_tot_ignit := (prob_ignition_lightning*0.42) + (prob_ignition_person*0.58)]
  
  frt11[veg_W==1,prog_tot_ignit:=0]
  frt11[veg_W==1,prob_ignition_lightning:=0]
  frt11[veg_W==1,prob_ignition_person:=0]
  frt11[veg_W==1,prob_ignition_escape:=0]
  frt11[veg_W==1,prob_ignition_spread:=0]
  
  
  frt11<-frt11[, c("pixelid","frt","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]  
  } else {
    
    print("no data for FRT 11")
    
    frt11<-data.table(pixelid = as.integer(),
                      frt = as.numeric(),
                     prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(), 
                     prob_ignition_escape = as.integer(),
                     prob_ignition_spread = as.integer(),
                     prob_tot_ignit = as.integer())
    
    
  }
  
  #### FRT12  #### 
  if (nrow(dat[frt==12,])>0) {
    frt12<- dat[frt==12,]
    
    frt12[fwveg == "S-3", veg_S1 :=1]
    
    frt12[pixelid>0, all:=1]
    
#    model_coef_table_lightning<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt12_lightning.csv")
    
    frt12[, logit_P_lightning := ignitstaticlightning * all + 
      sim$coefficients[cause == 'Lightning' & frt==12,]$coef_climate_1 * climate1lightning + 
      sim$coefficients[cause == 'Lightning' & frt==12,]$coef_c2 * veg_C2 +
      sim$coefficients[cause == 'Lightning' & frt==12,]$coef_c3 * veg_C3 +
      sim$coefficients[cause == 'Lightning' & frt==12,]$coef_c4 * veg_C4 +
      sim$coefficients[cause == 'Lightning' & frt==12,]$coef_c5 * veg_C5 +
      sim$coefficients[cause == 'Lightning' & frt==12,]$coef_c7 * veg_C7 +
      sim$coefficients[cause == 'Lightning' & frt==12,]$coef_d12 * veg_D12 +
      sim$coefficients[cause == 'Lightning' & frt==12,]$coef_m12 * veg_M12 +
      sim$coefficients[cause == 'Lightning' & frt==12,]$coef_m3 * veg_M3 +
      sim$coefficients[cause == 'Lightning' & frt==12,]$coef_N * veg_N + 
      sim$coefficients[cause == 'Lightning' & frt==12,]$coef_o1ab * veg_O1ab +
      sim$coefficients[cause == 'Lightning' & frt==12,]$coef_s1 * veg_S1 +
      sim$coefficients[cause == 'Lightning' & frt==12,]$coef_s2 * veg_S2]
      
    
    # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
    frt12[, prob_ignition_lightning := exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
    
    # Person caused fires
 #  model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT12_person.csv")
    frt12[, logit_P_human := ignitstatichuman  * all + 
            sim$coefficients[cause == 'person' & frt == 12, ]$coef_climate_1 * climate1person +
      sim$coefficients[cause == 'person' & frt == 12, ]$coef_c3 * veg_C3 +
      sim$coefficients[cause == 'person' & frt == 12, ]$coef_c5 * veg_C5 +
      sim$coefficients[cause == 'person' & frt == 12, ]$coef_c7 * veg_C7 +
      sim$coefficients[cause == 'person' & frt == 12, ]$coef_d12 * veg_D12 +
      sim$coefficients[cause == 'person' & frt == 12, ]$coef_m12 * veg_M12 +
      sim$coefficients[cause == 'person' & frt == 12, ]$coef_N * veg_N +
      sim$coefficients[cause == 'person' & frt == 12, ]$coef_o1ab * veg_O1ab +
    sim$coefficients[cause == 'person' & frt == 12, ]$coef_s1 * veg_S1 +
    sim$coefficients[cause == 'person' & frt == 12, ]$coef_log_road_dist * log(rds_dist+1) ]
    
    frt12[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
    
    # Fire Escape
#   model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt12_escape.csv")
   
  frt12[, veg_S1 := 0]
  frt12[fwveg == "S-1", veg_S1 :=1]
  
  frt12[fwveg == "S-3", veg_S1 :=1]
  frt12[fwveg == "S-2", veg_C7 :=1]
  frt12[fwveg == "C-1", veg_C3 :=1]
  frt12[fwveg == "C-4", veg_C2 :=1]
  frt12[fwveg == "M-3", veg_O1ab :=1]
    
  frt12[, logit_P_escape := escapestatic * all + 
      sim$coefficients[cause == 'escape' & frt==12,]$coef_climate_1 * climate1escape + 
      sim$coefficients[cause == 'escape' & frt==12,]$coef_climate_2 * climate2escape +
      sim$coefficients[cause == 'escape' & frt==12,]$coef_c2 * veg_C2 +
      sim$coefficients[cause == 'escape' & frt==12,]$coef_c5 * veg_C5 + 
      sim$coefficients[cause == 'escape' & frt==12,]$coef_c7 * veg_C7 +
      sim$coefficients[cause == 'escape' & frt==12,]$coef_d12 * veg_D12 +
      sim$coefficients[cause == 'escape' & frt==12,]$coef_m12 * veg_M12 +
      sim$coefficients[cause == 'escape' & frt==12,]$coef_N * veg_N +
      sim$coefficients[cause == 'escape' & frt==12,]$coef_o1ab * veg_O1ab +
      sim$coefficients[cause == 'escape' & frt==12,]$coef_s1 * veg_S1 +
      sim$coefficients[cause == 'escape' & frt==12,]$coef_s2 * veg_S2 +
      sim$coefficients[cause == 'escape' & frt==12,]$coef_road_dist * rds_dist]
    
    frt12[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
    
    # Spread
#    model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt12_spread.csv")
    
    frt12[, veg_C7 := 0]
    frt12[fwveg == "C-7", veg_C7 := 1]
    frt12[, veg_M12 := 0]
    frt12[fwveg == "M-1/2", veg_M12 := 1]
    frt12[, veg_C3 := 0]
    frt12[fwveg == "C-3", veg_C3 := 1]
    
    frt12[fwveg == "S-1", veg_M12 :=1]
    frt12[fwveg == "S-2", veg_C7:=1]
    frt12[fwveg == "S-3", veg_M12:=1]
    
    frt12[, logit_P_spread := spreadstatic * all + 
            sim$coefficients[cause == 'spread' & frt==12,]$coef_climate_2 * climate2spread +
            sim$coefficients[cause == 'spread' & frt==12,]$coef_c2 * veg_C2 +
            sim$coefficients[cause == 'spread' & frt==12,]$coef_c3 * veg_C3 +
            sim$coefficients[cause == 'spread' & frt==12,]$coef_c4 * veg_C4 +
            sim$coefficients[cause == 'spread' & frt==12,]$coef_c5 * veg_C5 +
            sim$coefficients[cause == 'spread' & frt==12,]$coef_c7 * veg_C7 +
            sim$coefficients[cause == 'spread' & frt==12,]$coef_d12 * veg_D12 +
            sim$coefficients[cause == 'spread' & frt==12,]$coef_m12 * veg_M12 +
            sim$coefficients[cause == 'spread' & frt==12,]$coef_m3 * veg_M3 +
            sim$coefficients[cause == 'spread' & frt==12,]$coef_N * veg_N +
            sim$coefficients[cause == 'spread' & frt==12,]$coef_o1ab * veg_O1ab +
            sim$coefficients[cause == 'spread' & frt==12,]$coef_s1 * veg_S1 +
            sim$coefficients[cause == 'spread' & frt==12,]$coef_s2 * veg_S2 +
            sim$coefficients[cause == 'spread' & frt==12,]$coef_log_road_dist * log(rds_dist+1)]
    
    frt12[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
    
    frt12[, prob_tot_ignit := (prob_ignition_lightning*0.48) + (prob_ignition_person*0.52)]
    
    frt12[veg_W==1,prog_tot_ignit:=0]
    frt12[veg_W==1,prob_ignition_lightning:=0]
    frt12[veg_W==1,prob_ignition_person:=0]
    frt12[veg_W==1,prob_ignition_escape:=0]
    frt12[veg_W==1,prob_ignition_spread:=0]
    
    
    frt12<-frt12[, c("pixelid","frt","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]    
  } else {
    
    print("no data for FRT 12")
    
    frt12<-data.table(pixelid = as.numeric(),
                      frt = as.numeric(),
                      prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(), 
                     prob_ignition_escape = as.integer(),
                     prob_ignition_spread = as.integer(),
                     prob_tot_ignit = as.integer())
    
  }
  
  #### FRT13  #### 
  if (nrow(dat[frt==13,])>0) {
    frt13<- dat[frt==13,]
    
    frt13[fwveg == "C-4", veg_C2 :=1]
    frt13[fwveg == "C-1", veg_C3 :=1]
    frt13[fwveg == "M-3", veg_O1ab :=1]
    
    frt13[pixelid>0, all:=1]
    
#    model_coef_table_lightning<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt13_lightning.csv")
    
    frt13[, logit_P_lightning := ignitstaticlightning * all + 
            sim$coefficients[cause == 'Lightning' & frt==13,]$coef_climate_1 * climate1lightning +
            sim$coefficients[cause == 'Lightning' & frt==13,]$coef_climate_2 * climate2lightning +
            sim$coefficients[cause == 'Lightning' & frt==13,]$coef_c3 * veg_C3 +
            sim$coefficients[cause == 'Lightning' & frt==13,]$coef_c5 * veg_C5 +
            sim$coefficients[cause == 'Lightning' & frt==13,]$coef_c7 * veg_C7 +
            sim$coefficients[cause == 'Lightning' & frt==13,]$coef_d12 * veg_D12 +
            sim$coefficients[cause == 'Lightning' & frt==13,]$coef_m12 * veg_M12 +
            sim$coefficients[cause == 'Lightning' & frt==13,]$coef_N * veg_N + 
            sim$coefficients[cause == 'Lightning' & frt==13,]$coef_o1ab * veg_O1ab +
            sim$coefficients[cause == 'Lightning' & frt==13,]$coef_s1 * veg_S1 +
            sim$coefficients[cause == 'Lightning' & frt==13,]$coef_s2 * veg_S2 +
            sim$coefficients[cause == 'Lightning' & frt==13,]$coef_s3 * veg_S3]
    
    
    # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
    frt13[, prob_ignition_lightning := exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
 
    
    # Person caused fires
#      model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT13_person.csv")
      
      frt13[, veg_C7 :=0]
      frt13[fwveg == "C-7", veg_C7 :=1]
      frt13[, veg_O1ab := 0]
      frt13[fwveg == "O-1a/b", veg_O1ab :=1]
      
      frt13[fwveg == "C-4", veg_C2 :=1]
      frt13[fwveg == "C-1", veg_C3 :=1]
      frt13[fwveg == "S-2", veg_C7 :=1]
      
      
    frt13[, logit_P_human := ignitstatichuman  * all + 
      sim$coefficients[cause == 'person' & frt == 13, ]$coef_climate_1 * climate1person +
      sim$coefficients[cause == 'person' & frt == 13, ]$coef_climate_2 * climate2person +
      sim$coefficients[cause == 'person' & frt == 13, ]$coef_log_road_dist * log(rds_dist+1) +
        sim$coefficients[cause == 'person' & frt == 13, ]$coef_c3 * veg_C3 +
        sim$coefficients[cause == 'person' & frt == 13, ]$coef_c5 * veg_C5 +
        sim$coefficients[cause == 'person' & frt == 13, ]$coef_c7 * veg_C7 +
        sim$coefficients[cause == 'person' & frt == 13, ]$coef_d12 * veg_D12 +
        sim$coefficients[cause == 'person' & frt == 13, ]$coef_m12 * veg_M12 +
        sim$coefficients[cause == 'person' & frt == 13, ]$coef_m3 * veg_M3 +
        sim$coefficients[cause == 'person' & frt == 13, ]$coef_N * veg_N +
        sim$coefficients[cause == 'person' & frt == 13, ]$coef_o1ab * veg_O1ab +
        sim$coefficients[cause == 'person' & frt == 13, ]$coef_s1 * veg_S1+
        sim$coefficients[cause == 'person' & frt == 13, ]$coef_s3 * veg_S3 
            ]
    
    frt13[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
    
    # Fire Escape
 #  model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt13_escape.csv")
    
    frt13[, veg_C2 := 0]
    frt13[fwveg == "C-2", veg_C2 :=1]
    frt13[, veg_C3 := 0]
    frt13[fwveg == "C-3", veg_C3 :=1]
    frt13[, veg_C7 := 0]
    frt13[fwveg == "C-7", veg_C7 :=1]
    frt13[, veg_O1ab := 0]
    frt13[fwveg == "O-1a/b", veg_O1ab :=1]
    
    frt13[fwveg == "C-1", veg_C3 :=1]
    frt13[fwveg == "C-4", veg_C2 :=1]
    
    frt13[, logit_P_escape := escapestatic * all + 
            sim$coefficients[cause == 'escape' & frt==13,]$coef_climate_1 * climate1escape + 
            sim$coefficients[cause == 'escape' & frt==13,]$coef_climate_2 * climate2escape +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_c3 * veg_C3 +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_c5 * veg_C5 + 
            sim$coefficients[cause == 'escape' & frt==13,]$coef_c7 * veg_C7 +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_d12 * veg_D12 +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_m12 * veg_M12 +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_m3 * veg_M3 +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_N * veg_N +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_o1ab * veg_O1ab +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_s1 * veg_S1 +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_s2 * veg_S2 +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_s3 * veg_S3 +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_road_dist * rds_dist]
    
    frt13[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
    
    # Spread
 #   model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt13_spread.csv")
    
    frt13[, veg_C2 := 0]
    frt13[fwveg == "C-2", veg_C2 := 1]
    frt13[, veg_C3 := 0]
    frt13[fwveg == "C-3", veg_C3 := 1]
    
    frt13[fwveg == "C-1", veg_C3 :=1]
    
    frt13[, logit_P_spread := spreadstatic * all + 
            sim$coefficients[cause == 'spread' & frt==13,]$coef_climate_2 * climate2spread +
            sim$coefficients[cause == 'spread' & frt==13,]$coef_c3 * veg_C3 +
            sim$coefficients[cause == 'spread' & frt==13,]$coef_c5 * veg_C5 +
            sim$coefficients[cause == 'spread' & frt==13,]$coef_c7 * veg_C7 +
            sim$coefficients[cause == 'spread' & frt==13,]$coef_d12 * veg_D12 +
            sim$coefficients[cause == 'spread' & frt==13,]$coef_m12 * veg_M12 +
            sim$coefficients[cause == 'spread' & frt==13,]$coef_m3 * veg_M3 +
            sim$coefficients[cause == 'spread' & frt==13,]$coef_N * veg_N +
            sim$coefficients[cause == 'spread' & frt==13,]$coef_o1ab * veg_O1ab +
            sim$coefficients[cause == 'spread' & frt==13,]$coef_s1 * veg_S1 +
            sim$coefficients[cause == 'spread' & frt==13,]$coef_s2 * veg_S2 +
            sim$coefficients[cause == 'spread' & frt==13,]$coef_s3 * veg_S3]
    
    frt13[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
    
    frt13[, prob_tot_ignit := (prob_ignition_lightning*0.83) + (prob_ignition_person*0.17)]
    
    frt13[veg_W==1,prog_tot_ignit:=0]
    frt13[veg_W==1,prob_ignition_lightning:=0]
    frt13[veg_W==1,prob_ignition_person:=0]
    frt13[veg_W==1,prob_ignition_escape:=0]
    frt13[veg_W==1,prob_ignition_spread:=0]
    
    
    frt13<-frt13[, c("pixelid", "frt","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]
    
  } else {
    
    print("no data for FRT 13")
    
    frt13<-data.table(pixelid=as.numeric(), 
                      frt = as.numeric(),
                      prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(), 
                     prob_ignition_escape = as.integer(),
                     prob_ignition_spread = as.integer(),
                     prob_tot_ignit = as.integer())
    
    
  }  
  
  #### FRT14 #### 
  if (nrow(dat[frt==14,])>0) {
    frt14<- dat[frt==14,]
    
    frt14[fwveg == "C-4", veg_C2 :=1]
    frt14[fwveg == "S-2", veg_C7 :=1]
    frt14[fwveg == "S-3", veg_M12 :=1]
    
    frt14[pixelid>0, all:=1]
    
# model_coef_table_lightning<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt14_lightning.csv")
    
    frt14[, logit_P_lightning := ignitstaticlightning * all + 
            sim$coefficients[cause == 'Lightning' & frt==14,]$coef_climate_1 * climate1lightning +
            sim$coefficients[cause == 'Lightning' & frt==14,]$coef_c3 * veg_C3 +
            sim$coefficients[cause == 'Lightning' & frt==14,]$coef_c5 * veg_C5 +
            sim$coefficients[cause == 'Lightning' & frt==14,]$coef_c7 * veg_C7 +
            sim$coefficients[cause == 'Lightning' & frt==14,]$coef_d12 * veg_D12 +
            sim$coefficients[cause == 'Lightning' & frt==14,]$coef_m12 * veg_M12 +
            sim$coefficients[cause == 'Lightning' & frt==14,]$coef_m3 * veg_M3 +
            sim$coefficients[cause == 'Lightning' & frt==14,]$coef_N * veg_N + 
            sim$coefficients[cause == 'Lightning' & frt==14,]$coef_o1ab * veg_O1ab +
            sim$coefficients[cause == 'Lightning' & frt==14,]$coef_s1 * veg_S1]
    
    
    # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
    frt14[, prob_ignition_lightning := exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
    
    # Person caused fires
#      model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT14_person.csv")
      
      frt14[, veg_C7 :=0]
      frt14[fwveg == "C-7", veg_C7 :=1]
      frt14[, veg_M12 :=0]
      frt14[fwveg == "M-1/2", veg_M12 :=1]
      
      frt14[fwveg == "M-3", veg_O1ab :=1]
      frt14[fwveg == "S-3", veg_S1 :=1]

    frt14[, logit_P_human := ignitstatichuman  * all + 
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_climate_1 * climate1person +
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_log_road_dist * log(rds_dist+1) +
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_c3 * veg_C3 +
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_c5 * veg_C5 +
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_c7 * veg_C7 +
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_d12 * veg_D12 +
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_m12 * veg_M12 +
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_N * veg_N +
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_o1ab * veg_O1ab +
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_s1 * veg_S1
    ]
    
    frt14[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
    
    # Fire Escape
#      model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt14_escape.csv")
      
  frt14[, veg_O1ab :=0]
  frt14[fwveg == "O-1a/b", veg_O1ab :=1]
  frt14[, veg_S1 :=0]
  frt14[fwveg == "S-1", veg_S1 :=1]
  frt14[, veg_C2 := 0]
  frt14[fwveg == "C-2", veg_C2 :=1]
  
  frt14[fwveg == "C-2", veg_C3 :=1]
  frt14[fwveg == "C-4", veg_C3 :=1]
  frt14[fwveg == "S-1", veg_M12 :=1]
  frt14[fwveg == "S-2", veg_C7 :=1]
  frt14[fwveg == "S-3", veg_M12 :=1]
    
   frt14[, logit_P_escape := escapestatic * all + 
      sim$coefficients[cause == 'escape' & frt==14,]$coef_climate_1 * climate1escape +
      sim$coefficients[cause == 'escape' & frt==14,]$coef_c7 * veg_C7 +
      sim$coefficients[cause == 'escape' & frt==14,]$coef_d12 * veg_D12 +
      sim$coefficients[cause == 'escape' & frt==14,]$coef_m12 * veg_M12 +
      sim$coefficients[cause == 'escape' & frt==14,]$coef_N * veg_N +
      sim$coefficients[cause == 'escape' & frt==14,]$coef_o1ab * veg_O1ab +
      sim$coefficients[cause == 'escape' & frt==14,]$coef_road_dist * rds_dist]
    
    frt14[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
    
    # Spread
#       model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt14_spread.csv")
       
       frt14[, veg_C3 :=0]
       frt14[fwveg == "C-3", veg_C3 :=1]
       frt14[, veg_C7 :=0]
       frt14[fwveg == "C-7", veg_C7 :=1]
       frt14[, veg_M12 := 0]
       frt14[fwveg == "M-1/2", veg_M12 :=1]
       
       frt14[fwveg == "S-2", veg_C7 :=1]
       frt14[fwveg == "C-4", veg_C2 :=1]
       frt14[fwveg == "S-3", veg_M12 :=1]
       
       
    frt14[, logit_P_spread := spreadstatic * all + 
            sim$coefficients[cause == 'spread' & frt==14,]$coef_climate_2 * climate2spread +
            sim$coefficients[cause == 'spread' & frt==14]$coef_c3 * veg_C3 +
            sim$coefficients[cause == 'spread' & frt==14,]$coef_c5 * veg_C5 +
            sim$coefficients[cause == 'spread' & frt==14,]$coef_c7 * veg_C7 +
            sim$coefficients[cause == 'spread' & frt==14,]$coef_d12 * veg_D12 +
            sim$coefficients[cause == 'spread' & frt==14,]$coef_m12 * veg_M12 +
            sim$coefficients[cause == 'spread' & frt==14,]$coef_N * veg_N +
            sim$coefficients[cause == 'spread' & frt==14,]$coef_o1ab * veg_O1ab +
            sim$coefficients[cause == 'spread' & frt==14,]$coef_s1 * veg_S1 +
            sim$coefficients[cause == 'spread' & frt==14,]$coef_road_dist * rds_dist]
    
    frt14[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
    
    frt14[, prob_tot_ignit := (prob_ignition_lightning*0.41) + (prob_ignition_person*0.59)]
    
    frt14[veg_W==1,prog_tot_ignit:=0]
    frt14[veg_W==1,prob_ignition_lightning:=0]
    frt14[veg_W==1,prob_ignition_person:=0]
    frt14[veg_W==1,prob_ignition_escape:=0]
    frt14[veg_W==1,prob_ignition_spread:=0]
    
  
    frt14<-frt14[, c("pixelid","frt","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]
    
  } else {
    
    print("no data for FRT 14")
    
    frt14<-data.table(pixelid= as.numeric(),
                      frt = as.numeric(),
                      prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(), 
                     prob_ignition_escape = as.integer(),
                     prob_ignition_spread = as.integer(),
                     prob_tot_ignit = as.integer())
    
      
  } 
  
  #### FRT15 #### 
  if (nrow(dat[frt==15,])>0) {
    frt15<- dat[frt==15,]
    
    frt15[fwveg == "C-2", veg_C3 :=1]
    frt15[fwveg == "O-1a/b", veg_C3 :=1]  
    frt15[pixelid>0, all:=1]
    
   # model_coef_table_lightning<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt15_lightning.csv")
    
    frt15[, logit_P_lightning := ignitstaticlightning * all + 
            sim$coefficients[cause == 'Lightning' & frt==15,]$coef_climate_2 * climate2lightning +
            sim$coefficients[cause == 'Lightning' & frt==15,]$coef_c5 * veg_C5 +
            sim$coefficients[cause == 'Lightning' & frt==15,]$coef_c7 * veg_C7 +
            sim$coefficients[cause == 'Lightning' & frt==15,]$coef_d12 * veg_D12 +
            sim$coefficients[cause == 'Lightning' & frt==15,]$coef_m12 * veg_M12 +
            sim$coefficients[cause == 'Lightning' & frt==15,]$coef_N * veg_N + 
            sim$coefficients[cause == 'Lightning' & frt==15,]$coef_s3 * veg_S3]
    
    
    # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
    frt15[, prob_ignition_lightning := exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
    
    # Person caused fires
#        model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT15_person.csv")
    
    
    frt15[, veg_C3 :=0]
    frt15[fwveg == "C-3", veg_C3 :=1]
    
    frt15[fwveg == "C-2", veg_C3 :=1]
    frt15[fwveg == "C-7", veg_C5 :=1]
    frt15[fwveg == "S-1", veg_S3 :=1]
    
    frt15[, logit_P_human := ignitstatichuman  * all + 
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_climate_1 * climate1person +
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_climate_2 * climate2person +
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_log_road_dist * log(rds_dist+1) +
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_c5 * veg_C5 +
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_d12 * veg_D12 +
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_m12 * veg_M12 +
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_N * veg_N +
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_o1ab * veg_O1ab +
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_s3 * veg_S3
    ]
    
    frt15[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
    
    # Fire Escape
#    model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt15_escape.csv")
    
    frt15[, veg_C5 :=0]
    frt15[fwveg == "C-5", veg_C5 :=1]
    frt15[, veg_S3 :=0]
    frt15[fwveg == "S-3", veg_S3 :=1]
    frt15[, veg_C3 := 0]
    frt15[fwveg == "C-3", veg_C3 :=1]
    
    frt15[fwveg == "C-2", veg_C3 :=1] 
    frt15[fwveg == "C-7", veg_C5 :=1]
    frt15[fwveg == "S-1", veg_S3 :=1]
    frt15[fwveg == "O-1a/b", veg_C3 :=1]
    
    ## Fix this? It looks like either I have the wrong coefficients table in here or the coefficients for some reason did not get entered into the table correctly. I need to fix this!
    
    frt15[, logit_P_escape := escapestatic * all + 
            sim$coefficients[cause == 'escape' & frt==15,]$coef_climate_2 * climate2escape +
            sim$coefficients[cause == 'escape' & frt==15,]$coef_c5 * veg_C5 +
            sim$coefficients[cause == 'escape' & frt==15,]$coef_d12 * veg_D12 +
            sim$coefficients[cause == 'escape' & frt==15,]$coef_m12 * veg_M12 +
            sim$coefficients[cause == 'escape' & frt==15,]$coef_N * veg_N +
            sim$coefficients[cause == 'escape' & frt==15,]$coef_S3 * veg_S3]
    
    frt15[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
    
    # Spread
#    model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt15_spread.csv")
    
    frt15[, veg_C3 :=0]
    frt15[fwveg == "C-3", veg_C3 :=1]
    frt15[, veg_C5 :=0]
    frt15[fwveg == "C-5", veg_C5 :=1]
    frt15[, veg_S3 := 0]
    frt15[fwveg == "S-3", veg_S3 :=1]
    
    frt15[fwveg == "C-2", veg_C3 :=1]
    frt15[fwveg == "M-3", veg_O1ab :=1]
    
    frt15[, logit_P_spread := spreadstatic * all + 
            sim$coefficients[cause == 'spread' & frt==15,]$coef_climate_1 * climate1spread +
            sim$coefficients[cause == 'spread' & frt==15,]$coef_climate_2 * climate2spread +
            sim$coefficients[cause == 'spread' & frt==15]$coef_c5 * veg_C5 +
            sim$coefficients[cause == 'spread' & frt==15,]$coef_c7 * veg_C7 +
            sim$coefficients[cause == 'spread' & frt==15,]$coef_d12 * veg_D12 +
            sim$coefficients[cause == 'spread' & frt==15,]$coef_m12 * veg_M12 +
            sim$coefficients[cause == 'spread' & frt==15,]$coef_N * veg_N +
            sim$coefficients[cause == 'spread' & frt==15,]$coef_o1ab * veg_O1ab +
            sim$coefficients[cause == 'spread' & frt==15,]$coef_s3 * veg_S3]
    
    frt15[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
    
    frt15[, prob_tot_ignit := (prob_ignition_lightning*0.28) + (prob_ignition_person*0.72)]
    
    frt15[veg_W==1,prog_tot_ignit:=0]
    frt15[veg_W==1,prob_ignition_lightning:=0]
    frt15[veg_W==1,prob_ignition_person:=0]
    frt15[veg_W==1,prob_ignition_escape:=0]
    frt15[veg_W==1,prob_ignition_spread:=0]
    
    
    frt15<-frt15[, c("pixelid","frt","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]    
  } else {
    
    print("no data for FRT 15")
    
    frt15<-data.table(pixelid = as.numeric(),
                      frt = as.numeric(),
                      prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(), 
                     prob_ignition_escape = as.integer(),
                     prob_ignition_spread = as.integer(),
                     prob_tot_ignit = as.integer())
  } 
  
  
  #### rbind frt data ####
  
  probFireRast<- do.call("rbind", list(frt5, frt7, frt9, frt10, frt11, frt12, frt13, frt14, frt15))
  
  sim$probFireRasts<-merge(sim$veg3, probFireRast, by.x="pixelid", by.y="pixelid", all.x=TRUE)
  
  sim$probFireRasts<-data.table(sim$probFireRasts)
  sim$probFireRasts[fwveg=="W",prob_tot_ignit:=0]
  
  print("number of NA values in probFireRasts$prob_ignition_lightning")
  print(table(is.na(sim$probFireRasts$prob_ignition_lightning)))
  
  
  return(invisible(sim))
}

distProcess <- function(sim) {
  
  if (suppliedElsewhere(sim$probFireRasts)) {
    
    probfire<-as.data.table(na.omit(sim$probFireRasts))
    #print(probfire)
    
    # create area raster
    ras.info<-dbGetQuery(sim$castordb, "Select * from raster_info limit 1;")
    area<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0)
    
    area[]<-sim$probFireRasts$prob_ignition_spread
    area <- reclassify(area, c(-Inf, 0, 0, 0, 1, 1))
    print(area)
    
    message("create escape raster")
    escapeRas<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0)
    escapeRas[]<-sim$probFireRasts$prob_ignition_escape
    
    
    message("create spread raster")
    spreadRas<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0)
    spreadRas[]<-sim$probFireRasts$prob_ignition_spread
  
    #for (i in 1:numberFireReps) {
    message("get fire ignition locations")
    
    no_ignitions<-round(rgamma(1, shape=sim$fit_g$estimate[1], rate=sim$fit_g$estimate[2]))

    no_ignitions<-ifelse(no_ignitions*sim$updateInterval < (sim$min_ignit*sim$updateInterval), (sim$min_ignit*sim$updateInterval), no_ignitions*sim$updateInterval)
    
    no_starts_sample<-sim$max_ignit*5*sim$updateInterval
    
    # sample more starting locations than needed and then discard extra after testing whether those locations actually ignite comparing its probability of igntion to a random number
    # get starting pixelids
    message("get pixelid of ignition locations")
    starts<-sample(probfire$pixelid, no_starts_sample, replace=FALSE)
    
    fire<-probfire[pixelid %in% starts,]
    fire$randomnumber<-runif(length(fire$pixelid))
    start<-fire[prob_tot_ignit>randomnumber, ]
    
    sams  <-  sample(start$pixelid, size = no_ignitions)
    #random.starts1<-probfire[pixelid %in% random.starts,]
    
    # take top ignition points up to the number of (no_ignitions) discard the rest. 
    
    #random.starts1$randomnumber<-runif(nrow(random.starts1))
    #escaped fires
    #escape.pts<- random.starts1[prob_ignition_escape  > randomnumber, ]
    
    message("simulating fire")
    
    # Iterative calling -- create a function with a high escape probability
    spreadWithEscape <- function(ras, start, escapeProb, spreadProb) {
      out <- spread2(ras, start = sams, spreadProb = escapeProb, asRaster = FALSE, allowOverlap=FALSE)
      while (any(out$state == "sourceActive")) {
        # pass in previous output as start
        out <- spread2(ras, start = out, spreadProb = spreadProb,
                       asRaster = TRUE, skipChecks = TRUE, allowOverlap=FALSE) # skipChecks for speed
      }
      out
    }
    
    sim$out  <- spreadWithEscape(area, start = random.starts, escapeProb = escapeRas , spreadProb = spreadRas)
  
    
    print(sim$out)
    
 
    message("updating pixels tables")
    
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, "UPDATE pixels SET age = 0, vol = 0, salvage_vol = 0 WHERE pixelid = :pixels", sim$out[, "pixels"])
    dbClearResult(rs)
    dbCommit(sim$castordb)
    
    message("updating vegetation inventory table")
    
    sim$inv[pixelid %in% sim$out$pixels, earliest_nonlogging_dist_type := "burn"]
    sim$inv[pixelid %in% sim$out$pixels, earliest_nonlogging_dist_date := time(sim)*sim$updateInterval + P(sim, "simStartYear", "fireCastor")]
    
    #qry<-paste0("UPDATE fueltype SET earliest_nonlogging_dist_type = 'burn', earliest_nonlogging_dist_date = ", time(sim)*sim$updateInterval + P(sim, "simStartYear", "fireCastor"), " WHERE pixelid = :pixels")
    #dbBegin(sim$castordb)
    #rs<-dbSendQuery(sim$castordb,qry , sim$out[, "pixels"])
    #dbClearResult(rs)
    #dbCommit(sim$castordb)
    
    #sim$dist.ras[out$pixels]<-time(sim)
    
    message("updating firedisturbanceTable")
    
    sim$firedisturbanceTable[pixelid %in% sim$out$pixels, numberTimesBurned := numberTimesBurned+1]
    
    x<-as.data.frame(table(sim$out$initialPixels))
    
    message("updating fire Report")
    
    tempfireReport<-data.table(timeperiod = time(sim), numberstarts = no_ignitions, numberescaped = nrow(x %>% dplyr::filter(Freq>1)), totalareaburned=sim$out[,.N], thlbburned = dbGetQuery(sim$castordb, paste0(" select sum(thlb) as thlb from pixels where pixelid in (", paste(sim$out$pixels, sep = "", collapse = ","), ");"))$thlb)
    
    
    sim$fireReport<-rbindlist(list(sim$fireReport,tempfireReport ))
    print(sim$fireReport)
      
    
  }
  
  
  return(invisible(sim))
}

savefirerast<-function(sim){
  
  message("saving rasters of fire locations")
  
  firepts<-sim$pts[,c("pixelid", "treed")]
  firepts[, burned:=0]
  
  firepts[pixelid %in% sim$out$pixels, burned := 1]
  
  ras.info<-dbGetQuery(sim$castordb, "Select * from raster_info limit 1;")
  burnpts<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0)
  
  burnpts[]<-firepts$burned
  
  terra::writeRaster(burnpts, file = paste0 ("burn_polygons_", time(sim)*sim$updateInterval, ".tif"),  overwrite=TRUE)
  
  return(invisible(sim))
}



numberStarts<-function(sim){
  
  message("downloading historical fire data and clip to aoi")
  library(bcdata)
  ignit<-try(
    bcdc_query_geodata("WHSE_LAND_AND_NATURAL_RESOURCE.PROT_HISTORICAL_INCIDENTS_SP") %>%
      dplyr::filter(FIRE_YEAR > 2000) %>%
      dplyr::filter(FIRE_TYPE == "Fire") %>%
      collect()
  )
  
  # ignit<- st_read ( dsn = "C:\\Users\\ekleynha\\Downloads\\BCGW_7113060B_1695444895226_2864\\PROT_HISTORICAL_INCIDENTS_SP\\H_FIRE_PNT_point.shp", stringsAsFactors = T) 
  
  # ignit<- ignit%>%
  #        dplyr::filter(FIRE_YEAR > 2002) %>%
  #        dplyr::filter(FIRE_TYPE == "Fire")

  
  message("done")
  
  
  study_area<-getSpatialQuery(paste0("SELECT * FROM ", sim$boundaryInfo[[1]], " WHERE ", sim$boundaryInfo[[2]], " in ('", paste(sim$boundaryInfo[[3]], sep = " '", collapse= "', '") ,"')"))
  
  print(study_area)
  ignit <- ignit[study_area, ]
  
  message("...done")
  
  library(dplyr)
  
  data <- ignit %>% group_by(FIRE_YEAR) %>% summarize(n=n()) %>% mutate(freq=n/sum(n)) 
  
  sim$fit_g  <- fitdistrplus::fitdist(data$n, "gamma")
  
  sim$min_ignit<-min(data$n)
  sim$max_ignit<-max(data$n)
  
  return(invisible(sim))
}

 
.inputObjects <- function(sim) {
  if(!suppliedElsewhere("road_distance", sim)){
    sim$road_distance<- data.table(pixelid= as.integer(), 
                                   road.dist = as.numeric())
  }
  
  if(!suppliedElsewhere("harvestPixelList", sim)){
    sim$harvestPixelList<- data.table(pixelid= as.integer(), 
                                      blockid = as.integer(),
                                      compartid = as.character())
  }
  return(invisible(sim))
}
