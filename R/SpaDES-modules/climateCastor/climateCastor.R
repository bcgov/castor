# Copyright 2023 Province of British Columbia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
#===========================================================================================#
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.
#===========================================================================================#

defineModule (sim, list (
  name = "climateCastor",
  description = "This module grabs the climate data from climateNA using climR for any area within the province",
  keywords = c ("climate", "gcm", "ssp", "future climate"), 
  authors = c (person ("Elizabeth", "Kleynhans", email = "elizabeth.kleynhans@gov.bc.ca", role = c("aut", "cre")),
               person ("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character (0),
  version = list (SpaDES.core = "0.2.5", climateCastor = "1.0.0"),
  spatialExtent = raster::extent (rep (NA_real_, 4)),
  timeframe = as.POSIXlt (c (NA, NA)),
  timeunit = "year",
  citation = list ("citation.bib"),
  documentation = list ("README.md", "climateCastor.Rmd"),
  reqdPkgs = list ("climr", "data.table", "terra", "here", "raster", "SpaDES.tools", "tidyr", "pool", "RSQLite"),
  parameters = rbind (
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter ("calculateInterval", "numeric", 1, 1, 5, "The simulation time at which climate variables are collected"),
    defineParameter("gcm", "character", '99999', NA, NA, "Global climate model from which to get future climate data e.g. ACCESS-ESM1-5"),
    defineParameter("ssp", "character", '99999', NA, NA, "Climate projection from which to get future climate data e.g. ssp370"),
    defineParameter("climateYears", "character", '99999', NA, NA, "Years to get the climate data for. Can be specified as a single year e.g. 2020, for specific years e.g. c(2020, 2025, 2030) (I think) or as a range e.g. 2020:2060"),
    defineParameter("maxRun", "integer", '99999', NA, NA, "Maximum number of model runs to include. A value of 0 is ensembleMean only."),
    defineParameter("run", "character", '99999', NA, NA, "The run of the climate projection from which to get future climate data e.g. r1i1p1f1"),
    defineParameter("nameClimateIdnoRast","numeric", NA, NA, NA, "Raster of climate_id numbers"),
    defineParameter("nameClimateTable","character", "99999", NA, NA, desc = "This table has the lat, long coordiantes and elevation of each climate_id.")
    ),
  inputObjects = bind_rows(
    expectsInput (objectName = "castordb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the model. This module needs the age variable from the pixels table in the castordb.', sourceURL = NA),
    expectsInput(objectName = "boundaryInfo", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName ="updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA)
  ),
  outputObjects = bind_rows(
    createsOutput (objectName = "climateTable", objectClass = "data.table", desc = "A data.table object. Consists of climate variables, pixelid, year, gcm, ssp, run and all the climate variables needed for a specified area at each time step. Gets saved as a table in the sqlite castordb.")
  )
)
)

## event types
#   - type `init` is required for initialization

doEvent.climateCastor = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- getClimateData(sim)
    },
    
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}
    
    getClimateData <- function(sim) {
      
      qry<-paste0("SELECT COUNT(*) as exists_check FROM sqlite_master WHERE type='table' AND name='climate_", P(sim, "gcmname", "climateCastor"),"_",P(sim, "ssp", "climateCastor"), "';")
      
      if(dbGetQuery(sim$castordb, qry)$exists_check==0) {
     
      message("extract climate_id values from raster")
      
      #We need elevation because climate BC adjusts the climate according to the elevation of the sampling location. 
      #### get climate_idno raster and extract climate_id values ####
      climate_id_rast<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                                srcRaster= P(sim, "nameClimateIdnoRast", "climateCastor"), 
                                                clipper=sim$boundaryInfo[1] , 
                                                geom= sim$boundaryInfo[4] , 
                                                where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                conn=NULL))
      
      if(terra::ext(sim$ras) == terra::ext(climate_id_rast)){
        climate_id<-data.table(pixelid_climate = as.numeric(climate_id_rast[]))
        climate_id[, pixelid := seq_len(.N)] 
      } else{
        stop(paste0("ERROR: extents are not the same check -", P(sim, "nameClimateIdnoRast", "climateCastor")))
      }
      
      dbExecute(sim$castordb, ("ALTER TABLE pixels ADD COLUMN pixelid_climate numeric;"))
      message("add pixelid_climate to pixels table")
      dbBegin(sim$castordb)
      rs<-dbSendQuery(sim$castordb, "UPDATE pixels set pixelid_climate = :pixelid_climate where pixelid = :pixelid", climate_id)
      dbClearResult(rs)
      dbCommit(sim$castordb)
      gc()

      message("look up lat, lon and elevation of climate_pixels")
      
      climate_id_key<-unique(climate_id[!(is.na(pixelid_climate )), pixelid_climate])
      climate_id_key<-data.table(getTableQuery(paste0("SELECT pixelid_climate, lat, long, el  FROM ",P(sim, "nameClimateTable","climateCastor"), " WHERE pixelid_climate IN (", paste(climate_id_key, collapse = ","),");")))
      
      setnames(climate_id_key, c("id", "lat", "lon", "elev"))
      climate_id_key<-climate_id_key[,c("id", "lon", "lat", "elev")]
      
      message("Downloading climate data from climateBC ...")  
      
      ds_out <- climr_downscale(
        xyz = climate_id_key,
        which_normal = "auto",
        historic_period = (P(sim, "historicPeriod", "climateCastor")),#"2001_2020",
        gcm_ts_years = (P(sim, "climateYears", "climateCastor")),
        gcm_models = (P(sim, "gcm", "climateCastor")),
        ssp = (P(sim, "ssp", "climateCastor")),# c("ssp370"),
        max_run = (P(sim, "maxRun", "climateCastor")),
        return_normal = TRUE, ## to return the 1961-1990 normals period
        vars = c("PPT04", "PPT05","PPT06","PPT07","PPT08","Tmax03","Tmax04","Tmax05","Tmax06","Tmax07","Tmax08", "Tave03","Tave04","Tave05","Tave06","Tave07","Tave08","Tave09","CMD06", "CMD07","CMD08","CMD09"))
      
      
      # if (!exists("dbCon")){
      #   dbCon <- climR::data_connect() ##connect to database
      # } else { message("connection to dbCon already made")}
      # 
      # thebb <- get_bb(climate_id_key[,c("long","lat", "el", "pixelid_climate")]) ##get bounding box based on input points
      # #dbCon <- climRdev::data_connect() ##connect to database
      # normal <- normal_input_postgis(dbCon = dbCon, bbox = thebb, cache = TRUE) ##get normal data and lapse rates
      # gcm_ts <- gcm_ts_input(dbCon, bbox = thebb, 
      #                        gcm = (P(sim, "gcm", "climateCastor")), 
      #                        ssp = (P(sim, "ssp", "climateCastor")),# c("ssp370"), 
      #                        years = (P(sim, "climateYears", "climateCastor")),
      #                        max_run = (P(sim, "maxRun", "climateCastor")),
      #                        cache = TRUE)
      # 
      # message("downscale Tmax")
      # results_Tmax <- downscale(
      #   xyz = as.data.frame(climate_id_key[,c("long","lat", "el", "pixelid_climate")]),
      #   normal = normal,
      #   gcm_ts = gcm_ts,
      #   vars = sprintf(c("Tmax%02d"),1:12)
      # )
      # 
      # message("downscale PPT")
      # results_PPT <- downscale(
      #   xyz = as.data.frame(as.data.frame(climate_id_key[,c("long","lat", "el", "pixelid_climate")]),),
      #   normal = normal,
      #   gcm_ts = gcm_ts,
      #   vars = sprintf(c("PPT%02d"),1:12)
      # )
      # 
      # message("downscale Tave")
      # results_Tave <-downscale(
      #   xyz = as.data.frame(as.data.frame(climate_id_key[,c("long","lat", "el", "pixelid_climate")]),),
      #   normal = normal,
      #   gcm_ts = gcm_ts,
      #   vars = sprintf(c("Tave%02d"),1:12)
      # )
      # 
      # message("downscale CMD")
      # results_CMD <-downscale(
      #   xyz = as.data.frame(as.data.frame(climate_id_key[,c("long","lat", "el", "pixelid_climate")]),),
      #   normal = normal,
      #   gcm_ts = gcm_ts,
      #   vars = sprintf(c("CMD%02d"),1:12)
      # )
      # 
      # message("downscale CMI")
      # results_CMI <-downscale(
      #   xyz = as.data.frame(as.data.frame(climate_id_key[,c("long","lat", "el", "pixelid_climate")]),),
      #   normal = normal,
      #   gcm_ts = gcm_ts,
      #   vars = sprintf(c("CMI%02d"),1:12)
      # )
      # 
      message("join downscaled climate data")
      
      # results<-merge(results_Tmax, results_PPT, by.x = c("ID", "GCM", "SSP", "RUN", "PERIOD"), by.y=c("ID", "GCM", "SSP", "RUN", "PERIOD"))
      # results<-merge(results, results_Tave, by.x = c("ID", "GCM", "SSP", "RUN", "PERIOD"), by.y=c("ID", "GCM", "SSP", "RUN", "PERIOD"))
      # results<-merge(results, results_CMD, by.x = c("ID", "GCM", "SSP", "RUN", "PERIOD"), by.y=c("ID", "GCM", "SSP", "RUN", "PERIOD"))
      # 
      # 
      # climate_id_key$ID<-1:length(climate_id_key$pixelid_climate)
      # 
      # climate_dat<-merge(x=climate_id_key, y= results, by.x = c("ID"), by.y = c("ID"), all.y = TRUE) 
      # 
      climate_dat<-climate_dat %>% dplyr::rename(gcm=GCM,
                                          ssp = SSP,
                                          run = RUN,
                                          period = PERIOD)
      
      message("upload climate data to sqlitedb")
      
      climate_dat[,c("ID", "lat", "long", "el"):=NULL]
    
      qry<-paste0("CREATE TABLE IF NOT EXISTS climate_", P(sim, "gcmname", "climateCastor"),"_",P(sim, "ssp", "climateCastor")," (pixelid_climate integer,  gcm character, ssp character, run character, period integer, Tmax01 numeric, Tmax02 numeric, Tmax03 numeric, Tmax04 numeric, Tmax05 numeric,  Tmax06 numeric, Tmax07 numeric, Tmax08 numeric, Tmax09 numeric, Tmax10 numeric, Tmax11 numeric, Tmax12 numeric, PPT01 numeric, PPT02 numeric, PPT03 numeric, PPT04 numeric, PPT05 numeric, PPT06 numeric, PPT07 numeric, PPT08 numeric, PPT09 numeric, PPT10 numeric, PPT11 numeric, PPT12 numeric, Tave01 numeric, Tave02 numeric, Tave03 numeric, Tave04 numeric, Tave05 numeric, Tave06 numeric, Tave07 numeric, Tave08 numeric, Tave09 numeric, Tave10 numeric, Tave11 numeric, Tave12 numeric, CMD01 numeric, CMD02 numeric, CMD03 numeric, CMD04 numeric, CMD05 numeric, CMD06 numeric, CMD07 numeric, CMD08 numeric, CMD09 numeric, CMD10 numeric, CMD11 numeric, CMD12 numeric)")
      
      dbExecute(sim$castordb, qry)
      
      qry<-paste0("INSERT INTO climate_", P(sim, "gcmname", "climateCastor"),"_",P(sim, "ssp", "climateCastor"), " (pixelid_climate,  gcm, ssp, run, period, Tmax01, Tmax02, Tmax03, Tmax04, Tmax05,  Tmax06, Tmax07, Tmax08, Tmax09, Tmax10, Tmax11, Tmax12, PPT01, PPT02, PPT03, PPT04, PPT05, PPT06, PPT07, PPT08, PPT09, PPT10, PPT11, PPT12, Tave01, Tave02, Tave03, Tave04, Tave05, Tave06, Tave07, Tave08, Tave09, Tave10, Tave11, Tave12, CMD01, CMD02, CMD03, CMD04, CMD05, CMD06, CMD07, CMD08, CMD09, CMD10, CMD11, CMD12) VALUES (:pixelid_climate, :gcm, :ssp, :run, :period, :Tmax01, :Tmax02, :Tmax03, :Tmax04, :Tmax05, :Tmax06, :Tmax07, :Tmax08, :Tmax09, :Tmax10, :Tmax11, :Tmax12, :PPT01, :PPT02, :PPT03, :PPT04, :PPT05, :PPT06, :PPT07, :PPT08, :PPT09, :PPT10, :PPT11, :PPT12, :Tave01, :Tave02, :Tave03, :Tave04, :Tave05, :Tave06, :Tave07, :Tave08, :Tave09, :Tave10, :Tave11, :Tave12, :CMD01, :CMD02, :CMD03, :CMD04, :CMD05, :CMD06, :CMD07, :CMD08, :CMD09, :CMD10, :CMD11, :CMD12)")
      
      dbBegin(sim$castordb)
      rs<-dbSendQuery(sim$castordb, qry, climate_dat)
      dbClearResult(rs)
      dbCommit(sim$castordb)
      
      } else {
        message("climate data already extracted")
      }
      
  return(invisible(sim))
}

