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
library (data.table)
library (terra)
library (keyring)
library (tidyverse)
library (here)
library (stringr)
library (truncnorm)
library (RANN)
library(future)
library(future.callr)
library(future.apply)
library(parallel)

plan(callr)

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

plot_what_is_done <- function(counts) {
     for (kk in seq_along(counts)) {
         f <- counts[[kk]]
     
           ## Already plotted?
           if (!inherits(f, "Future")) next
     
         ## Not resolved?
         if (!resolved(f)) next
     
         # message(sprintf("Plotting tile #%d ...", kk))
         # counts[[kk]] <- value(f)
         # screen(kk)
         # plot(counts[[kk]])
       }
   
     counts
  }


run_iteration <- function(
    iteration,
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
  message(" ", iteration, appendLF = FALSE)
  future(
    {
      moduleDir <- file.path(paste0(here::here(), "/R/SpaDES-modules"))
      paths <- list(
        modulePath = paste0(here::here(),"/R/SpaDES-modules"),
        outputPath = paste0(here::here(),"/R/scenarios/fisher/outputs/", iteration)
      )
      
      times <- list (start = 0, end = 4)
      message(sprintf("Running iteration #%d of %d ...", iteration, 4), appendLF = FALSE)
      parameters <- list(FLEX = list (female_max_age = 9,
                                      den_target = 0.003, 
                                      rest_target = 0.028,
                                      move_target = 0.091,
                                      reproductive_age = 2, 
                                      sex_ratio = 0.5,
                                      female_dispersal = 785000,  # ha; radius = 500 pixels = 50km = 7850km2 area
                                      timeInterval = 5, # should be consistent with the time interval used to model habitat
                                      burnInLength = burn_in_length, 
                                      d2_target = d2_target,
                                      initialFisherPop = initial_fisher_pop,
                                      # e.g., growingstockLCUS periodLength
                                      # rasterHabitat = paste0 (here::here(), "/R/SpaDES-modules/FLEX/williston.tif")
                                      rasterHabitat = paste0 (here::here(), "/R/scenarios/fisher/inputs/scenario.tif")
                                      
      )
      )
      
      modules <- list ("FLEX")
      
      mySim <- simInit(times = times, 
                       params = parameters, 
                       modules = modules,
                       objects = list(scenario = data.table(name = "test")),
                       paths = paths)
      
      #outputs(mySim) <- data.frame (objectName = c("fisherABMReport"))
      mySimOut <- spades(mySim)
      message(" done")
    }, 
    lazy = TRUE
  )
}

# run_iteration(
#   times,
#   female_max_age,
#   den_target,
#   rest_target,
#   move_target,
#   reproductive_age,
#   sex_ratio,
#   female_dispersal,
#   time_interval,
#   burn_in_length,
#   d2_target,
#   initial_fisher_pop
# )

cores <- floor(parallel::detectCores() / 2)
# 
# r <- future_lapply(
counts <- lapply(
  # future.seed = TRUE,
  X = 1:cores,
  FUN = run_iteration,
  # mc.cores = cores,
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

repeat {
   counts <- plot_what_is_done(counts)
   # if (!any(sapply(counts, FUN = inherits, "Future"))) break
}

# counts <- lapply(
#   seq_along(Cs), 
#   FUN=function(ii) {
#     message(" ", ii, appendLF = FALSE)
#     C <- Cs[[ii]]
#     future(
#       {
#         message(sprintf("Calculating tile #%d of %d ...", ii, n), appendLF = FALSE)
#         fit <- mandelbrot(C)
#         
#         ## Emulate slowness
#         delay(fit)
#         
#         message(" done")
#         fit
#       }, 
#       lazy = TRUE
#     )
#   }
#   )

# 
# str(r)
# 
