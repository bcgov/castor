## survivalCLUS

### What it does

Estimates the survival of adult female caribou based on the proportion of early seral (i.e., 1 to 40 years) forest as presented by [Wittmer et al. (2007)](https://besjournals.onlinelibrary.wiley.com/doi/full/10.1111/j.1365-2656.2007.01220.x).(see details in '/R/caribou_habitat/25_Wittmer_caribou_model') on southern mountain caribou (Designatable Unit 9). Specifically, we apply the population-scale model that Wittmer et al. (2007) developed. 

The module requires input on forest age (output from the CLUS forestry modules) and density of caribou herds. Currently, the caribou herd density parameter is static and must be set by the user. A caribou herd raster was derived from the provincial caribou herd boundary data set (see details in "/R/Params/caribou_herd_raster.rmd").

We caution against using the model outside of the southern mountain caribou population range, as it was developed using data only from that population, and thus may not be applicable to other parts of BC. 

#### Management levers

* Adult caribou female survival as an indicator being tracked through out the simulation.

### Input Parameters

* *calculateInterval*. The interval from which to calculate the RSF(s). Default = 1 (yearly).
* *caribou_herd_density*. Caribou herd density for adjusting the Wittmer et al. survival model.
* *nameRasCaribouHerd*. Name of the raster of the caribou herd boundaries raster that is stored in the psql clusdb. see [here](https://github.com/bcgov/clus/blob/master/R/Params/caribou_management_areas.Rmd) 
* *tableCaribouHerd*.The look up table to convert raster values to caribou herd name labels. The two values required are value and herd_name. see [here](https://github.com/bcgov/clus/blob/master/R/Params/caribou_management_areas.Rmd)

#### Data Needs

Proportion of early seral habitat.

### Outputs

* Survival report - estimate of the caribou adult female survival for each herd in the *nameRasCaribouHerd* for each time period of the simulation.

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