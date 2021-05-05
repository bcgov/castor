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
# Everything in this file gets sourced during simInit, and all functions and objects
# are put into the simList. To use objects, use sim$xxx, and are thus globally available
# to all modules. Functions can be used without sim$ as they are namespaced, like functions
# in R packages. If exact location is required, functions will be: sim$<moduleName>$FunctionName

defineModule(sim, list(
  name = "roadCLUS",
  description = NA, #"Simulates strategic roads using a single target access problem following Anderson and Nelson 2004",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhly", email = "tyler.muhly@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.2.5", harvestCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "roadCLUS.Rmd"),
  reqdPkgs = list("raster", "sf", "latticeExtra", "SpaDES.tools", "rgeos", "velox", "RANN", "dplyr"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter("roadMethod", "character", "snap", NA, NA, "This describes the method from which to simulate roads - default is snap."),
    defineParameter("simulationTimeStep", "numeric", 1, NA, NA, "This describes the simulation time step interval"),
    defineParameter("nameCostSurfaceRas", "character", "rast.rd_cost_surface", NA, NA, desc = "Name of the cost surface raster"),
    defineParameter("nameRoads", "character", "rast.pre_roads", NA, NA, desc = "Name of the pre-roads raster and schema"),
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
    expectsInput(objectName = "boundaryInfo", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "nameRoads", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "nameCostSurfaceRas", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName = "bbox", objectClass ="numeric", desc = NA, sourceURL = NA),
    expectsInput(objectName = "landings", objectClass = "SpatialPoints", desc = NA, sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "raster", desc = NA, sourceURL = NA),
    expectsInput(objectName = "rasVelo", objectClass = "VeloxRaster", desc = NA, sourceURL = NA),
    expectsInput(objectName = "roadSourceID", objectClass = "integer", desc = "The source used in Dijkstra's pre-solving approach", sourceURL = NA),
    expectsInput(objectName = "updateInterval", objectClass ="numeric", desc = 'The length of the time period. Ex, 1 year, 5 year', sourceURL = NA)
    
     ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = "roads", objectClass = "RasterLayer", desc = "A raster of the roads"),
    createsOutput(objectName = "roadslist", objectClass = "data.table", desc = "A table of the road segments for every pixel")
  )
))

## event types
#   - type `init` is required for initialiazation

