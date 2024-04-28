## disturbanceCastor

### Required package versions of SpaDES to run these modules
The module needs *dataCastor*, *roadCastor* and *blockingCastor* to run.

### What it does

Calculates and simulates disturbances in various zones. This module takes the output from a series of *Castor* disturbance modules and calculates the area disturbed given specific assumptions surrounding the type of disturbance. For roads, a user defined buffer is used; whereas for cutblocks, an age parameter is used to define early when calculating the cumulative area of early cutblocks.

This was designed for measuring disturbance specific to forestry and caribou habitat, but could be modified to include other forms of disturbance metrics.

#### Management levers

* updates the 'dist' column in the pixels table. This column is calculated as the distance to forestry disturbances like cutblocks and roads.

### Input Parameters

* *criticalHabitatTable*
* *criticalHabRaster* Raster that describes the boundaries of the critical habitat
* *calculateInterval* The simulation time at which disturbance indicators are calculated
* *permDisturbanceRaster* Raster of permanent disturbances that won't get recovered,
* *recovery* The age of recovery for disturbances
* *distBuffer*

#### Data Needs

Any spatial or tabular data can be entered into the design of castordb. The minimum amount of data needed to run the simulation includes:

##### Rasters


##### Tables

### Outputs

### Licence

    Copyright 2024 Province of British Columbia

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.