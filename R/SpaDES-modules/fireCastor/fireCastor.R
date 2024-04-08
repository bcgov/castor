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
  reqdPkgs = list("here","data.table", "raster", "SpaDES.tools", "tidyr", "pool", "climr"),
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
    #defineParameter("maxRun", "integer", '99999', NA, NA, "Maximum number of model runs to include. A value of 0 is ensembleMean only."),
    #defineParameter("run", "character", '99999', NA, NA, "The run of the climate projection from which to get future climate data e.g. r1i1p1f1"),
    defineParameter("nameForestInventoryRaster", "numeric", NA, NA, NA, "Raster of VRI feature id"),
    defineParameter("nameForestInventoryTable2", "character", "99999", NA, NA, desc = "Name of the veg comp table - the forest inventory"),
    defineParameter("nameForestInventoryKey", "character", "99999", NA, NA, desc = "Name of the veg comp primary key that links the table to the raster"),
    defineParameter("ignitionMethod", "character", "pre", NA, NA, "This describes the type of method used to determine the number of fire starts"),
    #defineParameter("numberFireReps", "numerical", "99999", NA, NA, desc = "value with the number of fire simulation repetitions needed"),
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
    expectsInput(objectName = "road_distance", objectClass = "data.table", desc = 'The euclidian distance to the nearest road', sourceURL = NA),
    expectsInput(objectName ="ignitionMethod", objectClass ="character", desc = NA, sourceURL = NA)
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
      sim <- scheduleEvent(sim, time(sim), "fireCastor", "downScaleTo10Km", 13)
      sim <- scheduleEvent(sim, time(sim), "fireCastor", "numberOfIgnitions", 14)
      sim <- scheduleEvent(sim, time(sim), "fireCastor", "areaBurned", 15)
      sim <- scheduleEvent(sim, time(sim), "fireCastor", "calculateProbEscapeSpread", 16)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor") , "fireCastor", "simulateFireStarts", 5)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor") , "fireCastor", "simulateFireSpread", 5)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor") , "fireCastor", "saveFireRasters", 6)
        },
      
getStaticFireVariables = {
      sim <- getStaticVariables(sim) # create table with static fire variables to calculate probability of ignition, escape, spread. Dont reschedule because I only need this once
},

