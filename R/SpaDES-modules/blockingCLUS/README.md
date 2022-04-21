## blockingCLUS

### What it does

"The accuracy of any attempt to model a forest system depends largely upon the precision with which the site can be classified into homogeneous units" (Vanclay)

blockingCLUS presents the logic for aggregating stands into homogeneous harvestable units or cutblocks. There are advantages to reducing forest attribute variation in the harvest block and this can be approached in two ways: 1) re-actively during the simulation (termed 'dynamic') or 2) pre-determined during the initialization of the simulation (termed 'pre'). 

The 'pre' method uses a graph based image segmentation algorithm and agglomerative clustering to group individual pixels into cutblocks. This process begins with a graph, solving a minimum spanning tree, its cut, followed by agglomerative clustering. 

A graph is created using eight surrounding pixels as the neighborhood, thus each pixel is a node and the connections between each of its neighboring pixels form the edges. The distance between each pixel is estimated from a multivariate distance metric which becomes the weight of the edges between pixels. Thus, similar pixels (as determined by the multivariate distance metric) will have a lower weight. A minimum spanning tree (MST) is then solved which greedily finds the closest pixel within its neighborhood subject to not looping. Thus, a "tree" or path is formed where pixels are connected to their most similar neighbor within their neighborhood. Once the MST is solved, a "cut"" is preformed where edges with a weight that is above the distance metric threshold are deleted. This "cut"" is important for setting the amount of homogeneity required within the cutblock. Following a graph based image segmentation approach this process delineates objects or clusters which are defined by the remaining connected components of the graph. However, these cluster are often quite large and may not meet size constraints for harvesting.

Agglomerative clustering begins from the bottom up where all pixels are classified as individual clusters/cutblocks of size one. Clusters increase in size by adding pixels or other clusters. Clustering occurs based on the solution from the MST which is driven by the edges; sorted in ascending order according to weight. A pixel with the smallest degree (i.e., the number of edges the pixel contains - i.e., a maximum of eight) is selected and its first edge (i.e., the smallest weight) is used to add the pixels into a larger cluster. A degree is subtracted from each of the two pixels that formed the cluster. The size of clusters increases by continually adding more clusters with the smallest degree. However, this could result in pixels forming rather large clusters and result with the same number of clusters as the number of connected components in the graph. To overcome this issue, cluster size is compared to a user specified maximum size. A decision is made to halt the formation of a cluster when the sum of the two clusters is greater than the user driven maximum size. However, this size is not constant, it begins with the largest size class and recursively goes to the next largest size class once the target number of clusters in that size class has been reached. It should be noted that this approach does not necessarily meet the target distribution set by the user but rather uses the target distribution as a guide. 

#### Management levers

* Criteria for linking harvest block layout in the model- homogeneity of the harvest unit
* Patch size targets - distributions of disturbance sizes

### Input Parameters

* *clusdb*. Connection to clusdb - see [clusdb](https://github.com/bcgov/clus/tree/master/R/SpaDES-modules/dataLoaderCLUS)
* *blockMethod*. This describes the type of blocking method (Default = 'pre', e.g., 'pre' or 'dynamic')
* *blockSeqInterval*. Interval for simulating blocks (Default = 1)
* *patchVariation*. Allowable distance (variation) within a block (Default = 6, -see [here](https://github.com/bcgov/clus/blob/master/reports/harvest/draft-CLUS-blocking.md)
* *patchZone*. Raster of zones to apply patch size constraints (Default = none, e.g., Landscape units)
* *patchDist*. The target patch size distribution (Default = < 40 ha, e.g., natural disturbance types patch size in [biodiversity guidebook](https://www.for.gov.bc.ca/hfd/library/documents/bib19715.pdf) )
* *nameCutblockRaster*. Name of the raster with ID pertaining to cutlocks (e.g., consolidated cutblocks)
* *spreadProbRas*. Raster for spread probability (required if blockMethod = 'dynamic')

#### Data Needs

* Rasters of crown closure (horizontal structure) and height (vertical structure) are used to determine the multivariate distance between adjacent stands.
* Raster for the spread probability of dynamic cutblocks (can also be dynamic in the model, e.g., Age or salvage)

### Outputs

* *harvestUnits*. Raster of harvest units or blocks 
* Populates blocks table -see [clusdb](https://github.com/bcgov/clus/tree/master/R/SpaDES-modules/dataLoaderCLUS)
* Populates adjacenctBlocks table for use in applying harvesting adjacency constraints -see [clusdb](https://github.com/bcgov/clus/tree/master/R/SpaDES-modules/dataLoaderCLUS)

### Licence

    Copyright 2019 Province of British Columbia

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.