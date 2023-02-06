
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
  name = "fisherCastor",
  description = "This module calculates the relative probability of occupancy within a fisher territory following Weir and Corbould 2010 - Journal of Wildlife Management 74(3):405–410; 2010; DOI: 10.2193/2008-579",
  keywords = "",
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "1.0.0", fisherCastor = "0.0.0.9000"),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = deparse(list("README.md", "fisherCastor.Rmd")),
  reqdPkgs = list(),
  parameters = rbind(
    defineParameter ("calculateInterval", "numeric", 1, 1, 5, "The simulation time at which survival rates are calculated"),
    defineParameter ("nameFetaRaster", "character", "rast.fetaid", NA, NA, "Name of the raster descirbing fetas. Stored in psql."), 
    defineParameter ("nameFisherPopVector", "character", NA, NA, NA, "Name of the raster(s) descirbing fisher populations"), 
    defineParameter ("nameRasWetlands", "character", "rast.wetlands", NA, NA, "Name of the raster for wetlands as described in Weir and Corbould 2010")
    ),
  inputObjects = bind_rows(
    expectsInput (objectName = "castordb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the model. This module needs the age variable from the pixels table in the castordb.', sourceURL = NA),
    expectsInput(objectName ="scenario", objectClass ="data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName ="updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA),
    expectsInput(objectName ="boundaryInfo", objectClass ="character", desc = "Name of the area of interest(aoi) eg. Quesnel_TSA", sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "SpatRaster", desc = NA, sourceURL = NA),
    expectsInput(objectName ="harvestPixelList", objectClass = "data.table", desc = NA, sourceURL = NA),
    expectsInput(objectName ="zone.available", objectClass ="data.table", desc = "The number of zones", sourceURL = NA)
  ),
  outputObjects = bind_rows(
    createsOutput (objectName = "fisher.feta.info", objectClass = "data.table", desc = "A data.table object containg which fisher zone a feta belongs to based on a majority rule"),
    createsOutput (objectName = "fisher.d2.cov", objectClass = "list", desc = "A list object containing a covariance matrix for each fisher zone required to compute d2"),
    createsOutput (objectName = "flexRasWorld", objectClass = "RasterLayer", desc = "A list of raster with 1st specifying the fisher habitat zones (1 to 4); 2nd a stack of mahalanobis distance through time and; 3rd a stack of movement habitat through time"),
    createsOutput (objectName = "fisherReport", objectClass = "data.table", desc = "A data.table object. Consists of fisher occupancy estimates for each territory in the study area at each time step. Gets saved in the 'outputs' folder of the module.")
  )
))

