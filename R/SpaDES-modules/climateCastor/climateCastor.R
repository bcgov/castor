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
  description = "This module gets the climate data from climR for any area within the province",
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
      sim <- getClimateDataForAOI(sim)
      sim <- getClimateDataForProvince(sim)
    },
    
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}
    
getClimateDataForAOI <- function(sim) {
  qry<-paste0("SELECT COUNT(*) as exists_check FROM pragma_table_info ('climate_", tolower(P(sim, "gcmname", "climateCastor")),"_",P(sim, "ssp", "climateCastor"),"') WHERE name='pixelid_climate';")
      
     # qry<-paste0("SELECT COUNT (*) as exists_check FROM sqlite_master WHERE type='table' AND name='climate_", tolower(P(sim, "gcmname", "climateCastor")),"_",P(sim, "ssp", "climateCastor"),"';")
      
      if(dbGetQuery(sim$castordb, qry)$exists_check==0) {
     
      message("extract climate_id values from raster")
      
      #We need elevation because climate BC adjusts the climate according to the elevation of the sampling location. 
      ## get climate_idno raster and extract climate_id values ##
      climate_id_rast<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                                srcRaster= P(sim, "nameClimateIdnoRast", "climateCastor"), 
                                                clipper=sim$boundaryInfo[1] , 
                                                geom= sim$boundaryInfo[4] , 
                                                where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                conn= sim$dbCreds))
      
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
      climate_id_key<-data.table(getTableQuery(paste0("SELECT pixelid_climate, lat, long, el  FROM ",P(sim, "nameClimateTable","climateCastor"), " WHERE pixelid_climate IN (", paste(climate_id_key, collapse = ","),");"), conn = sim$dbCreds))
      
      setnames(climate_id_key, c("id", "lat", "lon", "elev"))
      climate_id_key<-climate_id_key[,c("id", "lon", "lat", "elev")]
      
      climate_id_key<-as.data.frame(climate_id_key)
      
      message("Downloading climate data from climateBC for AOI ...")  
      
      if (P(sim, "climateData", "climateCastor")== "observed") {
        
        message("extracting observed climate data")
        
        ds_out <- downscale(
          xyz = climate_id_key,
          which_refmap = "auto",
          obs_years = (P(sim, "climateYears", "climateCastor")),
          obs_ts_dataset = "climatena",
          vars = (P(sim, "vars_aoi", "climateCastor")))
        
        ds_out$GCM<-"climatena"
        ds_out$SSP<-"none"
        ds_out$RUN<-"none"
        ds_out<-data.table(ds_out)
        ds_out[,DATASET:=NULL]
        
      } else {
        
        message("extracting gcm data")
      
      ds_out <- downscale(
        xyz = climate_id_key,
        which_refmap = "auto",
        gcm_ssp_years = (P(sim, "climateYears", "climateCastor")),
        gcms = (P(sim, "gcm", "climateCastor")),
        ssps = (P(sim, "ssp", "climateCastor")),# c("ssp370"),
        max_run = (P(sim, "maxRun", "climateCastor")),
        vars = (P(sim, "vars_aoi", "climateCastor"))) # also need annual CMI (I think) for ignitions
      }
      
      ds_out<-ds_out[!is.na(RUN),]
      ds_out<-ds_out[order(GCM, SSP, RUN, id, PERIOD)]
      ds_out<-ds_out[, `:=`(CMI = rowMeans(.SD, na.rm=T)), .SDcols=c("CMI_05", "CMI_06","CMI_07","CMI_08")]
      ds_out[ ,CMI3yr := frollsum(.SD, n=3), by = "id", .SDcols = "CMI"]

      
      ### UPDATE THIS ###
      #ds_out<-ds_out[!PERIOD %in% c(2021, 2022), ]
      
      message("upload climate data to sqlitedb")
      
      qry<-paste0("CREATE TABLE IF NOT EXISTS climate_", tolower(P(sim, "gcmname", "climateCastor")),"_",P(sim, "ssp", "climateCastor")," (pixelid_climate integer, gcm character, ssp character, run character, period integer, ", paste(tolower(P(sim,"vars_aoi", "climateCastor")),sep="' '", collapse=" numeric, "), " numeric,", " cmi numeric, cmi3yr numeric)")
      
      dbExecute(sim$castordb, qry)
      
      qry<-paste0("INSERT INTO climate_", tolower(P(sim, "gcmname", "climateCastor")),"_",P(sim, "ssp", "climateCastor"), " (pixelid_climate,  gcm, ssp, run, period, ", paste(tolower(P(sim,"vars_aoi", "climateCastor")),sep="' '", collapse=", "),", cmi, cmi3yr) VALUES (:id, :GCM, :SSP, :RUN, :PERIOD, :", paste( P(sim,"vars_aoi", "climateCastor"),sep="' '", collapse=", :"),", :CMI, :CMI3yr)")

      dbBegin(sim$castordb)
      rs<-dbSendQuery(sim$castordb, qry, ds_out)
      dbClearResult(rs)
      dbCommit(sim$castordb)
      
      } else {
        message("climate data already extracted")
      }
  return(invisible(sim))
}

 getClimateDataForProvince <- function(sim) {
  # qry<-paste0("SELECT COUNT(*) as exists_check FROM sqlite_master WHERE type='table' AND name='climate_provincial_", P(sim, "gcmname", "climateCastor"),"_",P(sim, "ssp", "climateCastor"), "';")
   
  #if(dbGetQuery(sim$castordb, qry)$exists_check==0) {
     
     message(paste0("extract climate_provincial_",tolower(P(sim, "gcmname", "climateCastor")),"_",P(sim, "ssp", "climateCastor")))
    
    qry<-paste0("CREATE TABLE IF NOT EXISTS climate_provincial_", tolower(P(sim, "gcmname", "climateCastor")),"_",P(sim, "ssp", "climateCastor")," (gcm character, ssp character, run character, period integer, ave_cmi numeric)")
    
    dbExecute(sim$castordb, qry)
    
    
 #   if (length(getTableQuery(paste0("SELECT * FROM ",P(sim, "nameProvCMITable","climateCastor"), " WHERE gcm = '",P(sim, "gcmname","climateCastor"), "' AND ssp = '", P(sim, "ssp","climateCastor"), "' limit 2"))$gcm)>0) {
    
    prov_cmi<-data.table(getTableQuery(paste0("SELECT * FROM ",P(sim, "nameProvCMITable","climateCastor"), " WHERE gcm = '",P(sim, "gcmname","climateCastor"), "' AND ssp = '", P(sim, "ssp","climateCastor"),"' AND period IN (", paste(P(sim, "climateYears","climateCastor"), collapse = ","),");" ), conn = sim$dbCreds))
    
    qry<-paste0("INSERT INTO climate_provincial_", tolower(P(sim, "gcmname", "climateCastor")),"_",P(sim, "ssp", "climateCastor"), " (gcm, ssp, run, period, ave_cmi) VALUES (:gcm,:ssp,:run, :period, :ave_cmi)")
    
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, qry, prov_cmi)
    dbClearResult(rs)
    dbCommit(sim$castordb)
    
    
    
    # in the case where castor database on Kyles computer does not have the required data go and get it manually from climR.
    # Note this is slow so should be avoided.
    #} else {

    #message("extract climate_id values from raster")
