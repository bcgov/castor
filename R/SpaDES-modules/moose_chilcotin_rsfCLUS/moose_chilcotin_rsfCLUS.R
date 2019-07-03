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
  name = "moose_chilcotin_rsfCLUS",
  description = "This module calculates Resource Selection Functions (RSFs) for moose within the simulation. Ntoe that RSF outputs are most appropriate for southern DU7 herds (e.g., TWeedsmuir and Itcha-Ilgachuz), and should probably only be used there, but in theory the model could be applied elsewhere.", 
  keywords = c ("moose", "resource", "selection", "function", "RSF", "habitat"), # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
    person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.3", moose_chilcotin_rsfCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "moose_chilcotin_rsfCLUS.Rmd"),
  reqdPkgs = list(),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter("calculateInterval", "numeric", 1, NA, NA, "The simulation time at which resource selection functions (RSFs) are calculated"),
    defineParameter("checkRasters", "logical", FALSE, NA, NA, "TRUE forces the moose_chilcotin_rsfCLUS to write the rasters to disk. For checking in a GIS"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput(objectName = "moose_chilcotin_rsf_model_coeff", objectClass = "data.table", desc = 'A User supplied data.table containing the RSF model coefficients and their decription', sourceURL = NA), # will be called from the pgdb
    expectsInput(objectName = "clusdb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the RSF', sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "RasterLayer", desc = 'A spatial raster dataset provided by dataLoaderCLUS module. The raster defines the spatial extent of the analysis (i.e., study area), currently defined by the caribou herd boundary selected for analysis, but could consist of multiple herds or some other type of boundary (e.g., TSA).', sourceURL = NA),
    expectsInput(objectName = "pts", objectClass = "data.table", desc = 'A spatial point layer of the centroids of the ras data.', sourceURL = NA)
    ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = "rsfcovar_moose_chilcotin", objectClass = "data.table", desc = "A data.table of covariates used to calculate the RSF. These covariates are extracted from raster data."),
    createsOutput(objectName = "rsfGLM_moose_chilcotin", objectClass = "list", desc = "A list of glm objects that describe the moose RSF. Gets created at Init"),
    createsOutput(objectName = "rsf_moose_chilcotin", objectClass = "data.table", desc = "A data.table of predicted moose rsf scores.")
    
  )
))

doEvent.moose_chilcotin_rsfCLUS = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = { # on initialization
      sim <- moose_chilcotin_rsfCLUS.Init(sim) # run a function that creates a data.table of RSF covariates (RSFcovar_moose_chilcotin) to be used in the RSF calculation
      sim <- moose_chilcotin_rsfCLUS.PredictRSF(sim) # predict the initial RSF using the covariates
      sim <- scheduleEvent(sim, time(sim) + P(sim, "moose_chilcotin_rsfCLUS", "calculateInterval"), "moose_chilcotin_rsfCLUS", "calculateRSF_moose_chilcotin", 8) # schedule the next time to update and calculate the RSF 
      sim <- scheduleEvent(sim, end(sim),"moose_chilcotin_rsfCLUS", "save_RSF_moose_chilcotin", 8 )
      },
    
    calculateRSF_moose_chilcotin = {
      sim <- moose_chilcotin_rsfCLUS.UpdateRSFCovar (sim) # fucntion that gets the RSF covariates that are dynamic rasters - ie., 'distance to' and simulation updatable variables (ex. height)
      # sim <- moose_chilcotin_rsfCLUS.StandardizeDynamicRSFCovar(sim) ### NOT NEEDED BECAUVE NOT STANDARDIZED 
      sim <- moose_chilcotin_rsfCLUS.PredictRSF (sim) # predict the initial RSF using the covariates
      sim <- scheduleEvent(sim, time(sim) + P(sim, "moose_chilcotin_rsfCLUS", "calculateInterval"), "moose_chilcotin_rsfCLUS", "calculateRSF_moose_chilcotin", 8) # schedule the next time to update and calculate the RSF 
    },
    save_RSF_moose_chilcotin = {
      print('saving at the end of the sim')
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}