doEvent.fisherCastor = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init(sim) #Gets the needed spatial layers
      if(!is.na(P(sim, "nameFetaRaster", "fisherCastor"))){
        sim <- setFisherD2Parameters(sim) #preps the object need for flex
        sim <- getFisherSuitability(sim) #calc the current world
        sim <- scheduleEvent (sim, time(sim) + P(sim, "calculateInterval", "fisherCastor"), "fisherCastor", "calculateFisherHabitatSuitability", 5) # schedule the next calculation event 
      }
    },
    calculateFisherHabitatSuitability = {
      sim <- getFisherSuitability(sim)
      sim <- scheduleEvent (sim, time(sim) + P(sim, "calculateInterval", "fisherCastor"), "fisherCastor", "calculateFisherHabitatSuitability", 5) # schedule the next
    },
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
                  "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  if(nrow(dbGetQuery(sim$castordb, "SELECT name FROM sqlite_schema WHERE type ='table' AND name = 'fisherhabitat';")) == 0){
    #Create the table in the database
    message("creating fisherhabitat table")
    dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS fisherhabitat (pixelid integer, fetaid integer, den_p integer, rus_p integer, mov_p integer, cwd_p integer, cav_p integer)")
    
    fisher.ras.ter<-data.table(reference_zone = P(sim, "nameFetaRaster", "fisherCastor"))
    #---Check is territory not already in the castordb
    getFisherTerritory<-fisher.ras.ter[!(reference_zone %in% dbGetQuery(sim$castordb, "SELECT * FROM zone;")$reference_zone),]
      
    if(nrow(getFisherTerritory[!is.na(reference_zone),]) > 0){
    
      getFisherTerritory[,zone:= paste0("zone", as.integer(dbGetQuery(sim$castordb, "SELECT count(*) as num_zones FROM zone;")$num_zones) + 1)] #assign zone name as the last zone number plus the new zones
      dbExecute (sim$castordb, paste0("ALTER TABLE pixels ADD COLUMN ", getFisherTerritory$zone, " integer")) # add a column to the pixel table that will define the fisher territory  
      
      feta.ras <- terra::rast(RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = P(sim, "nameFetaRaster", "fisherCastor") , # 
                                clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                                where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                conn = NULL))
      ras.territory <- data.table (V1 = as.integer(feta.ras[]))
      ras.territory[, V1 := as.integer (V1)] # add the herd boudnary value from the raster and make the value an integer
      ras.territory[, pixelid := seq_len(.N)] # add pixelid value
        
      
      dbBegin (sim$castordb) # fire up the db and add the herd boundary values to the pixels table 
        rs <- dbSendQuery (sim$castordb, paste0("Update pixels set ", getFisherTerritory$zone, "= :V1 where pixelid = :pixelid"), ras.territory) 
      dbClearResult (rs)
      dbCommit (sim$castordb) # commit the new column to the db
          
      #---Set the fisher territory to the zone table
      dbExecute (sim$castordb, paste0("INSERT INTO zone (zone_column, reference_zone) VALUES ('", getFisherTerritory$zone, "', '", getFisherTerritory$reference_zone, "')")) 
      
      #---Clean up
      rm(ras.territory,getFisherTerritory)
      gc()
      
      #---set the permanent wetlands raster to pixels table
      if(dbGetQuery (sim$castordb, "SELECT COUNT(*) as exists_check FROM pragma_table_info('pixels') WHERE name='wetland';")$exists_check == 0){
          dbExecute (sim$castordb, "ALTER TABLE pixels ADD COLUMN wetland integer") # add a column to the pixel table that will define the wetland area   
          ras.wetland <- data.table (V1 = as.numeric(terra::rast(RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), 
                          srcRaster = P(sim, "nameRasWetlands", "fisherCastor") , # 
                          clipper=sim$boundaryInfo[[1]], 
                          geom= sim$boundaryInfo[[4]], 
                          where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                          conn=NULL))[]))
          ras.wetland[, V1 := as.integer (V1)] # add the wetlands value from the raster and make the value an integer
          ras.wetland[, pixelid := seq_len(.N)] # add pixelid value
          
          dbBegin (sim$castordb) # add values to the pixels table 
          rs <- dbSendQuery (sim$castordb, paste0("Update pixels set wetland = :V1 where pixelid = :pixelid"), ras.wetland) 
          dbClearResult (rs)
          dbCommit (sim$castordb) # commit the new column to the db
          
          rm(ras.wetland)
      }else{
        message("Using prevsiouly declared wetlands raster")
      }
    }else{
      stop("Specify a new fisher habitat raster. The fisher zone is already specified as another zone")
    }
  
  #---------FLEX modelling
    message("creating permanent habitat table")
    
    hab_p <- data.table(
                    pixelid = 1:ncell(feta.ras),
                    fetaid = as.integer(feta.ras[]),
                    den_p= as.integer(terra::rast(RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = "rast.fisher_denning_p" , # 
                      clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                      where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                      conn = NULL))[]),
                    rus_p = as.integer(terra::rast(RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = "rast.fisher_rust_p" , # 
                      clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                      where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                      conn = NULL))[]),
                    cwd_p = as.integer(terra::rast(RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = "rast.fisher_cwd_p" , # 
                      clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                      where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                      conn = NULL))[]),
                    cav_p = as.integer(terra::rast(RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = "rast.fisher_cavity_p" , # 
                      clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                      where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                      conn = NULL))[]),
                    mov_p = as.integer(terra::rast(RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = "rast.fisher_movement_p" , # 
                                          clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                                          where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                          conn = NULL))[]))
    
    hab_p<-hab_p[!is.na(fetaid) & mov_p > 0,] #Remove the non contributing pixels
    
    
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, "INSERT INTO fisherhabitat (pixelid , fetaid,  den_p, rus_p, cwd_p, cav_p, mov_p) 
                        values (:pixelid , :fetaid,  :den_p, :rus_p, :cwd_p, :cav_p, :mov_p);", hab_p)
    dbClearResult(rs)
    dbCommit(sim$castordb)
    
    #---Initiate the time 0 output object fisherReport
    message("Initializing the fisherReport")
    sim$fisherReport<-data.table(timeperiod = as.integer(), scenario = as.character(), compartment =  as.character(), openess = as.numeric(), zone = as.integer(), reference_zone = as.character(), rel_prob_occup = as.numeric(), denning= as.numeric(), rust= as.numeric(), cavity= as.numeric(), cwd= as.numeric(), mov= as.numeric(), d2 = as.numeric())
    
  }else{
    message("Using existing fisher parameters")
  }
  
  return(invisible(sim))
}

