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
  reqdPkgs = list("raster","gdistance", "sp", "latticeExtra", "sf", "rgeos"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter("roadMethod", "character", "snap", NA, NA, "This describes the method from which to simulate roads - default is snap."),
    defineParameter("simulationTimeStep", "numeric", 1, NA, NA, "This describes the simulation time step interval"),
    defineParameter("nameCostSurfaceRas", "character", "rd_cost_surface", NA, NA, desc = "Name of the cost surface raster"),
    defineParameter("nameRoads", "character", "pre_roads_ras", NA, NA, desc = "Name of the pre-roads raster and schema"),
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
    expectsInput(objectName = "landings", objectClass = "SpatialPoints", desc = NA, sourceURL = NA)
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
      # schedule future event(s)
      sim <- scheduleEvent(sim, eventTime = start(sim),  "roadCLUS", "save.sim")
      sim <- scheduleEvent(sim, eventTime = start(sim), "roadCLUS", "buildRoads")
      sim <- scheduleEvent(sim, eventTime = end(sim),  "roadCLUS", "analysis.sim", eventPriority=19)
      sim <- scheduleEvent(sim, eventTime = end(sim),  "roadCLUS", "save.sim",eventPriority=20)
    },
    plot.sim = {
      # do stuff for this event
      sim <- roadCLUS.roadsPlot(sim)
    },
    save.sim = {
      # do stuff for this event
      sim <- roadCLUS.roadsSave(sim, time(sim))
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
            } ,
            lcp ={
              sim <- roadCLUS.getClosestRoad(sim)
              sim <- roadCLUS.lcpList(sim)
              sim <- roadCLUS.shortestPaths(sim)# includes update graph 
            },
            mst ={
              sim <- roadCLUS.getClosestRoad(sim)
              sim <- roadCLUS.mstList(sim)# will take more time than lcpList given the construction of a mst
              sim <- roadCLUS.shortestPaths(sim)# update graph is within the shorestPaths function
            }
        )
        
        sim <- scheduleEvent(sim, time(sim) + P(sim)$roadSeqInterval, "roadCLUS", "buildRoads")
      }else{
        sim <- scheduleEvent(sim, time(sim) + P(sim)$roadSeqInterval, "roadCLUS", "buildRoads")
      }
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

roadCLUS.Init <- function(sim) {
  sim<-roadCLUS.getRoads(sim) # Get the existing roads
  sim<-roadCLUS.getCostSurface(sim) # Get the cost surface
  
  if(P(sim)$roadMethod == 'lcp' || P(sim)$roadMethod == 'mst'){
    sim <- roadCLUS.getGraph(sim)
  }
 
  return(invisible(sim))
}

roadCLUS.roadsPlot<-function(sim){
  #Plot(sim$roads, title = paste("Simulated Roads ", time(sim)))
  return(invisible(sim))
}

roadCLUS.roadsSave<-function(sim, time){
  if (time == 0 && !file.exists(paste0(sim$boundaryInfo[3], ".tif"))){
    writeRaster(sim$roads, file=paste0(sim$boundaryInfo[3],".tif"), format="GTiff", overwrite=TRUE)
  } else{
    writeRaster(sim$roads, file=paste0(P(sim)$outputPath,  sim$boundaryInfo[3],"_",P(sim)$roadMethod,"_", time, ".tif"), format="GTiff", overwrite=TRUE)
  }
  return(invisible(sim))
}

### Get the rasterized roads layer
roadCLUS.getRoads <- function(sim) {
    sim$roads<-getRasterQuery(P(sim)$nameRoads, sim$bbox)
  return(invisible(sim))
}

### Get the rasterized cost surface
roadCLUS.getCostSurface<- function(sim){
  rds<-raster::reclassify(sim$roads, c(-1,0,1, 0.000000000001, maxValue(sim$roads),0))# if greater than 0 than 0 if not 0 than 1;
  sim$costSurface<-rds*(resample(getRasterQuery(P(sim)$nameCostSurfaceRas, sim$bbox), sim$roads, method = 'bilinear')*288 + 3243)#multiply the cost surface by the existing roads
  return(invisible(sim))
}

