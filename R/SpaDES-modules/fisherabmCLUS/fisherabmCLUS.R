# Copyright 2022 Province of British Columbia
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

# Everything in this file and any files in the R directory are sourced during `simInit()`;
## all functions and objects are put into the `simList`.
## To use objects, use `sim$xxx` (they are globally available to all modules).
## Functions can be used inside any function that was sourced in this module;
## they are namespaced to the module, just like functions in R packages.
## If exact location is required, functions will be: `sim$.mods$<moduleName>$FunctionName`.

defineModule(sim, list(
  name = "fisherabmCLUS",
  description = "An agent based model (ABM) to simulate fisher life history on a landscape.",
  keywords = "fisher, martes, agent based model",
  authors = structure(list(list(given = c("First", "Middle"), family = "Last", role = c("aut", "cre"), email = "email@example.com", comment = NULL)), class = "person"),
  childModules = character(0),
  version = list(fisherabmCLUS = "0.0.0.9000"),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.md", "fisherabmCLUS.Rmd"), ## same file
  reqdPkgs = list("SpaDES.core (>=1.0.10)", "ggplot2"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter("n_females", "numeric", 1000, 0, 10000,
                    "The number of females to 'seed' the landscape with."),    
    defineParameter("female_hr_size_mean", "numeric", 3000, 100, 30000,
                    "The mean home range (territory) size, in hectares, of a female fisher."),    
    defineParameter("female_hr_size_sd", "numeric", 500, 10, 30000,
                    "The standard deviation of a home range (territory) size, in hectares, of female fisher."), 
    defineParameter("female_max_age", "numeric", 15, 0, 20,
                    "The maximum possible age of a female fisher."), 
    defineParameter("female_search_radius", "numeric", 6, 0, 100,
                    "The maximum search radius, in km, that a female fisher could ‘search’ to establish a territory."), 
    defineParameter("den_target ", "numeric", 0.10, 0.01, 0.99,
                    "The desired proportion of a home range that is denning habitat."), 
    defineParameter("rest_target ", "numeric", 0.10, 0.01, 0.99,
                    "The desired proportion of a home range that is resting habitat."),   
    defineParameter("move_target ", "numeric", 0.40, 0.01, 0.99,
                    "The desired proportion of a home range that is movement habitat."), 
    defineParameter("survival_rate_table", "character", "table name in pgdb?", NA, NA,
                    "Table of fisher survial rates by sex, age and habitat quality."),
    defineParameter("d2_survival_adj", "function", NA, NA, NA,
                    "Function relating habitat quality to survival rate."),
    defineParameter("reproductive_age", "numeric", 2, 1, 5,
                    "Minimum age that a female fisher reaches sexual maturity."),
    defineParameter("den_rate_mean", "numeric", 0.5, 0, 1,
                    "Mean rate at which a female gets pregnant and gives birth to young (i.e., a combination of pregnancy rate and birth rate)."),
    defineParameter("den_rate_sd", "numeric", 0.1, 0, 1,
                    "Standard deviation of the rate at which a female gets pregnant and gives birth to young (i.e., a combination of pregnancy rate and birth rate)."),
    defineParameter("litter_size_mean", "numeric", 2, 1, 10,
                    "Mean number of kits born in a litter."),
    defineParameter("sex_ratio", "numeric", 0.5, 0, 1,
                    "The ratio of females to males in a litter."),
    defineParameter("max_female_dispersal_dist", "numeric", 10, 1, 100,
                    "The maximum distance, in kilometres, a female will disperse to find a territory."),
    defineParameter("timeInterval", "numeric", 1, 1, 20,
                    "The time step, in years, between cacluating life history events (reproduce, updateHR, survive, disperse)."),
    defineParameter(".plots", "character", "screen", NA, NA,
                    "Used by Plots function, which can be optionally used here"),
    defineParameter(".plotInitialTime", "numeric", start(sim), NA, NA,
                    "Describes the simulation time at which the first plot event should occur."),
    defineParameter(".plotInterval", "numeric", NA, NA, NA,
                    "Describes the simulation time interval between plot events."),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA,
                    "Describes the simulation time at which the first save event should occur."),
    defineParameter(".saveInterval", "numeric", NA, NA, NA,
                    "This describes the simulation time interval between save events."),
    ## .seed is optional: `list('init' = 123)` will `set.seed(123)` for the `init` event only.
    defineParameter(".seed", "list", list(), NA, NA,
                    "Named list of seeds to use for each event (names)."),
    defineParameter(".useCache", "logical", FALSE, NA, NA,
                    "Should caching of events or module be used?")
  ),
  inputObjects = bindrows(
    #expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput (objectName = NA, objectClass = NA, desc = NA, sourceURL = NA)
  ),
  outputObjects = bindrows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput (objectName = NA, objectClass = NA, desc = NA)
  )
))

