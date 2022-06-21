
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
  name = "fisherCLUS",
  description = "This module calculates the relative probability of occupancy within a fisher territory following Weir and Corbould 2010 - Journal of Wildlife Management 74(3):405–410; 2010; DOI: 10.2193/2008-579",
  keywords = "",
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "1.0.0", fisherCLUS = "0.0.0.9000"),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = deparse(list("README.md", "fisherCLUS.Rmd")),
  reqdPkgs = list(),
  parameters = rbind(
    defineParameter ("calculateInterval", "numeric", 1, 1, 5, "The simulation time at which survival rates are calculated"),
    defineParameter ("nameFetaRaster", "character", "rast.fetaid", NA, NA, "Name of the raster descirbing fetas. Stored in psql."), 
    defineParameter ("nameFisherPopVector", "character", NA, NA, NA, "Name of the raster(s) descirbing fisher populations"), 
    defineParameter ("nameRasWetlands", "character", "rast.wetlands", NA, NA, "Name of the raster for wetlands as described in Weir and Corbould 2010")
    ),
  inputObjects = bind_rows(
    expectsInput (objectName = "clusdb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the model. This module needs the age variable from the pixels table in the clusdb.', sourceURL = NA),
    expectsInput(objectName ="scenario", objectClass ="data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName ="updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA),
    expectsInput(objectName ="boundaryInfo", objectClass ="character", desc = "Name of the area of interest(aoi) eg. Quesnel_TSA", sourceURL = NA),
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

doEvent.fisherCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init(sim) #Gets the needed spatial layers
      if(!is.na(P(sim, "nameFetaRaster", "fisherCLUS"))){
        sim <- setFLEXWorld(sim) #preps the object need for flex
        sim <- getFLEXWorld(sim) #calc the current world
        sim <- scheduleEvent (sim, time(sim) + P(sim, "calculateInterval", "fisherCLUS"), "fisherCLUS", "calculateFLEXWorld", 5) # schedule the next calculation event 
      }
    },
    calculateFLEXWorld = {
      sim <- getFLEXWorld(sim)
      sim <- scheduleEvent (sim, time(sim) + P(sim, "calculateInterval", "fisherCLUS"), "fisherCLUS", "calculateFLEXWorld", 5) # schedule the next
    },
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
                  "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  if(nrow(dbGetQuery(sim$clusdb, "SELECT name FROM sqlite_schema WHERE type ='table' AND name = 'fisherhabitat';")) == 0){
    #Create the table in the database
    message("creating fisherhabitat table")
    dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS fisherhabitat (pixelid integer, fetaid integer, den_p integer, rus_p integer, mov_p integer, cwd_p integer, cav_p integer)")
    
    fisher.ras.ter<-data.table(reference_zone = P(sim, "nameFetaRaster", "fisherCLUS"))
    #---Check is territory not already in the clusdb
    getFisherTerritory<-fisher.ras.ter[!(reference_zone %in% dbGetQuery(sim$clusdb, "SELECT * FROM zone;")$reference_zone),]
      
    if(nrow(getFisherTerritory[!is.na(reference_zone),]) > 0){
    
      getFisherTerritory[,zone:= paste0("zone", as.integer(dbGetQuery(sim$clusdb, "SELECT count(*) as num_zones FROM zone;")$num_zones) + 1)] #assign zone name as the last zone number plus the new zones
      dbExecute (sim$clusdb, paste0("ALTER TABLE pixels ADD COLUMN ", getFisherTerritory$zone, " integer")) # add a column to the pixel table that will define the fisher territory  
      
      feta.ras <- RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = P(sim, "nameFetaRaster", "fisherCLUS") , # 
                                clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                                where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                conn = NULL)
      ras.territory <- data.table (V1 = feta.ras[])
      ras.territory[, V1 := as.integer (V1)] # add the herd boudnary value from the raster and make the value an integer
      ras.territory[, pixelid := seq_len(.N)] # add pixelid value
        
      
      dbBegin (sim$clusdb) # fire up the db and add the herd boundary values to the pixels table 
        rs <- dbSendQuery (sim$clusdb, paste0("Update pixels set ", getFisherTerritory$zone, "= :V1 where pixelid = :pixelid"), ras.territory) 
      dbClearResult (rs)
      dbCommit (sim$clusdb) # commit the new column to the db
          
      #---Set the fisher territory to the zone table
      dbExecute (sim$clusdb, paste0("INSERT INTO zone (zone_column, reference_zone) VALUES ('", getFisherTerritory$zone, "', '", getFisherTerritory$reference_zone, "')")) 
      
      #---Clean up
      rm(ras.territory,getFisherTerritory)
      gc()
      
      #---set the permanent wetlands raster to pixels table
      if(dbGetQuery (sim$clusdb, "SELECT COUNT(*) as exists_check FROM pragma_table_info('pixels') WHERE name='wetland';")$exists_check == 0){
          dbExecute (sim$clusdb, "ALTER TABLE pixels ADD COLUMN wetland integer") # add a column to the pixel table that will define the wetland area   
          ras.wetland <- data.table (V1 = RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), 
                          srcRaster = P(sim, "nameRasWetlands", "fisherCLUS") , # 
                          clipper=sim$boundaryInfo[[1]], 
                          geom= sim$boundaryInfo[[4]], 
                          where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                          conn=NULL)[])
          ras.wetland[, V1 := as.integer (V1)] # add the wetlands value from the raster and make the value an integer
          ras.wetland[, pixelid := seq_len(.N)] # add pixelid value
          
          dbBegin (sim$clusdb) # add values to the pixels table 
          rs <- dbSendQuery (sim$clusdb, paste0("Update pixels set wetland = :V1 where pixelid = :pixelid"), ras.wetland) 
          dbClearResult (rs)
          dbCommit (sim$clusdb) # commit the new column to the db
          
          rm(ras.wetland)
      }else{
        message("Using prevsiouly declared wetlands raster")
      }
    }else{
      stop("Specify a new fisher habitat raster. The fisher zone is already specified as another zone")
    }
  
  #---------FLEX modelling
    hab_p <- data.table(
                    pixelid = 1:ncell(feta.ras),
                    fetaid = feta.ras[],
                    den_p= RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = "rast.fisher_denning_p" , # 
                      clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                      where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                      conn = NULL)[],
                    rus_p = RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = "rast.fisher_rust_p" , # 
                      clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                      where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                      conn = NULL)[],
                    cwd_p = RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = "rast.fisher_cwd_p" , # 
                      clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                      where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                      conn = NULL)[],
                    cav_p = RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = "rast.fisher_cavity_p" , # 
                      clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                      where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                      conn = NULL)[],
                    mov_p = RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = "rast.fisher_movement_p" , # 
                                          clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                                          where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                          conn = NULL)[])
    
    hab_p<-hab_p[!is.na(fetaid) & mov_p > 0,] #Remove the non contributing pixels
    
    
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "INSERT INTO fisherhabitat (pixelid , fetaid,  den_p, rus_p, cwd_p, cav_p, mov_p) 
                        values (:pixelid , :fetaid,  :den_p, :rus_p, :cwd_p, :cav_p, :mov_p);", hab_p)
    dbClearResult(rs)
    dbCommit(sim$clusdb)
    
    
    #---Get the raster info for the population specification raster
    fisher.pop <- getSpatialQuery(paste0("SELECT pop,  ST_Intersection(aoi.",sim$boundaryInfo[[4]],", fisher_zones.wkb_geometry) FROM 
                           (SELECT ",sim$boundaryInfo[[4]]," FROM ",sim$boundaryInfo[[1]]," where ",sim$boundaryInfo[[2]]," in('", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "', '") ,"') ) as aoi 
                           JOIN fisher_zones ON ST_Intersects(aoi.",sim$boundaryInfo[[4]],", fisher_zones.wkb_geometry)"))
   
    ras.fisher.pop <- fasterize::fasterize(sf= fisher.pop, raster = aggregate(sim$ras, fact =55) , field = "pop")
    ras.fisher.pop.extent<-extent(ras.fisher.pop)
    dbExecute(sim$clusdb, paste0("INSERT INTO raster_info (name, xmin, xmax, ymin, ymax, ncell, nrow, crs) values ('fisherpop',", ras.fisher.pop.extent[1], ", ", ras.fisher.pop.extent[2], ", ",
                                 ras.fisher.pop.extent[3], ", ", ras.fisher.pop.extent[4], ",", ncell(ras.fisher.pop) , ", ", nrow(ras.fisher.pop),", '3005')"))
    
    #---add in raster values
    message("Creating fisher population specification raster")
    dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS fisher_pop_raster (id integer, pop integer)")
    fisher.pop.ras.table<-data.table(id = 1:ncell(ras.fisher.pop), pop = ras.fisher.pop[])
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "INSERT INTO fisher_pop_raster (id , pop) 
                        values (:id , :pop);", fisher.pop.ras.table)
    dbClearResult(rs)
    dbCommit(sim$clusdb)
    
    #---Initiate the time 0 output object fisherReport
    message("Initializing the fisherReport")
    sim$fisherReport<-data.table(timeperiod = as.integer(), scenario = as.character(), compartment =  as.character(), openess = as.numeric(), zone = as.integer(), reference_zone = as.character(), rel_prob_occup = as.numeric(), d2 = as.numeric())
    
  }else{
    message("Using existing fisher parameters")
  }
  
  return(invisible(sim))
}

