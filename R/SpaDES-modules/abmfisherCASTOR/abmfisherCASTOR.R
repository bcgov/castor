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
  name = "abmfisherCASTOR",
  description = "An agent based model (ABM) to simulate fisher life history on a landscape.",
  keywords = "fisher, martes, agent based model",
  authors = structure(list(list(given = c("First", "Middle"), family = "Last", role = c("aut", "cre"), email = "email@example.com", comment = NULL)), class = "person"),
  childModules = character(0),
  version = list (abmfisherCASTOR = "1.0.0.0000"),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.md", "abmfisherCASTOR.Rmd"), ## same file
  reqdPkgs = list("SpaDES.core (>=1.0.10)", "data.table", "terra", "keyring", "here"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    # defineParameter("n_females", "numeric", 1000, 0, 10000, # not used
    #                 "The number of females to 'seed' the landscape with."),    
    defineParameter("female_max_age", "numeric", 9, 0, 15,
                    "The maximum possible age of a female fisher. Taken from research referenced by Roray Fogart in VORTEX_inputs_new.xlsx document."), 
    defineParameter("den_target", "numeric", 0.10, 0.003, 0.54,
                    "The minimum proportion of a home range that is denning habitat. Values taken from empirical female home range data across populations."), 
    defineParameter("rest_target", "numeric", 0.26, 0.028, 0.58,
                    "The minimum proportion of a home range that is resting habitat. Values taken from empirical female home range data across populations."),   
    defineParameter("move_target", "numeric", 0.36, 0.091, 0.73,
                    "The minimum proportion of a home range that is movement habitat. Values taken from empirical female home range data across populations."), 
    defineParameter("sex_ratio", "numeric", 0.5, 0, 1,
                    "The probability of being a female in a litter."),
    defineParameter("female_dispersal", "numeric", 785000, 100, 10000000,
                    "The area, in hectares, a fisher could explore during a dispersal to find a territory."),
    defineParameter("iterations", "numeric", 1, 1, 10000,
                    "Number of times to repeat the simulation."),
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
    #expectsInput (objectName = NA, objectClass = NA, desc = NA, sourceURL = NA)
    expectsInput (objectName = "castordb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates castor realted information", sourceURL = NA),
    expectsInput (objectName = "fisher_d2_cov", objectClass = "data.table", desc = "variance matrix for mahalanobis distance model; don't touch this unless d2 model updated", sourceURL = NA),
    expectsInput (objectName = "survival_rate_table", objectClass = "data.table", desc = "Table of fisher survival rates by sex, age and population, taken from Lofroth et al 2022 JWM vital rates manuscript. Headers: Fpop: the two populations in BC: Boreal, Coumbian; Age_class: two classes: Adult, Juvenile; Cohort: Fpop and Age_class combination: CFA, CFJ, BFA, BFJ; Mean: mean survival probability; SE: standard error of the mean. Decided to go with SE rather than SD as confidence intervals are quite wide and stochasticity would likely drive populations to extinction. Keeping consistent with Rory Fogarty's population analysis decisions.", sourceURL = NA),
    expectsInput (objectName = "repro_rate_table", objectClass = "data.table", desc = "Table of fisher reproductive rates (i.e., denning rate = a combination of pregnancy rate and birth rate; and litter size = number of kits) by population, taken from Lofroth et al 2022 JWM vital rates manuscript. Headers: Fpop: the two populations in BC: Boreal, Coumbian; Param: the reproductive parameter: DR (denning rate), LS (litter size); Mean: mean reproductive rate per parameter and population; SD: reproductive rate standard deviation value per parameter and population.", sourceURL = NA),
    expectsInput (objectName = "female_hr_table", objectClass = "data.table", desc = "Table of female home range sizes, by fisher population.", sourceURL = NA),
    expectsInput (objectName = "mahal_metric_table", objectClass = "data.table", desc = "Table of mahalanobis D2 values based on Fisher Habitat Extension zones, provided by Rich Weir summer 2022. Headers: FHE_zone: the four fisher habitat extension zones: Boreal, Sub-Boreal moist, Sub-Boreal dry, Dry Forest; FHE_zone_num: the corresponding FHE_zone number: Boreal = 1, Sub-Boreal moist = 2, Sub-Boreal Dry = 3, Dry Forest = 4; Mean: mean mahalanobis D2 value per FHE zone; SD: mahalanobis D2 standard deviation value per FHE zone; Max: maximum mahalanobis D2 value per FHE zone.", sourceURL = NA),
    expectsInput (objectName = "scenario", objectClass = "data.table", desc = "Table of scenario description.", sourceURL = NA),
    expectsInput (objectName = "ras", objectClass = "RasterLayer", desc = "Raster of area of interest.", sourceURL = NA),
    expectsInput (objectName = "boundaryInfo", objectClass ="character", desc = "Name of the area of interest(aoi) eg. Quesnel_TSA", sourceURL = NA),
    expectsInput (objectName = "updateInterval", objectClass = "numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA)
        ),
  outputObjects = bindrows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    #createsOutput (objectName = NA, objectClass = NA, desc = NA)
    createsOutput (objectName = "agents", objectClass = "data.table", desc = "Fisher agents table." ),
    createsOutput (objectName = "territories", objectClass = "data.table", desc = "Fisher territories table." ),
    createsOutput (objectName = "pix.rast", objectClass = "RasterLayer", desc = "A raster dataset of pixel values in the area of interest." ),
    createsOutput (objectName = "fisherABMReport", objectClass = "data.table", desc = "A data.table object. Consists of fisher population numbers in the study area at each time step."),
    createsOutput (objectName = "table.hab", objectClass = "data.table", desc = "Table of fisher habitat metrics at pixels in the area of interest." ),
    createsOutput (objectName = "sim.iter.annual", objectClass = "list", desc = "List of simulation iterations (a list of sims for each iteration)."))
))

## event types

doEvent.abmfisherCASTOR = function (sim, eventTime, eventType) {
  switch(
    eventType,
    
    init = {
      sim <- Init (sim)
      sim <- saveAgents (sim)
      sim <- scheduleEvent (sim, time(sim) + P(sim, "timeInterval", "abmfisherCASTOR"), "abmfisherCASTOR", "runevents", 19)
      sim <- scheduleEvent (sim, time(sim) + P(sim, "timeInterval", "abmfisherCASTOR"), "abmfisherCASTOR", "save", 20)
    },
    # interpolatehabitat = {
    # 
    #   # develop this in next version?
    #   
    #   # need some functions here to interpolate habitat degradation/improvement over the forestry simulation interval (five years)
    #   # the reproduce, etc. functions should happen annually, but the forestry sim interval will likely be > 1 year
    #   # we don't want to take the habitat at the start or end of the interval to estimate reproduction, etc.
    #   # because it would over or underestimate those values over the interval period
    #   # instead, we could calc the mid-point between the start and end as the habitat score
    #   #  this would 'smooth' the habitat effects over a five year period, probably returning more realistic results
    #   
    #   sim <- scheduleEvent(sim, time(sim) + P(sim, "timeInterval", "abmfisherCASTOR"), "abmfisherCASTOR", "reproduce", 20)
    #   
    # },
   runevents = {
      sim <- annualEvents (sim)
      sim <- scheduleEvent (sim, time(sim) + P(sim, "timeInterval", "abmfisherCASTOR"), "abmfisherCASTOR", "runevents", 19)
    },
   save = {
      sim <- saveAgents (sim)
      sim <- scheduleEvent (sim, time(sim) + P(sim, "timeInterval", "abmfisherCASTOR"), "abmfisherCASTOR", "save", 20)
    },
   
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
                  "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'", sep = ""))
  )
  return(invisible(sim))
}


