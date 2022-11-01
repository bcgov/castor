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

defineModule (sim, list(
  name = "fisherHabitatLoader",
  description = "An module to create spataila fisher habitat data from forest data output from forestryCLUS.",
  keywords = "fisher, martes, habitat, raster",
  authors = structure(list(list(given = c("First", "Middle"), family = "Last", role = c("aut", "cre"), email = "email@example.com", comment = NULL)), class = "person"),
  childModules = character(0),
  version = list(fisherHabitatLoader = "0.0.0.9000"),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.md", "fisherHabitatLoader.Rmd"), ## same file
  reqdPkgs = list("SpaDES.core (>=1.0.10)", "data.table", "terra", "here"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    # defineParameter("n_females", "numeric", 1000, 0, 10000, # not used
    #                 "The number of females to 'seed' the landscape with."),    
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
    #expectsInput (objectName = NA, objectClass = NA, desc = NA, sourceURL = NA)
    expectsInput (objectName = "clusdb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates clus realted information", sourceURL = NA),
    expectsInput (objectName = "scenario", objectClass = "data.table", desc = "Table of scenario description.", sourceURL = NA),
    expectsInput (objectName = "ras", objectClass = "RasterLayer", desc = "Raster of the area of interest. This is stored in the clusdb that comes from dataLoaderCLUS.", sourceURL = NA),
    expectsInput (objectName = "boundaryInfo", objectClass ="character", desc = "Name of the area of interest(aoi) eg. Quesnel_TSA", sourceURL = NA),
    expectsInput (objectName = "updateInterval", objectClass = "numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA)
    ),
  outputObjects = bindrows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    #createsOutput (objectName = NA, objectClass = NA, desc = NA)
    createsOutput (objectName = "habitat.rast.stack", objectClass = "raster stack", desc = "A raster stack of fisher habitat over time." )
    )
))

## event types

doEvent.fisherHabitatLoader = function (sim, eventTime, eventType) {
  switch(
    eventType,
    
    init = {
      sim <- Init (sim)
      sim <- scheduleEvent (sim, time(sim) + 1, "fisherHabitatLoader", "update", 2)
      sim <- scheduleEvent (sim, end (sim), "fisherHabitatLoader", "save", 3)
      
    },

    update = {
      sim <- updateHabitat (sim)
      sim <- scheduleEvent (sim, time (sim) + 1, "fisherHabitatLoader", "update", 2)
    },
   
    save = {
      sim <- saveHabitat (sim)
    },
    
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
                  "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'", sep = ""))
  )
  return(invisible(sim))
}


