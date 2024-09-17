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
  name = "FLEX",
  description = "An agent based model for fisher", 
  keywords = NA, # c("insert key words here"),
  authors = c(person("Joanna", "Burgar", email = "Joanna.Burgar@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre")),
              person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", FLEX = "2.1.2"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.md", "FLEX.Rmd"),
  reqdPkgs = list("sf"),
  parameters = rbind(
    defineParameter("burnInLength", "integer", 5, 1, 100, "The number of iterations to burn in"),
    defineParameter("d2_target", "integer", 7, 1, 15, "The D2 threshold"), 
    defineParameter("initialFisherPop", "integer", 9999, 1, 600, "The number of fisher to populate the landscape. If set to default 9999 then an estimate of the intital fisher pop is preformed"), 
    defineParameter("female_max_age", "numeric", 9, 0, 15, "The maximum possible age of a female fisher. Taken from research referenced by Roray Fogart in VORTEX_inputs_new.xlsx document."), 
    defineParameter("sex_ratio", "numeric", 0.5, 0, 1,"The probability of being a female in a litter."),
    defineParameter("reproductive_age", "numeric", 2, 0, 9,"The minimum reproductive age of a fisher."),
    defineParameter("female_dispersal", "numeric", 785000, 100, 10000000,"The area, in hectares, a fisher could explore during a dispersal to find a territory."),
    defineParameter("rasterHabitat", "character", paste0 (here::here(), "/R/scenarios/test_flex2/test_Williams_Lake_TSA_fisher_habitat.tif"), NA, NA, "Directory where the fisher habitat raster .tif is stored. Used as habitat input to this module. A band in the .tif exists for each time interval simulated in forestryCastor, and each fisher habitat type (denning, movement, cwd, rust, cavity)."), # create a default somewhere??
    defineParameter("timeInterval", "numeric", 1, 1, 20, "The time step, in years, when habtait was updated. It should be consistent with periodLength form growingStockCASTOR. Life history events (reproduce, updateHR, survive, disperse) are calaculated this many times for each interval."),
    defineParameter("den_target", "numeric", 0.001, 0, 1,"The minimum proportion of a home range that is denning habitat. Values taken from empirical female home range data across populations."), 
    defineParameter("rest_target", "numeric", 0.001, 0, 1, "The minimum proportion of a home range that is resting habitat. Values taken from empirical female home range data across populations."),   
    defineParameter("move_target", "numeric", 0.001, 0, 1, "The minimum proportion of a home range that is movement habitat. Values taken from empirical female home range data across populations."), 
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput (objectName = "scenario", objectClass = "data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput (objectName = "fisher_d2_cov", objectClass = "data.table", desc = "variance matrix for mahalanobis distance model; don't touch this unless d2 model updated", sourceURL = NA),
    expectsInput (objectName = "survival_rate_table", objectClass = "data.table", desc = "Table of fisher survival rates by sex, age and population, taken from Lofroth et al 2022 JWM vital rates manuscript. Headers: Fpop: the two populations in BC: Boreal, Coumbian; Age_class: two classes: Adult, Juvenile; Cohort: Fpop and Age_class combination: CFA, CFJ, BFA, BFJ; Mean: mean survival probability; SE: standard error of the mean. Decided to go with SE rather than SD as confidence intervals are quite wide and stochasticity would likely drive populations to extinction. Keeping consistent with Rory Fogarty's population analysis decisions.", sourceURL = NA),
    expectsInput (objectName = "repro_rate_table", objectClass = "data.table", desc = "Table of fisher reproductive rates (i.e., denning rate = a combination of pregnancy rate and birth rate; and litter size = number of kits) by population, taken from Lofroth et al 2022 JWM vital rates manuscript. Headers: Fpop: the two populations in BC: Boreal, Coumbian; Param: the reproductive parameter: DR (denning rate), LS (litter size); Mean: mean reproductive rate per parameter and population; SD: reproductive rate standard deviation value per parameter and population.", sourceURL = NA),
    expectsInput (objectName = "female_hr_table", objectClass = "data.table", desc = "Table of female home range sizes, by fisher population.", sourceURL = NA),
    expectsInput (objectName = "mahal_metric_table", objectClass = "data.table", desc = "Table of mahalanobis D2 values based on Fisher Habitat Extension zones, provided by Rich Weir summer 2022. Headers: FHE_zone: the four fisher habitat extension zones: Boreal, Sub-Boreal moist, Sub-Boreal dry, Dry Forest; FHE_zone_num: the corresponding FHE_zone number: Boreal = 1, Sub-Boreal moist = 2, Sub-Boreal Dry = 3, Dry Forest = 4; Mean: mean mahalanobis D2 value per FHE zone; SD: mahalanobis D2 standard deviation value per FHE zone; Max: maximum mahalanobis D2 value per FHE zone.", sourceURL = NA)
    ),
  outputObjects = bind_rows(
    createsOutput (objectName = "agents", objectClass = "data.table", desc = "Fisher agents table." ),
    createsOutput (objectName = "dispersers", objectClass = "data.table", desc = "Fisher dispersers table." ),
    createsOutput (objectName = "territories", objectClass = "data.table", desc = "Fisher territories table." ),
    createsOutput (objectName = "pix.rast", objectClass = "SpatRaster", desc = "A raster dataset of pixel values in the area of interest." ),
    createsOutput (objectName = "raster.stack", objectClass = "SpatRaster", desc = "The habitat data as a raster stack." ),
    createsOutput (objectName = "spread.rast", objectClass = "RasterLayer", desc = "The raster layer describing how fisher search for habitat." ),
    createsOutput (objectName = "table.hab.spread", objectClass = "data.table", desc = "Fisher habitat categoires table." ),
    createsOutput (objectName = "ras.territories", objectClass = "SpatRaster", desc = "The territories over a sim." ),
    createsOutput (objectName = "ras.territories.freq", objectClass = "SpatRaster", desc = "Number of times a pixel was used as a territories over a sim." ),
    createsOutput (objectName = "ras.territories.stack", objectClass = "SpatRaster", desc = "The territories over a sim as a stacked raster." ),
    createsOutput (objectName = "max.id", objectClass = "integer", desc = "The maximum territory identifier" ),
    createsOutput (objectName = "fisherABMReport", objectClass = "data.table", desc = "A data.table object. Consists of fisher population numbers in the study area at each time step."),
    
  )
))


