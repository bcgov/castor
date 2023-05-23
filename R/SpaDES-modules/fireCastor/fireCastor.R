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
      sim <- getStaticFireVariables(sim) # create table with static fire variables to calculate probability of ignition, escape, spread
      
      if(nrow(sim$road_distance) < 1){
        sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor") , "fireCastor", "roadDistanceCalc", 9)
      }
      
      roadDistanceCalc ={
        sim <- roadDistCalc(sim)
        sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastor"), "fireCastor", "roadDistanceCalc", 9)
      }
      
      sim <- getDistanceToRoad(sim)
      sim <- getClimateVariables (sim)
      
      if(nrow(dbGetQuery(sim$castordb, "SELECT * FROM sqlite_master WHERE type = 'table' and name ='fueltype'")) == 0){
        message('Creating fueltypes table')
        
      sim <- createVegetationTable(sim)
      sim <- scheduleEvent(sim, eventTime = time(sim),  "fireCastor", "calcFuelTypes", eventPriority=8) # 
      }
      
      sim <- calcFuelTypes(sim)
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
  
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS firevariables (pixelid integer, frt integer, ignitstaticlightning numeric, ignitstatichuman numeric, escapestatic numeric, spreadstatic numeric, distancetoroads numeric, elevation numeric, climate1lightning, climate2lightning, climate1person, climate2person, climate1escape, climate2escape, climate1spread, climate2spread)")
  
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
  
    #road_distance <- sim$road_distance # this step maybe unneccessary. ##CHECK: could check it both ways by putting sim$road_distance into the query instead of road_distance
    
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, 'UPDATE firevariables SET distancetoroads  = :road_distance WHERE pixelid = :pixelid', sim$road_distance) # I dont know if ending this with sim$road_distance will work.
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
    elev<-data.table(eleva = as.numeric(ras.elev[]))
    elev[, pixelid := seq_len(.N)][, eleva := as.numeric(eleva)]
    elev<-elev[eleva > -1, ]
    
    #add to the castordb
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, "UPDATE pixels set elv = :eleva where pixelid = :pixelid", elev)
    dbClearResult(rs)
    dbCommit(sim$castordb)
    
    rm(ras.elev,elev)
    gc()
  }else{
    stop(paste0("ERROR: extents are not the same check -", P(sim, "nameElevation", "fireCastor")))
  }
  }
  
  sim$elev<-data.table(dbGetQuery(sim$castordb, paste0("SELECT elv, pixelid, compartid FROM pixels")))
  
  message("change data format for download of climate data")
  
  sim$ras2<-terra::project(sim$ras, "EPSG:4326")
  lat_lon_pts<-data.table(terra::xyFromCell(sim$ras2,1:length(sim$ras2[])))
  sim$lat_lon_pts <- sim$lat_lon_pts[, pixelid:= seq_len(.N)]
  
  sim$sample.pts<-merge (sim$lat_lon_pts, sim$elev, by = 'pixelid', all.x =TRUE)
  
  # now pull out the points where there is data for compartid and save only that
 sim$samp.pts<- sim$sample.pts[!is.na(compartid),]
 colnames(sim$samp.pts)[colnames(sim$samp.pts) == "pixelid"] <- "ID1"
 colnames(sim$samp.pts)[colnames(sim$samp.pts) == "compartid"] <- "ID2"
 colnames(sim$samp.pts)[colnames(sim$samp.pts) == "y"] <- "lat"
 colnames(sim$samp.pts)[colnames(sim$samp.pts) == "x"] <- "long"
 colnames(sim$samp.pts)[colnames(sim$samp.pts) == "elv"] <- "el"
 
 sim$samp.pts<-as.data.frame(sim$samp.pts)
 sim$samp.pts<-sim$samp.pts%>% dplyr::select(ID1, ID2, lat, long, el)
 sim$samp.pts$ID2<-1
  
 #write the points to file so that we can use Tongli's Climate BC program to grab climate for our year of interest
  write.csv(sim$samp.pts, file = paste0(here::here(), "\\R\\SpaDES-modules\\fireCastor\\inputs\\sample_pts.csv"), row.names=FALSE)
  
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
    dplyr::select(ID1, Tmax01:Tmax12, Tave04:Tave10, PPT01:PPT12, RH05:RH08) %>% 
    dplyr::rename(pixelid = ID1)
  
  x2<-merge(climate2, frt_id)
  
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
  
  x3<-x2 %>% dplyr::select(pixelid, climate1_lightning, climate2_lightning, climate1_person, climate2_person, climate1_escape, climate2_escape, climate1_spread, climate2_spread)
  
  dbBegin(sim$castordb)
  rs<-dbSendQuery(sim$castordb, 'UPDATE firevariables SET climate1lightning  = :climate1_lightning, climate2lightning = :climate2_lightning, climate1person = :climate1_person, climate2person = :climate2_person, climate1escape = :climate1_escape, climate2escape = :climate2_escape, climate1spread = :climate1_spread, climate2spread = :climate2_spread WHERE pixelid = :pixelid', x3) 
  dbClearResult(rs)
  dbCommit(sim$castordb)  
 
  rm(x3, x2, climate2, climate, days_month, DC_half, Em, Em2, MDC_m, precip, Qmr, Qmr2, RMeff)
  
  gc()
  return(invisible(sim))
}

