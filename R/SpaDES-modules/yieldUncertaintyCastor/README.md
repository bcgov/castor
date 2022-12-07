## yieldUncertaintyCastor 

### What it does

Calibrates yield models used in BC to provide valuable information about timber projection uncertainty. This module builds on Robinson et al.'s (2016) approach by calibrating timber volume estimates using scale (observed) volume data to account for the uncertainty from both the forest inventory and the growth model. This module supports concepts of adaptive forest management in BC, by identifying factors leading to greater or lesser uncertainty around strategic decisions. For example, this module may inform a more robust AAC decision, by helping the Chief Forester understand situations where uncertainty in yields could lead to over or under estimates in AAC. This module will be used in the castor simulator model to provide an estimate of volume yield uncertainty in the quantification of impacts from caribou conservation activities on harvest flows. 

#### Management levers

* Uncertainty from the interactions of inventory and growth model on total harvest

* Used to indicate differences among alternative scenarios

### Input Parameters

#### Data Needs

A calibration model needs to be fit using [observed scale information](https://www2.gov.bc.ca/gov/content/industry/forestry/competitive-forest-industry/timber-pricing/harvest-billing-system) commonly collected following harvesting operations or possibly plot data. See [here](https://github.com/bcgov/castor/blob/master/R/Params/linkHBS_VRI_Calibtation.md) 

##### Rasters

* Covariates - used to adjust the parameter of the conditional distribtution (e.g., Stand height, elevation, etc)

##### Objects

* [gamlss](https://cran.r-project.org/web/packages/gamlss/gamlss.pdf) object used to make predictions<<<This may not be needed -- could just hard code this object?>>>. These models use a distributional regression approach where all parameters of the conditional response distribution are modelled. This object also extends 'nlme'.

* dataset used to derive the gamlss object. This is needed to make predictions

### Outputs

* Yield uncertainty report which includes the calibrated volume, the probability the target volume is attained and 5th and 95th percentiles of the total harvest (over a time period) 

### Licence

    Copyright 2023 Province of British Columbia

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    
### References

Robinson, A.P., McLarin, M. and Moss, I., 2016. A simple way to incorporate uncertainty and risk into forest harvest scheduling. Forest Ecology and Management, 359, pp.11-18.