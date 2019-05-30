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
# Everything in this file gets sourced during simInit, and all functions and objects
# are put into the simList. To use objects, use sim$xxx, and are thus globally available
# to all modules. Functions can be used without sim$ as they are namespaced, like functions
# in R packages. If exact location is required, functions will be: sim$<moduleName>$FunctionName

defineModule(sim, list(
  name = "roadCLUS",
  description = NA, #"Simulates strategic roads using a single target access problem following Anderson and Nelson 2004",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhley", email = "tyler.muhley@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.1.1", harvestCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "roadCLUS.Rmd"),
  reqdPkgs = list("raster", "sf", "latticeExtra", "SpaDES.tools", "rgeos", "velox", "RANN"),
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
    defineParameter(".useCache", "numeric", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    #expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput(objectName ="roadMethod", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName ="boundaryInfo", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName ="nameRoads", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName ="nameCostSurfaceRas", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput("bbox", objectClass ="numeric", desc = NA, sourceURL = NA),
    expectsInput(objectName = "landings", objectClass = "SpatialPoints", desc = NA, sourceURL = NA),
    expectsInput(objectName = "ras", objectClass = "raster", desc = NA, sourceURL = NA),
    expectsInput(objectName = "rasVelo", objectClass = "VeloxRaster", desc = NA, sourceURL = NA)
  ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = "roads", objectClass = "RasterLayer", desc = NA)
  )
))

## event types
#   - type `init` is required for initialiazation

doEvent.roadCLUS = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    init = {
      ### check for more detailed object dependencies:
      sim<-roadCLUS.Init(sim)
      ## set seed
      #set.seed(sim$.seed)
      if(P(sim)$roadMethod == 'pre'){
        sim <- roadCLUS.PreSolve(sim)
      }else{
      # schedule future event(s)
      sim <- scheduleEvent(sim, eventTime = start(sim), "roadCLUS", "buildRoads", 7)
      sim <- scheduleEvent(sim, eventTime = end(sim),  "roadCLUS", "save.sim", eventPriority=20)
      sim <- scheduleEvent(sim, eventTime = end(sim),  "roadCLUS", "plot.sim", eventPriority=21)
      }
      
      if(!suppliedElsewhere("landings", sim)){
        sim <- scheduleEvent(sim, eventTime = start(sim),  "roadCLUS", "simLandings")
      }
    },
    plot.sim = {
      # do stuff for this event
      sim <- roadCLUS.plot(sim)
    },
    save.sim = {
      # do stuff for this event
      sim <- roadCLUS.save(sim)
    },
    analysis.sim = {
      # do stuff for this event
      sim <- roadCLUS.analysis(sim)
    },
    
    buildRoads = {
      #Check if there are cutblock landings to simulate roading
      if(!is.null(sim$landings)){
        switch(P(sim)$roadMethod,
            snap= {
              sim <- roadCLUS.getClosestRoad(sim)
              sim <- roadCLUS.buildSnapRoads(sim)
              sim <- roadCLUS.updateRoadsTable(sim)
            } ,
            lcp ={
              sim <- roadCLUS.getClosestRoad(sim)
              sim <- roadCLUS.lcpList(sim)
              sim <- roadCLUS.shortestPaths(sim)# includes update graph 
              sim <- roadCLUS.updateRoadsTable(sim)
            },
            mst ={
              sim <- roadCLUS.getClosestRoad(sim)
              sim <- roadCLUS.mstList(sim)# will take more time than lcpList given the construction of a mst
              sim <- roadCLUS.shortestPaths(sim)# update graph is within the shorestPaths function
              sim <- roadCLUS.updateRoadsTable(sim)
            }

        )
        
        sim <- scheduleEvent(sim, time(sim) + P(sim)$roadSeqInterval, "roadCLUS", "buildRoads",7)
      }else{
        #go on to the next time period to see if there are landings to build roads
        sim <- scheduleEvent(sim, time(sim) + P(sim)$roadSeqInterval, "roadCLUS", "buildRoads",7)
      }
    },
    simLandings = {
      message("simulating random landings")
      sim$landings<-NULL
      sim<-roadCLUS.randomLandings(sim)
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

roadCLUS.Init <- function(sim) {
  sim <- roadCLUS.getRoads(sim) # Get the existing roads
  if(!P(sim)$roadMethod == 'snap'){
    sim <- roadCLUS.getCostSurface(sim) # Get the cost surface
    sim <- roadCLUS.getGraph(sim) # build the graph
  }
  return(invisible(sim))
}

roadCLUS.plot<-function(sim){
  Plot(sim$roads, title = paste("Simulated Roads ", time(sim)))
  return(invisible(sim))
}

roadCLUS.save<-function(sim){
  writeRaster(sim$roads, file=paste0(P(sim)$outputPath,  sim$boundaryInfo[[3]][[1]],"_",P(sim)$roadMethod,"_", time(sim), ".tif"), format="GTiff", overwrite=TRUE)
  return(invisible(sim))
}

### Get the rasterized roads layer
roadCLUS.getRoads <- function(sim) {
    sim$roads<-RASTER_CLIP2(srcRaster= P(sim, "roadCLUS", "nameRoads"), 
                            clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), 
                            geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), 
                            where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", paste(sim$boundaryInfo[[3]], sep = "' '", collapse= "'', ''") ,"'')"), conn=NULL)
    #Update the pixels table to set the roaded pixels
    roadUpdate<-data.table(c(t(raster::as.matrix(sim$roads)))) #transpose then vectorize which matches the same order as adj
    roadUpdate[, pixelid := seq_len(.N)]
    roadUpdate<-roadUpdate[V1 > 0, roadyear := 0]

    if(exists("clusdb", where = sim)){
      dbBegin(sim$clusdb)
        rs<-dbSendQuery(sim$clusdb, 'UPDATE pixels SET roadyear = :roadyear WHERE pixelid = :pixelid', roadUpdate[,2:3]  )
      dbClearResult(rs)
      dbCommit(sim$clusdb)

      roadpixels<-dbGetQuery(sim$clusdb, 'SELECT roadyear FROM pixels')
      sim$roads[]<-unlist(c(roadpixels), use.names =FALSE)
    }
    
    sim$paths.v<-NULL #set the placeholder for simulated paths
    
    rm(roadUpdate)
    gc()
    #print(dbGetQuery(sim$clusdb, "SELECT * FROM pixels WHERE roadyear >=0 limit 1"))
    return(invisible(sim))
}

