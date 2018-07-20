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
# Everything in this file gets sourced during simInit, and all functions and objects
# are put into the simList. To use objects, use sim$xxx, and are thus globally available
# to all modules. Functions can be used without sim$ as they are namespaced, like functions
# in R packages. If exact location is required, functions will be: sim$<moduleName>$FunctionName
defineModule(sim, list(
  name = "harvestCLUS",
  description = NA, #"Simulates anthropegenic disturbance on a landscape, where spread probability is conditional on a economic decision space",
  keywords = NA, # c("harvesting, economics, human"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
  person("Tyler", "Muhley", email = "tyler.muhley@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.1.1", harvestCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c("2018-04-09", NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "harvestCLUS.Rmd"),
  reqdPkgs = list("ggplot2", "methods", "raster", "RColorBrewer"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter("nPatches", "numeric", 5L, 0L, 100L, desc = "Number of patches to initiate at each returnInterval"),
    defineParameter("harvestStatsName", "character", "nPixelsHarvested", NA, NA, desc = "Name for the harvest patch statistics object"),
    defineParameter("persistprob", "numeric", 0.00, 0.00, 1.00, desc = "Probability that a burning cell will continue burning for 1 iteration"),
    defineParameter("its", "numeric", 1e6, NA, NA, desc = "Maximum number of iterations for the spread algorithm"),
    defineParameter("startTime", "numeric", start(sim), NA, NA, desc = "Simulation time at which to initiate patches"),
    defineParameter("simulationTimeStep", "numeric", start(sim), NA, NA, desc = "This describes the simulation time step interval"),
    defineParameter("returnInterval", "numeric", 1.0, NA, NA, desc = "Time interval between fire events"),
    defineParameter(".plotInitialTime", "numeric", start(sim), NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", 1, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".saveInitialTime", "numeric", NA_real_, NA, NA, desc = "Initial time for saving"),
    defineParameter(".seed", "numeric", 1586, NA, NA, "Use this to get reproducible random numbers"),
    defineParameter(".useCache", "numeric", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput(objectName = c("landscape",params(sim)$harvestCLUS$harvestStatsName), objectClass = c("RasterStack", "character"), 
                 desc = c(NA,NA), sourceURL = c(NA,NA))
  ),
  outputObjects = data.frame(
    objectName = c("Patches", "PatchesCumul", "PatchSizeDistribution", params(sim)$harvestCLUS$harvestStatsName),
    objectClass = c("RasterLayer", "RasterLayer", "gg", "character"),
    other = rep(NA_character_, 4L), stringsAsFactors = FALSE)
))

## event types
#   - type `init` is required for initialiazation

doEvent.harvestCLUS = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    init = {
      ### check for more detailed object dependencies:
      ### (use `checkObject` or similar)
      checkObject(sim, name = "landscape")
      
      ## set seed
      set.seed(sim$.seed)
      
      #Clear global parameters
      sim[[P(sim)$harvestStatsName]] <- numeric()
      
      #Create a storage list of harvesting
      sim$harvestRasters <- list()
      # do stuff for this event
      sim <- harvestCLUSInit(sim)

      # schedule future event(s)
      # schedule the next event
      sim <- scheduleEvent(sim, P(sim)$startTime, "harvestCLUS", "harvest")
      sim <- scheduleEvent(sim, P(sim)$.saveInterval, "harvestCLUS", "save")
      sim <- scheduleEvent(sim, P(sim)$.plotInitialTime, "harvestCLUS", "plot.init")
    },
    harvest = {
      # do stuff for this event
      sim <- sim$harvestCLUSHarvest(sim)
      # schedule the next events
      sim <- scheduleEvent(sim, time(sim), "harvestCLUS", "stats") # do stats immediately following burn
      sim <- scheduleEvent(sim, time(sim) + P(sim)$returnInterval, "harvestCLUS", "harvest")
    },
    stats = {
      sim <- sim$harvestCLUSStats(sim)
    },
    
    plot.init = {
      plot(sim$PatchesCumul)
      sim <- scheduleEvent(sim, time(sim) + P(sim)$.plotInterval, "harvestCLUS", "plot.sim")
    },
    
    plot.sim = {
      # do stuff for this event
      plot(sim$PatchesCumul,zero.color = "white", legendRange = 0:sim$maxPatchesCumul,cols=c("orange", "darkred"))
      
      if (length(sim[[P(sim)$harvestStatsName]]) > 0) {
          nPixelsHarvested <- sim[[P(sim)$harvestStatsName]]
          
          binwidthRange <- pmax(1,diff(range(nPixelsHarvested*6.25))/30)
          sim$PatchSizeDistribution <- qplot(main = "", nPixelsHarvested*6.25,
                                            xlab = "Hectares", binwidth = binwidthRange)
          sim$PatchSizeDistribution <- sim$PatchSizeDistribution +
            theme(axis.text.x = element_text(size = 10, angle = 45, hjust = 1, colour = "black"),
                  axis.text.y = element_text(size = 10, colour = "black"),
                  axis.title.x = element_text(size = 12, colour = "black"),
                  axis.title.y = element_text(size = 12, colour = "black"))
          suppressMessages(Plot(sim$PatchSizeDistribution))
      }
      
      #Scehdule the next plot event
      sim <- scheduleEvent(sim, time(sim) + P(sim)$.plotInterval, "harvestCLUS", "plot.sim")
    },
    save = {
      sim <- saveFiles(sim)
      # schedule the next event
      sim <- scheduleEvent(sim, time(sim) + P(sim)$.saveInterval, "harvestCLUS", "save")
    },

    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

## event functions
#   - follow the naming convention `modulenameEventtype()`;
#   - `modulenameInit()` function is required for initiliazation;
#   - keep event functions short and clean, modularize by calling subroutines from section below.

#Initialize the disturbance map - creates a blank map from which to simulate disturbances
harvestCLUSInit <- function(sim) {
  ### create harvest map that tracks cutblock locations over time
  sim$maxPatchesCumul <- 7 #?????????????
  
  sim$Patches <- raster(extent(raster(sim$landscape,1)), ncol = ncol(raster(sim$landscape,1)),nrow = nrow(raster(sim$landscape,1)), vals = 0) %>% mask(raster(sim$landscape,1))
  ## set the colours for mapping
  setColors(sim$Patches, n = P(sim)$nPatches + 1) <-c("#FFFFFF", rev(heat.colors(P(sim)$nPatches)))
  sim$PatchesCumul <- sim$Patches
  return(invisible(sim))
}

#Simulates the harvesting of forest from the disturbance agent of interest
harvestCLUSHarvest <- function(sim) {
  #Get a spread probability map for the landscape ***TO DO: get logic for this. Right now - using some proxy of age? 
  patchSpreadProb <- reclassify(x = raster(sim$landscape,2) ,rcl = cbind(seq(0,110,10.1),seq(10,110,10), c(0, 0, 0, 0, 0.15,0.18, 0.21, 0.21, 0.35, 0.45, 0.5)))
  #Get a count from a poison distrubtion with lambda = to the mean patches specified by the user.
  nPatches <- rpois(1, P(sim)$nPatches)
  
  if(nPatches > 0){
      sim$Patches <- SpaDES.tools::spread(patchSpreadProb,
                                        #randomly select points from which to intitate the cutblocks
                                        loci = as.integer(sample(1:ncell(patchSpreadProb), nPatches)),
                                        spreadProb = patchSpreadProb,
                                        persistance = 0,
                                        mask = NULL,
                                        maxSize = 1e8,
                                        directions = 8,
                                        iterations = P(sim)$its,
                                        plot.it = FALSE,
                                        id = TRUE)
      
      sim$Patches[is.na(raster(sim$landscape,1))] <- NA
      names(sim$Patches) <- "Patches"
      setColors(sim$Patches, n = nPatches + 1) <- c("#FFFFFF", rev(heat.colors(nPatches)))
      
      sim$PatchesCumul[] <- sim$PatchesCumul[] + (sim$Patches[] > 0)
      setColors(sim$PatchesCumul) <- c(colorRampPalette(c("orange", "darkred"))(sim$maxPatchesCumul))
  }
  return(invisible(sim))
}

harvestCLUSStats <- function(sim) {
  npix <- sim[[P(sim)$harvestStatsName]]
  sim[[P(sim)$harvestStatsName]] <- c(npix, length(which(values(sim$Patches) > 0)))
  return(invisible(sim))
}


.inputObjects <- function(sim) {
  # Any code written here will be run during the simInit for the purpose of creating
  # any objects required by this module and identified in the inputObjects element of defineModule.
  # This is useful if there is something required before simulation to produce the module
  # object dependencies, including such things as downloading default datasets, e.g.,
  # downloadData("LCC2005", modulePath(sim)).
  # Nothing should be created here that does not create an named object in inputObjects.
  # Any other initiation procedures should be put in "init" eventType of the doEvent function.
  # Note: the module developer can use 'sim$.userSuppliedObjNames' in their function below to
  # selectively skip unnecessary steps because the user has provided those inputObjects in the
  # simInit call. e.g.,
  # if (!('defaultColor' %in% sim$.userSuppliedObjNames)) {
  #  sim$defaultColor <- 'red'
  # }
  # ! ----- EDIT BELOW ----- ! #
  
  ##Create an empty raster stack objected called landscape
  if(is.null(sim$landscape)){
    crs <- CRS("+proj=utm +zone=48 +datum=WGS84")
    ras = raster(extent(0, 500, 0, 500),res =1, vals =0, crs = crs )
    
    ###Use the SpaDES.tools function 
    ####Example creating a guassMap describing forest age
    forestAge <- gaussMap(ras, scale = 10, var = 0.1, speedup = 1)
    forestAge[] <- round(getValues(forestAge)/3, 1) * 110
    DEM <- gaussMap(ras, scale = 300, var = 0.03, speedup = 1)
    habitatQuality <- (DEM + 10 + (forestAge + 2.5) * 10) / 100
    
    ##Stack the raster
    sim$landscape<- stack(DEM, forestAge, habitatQuality)
    names(sim$landscape)<-c("DEM", "forestAge", "habitatQuality")
  }

  # ! ----- STOP EDITING ----- ! #
  return(invisible(sim))
}

