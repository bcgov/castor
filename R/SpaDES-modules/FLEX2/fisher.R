#!/usr/bin/env Rscript

stub <- function() {}
thisPath <- function() {
  cmdArgs <- commandArgs(trailingOnly = FALSE)
  if (length(grep("^-f$", cmdArgs)) > 0) {
    # R console option
    normalizePath(dirname(cmdArgs[grep("^-f", cmdArgs) + 1]))[1]
  } else if (length(grep("^--file=", cmdArgs)) > 0) {
    # Rscript/R console option
    scriptPath <- normalizePath(dirname(sub("^--file=", "", cmdArgs[grep("^--file=", cmdArgs)])))[1]
  } else if (Sys.getenv("RSTUDIO") == "1") {
    if (rstudioapi::isAvailable(version_needed=NULL,child_ok=FALSE)) {
      # RStudio interactive
      dirname(rstudioapi::getSourceEditorContext()$path)
    } else if (is.null(knitr::current_input(dir = TRUE)) == FALSE) {
      # Knit
      knitr::current_input(dir = TRUE)
    } else {
      # R markdown on RStudio
      getwd()
    }
  } else if (is.null(attr(stub, "srcref")) == FALSE) {
    # sourced via R console
    dirname(normalizePath(attr(attr(stub, "srcref"), "srcfile")$filename))
  } else {
    stop("Cannot find file path")
  }
}

setwd(thisPath())

args = commandArgs(trailingOnly = TRUE)
if (length(args) != 10) {
  stop("All arguments must be supplied.\n", call.=FALSE)
}

library (SpaDES.core)
library (data.table)
library (terra)
library (keyring)
library (tidyverse)
library (here)
library (stringr)
library (truncnorm)
library (RANN)
source (paste0 (here::here(), "/R/functions/R_Postgres.R"))

times <- as.numeric(args[1])
female_max_age <- as.numeric(args[2])
den_target <- as.numeric(args[3])
rest_target <- as.numeric(args[4])
move_target <- as.numeric(args[5])
reproductive_age <- as.numeric(args[6])
sex_ratio <- as.numeric(args[7])
female_dispersal <- as.numeric(args[8])
timeInterval <- as.numeric(args[9])
appx <- as.numeric(args[10])

moduleDir <- file.path(paste0(here::here(), "/R/SpaDES-modules"))
inputDir <- file.path(paste0(here::here(), "/R/scenarios/fisher/inputs")) %>% reproducible::checkPath (create = TRUE)
outputDir <- file.path(paste0(here::here(), "/R/scenarios/fisher/outputs/", appx)) %>% reproducible::checkPath (create = TRUE)
cacheDir <- file.path(paste0(here::here(), "/R/scenarios/fisher"))

times <- list (start = 0, end = times)

parameters <- list(FLEX2 = list (female_max_age = female_max_age,
                                 den_target = den_target,
                                 rest_target = rest_target,
                                 move_target = move_target,
                                 reproductive_age = reproductive_age,
                                 sex_ratio = sex_ratio,
                                 female_dispersal = female_dispersal,  # ha; radius = 500 pixels = 50km = 7850km2 area
                                 timeInterval = timeInterval, # should be consistent with the time interval used to model habitat
                                                    # e.g., growingstockLCUS periodLength
                                 iterations = 1, # not currently implemented
                                 rasterHabitat = paste0 (here::here(), "/R/scenarios/fisher/inputs/scenario.tif")

                )
)

scenario = data.table (name = "test",
                       description = "Testing fisher ABM.")

modules <- list ("FLEX2")

objects <- list (scenario = scenario)
inputs <- list ()
outputs <- data.frame (objectName = c())

paths <- list(cachePath = cacheDir,
              modulePath = moduleDir,
              inputPath = inputDir,
              outputPath = outputDir)

mySim <- simInit(times = times,
                 params = parameters,
                 modules = modules,
                 objects = objects,
                 paths = paths)

fisherSimOut <- spades(mySim)

# str(mySimOut)
# 
# mySimOut$ras.territories
# 
# mySimOut$fisherABMReport
# mySimOut$ras.territories
# plot(mySimOut$ras.territories)
# 
# agents <- mySimOut$agents
# territories <- mySimOut$territories
# 
# length(unique(territories$individual_id))
# length(unique(agents$individual_id))
# 
# agents %>% filter(!individual_id %in% unique(territories$individual_id))
# 
# hist(agents$age)
# 
# raster.file <- list.files("./R/scenarios/fisher/outputs")
# test <- terra::rast("./R/scenarios/fisher/outputs/test_final_fisher_territories.tif")
# 
# plot(test)
# mySimOut$agents %>% filter(d2_score>0)
# plot(mySimOut$ras.territories)
