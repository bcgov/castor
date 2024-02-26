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
      sim <- scheduleEvent(sim, time(sim), "fireCastor", "calculateProbIgnitEscape", 13)
      
      if (!suppliedElsewhere(sim$fit_g)) {
        sim <- numberStarts(sim) 
        #sim <- scheduleEvent(sim, time(sim), "fireCastor", "getIgnitionDistribution", 15)
      }
     
      #if (suppliedElsewhere(sim$probFireRasts)) {

     # sim$fireReport<-data.table(timeperiod= integer(), numberstarts = integer(), numberescaped = integer(), totalareaburned = integer(), thlbburned = integer())
      
     # sim$firedisturbanceTable<-data.table(scenario = scenario$name, numberFireReps = numberFireReps, pixelid = pts$pixelid, numberTimesBurned = as.integer(0))

        sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor") , "fireCastor", "simulateFireStarts", 5)
        sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor") , "fireCastor", "simulateFireSpread", 5)
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

calculateProbIgnitEscape = {
      sim <- calcProbIgnitEscape(sim) 
      sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor") , "fireCastor", "calculateProbIgnitEscape", 13)
},

getIgnitionDistribution = {
  sim <- numberStarts(sim) # create table with static fire variables to calculate probability of ignition, escape, spread. Dont reschedule because I only need this once
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
  
    rm(ras.ignitlightning, ignit_lightning_static, ras.ignithuman, ignit_human_static, ras.escape, escape_static)
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
   
   id_vals<-data.table(dbGetQuery(sim$castordb, paste0("SELECT pixelid, pixelid_climate FROM pixels")))
   
   #id_vals2<-merge(climate_dat_no1)
   
   dat<-data.table(dbGetQuery(sim$castordb, paste0("SELECT * FROM climate_", P(sim, "gcmname", "climateCastor"),"_",P(sim, "ssp", "climateCastor"), " WHERE period=", time(sim)*sim$updateInterval + P(sim, "simStartYear", "fireCastor") , " AND run!= 'ensembleMean'", ";")))
   
   clim<-merge(dat, id_vals, by.x = "pixelid_climate", by.y ="pixelid_climate", all.y=TRUE )
   
   clim_dat<-merge(clim, sim$frt_id, by.x="pixelid", by.y="pixelid")
   
   #create climate 1 and climate 2 for lighting
   clim_dat[frt==5, climate1lightning:=(Tave05 + Tave06 + Tave07 + Tave08)/4]
   clim_dat[frt==5, climate2lightning:=(PPT05 + PPT06 + PPT07 + PPT08)/4]
   clim_dat[frt==7, climate1lightning:=(Tmax03 + Tmax04 + Tmax05 + Tmax06 + Tmax07 + Tmax08)/6]
   clim_dat[frt==9, climate1lightning:=(Tave04 + Tave05 + Tave06 + Tave07 + Tave08 + Tave09)/6]
   clim_dat[frt==10, climate1lightning:=(Tave07 + Tave08)/2]
   clim_dat[frt==10, climate2lightning:=(PPT07 + PPT08)/2]
   clim_dat[frt==11, climate1lightning:=(Tave03 + Tave04 + Tave05 + Tave06 + Tave07 + Tave08)/6]
   clim_dat[frt==12, climate1lightning:=(Tmax07 + Tmax08)/2]
   clim_dat[frt==13, climate1lightning:=Tave07]
   clim_dat[frt==13, climate2lightning:=PPT07]
   clim_dat[frt==14, climate1lightning:=CMD07]
   clim_dat[frt==15, climate1lightning:=(Tave07 + Tave08)/2]
   clim_dat[frt==15, climate2lightning:=(PPT07 + PPT08)/2]
   
   ## person caused fires
   clim_dat[frt==5, climate1person:=(PPT06 + PPT07)/2]
   clim_dat[frt==7, climate1person:=(Tmax05 + Tmax06 + Tmax07 + Tmax08)/4]
   clim_dat[frt==9, climate1person:=(Tave04 + Tave05 + Tave06 + Tave07)/4]
   clim_dat[frt==9, climate2person:=(PPT04 + PPT05 + PPT06 + PPT07)/4]
   clim_dat[frt==10, climate1person:=(CMD06 + CMD07 + CMD08 + CMD09)/4]
   clim_dat[frt==11, climate1person:=(Tmax04 + Tmax05 + Tmax06 + Tmax07)/4]
   clim_dat[frt==11, climate2person:=(PPT04 + PPT05 + PPT06 + PPT07)/4]
   clim_dat[frt==12, climate1person:=(Tmax04 + Tmax05 + Tmax06 + Tmax07 + Tmax08)/5]
   clim_dat[frt==13, climate1person:=(Tmax04 + Tmax05 + Tmax06 + Tmax07 + Tmax08)/5]
   clim_dat[frt==14, climate1person:=(Tmax04 + Tmax05 + Tmax06 + Tmax07 + Tmax08)/5]
   clim_dat[frt==15, climate1person:=(Tave06 + Tave07 + Tave08)/3]
   clim_dat[frt==15, climate2person:=(PPT06 + PPT07 + PPT08)/3]
   
   ## escape caused fires
   clim_dat[frt==5, climate1escape:=(Tmax04+Tmax05)/2]
   clim_dat[frt==5, climate2escape:=(PPT04+PPT05)/2]
   clim_dat[frt==7, climate1escape:=CMI04]
   clim_dat[frt==9, climate1escape:=Tave05]
   clim_dat[frt==9, climate2escape:=PPT05]
   clim_dat[frt==10, climate1escape:=(CMD04+CMD05+CMD06)/3]
   clim_dat[frt==11, climate1escape:=Tave05]
   clim_dat[frt==11, climate2escape:=PPT05]
   clim_dat[frt==12, climate1escape:=(Tmax04+Tmax05+Tmax06)/3]
   clim_dat[frt==12, climate2escape:=(PPT04+PPT05+PPT06)/3]
   clim_dat[frt==13, climate1escape:=(Tmax07+Tmax08)/2]
   clim_dat[frt==13, climate2escape:=(PPT07+PPT08)/2]
   clim_dat[frt==14, climate1escape:=(Tmax04+Tmax05+Tmax06)/3]
   clim_dat[frt==14, climate2escape:=(PPT04+PPT05+PPT06)/3]
   clim_dat[frt==15, climate1escape:=(CMD07 +CMD08)/2]
   
   # spread
   clim_dat[frt==5, climate1spread:=(Tmax06+Tmax07+Tmax08)/3]
   clim_dat[frt==5, climate2spread:=(PPT06+PPT07+PPT08)/3]
   
   
  sim$climate_data<-clim_dat[ ,c("pixelid","gcm", "ssp", "run","period","climate1lightning", "climate2lightning","climate1person","climate2person", "climate1escape", "climate2escape", "climate1spread", "climate2spread")]
  
  
   return(invisible(sim))
   
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
      
      fuel_attributes_castordb<-sapply(c('bclcs_level_1', 'bclcs_level_4','species_cd_1','species_pct_1','species_cd_2', 'species_pct_2', 'species_cd_3', 'species_pct_3','species_cd_4','species_pct_4', 'species_cd_5', 'species_pct_5', 'species_cd_6', 'species_pct_6'), function(x){
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
  
message("getting vegetation data")

  veg_attributes<- data.table(dbGetQuery(sim$castordb, "SELECT pixelid, basalarea, age, height,  blockid FROM pixels"))
  
  veg2<-merge(sim$inv, veg_attributes, by.x="pixelid", by.y = "pixelid", all.x=TRUE)
  
  veg2[height >= 4 & basalarea >= 8 & bclcs_level_4 == "TC", veg_cat:=1]
  veg2[height >= 4 & basalarea >= 8 & bclcs_level_4 == "TM", veg_cat:=2]
  veg2[height >= 4 & basalarea >= 8 & bclcs_level_4 == "TB", veg_cat:=3]
  veg2[((height < 4 | basalarea < 8 | is.na(height ) | is.na(basalarea)) & bclcs_level_4 %in% c("TC", "TM", "TB")), veg_cat:=4]
  veg2[!bclcs_level_4 %in% c("TC", "TM", "TB"), veg_cat:=5]
  veg2[bclcs_level_1 != 'V' & (is.na(basalarea) | basalarea < 8), veg_cat:=6]
  
  rm(veg_attributes)
  gc()
  
  sim$veg2<-veg2

  return(invisible(sim)) 
  
}

calcProbIgnitEscape<-function(sim){
  
  #### UPDATE FROM HERE ####
 
  
  dat<-merge(sim$veg2, sim$climate_data, by.x="pixelid", by.y="pixelid", all.x=TRUE)
  dat<-merge(dat, sim$road_distance, by.x="pixelid", by.y="pixelid", all.x=TRUE)
  #dat<-merge(dat, sim$elev, by.x="pixelid", by.y="pixelid", all.x=TRUE)
  
  dat<-merge(dat,sim$fire_static, all.x=TRUE)
  
  message("get coefficient table")
  
  #if (!suppliedElsewhere(sim$coefficients)) {
  sim$coefficients<-as.data.table(getTableQuery(paste0("SELECT * FROM " ,P(sim, "firemodelcoeftbl","fireCastor"), ";")))
 # } else { print("coefficient table already loaded")}
  
  dat<-data.table(dat)
  
  
  # there aer values in climate that are null values e.g. -9999
  
  dat[climate1lightning==-9999, climate1lightning:=NA]
  dat[climate2lightning==-9999, climate2lightning:=NA]
  dat[climate1person ==-9999, climate1person:=NA]
  dat[climate2person ==-9999, climate2person:=NA]
  dat[climate1escape ==-9999, climate1escape:=NA]
  dat[climate2escape ==-9999, climate2escape:=NA]
  dat[climate1spread ==-9999, climate1spread :=NA]
  dat[climate2spread ==-9999, climate2spread :=NA]
  
  browser()
  
  #---------#
  #### FRT 5  ####
  #---------#
  if (nrow(dat[frt==5,])>0) {
  frt5<- dat[frt==5, ]
  head(frt5)
  
  # put coefficients into model formula
  #logit(p) = b0+b1X1+b2X2+b3X3….+bkXk
  frt5[, logit_P_lightning := ignitstaticlightning * all + 
         sim$coefficients[cause == "lightning" & frt==5,]$coef_climate_1 * climate1lightning + 
         sim$coefficients[cause == "lightning" & frt==5,]$coef_climate_2 * climate2lightning +
         sim$coefficients[cause == "lightning" & frt==5,]$coef_c2 * veg_C2 +
         sim$coefficients[cause == "lightning" & frt==5,]$coef_c3 * veg_C3 +
         sim$coefficients[cause == "lightning" & frt==5,]$coef_c7 * veg_C5 +
         sim$coefficients[cause == "lightning" & frt==5,]$coef_c7 * veg_C7 +
         sim$coefficients[cause == "lightning" & frt==5,]$coef_d12 * veg_D12 +
         sim$coefficients[cause == "lightning" & frt==5,]$coef_m12 * veg_M12 +
         sim$coefficients[cause == "lightning" & frt==5,]$coef_o1ab * veg_O1ab + 
         sim$coefficients[cause == "lightning" & frt==5,]$coef_o1ab * veg_S1]
  
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
  
  # change veg categories to ones that we have coefficients
  
  frt5[, logit_P_escape := escapestatic * all + 
         sim$coefficients[cause == 'escape' & frt==5,]$coef_climate_1 * climate1escape +
         sim$coefficients[cause == 'escape' & frt==5,]$coef_c2 * veg_C2 +
         sim$coefficients[cause == 'escape' & frt==5,]$coef_c3 * veg_C3 +
         sim$coefficients[cause == 'escape' & frt==5,]$coef_c3 * veg_C5 +
         sim$coefficients[cause == 'escape' & frt==5,]$coef_c3 * veg_C7 +
         sim$coefficients[cause == 'escape' & frt==5,]$coef_d12 * veg_D12 +
         sim$coefficients[cause == 'escape' & frt==5,]$coef_m12 * veg_M12 +
         sim$coefficients[cause == 'escape' & frt==5,]$coef_o1ab * veg_O1ab + 
         sim$coefficients[cause == 'escape' & frt==5,]$coef_o1ab * veg_S1]
       
  frt5[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]

  
  
  # currently I weight the total probability of ignition by the frequency of each cause.But I calculated this once and assume its static. Probably I should actually calculate this once during the simulation for my AOI and then assume it does not change over time. Or I should use that equation that weights them equally since we dont know whats going to happen inthe future.
  
  frt5[, prob_tot_ignit := prob_ignition_lightning*0.8 + prob_ignition_person*0.2]
  
  frt5[fwveg %in% c("W", "N"), prog_tot_ignit:=0]
  frt5[fwveg %in% c("W", "N"),prob_ignition_lightning:=0]
  frt5[fwveg %in% c("W", "N"),prob_ignition_person:=0]
  frt5[fwveg %in% c("W", "N"),prob_ignition_escape:=0]
  #frt5[fwveg %in% c("W", "N"),prob_ignition_spread:=0]
  
  
  frt5<-frt5[, c("pixelid","frt", "prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", 
                 #"prob_ignition_spread",
                 "prob_tot_ignit")]
  
  } else {
    
    print("no data for FRT 5")
    
    frt5<-data.table(pixelid=as.numeric(),
                     frt = as.numeric(),
                     prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(),
                     prob_ignition_escape = as.integer(),
                     #prob_ignition_spread = as.integer(),
                     prob_tot_ignit = as.integer())
  }
  
  #### FRT7 #### 
  if (nrow(dat[frt==7,])>0) {
  frt7<- dat[frt==7,]
  
  #NOTE C-1 is the intercept
  frt7[fwveg == "C-4", veg_C2 :=1]
  frt7[fwveg == "C-7", veg_C3:=1]
  frt7[fwveg == "C-5", veg_C3:=1]
  frt7[fwveg == "S-1", veg_O1ab:=1]
  
  frt7[pixelid>0, all:=1]
  
  #model_coef_table_lightning<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt7_lightning.csv")
  
  frt7[, logit_P_lightning := ignitstaticlightning * all + 
    sim$coefficients[cause=="lightning" & frt==7,]$coef_climate_1 * climate1lightning +
    sim$coefficients[cause=="lightning" & frt==7,]$coef_c2 * veg_C2 +
    sim$coefficients[cause=="lightning" & frt==7,]$coef_c3 * veg_C3 +
    sim$coefficients[cause=="lightning" & frt==7,]$coef_d12 * veg_D12 +
    sim$coefficients[cause=="lightning" & frt==7,]$coef_m12 * veg_M12 +
    sim$coefficients[cause=="lightning" & frt==7,]$coef_o1ab * veg_O1ab]

  # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
  frt7[, prob_ignition_lightning:=exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
  
  # Person caused fires
 # model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT7_person.csv")
  
  frt7[,veg_O1ab:= 0]
  frt7[fwveg == "O-1a/b", veg_O1ab := 1]


  frt7[, logit_P_human := ignitstatichuman  * all + 
      sim$coefficients[cause == 'person' & frt == 7, ]$coef_climate_1 * climate1person + 
      sim$coefficients[cause == 'person' & frt==7,]$coef_c2*veg_C2 +
      sim$coefficients[cause == 'person' & frt==7,]$coef_c3*veg_C3 +
      sim$coefficients[cause == 'person' & frt==7,]$coef_d12*veg_D12 +
      sim$coefficients[cause == 'person' & frt==7,]$coef_m12*veg_M12 +
      sim$coefficients[cause == 'person' & frt==7,]$coef_o1ab*veg_O1ab +
      sim$coefficients[cause == 'person' & frt==7,]$coef_s1*veg_S1 +
      sim$coefficients[cause == 'person' & frt==7,]$coef_log_road_dist  * log(rds_dist+1)]
       
       frt7[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
       
    # Fire Escape
#model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt7_escape.csv")
       
       # reset the veg categories

  frt7[, veg_C2 := 0]
  frt7[fwveg == "C-2", veg_C2 := 1]
  frt7[, veg_C3 := 0]
  frt7[fwveg == "C-3", veg_C3 := 1]
  frt7[, veg_M12 := 0]
  frt7[fwveg == "M-1/2", veg_M12 := 1]
  frt7[,veg_O1ab:= 0]
  frt7[fwveg == "O-1a/b", veg_O1ab := 1]
       
  # change veg categories to ones that we have sim$coefficients
  frt7[fwveg == "C-4", veg_C2 := 1]
  frt7[fwveg == "C-5", veg_C3 := 1]
  frt7[fwveg == "C-7", veg_C3 := 1]
  frt7[fwveg == "S-1", veg_O1ab := 1]
       
       
  frt7[, logit_P_escape := escapestatic * all + 
    sim$coefficients[cause == 'escape' & frt==7,]$coef_climate_1 * climate1escape +
    sim$coefficients[cause == 'escape' & frt==7,]$coef_c1 * veg_C1 +
    sim$coefficients[cause == 'escape' & frt==7,]$coef_c2 * veg_C2 +
    sim$coefficients[cause == 'escape' & frt==7,]$coef_c3 * veg_C3 +
    sim$coefficients[cause == 'escape' & frt==7,]$coef_m12 * veg_M12 +
    sim$coefficients[cause == 'escape' & frt==7,]$coef_o1ab * veg_O1ab]
       
  frt7[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
       
       # Spread
 #      model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt7_spread.csv")
       
    #    # reset the veg categories
    #    frt7[, veg_D12 := 0]
    #    frt7[fwveg == "D-1/2", veg_D12 := 1]
    #    frt7[, veg_C2 := 0]
    #    frt7[fwveg == "C-2", veg_C2 := 1]
    #    frt7[, veg_M12 := 0]
    #    frt7[fwveg == "M-1/2", veg_M12 := 1]
    #    
    #    # change veg categories to ones that we have sim$coefficients
    #    frt7[fwveg == "C-5", veg_C7 := 1]
    #    frt7[fwveg == "M-3", veg_O1ab := 1]
    #    
    # frt7[, logit_P_spread := spreadstatic * all + 
    #   sim$coefficients[cause == 'spread' & frt==7,]$coef_climate_1 * climate1spread+
    #   sim$coefficients[cause == 'spread' & frt==7,]$coef_climate_2 * climate2spread+
    #   sim$coefficients[cause == 'spread' & frt==7,]$coef_c2 * veg_C2 +
    #   sim$coefficients[cause == 'spread' & frt==7,]$coef_c3 * veg_C3 +
    #   sim$coefficients[cause == 'spread' & frt==7,]$coef_c7 * veg_C7 +
    #   sim$coefficients[cause == 'spread' & frt==7,]$coef_d12 * veg_D12 +
    #   sim$coefficients[cause == 'spread' & frt==7,]$coef_m12 * veg_M12 +
    #   sim$coefficients[cause == 'spread' & frt==7,]$coef_N * veg_N +
    #   sim$coefficients[cause == 'spread' & frt==7,]$coef_o1ab * veg_O1ab +
    #   sim$coefficients[cause == 'spread' & frt==7,]$coef_s1 * veg_S1 +
    #   sim$coefficients[cause == 'spread' & frt==7,]$coef_s2 * veg_S2 +
    #   sim$coefficients[cause == 'spread' & frt==7,]$coef_log_road_dist * log(rds_dist+1)]
    #    
    #    frt7[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
       
       frt7[, prob_tot_ignit := prob_ignition_lightning*0.2 + (prob_ignition_person*0.8)]
       
       frt7[fwveg %in% c("W", "N"), prog_tot_ignit:=0]
       frt7[fwveg %in% c("W", "N"),prob_ignition_lightning:=0]
       frt7[fwveg %in% c("W", "N"),prob_ignition_person:=0]
       frt7[fwveg %in% c("W", "N"),prob_ignition_escape:=0]
       
      frt7<-frt7[, c("pixelid","frt","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_tot_ignit")]
      
  } else {
    
    print("no data for FRT 7")
    
    frt7<-data.table(pixelid=as.numeric(),
                     frt = as.numeric(),
                     prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(), 
                     prob_ignition_escape = as.integer(),
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
    sim$coefficients[cause == "lightning" & frt==9,]$coef_climate_1*climate1lightning ]
    
    # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
    frt9[, prob_ignition_lightning := exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
    
  # Person caused fires
  # model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT9_person.csv")
  frt9[, logit_P_human := ignitstatichuman  * all + 
      sim$coefficients[cause == 'person' & frt == 9, ]$coef_climate_1 * climate1person + sim$coefficients[cause == 'person' & frt == 9, ]$coef_climate_2 * climate2person] 
         
         frt9[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
         
  # Fire Escape
#  model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt11_escape.csv")
         
# Note FRT 9 and FRT 11 were combined due to lack of data         
         
  frt9[, logit_P_escape := escapestatic * all + 
        sim$coefficients[cause == 'escape' & frt==11,]$coef_climate_1 * climate1escape +
         sim$coefficients[cause == 'escape' & frt==11,]$coef_climate_2 * climate2escape] 
         
  frt9[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
         
         # Spread
 #  model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt9_spread.csv")
         
         # reset the veg categories
  #   frt9[, veg_C7 := 0]
  #   frt9[fwveg == "C-7", veg_C7 := 1]
  #   frt9[, veg_C2 := 0]
  #   frt9[fwveg == "C-2", veg_C2 := 1]
  #   frt9[, veg_M12 := 0]
  #   frt9[fwveg == "M-1/2", veg_M12 := 1]
  #        
  #        # change veg categories to ones that we have sim$coefficients
  #   frt9[fwveg == "C-4", veg_C2 := 1]
  #   frt9[fwveg == "C-5", veg_C7 := 1]
  #   frt9[fwveg == "S-1", veg_M12 := 1]
  #        
  #   frt9[, logit_P_spread := spreadstatic * all + 
  #       sim$coefficients[cause == 'spread' & frt==9,]$coef_climate_1 * climate1spread+
  #       sim$coefficients[cause == 'spread' & frt==9,]$coef_climate_2 * climate2spread+
  #       sim$coefficients[cause == 'spread' & frt==9,]$coef_c2 * veg_C2 +
  #       sim$coefficients[cause == 'spread' & frt==9,]$coef_c3 * veg_C3 +
  #       sim$coefficients[cause == 'spread' & frt==9,]$coef_c7 * veg_C7 +
  #       sim$coefficients[cause == 'spread' & frt==9,]$coef_d12 * veg_D12 +
  #       sim$coefficients[cause == 'spread' & frt==9,]$coef_m12 * veg_M12 +
  #       sim$coefficients[cause == 'spread' & frt==9,]$coef_N * veg_N +
  #       sim$coefficients[cause == 'spread' & frt==9,]$coef_o1ab * veg_O1ab +
  #       sim$coefficients[cause == 'spread' & frt==9,]$coef_log_road_dist * log(rds_dist+1)]
  #        
  # frt9[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
  
  frt9[, prob_tot_ignit := (prob_ignition_lightning*0.7) + (prob_ignition_person*0.3)]
  
  frt9[fwveg %in% c("W", "N"), prog_tot_ignit:=0]
  frt9[fwveg %in% c("W", "N"),prob_ignition_lightning:=0]
  frt9[fwveg %in% c("W", "N"),prob_ignition_person:=0]
  frt9[fwveg %in% c("W", "N"),prob_ignition_escape:=0]
  
  
  frt9<-frt9[, c("pixelid","frt","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_tot_ignit")]
  } else {
    
    print("no data for FRT 9")
    
    frt9<-data.table(pixelid=as.numeric(),
                     frt = as.numeric(),
                     prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(), 
                     prob_ignition_escape = as.integer(),
                     prob_tot_ignit = as.integer())
    
      
  }
  
  #### FRT10 #### 
  if (nrow(dat[frt==10,])>0) {
    frt10<- dat[frt==10,]
    
    frt10[pixelid>0, all:=1]
    
 #   model_coef_table_lightning<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt10_lightning.csv")
    
    # frt10[, logit_P_lightning := ignitstaticlightning * all + 
    #   sim$coefficients[cause == 'lightning' & frt==10,]$coef_climate_1*climate1lightning + 
    #   sim$coefficients[cause == 'lightning' & frt==10,]$coef_climate_2*climate2lightning]
    # 
    # # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
    # frt10[, prob_ignition_lightning := exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
    # 
    # Person caused fires
 #    model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT10_person.csv")
    
      #   frt10[, logit_P_human := ignitstatichuman  * all + 
      # sim$coefficients[cause == 'person' & frt == 10, ]$coef_climate_1 * climate1person + 
      # sim$coefficients[cause == 'person' & frt == 10, ]$coef_log_road_dist * log(rds_dist + 1)]
      #    
      #    frt10[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
      #    
      #    # Fire Escape
   #  model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt10_escape.csv")
         
         #### CHECK MY ESCAPE VALUES SEEM VERY LOW
         
    frt10[, logit_P_escape := escapestatic * all + 
        sim$coefficients[cause == 'escape' & frt==10,]$coef_climate_1 * climate1escape]
         
         frt10[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
         
         # Spread
 #   model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt10_spread.csv")
    
    # frt10[, veg_C3 := 0]
    # frt10[fwveg == "C-3", veg_C3 := 1]
    # frt10[, veg_C4 := 0]
    # frt10[fwveg == "C-4", veg_C4 := 1]
    # frt10[, veg_C5 := 0]
    # frt10[fwveg == "C-5", veg_C5 := 1]
    # 
    # 
    # frt10[fwveg == "C-4", veg_C2 :=1]
    # frt10[fwveg == "S-2", veg_C7:=1]
    # frt10[fwveg == "M-3", veg_O1ab:=1]
    # 
    # 
    # frt10[, logit_P_spread := spreadstatic * all + 
    #     sim$coefficients[cause == 'spread' & frt==10,]$coef_climate_1 * climate1spread+
    #     sim$coefficients[cause == 'spread' & frt==10,]$coef_climate_2 * climate2spread+
    #     sim$coefficients[cause == 'spread' & frt==10,]$coef_c2 * veg_C2 +
    #     sim$coefficients[cause == 'spread' & frt==10,]$coef_c3 * veg_C3 +
    #     sim$coefficients[cause == 'spread' & frt==10,]$coef_c5 * veg_C5 +
    #     sim$coefficients[cause == 'spread' & frt==10,]$coef_c7 * veg_C7 +
    #     sim$coefficients[cause == 'spread' & frt==10,]$coef_d12 * veg_D12 +
    #     sim$coefficients[cause == 'spread' & frt==10,]$coef_m12 * veg_M12 +
    #     sim$coefficients[cause == 'spread' & frt==10,]$coef_m3 * veg_M3 +
    #     sim$coefficients[cause == 'spread' & frt==10,]$coef_N * veg_N +
    #     sim$coefficients[cause == 'spread' & frt==10,]$coef_o1ab * veg_O1ab +
    #     sim$coefficients[cause == 'spread' & frt==10,]$coef_s1 * veg_S1]
    #      
    # frt10[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
    
    
    # frt10[, prob_tot_ignit := (as.numeric(prob_ignition_lightning)*0.86) + (as.numeric(prob_ignition_person)*0.14)]
    # 
    # frt10[fwveg %in% c("W", "N"), prog_tot_ignit:=0]
    # frt10[fwveg %in% c("W", "N"),prob_ignition_lightning:=0]
    # frt10[fwveg %in% c("W", "N"),prob_ignition_person:=0]
    frt10[veg_cat %in% c("0", "6"),prob_ignition_escape:=0]
    

    
    frt10<-frt10[, c("pixelid","frt","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_tot_ignit")]
  } else {
    
    print("no data for FRT 10")
    
    frt10<-data.table(pixelid=as.numeric(),
                      frt = as.numeric(),
                      prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(), 
                     prob_ignition_escape = as.integer(),
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
      sim$coefficients[cause == 'lightning' & frt==11,]$coef_climate_1 * climate1lightning]
    
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
            sim$coefficients[cause == 'escape' & frt==11,]$coef_climate_1 * climate1escape +
            sim$coefficients[cause == 'escape' & frt==11,]$coef_climate_2 * climate2escape]
    
    frt11[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
    
    # Spread
#   model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt11_spread.csv")
    
  #   frt11[, veg_C7 := 0]
  #   frt11[fwveg == "C-7", veg_C7 := 1]
  #   frt11[, veg_M12 := 0]
  #   frt11[fwveg == "M-1/2", veg_M12 := 1]
  #   frt11[, veg_C3 := 0]
  #   frt11[fwveg == "C-3", veg_C3 := 1]
  # 
  #   frt11[fwveg == "S-1", veg_M12 :=1]
  #   frt11[fwveg == "S-2", veg_C7:=1]
  #   frt11[fwveg == "S-3", veg_M12:=1]
  #   
  # frt11[, logit_P_spread := spreadstatic * all + 
  #       sim$coefficients[cause == 'spread' & frt==11,]$coef_climate_2 * climate2spread +
  #       sim$coefficients[cause == 'spread' & frt==11,]$coef_c2 * veg_C2 +
  #       sim$coefficients[cause == 'spread' & frt==11,]$coef_c3 * veg_C3 +
  #       sim$coefficients[cause == 'spread' & frt==11,]$coef_c5 * veg_C5 +
  #       sim$coefficients[cause == 'spread' & frt==11,]$coef_c7 * veg_C7 +
  #       sim$coefficients[cause == 'spread' & frt==11,]$coef_d12 * veg_D12 +
  #       sim$coefficients[cause == 'spread' & frt==11,]$coef_m12 * veg_M12 +
  #       sim$coefficients[cause == 'spread' & frt==11,]$coef_N * veg_N +
  #       sim$coefficients[cause == 'spread' & frt==11,]$coef_o1ab * veg_O1ab +
  #       sim$coefficients[cause == 'spread' & frt==11,]$coef_road_dist * rds_dist]
  #   
  # frt11[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
  
  frt11[, prob_tot_ignit := (prob_ignition_lightning*0.4) + (prob_ignition_person*0.6)]
  
  frt11[fwveg %in% c("W", "N"), prog_tot_ignit:=0]
  frt11[fwveg %in% c("W", "N"),prob_ignition_lightning:=0]
  frt11[fwveg %in% c("W", "N"),prob_ignition_person:=0]
  frt11[fwveg %in% c("W", "N"),prob_ignition_escape:=0]
  
  
  frt11<-frt11[, c("pixelid","frt","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_tot_ignit")]  
  } else {
    
    print("no data for FRT 11")
    
    frt11<-data.table(pixelid = as.integer(),
                      frt = as.numeric(),
                     prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(), 
                     prob_ignition_escape = as.integer(),
                     prob_tot_ignit = as.integer())
    
    
  }
  
  #### FRT12  #### 
  if (nrow(dat[frt==12,])>0) {
    frt12<- dat[frt==12,]
    
    frt12[pixelid>0, all:=1]
    
#    model_coef_table_lightning<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt12_lightning.csv")
    
    frt12[, logit_P_lightning := ignitstaticlightning * all + 
      sim$coefficients[cause == 'lightning' & frt==12,]$coef_climate_1 * climate1lightning + 
      sim$coefficients[cause == 'lightning' & frt==12,]$coef_c1 * veg_C1 +
      sim$coefficients[cause == 'lightning' & frt==12,]$coef_c2 * veg_C2 + #c3 is the intercept
      sim$coefficients[cause == 'lightning' & frt==12,]$coef_c5 * veg_C5 +
      sim$coefficients[cause == 'lightning' & frt==12,]$coef_c7 * veg_C7 +
      sim$coefficients[cause == 'lightning' & frt==12,]$coef_d12 * veg_D12 +
      sim$coefficients[cause == 'lightning' & frt==12,]$coef_m12 * veg_M12 +
      sim$coefficients[cause == 'lightning' & frt==12,]$coef_o1ab * veg_O1ab +
      sim$coefficients[cause == 'lightning' & frt==12,]$coef_s1 * veg_S1]
      
    
    # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
    frt12[, prob_ignition_lightning := exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
    
    # Person caused fires
 #  model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT12_person.csv")
    frt12[, logit_P_human := ignitstatichuman  * all + 
            sim$coefficients[cause == 'person' & frt == 12, ]$coef_climate_1 * climate1person +
      sim$coefficients[cause == 'person' & frt == 12, ]$coef_c1 * veg_C1 +
      sim$coefficients[cause == 'person' & frt == 12, ]$coef_c2 * veg_C2 +
      sim$coefficients[cause == 'person' & frt == 12, ]$coef_c5 * veg_C5 +
      sim$coefficients[cause == 'person' & frt == 12, ]$coef_c7 * veg_C7 +
      sim$coefficients[cause == 'person' & frt == 12, ]$coef_d12 * veg_D12 +
      sim$coefficients[cause == 'person' & frt == 12, ]$coef_m12 * veg_M12 +
      sim$coefficients[cause == 'person' & frt == 12, ]$coef_o1ab * veg_O1ab +
    sim$coefficients[cause == 'person' & frt == 12, ]$coef_s1 * veg_S1 +
    sim$coefficients[cause == 'person' & frt == 12, ]$coef_log_road_dist * log(rds_dist+1) ]
    
    frt12[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
    
    # Fire Escape
#   model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt12_escape.csv")
   
  frt12[, veg_S1 := 0]

  frt12[fwveg == "C-1", veg_C3 :=1]
  frt12[fwveg == "C-4", veg_C2 :=1]
    
  frt12[, logit_P_escape := escapestatic * all + 
      sim$coefficients[cause == 'escape' & frt==12,]$coef_climate_2 * climate2escape +
      sim$coefficients[cause == 'escape' & frt==12,]$coef_c2 * veg_C2 +
      sim$coefficients[cause == 'escape' & frt==12,]$coef_c5 * veg_C5 + 
      sim$coefficients[cause == 'escape' & frt==12,]$coef_c7 * veg_C7 +
      sim$coefficients[cause == 'escape' & frt==12,]$coef_d12 * veg_D12 +
      sim$coefficients[cause == 'escape' & frt==12,]$coef_m12 * veg_M12 +
      sim$coefficients[cause == 'escape' & frt==12,]$coef_o1ab * veg_O1ab +
      sim$coefficients[cause == 'escape' & frt==12,]$coef_o1ab * veg_S1 + # seems like there were no S-1 values in my training dataset so Ill use the coef of o1ab for this category
      sim$coefficients[cause == 'escape' & frt==12,]$coef_road_dist * rds_dist]
  
    frt12[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
    
    # Spread
#    model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt12_spread.csv")
    
    # frt12[, veg_C7 := 0]
    # frt12[fwveg == "C-7", veg_C7 := 1]
    # frt12[, veg_M12 := 0]
    # frt12[fwveg == "M-1/2", veg_M12 := 1]
    # frt12[, veg_C3 := 0]
    # frt12[fwveg == "C-3", veg_C3 := 1]
    # 
    # frt12[fwveg == "S-1", veg_M12 :=1]
    # frt12[fwveg == "S-2", veg_C7:=1]
    # frt12[fwveg == "S-3", veg_M12:=1]
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
    
    frt12[, prob_tot_ignit := (prob_ignition_lightning*0.5) + (prob_ignition_person*0.5)]
    
    frt12[fwveg %in% c("W", "N"), prog_tot_ignit:=0]
    frt12[fwveg %in% c("W", "N"),prob_ignition_lightning:=0]
    frt12[fwveg %in% c("W", "N"),prob_ignition_person:=0]
    frt12[fwveg %in% c("W", "N"),prob_ignition_escape:=0]
    
    
    frt12<-frt12[, c("pixelid","frt","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_tot_ignit")]    
  } else {
    
    print("no data for FRT 12")
    
    frt12<-data.table(pixelid = as.numeric(),
                      frt = as.numeric(),
                      prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(), 
                     prob_ignition_escape = as.integer(),
                     prob_tot_ignit = as.integer())
    
  }
  
  #### FRT13  #### 
  if (nrow(dat[frt==13,])>0) {
    frt13<- dat[frt==13,]
    
    frt13[fwveg == "C-4", veg_C2 :=1]
    frt13[fwveg == "C-1", veg_C3 :=1]
    
    frt13[pixelid>0, all:=1]
    
#    model_coef_table_lightning<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt13_lightning.csv")
    
    frt13[, logit_P_lightning := ignitstaticlightning * all + 
            sim$coefficients[cause == 'lightning' & frt==13,]$coef_climate_1 * climate1lightning +
            sim$coefficients[cause == 'lightning' & frt==13,]$coef_log_climate_2 * log(climate2lightning+0.1) +
            sim$coefficients[cause == 'lightning' & frt==13,]$coef_c2 * veg_C2 +
            sim$coefficients[cause == 'lightning' & frt==13,]$coef_c5 * veg_C5 +
            sim$coefficients[cause == 'lightning' & frt==13,]$coef_c7 * veg_C7 +
            sim$coefficients[cause == 'lightning' & frt==13,]$coef_d12 * veg_D12 +
            sim$coefficients[cause == 'lightning' & frt==13,]$coef_m12 * veg_M12 +
            sim$coefficients[cause == 'lightning' & frt==13,]$coef_o1ab * veg_O1ab +
            sim$coefficients[cause == 'lightning' & frt==13,]$coef_s1 * veg_S1]
    
    
    # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
    frt13[, prob_ignition_lightning := exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
 
    
    # Person caused fires
#      model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT13_person.csv")
      
      
      
    frt13[, logit_P_human := ignitstatichuman  * all + 
      sim$coefficients[cause == 'person' & frt == 13, ]$coef_climate_1 * climate1person +
      sim$coefficients[cause == 'person' & frt == 13, ]$coef_log_road_dist * log(rds_dist+1) +
        sim$coefficients[cause == 'person' & frt == 13, ]$coef_c2 * veg_C2 +
        sim$coefficients[cause == 'person' & frt == 13, ]$coef_c5 * veg_C5 +
        sim$coefficients[cause == 'person' & frt == 13, ]$coef_c7 * veg_C7 +
        sim$coefficients[cause == 'person' & frt == 13, ]$coef_d12 * veg_D12 +
        sim$coefficients[cause == 'person' & frt == 13, ]$coef_m12 * veg_M12 +
        sim$coefficients[cause == 'person' & frt == 13, ]$coef_o1ab * veg_O1ab +
        sim$coefficients[cause == 'person' & frt == 13, ]$coef_s1 * veg_S1]
    
    frt13[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
    
    # Fire Escape
 #  model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt13_escape.csv")
    
    frt13[, logit_P_escape := escapestatic * all +  
            sim$coefficients[cause == 'escape' & frt==13,]$coef_climate_2 * climate2escape +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_c2 * veg_C2 +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_c5 * veg_C5 + 
            sim$coefficients[cause == 'escape' & frt==13,]$coef_c7 * veg_C7 +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_d12 * veg_D12 +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_m12 * veg_M12 +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_o1ab * veg_O1ab +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_s1 * veg_S1 +
            sim$coefficients[cause == 'escape' & frt==13,]$coef_road_dist * rds_dist]
    
    frt13[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
    
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
    
    frt13[, prob_tot_ignit := (prob_ignition_lightning*0.8) + (prob_ignition_person*0.2)]
    
    frt13[fwveg %in% c("W", "N"), prog_tot_ignit:=0]
    frt13[fwveg %in% c("W", "N"),prob_ignition_lightning:=0]
    frt13[fwveg %in% c("W", "N"),prob_ignition_person:=0]
    frt13[fwveg %in% c("W", "N"),prob_ignition_escape:=0]
    
    
    frt13<-frt13[, c("pixelid", "frt","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_tot_ignit")]
    
  } else {
    
    print("no data for FRT 13")
    
    frt13<-data.table(pixelid=as.numeric(), 
                      frt = as.numeric(),
                      prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(), 
                     prob_ignition_escape = as.integer(),
                     prob_tot_ignit = as.integer())
    
    
  }  
  
  #### FRT14 #### 
  if (nrow(dat[frt==14,])>0) {
    frt14<- dat[frt==14,]
    
    frt14[fwveg == "C-4", veg_C2 :=1]
    
    frt14[pixelid>0, all:=1]
    
# model_coef_table_lightning<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt14_lightning.csv")
    
    frt14[, logit_P_lightning := ignitstaticlightning * all + 
            sim$coefficients[cause == 'lightning' & frt==14,]$coef_climate_1 * climate1lightning]
    
    # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
    frt14[, prob_ignition_lightning := exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
    
    # Person caused fires
#      model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT14_person.csv")
    

    frt14[, logit_P_human := ignitstatichuman  * all + 
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_climate_1 * climate1person +
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_log_road_dist * log(rds_dist+1) +
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_c2 * veg_C2 + #C7 is the intercept
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_c3 * veg_C3 +
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_c5 * veg_C5 +
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_d12 * veg_D12 +
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_m12 * veg_M12 +
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_o1ab * veg_O1ab +
            sim$coefficients[cause == 'person' & frt == 14, ]$coef_s1 * veg_S1]
    
    frt14[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
    
    # Fire Escape
#      model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt14_escape.csv")
      

   frt14[, logit_P_escape := escapestatic * all + 
      sim$coefficients[cause == 'escape' & frt==14,]$coef_climate_1 * climate1escape +
      sim$coefficients[cause == 'escape' & frt==14,]$coef_climate_2 * climate2escape +
      sim$coefficients[cause == 'escape' & frt==14,]$coef_c2 * veg_C2 + # C7 is the intercept and C5 is combined with c7 because not enough of c5's to include in model
      sim$coefficients[cause == 'escape' & frt==14,]$coef_c3 * veg_C3 +
      sim$coefficients[cause == 'escape' & frt==14,]$coef_d12 * veg_D12 +
      sim$coefficients[cause == 'escape' & frt==14,]$coef_m12 * veg_M12 +
      sim$coefficients[cause == 'escape' & frt==14,]$coef_o1ab * veg_O1ab +
        sim$coefficients[cause == 'escape' & frt==14,]$coef_m12 * veg_S1 +
      sim$coefficients[cause == 'escape' & frt==14,]$coef_road_dist * rds_dist]
    
    frt14[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
    
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
    
    frt14[, prob_tot_ignit := (prob_ignition_lightning*0.4) + (prob_ignition_person*0.6)]
    
    frt14[fwveg %in% c("W", "N"), prog_tot_ignit:=0]
    frt14[fwveg %in% c("W", "N"),prob_ignition_lightning:=0]
    frt14[fwveg %in% c("W", "N"),prob_ignition_person:=0]
    frt14[fwveg %in% c("W", "N"),prob_ignition_escape:=0]
    
  
    frt14<-frt14[, c("pixelid","frt","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_tot_ignit")]
    
  } else {
    
    print("no data for FRT 14")
    
    frt14<-data.table(pixelid= as.numeric(),
                      frt = as.numeric(),
                      prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(), 
                     prob_ignition_escape = as.integer(),
                     prob_tot_ignit = as.integer())
    
      
  } 
  
  #### FRT15 #### 
  if (nrow(dat[frt==15,])>0) {
    frt15<- dat[frt==15,]
    frt15[pixelid>0, all:=1]
    
   # model_coef_table_lightning<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt15_lightning.csv")
    
    frt15[, logit_P_lightning := ignitstaticlightning * all + 
            sim$coefficients[cause == 'lightning' & frt==15,]$coef_climate_1 * climate1lightning +
            sim$coefficients[cause == 'lightning' & frt==15,]$coef_climate_2 * climate2lightning +
            sim$coefficients[cause == 'lightning' & frt==15,]$coef_c3 * veg_C3 + # C5 is the intercept
            sim$coefficients[cause == 'lightning' & frt==15,]$coef_c7 * veg_C7 +
            sim$coefficients[cause == 'lightning' & frt==15,]$coef_d12 * veg_D12 +
            sim$coefficients[cause == 'lightning' & frt==15,]$coef_m12 * veg_M12 +
            sim$coefficients[cause == 'lightning' & frt==15,]$coef_o1ab * veg_O1ab + 
            sim$coefficients[cause == 'lightning' & frt==15,]$coef_s1 * veg_S1]
    
    
    # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
    frt15[, prob_ignition_lightning := exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
    
    # Person caused fires
#        model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT15_person.csv")
    
    frt15[, logit_P_human := ignitstatichuman  * all + 
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_climate_1 * climate1person +
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_climate_2 * climate2person +
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_log_road_dist * log(rds_dist+1) +
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_c3 * veg_C3 +# C5 in the intercept
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_c7 * veg_C7 +
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_d12 * veg_D12 +
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_m12 * veg_M12 +
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_o1ab * veg_O1ab +
            sim$coefficients[cause == 'person' & frt == 15, ]$coef_s1 * veg_S1
    ]
    
    frt15[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
    
    # Fire Escape
#    model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt15_escape.csv")
    
    
    
    ## Fix this? It looks like either I have the wrong coefficients table in here or the coefficients for some reason did not get entered into the table correctly. I need to fix this!
    
    frt15[, logit_P_escape := escapestatic * all + 
            sim$coefficients[cause == 'escape' & frt==15,]$coef_climate_1 * climate1escape]
    
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
    
    no_ignitions<-round(rgamma(1, shape=sim$fit_g$estimate[1], rate=sim$fit_g$estimate[2]))

    no_ignitions<-ifelse(no_ignitions*sim$updateInterval < (sim$min_ignit*sim$updateInterval), (sim$min_ignit*sim$updateInterval), no_ignitions*sim$updateInterval)
    
    no_starts_sample<-sim$max_ignit*5*sim$updateInterval
    
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



numberStarts<-function(sim){
  
  message("downloading historical fire data and clip to aoi")
  library(bcdata)
  ignit<-try(
    bcdc_query_geodata("WHSE_LAND_AND_NATURAL_RESOURCE.PROT_HISTORICAL_INCIDENTS_SP") %>%
      dplyr::filter(FIRE_YEAR > 2002) %>%
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
