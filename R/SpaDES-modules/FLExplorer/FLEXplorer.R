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
  name = "FLEXplorer",
  description = "An agent based model for fisher", 
  keywords = NA, # c("insert key words here"),
  authors = c(person("Joanna", "Burger", email = "Joanna.Burger@gov.bc.ca", role = c("aut", "cre")),
    person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", FLEXplorer = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.md", "FLEXplorer.Rmd"),
  reqdPkgs = list(),
  parameters = rbind(
    defineParameter("female_max_age", "numeric", 9, 0, 15, "The maximum possible age of a female fisher. Taken from research referenced by Roray Fogart in VORTEX_inputs_new.xlsx document."), 
    defineParameter("den_target", "numeric", 0.10, 0.003, 0.54,"The minimum proportion of a home range that is denning habitat. Values taken from empirical female home range data across populations."), 
    defineParameter("rest_target", "numeric", 0.26, 0.028, 0.58,"The minimum proportion of a home range that is resting habitat. Values taken from empirical female home range data across populations."),   
    defineParameter("move_target", "numeric", 0.36, 0.091, 0.73,"The minimum proportion of a home range that is movement habitat. Values taken from empirical female home range data across populations."), 
    defineParameter("sex_ratio", "numeric", 0.5, 0, 1,"The probability of being a female in a litter."),
    defineParameter("reproductive_age", "numeric", 2, 0, 9,"The minimum reproductive age of a fisher."),
    defineParameter("female_dispersal", "numeric", 785000, 100, 10000000,"The area, in hectares, a fisher could explore during a dispersal to find a territory."),
    defineParameter("rasterHabitat", "character", paste0 (here::here(), "/R/scenarios/test_flex2/test_Williams_Lake_TSA_fisher_habitat.tif"), NA, NA, "Directory where the fisher habitat raster .tif is stored. Used as habitat input to this module. A band in the .tif exists for each time interval simulated in forestryCastor, and each fisher habitat type (denning, movement, cwd, rust, cavity)."), # create a default somewhere??
    defineParameter("timeInterval", "numeric", 1, 1, 20, "The time step, in years, when habtait was updated. It should be consistent with periodLength form growingStockCASTOR. Life history events (reproduce, updateHR, survive, disperse) are calaculated this many times for each interval."),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput (objectName = "fisher_d2_cov", objectClass = "data.table", desc = "variance matrix for mahalanobis distance model; don't touch this unless d2 model updated", sourceURL = NA),
    expectsInput (objectName = "survival_rate_table", objectClass = "data.table", desc = "Table of fisher survival rates by sex, age and population, taken from Lofroth et al 2022 JWM vital rates manuscript. Headers: Fpop: the two populations in BC: Boreal, Coumbian; Age_class: two classes: Adult, Juvenile; Cohort: Fpop and Age_class combination: CFA, CFJ, BFA, BFJ; Mean: mean survival probability; SE: standard error of the mean. Decided to go with SE rather than SD as confidence intervals are quite wide and stochasticity would likely drive populations to extinction. Keeping consistent with Rory Fogarty's population analysis decisions.", sourceURL = NA),
    expectsInput (objectName = "repro_rate_table", objectClass = "data.table", desc = "Table of fisher reproductive rates (i.e., denning rate = a combination of pregnancy rate and birth rate; and litter size = number of kits) by population, taken from Lofroth et al 2022 JWM vital rates manuscript. Headers: Fpop: the two populations in BC: Boreal, Coumbian; Param: the reproductive parameter: DR (denning rate), LS (litter size); Mean: mean reproductive rate per parameter and population; SD: reproductive rate standard deviation value per parameter and population.", sourceURL = NA),
    expectsInput (objectName = "female_hr_table", objectClass = "data.table", desc = "Table of female home range sizes, by fisher population.", sourceURL = NA),
    expectsInput (objectName = "mahal_metric_table", objectClass = "data.table", desc = "Table of mahalanobis D2 values based on Fisher Habitat Extension zones, provided by Rich Weir summer 2022. Headers: FHE_zone: the four fisher habitat extension zones: Boreal, Sub-Boreal moist, Sub-Boreal dry, Dry Forest; FHE_zone_num: the corresponding FHE_zone number: Boreal = 1, Sub-Boreal moist = 2, Sub-Boreal Dry = 3, Dry Forest = 4; Mean: mean mahalanobis D2 value per FHE zone; SD: mahalanobis D2 standard deviation value per FHE zone; Max: maximum mahalanobis D2 value per FHE zone.", sourceURL = NA)
    ),
  outputObjects = bind_rows(
    createsOutput (objectName = "agents", objectClass = "data.table", desc = "Fisher agents table." ),
    createsOutput (objectName = "territories", objectClass = "data.table", desc = "Fisher territories table." ),
    createsOutput (objectName = "pix.rast", objectClass = "SpatRaster", desc = "A raster dataset of pixel values in the area of interest." ),
    createsOutput (objectName = "raster.stack", objectClass = "SpatRaster", desc = "The habitat data as a raster stack." ),
    createsOutput (objectName = "spread.rast", objectClass = "RasterLayer", desc = "The raster layer describing how fisher search for habitat." ),
    createsOutput (objectName = "table.hab.spread", objectClass = "data.table", desc = "Fisher habitat categoires table." ),
    #createsOutput (objectName = "ras.territories", objectClass = "SpatRaster", desc = "The territories over a sim." ),
    createsOutput (objectName = "fisherABMReport", objectClass = "data.table", desc = "A data.table object. Consists of fisher population numbers in the study area at each time step."),
    
  )
))


