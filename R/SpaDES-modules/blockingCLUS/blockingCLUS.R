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
    #createsOutput(objectName = "ras.similar", objectClass = "RasterLayer", desc = NA),
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
  #conn=GetPostgresConn(dbName = "clus", dbUser = "postgres", dbPass = "postgres", dbHost = 'DC052586', dbPort = 5432) 
  #geom<-dbGetQuery(conn, paste0("SELECT ST_ASTEXT(ST_TRANSFORM(ST_Force2D(ST_UNION(",P(sim, "dataLoaderCLUS", "nameBoundaryGeom"),")), 4326)) FROM ", P(sim, "dataLoaderCLUS", "nameBoundaryFile")," WHERE ",P(sim, "dataLoaderCLUS", "nameBoundaryColumn"), " = '",  P(sim, "dataLoaderCLUS", "nameBoundary"), "';"))
  #ras.similar<-RASTER_CLIP(srcRaster= P(sim, "blockingCLUS", "nameSimilarityRas"), clipper=geom, conn=conn) 
  
  #Calculate the similarity using Mahalanobis distance of similarity
  dt<-data.table(dbGetQuery(sim$clusdb, 'SELECT pixelid, height, crownclosure FROM pixels WHERE height > 0 and crownclosure > 0'))
  dt[, mdist:= mahalanobis(dt[, 2:3], colMeans(dt[, 2:3]), cov(dt[, 2:3])) + runif(nrow(dt), 0, 0.0001)] #fuzzy the precision to get a better 'shape' in the blocks
  
  # attaching to the pixels table
  print("updating pixels table with similarity metric")
  dbExecute(sim$clusdb, "ALTER TABLE pixels ADD COLUMN similar numeric")
  dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "UPDATE pixels SET similar = :mdist WHERE pixelid = :pixelid", dt[,c(1,4)])
  dbClearResult(rs)
  dbCommit(sim$clusdb)
  
  rm(dt)
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
  #NEED BETTER LOGIC HERE....
  sim$aoi <- sim$ras #set the area of interest as the similarity raster
  sim$aoi[aoi[] > 0] <- 1 # for those locations where the distance is greater than 0 assign a 1
  sim$aoi[is.na(aoi[])] <- 0 # for those locations where there is no distance - they are NA, assign a 0
  
  sim$harvestUnits<-NULL
  
  #scale the similarity raster so that the values are [0,1]
  sim$ras.similar<-1-(sim$ras - minValue(sim$ras))/(maxValue(sim$ras)-minValue(sim$ras))
  return(invisible(sim))
}

