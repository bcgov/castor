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
  name = "fireCastor",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Elizabeth", "Kleynhans", email = "elizabeth.kleynhans@gov.bc.ca", role = c("aut", "cre")),
              person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", fireCastor = "1.0.0"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "fireCastor.Rmd"),
  reqdPkgs = list("here","data.table", "raster", "SpaDES.tools", "tidyr"),
  parameters = rbind(
    defineParameter("criticalHabitatTable", "character", '99999', NA, NA, "Value attribute table that links to the raster and describes the boundaries of the critical habitat"),
    defineParameter("criticalHabRaster", "character", '99999', NA, NA, "Raster that describes the boundaries of the critical habitat"),
    defineParameter("calculateInterval", "numeric", 1, NA, NA, "The simulation time at which disturbance indicators are calculated"),
    defineParameter("permDisturbanceRaster", "character", '99999', NA, NA, "Raster of permanent disturbances"),
    defineParameter("recovery", "numeric", 40, NA, NA, "The age of recovery for disturbances"),
    defineParameter("distBuffer", "integer", 500, NA, NA, "The buffer for disturbances"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    #expectsInput(objectName = "disturbanceFlow", objectClass = "data.table", desc = "Time series table of annual area disturbed", sourceURL = NA),
    expectsInput(objectName = "boundaryInfo", objectClass = "character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "castordb", objectClass = "SQLiteConnection", desc = 'A database that stores dynamic variables used in the RSF', sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "RasterLayer", desc = "A raster object created in dataCastor. It is a raster defining the area of analysis (e.g., supply blocks/TSAs).", sourceURL = NA),
    expectsInput(objectName = "pts", objectClass = "data.table", desc = "Centroid x,y locations of the ras.", sourceURL = NA),
    expectsInput(objectName = "scenario", objectClass = "data.table", desc = 'The name of the scenario and its description', sourceURL = NA),
    expectsInput(objectName = "updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA)
    #expectsInput(objectName ="harvestPixelList", objectClass ="data.table", desc = 'The list of pixels being harvesting in a time period', sourceURL = NA)
  ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput("fire", "data.table", "Disturbance by fire table for every pixel"),
    createsOutput("fireReport", "data.table", "Summary per simulation period of the fire indicators")
  )
))

doEvent.fireCastor = function(sim, eventTime, eventType, debug = FALSE){
  switch(
    eventType,
    init = {
      sim <- Init (sim) # this function inits 
      sim <- createFireIgnitEscapeSpreadTable(sim) # create
      sim <- setFireIgnitEscapeSpreadTable(sim) #inserts values into the probability of ignition, escape, spread table
      sim <- scheduleEvent(sim, time(sim) , "fireCastor", "analysis", 9)

      # what is disturbance flow?
      if(nrow(sim$disturbanceFlow) > 0){
        ras.info<-dbGetQuery(sim$castordb, "Select * from raster_info limit 1;")
        
        sim$ignitRas<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0)
        sim$escapeRas<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0)
        sim$spreadRas<-raster(extent(ras.info$xmin, ras.info$xmax, ras.info$ymin, ras.info$ymax), nrow = ras.info$nrow, ncol = ras.info$ncell/ras.info$nrow, vals =0)
    
        sim$fireIgnitEscapeSpreadTable<-data.table(pixelid = as.integer(), mean = as.numeric(), sd = as.numeric(), period = as.integer(), flow = as.numeric(), count = as.numeric(), med = as.numeric(), total = as.numeric(), thlb = as.numeric() )
        
        #sim$spreadRas[]<-dbGetQuery(sim$castordb, "Select treed from pixels order by pixelid;")$treed
    sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "disturbanceCastor") , "disturbanceCastor", "disturbProcess", 9)
  }
  },

disturbProcess ={
  sim<-distProcess(sim)
  sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "disturbanceCastor"), "disturbanceCastor", "disturbProcess", 9)
  },

analysis = {
  sim <- distAnalysis(sim)
  sim <- scheduleEvent(sim, time(sim) + P(sim, "calculateInterval", "disturbanceCastor"), "disturbanceCastor", "analysis", 9)
},

warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
              "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  
  sim$fireReport<-data.table(scenario = character(), compartment = character(), 
                             timeperiod= integer(), critical_hab = character(), 
                             pixelid = integer(), number_sims = numeric(), 
                             number_times_burned = numeric())
  sim$firedisturbance <- sim$pts
  
  # do I need to do this L104 - 198 of disturbanceCastor
  message("...Get the critical habitat")
  
 
  return(invisible(sim))
  
}

