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

# test
version$major
version$minor
R_version <- paste0("R-",version$major,".",version$minor)

.libPaths(paste0("C:/Program Files/R/",R_version,"/library")) # to ensure reading/writing libraries from C drive
tz = Sys.timezone() # specify timezone in BC

list.of.packages <- c("tidyverse", "data.table")
lapply(list.of.packages, require, character.only = TRUE)

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
    defineParameter("female_hr_table", "character", NA, NA, NA,
                    paste0("A table of mean and standard deviation of female fisher home range (territory) sizes in different habitat zones.",
                    "Table with the following headers:",
                    "FHE: the four Fisher Habitat Extension zones: Boreal, Dry Forest, Sub-Boreal moist, Sub-Boreal dry",
                    "Mean_Area_km2: the mean area for female fisher home ranges in km2 for each FHE", 
                    "SD_Area_km2: the sd for female fisher home ranges in km2 for each FHE")),    
    defineParameter("female_max_age", "numeric", 9, 0, 15,
                    "The maximum possible age of a female fisher. Taken from research referenced by Roray Fogart in VORTEX_inputs_new.xlsx document."), 
    defineParameter("female_search_radius", "numeric", 5, 0, 100,
                    "The maximum search radius, in km, that a female fisher could ‘search’ to establish a territory."), 
    defineParameter("den_target", "numeric", 0.10, 0.003, 0.54,
                    "The minimum proportion of a home range that is denning habitat. Values taken from empirical female home range data across populations."), 
    defineParameter("rest_target", "numeric", 0.26, 0.028, 0.58,
                    "The minimum proportion of a home range that is resting habitat. Values taken from empirical female home range data across populations."),   
    defineParameter("move_target", "numeric", 0.36, 0.091, 0.73,
                    "The minimum proportion of a home range that is movement habitat. Values taken from empirical female home range data across populations."), 
    defineParameter("survival_rate_table", "character", NA, NA, NA,
                    paste0("Table of fisher survial rates by sex, age and population, taken from Lofroth et al 2022 JWM vital rates manuscript.",
                           "Table with the following headers:",
                           "Fpop: the two populations in BC: Boreal, Coumbian",
                           "Age_class: two classes: Adult, Juvenile",
                           "Cohort: Fpop and Age_class combination: CFA, CFJ, BFA, BFJ",
                           "Mean: mean survival probability",
                           "SE: standard error of the mean",
                           "Decided to go with SE rather than SD as confidence intervals are quite wide and stochasticity would likely drive populations to extinction. Keeping consistent with Rory Fogarty's population analysis decisions.")),
    defineParameter("d2_reproduction_adj", "function", NA, NA, NA,
                    "Function relating habitat quality to reproductive rate."),
    defineParameter("repro_rate_table", "character", NA, NA, NA,
                    paste0("Table of fisher reproductive rates (i.e., denning rate = a combination of pregnancy rate and birth rate; and litter size = number of kits) by population, taken from Lofroth et al 2022 JWM vital rates manuscript",
                           "Table with the following headers:",
                           "Fpop: the two populations in BC: Boreal, Coumbian",
                           "Param: the reproductive parameter: DR (denning rate), LS (litter size)",
                           "Mean: mean reproductive rate per parameter and population",
                           "SD: reproductive rate standard deviation value per parameter and population")),
    defineParameter("mahal_metric_table", "character", NA, NA, NA,
                    paste0("Table of mahalanobis D2 values based on Fisher Habitat Extension zones, provided by Rich Weir summer 2022",
                           "Table with the following headers:",
                           "FHE_zone: the four fisher habitat extension zones: Boreal, Sub-Boreal moist, Sub-Boreal dry, Dry Forest",
                           "FHE_zone_num: the corresponding FHE_zone number: Boreal = 1, Sub-Boreal moist = 2, Sub-Boreal Dry = 3, Dry Forest = 4",
                           "Mean: mean mahalanobis D2 value per FHE zone",
                           "SD: mahalanobis D2 standard deviation value per FHE zone",
                           "Max: maximum mahalanobis D2 value per FHE zone")),
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
 
      sim <- Init (sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "timeInterval", "fisherabmCLUS"), "fisherabmCLUS", "interpolatehabitat", 19)

    },
   
    interpolatehabitat = {
      
      # need some functions here to interpolate habitat degradation/improvement over the forestry simulation interval (five years)
      # the reproduce, etc. functions should happen annually, but the forestry sim interval will likely be > 1 year
      # we don't want to take the habitat at the start or end of the interval to estimate reproduction, etc.
      # because it would over or underestimate those values over the interval period
      # instead, we could calc the mid-point between the start and end as the habitat score
      #  this would 'smooth' the habitat effects over a five year period, probably returning more realistic results
      
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
      sim <- scheduleEvent (sim, time(sim), "fisherabmCLUS", "disperse", 22)
      # ! ----- STOP EDITING ----- ! #
    },
    
    disperse = {
      # ! ----- EDIT BELOW ----- ! #
      sim <- dispersal (sim)
      sim <- scheduleEvent (sim, time(sim), "fisherabmCLUS", "survive", 23)   
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
      sim <- scheduleEvent (sim, time(sim) + P(sim, "timeInterval", "fisherabmCLUS"), "fisherabmCLUS", "reproduce", 24)
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
  
  message ("Get the area of interest ...")
  # get the aoi raster
  aoi <- RASTER_CLIP2 (tmpRast = paste0('temp_', sample(1:10000, 1)), 
                           srcRaster = P (sim, "nameCompartmentRaster", "dataLoaderCLUS"), 
                           clipper = P (sim, "nameBoundaryFile", "dataLoaderCLUS" ), 
                           geom = P (sim, "nameBoundaryGeom", "dataLoaderCLUS"), 
                           where_clause =  paste0 ( P (sim, "nameBoundaryColumn", "dataLoaderCLUS"), " in (''", paste(P(sim, "nameBoundary", "dataLoaderCLUS"), sep = "' '", collapse= "'', ''") ,"'')"),
                           conn = NULL) 

  # get pixel id's for aoi 
  pix.for.rast <- data.table (dbGetQuery (sim$clusdb, "SELECT pixelid FROM pixels WHERE compartid IS NOT NULL;"))
  pix.rast <- aoi
  pix.rast [pix.for.rast$pixelid] <- pix.for.rast$pixelid
  sim$pix.rast <- pix.rast

  message ("Get the habitat data ...")
  # get the fisher habitat areas
  table.hab <- data.table (pixelid = sim$pix.rast[],
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
                                                  conn = NULL)[])
  #  identify which population a pixel is in
  fisher.pop <- getSpatialQuery(paste0("SELECT pop,  ST_Intersection(aoi.",sim$boundaryInfo[[4]],", fisher_zones.wkb_geometry) FROM 
                                       (SELECT ",sim$boundaryInfo[[4]]," FROM ",sim$boundaryInfo[[1]]," where ",sim$boundaryInfo[[2]]," in('", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "', '") ,"') ) as aoi 
                                       JOIN fisher_zones ON ST_Intersects(aoi.",sim$boundaryInfo[[4]],", fisher_zones.wkb_geometry)"))
  table.hab$fisher_pop <- fasterize::fasterize (sf = fisher.pop, raster = sim$pix.rast, field = "pop")[]
  #---VAT for populations: 1 = Boreal; 2 = SBS-wet; 3 = SBS-dry; 4 = Dry Forest

  table.hab <- table.hab [!is.na (pixelid), ] # remove pixels outside of the aoi
  table.hab <- merge (table.hab, # add the habitat characteristics
                      data.table (dbGetQuery(sim$clusdb, "SELECT pixelid, age, crownclosure, qmd, basalarea, height  FROM pixels;")),
                      by = "pixelid")
  # classify the habitat
  table.hab [den_p == 1 & age >= 125 & crownclosure >= 30 & qmd >=28.5 & basalarea >= 29.75, denning := 1][den_p == 2 & age >= 125 & crownclosure >= 20 & qmd >=28 & basalarea >= 28, denning := 1][den_p == 3 & age >= 135, denning:=1][den_p == 4 & age >= 207 & crownclosure >= 20 & qmd >= 34.3, denning:=1][den_p == 5 & age >= 88 & qmd >= 19.5 & height >= 19, denning:=1][den_p == 6 & age >= 98 & qmd >= 21.3 & height >= 22.8, denning:=1]
  table.hab [rus_p == 1 & age > 0 & crownclosure >= 30 & qmd >= 22.7 & basalarea >= 35 & height >= 23.7, rust:=1][rus_p == 2 & age >= 72 & crownclosure >= 25 & qmd >= 19.6 & basalarea >= 32, rust:=1][rus_p == 3 & age >= 83 & crownclosure >=40 & qmd >= 20.1, rust:=1][rus_p == 5 & age >= 78 & crownclosure >=50 & qmd >= 18.5 & height >= 19 & basalarea >= 31.4, rust:=1][rus_p == 6 & age >= 68 & crownclosure >=35 & qmd >= 17 & height >= 14.8, rust:=1]
  table.hab [cav_p == 1 & age > 0 & crownclosure >= 25 & qmd >= 30 & basalarea >= 32 & height >=35, cavity:=1][cav_p == 2 & age > 0 & crownclosure >= 25 & qmd >= 30 & basalarea >= 32 & height >=35, cavity:=1]
  table.hab [cwd_p == 1 & age >= 135 & qmd >= 22.7 & height >= 23.7, cwd:=1][cwd_p == 2 & age >= 135 & qmd >= 22.7 & height >= 23.7, cwd:=1][cwd_p == 3 & age >= 100, cwd:=1][cwd_p >= 5 & age >= 78 & qmd >= 18.1 & height >= 19 & crownclosure >=60, cwd:=1]
  table.hab [mov_p > 0 & age > 0 & crownclosure >= 40, movement:=1]
  table.hab <- table.hab [, .(pixelid, fisher_pop, den_p, denning, rus_p, rust, cav_p, cavity, 
                              cwd_p, cwd, mov_p, movement)] # could add other things, openness, crown closure, cost surface?
  # sim$table.hab <- table.hab [denning != "" | rust != "" | cavity != "" | cwd != "" | movement != "", ]

  message ("Create agents table and assign values...")
  # assign agents to denning pixels
    # systematic method
      # this provides a 'buffer' between pixels to allow some space for fisher to form an HR; 
      # if they are too close then it forms fewer HRs
    den.pix <- as.data.table (table.hab [denning == 1 & !is.na (fisher_pop), pixelid])
    den.pix.sample <- den.pix [seq (1, nrow (den.pix), 50), ] # grab every ~50th pixel; ~1 pixel every 5km
    ids <- seq (from = 1, to = nrow (den.pix.sample), by = 1)
    agents <- data.table (individual_id = ids,
                          sex = "F",
                          age = sample (1:P(sim, "female_max_age", "fisherabmCLUS"), length (ids), replace = T), # randomly draw ages between 1 and the max age,
                          pixelid = den.pix.sample$V1,
                          hr_size = numeric (),
                          d2_score = numeric ())

    # user-defined method; allow user to pick the # of agents
      # ids <- seq (from = 1, to = P(sim, "n_females", "fisherabmCLUS"), by = 1) # sequence of individual id's from 1 to n_females
      # agents <- data.table (individual_id = ids, 
      #                       sex = "F", 
      #                       age = sample (1:P(sim, "max_age", "fisherabmCLUS"), length (ids), replace = T), # randomly draw ages between 1 and the max age, 
      #                       pixelid = numeric (), 
      #                       hr_size = numeric (),
      #                       d2_score = numeric ())
      # 
      # assign a random starting location that is a denning pixel in population range
      # agents$pixelid <- sample (table.hab [denning == 1 & !is.na (fisher_pop), pixelid], length (ids), replace = T)

  # assign the population ID
  agents <- merge (agents, table.hab [ , c("pixelid", "fisher_pop")], 
                   by = "pixelid", all.x = T)
  # assign an HR size based on population
  agents [fisher_pop == 1, hr_size := round (rnorm (nrow (agents [fisher_pop == 1, ]), sim$female_hr_table [fisher_pop == 1, hr_mean], sim$female_hr_table [fisher_pop == 1, hr_sd]))]
  agents [fisher_pop == 2, hr_size := round (rnorm (nrow (agents [fisher_pop == 2, ]), sim$female_hr_table [fisher_pop == 2, hr_mean], sim$female_hr_table [fisher_pop == 2, hr_sd]))]
  agents [fisher_pop == 3, hr_size := round (rnorm (nrow (agents [fisher_pop == 3, ]), sim$female_hr_table [fisher_pop == 3, hr_mean], sim$female_hr_table [fisher_pop == 3, hr_sd]))]
  agents [fisher_pop == 4, hr_size := round (rnorm (nrow (agents [fisher_pop == 4, ]), sim$female_hr_table [fisher_pop == 4, hr_mean], sim$female_hr_table [fisher_pop == 4, hr_sd]))]

  message ("Create territories ...")
  # assign agents to territories table
  territories <- data.table (individual_id = agents$individual_id, 
                             pixelid = agents$pixelid)
  
  # create spread probability raster
  # currently uses all denning, rust, cavity, cwd and movement habitat as 
  # spreadProb = 1, and non-habitat as spreadProb = 0.10; allows some spread to sub-optimal habitat
  table.hab [denning == 1 | rust == 1 | cavity == 1 | cwd == 1 | movement == 1, spreadprob := format (round (1.00, 2), nsmall = 2)]
  table.hab [is.na (spreadprob), spreadprob := format (round (0.18, 2), 2)] # I tested different numbers
                                                                            # 18% resulted in the mean proportion of home ranges consisting of denning, resting or movement habitat as 55%; 19 was 49%; 17 was 59%; 20 was 47%; 15 was 66%
                                                                            # Caution: this parameter may be area-specific and may need to be and need to be 'tuned' for each AOI
  # if non-habitat spreadprob
  spread.rast <- sim$pix.rast
  spread.rast [table.hab$pixelid] <- table.hab$spreadprob
  sim$spread.rast <- spread.rast

  # this step took 15 mins with ~8500 starting points; 6 mins for 2174 points; 1 min for 435 points
  table.hr <- SpaDES.tools::spread2 (sim$pix.rast, # within the area of interest
                                     start = agents$pixelid, # for each individual
                                     spreadProb = sim$spread.rast, # use spread prob raster
                                     exactSize = agents$hr_size, # spread to the size of their territory
                                     allowOverlap = F, # no overlap allowed
                                     asRaster = F, # output table
                                     # returnDistances = T, # not working; see below
                                     circle = F) # spread to adjacent cells
    
  # calc distance between each pixel and the denning site
      # not sure if we need this; keeping it here in case we need it
  # table.hr <- cbind (table.hr, xyFromCell (sim$pix.rast, table.hr$pixels))
  # table.hr [!(pixels %in% agents$pixelid), dist := RANN::nn2 (table.hr [pixels %in% agents$pixelid, c("x","y")], table.hr [!(pixels %in% agents$pixelid), c("x","y")], k = 1)$nn.dists]
  # table.hr [is.na (dist), dist := 0]

  # add individual id and habitat
  table.hr <- merge (merge (table.hr,
                            agents [, c ("pixelid", "individual_id")],
                            by.x = "initialPixels", by.y = "pixelid"), 
                     table.hab [, c ("pixelid", "denning", "rust", "cavity", "cwd", "movement")],
                     by.x = "pixels", by.y = "pixelid")

  # check to see if home range target was met; if not, remove the animal 
  table.hr [, pix.count := sum (length (pixels)), by = individual_id]
  pix.count <- merge (agents [, c ("pixelid", "individual_id", "hr_size")],
                      table.hr [, c ("pixels", "pix.count")],
                      by.x = "pixelid", by.y = "pixels",
                      all.x = T)
  for (i in pix.count$individual_id) { # for each individual
    if ( pix.count [individual_id == i, pix.count] >= pix.count [individual_id == i, hr_size]) { 
      # if it achieves its home range size and minimum habitat targets 
      # do nothing; we need to check if it meets min. habitat criteria (see below)
    } else {
      # delete the individual from the agents and territories table
      territories <- territories [individual_id != i] 
      agents <- agents [individual_id != i]
    } 
  }

  # check to see if minimum habitat target was met (prop habitat = 0.15); if not, remove the animal 
  hab.count <- table.hr [denning == 1 | rust == 1 | cwd == 1 | movement == 1, .(.N), by = individual_id]
  hab.count <- merge (hab.count,
                      agents [, c ("hr_size", "individual_id")],
                      by = "individual_id")
  hab.count$prop_hab <- hab.count$N / hab.count$hr_size
  for (i in hab.count$individual_id) { # for each individual
    if ( hab.count [individual_id == i, prop_hab] >= 0.15) { 
      # if it achieves its home range size and minimum habitat targets 
      # do nothing; we still need to check if it meets min. habitat criteria (see below)
    } else {
      # delete the individual from the agents and territories table
      territories <- territories [individual_id != i] 
      agents <- agents [individual_id != i]
    } 
  }

        #  remove pixels if already occupied
          # not used, but keeping here if we need it later
            # search.temp <- merge (search.temp, territories, 
            #                       by.x = "pixels", by.y = "pixelid", all.x = T)
            # search.temp <- search.temp [is.na (individual_id) | individual_id == (agents [pixelid == i, individual_id]), ]
  
  
  # check if proportion of habitat types are greater than the minimum thresholds 
  for (i in agents$individual_id) { # for each individual
    if (P(sim, "rest_target", "fisherabmCLUS") <= (nrow (table.hr [individual_id == i & rust == 1]) + nrow (table.hr [individual_id == i & cwd == 1])) / agents [individual_id == i, hr_size] & P(sim, "move_target", "fisherabmCLUS") <= nrow (table.hr [individual_id == i & movement == 1]) / agents [individual_id == i, hr_size] & P(sim, "den_target", "fisherabmCLUS") <= nrow (table.hr [individual_id == i & denning == 1]) / agents [individual_id == i, hr_size]
    ) {
      # check to see it meets all thresholds
      # assign the pixels to territories table
      territories <- rbind (territories, table.hr [individual_id == i, .(pixelid = pixels, individual_id)]) 
    } else {
      # delete the individual from the agents and territories table
      territories <- territories [individual_id != (agents [individual_id == i, individual_id]), ] 
      agents <- agents [individual_id != i]
    } 
  }
  
    # write the territories table
    if(nrow(dbGetQuery(sim$clusdb, "SELECT name FROM sqlite_schema WHERE type ='table' AND name = 'territories';")) == 0){
      # if the table exists, write it to the db
      DBI::dbWriteTable (sim$clusdb, "territories", territories, append = FALSE, 
                         row.names = FALSE, overwite = FALSE)  
    } else {
      # if the table exists, append it to the table in the db
      DBI::dbWriteTable (sim$clusdb, "territories", territories, append = TRUE, 
                         row.names = FALSE, overwite = FALSE)  
    }

  #---Calculate D2 (Mahalanobis) 
    # try to make this part into a function....
  message ("Calculate habitat quality.")
  
  # identify which fisher pop an animal belongs to
  terr.pop <- merge (territories, table.hab [, c ("pixelid", "fisher_pop")], 
                      by = "pixelid", all.x = T)
  # get the mean of pixels pop. values, rounded to get the majority; majority = pop membership
  terr.pop [, fisher_pop := .(round (mean (fisher_pop, na.rm = T), digits = 0)), by = individual_id] 
  terr.pop <- unique (terr.pop [, c ("individual_id", "fisher_pop")])
  agents <- merge (agents [, -c ("fisher_pop")], # assign new fisher_pop to agents table
                   terr.pop [, c ("individual_id", "fisher_pop")], 
                   by = "individual_id", all.x = T)
  
  # get habitat for mahalanobis
  tab.mahal <- merge (territories, 
                      table.hab [, c ("pixelid", "denning", "rust", "cavity", "movement", "cwd")], 
                      by = "pixelid", all.x = T)
  # % of each habitat by territory
  tab.perc <- Reduce (function (...) merge (..., all = TRUE, by = "individual_id"), 
                      list (tab.mahal [, .(den_perc = ((sum (denning, na.rm = T)) / .N) * 100), by = individual_id ], 
                            tab.mahal [, .(rust_perc = ((sum (rust, na.rm = T)) / .N) * 100), by = individual_id ], 
                            tab.mahal [, .(cav_perc = ((sum (cavity, na.rm = T)) / .N) * 100), by = individual_id ], 
                            tab.mahal [, .(move_perc = ((sum (movement, na.rm = T)) / .N) * 100), by = individual_id ], 
                            tab.mahal [, .(cwd_perc = ((sum (cwd, na.rm = T)) / .N) * 100), by = individual_id ]))
  
  # add pop id
  tab.perc <- merge (tab.perc, 
                     agents [, c ("individual_id", "fisher_pop")],
                     by = "individual_id", all.x = T)
  # log transform the data
  tab.perc [fisher_pop == 2 & den_perc >= 0, den_perc := log (den_perc + 1)][fisher_pop == 1 & cav_perc >= 0, cavity := log (cav_perc + 1)] # sbs-wet
  tab.perc [fisher_pop == 3 & den_perc >= 0, den_perc := log (den_perc + 1)]# sbs-dry
  tab.perc [fisher_pop == 1 | fisher_pop == 4 & rust_perc >= 0, rust_perc := log (rust_perc + 1)] #boreal and dry
  
  # truncate at the center plus one st dev
  stdev_pop1 <- sqrt (diag (fisher_d2_cov[[1]])) # boreal
  stdev_pop2 <- sqrt (diag (fisher_d2_cov[[2]])) # sbs-wet
  stdev_pop3 <- sqrt (diag (fisher_d2_cov[[3]])) # sbs-dry
  stdev_pop4 <- sqrt (diag (fisher_d2_cov[[4]])) # dry

  tab.perc [fisher_pop == 1 & den_perc > 24  + stdev_pop1[1], den_perc := 24 + stdev_pop1[1]][fisher_pop == 1 & rust_perc > 2.2 + stdev_pop1[2], rust_perc := 2.2 + stdev_pop1[2]][fisher_pop == 1 & cwd_perc > 17.4 + stdev_pop1[3], cwd_perc := 17.4 + stdev_pop1[3]][fisher_pop == 1 & move_perc > 56.2 + stdev_pop1[4], move_perc := 56.2 + stdev_pop1[4]]
  tab.perc [fisher_pop == 2 & den_perc > 1.6 + stdev_pop2[1], den_perc := 1.6 + stdev_pop2[1]][fisher_pop == 2 & rust_perc > 36.2 + stdev_pop2[2], rust_perc := 36.2 + stdev_pop2[2]][fisher_pop == 2 & cav_perc > 0.7 + stdev_pop2[3], cav_perc := 0.7 + stdev_pop2[3]][fisher_pop == 2 & cwd_perc > 30.4 + stdev_pop2[4], cwd_perc := 30.4 + stdev_pop2[4]][fisher_pop == 2 & move_perc > 26.8 + stdev_pop2[5], move_perc := 26.8+ stdev_pop2[5]]
  tab.perc [fisher_pop == 3 & den_perc > 1.2 + stdev_pop3[1], den_perc := 1.2 + stdev_pop3[1]][fisher_pop == 3 & rust_perc > 19.1 + stdev_pop3[2], rust_perc := 19.1 + stdev_pop3[2]][fisher_pop == 3 & cav_perc > 0.5 + stdev_pop3[3], cav_perc := 0.5 + stdev_pop3[3]][fisher_pop == 3 & cwd_perc > 10.2 + stdev_pop3[4], cwd_perc := 10.2 + stdev_pop3[4]][fisher_pop == 3 & move_perc > 33.1 + stdev_pop3[5], move_perc := 33.1+ stdev_pop3[5]]
  tab.perc [fisher_pop == 4 & den_perc > 2.3 + stdev_pop4[1], den_perc := 2.3 + stdev_pop4[1]][fisher_pop == 4 & rust_perc > 1.6 +  stdev_pop4[2], rust_perc := 1.6  + stdev_pop4[2]][fisher_pop == 4 & cwd_perc > 10.8 + stdev_pop4[3], cwd_perc := 10.8 + stdev_pop4[3]][fisher_pop == 4 & move_perc > 21.5 + stdev_pop4[4], move_perc := 21.5+ stdev_pop4[4]]

  #-----D2
  tab.perc [fisher_pop == 1, d2 := mahalanobis (tab.perc [fisher_pop == 1, c ("den_perc", "rust_perc", "cwd_perc", "move_perc")], c(24.0, 2.2, 17.4, 56.2), cov = sim$fisher.d2.cov[[4]])]
  tab.perc [fisher_pop == 2, d2 := mahalanobis (tab.perc [fisher_pop == 2, c ("den_perc", "rust_perc", "cav_perc", "cwd_perc", "move_perc")], c(1.6, 36.2, 0.7, 30.4, 26.8), cov = fisher_d2_cov[[2]])]
  tab.perc [fisher_pop == 3, d2 := mahalanobis (tab.perc [fisher_pop == 3, c ("den_perc", "rust_perc", "cav_perc", "cwd_perc", "move_perc")], c(1.16, 19.1, 0.45, 8.69, 33.06), cov = fisher_d2_cov[[3]])]
  tab.perc [fisher_pop == 4, d2 := mahalanobis (tab.perc [fisher_pop == 4, c ("den_perc", "rust_perc", "cwd_perc", "move_perc")], c(2.3, 1.6, 10.8, 21.5), cov = fisher_d2_cov[[4]])]

  agents <- merge (agents [, - ('d2_score')],
                   tab.perc [, .(individual_id, d2_score = d2)],
                   by = "individual_id")
  
  # write the agents table
  if(nrow(dbGetQuery(sim$clusdb, "SELECT name FROM sqlite_schema WHERE type ='table' AND name = 'agents';")) == 0){
    # if the table exists, write it to the db
    DBI::dbWriteTable (sim$clusdb, "agents", agents, append = FALSE, 
                       row.names = FALSE, overwite = FALSE)  
  } else {
    # if the table exists, append it to the table in the db
    DBI::dbWriteTable (sim$clusdb, "agents", agents, append = TRUE, 
                       row.names = FALSE, overwite = FALSE)  
  }
  message ("Initial territories created!")
  return (invisible (sim))
}

###--- SURVIVE
# create a function that runs each year to determine the probability of a fisher surviving to the next year
# also need to kill off any fishers that are over the max age for females (default = 9) or having been dispersing for 2 years

survive_FEMALE <- function(sim){
  
  # Fpop="C",
  # female_max_age=9

  # using 'dummy' tables (only necessary while working through function)
  # territories <- data.table(individual_id = rep(seq_len(5),each=5),
  #                           pixelid = 1:25)
  # 
  # agents <- data.table(individual_id = 1:5,
  #                      sex = "F",
  #                      age = sample(2:8, 5, replace=T),
  #                      pixelid = c(1,6,11,16,21),
  #                      hr_size = rnorm(5, mean=28, sd=14),
  #                      d2_score = rnorm(5, mean=4, sd=1))
  
  # pull in survival table (only necessary while working through function)
  survival_rate_table <- read.csv("R/SpaDES-modules/fisherabmCLUS/data/surv_rate_table_08Aug2022.csv")
  
  # delete the individuals older than max female age from the agents and territories table
  agents <- dbGetQuery (sim$clusdb, "SELECT * from agents;")
  territories <- dbGetQuery (sim$clusdb, "SELECT * from territories;")
  agents <- agents [age < P(sim, "female_max_age", "fisherabmCLUS"), ] # this is the data.table way to filter
  territories <- territories %>% filter(individual_id %in% agents$individual_id)
  
  # have age 1 = juvenile, 2+ = adult (cannot die if 0)
  # use rbinom with lower = mean - SE, upper = mean + SE
  
  # create temp table of fishers that need to survive (i.e., fishers < 1 cannot die)
  yoyFishers <- agents %>% filter(age==0) # young of year fishers - need this later to rbind with new agents table
  
  survFishers <- agents %>% filter(age > 0)
  survFishers <- survFishers %>% mutate(age_class = case_when(age<2 ~ "J", age>=2 ~ "A"))
  
  survFishers$Cohort <- toupper(paste0(rep(Fpop,times=nrow(survFishers)),rep("F",times=nrow(survFishers)),survFishers$age_class))
  survFishers <- left_join(survFishers,survival_rate_table,by=c("Cohort"))
  
  # increase the likelihood of older fishers to die, similar to age distribution figures / data from Rory Fogarty
  survFishers <- survFishers %>% mutate(LSE = case_when(age_class=="J" ~ Mean-(1*SE),
                                                        age_class=="A" & age < 4 ~ Mean-(1*SE),
                                                        age_class=="A" & age < 7 ~ Mean-(2*SE),
                                                        age_class=="A" & age >= 7 ~ Mean-(3*SE)))
  
  survFishers <- survFishers %>% mutate(HSE = case_when(age_class=="J" ~ Mean+(1*SE),
                                                        age_class=="A" & age < 4 ~ Mean+(1*SE),
                                                        age_class=="A" & age >= 4 ~ Mean+(2*SE)))
  
  survFishers$HSE <- ifelse(survFishers$HSE>1,1,survFishers$HSE)
  
  survFishers$live <- NA
  for(i in 1:nrow(survFishers)){
    survFishers[i,]$live <- rbinom(n=1, size=1, prob=(survFishers[i,]$Mean-survFishers[i,]$SE):round(survFishers[i,]$Mean+survFishers[i,]$SE))
  }
  
  liveFishers <- survFishers %>% filter(live==1) # the fishers who have survived
  
  # delete the individuals who did not survive from the agents table and the territories table
  agents <- agents %>% filter(individual_id %in% liveFishers$individual_id)
  agents <- rbind(agents, yoyFishers)
  territories <-territories %>% filter(individual_id %in% agents$individual_id)
  
  # allowing kits to survive even if mothers die as by 1 year kits able to live in territory without mom
  # need to still deal with juveniles who are dispersing
  old.dispersers <- agents %>% filter(!individual_id %in% territories$individual_id & age > 1) # fishers > 2 who aren't established
  agents <- agents %>% filter(!individual_id %in% old.dispersers$individual_id)
  
  # all remaining fishers will age 1 year
  agents$age <- agents$age +1
  
  return(invisible(sim))
}


###--- REPRODUCE
repro_FEMALE <- function(sim) {
  
  # Fpop="B",
  # FHE = "Boreal" # this will come in from raster pixel that corresponds to the pixelid for each individual
  # using 'dummy' tables (only necessary while working through function)
  # territories <- data.table(individual_id = rep(seq_len(5),each=5),
  #                           pixelid = 1:25)
  # 
  # agents <- data.table(individual_id = 1:5,
  #                      sex = "F",
  #                      age = sample(2:8, 5, replace=T),
  #                      pixelid = c(1,6,11,16,21),
  #                      hr_size = rnorm(5, mean=28, sd=14),
  #                      d2_score = rnorm(5, mean=4, sd=1))
  
  # pull in survival table (only necessary while working through function)
  repro_rate_table <- read.csv("R/SpaDES-modules/fisherabmCLUS/data/repro_rate_table_08Aug2022.csv")
  mahal_metric_table <- read.csv("R/SpaDES-modules/fisherabmCLUS/data/mahal_metric_09Aug2022.csv")
  female_hr_table <- read.csv("R/SpaDES-modules/fisherabmCLUS/data/Fisher_HR_mean_sd_km_08Aug2022.csv")
  
  CI_from_meanSDn <- function(mean=mean, sd=sd, n=n, alpha=0.05){
    sample.mean <- mean
    # print(sample.mean)
    
    sample.n <- n
    sample.sd <- sd
    sample.se <- sample.sd/sqrt(sample.n)
    # print(sample.se)
    
    alpha <- alpha
    degrees.freedom = sample.n - 1
    t.score = qt(p=alpha/2, df=degrees.freedom,lower.tail=F)
    # print(t.score)
    
    margin.error <- t.score * sample.se
    lower.bound <- sample.mean - margin.error
    upper.bound <- sample.mean + margin.error
    # print(c(lower.bound,upper.bound))
    
    return(c(lower.bound, upper.bound))
  }
  
  fisher.pop = Fpop # work around to deal with different usage of Fpop (full name or initial)
  
  # determine which individuals will reproduce this year
  reproFishers <- agents %>% filter(age > 1) # female fishers capable of reproducing
  
  if (length(reproFishers) > 0) {
    
    
    # assign each female fisher 1 = reproduce or 0 = does not reproduce
    DR <- repro_rate_table %>% dplyr::filter(str_detect(Fpop, fisher.pop)) %>% dplyr::filter(str_detect(Param,"DR"))
    DR_CIs <- CI_from_meanSDn(mean=DR$Mean, sd=DR$SD, n=DR$n)
    
    reproFishers$reproduce <- rbinom(n = nrow(reproFishers), size = 1, prob = DR_CIs)
    
    # for those fishers who are reproducing, assign litter size
    reproFishers <- reproFishers %>% filter(reproduce==1)
    LS <- repro_rate_table %>% dplyr::filter(str_detect(Fpop, fisher.pop)) %>% dplyr::filter(str_detect(Param,"LS"))
    reproFishers$num.kits <- rnorm(n=nrow(reproFishers), mean=LS$Mean, sd=LS$SD)
    
    # revise number of kits based on habitat quality within FHE zone, remove males and round up (whole number to make sense, give young a chance)
    mahal_score <- mahal_metric_table %>% filter(FHE_zone==FHE) 
    # need to check with fisher team if these habitat qualifiers make sense
    reproFishers <- reproFishers %>% mutate(num.kits = case_when(d2_score < mahal_score$Mean ~ ceiling(num.kits/2),
                                                                 d2_score < (mahal_score$Mean + mahal_score$SD) ~ ceiling((num.kits*0.75)/2),
                                                                 d2_score <= mahal_score$Max ~ ceiling((num.kits*0.50)/2),
                                                                 d2_score > mahal_score$Max ~ num.kits*0))
    
    female_hr_size <- female_hr_table %>% filter(FHE_zone==FHE)
    
    for(i in 1:nrow(reproFishers)){
      tmp_juv <- reproFishers[rep(i, reproFishers[i,]$num.kits)]
      tmp_juv$individual_id <- seq(from=max(agents$individual_id+1), 
                                   to=max(agents$individual_id+reproFishers[i,]$num.kits), by=1)
      tmp_juv$age <- 0
      tmp_juv$hr_size = rnorm(reproFishers[i,]$num.kits, female_hr_size$Mean_Area_km2, female_hr_size$SD_Area_km2 )
      tmp_juv$d2_score <- NA
      
      agents <- rbind(agents, tmp_juv %>% dplyr::select(-reproduce, -num.kits)) 
      
      # no update to the territories table because juveniles have not yet established a territory
    }
  }
 
  return (invisible (sim))
}


###--- DISPERSE
dispersal <- function (sim) {

  # get the dispersers; age 1 y.o. fishers
  dispersers <- dbGetQuery (sim$clusdb, "SELECT * FROM agents WHERE age = 1 AND d2_score IS NULL") # grab the agents at age of dispersal; use d2_score criteria as secondary check?

  # create the dispersal area; i.e., where the fisher searches 
  table.disperse <- SpaDES.tools::spread2 (sim$pix.rast, # within the area of interest
                                           start = dispersers$pixelid, # for each individual
                                           spreadProb = sim$spread.rast, # spread more in habitat (i.e., there is some 'direction' towards habitat)
                                           exactSize = 785000, # spread to a dispersal distance within a 50km radius; 
                                                               # 500 pixels = 50km; area = pi * radius^2 
                                                               # 50km radius = 7850km2 area, which is 1/6 of the Williams Lake TSA; realistic?
                                           allowOverlap = T, # overlap allowed; fishers could pick the same dispersal area
                                           asRaster = F, # output as table
                                           # returnDistances = T, # not working; see below
                                           circle = F) # spread to adjacent cells; not necessarily a circle

  # identify pixels within mothers home range and remove them from the dispersal table
    # WE ONLY NEED THIS IF WE DON'T REMOVE ALL OCCUPIED TERRITORIES (NEXT STEP)
  # start.pix <- dispersers$pixelid
  # for (i in start.pix) { # Select agents with the same starting pixel but are adults; these should be moms
  #   query <- glue_sql ("SELECT individual_id FROM agents WHERE agents.age > 1 AND agents.pixelid = {i}")
  #   mom <- dbGetQuery (sim$clusdb, query)
  #   mom <- mom$individual_id # get the mom's id
  #   query2 <- glue_sql ("SELECT * FROM territories WHERE territories.individual_id = {mom}")
  #   mom.terr <- dbGetQuery (sim$clusdb, query2) # get the mom's territory pixels
  #   table.disperse <- table.disperse [!pixels %in% mom.terr$pixelid] # remove pixels in the dispersal area that are in the mom's terr  
  # } 
  
  # identify pixels already occupied by a fisher and remove them from the dispersal table
  terrs <- dbGetQuery (sim$clusdb, "SELECT * FROM territories")
  table.disperse <- table.disperse [!pixels %in% terrs$pixelid]
  
  # identify areas with more habitat (denning?)
  inds <- unique (table.disperse$initialPixels) # unique individuals
  
  ind.disp.pix <- rast (sim$pix.rast) # raster of area - needs to be a 'SpatRaster'
  ind.disp.pix [ind.disp.pix > 0] <- 0 # assign 0 values
  
  for (i in inds) {
    ind.disperse <- table.disperse [initialPixels == i] # identify dispersal pix by ind
    tmp.ind.disp.pix <- ind.disp.pix
    tmp.ind.disp.pix [ind.disperse$pixels] <- 1 # assign dispersal pix to raster
    
    # convert raster to polygon and start at centre in largest poly?
    terra::as.polygons (tmp.ind.disp.pix)
    
    
    
    
    
    
    # neighborhood method; calc sum of habitat raters in a 'neighborhood' (territory)
    # this is waaaaaay too slow
      # habitat.area <- terra::focal (tmp.ind.disp.pix, # pixel raster
      #                               w = 399, # w = search area radius = 399 pixels = 5,000km2
      #                               fun = sum, # sum the pixel values
      #                               na.rm = TRUE # ignore NA values
      #                               ) 

    
  }
  


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
