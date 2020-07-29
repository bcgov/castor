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
  name = "uploaderCLUS",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors =  c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
               person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", uploaderCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "uploaderCLUS.Rmd"),
  reqdPkgs = list("sf", "rpostgis","DBI", "RSQLite", "data.table"),
  parameters = rbind(
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter("aoiName", "character", "test", NA, NA, "The name of the ares of interest i.e., chilcotin"),
    defineParameter("dbInfo", "list", list("localhost","clus", "password", "clus"), NA, NA, "A list of database information in the order: host, user, password, database"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput(objectName ="clusdb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates clus realted information", sourceURL = NA),
    expectsInput(objectName ="scenario", objectClass ="data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName ="foreststate", objectClass ="data.table", desc = 'The current state of the forest from dataLoaderCLUS', sourceURL = NA),
    expectsInput(objectName ="updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA)
    
  ),
  outputObjects = bind_rows(
    createsOutput(objectName = NA, objectClass = NA, desc = NA)
  )
))

doEvent.uploaderCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init(sim) #if the schema exists - delete all the rows that are labeled with the scenario and if it doesn't make it
      sim <- scheduleEvent(sim, end(sim), "uploaderCLUS", "save", 99999)
    },
    save = {
      sim <- save.currentState(sim)
      sim <- save.reports(sim)
      sim <- save.rasters(sim) 
    },
    
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  #check to see if a scenario table exists. If it does -- delete from the table where scenario is equal to the scenario
  connx<-DBI::dbConnect(dbDriver("PostgreSQL"), 
                        host=P(sim, "uploaderCLUS", "dbInfo")[[1]], 
                        dbname = P(sim, "uploaderCLUS", "dbInfo")[[4]], 
                        port='5432', 
                        user=P(sim, "uploaderCLUS", "dbInfo")[[2]],
                        password= P(sim, "uploaderCLUS", "dbInfo")[[3]])

  #Does the schema exist?
  if(length(dbGetQuery(connx, paste0("SELECT schema_name FROM information_schema.schemata WHERE schema_name = '", P(sim, "uploaderCLUS", "aoiName") ,"';"))) > 0){
    message("...remove old information")
    #remove all the rows that have the scenario name in them
    if(length(sim$foreststate) > 0){
      message("...Add new forest state")
      dbExecute(connx, paste0("DELETE FROM ",P(sim, "uploaderCLUS", "aoiName"), ".state where aoi = '", P(sim, "uploaderCLUS", "aoiName"), "' and compartment in('",paste(sim$boundaryInfo[[3]], sep = " ", collapse = "','"),"');"))
    }
    
    dbExecute(connx, paste0("DELETE FROM ",P(sim, "uploaderCLUS", "aoiName"), ".scenarios where scenario = '", sim$scenario$name, "';"))
    dbExecute(connx, paste0("INSERT INTO ",P(sim, "uploaderCLUS", "aoiName"), ".scenarios (scenario, description) values ('", sim$scenario$name,"', '", sim$scenario$description, "');"))
    
    dbExecute(connx, paste0("DELETE FROM ",P(sim, "uploaderCLUS", "aoiName"), ".harvest where scenario = '", sim$scenario$name, "' and compartment in('",paste(sim$boundaryInfo[[3]], sep = " ", collapse = "','"),"');"))
    dbExecute(connx, paste0("DELETE FROM ",P(sim, "uploaderCLUS", "aoiName"), ".growingstock where scenario = '", sim$scenario$name,"' and compartment in('",paste(sim$boundaryInfo[[3]], sep = " ", collapse = "','"),"');"))
    dbExecute(connx, paste0("DELETE FROM ",P(sim, "uploaderCLUS", "aoiName"), ".rsf where scenario = '", sim$scenario$name, "' and compartment in('",paste(sim$boundaryInfo[[3]], sep = " ", collapse = "','"),"')"))
    dbExecute(connx, paste0("DELETE FROM ",P(sim, "uploaderCLUS", "aoiName"), ".survival where scenario = '", sim$scenario$name, "' and compartment in('",paste(sim$boundaryInfo[[3]], sep = " ", collapse = "','"),"')"))
    dbExecute(connx, paste0("DELETE FROM ",P(sim, "uploaderCLUS", "aoiName"), ".yielduncertainty where scenario = '", sim$scenario$name, "' and compartment in('",paste(sim$boundaryInfo[[3]], sep = " ", collapse = "','"),"');"))
    dbExecute(connx, paste0("DELETE FROM ",P(sim, "uploaderCLUS", "aoiName"), ".disturbance where scenario = '", sim$scenario$name, "' and compartment in('",paste(sim$boundaryInfo[[3]], sep = " ", collapse = "','"),"');"))
    dbDisconnect(connx)
  }else{
    #Create the schema and all the tables
    dbExecute(connx, paste0("CREATE SCHEMA ",P(sim, "uploaderCLUS", "aoiName"),";"))
    dbExecute(connx, paste0("GRANT ALL ON SCHEMA ",P(sim, "uploaderCLUS", "aoiName")," TO appuser;"))
    dbExecute(connx, paste0("GRANT ALL ON SCHEMA ",P(sim, "uploaderCLUS", "aoiName")," TO clus_project;"))
    #Create the tables
    tableList = list(state = data.table(aoi=character(), compartment=character(), total= integer(), thlb= numeric(), early= integer(), mature= integer(), old= integer(), road = integer()),

                    scenarios = data.table(scenario =character(), description= character()), 
                    harvest = data.table(scenario = character(), timeperiod = integer(), compartment = character(), target= numeric(), area= numeric(), volume = numeric(), age = numeric(), hsize = numeric(), avail_thlb= numeric(), transition_area = numeric(), transition_volume= numeric()), 
                    growingstock = data.table(scenario = character(), compartment = character(), timeperiod = integer(), gs = numeric(), m_gs = numeric(), m_dec_gs = numeric()), 
                    rsf = data.table(scenario = character(), compartment = character(), timeperiod = integer(), critical_hab = character() , sum_rsf_hat = numeric() , sum_rsf_hat_75 = numeric(), per_rsf_hat_75 = numeric(), rsf_model= character()), 
                    survival = data.table(scenario = character(), compartment = character(), timeperiod = integer(), herd_bounds = character() , prop_age = numeric(), prop_mature = numeric(), prop_old = numeric(), survival_rate= numeric(), area = integer()),
                    disturbance = data.table(scenario = character(), compartment = character(), timeperiod = integer(), critical_hab = character(), dist500= numeric(), dist500_per = numeric(), dist= numeric(), dist_per = numeric()),
                    yielduncertainty = data.table(scenario = character(), compartment = character(), timeperiod = integer(), projvol = numeric(), calibvol = numeric (), prob = numeric(), pred5 = numeric(), pred95 = numeric() )
    )
    tablesUpload<-c("state", "scenarios", "harvest","growingstock", "rsf", "survival", "disturbance", "yielduncertainty")
    for(i in 1:length(tablesUpload)){
      dbWriteTable(connx, c(P(sim, "uploaderCLUS", "aoiName"), tablesUpload[[i]]), tableList[[tablesUpload[i]]], row.names = FALSE)
      dbExecute(connx, paste0("GRANT SELECT ON ", P(sim, "uploaderCLUS", "aoiName"),".", tablesUpload[[i]]," to appuser;"))
      dbExecute(connx, paste0("GRANT ALL ON ", P(sim, "uploaderCLUS", "aoiName"),".", tablesUpload[[i]]," to clus_project;"))
    }
    
    dbExecute(connx, paste0("INSERT INTO ",P(sim, "uploaderCLUS", "aoiName"), ".scenarios (scenario, description) values ('", sim$scenario$name,"', '", sim$scenario$description, "');"))
    dbDisconnect(connx)
  }
  return(invisible(sim))
}

