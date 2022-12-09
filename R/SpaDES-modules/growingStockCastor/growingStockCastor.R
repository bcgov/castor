
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

defineModule(sim, list(
  name = "growingStockCastor",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", growingStockCastor = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "growingStockCastor.Rmd"),
  reqdPkgs = list(),
  parameters = rbind(
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant"),
    defineParameter("periodLength", "integer", 5, NA, NA, "The length of the time period. Ex, 1 year, 5 year"),
    defineParameter("vacuumInterval", "integer", 5, NA, NA, "The interval when the database should be vacuumed"),
    defineParameter("growingStockConst", "numeric", 9999, NA, NA, "A percentage of the initial level of growingstock maintaining a minimum amount of growingstock")
  ),
  inputObjects = bind_rows(
    expectsInput(objectName = "castordb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates castor realted information", sourceURL = NA),
    expectsInput(objectName = "scenario", objectClass ="data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName = "boundaryInfo", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "extent", objectClass ="list", desc = NA, sourceURL = NA)
  ),
  outputObjects = bind_rows(
    createsOutput(objectName = "growingStockReport", objectClass = "data.table", desc = NA),
    createsOutput(objectName = "growingStockLevel", objectClass = "numeric", desc = NA),
    createsOutput(objectName = "updateInterval", objectClass = "numeric", desc = NA)
  )
))

doEvent.growingStockCastor = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim$updateInterval<-max(1, round(P(sim, "periodLength", "growingStockCastor")/2, 0)) #take the mid point -- less biased
      sim <- initGSCastor(sim)
      sim <- scheduleEvent(sim, time(sim) + 1, "growingStockCastor", "updateGrowingStock", 1)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "vacuumInterval", "growingStockCastor"), "growingStockCastor", "vacuumDB", 2)
    },
    updateGrowingStock= {
      sim <- updateGS(sim)
      sim$updateInterval<-P(sim, "periodLength", "growingStockCastor")
      sim <- recordGS(sim)
      sim <- scheduleEvent(sim, time(sim) + 1, "growingStockCastor", "updateGrowingStock", 1)
    },
    vacuumDB ={
      sim <- vacuumDB(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "vacuumInterval", "growingStockCastor"), "growingStockCastor", "vacuumDB", 2)
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

