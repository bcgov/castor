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
    defineParameter("repro_rate_table", "function", NA, NA, NA,
                    paste0("Table of fisher reproductive rates (i.e., denning rate = a combination of pregnancy rate and birth rate; and litter size = number of kits) by population, taken from Lofroth et al 2022 JWM vital rates manuscript",
                           "Table with the following headers:",
                           "Fpop: the two populations in BC: Boreal, Coumbian",
                           "Param: the reproductive parameter: DR (denning rate), LS (litter size)",
                           "Mean: mean reproductive rate per parameter and population",
                           "SD: standard deviation of the mean reproductive rate per parameter and population")),
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
      # do stuff for this event
      
      # e.g., call your custom functions/methods here
      # you can define your own methods below this `doEvent` function
      
      # schedule future event(s)
      
      # e.g.,
      # sim <- scheduleEvent(sim, time(sim) + increment, "fisherabmCLUS", "templateEvent")
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
  pix.for.rast <- data.table (dbGetQuery(sim$clusdb, "SELECT pixelid FROM pixels WHERE compartid IS NOT NULL;"))
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
  table.hab$fisher.pop <- fasterize::fasterize (sf = fisher.pop, raster = sim$pix.rast, field = "pop")[]
  #---VAT for populations: 1 = SBS-wet; 2 = SBS-dry; 3 = Dry Forest; 4 = Boreal_A; 5 = Boreal_B
  
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
  
  sim$table.hab <- table.hab [, .(pixelid, fisher.pop, den_p, denning, rus_p, rust, cav_p, cavity, 
                                  cwd_p, cwd, mov_p, movement)]
  # sim$table.hab <- table.hab [denning != "" | rust != "" | cavity != "" | cwd != "" | movement != "", ]
  # remove the rows with at least one NA value - don't do this....
  rm (pix.for.rast, aoi, table.hab)
  gc ()
  
  message ("Create agents table and assign values...")
  ids <- seq (from = 1, to = P(sim, "n_females", "fisherabmCLUS"), by = 1) # sequence of individual id's from 1 to n_females
  
  
  agents <- data.table (individual_id = ids, 
                        sex = "F", 
                        age = sample (1:P(sim, "max_age", "fisherabmCLUS"), length (ids), replace = T), # randomly draw ages between 1 and the max age, 
                        pixelid = numeric (), 
                        hr_size = numeric (), 
                        d2_score = numeric ())
  
  # assign a random starting location that is a denning pixel in population range
  agents$pixelid <- sample (table.hab [denning == 1 & !is.na (fisher.pop), pixelid], length (ids), replace = T)

  # assign an HR size based on population
    # calling a table from postgres db; is there a better, alternative way to do this?
  
  # conn<-DBI::dbConnect(dbDriver("PostgreSQL"), 
  #                      host=key_get("dbhost", keyring="postgreSQL"), 
  #                      dbname = 'clus', port='5432', 
  #                      user=key_get("dbuser", keyring="postgreSQL"), 
  #                      password=key_get("dbpass", keyring="postgreSQL"))
  # hr.tab <- data.table (dbGetQuery(conn, "SELECT * FROM public.fisher_home_range;")) # this table tbd 
  
  # using a 'dummy' table for now
  hr.tab <- data.table (fisher.pop = c (1:5), # fisher pops: 1 = SBS-wet; 2 = SBS-dry; 3 = Dry Forest; 4 = Boreal_A; 5 = Boreal_B
                        hr_mean = c (3000, 3000, 3000, 4000, 4000),
                        hr_sd = c (500, 500, 500, 500, 500))
  
  
  
  
  
  for (i in agents$pixelid) { 
    if (agents [pixelid == (sim$table.hab [pixelid = i & fisher.pop == 1, pixelid]), ]) {
      
    } else if () {
      
    }
    
  }
    
  
  search.temp <- search.temp [is.na (individual_id) | individual_id == (agents [pixelid == i, individual_id]), ]
  
  
  
  
  agents$hr_size <-
  
  rnorm (P(sim, "n_females", "fisherabmCLUS"), P(sim, "female_hr_size_mean", "fisherabmCLUS"), P(sim, "female_hr_size_sd", "fisherabmCLUS")), 
  
  
  
  dbDisconnect(conn)
  
  
  
  

  message ("Create territories table ...")
  territories <- data.table (individual_id = agents$individual_id, 
                             pixelid = agents$pixelid)

  for (i in agents$pixelid) { # for each individual
    search.temp <- SpaDES.tools::spread2 (sim$pix.rast, # calculate pixels in its search radius
                                          start = i, 
                                          spreadProb = 1, 
                                          maxSize = ((P(sim, "female_search_radius", "fisherabmCLUS")^2 * pi) * 100), # convert radius to area in ha
                                          allowOverlap = F,
                                          asRaster = F,
                                          circle = T)
    # calc distance between each pixel and the denning site
    # not sure if we need this; current version doesn't use it; grabs all habitat in the search radius
    search.temp <- cbind (search.temp, xyFromCell (sim$pix.rast, search.temp$pixels))
    search.temp [!(pixels %in% agents$pixelid), dist := RANN::nn2 (search.temp [pixels %in% agents$pixelid, c("x","y")], search.temp [!(pixels %in% agents$pixelid), c("x","y")], k = 1)$nn.dists]
    search.temp [is.na (dist), dist := 0]
    
    # remove pixels if already occupied
    search.temp <- merge (search.temp, territories, 
                          by.x = "pixels", by.y = "pixelid", all.x = T)
    search.temp <- search.temp [is.na (individual_id) | individual_id == (agents [pixelid == i, individual_id]), ]
    
    # assign individual ID
    search.temp$individual_id <- agents [pixelid == i, individual_id]
    
    # assign habitat 
    search.hab.pix <- merge (search.temp, sim$table.hab, by.x = "pixels", 
                             by.y = "pixelid") 
    
    # if proportion of habitat types are greater than the minimum target
    if (P(sim, "rest_target", "fisherabmCLUS") <= length (which (search.hab.pix$rust == 1)) + length (which (search.hab.pix$cwd == 1)) & P(sim, "move_target", "fisherabmCLUS") <= length (which (search.hab.pix$movement == 1)) & P(sim, "den_target", "fisherabmCLUS") <= length (which (search.hab.pix$denning == 1))) {
      # assign the pixels to territories table
      territories <- rbind (territories, search.hab.pix [rust == 1 | cwd ==1, .(pixelid = pixels, individual_id)]) 
    } else {
      # delete the individual from the agents and territories table
      territories <- territories [individual_id != (agents [pixelid == i, individual_id]), ] 
      agents <- agents [pixelid != i]
    } 
  
    
    # then meet some habitat configuration criteria, e.g., min patch size,
    # min distance between patches; Jo to give this some more thought
    
    
    if(nrow(dbGetQuery(sim$clusdb, "SELECT name FROM sqlite_schema WHERE type ='table' AND name = 'territories';")) == 0){
      # if the table exists, write it to the db
      DBI::dbWriteTable (sim$clusdb, "territories", territories, append = FALSE, 
                         row.names = FALSE, overwite = FALSE)  
    } else {
      # if the table exists, append it to the table in the db
      DBI::dbWriteTable (sim$clusdb, "territories", territories, append = TRUE, 
                         row.names = FALSE, overwite = FALSE)  
    }
  }
  message ("Territories created.")
  
  
  # calculate d2 score.....
  
  
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
  
  
  
  # ! ----- STOP EDITING ----- ! #

  return(invisible(sim))
}

