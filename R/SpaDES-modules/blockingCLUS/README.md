## blockingCLUS

### What it does

Presents the logic for aggregating stands into harvestable units or cutblocks. Approached in two ways: 1) reactively during the simulation (termed 'dynamic') or 2) pre-determined during the intitialization of the simulation (termed 'pre'). 

#### Management levers

* Criteria for linking harvest block layout in the model- homogeneity of the harvest unit
* Patch size targets - distributions of disturbance sizes

### Required inputs

* *clusdb*. Connection to clusdb - see [clusdb](https://github.com/bcgov/clus/tree/master/R/SpaDES-modules/dataLoaderCLUS)
* *blockMethod*. This describes the type of blocking method (Default = 'pre', e.g., 'pre' or 'dynamic')
* *blockSeqInterval*. Interval for simulating blocks (Default = 1)
* *patchVariation*. Allowable distance (variation) within a block (Default = 6, -see [here](https://github.com/bcgov/clus/blob/master/reports/harvest/draft-CLUS-blocking.md)
* *patchZone*. Raster of zones to apply patch size constraints (Default = none, e.g., Landscape units)
* *patchDist*. The target patch size distribution (Default e.g., follow natural disturbance types)
* *nameCutblockRaster*. Name of the raster with ID pertaining to cutlocks (e.g., consolidated cutblocks)
* *spreadProbRas*. Raster for spread probability (required if blockMethod = 'dynamic')


### Outputs

* Raster of harvest units or blocks 
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