createFireIgnitEscapeSpreadTable<-function(sim){
  message("create probability of ignition, escape, and spread table")
  # need distance to road
  #climate
  #Vegetation
  #constant coefficients
  
  sim$ignitiontable<-data.table(dbGetQuery(sim$castordb, paste0( "SELECT pixelid, age, crownclosure, height, treed as bclcs_level_2, (case when ((",time(sim)*sim$updateInterval, " - roadstatus < ",P(sim, "recovery", "disturbanceCastor")," AND (roadtype != 0 OR roadtype IS NULL)) OR roadtype = 0) then 1 else 0 end) as road_dist FROM pixels;")))
  
  message("calculate distance to roads")
  outPts [road_dist > 0, field := 0] #note that outside critical_hab roads will impact this.
  nearNeigh_rds <- RANN::nn2(outPts[field == 0, c('x', 'y')], 
                             outPts[is.na(field), c('x', 'y')], 
                             k = 1)
  
  outPts<-outPts[is.na(field) , rds_dist := nearNeigh_rds$nn.dists] # assign the distances
  outPts[is.na(rds_dist), rds_dist:=0] # those that are the distance to pixels, assign

  ###########################  
  # I think I need to join this distance to raods back to my table somehow here. Think about it!
  ###########################
  
  message("get constant coefficients")
  # if(!(P(sim, "nameConstCoefLightning", "fireCastor") == '99999')){
  #   message(paste0('..getting constant coefficients for lightning: ',P(sim, "nameConstCoefLightning", "fireCastor")))
    cclightning<- data.table (cclightning =  RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                       srcRaster= "rast.const_coef_lightning_ignit",#P(sim, "nameConstCoefLightning", "fireCastor"), 
                                       clipper=sim$boundaryInfo[1] , 
                                       geom= sim$boundaryInfo[4] , 
                                       where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                       conn=NULL)[])
                              
cclightning[,pixelid:=seq_len(.N)]#make a unique id to ensure it merges correctly