### Get the rasterized cost surface
roadCLUS.getCostSurface<- function(sim){
  #rds<-raster::reclassify(sim$roads, c(-1,0,1, 0.000000000001, maxValue(sim$roads),0))# if greater than 0 than 0 if not 0 than 1;
  rds<-sim$roads
  rds[is.na(rds[])]<-1

  conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
  costSurf<-RASTER_CLIP2(srcRaster= P(sim, "roadCLUS", "nameCostSurfaceRas"), clipper=P(sim, "dataLoaderCLUS", "nameBoundaryFile"), geom= P(sim, "dataLoaderCLUS", "nameBoundaryGeom"), where_clause =  paste0(P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " in (''", P(sim, "dataLoaderCLUS", "nameBoundary"),"'')"), conn=conn) 
  sim$costSurface<-rds*(resample(costSurf, sim$ras, method = 'bilinear')*288 + 3243) #multiply the cost surface by the existing roads
  
  sim$costSurface[sim$costSurface[] == 0]<-0.00000000001 #giving some weight to roaded areas
  writeRaster(sim$costSurface, file="cost.tif", format="GTiff", overwrite=TRUE)
  
  rm(rds, costSurf)
  gc()
  return(invisible(sim))
}

roadCLUS.getClosestRoad <- function(sim){
  message('getClosestRoad')
  
  sim$roads.close.XY<-NULL
  roads.pts <- raster::rasterToPoints(sim$roads, fun=function(x){x >= 0})
  closest.roads.pts <-RANN::nn2(roads.pts[,1:2],coordinates(sim$landings), k =1) #package RANN function nn2()? - yes much faster
  sim$roads.close.XY <- as.matrix(roads.pts[closest.roads.pts$nn.idx, 1:2,drop=F]) #this function returns a matrix of x, y coordinates corresponding to the closest road
  
  rm(roads.pts, closest.roads.pts)
  gc()
  return(invisible(sim))
}