initGSCastor <- function(sim) {
  #Linear interpolation between yields in SQLite. Note with any linear interpolation there is a bias for higher yields at younger ages (before cMAI) and lower yields at older ages (past cMAI)
  #Rise vs run to calc the slope of the secant line between the rounded floor and ceiling values for age and yield i.e., (y1-y2)/(x1-x2)
  #Then multiply by the x value ie., slope*(age - floor.age) + floor.yield
  
  #This might be more efficient with a large number of yields to interpolate - its slighly slower 1 second -- more efficient with larger data
  #dat<-data.table(dbGetQuery(sim$castordb, "SELECT yieldid, age, tvol, height, eca FROM yields where tvol is not null"))
  #tab1<-data.table(dbGetQuery(sim$castordb, "SELECT pixelid, yieldid, age FROM pixels WHERE age >= 0 and yieldid is not null"))
  #tab1[, vol:= lapply(.SD, function(x) {approx(dat[yieldid == .BY]$age, dat[yieldid == .BY]$tvol,  xout=x, rule = 2)$y}), .SD = "age" , by=yieldid]
  #tab1[, ht:= lapply(.SD, function(x) {approx(dat[yieldid == .BY]$age, dat[yieldid == .BY]$height, xout=x, rule = 2)$y}), .SD = "age" , by=yieldid]

  if(length(dbGetQuery(sim$castordb, "SELECT variable FROM zoneConstraints WHERE variable = 'eca' LIMIT 1")) > 0){
    #tab1[, eca:= lapply(.SD, function(x) {approx(dat[yieldid == .BY]$age, dat[yieldid == .BY]$eca,  xout=x, rule = 2)$y}), .SD = "age" , by=yieldid]
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
    
    rs<-dbSendQuery(sim$castordb, "UPDATE pixels SET vol = :vol, height = :ht, eca = :eca, dec_pcnt = :dec_pcnt, crownclosure = :crownclosure, qmd = :qmd, basalarea= :basalarea where pixelid = :pixelid", tab1[,c("vol", "ht", "eca", "pixelid", "dec_pcnt", "crownclosure", "qmd", "basalarea")])
    dbClearResult(rs)
    dbCommit(sim$castordb)
  }else{
    
    tab1<-data.table(dbGetQuery(sim$castordb, "WITH t as (select pixelid, yieldid, age, height, crownclosure, dec_pcnt, basalarea, qmd, eca, vol from pixels where age > 0 and age <= 350) 
SELECT pixelid,
case when k.tvol is null then t.vol else (((k.tvol - y.tvol*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.tvol end as vol,
case when k.height is null then t.height else (((k.height - y.height*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.height end as ht,
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
    
    rs<-dbSendQuery(sim$castordb, "UPDATE pixels SET vol = :vol, height = :ht,  dec_pcnt = :dec_pcnt, crownclosure = :crownclosure, qmd = :qmd, basalarea= :basalarea where pixelid = :pixelid", tab1[,c("vol", "ht",  "pixelid", "dec_pcnt", "crownclosure", "qmd", "basalarea")])
    dbClearResult(rs)
    dbCommit(sim$castordb)
    }
  
  sim$growingStockReport<-data.table(scenario = sim$scenario$name, timeperiod = time(sim)*P(sim, "periodLength", "growingStockCastor"),  
                                     dbGetQuery(sim$castordb,"SELECT sum(vol) as gs, sum(vol*thlb) as m_gs, sum(vol*thlb*dec_pcnt) as m_dec_gs, compartid as compartment FROM pixels group by compartid;"))
                                     
  
  rm(tab1)
  gc()
  return(invisible(sim))
}

updateGS<- function(sim) {
  #Note: See the SQLite approach to updating. The Update statement does not support JOIN
  #update the yields being tracked
  message("...drop indexs")
  dbExecute(sim$castordb, "DROP INDEX index_age")
  dbExecute(sim$castordb, "DROP INDEX index_height")
  
  message("...increment age by:",sim$updateInterval)
  #Update the pixels table
  dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, paste0("UPDATE pixels SET age = age + ", sim$updateInterval," WHERE age >= 0"))
  dbClearResult(rs)
  dbCommit(sim$castordb)
  
  message("...update yields")
  if(length(dbGetQuery(sim$castordb, "SELECT variable FROM zoneConstraints WHERE variable = 'eca' LIMIT 1")) > 0){
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
    
    rs<-dbSendQuery(sim$castordb, "UPDATE pixels SET vol = :vol, height = :ht, eca = :eca, dec_pcnt = :dec_pcnt, crownclosure = :crownclosure, qmd = :qmd, basalarea= :basalarea where pixelid = :pixelid", tab1[,c("vol", "ht", "eca", "pixelid", "dec_pcnt", "crownclosure", "qmd", "basalarea")])
    dbClearResult(rs)
    dbCommit(sim$castordb)
    
  }else{
    
    tab1<-data.table(dbGetQuery(sim$castordb, "WITH t as (select pixelid, yieldid, age, height, crownclosure, dec_pcnt, basalarea, qmd, eca, vol from pixels where age > 0 and age <= 350) 
                                SELECT pixelid,
                                case when k.tvol is null then t.vol else (((k.tvol - y.tvol*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.tvol end as vol,
                                case when k.height is null then t.height else (((k.height - y.height*1.0)/10)*(t.age - CAST(t.age/10 AS INT)*10))+ y.height end as ht,
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
    
    rs<-dbSendQuery(sim$castordb, "UPDATE pixels SET vol = :vol, height = :ht,  dec_pcnt = :dec_pcnt, crownclosure = :crownclosure, qmd = :qmd, basalarea= :basalarea where pixelid = :pixelid", tab1[,c("vol", "ht",  "pixelid", "dec_pcnt", "crownclosure", "qmd", "basalarea")])
    dbClearResult(rs)
    dbCommit(sim$castordb) 
  }
  
  message("...create indexes")
  
  dbExecute(sim$castordb, "CREATE INDEX index_age on pixels (age)")
  dbExecute(sim$castordb, "CREATE INDEX index_height on pixels (height)")

  rm(tab1)
  gc()
  return(invisible(sim))
}

vacuumDB<- function(sim){
  message("...vacuum db")
  dbExecute(sim$castordb, "VACUUM;")
  return(invisible(sim)) 
}

recordGS<- function(sim) {
  message("...recording")
  sim$growingStockReport<- rbindlist(list(sim$growingStockReport, data.table(scenario = sim$scenario$name, timeperiod = time(sim)*sim$updateInterval,  
              dbGetQuery(sim$castordb, "SELECT sum(vol) as gs, sum(vol*thlb) as m_gs, sum(vol*thlb*dec_pcnt) as m_dec_gs, compartid as compartment FROM pixels group by compartid;"))), use.names = TRUE)
  
   return(invisible(sim))
}

.inputObjects <- function(sim) {
  return(invisible(sim))
}