setFisherD2Parameters<-function(sim){ #sets up the world object
  # 1: Boreal, 2: SBS-wet, 3: Sbs-dry, 4 = Dry Forest
  sim$fisher.feta.info <- data.table(dbGetQuery(sim$castordb, "with freqs as (select count(mov_p) as freq, mov_p, fetaid from fisherhabitat group by fetaid, mov_p) select max(freq), mov_p as pop, fetaid from freqs group by fetaid;"))#the population each feta belong to
  sim$fisher.d2.cov <- list(matrix(c(193.235, 	5.418, 	42.139, 	125.177, 	-117.128, 	5.418, 	0.423, 	2.926, 	5.229, 	-4.498, 	42.139, 	2.926, 	36.03, 	46.52, 	-42.571, 	125.177, 	5.229, 	46.52, 	131.377, 	-101.195, 	-117.128, 	-4.498, 	-42.571, 	-101.195, 	105.054), ncol =5, nrow =5),
                            matrix(c(0.536,	2.742,	0.603,	3.211,	-2.735,	1.816,	2.742,	82.721,	4.877,	83.281,	7.046,	-21.269,	0.603,	4.877,	0.872,	4.033,	-0.67,	-0.569,	3.211,	83.281,	4.033,	101.315,	-15.394,	-1.31,	-2.735,	7.046,	-0.67,	-15.394,	56.888,	-48.228,	1.816,	-21.269,	-0.569,	-1.31,	-48.228,	47.963), nrow =6, ncol =6),
                            matrix(c(0.525,	-1.909,	-0.143,	2.826,	-6.891,	3.264,	-1.909,	96.766,	-0.715,	-39.021,	69.711,	-51.688,	-0.143,	-0.715,	0.209,	-0.267,	1.983,	-0.176,	2.826,	-39.021,	-0.267,	58.108,	-21.928,	22.234,	-6.891,	69.711,	1.983,	-21.928,	180.113,	-96.369,	3.264,	-51.688,	-0.176,	22.234,	-96.369,	68.499), nrow =6, ncol =6),
                            matrix(c(2.905,	0.478,	4.04,	1.568,	-3.89,	0.478,	0.683,	6.131,	8.055,	-8.04,	4.04,	6.131,	62.64,	73.82,	-62.447,	1.568,	8.055,	73.82,	126.953,	-130.153,	-3.89,	-8.04,	-62.447,	-130.153,	197.783), nrow =5, ncol =5)
  )
  return(invisible(sim))
}