## event types
#   - type `init` is required for initialization

doEvent.fisherabmCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
 
      sim <- Init(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "timeInterval", "fisherabmCLUS"), "fisherabmCLUS", "reproduce", 20)

    },
    reproduce = {
      # ! ----- EDIT BELOW ----- ! #
      # do stuff for this event

      # e.g., call your custom functions/methods here
      # you can define your own methods below this `doEvent` function

      # schedule future event(s)

      # e.g.,
      # sim <- scheduleEvent(sim, time(sim) + increment, "fisherabmCLUS", "templateEvent")
      sim <- scheduleEvent(sim, time(sim), "fisherabmCLUS", "updateHR", 21)
      
      # ! ----- STOP EDITING ----- ! #
    },
    updateHR = {
      # ! ----- EDIT BELOW ----- ! #
      # do stuff for this event

      # e.g., call your custom functions/methods here
      # you can define your own methods below this `doEvent` function

      # schedule future event(s)

      # e.g.,
      # sim <- scheduleEvent(sim, time(sim) + increment, "fisherabmCLUS", "templateEvent")
      sim <- scheduleEvent(sim, time(sim), "fisherabmCLUS", "disperse", 22)
      # ! ----- STOP EDITING ----- ! #
    },
    disperse = {
      # ! ----- EDIT BELOW ----- ! #
      # do stuff for this event
      
      # e.g., call your custom functions/methods here
      # you can define your own methods below this `doEvent` function
      
      # schedule future event(s)
      
      # e.g.,
      # sim <- scheduleEvent(sim, time(sim) + increment, "fisherabmCLUS", "templateEvent")
      sim <- scheduleEvent(sim, time(sim), "fisherabmCLUS", "survive", 23)   
      # ! ----- STOP EDITING ----- ! #
    },
    survive = {
      # ! ----- EDIT BELOW ----- ! #
      # do stuff for this event
      
      # e.g., call your custom functions/methods here
      # you can define your own methods below this `doEvent` function
      
      # schedule future event(s)
      
      # e.g.,
      # sim <- scheduleEvent(sim, time(sim) + increment, "fisherabmCLUS", "templateEvent")
      sim <- scheduleEvent(sim, time(sim) + P(sim, "timeInterval", "fisherabmCLUS"), "fisherabmCLUS", "reproduce", 20)
      # ! ----- STOP EDITING ----- ! #
    },
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
                  "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'", sep = ""))
  )
  return(invisible(sim))
}



## event functions
#   - keep event functions short and clean, modularize by calling subroutines from section below.

