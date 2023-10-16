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
if (length(args) != 13) {
  stop("All arguments must be supplied.\n", call.=FALSE)
}

library (SpaDES.core)
library (SpaDES.tools)
library (SpaDES.experiment)
library (data.table)
library (terra)
library (keyring)
library (tidyverse)
library (here)
library (stringr)
library (truncnorm)
library (RANN)
library (raster)
# library(future)
# library(future.callr)
# library(future.apply)
library(parallel)

# plan(callr)

times <- as.numeric(args[1])
female_max_age <- as.numeric(args[2])
den_target <- as.numeric(args[3])
rest_target <- as.numeric(args[4])
move_target <- as.numeric(args[5])
reproductive_age <- as.numeric(args[6])
sex_ratio <- as.numeric(args[7])
female_dispersal <- as.numeric(args[8])
time_interval <- as.numeric(args[9])
burn_in_length <- as.numeric(args[10])
d2_target <- as.numeric(args[11])
initial_fisher_pop <- as.numeric(args[12])
appx <- as.numeric(args[13])

run_iteration <- function(
  cores,
  times,
  female_max_age,
  den_target,
  rest_target,
  move_target,
  reproductive_age,
  sex_ratio,
  female_dispersal,
  time_interval,
  burn_in_length,
  d2_target,
  initial_fisher_pop
) {
      moduleDir <- file.path(paste0(here::here(), "/R/SpaDES-modules"))
      paths <- list(
        modulePath = paste0(here::here(),"/R/SpaDES-modules"),
        outputPath = paste0(here::here(),"/R/scenarios/fisher/outputs")
      )
      
      times <- times - 1
      times <- list (start = 0, end = times)
      
      parameters <- list(
        FLEX = list(
          female_max_age = female_max_age,
          den_target = den_target, 
          rest_target = rest_target,
          move_target = move_target,
          reproductive_age = reproductive_age, 
          sex_ratio = sex_ratio,
          female_dispersal = female_dispersal,  # ha; radius = 500 pixels = 50km = 7850km2 area
          timeInterval = time_interval, # should be consistent with the time interval used to model habitat
          burnInLength = burn_in_length, 
          d2_target = d2_target,
          initialFisherPop = initial_fisher_pop,
          # e.g., growingstockLCUS periodLength
          # rasterHabitat = paste0 (here::here(), "/R/SpaDES-modules/FLEX/williston.tif")
          rasterHabitat = paste0 (here::here(), "/R/scenarios/fisher/inputs/scenario.tif")
        )
      )
      
      modules <- list ("FLEX")
      
      mySim <- simInit(
        times = times, 
        params = parameters, 
        modules = modules,
        objects = list(scenario = data.table(name = "test")),
        paths = paths
      )
      
      raster::beginCluster()
      experiment(mySim, replicates = cores)
      raster::endCluster()

      message(" done")
}

cores <- floor(parallel::detectCores())

run_iteration(
  cores,
  times,
  female_max_age,
  den_target,
  rest_target,
  move_target,
  reproductive_age,
  sex_ratio,
  female_dispersal,
  time_interval,
  burn_in_length,
  d2_target,
  initial_fisher_pop
)