doEvent.FLEX = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- Init(sim)
      sim <- getInitialFisherHR(sim)
      for (i in 1:P(sim, "burnInLength", "FLEX")) { #What should this order be?
        sim <- survivalFisher(sim) #overall survival for the year -- remove mothers and unborn kits before the year starts
        sim <- disperseFisher(sim) #go find a territory if the habitat changed or kits born year previously
        sim <- reproduceFisher(sim) #since territories are established -- can reproduce and have kits age = 0.
        sim <- ageFisher(sim) # age the fisher so the kits are one year starting in the next i
        #sim <- recordABMReport(sim, i)
        sim <- plot_territories(sim)
      }
      sim <- recordABMReport(sim, 0)
      sim <- scheduleEvent (sim, time (sim) + 1, "FLEX", "runevents", 19)
      sim <- scheduleEvent (sim, end(sim), "FLEX", "save_fisher_reports", 20)
    },
    runevents = {
      
      sim <- updateHabitat (sim)
      sim <- checkHabitatNeeds(sim)
      
      for (i in 1:P(sim, "timeInterval", "FLEX")) { #What should this order be?
        sim <- survivalFisher(sim) #overall survival for the year -- remove mothers and unborn kits before the year starts
        sim <- disperseFisher(sim) #go find a territory if the habitat changed or kits born year previously
        sim <- plot_territories(sim)
        sim <- reproduceFisher(sim) #since territories are established -- can reproduce and have kits age = 0.
        sim <- ageFisher(sim) # age the fisher so the kits are one year starting in the next i
        sim <- recordABMReport(sim, i)
      }
      
      sim <- scheduleEvent (sim, time(sim) + 1, "FLEX", "runevents", 19)
    },
    
    reportFisherABM = {
      sim <- recordABMReport (sim)
      sim <- scheduleEvent (sim, time (sim) + 1, "FLEX", "reportFisherABM", 20)
    },
    
    plot = {
      sim <- plot_territories(sim)
    },
    save_fisher_reports = {
      sim <- saveFisherReports(sim)
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  message ("Load the habitat data.")
  sim$raster.stack <- terra::rast (P (sim, "rasterHabitat", "FLEX")) 
  
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
                                     n_f_disp  = as.numeric (), # number of kit females
                                     #mort_n_f_adult = as.numeric (), # number of adult female moralities
                                     #mort_n_f_juv = as.numeric (), # number of juvenile females  moralities
                                     #mort_n_f_disp  = as.numeric (), # number of disperser moralities
                                     mean_age_f = as.numeric (), # mean age of females
                                     sd_age_f = as.numeric (), # standard dev age of females
                                     timeperiod = as.integer (), # time step of the simulation
                                     scenario = as.character ()
  )

  sim$ras.territories <- sim$pix.rast
  sim$ras.territories [] <- 0
  sim$ras.territories.freq <- sim$ras.territories
  
  message ("Create fisher agents table and assign values...")
  den.pix <- table.habitat.init [ras_fisher_denning_init == 1, c ("pixelid", "ras_fisher_denning_init")]
  #use an aggregated raster to find denning pixels to establish
  den.rast <- terra::subset (sim$raster.stack, grep ("ras_fisher_denning_init", names (sim$raster.stack)))
  
  #POPULATE LANDSCAPE WITH FISHER
  #Get the initial number of fisher from user or estimate. 
  if(P(sim, "initialFisherPop", "FLEX") == 9999 ){ # estimate the initial number of fisher
   den.rast.ag <- aggregate(den.rast, fact=50) # fact is the number of pixels to expand by -- so 50 = 60 x 60 ha ~ 3600 ha or 25 km2
   init_n_fisher <- nrow(den.rast.ag[den.rast.ag[] > 0.01]) # Remove remote areas (i.e., lakes) that have no denning within 2500 ha
  }else{ #use the user specified initial number of fisher
    init_n_fisher <- P(sim, "initialFisherPop", "FLEX")
  }
                 
  den.pix.coords<- data.table(xyFromCell(sim$pix.rast, den.pix$pixelid))
  den.pix.coords$pixelid<-den.pix$pixelid
  
  #Use a well balanced sampling design see: https://dickbrus.github.io/SpatialSamplingwithR/BalancedSpreaded.html#LPM 
  #set.seed(1586) #Useful for testing
  pi <- sampling::inclusionprobabilities(rep(1/nrow(den.pix), nrow(den.pix)), init_n_fisher) #Equal probability. TODO: inclusion probabilities can be based on field data
  den.samples <- lpm(pi, cbind(den.pix.coords$x, den.pix.coords$y)) #Local pivot method using BalancedSampling
  denning.starts <- den.pix.coords[den.samples, ]
  
  # create agents table  
  sim$agents <- data.table (individual_id = seq (from = 1, to = nrow (denning.starts), by = 1),
                            sex = "F",
                            age = sample(x = c(3,4,5,6,7,8,9,10,11,12), nrow (denning.starts), replace = T, prob = c(0.5,0.05,0.04,0.01,0.01,0.01,0.001,0.001,0.001,0.001)), # randomly draw ages from discrete distribution Rich Weir sample data
                            initialPixels = denning.starts$pixelid,
                            size_achieved = as.numeric(NA))
  #Add in dispersers age <= 2 years (which account for ~70% of the population)
  n_disp = round((nrow (denning.starts)/(100-(44+27)))*(44+27), 0)
  max_id<- max(sim$agents$individual_id) + 1
  sim$agents<-rbindlist(list(sim$agents, data.table (individual_id = seq (from = max_id , to = (max_id + (n_disp-1)), by = 1),
              sex = "F",
              age = sample(x = c(1,2), n_disp, replace = T, prob = c(0.44, 0.27)), # randomly draw ages from discrete distribution Rich Weir sample data
              initialPixels = sample(denning.starts$pixelid, n_disp, replace =T),
              size_achieved = NA)
  ))
  
  #---- assign the population to sim$agents table
  tab.fisher.pop <- table.habitat.init [ras_fisher_pop > 0, c ("pixelid", "ras_fisher_pop")]
  names (tab.fisher.pop) <- c ("pixelid", "fisher_pop")
  tab.fisher.pop$fisher_pop <- as.numeric (tab.fisher.pop$fisher_pop)
  sim$agents <- merge (sim$agents, 
                       tab.fisher.pop [ , c("pixelid", "fisher_pop")], 
                       by.x = "initialPixels", by.y = "pixelid", all.x = T)
  
  #---- assign an HR size based on population
  sim$agents [fisher_pop == 1, hr_size := round (rnorm (nrow (sim$agents [fisher_pop == 1, ]), sim$female_hr_table [fisher_pop == 1, hr_mean], sim$female_hr_table [fisher_pop == 1, hr_sd]))]
  sim$agents [fisher_pop == 2, hr_size := round (rnorm (nrow (sim$agents [fisher_pop == 2, ]), sim$female_hr_table [fisher_pop == 2, hr_mean], sim$female_hr_table [fisher_pop == 2, hr_sd]))]
  sim$agents [fisher_pop == 3, hr_size := round (rnorm (nrow (sim$agents [fisher_pop == 3, ]), sim$female_hr_table [fisher_pop == 3, hr_mean], sim$female_hr_table [fisher_pop == 3, hr_sd]))]
  sim$agents [fisher_pop == 4, hr_size := round (rnorm (nrow (sim$agents [fisher_pop == 4, ]), sim$female_hr_table [fisher_pop == 4, hr_mean], sim$female_hr_table [fisher_pop == 4, hr_sd]))]
  
  sim$agents [fisher_pop == 1, hr_size_lb :=  sim$female_hr_table [fisher_pop == 1, hr_mean]- 2*sim$female_hr_table [fisher_pop == 1, hr_sd]]
  sim$agents [fisher_pop == 2, hr_size_lb := sim$female_hr_table [fisher_pop == 2, hr_mean]- 2*sim$female_hr_table [fisher_pop == 2, hr_sd]]
  sim$agents [fisher_pop == 3, hr_size_lb := sim$female_hr_table [fisher_pop == 3, hr_mean]- 2*sim$female_hr_table [fisher_pop == 3, hr_sd]]
  sim$agents [fisher_pop == 4, hr_size_lb := sim$female_hr_table [fisher_pop == 4, hr_mean]- 2*sim$female_hr_table [fisher_pop == 4, hr_sd]]
 
  #assign a NA d2
  sim$agents[, d2:=NA]
  
  #Create the dispersers as age<=2
  sim$dispersers<-sim$agents[age <=2, ]
  sim$agents<-sim$agents[age >2, ]
  # create spread probability raster. Note: this is limited to fisher range. Any pixel thats classified as fisher habitat category contains a probability
  sim$table.hab.spread <- table.habitat.init [ras_fisher_pop > 0, 
                                              c ("pixelid", "ras_fisher_denning_init", "ras_fisher_rust_init", "ras_fisher_cavity_init", "ras_fisher_cwd_init", "ras_fisher_movement_init", "ras_fisher_open_init")]
  names (sim$table.hab.spread) <- c ("pixelid", "denning", "rust", "cavity", "cwd", "movement", "open")
  return(invisible(sim))
}