Init <- function(sim) {
  
  message ("Initiating fisher ABM...")
  
  message ("Create agents table and assign values...")
  ids <- seq (from = 1, to = P(sim, "n_females", "fisherabmCLUS"), by = 1) # sequence of individual id's from 1 to n_females
  agents <- data.table (individual_id = ids, 
                        sex = "F", 
                        age = sample (1:P(sim, "max_age", "fisherabmCLUS"), length (ids), replace = T), # randomly draw ages between 1 and the max age, 
                        pixelid = numeric (), 
                        hr_size = rnorm (P(sim, "n_females", "fisherabmCLUS"), P(sim, "female_hr_size_mean", "fisherabmCLUS"), P(sim, "female_hr_size_sd", "fisherabmCLUS")), 
                        d2_score = numeric ())
  # get the pixelid's that are fisher habitat and randomly assign to the agents
  # NOTE: this is for central interior fisher only
  # we may need a s'witch' param for central interior or boreal
  den.pix <- data.table (dbGetQuery(sim$clusdb, "SELECT pixelid FROM pixels WHERE age >= 125 AND crownclosure >= 30 AND qmd >=28.5 AND basalarea >= 29.75;"))
  agents$pixelid <- sample (den.pix$pixelid, length (ids), replace = T)
  
  if(nrow(dbGetQuery(sim$clusdb, "SELECT name FROM sqlite_schema WHERE type ='table' AND name = 'agents';")) == 0){
    # if the table exists, write it to the db
    DBI::dbWriteTable (sim$clusdb, "agents", agents, append = FALSE, 
                       row.names = FALSE, overwite = FALSE)  
  } else {
    # if the table exists, append it to the table in the db
    DBI::dbWriteTable (sim$clusdb, "agents", agents, append = TRUE, 
                       row.names = FALSE, overwite = FALSE)  
  }
  
  message ("Create territories table...")
  territories <- data.table (individual_id = agents$individual_id, 
                             pixelid = agents$pixelid)
  if(nrow(dbGetQuery(sim$clusdb, "SELECT name FROM sqlite_schema WHERE type ='table' AND name = 'territories';")) == 0){
    # if the table exists, write it to the db
    DBI::dbWriteTable (sim$clusdb, "territories", territories, append = FALSE, 
                       row.names = FALSE, overwite = FALSE)  
  } else {
    # if the table exists, append it to the table in the db
    DBI::dbWriteTable (sim$clusdb, "territories", territories, append = TRUE, 
                       row.names = FALSE, overwite = FALSE)  
  }
  
 ##Create Female Home Ranges
  message ("Create female home ranges...")
  # get the aoi raster
  sim$aoi <- RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), 
                           srcRaster = P (sim, "nameCompartmentRaster", "dataLoaderCLUS"), 
                           clipper = P (sim, "nameBoundaryFile", "dataLoaderCLUS" ), 
                           geom = P (sim, "nameBoundaryGeom", "dataLoaderCLUS"), 
                           where_clause =  paste0 ( P (sim, "nameBoundaryColumn", "dataLoaderCLUS"), " in (''", paste(P(sim, "nameBoundary", "dataLoaderCLUS"), sep = "' '", collapse= "'', ''") ,"'')"),
                           conn = NULL) 
  # this step takes a couple seconds - can be do it faster?
  # or get this as sim$ras form dataloderCLUS?
  
  # pixel id's in aoi landscape 
  pix.for.rast <- data.table (dbGetQuery(sim$clusdb, "SELECT pixelid FROM pixels WHERE compartid IS NOT NULL;"))
  sim$pix.rast <- sim$aoi
  sim$pix.rast [pix.for.rast$pixelid] <- pix.for.rast$pixelid
  
  # fisher starting locations 
  sim$start.rast <- sim$aoi
  sim$start.rast [agents$pixelid] <- agents$pixelid
  
  # pixels in fisher search area
  # apply fucntion - for each agent....
  
  
  
  fisherSearchArea<-SpaDES.tools::spread2(aoi, 
                                          start = fisherLocation, 
                                          spreadProb = 1, 
                                          maxSize = 1000, 
                                          allowOverlap = T, 
                                          returnDistances = T, # Does not work?
                                          asRaster = F)
  
  
  
  
  
  
  
  # denning pixels
  sim$den.rast <- sim$aoi
  sim$den.rast [den.pix$pixelid] <- den.pix$pixelid
  
  
  
  sim$harvestBlocks[queue$pixelid]<-time(sim)*sim$updateInterval

    
    
    
    
  
  pixels<-data.table(pixelid=aoi[]) #transpose then vectorize which matches the same order as adj
  pixels[, pixelid := seq_len(.N)]

  aoi []<-pixels$pixelid
  
  test.rast [] <- den.pix$pixelid
  
  
  
  
  
  
  
  

  
  
  
  sql<-paste0("SELECT pixelid, p.blockid as blockid, compartid, yieldid, height, elv, (age*thlb) as age_h, thlb, (thlb*vol) as vol_h, (thlb*salvage_vol) as salvage_vol ", partition_case, "
FROM pixels p
INNER JOIN 
(SELECT blockid, ROW_NUMBER() OVER ( 
		ORDER BY ", P(sim, "harvestBlockPriority", "forestryCLUS"), ") as block_rank FROM blocks) b
on p.blockid = b.blockid
WHERE compartid = '", compart ,"' AND zone_const = 0 AND thlb > 0 AND p.blockid > 0 AND (", partition_sql, ")
ORDER by block_rank, ", P(sim, "harvestBlockPriority", "forestryCLUS"), "
                           LIMIT ", as.integer(sum(harvestTarget)/50))
  
}





