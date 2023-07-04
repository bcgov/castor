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
    expectsInput(objectName = "updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA)
    expectsInput(objectName = "calendarStartYear", objectClass ="numeric", desc = 'The calendar year of the first simulation', sourceURL = NA)
    expectsInput(objectName = "road_distance", objectClass = "data.table", desc = 'The euclidian distance to the nearest road', sourceURL = NA)
    #expectsInput(objectName = "harvestPixelList", objectClass = "data.table", desc = 'A list of the pixels that are harvested at each time point', sourceURL = NA)
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
      
      sim <- scheduleEvent(sim, time(sim), "fireCastor", "getStaticFireVariables")
      
      if(nrow(sim$road_distance) < 1){
        sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor") , "fireCastor", "roadDistanceCalc", 2)
      }
      #sim <- scheduleEvent(sim, time(sim) + 1, "fireCastor", "roadDistanceCalc", 2)
      sim <- scheduleEvent(sim, time(sim), "fireCastor", "getClimateFireVariables", 3)
      sim <- scheduleEvent(sim, time(sim), "fireCastor", "getVegVariables", 4)
      sim <- scheduleEvent(sim, time(sim), "fireCastor", "determineFuelTypes", 5)
      sim <- scheduleEvent(sim, time(sim), "fireCastor", "calcProbabilityFire", 6)
      sim <- scheduleEvent(sim, time(sim), "fireCastor", "simulateFire", 9)
      
      if(nrow(sim$probFireRasts) > 0){
        
        setorder(sim$probFireRasts, cols = "pixelid")
        
        ras.info<-dbGetQuery(sim$castordb, "Select * from raster_info limit 1;")
        
        sim$ignitionRas<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0)
        sim$ignitionRas[]<-sim$probFireRasts$prob_tot_ignit
        
        sim$escapeRas<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0)
        sim$escapeRas[]<-sim$probFireRasts$prob_ignition_escape
        
        sim$spreadRas<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0)
        sim$spreadRas[]<-sim$probFireRasts$prob_ignition_spread
        
        sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor") , "fireCastor", "simulateFire", 9)
      }
      
    }
      
getStaticFireVariables = {
      sim <- getStaticVariables(sim) # create table with static fire variables to calculate probability of ignition, escape, spread
},

roadDistanceCalc ={
  sim <- roadDistCalc(sim)
  sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor"), "fireCastor", "roadDistanceCalc", 2)
},

getClimateFireVariables = {
    sim <- getClimateVariables (sim)
    sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor"), "fireCastor", "getClimateFireVariables", 3)
},

getVegVariables = {
  if(nrow(dbGetQuery(sim$castordb, "SELECT * FROM sqlite_master WHERE type = 'table' and name ='fueltype'")) == 0){
        message('Creating fueltypes table')
        
      sim <- createVegetationTable(sim)
      #sim <- scheduleEvent(sim, eventTime = time(sim),  "fireCastor", "getVegVariables", eventPriority=8) # 
      # I did not schedule this again because this table gets updated during the disturbanceProcess parts of the simulation but does not need to be calculated again. 
      
  }
},
  
determineFuelTypes = {
      sim <- calcFuelTypes(sim)
      sim <- scheduleEvent(sim, eventTime = time(sim) + P(sim, "calculateInterval", "fireCastor"),  "fireCastor", "determineFuelTypes", eventPriority=5) # 
},

calcProbabilityFire = {}
      sim <- calcProbFire(sim) 
      sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor") , "fireCastor", "calcProbabilityFire", 6)
},

simulateFire ={
  sim<-distProcess(sim)
  sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor"), "fireCastor", "simulateFire", 9)
  },

analysis = {
  sim <- fireAnalysis(sim)
  sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor"), "fireCastor", "analysis", 9)
},

warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
              "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  
  sim$fireReport<-data.table(scenario = character(), timeperiod= integer(),
                             critical_hab = character(), pixelid = integer(),
                             number_sims = numeric(), number_times_burned = numeric())
  sim$firedisturbance <- sim$pts
  
  message("create empty table of fire variables needed to calculate probabilities")
  
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS firevariables (pixelid integer, frt integer, ignitstaticlightning numeric, ignitstatichuman numeric, escapestatic numeric, spreadstatic numeric, distancetoroads numeric, elevation numeric, climate1lightning numeric, climate2lightning numeric, climate1person numeric, climate2person numeric, climate1escape numeric, climate2escape numeric, climate1spread numeric, climate2spread numeric, fwveg)")
  
  return(invisible(sim))
  
}