###--- SURVIVE
# create a function that runs each year to determine the probability of a fisher surviving to the next year
# also need to kill off any fishers that are over the max age for females (default = 9) or having been dispersing for 2 years

survive_FEMALE <- function(sim){
  
  # Fpop="C",
  # female_max_age=9)

  # using 'dummy' tables (only necessary while working through function)
  territories <- data.table(individual_id = rep(seq_len(5),each=5),
                            pixelid = 1:25)
  
  agents <- data.table(individual_id = 1:5,
                       sex = "F",
                       age = sample(2:8, 5, replace=T),
                       pixelid = c(1,6,11,16,21),
                       hr_size = rnorm(5, mean=28, sd=14),
                       d2_score = rnorm(5, mean=4, sd=1))
  
  # pull in survival table (only necessary while working through function)
  survival_rate_table <- read.csv("R/SpaDES-modules/fisherabmCLUS/data/surv_rate_table_08Aug2022.csv")
  
  # delete the individuals older than max female age from the agents and territories table
  agents <- agents %>% filter(age<female_max_age) # likely this needs to be written in "spades" P(sim) format
  territories <-territories %>% filter(individual_id %in% agents$individual_id)
  
  # have age 1 = juvenile, 2+ = adult (cannot die if 0)
  # use rbinom with lower = mean - SE, upper = mean + SE
  
  # create temp table of fishers that need to survive (i.e., fishers < 1 cannot die)
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
  territories <-territories %>% filter(individual_id %in% agents$individual_id)
  
  # allowing kits to survive even if mothers die as by 1 year kits able to live in territory without mom
  # need to still deal with juveniles who are dispersing
  # dispersing <- survFishers %>% filter(disperse=="D" & age>2) # "who" of dispersing fishers over 2
  
  # all remaining fishers will age 1 year
  agents$age <- agents$age +1
  agents
  
  return(invisible(sim))
}