moose_chilcotin_rsfCLUS.Init <- function(sim) { # this function initializes the module by creating a data.table of the 'static' (do not change over the sim) raster covariates needed to calculate the RSF equation  
   #init a concatenated variable called 'rsf_moose_chilcotin' that will report the population and season
  moose_chilcotin_rsf_model_coeff[, rsf_moose_chilcotin:= do.call(paste0, list(collapse = "_", .BY)), by = c("population", "season") ] # what is this doing?
  moose_chilcotin_rsf_model_coeff[layer != 'int', layer_uni:= do.call(paste, list(collapse = "_", .BY)), by = c("population", "season", "layer") ] # what is this doing?
  
  sim$rsf_moose_chilcotin <- data.table() #init the rsf table
  #Set all the static rasters - when rsfCovar_moose_chilcotin does not exist in sim$clusdb  
  if(nrow(dbGetQuery(sim$clusdb, "SELECT * FROM sqlite_master WHERE type = 'table' and name ='rsfCovar_moose_chilcotin'")) == 0) { # I thought rsfCovar was an output? why being called form clus db?
    #init the rsfcovar_moose_chilcotin table
    sim$rsfcovar_moose_chilcotin <- data.table(sim$pts) # takes the centroid locations of the study area raster to paramterize the rsf table 
    
    # Upload the boundary where the rsf will be applied
    rsf_list_moose_chilcotin <- unique(moose_chilcotin_rsf_model_coeff[, c ("population","bounds")])
    
    for(k in 1:nrow(rsf_list_moose_chilcotin)){ # for each boundary (i.e., RSF 'study area') 
      message(rsf_list_moose_chilcotin[k]$bounds) # say which boundary
      bounds<-data.table(c(t(raster::as.matrix( # call the RSF boundary raster and clip if by the caribou herd boundary, then turn the raster into a data.table 
        RASTER_CLIP2(srcRaster= paste0(rsf_list_moose_chilcotin[k]$bounds), 
                     clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                     geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                     where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                     conn=NULL)))))
      sim$rsfcovar_moose_chilcotin[, (rsf_list_moose_chilcotin[k]$population):= bounds$V1] # attach the raster data.table to the RSF covariate data.table; WHAT IS BEING ATTACHED FROM RASTER???
    }
    
    # load the static rasters for calculating the RSF
    static_list <- as.list (unlist(unique(moose_chilcotin_rsf_model_coeff[static == 'Y' & layer != 'int'])[,c("sql")], use.names = FALSE)) # query and create the list of static rasters
    
    for(layer_name in static_list){ # for each static raster
      message(layer_name) # declare the static raster name
      if(moose_chilcotin_rsf_model_coeff[sql == layer_name & layer != 'int']$type == 'RC' ){ # if it's a reclass type of static raster
        rclass_text<- moose_chilcotin_rsf_model_coeff[sql == layer_name & layer != 'int']$reclass # query and extract the reclass queries
        message(rclass_text) # declare teh reclass query
        layer<-data.table(c(t(raster::as.matrix( # clip the raster you queried and reclass the values so that the class integers become the RSF coefficient values for that class (this is what the sql statement is doing), then convert it to a data.table
          RASTER_CLIP_CAT(srcRaster= layer_name, 
                       clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                       geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                       where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                       out_reclass = rclass_text,
                       conn=NULL)))))
      }else{ # if it's not a reclass type of static raster
        layer<-data.table(c(t(raster::as.matrix( # clip the raster (selected based on the sql statement for that raster) and turn it into a data.table
          RASTER_CLIP2(srcRaster= layer_name, 
                       clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                       geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                       where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                       conn=NULL)))))
      }
      sim$rsfcovar_moose_chilcotin[, (layer_name):= layer$V1] # attach the static variables to the the rsfcovar table
    }

    
    moose_chilcotin_rsfCLUS.UpdateRSFCovar(sim) # function to update the dynamic RSF raster covariates 
     
    if(P(sim, "moose_chilcotin_rsfCLUS", "checkRasters")){ # If checkRasters parameter set to TRUE, then rasters saved to disk (postgres db?)
      sim <- moose_chilcotin_rsfCLUS.checkRasters(sim)
    }
    
    # moose_chilcotin_rsfCLUS.StandardizeStaticRSFCovar(sim) # function to standardize covariates; not needed here
    # moose_chilcotin_rsfCLUS.StandardizeDynamicRSFCovar(sim) # function to standardize covariates; not needed here
    moose_chilcotin_rsfCLUS.StoreRSFCovar(sim) # store the current/initial rsfcovar_moose_chilcotin for future use
     
  }else{ # If checkRasters parameter set to FALSE, then ????
    sim$rsfcovar_moose_chilcotin <- dbGetQuery(sim$clusdb, "SELECT * FROM rsfcovar_moose_chilcotin")
  }
  
  #Set the GLM objects so that inherits class 'glm' which is needed for predict.glm function/method
  moose_chilcotin_rsf_list<-lapply(as.list(unique(moose_chilcotin_rsf_model_coeff[,"rsf_moose_chilcotin"])$rsf_moose_chilcotin), function(x) {#prepare the list needed for lapply to get the glm objects  
    moose_chilcotin_rsf_model_coeff[rsf_moose_chilcotin==x, c("rsf_moose_chilcotin","beta", "layer_uni")]
  })
  
  sim$rsfGLM_moose_chilcotin <- lapply(moose_chilcotin_rsf_list, getglmobj) # init the glm objects for each of the rsf population and season; # getglmobj is a function that creates a glm object for each rsf
  
  return(invisible(sim))
}

