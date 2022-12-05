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
  name = "dbCreatorCastor",
  description = "",
  keywords = "",
  authors =  c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
               person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(dbCreatorCastor = "0.0.0.9000"),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.md", "dbCreatorCastor.Rmd"), ## same file
  reqdPkgs = list("SpaDES.core (>=1.0.10)", "ggplot2", "terra", "RandomFields (>=3.0.61)"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter(".plots", "character", "screen", NA, NA,"Used by Plots function, which can be optionally used here"),
    defineParameter(".plotInitialTime", "numeric", start(sim), NA, NA,"Describes the simulation time at which the first plot event should occur."),
    defineParameter(".plotInterval", "numeric", NA, NA, NA,"Describes the simulation time interval between plot events."),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "Describes the simulation time at which the first save event should occur."),
    defineParameter(".saveInterval", "numeric", NA, NA, NA,"This describes the simulation time interval between save events."),
    defineParameter(".seed", "list", list(), NA, NA,"Named list of seeds to use for each event (names)."),
    defineParameter(".useCache", "logical", FALSE, NA, NA,"Should caching of events or module be used?"),
    defineParameter("sqlite_dbname", "character", "test", NA, NA,"name of the castordb"),
    defineParameter("clusterLevel", "numeric", 1, 0.001, 1.999,"This describes the alpha parameter in RandomFields. alpha is [0,2]")
  ),
  inputObjects = bindrows(
    #expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput(objectName = "extent", objectClass = "list", desc = "The exent in a list ordered by: nrows, ncols, xmin, xmax, ymin, ymax", sourceURL = NA),
    expectsInput(objectName = "zoneConstraint", objectClass = "data.table", desc = "The constraint to be applied", sourceURL = NA)
  ),
  outputObjects = bindrows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput("castordb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates realted information"),
    createsOutput("ras", objectClass ="RasterLayer", desc = "Raster Layer of the cell index"),
    createsOutput(objectName = "pts", objectClass = "data.table", desc = "A data.table of X,Y locations - used to find distances"),
    createsOutput(objectName = "foreststate", objectClass = "data.table", desc = "A data.table of the current state of the aoi")
  )
))

doEvent.dbCreatorCastor = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = { # initialization event
      
      # function (below) that creates an SQLite database
      sim <- createCastorDB(sim) 
      
      #populate clusdb tables
      sim <- setTablesCastorDB(sim)
      sim <- setZoneConstraints(sim)
      sim <- setIndexesCastorDB(sim) # creates index to facilitate db querying?
      sim <- updateGS(sim) # update the forest attributes
      sim <- scheduleEvent(sim, eventTime = end(sim),  "dbCreatorCastor", "removeCastorDB", eventPriority=99) #disconnect the db once the sim is over
    },
    removeCastorDB={
      sim <- disconnectCastorDB(sim)
    },
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
                  "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'", sep = ""))
  )
  return(invisible(sim))
}

createCastorDB <- function(sim) {
  message ('create castordb')
  #build the clusdb - a realtional database that tracks the interactions between spatial and temporal objectives
  sim$castordb <- dbConnect(RSQLite::SQLite(), ":memory:") #builds the db in memory; also resets any existing db! Can be set to store on disk
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS yields ( id integer PRIMARY KEY, yieldid integer, age integer, tvol numeric, dec_pcnt numeric, height numeric, qmd numeric default 0.0, basalarea numeric default 0.0, crownclosure numeric default 0.0, eca numeric);")
  
  #Note Zone table is created as a JOIN with zoneConstraints and zone
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS raster_info (name text, xmin numeric, xmax numeric, ymin numeric, ymax numeric, ncell integer, nrow integer, crs text);")
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS zone (zone_column text, reference_zone text)")
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS zoneConstraints ( id integer PRIMARY KEY, zoneid integer, reference_zone text, zone_column text, ndt integer, variable text, threshold numeric, type text, percentage numeric, denom text, multi_condition text, t_area numeric, start integer, stop integer);")
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS pixels ( pixelid integer PRIMARY KEY, compartid character, 
own integer, yieldid integer, yieldid_trans integer, zone_const integer DEFAULT 0, treed integer, thlb numeric , elv numeric DEFAULT 0, age numeric, vol numeric, dist numeric DEFAULT 0,
crownclosure numeric, height numeric, basalarea numeric, qmd numeric, siteindex numeric, dec_pcnt numeric, eca numeric, salvage_vol numeric default 0);")
  
  return(invisible(sim))
}