save.currentState<- function(sim){
  if(length(sim$foreststate)>0){
    connx<-DBI::dbConnect(dbDriver("PostgreSQL"), 
                          host=P(sim, "uploaderCLUS", 
                                 "dbInfo")[[1]], 
                          dbname = P(sim, "uploaderCLUS", 
                                     "dbInfo")[[4]], 
                          port='5432', 
                          user=P(sim, "uploaderCLUS", "dbInfo")[[2]],
                          password= P(sim, "uploaderCLUS", "dbInfo")[[3]])

  
    sim$foreststate[,aoi:= P(sim, "uploaderCLUS", "aoiName")]
    dbWriteTable(connx, c(P(sim, "uploaderCLUS", "aoiName"), 'state'), 
                 sim$foreststate, append = T, row.names = FALSE)
  

    dbDisconnect(connx)
  }
  return(invisible(sim))
}

save.reports <-function (sim){

  connx<-DBI::dbConnect(dbDriver("PostgreSQL"), 
                        host=P(sim, "uploaderCLUS", "dbInfo")[[1]], 
                        dbname = P(sim, "uploaderCLUS", "dbInfo")[[4]], 
                        port='5432', 
                        user=P(sim, "uploaderCLUS", "dbInfo")[[2]],
                        password= P(sim, "uploaderCLUS", "dbInfo")[[3]])
  #harvestingReport
  if(!is.null(sim$harvestReport)){
    dbWriteTable(connx, c(P(sim, "uploaderCLUS", "aoiName"), 'harvest'),
                 sim$harvestReport, append = T,
                 row.names = FALSE)
  }
  #GrowingStockReport
  if(!is.null(sim$growingStockReport)){
    dbWriteTable(connx, c(P(sim, "uploaderCLUS", "aoiName"), 'growingstock'), 
                 sim$growingStockReport, append = T,
                 row.names = FALSE)
  }
  #rsf
  if(!is.null(sim$rsf)){
    dbWriteTable(connx, c(P(sim, "uploaderCLUS", "aoiName"), 'rsf'), 
                 sim$rsf, append = T,row.names = FALSE)
  }
  #survival
  if(!is.null(sim$tableSurvival)){
    dbWriteTable(connx, c(P(sim, "uploaderCLUS", "aoiName"), 'survival'), 
                 sim$tableSurvival, append = T,row.names = FALSE)
  }
  #disturbance
  if(!is.null(sim$disturbanceReport)){
    DBI::dbWriteTable(connx, c(P(sim, "uploaderCLUS", "aoiName"), 'disturbance'), 
                      sim$disturbanceReport, append = T,row.names = FALSE)
  }
  #yielduncertainty
  if(!is.null(sim$yielduncertain)){
    DBI::dbWriteTable(connx, c(P(sim, "uploaderCLUS", "aoiName"), 'yielduncertainty'), 
                      sim$yielduncertain, append = T,row.names = FALSE)
  }
  dbDisconnect(connx)
  return(invisible(sim)) 
}

