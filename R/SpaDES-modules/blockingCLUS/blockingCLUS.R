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

defineModule(sim, list(
  name = "blockingCLUS",
  description = NA, #"insert module description here",
  keywords = NA, # c("insert key words here"),
  authors = c(person("Kyle", "Lochhead", email = "kyle.lochhead@gov.bc.ca", role = c("aut", "cre")),
              person("Tyler", "Muhley", email = "tyler.muhley@gov.bc.ca", role = c("aut", "cre"))),
  childModules = character(0),
  version = list(SpaDES.core = "0.1.1", blockingCLUS = "0.0.1"),
  spatialExtent = raster::extent(rep(NA_real_, 4)),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.txt", "blockingCLUS.Rmd"),
  reqdPkgs = list("here","igraph","data.table", "raster", "SpaDES.tools", "snow", "parallel", "tidyr"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter("nameSimilarityRas", "character", "rast.similarity_vri2003", NA, NA, desc = "Name of the cost surface raster"),
    defineParameter("useLandingsArea", "logical", FALSE, NA, NA, desc = "Use the area provided by the historical cutblocks?"),
    defineParameter("useSpreadProbRas", "logical", FALSE, NA, NA, desc = "Use the similarity raster to direct the spreading?"),
    defineParameter("blockSeqInterval", "numeric", 1, NA, NA, "This describes the simulation time at which blocking should be done if dynamically blocked"),
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first plot event should occur"),
    defineParameter(".plotInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between plot events"),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA, "This describes the simulation time at which the first save event should occur"),
    defineParameter(".saveInterval", "numeric", NA, NA, NA, "This describes the simulation time interval between save events"),
    defineParameter(".useCache", "numeric", FALSE, NA, NA, "Should this entire module be run with caching activated? This is generally intended for data-type modules, where stochasticity and time are not relevant")
  ),
  inputObjects = bind_rows(
    #expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput(objectName ="clusdb", objectClass ="SQLiteConnection", desc = "A rsqlite database that stores, organizes and manipulates clus realted information", sourceURL = NA),
    expectsInput(objectName ="blockMethod", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName ="nameSimilarityRas", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName ="boundaryInfo", objectClass ="character", desc = NA, sourceURL = NA),
    expectsInput(objectName ="landings", objectClass = "SpatialPoints", desc = NA, sourceURL = NA),
    expectsInput(objectName ="landingsArea", objectClass = "numeric", desc = NA, sourceURL = NA)
  ),
  outputObjects = bind_rows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = "ras.similar", objectClass = "RasterLayer", desc = NA),
    createsOutput(objectName = "harvestUnits", objectClass = "RasterLayer", desc = NA)
  )
))

doEvent.blockingCLUS = function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    init = {
      sim<-blockingCLUS.Init(sim)
      sim <- scheduleEvent(sim, eventTime = end(sim),  "blockingCLUS", "writeBlocks", eventPriority=21) # set this last. Not that important
      switch(P(sim)$blockMethod,
             pre= {
               sim <- blockingCLUS.preBlock(sim) #preforms the pre-blocking algorthium in Java
             },
             dynamic ={
               sim <- blockingCLUS.setSpreadProb(sim)
               sim <- scheduleEvent(sim, time(sim) + P(sim)$blockSeqInterval, "blockingCLUS", "buildBlocks")
             }
      )
    },
    buildBlocks = {
        sim <- blockingCLUS.spreadBlock(sim)
        sim <- scheduleEvent(sim, time(sim) + P(sim)$blockSeqInterval, "blockingCLUS", "buildBlocks")
    },
    writeBlocks = {
      writeRaster(sim$harvestUnits, "hu.tif", overwrite = TRUE)
    },
    warning(paste("Undefined event type: '", current(sim)[1, "eventType", with = FALSE],
                  "' in module '", current(sim)[1, "moduleName", with = FALSE], "'", sep = ""))
  )
  return(invisible(sim))
}

blockingCLUS.Init <- function(sim) {
  sim<-blockingCLUS.getBounds(sim) # Get the boundary from which to confine the blocking used in cutblockseq
 
   #clip the boundary with the provincial similarity raste
  conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
  geom<-dbGetQuery(conn, paste0("SELECT ST_ASTEXT(ST_TRANSFORM(ST_Force2D(ST_UNION(GEOM)), 4326)) FROM ", P(sim, "dataLoaderCLUS", "nameBoundaryFile")," WHERE ",P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " = '",  P(sim, "dataLoaderCLUS", "nameBoundary"), "';"))
  sim$ras.similar<-RASTER_CLIP(srcRaster= P(sim, "blockingCLUS", "nameSimilarityRas"), clipper=geom, conn=conn) 
  # going to leave the similarity raster unattached to clusdb, rather use it to sample zones.
  
  thlb<-sim$ras.similar #mask similarity raster
  thlb[]<-as.matrix(dbGetQuery(sim$clusdb, "Select thlb from pixels"))
  thlb[thlb[] > 0]<-1
  sim$ras.similar<-sim$ras.similar*thlb
  
  rm(thlb)
  gc()
  
  return(invisible(sim))
}