getInitialFisherHR<-function(sim){
  message ("Establishing fisher territories ...")
  # convert to raster objects for spread2 not needed
  sim$spread.rast <- spreadRast (sim$pix.rast, sim$table.hab.spread, NULL)
  contingentHR <- SpaDES.tools::spread2 (sim$spread.rast, 
                                       start = sim$agents$initialPixels, 
                                       spreadProb = sim$spread.rast,
                                       exactSize = sim$agents$hr_size, 
                                       allowOverlap = F, asRaster = F, circle = F)
  #Convert the raster spread process from territory searching into a minimum convex polygon
  total_ha<-contingentHR[, .N, by = "initialPixels"]
  contingentHR<-contingentHR[!(initialPixels %in% total_ha[N < 100, ]$initialPixels),]
  if(nrow(contingentHR) > 0) {
    contingentHR.ras<-mcp_spread(sim$pix.rast, contingentHR)
  }else{
    contingentHR.ras<-contingentHR
  }
  #Assess territories for occupancy
  #Check the size of the territories
  #Update the sim$agents table to reflect territory size that has been polygonized
  #---- 1. Size Criteria
  have_hr_size<-sim$agents[!is.na(size_achieved), ]
  dont_have_hr_size<-sim$agents[is.na(size_achieved), ]
  dont_have_hr_size$size_achieved <- NULL
  dont_have_hr_size <- merge(contingentHR.ras[, .(size_achieved = .N), by = initialPixels], dont_have_hr_size,
                           by.x = "initialPixels", by.y = "initialPixels", all.y=T)
  sim$agents<-rbindlist(list(have_hr_size, dont_have_hr_size), use.names=TRUE)
  
  #Remove fisher -- small home ranges can have suitable habitat so need to move them to dispersers table
  remove_fisher <- sim$agents[size_achieved < hr_size_lb & size_achieved < hr_size, ]
 
  sim$dispersers<- rbindlist(list(sim$dispersers, sim$agents[individual_id %in% remove_fisher$individual_id, c("initialPixels", "individual_id", "sex", "age", "fisher_pop", "hr_size", "hr_size_lb", "d2", "size_achieved")]), use.names=TRUE)
  sim$agents <- sim$agents[!(individual_id %in% remove_fisher$individual_id), ]
  contingentHR.ras <- contingentHR.ras[!(initialPixels %in% remove_fisher$initialPixels), ]
  
  #---- 2. Absolute amount of habitat -- this is checked by d2 now see 3. below
  check_habitat <- merge(contingentHR.ras, sim$table.hab.spread[, c ("pixelid", "denning", "rust", "cavity", "cwd", "movement", "open")],
                       by.x = "pixelid", by.y = "pixelid", all.x =TRUE)
  
  #hab.count <- check_habitat [denning == 1 | rust == 1 | cavity == 1 |cwd == 1 | movement == 1, .(total_hab = .N), by = initialPixels]
  #hab.count <- merge (hab.count, sim$agents [, c ("size_achieved", "initialPixels", "individual_id")], by.x = "initialPixels", by.y = "initialPixels", all.x=T)
  
  #remove_fisher<- hab.count[total_hab/size_achieved < 0.15, ]
  #sim$dispersers<- rbindlist(list(sim$dispersers, sim$agents[individual_id %in% remove_fisher$individual_id, ]))
  #sim$agents<-sim$agents[!(individual_id %in% remove_fisher$individual_id), ]
  #contingentHR.ras<-contingentHR.ras[!(initialPixels %in% remove_fisher$initialPixels), ]
  #check_habitat <- check_habitat[!(initialPixels %in% remove_fisher$initialPixels),]

  #---- 3. Habitat Quality Criteria fir adjusting survival rate
  tab.perc <- habitatQual (check_habitat, sim$agents, sim$fisher_d2_cov)
  #remove_fisher<- tab.perc[d2 > P(sim, "d2_target", "FLEX") | den_perc < P(sim, "den_target", "FLEX") | cwd_perc < P(sim, "rest_target", "FLEX")| move_perc < P(sim, "move_target", "FLEX"), ]
  #sim$dispersers<- rbindlist(list(sim$dispersers, sim$agents[individual_id %in% remove_fisher$individual_id, ]))
  #sim$agents<-sim$agents[!(individual_id %in% remove_fisher$individual_id), ]
  #contingentHR.ras<-contingentHR.ras[!(initialPixels %in% remove_fisher$initialPixels), ]
  
  # Report Outputs
  sim$agents <- merge (sim$agents, tab.perc [, .(individual_id, d2_score = d2)], by = "individual_id")
  
  # save the largest individual id; need this later for setting id's of kits
  sim$max.id <- max (sim$agents$individual_id, sim$dispersers$individual_id, na.rm = TRUE)
  
  # territories raster set a territory as value = 1 
  # final raster is the number of time periods that a pixel was a territory
  sim$ras.territories[contingentHR.ras$pixelid]<-contingentHR.ras$initialPixels
  sim$territories<-contingentHR.ras
  
  if(is.null(sim$dispersers)){
    sim$dispersers<-sim$agents[sex == 'U', ] #make an empty object
  }
  sim$dispersers[, d2_score := NA]
  message (paste0("Territories formed:", nrow(sim$agents)))
  return(invisible(sim))
}


