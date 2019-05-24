
# Copyright 2018 Province of British Columbia
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
    defineParameter("updateInterval", "numeric", 1, NA, NA, "")
  ),
  inputObjects = bind_rows(
    expectsInput(objectName ="clusdb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates clus realted information", sourceURL = NA)
  ),
  outputObjects = bind_rows(
    createsOutput(objectName = "growingStockReport", objectClass = "data.table", desc = NA)
  )
))


doEvent.growingStockCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "growingStockCLUS", "updateInterval"), "growingStockCLUS", "updateGrowingStock", 9)

    },
    updateGrowingStock= {
      sim <- growingStockCLUS.Update(sim)
      sim <- growingStockCLUS.record(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "growingStockCLUS", "updateInterval"), "growingStockCLUS", "updateGrowingStock", 9)
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
  #This might be more efficient with a large number of yields to interpolate - its slighly slower 1 second
  #Maybe very large AOI it will be more efficient???
  
  #dbGetQuery(clusdb, "SELECT t.pixelid,
  #(((k.tvol - y.tvol*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.tvol as itvol,
  #(((k.height - y.height*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.height as iht
  #FROM pixels t
  #LEFT JOIN yields y 
  #ON t.yieldid = y.yieldid AND CAST(t.age/10 AS INT)*10 = y.age
  #LEFT JOIN yields k 
  #ON t.yieldid = k.yieldid AND round(t.age/10+0.5)*10 = k.age WHERE t.age > 0")

  #Note with any linear interpolation there is a bias for higher yields at younger ages (before cMAI) and lower yields at older ages (past cMAI)
  dat<-data.table(dbGetQuery(sim$clusdb, "SELECT yieldid, age, tvol, height FROM yields"))
  tab1<-data.table(dbGetQuery(sim$clusdb, "SELECT pixelid, yieldid, age FROM pixels WHERE age >= 0"))
  tab1[, vol:= lapply(.SD, function(x) {approx(dat[yieldid == .BY]$age, 
                                                           dat[yieldid == .BY]$tvol, 
                                                           xout=x, rule = 2)$y}), .SD = "age" , by=yieldid]
  tab1[, ht:= lapply(.SD, function(x) {approx(dat[yieldid == .BY]$age, 
                                              dat[yieldid == .BY]$height, 
                                              xout=x, rule = 2)$y}), .SD = "age" , by=yieldid]
  dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET vol = :vol, height = :ht where pixelid = :pixelid", tab1[,c("vol", "ht", "pixelid")])
  dbClearResult(rs)
  dbCommit(sim$clusdb)
  
  sim$growingStockReport<-list(dbGetQuery(sim$clusdb, "SELECT sum(vol) FROM pixels"))
  
  rm(tab1,dat)
  gc()
  return(invisible(sim))
}
growingStockCLUS.Update<- function(sim) {
  #Note: See the SQLiteapproach to updating. The Update statement does not support JOIN
  #update the age first
  print(paste0("update at ", time(sim)))
  dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, paste0("UPDATE pixels SET age = age +", P(sim, "growingStockCLUS", "updateInterval"),"  WHERE age >= 0"))
  dbClearResult(rs)
  dbCommit(sim$clusdb)
  
  dbExecute(sim$clusdb, "VACUUM;")
  #update the yields being tracked
  dat<-data.table(dbGetQuery(sim$clusdb, "SELECT yieldid, age, tvol FROM yields"))
  tab1<-data.table(dbGetQuery(sim$clusdb, "SELECT pixelid, yieldid, age FROM pixels WHERE age >= 0"))
  tab1[, vol:= lapply(.SD, function(x) {approx(dat[yieldid == .BY]$age, 
                                               dat[yieldid == .BY]$tvol, 
                                               xout=x, rule = 2)$y}), .SD = "age" , by=yieldid]
  tab1[, ht:= lapply(.SD, function(x) {approx(dat[yieldid == .BY]$age, 
                                              dat[yieldid == .BY]$height, 
                                              xout=x, rule = 2)$y}), .SD = "age" , by=yieldid]
  dbBegin(sim$clusdb)
  rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET vol = :vol, height = :ht where pixelid = :pixelid", tab1[,c("vol", "ht", "pixelid")])
  dbClearResult(rs)
  dbCommit(sim$clusdb)
  
  #Vacuum the db
  dbExecute(sim$clusdb, "VACUUM;")
  
  rm(tab1,dat)
  gc()
  return(invisible(sim))
}
growingStockCLUS.record<- function(sim) {
  sim$growingStockReport[time(sim)+P(sim, "growingStockCLUS", "updateInterval")]<- dbGetQuery(sim$clusdb, "SELECT sum(vol) FROM pixels")
  return(invisible(sim))
}
.inputObjects <- function(sim) {
  return(invisible(sim))
}