###Set the grpah which determines least cost paths
roadCLUS.getGraph<- function(sim){
  #Creates a graph (sim$g) in inititation phase which can be updated and solved for paths
  sim$paths.v<-NULL
  #------prepare the cost surface raster
  ras.matrix<-raster::as.matrix(sim$costSurface)#get the cost surface as a matrix using the raster package
  weight<-c(t(ras.matrix)) #transpose then vectorize which matches the same order as adj
  weight<-data.table(weight) # convert to a data.table - faster for large objects than data.frame
  weight$id<-as.integer(row.names(weight)) # get the id for ther verticies which is used to merge with the edge list from adj
  
  #------get the adjacency using SpaDES function adj
  edges<-adj(returnDT= TRUE, numCol = ncol(ras.matrix), numCell=ncol(ras.matrix)*nrow(ras.matrix), directions =8, cells = 1:as.integer(ncol(ras.matrix)*nrow(ras.matrix)))
  edges.w1<-merge(x=edges, y=weight, by.x= "from", by.y ="id") #merge in the weights from a cost surface
  setnames(edges.w1, c("from", "to", "w1")) #reformat
  edges.w2<-data.table::setDT(merge(x=edges.w1, y=weight, by.x= "to", by.y ="id"))#merge in the weights to a cost surface
  setnames(edges.w2, c("from", "to", "w1", "w2")) #reformat
  edges.w2$weight<-(edges.w2$w1 + edges.w2$w2)/2 #take the average cost between the two pixels
  
  #------get the edges list
  edges.weight<-edges.w2[complete.cases(edges.w2), c(1:2, 5)] #get rid of NAs caused by barriers. Drop the w1 and w2 costs.
  edges.weight$id<-1:nrow(edges.weight) #set the ids of the edge list. Faster than using as.integer(row.names())
  
  #------make the graph
  sim$g<-graph.edgelist(as.matrix(edges.weight)[,1:2], dir = FALSE) #create the graph using to and from columns. Requires a matrix input
  E(sim$g)$weight<-as.matrix(edges.weight)[,3]#assign weights to the graph. Requires a matrix input

  #------clean up
  rm(edges.w1,edges.w2, edges, weight, ras.matrix)#remove unused objects
  gc() #garbage collection
  return(invisible(sim))
}

##Get a list of paths from which there is a to and from point
roadCLUS.lcpList<- function(sim){
  paths.matrix<-cbind(cellFromXY(sim$costSurface,sim$landings ), cellFromXY(sim$costSurface,sim$roads.close.XY ))
  sim$paths.list<-split(paths.matrix, 1:nrow(paths.matrix))
  rm(paths.matrix)
  gc()
  return(invisible(sim))
}

roadCLUS.mstList<- function(sim){
  #print('mstList')
  mst.v <- as.vector(rbind(cellFromXY(sim$costSurface,sim$landings ), cellFromXY(sim$costSurface,sim$roads.close.XY )))
  paths.matrix<-as.matrix(mst.v)
  paths.matrix<- paths.matrix[!duplicated(paths.matrix[,1]),]
  #print(paths.matrix)
  if(length(paths.matrix) > 1){
    mst.adj <- distances(sim$g, paths.matrix, paths.matrix) # get an adjaceny matrix given then cell numbers
    #print(mst.adj)
    rownames(mst.adj)<-paths.matrix # set the verticies names as the cell numbers in the costSurface
    colnames(mst.adj)<-paths.matrix # set the verticies names as the cell numbers in the costSurface
    mst.g <- graph_from_adjacency_matrix(mst.adj, weighted=TRUE) # create a graph
    mst.paths <- mst(mst.g, weighted=TRUE) # get the the minimum spanning tree
    paths.matrix<-noquote(get.edgelist(mst.paths, names=TRUE))
    class(paths.matrix) <- "numeric"
    sim$paths.list<-split(paths.matrix, 1:nrow(paths.matrix)) # put the edge combinations in a list used for shortestPaths
    #print(sim$paths.list)
    rm(mst.paths,mst.g, mst.adj, mst.v, paths.matrix)
    gc()
  }
  
  return(invisible(sim))
}