## event functions
Init <- function (sim) {
  
  message ("Initiating fisher habitat data creation...")
  
  # instantiate raster for saving data
  sim$ras.fisher.habitat <- sim$ras
  # get pixel id's for aoi 
  pix.for.rast <- data.table (dbGetQuery (sim$clusdb, "SELECT pixelid FROM pixels WHERE compartid IS NOT NULL;"))
  sim$ras.fisher.habitat [pix.for.rast$pixelid] <- pix.for.rast$pixelid
  sim$ras.fisher.habitat [!pix.for.rast$pixelid] <- NA
  
  message ("Getting fisher habitat capability and range data...")

  # below creates a 'table in the clus db that defines where fisher habitat could occur
  if(nrow (dbGetQuery(sim$clusdb, "SELECT name FROM sqlite_schema WHERE type ='table' AND name = 'fisherlandscape';")) == 0) { # Check to see if this data exists in the sqlite db already
    message ("Creating fisherlandscape table.")
    # Create the habitat data table in the database if it does not exist
    dbExecute (sim$clusdb, "CREATE TABLE IF NOT EXISTS fisherlandscape (pixelid integer, den_p integer, rus_p integer, mov_p integer, cwd_p integer, cav_p integer, fisher_pop integer)")
    sim$table.hab <- data.table (pixelid = sim$ras.fisher.habitat [], # this identifies and grabs ('clips') the potential habitat in the area of interest
                                 den_p = RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = "rast.fisher_denning_p" , # 
                                                       clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                                                       where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                       conn = NULL)[],
                                 rus_p = RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = "rast.fisher_rust_p" , # 
                                                       clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                                                       where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                       conn = NULL)[],
                                 cwd_p = RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = "rast.fisher_cwd_p" , # 
                                                       clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                                                       where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                       conn = NULL)[],
                                 cav_p = RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = "rast.fisher_cavity_p" , # 
                                                       clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                                                       where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                       conn = NULL)[],
                                 mov_p = RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = "rast.fisher_movement_p" , # 
                                                       clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                                                       where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                       conn = NULL)[],
                                 fisher_pop = RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), srcRaster = "rast.fisher_zones" , # 
                                                       clipper=sim$boundaryInfo[[1]], geom=sim$boundaryInfo[[4]], 
                                                       where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                       conn = NULL)[]
                                 ) #---VAT for populations: 1 = Boreal; 2 = SBS-wet; 3 = SBS-dry; 4 = Dry Forest
    
    
    sim$table.hab [, fisher_pop := as.numeric (fisher_pop)]
    sim$table.hab <- sim$table.hab [fisher_pop > 0, ] # filter so it's only including habitat in fisher population ranges
    dbBegin (sim$clusdb) 
    rs <- dbSendQuery (sim$clusdb, paste0 ("INSERT INTO fisherlandscape (pixelid, den_p, rus_p, mov_p, cwd_p, cav_p, fisher_pop) 
                                            VALUES (:pixelid, :den_p, :rus_p, :mov_p, :cwd_p, :cav_p, :fisher_pop)"), sim$table.hab) 
    dbClearResult (rs)
    dbCommit (sim$clusdb)
  } else {
    sim$table.hab <- data.table (dbGetQuery (sim$clusdb, "SELECT * FROM fisherlandscape;"))
  }
  
  message ("Getting fisher habitat suitability data.")

  table.hab.init <- merge (sim$table.hab, 
                           data.table (dbGetQuery (sim$clusdb, "SELECT pixelid, age, crownclosure, qmd, basalarea, height FROM pixels WHERE compartid IS NOT NULL;")),
                           by.x = "pixelid",
                           by.y = "pixelid",
                           all.x = TRUE)
  
  # classify the habitat
  table.hab.init <- classifyHabitat (table.hab.init)
 
  # map the habitat to the raster
      # fisher population
  ras.fisher.pop <- terra::rast (sim$ras)
  ras.fisher.pop [] <- 0
  table.hab.init.fisher.pop <- table.hab.init [fisher_pop > 0, ]
  ras.fisher.pop [table.hab.init.fisher.pop$pixelid] <- table.hab.init.fisher.pop$fisher_pop 
    # denning
  ras.fisher.denning.init <- terra::rast (sim$ras)
  ras.fisher.denning.init [] <- 0
  table.hab.init.den <- table.hab.init [denning == 1, ]
  ras.fisher.denning.init [table.hab.init.den$pixelid] <- 1 
    # rust
  ras.fisher.rust.init <- terra::rast (sim$ras)
  ras.fisher.rust.init [] <- 0
  table.hab.init.rust <- table.hab.init [rust == 1, ]
  ras.fisher.rust.init [table.hab.init.rust$pixelid] <- 1 
    # cavity
  ras.fisher.cavity.init <- terra::rast (sim$ras)
  ras.fisher.cavity.init [] <- 0
  table.hab.init.cavity <- table.hab.init [cavity == 1, ]
  ras.fisher.cavity.init [table.hab.init.cavity$pixelid] <- 1 
    # cwd
  ras.fisher.cwd.init <- terra::rast (sim$ras)
  ras.fisher.cwd.init [] <- 0
  table.hab.init.cwd <- table.hab.init [cwd == 1, ]
  ras.fisher.cwd.init [table.hab.init.cwd$pixelid] <- 1
    # movement
  ras.fisher.movement.init <- terra::rast (sim$ras)
  ras.fisher.movement.init [] <- 0
  table.hab.init.movement <- table.hab.init [movement == 1, ]
  ras.fisher.movement.init [table.hab.init.movement$pixelid] <- 1
  
  # create a list of rasters (equivalent to a raster stack)
  sim$raster.stack <- c (ras.fisher.pop, ras.fisher.denning.init, ras.fisher.rust.init, ras.fisher.cavity.init, ras.fisher.cwd.init, ras.fisher.movement.init)
  names (sim$raster.stack) <- c ("ras_fisher_pop", "ras_fisher_denning_init", "ras_fisher_rust_init", "ras_fisher_cavity_init", "ras_fisher_cwd_init", "ras_fisher_movement_init")
  
  return (invisible (sim))
}



###--- Update Habitat
updateHabitat <- function (sim) {
  message ("Updating the fisher habitat...")
  
  # Update the habitat data in the territories
  table.hab.update <- merge (sim$table.hab, 
                             data.table (dbGetQuery (sim$clusdb, "SELECT pixelid, age, crownclosure, qmd, basalarea, height  FROM pixels;")),
                             by = "pixelid")
  table.hab.update <- classifyHabitat (table.hab.update)
  
  # Map the habitat to the raster
  # denning
  ras.fisher.denning <- terra::rast (sim$ras)
  ras.fisher.denning [] <- 0
  table.hab.den <- table.hab.update [denning == 1, ]
  ras.fisher.denning [table.hab.den$pixelid] <- 1 
  # rust
  ras.fisher.rust <- terra::rast (sim$ras)
  ras.fisher.rust [] <- 0
  table.hab.rust <- table.hab.update [rust == 1, ]
  ras.fisher.rust [table.hab.rust$pixelid] <- 1 
  # cavity
  ras.fisher.cavity <- terra::rast (sim$ras)
  ras.fisher.cavity [] <- 0
  table.hab.cavity <- table.hab.update [cavity == 1, ]
  ras.fisher.cavity [table.hab.cavity$pixelid] <- 1 
  # cwd
  ras.fisher.cwd <- terra::rast (sim$ras)
  ras.fisher.cwd [] <- 0
  table.hab.cwd <- table.hab.update [cwd == 1, ]
  ras.fisher.cwd [table.hab.cwd$pixelid] <- 1
  # movement
  ras.fisher.movement <- terra::rast (sim$ras)
  ras.fisher.movement [] <- 0
  table.hab.movement <- table.hab.update [movement == 1, ]
  ras.fisher.movement [table.hab.movement$pixelid] <- 1
  
  # create a list of rasters (equivalent to a raster stack)
  raster.stack.update <- c (ras.fisher.denning, ras.fisher.rust, ras.fisher.cavity, ras.fisher.cwd, ras.fisher.movement)
  names (raster.stack.update) <- c (paste0 ("ras_fisher_denning_", time(sim)*sim$updateInterval), 
                                    paste0 ("ras_fisher_rust_", time(sim)*sim$updateInterval), 
                                    paste0 ("ras_fisher_cavity_", time(sim)*sim$updateInterval),
                                    paste0 ("ras_fisher_cwd_", time(sim)*sim$updateInterval),
                                    paste0 ("ras_fisher_movement_", time(sim)*sim$updateInterval))
  sim$raster.stack <- c (sim$raster.stack, raster.stack.update)

  rm (raster.stack.update, table.hab.update)

  message ("Updating fisher habitat complete.")
  
  return (invisible (sim))
}