disperseFisher<- function(sim){

  message (paste0("disperseFisher: # dispersing:", nrow(sim$dispersers)))
  sim$dispersers[, size_achieved:=NA] #reset all the home ranges
 
  if (nrow (sim$dispersers) > 0) { # check to make sure there are dispersers
    # ADULTS PREVIOUSLY ESTABLISHED--Allow fisher whose territories have been degraded are allowed to change their territory shape
    est.fisher<-sim$dispersers[age > 1,]
    if(nrow(est.fisher) > 0){ # fisher who have and individual id had a territory
      sim$dispersers[sim$dispersers[,age > 1],id:= .I ] # Need id (an identifier for the adults)
      #check to find the nearest denning habitat to their current
      den.available <- sim$table.hab.spread[denning == 1 & !(pixelid %in% sim$territories$pixelid),]
      den.available.coords <- data.table(xyFromCell(sim$pix.rast, den.available$pixelid))
      den.available.coords$pixelid <- den.available$pixelid
      
      current.location.coords <- data.table(xyFromCell(sim$pix.rast, est.fisher$initialPixels))
      current.location.coords <- current.location.coords[, id := .I]
      
      #Get the available number of territories and compare to the number of preestablished that need a territory
      den.rast <- sim$pix.rast
      den.rast[] <- 0
      den.rast[den.available$pixelid] <- 1
      
      den.rast.ag <- aggregate(den.rast, fact=50) # fact is the number of pixels to expand by -- so 50 = 60 x 60 ha ~ 3600 ha or 25 km2
      n_fisher <- nrow(den.rast.ag[den.rast.ag[] > 0.01]) # Remove remote areas (i.e., lakes) that have no denning within 2500 ha
      
      # den.rast.ag <- aggregate(den.rast, fact=round(sqrt(mean(sim$female_hr_table$hr_mean)),0)) #fact is the number of pixels to expand by -- so 50 = 60 x 60 ha ~ 3600 ha or 25 km2
      # n_fisher <- nrow(den.rast.ag[den.rast.ag[] > 0.008]) #Remove remote areas (i.e., lakes) that have denning sites that have less than 1 percent denning
      
      #Use a well balanced sampling design see: https://dickbrus.github.io/SpatialSamplingwithR/BalancedSpreaded.html#LPM 
      #set.seed(1586) #Useful for testing
      pi <- sampling::inclusionprobabilities(rep(1/nrow(den.available), nrow(den.available)), n_fisher) #Equal probability
      den.samples <- lpm(pi, cbind(den.available.coords$x, den.available.coords$y))#, h=5000) #Local pivot method using BalancedSampling
      denning.starts <- den.available.coords[den.samples, ] # Location potentials for the juvies
      
      #Allocate adults to denning sites. See which adults are the closest to each of the denning.starts
      den.site.potentials <- RANN::nn2 (data =  denning.starts[,c("x", "y")], 
                                        query = current.location.coords[,c("x", "y")], 
                                        searchtype = 'radius', radius =  as.integer(P(sim, "female_dispersal", "FLEX")), k =min(10, nrow(denning.starts[,c("x", "y")])))
      
      
      temp_sites<-getClosestWellSpreadDenningSites(den.site.potentials$nn.idx, den.site.potentials$nn.dists) #TODO: test for ties -- same initialPixels
      current.location.coords<-merge(current.location.coords, temp_sites, by= "id")
      current.location.coords.found.site<-current.location.coords[ds.indx > 0, ]
      
      if(nrow(current.location.coords.found.site) > 0 ){ # found some denning sites for the pre-established
        
        current.location.coords.found.site$new_pixelid <- denning.starts[current.location.coords.found.site$ds.indx]$pixelid
        current.location.coords<-merge(current.location.coords, current.location.coords.found.site[, c("id", "new_pixelid")], by = "id")
        
        #Change pixelid in sim$dispersers
        sim$dispersers<-merge(sim$dispersers, current.location.coords[,c("id", "new_pixelid")], by.x = "id",by.y = "id", all.x =T)
        sim$dispersers[new_pixelid > 0, initialPixels := new_pixelid]
        
        adult.fisher.found.site<-sim$dispersers[new_pixelid > 0, ]
        #adult.fisher.found.site$size_achieved<-NULL
        
        sim$spread.rast <- spreadRast (sim$pix.rast, sim$table.hab.spread, sim$territories)
        sim$dispersers$new_pixelid <- NULL
        contingentHR <- SpaDES.tools::spread2 (sim$spread.rast, 
                                               start = adult.fisher.found.site$initialPixels, 
                                               spreadProb = as.numeric (sim$spread.rast[]),
                                               exactSize = adult.fisher.found.site$hr_size, # try to find same home range size
                                               allowOverlap = F, asRaster = F, circle = F)
        #Convert the raster spread process from territory searching into a minimum convex polygon
        total_ha<-contingentHR[, .N, by = "initialPixels"]
        contingentHR<-contingentHR[!(initialPixels %in% total_ha[N < 100, ]$initialPixels),]
        if(nrow(contingentHR) > 0) {
          contingentHR.ras<-mcp_spread(sim$pix.rast, contingentHR)
        }else{
          contingentHR.ras<-contingentHR
        }
        check_size <- merge(contingentHR.ras[, .(size_achieved = .N), by = initialPixels], adult.fisher.found.site [, c ("initialPixels", "individual_id", "hr_size", "hr_size_lb")],
                            by.x = "initialPixels", by.y = "initialPixels", all.y=T)
        remove_fisher <- check_size[size_achieved < hr_size_lb | is.na(size_achieved), ]
        adult.fisher.found.site  <- adult.fisher.found.site [!(individual_id %in% remove_fisher$individual_id), ]
        adult.fisher.found.site$size_achieved  <- NULL
        adult.fisher.found.site<- merge(adult.fisher.found.site, check_size [, c("individual_id", "size_achieved")],by.x = "individual_id", by.y = "individual_id", all.x = T)
        contingentHR.ras <- contingentHR.ras[!(initialPixels %in% remove_fisher$initialPixels), ]
        
        #Change hr_size in sim$dispersers
        have_hr_size<-sim$dispersers[!is.na(size_achieved), ]
        dont_have_hr_size<-sim$dispersers[is.na(size_achieved), ]
        dont_have_hr_size$size_achieved <- NULL
        
        dont_have_hr_size<- merge(dont_have_hr_size, check_size [size_achieved >=hr_size_lb , c("initialPixels", "size_achieved")],by.x = "initialPixels", by.y = "initialPixels", all.x = T)
        sim$dispersers<-rbindlist(list(have_hr_size, dont_have_hr_size), use.names = TRUE)
        
        #---- 2. Absolute amount of habitat
        if(nrow(adult.fisher.found.site) > 0){
          check_habitat <- merge(contingentHR.ras, sim$table.hab.spread[, c ("pixelid", "denning", "rust", "cavity", "cwd", "movement", "open")],
                                 by.x = "pixelid", by.y = "pixelid", all.x =TRUE)
          
          #hab.count <- check_habitat [denning == 1 | rust == 1 | cavity == 1 |cwd == 1 | movement == 1, .(total_hab = .N), by = initialPixels]
          #hab.count <- merge (hab.count, adult.fisher.found.site  [, c ("hr_size", "pixelid")], by.x = "initialPixels", by.y = "pixelid", all.x=T)
          
          #remove_fisher<- hab.count[total_hab/hr_size < 0.15, ]
          #adult.fisher.found.site <- adult.fisher.found.site [!(pixelid %in% remove_fisher$initialPixels), ]
          #contingentHR.ras <- contingentHR.ras[!(initialPixels %in% remove_fisher$initialPixels), ]
          #check_habitat <- check_habitat[!(initialPixels %in% remove_fisher$initialPixels),]
          
          #---- 3. Habitat Quality Criteria
         
            tab.perc <- habitatQual (check_habitat, adult.fisher.found.site, sim$fisher_d2_cov)
            #remove_fisher<- tab.perc[d2 > P(sim, "d2_target", "FLEX") | den_perc < P(sim, "den_target", "FLEX") | cwd_perc < P(sim, "rest_target", "FLEX")| move_perc < P(sim, "move_target", "FLEX"), ]
            #adult.fisher.found.site <- adult.fisher.found.site [!(pixelid %in% remove_fisher$initialPixels), ]
            #contingentHR<-contingentHR[!(initialPixels %in% remove_fisher$initialPixels), ]
            
            # fisher were able to re-establish. Include the agent and territory - 
            
              message(paste0("disperseFisher: # adults established: ", nrow(adult.fisher.found.site)))
              tab.perc<-tab.perc[, d2_score:=d2]
              adult.fisher.found.site <- adult.fisher.found.site[,`:=`(d2_score = NULL)] #remove variables not found in sim$agents
              adult.fisher.found.site<-merge(adult.fisher.found.site, tab.perc[,c("individual_id", "d2_score")], by.x = "individual_id", by.y = "individual_id")
              sim$territories<-rbindlist(list(sim$territories, contingentHR.ras[initialPixels %in% adult.fisher.found.site$initialPixels]))
              #message(nrow(sim$territories))
              sim$spread.rast <- spreadRast (sim$pix.rast, sim$table.hab.spread, sim$territories)
              
              #Assign an individual_id to the established juvies
              #juv.fisher.found.site[, new_individual_id := sim$max.id + .I] #add a unique ID
              
              #update sim$dispersers
              sim$dispersers<- sim$dispersers[,`:=`(d2_score = NULL)]
              sim$dispersers<-merge(sim$dispersers, adult.fisher.found.site[, c("individual_id", "d2_score")], by.x = "individual_id", by.y = "individual_id", all.x =T)
              keep_dispersers<-sim$dispersers[is.na(d2_score), ]$individual_id
              sim$dispersers<-sim$dispersers[, `:=`(id = NULL)]
              sim$agents<-rbindlist(list(sim$agents, sim$dispersers[!is.na(d2_score),]), use.names=TRUE) # add the individuals back to the agents table
              sim$dispersers<-sim$dispersers[individual_id %in% keep_dispersers, ] #Fisher stay in the dispersers table
              sim$max.id<-max(sim$agents$individual_id, sim$dispersers$individual_id, na.rm=TRUE)
              if(is.null(sim$dispersers)){
                sim$dispersers<-data.table (individual_id = as.integer(), pixelid = as.integer(), sex = as.character(),age = as.integer(),  fisher_pop = as.integer(), hr_size = as.integer(), hr_size_lb = as.integer(), d2_Score = as.numeric )
              }
            
          
        }
      }
      sim$dispersers<-sim$dispersers[, id := 0]
      sim$dispersers<-sim$dispersers[, `:=`(id = NULL)]
      sim$dispersers$size_achieved<-NA
    }
    #browser()
    #---Kits try disperse after the adults (larger sized animals win)
    #check the individual_id post habitatQual calls, assign an individual_id to these establish juvies
    if(nrow(sim$dispersers[ age >= 1,]) > 0){ #kits and adults that haven't established
      #sim$dispersers[is.na(individual_id) & age > 0, id := .I] # Need id (an identifier for the juvenile)
      sim$dispersers[sim$dispersers[, age >= 1],id:= .I ]
      juv.fisher <- sim$dispersers[id > 0, ] 
 
      current.location.coords <- data.table(xyFromCell(sim$pix.rast, juv.fisher$initialPixels))
      current.location.coords <- cbind(current.location.coords, juv.fisher)
      
      #Sample denning sites the same way as the init allowing some juveniles to disperse
      den.available <- sim$table.hab.spread[denning == 1 & !(pixelid %in% sim$territories$pixels),] #Need this because the sim$territories may have changed when adults have re-established territories
      den.available.coords <- data.table(xyFromCell(sim$pix.rast, den.available$pixelid))
      #plot(den.available.coords)
      den.available.coords$pixelid <- den.available$pixelid
      
      #Get the available number of territories and compare to the number of juvies that need a territory
      den.rast <- sim$pix.rast
      den.rast[] <- 0
      den.rast[den.available$pixelid] <- 1
      den.rast.ag <- terra::aggregate(den.rast, fact=round(sqrt(mean(sim$female_hr_table$hr_mean)),0)) #fact is the number of pixels to expand by -- so 50 = 60 x 60 ha ~ 3600 ha or 25 km2
      n_fisher <- nrow(den.rast.ag[den.rast.ag[] > 0.008]) #Remove remote areas (i.e., lakes) that have denning sites that have less than 1 percent denning
  
      #Use a well balanced sampling design see: https://dickbrus.github.io/SpatialSamplingwithR/BalancedSpreaded.html#LPM 
      #set.seed(1586) #Useful for testing
      pi <- sampling::inclusionprobabilities(rep(1/nrow(den.available), nrow(den.available)), n_fisher) #Equal probability
      den.samples <- lpm(pi, cbind(den.available.coords$x, den.available.coords$y)) #Local pivot method using BalancedSampling
      denning.starts <- den.available.coords[den.samples, ] # Location potentials for the juvies
      
      #Allocate juveniles to denning sites. See which juveniles are the closest to each of the denning.starts
      den.site.potentials <- RANN::nn2 (data =  denning.starts[,c("x", "y")], 
                                        query = current.location.coords[,c("x", "y")], 
                                        searchtype = 'radius', radius =  as.integer(P(sim, "female_dispersal", "FLEX")), k =min(10, nrow(denning.starts[,c("x", "y")])))
      
      
      temp_sites<-getClosestWellSpreadDenningSites(den.site.potentials$nn.idx, den.site.potentials$nn.dists) #TODO: test for ties -- same initialPixels
      current.location.coords<-merge(current.location.coords, temp_sites, by= "id")
      current.location.coords.found.site<-current.location.coords[ds.indx > 0, ]
      
      if(nrow(current.location.coords.found.site) > 0 ){ # found some denning sites for the juvies
        
        current.location.coords.found.site$new_pixelid <- denning.starts[current.location.coords.found.site$ds.indx]$pixelid
        current.location.coords<-merge(current.location.coords, current.location.coords.found.site[, c("id", "new_pixelid")], by = "id")

        #Change pixelid in sim$dispersers
        sim$dispersers<-merge(sim$dispersers, current.location.coords[,c("id", "new_pixelid")], by.x = "id", by.y = "id", all.x =T)
        sim$dispersers[new_pixelid > 0, initialPixels := new_pixelid]

        juv.fisher.found.site<-sim$dispersers[!is.na(new_pixelid), ]
        sim$dispersers$new_pixelid <- NULL
  
        #juv.fisher.found.site<-juv.fisher.found.site[, initialPixels:= new_pixelid]
        sim$spread.rast <- spreadRast (sim$pix.rast, sim$table.hab.spread, sim$territories)
        #---- assign fisher_pop?
        #---- assign an HR size based on population
        
        juv.fisher.found.site [fisher_pop == 1, hr_size := round (rnorm (nrow (juv.fisher.found.site [fisher_pop == 1, ]), sim$female_hr_table [fisher_pop == 1, hr_mean], sim$female_hr_table [fisher_pop == 1, hr_sd]))]
        juv.fisher.found.site [fisher_pop == 2, hr_size := round (rnorm (nrow (juv.fisher.found.site [fisher_pop == 2, ]), sim$female_hr_table [fisher_pop == 2, hr_mean], sim$female_hr_table [fisher_pop == 2, hr_sd]))]
        juv.fisher.found.site [fisher_pop == 3, hr_size := round (rnorm (nrow (juv.fisher.found.site [fisher_pop == 3, ]), sim$female_hr_table [fisher_pop == 3, hr_mean], sim$female_hr_table [fisher_pop == 3, hr_sd]))]
        juv.fisher.found.site [fisher_pop == 4, hr_size := round (rnorm (nrow (juv.fisher.found.site [fisher_pop == 4, ]), sim$female_hr_table [fisher_pop == 4, hr_mean], sim$female_hr_table [fisher_pop == 4, hr_sd]))]
        
        juv.fisher.found.site [fisher_pop == 1, hr_size_lb := sim$female_hr_table [fisher_pop == 1, hr_mean]- 2*sim$female_hr_table [fisher_pop == 1, hr_sd]]
        juv.fisher.found.site [fisher_pop == 2, hr_size_lb := sim$female_hr_table [fisher_pop == 2, hr_mean]- 2*sim$female_hr_table [fisher_pop == 2, hr_sd]]
        juv.fisher.found.site [fisher_pop == 3, hr_size_lb := sim$female_hr_table [fisher_pop == 3, hr_mean]- 2*sim$female_hr_table [fisher_pop == 3, hr_sd]]
        juv.fisher.found.site [fisher_pop == 4, hr_size_lb := sim$female_hr_table [fisher_pop == 4, hr_mean]- 2*sim$female_hr_table [fisher_pop == 4, hr_sd]]
        
        contingentHR <- SpaDES.tools::spread2 (sim$spread.rast, 
                                               start = juv.fisher.found.site$initialPixels, 
                                               spreadProb = as.numeric (sim$spread.rast[]),
                                               exactSize = juv.fisher.found.site$hr_size, # try to find same home range size
                                               allowOverlap = F, asRaster = F, circle = F)
        # only care about home range bigger than 100 ha
        total_ha<-contingentHR[, .N, by = "initialPixels"]
        contingentHR<-contingentHR[!(initialPixels %in% total_ha[N < 100, ]$initialPixels),]
        if(nrow(contingentHR) > 0) {
          contingentHR.ras<-mcp_spread(sim$pix.rast, contingentHR)
        }else{
          contingentHR.ras<-contingentHR
        }
        check_size <- merge(contingentHR.ras[, .(size_achieved = .N), by = initialPixels], juv.fisher.found.site [, c ("initialPixels", "id", "individual_id", "hr_size", "hr_size_lb")],
                            by.x = "initialPixels", by.y = "initialPixels", all.y=TRUE)
        remove_fisher <- check_size[size_achieved < hr_size_lb | is.na(size_achieved), ]
       
        juv.fisher.found.site  <- juv.fisher.found.site [!(initialPixels %in% remove_fisher$initialPixels), ]
        juv.fisher.found.site$size_achieved  <- NULL
        juv.fisher.found.site<- merge(juv.fisher.found.site, check_size [, c("initialPixels", "size_achieved")],by.x = "initialPixels", by.y = "initialPixels", all.x = T)
        contingentHR.ras <- contingentHR.ras[!(initialPixels %in% remove_fisher$initialPixels), ]
        
        #Change hr_size in sim$dispersers
        have_hr_size<-sim$dispersers[!is.na(size_achieved), ]
        dont_have_hr_size<-sim$dispersers[is.na(size_achieved), ]
        dont_have_hr_size$size_achieved <- NULL
        #browser()
        dont_have_hr_size<- merge(dont_have_hr_size, check_size [, c("individual_id", "size_achieved")],by.x = "individual_id", by.y = "individual_id", all.x = T)
        sim$dispersers<-rbindlist(list(have_hr_size, dont_have_hr_size), use.names = TRUE)
        
        #---- 2. Absolute amount of habitat
        if(nrow(juv.fisher.found.site) > 0){
          check_habitat <- merge(contingentHR.ras, sim$table.hab.spread[, c ("pixelid", "denning", "rust", "cavity", "cwd", "movement", "open")],
                                 by.x = "pixelid", by.y = "pixelid", all.x =TRUE)
          
          tab.perc <- habitatQual (check_habitat, juv.fisher.found.site, sim$fisher_d2_cov)
          #remove_fisher<- tab.perc[d2 > P(sim, "d2_target", "FLEX") | den_perc < P(sim, "den_target", "FLEX") | cwd_perc < P(sim, "rest_target", "FLEX")| move_perc < P(sim, "move_target", "FLEX"), ]
           # juv.fisher.found.site <- juv.fisher.found.site [!(pixelid %in% remove_fisher$initialPixels), ]
            #contingentHR<-contingentHR[!(initialPixels %in% remove_fisher$initialPixels), ]
            
          # fisher were able to re-establish. Include the agent and territory - 
          message(paste0("disperseFisher: # juvs established:", nrow(juv.fisher.found.site))) 
          tab.perc<-tab.perc[, d2_score:=d2]
          juv.fisher.found.site <- juv.fisher.found.site[,`:=`(d2_score = NULL)] #remove variables not found in sim$agents
          juv.fisher.found.site<-merge(juv.fisher.found.site, tab.perc[,c("individual_id", "d2_score")], by.x = "individual_id", by.y = "individual_id")
          sim$territories<-rbindlist(list(sim$territories, contingentHR.ras))
          #message(nrow(sim$territories))
          sim$spread.rast <- spreadRast (sim$pix.rast, sim$table.hab.spread, sim$territories)
          
          #Assign an individual_id to the established juvies
          #sim$max.id<-max(sim$agents$individual_id, sim$dispersers$individual_id, na.rm=T)
          #juv.fisher.found.site[, new_individual_id := sim$max.id + .I] #add a unique ID
             
          #update sim$dispersers
          sim$dispersers<- sim$dispersers[,`:=`(d2_score = NULL)]
          sim$dispersers<-merge(sim$dispersers, juv.fisher.found.site[, c("individual_id", "d2_score")], by.x = "individual_id", by.y = "individual_id", all.x =T)
          #sim$dispersers[!is.na(new_individual_id), individual_id := new_individual_id]
          keep_dispersers<-sim$dispersers[is.na(d2_score), ]$individual_id
          sim$dispersers<-sim$dispersers[, `:=`(id = NULL)]
          sim$agents<-rbindlist(list(sim$agents, sim$dispersers[!is.na(d2_score),]), use.names=TRUE) # add the individuals back to the agents table
          sim$dispersers<-sim$dispersers[individual_id %in% keep_dispersers, ] #Fisher stay in the dispersers table
          sim$max.id<-max(sim$agents$individual_id, sim$dispersers$individual_id)
          
          if(is.null(sim$dispersers)){
            sim$dispersers<-data.table (individual_id = as.integer(), pixelid = as.integer(), sex = as.character(),age = as.integer(),  fisher_pop = as.integer(), hr_size = as.integer(), hr_size_lb = as.integer(), d2_Score = as.numeric )
          }
            
          
        }
      }
      sim$dispersers<-sim$dispersers[, id := 0]
      sim$dispersers<-sim$dispersers[, `:=`(id = NULL)]
      sim$dispersers$size_achieved<-NA
    }
 
  }else{
    sim$dispersers<-sim$dispersers[, id := 0]
    sim$dispersers<-sim$dispersers[, `:=`(id = NULL)]
    sim$dispersers$size_achieved<-NA
    message("disperseFisher: No Dispersers!")
  }
  
  message (paste0("disperseFisher: # left as dispersers: ", nrow(sim$dispersers)))
  return(invisible(sim))
}