doEvent.roadCLUS = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    init = {
      sim<-Init(sim) # Get the existing roads and if required, the cost surface and graph
      ## set seed ??
      #set.seed(sim$.seed)
      
      # schedule future event(s)
      sim <- scheduleEvent(sim, eventTime =  time(sim) + P(sim, "roadCLUS", "roadSeqInterval"), "roadCLUS", "buildRoads", 7)
      sim <- scheduleEvent(sim, eventTime = end(sim),  "roadCLUS", "savePredRoads", eventPriority=9)
      
      if(!suppliedElsewhere("landings", sim)){ # Simulate random landings for running this module independently
        sim <- scheduleEvent(sim, eventTime = start(sim),  "roadCLUS", "simLandings")
      }
    },
    
    plot = {
      # do stuff for this event
      sim <- plotRoads(sim)
    },
    
    savePredRoads = {
      # do stuff for this event
      sim <- saveRoads(sim)
    },
    buildRoads = { # Builds or simulates roads at the roading interval
      if(!is.null(sim$landings)){ #Check if there are cutblock landings to simulate roading
        switch(P(sim)$roadMethod,
            snap={ # Individiually links landings to closest road segment with a straight line
              sim <- getClosestRoad(sim) # Uses nearest neighbour to find the closest road segement to the target
              sim <- buildSnapRoads(sim)
              sim <- updateRoadsTable(sim) # Updates the pixels table in clusdb to the proper year that pixel was roaded
            },
            lcp ={ # Create a least-cost path on the fly -- updates the cost surface at each road interval
              sim <- getClosestRoad(sim) 
              sim <- lcpList(sim) # Prepares the target and closest road information
              sim <- getShortestPaths(sim) # Uses Dijkstra to solve least cost paths -- includes update of the graph (sim$g)
              sim <- updateRoadsTable(sim)
            },
            mst ={ # Create a minimum spanning tree before least-cost paths -- updates the cost surface at each road interval
              sim <- getClosestRoad(sim)
              sim <- mstList(sim)# Construction of a minimum spanning tree to connect targets before connecting to exising road network
              sim <- getShortestPaths(sim)
              sim <- updateRoadsTable(sim)
            },
            pre ={ # Solve the road network initially -- assumes cost surface is static
              sim <- getRoadSegment(sim)
              sim <- updateRoadsTable(sim)
            }

        )
        
        sim <- scheduleEvent(sim, time(sim) + P(sim)$roadSeqInterval, "roadCLUS", "buildRoads",7)
      }else{
        # Go on to the next time period to see if there are landings to build roads
        sim <- scheduleEvent(sim, time(sim) + P(sim)$roadSeqInterval, "roadCLUS", "buildRoads",7)
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
  sim <- getExistingRoads(sim) # Get the existing roads
  
  if(P(sim)$roadMethod == 'pre'){ # Pre-solve the road network
    
    if(length(dbGetQuery (sim$clusdb, "SELECT name FROM sqlite_master WHERE type='table' AND name='roadslist';")$name) == 0){ #already built the roadslist
      sim <- getCostSurface(sim) # Get the cost surface
      sim <- getGraph(sim) # build the graph
      sim <- preSolve(sim)
      if(!is.null(sim$landings)){
        sim <- getRoadSegment(sim)
        sim <- addInitialRoadsTable(sim)
      }
    }else{
      sim$roadslist<-data.table(dbGetQuery(sim$clusdb, "select * from roadslist;"))
    }
  }
  
  if(P(sim)$roadMethod %in% c('mst', 'lst')){ #the other methods
    sim <- getCostSurface(sim) # Get the cost surface
    sim <- getGraph(sim) # build the graph
  }
  return(invisible(sim))
}

plotRoads<-function(sim){
  Plot(sim$roads, title = paste("Simulated Roads ", time(sim)))
  return(invisible(sim))
}

saveRoads<-function(sim){
  writeRaster(sim$roads, file=paste0(P(sim)$outputPath,  sim$boundaryInfo[[3]][[1]],"_",P(sim)$roadMethod,"_", time(sim)*sim$updateInterval, ".tif"), format="GTiff", overwrite=TRUE)
  return(invisible(sim))
}

### Get the rasterized roads layer
getExistingRoads <- function(sim) {
    if(nrow(dbGetQuery(sim$clusdb, 'SELECT roadyear FROM pixels where roadyear is not null limit 1')) > 0){
      message("using already loaded roads")
      sim$roads<-sim$ras
    }else{
      sim$roads<-RASTER_CLIP2(tmpRast = paste0('temp_', sample(1:10000, 1)), 
                            srcRaster= P(sim, "roadCLUS", "nameRoads"), 
                            clipper=sim$boundaryInfo[[1]], 
                            geom= sim$boundaryInfo[[4]], 
                            where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                            conn = NULL)
    
      #Update the pixels table to set the roaded pixels
      roadUpdate<-data.table(c(t(raster::as.matrix(sim$roads)))) #transpose then vectorize which matches the same order as adj
      roadUpdate[, pixelid := seq_len(.N)]
      roadUpdate<-roadUpdate[V1 > 0, roadyear := -1]

      #Set the road year
      dbBegin(sim$clusdb)
        rs<-dbSendQuery(sim$clusdb, 'UPDATE pixels SET roadyear = :roadyear WHERE pixelid = :pixelid', roadUpdate[,2:3]  )
      dbClearResult(rs)
      dbCommit(sim$clusdb)  
      
      rm(roadUpdate)
      gc()
    }
    
    sim$roads[]<-dbGetQuery(sim$clusdb, 'SELECT roadyear FROM pixels')$roadyear
    sim$paths.v<-NULL #set the placeholder for simulated paths
    #writeRaster(sim$roads, file="roads_0.tif", format="GTiff", overwrite=TRUE)
    
    #print(dbGetQuery(sim$clusdb, "SELECT * FROM pixels WHERE roadyear >=0 limit 1"))
    return(invisible(sim))
}

### Get the rasterized cost surface
getCostSurface<- function(sim){
  
  rds<-sim$roads
  rds[is.na(rds[])] <- 1
  rds[rds[] < 0] <-0 #convert the roads that are not 'pre' start time roads back to zero
  
  #conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
  costSurf<-RASTER_CLIP2(tmpRast =paste0('temp_', sample(1:10000, 1)), 
                         srcRaster=P(sim, "roadCLUS", "nameCostSurfaceRas"), 
                         clipper=sim$boundaryInfo[[1]], 
                         geom=sim$boundaryInfo[[4]], 
                         where_clause =  paste0 (sim$boundaryInfo[[2]], " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"),
                         conn = NULL) 
  sim$costSurface<-rds*(resample(costSurf, sim$ras, method = 'bilinear')*288 + 3243) #multiply the cost surface by the existing roads
  sim$costSurface[sim$costSurface[] == 0]<- 0.00000000001 #giving some weight to roaded areas
  
  #Add in the age
  age<-sim$ras
  age[]<-abs(dbGetQuery(sim$clusdb, "SELECT age from pixels order by pixelid;")$age)
  age[]<-(1/(age[] + 1))*800
  
  sim$costSurface <- sim$costSurface + age
  #writeRaster(sim$costSurface, file="cost.tif", format="GTiff", overwrite=TRUE)
  
  rm(rds,age, costSurf)
  gc()
  return(invisible(sim))
}

getClosestRoad <- function(sim){
  message('getClosestRoad')
  
  sim$roads.close.XY<-NULL
  roads.pts <- raster::rasterToPoints(sim$roads, fun=function(x){x >= -1})
  closest.roads.pts <-RANN::nn2(roads.pts[,1:2],coordinates(sim$landings), k =1) #package RANN function nn2 is much faster
  sim$roads.close.XY <- as.matrix(roads.pts[closest.roads.pts$nn.idx, 1:2,drop=F]) #this function returns a matrix of x, y coordinates corresponding to the closest road
  
  
  rm(roads.pts, closest.roads.pts)
  gc()
  return(invisible(sim))
}

buildSnapRoads <- function(sim){
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
      sim$roads[sim$ras[] %in% sim$paths.v] <- time(sim)*sim$updateInterval
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
 
    dbBegin(sim$clusdb)
      rs<-dbSendQuery(sim$clusdb, 'UPDATE pixels SET roadyear = :roadyear WHERE pixelid = :pixelid', roadUpdate )
    dbClearResult(rs)
    dbCommit(sim$clusdb)
  }
  
  sim$paths.v<-NULL
  return(invisible(sim))
}