doEvent.FLEXplorer = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init(sim)
      sim <- getFisherHR(sim)
      
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  message ("Load the habitat data.")
  sim$raster.stack <- terra::rast (P (sim, "rasterHabitat", "FLEXplorer")) 
  
  # get the pixel id raster
  sim$pix.rast <- terra::subset (sim$raster.stack, grep ("pixelid", names (sim$raster.stack)))
  
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
  den.pix <- table.habitat.init [ras_fisher_denning_init == 1, c ("pixelid", "ras_fisher_denning_init")]
  # sample the pixels where there is denning habitat
  #den.pix.sample <- den.pix [seq (1, nrow (den.pix), 50), ] # grab every ~50th pixel; ~1 pixel every 5km
  #use a aggregated raster to find denning pixels to establish
  den.rast <- terra::subset (sim$raster.stack, grep ("ras_fisher_denning_init", names (sim$raster.stack)))
  den.rast.ag <- aggregate(den.rast, fact=round(sqrt(mean(sim$female_hr_table$hr_mean)),0)) #fact is the number of pixels to expand by -- so 50 = 60 x 60 ha ~ 3600 ha or 25 km2
                    
  den.ag<-data.table(xyFromCell(den.rast.ag, 1:ncell(den.rast.ag)))
  den.ag$value<-den.rast.ag[]#include the amount of denning value which is a average of 0's and 1's to arrive at the proportion
  den.ag<-den.ag[value > 0, ]#Remove remote areas (i.e., lakes) that have no denning within 2500 ha
  
  den.pix.coords<- data.table(xyFromCell(sim$pix.rast, den.pix$pixelid))
  den.pix.coords$pixelid<-den.pix$pixelid
  
  samples<-RANN::nn2 (data =  den.pix.coords[,c("x", "y")], 
             query = den.ag[,c("x", "y")], k =  30, radius = 2500 )$nn.idx #Find the closest 30 denning pixels within 2500 m
  
  denning.starts<-data.table(ID = 1:nrow(samples))
  for(i in 1:nrow(samples) ) {
    x <- as.vector( samples[i,] )
    denning.starts[ID == i, loc := sample(x, 1)] #loc is the index within den.pix.coords - NOT pixelid!
  }
  
  # create agents table  
  sim$agents <- data.table (individual_id = seq (from = 1, to = nrow (denning.starts), by = 1),
                            sex = "F",
                            age = sample (1:P (sim, "female_max_age", "FLEXplorer"), length (seq (from = 1, to = nrow (denning.starts), by = 1)), replace = T), # randomly draw ages between 1 and the max age,
                            pixelid = den.pix.coords[denning.starts$loc]$pixelid)
  
  #---- assign the population to sim$agents table
  tab.fisher.pop <- table.habitat.init [ras_fisher_pop > 0, c ("pixelid", "ras_fisher_pop")]
  names (tab.fisher.pop) <- c ("pixelid", "fisher_pop")
  tab.fisher.pop$fisher_pop <- as.numeric (tab.fisher.pop$fisher_pop)
  sim$agents <- merge (sim$agents, 
                       tab.fisher.pop [ , c("pixelid", "fisher_pop")], 
                       by.x = "pixelid", by.y = "pixelid", all.x = T)
  
  #---- assign an HR size based on population
  sim$agents [fisher_pop == 1, hr_size := round (rnorm (nrow (sim$agents [fisher_pop == 1, ]), sim$female_hr_table [fisher_pop == 1, hr_mean], sim$female_hr_table [fisher_pop == 1, hr_sd]))]
  sim$agents [fisher_pop == 2, hr_size := round (rnorm (nrow (sim$agents [fisher_pop == 2, ]), sim$female_hr_table [fisher_pop == 2, hr_mean], sim$female_hr_table [fisher_pop == 2, hr_sd]))]
  sim$agents [fisher_pop == 3, hr_size := round (rnorm (nrow (sim$agents [fisher_pop == 3, ]), sim$female_hr_table [fisher_pop == 3, hr_mean], sim$female_hr_table [fisher_pop == 3, hr_sd]))]
  sim$agents [fisher_pop == 4, hr_size := round (rnorm (nrow (sim$agents [fisher_pop == 4, ]), sim$female_hr_table [fisher_pop == 4, hr_mean], sim$female_hr_table [fisher_pop == 4, hr_sd]))]
  
  sim$agents [fisher_pop == 1, hr_size_lb :=  sim$female_hr_table [fisher_pop == 1, hr_mean]- 2*sim$female_hr_table [fisher_pop == 1, hr_sd]]
  sim$agents [fisher_pop == 2, hr_size_lb := sim$female_hr_table [fisher_pop == 2, hr_mean]- 2*sim$female_hr_table [fisher_pop == 2, hr_sd]]
  sim$agents [fisher_pop == 3, hr_size_lb := sim$female_hr_table [fisher_pop == 3, hr_mean]- 2*sim$female_hr_table [fisher_pop == 3, hr_sd]]
  sim$agents [fisher_pop == 4, hr_size_lb := sim$female_hr_table [fisher_pop == 4, hr_mean]- 2*sim$female_hr_table [fisher_pop == 4, hr_sd]]
 
  message ("Initiate fisher territories ...")
  # assign agents to territories table
  sim$territories <- data.table (individual_id = sim$agents$individual_id,  pixelid = sim$agents$pixelid)
  
  # create spread probability raster. Note: this is limited to fisher range
  sim$table.hab.spread <- table.habitat.init [ras_fisher_pop > 0, 
                                              c ("pixelid", "ras_fisher_denning_init", "ras_fisher_rust_init", "ras_fisher_cavity_init", "ras_fisher_cwd_init", "ras_fisher_movement_init", "ras_fisher_open_init")]
  names (sim$table.hab.spread) <- c ("pixelid", "denning", "rust", "cavity", "cwd", "movement", "open")
  

  return(invisible(sim))
}