checkHabitatNeeds <- function(sim){
  message (paste0("checkHabitatNeeds: checking ", nrow(sim$agents), " territories"))
  # Check if Fisher Habitat Needs are Being Met if not, the animal gets a null d2 score and will disperse
  #---- 1. Absolute amount of habitat. Check to see if minimum habitat target was met (prop habitat = 0.15); if not, remove the animal 
  check_habitat <- merge(sim$territories, sim$table.hab.spread[, c ("pixelid", "denning", "rust", "cavity", "cwd", "movement", "open")],
                         by.x = "pixelid", by.y = "pixelid", all.x =TRUE)
  #---- 3. Habitat Quality Criteria
  tab.perc <- habitatQual (check_habitat, sim$agents, sim$fisher_d2_cov)
  #n_hab_lost<- nrow(remove_fisher)
  #update d2_score in agents table
  tab.perc<-tab.perc[, d2_score:=d2]
  sim$agents <- sim$agents[,`:=`(d2_score = NULL)] #remove variables not found in sim$agents
  
  sim$agents<-merge(sim$agents, tab.perc[!is.na(d2_score),c("initialPixels", "d2_score")], by.x = "initialPixels", by.y = "initialPixels", all.x =T)
  
  sim$spread.rast <- spreadRast (sim$pix.rast, sim$table.hab.spread, sim$territories)
  #message (paste0("checkHabitatNeeds: ", n_hab_lost, " lost territories."))
  return(invisible(sim))
}


