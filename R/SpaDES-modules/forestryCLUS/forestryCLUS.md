---
title: "forestryCLUS"
author: ""
date: "08 April 2019"
output:
  html_document: 
    keep_md: yes
---

<!--
Copyright 2018 Province of British Columbia
 
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.-->

# Overview

This module provides the logic for simulating forestry decisions on the landscape. These decisions currently involve spatializing the harvest flow objectives which include: where, when and how much to harvest. These factors help determine policies related to harvest flows, opening size, seral distrubitions, road densitites, preservation areas, silvicultural systems, etc. More sophistication to these decisions would involve looking at the costs and benefits beyond the current time period; this requires optimization or improved heuristics -- which may be considered in the future. The general overview of forestryCLUS follows.

At each time step, harvest units (pixels or blocks) are ranked according to a priority (e.g., oldest first), this constructs a queue. This queue of harvest units are then subject to various constraints meant to meet objectives for the study area. Harvest units are harvested until either a constraint is binding, the queue is exhausted or the harvest flow is met. Next, the age of the forest is advanced to the next time period and the process is repeated. 

During the simulation various reports and information surrounding each pixel can be saved/recorded or used in a summary. Note these outputs are considered expected future outcomes given the inputs developed by the anlayst.For a historical selection of harvesting activities see [cutblockSeqPrepCLUS](https://github.com/bcgov/clus/tree/master/R/SpaDES-modules/cutblockSeqPrepCLUS). Both  cutblockSeqPrepCLUS and forestryCLUS build a list of landing locations through simulation time. One is historical while the other is one possible future realization.

# Usage
This module could be a parent module?? It relies on: 
1. dataloadCLUS (set up the clusdb) 
2. blockingCLUS (preforms the pixel aggregation into harvest units)
3. growingStockCLUS (increments the age and volume in pixels)
4. (Optionally) rsfCLUS (track resource selection functions)
5. (Optionally) roadCLUS (preforms the access to the harvest units)



```r
library(SpaDES.core)
```

```
## Warning: package 'SpaDES.core' was built under R version 3.5.3
```

```
## Loading required package: quickPlot
```

```
## Loading required package: reproducible
```

```
## Warning: package 'reproducible' was built under R version 3.5.3
```

```
## 
## Attaching package: 'SpaDES.core'
```

```
## The following objects are masked from 'package:stats':
## 
##     end, start
```

```
## The following object is masked from 'package:utils':
## 
##     citation
```

```r
library(data.table)
```

```
## Warning: package 'data.table' was built under R version 3.5.3
```

```r
source("C:/Users/KLOCHHEA/clus/R/functions/R_Postgres.R")
```

```
## Loading required package: RPostgreSQL
```

```
## Loading required package: DBI
```

```
## Warning: package 'sf' was built under R version 3.5.3
```

```
## Linking to GEOS 3.6.1, GDAL 2.2.3, PROJ 4.9.3
```

```
## Warning: package 'raster' was built under R version 3.5.3
```

```
## Loading required package: sp
```

```
## 
## Attaching package: 'raster'
```

```
## The following object is masked from 'package:data.table':
## 
##     shift
```

```
## Warning: package 'rgdal' was built under R version 3.5.3
```

```
## rgdal: version: 1.4-3, (SVN revision 828)
##  Geospatial Data Abstraction Library extensions to R successfully loaded
##  Loaded GDAL runtime: GDAL 2.2.3, released 2017/11/20
##  Path to GDAL shared files: C:/Program Files/R/R-3.5.1/library/sf/gdal
##  GDAL binary built with GEOS: TRUE 
##  Loaded PROJ.4 runtime: Rel. 4.9.3, 15 August 2016, [PJ_VERSION: 493]
##  Path to PROJ.4 shared files: C:/Program Files/R/R-3.5.1/library/sf/proj
##  Linking to sp version: 1.3-1
```

```
## Loading required package: gsubfn
```

```
## Loading required package: proto
```

```
## Loading required package: RSQLite
```

```
## sqldf will default to using PostgreSQL
```

```r
moduleDir <- file.path("C:/Users/KLOCHHEA/clus/R/SpaDES-modules")
inputDir <- file.path("C:/Users/KLOCHHEA/clus/R") %>% reproducible::checkPath(create = TRUE)
outputDir <- file.path("C:/Users/KLOCHHEA/clus/R")
cacheDir <- file.path("C:/Users/KLOCHHEA/clus/R")
times <- list(start = 0, end = 2)
parameters <- list(
  .progress = list(type = NA, interval = NA),
  .globals = list(),
  dataLoaderCLUS = list( 
                         #Database connection
                         dbName='clus',
                         save_clusdb = FALSE,
                         useCLUSdb = "C:/Users/KLOCHHEA/clus/R/SpaDES-modules/forestryCLUS/clusdb.sqlite",
                         #Study Area
                         nameBoundaryFile="study_area_compart",
                         nameBoundaryColumn="tsb_number",
                         nameBoundary=c("08B", "08C"), 
                         nameBoundaryGeom='wkb_geometry',
                         nameCompartmentRaster = "rast.forest_tenure",
                         #Zones
                         nameMaskHarvestLandbaseRaster='rast.bc_thlb2018',
                         nameZoneRasters=c("rast.zone_beo", "rast.zone_vqo"),
                         nameZoneTable ="zone_constraints",
                         #VRI info
                         nameAgeRaster= "rast.vri2017_projage1",
                         #nameHeightRaster= "rast.vri2017_projheight1",
                         #nameCrownClosureRaster = "rast.vri2017_crownclosure",
                         #Yield info
                         #nameYieldIDRaster ="rast.yieldid",
                         nameYieldTable ="yield_ex"
                      ),  
  blockingCLUS = list(blockMethod='pre', 
                      patchZone = 'rast.zone_beo',
                      nameCutblockRaster ="rast.cns_cut_bl",
                      useLandingsArea=FALSE, 
                      useSpreadProbRas=FALSE),
  forestryCLUS = list( harvestPriority = "age DESC, vol DESC, crowncover DESC")
                )
modules <- list("dataLoaderCLUS", "growingStockCLUS", "blockingCLUS", "forestryCLUS")
harvestFlow<- data.table(compartment = c('08B','08B','08B','08C','08C','08C'),
                                   partition = 'vol > 50',
                                   year = rep(seq(from = 2018, to=2020, by = 
                                                    1),2), 
                                   flow = c(1000, 1001, 1004, 1100, 1011, 1024))
objects <- list(harvestFlow = harvestFlow 
                )
paths <- list(
  cachePath = cacheDir,
  modulePath = moduleDir,
  inputPath = inputDir,
  outputPath = outputDir
)

mySim <- simInit(times = times, params = parameters, modules = modules,
                 objects = objects, paths = paths)
```

```
## Setting:
##   options(
##     reproducible.cachePath = 'C:/Users/KLOCHHEA/clus/R'
##     spades.inputPath = 'C:/Users/KLOCHHEA/clus/R'
##     spades.outputPath = 'C:/Users/KLOCHHEA/clus/R'
##     spades.modulePath = 'C:/Users/KLOCHHEA/clus/R/SpaDES-modules'
##   )
```

```
## Loading required package: here
```

```
## here() starts at C:/Users/KLOCHHEA/clus
```

```
## Loading required package: igraph
```

```
## 
## Attaching package: 'igraph'
```

```
## The following object is masked from 'package:raster':
## 
##     union
```

```
## The following objects are masked from 'package:stats':
## 
##     decompose, spectrum
```

```
## The following object is masked from 'package:base':
## 
##     union
```

```
## Loading required package: parallel
```

```
## Loading required package: snow
```

```
## 
## Attaching package: 'snow'
```

```
## The following objects are masked from 'package:parallel':
## 
##     clusterApply, clusterApplyLB, clusterCall, clusterEvalQ,
##     clusterExport, clusterMap, clusterSplit, makeCluster,
##     parApply, parCapply, parLapply, parRapply, parSapply,
##     splitIndices, stopCluster
```

```
## Loading required package: SpaDES.tools
```

```
## Loading required package: tidyr
```

```
## 
## Attaching package: 'tidyr'
```

```
## The following object is masked from 'package:SpaDES.tools':
## 
##     spread
```

```
## The following object is masked from 'package:igraph':
## 
##     crossing
```

```
## The following object is masked from 'package:raster':
## 
##     extract
```

```
## Module dataLoaderCLUS still uses the old way of function naming.
##   It is now recommended to define functions that are not prefixed with the module name
##   and to no longer call the functions with sim$functionName.
##   Simply call functions in your module with their name: e.g.,
##   sim <- Init(sim), rather than sim <- sim$myModule_Init(sim)
```

```
## defineParameter: '.useCache' is not of specified type 'numeric'.
```

```
## dataLoaderCLUS: module code: nameBoundaryFile, nameBoundary, nameBoundaryColumn, nameBoundaryGeom are declared in metadata inputObjects, but no default(s) are provided in .inputObjects
```

```
## dataLoaderCLUS: module code: nameBoundaryFile, nameBoundary, nameBoundaryColumn, nameBoundaryGeom are declared in metadata inputObjects, but are not used in the module
```

```
## dataLoaderCLUS: module code: dataLoaderCLUS.setTablesCLUSdb: local variable 'test' assigned but may not be used
```

```
## dataLoaderCLUS: module code: dataLoaderCLUS.setTablesCLUSdb: local variable 'zones_aoi' assigned but may not be used
```

```
## Module growingStockCLUS still uses the old way of function naming.
##   It is now recommended to define functions that are not prefixed with the module name
##   and to no longer call the functions with sim$functionName.
##   Simply call functions in your module with their name: e.g.,
##   sim <- Init(sim), rather than sim <- sim$myModule_Init(sim)
```

```
## growingStockCLUS: module code: clusdb is declared in metadata inputObjects, but no default(s) is provided in .inputObjects
```

```
## Module blockingCLUS still uses the old way of function naming.
##   It is now recommended to define functions that are not prefixed with the module name
##   and to no longer call the functions with sim$functionName.
##   Simply call functions in your module with their name: e.g.,
##   sim <- Init(sim), rather than sim <- sim$myModule_Init(sim)
```

```
## defineParameter: '.useCache' is not of specified type 'numeric'.
```

```
## blockingCLUS: module code: clusdb, ras, blockMethod, zone.length, boundaryInfo, landings, landingsArea, growingStockReport are declared in metadata inputObjects, but no default(s) are provided in .inputObjects
```

```
## blockingCLUS: module code: blockMethod, zone.length, growingStockReport are declared in metadata inputObjects, but are not used in the module
```

```
## blockingCLUS: module code: blockingCLUS.preBlock: warning in graph.edgelist(edges.weight[, 1:2], dir = FALSE): partial argument match of 'dir' to 'directed'
```

```
## blockingCLUS: module code: blockingCLUS.preBlock: no visible binding for '<<-' assignment to 'lastBlockID'
```

```
## blockingCLUS: module code: blockingCLUS.preBlock : <anonymous>: no visible binding for '<<-' assignment to 'lastBlockID'
```

```
## blockingCLUS: outputObjects: aoi, ras.spreadProbBlock are assigned to sim inside blockingCLUS.setSpreadProb, but are not declared in metadata outputObjects
```

```
## blockingCLUS: outputObjects: aoi is assigned to sim inside blockingCLUS.spreadBlock, but is not declared in metadata outputObjects
```

```
## blockingCLUS: inputObjects: aoi, ras.spreadProbBlocks, ras.spreadProbBlock are used from sim inside blockingCLUS.setSpreadProb, but are not declared in metadata inputObjects
```

```
## blockingCLUS: inputObjects: aoi, ras.spreadProbBlock are used from sim inside blockingCLUS.spreadBlock, but are not declared in metadata inputObjects
```

```
## Module forestryCLUS still uses the old way of function naming.
##   It is now recommended to define functions that are not prefixed with the module name
##   and to no longer call the functions with sim$functionName.
##   Simply call functions in your module with their name: e.g.,
##   sim <- Init(sim), rather than sim <- sim$myModule_Init(sim)
```

```
## forestryCLUS: module code: landings is declared in metadata outputObjects, but is not assigned in the module
```

```
## forestryCLUS: module code: clusdb, harvestFlow, growingStockReport are declared in metadata inputObjects, but no default(s) are provided in .inputObjects
```

```
## forestryCLUS: module code: harvestFlow, growingStockReport are declared in metadata inputObjects, but are not used in the module
```

```
## Running .inputObjects for dataLoaderCLUS
```

```
## Running .inputObjects for growingStockCLUS
```

```
## Running .inputObjects for forestryCLUS
```

```
## Parameter useSpreadProbRas is not used in module blockingCLUS
```

```r
system.time({
mysimout<-spades(mySim)
})
```

```
## This is the current event, printed as it is happening:
## eventTime moduleName eventType eventPriority
## 0         checkpoint init      5            
## 0         save       init      5            
## 0         progress   init      5            
## 0         load       init      5            
## 0         dataLoaderCLUS init      5            
## [1] "Loading existing db..."
## 0         growingStockCLUS init      5            
## 0         forestryCLUS     init      5            
## 0         blockingCLUS     init      5            
## 1         forestryCLUS     schedule  5            
## [1] "...setting constraints"
## [1] "....assigning zone_const"
## [1] "Harvest Target: 1001"
## [1] "queue"
## [1] 1
## attr(,"unit")
## [1] "year"
## [1] 0
## [1] 0
## [1] "Harvest Target: 1011"
## [1] "queue"
## [1] 1
## attr(,"unit")
## [1] "year"
## [1] 1.828
## [1] 132.53
## 1         growingStockCLUS updateGrowingStock 9            
## [1] "update at 1"
## 1         blockingCLUS     UpdateBlocks       10           
## [1] "update the blocks table"
## 2         forestryCLUS     schedule           5            
## [1] "...setting constraints"
## [1] "....assigning zone_const"
## [1] "Harvest Target: 1004"
## [1] "queue"
## [1] 2
## attr(,"unit")
## [1] "year"
## [1] 0
## [1] 0
## [1] "Harvest Target: 1024"
## [1] "queue"
## [1] 2
## attr(,"unit")
## [1] "year"
## [1] 0
## [1] 0
## 2         growingStockCLUS updateGrowingStock 9            
## [1] "update at 2"
## 2         blockingCLUS     UpdateBlocks       10           
## [1] "update the blocks table"
## 2         forestryCLUS     save               20           
## 2         dataLoaderCLUS   removeDbCLUS       99
```

```
##    user  system elapsed 
##   69.75   13.95   94.80
```

# Events

## Flow Chart


```r
library(SpaDES.core)
eventDiagram(mysimout)
```

<!--html_preserve--><div id="htmlwidget-ac19887cc8e8e424578a" style="width:1000px;height:390px;" class="DiagrammeR html-widget"></div>
<script type="application/json" data-for="htmlwidget-ac19887cc8e8e424578a">{"x":{"diagram":"gantt\ndateFormat  YYYY-MM-DD\ntitle SpaDES event diagram\nsection  checkpoint \n init:done,checkpoint1,2019-05-28,2019-06-01\nsection  save \n init:done,save1,2019-05-28,2019-06-01\nsection  load \n init:done,load1,2019-05-28,2019-06-01\nsection  dataLoaderCLUS \n init:done,dataLoaderCLUS1,2019-05-28,2019-06-01\nremoveDbCLUS:active,dataLoaderCLUS2,2021-05-27,2021-06-01\nsection  growingStockCLUS \n init:done,growingStockCLUS1,2019-05-28,2019-06-01\nupdateGrowingStock:active,growingStockCLUS2,2020-05-27,2020-05-31\nupdateGrowingStock:active,growingStockCLUS3,2021-05-27,2021-06-01\nsection  forestryCLUS \n init:done,forestryCLUS1,2019-05-28,2019-06-01\nschedule:active,forestryCLUS2,2020-05-27,2020-05-31\nschedule:active,forestryCLUS3,2021-05-27,2021-06-01\nsave:active,forestryCLUS4,2021-05-27,2021-06-01\nsection  blockingCLUS \n init:done,blockingCLUS1,2019-05-28,2019-06-01\nUpdateBlocks:active,blockingCLUS2,2020-05-27,2020-05-31\nUpdateBlocks:active,blockingCLUS3,2021-05-27,2021-06-01\n"},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

## Algorithum

The general algorithum (pseudo-code) follows as:

`compartment_list`= SELECT zones FROM compartments WHERE target > 0 ORDER BY priority_compartment

FOR compartment_selected in `compartment_list`
`queue`<- SELECT pixelid, blockid FROM pixels WHERE 
            compartment = compartment_selected AND thlb > 0 AND constraint = 0                 ORDER BY priority
               
IF (`queue` > 0 )
  check constraints
ELSE 
  NEXT
        

# Data dependencies

## Input data

A SQLite db is required (output from dataloaderCLUS). A harvestFlow data.table object that includes the forest management unit (i.e., compartment, aka - 'supply block'), the partition from which the harvest flow applies (e.x., All dead pine); the year at which the flow applies and the amount of volume.

## Output data

A list of landings || blocks from when they are harvested.

# Links to other modules

dataloaderCLUS is required.