getFisherHR<-function(sim){
  message ("Establishing fisher territories ...")
  # convert to raster objects for spread2
  sim$spread.rast <- spreadRast (raster::raster (sim$pix.rast), sim$table.hab.spread)
  contingentHR <- SpaDES.tools::spread2 (sim$spread.rast, 
                                       start = sim$agents$pixelid, 
                                       spreadProb = as.numeric (sim$spread.rast[]),
                                       exactSize = sim$agents$hr_size, 
                                       allowOverlap = F, asRaster = F, circle = F)
  
  message ("Assess territories for occupancy ...")
  #---- 1. Size Criteria
  check_size <- merge(contingentHR[, .(size_achieved = .N), by = initialPixels], sim$agents [, c ("pixelid", "individual_id", "hr_size", "hr_size_lb")],
                           by.x = "initialPixels", by.y = "pixelid")
  #-------------REMOVE AGENTS and TERRITORIES THAT DIDNT ACHIEVE MINIMUM TERRITORY SIZE
  remove_fisher <- check_size[size_achieved < hr_size_lb, ]
  sim$agents <- sim$agents[!(individual_id %in% remove_fisher$individual_id), ]
  contingentHR <- contingentHR[!(initialPixels %in% remove_fisher$initialPixels), ]
  
  #---- 2. Absolute amount of habitat
  check_habitat <- merge(contingentHR, sim$table.hab.spread[, c ("pixelid", "denning", "rust", "cavity", "cwd", "movement", "open")],
                       by.x = "pixels", by.y = "pixelid", all.x =TRUE)
  
  browser()
  hab.count <- check_habitat [denning == 1 | rust == 1 | cavity == 1 |cwd == 1 | movement == 1, .(total_hab = .N), by = initialPixels]
  hab.count <- merge (hab.count, sim$agents [, c ("hr_size", "pixelid", "individual_id")], by.x = "initialPixels", by.y = "pixelid", all.x=T)
  
  remove_fisher<- hab.count[total_hab/hr_size < 0.15, ]
  sim$agents<-sim$agents[!(individual_id %in% remove_fisher$individual_id), ]
  contingentHR<-contingentHR[!(initialPixels %in% remove_fisher$initialPixels), ]
  
  #---- 3. Habitat Quality Criteria
  tab.perc <- habitatQual (contingentHR, sim$agents, sim$fisher_d2_cov)
  
  return(invisible(sim))
}