moose_chilcotin_rsfCLUS.UpdateRSFCovar<-function(sim){ # gets the RSF covariates that are dynamic rasters - ie., 'distance to' and simulation updatable variables (ex. height)
  if(nrow(unique(moose_chilcotin_rsf_model_coeff[type == 'UP']))>0){ #UP is 'updated' (i.e., dynamic)  layers
    sim<-getUpdatedLayers(sim) # function to query the raster data that are updated in the RSF and then convert to a data.table and attach it to the rsfcovar_moose_chilcotin data.table
  }
  if(nrow(unique(moose_chilcotin_rsf_model_coeff[type == 'DT']))>0){ #DT is distance to dynamic layers
    sim<-getDistanceToLayers(sim)
  }
  return(invisible(sim))
}

getUpdatedLayers <- function (sim){ # gets the updateable (internal to sim$clusdb) raster variables for the rsf
  up_layers <- paste (unlist(unique(moose_chilcotin_rsf_model_coeff[type == 'UP',"layer"]), use.names = FALSE), sep="' '", collapse=", ") # creates an SQL statement of the updateable raster names
  newLayer<-dbGetQuery(sim$clusdb,paste0( "SELECT ", up_layers," FROM pixels"))# take the sql statement and query the clus db for the raster data
  #newLayer<-dbGetQuery(sim$clusdb,paste0( "SELECT pixelid FROM pixels WHERE ", dy_layers))
  sim$rsfcovar_moose_chilcotin [, (colnames(newLayer)) := as.data.table(newLayer)] # convert the raster to data.table and attach the values to the rsfcovar table; The '()' is need to evaluate the colnames function
  rm(newLayer)
  gc()
  return(invisible(sim)) 
}