reproduceFisher<-function(sim){
  # Step 4: Reproduce
  reproFishers <- sim$agents [sex == "F" & age >= P (sim, "reproductive_age", "FLEX"), ] # females of reproductive age in a territory
  message (paste0("reproduceFisher: # reproducing: ", nrow(reproFishers)))
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
    reproFishers <- litterSize (sim$mahal_metric_table, sim$repro_rate_table, reproFishers)
    reproFishers <- reproFishers [kits >= 1, ] # remove females with no kits
    
    if (nrow (reproFishers) > 0) {
      ## add the kits to the agents table
      # create new agents
      new.agents <- data.frame (lapply (reproFishers, rep, reproFishers$kits)) # repeat the rows in the reproducing fishers table by the number of kits 
      # assign whether fisher is a male or female; remove males
      new.agents$kits <- rbinom (size = 1, n = nrow (new.agents), prob = P (sim, "sex_ratio", "FLEX")) # prob of being a female
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
      sim$max.id<-max(sim$agents$individual_id, sim$dispersers$individual_id, na.rm=T)
      new.agents[, individual_id := sim$max.id + .I] #add a unique ID
      
      # update the individual id -- this gets done once they disperse
    } else {
      message ("reproduceFisher: No reproducing fishers!")
    }
    
    if (exists ("new.agents")) {
      if (nrow (new.agents) > 0) {
        sim$dispersers <- rbind (sim$dispersers,
                             new.agents, fill = TRUE) # save the new agents
        message(paste0("reproduceFisher: # kits added: ",nrow (new.agents) ))
      }
    }
    
    # if there are kits, move first one pixel over from mother and each sibling one pixel over
    while (any (duplicated (sim$dispersers$pixelid))) { # loop in case there is > 2 kits
      sim$dispersers$pixelid <-  replace (sim$dispersers$pixelid, 
                                      duplicated (sim$dispersers$pixelid), 
                                      sim$dispersers$pixelid [duplicated(sim$dispersers$pixelid)] + 1)
    }
    
    # NOTE: the above two function could move a fisher on the eastern edge of the area of interest to the western edge
    # functionally this would be like a kit dispersing 'out' of the area, offset by a kit dispersing 'in' to the area elsewhere
    
    
  } else {
    message ("reproduceFisher: No reproducing fishers!")
  }
  # no update to the territories table because juveniles have not yet established a territory
  #message ("Kits added to population.")
  return(invisible(sim))
}

survivalFisher<-function(sim){
  #survival -- establish a territory: [1, 2], [3,5], [5,8], [9+] -- best, dispersers ---[1, 2],[3,5], [5,8], [9+]
  # Step 5. Survive and Age 1 Year
  n_adults<-nrow(sim$agents[age > 0 ,])
  n_dispersers<-nrow(sim$dispersers)
  #browser()
  
  if(n_dispersers > 0 ){
    sim$dispersers[,  cohort:= fcase(age <= 1, "Juvenile", age > 1 & age <= 5, "Adult", age > 5 & age <= 8, "Senior", age >= 9, "Old")]
    sim$dispersers<-merge(sim$dispersers, sim$survival_rate_table[type == "Disperser", ], by.x = c("fisher_pop", "cohort"), by.y = c("fisher_pop", "cohort") , all.x =T)
    sim$dispersers[,  survive := rbinom (n = .N, size = 1, prob = rtruncnorm (1, a = 0, b = 1, mean = Mean, sd = SD))]
    
    sim$dispersers<-sim$dispersers [survive == 1, ]# remove the 'dead' individuals
    #Remove columns: Mean, SD, cohort, type, survive
    sim$dispersers[,`:=`(Mean = NULL, SD = NULL, cohort = NULL, type = NULL, survive = NULL)]
  }
  if(n_adults > 0){
    #Merge in the corresponding survival_rate_table to the dispersers and the agents
    sim$agents[,  cohort:= fcase(age <= 1, "Juvenile", age >1 & age <= 5, "Adult", age > 5 & age <= 8, "Senior", age >= 9, "Old")]
    sim$agents<-merge(sim$agents, sim$survival_rate_table[type == "Established", ], by.x = c("fisher_pop", "cohort"), by.y = c("fisher_pop", "cohort") , all.x =T)
    #TO DO: ADJUST SURVIVAL of Established Fisher BELOW
    sim$agents<-merge(sim$agents, sim$mahal_metric_table[,c("FHE_zone_num", "Max")], by.x = "fisher_pop", by.y = "FHE_zone_num", all.x=T)
    sim$agents[d2_score > Max, Mean := Mean*(pchisq(d2_score, df = 4, lower.tail = F)/pchisq(Max, df = 4, lower.tail = F))]
    sim$agents[,  survive := rbinom (n = .N, size = 1, prob = rtruncnorm (1, a = 0, b = 1, mean = Mean, sd = SD))]
    sim$agents <- sim$agents [ survive == 1,]# remove the 'dead' individuals
    sim$territories <- sim$territories [initialPixels %in% sim$agents$initialPixels,] # remove territories
    #Remove columns: Mean, SD, cohort, type, survive
    sim$agents[, `:=`(Mean = NULL,  SD = NULL, cohort = NULL, type = NULL, survive = NULL, Max =NULL)]
  }

  message(paste0("survivalFisher: Established Females: " , n_adults, " and ", nrow(sim$agents[age > 0,]), " survived" ))
  #message(paste0("survivalFisher: Juveniles: " , n_juv, " and ", nrow(sim$agents[age <= 1,]), " survived" ))
  message(paste0("survivalFisher: Dispersers: " , n_dispersers, " and ", nrow(sim$dispersers), " survived" ))
  
  return(invisible(sim))
}

ageFisher<-function(sim){
  message("ageFisher: Fisher age one year")
  # this is where we age the fisher; survivors age 1 year
  sim$agents <- sim$agents[, age := age + 1] 
  sim$dispersers<- sim$dispersers[, age := age + 1] 
  
  #message ("Fishers survived and aged one year.")
  return(invisible(sim))
}

recordABMReport<-function(sim, i){
  new.agents.save <- data.table (n_f_adult = as.numeric (nrow (sim$agents [sex == "F" & age > 1, ])), 
                                 n_f_juv = as.numeric (nrow (sim$agents [sex == "F" & age <= 1 & age > 0, ])),
                                 n_f_disp = as.numeric (nrow (sim$dispersers [sex == "F" & age > 0, ])),
                                 mean_age_f = as.numeric (mean (c (sim$agents [sex == "F", age]))), 
                                 sd_age_f = as.numeric (sd (c (sim$agents [sex == "F", age]))), 
                                 timeperiod = max(0, as.integer ( time(sim) * P (sim, "timeInterval", "FLEX") - ( P (sim, "timeInterval", "FLEX") - i))), 
                                 scenario = as.character (sim$scenario$name))
  sim$fisherABMReport <- rbindlist (list (sim$fisherABMReport, new.agents.save), use.names = TRUE)
  #terra::writeRaster(sim$ras.territories, paste0(SpaDES.core::outputPath(sim),"/hr_",time(sim) * P (sim, "timeInterval", "FLEX") + i, ".tif"), overwrite = T)
  names(sim$ras.territories) <- paste0("hr_", max(0, as.integer ( time(sim) * P (sim, "timeInterval", "FLEX") - ( P (sim, "timeInterval", "FLEX") - i))))
  if(is.null(sim$ras.territories.stack)){
    sim$ras.territories.stack <- sim$ras.territories
    sim$ras.territories.freq <- sim$ras.territories
    sim$ras.territories.freq[sim$ras.territories.freq[] > 0]<-1
  }else{
    sim$ras.territories.stack <- rast(list(sim$ras.territories.stack,sim$ras.territories))
    temp.ras.territories.freq<-sim$ras.territories
    temp.ras.territories.freq[temp.ras.territories.freq[] > 0]<-1
    sim$ras.territories.freq <- sim$ras.territories.freq + temp.ras.territories.freq 
  }
  
  
  return(invisible(sim))
}

saveFisherReports<-function(sim){
  write.csv (x = sim$fisherABMReport,
             file = paste0 (outputPath (sim), "/fisher_agents.csv"))
  terra::writeRaster (x = sim$ras.territories.stack,
                       filename = paste0 (outputPath (sim), "/", sim$scenario$name, "_final_fisher_territories.tif"),
                       overwrite = TRUE)
  terra::writeRaster (x = sim$ras.territories.freq,
                      filename = paste0 (outputPath (sim), "/", sim$scenario$name, "_freq_fisher_territories.tif"),
                      overwrite = TRUE)
  return(invisible(sim))
}

