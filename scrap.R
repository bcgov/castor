library(raster)
library(data.table)
library(rJava)
library(jdx)
library(SpaDES.tools)
library(igraph)

#Pass a complex data structure like a data.frame?
set.seed(1)
#set.seed(99) #creates a duplicate in the block list -- TODO need to find this
size = as.integer(5)
ras = raster(extent(0, size, 0, size),res =1, vals =1)
ras[]<-runif(as.integer(size**2), 0,1)
Ras <- randomPolygons(ras, hecatares = 500, num = 4)
ras<-Ras + ras
ras[1:5]<-NA
landings<-xyFromCell(ras, sample(1:ncell(ras), 5), Spatial = TRUE)

#plot(ras)
ncol(ras)
object.size(ras)

fr <- data.table(getValues(ras))
fr$y<-rep(1:ncol(ras), each=nrow(ras))
fr$x<-rep(1:ncol(ras), ncol(ras))

#o <- convertToJava(fr)
#o <- rJava::.jcast(o, getJavaClassName(o), convert.array = TRUE)
#.jcall(fhClass,"Ljava/util/ArrayList;","RunForest_Hierarchy", o, evalArray = TRUE) 
#.jcall(fhClass,"Ljava/util/ArrayList;","RunForest_Hierarchy", o, evalArray = TRUE) 

#------get the adjacency using SpaDES function adj

ras.matrix<-raster::as.matrix(ras)#get the cost surface as a matrix using the raster package
weight<-c(t(ras.matrix)) #transpose then vectorize which matches the same order as adj
weight<-data.table(weight) # convert to a data.table - faster for large objects than data.frame
weight$id<-as.integer(row.names(weight)) # get the id for ther verticies which is used to merge with the edge list from adj


edges<-adj(returnDT= TRUE, directions = 4, numCol = ncol(ras.matrix), numCell=ncol(ras.matrix)*nrow(ras.matrix),
            cells = 1:as.integer(ncol(ras.matrix)*nrow(ras.matrix)))
edges<-data.table(edges)
edges[from < to, c("from", "to") := .(to, from)]
edges<-unique(edges)

edges.w1<-merge(x=edges, y=weight, by.x= "from", by.y ="id") #merge in the weights from a cost surface
setnames(edges.w1, c("from", "to", "w1")) #reformat
edges.w2<-data.table::setDT(merge(x=edges.w1, y=weight, by.x= "to", by.y ="id"))#merge in the weights to a cost surface
setnames(edges.w2, c("from", "to", "w1", "w2")) #reformat
edges.w2$weight<-abs(edges.w2$w2 - edges.w2$w1) #take the average cost between the two pixels

#------get the edges list
edges.weight<-edges.w2[complete.cases(edges.w2), c(1:2, 5)] #get rid of NAs caused by barriers. Drop the w1 and w2 costs.
edges.weight$id<-1:nrow(edges.weight) #set the ids of the edge list. Faster than using as.integer(row.names())


#summary(edges.weight$weight)
#------make the graph
g<-graph.lattice()
g<-graph.edgelist(as.matrix(edges.weight)[,1:2], dir = FALSE) #create the graph using to and from columns. Requires a matrix input

E(g)$weight<-as.matrix(edges.weight)[,3]#assign weights to the graph. Requires a matrix input
#plot(g)
object.size(g)
 
g.mst<-mst(g, weighted=TRUE)
  paths.matrix<-data.table(cbind(noquote(get.edgelist(g.mst)), E(g.mst)$weight))
  paths.matrix[, V1 := as.integer(V1)]
  paths.matrix[, V2 := as.integer(V2)]

#paths.matrix[order(V3),ID := .I] 
#paths.matrix[order(ID)] 
dg<-degree(g.mst)
max(dg)
#plot(g.mst)
#ceb<-cluster_edge_betweenness(g,merges = TRUE)

ceb<-cluster_louvain(g)
ceb<-cluster_fast_greedy(g,merges = TRUE)
ceb<-blocks(cohesive_blocks(g))
cliques(g, min =2, max = 5)
ras.ceb<-ras
out<-as.vector(membership(ceb))
ras.ceb[]<-out 
plot(ras.ceb)
plot(ras)


#Playing with rJava"-XX:-UseGCOverheadLimit"

.jinit(classpath= paste0(getwd(),"/Java/bin"), parameters="-Xmx5g", force.init = TRUE)
.jclassPath() #see what the class path looks like
getOption("java.parameters")
javaImport(packages = "java.util")
#myclass <- .jnew("blockBuilder.blockBuilder", .jarray("sert0")) #creates a low-level java object from R
#myclass2 <- new(J("blockBuilder.blockBuilder"), .jarray("sert2")) #creates a high-level java object from R
#result=myclass$getStringtest("testing0") #call a method from the java object
#result2=.jcall(myclass,"S","getStringtest","testing1") #calls a method from the java object and assigns it result
#fhClass<-.jnew("forest_hierarchy.Forest_Hierarchy") #need to change this to provide arguments
#.jcall(obj=fhClass, returnSig ="V","createData")
#.jcall(obj= fhClass, returnSig ="V", "setMST", o, evalArray = TRUE) # add the edge list

object.size(paths.matrix)
d<-convertToJava(as.integer(degree(g.mst)))
#convertToR(d)

h<-convertToJava(data.table(size= c(4,6,5), n = as.integer(c(3,1,1))))
h<-rJava::.jcast(h, getJavaClassName(h), convert.array = TRUE)

#  e <- convertToJava(paths.matrix,data.frame.row.major = TRUE)
#  e <- rJava::.jcast(e, getJavaClassName(e), convert.array = TRUE)
  
to<-.jarray(as.matrix(paths.matrix[,1]))
from<-.jarray(as.matrix(paths.matrix[,2]))
weight<-.jarray(as.matrix(paths.matrix[,3]))

  #convertToR(h)
system.time({  
  fhClass<-.jnew("forest_hierarchy.Forest_Hierarchy") # creates a forest hierarchy object
  fhClass$setRParms(to, from, weight, d, h) # sets the R parameters <Edges> <Degree> <Histogram>
  fhClass$blockEdges() # creates the blocks
  test<-fhClass$getBlocks() # retrieves the result
  #length(unique(test))
})

ras.out<-ras
ras.out[]<-convertToR(test)
plot(ras.out)
plot(ras)
writeRaster(ras.out, file="simulated", format="GTiff", overwrite=TRUE)
writeRaster(ras, file="test", format="GTiff", overwrite=TRUE)

#spades spread function
library(SpaDES.tools)
size = as.integer(5)
ras = raster(extent(0, size, 0, size),res =1, vals =1)
land<-ras
ras[]<-runif(as.integer(size**2), 0,1)
plot(ras)
stopRuleHistogram <- function(landscape, endSizes, id) sum(landscape) > endSizes[id]
stopRuleA<-spread(landscape=land, loci = c(1,20, 16), exactSizes = TRUE, maxsize= 10, 
                  stopRule = stopRuleHistogram, spreadProb = ras, id= TRUE, directions =4
            , stopRuleBehavior = "excludePixel", endSizes = rnorm(3, 2, 3))

foo <- cbind(vals = ras[stopRuleA], id = stopRuleA[stopRuleA > 0]);
tapply(foo[, "vals"], foo[, "id"], sum)
plot(stopRuleA)