spreadRast <- function (rasterInput, habitatInput) {
  #TODO: Net out current maintained territories so that NEW fisher can't spread into established territories
  
  out.rast <- rasterInput
  out.rast [] <- 0
  # currently uses all denning, rust, cavity, cwd, movement  and 'closed' (not open) habitat as 
  # spreadProb = 1, and non-habitat as spreadProb = 0.10; allows some spread to sub-optimal habitat
  habitatInput [denning == 1 | rust == 1 | cavity == 1 | cwd == 1 | movement == 1 | open == 0, spreadprob := format (round (1.00, 2), nsmall = 2)] 
  habitatInput [is.na (spreadprob), spreadprob := format (round (0.18, 2), 2)] # I tested different numbers
  # 18% resulted in the mean proportion of home ranges consisting of denning, resting or movement habitat as 55%; 19 was 49%; 17 was 59%; 20 was 47%; 15 was 66%
  # Caution: this parameter may be area-specific and may need to be and need to be 'tuned' for each AOI
  habitatInput [open == 1, spreadprob := format (round (0.09, 2), 2)]
  out.rast [habitatInput$pixelid] <- habitatInput$spreadprob
  return (out.rast)	
}


.inputObjects <- function(sim) {
  dPath <- asPath(getOption("reproducible.destinationPath", dataPath(sim)), 1)
  message(currentModule(sim), ": using dataPath '", dPath, "'.")
  
  if(!suppliedElsewhere("fisher_d2_cov", sim)){
    sim$fisher_d2_cov <- list(matrix(c(193.235,	5.418,	42.139,	125.177, -117.128, 5.418,	0.423,	2.926,	5.229, -4.498, 42.139,	2.926,	36.03,	46.52, -42.571, 125.177,	5.229, 46.52,	131.377, -101.195,	-117.128,	-4.498,	-42.571,	-101.195,	105.054), ncol = 5, nrow = 5), # 1- boreal
                              matrix(c(0.536,	2.742,	0.603,	3.211,	-2.735, 1.816, 2.742,	82.721,	4.877,	83.281,	7.046, -21.269, 0.603,	4.877,	0.872,	4.033,	-0.67, -0.569, 3.211,	83.281,	4.033,	101.315,	-15.394, -1.31,	-2.735,	7.046,	-0.67,	-15.394,	56.888,	-48.228,	1.816,	-21.269,	-0.569,	-1.31,	-48.228,	47.963), ncol = 6, nrow = 6), # 2- sbs-wet
                              matrix(c(0.525,	-1.909,	-0.143,	2.826,	-6.891, 3.264, -1.909,	96.766,	-0.715,	-39.021,	69.711, -51.688,	-0.143, -0.715,	0.209,	-0.267,	1.983, -0.176, 2.826,	-39.021,	-0.267,	58.108,	-21.928, 22.234, -6.891,	69.711,	1.983,	-21.928,	180.113, -96.369,	3.264,	-51.688,	-0.176,	22.234,	-96.369,	68.499), ncol = 6, nrow = 6), # 3 sbs-dry
                              matrix(c(2.905,	0.478,	4.04,	1.568, -3.89, 0.478,	0.683,	6.131,	8.055,	-8.04,	4.04,	6.131,	62.64,	73.82,	-62.447,	1.568,	8.055,	73.82,	126.953,	-130.153,	-3.89,	-8.04,	-62.447,	-130.153,	197.783), ncol = 5, nrow = 5) # 4 - Dry
    )
  }
  if(!suppliedElsewhere("survival_rate_table", sim)){
    sim$survival_rate_table <- data.table (Fpop = c (1,1,1,2,2,2,3,3,3,4,4,4),
                                         age = c ("Adult", "Juvenile", "Disperser", "Adult", "Juvenile", "Disperser", "Adult", "Juvenile", "Disperser", "Adult", "Juvenile", "Disperser"),
                                         Mean = c (0.8, 0.6, 0.6, 0.8, 0.6, 0.6, 0.8, 0.6, 0.6, 0.8, 0.6, 0.6),
                                         SD = c (0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1))
  }
  if(!suppliedElsewhere("repro_rate_table", sim)){
    sim$repro_rate_table <- data.table (Fpop = c(1,1,2,2,3,3,4,4),
                                      Param = c("DR", "LS","DR", "LS","DR", "LS","DR", "LS"),
                                      Mean = c(0.5,3,0.5,3,0.5,3,0.5,3),
                                      SD = c(0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1))
  }
  if(!suppliedElsewhere("female_hr_table", sim)){
    sim$female_hr_table <- data.table (fisher_pop = c (1:4), 
                                     hr_mean = c (3000, 4500, 4500, 3000),
                                     hr_sd = c (500, 500, 500, 500)) # updating to more realistic SD (higher for SBD but then crashes)
  }
  if(!suppliedElsewhere("mahal_metric_table", sim)){
  sim$mahal_metric_table <- data.table (FHE_zone = c ("Boreal", "Sub-Boreal moist", "Sub-Boreal dry", "Dry Forest"),
                                        FHE_zone_num = c (1:4),
                                        Mean = c (3.8, 4.4, 4.4, 3.6),
                                        SD = c (2.71, 1.09, 2.33, 1.62),
                                        Max = c (9.88, 6.01, 6.63, 7.5))
  }

  return(invisible(sim))
}
