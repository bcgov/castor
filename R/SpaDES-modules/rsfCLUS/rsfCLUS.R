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
    defineParameter("checkRasters", "logical", FALSE, NA, NA, "TRUE forces the rsfCLUS to write the rasters to disk. For checking in a GIS"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput(objectName = "rsf_model_coeff", objectClass = "data.table", desc = 'A User supplied data.table containing the model coeffecients and their decription', sourceURL = NA),
    expectsInput(objectName = "clusdb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the RSF', sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "RasterLayer", desc = NA, sourceURL = NA),
    expectsInput(objectName = "pts", objectClass = "data.table", desc = NA, sourceURL = NA)
    ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = "rsfCovar", objectClass = "data.table", desc = "A data.table of covariates used to calculate the RSF. This could be uploaded into clusdb?"),
    createsOutput(objectName = "rsfGLM", objectClass = "list", desc = "A list of glm objects that describe the RSF. Gets created at Init"),
    createsOutput(objectName = "rsf", objectClass = "data.table", desc = "A data.table of predicted rsf")
    
  )
))

doEvent.rsfCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      sim <- rsfCLUS.Init(sim)
      sim <- rsfCLUS.PredictRSF(sim)
      #sim <- scheduleEvent(sim, time(sim) + P(sim)$rsfCalcInterval, "rsfCLUS", "calculateRSF")
    },
    
    calculateRSF = {
      sim <- rsfCLUS.UpdateRSFCovar(sim)
      sim <- rsfCLUS.StandardizeDynamicRSFCovar(sim)
      sim <- rsfCLUS.PredictRSF(sim)
      
      sim <- scheduleEvent(sim, time(sim) + P(sim)$rsfCalcInterval, "rsfCLUS", "calculateRSF")
    },
    
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

rsfCLUS.Init <- function(sim) {
   #init a concatenated variable called 'rsf' that will report the population and season
  rsf_model_coeff[, rsf:= do.call(paste0, list(collapse = "_", .BY)), by = c("population", "season") ]
  rsf_model_coeff[layer != 'int', layer_uni:= do.call(paste, list(collapse = "_", .BY)), by = c("population", "season", "layer") ]
  
  #Set all the static rasters - when rsfcovar does not exist in sim$clusdb  
  if(nrow(dbGetQuery(sim$clusdb, "SELECT * FROM sqlite_master WHERE type = 'table' and name ='rsfcovar'")) == 0) {
    #init the rsfcovar table
    sim$rsfcovar<-data.table(sim$pts)
    
    #Upload the boundary from which the rsf will be applied
    rsf_list<-unique(rsf_model_coeff[, c("population","bounds")])
    
    for(k in 1:nrow(rsf_list)){
      print(rsf_list[k]$bounds)
      bounds<-data.table(c(t(raster::as.matrix(
        RASTER_CLIP2(srcRaster= paste0(rsf_list[k]$bounds), 
                     clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                     geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                     where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                     conn=NULL)))))
      sim$rsfcovar[, (rsf_list[k]$population):= bounds$V1]
    }
    
    #load the static variables
    static_list<-as.list(unlist(unique(rsf_model_coeff[static == 'Y' & layer != 'int'])[,c("sql")], use.names = FALSE))
    for(layer_name in static_list){ 
      print(layer_name)
      layer<-data.table(c(t(raster::as.matrix(
        RASTER_CLIP2(srcRaster= layer_name, 
                    clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                    geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                    where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                    conn=NULL)))))
      
      sim$rsfcovar[, (layer_name):= layer$V1] 
    }

     rsfCLUS.UpdateRSFCovar(sim) # Complete the rsfcovar table with the dynamic variables
     
     if(P(sim, "rsfCLUS", "checkRasters")){
       sim <- rsfCLUS.checkRasters(sim)
     }
     rsfCLUS.StandardizeStaticRSFCovar(sim)
     rsfCLUS.StandardizeDynamicRSFCovar(sim)
     rsfCLUS.StoreRSFCovar(sim) # store the current/initial rsfcovar for future use
     
  }else{
    sim$rsfcovar<-dbGetQuery(sim$clusdb, "SELECT * FROM rsfcovar")
  }
  #Set the GLM objects so that inherits class 'glm' which is needed for predict.glm function/method
  rsf_list<-lapply(as.list(unique(rsf_model_coeff[,"rsf"])$rsf), function(x) {#prepare the list needed for lapply to get the glm objects  
    rsf_model_coeff[rsf==x, c("rsf","beta", "layer_uni", "mean", "sdev")]
  })
  sim$rsfGLM<-lapply(rsf_list, getglmobj)#init the glm objects for each of the rsf population and season
  return(invisible(sim))
}