setTablesCastorDB <- function(sim) {
  message('...setting data tables')
  randomRas<-randomRaster(sim$extent, P(sim, 'clusterLevel', 'dbCreatorCastor'))
  
  sim$pts <- data.table(xyFromCell(randomRas,1:length(randomRas))) #Seems to be faster than rasterTopoints
  sim$pts <- sim$pts[, pixelid:= seq_len(.N)] # add in the pixelid which streams data in according to the cell number = pixelid
  
  pixels <- data.table(age = as.integer(round(randomRas[]*200,0)))
  pixels[, pixelid := seq_len(.N)]

  #Add the raster_info
  ras.extent<-terra::ext(randomRas)
  sim$ras<-terra::rast(nrows = sim$extent[[1]], ncols = sim$extent[[2]], xmin = sim$extent[[3]], xmax = sim$extent[[4]], ymin = sim$extent[[5]], ymax = sim$extent[[6]], vals = 0 )
  sim$ras[]<-pixels$pixelid
  
  dbExecute(sim$castordb, glue::glue("INSERT INTO raster_info (name, xmin, xmax, ymin, ymax, ncell, nrow, crs) values ('ras', {ras.extent[1]}, {ras.extent[2]}, {ras.extent[3]}, {ras.extent[4]}, {ncell(sim$ras)}, {nrow(sim$ras)}, '3005');"))

  #compartid, ownership, zones
  pixels<-pixels[, compartid := 'all'][, own := 1][, zone1:= 1][, thlb := 1][, yieldid := 1][, yieldid_trans := 1][, treed:= 1][,height:=NA][,crownclosure:= NA][,basalarea:=NA][,qmd:=NA][, siteindex := 25]

  #zones
  sim$zone.length<-1
  dbExecute(sim$castordb, "ALTER TABLE pixels ADD COLUMN zone1 integer;")
  dbExecute(sim$castordb, "INSERT INTO zone (zone_column, reference_zone) values ( 'zone1', 'default');" )
  
  #Set the yields table with a dummy yield curve: "ycid", "age", "tvol", "dec_pcnt", "height", "eca", "basalarea", "qmd", "crownclosure"
  yields<-data.table(yieldid= 1, 
                     age= seq(from =0, to=250, by = 10), 
                     tvol = c(0, 0, 0, 24.2, 98.6, 192.9, 292.4, 382.1, 482.8, 574.5, 648, 706.6, 771.6, 833.7, 885.8, 924.2, 956.2, 982.6, 1004.2, 1023.1, 1038.7, 1051.1, 1060.5, 1067.6, 1072.5, 1075.6 ), 
                     dec_pcnt = NA, 
                     height = c(0, 2.7, 7.1, 11.4, 15.4, 18.9, 22, 24.7, 27.1, 29.2, 31, 32.5, 33.9, 35, 36, 36.9, 37.7, 38.3, 38.9, 39.3, 39.7, 40.1, 40.4, 40.6, 40.8, 41), 
                     eca = c(1, 1, 0.25, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1),
                     basalarea = c(0, 0, 1.3, 8.1, 18.6, 28.6, 37.7, 45.1, 52.7, 58.9, 63.7, 67.4, 71.1, 74.6, 77.4, 79.3, 80.8, 82.1, 83.1, 83.9, 84.5, 84.9, 85.2, 85.3, 85.4, 85.4),
                     qmd = c(0, 0.5, 5.7, 14.1, 21.5, 26.8, 30.9, 34, 36.8, 39, 40.7, 42.1, 43.4, 44.7, 45.8, 46.5, 47.2, 47.8, 48.3, 48.7, 49.1, 49.4, 49.7, 49.9, 50.1, 50.3),
                     crownclosure = c(0, 2.8, 25.6, 64.7, 79.6, 82.5, 82.5, 82, 81.6, 81.2, 80.8, 80.3, 79.9, 79.5, 79.1, 78.6, 78.2, 77.8, 77.4, 76.9, 76.5, 76.1, 75.7, 75.2, 74.8, 74.4)
                     )
  dbBegin(sim$castordb)
  rs<-dbSendQuery(sim$castordb, "INSERT INTO yields (yieldid, age, tvol, dec_pcnt, height, eca, basalarea, qmd, crownclosure ) 
                      values (:yieldid, :age, :tvol, :dec_pcnt, :height, :eca, :basalarea, :qmd, :crownclosure)", yields)
  dbClearResult(rs)
  dbCommit(sim$castordb)
  
  #-----------------------------#
  #Load the pixels in RSQLite----
  #-----------------------------#
  qry<-paste0('INSERT INTO pixels (pixelid, compartid, yieldid, yieldid_trans, own, thlb, treed, age, crownclosure, height, siteindex, basalarea, qmd, dec_pcnt, zone1) 
               values (:pixelid, :compartid, :yieldid, :yieldid_trans, :own,  :thlb, :treed, :age, :crownclosure, :height, :siteindex, :basalarea, :qmd, 0, :zone1)')
  #pixels table
  dbBegin(sim$castordb)
  rs<-dbSendQuery(sim$castordb, qry, pixels )
  dbClearResult(rs)
  dbCommit(sim$castordb)
  
  rm(pixels)
  gc()
  
  return(invisible(sim))
}

setZoneConstraints<-function(sim){
  message("... setting ZoneConstraints table")
  zones <- data.table(zoneid =1, zone_column = 'zone1', reference_zone = 'default', ndt =3, variable = sim$zoneConstraint$variable, threshold = sim$zoneConstraint$threshold, type = sim$zoneConstraint$type, percentage = sim$zoneConstraint$percentage,
                      multi_condition = NA, t_area = sim$extent[[1]]*sim$extent[[2]], denom = NA, start = 0, stop = 250)
  
  dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, "INSERT INTO zoneConstraints (zoneid, reference_zone, zone_column, ndt, variable, threshold, type ,percentage, multi_condition, t_area, start, stop) 
                      values (:zoneid, :reference_zone, :zone_column, :ndt, :variable, :threshold, :type, :percentage, :multi_condition, :t_area, :start, :stop);", zones[,c('zoneid', 'zone_column', 'reference_zone', 'ndt','variable', 'threshold', 'type', 'percentage', 'multi_condition', 't_area', 'start', 'stop')])
  dbClearResult(rs)
  dbCommit(sim$castordb)
  
  return(invisible(sim))
}

setIndexesCastorDB <- function(sim) { # making indexes helps with query speed for future querying
  dbExecute(sim$castordb, "CREATE UNIQUE INDEX index_pixelid on pixels (pixelid);")
  dbExecute(sim$castordb, "CREATE INDEX index_age on pixels (age);")
  dbExecute(sim$castordb, "VACUUM;")
  message('...done')
  return(invisible(sim))
}

updateGS<- function(sim) {
  #Note: See the SQLite approach to updating. The Update statement does not support JOIN
  #update the yields being tracked
  message("...update yields")
  
  tab1<-data.table(dbGetQuery(sim$castordb, "WITH t as (select pixelid, yieldid, age, height, crownclosure, dec_pcnt, basalarea, qmd, eca, vol from pixels where age > 0 and age <= 350) 
SELECT pixelid,
case when k.tvol is null then t.vol else (((k.tvol - y.tvol*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.tvol end as vol,
case when k.height is null then t.height else (((k.height - y.height*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.height end as ht,
case when k.eca is null then t.eca else (((k.eca - y.eca*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.eca end as eca,
case when k.dec_pcnt is null then t.dec_pcnt else (((k.dec_pcnt - y.dec_pcnt*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.dec_pcnt end as dec_pcnt,
case when k.crownclosure is null then t.crownclosure else (((k.crownclosure - y.crownclosure*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.crownclosure end as crownclosure,
case when k.basalarea is null then t.basalarea else (((k.basalarea - y.basalarea*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.basalarea end as basalarea,
case when k.qmd is null then t.qmd else (((k.qmd - y.qmd*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.qmd end as qmd
FROM t
LEFT JOIN yields y 
ON t.yieldid = y.yieldid AND CAST(t.age/10 AS INT)*10 = y.age
LEFT JOIN yields k 
ON t.yieldid = k.yieldid AND round(t.age/10+0.5)*10 = k.age;"))
    
  dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, "UPDATE pixels SET vol = :vol, height = :ht, eca = :eca, dec_pcnt = :dec_pcnt, crownclosure = :crownclosure, qmd = :qmd, basalarea= :basalarea where pixelid = :pixelid;", tab1[,c("vol", "ht", "eca", "pixelid", "dec_pcnt", "crownclosure", "qmd", "basalarea")])
  dbClearResult(rs)
  dbCommit(sim$castordb)
 
  message("...create indexes")
  dbExecute(sim$castordb, "CREATE INDEX index_height on pixels (height);")
  rm(tab1)
  gc()
  return(invisible(sim))
}

disconnectCastorDB<- function(sim) {
    message('Saving castordb')
    con<-dbConnect(RSQLite::SQLite(), paste0(getPaths()$outputPath, "/", P(sim, 'sqlite_dbname', 'dbCreatorCastor'), "_castorDB.sqlite"))
    RSQLite::sqliteCopyDatabase(sim$castordb, con)
    dbDisconnect(sim$castordb)
    dbDisconnect(con)
  return(invisible(sim))
}

randomRaster<-function(extent, clusterLevel){
  ras <- terra::rast(nrows = extent[[1]], ncols = extent[[2]], xmin = extent[[3]], xmax = extent[[4]], ymin = extent[[5]], ymax = extent[[6]], vals = 0 )
  model <- RandomFields::RMstable(scale = 300, var = 0.003,  alpha = clusterLevel)
  data.rv<-RandomFields::RFsimulate(model, y = 1:extent[[1]],  x = 1:extent[[2]], grid = TRUE)$variable1
  data.rv<-(data.rv - min(data.rv))/(max(data.rv)- min(data.rv))
  return(terra::setValues(ras, data.rv))
}

.inputObjects <- function(sim) {
  if (!suppliedElsewhere('extent', sim)) {
     sim$extent <- list(10,10, 0,10,0,10)
  }
  if (!suppliedElsewhere('zoneConstraint', sim)) {
    sim$zoneConstraint <- data.table(variable = "age", type = "ge", threshold = 140, percentage = 20)
  }
  
  
  #cacheTags <- c(currentModule(sim), "function:.inputObjects") ## uncomment this if Cache is being used
  dPath <- asPath(getOption("reproducible.destinationPath", dataPath(sim)), 1)
  message(currentModule(sim), ": using dataPath '", dPath, "'.")

  return(invisible(sim))
}