plot_territories<- function(sim) {
  sim$ras.territories[] <- 0
  sim$ras.territories[sim$territories$pixelid]<-sim$territories$initialPixels
  terra::plot(sim$ras.territories)
  return(invisible(sim))
}

updateHabitat <- function (sim) {
  message ("updateHabitat: Update fisher habitat data...")
  # 1. update the habitat data in the territories
  # subset data for the time interval
  cols <- c ("pixelid", "ras_fisher_pop",  
             paste0 ("ras_fisher_denning_", (time(sim) * P (sim, "timeInterval", "FLEX"))), 
             paste0 ("ras_fisher_rust_", (time(sim) * P (sim, "timeInterval", "FLEX"))), 
             paste0 ("ras_fisher_cavity_", (time(sim) * P (sim, "timeInterval", "FLEX"))), 
             paste0 ("ras_fisher_cwd_", (time(sim) * P (sim, "timeInterval", "FLEX"))), 
             paste0 ("ras_fisher_movement_", (time(sim) * P (sim, "timeInterval", "FLEX"))),
             paste0 ("ras_fisher_open_", (time(sim) * P (sim, "timeInterval", "FLEX"))))
  raster.stack.update <- terra::subset (sim$raster.stack, cols)
  
  # convert data to table
  table.hab.update <- na.omit (as.data.table (raster.stack.update []))
  sim$table.hab.spread <- table.hab.update [ras_fisher_pop > 0, ]
  names (sim$table.hab.spread) <- c ("pixelid", "fisher_pop", "denning", "rust", "cavity", "cwd", "movement", "open")
  
  # B. Update the spread probability raster
  sim$spread.rast <- spreadRast (sim$pix.rast, sim$table.hab.spread, sim$territories)
  message ("done.")
  
  return (invisible (sim))
}


litterSize <- function (mahalTable, reproTable, reproFishers){
  
  reproFishers<-merge(reproFishers, mahalTable, by.x = "fisher_pop", by.y = "FHE_zone_num")
  reproFishers<-merge(reproFishers, reproTable[Param == 'LS', ], by.x = "fisher_pop", by.y = "Fpop")
  reproFishers<-reproFishers[d2_score <= Mean.x, lambda:=Mean.y][d2_score > Mean.x & d2_score < (Mean.x + sqrt(Mean.x)), lambda:=Mean.y*0.66][d2_score > (Mean.x + sqrt(Mean.x)) & d2_score <= (Mean.x + 2*sqrt(Mean.x)), lambda:=Mean.y*0.05][d2_score > (Mean.x + 2*sqrt(Mean.x)), lambda:=0]
  suppressWarnings(reproFishers[!is.na(lambda), kits:=as.integer (rpois (n = 1, lambda = lambda)), by= individual_id ])
 
  reproFishers<-reproFishers[, ':='(Mean.x = NULL, Mean.y =NULL, SD.x =NULL, SD.y =NULL, Max= NULL, Param = NULL, lambda=NULL, FHE_zone =NULL)]
  return (reproFishers)
}

habitatQual <- function (inputTable, agentsTable, d2Table) {
  tab.perc <- Reduce (function (...) merge (..., all = TRUE, by = "initialPixels"), 
                      list (inputTable [, .(den_perc = sum (denning, na.rm = T)) , by = initialPixels ], 
                            inputTable [, .(rust_perc = sum (rust, na.rm = T)) , by = initialPixels ], 
                            inputTable [, .(cav_perc = sum (cavity, na.rm = T)) , by = initialPixels ], 
                            inputTable [, .(move_perc = sum (movement, na.rm = T)) , by = initialPixels ], 
                            inputTable [, .(cwd_perc = sum (cwd, na.rm = T)) , by = initialPixels ],
                            inputTable [, .(open_perc = sum (open, na.rm =T)) , by = initialPixels])
  )
 
  tab.perc <- merge (tab.perc, 
                     agentsTable [, c ("initialPixels", "individual_id", "fisher_pop", "size_achieved")], #individual_id was in this list before
                     by.x = "initialPixels",by.y = "initialPixels", all.x = T)
  #convert raw areas of habitat to percentage of the territory
  tab.perc[ ,den_perc:=(den_perc/size_achieved)*100][ ,open_perc:=(open_perc/size_achieved)*100][ ,cwd_perc:=(cwd_perc/size_achieved)*100][ ,move_perc:=(move_perc/size_achieved)*100][ ,cav_perc:=(cav_perc/size_achieved)*100][ ,rust_perc:=(rust_perc/size_achieved)*100]
  
  # log transform the data
  tab.perc [fisher_pop == 2 & den_perc >= 0, den_perc := log (den_perc + 1)][fisher_pop == 2 & cav_perc >= 0, cavity := log (cav_perc + 1)] # sbs-wet
  tab.perc [fisher_pop == 3 & den_perc >= 0, den_perc := log (den_perc + 1)]# sbs-dry
  tab.perc [fisher_pop == 4 & rust_perc >= 0, rust_perc := log (rust_perc + 1)] # dry
  
  # truncate at the center 
  # 1 = boreal
  # 2 = sbs-wet
  # 3 = sbs-dry
  # 4 = dry
  
  tab.perc [fisher_pop == 1 & den_perc > 24, den_perc := 24][fisher_pop == 1 & rust_perc > 2.2, rust_perc := 2.2][fisher_pop == 1 & cwd_perc > 17.4, cwd_perc := 17.4][fisher_pop == 1 & move_perc > 56.2, move_perc := 56.2][fisher_pop == 1 & open_perc < 31.2, open_perc := 31.2]
  tab.perc [fisher_pop == 2 & den_perc > 1.57, den_perc := 1.57][fisher_pop == 2 & rust_perc > 36.2, rust_perc := 36.2][fisher_pop == 2 & cav_perc > 0.685, cav_perc := 0.685][fisher_pop == 2 & cwd_perc > 30.38, cwd_perc := 30.38][fisher_pop == 2 & move_perc > 61.5, move_perc := 61.5][fisher_pop == 2 & open_perc < 32.7, open_perc := 32.7]
  tab.perc [fisher_pop == 3 & den_perc > 1.16, den_perc := 1.16][fisher_pop == 3 & rust_perc > 19.1, rust_perc := 19.1][fisher_pop == 3 & cav_perc > 0.45, cav_perc := 0.45][fisher_pop == 3 & cwd_perc > 12.7, cwd_perc := 12.7][fisher_pop == 3 & move_perc > 51.3, move_perc := 51.3][fisher_pop == 3 & open_perc < 37.3, open_perc := 37.3]
  tab.perc [fisher_pop == 4 & den_perc > 2.3, den_perc := 2.3][fisher_pop == 4 & rust_perc > 1.6, rust_perc := 1.6][fisher_pop == 4 & cwd_perc > 10.8, cwd_perc := 10.8][fisher_pop == 4 & move_perc > 58.1, move_perc := 58.1][fisher_pop == 4 & open_perc < 15.58, open_perc := 15.58]
  
  tab.perc [fisher_pop == 1, d2 := mahalanobis (tab.perc [fisher_pop == 1, c ("den_perc", "rust_perc", "cwd_perc", "move_perc", "open_perc")], c(23.98, 2.24, 17.4, 56.2, 31.2), cov = d2Table[[1]])]
  tab.perc [fisher_pop == 2, d2 := mahalanobis (tab.perc [fisher_pop == 2, c ("den_perc", "rust_perc", "cav_perc", "cwd_perc", "move_perc", "open_perc")], c(1.57, 36.2, 0.68, 30.38, 61.5, 32.72), cov = d2Table[[2]])]
  tab.perc [fisher_pop == 3, d2 := mahalanobis (tab.perc [fisher_pop == 3, c ("den_perc", "rust_perc", "cav_perc", "cwd_perc", "move_perc", "open_perc")], c(1.16, 19.1, 0.4549, 12.76, 51.25, 37.27), cov = d2Table[[3]])]
  tab.perc [fisher_pop == 4, d2 := mahalanobis (tab.perc [fisher_pop == 4, c ("den_perc", "rust_perc", "cwd_perc", "move_perc", "open_perc")], c(2.31, 1.63, 10.8, 58.1, 15.58), cov = d2Table[[4]])]
  
  return (tab.perc)
}