sim$ignitiontable<-merge (sim$ignitiontable,
                          cclightning,
                          by.x = "pixelid",
                          by.y = "pixelid", 
                          all.x = T)

  
  
  
  
  sim$probIgnit<-sim$pts
  
  probIgnit<-dbGetQuery(mySim$castordb, "SELECT * FROM pixels limit 10;")
  
  
  #dbExecute(sim$castordb, "ALTER TABLE pixels ADD COLUMN blockid integer DEFAULT 0")
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS fire (pixelid integer, frt integer, bclcs_level_2 character, proj_age_1 numeric, proj_height numeric, crown_closure numeric, pct_dead numeric, 
            inventory_standard_cd character, non_productive_cd character,coast_interior_cd character, bclcs_level_1 character,  bclcs_level_3 character,  bclcs_level_5 character, land_cover_class_cd_1 character, bec_zone_code character, bec_subzone character, earliest_nonlogging_dist_type character, earliest_nonlogging_dist_date timestamp, )")
 
  
   
  dbExecute(castordb, paste0("CREATE TABLE fire as SELECT ", pzone,", ", pzone," as zoneid, avg(age) as age, avg(dist) as dist, avg(vol*thlb) as vol FROM pixels))
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS adjacentBlocks ( id integer PRIMARY KEY, adjblockid integer, blockid integer)")
  return(invisible(sim)) 
}

all.dist<-data.table(dbGetQuery(sim$castordb, paste0("SELECT age, blockid, (case when ((",time(sim)*sim$updateInterval, " - roadstatus < ",P(sim, "recovery", "disturbanceCastor")," AND (roadtype != 0 OR roadtype IS NULL)) OR roadtype = 0) then 1 else 0 end) as road_dist, pixelid FROM pixels WHERE perm_dist > 0 OR (blockid > 0 and age >= 0) OR (",time(sim)*sim$updateInterval, " - roadstatus < ", P(sim, "recovery", "disturbanceCastor")," AND (roadtype != 0 OR roadtype IS NULL)) OR roadtype = 0;")))

all.dist<-data.table(dbGetQuery(sim$castordb, paste0("SELECT age, blockid, (case when ((",time(sim)*sim$updateInterval, " - roadstatus < ",P(sim, "recovery", "disturbanceCastor")," AND (roadtype != 0 OR roadtype IS NULL)) OR roadtype = 0) then 1 else 0 end) as road_dist, pixelid FROM pixels WHERE perm_dist > 0 OR (blockid > 0 and age >= 0) OR (",time(sim)*sim$updateInterval, " - roadstatus < ", P(sim, "recovery", "disturbanceCastor")," AND (roadtype != 0 OR roadtype IS NULL)) OR roadtype = 0;")))


all.dist<-data.table(dbGetQuery(mySim$castordb, paste0("SELECT age, blockid, (case when ((roadtype != 0 OR roadtype IS NULL) OR roadtype = 0) then 1 else 0 end) as road_disturbance, pixelid FROM pixels WHERE perm_dist > 0 OR (blockid > 0 and age >= 0) OR 1 - roadstatus < 300;")))


all.dat<-data.table(dbGetQuery(mySim$castordb, paste0("SELECT age, height, (case when ((roadtype != 0 OR roadtype IS NULL) OR roadtype = 0) then 1 else 0 end) as road_disturbance, pixelid FROM pixels WHERE perm_dist > 0 OR (blockid > 0 and age >= 0) OR 1 - roadstatus < 300;")))

dbGetQuery(mySim$castordb, "SELECT * FROM pixels limit 10;")




createFiresTable<-function(sim){
  message("create fireid and fires and adjacentBlocks")
  dbExecute(sim$castordb, "ALTER TABLE pixels ADD COLUMN blockid integer DEFAULT 0")
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS blocks ( blockid integer DEFAULT 0, age integer, height numeric, vol numeric, salvage_vol numeric, dist numeric DEFAULT 0, landing integer)")
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS adjacentBlocks ( id integer PRIMARY KEY, adjblockid integer, blockid integer)")
  return(invisible(sim)) 
}

getExistingCutblocks<-function(sim){
  
  if(!(P(sim, "nameCutblockRaster", "blockingCastor") == '99999')){
    message(paste0('..getting cutblocks: ',P(sim, "nameCutblockRaster", "blockingCastor")))
    ras.blk<- terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                       srcRaster= P(sim, "nameCutblockRaster", "blockingCastor"), 
                                       clipper=sim$boundaryInfo[1] , 
                                       geom= sim$boundaryInfo[4] , 
                                       where_clause =  paste0(sim$boundaryInfo[2] , " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                       conn=NULL))
    if(terra::ext(sim$ras) == terra::ext(ras.blk)){
      exist_cutblocks<-data.table(blockid = as.integer(ras.blk[]))
      exist_cutblocks[, pixelid := seq_len(.N)][, blockid := as.integer(blockid)]
      exist_cutblocks<-exist_cutblocks[blockid > 0, ]
      
      #add to the castordb
      dbBegin(sim$castordb)
      rs<-dbSendQuery(sim$castordb, "Update pixels set blockid = :blockid where pixelid = :pixelid", exist_cutblocks)
      dbClearResult(rs)
      dbCommit(sim$castordb)
      
      sim$existBlockId<-dbGetQuery(sim$castordb, "Select max(blockid) from pixels")
      
      rm(ras.blk,exist_cutblocks)
      gc()
    }else{
      stop(paste0("ERROR: extents are not the same check -", P(sim, "nameCutblockRaster", "blockingCastor")))
    }
  }else{
    sim$existBlockId<-0
  }
  return(invisible(sim))
}

setBlocksTable <- function(sim) {
  message("set the blocks table")
  dbExecute(sim$castordb, paste0("UPDATE blocks SET vol = 0 WHERE vol IS NULL")) 
  dbExecute(sim$castordb, paste0("UPDATE blocks SET dist = 0 WHERE dist is NULL")) 
  # Use "(CASE WHEN min(dist) = dist THEN pixelid ELSE pixelid END) as landing" to get set landing as pixel
  
  dbExecute(sim$castordb, paste0("INSERT INTO blocks (blockid, age, height,  vol, salvage_vol, dist, landing)  
                    SELECT blockid, round(AVG(age),0) as age, AVG(height) as height, AVG(vol) as vol, AVG(salvage_vol) as salvage_vol, AVG(dist) as dist, (CASE WHEN min(dist) = dist THEN pixelid ELSE pixelid END) as landing
                                       FROM pixels WHERE blockid > 0 AND thlb > 0 GROUP BY blockid "))  
  
  dbExecute(sim$castordb, "CREATE INDEX index_blockid on blocks (blockid)")
  return(invisible(sim))
}

setHistoricalLandings <- function(sim) {
  land_pixels<-data.table(dbGetQuery(sim$castordb, paste0("select landing from blocks where blockid < ", sim$existBlockId)))
  #print (land_pixels)
  if(nrow(land_pixels) > 0 ){
    sim$landings <- land_pixels$landing
  }else{
    sim$landings <- NULL
  }
  
  return(invisible(sim))
}

setSpreadProb<- function(sim) {
  #Create a mask for the area of interst
  sim$aoi <- sim$ras #set the area of interest as the similarity raster
  sim$aoi[] <- as.numeric (unlist (dbGetQuery(sim$castordb, "SELECT thlb FROM pixels"))) # set as.numeric, else a data type issue error....
  sim$aoi[sim$aoi > 0] <- 1 # for those locations where the distance is thlb than 0 assign a 1
  sim$aoi <- terra::subst (sim$aoi, NA, 0) # for those locations where there is no thlb - they are NA, assign a 0
  
  sim$harvestUnits<-NULL
  
  if(!P(sim)$spreadProbRas == "99999"){
    #scale the spread probability raster so that the values are [0,1]
    sim$ras.spreadProbBlock<-terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                                                      srcRaster= P(sim, "spreadProbRas", "blockingCastor"), 
                                                      clipper = sim$boundaryInfo[[1]],  # by the area of analysis (e.g., supply block/TSA)
                                                      geom = sim$boundaryInfo[[4]], 
                                                      where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                                                      conn=NULL))
    sim$ras.spreadProbBlock<-1-(sim$ras.spreadProbBlocks - minValue(sim$ras.spreadProbBlock))/(maxValue(sim$ras.spreadProbBlock)-minValue(sim$ras.spreadProbBlock))
  }else{
    sim$ras.spreadProbBlock<-sim$aoi
  }
  
  return(invisible(sim))
}


preBlock <- function(sim) {
  
  edges<-sim$edgesAdj
  
  edges[, to := as.integer(to)]
  edges[, from := as.integer(from)]
  edges[from < to, c("from", "to") := .(to, from)] #find the duplicates. Since this is non-directional graph no need for weights in two directions
  edges<-unique(edges)#remove the duplicates
  
  weight<-data.table(dbGetQuery(sim$castordb, 'SELECT pixelid, crownclosure, height FROM pixels WHERE 
                                thlb > 0 AND blockid = 0;')) # convert to a data.table - faster for large objects than data.frame
  
  #scale the crownclosure and height between 0 and 1 to remove bias of distances towards a variable
  weight[, height:=scale(height)][, crownclosure:=scale(crownclosure)] #scale the variables
  
  #Get the inverse of the covariance-variance matrix or since its standardized correlation matrix
  covm<-solve(cov(weight[,c("crownclosure", "height")], use= 'complete.obs'))
  
  edges.w1<-merge(x=edges, y=weight, by.x= "from", by.y ="pixelid", all.x= TRUE) #merge in the weights from a cost surface
  setnames(edges.w1, c("from", "to", "w1_cc", "w1_ht"))  #reformat
  edges.w2<-data.table::setDT(merge(x=edges.w1, y=weight, by.x= "to", by.y ="pixelid", all.x= TRUE))#merge in the weights to a cost surface
  setnames(edges.w2, c("from", "to", "w1_cc", "w1_ht", "w2_cc", "w2_ht")) #reformat
  
  #edges.w2$weight<-abs(edges.w2$w2 - edges.w2$w1) #take the absolute cost between the two pixels
  edges.w2[, weight:= (w1_cc-w2_cc)*((w1_cc-w2_cc)*covm[1,1] + (w1_ht-w2_ht)*covm[1,2]) + 
             (w1_ht-w2_ht)*((w1_cc-w2_cc)*covm[2,1] + (w1_ht-w2_ht)*covm[2,2]) + runif(nrow(edges.w2), 0, 0.0001)] #take the mahalanobis distance between the two pixels
  #Note for the mahalanobis distance sum of d standard normal random variables has Chi-Square distribution with d degrees of freedom
  
  #------get the edges list
  edges.weight<-edges.w2[complete.cases(edges.w2), c("from", "to", "weight")] #get rid of NAs caused by barriers. Drop the w1 and w2 costs.
  edges.weight<-as.matrix(edges.weight[, id := seq_len(.N)]) #set the ids of the edge list. Faster than using as.integer(row.names())
  
  #summary(edges.weight$weight)
  #------make the graph
  #g<-graph.lattice(c(nrow(sim$ras), ncol(sim$ras), 1))#instantiate the igraph object
  g<-graph.edgelist(edges.weight[,1:2], dir = FALSE) #create the graph using to and from columns. Requires a matrix input
  E(g)$weight<-edges.weight[,3]#assign weights to the graph. Requires a matrix input
  #V(g)$name<-V(g) #assigns the name of the vertex - useful for maintaining link with raster
  g<-g %>% 
    set_vertex_attr("name", value = V(g))
  g<-delete.vertices(g, degree(g) == 0) #not sure this is actually needed for speed gains? The problem here is that it may delete island pixels
  #test22<<-dbGetQuery(sim$castordb, "select pixelid from pixels where thlb > 0 AND blockid = 0 and zone1 = 22;")
  # stop()
  patchSizeZone<-dbGetQuery(sim$castordb, paste0("SELECT zone_column FROM zone where reference_zone = '",  P(sim, "patchZone", "blockingCastor"),"'"))
  if(nrow(patchSizeZone) == 0){
    stop(paste0("check ", P(sim, "patchZone", "blockingCastor")))
  }
  #only select those zones to apply constraints that actually have thlb in them.
  zones<-unname(unlist(dbGetQuery(sim$castordb, paste0("SELECT distinct(", patchSizeZone, ") FROM pixels WHERE 
                                 thlb > 0 AND ", patchSizeZone, " IS NOT NULL group by ", patchSizeZone)))) 
  resultset<-list() #create an empty resultset to be appended within the for loop
  islands<-list() #create an empty list to add pixels that are islands and don't connect to the graph
  
  for(zone in zones){
    message(paste0("loading--", zone))
    vertices<-data.table(dbGetQuery(sim$castordb,
                                    paste0("SELECT pixelid FROM pixels where thlb > 0 AND blockid = 0 and ", patchSizeZone, " = ", zone, ";")))
    
    islands_new<-vertices[!(pixelid %in% V(g)$name),] #check to make sure all the verticies are in the graph
    if(nrow(islands_new) > 0){
      vertices<-vertices[!(pixelid %in% unlist(islands_new, use.names = FALSE)),] #grab only the verticies that are in the graph -- this means verticies that are 'islands' are not included. These are added in later in the algorithm
      islands<-append(islands, islands_new)
    }
    
    #get the inputs for the forest_hierarchy java object as a list. This involves induced_subgraph
    g.sub<-induced_subgraph(g, vids = as.character(vertices$pixelid))
    #browser()
    if(length(V(g.sub)) > 1){
      lut<-data.table(verts = as_ids(V(g.sub)))[, ind := seq_len(.N)]
      g.sub2<-g.sub %>% set_vertex_attr("name", value = lut$ind)
      
      g.mst_sub<-mst(g.sub2, weighted=TRUE)
      #g.mst_sub<-delete.vertices(g.mst_sub, degree(g.mst_sub) == 0)
      
      
      paths.matrix<-data.table(cbind(noquote(get.edgelist(g.mst_sub)), E(g.mst_sub)$weight))
      paths.matrix[, V1 := as.integer(V1)][, V2 := as.integer(V2)]
      
      #get patch size distribution by natural disturbance type
      natDT <- dbGetQuery(sim$castordb,paste0("SELECT ndt, t_area FROM zoneConstraints WHERE reference_zone = '", P(sim, "patchZone", "blockingCastor"), "' AND zoneid = ", zone))
      targetNum <- sim$patchSizeDist[ndt == natDT$ndt, ] # get the target patchsize
      targetNum[,targetNum:= (natDT$t_area*freq)/sizeClass][,targetNum:= ceiling(targetNum)]
      
      #Adjust the target number based on the current distribution
      current.block.dist <- dbGetQuery(sim$castordb,paste0("SELECT blockid, count() as area FROM pixels WHERE ",patchSizeZone," = ", zone, " And blockid > 0 group by blockid;"))
      if(nrow(current.block.dist) > 0){
        currentNum <- data.table(sizeClass = targetNum$sizeClass)
        current.block.dist <- hist(current.block.dist$area, breaks = c(0, currentNum[max(sizeClass) == sizeClass, sizeClass:= 10000]$sizeClass), plot= F)$count
        patchDist <- list(targetNum$sizeClass , data.table(num = targetNum$targetNum - current.block.dist)[num<0,num:=0]$num)
      }else{
        patchDist <- list(targetNum$sizeClass ,  targetNum$targetNum )
      }
      #make list of blocking parameters
      if(nrow(paths.matrix) > 1){
        resultset <-append(resultset, list(list(as.matrix(degree(g.mst_sub)), paths.matrix, zone, patchDist, P(sim)$patchVariation, lut))) #the degree list (which is the number of connections to other pixels) and the edge list describing the to-from connections - with their weights
      }else{
        message(paste0(zone, " has length<1"))
      }
    }else{
      message(paste0(zone, " has length<0"))
      next
    }
  }
  
  #Run the forest_hierarchy java object in parallel. One for each 'zone'. This will maintain zone boundaries as block boundaries
  if(length(zones) > 1 && object.size(g) > 10000000000){ #0.1 GB
    noCores<-min(parallel::detectCores()-1, length(zones))
    message(paste0("make cluster on:", noCores, " cores"))
    #Set up the clusters
    cl<-makeCluster(noCores, type = "SOCK")
    clusterCall(cl, worker.init, c('data.table','rJava', 'jdx')) #instantiates a JVM on each core
    #apply the function to the clusters
    blockids<-parLapply(cl, resultset, getBlocksIDs)#runs in parallel using load balancing
    #remove the cluster
    stopCluster.default(cl)
  }else{
    options(java.parameters = "-Xmx2g")
    library(rJava) #Calling the rJava library instantiates the JVM. Note: cannot instantiate the same JVM on both the cores and the master. 
    library(jdx)
    message("running java on one cluster")
    blockids<-lapply(resultset, getBlocksIDs)
  }#blockids is a list of integers representing blockids and the corresponding vertex names (i.e., pixelid)
  
  rm(resultset, g, covm)
  gc()
  
  message("Updating blocks table")
  #Need to combine the results of blockids into castordb. Update the pixels table and populate the blockids
  lastBlockID <<- 0
  result<-lapply(blockids, function(x){
    test2<-x[][[1]][x[][[1]][,1]>-1,]
    
    if(lastBlockID > 0){
      test2[,1]<-test2[,1] + lastBlockID
    } 
    lastBlockID<<-max(test2[,1])
    test2
  })
  
  blockids <- data.table(Reduce(function(...) merge(..., all=T), result))#join the list components
  #Any blockids previously loaded - respect their values
  max_blockid<- dbGetQuery(sim$castordb, "SELECT max(blockid) FROM pixels")
  blockids[V1 > 0, V1:= V1 + as.integer(max_blockid)] #if there are previous blocks loaded-- it doesnt overwrite their ids
  
  #TODO:Add in any islands
  islands<-data.table(islands)
  islands<-islands[,num:=seq_len(.N)]
  print(islands)
  max_blockid<-max(blockids$V1)
  blockids<-blockids[V2 %in% unlist(islands$islands), V1:= num + as.integer(max_blockid)]
  
  #add to the castordb
  dbBegin(sim$castordb)
  rs<-dbSendQuery(sim$castordb, "Update pixels set blockid = :V1 where pixelid = :V2", blockids)
  dbClearResult(rs)
  dbCommit(sim$castordb)
  
  #store the block pixel raster
  sim$harvestUnits<-sim$ras
  sim$harvestUnits[]<- unlist(c(dbGetQuery(sim$castordb, 'Select blockid from pixels ORDER BY pixelid ASC')))
  
  terra::writeRaster(sim$harvestUnits, "hu.tif", overwrite = TRUE)
  #stop()
  rm(zones, result, blockids, max_blockid)
  gc()
  return(invisible(sim))
}

setAdjTable<-function(sim){
  #set the adjacency table
  blockids<-data.table(dbGetQuery(sim$castordb, "SELECT blockid, pixelid FROM pixels WHERE blockid > 0"))
  setkey(blockids, pixelid)
  edgesAdj<-merge(sim$edgesAdj, blockids,by.x="to", by.y="pixelid" )
  edgesAdj<-merge(edgesAdj, blockids,by.x="from", by.y="pixelid" )
  edgesAdj<-data.table(edgesAdj[,c("blockid.x","blockid.y")])
  edgesAdj<-edgesAdj[blockid.x  != blockid.y]
  edgesAdj<-edgesAdj[blockid.x  > 0 & blockid.y  > 0]
  edgesAdj<-unique(edgesAdj)
  setnames(edgesAdj, c("blockid", "adjblockid")) #reformat
  
  message("set the adjacency table")
  dbBegin(sim$castordb)
  rs<-dbSendQuery(sim$castordb, "INSERT INTO adjacentBlocks (blockid , adjblockid) VALUES (:blockid, :adjblockid)", edgesAdj)
  dbClearResult(rs)
  dbCommit(sim$castordb)
  
  dbExecute(sim$castordb, "CREATE INDEX index_adjblockid on adjacentBlocks (adjblockid)")
  
  return(invisible(sim))
}

spreadBlock<- function(sim) {
  if (!is.null(sim$landings)) {
    
    if(P(sim)$useLandingsArea){
      size<-sim$landingsArea
    }else{
      size<-as.integer(runif(length(landings), 20, 100))
    }
    
    landings<-terra::cellFromXY(sim$aoi, sim$landings)
    landings<-as.data.frame(cbind(landings, size))
    landings<-landings[!duplicated(landings$landings),]
    
    simBlocks<-SpaDES.tools::spread2(landscape=sim$aoi, spreadProb = sim$ras.spreadProbBlock, 
                                     start = landings[,1], directions =8, 
                                     maxSize= landings[,2], allowOverlap=FALSE)
    
    mV<-maxValue(simBlocks) 
    #update the aoi to remove areas that have already been spread to...?
    maskSimBlocks<-reclassify(simBlocks, matrix(cbind( NA, NA, 1, -1,0.5, 1, 0.5, mV + 1, 0), ncol =3, byrow =TRUE))
    sim$aoi<- sim$aoi*maskSimBlocks
    
    if(is.null(sim$harvestUnits)){ 
      simBlocks[is.na(simBlocks[])] <- 0
      sim$harvestUnits <- simBlocks #the first spreading event
      
    }else{
      simBlocks <- simBlocks + maxValue(sim$harvestUnits)
      simBlocks[is.na(simBlocks[])] <- 0
      sim$harvestUnits <- sim$harvestUnits +  simBlocks
    }
    rm( simBlocks, maskSimBlocks, landings, mV, size)
    gc()
  }
  return(invisible(sim))
}



updateBlocks<-function(sim){ #This function updates the block information used in summaries and for a queue
  message("update the blocks table")
  new_blocks<- data.table(dbGetQuery(sim$castordb, "SELECT blockid, round(AVG(age),0) as age , AVG(height) as height, AVG(vol) as vol, AVG(salvage_vol) as s_vol, AVG(dist) as dist
             FROM pixels WHERE blockid > 0 GROUP BY blockid;"))
  
  dbBegin(sim$castordb)
  rs<-dbSendQuery(sim$castordb, "UPDATE blocks SET age =  :age, height = :height, vol = :vol, salvage_vol = :s_vol, dist = :dist WHERE blockid = :blockid", new_blocks)
  dbClearResult(rs)
  dbCommit(sim$castordb)
  
  rm(new_blocks)
  gc()
  return(invisible(sim))
}

### additional functions
getBlocksIDs<- function(x){ 
  #---------------------------------------------------------------------------------#
  #This function uses resultset object as its input. 
  #The resultset object is a list of lists: 1.the degree list.
  #2. A list of edges (to and from) and weights; 3. The zone name; and
  #4. The patch size distribution. These are accessed via x[][[1-4]]
  #---------------------------------------------------------------------------------#
  message(paste0("getBlocksID for zone: ", x[][[3]])) #Let the user know what zone is being blocked
  
  .jinit(classpath= paste0(here::here(),"/Java/forest_blocking/bin"), parameters="-Xmx2g", force.init = TRUE) #instantiate the JVM
  fhClass<-.jnew("forest_hierarchy.Forest_Hierarchy") # creates a new forest hierarchy object in java
  
  dg<- data.table(cbind(as.integer(rownames(x[][[1]])),as.integer(x[][[1]]))) #Sets the degree list
  dg<- data.table(tidyr::complete(dg, V1= seq(1:as.integer(max(dg[,1]))),fill = list(V2 = as.integer(-1))))#this is needed for indexing
  #TODO: remove this index dependancy in java where the index refers to the pixelid.
  d<-convertToJava(as.integer(unlist(dg[,"V2"]))) #convert to a java object
  
  #Set the patchsize distribution as a java object
  h<-convertToJava(data.frame(size= x[][[4]][[1]], n = as.integer(x[][[4]][[2]])), array.order = "column-major", data.frame.row.major = TRUE)
  h<-rJava::.jcast(h, getJavaClassName(h), convert.array = TRUE)
  
  to<-.jarray(as.matrix(x[][[2]][,1])) #set the "to" list as a java object
  from<-.jarray(as.matrix(x[][[2]][,2]))#set the "from" list as a java object
  weight<-.jarray(as.matrix(x[][[2]][,3])) #set the "weight" list as a java object
  fhClass$setRParms(to, from, weight, d, h, x[][[5]]) # sets the input R parameters <Edges> <Degree> <Histogram> <variation>
  fhClass$blockEdges2() # builds the blocks
  #blockids<-cbind(convertToR(fhClass$getBlocks()), as.integer(unlist(dg[,1]))) #creates a link between pixelid and blockid
  blockids<-cbind(convertToR(fhClass$getBlocks()), as.integer(x[][[6]]$verts)) #creates a link between pixelid and blockid
  #stop()
  fhClass$clearInfo() #This method clears the object so it can be sent for garbage collection
  
  rm(fhClass, dg, h, to, from, weight) #remove from memory
  gc() #call garbage collection in R
  jgc() #call garbage collection in java
  
  list(blockids) #add the output of pixelid and the corresponding blockid in a list
}

worker.init <- function(packages) { #used for setting up the environments of the cores
  for (p in packages) {
    library(p, character.only=TRUE) #need character.only=TRUE to evaluate p as a character
  }
  NULL #return NULL to avoid sending unnecessary data back to the master process
}

jgc <- function() .jcall("java/lang/System", method = "gc")

binFreqTable <- function(x, bins) {
  freq = hist(x, breaks=c(0,bins, 100000), include.lowest=TRUE, plot=FALSE)
  ranges = paste(head(freq$breaks,-1), freq$breaks[-1], sep=" - ")
  return(data.frame(range = ranges, frequency = freq$counts))
}

.inputObjects <- function(sim) {
  if(!suppliedElsewhere("patchSizeDist", sim)){
    sim$patchSizeDist<- data.table(ndt= c(1,1,1,1,1,1,
                                          2,2,2,2,2,2,
                                          3,3,3,3,3,3,
                                          4,4,4,4,4,4,
                                          5,5,5,5,5,5,
                                          6,6,6,6,6,6,
                                          7,7,7,7,7,7,
                                          8,8,8,8,8,8,
                                          9,9,9,9,9,9,
                                          10,10,10,10,10,10,
                                          11,11,11,11,11,11,
                                          12,12,12,12,12,12,
                                          13,13,13,13,13,13,
                                          14,14,14,14,14,14), 
                                   sizeClass = c(40,80,120,160,200,240), 
                                   freq = c(0.3,0.3,0.1,0.1,0.1, 0.1,
                                            0.3,0.3,0.1,0.1,0.1, 0.1,
                                            0.2, 0.3, 0.125, 0.125, 0.125, 0.125,
                                            0.1,0.02,0.02,0.02,0.02,0.8,
                                            0.3,0.3,0.1,0.1,0.1, 0.1,
                                            0.1,0.05,0.2,0.2,0.2,0.25,
                                            0.2,0.1,0.2,0.2,0.2,0.1,
                                            0.05,0.05,0.1,0.1,0.3,0.4,
                                            0.05,0.05,0.1,0.2,0.3,0.3,
                                            0.2,0.1,0.1,0.2,0.2,0.4,
                                            0.05,0.05,0.1,0.1,0.1,0.6,
                                            0.2,0.1,0.2,0.2,0.2,0.1,
                                            0.2,0.1,0.2,0.2,0.2,0.1,
                                            0.2,0.1,0.2,0.2,0.2,0.1))
  }
  return(invisible(sim))
}