rsfCLUS.UpdateRSFCovar<-function(sim){ #gets the variables that are dynamic - ie., 'distance to' and simulation updatable variables (ex. height)
  if(nrow(unique(rsf_model_coeff[type == 'UP']))>0){ #UP is updated layers
    sim<-getUpdatedLayers(sim)
  }
  if(nrow(unique(rsf_model_coeff[type == 'DT']))>0){ #DT is distance to
    sim<-getDistanceToLayers(sim)
  }
  return(invisible(sim))
}

getUpdatedLayers<-function(sim){ #gets the updateable (internal to sim$clusdb) variables for the rsf
  up_layers<-paste(unlist(unique(rsf_model_coeff[type == 'UP',"layer"]), use.names = FALSE), sep="' '", collapse=", ")
  newLayer<-dbGetQuery(sim$clusdb,paste0( "SELECT ", up_layers," FROM pixels"))
  sim$rsfcovar[, (colnames(newLayer)) := as.data.table(newLayer)] # The '()' is need to evaluate the colnames function
  rm(newLayer)
  gc()
  return(invisible(sim)) 
}

getDistanceToLayers<-function(sim){ #takes a sql statement and returns the distance to the result set generated by the sql
  
  #Get a list of the Distance To layers that are dynamic in the sim
  dt_layers<-as.list(unique(rsf_model_coeff[static =='N' & type == 'DT',c("population", "sql", "layer", "mean", "sdev") ], by =c("population", "sql")))
  
  #Get unique sql fields
  dt_sql<-unique(dt_layers$sql)
  
  for(i in 1:length(dt_sql)){ #Loop through each of the DT layers
    dt_select<-data.table(dbGetQuery(sim$clusdb, paste0("SELECT pixelid FROM pixels WHERE ", dt_sql[i])))
    if(nrow(dt_select) > 0){ print(paste0(dt_sql[i], ": TRUE"))
      
      dt_select[,field := 0]
      #outPts contains pixelid, x, y, field, population
      #sim$rsfcovar contains: pixelid, x,y, population
      outPts<-merge(sim$rsfcovar, dt_select, by = 'pixelid', all.x =TRUE) 
      
      #The number of Du's that use this layer. This calcs the Distance To using the boundary of the DU!
      dt_variable<-unique(rsf_model_coeff[sql == dt_sql[i]], by ="population")
      for(j in 1:nrow(dt_variable)){
        pop_select<-parse(text=dt_variable$population[j])
        if(nrow(outPts[field==0 & eval(pop_select) > 0, c('x', 'y')])>0){
          nearNeigh<-RANN::nn2(outPts[field==0 & eval(pop_select) > 0, c('x', 'y')], 
                               outPts[is.na(field) & eval(pop_select) > 0, c('x', 'y')], 
                               k = 1)
          outPts<-outPts[is.na(field) & eval(pop_select) > 0, dist:=nearNeigh$nn.dists]#assign the distances
          outPts[is.na(dist) & eval(pop_select) > 0, dist:=0] #those that are the distance to pixels, assign 

          sim$rsfcovar<-merge(sim$rsfcovar, outPts[,c("pixelid","dist")], by = 'pixelid', all.x =TRUE) #sim$rsfcovar contains: pixelid, x,y, population
          sim$rsfcovar[, (dt_variable$layer[j]):= dist]
          sim$rsfcovar[, dist:=NULL]
          
        }else{
          print(paste0(pop_select, " does not overlap"))
        }
      }
    }else{
      variables_non<-rsf_model_coeff[sql == eval(dt_sql[i]),]
      for(s in 1:nrow(variables_non)){
        sim$rsfcovar[, (variables_non$layer[s]):= nrow(sim$ras)*100] 
      }
    }
  }
  
  rm(outPts,dt_variable,dt_select)
  gc()
  return(invisible(sim))
}

rsfCLUS.PredictRSF <- function(sim){
  #Loop through each population and season to predict its selection probability
  print("predicting RSF")
  rsfPops<- unique(rsf_model_coeff[,"rsf"])$rsf
  sim$rsf<- data.table()
  for(i in 1:length(rsfPops)){
    suppressWarnings(sim$rsf<-cbind(sim$rsf, data.table(predict.glm(sim$rsfGLM[[i]], sim$rsfcovar, type = "response"))))
    setnames(sim$rsf, "V1", paste0(rsfPops[i],"_", time(sim)))
  }
  
  #----Plot the Raster---------------------------
  test<-sim$ras
  test[]<-unlist(sim$rsf[,1])
  writeRaster(test, paste0(rsfPops[1],"_", time(sim), ".tif"), overwrite = TRUE)
  #----------------------------------------------
  return(invisible(sim))
}