mcp_spread<-function(spread_ras, spread_out_table){ #Turn the spreading raster contagion process into a vectorized polygon needed for statistical consistency with d2 calculation 
  xy<-data.table(cbind(spread_out_table, terra::xyFromCell(spread_ras, spread_out_table$pixels)))
  border_pixels<-xy[, keep_right:=max(x), by =c("y", "initialPixels") ][, keep_left:=min(x), by = c("y", "initialPixels")][, keep_above:= min(y), by = c("x", "initialPixels")][, keep_below:= max(y), by = c("x", "initialPixels")] [ keep_right == x | keep_left ==x | keep_above ==y | keep_below ==y,]
  border_pts <- sf::st_as_sf(border_pixels, coords = c(4:5), agr ="initialPixels")
  border_pts<-border_pts %>%
    group_by(initialPixels) %>% 
    summarize(geometry = st_union(geometry))
  border.poly<-st_convex_hull(border_pts)
  border.poly$ID <- 1:nrow(border.poly) # key for linking to inititalPixels
  ip_link<-data.table(st_drop_geometry(border.poly))[,c("ID", "initialPixels")]
  
  
  spread_ras[]<-0
  spread_ras[]<-1:(nrow(spread_ras)*ncol(spread_ras))
  ras.mcp<-data.table(terra::extract(spread_ras, border.poly))[pixelid>0,]
  
  #Lets take the overestimate of the convexhull and remove any pixels outside perimeter
  #ras.mcp<-terra::rasterize( border.poly, spread_ras, field = "initialPixels")
  #dt.mcp<-data.table(initialPixels= ras.mcp[])[,pixelid := seq_len(.N)][!is.na(initialPixels),]
  #get the x and y of each pixel within each territory
  #dt.mcp<-data.table(cbind(dt.mcp, raster::xyFromCell(ras.mcp, dt.mcp$pixelid)))
  #setnames(dt.mcp, c("x", "y"), c("X", "Y")) #rename so its not the same as other layer
  
  dt.mcp<-data.table(cbind(ras.mcp, terra::xyFromCell(spread_ras, ras.mcp$pixelid)))
  setnames(dt.mcp, c("x", "y"), c("X", "Y"))
  dt.mcp<-data.table(merge(dt.mcp, ip_link, by = "ID"))[initialPixels >0 & pixelid >0,]
  
  border_pixels2<-merge(dt.mcp, border_pixels[!is.na(keep_left), c("y", "initialPixels", "keep_left", "keep_right")], 
               by.x = c("Y", "initialPixels"), by.y = c( "y","initialPixels"), all.x=T, allow.cartesian=TRUE)
  border_pixels3<-border_pixels2[X>=keep_left & X<=keep_right,]
  
  border_pixels4<-merge(border_pixels3, border_pixels[!is.na(keep_below), c("x", "initialPixels", "keep_above", "keep_below")],  by.x = c("X", "initialPixels"), by.y = c( "x","initialPixels"), all.x=T, allow.cartesian=TRUE)
  border_pixels5<-border_pixels4[Y>=keep_above & Y<=keep_below,]
  return(unique(border_pixels5))
}

spreadRast <- function (rasterInput, habitatInput, mask) {
  #Net out current maintained territories so that NEW fisher can't spread into established territories
  out.rast <- rasterInput
  out.rast [] <- 0
  # currently uses all denning, rust, cavity, cwd, movement  and 'closed' (not open) habitat as 
  # spreadProb = 1, and non-habitat as spreadProb = 0.10; allows some spread to sub-optimal habitat
  habitatInput [denning == 1 | rust == 1 | cavity == 1 | cwd == 1 | movement == 1 | open == 0, spreadprob := format (round (1.00, 2), nsmall = 2)] 
  habitatInput [is.na (spreadprob), spreadprob := format (round (0.18, 2), 2)] # I tested different numbers
  # 18% resulted in the mean proportion of home ranges consisting of denning, resting or movement habitat as 55%; 19 was 49%; 17 was 59%; 20 was 47%; 15 was 66%
  # Caution: this parameter may be area-specific and may need to be and need to be 'tuned' for each AOI
  habitatInput [open == 1, spreadprob := format (round (0.09, 2), 2)]
  out.rast [habitatInput$pixelid] <- as.numeric(habitatInput$spreadprob)
  
  if(!is.null(mask)){
    out.rast [mask$pixelid] <- 0
  }

  return (out.rast)	
}

getClosestWellSpreadDenningSites<-function(juv.idx,juv.dist){
  juv.dist[which(juv.idx[] == 0, arr.ind=TRUE)] <- Inf #set all zeros to Inf to deal with min() function returning a zero instead of min distance
  juv.idx[which(juv.idx[] == 0, arr.ind=TRUE)] <- Inf
  #Select closest juvenile -- in the case of ties - have same initalPixel - pick one--it doesn't matter cause both the same)
  temp<-data.table(id = 1:nrow(juv.idx), ds.indx = 0)
  j =1
  repeat{
    if(!(juv.dist[which(juv.dist[,j]==min(juv.dist[,j]), arr.ind=TRUE), j][[1]] == Inf)){ #if the minimum distance in col j isn't Inf
      element <- which(juv.dist[,j]==min(juv.dist[,j]), arr.ind=TRUE) # the row index (i.e., the juv fisher) that has the smallest distance
      value <- juv.idx[which(juv.dist[,j]==min(juv.dist[,j]), arr.ind=TRUE),j] # the index that has the smallest distance
      if(!(value[[1]] == Inf)){ #check to make sure the index/fisher isn't Inf -- should always be since previous if
        temp <- temp[id == element[[1]], ds.indx := value[[1]] ] #assign the fisher (row) an index (location)
        juv.dist[which(juv.idx[] == value[[1]], arr.ind=TRUE)] <- Inf # this site is done --assign Inf so others can't use it
        juv.idx[which(juv.idx[] == value[[1]], arr.ind=TRUE)] <- Inf # this site is done --assign Inf so others can't use it
        juv.dist[element, ] <- Inf #make the whole row Inf
        juv.idx[element, ] <- Inf #make the whole row Inf
      }
    }
    if(min(temp$ds.indx) > 0 | j == 11 | min(juv.dist) == Inf){ # all of the fisher got site or there are no sites left out of the 10
      break # all fisher found a site or all neighbors have been exhausted
    }  
    if(min(juv.dist[,j]) == Inf){ # their are no more denning sites closest (the jth Nearest Neighbour) go to the next nearest neighbour
      j = j + 1
    }
  }
  
  return(temp)  
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
    sim$survival_rate_table <- rbindlist(list(
      data.table (fisher_pop = c (1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4),
                  type = "Established",
                  cohort = c ("Adult", "Juvenile", "Senior", "Old", "Adult", "Juvenile", "Senior", "Old", "Adult", "Juvenile", "Senior", "Old", "Adult", "Juvenile", "Senior", "Old"),
                  Mean = c (0.8, 0.6, 0.8, 0.2,  0.8, 0.6, 0.8, 0.2, 0.8, 0.6, 0.8, 0.2, 0.8, 0.6, 0.8,0.2),
                  SD = c (0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1, 0.2,0.1,0.1,0.1,0.1,0.1,0.1)), 
      data.table (fisher_pop = c (1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4),
                  type = "Disperser",
                  cohort = c ("Adult", "Juvenile", "Senior", "Old", "Adult", "Juvenile", "Senior", "Old", "Adult", "Juvenile", "Senior", "Old", "Adult", "Juvenile", "Senior", "Old"),
                  Mean = c (0.75, 0.6, 0.75, 0.2,  0.75, 0.6, 0.75, 0.2, 0.75, 0.6, 0.75, 0.2, 0.75, 0.6, 0.75, 0.2),
                  SD = c (0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1, 0.1,0.1,0.1,0.1,0.1,0.1,0.1))
                                ))
   
  }
  if(!suppliedElsewhere("repro_rate_table", sim)){
    sim$repro_rate_table <- data.table (Fpop = c(1,1,2,2,3,3,4,4),
                                      Param = c("DR", "LS","DR", "LS","DR", "LS","DR", "LS"), # updating to be more realistic
                                      Mean = c(0.82,2.6,0.54,1.7,0.54,1.7,0.54,1.7), # from Lofroth et al 2022
                                      SD = c(0.3,0.7,0.4,0.7,0.4,0.7,0.4,0.7))
  }
  if(!suppliedElsewhere("female_hr_table", sim)){
    sim$female_hr_table <- data.table (fisher_pop = c (1:4), 
                                     # hr_mean = c (3000, 3000, 4500, 3000), 
                                     hr_mean = c (2880, 2920, 4340, 4530), # actual mean
                                     # hr_sd = c (500, 500, 500, 500),
                                     hr_sd = c (482, 460, 1120, 571)) # actual SE
  }
  if(!suppliedElsewhere("mahal_metric_table", sim)){
  sim$mahal_metric_table <- data.table (FHE_zone = c ("Boreal", "Sub-Boreal moist", "Sub-Boreal dry", "Dry Forest"),
                                        FHE_zone_num = c (1:4),
                                        Mean = c (3.8, 4.4, 4.4, 3.6),
                                        SD = c (2.71, 1.09, 2.33, 1.62),
                                        Max = c (9.88, 6.01, 6.63, 7.5))
  }
  if(!suppliedElsewhere("scenario", sim)){
    sim$scenario <- data.table(name="test_final", description = "test")
  }
  return(invisible(sim))
}