# 
#   location_table<-getSpatialQuery(paste0("SELECT * FROM ", P(sim, "nameClimateTable","climateCastor"),";"))
#   setnames(location_table, c("lon", "lat", "id", "elev"))
#   location_table<-location_table[,c("id", "lon", "lat", "elev")]
# 
#   #get climate data for locations on land i.e. that have an elevation
#   location_table<-data.table(location_table)
#   location_table<-location_table[elev!="NA",]
# 
#   # when i try to get climr data it crashes because there are to many locations so Ill split the file up into multiple sections
#   x<-round(length(location_table$id)/15,0)
# 
#   x1<-location_table[1:x,]
#   x2<-location_table[(x+1):(x*2),]
#   x3<-location_table[(x*2+1):(x*3),]
#   x4<-location_table[(x*3+1):(x*4),]
#   x5<-location_table[(x*4+1):(x*5),]
#   x6<-location_table[(x*5+1):(x*6),]
#   x7<-location_table[(x*6+1):(x*7),]
#   x8<-location_table[(x*7+1):(x*8),]
#   x9<-location_table[(x*8+1):(x*9),]
#   x10<-location_table[(x*9+1):(x*10),]
#   x11<-location_table[(x*10+1):(x*11),]
#   x12<-location_table[(x*11+1):(x*12),]
#   x13<-location_table[(x*12+1):(x*13),]
#   x14<-location_table[(x*13+1):(x*14),]
#   x15<-location_table[(x*14+1):(length(location_table$id)),]
# 
#   rm(location_table)
#   gc()
# 
#   message("Downloading provincial CMI from climateBC")
# 
#   inputs <- list(x1, x2, x3, x4, x5, x6,x7,x8, x9, x10, x11, x12, x13, x14, x15)
#   ds_out<-list()
# 
#   for (i in 1:length(inputs)){
#     print(i)
# 
#     ds_out_prov <- climr_downscale(
#       xyz = inputs[[i]],
#       which_normal = "auto",
#       historic_period = (P(sim, "historicPeriod", "climateCastor")),#"2001_2020",
#       gcm_ts_years = (P(sim, "climateYears", "climateCastor")),#2020: 2030,
#       gcm_models = (P(sim, "gcm", "climateCastor")), #"MPI-ESM1-2-HR",
#       ssp = (P(sim, "ssp", "climateCastor")),# c("ssp370"),
#       max_run = (P(sim, "maxRun", "climateCastor")),
#       return_normal = FALSE, ## to return the 1961-1990 normals period
#       vars = P(sim,"vars_prov", "climateCastor"))
# 
#     setnames(ds_out_prov, old = "id", new="pixelid_climate")
#     ds_out_prov[,rowmeanCMI:=(CMI05+CMI06+CMI07+CMI08)/4]
#     ds_out_prov[, c("GCM", "SSP","CMI05", "CMI06", "CMI07", "CMI08"):=NULL]
#     ds_out_prov<-ds_out_prov[!is.na(RUN), ]
#     ds_out<-rbind(ds_out, ds_out_prov)
# 
#     rm(ds_out_prov)
#     gc()
#   }
# 
#   ds_out<-ds_out[!is.na(rowmeanCMI)]
#   ds_out[, ave_cmi:=mean(rowmeanCMI), by=c("RUN", "PERIOD")]
#   prov_cmi<-unique(ds_out, by="ave_cmi")
#   prov_cmi[, c("pixelid_climate", "rowmeanCMI"):=NULL]
#     
#     
#   qry<-paste0("INSERT INTO climate_provincial_", tolower(P(sim, "gcmname", "climateCastor")),"_",P(sim, "ssp", "climateCastor"), " (gcm, ssp, run, period, ave_cmi) VALUES (:GCM,:SSP,:RUN, :PERIOD, :ave_cmi)")
# 
#   dbBegin(sim$castordb)
#   rs<-dbSendQuery(sim$castordb, qry, prov_cmi)
#   dbClearResult(rs)
#   dbCommit(sim$castordb)
# 
#   rm(ds_out, x1, x2, x3, x4, x5, x6, x7, x8,x9, x10, x11, x12, x13, x14, x15, inputs)
#   gc()
#     }
#     
#   } else {message ("provincial climate data extracted ")}
  return(invisible(sim))
}

