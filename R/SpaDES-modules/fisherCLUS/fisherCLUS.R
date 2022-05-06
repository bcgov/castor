
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
    defineParameter ("nameRasFisherTerritory", "character", NA, NA, NA, "Name of the raster(s) descirbing fisher territories. Stored in psql."), 
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
    createsOutput (objectName = "tableFisherOccupancy", objectClass = "data.table", desc = "A data.table object. Consists of fisher occupancy estimates for each territory in the study area at each time step. Gets saved in the 'outputs' folder of the module.")
  )
))

doEvent.fisherCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init(sim) #Gets the needed spatial layers
      sim <- predictOccupancy(sim)# Predicts the time =0 fisher occupancy
      sim <- scheduleEvent (sim, time(sim) + P(sim, "fisherCLUS", "calculateInterval"), "fisherCLUS", "calculateFisherOccupancy", 8) # schedule the next calculation event 
    },
    calculateFisherOccupancy = { # calculate fisher occupancy at each time interval 
      sim <- predictOccupancy (sim) # Calculates fisher occupancy
      sim <- scheduleEvent (sim, time(sim) + P(sim, "fisherCLUS", "calculateInterval"), "fisherCLUS", "calculateFisherOccupancy", 8) # schedule the next calculation event  
    },
    setFisherHabitat = {
      sim <- flexWorld(sim) #preps the object need for flex
      sim <- scheduleEvent (sim, time(sim) + P(sim, "fisherCLUS", "calculateInterval"), "fisherCLUS", "setFisherHabitat", 8) # schedule the next
    },
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
                  "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  fisher.ras.ter<-data.table(reference_zone = P(sim, "fisherCLUS", "nameRasFisherTerritory"))
  #Add any territory not already in the clusdb
  getFisherTerritory<-fisher.ras.ter[!(reference_zone %in% sim$zone.available$reference_zone),]

  if(nrow(getFisherTerritory) > 0){
    getFisherTerritory[,zone:= paste0("zone", .I + as.integer(length(sim$zone.available$reference_zone)))] #assign zone name as the last zone number plus the new zones
    for(i in 1:nrow(getFisherTerritory)){
      dbExecute (sim$clusdb, paste0("ALTER TABLE pixels ADD COLUMN ", getFisherTerritory$zone[i], " integer")) # add a column to the pixel table that will define the fisher territory  
      
      ras.territory <- data.table (c (t (raster::as.matrix ( # 
      RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), 
                    srcRaster = getFisherTerritory$reference_zone[i] , # 
                    clipper = P (sim, "dataLoaderCLUS", "nameBoundaryFile"),  # 
                    geom = P (sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                    where_clause =  paste0 (P (sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                    conn = NULL)))))
      
 
      ras.territory[, V1 := as.integer (V1)] # add the herd boudnary value from the raster and make the value an integer
      ras.territory[, pixelid := seq_len(.N)] # add pixelid value
      
      dbBegin (sim$clusdb) # fire up the db and add the herd boundary values to the pixels table 
        rs <- dbSendQuery (sim$clusdb, paste0("Update pixels set ", getFisherTerritory$zone[i], "= :V1 where pixelid = :pixelid", ras.territory)) 
      dbClearResult (rs)
      dbCommit (sim$clusdb) # commit the new column to the db
      
      #Add the new fisher territory to the zone table
      dbExecute (sim$clusdb, paste0("INSERT INTO zone (zone_column, reference_zone) VALUES (", getFisherTerritory$zone[i], ", ", getFisherTerritory$reference_zone[i], ")")) 
    
    }
    rm(ras.territory,getFisherTerritory)
    #Add in the permanent wetlands raster to pixels table
    gc()
    if(dbGetQuery (sim$clusdb, "SELECT COUNT(*) as exists_check FROM pragma_table_info('pixels') WHERE name='wetland';")$exists_check > 0){
      dbExecute (sim$clusdb, "ALTER TABLE pixels ADD COLUMN wetland integer") # add a column to the pixel table that will define the wetland area   
      ras.wetland <- data.table (c (t (raster::as.matrix ( # 
        RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), 
                      srcRaster = P(sim, "fisherCLUS", "nameRasWetlands") , # 
                      clipper = P (sim, "dataLoaderCLUS", "nameBoundaryFile"),  # 
                      geom = P (sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                      where_clause =  paste0 (P (sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                      conn = NULL)))))
      ras.wetland[, V1 := as.integer (V1)] # add the wetlands value from the raster and make the value an integer
      ras.wetland[, pixelid := seq_len(.N)] # add pixelid value
      
      dbBegin (sim$clusdb) # add values to the pixels table 
      rs <- dbSendQuery (sim$clusdb, paste0("Update pixels set wetland = :V1 where pixelid = :pixelid"), ras.wetland) 
      dbClearResult (rs)
      dbCommit (sim$clusdb) # commit the new column to the db
      
      rm(ras.wetland)
    }
  }

  #Initiate the time 0 output object tableFisherOccupancy
  sim$tableFisherOccupancy<-data.table(timeperiod = as.integer(), scenario = as.character(), compartment =  as.character(), openess = as.numeric(), zone = as.integer(), reference_zone = as.character(), rel_prob_occup = as.numeric())

  #---------FLEX modelling
  if(nrow(dbGetQuery(sim$clusdb, "SELECT name FROM sqlite_schema WHERE type ='table' AND name = 'fisherhabitat';")) == 0){
    #Create the table in the database
    dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS fisherhabitat (pixelid integer, fetaid integer, den_p integer, rus_p integer, mov_p integer, cwd_p integer, cav_p integer)")
    feta.ras <- RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = P(sim, "nameFetaRaster", "fisherCLUS") , # 
                             clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                             where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                             conn = NULL)
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
                    mov_p = dbgetQuery(sim$clusdb, "SELECT treed FROM pixels ORDER BY pixelid;"))
    
    hab_p<-hab_p[!is.na(fetaid) & mov_p > 0,] #Remove the non contributing pixels
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "INSERT INTO fisherhabitat (pixelid , fetaid,  den_p, rus_p, cwd_p, cav_p, mov_p) 
                        values (:pixelid , :fetaid,  :den_p, :rus_p, :cwd_p, :cav_p, :mov_p);", hab_p)
    dbClearResult(rs)
    dbCommit(sim$clusdb)
  }
  
  return(invisible(sim))
}