save.rasters <-function (sim){
  #rasters
  
  if(is.null(sim$foreststate)){
    connx<-DBI::dbConnect(dbDriver("PostgreSQL"), 
                          host=P(sim, "uploaderCLUS", "dbInfo")[[1]], 
                          dbname = P(sim, "uploaderCLUS", "dbInfo")[[4]], 
                          port='5432', 
                          user=P(sim, "uploaderCLUS", "dbInfo")[[2]],
                          password= P(sim, "uploaderCLUS", "dbInfo")[[3]])
    ##blocks
    message('....cutblock raster')
    commitRaster(layer = paste0(paste0(here::here(), "/R/SpaDES-modules/forestryCLUS/") ,paste0(sim$scenario$name, "_",P(sim, "dataLoaderCLUS", "nameBoundary"), "_harvestBlocks.tif")), 
                 schema = P(sim, "uploaderCLUS", "aoiName"), 
                 name = paste0(sim$scenario$name, "_", sim$boundaryInfo[[3]][[1]],"_cutblocks"), 
                 dbInfo = P(sim, "uploaderCLUS", "dbInfo") )
    dbExecute(connx, paste0("GRANT SELECT ON ", P(sim, "uploaderCLUS", "aoiName"),".", paste0(sim$scenario$name, "_", sim$boundaryInfo[[3]][[1]],"_cutblocks")," to appuser;"))
    dbExecute(connx, paste0("GRANT ALL ON ", P(sim, "uploaderCLUS", "aoiName"),".", paste0(sim$scenario$name, "_", sim$boundaryInfo[[3]][[1]],"_cutblocks")," to clus_project;"))
    
    ##roads
    if(!is.null(sim$roads)){

    message('....roads raster')
    commitRaster(layer = paste0(paste0(here::here(), "/R/SpaDES-modules/forestryCLUS/")  ,sim$boundaryInfo[[3]][[1]],"_", P(sim, "roadCLUS", "roadMethod"),"_", time(sim)*sim$updateInterval, ".tif"), 
                 schema = P(sim, "uploaderCLUS", "aoiName"), name = paste0(sim$scenario$name, "_", sim$boundaryInfo[[3]][[1]],"_roads"),
                 dbInfo = P(sim, "uploaderCLUS", "dbInfo"))
    dbExecute(connx, paste0("GRANT SELECT ON ", P(sim, "uploaderCLUS", "aoiName"),".", paste0(sim$scenario$name, "_", sim$boundaryInfo[[3]][[1]],"_roads")," to appuser;"))
    dbExecute(connx, paste0("GRANT ALL ON ", P(sim, "uploaderCLUS", "aoiName"),".", paste0(sim$scenario$name, "_", sim$boundaryInfo[[3]][[1]],"_roads")," to clus_project;"))
    
    }
    ##zoneConstraint
    message('....constraint raster')
    commitRaster(layer = paste0(paste0(here::here(), "/R/SpaDES-modules/forestryCLUS/") , paste0(sim$scenario$name, "_",P(sim, "dataLoaderCLUS", "nameBoundary"), "_constraints.tif")), 
                 schema = P(sim, "uploaderCLUS", "aoiName"), 
                 name = paste0(sim$scenario$name, "_", sim$boundaryInfo[[3]][[1]],"_constraint"),
                 dbInfo = P(sim, "uploaderCLUS", "dbInfo"))
    dbExecute(connx, paste0("GRANT SELECT ON ", P(sim, "uploaderCLUS", "aoiName"),".", paste0(sim$scenario$name, "_", sim$boundaryInfo[[3]][[1]],"_constraint")," to appuser;"))
    dbExecute(connx, paste0("GRANT ALL ON ", P(sim, "uploaderCLUS", "aoiName"),".", paste0(sim$scenario$name, "_", sim$boundaryInfo[[3]][[1]],"_constraint")," to clus_project;"))
    
    ##rsfEND
  }
  return(invisible(sim)) 
}

#---Other functions
commitRaster<-function(layer, schema, name, dbInfo){
  #print(paste0('raster2pgsql -s 3005 -d -I -C -M -N 2147483648  ', layer, ' -t 100x100 ', schema, '.', name, ' |  psql postgres://', dbInfo[[2]], ':', dbInfo[[3]], '@', dbInfo[[1]], ':5432/',dbname = dbInfo[[4]]))
  system("cmd.exe", 
         input = paste0('raster2pgsql -s 3005 -d -I -C -M -N 2147483648  ', layer, ' -t 100x100 ', schema, '.', name, ' |  psql postgres://', dbInfo[[2]], ':', dbInfo[[3]], '@', dbInfo[[1]], ':5432/',dbname = dbInfo[[4]]), 
         show.output.on.console = FALSE, 
         invisible = TRUE)
}
