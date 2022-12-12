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
  name = "FLEX2",
  description = "An agent based model (ABM) to simulate fisher life history on a landscape.",
  keywords = "fisher, martes, agent based model",
  authors = structure(list(list(given = c("First", "Middle"), family = "Last", role = c("aut", "cre"), email = "email@example.com", comment = NULL)), class = "person"),
  childModules = character(0),
  version = list(FLEX2 = "0.0.0.9000"),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.md", "FLEX2.Rmd"), ## same file
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
    defineParameter("reproductive_age", "numeric", 2, 0, 9,
                    "The minimum reproductive age of a fisher."),
    defineParameter("female_dispersal", "numeric", 785000, 100, 10000000,
                    "The area, in hectares, a fisher could explore during a dispersal to find a territory."),
    defineParameter("iterations", "numeric", 1, 1, 10000,
                    "Number of times to repeat the simulation."),
    defineParameter("rasterStack", "character", paste0 (here::here(), "/R/scenarios/test_flex2/test_Williams_Lake_TSA_fisher_habitat.tif"), NA, NA,
                    "Directory where the fisher habitat raster .tif is stored. Used as habitat input to this module. A band in teh .tif exists for each time interval simulated in forestryCASTOR, and each fisher habitat type (denning, movement, cwd, rust, cavity)."), # create a default somewhere??
    defineParameter("timeInterval", "numeric", 1, 1, 20,
                    "The time step, in years, when habtait was updated. It should be consistent with periodLength form growingStockCASTOR. Life history events (reproduce, updateHR, survive, disperse) are calaculated this many times for each interval."),
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
    expectsInput (objectName = "fisher_d2_cov", objectClass = "data.table", desc = "variance matrix for mahalanobis distance model; don't touch this unless d2 model updated", sourceURL = NA),
    expectsInput (objectName = "survival_rate_table", objectClass = "data.table", desc = "Table of fisher survival rates by sex, age and population, taken from Lofroth et al 2022 JWM vital rates manuscript. Headers: Fpop: the two populations in BC: Boreal, Coumbian; Age_class: two classes: Adult, Juvenile; Cohort: Fpop and Age_class combination: CFA, CFJ, BFA, BFJ; Mean: mean survival probability; SE: standard error of the mean. Decided to go with SE rather than SD as confidence intervals are quite wide and stochasticity would likely drive populations to extinction. Keeping consistent with Rory Fogarty's population analysis decisions.", sourceURL = NA),
    expectsInput (objectName = "repro_rate_table", objectClass = "data.table", desc = "Table of fisher reproductive rates (i.e., denning rate = a combination of pregnancy rate and birth rate; and litter size = number of kits) by population, taken from Lofroth et al 2022 JWM vital rates manuscript. Headers: Fpop: the two populations in BC: Boreal, Coumbian; Param: the reproductive parameter: DR (denning rate), LS (litter size); Mean: mean reproductive rate per parameter and population; SD: reproductive rate standard deviation value per parameter and population.", sourceURL = NA),
    expectsInput (objectName = "female_hr_table", objectClass = "data.table", desc = "Table of female home range sizes, by fisher population.", sourceURL = NA),
    expectsInput (objectName = "mahal_metric_table", objectClass = "data.table", desc = "Table of mahalanobis D2 values based on Fisher Habitat Extension zones, provided by Rich Weir summer 2022. Headers: FHE_zone: the four fisher habitat extension zones: Boreal, Sub-Boreal moist, Sub-Boreal dry, Dry Forest; FHE_zone_num: the corresponding FHE_zone number: Boreal = 1, Sub-Boreal moist = 2, Sub-Boreal Dry = 3, Dry Forest = 4; Mean: mean mahalanobis D2 value per FHE zone; SD: mahalanobis D2 standard deviation value per FHE zone; Max: maximum mahalanobis D2 value per FHE zone.", sourceURL = NA),
    expectsInput (objectName = "scenario", objectClass = "data.table", desc = "Table of scenario description.", sourceURL = NA),
    ),
  outputObjects = bindrows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    #createsOutput (objectName = NA, objectClass = NA, desc = NA)
    createsOutput (objectName = "agents", objectClass = "data.table", desc = "Fisher agents table." ),
    createsOutput (objectName = "territories", objectClass = "data.table", desc = "Fisher territories table." ),
    createsOutput (objectName = "pix.rast", objectClass = "SpatRaster", desc = "A raster dataset of pixel values in the area of interest." ),
    createsOutput (objectName = "raster.stack", objectClass = "SpatRaster", desc = "The habitat data as a raster stack." ),
    createsOutput (objectName = "ras.territories", objectClass = "SpatRaster", desc = "The territories over a sim." ),
    createsOutput (objectName = "fisherABMReport", objectClass = "data.table", desc = "A data.table object. Consists of fisher population numbers in the study area at each time step."),
    )
))

## event types

doEvent.FLEX2 = function (sim, eventTime, eventType) {
  switch(
    eventType,
    
    init = {
      sim <- Init (sim)
      sim <- saveAgents (sim)
      sim <- scheduleEvent (sim, time (sim) + 1, "FLEX2", "runevents", 19)
      sim <- scheduleEvent (sim, end (sim), "FLEX2", "save", 20)
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
    #   sim <- scheduleEvent(sim, time(sim) + P(sim, "timeInterval", "FLEX2"), "FLEX2", "reproduce", 20)
    #   
    # },
   runevents = {
      sim <- updateHabitat (sim)
      sim <- annualEvents (sim)
      sim <- updateAgents (sim)
      sim <- scheduleEvent (sim, time(sim) + 1, "FLEX2", "runevents", 19)
    },
   
   save = {
      sim <- saveAgents (sim)
    },
   
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
                  "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'", sep = ""))
  )
  return(invisible(sim))
}


