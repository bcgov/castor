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
  name = "yieldUncertaintyCLUS",
  description = "Calibrates yield models used in BC, conditional on observed yield data following harvesting operations", 
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", yieldUncertaintyCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.md", "yieldUncertaintyCLUS.Rmd"),
  reqdPkgs = list(),
  parameters = rbind(
    defineParameter("calculateInterval", "numeric", 1, NA, NA, "The interval for calculating total harvest uncertainty. E.g., 1,5 or 10 year"),
    defineParameter("elevationRaster", "character", "rast.dem", NA, NA, "The elevation raster used as a covariate in the calibration model"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput(objectName = "clusdb", objectClass ="SQLiteConnection", desc = "A rSQLite database that stores, organizes and manipulates clus realted information", sourceURL = NA),
    expectsInput(objectName = "boundaryInfo", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "harvestBlockList", objectClass = "data.table", desc = NA, sourceURL = NA),
    #expectsInput(objectName = "calb_ymodel", objectClass = "gamlss", desc = "A gamma model of volume yield uncertainty", sourceURL = NA),
    expectsInput(objectName = "yieldUncertaintyCovar", objectClass = "character", desc = "String of the yield uncertainty covariates", sourceURL = NA),
    expectsInput(objectName =" scenario", objectClass ="data.table", desc = 'The name of the scenario and its description', sourceURL = NA)
  
    ),
  outputObjects = bind_rows(
    createsOutput(objectName = "yielduncertain", objectClass = "data.table", desc = NA)
  )
))


doEvent.yieldUncertaintyCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init(sim)
      # schedule future event(s)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "yieldUncertaintyCLUS", "calculateInterval"), "yieldUncertaintyCLUS", "calculateUncertainty", eventPriority= 12)
    },
    calculateUncertainty = {
      sim <- calculateYieldUncertainty(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "yieldUncertaintyCLUS", "calculateInterval"), "yieldUncertaintyCLUS", "calculateUncertainty", eventPriority= 12)
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  #Add a column for the covariates list -- this is now hard coded -- needs to be generalized. Done in dataLoaderCLUS
  #dbExecute(sim$clusdb, paste0("ALTER TABLE pixels ADD COLUMN elv numeric"))
  
  #Get any covariates in the calibration model. Need an indicator if this has already been run and in the database
  if(!(dbGetQuery(sim$clusdb, "SELECT count(*) from pixels where elv > 0") > 0)){
    elevation<- data.table (c (t (raster::as.matrix( 
    RASTER_CLIP2(tmpRast = sim$boundaryInfo[[3]], 
                 srcRaster = P(sim, "yieldUncertaintyCLUS", "elevationRaster"), # for each unique spp-pop-boundary, clip each rsf boundary data, 'bounds' (e.g., rast.du6_bounds)
                 clipper = sim$boundaryInfo[[1]],  # by the area of analysis (e.g., supply block/TSA)
                 geom = sim$boundaryInfo[[4]], 
                 where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                 conn = NULL)))))
    elevation[,V1:=as.integer(V1)] #make an integer for merging the values
    elevation[,pixelid:=seq_len(.N)]#make an index
  
    dbBegin(sim$clusdb)
      rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET elv =  :V1 WHERE pixelid = :pixelid", elevation)
    dbClearResult(rs)
    dbCommit(sim$clusdb)
  }
 
  sim$yieldUncertaintyCovar<- ' elv ,'

  return(invisible(sim))
}

calculateYieldUncertainty <-function(sim) {
  sim$yielduncertain <- rbindlist(list(sim$yielduncertain,
  #lapply(split(sim$harvestBlockList, by ="compartid"), simYieldUncertainty, sim$calb_ymodel, sim$scenario$name, time(sim)))))
                rbindlist(lapply(split(sim$harvestBlockList, by ="compartid"), simYieldUncertainty, sim$scenario$name, time(sim))
                          )))
  
  if(nrow(sim$yielduncertain) == 0){
    sim$yielduncertain<-NULL
  }
  
  #Remove any blocks from the list. This will 'accumulate' in the forestryCLUS module
  sim$harvestBlockList<-NULL
  return(invisible(sim))
}

simYieldUncertainty <-function(to.cut, scenarioName, time.sim) {
  message(".....calc uncertainty of yields")
  #to.cut$dummy<-1
  #cut.hat <- gamlss::predictAll(calb_ymodel, newdata = to.cut[,c("proj_vol", "dummy","proj_height_1", "X", "Y")]) #get the mu.hat and sigma.hat 
  #to.cut$mu<-cut.hat$mu
  #to.cut$sigma<-cut.hat$sigma
  
  #Hard code the model...this is going to change once another calibration model for TASS yields has been developed...
  to.cut[, mu:= exp(0.2902 + log(proj_vol)*0.9416)]
  to.cut[, sigma:= exp(1.4803905 + log(proj_vol)*-0.0937275 + proj_height_1*-0.0402479 + elv*-0.0003855)]
  
  message(paste0(".......sim error: ", nrow(to.cut)))
  
  sim.volume <-rGA(20000, mu = sum(to.cut$mu), sigma = sqrt(sum((to.cut$mu*to.cut$sigma)**2))/sum(to.cut$mu) )
  distquants<-quantile(sim.volume, p = c(0.05, 0.95))
  
  return(data.table(scenario = scenarioName,
                    compartment= max(to.cut$compartid),
                    timeperiod = time.sim,
                    projvol =sum(to.cut$proj_vol),
                    calibvol = mean(sim.volume), 
                    prob = mean(sim.volume>sum(to.cut$proj_vol)),
                    pred5 = distquants[1],
                    pred95 = distquants[2])) 
}

.inputObjects <- function(sim) {
  dPath <- asPath(getOption("reproducible.destinationPath", dataPath(sim)), 1)
  message(currentModule(sim), ": using dataPath '", dPath, "'.")

  return(invisible(sim))
}
