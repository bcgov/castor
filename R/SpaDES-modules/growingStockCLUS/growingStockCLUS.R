
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
  name = "growingStockCLUS",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhley", email = "tyler.muhley@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", growingStockCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "growingStockCLUS.Rmd"),
  reqdPkgs = list(),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant"),
    defineParameter("updateInterval", "numeric", 1, NA, NA, "The interval when the growinstock should be updated"),
    defineParameter("growingStockConst", "numeric", 9999, NA, NA, "A percentage of the initial level of growingstock maintaining a minimum amount of growingstock")
  ),
  inputObjects = bind_rows(
    expectsInput(objectName ="scenario", objectClass ="data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName ="clusdb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates clus realted information", sourceURL = NA)
  ),
  outputObjects = bind_rows(
    createsOutput(objectName = "growingStockReport", objectClass = "data.table", desc = NA),
    createsOutput(objectName = "growingStockLevel", objectClass = "numeric", desc = NA)
  )
))

doEvent.growingStockCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "growingStockCLUS", "updateInterval"), "growingStockCLUS", "updateGrowingStock", 1)
    },
    updateGrowingStock= {
      sim <- growingStockCLUS.Update(sim)
      sim <- growingStockCLUS.record(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "growingStockCLUS", "updateInterval"), "growingStockCLUS", "updateGrowingStock", 1)
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  #To do a linear interpolation between yields in SQLite
  #Rise vs run to calc the slope of the secant line between the rounded floor and ceiling values for age and yield i.e., (y1-y2)/(x1-x2)
  #Then multiply by the x value ie., slope*(age - floor.age) + floor.yield
  #This might be more efficient with a large number of yields to interpolate - its slighly slower 1 second -- more efficient with larger data
  
  #Note with any linear interpolation there is a bias for higher yields at younger ages (before cMAI) and lower yields at older ages (past cMAI)
  
  #dat<-data.table(dbGetQuery(sim$clusdb, "SELECT yieldid, age, tvol, height, eca FROM yields where tvol is not null"))
  #tab1<-data.table(dbGetQuery(sim$clusdb, "SELECT pixelid, yieldid, age FROM pixels WHERE age >= 0 and yieldid is not null"))
  #tab1[, vol:= lapply(.SD, function(x) {approx(dat[yieldid == .BY]$age, dat[yieldid == .BY]$tvol,  xout=x, rule = 2)$y}), .SD = "age" , by=yieldid]
  #tab1[, ht:= lapply(.SD, function(x) {approx(dat[yieldid == .BY]$age, dat[yieldid == .BY]$height, xout=x, rule = 2)$y}), .SD = "age" , by=yieldid]

  if(length(dbGetQuery(sim$clusdb, "SELECT variable FROM zoneConstraints WHERE variable = 'eca' LIMIT 1")) > 0){
    #tab1[, eca:= lapply(.SD, function(x) {approx(dat[yieldid == .BY]$age, dat[yieldid == .BY]$eca,  xout=x, rule = 2)$y}), .SD = "age" , by=yieldid]
    
    tab1<-data.table(dbGetQuery(sim$clusdb, "SELECT t.pixelid,
    (((k.tvol - y.tvol*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.tvol as vol,
    (((k.height - y.height*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.height as ht,
    (((k.eca - y.eca*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.height as eca
    FROM pixels t
    LEFT JOIN yields y 
    ON t.yieldid = y.yieldid AND CAST(t.age/10 AS INT)*10 = y.age
    LEFT JOIN yields k 
    ON t.yieldid = k.yieldid AND round(t.age/10+0.5)*10 = k.age WHERE t.age > 0"))
    
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET vol = :vol, height = :ht, eca = :eca where pixelid = :pixelid", tab1[,c("vol", "ht", "eca", "pixelid")])
    dbClearResult(rs)
    dbCommit(sim$clusdb)
  }else{
    
    tab1<-data.table(dbGetQuery(sim$clusdb, "SELECT t.pixelid,
    (((k.tvol - y.tvol*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.tvol as vol,
    (((k.height - y.height*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.height as ht
    FROM pixels t
    LEFT JOIN yields y 
    ON t.yieldid = y.yieldid AND CAST(t.age/10 AS INT)*10 = y.age
    LEFT JOIN yields k 
    ON t.yieldid = k.yieldid AND round(t.age/10+0.5)*10 = k.age WHERE t.age > 0"))
    
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET vol = :vol, height = :ht  where pixelid = :pixelid", tab1[,c("vol", "ht", "pixelid")])
    dbClearResult(rs)
    dbCommit(sim$clusdb)  
    }
  
  sim$growingStockReport<-data.table(scenario = sim$scenario$name, timeperiod = time(sim),  
                                     dbGetQuery(sim$clusdb, 
                                     paste0("SELECT sum(vol) as gs, sum(vol*thlb) as m_gs, sum(vol*thlb*dec_pcnt) as m_dec_gs, compartid as compartment FROM pixels where compartid 
              in('",paste(sim$boundaryInfo[[3]], sep = " ", collapse = "','"),"')
                         group by compartid;")))
                                     
  
  rm(tab1)
  gc()
  return(invisible(sim))
}

growingStockCLUS.Update<- function(sim) {
  #Note: See the SQLite approach to updating. The Update statement does not support JOIN
  #update the yields being tracked
  message("...drop indexs")
  dbExecute(sim$clusdb, "DROP INDEX index_age")
  dbExecute(sim$clusdb, "DROP INDEX index_height")
  
  message("...increment age")
  #Update the pixels table
  dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET age = age + 1 WHERE age >= 0")
  dbClearResult(rs)
  dbCommit(sim$clusdb)
  
  message("...update yields")
  if(length(dbGetQuery(sim$clusdb, "SELECT variable FROM zoneConstraints WHERE variable = 'eca' LIMIT 1")) > 0){
    #tab1[, eca:= lapply(.SD, function(x) {approx(dat[yieldid == .BY]$age, dat[yieldid == .BY]$eca,  xout=x, rule = 2)$y}), .SD = "age" , by=yieldid]
    
    tab1<-data.table(dbGetQuery(sim$clusdb, "SELECT t.pixelid,
    (((k.tvol - y.tvol*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.tvol as vol,
    (((k.height - y.height*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.height as ht,
    (((k.eca - y.eca*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.height as eca
    FROM pixels t
    LEFT JOIN yields y 
    ON t.yieldid = y.yieldid AND CAST(t.age/10 AS INT)*10 = y.age
    LEFT JOIN yields k 
    ON t.yieldid = k.yieldid AND round(t.age/10+0.5)*10 = k.age WHERE t.age > 0"))
    
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET vol = :vol, height = :ht, eca = :eca where pixelid = :pixelid", tab1[,c("vol", "ht", "eca", "pixelid")])
    dbClearResult(rs)
    dbCommit(sim$clusdb)
  }else{
    
    tab1<-data.table(dbGetQuery(sim$clusdb, "SELECT t.pixelid,
    (((k.tvol - y.tvol*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.tvol as vol,
    (((k.height - y.height*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.height as ht
    FROM pixels t
    LEFT JOIN yields y 
    ON t.yieldid = y.yieldid AND CAST(t.age/10 AS INT)*10 = y.age
    LEFT JOIN yields k 
    ON t.yieldid = k.yieldid AND round(t.age/10+0.5)*10 = k.age WHERE t.age > 0"))
    
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET vol = :vol, height = :ht  where pixelid = :pixelid", tab1[,c("vol", "ht", "pixelid")])
    dbClearResult(rs)
    dbCommit(sim$clusdb)  
  }
  
  message("...create indexes")
  
  dbExecute(sim$clusdb, "CREATE INDEX index_age on pixels (age)")
  dbExecute(sim$clusdb, "CREATE INDEX index_height on pixels (height)")
  
  #Vacuum the db
  message("...vacuum db")
  dbExecute(sim$clusdb, "VACUUM;")
  
  rm(tab1)
  gc()
  return(invisible(sim))
}

growingStockCLUS.record<- function(sim) {
  message("...recording")
  sim$growingStockReport<- rbindlist(list(sim$growingStockReport, data.table(scenario = sim$scenario$name, timeperiod = time(sim),  
              dbGetQuery(sim$clusdb, paste0("SELECT sum(vol) as gs, sum(vol*thlb) as m_gs, sum(vol*thlb*dec_pcnt) as m_dec_gs, compartid as compartment FROM pixels where compartid 
              in('",paste(sim$boundaryInfo[[3]], sep = " ", collapse = "','"),"')
                         group by compartid;")))), use.names = TRUE)
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  return(invisible(sim))
}