getStaticVariables<-function(sim){
  if(nrow(sim$fire_static) == 0){
  
  message("get fire regime type")
  #constant coefficients
  ras.frt<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                                srcRaster= P(sim, "nameFrtRaster", "fireCastor"), 
                                                clipper=sim$boundaryInfo[1] , 
                                                geom= sim$boundaryInfo[4] , 
                                                where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                conn=NULL))
  if(terra::ext(sim$ras) == terra::ext(ras.frt)){
    sim$frt_id<-data.table(frt = as.integer(ras.frt[]))
    sim$frt_id[, pixelid := seq_len(.N)][, frt := as.integer(frt)]
    sim$frt_id<-sim$frt_id[frt > 0, ]
  
  rm(ras.frt)
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
    sim$fire_static<-merge(fire_static, frt_id, by.x="pixelid", by.y="pixelid", all.x=TRUE)
    
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

  if ((dbGetQuery(sim$castordb, paste0("SELECT MAX(elv) FROM pixels"))) < 2 ) {
  
  message("extract elevation")
  #constant coefficients
  ras.elev<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                      srcRaster= P(sim, "nameElevation", "fireCastor"), 
                                      clipper=sim$boundaryInfo[1] , 
                                      geom= sim$boundaryInfo[4] , 
                                      where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                      conn=NULL))
  
  if(terra::ext(sim$ras) == terra::ext(ras.elev)){
    elev<-data.table(elv = as.numeric(ras.elev[]))
    elev[, pixelid := seq_len(.N)][, elv := as.numeric(elv)]
    sim$elev<-elev[elv > -10, ]
    
    #add to the castordb
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, "UPDATE pixels set elv = :eleva where pixelid = :pixelid", elev)
    dbClearResult(rs)
    dbCommit(sim$castordb)
    
    rm(ras.elev)
    gc()
  }else{
    stop(paste0("ERROR: extents are not the same check -", P(sim, "nameElevation", "fireCastor")))
  }
  } 
  
  
 # sim$elev<-data.table(dbGetQuery(sim$castordb, paste0("SELECT elv, pixelid FROM pixels")))
  
  message("change data format for download of climate data")
  
  ras2<-terra::project(sim$ras, "EPSG:4326")
  lat_lon_pts<-data.table(terra::xyFromCell(ras2,1:length(ras2[])))
  lat_lon_pts <- lat_lon_pts[, pixelid:= seq_len(.N)]
  
  sample.pts<-merge (lat_lon_pts, sim$elev, by = 'pixelid', all.x =TRUE)
  sample.pts2<-merge(sample.pts, sim$frt_id, by='pixelid', all.x=TRUE)
  
  rm(ras2, lat_lon_pts)
  gc()
  # now pull out the points where there is data for compartid and save only that
 samp.pts<- sample.pts2[!is.na(frt),]
 colnames(samp.pts)[colnames(samp.pts) == "pixelid"] <- "ID1"
 colnames(samp.pts)[colnames(samp.pts) == "frt"] <- "ID2"
 colnames(samp.pts)[colnames(samp.pts) == "y"] <- "lat"
 colnames(samp.pts)[colnames(samp.pts) == "x"] <- "long"
 colnames(samp.pts)[colnames(samp.pts) == "elv"] <- "el"
 
 samp.pts<-as.data.frame(samp.pts)
 samp.pts<-samp.pts%>% dplyr::select(ID1, ID2, lat, long, el)
  
 #write the points to file so that we can use Tongli's Climate BC program to grab climate for our year of interest
  write.csv(samp.pts, file = paste0(here::here(), "\\R\\SpaDES-modules\\fireCastor\\inputs\\sample_pts.csv"), row.names=FALSE)
  
  # seems to be very sensitive to slashes 
  # I should maybe allow the user to specify the name or link it to the climate variable people are downloading
  library(ClimateNAr)
  
  wkDir = "D:/Climatebc_v731/"
  exe = "ClimateBC_v7.31.exe"
  period = paste0('P(sim, "nameClimateTimePoint", "fireCastor")', '.ann') #'Year_2021.ann' 
  inFile =  paste0(here::here(), '\\R\\SpaDES-modules\\fireCastor\\inputs\\sample_pts.csv')
  inputFile = gsub("/","\\\\", inFile)
  outFile = paste0(here::here(), '\\R\\SpaDES-modules\\fireCastor\\outputs\\','P(sim, "nameClimateTimePoint", "fireCastor")','.csv')
  outputFile = gsub("/", "\\\\",outFile)
  
  message("Downloading climate data from climateBC ...")
  
  ClimateNA_cmdLine(exe, wkDir, period, MSY='M',inputFile, outputFile) #this did not work. Did not give me any data
  #system2(exe,args= c('/M', paste0("/",period), paste0("/",inputFile), paste0("/",outputFile)))
  
  climate<-read.csv(outputFile)
  
  # remove unneccessary columns
  
  
  climate2<- climate %>% 
    dplyr::select(ID1, Elevation, Tmax01:Tmax12, Tave04:Tave10, PPT01:PPT12, RH05:RH08) %>% 
    dplyr::rename(pixelid = ID1)
  
  climate2<-as.data.table(climate2)
  
  x2<-merge(sim$fire_static, climate2, by="pixelid", all.x=TRUE)
  
  # FOR EACH DATASET CALCULATE THE MONTHLY DROUGHT CODE Following Girardin & Wotton (2009)
  
  #_-------------------------------------------#
  #### Equations to calculate drought code ####
  #____________________________________________#
  months<- c("02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12")
  
  days_month<- c(31, 30, 31, 30, 31, 31, 30, 31, 30) # number of days in each month starting in Jan
  # Daylength adjustment factor (Lf) [Development and Structure of the Canadian Forest Fire Weather Index System pg 15, https://d1ied5g1xfgpx8.cloudfront.net/pdfs/19927.pdf] ####
  # Month <- Lf value
  # LF[1] is the value for March
  Lf<-c( -1.6, 0.9, 3.8, 5.8, 6.4, 5.0, 2.4, 0.4, -1.6)
  
  ### Calculate drought code for Fire ignition data

    #x2<- climate2 %>% dplyr::filter(Tmax05 != -9999) # there are some locations that did not have climate data, probably because they were over the ocean, so Im removing these here.
    
    for (j in 1 : length(Lf)) {
      
      
      x2$MDC_02<-15 # the MDC value for Feb This assumes that the ground is saturated at the start of the season. Maybe not true for all locations... may need to think about this a little more.
      
      Em<- days_month[j]*((0.36*x2[[paste0("Tmax",months[j+1])]])+Lf[j])
      Em2 <- ifelse(Em<0, 0, Em)
      DC_half<- x2[[paste0("MDC_",months[j])]] + (0.25 * Em2)
      precip<-x2[[paste0("PPT",months[j+1])]]
      RMeff<-(0.83 * (x2[[paste0("PPT",months[j+1])]]))
      Qmr<- (800 * exp((-(DC_half))/400)) + (3.937 * RMeff)
      Qmr2 <- ifelse(Qmr>800, 800, Qmr)
      MDC_m <- (400 * log(800/Qmr2)) + 0.25*Em2
      x2[[paste0("MDC_",months[j+1])]] <- (x2[[paste0("MDC_",months[j])]] + MDC_m)/2
      x2[[paste0("MDC_",months[j+1])]] <- ifelse(x2[[paste0("MDC_",months[j+1])]] <15, 15, x2[[paste0("MDC_",months[j+1])]])
    }
  
  # Lightning climate variables
  #climate_variables_lightning<-read.csv("C:/Work/caribou/castor_data/Fire/Fire_sim_data/data/climate_AIC_results_lightning_FRT_summary.csv")  
  x2<-x2 %>%
    dplyr::mutate(climate1_lightning = dplyr::case_when(
      frt == "5" ~ (Tave05 + Tave06 + Tave07 +Tave08)/4 ,
      frt == "7" ~ (RH05 + RH06 + RH07)/3,
      frt == "9" ~ Tmax05,
      frt == "10" ~ (Tave07 + Tave08 + Tave09)/3 ,
      frt == "11" ~ (Tmax07 + Tmax08 + Tmax09)/3,
      frt == "12" ~ (Tmax07 + Tmax08)/2,
      frt == "13" ~ Tave07,
      frt == "14" ~ (Tave07 + Tave08)/2,
      frt == "15" ~ (Tave06 + Tave07 + Tave08)/3 ,
      TRUE ~ NA_real_))
  
  x2 <- x2 %>%
    dplyr::mutate(climate2_lightning = dplyr::case_when(
      frt == "5" ~ as.numeric((PPT05 + PPT06 +PPT07 + PPT08)/4) ,
      frt == "10" ~ as.numeric((PPT07 + PPT08 + PPT09)/3) ,
      frt == "11" ~ as.numeric((PPT07 + PPT08 + PPT09)/3),
      frt == "13" ~ as.numeric(PPT07),
      frt == "15" ~ as.numeric((PPT06 + PPT07 + PPT08)/3),
      TRUE ~ NA_real_))

  # Person Climate variables not included in lightning
  #climate_variables_person<-read.csv("C:/Work/caribou/castor_data/Fire/Fire_sim_data/data/climate_AIC_results_person_FRT_summary.csv")
  
  x2<-x2 %>%
    dplyr::mutate(climate1_person = dplyr::case_when(
      frt == "5" ~ as.numeric((PPT06 + PPT07)/2),
      frt == "7" ~ (Tave04 + Tave05 + Tave06 + Tave07 +Tave08 + Tave09 + Tave10)/7,
      frt == "9" ~ Tmax05, # NDT4
      frt == "10" ~ as.numeric(PPT06 + PPT07 + PPT08 + PPT09)/4,
      frt == "11" ~ (Tave08 + Tave09 + Tave10)/3,
      frt == "12" ~ (Tmax04 + Tmax05 + Tmax06 + Tmax07 + Tmax08 + Tmax09 + Tmax10)/7,
      frt == "13" ~ (Tave07 + Tave08 + Tave09)/3,
      frt == "14" ~ (Tmax04 + Tmax05 + Tmax06 + Tmax07 + Tmax08 + Tmax09 + Tmax10)/7,
      frt == "15" ~ (Tave07 + Tave08 + Tave09)/3,
      TRUE ~ NA_real_))
  
  # #Repeat for climate 2
  x2<-x2 %>%
    dplyr::mutate(climate2_person = dplyr::case_when(
      frt == "13" ~ as.numeric((PPT07 + PPT08 + PPT09)/3),
      frt == "15" ~ as.numeric((PPT07 + PPT08 + PPT09)/3),
      TRUE ~ NA_real_))
  
  # escape variables not listed above
  #climate_escape<-read.csv("C:\\Work\\caribou\\castor_data\\Fire\\Fire_sim_data\\data\\climate_AIC_results_escape_summary_March2023.csv")
  x2<-x2 %>%
    dplyr::mutate(climate1_escape = dplyr::case_when(
      frt == "5" ~ as.numeric(PPT05) ,
      frt == "7" ~ Tave06,
      frt == "9" ~ Tave05,
      frt == "10" ~ as.numeric((PPT04 + PPT05 + PPT06)/3),
      frt == "11" ~ MDC_06,
      frt == "12" ~ (Tmax07 + Tmax08 + Tmax09)/3,
      frt == "13" ~ (Tmax07 + Tmax08 + Tmax09)/3,
      frt == "14" ~ as.numeric((MDC_05 + MDC_06 + MDC_07 + MDC_08)/4),
      frt == "15" ~ (Tave07 + Tave08 + Tave09)/3 ,
      TRUE ~ NA_real_))
  
  x2<-x2 %>%
    dplyr::mutate(climate2_escape = dplyr::case_when(
      frt == "7" ~ as.numeric(PPT06),
      frt == "12" ~ as.numeric((PPT07 + PPT08 + PPT09)/3) ,
      frt == "13" ~ as.numeric((PPT07 + PPT08 + PPT09)/3),
      frt == "15" ~ as.numeric((PPT07 + PPT08 + PPT09)/3),
      TRUE ~ NA_real_))
  
  # spread variables not listed above
  # climate_spread<-read.csv("C:\\Work\\caribou\\castor_data\\Fire\\Fire_sim_data\\data\\climate_AIC_results_spread_summary_March2023.csv")
  x2<-x2 %>%
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
  
  x2<-x2 %>%
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
  
  sim$fire_variables<-x2 %>% dplyr::select(pixelid, frt, Elevation, ignitstaticlightning, ignitstatichuman, escapestatic, spreadstatic, climate1_lightning, climate2_lightning, climate1_person, climate2_person, climate1_escape, climate2_escape, climate1_spread, climate2_spread)
  # 
  # dbBegin(sim$castordb)
  # rs<-dbSendQuery(sim$castordb, 'UPDATE firevariables SET climate1lightning  = :climate1_lightning, climate2lightning = :climate2_lightning, climate1person = :climate1_person, climate2person = :climate2_person, climate1escape = :climate1_escape, climate2escape = :climate2_escape, climate1spread = :climate1_spread, climate2spread = :climate2_spread WHERE pixelid = :pixelid', sim$clim_variables) 
  # dbClearResult(rs)
  # dbCommit(sim$castordb)  
  # 
  rm(x2, climate2, climate, days_month, DC_half, Em, Em2, MDC_m, precip, Qmr, Qmr2, RMeff)
  
  gc()
  return(invisible(sim))
}