rsfCLUS.StandardizeStaticRSFCovar<-function(sim){
  print('standardizing static covariates')
  
  static_list<-rsf_model_coeff[static == 'Y' & layer != 'int'] # Get the static list
  static_list <- within(static_list,  equate <- paste(layer_uni, sql, sep="=")) # concatenate two colums so that the new layer equals the old layer

  static_equals<-paste(static_list$equate, sep ="' '", collapse = ", ")
  static_assign<-parse(text=paste0("`:=`(",static_equals ,")"))
  sim$rsfcovar[,eval(static_assign)] #Assugn the new names with the imported (old) layers
 
  cm <- setNames(static_list$mean, static_list$layer_uni)
  csd <- setNames(static_list$sdev, static_list$layer_uni) #A named vector pertaining to the standard deviation
  
  #Standardize the covariates
  for(j in new_cols){
    set(sim$rsfcovar, i=NULL, j = j, value= (sim$rsfcovar[[j]] - cm[[j]] ) /csd[[j]] )
  }
  
  #Drop the unstandardized covars
  static_drop<-unique(static_list$sql)
  sim$rsfcovar<-sim$rsfcovar[,(static_drop):= NULL]
  
  return(invisible(sim))
}

rsfCLUS.StandardizeDynamicRSFCovar<-function(sim){
  print('standardizing dynamic covariates')
  
  dynamic_list<-rsf_model_coeff[static == 'N' & layer != 'int']
  dynamic_list <- within(dynamic_list,  equate <- paste(layer_uni, layer, sep="=")) # concatenate two colums so that the new layer equals the old layer
  
  dynamic_equals<-paste(dynamic_list$equate, sep ="' '", collapse = ", ")
  dynamic_assign<-parse(text=paste0("`:=`(",dynamic_equals ,")"))
  sim$rsfcovar[,eval(dynamic_assign)] #Assign the new names with the imported (old) layers
  
  cm <- setNames(dynamic_list$mean, dynamic_list$layer_uni)
  csd <- setNames(dynamic_list$sdev, dynamic_list$layer_uni) #A named vector pertaining to the standard deviation
  
  #Standardize the covariates
  for(j in dynamic_list$layer_uni){
    set(sim$rsfcovar, i=NULL, j = j, value= (sim$rsfcovar[[j]] - cm[[j]] ) /csd[[j]] )
  }
  
  #Drop the unstandardized covars
  dynamic_drop<-unique(dynamic_list$layer)
  sim$rsfcovar<-sim$rsfcovar[,(dynamic_drop):= NULL]
  
  return(invisible(sim))
}

rsfCLUS.StoreRSFCovar<- function(sim){
  #Stores the rsfCover in clusdb. This allows a clusdb to be created and used again without wait times for dataloading
  ##Create the table in clusdb
  dbExecute(sim$clusdb, paste0("CREATE TABLE IF NOT EXISTS rsfcovar (",
                              paste(colnames(sim$rsfcovar), sep = "' '", collapse = ' numeric, '), " numeric)"))
  #Insert the values
  dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, paste0("INSERT INTO rsfcovar (",
                                       paste(colnames(sim$rsfcovar), sep = "' '", collapse = ', '), ") 
                        values (:", paste(colnames(sim$rsfcovar), sep = "' '", collapse = ',:'), ")"), sim$rsfcovar)
  dbClearResult(rs)
  dbCommit(sim$clusdb)
  #print(dbGetQuery(sim$clusdb, "SELECT * from rsfcovar LIMIT 7"))
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
  layers <-parm_list[,"layer_uni"][-1] #-1 removes the intercept
  beta <-parm_list[,"beta"]
  #These names need to match the names in rsfcovar -- this means different columns for each standardized variable...
  #set the names of the fake.dt to the names of variables used in the RSF
  setnames(fake.dt, sprintf("x%s",seq(1:nrow(layers))), layers$layer_uni)
  #Fit a fake model to get the class inheritance of glm
  suppressWarnings(lmFit <-glm(paste("y~", paste(layers$layer_uni, sep = "' '", collapse= "+")),family=binomial(link='logit'), data = fake.dt))
  #Hack the coefficients list so that the glm object uses these coefficents
  lmFit$coefficients <- beta$beta
  
  return(lmFit)
}

completeDTZeros = function(DT) { #Sets all of the data.table columns that have NA to zero
  for (i in names(DT)) DT[is.na(get(i)), (i):=0]
}

rsfCLUS.checkRasters <- function(sim) {
#----Plotting the raster---
  for(layer in colnames(sim$rsfcovar)){
    print(paste0("ploting", layer))
    distRas<-sim$ras 
    test<-parse(text = paste0("sim$rsfcovar$",layer))
    distRas[]<-eval(test)
    writeRaster(distRas, paste0(layer, ".tif"), overwrite = TRUE)
  }

#--------------------------
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  return(invisible(sim))
}