roadDistanceCalc ={
  sim <- roadDistCalc(sim) 
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


calculateProbEscapeSpread = {
      sim <- calcProbEscapeSpread(sim) 
      sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor") , "fireCastor", "calculateProbEscapeSpread", 16)
},

downScaleTo10Km = {
  sim <- downScaleData(sim)
  sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor") , "fireCastor", "downScaleTo10Km", 13)
},

numberOfIgnitions = {
    switch(P(sim)$ignitionMethod,
           poissonProcess={ # using Kyles inhomogeneous poisson process model
             sim <- poissonProcessModel(sim)
           },
           
           historicalDist={ # Number of ignitions are sampled off a historical distribution
             sim <- historicalNumberStarts(sim) 
           },
           
           static={ # user defined number of ignitions
             sim <-staticNumberStart(sim)
             
           },
    )
  sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor"), "fireCastor", "numberOfIgnitions",14)
},

areaBurned = {
  sim<-fireSize(sim)
  sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor"), "fireCastor", "areaBurned", 15)
},

simulateFireStarts = {
  sim<-ignitLocations(sim)
  sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor"), "fireCastor", "simulateFireStarts", 5)
  },

simulateFireSpread = {
  sim<-spreadProcess(sim)
  sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor"), "fireCastor", "simulateFireSpread", 5)
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
#   #constant coefficients
#   ras.ignitlightning<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
#                                      srcRaster= P(sim, "nameStaticLightningIgnitRaster", "fireCastor"), 
#                                      clipper=sim$boundaryInfo[1] , 
#                                      geom= sim$boundaryInfo[4] , 
#                                      where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
#                                      conn=NULL))
#   if(terra::ext(sim$ras) == terra::ext(ras.ignitlightning)){
#     ignit_lightning_static<-data.table(ignitstaticlightning = as.numeric(ras.ignitlightning[]))
#     ignit_lightning_static[, pixelid := seq_len(.N)][, ignitstaticlightning := as.numeric(ignitstaticlightning)]
#     ignit_lightning_static<-ignit_lightning_static[ignitstaticlightning > -200, ]
#     }else{
#       stop(paste0("ERROR: extents are not the same check -", P(sim, "nameStaticLightningIgnitRaster", "fireCastor")))
# }
# 
#     # ignition human    
#     ras.ignithuman<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
#                                                   srcRaster= P(sim, "nameStaticHumanIgnitRaster", "fireCastor"), 
#                                                   clipper=sim$boundaryInfo[1] , 
#                                                   geom= sim$boundaryInfo[4] , 
#                                                   where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
#                                                   conn=NULL))
#     if(terra::ext(sim$ras) == terra::ext(ras.ignithuman)){
#       ignit_human_static<-data.table(ignitstatichuman = as.numeric(ras.ignithuman[]))
#       ignit_human_static[, pixelid := seq_len(.N)][, ignitstatichuman := as.numeric(ignitstatichuman)]
#       ignit_human_static<-ignit_human_static[ignitstatichuman > -200, ]
#     }else{
#       stop(paste0("ERROR: extents are not the same check -", P(sim, "nameStaticHumanIgnitRaster", "fireCastor")))
#     }
#     
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
        # ras.spread<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
        #                                               srcRaster= P(sim, "nameStaticSpreadRaster", "fireCastor"), 
        #                                               clipper=sim$boundaryInfo[1] , 
        #                                               geom= sim$boundaryInfo[4] , 
        #                                               where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
        #                                               conn=NULL))
        # if(terra::ext(sim$ras) == terra::ext(ras.spread)){
        #   spread_static<-data.table(spreadstatic = as.numeric(ras.spread[]))
        #   spread_static[, pixelid := seq_len(.N)][, spreadstatic := as.numeric(spreadstatic)]
        #   spread_static<-spread_static[spreadstatic > -200, ]
        # }else{
        #   stop(paste0("ERROR: extents are not the same check -", P(sim, "nameStaticSpreadRaster", "fireCastor")))
        # }
        
    # fire_static<-merge(ignit_lightning_static,ignit_human_static, by.x="pixelid", by.y="pixelid", all.x=TRUE)
    # fire_static<-merge(fire_static,escape_static, by.x="pixelid", by.y="pixelid", all.x=TRUE)
 #   fire_static<-merge(fire_static,spread_static, by.x="pixelid", by.y="pixelid", all.x=TRUE)
    sim$fire_static<-merge(escape_static, sim$frt_id, by.x="pixelid", by.y="pixelid", all.x=TRUE)
    
    #add to the castordb
    # dbBegin(sim$castordb)
    # rs<-dbSendQuery(sim$castordb, "INSERT INTO firevariables (pixelid, frt, ignitstaticlightning, ignitstatichuman, escapestatic, spreadstatic) values (:pixelid, :frt, :ignitstaticlightning, :ignitstatichuman, :escapestatic, :spreadstatic)", fire_static)
    # dbClearResult(rs)
    # dbCommit(sim$castordb)
  
    rm(ras.escape, escape_static)
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
  
  #### TO DO: fix GCM run ####
  #I need to think about how to incorporate the different GCM runs in here. i.e. each GCM has several runs. What should I do about this.  
  
   
   id_vals<-data.table(dbGetQuery(sim$castordb, paste0("SELECT pixelid, pixelid_climate FROM pixels")))
   
   #id_vals2<-merge(climate_dat_no1)
   
   dat<-data.table(dbGetQuery(sim$castordb, paste0("SELECT * FROM climate_", P(sim, "gcmname", "climateCastor"),"_",P(sim, "ssp", "climateCastor"), " WHERE period=", time(sim)*P(sim, "calculateInterval", "fireCastor") + P(sim, "simStartYear", "fireCastor") , " AND run == 'r10i1p1f1'", ";")))
   #sim$run
   
   sim$clim<-merge(dat, id_vals, by.x = "pixelid_climate", by.y ="pixelid_climate", all.y=TRUE )
   
   clim_dat<-merge(sim$clim, sim$frt_id, by.x="pixelid", by.y="pixelid")
   #clim_dat<-clim_dat[, cmi_min:= do.call(pmin, .SD),.SDcols=c("cmi05", "cmi06","cmi07","cmi08") ]
   
   ## escape caused fires
   clim_dat[frt %in% c(5, 7), climate1escape:=(tmax04+tmax05)/2]
   clim_dat[frt %in% c(5, 7), climate2escape:=(ppt04+ppt05)/2]
   clim_dat[frt==10, climate1escape:=(cmd04+cmd05+cmd06)/3]
   clim_dat[frt %in% c(9,11), climate1escape:=(cmi04 + cmi05 + cmi06 + cmi07)/4]
   #clim_dat[frt==11, climate2escape:=PPT05]
   clim_dat[frt==12, climate1escape:=(tmax04+tmax05+tmax06)/3]
   clim_dat[frt==12, climate2escape:=(ppt04+ppt05+ppt06)/3]
   clim_dat[frt==13, climate1escape:=(tmax07+tmax08)/2]
   clim_dat[frt==13, climate2escape:=(ppt07+ppt08)/2]
   clim_dat[frt==14, climate1escape:=(tmax04+tmax05+tmax06)/3]
   clim_dat[frt==14, climate2escape:=(ppt04+ppt05+ppt06)/3]
   clim_dat[frt==15, climate1escape:=(cmd07 +cmd08)/2]
   
   # spread
   clim_dat[frt==5, climate1spread:=(tmax06+tmax07+tmax08)/3]
   clim_dat[frt==5, climate2spread:=(ppt06+ppt07+ppt08)/3]
   
   
  sim$climate_data<-clim_dat[ ,c("pixelid","gcm", "ssp", "run","period","cmi", "cmi3yr", "climate1escape", "climate2escape", "climate1spread", "climate2spread")]
  
  
   return(invisible(sim))
   
  }
   

createVegetationTable <- function(sim) {
  
  message("get vegetation data from the VRI")
  
  # Get bec zone and bec subzone if is not in VRI table
  
  if(!(P(sim, "nameBecRast", "fireCastor") == "99999")){
  
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
  } else {
    message("BEC info in VRI")
  }


  #**************FOREST INVENTORY - VEGETATION VARIABLES*******************#
  #----------------------------#
  #----Set forest attributes----
  #----------------------------#
  if(!P(sim, "nameForestInventoryRaster","fireCastor") == '99999'){
    message("clipping inventory key")
    ras.fid<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                       srcRaster= P(sim, "nameForestInventoryRaster", "fireCastor"), 
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
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameForestInventoryRaster", "fireCastor")))
    }
    
    
    if(!P(sim, "nameForestInventoryTable2","fireCastor") == '99999'){ #Get the forest inventory variables 
      
      fuel_attributes_castordb<-sapply(c('bclcs_level_1', 'bclcs_level_4', 'bec_zone_code', 'species_cd_1','species_pct_1','species_cd_2', 'species_pct_2', 'species_cd_3', 'species_pct_3', 'species_cd_4', 'species_pct_4', 'species_cd_5', 'species_pct_5', 'species_cd_6', 'species_pct_6'), function(x){
        if(!(P(sim, paste0("nameForestInventory", x), "fireCastor") == '99999')){
          return(paste0(P(sim, paste0("nameForestInventory", x), "fireCastor"), " as ", tolower(x)))
        }else{
          message(paste0("WARNING: Missing parameter nameForestInventory", x, " ---Defaulting to NA"))
        }
      })
      
      fuel_attributes_castordb<-Filter(Negate(is.null), fuel_attributes_castordb) #remove any nulls
      
      if(length(fuel_attributes_castordb) > 0){
        print(paste0("getting inventory attributes to create fuel types: ", paste(fuel_attributes_castordb, collapse = ",")))
        fids<-unique(inv_id[!(is.na(fid)), fid])
        attrib_inv<-data.table(getTableQuery(paste0("SELECT " , P(sim, "nameForestInventoryKey", "fireCastor"), " as fid, ", paste(fuel_attributes_castordb, collapse = ","), " FROM ",P(sim, "nameForestInventoryTable2","fireCastor"), " WHERE ", P(sim, "nameForestInventoryKey", "fireCastor") ," IN (",
                                                    paste(fids, collapse = ","),");" )))
        
        
        message("...merging with fid") #Merge this with the raster using fid which gives you the primary key -- pixelid
        inv<-merge(x=inv_id, y=attrib_inv, by.x = "fid", by.y = "fid", all.x = TRUE) 
        inv<-inv[, fid:=NULL] # remove the fid key
        
        inv<-merge(x=inv, y=bec, by.x="pixelid", by.y="pixelid", all.x=TRUE)
        
        message("calculating % conifer")
        
        conifer<-c("C","CW","Y","YC","F","FD","FDC","FDI","B","BB","BA","BG","BL","H","HM","HW","HXM","J","JR","JS","P","PJ","PF","PL","PR","PLI","PXJ","PY","PLC","PW","PA","S","SB","SE","SS","SW","SX","SXW","SXL","SXS","T","TW","X", "XC","XH", "ZC")
        
        inv[, pct1:=0][species_cd_1 %in% conifer, pct1:=species_pct_1]
        inv[, pct2:=0][species_cd_2 %in% conifer, pct2:=species_pct_2]
        inv[, pct3:=0][species_cd_3 %in% conifer, pct3:=species_pct_3]
        inv[, pct4:=0][species_cd_4 %in% conifer, pct4:=species_pct_4]
        inv[, pct5:=0][species_cd_5 %in% conifer, pct5:=species_pct_5]
        inv[, pct6:=0][species_cd_6 %in% conifer, pct6:=species_pct_6]
           
        #determing total percent cover of conifer species
        inv[,conifer_pct_cover_total:=pct1+pct2+pct3+pct4+pct5+pct6]
        inv[!is.na(species_cd_1) & is.na(conifer_pct_cover_total), conifer_pct_cover_total:=0]
        
        # remove extra unneccesary columns
        inv<-inv[, c("species_cd_3", "species_cd_4", "species_cd_5", "species_cd_6", "species_pct_3", "species_pct_4", "species_pct_5", "species_pct_6","pct1", "pct2", "pct3", "pct4", "pct5", "pct6"):=NULL] 
        
        sim$inv<-inv
        
        rm(inv_id, attrib_inv)
        gc()
    
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
  
message("getting vegetation data")

  veg_attributes<- data.table(dbGetQuery(sim$castordb, "SELECT pixelid, basalarea, age, height,  blockid FROM pixels"))
  
  veg2<-merge(sim$inv, veg_attributes, by.x="pixelid", by.y = "pixelid", all.x=TRUE)
  
  veg2[height >= 4 & basalarea >= 8 & bclcs_level_4 == "TC", veg_cat:=1]
  veg2[height >= 4 & basalarea >= 8 & bclcs_level_4 == "TM", veg_cat:=2]
  veg2[height >= 4 & basalarea >= 8 & bclcs_level_4 == "TB", veg_cat:=3]
  veg2[((height < 4 | basalarea < 8 | is.na(height ) | is.na(basalarea)) & bclcs_level_4 %in% c("TC", "TM", "TB")), veg_cat:=4]
  veg2[bclcs_level_1 == 'V' & !bclcs_level_4 %in% c("TC", "TM", "TB"), veg_cat:=5]
  veg2[bclcs_level_1 != 'V', veg_cat:=6] # & (is.na(basalarea) | basalarea < 8)
  
  veg2[is.na(veg_cat), veg_cat:=0]
  
  rm(veg_attributes)
  gc()
  
  sim$veg2<-veg2

  return(invisible(sim)) 
  
}

calcProbEscape<-function(sim){
  
  
  #### UPDATE FROM HERE ####
 
  
  dat<-merge(sim$veg2, sim$climate_data, by.x="pixelid", by.y="pixelid", all.x=TRUE)
  dat<-merge(dat, sim$road_distance, by.x="pixelid", by.y="pixelid", all.x=TRUE)
  #dat<-merge(dat, sim$elev, by.x="pixelid", by.y="pixelid", all.x=TRUE)
  
  dat<-merge(dat,sim$fire_static, all.x=TRUE)
  
  message("get coefficient table")
  
  dat<-data.table(dat)
  
  sim$dat<-dat

  dat[climate1escape ==-9999, climate1escape:=NA]
  dat[climate2escape ==-9999, climate2escape:=NA]
  dat[climate1spread ==-9999, climate1spread :=NA]
  dat[climate2spread ==-9999, climate2spread :=NA]
  
  dat[,veg_cat2:=0][veg_cat==2, veg_cat2:=1]
  dat[,veg_cat3:=0][veg_cat==3, veg_cat3:=1]
  dat[,veg_cat4:=0][veg_cat==4, veg_cat4:=1]
  dat[,veg_cat5:=0][veg_cat==5, veg_cat5:=1]
  
  #---------#
  #### FRT 5  ####
  #---------#
  if (nrow(dat[frt %in% c(5,7),])>0) {
  frt57<- dat[frt %in% c(5,7), ]
  head(frt57)
     
  # Fire Escape
 # model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt5_escape.csv")
  
  # change veg categories to ones that we have coefficients
  
  frt57[, logit_P_escape := -0.3739924 +
         -0.02523745*climate2 +
         0.3501348*veg_cat2 +
         0.9389967*veg_cat3 +
         0.5863252*veg_cat4 +
         -2.753341*veg_cat5 + 
         0.01888822*conifer_pct_cover_total +
         -0.006227998*age +
         5.430062e-05*dist_infra +
         -0.02353765*veg_cat2*conifer_pct_cover_total+
         -0.03563329*veg_cat3*conifer_pct_cover_total+
         -0.004787786*veg_cat4*conifer_pct_cover_total+
         0.02868299*veg_cat5*conifer_pct_cover_total]
         
       
  frt57[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
  frt57[veg_cat==6, prob_ignition_escape:=0]

  
  frt57<-frt57[, c("pixelid","frt","prob_ignition_escape")]
  
  } else {
    
    print("no data for FRT 5")
    
    frt57<-data.table(pixelid=as.numeric(),
                     frt = as.numeric(),
                     prob_ignition_escape = as.integer())
  }
  
  
  #### FRT9 #### 
  if (nrow(dat[frt %in% c(9,11),])>0) {
    frt9<- dat[frt %in% c(9,11),]
    
  # Fire Escape
#  model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt11_escape.csv")
         
# Note FRT 9 and FRT 11 were combined due to lack of data         
  frt9[, logit_P_escape := 
         -4.028508 +
         -0.07285105*climate1 +
         0.04077977 * slope +
         0.305426*log(rds_dist+1)+
         5.938547e-05*dist_infra] 
         
  frt9[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
  frt9[veg_cat==6, prob_ignition_escape:=0]
         

  frt9<-frt9[, c("pixelid","frt", "prob_ignition_escape")]
  } else {
    
    print("no data for FRT 9")
    
    frt9<-data.table(pixelid=as.numeric(),
                     frt = as.numeric(), 
                     prob_ignition_escape = as.integer())
    
      
  }
  
  #### FRT10 #### 
  if (nrow(dat[frt==10,])>0) {
    frt10<- dat[frt==10,]
    # categorizing all treed areas into the same category because there were no treed area in the categories 2 and 3 in actual data
    #frt10[veg_cat %in% c(2,3), veg_cat:=1]
    
    frt10[pixelid>0, all:=1]
    
      #    # Fire Escape
   #  model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt10_escape.csv")
         
    frt10[, logit_P_escape := -3.010075 +
            0.06581443*climate1 + 
            1.555569*veg_cat4 + 
            0.9485711*veg_cat5 + 
            7.568074e-05*rds_dist +
            -0.08912795*veg_cat4*climate1 +
            -0.0457739*veg_cat5*climate1
          ]
         
         frt10[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
         frt10[veg_cat %in% c("0", "6"),prob_ignition_escape:=0]
         
         # Spread

         spread_10<-readRDS("C:/Work/caribou/castor/R/fire_sim/tmp/frt10.rds")
            
    # frt10[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
    
    
    # frt10[, prob_tot_ignit := (as.numeric(prob_ignition_lightning)*0.86) + (as.numeric(prob_ignition_person)*0.14)]
    # 
    # frt10[fwveg %in% c("W", "N"), prog_tot_ignit:=0]
    # frt10[fwveg %in% c("W", "N"),prob_ignition_lightning:=0]
    # frt10[fwveg %in% c("W", "N"),prob_ignition_person:=0]
    
  
    
    frt10<-frt10[, c("pixelid","frt", "prob_ignition_escape")]
  } else {
    
    print("no data for FRT 10")
    
    frt10<-data.table(pixelid=as.numeric(),
                      frt = as.numeric(),
                     prob_ignition_escape = as.integer())
    
    
  }

  #### FRT11 #### 
  if (nrow(dat[frt==11,])>0) {
    frt11<- dat[frt==11,]
    
    # Fire Escape
 #   model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt11_escape.csv")
    
    frt11[, logit_P_escape := -4.028508 +
            -0.07285105 * climate1 +
            0.04077977 * slope + 
            0.305426 * log(rds_dist + 1) +
            5.938547e-05 * dist_infra
            ]
    
    frt11[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
    
    frt11[veg_cat %in% c(1,6),prob_ignition_escape:=0 ]
    
    # Spread
#   model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt11_spread.csv")
    

  frt11<-frt11[, c("pixelid","frt", "prob_ignition_escape")]  
  } else {
    
    print("no data for FRT 11")
    
    frt11<-data.table(pixelid = as.integer(),
                      frt = as.numeric(),
                     prob_ignition_escape = as.integer())
  }
  
  #### FRT12  #### 
  if (nrow(dat[frt==12,])>0) {
    frt12<- dat[frt==12,]
    
    frt12[pixelid>0, all:=1]
    frt12[veg_cat==3,veg_cat2:=1]
    

    # Fire Escape
#   model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt12_escape.csv")
   
  frt12[, logit_P_escape := -2.841366 +
          -0.05367503 * climate2 + 
          -3.693762 * veg_cat2 +
          -1.347356 * veg_cat4 +
          -0.6306343 * veg_cat5 +
          0.0006987995 *elevation +
          0.000150056 * rds_dist +
          0.3306912 * log(dist_infra+1) +
          0.06785558* climate2 * veg_cat2 +
          0.04002989* climate2 * veg_cat4 +
          0.02299421* climate2 * veg_cat5]
  
    frt12[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
    frt12[veg_cat %in% c(0,6), prob_ignition_escape:=0]
    
    # Spread
#    model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt12_spread.csv")
    
    # 
    # frt12[, logit_P_spread := spreadstatic * all + 
    #         sim$coefficients[cause == 'spread' & frt==12,]$coef_climate_2 * climate2spread +
    #         sim$coefficients[cause == 'spread' & frt==12,]$coef_c2 * veg_C2 +
    #         sim$coefficients[cause == 'spread' & frt==12,]$coef_c3 * veg_C3 +
    #         sim$coefficients[cause == 'spread' & frt==12,]$coef_c4 * veg_C4 +
    #         sim$coefficients[cause == 'spread' & frt==12,]$coef_c5 * veg_C5 +
    #         sim$coefficients[cause == 'spread' & frt==12,]$coef_c7 * veg_C7 +
    #         sim$coefficients[cause == 'spread' & frt==12,]$coef_d12 * veg_D12 +
    #         sim$coefficients[cause == 'spread' & frt==12,]$coef_m12 * veg_M12 +
    #         sim$coefficients[cause == 'spread' & frt==12,]$coef_m3 * veg_M3 +
    #         sim$coefficients[cause == 'spread' & frt==12,]$coef_N * veg_N +
    #         sim$coefficients[cause == 'spread' & frt==12,]$coef_o1ab * veg_O1ab +
    #         sim$coefficients[cause == 'spread' & frt==12,]$coef_s1 * veg_S1 +
    #         sim$coefficients[cause == 'spread' & frt==12,]$coef_s2 * veg_S2 +
    #         sim$coefficients[cause == 'spread' & frt==12,]$coef_log_road_dist * log(rds_dist+1)]
    # 
    # frt12[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
    

    
    frt12<-frt12[, c("pixelid","frt", "prob_ignition_escape")]    
  } else {
    
    print("no data for FRT 12")
    
    frt12<-data.table(pixelid = as.numeric(),
                      frt = as.numeric(), 
                     prob_ignition_escape = as.integer())
    
  }
  
  #### FRT13  #### 
  if (nrow(dat[frt==13,])>0) {
    frt13<- dat[frt==13,]
    
    frt13[bec_zone_code=="SBPS", bec_zone_code:="SBS"]
    frt13[bec_zone_code=="BWBS", bec_zone_code:="IDF"]
    frt13[bec_zone_code=="BAFA", bec_zone_code:="CMA"]
    frt13[bec_zone_code=="IMA", bec_zone_code:="CMA"]
    frt13[bec_zone_code=="MH", bec_zone_code:="CWH"]
    
    frt13<-cbind(frt13, model.matrix( ~ 0 + bec_zone_code, data=frt13 )) #add in the indicator structure for bec_zone_code
    
    # Fire Escape
 #  model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt13_escape.csv")
    
    frt13[, logit_P_escape := -8.041024 +
            -0.009703917 * climate2 +
            1.127389 * bec_CWH +
            1.158745 * bec_ESSF +
            0.6964435 * bec_ICH +
            -1.101433 * bec_IDF +
            1.085356 * bec_MS +
            0.9982373 * bec_SBS +
            0.04032754 * slope +
            0.0003744881 * elevation + 
            0.1916564 * aspect_O +
            0.6570631 + aspect_S +
            0.5035446 + log(dist_infra+1)]
    
    frt13[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
    frt13[veg_cat %in% c(0,6), prob_ignition_escape:=0]
    
    # Spread
 #   model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt13_spread.csv")
    
    # frt13[, veg_C2 := 0]
    # frt13[fwveg == "C-2", veg_C2 := 1]
    # frt13[, veg_C3 := 0]
    # frt13[fwveg == "C-3", veg_C3 := 1]
    # 
    # frt13[fwveg == "C-1", veg_C3 :=1]
    # 
    # frt13[, logit_P_spread := spreadstatic * all + 
    #         sim$coefficients[cause == 'spread' & frt==13,]$coef_climate_2 * climate2spread +
    #         sim$coefficients[cause == 'spread' & frt==13,]$coef_c3 * veg_C3 +
    #         sim$coefficients[cause == 'spread' & frt==13,]$coef_c5 * veg_C5 +
    #         sim$coefficients[cause == 'spread' & frt==13,]$coef_c7 * veg_C7 +
    #         sim$coefficients[cause == 'spread' & frt==13,]$coef_d12 * veg_D12 +
    #         sim$coefficients[cause == 'spread' & frt==13,]$coef_m12 * veg_M12 +
    #         sim$coefficients[cause == 'spread' & frt==13,]$coef_m3 * veg_M3 +
    #         sim$coefficients[cause == 'spread' & frt==13,]$coef_N * veg_N +
    #         sim$coefficients[cause == 'spread' & frt==13,]$coef_o1ab * veg_O1ab +
    #         sim$coefficients[cause == 'spread' & frt==13,]$coef_s1 * veg_S1 +
    #         sim$coefficients[cause == 'spread' & frt==13,]$coef_s2 * veg_S2 +
    #         sim$coefficients[cause == 'spread' & frt==13,]$coef_s3 * veg_S3]
    # 
    # frt13[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
    
    frt13<-frt13[, c("pixelid", "frt", "prob_ignition_escape")]
    
  } else {
    
    print("no data for FRT 13")
    
    frt13<-data.table(pixelid=as.numeric(), 
                      frt = as.numeric(), 
                     prob_ignition_escape = as.integer())
    
    
  }  
  
  #### FRT14 #### 
  if (nrow(dat[frt==14,])>0) {
    frt14<- dat[frt==14,]
    
    frt14[bec_zone_code=="ESSF", bec_zone_code:="ICH"]
    escape_frt14[veg_cat=="3", veg_cat2:=1]
    
    frt14<-cbind(frt14, model.matrix( ~ 0 + bec_zone_code, data=frt14 ))
    
    # Fire Escape
#      model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt14_escape.csv")
      

   frt14[, logit_P_escape := -3.559506 +
           -0.02194852 * climate2 +
           -0.139658 * veg_cat2 +
           -0.004426213 * veg_cat4 +
           0.6245107 * veg_cat5 +
           0.0008269012 * elevation +
           0.3923424 * log(dist_infra+1) +
           -0.9131595 * bec_ICH +
           -1.584701 * bec_IDF +
           -1.443547 * bec_MS +
           -1.051235 * bec_PP +
           -0.4199083 * bec_SBPS +
           -1.161136 * bec_SBS]
    
    frt14[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
    frt14[veg_cat %in% c(0,6), prob_ignition_escape:=0]
    
    # Spread
#       model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt14_spread.csv")
       
    #    frt14[fwveg == "S-2", veg_C7 :=1]
    #    frt14[fwveg == "C-4", veg_C2 :=1]
    #    frt14[fwveg == "S-3", veg_M12 :=1]
    #    
    #    
    # frt14[, logit_P_spread := spreadstatic * all + 
    #         sim$coefficients[cause == 'spread' & frt==14,]$coef_climate_2 * climate2spread +
    #         sim$coefficients[cause == 'spread' & frt==14]$coef_c3 * veg_C3 +
    #         sim$coefficients[cause == 'spread' & frt==14,]$coef_c5 * veg_C5 +
    #         sim$coefficients[cause == 'spread' & frt==14,]$coef_c7 * veg_C7 +
    #         sim$coefficients[cause == 'spread' & frt==14,]$coef_d12 * veg_D12 +
    #         sim$coefficients[cause == 'spread' & frt==14,]$coef_m12 * veg_M12 +
    #         sim$coefficients[cause == 'spread' & frt==14,]$coef_N * veg_N +
    #         sim$coefficients[cause == 'spread' & frt==14,]$coef_o1ab * veg_O1ab +
    #         sim$coefficients[cause == 'spread' & frt==14,]$coef_s1 * veg_S1 +
    #         sim$coefficients[cause == 'spread' & frt==14,]$coef_road_dist * rds_dist]
    # 
    # frt14[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
    
    frt14<-frt14[, c("pixelid","frt","prob_ignition_escape")]
    
  } else {
    
    print("no data for FRT 14")
    
    frt14<-data.table(pixelid= as.numeric(),
                      frt = as.numeric(), 
                     prob_ignition_escape = as.integer())
  } 
  
  #### FRT15 #### 
  if (nrow(dat[frt==15,])>0) {
    frt15<- dat[frt==15,]
    
    frt15[veg_cat==3, veg_cat2:=1]
    frt15<-cbind(frt15, model.matrix( ~ 0 + bec_zone_code, data=frt15))
    
    # Fire Escape
#    model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt15_escape.csv")
    
    frt15[, logit_P_escape := -12.87904 +
            0.02153108*climate1 +
            -6.180944*veg_cat2 +
            0.6523298*veg_cat4 +
            -0.6588419*veg_cat5 +
            5.430646*aspect_O +
            4.668458 *aspect_S +
            0.4129819*log(dist_infra+1) +
            0.2966214*bec_CWH +
            -0.3610074*bec_MH
            ]
    
    frt15[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
    
    # Spread
#    model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt15_spread.csv")
    
# 
#     frt15[fwveg == "C-2", veg_C3 :=1]
#     frt15[fwveg == "M-3", veg_O1ab :=1]
#     
#     frt15[, logit_P_spread := spreadstatic * all + 
#             sim$coefficients[cause == 'spread' & frt==15,]$coef_climate_1 * climate1spread +
#             sim$coefficients[cause == 'spread' & frt==15,]$coef_climate_2 * climate2spread +
#             sim$coefficients[cause == 'spread' & frt==15]$coef_c5 * veg_C5 +
#             sim$coefficients[cause == 'spread' & frt==15,]$coef_c7 * veg_C7 +
#             sim$coefficients[cause == 'spread' & frt==15,]$coef_d12 * veg_D12 +
#             sim$coefficients[cause == 'spread' & frt==15,]$coef_m12 * veg_M12 +
#             sim$coefficients[cause == 'spread' & frt==15,]$coef_N * veg_N +
#             sim$coefficients[cause == 'spread' & frt==15,]$coef_o1ab * veg_O1ab +
#             sim$coefficients[cause == 'spread' & frt==15,]$coef_s3 * veg_S3]
#     
#     frt15[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
    
    frt15[, prob_tot_ignit := (prob_ignition_lightning*0.3) + (prob_ignition_person*0.7)]
    
    frt15[fwveg %in% c("W", "N"), prog_tot_ignit:=0]
    frt15[fwveg %in% c("W", "N"),prob_ignition_lightning:=0]
    frt15[fwveg %in% c("W", "N"),prob_ignition_person:=0]
    frt15[fwveg %in% c("W", "N"),prob_ignition_escape:=0]
    
    
    frt15<-frt15[, c("pixelid","frt","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_tot_ignit")]    
  } else {
    
    print("no data for FRT 15")
    
    frt15<-data.table(pixelid = as.numeric(),
                      frt = as.numeric(),
                      prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(), 
                     prob_ignition_escape = as.integer(),
                     prob_tot_ignit = as.integer())
  } 
  
  
  #### rbind frt data ####
  
  probFireRast<- do.call("rbind", list(frt5, frt7, frt9, frt10, frt11, frt12, frt13, frt14, frt15))
  
  sim$probFireRasts<-merge(sim$veg3, probFireRast, by.x="pixelid", by.y="pixelid", all.x=TRUE)
  
  sim$probFireRasts<-data.table(sim$probFireRasts)
  
  print("number of NA values in probFireRasts$prob_ignition_lightning")
  print(table(is.na(sim$probFireRasts$prob_ignition_lightning)))
  
  
  return(invisible(sim))
}


downScaleData<-function(sim){
  
  message("get spatial varying intercept")
  sim$ras.m8<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                         srcRaster= P(sim, "m8_est_rf", "fireCastor"), #rast.m8_est_rf",
                                         clipper=sim$boundaryInfo[1] , 
                                         geom= sim$boundaryInfo[4] , 
                                         where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                         conn=NULL))
  
  message("Change resolution of pixels to 10 x 10km")
  
  ### FRT
  ras.frt.10km<-terra::crop(terra::aggregate(sim$ras.frt, fact = 100, fun = modal ),sim$ras.m8) 
  ### vegetation
  sim$veg2<-sim$veg2[order(pixelid)]
  
  # create area raster
  ras.info<-dbGetQuery(sim$castordb, "Select * from raster_info limit 1;")
  ras.haz<-terra::rast(nrows=ras.info$nrow, ncols = ras.info$ncell/ras.info$nrow, xmin=ras.info$xmin, xmax=ras.info$xmax, ymin=ras.info$ymin, ymax=ras.info$ymax)
  
  message("vegetation and flammable categories")
  ras.haz[]<-sim$veg2$veg_cat
  ras.haz[is.na(ras.haz[])]<-0
  #ras.haz<-terra::rast(ras.haz)
  
  ras1<-ras.haz
  ras1[ras1[] > 1 ]<-0
  ras.fuel1<-terra::crop(terra::aggregate(ras1, fact = 100, fun = sum ),sim$ras.m8) # area coniferous
  
  ras3<-ras.haz
  ras3[ras3[] != 3 ]<-0
  ras3[ras3[] == 3 ]<-1
  ras.fuel3<-terra::crop(terra::aggregate(ras3, fact = 100, fun = sum ),sim$ras.m8) # area decidious
  
  ras4<-ras.haz
  ras4[ras4[] != 4 ]<-0
  ras4[ras4[] == 4 ]<-1
  ras.fuel4<-terra::crop(terra::aggregate(ras4, fact = 100, fun = sum ),sim$ras.m8) # area young
  
  ras.flam<-ras.haz
  ras.flam[ras.flam[] %between% c(1,5)]<-1
  ras.flam[ras.flam[] == 6 ]<-0
  ras.flammable<-terra::crop(terra::aggregate(ras.flam, fact = 100, fun = sum ),sim$ras.m8)
  
  # Climate
  message("get provincial meanCMI")
  
  Prov_CMI<-data.table(dbGetQuery(sim$castordb, paste0("SELECT * FROM climate_provincial_", tolower(P(sim, "gcmname", "climateCastor")),"_",P(sim, "ssp", "climateCastor"), " WHERE period=", time(sim)*(P(sim, "calculateInterval", "fireCastor")) + P(sim, "simStartYear", "fireCastor") , ";")))
  
  message("get climate for aoi")
  
  sim$clim<-sim$clim[, cmi_min:= do.call(pmin, .SD),.SDcols=c("cmi05", "cmi06","cmi07","cmi08") ]
  
  sim$clim<-sim$clim[, `:=`(PPT_sm = rowSums(.SD, na.rm=T)), .SDcols=c("ppt05", "ppt06","ppt07","ppt08")]
  
  sim$clim<-sim$clim[, TEMP_MAX:= do.call(pmax, .SD),.SDcols=c("tmax05","tmax06","tmax07","tmax08") ]
  
  sim$clim<-sim$clim[order(pixelid)]
  
  # create climate rasters at 10x10km scale
  ras.haz[]<-sim$clim$cmi
  ras.cmi<-ras.haz
  ras.cmi.10km<-terra::crop(terra::aggregate(ras.cmi, fact = 100, fun = mean ),sim$ras.m8)
  
  ras.haz[]<-sim$clim$cmi3yr
  ras.cmi3yr<-ras.haz
  ras.cmi3yr.10km<-terra::crop(terra::aggregate(ras.cmi3yr, fact = 100, fun = mean ),sim$ras.m8)
  
  ras.haz[]<-sim$clim$cmi_min
  ras.cmi_min<-ras.haz
  ras.cmi_min.10km<-terra::crop(terra::aggregate(ras.cmi_min, fact = 100, fun = mean ),sim$ras.m8)
  
  ras.haz[]<-sim$clim$TEMP_MAX
  ras.TEMP_MAX<-ras.haz
  ras.TEMP_MAX.10km<-terra::crop(terra::aggregate(ras.TEMP_MAX, fact = 100, fun = mean ),sim$ras.m8)
  
  ras.haz[]<-sim$clim$PPT_sm
  ras.PPT_sm<-ras.haz
  ras.PPT_sm.10km<-terra::crop(terra::aggregate(ras.PPT_sm, fact = 100, fun = mean ),sim$ras.m8)
  
  ras.m8<-terra::crop(sim$ras.m8, ras.cmi_min.10km)
  
  sim$downdat <- data.table(frt = ras.frt.10km [], est_rf = ras.m8 [], CMI = ras.cmi.10km [], CMI_MIN = ras.cmi_min.10km[], CMI3YR = ras.cmi3yr.10km [], PPT_sum = ras.PPT_sm.10km [], TEMP_MAX = ras.TEMP_MAX.10km [], con = ras.fuel1 [], young = ras.fuel4 [], dec = ras.fuel3 [], flammable = ras.flammable [])[, pixelid10km := seq_len(.N)][, year := Prov_CMI$period[1]]
  
  sim$downdat[, frt5:=0][frt.layer==5, frt5:=1]
  sim$downdat[, frt7:=0][frt.layer==7, frt7:=1]
  sim$downdat[, frt9:=0][frt.layer==9, frt9:=1]
  sim$downdat[, frt10:=0][frt.layer==10, frt10:=1]
  sim$downdat[, frt11:=0][frt.layer==11, frt11:=1]
  sim$downdat[, frt12:=0][frt.layer==12, frt12:=1]
  sim$downdat[, frt13:=0][frt.layer==13, frt13:=1]
  sim$downdat[, frt14:=0][frt.layer==14, frt14:=1]
  sim$downdat[, frt15:=0][frt.layer==15, frt15:=1]
  
  x<-unique(sim$clim[!is.na(cmi), "run" ])
  CMIrun<-unique(sim$clim$run)
  meanCMI<-Prov_CMI[run==x,"meanCMI"]
  
  sim$downdat[, avgCMIProv:=meanCMI]
  
  return(invisible(sim))
}
  
  poissonProcessModel<-function(sim){
  
  sim$downdat<-sim$downdat[ ,est:= exp(-17.0 -0.0576*CMI_MIN.lyr.1-0.124*(CMI.lyr.1-CMI3YR.lyr.1/3)-0.363*avgCMIProv  -0.979*frt5 -0.841*frt7 -1.55*frt9  -1.55*frt10  -1.03*frt11  -1.09*frt12 -1.34*frt13  -0.876*frt14  -2.36*frt15+ 0.495*log(con.lyr.1 + 1) + 0.0606 *log(young.lyr.1 + 1) -0.0256 *log(dec.lyr.1 + 1) +est_rf.layer  + log(flammable.lyr.1) )]
  
  #ras.test<-ras.m8
  #ras.test[]<-dat$est
  
  return(invisible(sim))
}

historicalNumberStarts<-function(sim){
  
  if(exists(sim$fit_g)){
    message("ignition number already parameterized with historical data")
  } else {
    library(bcdata)
    ignit<-try(
      bcdc_query_geodata("WHSE_LAND_AND_NATURAL_RESOURCE.PROT_HISTORICAL_INCIDENTS_SP") %>%
        dplyr::filter(FIRE_YEAR > 2008) %>%
        dplyr::filter(FIRE_TYPE == "Fire") %>%
        dplyr::filter(FIRE_CAUSE =="Lightning") %>%
        dplyr::filter(CURRENT_SIZE >= 1.0) %>%
        collect()
    )
    
    message("done")
    
    study_area<-getSpatialQuery(paste0("SELECT * FROM ", sim$boundaryInfo[[1]], " WHERE ", sim$boundaryInfo[[2]], " in ('", paste(sim$boundaryInfo[[3]], sep = " '", collapse= "', '") ,"')"))
    
    print(study_area)
    ignit <- ignit[study_area, ]
    
    message("...done")
    
    library(dplyr)
    
    data <- ignit %>% group_by(FIRE_YEAR) %>% summarize(n=n()) %>% mutate(freq=n/sum(n)) 
    
    sim$fit_g  <- fitdistrplus::fitdist(data$n, "gamma")
    
    #sim$min_ignit<-min(data$n)
    #sim$max_ignit<-max(data$n)
  }
  
  sim$no_ignitions<-round(rgamma(1, shape=sim$fit_g$estimate[1], rate=sim$fit_g$estimate[2]))
  
  return(invisible(sim))
}

staticNumberStart <- function(sim) {
  sim$no_starts <- P(sim, "numberStarts", "fireCastor")
  
  return(invisible(sim))
}

fireSize <- function(sim) {
  
  if (P(sim, "ignitionMethod", "fireCastor")== "historicalDist") {
    message("ignition # selected from historical distribution")
    sim$downdat[,est:=sim$no_ignitions]
  } else { 
    if (P(sim, "ignitionMethod", "fireCastor")== "static") {
      message("user defined number of ignitions")
      sim$downdat[,est:=sim$no_starts]
    } else {
      message("ignition # determined from poisson process model")
    }
    }
  
  sim$downdat[, mu1:= 2.158738 -0.001108*PPT_sum.lyr.1 -0.011496*CMI.lyr.1 + -0.719612*est  -0.020594*log(con.lyr.1 + 1)][, sigma1:=  1.087][ , mu2:= 2.645616 -0.001222*PPT_sum.lyr.1 + 0.049921*CMI.lyr.1 +1.918825*est -0.209590*log(con.lyr.1 + 1) ][, sigma2:= 0.27]
  
  sim$downdat[, pi2:=1/(1+exp(-1*(-0.1759469+ -1.374135*frt5-0.6081503*frt7-2.698864*frt9 -1.824072*frt10 -3.028758*frt11  -1.234629*frt12-1.540873*frt13-0.842797*frt14  -1.334035*frt15+ 0.6835479*avgCMIProv+0.1055167*TEMP_MAX.lyr.1 )))][,pi1:=1-pi2]
  
  #selected.seed<-sample(1:1000,1)
  #set.seed(selected.seed)
  sim$downdat<-sim$downdat[, fire:= rnbinom(n = 1, size = 0.416, mu =est), by=1:nrow(sim$downdat)][fire>0,]
  sim$downdat<-sim$downdat[ , k_sim:= sample(1:2,prob=c(pi1, pi2),size=1), by = seq_len(nrow(sim$downdat))]
  sim$downdat<-sim$downdat[k_sim==1, mu_sim := exp(mu1)][k_sim==1, sigma_sim := exp(sigma1)][k_sim==2, mu_sim := exp(mu2)][k_sim==2, sigma_sim := exp(sigma2)]
  
  browser()

  # aab<-data.table(aab = as.numeric())
  # for(f in 1:length(occ$fire)){
  #   fires<-rWEI3(occ$fire[f], mu = occ$mu_sim[f], sigma =occ$sigma_sim[f])
  #   sim$aab<- rbindlist(list(aab, data.table(aab = sum(exp(fires)))))
    #}

  return(invisible(sim))
}

ignitLocations <- function(sim) {
  
  #if (suppliedElsewhere(sim$probFireRasts)) {
  
  sim$probFireRasts<-sim$probFireRasts[order(pixelid)]
    probfire<-as.data.table(na.omit(sim$probFireRasts))
    #print(probfire)
    
    # create area raster
    ras.info<-dbGetQuery(sim$castordb, "Select * from raster_info limit 1;")
    sim$area<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0)
    
    
    sim$area[]<-sim$probFireRasts$prob_ignition_escape
    sim$area <- reclassify(sim$area, c(-Inf, 0, 0, 0, 1, 1))
    
    message("create escape raster")
    escapeRas<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0)
    escapeRas[] <- sim$probFireRasts$prob_ignition_escape
 # }
    
    
    #for (i in 1:numberFireReps) {
    message("get fire ignition locations")
    
    # sample more starting locations than needed and then discard extra after testing whether those locations actually ignite comparing its probability of igntion to a random number
    # get starting pixelids
    message("get pixelid of ignition locations")
    starts<-sample(probfire$pixelid, no_starts_sample, replace=FALSE)
    
    fire<-probfire[pixelid %in% starts,]
    fire$randomnumber<-runif(length(fire$pixelid))
    start<-fire[prob_ignition_escape>randomnumber, ]# change prob_ignition_escape to prob_tot_ignit if want to test ignition locations
    
    sim$sams  <-  sample(start$pixelid, size = no_ignitions)
    #random.starts1<-probfire[pixelid %in% random.starts,]
    
    # take top ignition points up to the number of (no_ignitions) discard the rest. 
    
    #random.starts1$randomnumber<-runif(nrow(random.starts1))
    #escaped fires
    #escape.pts<- random.starts1[prob_ignition_escape  > randomnumber, ]
    return(invisible(sim))
  }
  
  spreadProcess <- function(sim) {   
    
  #create prob spread
  dat<-merge(sim$veg3, sim$climate_data, by.x="pixelid", by.y="pixelid", all.x=TRUE)
  dat<-merge(dat, sim$road_distance, by.x="pixelid", by.y="pixelid", all.x=TRUE)
  dat<-merge(dat, mySim$frt_id, by.x="pixelid", by.y="pixelid", all.x=TRUE)

  #### Distance to ignition points ####
  xy_loc_ig<-sim$pts[pixelid %in% sim$sams, c("x", "y")]
  d<-distanceFromPoints(sim$area, xy_loc_ig)
  
  dat<-dat[order(pixelid)]
  dat<-cbind(dat, as.data.frame(d))
  colnames(dat)[colnames(dat) == "layer"] <- "rast_ignit_dist"
  
  
  ####elevation data####
  # check if there is elevation data in the pixels table, if not extract.
  if(dbGetQuery(sim$castordb, "SELECT MAX(elv) FROM pixels;")[1,1]>0) {
    elv<-dbGetQuery(sim$castordb, "SELECT pixelid, elv FROM pixels")
    } else {
    elv <- data.table(elv = RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                                       srcRaster = P(sim, "nameElevationRaster", "fireCastor"), 
                                                       clipper = sim$boundaryInfo[[1]],  # by the area of analysis (e.g., supply block/TSA)
                                                       geom = sim$boundaryInfo[[4]], 
                                                       where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                       conn = NULL)[])
      elv[,pixelid:=seq_len(.N)]#make a unique id to ensure it merges correctly
      #add to the castordb
      dbBegin(sim$castordb)
      rs<-dbSendQuery(sim$castordb, "Update pixels set elv = :elv where pixelid = :pixelid", elv)
      dbClearResult(rs)
      dbCommit(sim$castordb)
      
      
    }
    
dat<-merge(dat, elv, by.x="pixelid", by.y="pixelid", all.x=TRUE)

  #### FRT5 ####
  
if (nrow(dat[frt==5,])>0) {
frt5<-dat[frt==5,]
frt5$fwveg<-as.factor(frt5$fwveg)
  
  # To get the models to fit properly I had to scale the variables so Ill use the mean and sd that I got when i fitted to models to scale the new variables
  
  frt5$scale_climate2<-(frt5$climate2spread-79.15963)/15.56926
  frt5$scale_dem<-(frt5$elv-675.0221)/201.9468
  frt5$scale_roads<-(frt5$rds_dist-916.9191)/1797.046
  frt5$scale_dist_ignit<-(frt5$rast_ignit_dist-8086.005)/7167.049
  frt5_2<-frt5[!fwveg %in% c("N", "W"),]
  frt5_2<-frt5_2[, c("gcm", "ssp", "run", "period", "climate1lightning", "climate2lightning", "climate1person", "climate2person", "climate1escape", "climate2escape"):=NULL]
  
  m5<-readRDS("C:/Work/caribou/castor/R/fire_sim/tmp/frt5.rds")

  frt5_2$logit_P_spread <- predict(m5,frt5_2,re.form=NA)
  frt5_2[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
}
  else {
    
    print("no data for FRT 5")
    
    frt5<-data.table(pixelid=as.numeric(),
                     frt = as.numeric(),
                     prob_ignition_spread = as.integer())
  }
  
  #### FRT7####
  
  if (nrow(dat[frt==7,])>0) {
    frt7<-dat[frt==7,]
    frt7$fwveg<-as.factor(frt7$fwveg)
    
    # To get the models to fit properly I had to scale the variables so Ill use the mean and sd that I got when i fitted to models to scale the new variables
    
    frt7$scale_climate2<-(frt7$climate2spread-79.15963)/15.56926
    frt7$scale_dem<-(frt7$elv-675.0221)/201.9468
    frt7$scale_roads<-(frt7$rds_dist-916.9191)/1797.046
    frt7$scale_dist_ignit<-(frt7$rast_ignit_dist-8086.005)/7167.049
    frt7_2<-frt7[!fwveg %in% c("N", "W"),]
    frt7_2<-frt7_2[, c("gcm", "ssp", "run", "period", "climate1lightning", "climate2lightning", "climate1person", "climate2person", "climate1escape", "climate2escape"):=NULL]
    
    m5<-readRDS("C:/Work/caribou/castor/R/fire_sim/tmp/frt7.rds")
    
    frt7_2$logit_P_spread <- predict(m5,frt7_2,re.form=NA)
    frt7_2[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
  }
    else {
      
      print("no data for FRT 5")
      
      frt7<-data.table(pixelid=as.numeric(),
                       frt = as.numeric(),
                       prob_ignition_spread = as.integer())
    }
  
  # what needs to be done:
  # 1.)scale the variables using the mean and sd from the statistical analysis, 
  #2.)then pull in the rds and run the model. 
  #3.) extract the data from some of the static variable rasters.
  #4.) get distance to ignition point
  #5. Scale the spread models to get reasonable fire sizes
  
  
  
  #   frt5[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
  
    
    message("create spread raster")
    spreadRas<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0)
    spreadRas[]<-sim$probFireRasts$prob_ignition_spread
    
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
