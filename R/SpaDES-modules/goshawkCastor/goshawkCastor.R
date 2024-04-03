#===========================================================================================#
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
#===========================================================================================#

defineModule(sim, list(
  name = "goshawkCastor",
  description = "",
  keywords = "",
  authors = c(person("Bill", "Harrower", email = "Bill.L.Harrower@gov.bc.ca", role = c("aut", "cre")),
              person("Elizabeth", "Kleynhans", email = "elizabeth.kleynhans@gov.bc.ca", role = c("aut", "cre")),
              person("Louise", "Waterhouse", email = "louise.waterhouse@gov.bc.ca", role = c("cre")),
              person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut","cre"))),
  childModules = character(0),
  version = list(goshawkCastor = "0.0.0.9000"),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.md", "goshawkCastor.Rmd"), ## same file
  reqdPkgs = list("SpaDES.core (>=1.0.10)", "ggplot2"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
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
    expectsInput(objectName = NA, objectClass = NA, desc = NA, sourceURL = NA)
  ),
  outputObjects = bindrows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = NA, objectClass = NA, desc = NA)
  )
))


doEvent.goshawkCastor = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init(sim)
      sim <- scheduleEvent(sim, P(sim)$.plotInitialTime, "goshawkCastor", "plot")
      sim <- scheduleEvent(sim, P(sim)$.saveInitialTime, "goshawkCastor", "save")
    },
    plot = {

      plotFun(sim) # example of a plotting function
     
    },
    save = {
      
    },
    nestPlacement = {
      #The nest placement sub-model places nests in the landscape according to habitat quality and nest spacing criteria
      n_nests <- 5 
      nests.available.coords<-data.table(terra::xyFromCell(sim$goshawkNestingHabitat, 1:nrow(sim$goshawkNestingHabitat[])))
      #Use a well balanced sampling design see: https://dickbrus.github.io/SpatialSamplingwithR/BalancedSpreaded.html#LPM 
      #Grafström, A., Lundström, N.L.P. and Schelin, L. (2012). Spatially balanced sampling through the Pivotal method. Biometrics 68(2), 514-520
      #set.seed(1586) #Useful for testing
      pi <- sampling::inclusionprobabilities(sim$goshawkNestingHabitat, n_nests) #Equal probability
      nest.samples <- BalancedSampling::lpm(pi, cbind(nests.available.coords$x, nests.available.coords$y), h = 500) #Local pivot method using BalancedSampling
      terra::plot(goshawkNestingHabitat)
      points(terra::xFromCell(goshawkNestingHabitat,nest.samples), terra::yFromCell(goshawkNestingHabitat, nest.samples))  
    },
    territoryGrowth = {
    #territory growth sub-model attempts to create territories around each nest area according to habitat quality, distance from the nest and restrictions on overlap of adjacent territories.
      
    },
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
                  "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'", sep = ""))
  )
  return(invisible(sim))
}


Init <- function(sim) {
 
  return(invisible(sim))
}


Save <- function(sim) {
  
  sim <- saveFiles(sim)
  return(invisible(sim))
}

### template for plot events
plotFun <- function(sim) {
  
  sampleData <- data.frame("TheSample" = sample(1:10, replace = TRUE))
  Plots(sampleData, fn = ggplotFn)

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
  #dPath <- asPath(getOption("reproducible.destinationPath", dataPath(sim)), 1)
  #message(currentModule(sim), ": using dataPath '", dPath, "'.")
  
  if (!suppliedElsewhere('goshawkNestingHabitat', sim)) {
    sim$goshawkNestingHabitat <- terra::rast(nrows =100, ncols=100, vals = runif(10000))
  }

  return(invisible(sim))
}

ggplotFn <- function(data, ...) {
  ggplot(data, aes(TheSample)) +
    geom_histogram(...)
}

### add additional events as needed by copy/pasting from above
