
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
#===========================================================================================

defineModule(sim, list(
  name = "earlySeralRiskCastor",
  description = "Calculates an early seral risk rating used for monitoring biodiversity",
  keywords = "",
  authors = c (person ("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre")),
               person ("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(earlySeralRiskCastor = "0.0.0.9000"),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.md", "earlySeralRiskCastor.Rmd"), ## same file
  reqdPkgs = list("SpaDES.core (>=1.0.10)", "ggplot2"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter(".plots", "character", "screen", NA, NA,"Used by Plots function, which can be optionally used here"),
    defineParameter(".plotInitialTime", "numeric", start(sim), NA, NA,"Describes the simulation time at which the first plot event should occur."),
    defineParameter(".plotInterval", "numeric", NA, NA, NA,"Describes the simulation time interval between plot events."),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA,"Describes the simulation time at which the first save event should occur."),
    defineParameter(".saveInterval", "numeric", NA, NA, NA,"This describes the simulation time interval between save events."),
    ## .seed is optional: `list('init' = 123)` will `set.seed(123)` for the `init` event only.
    defineParameter(".seed", "list", list(), NA, NA,"Named list of seeds to use for each event (names)."),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should caching of events or module be used?"),
    defineParameter("becRaster", "character", "99999", NA, NA, "A raster of bec zones to evaluate")
  ),
  inputObjects = bindrows(
    expectsInput (objectName = "castordb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the model. This module needs the roadyear variable from the pixels table in the castordb.', sourceURL = NA),
    expectsInput(objectName ="scenario", objectClass ="data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName ="updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA)
  ),
  outputObjects = bindrows(
    createsOutput (objectName = "earlySeralRiskReport", objectClass = "data.table", desc = "A data.table object of the percentage early seral")
  )
))

doEvent.earlySeralRiskCastor = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init(sim)
      sim <- scheduleEvent (sim, time(sim) + 1, "earlySeralRiskCastor", "calculateEarlySeralRisk", 10) # schedule the next survival calculation event; should be after roadCastor
    },
    calculateEarlySeralRisk = {
      sim <- calcEarlySeralRisk(sim)
      sim <- scheduleEvent (sim, time(sim) + 1, "earlySeralRiskCastor", "calculateEarlySeralRisk", 10) # schedule the next survival calculation event; should be after roadCastor
    },
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
                  "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  if(!(P(sim, "becRaster", "earlySeralRiskCastor") %in% dbGetQuery(sim$castordb, "select reference_zone from zone;")$reference_zone)){
    stop("...add the functionality to specify other rasters as area bounds for early seral risk")
  }else{
    message(paste0("using:", P(sim, "becRaster", "earlySeralRiskCastor")))
    sim$esRiskZone<-dbGetQuery(sim$castordb, paste0("select zone_column from zone where reference_zone ='",P(sim, "becRaster", "earlySeralRiskCastor") ,"';"))$zone_column
    sim$earlySeralRiskReport<-data.table(timeperiod = as.integer(), scenario = as.character(), compartment =  as.character(),  zone = as.integer(), total_area = as.integer(), per_early_seral = as.numeric())
  }
  
  return(invisible(sim))
}

calcEarlySeralRisk <- function(sim) {
  tempESR<-data.table (dbGetQuery (sim$castordb, paste0("SELECT count(*) as total_area, avg(case when age < 40 then 1.0 else 0 end) as per_early_seral, ",sim$esRiskZone," as zone, compartid as compartment FROM pixels where compartid is not null  group by compartid, ",sim$esRiskZone,";")))
  tempESR<-tempESR[,`:=` (timeperiod = time(sim)*sim$updateInterval, scenario = sim$scenario$name) ]
  sim$earlySeralRiskReport<-rbindlist(list(sim$earlySeralRiskReport, tempESR), use.names=TRUE)
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  return(invisible(sim))
}