## event functions
Init <- function(sim) {
  
  message ("Initiating fisher ABM...")
  
  message ("Get the area of interest ...")
  # get pixel id's for aoi 
  # add the pixelid step to fisher habitat loader
  
  message ("Load the habitat data.")
  sim$raster.stack <- terra::rast (P (sim, "rasterStack", "FLEX2")) 

  # get the pixel id raster
  sim$pix.rast <- terra::subset (sim$raster.stack,
                                 grep ("pixelid", 
                                        names (sim$raster.stack)))
 
  # grab the init data and fisher pop data only; convert to a table
  raster.stack.init <- terra::subset (sim$raster.stack,
                                      grep ("pixelid|init|fisher_pop", 
                                            names (sim$raster.stack)))
  table.habitat.init <- na.omit (as.data.table (raster.stack.init []))
  table.habitat.init <- table.habitat.init [ras_fisher_pop > 0, ]
  table.habitat.init$ras_fisher_pop <- as.numeric (table.habitat.init$ras_fisher_pop)
  
  # instantiate table and raster for saving data
  message ("Initializing the fisher report.")
  
  sim$fisherABMReport <- data.table (n_f_adult = as.numeric (), # number of adult females
                                     n_f_juv = as.numeric (), # number of juvenile females
                                     mean_age_f = as.numeric (), # mean age of females
                                     sd_age_f = as.numeric (), # standard dev age of females
                                     timeperiod = as.integer (), # time step of the simulation
                                     scenario = as.character ()
  )
  
  sim$ras.territories <- sim$pix.rast
  sim$ras.territories [] <- 0

  message ("Create fisher agents table and assign values...")
  
  # assign agents to denning pixels
    
  # dennign habitat
      # select the init denning raster
  den.pix <- table.habitat.init [ras_fisher_denning_init == 1, c ("pixelid", "ras_fisher_denning_init")]
      # sample the pixels where there is denning habitat
  den.pix.sample <- den.pix [seq (1, nrow (den.pix), 50), ] # grab every ~50th pixel; ~1 pixel every 5km

  # create agents table  
  sim$agents <- data.table (individual_id = seq (from = 1, to = nrow (den.pix.sample), by = 1),
                            sex = "F",
                            age = sample (1:P (sim, "female_max_age", "FLEX2"), length (seq (from = 1, to = nrow (den.pix.sample), by = 1)), replace = T), # randomly draw ages between 1 and the max age,
                            pixelid = den.pix.sample$pixelid)
  

    # user-defined method; allow user to pick the # of agents
      # ids <- seq (from = 1, to = P(sim, "n_females", "FLEX2"), by = 1) # sequence of individual id's from 1 to n_females
      # agents <- data.table (individual_id = ids, 
      #                       sex = "F", 
      #                       age = sample (1:P(sim, "max_age", "FLEX2"), length (ids), replace = T), # randomly draw ages between 1 and the max age, 
      #                       pixelid = numeric (), 
      #                       hr_size = numeric (),
      #                       d2_score = numeric ())
      # 
      # assign a random starting location that is a denning pixel in population range
      # agents$pixelid <- sample (den.pix.sample [, pixelid], length (ids), replace = T)
  
  # assign the population
  tab.fisher.pop <- table.habitat.init [ras_fisher_pop > 0, c ("pixelid", "ras_fisher_pop")]
  names (tab.fisher.pop) <- c ("pixelid", "fisher_pop")
  tab.fisher.pop$fisher_pop <- as.numeric (tab.fisher.pop$fisher_pop)
  sim$agents <- merge (sim$agents, 
                       tab.fisher.pop [ , c("pixelid", "fisher_pop")], 
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
  table.hab.spread <- table.habitat.init [ras_fisher_pop > 0, 
                                         c ("pixelid", "ras_fisher_denning_init", "ras_fisher_rust_init", "ras_fisher_cavity_init", "ras_fisher_cwd_init", "ras_fisher_movement_init")]
  names (table.hab.spread) <- c ("pixelid", "denning", "rust", "cavity", "cwd", "movement")
  
  # convert to raster objects for spread2
  sim$pix.raster <- raster::raster (sim$pix.rast)
  sim$spread.rast <- spreadRast (sim$pix.raster, # see function below
                                 table.hab.spread) 

  table.hr <- SpaDES.tools::spread2 (sim$pix.raster, # within the area of interest
                                     start = sim$agents$pixelid, # for each individual
                                     spreadProb = as.numeric (sim$spread.rast[]), # use spread prob raster; index [] speeds up the process
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
                     table.hab.spread [, c ("pixelid", "denning", "rust", "cavity", "cwd", "movement")],
                     by.x = "pixels", by.y = "pixelid")

  # check to see if home range target was within 2 SD's of the mean; if not, remove the animal 
  table.hr [, pix.count := sum (length (pixels)), by = individual_id]
  pix.count <- merge (sim$agents [, c ("pixelid", "individual_id", "hr_size", "fisher_pop")],
                      table.hr [, c ("pixels", "pix.count")],
                      by.x = "pixelid", by.y = "pixels",
                      all.x = T)
  
  # for each fisher population
  pix.count.ids <- c (unique (pix.count [fisher_pop == 1, ]$individual_id))
  if (length (pix.count.ids) > 0) {
    for (i in 1:length (pix.count.ids)) { # for each individual
      if (pix.count [fisher_pop == 1 & individual_id == pix.count.ids[i], pix.count] >= (sim$female_hr_table [fisher_pop == 1, hr_mean] - (2 * sim$female_hr_table [fisher_pop == 1, hr_sd])) & pix.count [fisher_pop == 1 & individual_id == pix.count.ids[i], pix.count] <= (sim$female_hr_table [fisher_pop == 1, hr_mean] + (2 * sim$female_hr_table [fisher_pop == 1, hr_sd]))) { 
        # if it achieves its home range size +/- 2 SD  
        # do nothing; we need to check if it meets min. habitat criteria (see below)
      } else {
        # delete the individual from the agents and territories table
        sim$territories <- sim$territories [individual_id != pix.count.ids[i]] 
        sim$agents <- sim$agents [individual_id != pix.count.ids[i]]
      } 
    }
  }

  pix.count.ids <- c (unique (pix.count [fisher_pop == 2, ]$individual_id))
  if (length (pix.count.ids) > 0) {
   for (i in 1:length (pix.count.ids)) { # for each individual
    if (pix.count [fisher_pop == 2 & individual_id == pix.count.ids[i], pix.count] >= (sim$female_hr_table [fisher_pop == 2, hr_mean] - (2 * sim$female_hr_table [fisher_pop == 2, hr_sd])) & pix.count [fisher_pop == 2 & individual_id == pix.count.ids[i], pix.count] <= (sim$female_hr_table [fisher_pop == 2, hr_mean] + (2 * sim$female_hr_table [fisher_pop == 2, hr_sd]))) { 
      
    } else {
      sim$territories <- sim$territories [individual_id != pix.count.ids[i]] 
      sim$agents <- sim$agents [individual_id != pix.count.ids[i]]
    } 
   }
  }
  
  pix.count.ids <- c (unique (pix.count [fisher_pop == 3, ]$individual_id))
  if (length (pix.count.ids) > 0) {
   for (i in 1:length (pix.count.ids)) { # for each individual
    if (pix.count [fisher_pop == 3 & individual_id == pix.count.ids[i], pix.count] >= (sim$female_hr_table [fisher_pop == 3, hr_mean] - (2 * sim$female_hr_table [fisher_pop == 3, hr_sd])) & pix.count [fisher_pop == 3 & individual_id == pix.count.ids[i], pix.count] <= (sim$female_hr_table [fisher_pop == 3, hr_mean] + (2 * sim$female_hr_table [fisher_pop == 3, hr_sd]))) { 
    
    } else {
      sim$territories <- sim$territories [individual_id != pix.count.ids[i]] 
      sim$agents <- sim$agents [individual_id != pix.count.ids[i]]
    } 
   }
  } 
  
  pix.count.ids <- c (unique (pix.count [fisher_pop == 4, ]$individual_id))
  if (length (pix.count.ids) > 0) {
   for (i in 1:length (pix.count.ids)) { # for each individual
    if (pix.count [fisher_pop == 4 & individual_id == pix.count.ids[i], pix.count] >= (sim$female_hr_table [fisher_pop == 4, hr_mean] - (2 * sim$female_hr_table [fisher_pop == 4, hr_sd])) & pix.count [fisher_pop == 4 & individual_id == pix.count.ids[i], pix.count] <= (sim$female_hr_table [fisher_pop == 4, hr_mean] + (2 * sim$female_hr_table [fisher_pop == 4, hr_sd]))) { 
      
    } else {
      sim$territories <- sim$territories [individual_id != pix.count.ids[i]] 
      sim$agents <- sim$agents [individual_id != pix.count.ids[i]]
    } 
   }
  }


  # check to see if minimum habitat target was met (prop habitat = 0.15); if not, remove the animal 
  hab.count <- table.hr [denning == 1 | rust == 1 | cavity == 1 |cwd == 1 | movement == 1, .(.N), by = individual_id]
  hab.count <- merge (hab.count,
                      sim$agents [, c ("hr_size", "individual_id")],
                      by = "individual_id")
  hab.count$prop_hab <- as.numeric (hab.count$N / hab.count$hr_size)
  
  hab.inds <- c (unique (hab.count$individual_id))
  
  for (i in 1:length (hab.inds)) { # for each individual
    if (hab.count [individual_id == hab.inds[i], prop_hab] >= 0.15) { 
      # if it achieves its home range size and minimum habitat targets 
      # do nothing; we still need to check if it meets min. habitat criteria (see below)
    } else {
      # delete the individual from the agents and territories table
      sim$territories <- sim$territories [individual_id != hab.inds[i]] 
      sim$agents <- sim$agents [individual_id != hab.inds[i]]
    } 
  }

  # check if proportion of habitat types are greater than the minimum thresholds 
  ind.ids <- c (unique (sim$agents$individual_id))

  for (i in 1:length (ind.ids)) { # for each individual
  
    rest.prop <- (nrow (table.hr [individual_id == ind.ids[i] & rust == 1]) + nrow (table.hr [individual_id == ind.ids[i] & cavity == 1]) + nrow (table.hr [individual_id == ind.ids[i] & cwd == 1])) / sim$agents [individual_id == ind.ids[i], hr_size]
    move.prop <- nrow (table.hr [individual_id == ind.ids[i] & movement == 1]) / sim$agents [individual_id == ind.ids[i], hr_size] 
    den.prop <- nrow (table.hr [individual_id == ind.ids[i] & denning == 1]) / sim$agents [individual_id == ind.ids[i], hr_size]
    
    if (length (rest.prop) != 0 & length (move.prop) != 0 & length (den.prop) != 0) { # check the proportion values are not NA's
    
      if (P(sim, "rest_target", "FLEX2") <= rest.prop & P(sim, "move_target", "FLEX2") <= move.prop & P(sim, "den_target", "FLEX2") <= den.prop) {
        # check to see it meets all thresholds
        # assign the pixels to territories table
        sim$territories <- rbind (sim$territories, table.hr [individual_id == ind.ids[i], .(pixelid = pixels, individual_id)]) 
        
        } else {
          # delete the individual from the agents and territories table
          sim$territories <- sim$territories [individual_id != (sim$agents [individual_id == ind.ids[i], individual_id]), ] 
          sim$agents <- sim$agents [individual_id != ind.ids[i],]
      } 
    } else {
      # delete the individual from the agents and territories table
      sim$territories <- sim$territories [individual_id != (sim$agents [individual_id == ind.ids[i], individual_id]), ] 
      sim$agents <- sim$agents [individual_id != ind.ids[i],] 
   }
  }
  
  #---Calculate D2 (Mahalanobis) 
  message ("Calculate habitat quality of fisher territories.")
      # identify which fisher pop an animal belongs to
  
  terr.pop <- merge (sim$territories, tab.fisher.pop [ , c("pixelid", "fisher_pop")], 
                      by = "pixelid", all.x = T)
    # get the mean of pixels pop. values, rounded to get the majority; majority = pop membership
  terr.pop [, fisher_pop := .(round (mean (fisher_pop, na.rm = T), digits = 0)), by = individual_id] 
  terr.pop <- unique (terr.pop [, c ("individual_id", "fisher_pop")])
  terr.pop$fisher_pop <- as.numeric (terr.pop$fisher_pop)
  sim$agents <- merge (sim$agents [, -c ("fisher_pop")], # assign new fisher_pop to agents table
                       terr.pop [, c ("individual_id", "fisher_pop")], 
                       by = "individual_id", all.x = T)
 
  # get habitat for mahalanobis
  tab.mahal <- merge (sim$territories, 
                      table.hab.spread [, c ("pixelid", "denning", "rust", "cavity", "movement", "cwd")], 
                      by = "pixelid", all.x = T)

  # calculate habitat quality 
  tab.perc <- habitatQual (tab.mahal, sim$agents, sim$fisher_d2_cov)
  
  sim$agents <- merge (sim$agents,
                       tab.perc [, .(individual_id, d2_score = d2)],
                       by = "individual_id")
  
  # save the largest individual id; need this later for setting id's of kits
  sim$max.id <- max (sim$agents$individual_id)

  # save
  new.agents.save <- data.table (n_f_adult = as.numeric (nrow (sim$agents [sex == "F" & age > 1, ])), 
                                 n_f_juv = as.numeric (nrow (sim$agents [sex == "F" & age == 1, ])), 
                                 mean_age_f = as.numeric (mean (c (sim$agents [sex == "F", age]))), 
                                 sd_age_f = as.numeric (sd (c (sim$agents [sex == "F", age]))), 
                                 timeperiod = as.integer (time(sim) * P (sim, "timeInterval", "FLEX2")), 
                                 scenario = as.character (sim$scenario$name))

  sim$fisherABMReport <- rbindlist (list (sim$fisherABMReport, 
                                          new.agents.save), 
                                    use.names = TRUE)
  # territories raster
  # set a territory as value = 1 
  # add it to the existing territories
  # final raster is the number of time periods that a pixel was a territory
  ras.territories.update <- sim$pix.rast
  ras.territories.update [] <- 0
  ras.territories.update [sim$territories$pixelid] <- 1
  sim$ras.territories <- sim$ras.territories + ras.territories.update

  browser()
  
    # clean-up
  rm (ras.territories.update, new.agents.save)
  
  message ("Territories and agents created!")
  
  return (invisible (sim))
}


###--- UPDATE HABITAT
updateHabitat <- function (sim) {
  
  message ("Update fisher habitat data...")
  # 1. update the habitat data in the territories
  # subset data for the time interval
  cols <- c ("pixelid", "ras_fisher_pop",  
             paste0 ("ras_fisher_denning_", (time(sim) * P (sim, "timeInterval", "FLEX2"))), 
             paste0 ("ras_fisher_rust_", (time(sim) * P (sim, "timeInterval", "FLEX2"))), 
             paste0 ("ras_fisher_cavity_", (time(sim) * P (sim, "timeInterval", "FLEX2"))), 
             paste0 ("ras_fisher_cwd_", (time(sim) * P (sim, "timeInterval", "FLEX2"))), 
             paste0 ("ras_fisher_movement_", (time(sim) * P (sim, "timeInterval", "FLEX2"))))
  raster.stack.update <- terra::subset (sim$raster.stack,
                                        cols)
  # convert data to table
  sim$table.hab.update <- na.omit (as.data.table (raster.stack.update []))
  sim$table.hab.update <- sim$table.hab.update [ras_fisher_pop > 0, ]
  sim$table.hab.update$ras_fisher_pop <- as.numeric (sim$table.hab.update$ras_fisher_pop)
  names (sim$table.hab.update) <- c ("pixelid", "fisher_pop", "denning", "rust", "cavity",
                                 "cwd", "movement")
  # B. Update the spread probability raster
  sim$spread.rast <- spreadRast (sim$pix.raster, sim$table.hab.update)
  message ("Fisher habitat data updated.")
  
  # C. Update Denning Habitat
  # identify the denning habitat 
  den.rast <- sim$pix.rast
  den.rast [] <- 0
  den.rast [sim$table.hab.update [denning == 1, pixelid]] <- 1
  den.rast [!sim$pix.rast$pixelid] <- NA
  names (den.rast) <- "denning"
  den.rast <- c (sim$pix.rast, den.rast)
  # convert to a table
  sim$den.table <- na.omit (as.data.table (den.rast []))
  # add x and y coords
  sim$den.table <- cbind (sim$den.table, crds (den.rast, df = T, na.rm = T))
  # only denning
  sim$den.table <- sim$den.table [denning == 1, ]
  # identify unoccupied denning habitat
  sim$den.table <- sim$den.table [!pixelid %in% sim$territories$pixelid]
  # identifier for linking tables
  sim$den.table$den_id <- seq (1: nrow (sim$den.table))
  sim$max.den.id <- max (sim$den.table$den_id)
  
  return (invisible (sim))
}


###--- ANNUAL LIFE EVENTS
annualEvents <- function (sim) {

  for (i in 1:P(sim, "timeInterval", "FLEX2")) { # repeat this function by the number of time intervals (in years)
    
    message ("Fisher checking habitat quality...")
    
   # Step 1: Check if Fisher Habitat Needs are Being Met
      # if not, the animal gets a null d2 score and will disperse
        # A. check to see if minimum habitat target was met (prop habitat = 0.15); if not, remove the animal 
    table.hab.terrs <- merge (sim$table.hab.update,
                              sim$territories,
                              by = "pixelid")
    hab.count <- table.hab.terrs [denning == 1 | rust == 1 | cavity == 1 | cwd == 1 | movement == 1, .(.N), by = individual_id]
    hab.count <- merge (hab.count,
                        sim$agents [, c ("hr_size", "individual_id")],
                        by = "individual_id")
    hab.count$prop_hab <- hab.count$N / hab.count$hr_size
    hab.count [is.na (hab.count$prop_hab), ] <- 0  # in case there is a NA value...
    hab.count <- hab.count [!duplicated (hab.count$individual_id), ] # remove any dupes
    
    hab.inds <- c (unique (hab.count$individual_id))
    
    if (length (hab.inds) > 0) {
      for (i in 1:length (hab.inds)) { # for each individual
        if (hab.count [individual_id == hab.inds[i], prop_hab] >= 0.15) { 
          # if it achieves its minimum habitat total habitat threshold
          # do nothing; we still need to check if it meets min. thresholds for each habitat type (see below)
        } else {
          # change the animals d2_score to NA; this is the criteria used to trigger a dispersal 
          sim$agents [individual_id == hab.inds[i], d2_score := NA]
          sim$agents$d2_score <- as.numeric (sim$agents$d2_score)
          # sim$agents$d2_score[sim$agents$d2_score == 0] <- NA
          # remove the individuals territory 
          sim$territories <- sim$territories [individual_id != hab.inds[i], ] 
        } 
      }
    }

        # B. check if proportion of habitat types are greater than the minimum thresholds 
    hab.inds.prop <- c (unique (table.hab.terrs$individual_id))

    if (length (hab.inds.prop) > 0) {
      for (i in 1:length (hab.inds.prop)) { # for each individual
        
        # breaking this down to make it easier to interpret
        rest.prop <- (nrow (table.hab.terrs [individual_id == hab.inds.prop[i] & rust == 1]) + nrow (table.hab.terrs [individual_id == hab.inds.prop[i] & cavity == 1]) + nrow (table.hab.terrs [individual_id == hab.inds.prop[i] & cwd == 1])) / sim$agents [individual_id == hab.inds.prop[i], hr_size]
        move.prop <- nrow (table.hab.terrs [individual_id == hab.inds.prop[i] & movement == 1]) / sim$agents [individual_id == hab.inds.prop[i], hr_size] 
        den.prop <- nrow (table.hab.terrs [individual_id == hab.inds.prop[i] & denning == 1]) / sim$agents [individual_id == hab.inds.prop[i], hr_size]
        
        if (length (rest.prop) != 0 & length (move.prop) != 0 & length (den.prop) != 0) { # check it's not empty
          
          if (P(sim, "rest_target", "FLEX2") <= rest.prop & P(sim, "move_target", "FLEX2") <= move.prop & P(sim, "den_target", "FLEX2") <= den.prop) {
            ## if it achieves its minimum thresholds for each habitat type 
            # do nothing; the fisher maintains its territory
          } else {
            # change the animals d2_score to NA
            sim$agents <- sim$agents [individual_id == hab.inds.prop[i], d2_score := NA]
            sim$agents$d2_score <- as.numeric (sim$agents$d2_score)
            # sim$agents$d2_score[sim$agents$d2_score == 0] <- NA
            # remove the individuals territory 
            sim$territories <- sim$territories [individual_id != hab.inds.prop[i], ] 
          } 
        } else {
          # change the animals d2_score to NA
          sim$agents <- sim$agents [individual_id == hab.inds.prop[i], d2_score := NA]
          sim$agents$d2_score <- as.numeric (sim$agents$d2_score)
          # sim$agents$d2_score[sim$agents$d2_score == 0] <- NA
          # remove the individuals territory 
          sim$territories <- sim$territories [individual_id != hab.inds.prop[i], ] 
      }
     }
    }

    message ("Habitat checked by fishers.")
    
    # Step 3: Fishers Disperse
    message ("Fishers start dispersal...")

    # A. Identify each fishers 'potential' dispersal area
    # grab the agents that don't have a home range, i.e., no d2_score 
    dispersers <- sim$agents [is.na(sim$agents$d2_score), ] 

    if (nrow (dispersers) > 0) { # check to make sure there are dispersers
    
    # remove the dispersers from the agents and territories tables
      # sim$agents <- sim$agents [!individual_id %in% dispersers$individual_id]
    sim$territories <- sim$territories [!individual_id %in% dispersers$individual_id]
    
    # re-set the dispersers HR size and fisher_pop and d2_score
    # dispersers <- dispersers %>% mutate_at(vars(individual_id, pixelid, age, hr_size, fisher_pop, d2_score), ~as.numeric(as.character(.)))
    dispersers <- dispersers [, hr_size := NA]
    dispersers$hr_size <- as.numeric (dispersers$hr_size)
    dispersers <- dispersers [, fisher_pop := NA]
    dispersers$fisher_pop <- as.numeric (dispersers$fisher_pop)
    dispersers <- dispersers [, d2_score := NA]
    dispersers$d2_score <- as.numeric (dispersers$d2_score)

    # find den sites; looping because of duplicate starts...
    # individuals
    inds <- dispersers$individual_id
    
    # remove occupied den sites
    sim$den.table <- sim$den.table [!pixelid %in% sim$territories$pixelid]
    
      # add individual locations to the den site table in case the den site habitat is now gone
    disp.rast <- sim$pix.rast
    starts <- dispersers [individual_id == c (inds), pixelid]
    den.starts <- data.table (terra::xyFromCell (disp.rast, starts))
    den.starts <- cbind (data.table (starts), den.starts)
    names (den.starts) <- c ("pixelid", "x", "y")
    den.starts$denning <- 1
    den.starts [, den_id := seq (from = (sim$max.den.id + 1), 
                                 to = (sim$max.den.id + nrow (den.starts)), 
                                 by = 1)]
    sim$max.den.id <- sim$max.den.id + nrow (den.starts)

    # remove target den sites that are occupied
    sim$den.table <- sim$den.table [!pixelid %in% den.starts$pixelid]
    sim$den.table <- rbind (sim$den.table,
                            den.starts)

      # create output table
    den.target <- data.table (individual_id = as.numeric (), # putting in a dummy row so that I can run the while loop
                              den_id = as.numeric ()) 
    
    
    dispersers1 <<- dispersers
    den.table <<- sim$den.table
    
    
      # remove den sites already occupied 
    if (length (inds) > 0) { # also put in a check to see if a den site is already occupied?
      for (i in 1:length (inds)) {
        den.site <- RANN::nn2 (data = sim$den.table, # in the den site data
                               query = sim$den.table [pixelid == dispersers [individual_id == inds[i], pixelid]], # location of the disperser, by individual id
                               k =  min (40, nrow (sim$den.table)), # return maximum 40 neighbours; keep this large to allow flexibility for dupes
                               radius = 500 # in hectares; 100m pixels; 50 km r = 7,850 km2 area
        )
        
      rdm.smp <- sample (2:ncol (den.site$nn.idx), 1) # Randomly select one of the five den sites		
     
      # need to check if den_id already 'occupied'
      while (nrow (den.target [den_id == den.site$nn.idx[, rdm.smp]]) > 0) { # if the den site is already occupied
        rdm.smp <- sample (2:ncol (den.site$nn.idx), 1) # Randomly select den site again
      }
      
      # set the target location
         den.target.temp <- data.table (individual_id = dispersers [individual_id == inds[i], individual_id], 
                                        den_id = den.site$nn.idx[, rdm.smp]) 	
         den.target <- rbind (den.target, den.target.temp)	
       
      }
    }
  
    
    den.target <<- den.target
    dispersers2 <<- dispersers
    
    
      # update the den locations
       den.target <- merge (den.target,
                            sim$den.table [, c ("den_id", "pixelid")],
                            by.x = "den_id", by.y = "den_id")
       dispersers <- merge (dispersers [, -"pixelid"],
                            den.target [, c ("individual_id", "pixelid")],
                            by.x = "individual_id", by.y = "individual_id")					 
            # update the fisher pop where the fisher is located
       dispersers <- merge (dispersers [, -"fisher_pop"],
                            sim$table.hab.update [, c ("pixelid", "fisher_pop")],
                            by.x = "pixelid", by.y = "pixelid")

      # create new HR sizes based on which fisher pop the animal belongs to
      dispersers [fisher_pop == 1, hr_size := round (rnorm (nrow (dispersers [fisher_pop == 1, ]), sim$female_hr_table [fisher_pop == 1, hr_mean], sim$female_hr_table [fisher_pop == 1, hr_sd]))]
      dispersers [fisher_pop == 2, hr_size := round (rnorm (nrow (dispersers [fisher_pop == 2, ]), sim$female_hr_table [fisher_pop == 2, hr_mean], sim$female_hr_table [fisher_pop == 2, hr_sd]))]
      dispersers [fisher_pop == 3, hr_size := round (rnorm (nrow (dispersers [fisher_pop == 3, ]), sim$female_hr_table [fisher_pop == 3, hr_mean], sim$female_hr_table [fisher_pop == 3, hr_sd]))]
      dispersers [fisher_pop == 4, hr_size := round (rnorm (nrow (dispersers [fisher_pop == 4, ]), sim$female_hr_table [fisher_pop == 4, hr_mean], sim$female_hr_table [fisher_pop == 4, hr_sd]))]

      # C. Dispersers create territories
      message ("Dispersing fishers forming territories...")
      
      table.disperse.hr <- SpaDES.tools::spread2 (sim$pix.raster, # within the area of interest
                                                  start = dispersers$pixelid, # for each individual
                                                  spreadProb = as.numeric (sim$spread.rast[]), # use spread prob raster
                                                  exactSize = dispersers$hr_size, # spread to the size of their assgined HR size
                                                  allowOverlap = F, # no overlap allowed
                                                  asRaster = F, # output as a table
                                                  circle = F) # spread to adjacent cells
     
   
      table.disperse.hr1 <<- table.disperse.hr
      
      
            # add individual id and habitat
      table.disperse.hr <- merge (merge (table.disperse.hr,
                                         dispersers [, c ("pixelid", "individual_id")],
                                         by.x = "initialPixels", by.y = "pixelid", all.x = T), 
                                  sim$table.hab.update [, c ("pixelid", "denning", "rust", "cavity", "cwd", "movement")],
                                  by.x = "pixels", by.y = "pixelid",
                                  all.x = T)
      
      table.disperse.hr2 <<- table.disperse.hr
      
  
        # check to see if home range target was within mean +/- 2 SD; if not, remove the disperser 
      table.disperse.hr [, pix.count := sum (length (pixels)), by = individual_id]
      table.disperse.hr.unq <- unique (table.disperse.hr, by = "individual_id")
      
      pix.count <- merge (dispersers [, c ("pixelid", "individual_id", "hr_size", "fisher_pop")],
                          table.disperse.hr.unq [, c ("individual_id", "pix.count")],
                          by.x = "individual_id", by.y = "individual_id",
                          all.x = T)  

      
        # for each fisher population
      pix.count.ids <- c (unique (pix.count [fisher_pop == 1, ]$individual_id))
      if (length (pix.count.ids) > 0) {
       for (i in 1:length (pix.count.ids)) { # for each individual
        if (pix.count [fisher_pop == 1 & individual_id == pix.count.ids[i], pix.count] >= (sim$female_hr_table [fisher_pop == 1, hr_mean] - (2 * sim$female_hr_table [fisher_pop == 1, hr_sd])) & pix.count [fisher_pop == 1 & individual_id == pix.count.ids[i], pix.count] <= (sim$female_hr_table [fisher_pop == 1, hr_mean] + (2 * sim$female_hr_table [fisher_pop == 1, hr_sd]))) { 
          # if its home range size is within mean +/- 2 SD
          # do nothing; we still need to check if it meets min. thresholds for each habitat type (see below)
        } else {
          # save them as agents without a d2score or HR
          sim$agents <- sim$agents [fisher_pop == 1 & individual_id == pix.count.ids[i], d2_score := NA]
          sim$agents$d2_score <- as.numeric (sim$agents$d2_score)
          sim$agents <- sim$agents [fisher_pop == 1 & individual_id == pix.count.ids[i], hr_size := NA]
          sim$agents$hr_size <- as.numeric (sim$agents$hr_size)
          dispersers <- dispersers [fisher_pop == 1 & individual_id != pix.count.ids[i]] # remove from dispersers table
        } 
       }
      }
      
      pix.count.ids <- c (unique (pix.count [fisher_pop == 2, ]$individual_id))
      if (length (pix.count.ids) > 0) {
        for (i in 1:length (pix.count.ids)) { # for each individual
        if (pix.count [fisher_pop == 2 & individual_id == pix.count.ids[i], pix.count] >= (sim$female_hr_table [fisher_pop == 2, hr_mean] - (2 * sim$female_hr_table [fisher_pop == 2, hr_sd])) & pix.count [fisher_pop == 2 & individual_id == pix.count.ids[i], pix.count] <= (sim$female_hr_table [fisher_pop == 2, hr_mean] + (2 * sim$female_hr_table [fisher_pop == 2, hr_sd]))) { 
          
        } else {
          sim$agents <- sim$agents [fisher_pop == 2 & individual_id == pix.count.ids[i], d2_score := NA]
          sim$agents$d2_score <- as.numeric (sim$agents$d2_score)
          sim$agents <- sim$agents [fisher_pop == 2 & individual_id == pix.count.ids[i], hr_size := NA]
          sim$agents$hr_size <- as.numeric (sim$agents$hr_size)
          dispersers <- dispersers [fisher_pop == 2 & individual_id != pix.count.ids[i]] # remove from dispersers table
        } 
       }
      }
      
      pix.count.ids <- c (unique (pix.count [fisher_pop == 3, ]$individual_id))
      if (length (pix.count.ids) > 0) {
      for (i in 1:length (pix.count.ids)) { # for each individual
        if (pix.count [fisher_pop == 3 & individual_id == pix.count.ids[i], pix.count] >= (sim$female_hr_table [fisher_pop == 3, hr_mean] - (2 * sim$female_hr_table [fisher_pop == 3, hr_sd])) & pix.count [fisher_pop == 3 & individual_id == pix.count.ids[i], pix.count] <= (sim$female_hr_table [fisher_pop == 3, hr_mean] + (2 * sim$female_hr_table [fisher_pop == 3, hr_sd]))) { 
          
        } else {
          sim$agents <- sim$agents [fisher_pop == 3 & individual_id == pix.count.ids[i], d2_score := NA]
          sim$agents$d2_score <- as.numeric (sim$agents$d2_score)
          sim$agents <- sim$agents [fisher_pop == 3 & individual_id == pix.count.ids[i], hr_size := NA]
          sim$agents$hr_size <- as.numeric (sim$agents$hr_size)
          dispersers <- dispersers [fisher_pop == 3 & individual_id != pix.count.ids[i]] # remove from dispersers table
        } 
       }
      }

      # below if the function where the 'duplicate' error gets thrown
        # there are duplicate "pix.count.ids", which originates from the dispersers individual_id's
      pix.count.ids <- c (unique (pix.count [fisher_pop == 4, ]$individual_id))
      if (length (pix.count.ids) > 0) {
      for (i in 1:length (pix.count.ids)) { # for each individual
        if (pix.count [fisher_pop == 4 & individual_id == pix.count.ids[i], pix.count] >= (sim$female_hr_table [fisher_pop == 4, hr_mean] - (2 * sim$female_hr_table [fisher_pop == 4, hr_sd])) & pix.count [fisher_pop == 4 & individual_id == pix.count.ids[i], pix.count] <= (sim$female_hr_table [fisher_pop == 4, hr_mean] + (2 * sim$female_hr_table [fisher_pop == 4, hr_sd]))) { 
          
        } else {
          sim$agents <- sim$agents [fisher_pop == 4 & individual_id == pix.count.ids[i], d2_score := NA]
          sim$agents$d2_score <- as.numeric (sim$agents$d2_score)
          sim$agents <- sim$agents [fisher_pop == 4 & individual_id == pix.count.ids[i], hr_size := NA]
          sim$agents$hr_size <- as.numeric (sim$agents$hr_size)
          dispersers <- dispersers [fisher_pop == 4 & individual_id != pix.count.ids[i]] # remove from dispersers table
        } 
       }
      }

       
      # check to see if minimum habitat target was met (prop habitat = 0.15); if not, remove the disperser 
      
        # first check to see if any dispersers left 
      if (nrow (dispersers) > 0) {
      
      hab.count <- table.disperse.hr [denning == 1 | rust == 1 | cavity == 1 | cwd == 1 | movement == 1, .(.N), by = individual_id]
      hab.count <- merge (hab.count,
                          dispersers [, c ("hr_size", "individual_id")],
                          by.x = "individual_id", by.y = "individual_id", all.x = TRUE)

       hab.count$prop_hab <- as.numeric (hab.count$N / hab.count$hr_size)
       hab.count [is.na (hab.count$prop_hab), ] <- 0  # in case there is a NA value...
       hab.count <- hab.count [!duplicated (hab.count$individual_id), ] # remove any dupes
       
       hab.inds <- c (hab.count$individual_id)
       
        for (i in 1:length (hab.inds)) { # for each individual
          if (hab.count [individual_id == hab.inds[i], prop_hab] >= 0.15) { 
            # if it achieves its minimum habitat total habitat threshold
            # do nothing; we still need to check if it meets min. habitat criteria (see below)
          } else {
            # save them as agents without a d2score
            sim$agents <- sim$agents [individual_id == hab.inds[i], d2_score := NA]
            sim$agents$d2_score <- as.numeric (sim$agents$d2_score)
            sim$agents <- sim$agents [individual_id == hab.inds[i], hr_size := NA]
            sim$agents$hr_size <- as.numeric (sim$agents$hr_size)
            # delete the individual from the dispersers table
            dispersers <- dispersers [individual_id != hab.inds[i]]
          } 
        }
      
        # finalize which fisher pop a successful disperser belongs to
      terr.pop <- merge (table.disperse.hr, sim$table.hab.update [, c ("pixelid", "fisher_pop")], 
                         by.x = "pixels",
                         by.y = "pixelid", all.x = T)
        # get the mean of pixels pop. values, rounded to get the majority; majority = pop membership
      terr.pop [, fisher_pop := .(round (mean (fisher_pop, na.rm = T), digits = 0)), by = individual_id] 
      terr.pop <- unique (terr.pop [, c ("individual_id", "fisher_pop")])
      terr.pop$fisher_pop <- as.numeric (terr.pop$fisher_pop )
      dispersers <- merge (dispersers [, -c ("fisher_pop")], # assign new fisher_pop to agents table
                           terr.pop [, c ("individual_id", "fisher_pop")], 
                           by = "individual_id", all.x = T)

      
      # D. Successful Dispersers get a D2 Score (Mahalanobis) 
      message ("Calculate habitat quality of succesfull dispersers...")

      # calculate habitat quality 
      tab.perc <- habitatQual (table.disperse.hr, dispersers, sim$fisher_d2_cov)
      
      dispersers <- merge (dispersers [, - ('d2_score')],
                           tab.perc [, .(individual_id, d2_score = d2)],
                           by = "individual_id")
      
      }
      
      message ("Habitat quality calculated.")
      
      # E. Check that min. habitat thresholds are met 
      
        # first check to see if any dispersers left 
      if (nrow (dispersers) > 0) {
        
      disp.ids <- c (unique (dispersers$individual_id)) # unique individuals

        for (i in 1:length (disp.ids)) { # for each individual
          
          # breaking this down to make it easier to interpret
          rest.prop <- (nrow (table.disperse.hr [individual_id == disp.ids[i] & rust == 1]) + nrow (table.disperse.hr [individual_id == disp.ids[i] & cavity == 1]) + nrow (table.disperse.hr [individual_id == disp.ids[i] & cwd == 1])) / dispersers [individual_id == disp.ids[i], hr_size]
          move.prop <- nrow (table.disperse.hr [individual_id == disp.ids[i] & movement == 1]) / dispersers [individual_id == disp.ids[i], hr_size] 
          den.prop <- nrow (table.disperse.hr [individual_id == disp.ids[i] & denning == 1]) / dispersers [individual_id == disp.ids[i], hr_size]
 
          if (length (rest.prop) != 0 & length (move.prop) != 0 & length (den.prop) != 0) { # check the proportion values are not NA's
           if (P(sim, "rest_target", "FLEX2") <= rest.prop & P(sim, "move_target", "FLEX2") <= move.prop & P(sim, "den_target", "FLEX2") <= den.prop) {
              # if it achieves the thresholds
              # assign the pixels to the territories table
              sim$territories <- rbind (sim$territories, 
                                        table.disperse.hr [individual_id == disp.ids[i], .(pixelid = pixels, individual_id)]) 
              # update dispersers new d2_score adn hr_size to the agents table
              sim$agents <- sim$agents [individual_id == disp.ids[i], d2_score := dispersers [individual_id == disp.ids[i], d2_score]] 
              sim$agents <- sim$agents [individual_id == disp.ids[i], hr_size := dispersers [individual_id == disp.ids[i], hr_size]] 
              sim$agents <- sim$agents [individual_id == disp.ids[i], fisher_pop := dispersers [individual_id == disp.ids[i], fisher_pop]] 
              
            } else {
              # update the individual d2 score to NA
              sim$agents <- sim$agents [individual_id == disp.ids[i], d2_score := NA]
              sim$agents$d2_score <- as.numeric (sim$agents$d2_score)
              sim$agents <- sim$agents [individual_id == disp.ids[i], hr_size := NA]
              sim$agents$hr_size <- as.numeric (sim$agents$hr_size)
              sim$agents <- sim$agents [individual_id == disp.ids[i], fisher_pop := NA]
              sim$agents$fisher_pop <- as.numeric (sim$agents$fisher_pop)
            } 
          } else {
            # update the individual d2 score to NA
            sim$agents <- sim$agents [individual_id == disp.ids[i], d2_score := NA]
            sim$agents$d2_score <- as.numeric (sim$agents$d2_score)
            sim$agents <- sim$agents [individual_id == disp.ids[i], hr_size := NA]
            sim$agents$hr_size <- as.numeric (sim$agents$hr_size)
            sim$agents <- sim$agents [individual_id == disp.ids[i], fisher_pop := NA]
            sim$agents$fisher_pop <- as.numeric (sim$agents$fisher_pop)
          }
        }
      }
      rm (dispersers)
      message ("Dispersal complete!")

    } else {
      
      message ("There are no dispersing fisher.")
      
    }
 
     # Step 4: Reproduce
      message ("Fishers reproducing...")
      
      reproFishers <- sim$agents [sex == "F" & age >= P (sim, "reproductive_age", "FLEX2") & !is.na (d2_score), ] # females of reproductive age in a territory

      # A. Assign each female fisher 1 = reproduce or 0 = does not reproduce
      if (nrow (reproFishers) > 0) {
        pop.ids <- c (unique (reproFishers$fisher_pop))
        for (i in 1:length (pop.ids)) { 
          reproFishers [fisher_pop == pop.ids[i], reproduce := rbinom (n = nrow (reproFishers [fisher_pop == pop.ids[i]]),
                                                                       size = 1,
                                                                       prob = rtruncnorm (1,
                                                                                          a = 0, # lower bounds
                                                                                          b = 1, # upper bounds
                                                                                          mean = sim$repro_rate_table [Fpop == pop.ids[i] & Param == 'DR', Mean], 
                                                                                          sd =  sim$repro_rate_table [Fpop == pop.ids[i] & Param == 'DR', SD]))]
        } 
        
        reproFishers <- reproFishers [reproduce == 1, ] # remove non-reproducers
        
        # for those fishers who are reproducing, assign litter size (Poisson distribution)
        # litter size adjusted for habitat quality
        reproFishers <- litterSize (1, sim$mahal_metric_table, sim$repro_rate_table, reproFishers)
        reproFishers <- litterSize (2, sim$mahal_metric_table, sim$repro_rate_table, reproFishers)
        reproFishers <- litterSize (3, sim$mahal_metric_table, sim$repro_rate_table, reproFishers)
        reproFishers <- litterSize (4, sim$mahal_metric_table, sim$repro_rate_table, reproFishers)
        
        reproFishers <- reproFishers [kits >= 1, ] # remove females with no kits
        
          if (nrow (reproFishers) > 0) {
          ## add the kits to the agents table
          # create new agents
          new.agents <- data.frame (lapply (reproFishers, rep, reproFishers$kits)) # repeat the rows in the reproducing fishers table by the number of kits 
          # assign whether fisher is a male or female; remove males
          new.agents$kits <- rbinom (size = 1, n = nrow (new.agents), prob = P (sim, "sex_ratio", "FLEX2")) # prob of being a female
          new.agents <- setDT (new.agents)
          new.agents <- new.agents [kits == 1, ] # female = 1; male = 0
          # make them age 0; 
          new.agents [, age := 0]
          # make their home range size = 0 and d2_score = 0; this gets done in the dispersal function 
          new.agents [, hr_size := NA]
          new.agents [, d2_score := NA]

          # drop individual_id, 'reproduce' and 'kits' columns (and time and scenario)
          new.agents$reproduce <- NULL
          new.agents$kits <- NULL
          new.agents$individual_id <- NULL
          
          # update the individual id
          if (nrow (new.agents) > 0) {
            new.agents [, individual_id := seq (from = (sim$max.id + 1), 
                                                to = (sim$max.id + nrow (new.agents)), 
                                                by = 1)]
            sim$max.id <- sim$max.id + nrow (new.agents)
            } else {
              message ("There are no female kits!")
            }
          
          } else {
            message ("There are no reproducing fishers!")
          }

        sim$agents <- rbind (sim$agents,
                             new.agents) # save the new agents
     
        # if there are kits, move first one pixel over from mother and each sibling one pixel over
        while (any (duplicated (sim$agents$pixelid))) { # loop in case there is > 2 kits
          sim$agents$pixelid <-  replace (sim$agents$pixelid, 
                                          duplicated (sim$agents$pixelid), 
                                          sim$agents$pixelid [duplicated(sim$agents$pixelid)] + 1)
        }
        
        # NOTE: the above two function could move a fisher on the eastern edge of the area of interest to the western edge
        # functionally this would be like a kit dispersing 'out' of the area, offset by a kit dispersing 'in' to the area elsewhere
        
        
      } else {
        message ("There are no reproducing fishers!")
      }
      # no update to the territories table because juveniles have not yet established a territory
      message ("Kits added to population.")
      
      
      # Step 5. Survive and Age 1 Year
        # old fishers die here; remove their territories
      survivors <- sim$agents [age < P(sim, "female_max_age", "FLEX2"), ] # remove old
      sim$agents <- sim$agents [individual_id %in% survivors$individual_id] 
      sim$territories <- sim$territories [individual_id %in% survivors$individual_id] # remove territories
      
        # old dispersers die here; remove their territories 
      dead.dispersers <- sim$agents [age > 2 & is.na (d2_score), ] # older than 2 and doesn't have a territory
      sim$agents <- sim$agents [!individual_id %in% dead.dispersers$individual_id]
      sim$territories <- sim$territories [!individual_id %in% dead.dispersers$individual_id] # remove territories
      
      # note that the above steps could inflate the model mortality rate, as old animals are presumably included in the survival rate estimate
      
      # age-class based survival rates
        # juveniles
      survivors.juv <- sim$agents [age == 1 & !is.na (d2_score), ]
      if (nrow (survivors.juv) > 0) {
       juv.fish.pops <- c (unique (survivors.juv$fisher_pop))
       for (i in 1:length (juv.fish.pops)) { 
        survivors.juv [fisher_pop == juv.fish.pops[i], 
                       survive := rbinom (n = nrow (survivors.juv [fisher_pop == juv.fish.pops[i], ]),
                                          size = 1,
                                          prob = rtruncnorm (1,
                                                             a = 0, # lower bounds
                                                             b = 1, # upper bounds
                                                             mean = sim$survival_rate_table [Fpop == juv.fish.pops[i] & age == 'Juvenile', Mean], 
                                                             sd = sim$survival_rate_table [Fpop == juv.fish.pops[i] & age == 'Juvenile', SD]))]
      } 
      } else {
        survivors.juv$survive <- 0 
     }
        
        # adults
      survivors.ad <- sim$agents [age > 1 & !is.na (d2_score), ]
      if (nrow (survivors.ad) > 0) {
       ad.fish.pops <- c (unique (survivors.ad$fisher_pop))
       for (i in 1:length(ad.fish.pops)) { 
        survivors.ad [fisher_pop == ad.fish.pops[i], 
                      survive := rbinom (n = nrow (survivors.ad [fisher_pop == ad.fish.pops[i], ]),
                                         size = 1,
                                         prob = rtruncnorm (1, # use rtruncnorm() to runcate valeus between 0 and 1
                                                            a = 0, # lower bounds
                                                            b = 1, # upper bounds
                                                            mean = sim$survival_rate_table [Fpop == ad.fish.pops[i] & age == 'Adult', Mean], 
                                                            sd = sim$survival_rate_table [Fpop == ad.fish.pops[i] & age == 'Adult', SD]))]
       }
       }else {
        survivors.ad$survive <- 0 
      }
          
        # dispersers
      survivors.disp <- sim$agents [age > 0 & !is.na (d2_score), ]
      if (nrow (survivors.disp) > 0) {
        disp.fish.pops <- c (unique (survivors.disp$fisher_pop))
        for (i in 1:length(disp.fish.pops)) { 
        survivors.disp [fisher_pop == disp.fish.pops[i], 
                        survive := rbinom (n = nrow (survivors.disp [fisher_pop == disp.fish.pops[i], ]),
                                           size = 1,
                                           prob = rtruncnorm (1,
                                                              a = 0, # lower bounds
                                                              b = 1, # upper bounds
                                                              mean = sim$survival_rate_table [Fpop == disp.fish.pops[i] & age == 'Disperser', Mean], 
                                                              sd =  sim$survival_rate_table [Fpop == disp.fish.pops[i] & age == 'Disperser', SD]))]
        }
        } else {
        survivors.disp [, survive := 0] 
      }  
        
        
      # kits
      # they all survive?
      survivors.kit <- sim$agents [age == 0, ]
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
      sim$agents$age <- sim$agents$age + 1 
      
      message ("Fishers survived and aged one year.")
    
  }
  
  return (invisible (sim))
}


###--- SAVE AGENTS AT TIME INTERVAL
updateAgents <- function (sim) {
  message ("Update reports...")
  
  # agents table
  # currently saving the number of agents and age of agents for a single iteration
  new.agents.save <- data.table (n_f_adult = as.numeric (nrow (sim$agents [sex == "F" & age > 1, ])), 
                                 n_f_juv = as.numeric (nrow (sim$agents [sex == "F" & age == 1, ])), 
                                 mean_age_f = as.numeric (mean (c (sim$agents [sex == "F", age]))), 
                                 sd_age_f = as.numeric (sd (c (sim$agents [sex == "F", age]))), 
                                 timeperiod = as.integer (time(sim) * P (sim, "timeInterval", "FLEX2")), 
                                 scenario = as.character (sim$scenario$name))
  
  sim$fisherABMReport <- rbindlist (list (sim$fisherABMReport, 
                                          new.agents.save), 
                                    use.names = TRUE)
  # territories raster
  # set a territory as value = 1 
  # add it to the existing territories
  # final raster is the number of time periods that a pixel was a territory
  ras.territories.update <- sim$pix.rast
  ras.territories.update [] <- 0
  ras.territories.update [sim$territories$pixelid] <- 1
  sim$ras.territories <- sim$ras.territories + ras.territories.update
  
  # clean-up
  rm (ras.territories.update, new.agents.save)
  
  return (invisible (sim))
}


###--- SAVE
saveAgents <- function (sim) {
  message ("Save the agents and territories.")
  # save the agents table
  # NOTE: this also can integrate with Castor/CLUS, as fisherABMReport is an object in uploaderCASTOR 
  #  thus the table can also be saved to a postgres database
  write.csv (x = sim$fisherABMReport,
             file = paste0 (outputPath (sim), "/", sim$scenario$name, "_fisher_agents.csv"))

  # write final agents table
  write.csv (x = sim$agents,
             file = paste0 (outputPath (sim), "/", sim$scenario$name, "_fisher_agents_timeinterval_end_table.csv"))
  
  # save the territories
    # using raster::writeRaster() here
    # terra::writeRaster() throws error: [writeRaster] there are no cell values
    # but there are values in the raster; possible bug?

  raster::writeRaster (x = raster::raster (sim$ras.territories),
                       filename = paste0 (outputPath (sim), "/", sim$scenario$name, "_fisher_territories.tif"),
                       overwrite = TRUE)
    
  # terra::writeRaster (x = terra::rast (sim$ras.territories), 
  #                    filename = paste0 (outputPath (sim), "/", sim$scenario$name, "_fisher_territories.tif"), 
  #                    overwrite = TRUE)

  # add final territories
  ras.territories.final <- sim$pix.rast
  ras.territories.final [] <- 0
  ras.territories.final [sim$territories$pixelid] <- sim$territories$individual_id
  
  raster::writeRaster (x = raster::raster (ras.territories.final),
                       filename = paste0 (outputPath (sim), "/", sim$scenario$name, "_final_fisher_territories.tif"),
                       overwrite = TRUE)
  
  # terra::writeRaster (x = terra::rast (ras.territories.final), 
  #                      filename = paste0 (outputPath (sim), "/", sim$scenario$name, "_final_fisher_territories.tif"), 
  #                      overwrite = TRUE)
  # 
  
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
      # territories.save [, c("timeperiod", "scenario") := list (time(sim)*P (sim, "timeInterval", "FLEX2"), sim$scenario$name)  ] # add the time of the calc
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


spreadRast <- function (rasterInput, habitatInput) {
  spread.rast <- rasterInput
  spread.rast [] <- 0
  # currently uses all denning, rust, cavity, cwd and movement habitat as 
  # spreadProb = 1, and non-habitat as spreadProb = 0.10; allows some spread to sub-optimal habitat
  habitatInput [denning == 1 | rust == 1 | cavity == 1 | cwd == 1 | movement == 1, spreadprob := format (round (1.00, 2), nsmall = 2)] 
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

litterSize <- function (fisherPop, mahalTable, reproTable, reproFishers){
  rep.ids <- c (unique (reproFishers$individual_id))
  for (i in 1:length (rep.ids)) {
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

