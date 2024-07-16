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


defineModule(sim, list(
  name = "fireCastorSingleYearRep",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Elizabeth", "Kleynhans", email = "elizabeth.kleynhans@gov.bc.ca", role = c("aut", "cre")),
              person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", fireCastorSingleYearRep = "1.0.0"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "fireCastorSingleYearRep.Rmd"),
  reqdPkgs = list("here","data.table", "raster", "SpaDES.tools", "tidyr","terra"),
  parameters = rbind(
    defineParameter("calculateInterval", "numeric", 1, NA, NA, "The simulation time at which disturbance indicators are calculated"),
    ),
  inputObjects = bind_rows(
    expectsInput(objectName = "castordb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the RSF', sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "SpatRaster", desc = "A raster object created in dataCastor. It is a raster defining the area of analysis (e.g., supply blocks/TSAs).", sourceURL = NA),
    expectsInput(objectName = "pts", objectClass = "data.table", desc = "Centroid x,y locations of the ras.", sourceURL = NA),
    expectsInput(objectName ="boundaryInfo", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "scenario", objectClass = "data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName = "updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA),
    expectsInput(objectName = "simStartYear", objectClass ="numeric", desc = 'The calendar year of the first simulation', sourceURL = NA),
    expectsInput(objectName = "downdat", "data.table", "Table of parameters needed for number of ignitions and area burned at 10km scale."),
    expectsInput(objectName = "probFireRasts", "data.table", "Table of calculated probability values for escape and spread for every pixel")
    ),
  
  outputObjects = bind_rows(
    createsOutput("firedisturbanceTableForReps", "data.table", "Disturbance by fire table for every pixel i.e. every time a pixel is burned it is updated by one so that at the end of the simulation time period we know how many times each pixel was burned"),
    createsOutput("fireReportForReps", "data.table", "Summary per simulation period of the fire indicators i.e. total area burned, number of fire starts"),
    createsOutput("perFireReportForReps", "data.table", "This table provides the pixelid of the ignition location and size reached by each fire."),
    createsOutput("fire.size","data.table","List of simulated fire sizes"),
    #createsOutput("ras.frt", "raster", "Raster of fire regime types (maybe not needed)"),
    createsOutput("downdat", "data.table", "Table of parameters needed for number of ignitions and area burned at 10km scale.")
    #createsOutput("probFireRasts", "data.table", "Table of calculated probability values for escape and spread for every pixel"),
    #createsOutput("out", "data.table", "Table of starting location of fires and pixel id's of locations burned during the simulation"),
    #createsOutput("ras.elev", "raster", "Raster of elevation for aoi"),
    #createsOutput("samp.pts", "data.table", "Table of latitude, longitude, and elevation of points at a scale of 800m x 800m across the area of interest for climate data extraction"),
    #createsOutput("fit_g", "vector", "Shape and rate parameters for the gamma distribution used to fit the distribution of ignition points"),
    #createsOutput("min_ignit", "value", "Minimum number of fires observed"),
    #createsOutput("max_ignit", "value", "Maximum number of ignitions observed multiplied by 5. I oversample the initial number of ignition locations and then select from the list of locations the ones that have a probability of ignition greater than a randomly drawn value until the number of drawn ignition locations is the same as the number I sampled from the gamma distribution.")
  )
))


doEvent.fireCastorSingleYearRep = function(sim, eventTime, eventType, debug = FALSE){
  switch(
    eventType,
    init = {
      sim <- Init (sim) # this function inits 
      sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastorSingleYearRep"), "fireCastorSingleYearRep", "burnRepitions", 15)
      sim <- scheduleEvent(sim, end(sim), "fireCastorSingleYearRep", "saveFireTables", 16)
      },
  
    burnRepitions = {
      sim<-burnReps(sim)
      sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "fireCastorSingleYearRep"), "fireCastorSingleYearRep", "burnRepitions", 15)
    },
    
    saveFireTables = {
      sim<-savefiretable(sim)
      #sim <- scheduleEvent(sim, end(sim), "fireCastorSingleYearRep", "saveFireTables", 16)
    },
    
    
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  
  sim$perFireReportForReps<-data.table(timeperiod= integer(), rep = integer(), ignition_location=integer(), pixelid10km = integer(), areaburned_estimated = numeric())
  
  sim$firedisturbanceTableForReps<-data.table(scenario = scenario$name, reps = as.numeric(0), pixelid = sim$pts$pixelid, numberTimesBurned = as.numeric(0))
  
  sim$fireReportForReps<-data.table(timeperiod= integer(), rep = integer(), numberstarts = integer(), totalareaburned = numeric(), thlbburned = numeric())
  
  browser()
  
  return(invisible(sim))
  
}


