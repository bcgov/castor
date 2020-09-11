
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
    defineParameter ("nameRasFisherTerritory", "character", "rast.zone_cond_fisher_dry", NA, NA, "Name of the raster(s) descirbing fisher territories. Stored in psql."), 
    defineParameter ("nameRasWetlands", "character", "rast.wetlands", NA, NA, "Name of the raster for wetlands as described in Weir and Corbould 2010")
    ),
  inputObjects = bind_rows(
    expectsInput (objectName = "clusdb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the model. This module needs the age variable from the pixels table in the clusdb.', sourceURL = NA),
    expectsInput(objectName ="scenario", objectClass ="data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName ="updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA),
    expectsInput(objectName ="boundaryInfo", objectClass ="character", desc = "Name of the area of interest(aoi) eg. Quesnel_TSA", sourceURL = NA),
    expectsInput(objectName ="zone.length", objectClass ="integer", desc = "The number of zones", sourceURL = NA)
  ),
  outputObjects = bind_rows(
    createsOutput (objectName = "tableFisherOccupancy", objectClass = "data.table", desc = "A data.table object. Consists of fisher occupancy estimates for each territory in the study area at each time step. Gets saved in the 'outputs' folder of the module.")
  )
))

doEvent.fisherCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init(sim)
      sim <- predictOccupancy(sim)
      sim <- scheduleEvent (sim, time(sim) + P(sim, "fisherCLUS", "calculateInterval"), "fisherCLUS", "calculateFisherOccupancy", 8) # schedule the next calculation event 
    },
    calculateFisherOccupancy = { # calculate fisher occupancy at each time interval 
      sim <- predictOccupancy (sim) # this function calculates survival rate
      sim <- scheduleEvent (sim, time(sim) + P(sim, "fisherCLUS", "calculateInterval"), "fisherCLUS", "calculateFisherOccupancy", 8) # schedule the next calculation event  
    },
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
                  "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  fisher.ras.ter<-data.table(reference_zone = P(sim, "fisherCLUS", "nameRasFisherTerritory"))
  #Add any territory not already in the clusdb
  getFisherTerritory<-fisher.ras.ter[!(reference_zone %in% dbGetQuery(sim$clusdb, "SELECT reference_zone FROM zone")$reference_zone),]
  if(nrow(getFisherTerritory) > 0){
    getFisherTerritory[,zone:= paste0("zone", .I + as.integer(sim$zone.length))] #assign zone name as the last zone number plus the new zones
    
    for(i in 1:nrow(getFisherTerritory)){
      dbExecute (sim$clusdb, paste0("ALTER TABLE pixels ADD COLUMN ", getFisherTerritory$zone[i], " integer")) # add a column to the pixel table that will define the fisher territory  
      
      ras.territory <- data.table (c (t (raster::as.matrix ( # 
      RASTER_CLIP2 (tmpRast = sim$boundaryInfo[[3]], 
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
  }
  #Add in the permenant wetlands raster
  if(nrow(data.table(dbGetQuery(sim$clusdb, "PRAGMA table_info(pixels)"))[name == 'wetland',])== 0){
    dbExecute (sim$clusdb, "ALTER TABLE pixels ADD COLUMN wetland integer") # add a column to the pixel table that will define the wetland area   
    ras.wetland <- data.table (c (t (raster::as.matrix ( # 
      RASTER_CLIP2 (tmpRast = sim$boundaryInfo[[3]], 
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
   gc()
  
  #Initiate the time 0 output object tableFisherOccupancy
  sim$tableFisherOccupancy<-data.table(timeperiod = as.integer(), scenario = as.character(), compartment =  as.character(), openess = as.numeric(), zone = as.integer(), reference_zone = as.character(), rel_prob_occup = as.numeric())

  return(invisible(sim))
}

predictOccupancy<- function(sim) {
  getFisherTerritory<-dbGetQuery(sim$clusdb, paste0("SELECT * FROM zone WHERE reference_zone IN ('", paste(P(sim, "fisherCLUS", "nameRasFisherTerritory"), sep = " ", collapse="', '"),"')"))
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

.inputObjects <- function(sim) {
  #dPath <- asPath(getOption("reproducible.destinationPath", dataPath(sim)), 1)
  #message(currentModule(sim), ": using dataPath '", dPath, "'.")
  return(invisible(sim))
}