blockingCLUS.getBounds<-function(sim){
  #The boundary may exist from previous modules?
  if(!suppliedElsewhere("bbox", sim)){
    sim$boundary<-getSpatialQuery(paste0("SELECT * FROM ",  P(sim, "dataLoaderCLUS", "nameBoundaryFile"), " WHERE ",   P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), "= '",  P(sim, "dataLoaderCLUS", "nameBoundary"),"';" ))
    sim$bbox<-st_bbox(sim$boundary)
  }
  return(invisible(sim))
}

blockingCLUS.setSpreadProb<- function(sim) {
  #Create a mask for the area of interst
  sim$aoi <- sim$ras.similar #set the area of interest as the similarity raster
  sim$aoi[aoi[] > 0] <- 1 # for those locations where the distance is greater than 0 assign a 1
  sim$aoi[is.na(aoi[])] <- 0 # for those locations where there is no distance - they are NA, assign a 0
  
  sim$harvestUnits<-NULL
  
  #scale the similarity raster so that the values are [0,1]
  sim$ras.similar<-1-(sim$ras.similar - minValue(sim$ras.similar))/(maxValue(sim$ras.similar)-minValue(sim$ras.similar))
  return(invisible(sim))
}

blockingCLUS.preBlock <- function(sim) {
  #fuzzy the precision to prevent "line" shapes
  ras_var<-sim$ras.similar
  len<-length(sim$ras.similar[sim$ras.similar > 0])
  ras_var[ras_var>0]<-runif(as.integer(len), 0,0.001)
  sim$ras.similar<-sim$ras.similar+ras_var
  
  ras.matrix<-raster::as.matrix(sim$ras.similar)#convert the raster to a matrix
  weight<-c(t(ras.matrix)) #transpose then vectorize which matches the same order as adj
  size_ras<-length(weight)
  weight<-data.table(weight) # convert to a data.table - faster for large objects than data.frame
  weight[, id := seq_len(.N)] # set the id for ther verticies which is used to merge with the edge list from adj
  
  edges<-data.table(SpaDES.tools::adj(returnDT= TRUE, directions = 4, numCol = ncol(ras.matrix), numCell=ncol(ras.matrix)*nrow(ras.matrix),
             cells = 1:as.integer(ncol(ras.matrix)*nrow(ras.matrix)))) #hard-coded the "rooks" case
  edges[from < to, c("from", "to") := .(to, from)] #find the duplicates. Since this is non-directional graph no need for weights in two directions
  edges<-unique(edges)#remove the duplicates
  
  edges.w1<-merge(x=edges, y=weight, by.x= "from", by.y ="id") #merge in the weights from a cost surface
  setnames(edges.w1, c("from", "to", "w1")) #reformat
  edges.w2<-data.table::setDT(merge(x=edges.w1, y=weight, by.x= "to", by.y ="id"))#merge in the weights to a cost surface
  setnames(edges.w2, c("from", "to", "w1", "w2")) #reformat
  edges.w2$weight<-abs(edges.w2$w2 - edges.w2$w1) #take the average cost between the two pixels
  
  #------get the edges list
  edges.weight<-edges.w2[complete.cases(edges.w2), c(1:2, 5)] #get rid of NAs caused by barriers. Drop the w1 and w2 costs.
  edges.weight<-as.matrix(edges.weight[, id := seq_len(.N)]) #set the ids of the edge list. Faster than using as.integer(row.names())
  
  #summary(edges.weight$weight)
  #------make the graph
  g<-graph.lattice()#instantiate the igraph object
  g<-graph.edgelist(edges.weight[,1:2], dir = FALSE) #create the graph using to and from columns. Requires a matrix input
  E(g)$weight<-edges.weight[,3]#assign weights to the graph. Requires a matrix input
  V(g)$name<-V(g) #assigns the name of the vertex - useful for maintaining link with raster
  
  zones<-unname(unlist(dbGetQuery(sim$clusdb, 'Select distinct (zoneid) from pixels where zoneid Is NOT NULL AND thlb > 0')))#get the zone names - strict use of integers for these
  print(zones)
 
  #get the inputs for the forest_hierarchy java object as a list  
  resultset<-lapply(zones, function (x){ 
    g.mst<-mst(induced_subgraph(g, v = as.matrix(dbGetQuery(sim$clusdb, paste0('SELECT pixelid FROM pixels where zoneid = ', as.integer(x), ' AND thlb > 0')))) , weighted=TRUE)
    paths.matrix<-data.table(cbind(noquote(get.edgelist(g.mst)), E(g.mst)$weight))
    paths.matrix[, V1 := as.integer(V1)]
    paths.matrix[, V2 := as.integer(V2)]
    degreeList<-as.matrix(degree(g.mst))
    
    list(degreeList, paths.matrix) #the degree list (which is the number of connections to other pixels) and the edge list describing the to-from connections - with their weights
  })
  
  #Run the forest_hierarchy java object in parallel. One for each 'zone'. This will maintain zone boundaries as block boundaries
  if(length(zones) > 1 && object.size(g) > 100000000){ #0.1 GB
    noCores<-min(parallel::detectCores()-1, length(zones))
    print(paste0("make cluster on:", noCores, " cores"))
    cl<-makeCluster(noCores, type = "SOCK")
    clusterCall(cl, worker.init, c('data.table','rJava', 'jdx')) #instantiates a JVM on each core
    blockids<-parLapply(cl, resultset, getBlocksIDs)#runs in parallel using load balancing
    stopCluster.default(cl)
  }else{
    library(rJava) #Calling the rJava library instantiates the JVM. Note: cannot instantiate the JVM on both the cores and the main. 
    library(jdx)
    blockids<-lapply(resultset, getBlocksIDs)
  }#blockids is a list of integers representing blockids and the corresponding vertex names (i.e., pixelid)
  
  #Need to combine the results of blockids into clusdb. Update the pixels table and populate the blockids
  lastBlockID <<- 0
  result<-lapply(blockids, function(x){
    test2<-x[][[1]][x[][[1]][,1]>-1,]
    if(lastBlockID > 0){
      test2[,1]<-test2[,1] + lastBlockID
    } 
    lastBlockID<<-max(test2[,1])
    list(test2)
  })
  
  blockids = Reduce(function(...) merge(..., all=T), result)#join the list components
  blockids[with(blockids, order(X2)), ] #sort the table
  blockids<-data.table(tidyr::complete(blockids, X2= seq(1:as.integer(length(sim$ras.similar))),fill = list(X1 = as.integer(-1))))
  
  #add to the clusdb
  dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "Update pixels set blockid = :X1 where pixelid = :X2", blockids)
    dbClearResult(rs)
  dbCommit(sim$clusdb)
  
  #store the block pixel raster
  #sim$harvestUnits<-raster(extent(sim$ras.similar),crs= crs(sim$ras.similar), res =100, vals = c(dbGetQuery(sim$clusdb, "Select blockid from pixels")))
  sim$harvestUnits<-sim$ras.similar
  sim$harvestUnits[]<- unlist(c(dbGetQuery(sim$clusdb, 'Select blockid from pixels')))
  rm(result, weight,  g, edges.weight, edges, ras.matrix)
  gc()
  return(invisible(sim))
}


