## Everything in this file gets sourced during `simInit()`,
## and all functions and objects are put into the `simList`.
## To use objects, use `sim$xxx` (they are globally available to all modules).
## Functions can be used without `sim$` as they are namespaced to the module,
## just like functions in R packages.
## If exact location is required, functions will be: `sim$<moduleName>$FunctionName`.
defineModule(sim, list(
  name = "mooseforageCASTOR",
  description = "This module extimates moose forage biomass from the forest inventory, using the method developed by Doug Lewis.",
  keywords = "",
  authors = structure(list(list(given = c("Tyler", "Bryon"), family = "Muhly", role = c("aut", "cre"), email = "tyler.muhly@gov.bc.ca", comment = NULL)), class = "person"),
  childModules = character(0),
  version = list(SpaDES.core = "1.0.3", mooseforageCASTOR = "0.0.0.9000"),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = deparse(list("README.txt", "mooseforageCASTOR.Rmd")),
  reqdPkgs = list(),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter ("nameForestInventoryWetlandField", "character", "99999", NA, NA, "Name of the wetland field in the forest inventory data."), 
    defineParameter ("nameForestInventoryWetlandClass", "character", "99999", NA, NA, "Name of the wetland class values in the forest inventory data."), 
    defineParameter ("nameForestInventoryRiparianField", "character", "99999", NA, NA, "Name of the riparian area field in the forest inventory data."), 
    defineParameter ("nameForestInventoryRiparianClass", "character", "99999", NA, NA, "Name of the riparian class values in the forest inventory data."), 
    defineParameter ("climateRaster", "character", "99999", NA, NA, "Name of the moose climate envelope raster to use in the databse."), 
    defineParameter("updateclimateRaster", "logical", FALSE, NA, NA, "Declare whether to update the climate envelope raster at future time intervals (2055, 2085) using projected climateBC data.")
    
  ),
  inputObjects = bind_rows(
    #expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput (objectName = "castordb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the model. This module needs the dec_pcnt, age variable from the pixels table in the castordb.', sourceURL = NA)  ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = NA, objectClass = NA, desc = NA)
  )
))

## event types
#   - type `init` is required for initialization

doEvent.mooseforageCASTOR = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      ### check for more detailed object dependencies:
      ### (use `checkObject` or similar)

      # do stuff for this event
      sim <- Init(sim)
      
      # schedule future event(s)
      sim <- scheduleEvent(sim, P(sim)$.plotInitialTime, "mooseforageCASTOR", "plot")
      sim <- scheduleEvent(sim, P(sim)$.saveInitialTime, "mooseforageCASTOR", "save")
    },
    plot = {
      # ! ----- EDIT BELOW ----- ! #
      # do stuff for this event

      #plotFun(sim) # uncomment this, replace with object to plot
      # schedule future event(s)

      # e.g.,
      #sim <- scheduleEvent(sim, time(sim) + P(sim)$.plotInterval, "mooseforageCASTOR", "plot")

      # ! ----- STOP EDITING ----- ! #
    },
    save = {
      # ! ----- EDIT BELOW ----- ! #
      # do stuff for this event

      # e.g., call your custom functions/methods here
      # you can define your own methods below this `doEvent` function

      # schedule future event(s)

      # e.g.,
      # sim <- scheduleEvent(sim, time(sim) + P(sim)$.saveInterval, "mooseforageCASTOR", "save")

      # ! ----- STOP EDITING ----- ! #
    },
    event1 = {
      
      
      
      
      
      # ! ----- EDIT BELOW ----- ! #
      # do stuff for this event

      # e.g., call your custom functions/methods here
      # you can define your own methods below this `doEvent` function

      # schedule future event(s)

      # e.g.,
      # sim <- scheduleEvent(sim, time(sim) + increment, "mooseforageCASTOR", "templateEvent")

      # ! ----- STOP EDITING ----- ! #
    },
    event2 = {
      # ! ----- EDIT BELOW ----- ! #
      # do stuff for this event

      # e.g., call your custom functions/methods here
      # you can define your own methods below this `doEvent` function

      # schedule future event(s)

      # e.g.,
      # sim <- scheduleEvent(sim, time(sim) + increment, "mooseforageCASTOR", "templateEvent")

      # ! ----- STOP EDITING ----- ! #
    },
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
                  "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'", sep = ""))
  )
  return(invisible(sim))
}

## event functions
#   - keep event functions short and clean, modularize by calling subroutines from section below.

### template initialization
Init <- function(sim) {
  # # ! ----- EDIT BELOW ----- ! #

  # define pixels that are wetlands
  
  #1. need to get wetland, riparian and deciduous (dec_pcnt in pixels) data from forest inventory - create static forage table
  #2. calculate static forage values for area of interest
  #3. create dynamic forage table
  #4. calculate dynamic forage values for area of interest -> repeat at interval
  #5. calculate total forage value -> repeat at interval
  #6. caclulate moose abundance estimaet at interval (end)
  #7 save the output table
  
  

  
  # Sql query for applyign forage values
  # forage_id is forage tpye
  # neeeds equation for 'dynamic' forage types
  # SQL equatiosn coudl also be a field in the table
  select sum(case forage_id when 0 then 50 when 1 then 75 when 2 then 100 when 3 then age*13 when 4 then age*age*0.5 + age*1.8 end) as forage from pixels where treed = 1  
  
  
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
  #Plot(sim$object)

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

### add additional events as needed by copy/pasting from above