createVegetationTable <- function(sim) {
  
  message("create fuel types table")
  
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS fueltype (pixelid integer, bclcs_level_1 character, bclcs_level_2 character, bclcs_level_3 character,  bclcs_level_5 character, inventory_standard_cd character, non_productive_cd character, coast_interior_cd character,  land_cover_class_cd_1 character, zone character, subzone character, earliest_nonlogging_dist_type character, years_since_nonlogging_dist integer, vri_live_stems_per_ha numeric, vri_dead_stems_per_ha numeric, species_cd_1 character, species_pct_1 numeric, species_cd_2 character, species_pct_2 numeric, dominant_conifer character, conifer_pct_cover_total numeric)")
  
  # Get bec zone and bec subzone
  
  print("getting BEC information")
  
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
    print("clipping inventory key")
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
    
    
    if(!P(sim, "nameForestInventoryTable2","dataCastor") == '99999'){ #Get the forest inventory variables 
      
      fuel_attributes_castordb<-c('bclcs_level_1', 'bclcs_level_2', 'bclcs_level_3',  'bclcs_level_5', 'inventory_standard_cd', 'non_productive_cd', 'coast_interior_cd',  'land_cover_class_cd_1', 'earliest_nonlogging_dist_type', 'earliest_nonlogging_dist_date','vri_live_stems_per_ha', 'vri_dead_stems_per_ha','species_cd_1','species_pct_1','species_cd_2', 'species_pct_2', 'species_cd_3', 'species_pct_3','species_cd_4','species_pct_4', 'species_cd_5', 'species_pct_5', 'species_cd_6', 'species_pct_6')
      
      if(length(fuel_attributes_castordb) > 0){
        print(paste0("getting inventory attributes to create fuel types: ", paste(fuel_attributes_castordb, collapse = ",")))
        fids<-unique(inv_id[!(is.na(fid)), fid])
        attrib_inv<-data.table(getTableQuery(paste0("SELECT " , P(sim, "nameForestInventoryKey", "dataCastor"), " as fid, ", paste(fuel_attributes_castordb, collapse = ","), " FROM ",
                                                    P(sim, "nameForestInventoryTable2","dataCastor"), " WHERE ", P(sim, "nameForestInventoryKey", "dataCastor") ," IN (",
                                                    paste(fids, collapse = ","),");" )))
        
        print("...merging with fid") #Merge this with the raster using fid which gives you the primary key -- pixelid
        inv<-merge(x=inv_id, y=attrib_inv, by.x = "fid", by.y = "fid", all.x = TRUE) 
        inv<-inv[, fid:=NULL] # remove the fid key
        
        inv<-merge(x=inv, y=bec, by.x="pixelid", by.y="pixelid", all.x=TRUE)
        
        print("calculating time since disturbance")
        inv[, earliest_nonlogging_dist_date := substr(earliest_nonlogging_dist_date,1,4)]
        inv[, earliest_nonlogging_dist_date := as.integer(earliest_nonlogging_dist_date)]
        inv[, years_since_nonlogging_dist:=NA][, years_since_nonlogging_dist:=(time(sim)*sim$updateInterval) + sim$calendarStartYear - earliest_nonlogging_dist_date, ]
        inv<-inv[, earliest_nonlogging_dist_date:=NULL]
      
        print("calculating % conifer and dominant conifer species")
        
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
        
        print('populating fuel type table')
        
        qry<-paste0('INSERT INTO fueltype (pixelid, bclcs_level_1, bclcs_level_2, bclcs_level_3, bclcs_level_5, inventory_standard_cd, non_productive_cd, coast_interior_cd, land_cover_class_cd_1,  earliest_nonlogging_dist_type, vri_live_stems_per_ha, vri_dead_stems_per_ha, species_cd_1, species_pct_1, species_cd_2, species_pct_2, zone, subzone,years_since_nonlogging_dist, dominant_conifer, conifer_pct_cover_total) values (:pixelid, :bclcs_level_1, :bclcs_level_2, :bclcs_level_3, :bclcs_level_5, :inventory_standard_cd, :non_productive_cd, :coast_interior_cd, :land_cover_class_cd_1, :earliest_nonlogging_dist_type, :vri_live_stems_per_ha, :vri_dead_stems_per_ha, :species_cd_1, :species_pct_1, :species_cd_2, :species_pct_2,:zone, :subzone, :years_since_nonlogging_dist, :dominant_conifer, :conifer_pct_cover_total)')
        
        #fueltype table
        dbBegin(sim$castordb)
        rs<-dbSendQuery(sim$castordb, qry, inv)
        dbClearResult(rs)
        dbExecute(sim$castordb, "CREATE INDEX index_pixelid on fueltype (pixelid)")
        dbCommit(sim$castordb)
        
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
print("getting vegetation data")

if (nrow(sim$inv)<1){
  inv<-data.table(dbGetQuery(sim$castordb, "SELECT * FROM fueltype"))
}

  veg_attributes<- data.table(dbGetQuery(sim$castordb, "SELECT pixelid, crownclosure, age, vol, height, dec_pcnt, blockid FROM pixels"))
  
  veg2<-merge(sim$inv, veg_attributes, by.x="pixelid", by.y = "pixelid", all.x=TRUE)
  
  rm(veg_attributes)
  gc()
  
}
  
  print("categorizing data into fuel types")
  
  #### Calculate fuel types ####
  
  # running the query from least specific to most specific so that I dont overwrite fuel types
  #veg2[, fwveg:="none"]
  
  # limited vegetation information  but has bec designation
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
  veg2[bclcs_level_1=="N" & earliest_nonlogging_dist_type %in% burn & (years_since_nonlogging_dist %between% c(4, 6)), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="N" & earliest_nonlogging_dist_type %in% burn & (years_since_nonlogging_dist %between% c(7,10)), fwveg:="O-1a/b"]
      
  ##------------------------------------------------##
  #### bclcs_level_1 == "V" & bclcs_level_2 =="N" ####
  ##------------------------------------------------##
  
  ### non-forested bclcs_level_2==N recently burned
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & earliest_nonlogging_dist_type %in% burn & years_since_nonlogging_dist < 2, fwveg:="N"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & earliest_nonlogging_dist_type %in% burn & years_since_nonlogging_dist %between% c(2,3), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="N" & earliest_nonlogging_dist_type %in% burn & years_since_nonlogging_dist %between% c(4,10), fwveg:="O-1a/b"]
  
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
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & conifer_pct_cover_total>=60 & crownclosure > 40 & earliest_nonlogging_dist_type %in% "burn" & years_since_nonlogging_dist  %between% c(4, 6), fwveg:="D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & conifer_pct_cover_total>=60 & crownclosure > 40 & earliest_nonlogging_dist_type %in% "burn" & years_since_nonlogging_dist  %between% c(7, 10), fwveg:= "C-5"]
  
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P", "XC"), fwveg:="C-3"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & species_pct_1> 79 & bclcs_level_5=="SP" & species_cd_1 %in% c("PL", "PLI", "PLC", "PJ", "P", "XC"), fwveg:="C-7"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & crownclosure <= 40 & earliest_nonlogging_dist_type %in% "burn" & years_since_nonlogging_dist < 2, fwveg:="N"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & conifer_pct_cover_total>=60 & crownclosure <= 40 & earliest_nonlogging_dist_type %in% "burn" & years_since_nonlogging_dist  %between% c(2,6), fwveg:= "D-1/2"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & conifer_pct_cover_total>=60 & crownclosure <= 40 & earliest_nonlogging_dist_type %in% "burn" & years_since_nonlogging_dist  %between% c(7,10), fwveg:="O-1a/b"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & conifer_pct_cover_total<60 &  earliest_nonlogging_dist_type %in% "burn" & years_since_nonlogging_dist  < 2, fwveg:="N"]
  veg2[bclcs_level_1=="V" & bclcs_level_2=="T" & conifer_pct_cover_total<60 &  earliest_nonlogging_dist_type %in% "burn" & years_since_nonlogging_dist  %between% c(2, 10), fwveg:="D-1/2"]
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
  
  veg2[, c("crownclosure", "age", "vol", "height", "dec_pcnt", "blockid"):=NULL]
  
  #veg2[, c("bclcs_level_1", "bclcs_level_2", "bclcs_level_3", "bclcs_level_5", "inventory_standard_cd", "non_productive_cd", "coast_interior_cd", "land_cover_class_cd_1", "zone", "subzone", "earliest_nonlogging_dist_type", "years_since_nonlogging_dist", "vri_live_stems_per_ha", "vri_dead_stems_per_ha", "species_cd_1", "species_pct_1", "species_cd_2", "species_pct_2", "dominant_conifer", "conifer_pct_cover_total", "crownclosure", "age", "vol", "height", "dec_pcnt", "blockid"):=NULL]
  
  #veg3<- veg2[, c("pixelid", "fwveg")]
  #veg3<-veg3[fwveg!="none", ]
  
  #### uploading fueltype layer to postgres ####
  
  print("updating fueltype table with fwveg data") 
  
  # for some reason updating the fueltype table takes for ever. So Ill drop the fueltype table and add it back. That's faster. Chat to Kyle about this later to find better solution.
  
  dbExecute(sim$castordb, "DROP TABLE fueltype")
  
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS fueltype (pixelid integer, bclcs_level_1 character, bclcs_level_2 character, bclcs_level_3 character,  bclcs_level_5 character, inventory_standard_cd character, non_productive_cd character, coast_interior_cd character,  land_cover_class_cd_1 character, zone character, subzone character, earliest_nonlogging_dist_type character, years_since_nonlogging_dist integer, vri_live_stems_per_ha numeric, vri_dead_stems_per_ha numeric, species_cd_1 character, species_pct_1 numeric, species_cd_2 character, species_pct_2 numeric, dominant_conifer character, conifer_pct_cover_total numeric, fwveg character)")
  
  qry<-paste0('INSERT INTO fueltype (pixelid, bclcs_level_1, bclcs_level_2, bclcs_level_3, bclcs_level_5, inventory_standard_cd, non_productive_cd, coast_interior_cd, land_cover_class_cd_1,  earliest_nonlogging_dist_type, vri_live_stems_per_ha, vri_dead_stems_per_ha, species_cd_1, species_pct_1, species_cd_2, species_pct_2, zone, subzone,years_since_nonlogging_dist, dominant_conifer, conifer_pct_cover_total, fwveg) values (:pixelid, :bclcs_level_1, :bclcs_level_2, :bclcs_level_3, :bclcs_level_5, :inventory_standard_cd, :non_productive_cd, :coast_interior_cd, :land_cover_class_cd_1, :earliest_nonlogging_dist_type, :vri_live_stems_per_ha, :vri_dead_stems_per_ha, :species_cd_1, :species_pct_1, :species_cd_2, :species_pct_2,:zone, :subzone, :years_since_nonlogging_dist, :dominant_conifer, :conifer_pct_cover_total, :fwveg)')
  
  #fueltype table
  dbBegin(sim$castordb)
  rs<-dbSendQuery(sim$castordb, qry, veg2)
  dbClearResult(rs)
  dbCommit(sim$castordb)
  
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
  rm(veg2, veg3)
  gc()

  return(invisible(sim)) 
  
}