roadCLUS.buildSnapRoads <- function(sim){
  rdptsXY<-data.frame(sim$roads.close.XY) #convert to a data.frame
  rdptsXY$id<-as.numeric(row.names(rdptsXY))
  landings<-data.frame(sim$landings)
  landings$id<-as.numeric(row.names(landings))
  coodMatrix<-rbind(rdptsXY,landings)
  coodMatrix$attr_data<-100
  mt<-coodMatrix %>% 
    st_as_sf(coords=c("x","y"))%>% 
    group_by(id) %>% summarize(m=mean(attr_data)) %>% 
    st_cast("LINESTRING")
  sim$paths.v<-unlist(sim$rasVelo$extract(mt), use.names = FALSE)
  sim$roads[sim$ras[] %in% sim$paths.v] <- (time(sim)+1)
  rm(rdptsXY, landings, mt, coodMatrix)
  gc()
  return(invisible(sim))
}

roadCLUS.updateRoadsTable <- function(sim){
  message('updateRoadsTable')
  roadUpdate<-data.table(sim$paths.v)
  setnames(roadUpdate, "pixelid")
  roadUpdate[,roadyear := time(sim)+1]
  #TODO: Fix--> Some pixels will be over written - so the road year isn't accurate.
  dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, 'UPDATE pixels SET roadyear = :roadyear WHERE pixelid = :pixelid', roadUpdate )
  dbClearResult(rs)
  dbCommit(sim$clusdb)
  
  sim$paths.v<-NULL
  
  return(invisible(sim))
}

###Set the grpah which determines least cost paths
roadCLUS.getGraph<- function(sim){
  #------get the adjacency using SpaDES function adj
  edges<-data.table(SpaDES.tools::adj(returnDT= TRUE, numCol = ncol(sim$ras), numCell=ncol(sim$ras)*nrow(sim$ras), 
                                      directions = 4, cells = 1:as.integer(ncol(sim$ras)*nrow(sim$ras))))
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
  
  #------make the graph
  #sim$g<-make_lattice(c(ncol(sim$ras), nrow(sim$ras)))#instantiate the igraph object
  sim$g<-graph.edgelist(as.matrix(edges.weight)[,1:2], dir = FALSE) #create the graph using to and from columns. Requires a matrix input
  E(sim$g)$weight<-as.matrix(edges.weight)[,3]#assign weights to the graph. Requires a matrix input
  V(sim$g)$name<-V(sim$g)
  sim$g<-delete.vertices(sim$g, degree(sim$g) == 0) #remove non-connected verticies
 
  #------clean up
  rm(edges.w1,edges.w2, edges, weight)#remove unused objects
  gc() #garbage collection
  return(invisible(sim))
}

##Get a list of paths from which there is a to and from point
roadCLUS.lcpList<- function(sim){
  message('lcp List')
  paths.matrix<-cbind(cellFromXY(sim$ras,sim$landings), cellFromXY(sim$ras,sim$roads.close.XY ))
  sim$paths.list<-split(paths.matrix, 1:nrow(paths.matrix))
  rm(paths.matrix)
  gc()
  return(invisible(sim))
}

roadCLUS.mstList<- function(sim){
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

roadCLUS.shortestPaths<- function(sim){
  message(paste0('shortestPaths for ', length(sim$paths.list)))
  
  sim$paths.list<-lapply(sim$paths.list, function(x) 
    cbind(as.integer(V(sim$g)[V(sim$g)$name == x[][1] ]),as.integer(V(sim$g)[V(sim$g)$name == x[][2] ]))
  )#paths.matrix is a vector of vertex ids

  #------finds the least cost paths between a list of two points
  if(length(sim$paths.list) > 0 ){
    paths<-unlist(lapply(sim$paths.list, function(x) get.shortest.paths(sim$g,  x[1], x[2], out = "both"))) #create a list of shortest paths
    
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

roadCLUS.randomLandings<-function(sim){
  sim$landings<-xyFromCell(sim$roads, sample(1:ncell(sim$roads), 5), Spatial = TRUE)
  return(invisible(sim))
}

roadCLUS.preSolve<-function(sim){
  #------solve the minnimum spanning tree
  paths<-mst(sim$g)
  #To DO: need some functions to determine which roads to 'activate' and which to 'close'
  return(invisible(sim)) 
}

.inputObjects <- function(sim) {
  if(!suppliedElsewhere("boundaryInfo", sim)){
    sim$boundaryInfo<-list("public.gcbp_carib_polygon","herd_name","Telkwa","geom")
  }

  return(invisible(sim))
}