predictOccupancy<- function(sim) {
  getFisherTerritory<- sim$zone.available[reference_zone %in% P(sim, "fisherCLUS", "nameRasFisherTerritory"),]
  #Build the query -- appending by fisher territory
  sql_fisher<-lapply(1:length(getFisherTerritory$zone_column), 
                     function(i){
                      data.table(dbGetQuery(sim$clusdb, paste0("Select (cast(sum(case when wetland > 0 OR age < 12 then 1 else 0 end) as float)/count())*100 as openess, ", getFisherTerritory$zone_column[i] ," as zone, '",getFisherTerritory$reference_zone[i],"' as reference_zone from pixels 
                      where ", getFisherTerritory$zone_column[i]," is not null group by ",getFisherTerritory$zone_column[i] )))
                      })
  occupancy<-rbindlist(sql_fisher)
  #Model from Weir and Corbould 2010
  occupancy[, rel_prob_occup:= ((exp(-0.219*openess))/(1+exp(-0.219*openess )))/0.5]
  occupancy[, c("timeperiod", "scenario", "compartment") := list(time(sim)*sim$updateInterval, sim$scenario$name, sim$boundaryInfo[[3]]) ] 
  
  sim$tableFisherOccupancy<-rbindlist(list(sim$tableFisherOccupancy, occupancy), use.names = TRUE)
  return(invisible(sim))
}

flexWorld<-function(sim){
  message("calc flex input")
  #---VAT for regional models: 1 = SBS-wet; 2 = SBS-dry; 3 = Dry Forest; 4 = Boreal_A; 5 = Boreal_B
  #---Note: age > 0 is added a query to remove any harvesting that occurs in the same sim time
  #TODO code out Boreal_B
  fisher.habitat<-dbGetQuery(userdb, "select fisherhabitat.pixelid, fetaid, den_p, rus_p, cav_p, cwd_p, age, height, crownclosure, basalarea, qmd from fisherhabitat inner join pixels on fisherhabitat.pixelid = pixels.pixelid")
  fisher.fetas<-dbGetQuery(sim$clusdb, "SELECT * FROM fetas;") #contains x, y, zone, population and feta id
  
  total_cut<-sim$harvestPixelList[nrow(sim$harvestPixelList),]$cvalue/P(sim, "periodLength", "growingstockCLUS")
  for(i in 1:P(sim, "periodLength", "growingstockCLUS")){
    fisher.habitat<-fisher.habitat[pixelid %in% sim$harvestPixelList[cvalue <= total_cut*i & cvalue > total_cut*(i-1),]$pixelid, age:=0]
    fisher.habitat[den_p == 1 & age >= 125 & crownclosure >= 30 & qmd >=28.5 & basalarea >= 29.75, denning:=1][den_p == 2 & age >= 125 & crownclosure >= 20 & qmd >=28 & basalarea >= 28, denning:=1][den_p == 3 & age >= 207 & crownclosure >= 20 & qmd >= 34.3, denning:=1][den_p == 4 & age >= 88 & qmd >= 19.5 & height >= 19, denning:=1]
    fisher.habitat[rus_p == 1 & age > 0 & crownclosure >= 30 & qmd >= 22.7 & basalarea >= 35 & height >= 23.7, rust:=1][rus_p == 2 & age >= 72 & crownclosure >= 25 & qmd >= 19.6 & basal_area >= 32, rust:=1][rus_p == 3 & age >= 83 & crownclosure >=40 & qmd >= 20.1, rust:=1][rus_p == 4 & age >= 78 & crownclosure >=50 & qmd >= 18.5 & height >= 19 & basalarea >= 31.4, rust:=1]
    fisher.habitat[cav_p == 1 & age > 0 & crownclosure >= 25 & qmd >= 30 & basalarea >= 32 & height >=35, cavity:=1][cav_p == 2 & age > 0 & height >= 35 & basal_area >=32, cavity:=1]
    fisher.habitat[cwd_p == 1 & age >= 135 & qmd >= 22.7 & height >= 23.7, cwd:=1][cwd_p == 2 & age >= 135 & crownclosure >= 25 & qmd >= 22.7 & height >= 23.7, cwd:=1][cwd_p == 3 & age >= 100, cwd:=1][cwd_p == 4 & age >= 78 & qmd >= 18.1 & height >= 19 & crownclosure >= 60, cwd:=1]
    fisher.habitat[mov_p == 1 & age > 0 & crownclosure >= 50, mov:=1]
  
    #---Summarize habitat by the feta
    den<-fisher.habitat[den_p > 0, .(denning = sum(denning, na.rm =T)/3000), by = fetaid]
    cav<-fisher.habitat[cav_p > 0, .(cavity = sum(cavity, na.rm =T)/3000), by = fetaid]
    rus<-fisher.habitat[rus_p > 0, .(rust = sum(rust, na.rm =T)/3000), by = fetaid] 
    cwd<-fisher.habitat[cwd_p > 0, .(cwd = sum(cwd, na.rm =T)/3000), by = fetaid]
    mov<-fisher.habitat[mov_p > 0, .(movement = sum(movement, na.rm =T)/3000), by = fetaid]
  
    #---Merge all data.table together
    fisher.habitat.rs <- Reduce(function(...) merge(..., all = TRUE), list(den,cav,rus,cwd,mov))
  
    #---Calculate D2 (Mahalanobis)
  
    #Aggregate to a 30km pixels and save for FLEX
    test<-aggregate(ras, fact =55)
  }
  sim$fisherWorld <- raster::stack()
  return(invisible(sim)) 
}

.inputObjects <- function(sim) {
  #dPath <- asPath(getOption("reproducible.destinationPath", dataPath(sim)), 1)
  #message(currentModule(sim), ": using dataPath '", dPath, "'.")
  return(invisible(sim))
}