calcProbFire<-function(sim){
  
  message("calculate probability of lightning")
  
  fwveg<-dbGetQuery(sim$castordb, "SELECT pixelid, fwveg from fueltype")
  
  if (!suppliedElsewhere(sim$fire_variables)) {
  sim$fire_variables<-dbGetQuery(sim$castordb, "SELECT * from firevariables")
  }
  
  dat<-merge(fwveg, sim$fire_variables, by.x="pixelid", by.y="pixelid", all.x=TRUE)
  dat<-merge(dat, sim$road_distance, by.x="pixelid", by.y="pixelid", all.x=TRUE)
  
  print("get coefficient table")
  
  if (!suppliedElsewhere(sim$coefficients)) {
  sim$coefficients<-as.data.table(getSpatialQuery("SELECT * FROM fire_model_coef_tbl; "))
  } else { print("coefficient table already loaded")}
  
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
         coefficients[cause == "Lightning" & frt==5,]$coef_climate_2 * climate2_lightning + 
         coefficients[cause == "Lightning" & frt==5,]$coef_c1 * veg_C1 +
         coefficients[cause == "Lightning" & frt==5,]$coef_c3 * veg_C3 +
         coefficients[cause == "Lightning" & frt==5,]$coef_c7 * veg_C7 +
         coefficients[cause == "Lightning" & frt==5,]$coef_d12 * veg_D12 +
         coefficients[cause == "Lightning" & frt==5,]$coef_m12 * veg_M12 +
         coefficients[cause == "Lightning" & frt==5,]$coef_o1ab * veg_O1ab]
  
  head(frt5)
  # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
  frt5[, prob_ignition_lightning := exp(logit_P_lightning)/(1+exp(logit_P_lightnin))]
  
  # PErson ignitions
  #model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT5_person.csv")
  frt5[, logit_P_human := ignitstatichuman  * all + 
         coefficients[cause == 'person' & frt == "5", ]$coef_climate_1 * climate1_person + 
         coefficients[cause == 'person' & frt==5,]$coef_log_road_dist  * log(rds_dist+1)]
       
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
         coefficients[cause == 'escape' & frt==5,]$coef_climate_1 * climate1_escape +
         coefficients[cause == 'escape' & frt==5,]$coef_c2 * veg_C2 +
         coefficients[cause == 'escape' & frt==5,]$coef_c3 * veg_C3 +
         coefficients[cause == 'escape' & frt==5,]$coef_d12 * veg_D12 +
         coefficients[cause == 'escape' & frt==5,]$coef_m12 * veg_M12 +
         coefficients[cause == 'escape' & frt==5,]$coef_N * veg_N +
         coefficients[cause == 'escape' & frt==5,]$coef_o1ab * veg_O1ab]
       
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
         coefficients[cause == 'spread' & frt==5,]$coef_climate_2 * climate2_spread+
         coefficients[cause == 'spread' & frt==5,]$coef_c2 * veg_C2 +
         coefficients[cause == 'spread' & frt==5,]$coef_c3 * veg_C3 +
         coefficients[cause == 'spread' & frt==5,]$coef_c5 * veg_C5 +
         coefficients[cause == 'spread' & frt==5,]$coef_c7 * veg_C7 +
         coefficients[cause == 'spread' & frt==5,]$coef_d12 * veg_D12 +
         coefficients[cause == 'spread' & frt==5,]$coef_m12 * veg_M12 +
         coefficients[cause == 'spread' & frt==5,]$coef_m3 * veg_M3 +
         coefficients[cause == 'spread' & frt==5,]$coef_N * veg_N +
         coefficients[cause == 'spread' & frt==5,]$coef_o1ab * veg_O1ab +
         coefficients[cause == 'spread' & frt==5,]$coef_s2 * veg_S2 +
         coefficients[cause == 'spread' & frt==5,]$coef_road_dist * rds_dist]
  
  frt5[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
  
  frt5[, prob_tot_ignit := prob_ignition_lightning*0.84 + prob_ignition_person*0.16]
  
  frt5<-frt5[, c("pixelid","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]
  
  } else {
    
    print("no data for FRT 5")
    
    frt5<-data.table(pixelid=as.numeric(),
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
    coefficients[cause=="Lightning" & frt==7,]$coef_climate_1 * climate1_lightning + 
    coefficients[cause=="Lightning" & frt==7,]$coef_c1 * veg_C1 +
    coefficients[cause=="Lightning" & frt==7,]$coef_c3 * veg_C3 +
    coefficients[cause=="Lightning" & frt==7,]$coef_d12 * veg_D12 +
    coefficients[cause=="Lightning" & frt==7,]$coef_m12 * veg_M12 +
    coefficients[cause=="Lightning" & frt==7,]$coef_o1ab * veg_O1ab]

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
      coefficients[cause == 'person' & frt == 7, ]$coef_climate_1 * climate1_person + 
      coefficients[cause == 'person' & frt==7,]$coef_c2*veg_C2 +
      coefficients[cause == 'person' & frt==7,]$coef_c3*veg_C3 +
      coefficients[cause == 'person' & frt==7,]$coef_c7*veg_C7 +
      coefficients[cause == 'person' & frt==7,]$coef_d12*veg_D12 +
      coefficients[cause == 'person' & frt==7,]$coef_m12*veg_M12 +
      coefficients[cause == 'person' & frt==7,]$coef_m3*veg_M3 +
      coefficients[cause == 'person' & frt==7,]$coef_N*veg_N +
      coefficients[cause == 'person' & frt==7,]$coef_o1ab*veg_O1ab +
      coefficients[cause == 'person' & frt==7,]$coef_log_road_dist  * log(rds_dist+1)]
       
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
       
  # change veg categories to ones that we have coefficients
  frt7[fwveg == "C-4", veg_C2 := 1]
  frt7[fwveg == "C-5", veg_D12 := 1]
  frt7[fwveg == "C-7", veg_D12 := 1]
  frt7[fwveg == "S-1", veg_M12 := 1]
  frt7[fwveg == "S-2", veg_M12 := 1]
       
       
  frt7[, logit_P_escape := escapestatic * all + 
    coefficients[cause == 'escape' & frt==7,]$coef_climate_2 * climate2_escape +
    coefficients[cause == 'escape' & frt==7,]$coef_c1 * veg_C1 +
    coefficients[cause == 'escape' & frt==7,]$coef_c3 * veg_C3 +
    coefficients[cause == 'escape' & frt==7,]$coef_d12 * veg_D12 +
    coefficients[cause == 'escape' & frt==7,]$coef_m12 * veg_M12 +
    coefficients[cause == 'escape' & frt==7,]$coef_N * veg_N +
    coefficients[cause == 'escape' & frt==7,]$coef_o1ab * veg_O1ab]
       
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
       
       # change veg categories to ones that we have coefficients
       frt7[fwveg == "C-5", veg_C7 := 1]
       frt7[fwveg == "M-3", veg_O1ab := 1]
       
    frt7[, logit_P_spread := spreadstatic * all + 
      coefficients[cause == 'spread' & frt==7,]$coef_climate_1 * climate1_spread+
      coefficients[cause == 'spread' & frt==7,]$coef_climate_2 * climate2_spread+
      coefficients[cause == 'spread' & frt==7,]$coef_c2 * veg_C2 +
      coefficients[cause == 'spread' & frt==7,]$coef_c3 * veg_C3 +
      coefficients[cause == 'spread' & frt==7,]$coef_c7 * veg_C7 +
      coefficients[cause == 'spread' & frt==7,]$coef_d12 * veg_D12 +
      coefficients[cause == 'spread' & frt==7,]$coef_m12 * veg_M12 +
      coefficients[cause == 'spread' & frt==7,]$coef_N * veg_N +
      coefficients[cause == 'spread' & frt==7,]$coef_o1ab * veg_O1ab +
      coefficients[cause == 'spread' & frt==7,]$coef_s1 * veg_S1 +
      coefficients[cause == 'spread' & frt==7,]$coef_s2 * veg_S2 +
      coefficients[cause == 'spread' & frt==7,]$coef_log_road_dist * log(rds_dist+1)]
       
       frt7[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
       
       frt7[, prob_tot_ignit := prob_ignition_lightning*0.16 + (prob_ignition_person*0.84)]
       
      frt7<-frt7[, c("pixelid","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]
      
  } else {
    
    print("no data for FRT 7")
    
    frt7<-data.table(pixelid=as.numeric(),
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
    coefficients[cause == "Lightning" & frt==9,]$coef_climate_1*climate1_lightning + 
    coefficients[cause == "Lightning" & frt==9,]$coef_c1 * veg_C1 +
    coefficients[cause == "Lightning" & frt==9,]$coef_c2 * veg_C2 +
    coefficients[cause == "Lightning" & frt==9,]$coef_c7 * veg_C7 +
    coefficients[cause == "Lightning" & frt==9,]$coef_m12 * veg_M12 +
    coefficients[cause == "Lightning" & frt==9,]$coef_n * veg_N +
    coefficients[cause == "Lightning" & frt==9,]$coef_o1ab * veg_O1ab]
    
    # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
    frt9[, prob_ignition_lightning<-exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
    
  # Person caused fires
  # model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT9_person.csv")
  frt9[, logit_P_human := ignitstatichuman  * all + 
      coefficients[cause == 'person' & frt == 9, ]$coef_climate_1 * climate1_person]
         
         frt9[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
         
  # Fire Escape
#  model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt9_escape.csv")
         
  frt9[, logit_P_escape := escapestatic * all + 
        coefficients[cause == 'escape' & frt==9,]$coef_climate_1 * climate1_escape +
        coefficients[cause == 'escape' & frt==9,]$coef_log_road_dist * log(rds_dist+1)]
         
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
         
         # change veg categories to ones that we have coefficients
    frt9[fwveg == "C-4", veg_C2 := 1]
    frt9[fwveg == "C-5", veg_C7 := 1]
    frt9[fwveg == "S-1", veg_M12 := 1]
         
    frt9[, logit_P_spread := spreadstatic * all + 
        coefficients[cause == 'spread' & frt==9,]$coef_climate_1 * climate1_spread+
        coefficients[cause == 'spread' & frt==9,]$coef_climate_2 * climate2_spread+
        coefficients[cause == 'spread' & frt==9,]$coef_c2 * veg_C2 +
        coefficients[cause == 'spread' & frt==9,]$coef_c3 * veg_C3 +
        coefficients[cause == 'spread' & frt==9,]$coef_c7 * veg_C7 +
        coefficients[cause == 'spread' & frt==9,]$coef_d12 * veg_D12 +
        coefficients[cause == 'spread' & frt==9,]$coef_m12 * veg_M12 +
        coefficients[cause == 'spread' & frt==9,]$coef_N * veg_N +
        coefficients[cause == 'spread' & frt==9,]$coef_o1ab * veg_O1ab +
        coefficients[cause == 'spread' & frt==9,]$coef_log_road_dist * log(rds_dist+1)]
         
  frt9[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
  
  frt9[, prob_tot_ignit := (prob_ignition_lightning*0.7) + (prob_ignition_person*0.3)]
  
  
  frt9<-frt9[, c("pixelid","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]
  } else {
    
    print("no data for FRT 9")
    
    frt9<-data.table(pixelid=as.numeric(),
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
      coefficients[cause == 'lightning' & frt==10,]$coef_climate_1*climate1_lightning + 
      coefficients[cause == 'lightning' & frt==10,]$coef_climate_2*climate2_lightning + 
      coefficients[cause == 'lightning' & frt==10,]$coef_c3 * veg_C3 +
      coefficients[cause == 'lightning' & frt==10,]$coef_c5 * veg_C5 +
      coefficients[cause == 'lightning' & frt==10,]$coef_c7 * veg_C7 +
      coefficients[cause == 'lightning' & frt==10,]$coef_d12 * veg_D12 +
      coefficients[cause == 'lightning' & frt==10,]$coef_m12 * veg_M12 +
      coefficients[cause == 'lightning' & frt==10,]$coef_N * veg_N +
      coefficients[cause == 'lightning' & frt==10,]$coef_o1ab * veg_O1ab]
    
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
      coefficients[cause == 'person' & frt == 10, ]$coef_climate_1 * climate1_person + 
      coefficients[cause == 'person' & frt == 10, ]$coef_c3 * veg_C3 +
      coefficients[cause == 'person' & frt == 10, ]$coef_c5 * veg_C5 +
      coefficients[cause == 'person' & frt == 10, ]$coef_c7 * veg_C7 +
      coefficients[cause == 'person' & frt == 10, ]$coef_N * veg_N +
      coefficients[cause == 'person' & frt == 10, ]$coef_log_road_dist * log(rds_dist+1) ]
         
         frt10[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
         
         # Fire Escape
   #  model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt10_escape.csv")
         
    frt10[, logit_P_escape := escapestatic * all + 
        coefficients[cause == 'escape' & frt==10,]$coef_climate_1 * climate1_escape +
        coefficients[cause == 'escape' & frt==10,]$coef_road_dist * rds_dist]
         
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
        coefficients[cause == 'spread' & frt==10,]$coef_climate_1 * climate1_spread+
        coefficients[cause == 'spread' & frt==10,]$coef_climate_2 * climate2_spread+
        coefficients[cause == 'spread' & frt==10,]$coef_c2 * veg_C2 +
        coefficients[cause == 'spread' & frt==10,]$coef_c3 * veg_C3 +
        coefficients[cause == 'spread' & frt==10,]$coef_c5 * veg_C5 +
        coefficients[cause == 'spread' & frt==10,]$coef_c7 * veg_C7 +
        coefficients[cause == 'spread' & frt==10,]$coef_d12 * veg_D12 +
        coefficients[cause == 'spread' & frt==10,]$coef_m12 * veg_M12 +
        coefficients[cause == 'spread' & frt==10,]$coef_m3 * veg_M3 +
        coefficients[cause == 'spread' & frt==10,]$coef_N * veg_N +
        coefficients[cause == 'spread' & frt==10,]$coef_o1ab * veg_O1ab +
        coefficients[cause == 'spread' & frt==10,]$coef_s1 * veg_S1]
         
    frt10[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
    
    
    frt10[, prob_tot_ignit := (prob_ignition_lightning*0.86) + (prob_ignition_person*0.14)]

    
    frt10<-frt10[, c("pixelid","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]
  } else {
    
    print("no data for FRT 10")
    
    frt10<-data.table(pixelid=as.numeric(),
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
      coefficients[cause == 'lightning' & frt==11,]$coef_climate_1 * climate1_lightning + 
      coefficients[cause == 'lightning' & frt==11,]$coef_climate_2 * climate2_lightning + 
      coefficients[cause == 'lightning' & frt==11,]$coef_c1 * veg_C1 +
      coefficients[cause == 'lightning' & frt==11,]$coef_c2 * veg_C2 +
      coefficients[cause == 'lightning' & frt==11,]$coef_c7 * veg_C7 +
      coefficients[cause == 'lightning' & frt==11,]$coef_m12 * veg_M12 +
      coefficients[cause == 'lightning' & frt==11,]$coef_N * veg_N]
    
    # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
    frt11[, prob_ignition_lightning<-exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
    
    
    # Person caused fires
#   model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT11_person.csv")
    frt11[, logit_P_human := ignitstatichuman  * all + 
            coefficients[cause == 'person' & frt == 11, ]$coef_climate_1 * climate1_person +
            coefficients[cause == 'person' & frt == 11, ]$coef_log_road_dist * log(rds_dist+1) ]
    
    frt11[,prob_ignition_person := exp(logit_P_human)/(1+exp(logit_P_human))]
    
    # Fire Escape
 #   model_coef_table_escape<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt11_escape.csv")
    
    frt11[, logit_P_escape := escapestatic * all + 
            coefficients[cause == 'escape' & frt==11,]$coef_climate_1 * climate1_escape]
    
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
        coefficients[cause == 'spread' & frt==11,]$coef_climate_2 * climate2_spread +
        coefficients[cause == 'spread' & frt==11,]$coef_c2 * veg_C2 +
        coefficients[cause == 'spread' & frt==11,]$coef_c3 * veg_C3 +
        coefficients[cause == 'spread' & frt==11,]$coef_c5 * veg_C5 +
        coefficients[cause == 'spread' & frt==11,]$coef_c7 * veg_C7 +
        coefficients[cause == 'spread' & frt==11,]$coef_d12 * veg_D12 +
        coefficients[cause == 'spread' & frt==11,]$coef_m12 * veg_M12 +
        coefficients[cause == 'spread' & frt==11,]$coef_N * veg_N +
        coefficients[cause == 'spread' & frt==11,]$coef_o1ab * veg_O1ab +
        coefficients[cause == 'spread' & frt==11,]$coef_road_dist * rds_dist]
    
  frt11[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
  
  frt11[, prob_tot_ignit := (prob_ignition_lightning*0.42) + (prob_ignition_person*0.58)]
  
  frt11<-frt11[, c("pixelid","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]  
  } else {
    
    print("no data for FRT 11")
    
    frt11<-data.table(pixelid = as.integer(),
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
      coefficients[cause == 'lightning' & frt==12,]$coef_climate_1 * climate1_lightning + 
      coefficients[cause == 'lightning' & frt==12,]$coef_c2 * veg_C2 +
      coefficients[cause == 'lightning' & frt==12,]$coef_c3 * veg_C3 +
      coefficients[cause == 'lightning' & frt==12,]$coef_c4 * veg_C4 +
      coefficients[cause == 'lightning' & frt==12,]$coef_c5 * veg_C5 +
      coefficients[cause == 'lightning' & frt==12,]$coef_c7 * veg_C7 +
      coefficients[cause == 'lightning' & frt==12,]$coef_d12 * veg_D12 +
      coefficients[cause == 'lightning' & frt==12,]$coef_m12 * veg_M12 +
      coefficients[cause == 'lightning' & frt==12,]$coef_m3 * veg_M3 +
      coefficients[cause == 'lightning' & frt==12,]$coef_N * veg_N + 
      coefficients[cause == 'lightning' & frt==12,]$coef_o1ab * veg_O1ab +
      coefficients[cause == 'lightning' & frt==12,]$coef_s1 * veg_S1 +
      coefficients[cause == 'lightning' & frt==12,]$coef_s2 * veg_S2]
      
    
    # y = e^(b0 + b1*x) / (1 + e^(b0 + b1*x))
    frt12[, prob_ignition_lightning := exp(logit_P_lightning)/(1+exp(logit_P_lightning))]
    
    # Person caused fires
 #  model_coef_table_person<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_FRT12_person.csv")
    frt12[, logit_P_human := ignitstatichuman  * all + 
            coefficients[cause == 'person' & frt == 12, ]$coef_climate_1 * climate1_person +
            coefficients[cause == 'person' & frt == 12, ]$coef_log_road_dist * log(rds_dist+1) ]
    
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
      coefficients[cause == 'escape' & frt==12,]$coef_climate_1 * climate1_escape + 
      coefficients[cause == 'escape' & frt==12,]$coef_climate_2 * climate2_escape +
      coefficients[cause == 'escape' & frt==12,]$coef_c2 * veg_C2 +
      coefficients[cause == 'escape' & frt==12,]$coef_c5 * veg_C5 + 
      coefficients[cause == 'escape' & frt==12,]$coef_c7 * veg_C7 +
      coefficients[cause == 'escape' & frt==12,]$coef_d12 * veg_D12 +
      coefficients[cause == 'escape' & frt==12,]$coef_m12 * veg_M12 +
      coefficients[cause == 'escape' & frt==12,]$coef_N * veg_N +
      coefficients[cause == 'escape' & frt==12,]$coef_o1ab * veg_O1ab +
      coefficients[cause == 'escape' & frt==12,]$coef_s1 * veg_S1 +
      coefficients[cause == 'escape' & frt==12,]$coef_s2 * veg_S2 +
      coefficients[cause == 'escape' & frt==12,]$coef_road_dist * rds_dist]
    
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
            coefficients[cause == 'spread' & frt==12,]$coef_climate_2 * climate2_spread +
            coefficients[cause == 'spread' & frt==12,]$coef_c2 * veg_C2 +
            coefficients[cause == 'spread' & frt==12,]$coef_c3 * veg_C3 +
            coefficients[cause == 'spread' & frt==12,]$coef_c4 * veg_C4 +
            coefficients[cause == 'spread' & frt==12,]$coef_c5 * veg_C5 +
            coefficients[cause == 'spread' & frt==12,]$coef_c7 * veg_C7 +
            coefficients[cause == 'spread' & frt==12,]$coef_d12 * veg_D12 +
            coefficients[cause == 'spread' & frt==12,]$coef_m12 * veg_M12 +
            coefficients[cause == 'spread' & frt==12,]$coef_m3 * veg_M3 +
            coefficients[cause == 'spread' & frt==12,]$coef_N * veg_N +
            coefficients[cause == 'spread' & frt==12,]$coef_o1ab * veg_O1ab +
            coefficients[cause == 'spread' & frt==12,]$coef_s1 * veg_S1 +
            coefficients[cause == 'spread' & frt==12,]$coef_s2 * veg_S2 +
            coefficients[cause == 'spread' & frt==12,]$coef_log_road_dist * log(rds_dist+1)]
    
    frt12[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
    
    frt12[, prob_tot_ignit := (prob_ignition_lightning*0.48) + (prob_ignition_person*0.52)]
    
    frt12<-frt12[, c("pixelid","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]    
  } else {
    
    print("no data for FRT 12")
    
    frt12<-data.table(pixelid = as.numeric(),
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
            coefficients[cause == 'lightning' & frt==13,]$coef_climate_1 * climate1_lightning +
            coefficients[cause == 'lightning' & frt==13,]$coef_climate_2 * climate2_lightning +
            coefficients[cause == 'lightning' & frt==13,]$coef_c3 * veg_C3 +
            coefficients[cause == 'lightning' & frt==13,]$coef_c5 * veg_C5 +
            coefficients[cause == 'lightning' & frt==13,]$coef_c7 * veg_C7 +
            coefficients[cause == 'lightning' & frt==13,]$coef_d12 * veg_D12 +
            coefficients[cause == 'lightning' & frt==13,]$coef_m12 * veg_M12 +
            coefficients[cause == 'lightning' & frt==13,]$coef_N * veg_N + 
            coefficients[cause == 'lightning' & frt==13,]$coef_o1ab * veg_O1ab +
            coefficients[cause == 'lightning' & frt==13,]$coef_s1 * veg_S1 +
            coefficients[cause == 'lightning' & frt==13,]$coef_s2 * veg_S2 +
            coefficients[cause == 'lightning' & frt==13,]$coef_s3 * veg_S3]
    
    
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
      coefficients[cause == 'person' & frt == 13, ]$coef_climate_1 * climate1_person +
      coefficients[cause == 'person' & frt == 13, ]$coef_climate_2 * climate2_person +
      coefficients[cause == 'person' & frt == 13, ]$coef_log_road_dist * log(rds_dist+1) +
        coefficients[cause == 'person' & frt == 13, ]$coef_c3 * veg_C3 +
        coefficients[cause == 'person' & frt == 13, ]$coef_c5 * veg_C5 +
        coefficients[cause == 'person' & frt == 13, ]$coef_c7 * veg_C7 +
        coefficients[cause == 'person' & frt == 13, ]$coef_d12 * veg_D12 +
        coefficients[cause == 'person' & frt == 13, ]$coef_m12 * veg_M12 +
        coefficients[cause == 'person' & frt == 13, ]$coef_m3 * veg_M3 +
        coefficients[cause == 'person' & frt == 13, ]$coef_N * veg_N +
        coefficients[cause == 'person' & frt == 13, ]$coef_o1ab * veg_O1ab +
        coefficients[cause == 'person' & frt == 13, ]$coef_s1 * veg_S1+
        coefficients[cause == 'person' & frt == 13, ]$coef_s3 * veg_S3 
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
            coefficients[cause == 'escape' & frt==13,]$coef_climate_1 * climate1_escape + 
            coefficients[cause == 'escape' & frt==13,]$coef_climate_2 * climate2_escape +
            coefficients[cause == 'escape' & frt==13,]$coef_c3 * veg_C3 +
            coefficients[cause == 'escape' & frt==13,]$coef_c5 * veg_C5 + 
            coefficients[cause == 'escape' & frt==13,]$coef_c7 * veg_C7 +
            coefficients[cause == 'escape' & frt==13,]$coef_d12 * veg_D12 +
            coefficients[cause == 'escape' & frt==13,]$coef_m12 * veg_M12 +
            coefficients[cause == 'escape' & frt==13,]$coef_m3 * veg_M3 +
            coefficients[cause == 'escape' & frt==13,]$coef_N * veg_N +
            coefficients[cause == 'escape' & frt==13,]$coef_o1ab * veg_O1ab +
            coefficients[cause == 'escape' & frt==13,]$coef_s1 * veg_S1 +
            coefficients[cause == 'escape' & frt==13,]$coef_s2 * veg_S2 +
            coefficients[cause == 'escape' & frt==13,]$coef_s3 * veg_S3 +
            coefficients[cause == 'escape' & frt==13,]$coef_road_dist * rds_dist]
    
    frt13[,prob_ignition_escape := exp(logit_P_escape)/(1+exp(logit_P_escape))]
    
    # Spread
 #   model_coef_table_spread<-read.csv("C:\\Work\\caribou\\castor\\R\\fire_sim\\Analysis_results\\BC\\Coefficient_tables\\top_mod_table_frt13_spread.csv")
    
    frt13[, veg_C2 := 0]
    frt13[fwveg == "C-2", veg_C2 := 1]
    frt13[, veg_C3 := 0]
    frt13[fwveg == "C-3", veg_C3 := 1]
    
    frt13[fwveg == "C-1", veg_C3 :=1]
    
    frt13[, logit_P_spread := spreadstatic * all + 
            coefficients[cause == 'spread' & frt==13,]$coef_climate_2 * climate2_spread +
            coefficients[cause == 'spread' & frt==13,]$coef_c3 * veg_C3 +
            coefficients[cause == 'spread' & frt==13,]$coef_c5 * veg_C5 +
            coefficients[cause == 'spread' & frt==13,]$coef_c7 * veg_C7 +
            coefficients[cause == 'spread' & frt==13,]$coef_d12 * veg_D12 +
            coefficients[cause == 'spread' & frt==13,]$coef_m12 * veg_M12 +
            coefficients[cause == 'spread' & frt==13,]$coef_m3 * veg_M3 +
            coefficients[cause == 'spread' & frt==13,]$coef_N * veg_N +
            coefficients[cause == 'spread' & frt==13,]$coef_o1ab * veg_O1ab +
            coefficients[cause == 'spread' & frt==13,]$coef_s1 * veg_S1 +
            coefficients[cause == 'spread' & frt==13,]$coef_s2 * veg_S2 +
            coefficients[cause == 'spread' & frt==13,]$coef_s3 * veg_S3 +
            coefficients[cause == 'spread' & frt==13,]$coef_log_road_dist * log(rds_dist+1)]
    
    frt13[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
    
    frt13[, prob_tot_ignit := (prob_ignition_lightning*0.83) + (prob_ignition_person*0.17)]
    
    frt13<-frt13[, c("pixelid", "prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]
    
  } else {
    
    print("no data for FRT 13")
    
    frt13<-data.table(pixelid=as.numeric(), 
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
            coefficients[cause == 'lightning' & frt==14,]$coef_climate_1 * climate1_lightning +
            coefficients[cause == 'lightning' & frt==14,]$coef_c3 * veg_C3 +
            coefficients[cause == 'lightning' & frt==14,]$coef_c5 * veg_C5 +
            coefficients[cause == 'lightning' & frt==14,]$coef_c7 * veg_C7 +
            coefficients[cause == 'lightning' & frt==14,]$coef_d12 * veg_D12 +
            coefficients[cause == 'lightning' & frt==14,]$coef_m12 * veg_M12 +
            coefficients[cause == 'lightning' & frt==14,]$coef_m3 * veg_M3 +
            coefficients[cause == 'lightning' & frt==14,]$coef_N * veg_N + 
            coefficients[cause == 'lightning' & frt==14,]$coef_o1ab * veg_O1ab +
            coefficients[cause == 'lightning' & frt==14,]$coef_s1 * veg_S1]
    
    
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
            coefficients[cause == 'person' & frt == 14, ]$coef_climate_1 * climate1_person +
            coefficients[cause == 'person' & frt == 14, ]$coef_log_road_dist * log(rds_dist+1) +
            coefficients[cause == 'person' & frt == 14, ]$coef_c3 * veg_C3 +
            coefficients[cause == 'person' & frt == 14, ]$coef_c5 * veg_C5 +
            coefficients[cause == 'person' & frt == 14, ]$coef_c7 * veg_C7 +
            coefficients[cause == 'person' & frt == 14, ]$coef_d12 * veg_D12 +
            coefficients[cause == 'person' & frt == 14, ]$coef_m12 * veg_M12 +
            coefficients[cause == 'person' & frt == 14, ]$coef_N * veg_N +
            coefficients[cause == 'person' & frt == 14, ]$coef_o1ab * veg_O1ab +
            coefficients[cause == 'person' & frt == 14, ]$coef_s1 * veg_S1
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
      coefficients[cause == 'escape' & frt==14,]$coef_climate_1 * climate1_escape +
      coefficients[cause == 'escape' & frt==14,]$coef_c7 * veg_C7 +
      coefficients[cause == 'escape' & frt==14,]$coef_d12 * veg_D12 +
      coefficients[cause == 'escape' & frt==14,]$coef_m12 * veg_M12 +
      coefficients[cause == 'escape' & frt==14,]$coef_N * veg_N +
      coefficients[cause == 'escape' & frt==14,]$coef_o1ab * veg_O1ab +
      coefficients[cause == 'escape' & frt==14,]$coef_road_dist * rds_dist]
    
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
            coefficients[cause == 'spread' & frt==14,]$coef_climate_2 * climate2_spread +
            coefficients[cause == 'spread' & frt==14]$coef_c3 * veg_C3 +
            coefficients[cause == 'spread' & frt==14,]$coef_c5 * veg_C5 +
            coefficients[cause == 'spread' & frt==14,]$coef_c7 * veg_C7 +
            coefficients[cause == 'spread' & frt==14,]$coef_d12 * veg_D12 +
            coefficients[cause == 'spread' & frt==14,]$coef_m12 * veg_M12 +
            coefficients[cause == 'spread' & frt==14,]$coef_N * veg_N +
            coefficients[cause == 'spread' & frt==14,]$coef_o1ab * veg_O1ab +
            coefficients[cause == 'spread' & frt==14,]$coef_s1 * veg_S1 +
            coefficients[cause == 'spread' & frt==14,]$coef_road_dist * rds_dist]
    
    frt14[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
    
    frt14[, prob_tot_ignit := (prob_ignition_lightning*0.41) + (prob_ignition_person*0.59)]
  
    frt14<-frt14[, c("pixelid","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]
    
  } else {
    
    print("no data for FRT 14")
    
    frt14<-data.table(pixelid= as.numeric(),
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
            coefficients[cause == 'lightning' & frt==15,]$coef_climate_2 * climate2_lightning +
            coefficients[cause == 'lightning' & frt==15,]$coef_c5 * veg_C5 +
            coefficients[cause == 'lightning' & frt==15,]$coef_c7 * veg_C7 +
            coefficients[cause == 'lightning' & frt==15,]$coef_d12 * veg_D12 +
            coefficients[cause == 'lightning' & frt==15,]$coef_m12 * veg_M12 +
            coefficients[cause == 'lightning' & frt==15,]$coef_N * veg_N + 
            coefficients[cause == 'lightning' & frt==15,]$coef_s3 * veg_S3]
    
    
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
            coefficients[cause == 'person' & frt == 15, ]$coef_climate_1 * climate1_person +
            coefficients[cause == 'person' & frt == 15, ]$coef_climate_1 * climate1_person +
            coefficients[cause == 'person' & frt == 15, ]$coef_log_road_dist * log(rds_dist+1) +
            coefficients[cause == 'person' & frt == 15, ]$coef_c5 * veg_C5 +
            coefficients[cause == 'person' & frt == 15, ]$coef_d12 * veg_D12 +
            coefficients[cause == 'person' & frt == 15, ]$coef_m12 * veg_M12 +
            coefficients[cause == 'person' & frt == 15, ]$coef_N * veg_N +
            coefficients[cause == 'person' & frt == 15, ]$coef_o1ab * veg_O1ab +
            coefficients[cause == 'person' & frt == 15, ]$coef_s3 * veg_S3
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
    
    frt15[, logit_P_escape := escapestatic * all + 
            coefficients[cause == 'escape' & frt==15,]$coef_climate_2 * climate2_escape +
            coefficients[cause == 'escape' & frt==15,]$coef_c5 * veg_C5 +
            coefficients[cause == 'escape' & frt==15,]$coef_d12 * veg_D12 +
            coefficients[cause == 'escape' & frt==15,]$coef_m12 * veg_M12 +
            coefficients[cause == 'escape' & frt==15,]$coef_N * veg_N +
            coefficients[cause == 'escape' & frt==15,]$coef_S3 * veg_S3]
    
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
            coefficients[cause == 'spread' & frt==15,]$coef_climate_1 * climate1_spread +
            coefficients[cause == 'spread' & frt==15,]$coef_climate_2 * climate2_spread +
            coefficients[cause == 'spread' & frt==15]$coef_c5 * veg_C5 +
            coefficients[cause == 'spread' & frt==15,]$coef_c7 * veg_C7 +
            coefficients[cause == 'spread' & frt==15,]$coef_d12 * veg_D12 +
            coefficients[cause == 'spread' & frt==15,]$coef_m12 * veg_M12 +
            coefficients[cause == 'spread' & frt==15,]$coef_N * veg_N +
            coefficients[cause == 'spread' & frt==15,]$coef_o1ab * veg_O1ab +
            coefficients[cause == 'spread' & frt==15,]$coef_s3 * veg_S3]
    
    frt15[,prob_ignition_spread := exp(logit_P_spread)/(1+exp(logit_P_spread))]
    
    frt15[, prob_tot_ignit := (prob_ignition_lightning*0.28) + (prob_ignition_person*0.72)]
    
    frt15<-frt15[, c("pixelid","prob_ignition_lightning", "prob_ignition_person", "prob_ignition_escape", "prob_ignition_spread", "prob_tot_ignit")]    
  } else {
    
    print("no data for FRT 15")
    
    frt15<-data.table(pixelid = as.numeric(),
                      prob_ignition_lightning = as.integer(),
                     prob_ignition_person = as.integer(), 
                     prob_ignition_escape = as.integer(),
                     prob_ignition_spread = as.integer(),
                     prob_tot_ignit = as.integer())
  } 
  
  
  #### rbind frt data ####
  
  sim$probFireRasts<- do.call("rbind", list(frt5, frt7, frt9, frt10, frt11, frt12, frt13, frt14, frt15))
  
  
 
  return(invisible(sim))
}

distProcess <- function(sim) {
  
  total_area_burned= integer(P(sim, "numberFireReps", "fireCastor"))
  number_escaped = numeric(P(sim, "numberFireReps", "fireCastor"))
  
  
  if (suppliedElsewhere(sim$probFireRasts)) {
    
    probfire<-na.omit(sim$probFireRasts)
    no_starts_sample<-ceiling((mean(sim$ignit_data) + 3*sd(sim$ignit_data))*8)
    # sample more starting locations than needed and then discard extra after testing whether those locations actually ignite comparing its probability of igntion to a random number
    # get starting pixelids
    starts<-sample(probfire$pixelid, no_starts_sample, replace=FALSE)
    
    fire<-probfire[pixelid %in% starts,]
    fire$randomnumber<-runif(no_starts_sample)
    start<-fire[prob_tot_ignit>randomnumber, ]
    
    # take top ignition points up to the number of (no_ignitions) discard the rest. 
    
    starts<-start[1:sim$no_ignitions]
    starts$randomnumber<-runif(nrow(starts))
    #escaped fires
    escape.pts<- starts[prob_ignition_escape > randomnumber ]
    number_escaped[i]<-nrow(escape.pts)
    
    out <- spread2(landscape = sim$spreadRas, start = escape.pts, spreadProb = sim$spreadRas, asRaster = FALSE)
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, "UPDATE pixels SET age = 0, vol = 0,  salvage_vol = 0, earliest_nonlogging_dist_type = 'burn', years_since_nonlogging_dist = 0, vri_live_stems_per_ha = 0 WHERE pixelid = :pixels", out[, "pixels"])
    

    #    gsub('\"', '', sim$boundaryInfo[[3]])
  
    
#      starts <- sample(dbGetQuery(sim$castordb, paste0("select pixelid from pixels where compartid == \'", sim$boundaryInfo[[3]],"\'"))$pixelid, sim$no_ignitions, replace = FALSE)
      
      # figure out how to get the cell numbers that are no NA. Then test if they ignite and if they do keep those numbers otherwise discard and retry a different number.
      
      
      #extract probability numbers from the igniton map
      if(sim$probFireRasts$prob_tot_ignit[starts] > 0 { 
        ignit<-
      } 
      #draw random number from uniform distribution
      random.num<-runif(sim$no_ignitions)
      
      
    # test if fires escape   
    distStarts$escape<-sim$escapeRas[distStarts$starts]>runif(length(distStarts$starts))
        
        out <- spread2(landscape = sim$spreadRas, start = distStarts$escape, exactSize = distStarts$size, spreadProbRel = sim$spreadRas, asRaster = FALSE)
        dbBegin(sim$castordb)
        rs<-dbSendQuery(sim$castordb, "UPDATE pixels SET age = 0, vol = 0,  salvage_vol = 0, earliest_nonlogging_dist_type = 'burn', years_since_nonlogging_dist = 0, vri_live_stems_per_ha = 0 WHERE pixelid = :pixels", out[, "pixels"])
        dbClearResult(rs)
        dbCommit(sim$castordb)
        tempReport<-data.table(sim$disturbanceFlow[compartment == compart & period == time(sim) & flow > 0,], count=nrow(distStarts), med=median(distStarts$size), total=sum(distStarts$size), thlb = dbGetQuery(sim$castordb, paste0(" select sum(thlb) as thlb from pixels where pixelid in (", paste(out$pixels, sep = "", collapse = ","), ");"))$thlb)
        sim$disturbanceProcessReport<-rbindlist(list(sim$disturbanceProcessReport,tempReport ))
      }
      
    
  }
  
  
  return(invisible(sim))
}

numberStarts<-function(sim){
  
  library(bcdata)
  ignit<-try(
    bcdc_query_geodata("WHSE_LAND_AND_NATURAL_RESOURCE.PROT_HISTORICAL_INCIDENTS_SP") %>%
      filter(FIRE_YEAR > 2000) %>%
      filter(FIRE_TYPE == "Fire") %>%
      collect()
  )
  
  study_area<-getSpatialQuery(paste0("SELECT * FROM ", sim$boundaryInfo[[1]]))
  
  ignit <- ignit[study_area, ]
  
  library(dplyr)
  
  data <- ignit %>% group_by(FIRE_YEAR) %>% summarize(n=n()) %>% mutate(freq=n/sum(n)) 
  
  sim$ignit_data<-data$n
  
  maxignitions<-mean(sim$ignit_data) + 3*sd(sim$ignit_data)
  
  # initiate ignitions at randomly chosen points
  sim$no_ignitions<-round(rnorm(1, mean=mean(sim$ignit_data), sd=sd(sim$ignit_data)),0)
  sim$no_ignitions<-ifelse(sim$no_ignitions<0, 4, sim$no_ignitions)
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
