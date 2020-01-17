## forestryCLUS 

### What it does

forestryCLUS is a convenient calculator for massive spatial calculations. Simply put, this module projects the state of the forest described in [dataLoaderCLUS](https://github.com/bcgov/clus/tree/master/R/SpaDES-modules/dataLoaderCLUS) into the future by taking into account management constraints for harvesting and forest growth (via [growingStock CLUS](https://github.com/bcgov/clus/tree/master/R/SpaDES-modules/growingStockCLUS) ). It should be used to explore possible futures - to identify where and where not to harvest, explore the consequences of policy and test sensitivity. 

It was designed to provide rapid feeback - for exploring the decision space for caribou and forestry related impacts. The following diagram is a simple representation of these impacts. The solid arrows are positive impacts, while the dashed arrows are negative impacts.

![](data/CaribouNetwork.jpeg)<!-- -->

#### Management levers

* Harvest flow targets - how much to cut in any given time period
* Harvest flow priority - what should be harvested first
* Constraints 
*Land cover*. Percentage of zone to be above or below a given threshold for a particular forest attribute
*No havesting*. Removing area from the thlb
*Equivalent Clear Cut Area*. Constraining aggregated disturbance for watershed indicators.
*Growing stck*. Forcing the future states of the forest to maintain a percentage of the current merchantable growing stock (i.e., standing volume)

### Input Parameters

* *clusdb*. Connection to clusdb - see [clusdb](https://github.com/bcgov/clus/tree/master/R/SpaDES-modules/dataLoaderCLUS)
* *useAdjacencyConstraint*. A logical variable determining if adjaceny constraints should be enforced or not. Default = FALSE.
* *harvestPriority*. The order in which harvest units are queued for harvesting. Greatest priority first (e.g., oldest or a priority from linear programming). DESC is decending, ASC is ascending
* *harvestFlow*. A table with the target harvest for a given time period and location.
* *scenario*. A description of the scenario being run.
* *calb_ymodel*. A gamma model for adjusting yields and calculating prediction intervals on timber volumes. see [here](https://github.com/bcgov/clus/blob/master/R/Params/linkHBS_VRI_Calibtation.md)
* *growingStockConstraint*. The percentage of standing merchantable timber that must be retained through out the planning horizon. values [0,1]

#### Data Needs

* *calb_ydata*. The dataset used to build the calb_ymodel. This is required for a monte carlo simulation of yield errors.

### Outputs

* Estimate of the yield uncertainty (probability the harvest flow will be acheived, 90% prediction interval)
* Harvesting report that tracks the growing stock, area harvested, volume harvested, avialable thlb for each year in the simulation
* Raster of harvested blocks (labeled by year they were harvested)
* Raster of the number of years over the simulation that the pixel was constrained to be harvested
* Landing locations where roading can be simulated

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