setFLEXWorld<-function(sim){ #sets up the world object
  #flexRasWorld has three objects - the first is the fisher habitat zone specification raster, the second is a raster stack of d2 over time and the third is a raster stack of fisher movement habitat over time
  sim$fisher.feta.info <- data.table(dbGetQuery(sim$clusdb, "with freqs as (select count(mov_p) as freq, mov_p, fetaid from fisherhabitat group by fetaid, mov_p) select max(freq), mov_p as pop, fetaid from freqs group by fetaid;"))#the population each feta belong to
  sim$fisher.d2.cov <- list(matrix(c(0.5,	2.7,	0.6,	3.2,	-6.5, 2.7,	82.7,	4.9,	83.3,	-75.8, 0.6,	4.9,	0.9,	4,	-7.1, 3.2,	83.3,	4,	101.3,	-100.4, -6.5,	-75.8,	-7.1,	-100.4,	156.2), ncol =5, nrow =5),
                           matrix(c(0.5,	-1.9,	-0.2,	1.9,	-3.8, -1.9,	96.8,	-0.7,	-24.6,	57.3, -0.2,	-0.7,	0.3,	-0.6,	1.2, 1.9,	-24.6,	-0.6,	45.5,	-2.8, -3.8,	57.3,	1.2,	-2.8,	77.3), ncol =5, nrow =5),
                           matrix(c(0.7,	0.5,	6.1,	2.1, 0.5,	2.9,	4.0,	5.2, 6.1,	4.0,	62.6,	22.4, 2.1,	5.2,	22.4,	42.3), ncol=4, nrow=4),
                           matrix(c(193.2,	5.4,	42.1,	125.2, 5.4,	0.4,	2.,	5.2, 42.1,	2.9,	36.0,	46.5, 125.2,	5.2, 46.5,	131.4), ncol =4, nrow =4))
  sim$flexRasWorld <- list()
  
  #---Fisher population raster for identifying Boreal vs Columbian populations
  ras.info<-dbGetQuery(sim$clusdb, "SELECT * FROM raster_info WHERE name = 'fisherpop';")
  ras.values<-dbGetQuery(sim$clusdb, "SELECT pop FROM fisher_pop_raster ORDER BY id;")
  
  sim$flexRasWorld[[1]]<- raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), vals = ras.values$pop, nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow)
  raster::crs(sim$flexRasWorld[[1]])<-paste0("EPSG:", ras.info$crs)
  
  return(invisible(sim))
}