###Set the grpah which determines least cost paths
getGraph<- function(sim){
  message("...Building graph")
  #------get the adjacency using SpaDES function adj
  edges<-data.table(SpaDES.tools::adj(returnDT= TRUE, numCol = ncol(sim$ras), numCell=ncol(sim$ras)*nrow(sim$ras), 
                                      directions = 8, cells = 1:as.integer(ncol(sim$ras)*nrow(sim$ras))))
  edges[, to:= as.integer(to)]
  edges[, from:= as.integer(from)]
  edges[from < to, c("from", "to") := .(to, from)]
  edges<-unique(edges)
  
  #------prepare the cost surface raster
  weight<-data.table(c(t(raster::as.matrix(sim$costSurface)))) #transpose then vectorize which matches the same order as adj
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
  
  bound.line<-getSpatialQuery(paste0("select st_boundary(",sim$boundaryInfo[[4]],") as geom from ",sim$boundaryInfo[[1]]," where 
  ",sim$boundaryInfo[[2]]," in ('",paste(sim$boundaryInfo[[3]], collapse = "', '") ,"')"))
 
 
 # bound.line_new<<-getSpatialQuery(paste0( "SELECT st_buffer(ST_Collect(ST_ExteriorRing(the_geom)), 10) AS erings
 # FROM (SELECT ",sim$boundaryInfo[[2]],", (ST_Dump(",sim$boundaryInfo[[4]],")).geom As the_geom
 #       FROM ",sim$boundaryInfo[[1]]," where 
 #       ",sim$boundaryInfo[[2]]," in ('",paste(sim$boundaryInfo[[3]], collapse = "', '") ,"')) As foo
  # GROUP BY ",sim$boundaryInfo[[2]],";"))
  #ras<<-sim$ras
  #rasVelo<<-sim$rasVelo
  #stop()
  #step.one<-data.table(c(t(raster::as.matrix(fasterize::fasterize(bound.line, sim$ras)))))[, pixelid := seq_len(.N)][V1==1,]$pixelid
  step.one<-unlist(sim$rasVelo$extract(bound.line), use.names = FALSE)
  
  
  step.two<-dbGetQuery(sim$clusdb, paste0("select pixelid from pixels where roadyear = -1 and 
                                                pixelid in (",paste(step.one, collapse = ', '),")"))
  
  step.two.xy<-data.table(xyFromCell(sim$ras, step.two$pixelid)) #Get the euclidean distance -- maybe this could be a pre-solved road network instead?
  step.two.xy[, id:= seq_len(.N)] # create a label (id) for each record to be bale to join back
  
  #Assign the road source the southern most pixelid?
  sim$roadSourceID<-min(step.two$pixelid)
  
  # Sequential Nearest Neighbour without replacement - find the closest pixel to create the loop
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
  
  #------make the graph
  #sim$g<-make_lattice(c(ncol(sim$ras), nrow(sim$ras)))#instantiate the igraph object
  sim$g<-graph.edgelist(as.matrix(edges.weight)[,1:2], dir = FALSE) #create the graph using to and from columns. Requires a matrix input
  E(sim$g)$weight<-as.matrix(edges.weight)[,3]#assign weights to the graph. Requires a matrix input
  #set the names of the graph as the pixelids
  sim$g<-sim$g %>% 
    set_vertex_attr("name", value = V(sim$g))
  
  #------clean up
  #sim$g<-delete.vertices(sim$g, degree(sim$g) == 0) #remove non-connected verticies????
  rm(edges.w1,edges.w2, edges, weight, bound.line, step.one, step.two.xy, link.cell)#remove unused objects
  gc() #garbage collection
  return(invisible(sim))
}

##Get a list of paths from which there is a to and from point
lcpList<- function(sim){
  message('lcp List')
  paths.matrix<-cbind(cellFromXY(sim$ras,sim$landings), cellFromXY(sim$ras,sim$roads.close.XY ))
  sim$paths.list<-split(paths.matrix, 1:nrow(paths.matrix))
  rm(paths.matrix)
  gc()
  return(invisible(sim))
}

mstList<- function(sim){
  message('mstList')
  rd_pts<-cellFromXY(sim$ras, sim$roads.close.XY )
  land_pts<-cellFromXY(sim$ras, sim$landings)

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
    sim$roads[sim$ras[] %in% pths2] <- (time(sim)+1)
    
    sim$roads.close.XY<-NULL
    rm(paths.e, paths)
    gc()
  }
  
  return(invisible(sim))
}

randomLandings<-function(sim){
  sim$landings<-xyFromCell(sim$roads, sample(1:ncell(sim$roads), 5), Spatial = TRUE)
  return(invisible(sim))
}

preSolve<-function(sim){
  message("Pre-solving the roads")
  if(exists("histLandings", where = sim)){
    message("...using historical landings")
    targets <- unique(as.character(cellFromXY(sim$ras, SpatialPoints(coords = as.matrix(sim$histLandings[,c(2,3)]), proj4string = CRS("+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0 +datum=NAD83
                          +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0")) )))
  }else{
    #TODO: get the centroid instead of the maximum pixelid? This may involve having to convert to vector?
    targets <- unique(dbGetQuery(sim$clusdb, "SELECT landing from blocks;")$landing)
  }
  
  #remove many of the isolated targets. Note that the vertex will change to start at 1 but since the names are set as pixelid it is ok. This is why I use as.character()
  #isolated = which(degree(sim$g)==0)
  #sim$g<-delete_vertices(sim$g, isolated)
  
  vert_graph <- as.character(igraph::V(sim$g)$name) # Need to remove thos targets that are not in the graph
  real_targts <-vert_graph[vert_graph[] %in% as.character(targets)] # This removes cases where the border pixels are not included in the graph

  #Solve Djkstra's for one source (random road location - most southern road?) to all possible targets. Then store the outcome into a list referenced by the target
  pre.paths<-igraph::get.shortest.paths(sim$g, as.character(sim$roadSourceID), real_targts)
  
  message("making road list")
  #TODO: Need a better data structure here. Minimize the size of string called road or the column road in roadslist -- ex. roads[ !(roads[] %in% oldroads)] - maybe not: using this as a year indicator?
  sim$roadslist<-rbindlist(lapply(pre.paths$vpath ,function(x){
    data.table(landing = x[][]$name[length(x[][]$name)],road = toString(x[][]$name[]))
     }))
  
  #TODO: store roadslist in clusdb
  message("store road list in clusdb")
  dbExecute(sim$clusdb, "CREATE TABLE IF NOT EXISTS roadslist ( landing integer,  road character )")
  dbBegin(sim$clusdb)
  rs<-dbSendQuery(sim$clusdb, "INSERT INTO roadslist (landing, road ) 
                      values (:landing, :road)", sim$roadslist)
  dbClearResult(rs)
  dbCommit(sim$clusdb)
  
  return(invisible(sim)) 
}

getRoadSegment<-function(sim){
  message("getRoadSegment")
  #Convert the landings to pixelid's
  targets<-cellFromXY(sim$ras, sim$landings)
  roadSegs<-unique(as.numeric(unlist(strsplit(sim$roadslist[landing %in% targets, ]$road, ","))))
  alreadyRoaded<-dbGetQuery(sim$clusdb, paste0("SELECT pixelid from pixels where roadyear >= 0 and pixelid in (",paste(roadSegs, collapse = ", "),")"))
  sim$paths.v<-roadSegs[!(roadSegs[] %in% alreadyRoaded$pixelid)]
  
  #update the raster
  sim$roads[sim$ras[] %in% sim$paths.v] <- time(sim)*sim$updateInterval
  return(invisible(sim)) 
}

addInitialRoadsTable<- function(sim) {
  roadUpdate<-data.table(sim$paths.v)
  if(nrow(roadUpdate) > 0){
    setnames(roadUpdate, "pixelid")
    roadUpdate[,roadyear := 0]
    message("Add initial roads")
    dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, 'UPDATE pixels SET roadyear = :roadyear WHERE pixelid = :pixelid', roadUpdate )
    dbClearResult(rs)
    dbCommit(sim$clusdb)
  }
  
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
  return(invisible(sim))
}