###---  Save
saveHabitat <- function (sim) {
  
  message ("Saving fisher habitat...")
  
  terra::writeRaster (x = sim$raster.stack, 
                      filename = paste0 (outputPath (sim), "/", sim$scenario$name, "_", sim$boundaryInfo[[3]][[1]],"_fisher_habitat.tif"), 
                      overwrite = TRUE)
  
  message ("Saving fisher habitat complete.")
  
  return (invisible (sim))
}


###--- FUNCTIONS THAT GET CALLED

classifyHabitat <- function (inputTable) {
  inputTable [den_p == 1 & age >= 125 & crownclosure >= 30 & qmd >=28.5 & basalarea >= 29.75, denning := 1][den_p == 2 & age >= 125 & crownclosure >= 20 & qmd >=28 & basalarea >= 28, denning := 1][den_p == 3 & age >= 135, denning:=1][den_p == 4 & age >= 207 & crownclosure >= 20 & qmd >= 34.3, denning:=1][den_p == 5 & age >= 88 & qmd >= 19.5 & height >= 19, denning:=1][den_p == 6 & age >= 98 & qmd >= 21.3 & height >= 22.8, denning:=1]
  inputTable [rus_p == 1 & age > 0 & crownclosure >= 30 & qmd >= 22.7 & basalarea >= 35 & height >= 23.7, rust:=1][rus_p == 2 & age >= 72 & crownclosure >= 25 & qmd >= 19.6 & basalarea >= 32, rust:=1][rus_p == 3 & age >= 83 & crownclosure >=40 & qmd >= 20.1, rust:=1][rus_p == 5 & age >= 78 & crownclosure >=50 & qmd >= 18.5 & height >= 19 & basalarea >= 31.4, rust:=1][rus_p == 6 & age >= 68 & crownclosure >=35 & qmd >= 17 & height >= 14.8, rust:=1]
  inputTable [cav_p == 1 & age > 0 & crownclosure >= 25 & qmd >= 30 & basalarea >= 32 & height >=35, cavity:=1][cav_p == 2 & age > 0 & crownclosure >= 25 & qmd >= 30 & basalarea >= 32 & height >=35, cavity:=1]
  inputTable [cwd_p == 1 & age >= 135 & qmd >= 22.7 & height >= 23.7, cwd:=1][cwd_p == 2 & age >= 135 & qmd >= 22.7 & height >= 23.7, cwd:=1][cwd_p == 3 & age >= 100, cwd:=1][cwd_p >= 5 & age >= 78 & qmd >= 18.1 & height >= 19 & crownclosure >=60, cwd:=1]
  inputTable [mov_p > 0 & age > 0 & crownclosure >= 40, movement:=1]
  inputTable <- inputTable [, .(pixelid, fisher_pop, den_p, denning, rus_p, rust, cav_p, cavity, 
                                  cwd_p, cwd, mov_p, movement)] # could add other things, openness, crown closure, cost surface?
  return (inputTable)
}


.inputObjects <- function (sim) {
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
  
  if (!suppliedElsewhere (ras)) { # empty raster object for defining the area of interest
    
    sim$ras <- RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), 
                         srcRaster = P (sim, "nameCompartmentRaster", "dataLoaderCLUS"), 
                         clipper = P (sim, "nameBoundaryFile", "dataLoaderCLUS" ), 
                         geom = P (sim, "nameBoundaryGeom", "dataLoaderCLUS"), 
                         where_clause =  paste0 ( P (sim, "nameBoundaryColumn", "dataLoaderCLUS"), " in (''", paste(P(sim, "nameBoundary", "dataLoaderCLUS"), sep = "' '", collapse= "'', ''") ,"'')"),
                         conn = NULL) 
  }
  
 
  
  # ! ----- STOP EDITING ----- ! #
  return(invisible(sim))
}