getFLEXWorld<-function(sim){
  message("calc relative prob of occupancy")
  getFisherTerritory<-dbGetQuery(sim$clusdb, paste0("SELECT zone_column, reference_zone FROM zone where reference_zone = '",P(sim, "nameFetaRaster", "fisherCLUS"),"';"))
  #---Build the query -- appending by fisher territory
  occupancy<-data.table(dbGetQuery(sim$clusdb, paste0("Select (cast(sum(case when wetland > 0 OR age < 12 then 1 else 0 end) as float)/count())*100 as openess, ", getFisherTerritory$zone_column ," as zone, '",getFisherTerritory$reference_zone,"' as reference_zone from pixels 
                        where ", getFisherTerritory$zone_column," is not null group by ",getFisherTerritory$zone_column )))
  
  #---Model from Weir and Corbould 2010
  occupancy[, rel_prob_occup:= ((exp(-0.219*openess))/(1+exp(-0.219*openess )))/0.5]
  
  message("calc flex world")
  #---VAT for regional models: 1 = SBS-wet; 2 = SBS-dry; 3 = Dry Forest; 4 = Boreal_A; 5 = Boreal_B
  #---Note: age > 0 is added a query to remove any harvesting that occurs in the same sim time
  #TODO code out Boreal_B
  fisher.habitat <- data.table(dbGetQuery(sim$clusdb, "select fisherhabitat.pixelid, fetaid, den_p, rus_p, cav_p, cwd_p, mov_p, age, height, crownclosure, basalarea, qmd from fisherhabitat inner join pixels on fisherhabitat.pixelid = pixels.pixelid"))
  total_cut <- sim$harvestPixelList[nrow(sim$harvestPixelList),]$cvalue/P(sim, "periodLength", "growingStockCLUS")
 
  if(is.null(sim$harvestPixelList)){
    estLength = 1
  }else{
    estLength =P(sim, "periodLength", "growingStockCLUS")
  }
  
  for(i in 1:estLength){
    if(!is.null(sim$harvestPixelList)){
      fisher.habitat<-fisher.habitat[pixelid %in% sim$harvestPixelList[cvalue <= total_cut*i & cvalue > total_cut*(i-1),]$pixelid, age:=0]
    }
    fisher.habitat[den_p == 1 & age >= 125 & crownclosure >= 30 & qmd >=28.5 & basalarea >= 29.75, denning:=1][den_p == 2 & age >= 125 & crownclosure >= 20 & qmd >=28 & basalarea >= 28, denning:=1][den_p == 3 & age >= 207 & crownclosure >= 20 & qmd >= 34.3, denning:=1][den_p == 4 & age >= 88 & qmd >= 19.5 & height >= 19, denning:=1][den_p == 5 & age >= 98 & qmd >= 21.3 & height >= 22.8, denning:=1]
    fisher.habitat[rus_p == 1 & age > 0 & crownclosure >= 30 & qmd >= 22.7 & basalarea >= 35 & height >= 23.7, rust:=1][rus_p == 2 & age >= 72 & crownclosure >= 25 & qmd >= 19.6 & basalarea >= 32, rust:=1][rus_p == 3 & age >= 83 & crownclosure >=40 & qmd >= 20.1, rust:=1][rus_p == 4 & age >= 78 & crownclosure >=50 & qmd >= 18.5 & height >= 19 & basalarea >= 31.4, rust:=1][rus_p == 5 & age >= 68 & crownclosure >=35 & qmd >= 17 & height >= 14.8, rust:=1]
    fisher.habitat[cav_p == 1 & age > 0 & crownclosure >= 25 & qmd >= 30 & basalarea >= 32 & height >=35, cavity:=1][cav_p == 2 & age > 0 & height >= 35 & basalarea >=32, cavity:=1]
    fisher.habitat[cwd_p == 1 & age >= 135 & qmd >= 22.7 & height >= 23.7, cwd:=1][cwd_p == 2 & age >= 135 & crownclosure >= 25 & qmd >= 22.7 & height >= 23.7, cwd:=1][cwd_p == 3 & age >= 100, cwd:=1][cwd_p >= 4 & age >= 78 & qmd >= 18.1 & height >= 19 & crownclosure >=60, cwd:=1]
    fisher.habitat[mov_p > 0 & age > 0 & crownclosure >= 40, movement:=1]
  
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
    fisher.habitat.rs[ pop == 1 & denning > 0, denning:=log(denning)][ pop == 1 & cavity > 0, cavity:=log(cavity)]
    fisher.habitat.rs[ pop == 2 & denning > 0, denning:=log(denning)]
    fisher.habitat.rs[ pop >= 3 & rust > 0, rust:=log(rust)]
    
    fisher.habitat.rs[ pop == 1, d2:= mahalanobis(fisher.habitat.rs[ pop == 1, c("denning", "rust", "cavity", "cwd", "mov")], c(1.6, 36.2, 0.7, 30.4, 26.8), cov = sim$fisher.d2.cov[[1]])]
    fisher.habitat.rs[ pop == 2, d2:= mahalanobis(fisher.habitat.rs[ pop == 2, c("denning", "rust", "cavity", "cwd", "mov")], c(1.2, 19.1, 0.5, 10.2, 33.1), cov = sim$fisher.d2.cov[[2]])]
    fisher.habitat.rs[ pop == 3, d2:= mahalanobis(fisher.habitat.rs[ pop == 3, c("denning", "rust", "cwd", "mov")], c(2.3, 1.6, 10.8, 21.5), cov = sim$fisher.d2.cov[[3]])]
    fisher.habitat.rs[ pop >= 4, d2:= mahalanobis(fisher.habitat.rs[ pop >= 4, c("denning", "rust", "cwd", "mov")], c(24.0, 2.2, 17.4, 56.2), cov = sim$fisher.d2.cov[[4]])]
    
    fisher.habitat.mahal<-merge(fisher.habitat, fisher.habitat.rs[,c("fetaid", "d2", "pop", "mov")], by.x = "fetaid", by.y = "fetaid", all.x =T)
  
    #-----Create Raster of D2
    ras.mahal<-sim$ras
    ras.mahal[]<-NA
    ras.mahal[fisher.habitat.mahal$pixelid]<-fisher.habitat.mahal$d2/100
    
    #---Create Raster of movement
    ras.mov<-sim$ras
    ras.mov[] <- NA
    ras.mov[fisher.habitat.mahal$pixelid]<-fisher.habitat.mahal$mov*2

    #Aggregate to a 30km pixels and save for FLEX
    if(i == 1){
      sim$flexRasWorld[[2]] <- aggregate(ras.mahal, fact =55)
      sim$flexRasWorld[[3]] <- aggregate(ras.mov, fact =55)
    }else{
      sim$flexRasWorld[[2]] <- stack(sim$flexRasWorld[[2]], aggregate(ras.mahal, fact =55))
      sim$flexRasWorld[[3]] <- stack(sim$flexRasWorld[[3]], aggregate(ras.mov, fact =55))
    }
  }
  
  fisherReport<-merge(occupancy, fisher.habitat.rs[, c("fetaid", "d2")], by.x = "zone", by.y = "fetaid")
  fisherReport[, c("timeperiod", "scenario", "compartment") := list(time(sim)*sim$updateInterval, sim$scenario$name, sim$boundaryInfo[[3]]) ] 
  sim$fisherReport<-rbindlist(list(sim$fisherReport, fisherReport), use.names=TRUE)
  
  return(invisible(sim)) 
}

.inputObjects <- function(sim) {
  #dPath <- asPath(getOption("reproducible.destinationPath", dataPath(sim)), 1)
  #message(currentModule(sim), ": using dataPath '", dPath, "'.")
  return(invisible(sim))
}