blockingCLUS.spreadBlock<- function(sim) {
  if (!is.null(sim$landings)) {
    
      if(P(sim)$useLandingsArea){
        size<-sim$landingsArea
      }else{
        size<-as.integer(runif(length(landings), 20, 100))
      }
    
      landings<-cellFromXY(sim$aoi, sim$landings)
      landings<-as.data.frame(cbind(landings, size))
      landings<-landings[!duplicated(landings$landings),]
      
      if(P(sim)$useSpreadProbRas){
        simBlocks<-SpaDES.tools::spread2(landscape=sim$aoi, spreadProb = sim$ras.similar, start = landings[,1], directions =4, 
                                         maxSize= landings[,2], allowOverlap=FALSE)
      }else{
          simBlocks<-SpaDES.tools::spread2(landscape=sim$aoi, spreadProb = sim$aoi, start = landings[,1], directions =4, 
                     maxSize= landings[,2], allowOverlap=FALSE)
      }
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

### additional functions
getBlocksIDs<- function(x){
  #print("getBlocksIDs")
  .jinit(classpath= paste0(here::here(),"/Java/bin"), parameters="-Xmx5g", force.init = TRUE)
  fhClass<-.jnew("forest_hierarchy.Forest_Hierarchy") # creates a forest hierarchy object
  
  dg<- data.table(cbind(as.integer(rownames(x[][[1]])),as.integer(x[][[1]])))
  dg<- data.table(tidyr::complete(dg, V1= seq(1:as.integer(max(dg[,1]))),fill = list(V2 = as.integer(-1)))) #TODO: remove this dependancy in java where the index refers to the pixelid.
  
  d<-convertToJava(as.integer(unlist(dg[,"V2"])))
  
  h<-convertToJava(data.frame(size= c(20,40,60,100), n = as.integer(c(1000000, 300000,10000,1000))), array.order = "column-major", data.frame.row.major = TRUE)
  h<-rJava::.jcast(h, getJavaClassName(h), convert.array = TRUE)
  
  to<-.jarray(as.matrix(x[][[2]][,1]))
  from<-.jarray(as.matrix(x[][[2]][,2]))
  weight<-.jarray(as.matrix(x[][[2]][,3]))
  
  fhClass$setRParms(to, from, weight, d, h) # sets the R parameters <Edges> <Degree> <Histogram>
  fhClass$blockEdges() # creates the blocks
  blockids<-cbind(convertToR(fhClass$getBlocks()), as.integer(unlist(dg[,1]))) #creates a link between pixelid and blockid
  list(blockids)
}

worker.init <- function(packages) { #used for setting up the environments of the cores
  for (p in packages) {
    library(p, character.only=TRUE) #need character.only=TRUE to evaluate p as a character
  }
  NULL #return NULL to avoid sending unnecessary data back to the master process
}