burnReps<-function(sim){
  
  for (rep in 1:(P(sim, "numberFireReps", "fireCastorSingleYearRep"))) {
    
    message(paste("running simulation rep ",(rep)))
    
    sim$downdat<-sim$downdat[ ,est:= exp(-17.0 -0.0576*cmi_min-0.124*(cmi-cmi3yr/3)-0.363*avgCMIProv  -0.979*frt5 -0.841*frt7 -1.55*frt9  -1.55*frt10  -1.03*frt11  -1.09*frt12 -1.34*frt13  -0.876*frt14  -2.36*frt15+ 0.495*log(con + 1) + 0.0606 *log(young + 1) -0.0256 *log(dec + 1) +est_rf  + log(flammable) )]
    
    sim$downdat[, mu1:= 2.158738 - 0.001108 * PPT_sm - 0.011496 * cmi + -0.719612 * est  -0.020594 * log(con + 1)][, sigma1:=  1.087][ , mu2:= 2.645616 -0.001222*PPT_sm + 0.049921 * cmi +1.918825 * est -0.209590*log(con + 1) ][, sigma2:= 0.27]
    
    sim$downdat[, pi2:=1/(1+exp(-1*(-0.1759469+ -1.374135*frt5-0.6081503*frt7-2.698864*frt9 -1.824072*frt10 -3.028758*frt11  -1.234629*frt12-1.540873*frt13-0.842797*frt14  -1.334035*frt15+ 0.6835479*avgCMIProv+0.1055167*TEMP_MAX )))][,pi1:=1-pi2]
    
    occ<-downdat[, fire:= rnbinom(n = 1, size = 0.416, mu = est), by=1:nrow(sim$downdat)][fire>0,]
    
    message("determine fire size")
    
    if (nrow(occ)>0){
      occ<-occ[ , k_sim:= sample(1:2,prob=c(pi1, pi2),size=1), by = seq_len(nrow(occ))]
      occ<-occ[k_sim==1, mu_sim := exp(mu1)][k_sim==1, sigma_sim := exp(sigma1)][k_sim==2, mu_sim := exp(mu2)][k_sim==2, sigma_sim := exp(sigma2)]
      
      fire.size.sim<-data.table(fire.size = as.numeric(), pixelid10km=as.integer())
      
      for(f in 1:length(occ$fire)){
        
        fires<-data.table(fire.size = (exp(gamlss.dist::rWEI(occ$fire[f], mu = occ$mu_sim[f], sigma =occ$sigma_sim[f]))), pixelid10km = occ$pixelid10km[f])
        
        #print(fires)
        
        fire.size.sim<- rbindlist(list(fire.size.sim, data.table(fire.size = sum(fires$fire.size), pixelid10km = fires$pixelid10km[1])))
      }
      
      fire.size<-fire.size.sim
      print(fire.size)
      
      
    } else {message("no fires simulated")}
    
    message("get ignition locations")
    # create empty fire report
    
    tempperFireReportForReps<-data.table(timeperiod= integer(),rep = integer(),ignition_location=integer(), pixelid10km = integer(), areaburned_estimated = numeric())
    
    if (!is.null(fire.size)) {
      fire.size$ignit_location<-0
      
      sim$probFireRast[is.na(prob_ignition_spread), prob_ignition_spread:=0]
      sim$probFireRast[is.na(prob_ignition_escape), prob_ignition_escape:=0]
      
      for (g in 1:length(fire.size$pixelid10km)){
        x<-sim$probFireRast[pixelid10km==fire.size$pixelid10km[g],]
        pixelid_value<-sample(x$pixelid,size=1, prob=as.numeric(x$prob_ignition_escape))
        fire.size$ignit_location[g]<-pixelid_value
      }
      
      # create area raster
      sim$probFireRast<-sim$probFireRast[order(pixelid)]
      area<-sim$ras
      area[]<-sim$probFireRast$prob_ignition_escape
      area[area[] > 0 ]<-1
      area<-raster(area)
      area[is.na(area[])] <- 0 
      
      message("create spread raster")
      spreadRas<-sim$ras
      spreadRas[]<-sim$probFireRast$prob_ignition_spread
      spreadRas<-raster(spreadRas)
      spreadRas[is.na(spreadRas[])] <- 0 
      
      fire.size$fire.size<-round(fire.size$fire.size,0)
      
      message("simulating fire")
      out <- spread2(area, start = fire.size$ignit_location, spreadProbRel =spreadRas, exactSize=fire.size$fire.size, asRaster = FALSE, allowOverlap=FALSE)
      

      
      message("updating firedisturbanceTableForReps")
      
      sim$firedisturbanceTableForReps[pixelid %in% out$pixels, numberTimesBurned := numberTimesBurned + 1]
      sim$firedisturbanceTableForReps[, reps := reps + 1]
      
      thlbburned = dbGetQuery(sim$castordb, paste0(" select sum(thlb) as thlb from pixels where pixelid in (", paste(out$pixels, sep = "", collapse = ","), ");"))$thlb
      
      totalareaburned=out[,.N]
      
      numberstarts<-length(fire.size$ignit_location)
      
      # create temp fire report
      
      tempperFireReportForReps<-data.table(timeperiod = time(sim), rep = rep,ignition_location=fire.size$ignit_location, pixelid10km = fire.size$pixelid10km, areaburned_estimated = fire.size$fire.size)
      
    } else {
      message("no fires simulated")
      numberstarts = 0
      totalareaburned = 0
      thlbburned = 0
      
      
      message("updating fire Report")
      
      # create individual fire size report with starting locations   
      tempperFireReportForReps<-data.table(timeperiod = time(sim), rep = rep, ignition_location="NA", pixelid10km = "NA", areaburned_estimated = totalareaburned)
      
    }
    
    sim$perFireReportForReps<-rbindlist(list(sim$perFireReportForReps,tempperFireReportForReps ))
    
    sim$fireReportForReps<-rbindlist(list(sim$fireReportForReps, data.table(timeperiod= time(sim), rep=rep, numberstarts = numberstarts, totalareaburned = totalareaburned, thlbburned = thlbburned)))
    
  }
  return(invisible(sim))
}


savefiretable <- function(sim) {
  message ("save fire tables for multiple reps within a year")
  
  #print(sim$perFireReport)
  saveRDS(sim$perFireReportForReps, file = paste0(outputPath(sim), "/perFireReportForReps_test_", time(sim)*sim$updateInterval, ".rds"))
  
  #print(sim$firedisturbanceTable)
  saveRDS(sim$firedisturbanceTableForReps, file = paste0(outputPath(sim), "/firedisturbanceTableForReps_", time(sim)*sim$updateInterval, ".rds"))
  
  #print(sim$fireReport)
  saveRDS(sim$fireReportForReps, file = paste0(outputPath(sim), "/fireReportForReps_test_", time(sim)*sim$updateInterval, ".rds"))
  
  return(invisible(sim))
}



.inputObjects <- function(sim) {
  # if(!suppliedElsewhere("road_distance", sim)){
  #   sim$road_distance<- data.table(pixelid= as.integer(), 
  #                                  rds_dist = as.numeric())
  # }
  
  if(!suppliedElsewhere("harvestPixelList", sim)){
    sim$harvestPixelList<- data.table(pixelid= as.integer(), 
                                      blockid = as.integer(),
                                      compartid = as.character())
  }
  return(invisible(sim))
}
