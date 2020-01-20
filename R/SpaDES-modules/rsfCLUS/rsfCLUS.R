# Copyright 2020 Province of British Columbia
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
#TODO: Be able to change raster values according to the time of the simulation. A RasterUpdate table that stores rasters for linear interpolation?

defineModule(sim, list(
  name = "rsfCLUS",
  description = "This module calculates Resource Selection Functions (RSFs), i.e., 'a habitat quality indicator', for wildlife species (e.g., caribou, moose, wolves) throughout the simulation.", 
  keywords = NA, # c("insert key words here"),
  authors = c(
    person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
    person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
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
    defineParameter("calculateInterval", "numeric", 1, NA, NA, "The simulation time at which resource selection function are calculated"),
    defineParameter("checkRasters", "logical", FALSE, NA, NA, "TRUE forces the rsfCLUS to write the rasters to disk. For checking in a GIS"),
    defineParameter("writeRSFRasters", "logical", FALSE, NA, NA, "TRUE forces the rsfCLUS to write the predicted rasters For checking in a GIS"),
    defineParameter("criticalHabitatTable", "character", "99999", NA, NA, "The name of the look up table to convert raster values to critical habitat labels. The two values required are value (int) and crithab (chr)"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    expectsInput(objectName = "rsf_model_coeff", objectClass = "data.table", desc = 'A User supplied data.table, currently created in the .RMD file. Contains information on the RSF model, i.e., their coefficients values and names, spatial boundary definitions, and SQL statements for querying data.', sourceURL = NA),
    expectsInput("boundaryInfo", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "clusdb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the RSF', sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "RasterLayer", desc = "A raster object created in dataLoaderCLUS. It is a raster defining the area of analysis (e.g., supply blocks/TSAs).", sourceURL = NA),
    expectsInput(objectName = "pts", objectClass = "data.table", desc = "Centroid x,y locations of the ras.", sourceURL = NA),
    expectsInput("landings", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName ="scenario", objectClass ="data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName ="harvestUnits", objectClass = "RasterLayer", desc = 'The name of the scenario and its description', sourceURL = NA)
    
    ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = "rsf_aoi", objectClass = "logical", desc = "Used to determine if an RSF should be run."),
    createsOutput(objectName = "rsfCovar", objectClass = "data.table", desc = "Used in the RSQLite clusdb. Consists of covariates at each pixelid used to calculate the RSF."),
    createsOutput(objectName = "rsfGLM", objectClass = "list", desc = "Instantiated glm objects that describe the mathematical components of RSFs. Gets created at Init. Used to predict the rsf scores based on the rsfCovar values."),
    createsOutput(objectName = "rsf", objectClass = "data.table", desc = "Consists of summed predicted RSF scores for each critical habitat")
  )
))

doEvent.rsfCLUS = function(sim, eventTime, eventType) { # in this module there are two event types, init and calculate the RSF 
  switch (
    eventType,
    init = {
      sim <- rsfCLUS.Init (sim) # this function inits two new data.tables in the RSQLite db: rsfCovar and rsf; clips the RSF boundary by the analysis area boundary (e.g., TSA); then clips each RSF area to the area of analysis (e.g., TSA)
      if(sim$rsf_aoi){
        sim <- rsfCLUS.PredictRSF (sim) # this function predicts each uniuue RSF score at each applicable pixelid 
        sim <- scheduleEvent (sim, time(sim) + P(sim, "rsfCLUS", "calculateInterval"), "rsfCLUS", "calculateRSF", 8) # schedule the next calculate RSF event 
      }
    },
    
    calculateRSF = {
      sim <- rsfCLUS.UpdateRSFCovar(sim) # this function updates the 'updateabale' and 'distance to' covariates in the model by querying the 'pixels' table in the RSQLite db
      sim <- rsfCLUS.StandardizeDynamicRSFCovar(sim) # this function standardizes the RSF covariate values
      sim <- rsfCLUS.PredictRSF(sim) #  this function predicts each uniuue RSF score at each applicable pixelid as stores in the rsf object
      sim <- rsfCLUS.Save(sim) #this function saves and summarizes rsf predictions for a time step
      sim <- scheduleEvent(sim, time(sim) + P(sim, "rsfCLUS", "calculateInterval"), "rsfCLUS", "calculateRSF", 8) # schedule the next calculate RSF event 
    },
    
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

rsfCLUS.Init <- function(sim) { # NOTE: uses data.table package syntax
  
  if(nrow(scenario) == 0) { stop('Include a scenario description as a data.table object with columns: name, description')}
  
  rsf_model_coeff [, rsf:= do.call(paste0, list(collapse = "_", .BY)), by = c("species", "population", "season") ] # init a new column in rsf_model_coeff that is concatenated variable called 'rsf' that will report the species, population and season 
  rsf_model_coeff [layer != 'int', layer_uni:= do.call(paste, list(collapse = "_", .BY)), by = c("species", "population", "season", "layer") ] # creates a new column, 'layer_uni' concatenating species-pop-season-layer 
  sim$rsf <- data.table() #instantiate the data.table object for the rsf predictions
  
   
  if (nrow (dbGetQuery (sim$clusdb, "SELECT * FROM sqlite_master WHERE type = 'table' and name ='rsfcovar'")) == 0) { # if there is no rsfcovar table in the RSQLite db (i.e., nrow == 0)
      sim$rsfcovar <- data.table (sim$pts) # init the rsfcovar table with the 'pts' object from dataLoaderCLUS; consists of pixelid's and x,y location centroid of the pixel 
      # Set all the bounds
      rsf_list <- unique (rsf_model_coeff [, c("species", "population", "bounds")]) # create a list of unique species, population, boundary types
      for(k in 1:nrow (rsf_list)) { # loop through the unique list of boundaries
        message (rsf_list[k]$bounds) 
        bounds <- data.table (c (t (raster::as.matrix( 
              RASTER_CLIP2(tmpRast = P (sim, "dataLoaderCLUS", "nameBoundary"), srcRaster = paste0(rsf_list[k]$bounds), # for each unique spp-pop-boundary, clip each rsf boundary data, 'bounds' (e.g., rast.du6_bounds)
                     clipper = sim$boundaryInfo[[1]],  # by the area of analysis (e.g., supply block/TSA)
                     geom = sim$boundaryInfo[[4]], 
                     where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                     conn = NULL)))))
        bounds[,V1:=as.integer(V1)] #make an integer for merging the values
        bounds[,pixelid:=seq_len(.N)]#make a unique id to ensure it merges correctly with rsfcovar
        if(nrow(bounds[!is.na(V1),]) > 0){
          if(!(P(sim, "rsfCLUS", "criticalHabitatTable") == '99999')){
            crit_lu<-data.table(getTableQuery(paste0("SELECT cast(value as int) , crithab FROM ",P(sim, "rsfCLUS", "criticalHabitatTable"))))
            bounds<-merge(bounds, crit_lu, by.x = "V1", by.y = "value", all.x = TRUE)
          }else{
            stop(paste0("ERROR: need to supply a lookup table: ", P(sim, "rsfCLUS", "criticalHabitatTable")))
          }
        }else{
          message(paste0("bounds raster does not overlap with aoi"))
          sim$rsf_aoi<-FALSE
          break;
        }
        sim$rsf_aoi<-TRUE
        setorder(bounds, pixelid) #sort the bounds so that it will match the order of rsfcovar
        sim$rsfcovar[, (rsf_list[k]$population):= bounds$crithab] # take the clipped, transposed, raster of each clipped RSF area (default name defined as 'v1'), and create new column(s) in the rsfcovar table that indicates to which pixel each RSF applies (value = 1), or not (value = 0, NA)
      }
      
      if(sim$rsf_aoi){ #if the boundary overlaps with the study area boundary
        #NON RECLASS -STATIC
        # set the 'static' Covariates to the rsfcovar table that are NOt Reclass types
        static_list <- as.list (unlist (unique (rsf_model_coeff[static == 'Y' & layer != 'int' & type != 'RC',c("sql") ]), use.names = FALSE)) # create a list of sql statements for each unique coefficient (row) that is static and not the intercept  
        for (layer_name in static_list){ # loop through the list of static covariates
          message(layer_name) # declare each 'name' in the list
          # if the covariate is not a reclass type, clip the raster to the study area and convert the covariate values to a data.table
          layer<-data.table(c(t(raster::as.matrix(
                RASTER_CLIP2(tmpRast = P (sim, "dataLoaderCLUS", "nameBoundary"), 
                             srcRaster= layer_name, 
                         clipper=sim$boundaryInfo[[1]], 
                         geom= sim$boundaryInfo[[4]], 
                         where_clause =  paste0(sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                         conn=NULL)))))
          
          sim$rsfcovar[, (layer_name):= layer$V1] # attach each covariate data.table to the rsfCovar table in the clusdb. The name is the text in column sql. Note this changes later on in standardize method
        }
        #RECLASS -STATIC
        # set the 'static' Covariates to the rsfcovar table that are Reclass types. This also involves changing the sql column to the text in layer_uni. This is needed to ensure the standardize method works
        static_rc_list <- as.list (rsf_model_coeff[static == 'Y' & layer != 'int' & type == 'RC', layer_uni ]) # create a list of sql statements for each unique coefficient (row) that is static and not the intercept  
        for(layer_name in static_rc_list){
          message(layer_name) # declare each 'name' in the list
          rClass_raster<-rsf_model_coeff[layer_uni == layer_name, sql]
          rclass_text <- rsf_model_coeff[layer_uni == layer_name, reclass] # create a table of the reclass SQL statement
          layer <- data.table(c(t(raster::as.matrix( # create a data.table of the transposed raster of each reclass
              RASTER_CLIP_CAT(tmpRast = P (sim, "dataLoaderCLUS", "nameBoundary"), 
                              srcRaster = rClass_raster, # clip the RC raster to the study area and reclassify it using the reclass SQL statement and convert the covariate values to a data.table
                              clipper = sim$boundaryInfo[[1]], 
                              geom = sim$boundaryInfo[[4]], 
                              where_clause =  paste0(sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                              out_reclass = rclass_text,
                              conn=NULL)))))
          layer[is.na(V1), V1:=0] # Return a zero for the 0 reclass -- getting a NA instead of 0 for some reason???
          sim$rsfcovar[, (layer_name):= layer$V1] # attach each covariate data.table to the rsfCovar table in the clusdb. The name is the text in column sql. Note this changes later on in standardize method
          #change the sql to equal the layer name
          rsf_model_coeff[layer_uni == layer_name , sql:=layer_name] #This is important to change the sql to the layer name because a unique name is needed in the standardize method
        }
        
      sim$rsf <- data.table() #instantiate the data.table object for the rsf predictions
      rsfCLUS.UpdateRSFCovar(sim) # update the 'dynmaic' Covariates to the rsfcovar table
  
      rsfCLUS.StandardizeStaticRSFCovar(sim) # function that standardizes the RSF covariate values
      rsfCLUS.StandardizeDynamicRSFCovar(sim) # function that standardizes the RSF covariate values
      rsfCLUS.StoreRSFCovar(sim) # function that stores the rsfcovar in the RSQLite clusdb for future use
      
      if(P(sim, "rsfCLUS", "checkRasters")){
        sim <- rsfCLUS.checkRasters(sim)
      } 
    }
      
  }else{ # if there is already an rsfcovar data.table in the RSQLite db then grab the table and load it into the sim
    message('...getting rsfcovar')
    sim$rsfcovar<-data.table(dbGetQuery(sim$clusdb, "SELECT * FROM rsfcovar"))
    sim$rsf_aoi<-TRUE
  }
  
  if(sim$rsf_aoi){
    #Set the GLM objects so that inherits class 'glm' which is needed for predict.glm function/method
    rsf_list<-lapply(as.list(unique(rsf_model_coeff[,"rsf"])$rsf), function(x) {#prepare the list needed for lapply to get the glm objects  
      rsf_model_coeff[rsf==x, c("rsf","beta", "layer_uni", "mean", "sdev")]
    })
    sim$rsfGLM<-lapply(rsf_list, getglmobj)#init the glm objects for each of the rsf population and season
  }
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
  up_layers<-paste(unlist(unique(rsf_model_coeff[static == 'N' & type == 'UP',"layer"]), use.names = FALSE), sep="' '", collapse=", ") # create a list of the unique updatebale variables
  if(!(up_layers=="")){
    newLayer<-data.table(dbGetQuery(sim$clusdb,paste0( "SELECT ", up_layers," FROM pixels ORDER BY pixelid"))) # loop through the list and query the 'pixels' table in the RSQLite db for each updateable variable
   
    test<-paste('newLayer$',colnames(newLayer), sep = '')
    test <- within(data.table(colnames(newLayer)),  equate <- paste(colnames(newLayer), test
                                                               , sep="=")) # concatenate two colums so that the new layer equals the old layer
    
    equals<-paste(test$equate, sep ="' '", collapse = ", ")
    assign<-parse(text=paste0("`:=`(",equals ,")"))
    print(is.data.table(sim$rsfcovar))
    sim$rsfcovar<-sim$rsfcovar[,eval(assign)] #Assign the new names with the imported (old) layers
    
    
    #sim$rsfcovar[, (colnames(newLayer)) := newLayer] # Attach those updatable varaibales to the rsfCover data.table; The '()' is need to evaluate the colnames function
    rm(newLayer)
    gc()
  }
  return(invisible(sim)) 
}

getDistanceToLayers<-function(sim){ #takes a sql statement and returns the distance to the result set generated by the sql
  #Get a list of the Distance To layers that are dynamic in the sim
  dt_layers<-as.list(unique(rsf_model_coeff[static =='N' & type == 'DT',c("species", "population", "sql", "layer", "mean", "sdev") ], by =c("species","population", "sql"))) # create a list of the unique 'distance to' variables
  #Get unique sql fields
  dt_sql<-unique(dt_layers$sql)
  
  if(length(dt_sql) > 0 ){
    for(i in 1:length(dt_sql)){ #Loop through each of the DT layers
      dt_select<-data.table(dbGetQuery(sim$clusdb, paste0("SELECT pixelid FROM pixels WHERE ", dt_sql[i]))) # loop through the list and query the 'pixels' table in the RSQLite db for each 'distance to' variable
      if(nrow(dt_select) > 0){ 
        print(paste0(dt_sql[i], ": TRUE"))
        dt_select[,field := 0]
        #outPts contains pixelid, x, y, field, population; sim$rsfcovar contains: pixelid, x,y, population
        outPts<-merge(sim$rsfcovar, dt_select, by = 'pixelid', all.x =TRUE) 
        #The number of Du's that use this layer. This calcs the Distance To using the boundary of the DU!
        dt_variable<-unique(rsf_model_coeff[sql == dt_sql[i]], by ="population") #population is used as the unique becuase it refers bounds
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
  }
  return(invisible(sim))
}

rsfCLUS.StandardizeStaticRSFCovar<-function(sim){
  message('standardizing static covariates')
  
  static_list<-rsf_model_coeff[static == 'Y' & layer != 'int' & sql != layer_uni] # Get the static list that are not RC. These don't get standardized
  static_list <- within(static_list,  equate <- paste(layer_uni, sql, sep="=")) # concatenate two colums so that the new layer equals the old layer
  
  static_equals<-paste(static_list$equate, sep ="' '", collapse = ", ")
  static_assign<-parse(text=paste0("`:=`(",static_equals ,")"))
  sim$rsfcovar[,eval(static_assign)] #Assign the new names with the imported (old) layers
 
  #select only the layers that need standarization
  static_list<-rsf_model_coeff[static == 'Y' & layer != 'int' & sql != layer_uni & mean !=0 & sdev!= 1,] 
  cm <- setNames(static_list$mean, static_list$layer_uni) #A named vector pertaining to the mean
  csd <- setNames(static_list$sdev, static_list$layer_uni) #A named vector pertaining to the standard deviation
  
  #Standardize the covariates
  for(j in static_list$layer_uni){
    #print(paste0(j, " mean:",cm[[j]], "std: ",csd[[j]]))
    set(sim$rsfcovar, i=NULL, j = j, value= (sim$rsfcovar[[j]] - cm[[j]] ) /csd[[j]] )
  }
  
  #Drop the unstandardized covars
  static_list<-rsf_model_coeff[static == 'Y' & layer != 'int' & sql != layer_uni,] 
  static_drop<-unique(static_list$sql)
  sim$rsfcovar<-sim$rsfcovar[,(static_drop):= NULL]
  
  return(invisible(sim))
}

rsfCLUS.StandardizeDynamicRSFCovar<-function(sim){
  message('standardizing dynamic covariates')
  dynamic_list<-rsf_model_coeff[static == 'N' & layer != 'int']
  
  if(nrow(dynamic_list) > 0){
    dynamic_list <- within(dynamic_list,  equate <- paste(layer_uni, layer, sep="=")) # concatenate two colums so that the new layer equals the old layer
  
    dynamic_equals<-paste(dynamic_list$equate, sep ="' '", collapse = ", ")
    dynamic_assign<-parse(text=paste0("`:=`(",dynamic_equals ,")"))
    sim$rsfcovar[,eval(dynamic_assign)] # Assign the new names with the imported (old) layers
  
    cm <- setNames(dynamic_list$mean, dynamic_list$layer_uni)#A named vector pertaining to the mean
    csd <- setNames(dynamic_list$sdev, dynamic_list$layer_uni) #A named vector pertaining to the standard deviation
  
    #Standardize the covariates
    for(j in dynamic_list$layer_uni){
      set(sim$rsfcovar, i=NULL, j = j, value= (sim$rsfcovar[[j]] - cm[[j]] ) /csd[[j]] )
    }
  
    #Drop the unstandardized covars
    dynamic_drop<-unique(dynamic_list$layer)
    sim$rsfcovar<-sim$rsfcovar[,(dynamic_drop):= NULL]
  }else{
    message('none')
  }
  return(invisible(sim))
}

rsfCLUS.StoreRSFCovar<- function(sim){
  message('storing covariates in rsfcovar table')
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
  print("done store")
  #print(dbGetQuery(sim$clusdb, "SELECT * from rsfcovar LIMIT 7"))
  return(invisible(sim))
}

getglmobj <-function(parm_list){ #creates a predict glm object for each rsf
  #Create a fake data.table with 30 vars --this can be more....Tyler's RSF models max out ~30
  fake.dt <-data.table(x1=runif(1000,0,1),x2=runif(1000,0,1),x3=runif(1000,0,1),x4=runif(1000,0,1),x5=runif(1000,0,1),
                       x6=runif(1000,0,1),x7=runif(1000,0,1),x8=runif(1000,0,1),x9=runif(1000,0,1),x10=runif(1000,0,1),
                       x11=runif(1000,0,1),x12=runif(1000,0,1),x13=runif(1000,0,1),x14=runif(1000,0,1),x15=runif(1000,0,1),
                       x16=runif(1000,0,1),x17=runif(1000,0,1),x18=runif(1000,0,1),x19=runif(1000,0,1),x20=runif(1000,0,1),
                       x21=runif(1000,0,1),x22=runif(1000,0,1),x23=runif(1000,0,1),x24=runif(1000,0,1),x25=runif(1000,0,1),
                       x26=runif(1000,0,1),x27=runif(1000,0,1),x28=runif(1000,0,1),x29=runif(1000,0,1),x30=runif(1000,0,1),
                       y=sample(c(0,1), replace=TRUE, size=1000))
  
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

rsfCLUS.checkRasters <- function(sim) {
#----Plotting the raster---
  for(layer in colnames(sim$rsfcovar)){
    message(paste0("ploting: ", layer))
    outRas<-sim$ras 
    test<-parse(text = paste0("sim$rsfcovar$",layer))
    if(is.character(eval(test))){
      test<-as.integer(as.factor(eval(test)))
      outRas[]<-test
    }else{
      outRas[]<-eval(test)
    }
    writeRaster(outRas, paste0(layer, ".tif"), overwrite = TRUE)
  }

#--------------------------
  return(invisible(sim))
}

rsfCLUS.PredictRSF <- function(sim){
  #Loop through each population and season to predict its resource selection probability at each applicable pixel
  message("predicting RSF")
  rsfPops<- unique(rsf_model_coeff[,c("rsf", "population")]) # list of unique RSFs (concatenated column created at init)
 
  for(i in 1:nrow(rsfPops)){ # for each unique RSF
    pred_rsf<-cbind(sim$rsfcovar[, paste0(rsfPops[[2]][[i]])], data.table(predict.glm(sim$rsfGLM[[i]], sim$rsfcovar, type = "response"))) # predict the rsf score using each glm object
    setnames(pred_rsf, c(paste0(rsfPops[[2]][[i]]) , paste0(rsfPops[[1]][[i]]))) # name each rsf prediction appropriately

    expr <- parse(text = paste0(rsfPops[[1]][[i]]))
    rsfdt<-data.table( pred_rsf[!is.na(eval(expr)),sum(eval(expr)), by = c(paste0(rsfPops[[2]][[i]]))])
    rsfdt[, timeperiod:=time(sim)]
    rsfdt[, rsf:=paste0(rsfPops[[1]][[i]])]
    setnames(rsfdt, c("critical_hab", "sum_rsf_hat", "timeperiod", "rsf_model"))
    rsfdt[, scenario:=scenario$name]
    rsfdt[, compartment :=  sim$boundaryInfo[[3]]]
    sim$rsf<-rbindlist(list(sim$rsf, rsfdt))

    if(P(sim, "rsfCLUS", "writeRSFRasters")){#----Plot the Raster---------------------------
      out.ras<-sim$ras
      out.ras[]<-unlist(pred_rsf[,eval(expr)], use.names = FALSE)
      writeRaster(out.ras, paste0(rsfPops[[1]][[i]],"_", time(sim), ".tif"), overwrite = TRUE)
      rm(out.ras)
    }#----------------------------------------------
    
    #Remove the prediction
    rm(pred_rsf)
  }
  
  
  return(invisible(sim))
}

rsfCLUS.Save<-function(sim){
  
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  return(invisible(sim))
}