createVegetationTable <- function(sim) {
  
  message("create fuel types table")
  
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS fueltype (pixelid integer, bclcs_level_1 character, bclcs_level_2 character, bclcs_level_3 character,  bclcs_level_5 character, inventory_standard_cd character, non_productive_cd character, coast_interior_cd character,  land_cover_class_cd_1 character, bec_zone_code character, bec_subzone character, earliest_nonlogging_dist_type character, earliest_nonlogging_dist_date timestamp, vri_live_stems_per_ha numeric, vri_dead_stems_per_ha numeric, species_cd_1 character, species_pct_1 numeric, species_cd_2 character, species_pct_2 numeric, species_cd_3 character, species_pct_3 numeric, species_cd_4 character, species_pct_4 numeric, species_cd_5 character, species_pct_5 numeric, species_cd_6 character, species_pct_6 numeric)")
  

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
    if(aoi == terra::ext(ras.fid)){ #need to check that each of the extents are the same
      inv_id<-data.table(fid = as.integer(ras.fid[]))
      inv_id[, pixelid:= seq_len(.N)]
      inv_id[, fid:= as.integer(fid)] #make sure the fid is an integer for merging later on
      rm(ras.fid)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameForestInventoryRaster", "dataCastor")))
    }
    
    
    if(!P(sim, "nameForestInventoryTable2","dataCastor") == '99999'){ #Get the forest inventory variables 
      
      fuel_attributes_castordb<-c('bclcs_level_1', 'bclcs_level_2', 'bclcs_level_3',  'bclcs_level_5', 'inventory_standard_cd', 'non_productive_cd', 'coast_interior_cd',  'land_cover_class_cd_1', 'bec_zone_code', 'bec_subzone', 'earliest_nonlogging_dist_type', 'earliest_nonlogging_dist_date','vri_live_stems_per_ha', 'vri_dead_stems_per_ha','species_cd_1','species_pct_1','species_cd_2', 'species_pct_2', 'species_cd_3', 'species_pct_3','species_cd_4','species_pct_4', 'species_cd_5', 'species_pct_5', 'species_cd_6', 'species_pct_6')
      
      if(length(fuel_attributes_castordb) > 0){
        print(paste0("getting inventory attributes to create fuel types: ", paste(forest_attributes_castordb, collapse = ",")))
        fids<-unique(inv_id[!(is.na(fid)), fid])
        attrib_inv<-data.table(getTableQuery(paste0("SELECT " , P(sim, "nameForestInventoryKey", "dataCastor"), " as fid, ", paste(forest_attributes_castordb, collapse = ","), " FROM ",
                                                    P(sim, "nameForestInventoryTable2","dataCastor"), " WHERE ", P(sim, "nameForestInventoryKey", "dataCastor") ," IN (",
                                                    paste(fids, collapse = ","),");" )))
        
        print("...merging with fid") #Merge this with the raster using fid which gives you the primary key -- pixelid
        inv<-merge(x=inv_id, y=attrib_inv, by.x = "fid", by.y = "fid", all.x = TRUE) 
        
        inv<-inv[, fid:=NULL] # remove the fid key
        
        message('populating fuel type table')
        
        qry<-paste0('INSERT INTO fueltype (pixelid, bclcs_level_1, bclcs_level_2, bclcs_level_3, bclcs_level_5, inventory_standard_cd, non_productive_cd, coast_interior_cd, land_cover_class_cd_1, bec_zone_code, bec_subzone, earliest_nonlogging_dist_type, earliest_nonlogging_dist_date, vri_live_stems_per_ha, vri_dead_stems_per_ha, species_cd_1, species_pct_1, species_cd_2, species_pct_2, species_cd_3, species_pct_3, species_cd_4, species_pct_4, species_cd_5, species_pct_5, species_cd_6, species_pct_6) values (:pixelid, :bclcs_level_1, :bclcs_level_2, :bclcs_level_3, :bclcs_level_5, :inventory_standard_cd, :non_productive_cd, :coast_interior_cd, :land_cover_class_cd_1, :bec_zone_code, :bec_subzone, :earliest_nonlogging_dist_type, :earliest_nonlogging_dist_date, :vri_live_stems_per_ha, :vri_dead_stems_per_ha, :species_cd_1, :species_pct_1, :species_cd_2, :species_pct_2, :species_cd_3, :species_pct_3, :species_cd_4, :species_pct_4, :species_cd_5, :species_pct_5, :species_cd_6, :species_pct_6)')
        
        #fueltype table
        dbBegin(sim$castordb)
        rs<-dbSendQuery(sim$castordb, qry, pixels)
        dbClearResult(rs)
        dbCommit(sim$castordb)
    
  
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
  
  dbGetQuery(castordb, "SELECT species_cd_1, species_cd_2, species_cd_3, species_cd_4, species_cd_5, species_cd_6, species_pct_1, species_pct_2")
  
  fire_veg_sf<- fire_veg_sf %>%
    mutate(pct1 = ifelse(species_cd_1 %in% conifer, species_pct_1, NA),
           pct2 = ifelse(species_cd_2 %in% conifer, species_pct_2, NA),
           pct3 = ifelse(species_cd_3 %in% conifer, species_pct_3, NA),
           pct4 = ifelse(species_cd_4 %in% conifer, species_pct_4, NA),
           pct5 = ifelse(species_cd_5 %in% conifer, species_pct_5, NA),
           pct6 = ifelse(species_cd_6 %in% conifer, species_pct_6, NA),
           dominant_conifer = ifelse(species_cd_1 %in% conifer, species_cd_1, 
                                     ifelse(species_cd_2 %in% conifer, species_cd_2,
                                            ifelse(species_cd_3 %in% conifer, species_cd_3,
                                                   ifelse(species_cd_4 %in% conifer, species_cd_4,
                                                          ifelse(species_cd_5 %in% conifer, species_cd_5,
                                                                 ifelse(species_cd_6 %in% conifer, species_cd_6, NA)))))))
  
  
  
  
  
  return(invisible(sim)) 
  
}
  
  
  
  
  
  
  
  
  
  
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS fire (pixelid integer, frt integer, bclcs_level_2 character, proj_age_1 numeric, proj_height numeric, crown_closure numeric, pct_dead numeric, 
            inventory_standard_cd character, non_productive_cd character,coast_interior_cd character, bclcs_level_1 character,  bclcs_level_3 character,  bclcs_level_5 character, land_cover_class_cd_1 character, bec_zone_code character, bec_subzone character, earliest_nonlogging_dist_type character, earliest_nonlogging_dist_date timestamp, )")
 
  
 
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
