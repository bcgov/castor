## blockingCLUS

### What it does

Presents the logic for aggregating stands into harvestable units or cutblocks. Approached in two ways: 1) reactively during the simulation (termed 'dynamic') or 2) pre-determined during the intitialization of the simulation (termed 'pre'). 

#### Management levers

* Criteria for linking harvest block layout in the model- homogeneity of the harvest unit
* Patch size targets - distributions of disturbance sizes

### Required inputs

* Interval for simulating blocks
* Allowable variation within a block (see [here]() https://github.com/bcgov/clus/blob/master/reports/harvest/draft-CLUS-blocking.md))
* Zones to apply patch size constraints (e.g., Landscape units)
* Target patch size distribution (e.g., follow natural disturbance types)
* Raster for spread probability
* Raster of current cutblocks

### Outputs

* Raster of harvest units or blocks 

This module depends on dataloaderCLUS which involves a postgres db that stores rasters at the provincial extent

## Licence

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