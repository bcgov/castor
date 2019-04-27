
# Copyright 2018 Province of British Columbia
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

defineModule(sim, list(
  name = "rsfCLUS",
  description = "This module calculates Resource Selection Functions within the simulation", 
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
    person("Tyler", "Muhley", email = "tyler.muhley@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.3", rsfCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "rsfCLUS.Rmd"),
  reqdPkgs = list(),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter("rsfCalcInterval", "numeric", 1, NA, NA, "The simulation time at which resource selection function are calculated"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput(objectName = "rsf_model_coeff", objectClass = "data.table", desc = 'A User supplied data.table containing the model coeffecients and their decription', sourceURL = NA),
    expectsInput(objectName = "clusdb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the RSF', sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "RasterLayer", desc = NA, sourceURL = NA)
    ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = "pts", objectClass = "data.table", desc = "A data.table of X,Y locations - used to find distances"),
    createsOutput(objectName = "rsf", objectClass = "data.table", desc = "A data.table of covariates used to calculate the RSF. This could be uploaded into clusdb?"),
    createsOutput(objectName = "rsfGLM", objectClass = "list", desc = "A list of glm objects that describe the RSF. Gets created at Init")
  )
))

doEvent.rsfCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- rsfCLUS.Init(sim)
      sim <- rsfCLUS.UpdateRSFTable(sim)
      sim <- rsfCLUS.PredictRSF(sim)
      #sim <- rsfCLUS.cleanRSF(sim)
      
      #sim <- scheduleEvent(sim, time(sim) + P(sim)$rsfCalcInterval, "rsfCLUS", "calculateRSF")
    },
    
    calculateRSF = {
      #sim <- rsfCLUS.UpdateRSFTable(sim)
      #sim <- rsfCLUS.PredictRSF(sim)
      
      #sim <- scheduleEvent(sim, time(sim) + P(sim)$rsfCalcInterval, "rsfCLUS", "calculateRSF")
    },
    
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

rsfCLUS.Init <- function(sim) {
  #init the raster pts
  sim$pts <- data.table(raster::rasterToPoints(sim$ras)) #Stores the X,Y of the raster
  setnames(sim$pts, "layer", "pixelid") #the default output from rasterToPoints is a variable called 'layer'
  
  #init the rsf table
  sim$rsf<-sim$pts
  sim$rsf<-sim$rsf[,'pixelid']
  
  #init a concatenated variable called 'rsf' that will report the population and season
  rsf_model_coeff[, rsf:= do.call(paste0, .BY), by = c("population", "season") ]
  
  #Set all the static rasters
  static_list<-as.list(unlist(unique(rsf_model_coeff[static == 'Y' & layer != 'int'])[,"layer"], use.names = FALSE))
  for(layer_name in static_list){ #Loop for getting all the rsf data into the rsf table
    print(layer_name)
    layer<-RASTER_CLIP2(srcRaster= layer_name, clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", P(sim, "dataLoaderCLUS", "nameBoundary"),"'')"), conn=NULL)
    sim$rsf<-cbind(sim$rsf, data.table(c(t(raster::as.matrix(layer)))))
    setnames(sim$rsf, "V1", layer_name)
  }
  
  rsf_list<-lapply(as.list(unique(rsf_model_coeff[,"rsf"])$rsf), function(x) {#prepare the list needed for lapply to get the glm objects  
    rsf_model_coeff[rsf==x, c("beta", "layer")]
  })
  sim$rsfGLM<-lapply(rsf_list, getglmobj)#init the glm objects for each of the rsf population and season
  
  return(invisible(sim))
}

rsfCLUS.UpdateRSFTable<-function(sim){ #gets the variables that are dynamic - ie., 'distance to' and simulation updatable variables (ex. height)
  if(nrow(unique(rsf_model_coeff[type == 'DT']))>0){ #DT is distance to
    sim<-getDistanceToLayers(sim)
  }
  if(nrow(unique(rsf_model_coeff[type == 'UP']))>0){ #UP is updated layers
    sim<-getUpdatedLayers(sim)
  }
  return(invisible(sim))
}

getUpdatedLayers<-function(sim){ #gets the updateable (internal to sim$clusdb) variables for the rsf
  up_layers<-paste(unlist((rsf_model_coeff[type == 'UP',"layer"]), use.names = FALSE), sep="' '", collapse=", ")
  sim$rsf<-cbind(sim$rsf, dbGetQuery(sim$clusdb,paste0( "SELECT ", up_layers," FROM pixels")))
  return(invisible(sim)) 
}