blockingCLUS.preBlock <- function(sim) {

  edgesAdj<-data.table(SpaDES.tools::adj(returnDT= TRUE, directions = 4, numCol = ncol(sim$ras), numCell=ncol(sim$ras)*nrow(sim$ras),
             cells = 1:as.integer(ncol(sim$ras)*nrow(sim$ras)))) #hard-coded the "rooks" case
  edges<-edgesAdj

  edges[, to := as.integer(to)]
  edges[from < to, c("from", "to") := .(to, from)] #find the duplicates. Since this is non-directional graph no need for weights in two directions
  edges<-unique(edges)#remove the duplicates

  weight<-data.table(dbGetQuery(sim$clusdb, 'SELECT pixelid, similar FROM pixels Order by pixelid ASC')) # convert to a data.table - faster for large objects than data.frame

  edges.w1<-merge(x=edges, y=weight, by.x= "from", by.y ="pixelid") #merge in the weights from a cost surface
  setnames(edges.w1, c("from", "to", "w1")) #reformat
  edges.w2<-data.table::setDT(merge(x=edges.w1, y=weight, by.x= "to", by.y ="pixelid"))#merge in the weights to a cost surface
  setnames(edges.w2, c("from", "to", "w1", "w2")) #reformat
  edges.w2$weight<-abs(edges.w2$w2 - edges.w2$w1) #take the absolute cost between the two pixels
 
  #------get the edges list
  edges.weight<-edges.w2[complete.cases(edges.w2), c(1:2, 5)] #get rid of NAs caused by barriers. Drop the w1 and w2 costs.
  edges.weight<-as.matrix(edges.weight[, id := seq_len(.N)]) #set the ids of the edge list. Faster than using as.integer(row.names())

  #summary(edges.weight$weight)
  #------make the graph
  g<-graph.lattice()#instantiate the igraph object
  g<-graph.edgelist(edges.weight[,1:2], dir = FALSE) #create the graph using to and from columns. Requires a matrix input
  E(g)$weight<-edges.weight[,3]#assign weights to the graph. Requires a matrix input
  V(g)$name<-V(g) #assigns the name of the vertex - useful for maintaining link with raster
  
  zones<-unname(unlist(dbGetQuery(sim$clusdb, 'Select distinct (zoneid) from pixels where thlb > 0  AND similar > 0 AND zoneid > 0 order by zoneid')))#get the zone names - strict use of integers for these
  print(zones)
  #patchSize<-unname(unlist(dbGetQuery(sim$clusdb, paste0("Select * FROM constraints where zoneid in (", zones, ")"))))
  
  #get the inputs for the forest_hierarchy java object as a list  
  resultset<-lapply(zones, function (x){ 
    vertices<-as.matrix(dbGetQuery(sim$clusdb, paste0('SELECT pixelid FROM pixels where zoneid = ', as.integer(x), ' AND thlb > 0 and similar > 0')))
    g.mst_sub<-mst(induced_subgraph(g, v = vertices), weighted=TRUE)
    #print(E(g.mst_sub))
    paths.matrix<-data.table(cbind(noquote(get.edgelist(g.mst_sub)), E(g.mst_sub)$weight))
    paths.matrix[, V1 := as.integer(V1)]
    paths.matrix[, V2 := as.integer(V2)]
    #print(head(get.edgelist(g.mst_sub)))
    list(as.matrix(degree(g.mst_sub)), paths.matrix, x) #the degree list (which is the number of connections to other pixels) and the edge list describing the to-from connections - with their weights
    })
  
  #Run the forest_hierarchy java object in parallel. One for each 'zone'. This will maintain zone boundaries as block boundaries
  if(length(zones) > 1 && object.size(g) > 10000000000){ #0.1 GB
    noCores<-min(parallel::detectCores()-1, length(zones))
    print(paste0("make cluster on:", noCores, " cores"))
    cl<-makeCluster(noCores, type = "SOCK")
    clusterCall(cl, worker.init, c('data.table','rJava', 'jdx')) #instantiates a JVM on each core
    blockids<-parLapply(cl, resultset, getBlocksIDs)#runs in parallel using load balancing
    stopCluster.default(cl)
  }else{
    library(rJava) #Calling the rJava library instantiates the JVM. Note: cannot instantiate the JVM on both the cores and the main. 
    library(jdx)
    print("running java on one cluster")
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
    test2
  })
  
  blockids <- Reduce(function(...) merge(..., all=T), result)#join the list components
  blockids<-data.table(blockids)
  blockids[with(blockids, order(V2)), ] #sort the table
  blockids<-data.table(tidyr::complete(blockids, V2= seq(1:as.integer(length(sim$ras))),fill = list(V1 = as.integer(-1))))
  
  #add to the clusdb
  dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "Update pixels set blockid = :V1 where pixelid = :V2", blockids)
    dbClearResult(rs)
  dbCommit(sim$clusdb)
  
  #store the block pixel raster
  sim$harvestUnits<-sim$ras
  sim$harvestUnits[]<- unlist(c(dbGetQuery(sim$clusdb, 'Select blockid from pixels')))
  
  #set the adjacency table
  setkey(blockids, V2)
  edgesAdj<-merge(edgesAdj, blockids,by.x="to", by.y="V2" )
  edgesAdj<-merge(edgesAdj, blockids,by.x="from", by.y="V2" )
  edgesAdj<-data.table(edgesAdj[,3:4])
  edgesAdj<-edgesAdj[V1.x  != V1.y]
  edgesAdj<-edgesAdj[V1.x  > 0 & V1.y  > 0]
  edgesAdj<-unique(edgesAdj)
  setnames(edgesAdj, c("blockid", "adjblockid")) #reformat
  
  print("set the adjacency table")
  dbBegin(sim$clusdb)
   rs<-dbSendQuery(sim$clusdb, "INSERT INTO adjacentBlocks (blockid , adjblockid) values (:blockid, :adjblockid)", edgesAdj)
   dbClearResult(rs)
  dbCommit(sim$clusdb)
  
  print("set the blocks table")
  dbBegin(sim$clusdb)
    rs<-dbSendQuery(sim$clusdb, "INSERT INTO blocks (blockid, zoneid, age, area, state, regendelay) SELECT blockid, zoneid, ROUND(AVG(age), 0) as age, count(*) as area, 0 , 0 from pixels where blockid > 0 group by blockid")
    dbClearResult(rs)
  dbCommit(sim$clusdb)

  rm(zones, result, weight, g, edges.weight, edges, edges.w1, edges.w2, 
     edgesAdj, blockids)
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
  print(paste0("getBlocksID for zone: ", x[][[3]]))
  if(nrow(as.matrix(x[][[2]][,1])) > 0){
  .jinit(classpath= paste0(here::here(),"/Java/bin"), parameters="-Xmx 5g", force.init = TRUE)
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
    fhClass$clearInfo()
    } else{
    blockids = NULL
    print("zero paths matrix")
  }
  list(blockids)
}

worker.init <- function(packages) { #used for setting up the environments of the cores
  for (p in packages) {
    library(p, character.only=TRUE) #need character.only=TRUE to evaluate p as a character
  }
  NULL #return NULL to avoid sending unnecessary data back to the master process
}