roadCLUS.shortestPaths<- function(sim){
  #print('shortestPaths')
  #------finds the least cost paths between a list of two points
  if(!length(sim$paths.list)==0){
    #print(sim$paths.list)
    paths<-unlist(lapply(sim$paths.list, function(x) get.shortest.paths(sim$g, x[1], x[2], out = "both"))) #create a list of shortest paths
    sim$paths.v<-unique(rbind(data.table(paths[grepl("vpath",names(paths))] ), sim$paths.v))#save the verticies for mapping
    paths.e<-paths[grepl("epath",names(paths))]
    edge_attr(sim$g, index= E(sim$g)[E(sim$g) %in% paths.e], name= 'weight')<-0.00001 #changes the cost(weight) associated with the edge that became a path (or road)
    
    #reset landings and roads close to them
    sim$landings<-NULL
    sim$roads.close.XY<-NULL
    rm(paths.e)
    gc()
  }
  return(invisible(sim))
}

roadCLUS.getClosestRoad <- function(sim){
  roads.pts <- rasterToPoints(sim$roads, fun=function(x){x > 0})
  closest.roads.pts <- apply(gDistance(SpatialPoints(roads.pts),SpatialPoints(sim$landings), byid=TRUE), 1, which.min)
  sim$roads.close.XY <- as.matrix(roads.pts[closest.roads.pts, 1:2,drop=F]) #this function returns a matrix of x, y coordinates corresponding to the closest road
  #The drop =F is needed for a single landing - during the subset of a matrix it will become a column vector because as it converts a vector to a matrix, r will assume you have one column
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
    mt<-coodMatrix %>% st_as_sf(coords=c("x","y"))%>% group_by(id) %>% summarize(m=mean(attr_data)) %>% st_cast("LINESTRING")
    test<-fasterize::fasterize(st_buffer(mt,50),sim$roads, field = "m")
    sim$roads<-raster::merge(test, sim$roads)
    rm(rdptsXY, landings, mt, coodMatrix, test)
    gc()
  return(invisible(sim))
}

roadCLUS.analysis <- function(sim){
  if(!P(sim)$roadMethod == 'snap'){
    ras.out<-sim$costSurface
    ras.out[]<-1:ncell(ras.out)
    ras.out[!(ras.out[] %in% as.matrix(sim$paths.v))] <- NA
    #ras.out<-raster::reclassify(ras.out, c(0.000000000001, maxValue(ras.out),0))
    sim$roads<-raster::merge(ras.out, sim$roads)
  } 
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  if(!suppliedElsewhere("boundaryInfo", sim)){
    sim$boundaryInfo<-c("gcbp_carib_polygon","herd_name","Muskwa","geom")
  }
  if(!suppliedElsewhere("bbox", sim)){
    sim$bbox<-st_bbox(getSpatialQuery(paste0("SELECT * FROM ",  sim$boundaryInfo[1], " WHERE ",    sim$boundaryInfo[2], "= '",   sim$boundaryInfo[3],"';" )))
  }
  if(!suppliedElsewhere("landings", sim)){
    sim$landings<-NULL
  }
  return(invisible(sim))
}
getSpatialQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='localhost', dbname = 'clus', port='5432' ,user='app_user' ,password='clus')
  on.exit(dbDisconnect(conn))
  st_read(conn, query = sql)
}

getTableQuery<-function(sql){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='localhost', dbname = 'clus', port='5432' ,user='app_user' ,password='clus')
  on.exit(dbDisconnect(conn))
  dbGetQuery(conn, sql)
}

getRasterQuery<-function(name, bb){
  conn<-DBI::dbConnect(dbDriver("PostgreSQL"), host='localhost', dbname = 'clus', port='5432' ,user='app_user' ,password='clus')
  on.exit(dbDisconnect(conn))
  pgGetRast(conn, name, boundary = c(bb[4],bb[2],bb[3],bb[1]))
}