## event functions
Init <- function(sim) {
  
  message ("Initiating fisher ABM...")
  
  # instantiate table and raster for saving data
  message("Initializing the report")

  sim$fisherABMReport <- data.table (n_f_adult = as.numeric (), # number of adult females
                                     n_f_juv = as.numeric (), # number of juvenile females
                                     n_f_disperse = as.numeric (), # number of female dispersers 
                                     mean_age_f = as.numeric (), # mean age of females
                                     sd_age_f = as.numeric (), # standard dev age of females
                                     timeperiod = as.integer (), # time step of the simulation
                                     scenario = as.character (), # simulation scenario name
                                     compartment = character() # harvest compartments
                                     )
  sim$ras.territories <- sim$ras
  sim$ras.territories [] <- 0
  
  message ("Get the area of interest ...")

  # get pixel id's for aoi 
  pix.for.rast <- data.table (dbGetQuery (sim$castordb, "SELECT pixelid FROM pixels WHERE compartid IS NOT NULL;"))
  sim$pix.rast <- sim$ras
  sim$pix.rast [pix.for.rast$pixelid] <- pix.for.rast$pixelid
  sim$pix.rast [!pix.for.rast$pixelid] <- NA
  
  message ("Get the habitat data ...")
  # get the fisher habitat areas
  
  if(nrow(dbGetQuery(sim$castordb, "SELECT name FROM sqlite_schema WHERE type ='table' AND name = 'fisherlandscape';")) == 0) { # Check to see if this data exists in the sqlite db already
    message ("Creating fisherlandscape table.")
    # Create the habitat data table in the database if it does not exist
    dbExecute (sim$castordb, "CREATE TABLE IF NOT EXISTS fisherlandscape (pixelid integer, den_p integer, rus_p integer, mov_p integer, cwd_p integer, cav_p integer, fisher_pop integer)")
    sim$table.hab <- data.table (pixelid = sim$pix.rast[], # this identifies and grabs ('clips') the potential habitat in the area of interest
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
    dbBegin (sim$castordb) 
    rs <- dbSendQuery (sim$castordb, paste0 ("INSERT INTO fisherlandscape (pixelid, den_p, rus_p, mov_p, cwd_p, cav_p, fisher_pop) 
                                            VALUES (:pixelid, :den_p, :rus_p, :mov_p, :cwd_p, :cav_p, :fisher_pop)"), sim$table.hab) 
    dbClearResult (rs)
    dbCommit (sim$castordb)
  } else {
    sim$table.hab <- data.table (dbGetQuery (sim$castordb, "SELECT * FROM fisherlandscape;"))
  }
  
  # add the habitat characteristics
  table.hab.init <- merge (sim$table.hab, 
                           data.table (dbGetQuery (sim$castordb, "SELECT pixelid, age, crownclosure, qmd, basalarea, height FROM pixels WHERE compartid IS NOT NULL;")),
                           by.x = "pixelid",
                           by.y = "pixelid",
                           all.x = TRUE)
  
  # classify the habitat
  table.hab.init <- classifyHabitat (table.hab.init)
 
  message ("Create fisher agents table and assign values...")
  # assign agents to denning pixels
    
  # systematic method
      # this provides a 'buffer' between pixels to allow some space for fisher to form an HR; 
      # if they are too close then it forms fewer HRs
    den.pix <- as.data.table (table.hab.init [denning == 1 & !is.na (fisher_pop), pixelid])
    den.pix.sample <- den.pix [seq (1, nrow (den.pix), 50), ] # grab every ~50th pixel; ~1 pixel every 5km
    sim$agents <- data.table (individual_id = seq (from = 1, to = nrow (den.pix.sample), by = 1),
                              sex = "F",
                              age = sample (1:P(sim, "female_max_age", "abmfisherCASTOR"), length (seq (from = 1, to = nrow (den.pix.sample), by = 1)), replace = T), # randomly draw ages between 1 and the max age,
                              pixelid = den.pix.sample$V1)
   
    # user-defined method; allow user to pick the # of agents
      # ids <- seq (from = 1, to = P(sim, "n_females", "abmfisherCASTOR"), by = 1) # sequence of individual id's from 1 to n_females
      # agents <- data.table (individual_id = ids, 
      #                       sex = "F", 
      #                       age = sample (1:P(sim, "max_age", "abmfisherCASTOR"), length (ids), replace = T), # randomly draw ages between 1 and the max age, 
      #                       pixelid = numeric (), 
      #                       hr_size = numeric (),
      #                       d2_score = numeric ())
      # 
      # assign a random starting location that is a denning pixel in population range
      # agents$pixelid <- sample (table.hab [denning == 1 & !is.na (fisher_pop), pixelid], length (ids), replace = T)
  # assign the population
  sim$agents <- merge (sim$agents, 
                       table.hab.init [ , c("pixelid", "fisher_pop")], 
                       by.x = "pixelid", by.y = "pixelid", all.x = T)
  # assign an HR size based on population
  sim$agents [fisher_pop == 1, hr_size := round (rnorm (nrow (sim$agents [fisher_pop == 1, ]), sim$female_hr_table [fisher_pop == 1, hr_mean], sim$female_hr_table [fisher_pop == 1, hr_sd]))]
  sim$agents [fisher_pop == 2, hr_size := round (rnorm (nrow (sim$agents [fisher_pop == 2, ]), sim$female_hr_table [fisher_pop == 2, hr_mean], sim$female_hr_table [fisher_pop == 2, hr_sd]))]
  sim$agents [fisher_pop == 3, hr_size := round (rnorm (nrow (sim$agents [fisher_pop == 3, ]), sim$female_hr_table [fisher_pop == 3, hr_mean], sim$female_hr_table [fisher_pop == 3, hr_sd]))]
  sim$agents [fisher_pop == 4, hr_size := round (rnorm (nrow (sim$agents [fisher_pop == 4, ]), sim$female_hr_table [fisher_pop == 4, hr_mean], sim$female_hr_table [fisher_pop == 4, hr_sd]))]

  message ("Create territories ...")
  # assign agents to territories table
  sim$territories <- data.table (individual_id = sim$agents$individual_id, 
                                  pixelid = sim$agents$pixelid)
  
  # create spread probability raster
    # note: this is limited to fisher range
  spread.rast <- spreadRast (sim$pix.rast, table.hab.init)

# this step took 15 mins with ~8500 starting points; 6 mins for 2174 points; 1 min for 435 points
  table.hr <- SpaDES.tools::spread2 (sim$pix.rast, # within the area of interest
                                     start = sim$agents$pixelid, # for each individual
                                     spreadProb = spread.rast, # use spread prob raster
                                     exactSize = sim$agents$hr_size, # spread to the size of their territory
                                     # returnDistances = T, # not working; see below
                                     allowOverlap = F, # no overlap allowed
                                     asRaster = F, # output table
                                     circle = F) # spread to adjacent cells
    
  # calc distance between each pixel and the denning site
      # not used; keeping it here in case we need it
    # table.hr <- cbind (table.hr, xyFromCell (sim$pix.rast, table.hr$pixels))
    # table.hr [!(pixels %in% agents$pixelid), dist := RANN::nn2 (table.hr [pixels %in% agents$pixelid, c("x","y")], table.hr [!(pixels %in% agents$pixelid), c("x","y")], k = 1)$nn.dists]
    # table.hr [is.na (dist), dist := 0]

  # add individual id and habitat
  table.hr <- merge (merge (table.hr,
                            sim$agents [, c ("pixelid", "individual_id")],
                            by.x = "initialPixels", by.y = "pixelid"), 
                     table.hab.init [, c ("pixelid", "denning", "rust", "cavity", "cwd", "movement")],
                     by.x = "pixels", by.y = "pixelid")

  # check to see if home range target was within 2 SD's of the mean; if not, remove the animal 
  table.hr [, pix.count := sum (length (pixels)), by = individual_id]
  pix.count <- merge (sim$agents [, c ("pixelid", "individual_id", "hr_size", "fisher_pop")],
                      table.hr [, c ("pixels", "pix.count")],
                      by.x = "pixelid", by.y = "pixels",
                      all.x = T)
  
  # for each fisher population
  for (i in pix.count [fisher_pop == 1, ]$individual_id) { # for each individual
      if (pix.count [fisher_pop == 1 & individual_id == i, pix.count] >= (female_hr_table [fisher_pop == 1, hr_mean] - (2 *female_hr_table [fisher_pop == 1, hr_sd])) & pix.count [fisher_pop == 1 & individual_id == i, pix.count] <= (female_hr_table [fisher_pop == 1, hr_mean] + (2 * female_hr_table [fisher_pop == 1, hr_sd]))) { 
        # if it achieves its home range size +/- 2 SD  
        # do nothing; we need to check if it meets min. habitat criteria (see below)
      } else {
        # delete the individual from the agents and territories table
        sim$territories <- sim$territories [individual_id != i] 
        sim$agents <- sim$agents [individual_id != i]
      } 
  }
  for (i in pix.count [fisher_pop == 2, ]$individual_id) { # for each individual
    if (pix.count [fisher_pop == 2 & individual_id == i, pix.count] >= (female_hr_table [fisher_pop == 2, hr_mean] - (2 *female_hr_table [fisher_pop == 2, hr_sd])) & pix.count [fisher_pop == 2 & individual_id == i, pix.count] <= (female_hr_table [fisher_pop == 2, hr_mean] + (2 * female_hr_table [fisher_pop == 2, hr_sd]))) { 
      
    } else {
      sim$territories <- sim$territories [individual_id != i] 
      sim$agents <- sim$agents [individual_id != i]
    } 
  }
  
  for (i in pix.count [fisher_pop == 3, ]$individual_id) { # for each individual
    if (pix.count [fisher_pop == 3 & individual_id == i, pix.count] >= (female_hr_table [fisher_pop == 3, hr_mean] - (2 *female_hr_table [fisher_pop == 3, hr_sd])) & pix.count [fisher_pop == 3 & individual_id == i, pix.count] <= (female_hr_table [fisher_pop == 3, hr_mean] + (2 * female_hr_table [fisher_pop == 3, hr_sd]))) { 
    
    } else {
      sim$territories <- sim$territories [individual_id != i] 
      sim$agents <- sim$agents [individual_id != i]
    } 
  }
  
  for (i in pix.count [fisher_pop == 4, ]$individual_id) { # for each individual
    if (pix.count [fisher_pop == 4 & individual_id == i, pix.count] >= (female_hr_table [fisher_pop == 4, hr_mean] - (2 *female_hr_table [fisher_pop == 4, hr_sd])) & pix.count [fisher_pop == 4 & individual_id == i, pix.count] <= (female_hr_table [fisher_pop == 4, hr_mean] + (2 * female_hr_table [fisher_pop == 4, hr_sd]))) { 
      
    } else {
      sim$territories <- sim$territories [individual_id != i] 
      sim$agents <- sim$agents [individual_id != i]
    } 
  }


  # check to see if minimum habitat target was met (prop habitat = 0.15); if not, remove the animal 
  hab.count <- table.hr [denning == 1 | rust == 1 | cwd == 1 | movement == 1, .(.N), by = individual_id]
  hab.count <- merge (hab.count,
                      sim$agents [, c ("hr_size", "individual_id")],
                      by = "individual_id")
  hab.count$prop_hab <- hab.count$N / hab.count$hr_size
  for (i in hab.count$individual_id) { # for each individual
    if ( hab.count [individual_id == i, prop_hab] >= 0.15) { 
      # if it achieves its home range size and minimum habitat targets 
      # do nothing; we still need to check if it meets min. habitat criteria (see below)
    } else {
      # delete the individual from the agents and territories table
      sim$territories <- sim$territories [individual_id != i] 
      sim$agents <- sim$agents [individual_id != i]
    } 
  }
        #  remove pixels if already occupied
          # not used, but keeping here if we need it later
            # search.temp <- merge (search.temp, territories, 
            #                       by.x = "pixels", by.y = "pixelid", all.x = T)
            # search.temp <- search.temp [is.na (individual_id) | individual_id == (agents [pixelid == i, individual_id]), ]
  
  # check if proportion of habitat types are greater than the minimum thresholds 
  for (i in sim$agents$individual_id) { # for each individual
    if (P(sim, "rest_target", "abmfisherCASTOR") <= (nrow (table.hr [individual_id == i & rust == 1]) + nrow (table.hr [individual_id == i & cwd == 1])) / sim$agents [individual_id == i, hr_size] & P(sim, "move_target", "abmfisherCASTOR") <= nrow (table.hr [individual_id == i & movement == 1]) / sim$agents [individual_id == i, hr_size] & P(sim, "den_target", "abmfisherCASTOR") <= nrow (table.hr [individual_id == i & denning == 1]) / sim$agents [individual_id == i, hr_size]
    ) {
      # check to see it meets all thresholds
      # assign the pixels to territories table
      sim$territories <- rbind (sim$territories, table.hr [individual_id == i, .(pixelid = pixels, individual_id)]) 
    } else {
      # delete the individual from the agents and territories table
      sim$territories <- sim$territories [individual_id != (sim$agents [individual_id == i, individual_id]), ] 
      sim$agents <- sim$agents [individual_id != i,]
    } 
  }
    
  #---Calculate D2 (Mahalanobis) 
  message ("Calculate habitat quality.")
    # identify which fisher pop an animal belongs to
  terr.pop <- merge (sim$territories, table.hab.init [, c ("pixelid", "fisher_pop")], 
                      by = "pixelid", all.x = T)
    # get the mean of pixels pop. values, rounded to get the majority; majority = pop membership
  terr.pop [, fisher_pop := .(round (mean (fisher_pop, na.rm = T), digits = 0)), by = individual_id] 
  terr.pop <- unique (terr.pop [, c ("individual_id", "fisher_pop")])
  sim$agents <- merge (sim$agents [, -c ("fisher_pop")], # assign new fisher_pop to agents table
                       terr.pop [, c ("individual_id", "fisher_pop")], 
                       by = "individual_id", all.x = T)
 
  # get habitat for mahalanobis
  tab.mahal <- merge (sim$territories, 
                      table.hab.init [, c ("pixelid", "denning", "rust", "cavity", "movement", "cwd")], 
                      by = "pixelid", all.x = T)
  
  # calculate habitat quality 
  tab.perc <- habitatQual (tab.mahal, sim$agents, sim$fisher_d2_cov)
  
  sim$agents <- merge (sim$agents,
                       tab.perc [, .(individual_id, d2_score = d2)],
                       by = "individual_id")

  message ("Territories and agents created!")
  
  return (invisible (sim))
}



###--- ANNUAL EVENTS
annualEvents <- function (sim) {
 
  for (i in P(sim, "periodLength", "growingStockCASTOR")) { # repeat this function by the number of periods (years); this ties it to growingstockCASTOR - make this independent?
    
    # Step 1: "Update" the Habitat Conditions 
    message ("Fishers check habitat in territory.")
    
      # A. update the habitat data in the territories
    table.hab.update <- merge (sim$table.hab, # add the habitat characteristics
                               data.table (dbGetQuery (sim$castordb, "SELECT pixelid, age, crownclosure, qmd, basalarea, height  FROM pixels;")),
                               by = "pixelid")
    
        # classify the habitat
    table.hab.update <- classifyHabitat (table.hab.update)
    table.hab.terrs <- merge (table.hab.update,
                              sim$territories,
                              by = "pixelid"
                              )
    
      # B. Update the spread probability raster
    spread.rast <- spreadRast (sim$pix.rast, table.hab.update)

    
    # Step 2: Check if Fisher Habitat Needs are Being Met
      # if not, the animal gets a null d2 score and will disperse
        # A. check to see if minimum habitat target was met (prop habitat = 0.15); if not, remove the animal 
    hab.count <- table.hab.terrs [denning == 1 | rust == 1 | cwd == 1 | movement == 1, .(.N), by = individual_id]
    hab.count <- merge (hab.count,
                        sim$agents [, c ("hr_size", "individual_id")],
                        by = "individual_id")
    hab.count$prop_hab <- hab.count$N / hab.count$hr_size
    for (i in hab.count$individual_id) { # for each individual
      if (hab.count [individual_id == i, prop_hab] >= 0.15) { 
        # if it achieves its minimum habitat total habitat threshold
        # do nothing; we still need to check if it meets min. thresholds for each habitat type (see below)
      } else {
        # change the animals d2_score to 0; this is the criteria used to trigger a dispersal 
        sim$agents <- sim$agents [individual_id == i, d2_score := NA]
        # remove the individuals territory 
        sim$territories <- sim$territories [individual_id != i] 
      } 
    }
    
        # B. check if proportion of habitat types are greater than the minimum thresholds 
    for (i in sim$agents$individual_id) { # for each individual
      if (P(sim, "rest_target", "abmfisherCASTOR") <= (nrow (table.hab.terrs [individual_id == i & rust == 1]) + nrow (table.hab.terrs [individual_id == i & cwd == 1])) / sim$agents [individual_id == i, hr_size] & P(sim, "move_target", "abmfisherCASTOR") <= nrow (table.hab.terrs [individual_id == i & movement == 1]) / sim$agents [individual_id == i, hr_size] & P(sim, "den_target", "abmfisherCASTOR") <= nrow (table.hab.terrs [individual_id == i & denning == 1]) / sim$agents [individual_id == i, hr_size]
      ) {
        ## if it achieves its minimum thresholds for each habitat type 
        # do nothing; the fisher maintains its territory
      } else {
        # change the animals d2_score to 0
        sim$agents <- sim$agents [individual_id == i, d2_score := NA]
        # remove the individuals territory 
        sim$territories <- sim$territories [individual_id != i] 
      } 
    }
    message ("Habitat checked.")
    
    
    # Step 3: Fishers Disperse
    message ("Fishers start dispersal.")
    
      # A. Identify each fishers 'potential' dispersal area
        # grab the agents that don't have a home range, i.e., no d2_score 
    dispersers <- sim$agents [is.na (sim$agents$d2_score), ] 
    # remove the dispersers from the agents and territories tables
    sim$agents <- sim$agents [!individual_id %in% dispersers$individual_id]
    sim$territories <- sim$territories [!individual_id %in% dispersers$individual_id]
    
        # re-set the dispersers HR size and fisher_pop
    dispersers <- dispersers [, hr_size := NA]
    dispersers <- dispersers [, fisher_pop := NA]
        # create the dispersal area; i.e., where the fisher searches 
    table.disperse <- SpaDES.tools::spread2 (sim$pix.rast, # within the area of interest
                                             start = dispersers$pixelid, # for each individual
                                             spreadProb = spread.rast, # spread more in habitat (i.e., there is some 'direction' towards habitat)
                                             exactSize = P (sim, "female_dispersal", "abmfisherCASTOR"), # spread to a dispersal area 
                                             allowOverlap = T, # overlap allowed; fishers could pick the same dispersal area
                                             asRaster = F, # output as table
                                             circle = F) # spread to adjacent cells; not necessarily a circle
        # identify pixels already occupied by a fisher and remove them from the dispersal table
    table.disperse <- table.disperse [!pixels %in% sim$territories$pixelid]
    
      # B. identify where each disperser creates its territory
    inds <- unique (table.disperse$initialPixels) # id the unique individuals
    ind.disp.rast <- terra::rast (sim$pix.rast) # empty raster of the aoi - needs to be a terra 'SpatRaster' object
    ind.disp.rast [ind.disp.rast > 0] <- 0 # assign 0 values; get updated in the fxn below
      
    message ("Identify fisher territory starting point.")
      
      for (i in inds) {
        ind.disperse <- table.disperse [initialPixels == i] # identify dispersal pixels for each ind
        tmp.ind.disp.rast <- ind.disp.rast
        tmp.ind.disp.rast [ind.disperse$pixels] <- 1 # assign dispersal pix to raster
        
        # target the denning habitat
        table.denning <- table.disperse [pixels %in% table.hab.update [denning == 1, pixelid]]
        
        if (nrow (table.denning) == 0) { # if there is no denning habitat 
          # need to disperse again
          # add the fisher back to the agents table without a hr size or d2 score
          sim$agents <- rbind (sim$agents,
                               dispersers [pixelid == i])
          # and remove the fisher from the dispersers table
          dispersers <- dispersers [pixelid != i] 
        } else {
          # convert the target raster (i.e., 'patches' of denning habitat) to polygons 
          target.rast <- terra::rast (sim$pix.rast)
          target.rast [] <- 0
          target.rast [table.denning$pixels] <- 1 
          target.polys <- terra::as.polygons (terra::patches (target.rast, # this function identifies contiguous polygons 
                                                              directions = 8, # queen's case for neighbouring cells
                                                              zeroAsNA = T)) 
          # add id and area to data
          target.polys$fid <- 1:nrow (target.polys)
          target.polys$area_ha <- expanse (target.polys, unit = "ha")
          # get the largest polygon
            # alternatively, we could  identify polys that achieve a minimum site size and select random
          max.poly <- target.polys [which.max (target.polys$area_ha),]
          # select a random point in that polygon
          start.pnt <- terra::spatSample (max.poly,
                                          size = 1,
                                          method = "random")
          # get the raster pixel id of the point
          target.pix <- terra::extract (terra::rast (sim$pix.rast), 
                                        start.pnt, 
                                        method = "simple")
          # make that raster pixel id the dispersers pixelid (i.e., staring point for forming a territory)
          dispersers <- dispersers [pixelid == i, pixelid := target.pix$layer]
          # update the fisher pop where the fisher is located
          tmp.pop <- as.numeric (sim$table.hab [pixelid == target.pix$layer, fisher_pop])
          dispersers <- dispersers [pixelid == target.pix$layer, fisher_pop := tmp.pop]
          
        }
        
      }
          # create new HR sizes based on which fisher pop the animal belongs to
      dispersers [fisher_pop == 1, hr_size := round (rnorm (nrow (dispersers [fisher_pop == 1, ]), sim$female_hr_table [fisher_pop == 1, hr_mean], sim$female_hr_table [fisher_pop == 1, hr_sd]))]
      dispersers [fisher_pop == 2, hr_size := round (rnorm (nrow (dispersers [fisher_pop == 2, ]), sim$female_hr_table [fisher_pop == 2, hr_mean], sim$female_hr_table [fisher_pop == 2, hr_sd]))]
      dispersers [fisher_pop == 3, hr_size := round (rnorm (nrow (dispersers [fisher_pop == 3, ]), sim$female_hr_table [fisher_pop == 3, hr_mean], sim$female_hr_table [fisher_pop == 3, hr_sd]))]
      dispersers [fisher_pop == 4, hr_size := round (rnorm (nrow (dispersers [fisher_pop == 4, ]), sim$female_hr_table [fisher_pop == 4, hr_mean], sim$female_hr_table [fisher_pop == 4, hr_sd]))]
      
      # C. Dispersers create territories
      message ("Fishers forming territories.")
      
      table.disperse.hr <- SpaDES.tools::spread2 (sim$pix.rast, # within the area of interest
                                                  start = dispersers$pixelid, # for each individual
                                                  spreadProb = spread.rast, # use spread prob raster
                                                  exactSize = dispersers$hr_size, # spread to the size of their assgined HR size
                                                  allowOverlap = F, # no overlap allowed
                                                  asRaster = F, # output as a table
                                                  circle = F) # spread to adjacent cells
        # add individual id and habitat
      table.disperse.hr <- merge (merge (table.disperse.hr,
                                         dispersers [, c ("pixelid", "individual_id")],
                                         by.x = "initialPixels", by.y = "pixelid"), 
                                  table.hab.update [, c ("pixelid", "denning", "rust", "cavity", "cwd", "movement")],
                                  by.x = "pixels", by.y = "pixelid")
        # check to see if home range target was within mean +/- 2 SD; if not, remove the animal 
      table.disperse.hr [, pix.count := sum (length (pixels)), by = individual_id]
      pix.count <- merge (dispersers [, c ("pixelid", "individual_id", "hr_size", "fisher_pop")],
                          table.disperse.hr [, c ("pixels", "pix.count")],
                          by.x = "pixelid", by.y = "pixels",
                          all.x = T)  
        # for each fisher population
      for (i in pix.count [fisher_pop == 1, ]$individual_id) { # for each individual
        if (pix.count [fisher_pop == 1 & individual_id == i, pix.count] >= (female_hr_table [fisher_pop == 1, hr_mean] - (2 *female_hr_table [fisher_pop == 1, hr_sd])) & pix.count [fisher_pop == 1 & individual_id == i, pix.count] <= (female_hr_table [fisher_pop == 1, hr_mean] + (2 * female_hr_table [fisher_pop == 1, hr_sd]))) { 
          # if its home range size is within mean +/- 2 SD
          # do nothing; we still need to check if it meets min. thresholds for each habitat type (see below)
        } else {
          # save them as agents without a d2score
          sim$agents <- rbind (sim$agents,
                               dispersers [individual_id == i])
          dispersers <- dispersers [individual_id != i] # remove from dispersers table
        } 
      }
      for (i in pix.count [fisher_pop == 2, ]$individual_id) { # for each individual
        if (pix.count [fisher_pop == 2 & individual_id == i, pix.count] >= (female_hr_table [fisher_pop == 2, hr_mean] - (2 *female_hr_table [fisher_pop == 2, hr_sd])) & pix.count [fisher_pop == 2 & individual_id == i, pix.count] <= (female_hr_table [fisher_pop == 2, hr_mean] + (2 * female_hr_table [fisher_pop == 2, hr_sd]))) { 
          
        } else {
          sim$agents <- rbind (sim$agents,
                               dispersers [individual_id == i])
          dispersers <- dispersers [individual_id != i] # remove from dispersers table
        } 
      }    
      for (i in pix.count [fisher_pop == 3, ]$individual_id) { # for each individual
        if (pix.count [fisher_pop == 3 & individual_id == i, pix.count] >= (female_hr_table [fisher_pop == 3, hr_mean] - (2 *female_hr_table [fisher_pop == 3, hr_sd])) & pix.count [fisher_pop == 3 & individual_id == i, pix.count] <= (female_hr_table [fisher_pop == 3, hr_mean] + (2 * female_hr_table [fisher_pop == 3, hr_sd]))) { 
          
        } else {
          sim$agents <- rbind (sim$agents,
                               dispersers [individual_id == i])
          dispersers <- dispersers [individual_id != i] # remove from dispersers table
        } 
      } 
      for (i in pix.count [fisher_pop == 4, ]$individual_id) { # for each individual
        if (pix.count [fisher_pop == 4 & individual_id == i, pix.count] >= (female_hr_table [fisher_pop == 4, hr_mean] - (2 *female_hr_table [fisher_pop == 4, hr_sd])) & pix.count [fisher_pop == 4 & individual_id == i, pix.count] <= (female_hr_table [fisher_pop == 4, hr_mean] + (2 * female_hr_table [fisher_pop == 4, hr_sd]))) { 
          
        } else {
          sim$agents <- rbind (sim$agents,
                               dispersers [individual_id == i])
          dispersers <- dispersers [individual_id != i] # remove from dispersers table
        } 
      }       
      
      
      # check to see if minimum habitat target was met (prop habitat = 0.15); if not, remove the animal 
      hab.count <- table.disperse.hr [denning == 1 | rust == 1 | cwd == 1 | movement == 1, .(.N), by = individual_id]
      hab.count <- merge (hab.count,
                          dispersers [, c ("hr_size", "individual_id")],
                          by = "individual_id")
      hab.count$prop_hab <- hab.count$N / hab.count$hr_size
      for (i in hab.count$individual_id) { # for each individual
        if ( hab.count [individual_id == i, prop_hab] >= 0.15) { 
          # if it achieves its minimum habitat total habitat threshold
          # do nothing; we still need to check if it meets min. habitat criteria (see below)
        } else {
          # save them as agents without a d2score
          sim$agents <- rbind (sim$agents,
                               dispersers [individual_id == i])
          # delete the individual from the dispersers table
          dispersers <- dispersers [individual_id != i]
        } 
      }
      
        # finalize which fisher pop a successful disperser belongs to
      terr.pop <- merge (table.disperse.hr, sim$table.hab [, c ("pixelid", "fisher_pop")], 
                         by.x = "pixels",
                         by.y = "pixelid", all.x = T)
        # get the mean of pixels pop. values, rounded to get the majority; majority = pop membership
      terr.pop [, fisher_pop := .(round (mean (fisher_pop, na.rm = T), digits = 0)), by = individual_id] 
      terr.pop <- unique (terr.pop [, c ("individual_id", "fisher_pop")])
      dispersers <- merge (dispersers [, -c ("fisher_pop")], # assign new fisher_pop to agents table
                           terr.pop [, c ("individual_id", "fisher_pop")], 
                           by = "individual_id", all.x = T)
      
      
      # D. Successful Dispersers get a D2 Score (Mahalanobis) 
      message ("Calculate habitat quality of succesfull dispersers.")

      # calculate habitat quality 
      tab.perc <- habitatQual (table.disperse.hr, dispersers, sim$fisher_d2_cov)
      
      dispersers <- merge (dispersers [, - ('d2_score')],
                           tab.perc [, .(individual_id, d2_score = d2)],
                           by = "individual_id")
      
      message ("Habitat quality calculated.")
      
      # E. Check that min. habitat thresholds are met 
      for (i in dispersers$individual_id) { # for each individual
        if (P(sim, "rest_target", "abmfisherCASTOR") <= (nrow (table.disperse.hr [individual_id == i & rust == 1]) + nrow (table.disperse.hr [individual_id == i & cwd == 1])) / dispersers [individual_id == i, hr_size] & P(sim, "move_target", "abmfisherCASTOR") <= nrow (table.disperse.hr [individual_id == i & movement == 1]) / dispersers [individual_id == i, hr_size] & P(sim, "den_target", "abmfisherCASTOR") <= nrow (table.disperse.hr [individual_id == i & denning == 1]) / dispersers [individual_id == i, hr_size]
        ) {
          # if it achieves the thresholds
          # assign the pixels to the territories table
          sim$territories <- rbind (sim$territories, 
                                    table.disperse.hr [individual_id == i, .(pixelid = pixels, individual_id)]) 
          # assign dispersers to the agents table
          sim$agents <- rbind (sim$agents, 
                               dispersers [individual_id == i, ]) 
          
        } else {
          # add the individual to the agents without a d2 score
          dispersers <- dispersers [individual_id != i, d2_score := NA]
          sim$agents <- rbind (sim$agents, dispersers [individual_id == i, ]) 
        } 
      }
      
      message ("Dispersal complete!")

 
     # Step 4: Reproduce
      message ("Fishers reproduce.")
      
      reproFishers <- sim$agents [sex == "F" & age > 1 & !is.na (d2_score) ] # females of reproductive age in a territory

      # A. Assign each female fisher 1 = reproduce or 0 = does not reproduce
      if (length (reproFishers) > 0) {
        
        for (i in unique (reproFishers$fisher_pop)) { 
          reproFishers [fisher_pop == i, reproduce := rbinom (n = nrow (reproFishers [fisher_pop == i]),
                                                              size = 1,
                                                              prob = rnorm (1, 
                                                                            mean = sim$repro_rate_table [Fpop == i & Param == 'DR', Mean], 
                                                                            sd =  sim$repro_rate_table [Fpop == i & Param == 'DR', SD]))]
        } 
        
        reproFishers <- reproFishers [reproduce == 1, ] # remove non-reproducers
        
        # for those fishers who are reproducing, assign litter size (Poisson distribution)
        # litter size adjusted for habitat quality
        reproFishers <- litterSize (1, sim$mahal_metric_table, sim$repro_rate_table)
        reproFishers <- litterSize (2, sim$mahal_metric_table, sim$repro_rate_table)
        reproFishers <- litterSize (3, sim$mahal_metric_table, sim$repro_rate_table)
        reproFishers <- litterSize (4, sim$mahal_metric_table, sim$repro_rate_table)
        
        reproFishers <- reproFishers [kits >= 1, ] # remove females with no kits
        
        ## add the kits to the agents table
        # create new agents
        new.agents <- data.frame (lapply (reproFishers, rep, reproFishers$kits)) # repeat the rows in the reproducing fishers table by the number of kits 
        
        # assign whether fisher is a male or female; remove males
        new.agents$kits <- rbinom (size = 1, n = nrow (new.agents), prob = P (sim, "sex_ratio", "abmfisherCASTOR")) # prob of being a female
        new.agents <- setDT (new.agents)
        new.agents <- new.agents [kits == 1, ] # female = 1; male = 0
        # make them age 0; 
        new.agents$age <- 0
        # make their home range size = 0 and d2_score = 0; this gets done in the dispersal function 
        new.agents$hr_size <- 0
        new.agents$d2_score <- 0
        # drop 'reproduce' and 'kits' columns (and time and scenario)
        new.agents$reproduce <- NULL
        new.agents$kits <- NULL
        # update the individual id
        new.agents$individual_id <- seq (from = max (sim$agents$individual_id + 1), 
                                         to = (max (sim$agents$individual_id) + nrow (new.agents)), by = 1)
        
        # add time, scenario
        sim$agents <- rbind (sim$agents,
                             new.agents) # save the new agents
        
      } else {
        message ("There are no reproducing fishers!")
      }
      # no update to the territories table because juveniles have not yet established a territory
      message ("Kits added to population.")
      
      
      # Step 5. Survive and Age 1 Year
        # old fishers die here; remove their territories
      survivors <- sim$agents [age < P(sim, "female_max_age", "abmfisherCASTOR"), ] # remove old
      sim$agents <- sim$agents [individual_id %in% survivors$individual_id] 
      sim$territories <- sim$territories [individual_id %in% survivors$individual_id] # remove territories
      
        # old dispersers die here; remove their territories 
      dead.dispersers <- survivors [age > 2 & d2_score == '', ] # older than 2 and doesn't have a territory
      sim$agents <- sim$agents [!individual_id %in% dead.dispersers$individual_id]
      sim$territories <- sim$territories [!individual_id %in% dead.dispersers$individual_id] # remove territories
      
      # note that the above steps could inflate the model mortality rate, as old animals are presumably included in the survival rate estimate
      
      # age-class based survival rates
        # juveniles
      survivors.juv <- survivors [age == 1 & !is.na (d2_score), ]
      if (nrow (survivors.juv) > 0) {
       for (i in unique (survivors.juv$fisher_pop)) { 
        survivors.juv <- survivors.juv [fisher_pop == i, 
                                        survive := rbinom (n = nrow (survivors.juv [fisher_pop == i]),
                                                           size = 1,
                                                           prob = rnorm (1, 
                                                                         mean = sim$survival_rate_table [Fpop == i & age == 'Juvenile', Mean], 
                                                                         sd = sim$survival_rate_table [Fpop == i & age == 'Juvenile', SD]))]
      } 
      } else {
        survivors.juv$survive <- 0 
     }
        
        # adults
      survivors.ad <- survivors [age > 1 & !is.na (d2_score), ]
      if (nrow (survivors.ad) > 0) {
       for (i in unique (survivors.ad$fisher_pop)) { 
        survivors.ad <- survivors.ad [fisher_pop == i, 
                                      survive := rbinom (n = nrow (survivors.ad [fisher_pop == i]),
                                                         size = 1,
                                                         prob = rnorm (1, 
                                                                       mean = sim$survival_rate_table [Fpop == i & age == 'Adult', Mean], 
                                                                       sd =  sim$survival_rate_table [Fpop == i & age == 'Adult', SD]))]
       }
       }else {
        survivors.ad$survive <- 0 
      }
          
        # dispersers
      survivors.disp <- survivors [age > 0 & !is.na (d2_score), ]
      if (nrow (survivors.disp) > 0) {
        for (i in unique (survivors.disp$fisher_pop)) { 
        survivors.disp <- survivors.disp [fisher_pop == i, 
                                         survive := rbinom (n = nrow (survivors.disp [fisher_pop == i]),
                                                            size = 1,
                                                            prob = rnorm (1, 
                                                                          mean = sim$survival_rate_table [Fpop == i & age == 'Disperser', Mean], 
                                                                          sd =  sim$survival_rate_table [Fpop == i & age == 'Disperser', SD]))]
        }
        } else {
        survivors.disp [, survive := 0] 
      }  
        
        
      # kits
      # they all survive?
      survivors.kit <- survivors [age == 0, ]
      survivors.kit [, survive := 1]
      
      # recombine the data
      survivors.all <- rbind (survivors.ad, survivors.juv, survivors.disp, survivors.kit)
      
      # remove the 'dead' individuals
      survivors.all <- survivors.all [survive == 1, ]
      survivors.all$survive <- NULL
      sim$agents <- sim$agents [individual_id %in% survivors.all$individual_id]
      # agents <- agents [pixelid %in% survivors$pixelid] # use this if we decide to kill the kits of mothers that do not survive; young share the same pixelid as mother
      sim$territories <- sim$territories [individual_id %in% survivors.all$individual_id] # remove territories
      
      # this is where we age the fisher; survivors age 1 year
      sim$agents$age <- sim$agents$age + 1 # time interval?
      
      message ("Fishers survived and aged one year.")
      message ("Fisher annual time step complete.")
      
    }

  return (invisible (sim))
}


###--- SAVE
saveAgents <- function (sim) {
  message ("Save the agents and territories.")
  # save the agents table
  # currently saving the number of agents and age of agents
    # divide by number of iterations (i.e., the 'weight' of an iteration)
    # then in post-processing, to calculate each value, sum by time step and scenario 
  new.agents.save <- data.table (n_f_adult = as.numeric (nrow (sim$agents [sex == "F" & age > 1 & !is.na (d2_score), ]) / P(sim, "iterations", "abmfisherCASTOR")), 
                                 n_f_juv = as.numeric (nrow (sim$agents [sex == "F" & age == 1 & !is.na (d2_score), ]) / P(sim, "iterations", "abmfisherCASTOR")), 
                                 n_f_disperse = as.numeric (nrow (sim$agents [sex == "F" & age > 0 & !is.na (d2_score), ]) / P(sim, "iterations", "abmfisherCASTOR")), 
                                 mean_age_f = as.numeric (mean (c (sim$agents [sex == "F", age]) / P(sim, "iterations", "abmfisherCASTOR"))), 
                                 sd_age_f = as.numeric (sd (c (sim$agents [sex == "F", age]) / P(sim, "iterations", "abmfisherCASTOR"))), 
                                 timeperiod = as.integer (time(sim)*sim$updateInterval), 
                                 scenario = as.character (sim$scenario$name),
                                 compartment = as.character (sim$boundaryInfo[[3]])
                                 )
  sim$fisherABMReport <- rbindlist (list (sim$fisherABMReport, 
                                          new.agents.save), 
                                    use.names = TRUE)
  
  # save the territories
    # set a territory as value = 1 divide by the number of iterations (weight)
    # add it to the existing territories
    # final raster is the number of time periods that a pixel was a territory
  ras.territories.update <- sim$ras
  ras.territories.update [] <- 0
  ras.territories.update [sim$territories$pixelid] <- 1 / P(sim, "iterations", "abmfisherCASTOR")
  sim$ras.territories <- sim$ras.territories + ras.territories.update
  writeRaster (x = sim$ras.territories, 
               filename = paste0 (outputPath (sim), "/", sim$scenario$name, "_", sim$boundaryInfo[[3]][[1]],"_fisherterritories.tif"), 
               overwrite = TRUE)
  # clean-up
  rm (ras.territories.update, new.agents.save)
  
    # use below if want to save the agents table
      # if(nrow(dbGetQuery(sim$castordb, "SELECT name FROM sqlite_schema WHERE type ='table' AND name = 'agents';")) == 0){
      #   # if the table exists, write it to the db
      #   DBI::dbWriteTable (sim$castordb, "agents", agents.save, append = FALSE,
      #                      row.names = FALSE, overwrite = FALSE)
      # } else {
      #   # if the table exists, append it to the table in the db
      #   DBI::dbWriteTable (sim$castordb, "agents", agents.save, append = TRUE,
      #                      row.names = FALSE, overwrite = FALSE)
      # }
  
  
    # use below if want to save the territories table
      # territories.save <- sim$territories
      # territories.save [, c("timeperiod", "scenario") := list (time(sim)*sim$updateInterval, sim$scenario$name)  ] # add the time of the calc
      # 
      # if(nrow(dbGetQuery (sim$castordb, "SELECT name FROM sqlite_schema WHERE type ='table' AND name = 'territories';")) == 0){
      #   # if the table exists, write it to the db
      #   DBI::dbWriteTable (sim$castordb, "territories", territories.save, append = FALSE,
      #                      row.names = FALSE, overwrite = FALSE)
      # } else {
      #   # if the table exists, append it to the table in the db
      #   DBI::dbWriteTable (sim$castordb, "territories", territories.save, append = TRUE,
      #                      row.names = FALSE, overwrite = FALSE)
      # }
  message ("Save fisher agents and territories complete.")
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

spreadRast <- function (rasterInput, habitatInput) {
  spread.rast <- rasterInput
  # currently uses all denning, rust, cavity, cwd and movement habitat as 
  # spreadProb = 1, and non-habitat as spreadProb = 0.10; allows some spread to sub-optimal habitat
  habitatInput [denning == 1 | rust == 1 | cavity == 1 | cwd == 1 | movement == 1, spreadprob := format (round (1.00, 2), nsmall = 2)] # throws error, but it works
  habitatInput [is.na (spreadprob), spreadprob := format (round (0.18, 2), 2)] # I tested different numbers
  # 18% resulted in the mean proportion of home ranges consisting of denning, resting or movement habitat as 55%; 19 was 49%; 17 was 59%; 20 was 47%; 15 was 66%
  # Caution: this parameter may be area-specific and may need to be and need to be 'tuned' for each AOI
  spread.rast [habitatInput$pixelid] <- habitatInput$spreadprob
  return (spread.rast)	
}

habitatQual <- function (inputTable, agentsTable, d2Table) {
  tab.perc <- Reduce (function (...) merge (..., all = TRUE, by = "individual_id"), 
                      list (inputTable [, .(den_perc = ((sum (denning, na.rm = T)) / .N) * 100), by = individual_id ], 
                            inputTable [, .(rust_perc = ((sum (rust, na.rm = T)) / .N) * 100), by = individual_id ], 
                            inputTable [, .(cav_perc = ((sum (cavity, na.rm = T)) / .N) * 100), by = individual_id ], 
                            inputTable [, .(move_perc = ((sum (movement, na.rm = T)) / .N) * 100), by = individual_id ], 
                            inputTable [, .(cwd_perc = ((sum (cwd, na.rm = T)) / .N) * 100), by = individual_id ]))
  tab.perc <- merge (tab.perc, 
                     agentsTable [, c ("individual_id", "fisher_pop")],
                     by = "individual_id", all.x = T)
  # log transform the data
  tab.perc [fisher_pop == 2 & den_perc >= 0, den_perc := log (den_perc + 1)][fisher_pop == 1 & cav_perc >= 0, cavity := log (cav_perc + 1)] # sbs-wet
  tab.perc [fisher_pop == 3 & den_perc >= 0, den_perc := log (den_perc + 1)]# sbs-dry
  tab.perc [fisher_pop == 1 | fisher_pop == 4 & rust_perc >= 0, rust_perc := log (rust_perc + 1)] #boreal and dry
  # truncate at the center plus one st dev
  stdev_pop1 <- sqrt (diag (d2Table[[1]])) # boreal
  stdev_pop2 <- sqrt (diag (d2Table[[2]])) # sbs-wet
  stdev_pop3 <- sqrt (diag (d2Table[[3]])) # sbs-dry
  stdev_pop4 <- sqrt (diag (d2Table[[4]])) # dry
  
  tab.perc [fisher_pop == 1 & den_perc > 24  + stdev_pop1[1], den_perc := 24 + stdev_pop1[1]][fisher_pop == 1 & rust_perc > 2.2 + stdev_pop1[2], rust_perc := 2.2 + stdev_pop1[2]][fisher_pop == 1 & cwd_perc > 17.4 + stdev_pop1[3], cwd_perc := 17.4 + stdev_pop1[3]][fisher_pop == 1 & move_perc > 56.2 + stdev_pop1[4], move_perc := 56.2 + stdev_pop1[4]]
  tab.perc [fisher_pop == 2 & den_perc > 1.6 + stdev_pop2[1], den_perc := 1.6 + stdev_pop2[1]][fisher_pop == 2 & rust_perc > 36.2 + stdev_pop2[2], rust_perc := 36.2 + stdev_pop2[2]][fisher_pop == 2 & cav_perc > 0.7 + stdev_pop2[3], cav_perc := 0.7 + stdev_pop2[3]][fisher_pop == 2 & cwd_perc > 30.4 + stdev_pop2[4], cwd_perc := 30.4 + stdev_pop2[4]][fisher_pop == 2 & move_perc > 26.8 + stdev_pop2[5], move_perc := 26.8+ stdev_pop2[5]]
  tab.perc [fisher_pop == 3 & den_perc > 1.2 + stdev_pop3[1], den_perc := 1.2 + stdev_pop3[1]][fisher_pop == 3 & rust_perc > 19.1 + stdev_pop3[2], rust_perc := 19.1 + stdev_pop3[2]][fisher_pop == 3 & cav_perc > 0.5 + stdev_pop3[3], cav_perc := 0.5 + stdev_pop3[3]][fisher_pop == 3 & cwd_perc > 10.2 + stdev_pop3[4], cwd_perc := 10.2 + stdev_pop3[4]][fisher_pop == 3 & move_perc > 33.1 + stdev_pop3[5], move_perc := 33.1+ stdev_pop3[5]]
  tab.perc [fisher_pop == 4 & den_perc > 2.3 + stdev_pop4[1], den_perc := 2.3 + stdev_pop4[1]][fisher_pop == 4 & rust_perc > 1.6 +  stdev_pop4[2], rust_perc := 1.6  + stdev_pop4[2]][fisher_pop == 4 & cwd_perc > 10.8 + stdev_pop4[3], cwd_perc := 10.8 + stdev_pop4[3]][fisher_pop == 4 & move_perc > 21.5 + stdev_pop4[4], move_perc := 21.5+ stdev_pop4[4]]
  
  tab.perc [fisher_pop == 1, d2 := mahalanobis (tab.perc [fisher_pop == 1, c ("den_perc", "rust_perc", "cwd_perc", "move_perc")], c(24.0, 2.2, 17.4, 56.2), cov = d2Table[[1]])]
  tab.perc [fisher_pop == 2, d2 := mahalanobis (tab.perc [fisher_pop == 2, c ("den_perc", "rust_perc", "cav_perc", "cwd_perc", "move_perc")], c(1.6, 36.2, 0.7, 30.4, 26.8), cov = d2Table[[2]])]
  tab.perc [fisher_pop == 3, d2 := mahalanobis (tab.perc [fisher_pop == 3, c ("den_perc", "rust_perc", "cav_perc", "cwd_perc", "move_perc")], c(1.16, 19.1, 0.45, 8.69, 33.06), cov = d2Table[[3]])]
  tab.perc [fisher_pop == 4, d2 := mahalanobis (tab.perc [fisher_pop == 4, c ("den_perc", "rust_perc", "cwd_perc", "move_perc")], c(2.3, 1.6, 10.8, 21.5), cov = d2Table[[4]])]
  return (tab.perc)
}

litterSize <- function (fisherPop, mahalTable, reproTable){
  for (i in unique (reproFishers$individual_id)) {
    reproFishers [fisher_pop == fisherPop & d2_score < mahalTable [FHE_zone_num == fisherPop, Mean], 
                  kits := as.integer (rpois (n = 1, # should be a Poisson distribution rpois()
                                             lambda = reproTable [Fpop == fisherPop & Param == 'LS', Mean]))]
    reproFishers [fisher_pop == fisherPop & d2_score > mahalTable [FHE_zone_num == fisherPop, Mean] & d2_score < (mahalTable [FHE_zone_num == fisherPop, Mean] + mahalTable [FHE_zone_num == fisherPop, SD]), 
                  kits := as.integer (rpois (n = 1, # should be a Poisson distribution rpois()
                                             lambda = (reproTable [Fpop == fisherPop & Param == 'LS', Mean] * 0.75)))]
    reproFishers [fisher_pop == fisherPop & d2_score > (mahalTable [FHE_zone_num == fisherPop, Mean] + mahalTable [FHE_zone_num == fisherPop, SD]) & d2_score <+ (mahalTable [FHE_zone_num == fisherPop, Mean] + (2 * mahalTable [FHE_zone_num == fisherPop, SD])), 
                  kits := as.integer (rpois (n = 1, # should be a Poisson distribution rpois()
                                             lambda = (reproTable [Fpop == fisherPop & Param == 'LS', Mean] * 0.50)))]
    reproFishers [fisher_pop == fisherPop & d2_score > (mahalTable [FHE_zone_num == fisherPop, Mean] + (2 * mahalTable [FHE_zone_num == fisherPop, SD])), 
                  kits := as.integer (rpois (n = 1, # should be a Poisson distribution rpois()
                                             lambda = (reproTable [Fpop == fisherPop & Param == 'LS', Mean] * 0)))]
  }
  return (reproFishers)
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
                         srcRaster = P (sim, "nameCompartmentRaster", "dataCASTOR"), 
                         clipper = P (sim, "nameBoundaryFile", "dataCASTOR" ), 
                         geom = P (sim, "nameBoundaryGeom", "dataCASTOR"), 
                         where_clause =  paste0 ( P (sim, "nameBoundaryColumn", "dataCASTOR"), " in (''", paste(P(sim, "nameBoundary", "dataCASTOR"), sep = "' '", collapse= "'', ''") ,"'')"),
                         conn = NULL) 
  }
  
  ###---INPUT TABLES - Edit as needed
  sim$fisher_d2_cov <- list(matrix(c(193.2,	5.4,	42.1,	125.2, 5.4,	0.4,	2.,	5.2, 42.1,	2.9,	36.0,	46.5, 125.2,	5.2, 46.5,	131.4), ncol = 4, nrow = 4), # 1- boreal
                            matrix(c(0.5,	2.7,	0.6,	3.2,	-6.5, 2.7,	82.7,	4.9,	83.3,	-75.8, 0.6,	4.9,	0.9,	4,	-7.1, 3.2,	83.3,	4,	101.3,	-100.4, -6.5,	-75.8,	-7.1,	-100.4,	156.2), ncol = 5, nrow =5), # 2- sbs-wet
                            matrix(c(0.5,	-1.9,	-0.14288,	2.57677,	-3.82, -1.908,	96.76,	-0.71,	-2.669,	57.27, -0.143,	-0.71,	0.208,	-1.059,	1.15, 2.57,	-2.6,	-1.059,	56.29,	-4.85, -3.82,	57.27,	1.15,	-4.85,	77.337), ncol =5, nrow =5), # 3 sbs-dry
                            matrix(c(0.7,	0.5,	6.1,	2.1, 0.5,	2.9,	4.0,	5.2, 6.1,	4.0,	62.6,	22.4, 2.1,	5.2,	22.4,	42.3), ncol=4, nrow=4) # 4 - Dr
                            )
  
  sim$survival_rate_table <- data.table (Fpop = c (1,1,1,2,2,2,3,3,3,4,4,4),
                                         age = c ("Adult", "Juvenile", "Disperser", "Adult", "Juvenile", "Disperser", "Adult", "Juvenile", "Disperser", "Adult", "Juvenile", "Disperser"),
                                         Mean = c (0.8, 0.6, 0.6, 0.8, 0.6, 0.6, 0.8, 0.6, 0.6, 0.8, 0.6, 0.6),
                                         SD = c (0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1))
  
  sim$repro_rate_table <- data.table (Fpop = c(1,1,2,2,3,3,4,4),
                                      Param = c("DR", "LS","DR", "LS","DR", "LS","DR", "LS"),
                                      Mean = c(0.5,3,0.5,3,0.5,3,0.5,3),
                                      SD = c(0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1))
  
  sim$female_hr_table <- data.table (fisher_pop = c (1:4), 
                                     hr_mean = c (3000, 4500, 4500, 3000),
                                     hr_sd = c (500, 500, 500, 500))
  
  sim$mahal_metric_table <- data.table (FHE_zone = c ("Boreal", "Sub-Boreal moist", "Sub-Boreal dry", "Dry Forest"),
                                        FHE_zone_num = c (1:4),
                                        Mean = c (3.8, 4.4, 4.4, 3.6),
                                        SD = c (2.71, 1.09, 2.33, 1.62),
                                        Max = c (9.88, 6.01, 6.63, 7.5))
  
  
  
  
  # ! ----- STOP EDITING ----- ! #
  return(invisible(sim))
}

