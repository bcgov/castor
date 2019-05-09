
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
      sim <- scheduleEvent(sim, time(sim) + P(sim, "growingStockCLUS", "updateInterval"), "growingStockCLUS", "updateGrowingStock")

    },
    updateGrowingStock= {
      sim <- growingStockCLUS.Update(sim)
      sim <- growingStockCLUS.record(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "growingStockCLUS", "updateInterval"), "growingStockCLUS", "updateGrowingStock")
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  dat<-dbGetQuery(sim$clusdb, "SELECT yieldid, age, tvol FROM yields")
  tab1<-dbGetQuery(sim$clusdb, "SELECT pixelid, yieldid, age FROM pixels")
  
  tab1[, vol:= lapply(.SD, function(x) approx(dat[yieldid == .BY]$age, 
                                              dat[yieldid == .BY]$tvol, 
                                              xout=x)$y), .SDcols="ages", by=yieldid]
  dbBegin(sim$clusdb)
  rs<-dbSendQuery(sim$clusdb, paste0("UPDATE pixels SET vol = :vol where pixelid = :pixelid", tab1))
  dbClearResult(rs)
  dbCommit(sim$clusdb)
  
  sim$growingStockReport<-list()
  
  return(invisible(sim))
}
growingStockCLUS.Update<- function(sim) {
  #update the age first
  dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, paste0("UPDATE pixels SET age = age +", P(sim, "growingStockCLUS", "updateInterval"),"  WHERE age >= 0"))
  dbClearResult(rs)
  dbCommit(sim$clusdb)
  
  #update the yields being tracked
  dat<-dbGetQuery(sim$clusdb, "SELECT yieldid, age, vol FROM yields")
  tab1<-dbGetQuery(sim$clusdb, "SELECT pixelid, yieldid, age FROM pixels")
  
  tab1[, vol:= lapply(.SD, function(x) approx(dat[yieldid == .BY]$age, 
                                                dat[yieldid == .BY]$vol, 
                                                xout=x)$y), .SDcols="ages", by=yieldid]
  
  dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, paste0("UPDATE pixels SET volume = :vol where pixelid = :pixelid", tab1))
  dbClearResult(rs)
  dbCommit(sim$clusdb)
  
  return(invisible(sim))
}
growingStockCLUS.record<- function(sim) {
  
  sim$growingStockReport<- NULL
    
  return(invisible(sim))
}
.inputObjects <- function(sim) {
  return(invisible(sim))
}