getDistanceToLayers<-function(sim){ #takes a sql statement and returns the distance to the result set generated by the sql
  
  #Get a list of the Distance To layers that are dynamic in the sim
  dt_layers<-as.list(unique(moose_chilcotin_rsf_model_coeff[static =='N' & type == 'DT',c("population", "sql", "layer", "mean", "sdev") ], by =c("population", "sql")))
  
  #Get unique sql fields
  dt_sql<-unique(dt_layers$sql)
  
  for(i in 1:length(dt_sql)){ #Loop through each of the DT layers
    dt_select<-data.table(dbGetQuery(sim$clusdb, paste0("SELECT pixelid FROM pixels WHERE ", dt_sql[i])))
    if(nrow(dt_select) > 0){ 
      print(paste0(dt_sql[i], ": TRUE"))
      dt_select[,field := 0]
      #outPts contains pixelid, x, y, field, population
      #sim$rsfcovar contains: pixelid, x,y, population
      outPts<-merge(sim$rsfcovar, dt_select, by = 'pixelid', all.x =TRUE) 
      
      #The number of Du's that use this layer. This calcs the Distance To using the boundary of the DU!
      dt_variable<-unique(moose_chilcotin_rsf_model_coeff[sql == dt_sql[i]], by ="population")
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
          message(paste0(pop_select, " does not overlap"))
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

moose_chilcotin_rsfCLUS.PredictRSF <- function(sim){ # function to predict the RSF scores in the study area
  #Loop through each population and season to predict its selection probability
  message("predicting RSF")
  rsfPops <- unique(moose_chilcotin_rsf_model_coeff[,"rsf"])$rsf # what is this?
  
  for(i in 1:length(rsfPops)){ # for each ???
    suppressWarnings(sim$rsf_moose_chilcotin <- cbind(sim$rsf_moose_chilcotin, data.table(predict.glm(sim$rsfGLM_moose_chilcotin[[i]], sim$rsfcovar_moose_chilcotin, type = "response")))) # create an RSF data.table object that consists of the glm (RSF) predictions and covariate values
    setnames(sim$rsf_moose_chilcotin, "V1", paste0(rsfPops[i],"_", time(sim))) # change the names of the data.table columns; V1 is the RSF predictions?
  }
  
  #----Plot the Raster---------------------------
  test<-sim$ras
  test[]<-unlist(sim$rsf_moose_chilcotin[,1]) # attach the predicted RSF scores to the study area raster and save it
  writeRaster(test, paste0(rsfPops[1],"_", time(sim), ".tif"), overwrite = TRUE)
  #----------------------------------------------
  return(invisible(sim))
}


### FOLLOWING FUNCTION NOT NEEDED HERE; COVARIATES NOT STANDARDIZED ###
# rsfCLUS.StandardizeStaticRSFCovar<-function(sim){
#   message('standardizing static covariates')
#   
#   static_list<-rsf_model_coeff[static == 'Y' & layer != 'int'] # Get the static list
#   static_list <- within(static_list,  equate <- paste(layer_uni, sql, sep="=")) # concatenate two colums so that the new layer equals the old layer
# 
#   static_equals<-paste(static_list$equate, sep ="' '", collapse = ", ")
#   static_assign<-parse(text=paste0("`:=`(",static_equals ,")"))
#   sim$rsfcovar[,eval(static_assign)] #Assign the new names with the imported (old) layers
#  
#   cm <- setNames(static_list$mean, static_list$layer_uni)
#   csd <- setNames(static_list$sdev, static_list$layer_uni) #A named vector pertaining to the standard deviation
#   
#   #Standardize the covariates
#   for(j in static_list$layer_uni){
#     set(sim$rsfcovar, i=NULL, j = j, value= (sim$rsfcovar[[j]] - cm[[j]] ) /csd[[j]] )
#   }
#   
#   #Drop the unstandardized covars
#   static_drop<-unique(static_list$sql)
#   sim$rsfcovar<-sim$rsfcovar[,(static_drop):= NULL]
#   
#   return(invisible(sim))
# }

### FOLLOWING FUNCTION NOT NEEDED HERE; COVARIATES NOT STANDARDIZED ###
# rsfCLUS.StandardizeDynamicRSFCovar<-function(sim){
#   message('standardizing dynamic covariates')
#   
#   dynamic_list<-rsf_model_coeff[static == 'N' & layer != 'int']
#   dynamic_list <- within(dynamic_list,  equate <- paste(layer_uni, layer, sep="=")) # concatenate two colums so that the new layer equals the old layer
#   
#   dynamic_equals<-paste(dynamic_list$equate, sep ="' '", collapse = ", ")
#   dynamic_assign<-parse(text=paste0("`:=`(",dynamic_equals ,")"))
#   sim$rsfcovar_moose_chilcotin[,eval(dynamic_assign)] #Assign the new names with the imported (old) layers
#   
#   cm <- setNames(dynamic_list$mean, dynamic_list$layer_uni)
#   csd <- setNames(dynamic_list$sdev, dynamic_list$layer_uni) #A named vector pertaining to the standard deviation
#   
#   #Standardize the covariates
#   for(j in dynamic_list$layer_uni){
#     set(sim$rsfcovar, i=NULL, j = j, value= (sim$rsfcovar[[j]] - cm[[j]] ) /csd[[j]] )
#   }
#   
#   #Drop the unstandardized covars
#   dynamic_drop<-unique(dynamic_list$layer)
#   sim$rsfcovar<-sim$rsfcovar[,(dynamic_drop):= NULL]
#   
#   return(invisible(sim))
# }

moose_chilcotin_rsfCLUS.StoreRSFCovar <- function(sim){
  # Stores the rsfCover in clusdb. This allows a clusdb to be created and used again without wait times for dataloading
  ## Create the table in clusdb
  dbExecute(sim$clusdb, paste0("CREATE TABLE IF NOT EXISTS rsfcovar_moose_chilcotin (",
                              paste(colnames(sim$rsfcovar_moose_chilcotin), sep = "' '", collapse = ' numeric, '), " numeric)"))
  #Insert the RSF values
  dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, paste0("INSERT INTO rsfcovar_moose_chilcotin (",
                                       paste(colnames(sim$rsfcovar_moose_chilcotin), sep = "' '", collapse = ', '), ") 
                        values (:", paste(colnames(sim$rsfcovar_moose_chilcotin), sep = "' '", collapse = ',:'), ")"), sim$rsfcovar_moose_chilcotin)
  dbClearResult(rs)
  dbCommit(sim$clusdb)
  #print(dbGetQuery(sim$clusdb, "SELECT * from rsfcovar_moose_chilcotin LIMIT 7"))
  return(invisible(sim))
}

getglmobj <-function(parm_list){ # creates a glm object for each rsf ### WHAT's THE parm_list here???
  #Create a fake data.table with 30 vars --this can be more
  fake.dt <-data.table(x1=runif(10,0,1),x2=runif(10,0,1),x3=runif(10,0,1),x4=runif(10,0,1),x5=runif(10,0,1),
                       x6=runif(10,0,1),x7=runif(10,0,1),x8=runif(10,0,1),x9=runif(10,0,1),x10=runif(10,0,1),
                       x11=runif(10,0,1),x12=runif(10,0,1),x13=runif(10,0,1),x14=runif(10,0,1),x15=runif(10,0,1),
                       x16=runif(10,0,1),x17=runif(10,0,1),x18=runif(10,0,1),x19=runif(10,0,1),x20=runif(10,0,1),
                       x21=runif(10,0,1),x22=runif(10,0,1),x23=runif(10,0,1),x24=runif(10,0,1),x25=runif(10,0,1),
                       x26=runif(10,0,1),x27=runif(10,0,1),x28=runif(10,0,1),x29=runif(10,0,1),x30=runif(10,0,1),
                       y=sample(c(0,1), replace=TRUE, size=10))
  
  #get the RSF parameters and variables
  layers <-parm_list[,"layer_uni"][-1] #-1 removes the intercept # WHAT IS layer_uni??? # WHY REMOVE INTERCEPT? - SHOULD BE IN RSPF
  beta <-parm_list[,"beta"]
  #These names need to match the names in rsfcovar_moose_chilcotin -- this means different columns for each standardized variable...
  #set the names of the fake.dt to the names of variables used in the RSF
  setnames(fake.dt, sprintf("x%s",seq(1:nrow(layers))), layers$layer_uni)
  #Fit a 'fake' model to get the class inheritance of glm
  suppressWarnings(lmFit <-glm(paste("y~", paste(layers$layer_uni, sep = "' '", collapse= "+")),family=binomial(link='logit'), data = fake.dt))
  #Hack the coefficients list so that the glm object uses these coefficents
  lmFit$coefficients <- beta$beta
  
  return(lmFit)
}



completeDTZeros = function (DT) { #Sets all of the data.table columns that have NA to zero
  for (i in names(DT)) DT[is.na(get(i)), (i):=0] # Incomplete??
}

rsfCLUS.checkRasters <- function(sim) {
#----Plotting the raster---
  for(layer in colnames(sim$rsfcovar)){
    message(paste0("plotting", layer))
    distRas<-sim$ras 
    test<-parse(text = paste0("sim$rsfcovar_moose_chilcotin$",layer))
    distRas[]<-eval(test)
    writeRaster(distRas, paste0(layer, ".tif"), overwrite = TRUE)
  }

#--------------------------
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  return(invisible(sim))
}