## smcaribouAbundanceCLUS

### What it does

The purpose of this module is to estimate a southern mountain caribou (osuthern group) subpopulation abundance as a function of the amount of forested area disturbed by roads and cutblocks in each core and matrix critical habitat area. The goal is to develop an understanding of how current and future forestry development might influence caribou subpopulations.

For more details please see [Lochhead et al. (In Prep.)](citation).

### Input Parameters
* *nameRasSMCHerd* - Name of the raster of the southern mountain caribou critical habitat areas. See [here](https://github.com/bcgov/clus/blob/master/R/Params/caribou_southern_mtn_pop_model.Rmd) 

* *tableSMCCoeffs* - The look up table of the southern mountain caribou critical habitat name and type (core or matrix) for each unique raster value, and the random adn fixed effects coefficients for each subpopulation and model. See [here](https://github.com/bcgov/castor/blob/master/R/Params/caribou_southern_mtn_pop_model.Rmd)

* *calculateInterval*. The interval from which to calculate the RSF(s). Default = 1 (yearly).

### Outputs

* southern mountain caribou (southern group) subpopulation abundance report - estimate of abundance for each subpopulation *rasterSMCHab* that overlaps the area of interest (e.g., timber supply area) for each time period of the simulation.


## Licence

    Copyright 2022 Province of British Columbia

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

