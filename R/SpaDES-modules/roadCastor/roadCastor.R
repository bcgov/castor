# Copyright 2023 Province of British Columbia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#===========================================================================================#
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

#===========================================================================================#

defineModule(sim, list(
  name = "roadCastor",
  description = NA, #"Simulates strategic roads using a single target access problem following Anderson and Nelson 2004",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", roadCastor = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "roadCastor.Rmd"),
  reqdPkgs = list("raster", "sf", "latticeExtra", "SpaDES.tools", "rgeos", "RANN", "dplyr", "cppRouting"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter("roadMethod", "character", "pre", NA, NA, "This describes the method from which to simulate roads - default is snap."),
    defineParameter("simulationTimeStep", "numeric", 1, NA, NA, "This describes the simulation time step interval"),
    defineParameter("nameCostSurfaceRas", "character", "rast.rd_cost_surface", NA, NA, desc = "Name of the cost surface raster"),
    defineParameter("nameRoads", "character", "rast.crds_all", NA, NA, desc = "Name of the pre-roads raster and schema"),
    defineParameter("roadSeqInterval", "numeric", 1, NA, NA, "This describes the simulation time at which roads should be build"),
    defineParameter(".plotInitialTime", "numeric", 1, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", 1, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "logical", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    #expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput(objectName = "roadMethod", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "extent", objectClass ="list", desc = NA, sourceURL = NA),
    expectsInput(objectName = "boundaryInfo", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "nameRoads", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "nameCostSurfaceRas", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "bbox", objectClass ="numeric", desc = NA, sourceURL = NA),
    expectsInput(objectName = "landings", objectClass = "integer", desc = NA, sourceURL = NA),
    expectsInput(objectName = "harvestPixelList", objectClass = "data.table", desc = NA, sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "SpatRaster", desc = NA, sourceURL = NA),
    expectsInput(objectName = "roadSourceID", objectClass = "integer", desc = "The source used in Dijkstra's pre-solving approach", sourceURL = NA),
    expectsInput(objectName = "millLocations", objectClass = "data.table", desc = "The x, y location in BC Albers (epsg: 3005) that define forest processing facilities", sourceURL = NA),
    expectsInput(objectName = "updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA)
    
     ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = "road.type", objectClass = "SpatRaster", desc = "A raster of the roads by type; 0 = perm roads; >0 = distance to mill as crow flies"),
    createsOutput(objectName = "road.year", objectClass = "SpatRaster", desc = "A raster of the time period roads were used"),
    createsOutput(objectName = "roadslist", objectClass = "data.table", desc = "A table of the road segments for every pixel"),
    createsOutput(objectName = "perm.roads", objectClass = "integer", desc = "A vector of pixelids that correspond to permanent roads"),
    createsOutput(objectName = "nodes", objectClass = "integer", desc = "A vector of pixelids in the graph"),
    createsOutput(objectName = "node.coords", objectClass = "data.frame", desc = "A table of coordinates for each node"),
    createsOutput(objectName = "edges.weight", objectClass = "data.table", desc = "A table of the edges (to, from and weight) to build the network")
    
  )
))

doEvent.roadCastor = function(sim, eventTime, eventType, debug = FALSE) {
  #set.seed(sim$.seed)## set seed ??
  switch(
    eventType,
    init = {
      sim<-Init(sim) # Get the existing roads and if required, the cost surface and graph
      # schedule future event(s)
      sim <- scheduleEvent(sim, eventTime =  time(sim) + P(sim, "roadSeqInterval", "roadCastor"), "roadCastor", "buildRoads", 7)
      sim <- scheduleEvent(sim, eventTime = end(sim),  "roadCastor", "savePredRoads", eventPriority=9)
      
      if(!suppliedElsewhere("landings", sim)){ # Simulate random landings for running this module independently
        sim <- scheduleEvent(sim, eventTime = start(sim),  "roadCastor", "simLandings")
      }
    },
    
    plot = {
      sim <- plotRoads(sim)
    },
    
    savePredRoads = {
      sim <- saveRoads(sim)
    },
    
    buildRoads = { # Builds or simulates roads at the roading interval
      if(!is.null(sim$landings)){ #Check if there are cutblock landings to simulate roading
        switch(P(sim)$roadMethod,
            snap={ # Individually links landings to closest road segment with a straight line
              sim <- getClosestRoad(sim) # Uses nearest neighbour to find the closest road segement to the target
              sim <- buildSnapRoads(sim)
              sim <- updateRoadsTable(sim) # Updates the pixels table in castordb to the proper year that pixel was roaded
            },
            lcp ={ # Create a least-cost path on the fly -- updates the cost surface at each road interval
              sim <- getRoutes(sim)
              sim <- setEdges(sim)
              sim <- updateRoadsTable(sim)
            },
            mst ={ # Create a minimum spanning tree before least-cost paths -- updates the cost surface at each road interval
              sim <- mstSolve(sim)
              sim <- setEdges(sim)
              sim <- updateRoadsTable(sim)
            },
            pre ={ # Solve the road network initially -- assumes cost surface is static
              sim <- getRoadSegment(sim)
              sim <- updateRoadsTable(sim)
            }
        )
        sim <- scheduleEvent(sim, time(sim) + P(sim)$roadSeqInterval, "roadCastor", "buildRoads",7)
      }else{
        # Go on to the next time period to see if there are landings to build roads
        sim <- scheduleEvent(sim, time(sim) + P(sim)$roadSeqInterval, "roadCastor", "buildRoads",7)
      }
    },
    
    simLandings = {
      message("simulating random landings")
      sim$landings<-NULL
      sim<-randomLandings(sim)
    },
    
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

Init <- function(sim) {
  sim <- getExistingRoads(sim) # Get the existing roads. Runs RASTERCLIP2 if no roadyear in pixels. initializes rasters;road.year, road.type, road.status
  
  if(P(sim)$roadMethod == 'pre'){ # Pre-solve the road network
    #check to see if the roads list has been saved in the db
    if(length(dbGetQuery (sim$castordb, "SELECT name FROM sqlite_master WHERE type='table' AND name='roadslist';")$name) == 0){ #already built the roadslist
      sim <- getCostSurface(sim) # Get the cost surface
      sim <- setGraph(sim) # build the graph
      sim <- getGraph(sim) # build the graph
      sim <- preSolve(sim) # solve the graph with djikstras
      if(!is.null(sim$landings)){
        sim <- getRoadSegment(sim)
        sim <- addInitialRoadsTable(sim)
      }
    }else{
      sim$roadslist<-data.table(dbGetQuery(sim$castordb, "select * from roadslist;"))
    }
  }
  
  if(P(sim)$roadMethod %in% c('mst', 'lcp')){ #the other methods
    if(nrow(dbGetQuery(sim$castordb, "SELECT * FROM sqlite_master WHERE type = 'table' and name ='roadedges'")) == 0){
      message('Creating road network...')
      sim <- getCostSurface(sim) # Get the cost surface uses RASTER_CLIP2
      sim <- setGraph(sim) # build the graph
    }
    sim <- getGraph(sim)
  }
  return(invisible(sim))
}

plotRoads<-function(sim){
  Plot(sim$road.year, title = paste("Simulated Roads ", time(sim)))
  return(invisible(sim))
}

saveRoads<-function(sim){
  terra::writeRaster(sim$road.status, file = paste0 (sim$scenario$name, "_", sim$boundaryInfo[[3]][[1]],"_", P(sim, "roadMethod", "roadCastor"),"_status_", time(sim)*sim$updateInterval, ".tif"),  overwrite=TRUE)
  terra::writeRaster(sim$road.year, file = paste0 (sim$scenario$name, "_", sim$boundaryInfo[[3]][[1]],"_", P(sim, "roadMethod", "roadCastor"),"_year_", time(sim)*sim$updateInterval, ".tif"), overwrite=TRUE)
  return(invisible(sim))
}

### Get the rasterized roads layer
getExistingRoads <- function(sim) {
  #check to see if roads are in the castordb?
  ##check it a field already in sim$castordb?
  if(dbGetQuery (sim$castordb, "SELECT COUNT(*) as exists_check FROM pragma_table_info('pixels') WHERE name='roadyear';")$exists_check > 0){
    message("using already loaded roads")
  }else{
    message("getting roads")
    dbExecute(sim$castordb, "ALTER TABLE pixels ADD COLUMN roadyear integer;")
    dbExecute(sim$castordb, "ALTER TABLE pixels ADD COLUMN roadtype numeric;")
    dbExecute(sim$castordb, "ALTER TABLE pixels ADD COLUMN roadstatus integer;")
  
    if(!is.null(sim$boundaryInfo)){
      sim$road.type<-terra::rast(RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                            srcRaster= P(sim, "nameRoads", "roadCastor"), 
                            clipper=sim$boundaryInfo[[1]], 
                            geom= sim$boundaryInfo[[4]], 
                            where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                            conn=sim$dbCreds))
      sim$road.type[sim$road.type[] < 0]<-NA
      #Update the pixels table to set the roaded pixels
      roadUpdate<-data.table(V1= as.numeric(sim$road.type[])) #transpose then vectorize which matches the same order as adj
      roadUpdate[, pixelid := seq_len(.N)]
      roadUpdate<-roadUpdate[V1 >= 0,]
    } 
    
    if(!is.na(sim$extent[[1]])){
      # make an existing road through the center of the aoi
      roadUpdate<-data.table(pixelid = seq(from = as.integer(sim$extent[[1]]*(sim$extent[[1]]/2)), to= as.integer(sim$extent[[1]]*(sim$extent[[1]]/2) + sim$extent[[2]]), by=1), V1 = 0)
    }
    
    if(is.null(roadUpdate)){
      stop("roadUpdate is null")
    }
    
    #Set the road information in the castordb
    dbBegin(sim$castordb)
      rs<-dbSendQuery(sim$castordb, 'UPDATE pixels SET roadtype = :V1, roadyear = 0, roadstatus = 0 WHERE pixelid = :pixelid', roadUpdate)
    dbClearResult(rs)
    dbCommit(sim$castordb)  
      
    rm(roadUpdate)
    gc()
  }
    
  #Initialize the road rasters
  sim$road.type<-sim$ras
  sim$road.type[]<-dbGetQuery(sim$castordb, 'SELECT roadtype FROM pixels order by pixelid')$roadtype
  sim$road.year<-sim$ras
  sim$road.year[]<-dbGetQuery(sim$castordb, 'SELECT roadyear FROM pixels order by pixelid')$roadyear
  sim$road.status<-sim$ras
  sim$road.status[]<-dbGetQuery(sim$castordb, 'SELECT roadstatus FROM pixels order by pixelid')$roadstatus
    
  sim$paths.v<-NULL #set the placeholder for simulated paths
  sim$roadSegs<-NULL #set the placeholder for simulated paths
  #writeRaster(sim$road.type, file="roads_0.tif", format="GTiff", overwrite=TRUE)
  return(invisible(sim))
}

### Get the rasterized cost surface
getCostSurface<- function(sim){
  
  if(!is.null(sim$boundaryInfo)){
    rds<-sim$road.type #roads is the road type 0 = perm, > 0 is the distance as crow flies to mill.

    rds[rds > 0] <- 0 #convert the roads that are not 'pre' start time roads back to zero
    rds[is.na(rds)] <- 1
    
     #Add in the age to incentivize roads near older forest
    age<-sim$ras
    age[]<-abs(dbGetQuery(sim$castordb, "SELECT age from pixels order by pixelid;")$age)
    age[is.na(age)]<-0
    age[]<-(1-(1/(age + 1)))*1000
    
    costSurf<-terra::rast(RASTER_CLIP2(tmpRast =paste0('temp_', sample(1:10000, 1)), 
                           srcRaster=P(sim, "nameCostSurfaceRas", "roadCastor"), 
                           clipper=sim$boundaryInfo[[1]], 
                           geom=sim$boundaryInfo[[4]], 
                           where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                           conn=sim$dbCreds)) 
    sim$costSurface<-rds*((terra::resample(costSurf, sim$ras, method = 'bilinear')*288 + 3243) + age) #multiply the cost surface by the existing roads
    sim$costSurface[sim$costSurface == 0]<- 0.00000000001 #giving some weight to roaded areas
    #writeRaster(sim$costSurface, file="cost.tif", format="GTiff", overwrite=TRUE)
    
    rm(rds, costSurf, age)
    gc()
  }
  
  if(!is.na(sim$extent[[1]])){
    costSurface<-sim$ras
    costSurface[]<-dbGetQuery(sim$castordb, "SELECT height from pixels order by pixelid;")$height
    sim$costSurface<-costSurface
  }
  
  return(invisible(sim))
}

getClosestRoad <- function(sim){ #TODO: convert to terra
  message('getClosestRoad')
  
  sim$roads.close.XY<-NULL
  #roads.pts get updated to include new roads
  #roads.pts <- terra::as.points(sim$road.type, fun=function(x){x >= -1}) #gets the closest existing road 
  filterRas<-sim$road.type
  filterRas[filterRas < -1] <- NA
  roads.pts <- terra::crds(terra::as.points(filterRas))
  closest.roads.pts <-RANN::nn2(roads.pts, terra::xyFromCell(sim$ras, sim$landings), k =1) #package RANN function nn2 is much faster
  sim$roads.close.XY <- as.matrix(roads.pts[closest.roads.pts$nn.idx, 1:2,drop=F]) #this function returns a matrix of x, y coordinates corresponding to the closest road

  rm(roads.pts, closest.roads.pts)
  gc()
  return(invisible(sim))
}

buildSnapRoads <- function(sim){ #Deprecate this?
  message("build snap roads")

    rdptsXY<-data.frame(sim$roads.close.XY) #convert to a data.frame
    rdptsXY$id<-as.numeric(row.names(rdptsXY))
    landings<-data.frame(sim$landings)
    landings$id<-as.numeric(row.names(landings))
    coodMatrix<-rbind(rdptsXY,landings)
    coodMatrix$attr_data<-100
    mt<-st_as_sf(coodMatrix, coords=c("x","y"), crs = 3005)  %>% 
      group_by(as.integer(id)) %>% 
      summarize(m=mean(attr_data)) %>% 
      filter(st_is(. , "MULTIPOINT")) %>% # Fixed. returns an error because the nearest road point is the landing point.
      st_cast("LINESTRING")

    if(length(sf::st_is_empty(mt)) > 0){
      mt2<- sf::as_Spatial(mt$geometry) #needed to run velox -- doesn't have sf compatability
      sim$paths.v<-unlist(sim$rasVelo$extract(mt2), use.names = FALSE)
      sim$road.year[sim$ras[] %in% sim$paths.v] <- time(sim)*sim$updateInterval
    }
    
    rm(rdptsXY, landings, mt, coodMatrix)
    gc()
  
  return(invisible(sim))
}

updateRoadsTable <- function(sim){
  message('updateRoadsTable')
  roadUpdate<-data.table(sim$paths.v)
  
  if(nrow(roadUpdate) > 0){
    setnames(roadUpdate, "pixelid")
    roadUpdate[,roadyear := time(sim)*sim$updateInterval]
 
    dbBegin(sim$castordb)
      rs<-dbSendQuery(sim$castordb, 'UPDATE pixels SET roadyear = :roadyear WHERE pixelid = :pixelid', roadUpdate )
    dbClearResult(rs)
    dbCommit(sim$castordb)
  }
  roadUpdateAll<-data.table(sim$roadSegs)
  if(nrow(roadUpdateAll) > 0){
    setnames(roadUpdateAll, "pixelid")
    
    roadUpdateAll[,roadstatus := time(sim)*sim$updateInterval]
    
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, 'UPDATE pixels SET roadstatus = :roadstatus WHERE pixelid = :pixelid', roadUpdateAll )
    dbClearResult(rs)
    dbCommit(sim$castordb)
    
  }
  
  sim$paths.v<-NULL
  sim$roadSegs<-NULL
  return(invisible(sim))
}

###Set the graph for determining least cost paths
setGraph<- function(sim){
  message("...Building graph")
  #------get the adjacency using SpaDES function adj
  edges<-data.table(SpaDES.tools::adj(returnDT= TRUE, numCol = ncol(sim$ras), numCell=ncol(sim$ras)*nrow(sim$ras), 
                                      directions = 8, cells = 1:as.integer(ncol(sim$ras)*nrow(sim$ras))))
  
  edges[, to:= as.integer(to)]
  edges[, from:= as.integer(from)]
  edges[from < to, c("from", "to") := .(to, from)]
  edges<-unique(edges)
  
  #------prepare the cost surface raster
  weight<-data.table(c(t(terra::as.matrix(sim$costSurface)))) #transpose then vectorize which matches the same order as adj
  weight[, id := seq_len(.N)] #full list of the raster including the NA. get the id for ther verticies which is used to merge with the edge list from adj
  
  edges.w1<-merge(x=edges, y=weight, by.x= "from", by.y ="id") #merge in the weights from a cost surface
  setnames(edges.w1, c("from", "to", "w1")) #reformat
  edges.w2<-data.table::setDT(merge(x=edges.w1, y=weight, by.x= "to", by.y ="id"))#merge in the weights to a cost surface
  setnames(edges.w2, c("from", "to", "w1", "w2")) #reformat
  edges.w2$weight<-(edges.w2$w1 + edges.w2$w2)/2 #take the average cost between the two pixels
  
  #------get the edges list
  edges.weight<-edges.w2[complete.cases(edges.w2), c(1:2, 5)] #get rid of NAs caused by barriers. Drop the w1 and w2 costs.
  
  #------Find edge connections for the remaining network - create a loop between edge pixels
  #Find the connections between points outside the graph and create edges there. This will minimize the issues with disconnected graph components
  #Step 1: clip the road dataset and see which pixels are at the boundary
  #Step 2: create edges between these pixels ---mimick the connection to the rest of the network
  #step 3: Label the edges with the correct vertex name
  if(!is.null(sim$boundaryInfo)){
    bound.line<-getSpatialQuery(paste0("select st_boundary(",sim$boundaryInfo[[4]],") as geom from ",sim$boundaryInfo[[1]]," where 
    ",sim$boundaryInfo[[2]]," in ('",paste(sim$boundaryInfo[[3]], collapse = "', '") ,"')"), conn=sim$dbCreds)
    #A velox workaround. Testing below
    step.one<-terra::extract(sim$ras, terra::vect(bound.line), cells=TRUE, xy=FALSE, ID = FALSE)$lyr.1
    
    step.two<-data.table(dbGetQuery(sim$castordb, paste0("select pixelid, roadtype from pixels where roadtype >= 0 and 
                                                  pixelid in (",paste(step.one, collapse = ', '),")")))
    
    step.two.xy<-data.table (terra::xyFromCell(sim$ras, step.two$pixelid)) #Get the euclidean distance -- maybe this could be a pre-solved road network instead?
    step.two.xy[, id:= seq_len(.N)] # create a label (id) for each record to be able to join back
    
    if(!suppliedElsewhere(sim$roadSourceID)){
      sim$roadSourceID<-step.two[order(roadtype)][1]$pixelid #Assign the road source to any one of the perm roads
    }
    #Sequential Nearest Neighbour without replacement - find the closest pixel to create the loop
    edges.loop<-rbindlist(lapply(1:nrow(step.two.xy), function(i){
      if(nrow(step.two.xy) == i ){ #The last pixel needed to make the loop
        data.table(from = nrow(step.two.xy), to = 1, weight.V1 = 1)
      }else{
        nn.edges<-RANN::nn2(step.two.xy[id > i, c("x", "y")], step.two.xy[id == i, c("x", "y")], k=1)
        data.table(from = i, to = step.two.xy[ id > i,][as.integer(nn.edges$nn.idx),]$id, weight = nn.edges$nn.dists)
      }
    }))
    
    #Need link.cell to link the from, to id back to a vertex in the graph
    link.cell<-data.table(step.two$pixelid)  # get the pixel id which is the vertex name
    link.cell[, id:= seq_len(.N)] # create a lable id for each record
  
    #Few formatting steps to make the merge back to edges.weight (this matrix creates the graph)
    edges.loop<-merge(edges.loop, link.cell, by.x = "from", by.y="id" )
    edges.loop<-merge(edges.loop, link.cell, by.x = "to", by.y="id" )
    setnames(edges.loop, c("from", "to", "weight.V1", "V1.x", "V1.y"), c("a1", "a2", "weight", "from", "to"))
    edges.loop<-edges.loop[, c( "from", "to", "weight")]
    edges.weight<-rbindlist(list(edges.weight,edges.loop)) #combine the loop edges back into the graph -- doesn't add any verticies only edges.
  
    rm(bound.line, step.one, step.two.xy, link.cell)#remove unused objects
    gc() #garbage collection
  }else{ #Just pick a permanent road from the db
    if(!suppliedElsewhere(sim$roadSourceID)){
      sim$roadSourceID <- dbGetQuery(sim$castordb, "Select pixelid from pixels where roadtype = 0 limit 1")$pixelid
    }
  }
  
  #Take care of perm roads
  perms<-dbGetQuery(sim$castordb, paste0("Select pixelid from pixels where roadtype = 0 and pixelid != ",sim$roadSourceID,";"))$pixelid
 
  if(length(perms) > 0){
    edges.weight[to %in% perms, to:=sim$roadSourceID]
    edges.weight[from %in% perms, from:=sim$roadSourceID]
    edges.weight<-edges.weight[!(to==from),]
    edges.weight<-unique(edges.weight)
  }
 
  
  sim$g<-cppRouting::makegraph(edges.weight,directed=F) 
  #sim$g<-cppRouting::cpp_simplify(sim$g) #Removed nodes of interest see Issue #348
  
  graph.df<-cppRouting::to_df(sim$g)
  
  message("store edge list in castordb")
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS roadsource ( source integer)")
  dbExecute(sim$castordb, paste0("INSERT INTO roadsource  (source) values (", sim$roadSourceID,");"))
  
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS roadedges ( 'to' integer, 'from' integer,  'weight' numeric )")
  dbBegin(sim$castordb)
  rs<-dbSendQuery(sim$castordb, "INSERT INTO roadedges ('to' , 'from', 'weight') 
                      values (:to, :from, :dist);", graph.df)
  dbClearResult(rs)
  dbCommit(sim$castordb)
  
  #Uses the coordinates for the NBA* algorithm
  ids<-as.integer(unique(c(unique(graph.df$to), unique(graph.df$from))))
  coords<-data.table(id = ids, terra::xyFromCell(sim$ras, ids))
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS roadcoords ( id integer, x integer,  y integer )")
  dbBegin(sim$castordb)
  rs<-dbSendQuery(sim$castordb, "INSERT INTO roadcoords (id , x,  y) 
                      values (:id, :x, :y);", coords)
  dbClearResult(rs)
  dbCommit(sim$castordb)
  #------clean up
  #sim$g<-delete.vertices(sim$g, degree(sim$g) == 0) #remove non-connected verticies????
  rm(ids, coords, edges.weight,edges.w1,edges.w2, edges, weight,perms)#remove unused objects
  gc() #garbage collection
  return(invisible(sim))
}


getGraph<- function(sim){
  message("...getting graph")
  #------Get all the road data from the database
  sim$roadSourceID<-dbGetQuery(sim$castordb, "select source from roadsource limit 1;")$source
  sim$edges.weight<-data.table(dbGetQuery(sim$castordb, "select * from roadedges;"))
  sim$node.coords<-data.table(dbGetQuery(sim$castordb, "select * from roadcoords;"))
  
  #------make the cppRouting graph object
  sim$g<-cppRouting::makegraph(sim$edges.weight,directed=F, coords = sim$node.coords) #coordinates help find paths
  #sim$g<-cppRouting::cpp_simplify(sim$g) #this should already be simplified when it was created
  
  if(P(sim)$roadMethod %in% c('lcp', 'mst')){ #Need a vector of permanent roads for cases where the landing falls on one -- since these roads are simplified to a single pixel with many edges.
    sim$perm.roads<-dbGetQuery(sim$castordb, "select pixelid from pixels where roadtype = 0;")
    sim$nodes <-unique(c(sim$edges.weight$to, sim$edges.weight$from))
  }
  
  #------make the igraph -- TO BE DEPRECATED
  #sim$g.igraph<-graph.edgelist(as.matrix(sim$edges.weight)[,1:2], dir = FALSE) #create the graph using to and from columns. Requires a matrix input
  #E(sim$g.igraph)$weight<-as.matrix(sim$edges.weight)[,3]#assign weights to the graph. Requires a matrix input
    #set the names of the graph as the pixelids
  #sim$g.igraph<-sim$g.igraph %>% 
  #    set_vertex_attr("name", value = V(sim$g.igraph))
    
  #------simplify the graph
  #sim$g.igraph<-igraph::simplify(sim$g.igraph) #remove more edges then needed.
  #sim$g.igraph<-delete.vertices(simplify(sim$g.igraph), degree(sim$g.igraph)==0)

  return(invisible(sim))
} 

setEdges<- function(sim){ #Updates the graph to account for the new roads
  #------set the newly simulated roads to have a low weight
  sim$edges.weight[to %in% sim$paths.v & from %in% sim$paths.v, weight := 0.0000001] #assign a low cost to the newly made road
  #------make the cppRouting graph object
  sim$g <- cppRouting::makegraph(sim$edges.weight,directed=F, coords = sim$node.coords) #rebuild the cppRouting graph
  #sim$g <- cppRouting::cpp_simplify(sim$g) #KISS 
  return(invisible(sim))
} 


lcpList<- function(sim){##Get a list of paths from which there is a to and from point
  message('lcp List')
  paths.matrix<-cbind(sim$landings, terra::cellFromXY(sim$ras,sim$roads.close.XY ))
  sim$paths.list<-split(paths.matrix, 1:nrow(paths.matrix))
  rm(paths.matrix)
  gc()
  return(invisible(sim))
}

mstSolve <- function(sim){
  message('mstSolve')
  #------get the edge list between a permanent road and the landing
  if(nrow(sim$harvestPixelList)>0){
  landing.cell <- data.table(landings = sim$harvestPixelList[sim$harvestPixelList[, .I[which.min(dist)], by=blockid]$V1]$pixelid )[!(landings %in% sim$perm.roads$pixelid),][ landings %in% sim$nodes, ]
  #landing.cell <- data.table(landings = cellFromXY(sim$ras,sim$landings))[!(landings %in% sim$perm.roads$pixelid),] #remove landings on permanent roads
  weights.closest.rd <- cppRouting::get_distance_matrix(Graph=sim$g, 
                                  from=landing.cell$landings, 
                                  to=sim$roadSourceID, 
                                  allcores=FALSE)
  edge.list <- data.table(from= landing.cell$landings, to = sim$roadSourceID, weight = weights.closest.rd[,1])
 
  #------get the edge list between the closest landings
  message('...get nearest neighbours')
  #browser()
  if(nrow(landing.cell) > 1){
    nnlandings <- RANN::nn2(terra::xyFromCell(sim$ras, landing.cell$landings), k =2)
    edge.list.inner <- data.table(from= landing.cell$landings, id=nnlandings$nn.idx[,1], idnn =nnlandings$nn.idx[,2] )
    edge.list.outer <- data.table(to =edge.list.inner$from, id =edge.list.inner$idnn) 
    edge.list.nn <- merge(edge.list.inner, edge.list.outer, by.x = "id", by.y = "id")
    edge.list.nn <- edge.list.nn[from < to, c("from", "to") := .(to, from)][,c("to", 'from')]
    edge.list.nn <- unique(edge.list.nn)
    
    edge.list2 <- data.table(to = edge.list.nn$to, 
                            from = edge.list.nn$from, 
                            weight = cppRouting::get_distance_pair(Graph=sim$g, from=edge.list.nn$from,to=edge.list.nn$to, algorithm = "NBA",constant = 110/0.06, allcores=FALSE))
    
    message('...solve the mst')
    #------solve the mst
    edges.all <- rbindlist(list(edge.list, edge.list2), use.names=TRUE)
  }else{
    edges.all<-edge.list
  }
  
  edges.all<-edges.all[!is.na(weight),]
  gi.mst <- igraph::mst(graph_from_data_frame(edges.all, directed=FALSE))
  paths.matrix <- data.table(get.edgelist(gi.mst, names=TRUE)) #Is this getting the edgelist using the vertex ids -yes!
  #V1 = from, V2 = to...we set the 'to' using roadSourceID on line 506
  paths.matrix.tothers <- paths.matrix[!(V2==sim$roadSourceID), ]
  
  message('...getting paths')
  #------get the shortest paths
  if(nrow(paths.matrix) > 0){
    #The solution from the mst will inevitably contain paths from a landing to the existing road network (roadSourceID)...try to seperate those going to sourceID and those going to other locations. Can this have saving since only one destination?
    if(nrow(paths.matrix.tothers) > 0){
      toRoadSourceID<-unique(as.integer(cppRouting::get_multi_paths(Graph = sim$g, from = sim$roadSourceID, to=paths.matrix[V2==sim$roadSourceID,"V1"]$V1, long =T )$node))
      toOthers<-unique(as.integer(cppRouting::get_path_pair(Graph = sim$g, from = paths.matrix.tothers$V2, to=paths.matrix.tothers$V1 , algorithm = "NBA", constant = 110/0.06, long =T )$node))
      sim$roadSegs <- unique(c(toOthers, toRoadSourceID))
    }else{
      toRoadSourceID<-unique(as.integer(cppRouting::get_multi_paths(Graph = sim$g, from = sim$roadSourceID, to=paths.matrix[V2==sim$roadSourceID,"V1"]$V1, long =T )$node))
      sim$roadSegs <- unique(toRoadSourceID)
    }
    
    alreadyRoaded <- dbGetQuery(sim$castordb, paste0("SELECT pixelid from pixels where roadyear is not null and pixelid in (",paste(sim$roadSegs, collapse = ", "),")"))
    
    sim$paths.v <- sim$roadSegs[!(sim$roadSegs[] %in% alreadyRoaded$pixelid)]
    #update the raster
    sim$road.year[sim$ras[] %in% sim$paths.v] <- time(sim)*sim$updateInterval
    sim$road.status[sim$ras[] %in% sim$roadSegs] <- time(sim)*sim$updateInterval
    
    #------Clean up
    rm(landing.cell,weights.closest.rd,edge.list,edges.all,gi.mst,paths.matrix,toRoadSourceID,alreadyRoaded)
    gc()
  }
  }
  return(invisible(sim)) 
}

mstList<- function(sim){
  message('mstList')
  rd_pts<-terra::cellFromXY(sim$ras, sim$roads.close.XY )
  land_pts<-sim$landings

  paths.list<-data.table(land_pts=as.integer(land_pts), rd_pts=as.integer(rd_pts))
  
  cols<-c("land_pts","rd_pts")
  vert.lu<-vertex_attr(sim$g, 'name')
  paths.list[, (cols) := lapply(.SD, function(x){match(x, vert.lu)}), .SDcols = cols]
  
  paths.list<-paths.list[!(land_pts == rd_pts)]
  
  land.vert<-unique(unlist(paths.list[,1], use.names= FALSE))
  land.adj <- igraph::distances(sim$g, land.vert, land.vert)
  rownames(land.adj)<-land.vert # set the verticies names 
  colnames(land.adj)<-land.vert # set the verticies names 
  
  rd.vert<-unique(unlist(paths.list[,2], use.names= FALSE))
  rd.adj <- igraph::distances(sim$g, rd.vert, rd.vert)
  rownames(rd.adj)<-rd.vert # set the verticies names 
  colnames(rd.adj)<-rd.vert # set the verticies names 
  
  path.wts <- diag(igraph::distances(sim$g, v=unlist(paths.list[,2], use.names= FALSE), 
                                           to=unlist(paths.list[,1], use.names= FALSE)))
  
  message('build graph')
  land.g <- graph_from_adjacency_matrix(land.adj, weighted=TRUE, mode = "lower") # create a graph
  V(land.g)$name<-land.vert
  
  rd.g <- graph_from_adjacency_matrix(rd.adj, weighted=TRUE, mode = "lower") # create a graph
  V(rd.g)$name<-rd.vert
  
  full.g <- land.g + rd.g
  E(full.g)[]$weight <- c(E(land.g)[]$weight, E(rd.g)[]$weight)
  delete_edge_attr(full.g,"weight_1")
  delete_edge_attr(full.g,"weight_2")
  
  #need to convert paths.list to the vertex id in full.g
  vert.lu<-vertex_attr(full.g, 'name')
  paths.list[, (cols) := lapply(.SD, function(x){match(x, vert.lu)}), .SDcols = cols]
  
  mst.g <-  full.g + edges(as.vector(t(as.matrix(paths.list))), weight = path.wts)
  
  message('solve mst')
  mst.paths <- mst(mst.g, weighted=TRUE) # get the minimum spanning tree
  paths.matrix<-noquote(get.edgelist(mst.paths, names=TRUE)) #Is this getting the edgelist using the vertex ids -yes!
  class(paths.matrix) <- "numeric"
  
  message('remove redundant paths')
  paths.matrix<-data.table(
    cbind(!paths.matrix[, 1] %in% rd.vert, !paths.matrix[,2] %in% rd.vert, 
           paths.matrix[,1],paths.matrix[,2] ))[!(V1 == 0 & V2 == 0), 3:4] #Remove road to road shorestest paths. sim$roads.close.XY will give 
  message('convert to vertex names')
  cols<-c("V3","V4")
  paths.matrix[, (cols) := lapply(.SD, function(x){V(sim$g)$name[x]}), .SDcols = cols]
  
  message('send to shortest paths')
  sim$paths.list<-split(as.matrix(paths.matrix, use.names = FALSE), 1:nrow(paths.matrix)) # put the edge combinations in a list used for shortestPaths
  rm(mst.paths,mst.g, paths.matrix)
  gc()
  
  return(invisible(sim))
}

getRoutes<-function(sim){ #for graphs using cppRouting
  message("getRoutes")
  landing.cell <-data.table(landings = sim$landings)[!(landings %in% sim$perm.roads$pixelid),] #remove landings on permanent roads
  sim$roadSegs <-unique(as.integer(cppRouting::get_multi_paths(Graph = sim$g, from = sim$roadSourceID, to = landing.cell$landings, long =T )$node))
  alreadyRoaded <-dbGetQuery(sim$castordb, paste0("SELECT pixelid from pixels where roadyear is not null and pixelid in (",paste(sim$roadSegs, collapse = ", "),")"))
  
  sim$paths.v<-sim$roadSegs[!(sim$roadSegs[] %in% alreadyRoaded$pixelid)]
  #update the raster
  sim$road.year[sim$ras[] %in% sim$paths.v] <- time(sim)*sim$updateInterval
  sim$road.status[sim$ras[] %in% sim$roadSegs] <- time(sim)*sim$updateInterval
  return(invisible(sim))
}

getShortestPaths<- function(sim){
  message(paste0('shortestPaths for ', length(sim$paths.list)))
  
  sim$paths.list<-lapply(sim$paths.list, function(x) 
    cbind(as.integer(V(sim$g)[V(sim$g)$name == x[][1] ]),as.integer(V(sim$g)[V(sim$g)$name == x[][2] ]))
  )#paths.matrix is a vector of vertex ids

  #------finds the least cost paths between a list of two points
  if(length(sim$paths.list) > 0 ){
    paths<-unlist(lapply(sim$paths.list, function(x) get.shortest.paths(sim$g,  x[1], x[2], out = "both"))) #create a list of shortest paths
    #Do all at once? 
    #paths<-get.shortest.paths(sim$g,  sim$paths.list[1][1], sim$paths.list[2], out = "both") #create a list of shortest paths
    
    paths.e<-paths[grepl("epath",names(paths))]
    edge_attr(sim$g, index= E(sim$g)[E(sim$g) %in% paths.e], name= 'weight')<-0.001 #changes the cost(weight) associated with the edge that became a path (or road)
      
    sim$paths.v<-unlist(data.table(paths[grepl("vpath",names(paths))]),  use.names = FALSE)#save the verticies for mapping
    pths2<- V(sim$g)$name[V(sim$g) %in% sim$paths.v]
    sim$road.year[sim$ras[] %in% pths2] <- (time(sim)+1)
    
    sim$roads.close.XY<-NULL
    rm(paths.e, paths)
    gc()
  }
  
  return(invisible(sim))
}

randomLandings<-function(sim){
  sim$landings<-sample(1:ncell(sim$road.type), 5)
  return(invisible(sim))
}

preSolve<-function(sim){
  
  message("Pre-solving the roads")
  if(exists("histLandings", where = sim)){
    message("...using historical landings")
    targets <- unique(c(as.character(cellFromXY(raster(sim$ras), SpatialPoints(coords = as.matrix(sim$histLandings[,c(2,3)]), proj4string = CRS("+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0 +datum=NAD83
                          +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0")) )), 
                      dbGetQuery(sim$castordb, "SELECT landing FROM blocks WHERE landing NOT IN ( SELECT pixelid FROM pixels WHERE roadtype = 0)")$landing)) #Remove landings on permanent roads

  }else{
    #TODO: get the centroid instead of the maximum pixelid? This may involve having to convert to vector?
    targets <- unique(dbGetQuery(sim$castordb, "SELECT landing FROM blocks WHERE landing NOT IN ( SELECT pixelid FROM pixels WHERE roadtype = 0)")$landing) #Remove landings on permanent roads
  }
  
  #vert_graph <- as.character(igraph::V(sim$g)$name) # Need to remove thos targets that are not in the graph
  #real_targts <-vert_graph[vert_graph[] %in% as.character(targets)] # This removes cases where the border pixels are not included in the graph
  df<-to_df(sim$g)
  verts<-unique(c(unique(df$from), unique(df$to)))
  targets<-targets[(targets %in% verts)]
  #Solve Djkstra's for one source (random road location - most southern road?) to all possible targets. Then store the outcome into a list referenced by the target
  #pre.paths<-igraph::get.shortest.paths(sim$g, as.character(sim$roadSourceID), real_targts)
  pre.paths<-cppRouting::get_multi_paths(sim$g, sim$roadSourceID, targets)
  
  message("making road list")
  #TODO: Need a better data structure here. Minimize the size of string called road or the column road in roadslist -- ex. roads[ !(roads[] %in% oldroads)] - maybe not: using this as a year indicator?
  #sim$roadslist<-rbindlist(lapply(pre.paths$vpath ,function(x){
  #  data.table(landing = x[][]$name[length(x[][]$name)],road = toString(x[][]$name[]))
  #   }))
  sim$roadslist<-rbindlist(lapply(names(pre.paths[[1]]) , function(x){
    data.table(landing = as.integer(x), road = toString(pre.paths[[1]][[x]])) 
               }))
  # store roadslist in castordb
  message("store road list in castordb")
  dbExecute(sim$castordb, "CREATE TABLE IF NOT EXISTS roadslist ( landing integer,  road character )")
  dbBegin(sim$castordb)
  rs<-dbSendQuery(sim$castordb, "INSERT INTO roadslist (landing, road ) 
                      values (:landing, :road)", sim$roadslist)
  dbClearResult(rs)
  dbCommit(sim$castordb)
  
  rm(df, targets, verts, pre.paths)
  gc()
  return(invisible(sim)) 
}

getRoadSegment<-function(sim){
  message("getRoadSegment")
  #Convert the landings to pixelid's
  targets<-sim$landings #This is pixelid not XY as used in other roading methods
  sim$roadSegs<-unique(as.numeric(unlist(strsplit(sim$roadslist[landing %in% targets, ]$road, ","))))
  alreadyRoaded<-dbGetQuery(sim$castordb, paste0("SELECT pixelid from pixels where roadyear IS NOT NULL and pixelid in (",paste(sim$roadSegs, collapse = ", "),")"))
  
  sim$paths.v<-sim$roadSegs[!(sim$roadSegs[] %in% alreadyRoaded$pixelid)]
  
  #update the raster
  sim$road.year[sim$ras[] %in% sim$paths.v] <- time(sim)*sim$updateInterval
  sim$road.status[sim$ras[] %in% sim$roadSegs] <- time(sim)*sim$updateInterval
  
  return(invisible(sim)) 
}

addInitialRoadsTable<- function(sim) {
  roadUpdate<-data.table(sim$paths.v)
  if(nrow(roadUpdate) > 0){
    setnames(roadUpdate, "pixelid")
    roadUpdate[,roadyear := 0]
    message("Add initial roads")
    dbBegin(sim$castordb)
    rs<-dbSendQuery(sim$castordb, 'UPDATE pixels SET roadyear = :roadyear, roadstatus =0 WHERE pixelid = :pixelid', roadUpdate )
    dbClearResult(rs)
    dbCommit(sim$castordb)
  }
  sim$roadSegs<-NULL
  sim$paths.v<-NULL
  sim$landings<-NULL
  return(invisible(sim))
} 
  
.inputObjects <- function(sim) {
  if(!suppliedElsewhere("boundaryInfo", sim)){
    sim$boundaryInfo<-list("public.gcbp_carib_polygon","herd_name","Telkwa","geom")
  }
  if(!suppliedElsewhere("updateInterval", sim)){
    sim$updateInterval<-5
  }
  if(!suppliedElsewhere("millLocations", sim)){
    sim$millLocations<-data.table(xcoord = c(1322373.9568, 	1324957.4209, 	1322206.3159, 	1322295.259, 	1333548.6163, 	1322386.0292, 	1272798.8327, 	1273207.7498, 	1264993.8579, 	1311793.8064, 	1480577.0932, 	1482285.787, 	1409426.5902, 	1408130.0774, 	1214515.3307, 	1057796.9663, 	1061901.4467, 	1204737.5417, 	1682383.6918, 	1004904.1387, 	1032911.0686, 	1033879.7161, 	1035494.8789, 	1017403.4648, 	1051715.6828, 	1044380.036, 	1040322.5376, 	1049005.8341, 	1478060.3851, 	1612394.1342, 	1599660.0853, 	1600537.2354, 	1454059.9024, 	1442556.3237, 	1167836.9334, 	1165554.2276, 	1273921.4228, 	1277767.5099, 	1287853.034, 	1291996.381, 	1292727.8541, 	1292825.9666, 	1308343.3609, 	1491553.0493, 	1490888.3662, 	1071568.3786, 	1073681.1968, 	1173856.8824, 	1732441.1482, 	1694348.9341, 	1172526.3524, 	1357359.9894, 	1224751.2421, 	1223220.8503, 	1222969.2115, 	1277494.8323, 	1611135.4891, 	1161879.6331, 	1163991.0554, 	1790592.1735, 	1484963.0426, 	1492203.9491, 	1483918.8533, 	1118968.9866, 	1119392.6315, 	1254532.3742, 	1116042.9183, 	1323371.8006, 	1316907.3526, 	1081335.1979, 	1617030.8268, 	1780004.9889, 	1780330.1702, 	1182205.4693, 	1182244.1878, 	1626358.0746, 	1552634.928, 	1797583.8217, 	1645553.9203, 	1234976.7443, 	953471.2228, 	952920.3105, 	1704413.6075, 	1402513.6774, 	1394777.429, 	1395193.5495, 	1416616.9123, 	1473126.0444, 	870941.284600001, 	1161092.752, 	1159143.4975, 	1162457.1503, 	1140319.2908, 	1140303.7596, 	1243313.8363, 	1287097.2188, 	1733290.6535, 	1496449.131, 	1497484.9754, 	1511209.8361, 	1179881.8404, 	1181261.7978, 	1180133.2954, 	1503492.5017, 	1503057.6765, 	1260686.4469, 	1249834.7055, 	1250235.4326, 	1260812.6496, 	1260839.0418, 	1260532.7139, 	1260833.5266, 	1255595.5106, 	1250245.5369, 	1260727.0681, 	1384219.9869, 	1387730.4063, 	1642475.3969, 	1380545.346, 	1373110.8233, 	1373478.3996, 	1066609.4377, 	1524226.689, 	1524238.1885, 	1265173.1533, 	1274467.5889, 	1265205.4496, 	1265868.157, 	1265169.9193, 	1267153.9746, 	1270401.1863, 	1233981.7567, 	1589203.5673, 	1582778.4103, 	1151381.9115, 	1156300.7505, 	1154029.8114, 	1143362.7483, 	1151385.0204, 	1223518.3274, 	1463576.7901, 	1238424.9729, 	1086627.2847, 	1086787.716, 	1086712.6659, 	1087290.2841, 	1080081.6728, 	594067.5494, 	592819.985400001, 	1237745.4764, 	899104.261299999, 	895471.2105, 	895828.8544, 	927035.694599999, 	922177.2697, 	1181781.7961, 	1119388.2831, 	1103911.5503, 	1118318.4172, 	1217137.0564, 	1216381.9379, 	1206958.6313, 	1216196.0023, 	1213460.5536, 	1215496.8889, 	1216048.5619, 	1214583.5919, 	1214477.9618, 	1216389.5876, 	1213733.4525, 	1399323.7906, 	1414952.1842, 	1399251.1055, 	1108865.7536, 	1058086.5473, 	602517.6657, 	594245.537699999, 	1235439.9391, 	1234062.5426, 	1233430.9369, 	1233120.6301, 	1235418.7948, 	1234340.2439, 	1698421.3477, 	1545910.6096, 	1548482.1898, 	1551644.4167, 	1544382.424, 	1213480.6982, 	1212776.4002, 	1212348.6633, 	1212875.9847, 	1595212.7388, 	1636522.7704, 	1478476.4446, 	1477621.3246, 	1365720.2326, 	1166021.896, 	1732517.3814, 	1612882.3065, 	926600.677100001, 	925730.397600001, 	1232356.3585, 	1238931.2171, 	1228800.5702, 	1240771.8427, 	1232349.4232, 	1470152.6785, 	1469187.937, 	1105410.5137, 	1331438.4983, 	829996.310699999, 	839776.713400001, 	829198.3181, 	829604.3169, 	1454278.3785, 	1210435.6757, 	1210881.2946, 	1146174.5004, 	1109706.7761, 	1127351.5603, 	1127663.2018, 	1125079.5506, 	1479934.4043, 	1456151.5862, 	1261270.4838, 	1263905.4097, 	1260667.3965, 	1260426.5846, 	1265769.3077, 	1266216.1886, 	1260057.0913, 	1264569.4126, 	1687146.3882
), ycoord = c(748580.8345, 	749873.002800001, 	754388.2707, 	754659.730799999, 	738009.823000001, 	740014.115599999, 	450919.8149, 	450203.9641, 	462401.724199999, 	474226.8914, 	620280.524, 	626755.7764, 	701444.894400001, 	702407.9999, 	1060609.3979, 	540492.7755, 	533918.8574, 	535034.842, 	692470.073100001, 	1038621.5022, 	1020510.8864, 	1019932.8754, 	1017411.6571, 	1024029.715, 	555703.9756, 	566764.9047, 	571282.9059, 	562811.615599999, 	661174.6263, 	522907.0638, 	515061.8401, 	515113.1072, 	483534.350199999, 	680576.509099999, 	436518.143100001, 	435454.0045, 	1197944.4321, 	1200504.4956, 	466407.7456, 	467577.505999999, 	463844.0283, 	463867.112600001, 	684611.0483, 	603326.022, 	603596.849199999, 	516630.607799999, 	516646.804099999, 	418985.8069, 	545173.8356, 	498673.1447, 	432098.518999999, 	1213579.2776, 	466976.808499999, 	464647.9768, 	467017.7852, 	467795.225500001, 	757546.397299999, 	419783.4893, 	423179.431500001, 	533993.662699999, 	639621.945599999, 	640093.617900001, 	642143.6698, 	476103.966399999, 	475705.202299999, 	467049.966, 	1055700.9676, 	1261481.8203, 	1261590.2039, 	1007076.365, 	492921.787900001, 	543714.8149, 	543480.564300001, 	497271.353, 	497448.7259, 	739887.367799999, 	475113.5583, 	508804.668199999, 	550510.985099999, 	924752.3619, 	1042778.2957, 	1042878.0927, 	661088.1733, 	663906.7311, 	646289.568600001, 	646213.197000001, 	644109.337400001, 	564824.627599999, 	1125753.5199, 	445122.7435, 	445540.4, 	439978.358999999, 	426361.6776, 	426431.955800001, 	468233.7585, 	639326.9005, 	541499.0726, 	604386.0811, 	603830.6516, 	608700.566500001, 	1150697.7118, 	1149799.5497, 	1147355.9316, 	678627.5176, 	678455.774599999, 	469230.572799999, 	469617.041300001, 	469688.117900001, 	468512.9374, 	468643.786599999, 	468405.091700001, 	468756.9505, 	467915.284700001, 	469649.2403, 	468743.0342, 	940410.7401, 	938124.3061, 	621678.638499999, 	587502.0634, 	578964.0485, 	578373.221999999, 	533180.1252, 	470586.737500001, 	470571.383199999, 	471077.750399999, 	466113.3024, 	464619.5484, 	464361.9189, 	464619.1701, 	464048.98, 	464319.7925, 	594690.138900001, 	612553.8092, 	614951.222200001, 	460827.975, 	460234.3147, 	462200.531199999, 	462815.9341, 	460841.830700001, 	469856.8279, 	516565.9169, 	471930.1152, 	470943.700999999, 	466297.2136, 	468351.6231, 	471914.7521, 	477795.8791, 	983860.961200001, 	982145.298699999, 	475619.8112, 	631151.393100001, 	634422.524499999, 	634154.039899999, 	616728.5405, 	619024.3331, 	503837.377599999, 	530894.536699999, 	540485.6939, 	531556.8748, 	996028.1226, 	1004403.344, 	1000399.6476, 	1004311.5643, 	996081.9597, 	983947.802300001, 	1002202.006, 	988718.600299999, 	985689.972100001, 	996366.2074, 	987804.879899999, 	510189.5702, 	507554.679400001, 	510129.2985, 	476460.637800001, 	557585.6993, 	935554.4345, 	933915.1218, 	887914.3607, 	893347.777799999, 	895434.817, 	895168.33, 	893448.534299999, 	894720.283399999, 	672321.0436, 	694004.601500001, 	693129.0503, 	686166.9463, 	701044.6854, 	469076.837300001, 	469786.312200001, 	469686.8497, 	469810.9914, 	483572.6127, 	508445.5902, 	650859.2645, 	650612.126800001, 	652186.016899999, 	495498.0889, 	597372.594599999, 	528984.342900001, 	1084655.6388, 	1085219.9128, 	461412.9976, 	468967.9805, 	471692.6667, 	468440.4038, 	461501.519300001, 	665581.5288, 	663000.8957, 	758189.930600001, 	1251530.7054, 	1060566.1911, 	1053780.7214, 	1064955.401, 	1068688.0179, 	887765.2655, 	469756.546800001, 	469800.815300001, 	995861.8572, 	1003564.1834, 	1002815.6485, 	1002972.3452, 	1004245.0086, 	604002.3039, 	554482.6812, 	800684.6206, 	796819.401799999, 	801227.3168, 	801217.417400001, 	797424.335000001, 	774692.3751, 	801179.262599999, 	796788.035, 	508233.346899999
))
  }
  return(invisible(sim))
}