getFisherSuitability<-function(sim){
  message("calc relative prob of occupancy")
  getFisherTerritory<-dbGetQuery(sim$castordb, paste0("SELECT zone_column, reference_zone FROM zone where reference_zone = '",P(sim, "nameFetaRaster", "fisherCastor"),"';"))
  #---Build the query -- appending by fisher territory
  occupancy<-data.table(dbGetQuery(sim$castordb, paste0("Select (cast(sum(case when wetland > 0 OR age < 12 then 1 else 0 end) as float)/count())*100 as openess, ", getFisherTerritory$zone_column ," as zone, '",getFisherTerritory$reference_zone,"' as reference_zone from pixels 
                        where ", getFisherTerritory$zone_column," is not null group by ",getFisherTerritory$zone_column )))
  
  #---Model from Weir and Corbould 2010
  occupancy[, rel_prob_occup:= ((exp(-0.219*openess))/(1+exp(-0.219*openess )))/0.5]
  
  message("calc flex world")
  #---VAT for regional models: 1 = SBS-wet; 2 = SBS-dry; 3 = Dry Forest; 4 = Boreal_A; 5 = Boreal_B
  #---Note: age > 0 is added a query to remove any harvesting that occurs in the same sim time
  fisher.habitat <- data.table(dbGetQuery(sim$castordb, "select fisherhabitat.pixelid, fetaid, den_p, rus_p, cav_p, cwd_p, mov_p, age, height, crownclosure, basalarea, qmd from fisherhabitat inner join pixels on fisherhabitat.pixelid = pixels.pixelid"))
  fisher.habitat<-fisher.habitat[pixelid %in% sim$harvestPixelList$pixelid, age:=0]
  

  fisher.habitat[den_p == 1 & age >= 125 & crownclosure >= 30 & qmd >=28.5 & basalarea >= 29.75, denning:=1][den_p == 2 & age >= 125 & crownclosure >= 20 & qmd >=28 & basalarea >= 28, denning:=1][den_p == 3 & age >= 135, denning:=1][den_p == 4 & age >= 207 & crownclosure >= 20 & qmd >= 34.3, denning:=1][den_p == 5 & age >= 88 & qmd >= 19.5 & height >= 19, denning:=1][den_p == 6 & age >= 98 & qmd >= 21.3 & height >= 22.8, denning:=1]
  fisher.habitat[rus_p == 1 & age > 0 & crownclosure >= 30 & qmd >= 22.7 & basalarea >= 35 & height >= 23.7, rust:=1][rus_p == 2 & age >= 72 & crownclosure >= 25 & qmd >= 19.6 & basalarea >= 32, rust:=1][rus_p == 3 & age >= 83 & crownclosure >=40 & qmd >= 20.1, rust:=1][rus_p == 5 & age >= 78 & crownclosure >=50 & qmd >= 18.5 & height >= 19 & basalarea >= 31.4, rust:=1][rus_p == 6 & age >= 68 & crownclosure >=35 & qmd >= 17 & height >= 14.8, rust:=1]
  fisher.habitat[cav_p == 1 & age > 0 & crownclosure >= 25 & qmd >= 30 & basalarea >= 32 & height >=35, cavity:=1][cav_p == 2 & age > 0 & crownclosure >= 25 & qmd >= 30 & basalarea >= 32 & height >=35, cavity:=1]
  fisher.habitat[cwd_p == 1 & age >= 135 & qmd >= 22.7 & height >= 23.7, cwd:=1][cwd_p == 2 & age >= 135 & qmd >= 22.7 & height >= 23.7, cwd:=1][cwd_p == 3 & age >= 100, cwd:=1][cwd_p >= 5 & age >= 78 & qmd >= 18.1 & height >= 19 & crownclosure >=60, cwd:=1]
  fisher.habitat[mov_p == 1 & age > 0 & crownclosure > 30, movement:=1]
    
    
  #---Summarize habitat by the feta
  den<-fisher.habitat[den_p > 0, .(denning = (sum(denning, na.rm =T)/3000)*100), by = fetaid]
  cav<-fisher.habitat[cav_p > 0, .(cavity = (sum(cavity, na.rm =T)/3000)*100), by = fetaid]
  rus<-fisher.habitat[rus_p > 0, .(rust = (sum(rust, na.rm =T)/3000)*100), by = fetaid] 
  cwd<-fisher.habitat[cwd_p > 0, .(cwd =(sum(cwd, na.rm =T)/3000)*100), by = fetaid]
  mov<-fisher.habitat[mov_p > 0, .(mov = (sum(movement, na.rm =T)/3000)*100), by = fetaid]
  
    #---Merge all habitat data.table together
    fisher.habitat.rs <- Reduce(function(...) merge(..., all = TRUE), list(sim$fisher.feta.info, den,cav,rus,cwd,mov))
    #fisher.d2.cov<<-sim$fisher.d2.cov
    #stop()
    #---Calculate D2 (Mahalanobis)
    #-----Add log transforms
    fisher.habitat.rs[is.na(fisher.habitat.rs)] <-0
    fisher.habitat.rs[ pop == 1 & denning >= 0, denning:=log(denning + 1)][ pop == 1 & cavity >= 0, cavity:=log(cavity + 1)]
    fisher.habitat.rs[ pop == 2 & denning >= 0, denning:=log(denning + 1)]
    fisher.habitat.rs[ pop >= 3 & rust >= 0, rust:=log(rust + 1)]
    #fisher.habitat.rs[is.na(fisher.habitat.rs)] <-0.0000000001
    
    #-----Truncate at the center plus one st dev
    stdev_pop1<-sqrt(diag(sim$fisher.d2.cov[[1]]))
    stdev_pop2<-sqrt(diag(sim$fisher.d2.cov[[2]]))
    stdev_pop3<-sqrt(diag(sim$fisher.d2.cov[[3]]))
    stdev_pop4<-sqrt(diag(sim$fisher.d2.cov[[4]]))
    
    #fisher.habitat.rs[ pop == 1 & denning > 1.6 + stdev_pop1[1], denning := 1.6 + stdev_pop1[1]][ pop == 1 & rust > 36.2 + stdev_pop1[2], rust :=36.2 + stdev_pop1[2]][ pop == 1 & cavity > 0.7 + stdev_pop1[3], cavity :=0.7+ stdev_pop1[3]][ pop == 1 & cwd > 30.4+ stdev_pop1[4], cwd :=30.4+ stdev_pop1[4]][ pop == 1 & mov > 26.8+ stdev_pop1[5], mov :=26.8+ stdev_pop1[5]]
    #fisher.habitat.rs[ pop == 2 & denning > 1.2 + stdev_pop2[1], denning := 1.2 + stdev_pop2[1]][ pop == 2 & rust > 19.1 + stdev_pop2[2], rust :=19.1 + stdev_pop2[2]][ pop == 2 & cavity > 0.5 + stdev_pop2[3], cavity :=0.5+ stdev_pop2[3]][ pop == 2 & cwd > 10.2+ stdev_pop2[4], cwd :=10.2+ stdev_pop2[4]][ pop == 2 & mov > 33.1+ stdev_pop2[5], mov :=33.1+ stdev_pop2[5]]
    #fisher.habitat.rs[ pop %in% c(3,4) & denning > 2.3 + stdev_pop3[1], denning := 2.3 + stdev_pop3[1]][ pop %in% c(3,4) & rust > 1.6 +  stdev_pop3[2], rust :=1.6  + stdev_pop3[2]][ pop %in% c(3,4) & cwd > 10.8+ stdev_pop3[3], cwd :=10.8 + stdev_pop3[3]][ pop %in% c(3,4) & mov > 21.5+ stdev_pop3[4], mov :=21.5+ stdev_pop3[4]]
    #fisher.habitat.rs[ pop >= 5 & denning > 24  + stdev_pop4[1], denning:=24+ stdev_pop4[1] ][ pop >= 5 & rust > 2.2+ stdev_pop4[2], rust :=2.2+ stdev_pop4[2]][ pop >= 5 & cwd > 17.4 + stdev_pop4[3], cwd :=17.4+ stdev_pop4[3]][ pop >= 5 & mov > 56.2+ stdev_pop4[4], mov :=56.2+ stdev_pop4[4]]
    
    #fisher.habitat.rs[ pop == 1 & denning > 1.6 , denning := 1.6 ][ pop == 1 & rust > 36.2, rust :=36.2][ pop == 1 & cavity > 0.7, cavity :=0.7][ pop == 1 & cwd > 30.4, cwd :=30.4][ pop == 1 & mov > 50, mov :=50]
    #fisher.habitat.rs[ pop == 2 & denning > 1.2 , denning := 1.2 ][ pop == 2 & rust > 19.1, rust :=19.1][ pop == 2 & cavity > 0.5, cavity :=0.5][ pop == 2 & cwd > 10.2, cwd :=10.2][ pop == 2 & mov > 50, mov :=50]
    #fisher.habitat.rs[ pop %in% c(3,4) & denning > 2.3 , denning := 2.3 ][ pop %in% c(3,4) & rust > 1.6, rust :=1.6][ pop %in% c(3,4) & cwd > 10.8, cwd :=10.8][ pop %in% c(3,4) & mov > 50, mov :=50]
    #fisher.habitat.rs[ pop >= 5 & denning > 24, denning:=24 ][ pop >= 5 & rust > 2.2, rust :=2.2][ pop >= 5 & cwd > 17.4, cwd :=17.4][ pop >= 5 & mov > 56.2, mov :=56.2]
    
    fisher.habitat.rs[ pop == 1 & denning > 1.6 , denning := 1.6 ][ pop == 1 & rust > 36.2, rust :=36.2][ pop == 1 & cavity > 0.7, cavity :=0.7][ pop == 1 & cwd > 30.4, cwd :=30.4][ pop == 1 & mov > 26.8, mov :=26.8]
    fisher.habitat.rs[ pop == 2 & denning > 1.2 , denning := 1.2 ][ pop == 2 & rust > 19.1, rust :=19.1][ pop == 2 & cavity > 0.5, cavity :=0.5][ pop == 2 & cwd > 10.2, cwd :=10.2][ pop == 2 & mov > 33.06, mov :=33.06]
    fisher.habitat.rs[ pop %in% c(3,4) & denning > 2.3 , denning := 2.3 ][ pop %in% c(3,4) & rust > 1.6, rust :=1.6][ pop %in% c(3,4) & cwd > 10.8, cwd :=10.8][ pop %in% c(3,4) & mov > 21.5, mov :=21.5]
    fisher.habitat.rs[ pop >= 5 & denning > 24, denning:=24 ][ pop >= 5 & rust > 2.2, rust :=2.2][ pop >= 5 & cwd > 17.4, cwd :=17.4][ pop >= 5 & mov > 56.2, mov :=56.2]
    
    
    #-----D2
    fisher.habitat.rs[ pop == 1, d2:= mahalanobis(fisher.habitat.rs[ pop == 1, c("denning", "rust", "cavity", "cwd", "mov")], c(1.6, 36.2, 0.7, 30.4, 26.8), cov = sim$fisher.d2.cov[[1]])]
    fisher.habitat.rs[ pop == 2, d2:= mahalanobis(fisher.habitat.rs[ pop == 2, c("denning", "rust", "cavity", "cwd", "mov")], c(1.16, 19.1, 0.45, 8.69, 33.06), cov = sim$fisher.d2.cov[[2]])]
    fisher.habitat.rs[ pop %in% c(3,4), d2:= mahalanobis(fisher.habitat.rs[ pop %in% c(3,4), c("denning", "rust", "cwd", "mov")], c(2.3, 1.6, 10.8, 21.5), cov = sim$fisher.d2.cov[[3]])]
    fisher.habitat.rs[ pop >= 5, d2:= mahalanobis(fisher.habitat.rs[ pop >= 5, c("denning", "rust", "cwd", "mov")], c(24.0, 2.2, 17.4, 56.2), cov = sim$fisher.d2.cov[[4]])]
   
    #fisher.habitat.rs[ pop == 1, d2:= mahalanobis(fisher.habitat.rs[ pop == 1, c("denning", "rust", "cavity", "cwd", "mov")], c(1.6, 36.2, 0.7, 30.4, 50), cov = sim$fisher.d2.cov[[1]])]
    #fisher.habitat.rs[ pop == 2, d2:= mahalanobis(fisher.habitat.rs[ pop == 2, c("denning", "rust", "cavity", "cwd", "mov")], c(1.16, 19.1, 0.45, 8.69, 50), cov = sim$fisher.d2.cov[[2]])]
    #fisher.habitat.rs[ pop %in% c(3,4), d2:= mahalanobis(fisher.habitat.rs[ pop %in% c(3,4), c("denning", "rust", "cwd", "mov")], c(2.3, 1.6, 10.8, 50), cov = sim$fisher.d2.cov[[3]])]
    #fisher.habitat.rs[ pop >= 5, d2:= mahalanobis(fisher.habitat.rs[ pop >= 5, c("denning", "rust", "cwd", "mov")], c(24.0, 2.2, 17.4, 56.2), cov = sim$fisher.d2.cov[[4]])]
    
    #fisher.habitat.rs[mov < 30 & d2 < 7, d2:=10]
    #print(nrow(fisher.habitat.rs[d2<7,]))
    fisher.habitat.mahal<-merge(fisher.habitat, fisher.habitat.rs[,c("fetaid", "d2", "pop", "mov")], by.x = "fetaid", by.y = "fetaid", all.x =T)
  
    #-----Create Raster of D2
    #ras.mahal<-sim$ras
    #ras.mahal[]<-NA
    #ras.mahal[fisher.habitat.mahal$pixelid]<-fisher.habitat.mahal$d2
    
    #---Create Raster of movement
    #ras.mov<-sim$ras
    #ras.mov[] <- NA
    #ras.mov[fisher.habitat.mahal$pixelid]<-fisher.habitat.mahal$mov

    #Aggregate to a 30km pixels and save for FLEX
    #if(i == 1){
    #  sim$flexRasWorld[[2]] <- aggregate(ras.mahal, fact =55)
     # sim$flexRasWorld[[3]] <- aggregate(ras.mov, fact =55)
   # }else{
     # sim$flexRasWorld[[2]] <- stack(sim$flexRasWorld[[2]], aggregate(ras.mahal, fact =55))
    #  sim$flexRasWorld[[3]] <- stack(sim$flexRasWorld[[3]], aggregate(ras.mov, fact =55))
    #}
  #}
  
  fisherReport<-merge(occupancy, fisher.habitat.rs[, c("fetaid", "denning", "rust", "cavity", "cwd", "mov","d2")], by.x = "zone", by.y = "fetaid")
  fisherReport[, c("timeperiod", "scenario", "compartment") := list(time(sim)*sim$updateInterval, sim$scenario$name, sim$boundaryInfo[[3]][[1]]) ] 
  sim$fisherReport<-rbindlist(list(sim$fisherReport, fisherReport), use.names=TRUE)
  
  return(invisible(sim)) 
}

.inputObjects <- function(sim) {
  #dPath <- asPath(getOption("reproducible.destinationPath", dataPath(sim)), 1)
  #message(currentModule(sim), ": using dataPath '", dPath, "'.")
  return(invisible(sim))
}


