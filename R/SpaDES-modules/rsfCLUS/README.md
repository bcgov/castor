## rsfCLUS

### What it does

Dynamically predicts various resource selection functions (RSF) for each specified time period in the simulation. The time at which an RSF is predicted is specified by the user. Three main types of variables are used to predict an RSF: static variables that do not change in the simulation, dynamic variables that require updating in the simulation, and 'distance to' variables that calculate a distance to a feature that can be either static or dynamic.

This module checks if the rsf table in [clusdb](https://github.com/bcgov/clus/tree/master/R/SpaDES-modules/dataLoaderCLUS) is populated or not. If this table has not been populated then the various explantory variables (X-variables) are stored into clusdb.

#### Management levers

* Wildlife indicators being tracked through out the simulation.

### Input Parameters

* *calculateInterval*. The interval from which to calculate the RSF(s). Default = 1 (yearly).
* *criticalHabitatTable*. The name of the raster that stores critical habitat zones for reporting the RSF predictions
* *rsf_coeff*.The name of the table that stores the rsf coefficients and variable types
* *writeRSFRasters*. A logical parameter for determining if the model should write the RSF predicted rasters to disk.

#### Data Needs

RSF models to be fit and formatted into the rsf_coeff table. 

### Outputs

* Raster of RSFs
* RSF report which includes the sum of predicted RSF scores within the critical habitat zones

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