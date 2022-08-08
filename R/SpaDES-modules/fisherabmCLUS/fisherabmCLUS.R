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
                    "A table of mean and standard deviation of female fisher home range (territory) sizes in different populations."),    
    defineParameter("female_max_age", "numeric", 15, 0, 20,
                    "The maximum possible age of a female fisher."), 
    defineParameter("female_search_radius", "numeric", 5, 0, 100,
                    "The maximum search radius, in km, that a female fisher could ‘search’ to establish a territory."), 
    defineParameter("den_target", "numeric", 0.1, 0, 1,
                    "The minimum proportion of a home range that is denning habitat."), 
    defineParameter("rest_target", "numeric", 0.2, 0, 1,
                    "The minimum proportion of a home range that is resting habitat."),   
    defineParameter("move_target", "numeric", 0.4, 0, 1,
                    "The minimum proportion of a home range that is movement habitat."), 
    defineParameter("survival_rate_table", "character", NA, NA, NA,
                    "Table of fisher survial rates by sex, age and population."),
    defineParameter("d2_reproduction_adj", "function", NA, NA, NA,
                    "Function relating habitat quality to reproductive rate."),
    defineParameter("repro_rate_table", "function", NA, NA, NA,
                    "A table of mean and standard deviation of rate at which a female gets pregnant and gives birth to young (i.e., a combination of pregnancy rate and birth rate), minimum age that a female fisher reaches sexual maturity, mean and standard deviation of litter size in different populations"),
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
  table.hab$fisher_pop <- fasterize::fasterize (sf = fisher.pop, raster = sim$pix.rast, field = "pop")[]
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
  
  sim$table.hab <- table.hab [, .(pixelid, fisher_pop, den_p, denning, rus_p, rust, cav_p, cavity, 
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
  agents$pixelid <- sample (table.hab [denning == 1 & !is.na (fisher_pop), pixelid], length (ids), replace = T)

  # assign the population ID
  agents <- merge (agents, table.hab [ , c("pixelid", "fisher_pop")], 
                              by = "pixelid", all.x = T)
  
  # assign an HR size based on population
    # calling a table from postgres db; is there a better way to do this?
  
  # conn<-DBI::dbConnect(dbDriver("PostgreSQL"), 
  #                      host=key_get("dbhost", keyring="postgreSQL"), 
  #                      dbname = 'clus', port='5432', 
  #                      user=key_get("dbuser", keyring="postgreSQL"), 
  #                      password=key_get("dbpass", keyring="postgreSQL"))
  # hr.tab <- data.table (dbGetQuery(conn, "SELECT * FROM public.fisher_home_range;")) # this table tbd 
  #   dbDisconnect(conn)

  # using a 'dummy' table for now
  hr.tab <- data.table (fisher_pop = c (1:5), # fisher pops: 1 = SBS-wet; 2 = SBS-dry; 3 = Dry Forest; 4 = Boreal_A; 5 = Boreal_B
                        hr_mean = c (3000, 2500, 3000, 4000, 4000),
                        hr_sd = c (500, 500, 500, 500, 500))
  
  agents [fisher_pop == 1, hr_size := rnorm (nrow (agents [fisher_pop == 1, ]), hr.tab [fisher_pop == 1, hr_mean], hr.tab [fisher_pop == 1, hr_sd])]
  agents [fisher_pop == 2, hr_size := rnorm (nrow (agents [fisher_pop == 2, ]), hr.tab [fisher_pop == 2, hr_mean], hr.tab [fisher_pop == 2, hr_sd])]
  agents [fisher_pop == 3, hr_size := rnorm (nrow (agents [fisher_pop == 3, ]), hr.tab [fisher_pop == 3, hr_mean], hr.tab [fisher_pop == 3, hr_sd])]
  agents [fisher_pop == 4, hr_size := rnorm (nrow (agents [fisher_pop == 4, ]), hr.tab [fisher_pop == 4, hr_mean], hr.tab [fisher_pop == 4, hr_sd])]
  agents [fisher_pop == 5, hr_size := rnorm (nrow (agents [fisher_pop == 5, ]), hr.tab [fisher_pop == 5, hr_mean], hr.tab [fisher_pop == 5, hr_sd])]
  
  sim$agents <- agents
  
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
    
    # if proportion of habitat types are greater than the minimum targets 
    # AND habitat pixels make up at least half of the territory
    if (P(sim, "rest_target", "fisherabmCLUS") <= (length (which (search.hab.pix$rust == 1)) + length (which (search.hab.pix$cwd == 1))) / agents [pixelid == i, hr_size] & P(sim, "move_target", "fisherabmCLUS") <= length (which (search.hab.pix$movement == 1)) / agents [pixelid == i, hr_size] & P(sim, "den_target", "fisherabmCLUS") <= length (which (search.hab.pix$denning == 1)) / agents [pixelid == i, hr_size] & 0.5 < (length (which (search.hab.pix$rust == 1)) + length (which (search.hab.pix$cwd == 1)) + length (which (search.hab.pix$movement == 1)) + length (which (search.hab.pix$denning == 1))) / agents [pixelid == i, hr_size]
    ) {
      # assign the pixels to territories table
      territories <- rbind (territories, search.hab.pix [rust == 1 | cwd == 1 | denning == 1 | movement == 1, .(pixelid = pixels, individual_id)]) 
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
    sim$territories <- territories
  }
  message ("Territories created.")
  
  
  #---Calculate D2 (Mahalanobis)
  message ("Calculate habitat quality.")
  
  # identify which fisher pop an animal belongs to
  terr.pop <- merge (territories, table.hab [, c ("pixelid", "fisher_pop")], 
                      by = "pixelid", all.x = T)
  # get the mean of pixels pop. values, rounded to get the majority; majority = pop membership
  terr.pop [, fisher_pop := .(mean (fisher_pop)), by = individual_id] 
  terr.pop$fisher_pop <- round (terr.pop$fisher_pop, digits = 0)
  terr.pop <- unique (terr.pop [, c ("individual_id", "fisher_pop")])
  agents <- merge (agents [, -c ("fisher_pop")], # assign new fisher_pop to agents table
                   terr.pop [, c ("individual_id", "fisher_pop")], 
                   by = "individual_id", all.x = T)
  
  # get % of habitat for mahalanobis
  tab.mahal <- merge (territories, 
                      table.hab [, c ("pixelid", "denning", "rust", "cavity", "movement")], 
                      by = "pixelid", all.x = T)
  # % of each habitat by territory
  tab.den.perc <- tab.mahal [, .((den.perc = (sum (denning, na.rm = T)) / .N) * 100), by = individual_id ]
  tab.rust.perc <- tab.mahal [, .((rust.perc = (sum (rust, na.rm = T)) / .N) * 100), by = individual_id ]
  tab.cavity.perc <- tab.mahal [, .((rust.perc = (sum (cavity, na.rm = T)) / .N) * 100), by = individual_id ]
  tab.move.perc <- tab.mahal [, .((rust.perc = (sum (movement, na.rm = T)) / .N) * 100), by = individual_id ]
  
  
  Reduce(merge,list(DT1,DT2,DT3,...))
  
  
  merge ()
  
  
  setnames (DT, "mpg_sq", "mpq_squared")
  
  
  tab.mahal [, .N, by = individual_id ]
  
  
  
  
  tab.mahal [, .(den.perc = (sum (denning, na.rm = T) / nrow (tab.mahal)) * 100), by = individual_id]
  


  

          
          
          
          
          
  

  
  
  

  #-----Add log transforms
  fisher.habitat.rs[is.na(fisher.habitat.rs)] <-0
  fisher.habitat.rs[ pop == 1 & denning >= 0, denning:=log(denning + 1)][ pop == 1 & cavity >= 0, cavity:=log(cavity + 1)]
  fisher.habitat.rs[ pop == 2 & denning >= 0, denning:=log(denning + 1)]
  fisher.habitat.rs[ pop >= 3 & rust >= 0, rust:=log(rust + 1)]
  #fisher.habitat.rs[is.na(fisher.habitat.rs)] <-0.0000000001
  
  #-----Truncate at the center plus one st dev
  stdev_pop1<-sqrt(diag(sim$fisher.d2.cov[[1]]))
  stdev_pop2<-sqrt(diag(sim$fisher.d2.cov[[2]]))
  stdev_pop3<-sqrt(diag(sim$fisher.d2.cov[[3]]))
  stdev_pop4<-sqrt(diag(sim$fisher.d2.cov[[4]]))
  
  fisher.habitat.rs[ pop == 1 & denning > 1.6 + stdev_pop1[1], denning := 1.6 + stdev_pop1[1]][ pop == 1 & rust > 36.2 + stdev_pop1[2], rust :=36.2 + stdev_pop1[2]][ pop == 1 & cavity > 0.7 + stdev_pop1[3], cavity :=0.7+ stdev_pop1[3]][ pop == 1 & cwd > 30.4+ stdev_pop1[4], cwd :=30.4+ stdev_pop1[4]][ pop == 1 & mov > 26.8+ stdev_pop1[5], mov :=26.8+ stdev_pop1[5]]
  fisher.habitat.rs[ pop == 2 & denning > 1.2 + stdev_pop2[1], denning := 1.2 + stdev_pop2[1]][ pop == 2 & rust > 19.1 + stdev_pop2[2], rust :=19.1 + stdev_pop2[2]][ pop == 2 & cavity > 0.5 + stdev_pop2[3], cavity :=0.5+ stdev_pop2[3]][ pop == 2 & cwd > 10.2+ stdev_pop2[4], cwd :=10.2+ stdev_pop2[4]][ pop == 2 & mov > 33.1+ stdev_pop2[5], mov :=33.1+ stdev_pop2[5]]
  fisher.habitat.rs[ pop %in% c(3,4) & denning > 2.3 + stdev_pop3[1], denning := 2.3 + stdev_pop3[1]][ pop %in% c(3,4) & rust > 1.6 +  stdev_pop3[2], rust :=1.6  + stdev_pop3[2]][ pop %in% c(3,4) & cwd > 10.8+ stdev_pop3[3], cwd :=10.8 + stdev_pop3[3]][ pop %in% c(3,4) & mov > 21.5+ stdev_pop3[4], mov :=21.5+ stdev_pop3[4]]
  fisher.habitat.rs[ pop >= 5 & denning > 24  + stdev_pop4[1], denning:=24+ stdev_pop4[1] ][ pop >= 5 & rust > 2.2+ stdev_pop4[2], rust :=2.2+ stdev_pop4[2]][ pop >= 5 & cwd > 17.4 + stdev_pop4[3], cwd :=17.4+ stdev_pop4[3]][ pop >= 5 & mov > 56.2+ stdev_pop4[4], mov :=56.2+ stdev_pop4[4]]
  
  
  #-----D2
  fisher.habitat.rs[ pop == 1, d2:= mahalanobis(fisher.habitat.rs[ pop == 1, c("denning", "rust", "cavity", "cwd", "mov")], c(1.6, 36.2, 0.7, 30.4, 26.8), cov = sim$fisher.d2.cov[[1]])]
  fisher.habitat.rs[ pop == 2, d2:= mahalanobis(fisher.habitat.rs[ pop == 2, c("denning", "rust", "cavity", "cwd", "mov")], c(1.16, 19.1, 0.45, 8.69, 33.06), cov = sim$fisher.d2.cov[[2]])]
  fisher.habitat.rs[ pop %in% c(3,4), d2:= mahalanobis(fisher.habitat.rs[ pop %in% c(3,4), c("denning", "rust", "cwd", "mov")], c(2.3, 1.6, 10.8, 21.5), cov = sim$fisher.d2.cov[[3]])]
  fisher.habitat.rs[ pop >= 5, d2:= mahalanobis(fisher.habitat.rs[ pop >= 5, c("denning", "rust", "cwd", "mov")], c(24.0, 2.2, 17.4, 56.2), cov = sim$fisher.d2.cov[[4]])]
  
  fisher.habitat.mahal<-merge(fisher.habitat, fisher.habitat.rs[,c("fetaid", "d2", "pop", "mov")], by.x = "fetaid", by.y = "fetaid", all.x =T)
  
  
  
  
  
  
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