###--- REPRODUCE
repro_FEMALE <- function(sim) {
  
  # Fpop="B",
  # female_max_age=9)
  
  # using 'dummy' tables (only necessary while working through function)
  territories <- data.table(individual_id = rep(seq_len(5),each=5),
                            pixelid = 1:25)
  
  agents <- data.table(individual_id = 1:5,
                       sex = "F",
                       age = sample(2:8, 5, replace=T),
                       pixelid = c(1,6,11,16,21),
                       hr_size = rnorm(5, mean=28, sd=14),
                       d2_score = rnorm(5, mean=4, sd=1))
  
  # pull in survival table (only necessary while working through function)
  repro_rate_table <- read.csv("R/SpaDES-modules/fisherabmCLUS/data/repro_rate_table_08Aug2022.csv")
  
  reproFishers <- agents %>% filter(age > 1) # female fishers capable of reproducing
  
  denCI <- repro_estimates %>% dplyr::filter(str_detect(Pop,Fpop)) %>% dplyr::filter(str_detect(Param,"CI")) %>% dplyr::select(dr)
  repro <- rbinom(n = length(whoAFFishers), size=1, prob=min(denCI):max(denCI)) # prob can be a range - use confidence intervals
  fishers <- NLset(turtles = fishers, agents = turtle(fishers, who=whoAFFishers), var = "repro", val = repro)
  
  # Random selection for which adult females reproduce, based on denning mean and SD (Central Interior)
  whoFishers <- as.data.frame(of(agents = fishers, var = c("who","repro"))) # "who" of the fishers before they reproduce
  reproWho <- whoFishers[whoFishers$repro==1,]$who # "who" of fishers which reproduce
  
  ltrM=repro_estimates[repro_estimates$Pop==Fpop & repro_estimates$Param=="mean",]$ls
  ltrSD=repro_estimates[repro_estimates$Pop==Fpop & repro_estimates$Param=="sd",]$ls
  
  # if there is at least one fisher reproducing
  # have those fishers have offspring, based on the mean and sd of empirical data
  if (length(reproWho) > 0) {
    fishers <- hatch(turtles = fishers, who = reproWho, n=round(rnorm(n=1, mean=ltrM, sd=ltrSD)/2),breed="juvenile") # litter size based on empirical data (divided by 2 for female only model)
    
    # assign all of the offsprig as dispersing, change repro and age values to reflect newborn kits rather than their moms
    allFishers <- of(agents=fishers, var="who")
    offspring <- allFishers[!(allFishers %in% whoFishers$who)]
    
    fishers <- NLset(turtles = fishers, agents = turtle(fishers, who=offspring), var = "disperse", val = "D")
    fishers <- NLset(turtles = fishers, agents = turtle(fishers, who=offspring), var = "age", val = 0) # just born so time step 0
    fishers <- NLset(turtles = fishers, agents = turtle(fishers, who=offspring), var = "repro", val = 0) # just born not yet reproductive
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