getDistanceToLayers<-function(sim){ #takes a sql statement and returns the distance to the result set generated by the sql
  dt_layers<-as.list(rsf_model_coeff[type == 'DT',c("sql", "layer") ])
  for(i in 1:nrow(rsf_model_coeff[type == 'DT'])){
    print(paste0("SELECT pixelid FROM pixels WHERE ", dt_layers$sql[i]))
    dt_select<-data.table(dbGetQuery(sim$clusdb, paste0("SELECT pixelid FROM pixels WHERE ", dt_layers$sql[i])))
    
    if(length(dt_select) > 0){
      dt_select[,field :=0]
      outPts<-merge(sim$pts, dt_select, by = 'pixelid', all.x =TRUE)
      nearNeigh<-RANN::nn2(outPts[field==0, 2:3], outPts[is.na(field), 2:3], k = 1)
      outPts<-outPts[is.na(field), dist:=nearNeigh$nn.dists] #assign the distances
      outPts[is.na(dist),]<-0 #those that are the distance to pixels, assign 
      sim$rsf<-merge(sim$rsf, outPts[,c('dist','pixelid')], by = 'pixelid', all.x = TRUE)
      #test<-unlist(sim$rsf[, "dist"], use.names = FALSE)
      setnames(sim$rsf, "dist", dt_layers$layer[i])
      
      #----Plotting the raster---
      #distRas<-sim$ras 
      #distRas[]<-test
      ##print(head(outPts[,'field']))
      ##distRas[]<-outPts[,'field']
      ##distRas[is.na(distRas[])]<-nearNeigh$nn.dists
      #writeRaster(distRas, paste0(dt_layers$layer[i], ".tif"), overwrite = TRUE)
      #--------------------------
      
      rm(outPts)
      gc()
    }
  }
  return(invisible(sim))
}

getglmobj <-function(parm_list){ #creates a predict glm object for each rsf
  #Create a fake data.table with 30 vars --this can be more....Tyler's RSF models max out ~30
  fake.dt <-data.table(x1=runif(10,0,1),x2=runif(10,0,1),x3=runif(10,0,1),x4=runif(10,0,1),x5=runif(10,0,1),
                       x6=runif(10,0,1),x7=runif(10,0,1),x8=runif(10,0,1),x9=runif(10,0,1),x10=runif(10,0,1),
                       x11=runif(10,0,1),x12=runif(10,0,1),x13=runif(10,0,1),x14=runif(10,0,1),x15=runif(10,0,1),
                       x16=runif(10,0,1),x17=runif(10,0,1),x18=runif(10,0,1),x19=runif(10,0,1),x20=runif(10,0,1),
                       x21=runif(10,0,1),x22=runif(10,0,1),x23=runif(10,0,1),x24=runif(10,0,1),x25=runif(10,0,1),
                       x26=runif(10,0,1),x27=runif(10,0,1),x28=runif(10,0,1),x29=runif(10,0,1),x30=runif(10,0,1),
                       y=sample(c(0,1), replace=TRUE, size=10))
  #get the RSF parameters and variables
  layers <-parm_list[,"layer"][-1] #-1 removes the intercept
  beta <-parm_list[,"beta"]
  #set the names of the fake.dt to the names of variables used in the RSF
  setnames(fake.dt, sprintf("x%s",seq(1:nrow(layers))), layers$layer)
  #Fit a fake model to get the class inheritance of glm
  suppressWarnings(lmFit <-glm(paste("y~", paste(layers$layer, sep = "' '", collapse= "+")),family=binomial(link='logit'), data = fake.dt))
  #Hack the coefficients listing so that the glm object thinks it fit this model
  lmFit$coefficients <- beta$beta

  return(lmFit)
}

rsfCLUS.PredictRSF(sim) <- function(sim){
  #TODO: Loop through each population and season to predict its selection probability
  #unique(rsf_model_coeff[,"rsf"])$rsf
  #lapply() or for loop here?
    
  return(invisible(sim))
}

completeDTZeros = function(DT) { #Sets all of the data.table columns that have NA to zero
  for (i in names(DT)) DT[is.na(get(i)), (i):=0]
}

.inputObjects <- function(sim) {
  return(invisible(sim))
}