queue<-data.table(dbGetQuery(sim$clusdb, sql))



  
  
  
  sim$aoi <- 
  
    data.table (dbGetQuery (clusdb, "SELECT * FROM agents;"))
  
  den.pix
  
  
  
  
  



    
    
    

  
  
  # ! ----- STOP EDITING ----- ! #

  return(invisible(sim))
}

### template for save events
Save <- function(sim) {
  # ! ----- EDIT BELOW ----- ! #
  # do stuff for this event
  sim <- saveFiles(sim)

  # ! ----- STOP EDITING ----- ! #
  return(invisible(sim))
}

### template for plot events
plotFun <- function(sim) {
  # ! ----- EDIT BELOW ----- ! #
  # do stuff for this event
  sampleData <- data.frame("TheSample" = sample(1:10, replace = TRUE))
  Plots(sampleData, fn = ggplotFn)

  # ! ----- STOP EDITING ----- ! #
  return(invisible(sim))
}

### template for your event1
Event1 <- function(sim) {
  # ! ----- EDIT BELOW ----- ! #
  # THE NEXT TWO LINES ARE FOR DUMMY UNIT TESTS; CHANGE OR DELETE THEM.
  # sim$event1Test1 <- " this is test for event 1. " # for dummy unit test
  # sim$event1Test2 <- 999 # for dummy unit test

  # ! ----- STOP EDITING ----- ! #
  return(invisible(sim))
}

### template for your event2
Event2 <- function(sim) {
  # ! ----- EDIT BELOW ----- ! #
  # THE NEXT TWO LINES ARE FOR DUMMY UNIT TESTS; CHANGE OR DELETE THEM.
  # sim$event2Test1 <- " this is test for event 2. " # for dummy unit test
  # sim$event2Test2 <- 777  # for dummy unit test

  # ! ----- STOP EDITING ----- ! #
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  # Any code written here will be run during the simInit for the purpose of creating
  # any objects required by this module and identified in the inputObjects element of defineModule.
  # This is useful if there is something required before simulation to produce the module
  # object dependencies, including such things as downloading default datasets, e.g.,
  # downloadData("LCC2005", modulePath(sim)).
  # Nothing should be created here that does not create a named object in inputObjects.
  # Any other initiation procedures should be put in "init" eventType of the doEvent function.
  # Note: the module developer can check if an object is 'suppliedElsewhere' to
  # selectively skip unnecessary steps because the user has provided those inputObjects in the
  # simInit call, or another module will supply or has supplied it. e.g.,
  # if (!suppliedElsewhere('defaultColor', sim)) {
  #   sim$map <- Cache(prepInputs, extractURL('map')) # download, extract, load file from url in sourceURL
  # }

  #cacheTags <- c(currentModule(sim), "function:.inputObjects") ## uncomment this if Cache is being used
  dPath <- asPath(getOption("reproducible.destinationPath", dataPath(sim)), 1)
  message(currentModule(sim), ": using dataPath '", dPath, "'.")

  # ! ----- EDIT BELOW ----- ! #

  # ! ----- STOP EDITING ----- ! #
  return(invisible(sim))
}

ggplotFn <- function(data, ...) {
  ggplot(data, aes(TheSample)) +
    geom_histogram(...)
}

### add additional events as needed by copy/pasting from above
