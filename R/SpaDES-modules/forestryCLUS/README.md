## forestryCLUS 

### What it does

forestryCLUS is a convenient calculator for massive spatial calculations. Simply put, this module projects the state of the forest described in [dataLoaderCLUS](https://github.com/bcgov/clus/tree/master/R/SpaDES-modules/dataLoaderCLUS) into the future by taking into account management constraints for harvesting and forest growth (via [growingStock CLUS](https://github.com/bcgov/clus/tree/master/R/SpaDES-modules/growingStockCLUS) ). It should be used to explore possible futures - to identify where and where not to harvest, explore the consequences of policy and test sensitivity. 

It was designed to provide rapid feeback - for exploring the decision space for caribou and forestry related impacts. The following diagram is a simple representation of these impacts. The solid arrows are positive impacts, while the dashed arrows are negative impacts.

![](data/CaribouNetwork.jpeg =200x)<!-- -->

#### Management levers

* Harvest flow targets - how much to cut in any given time period
* Harvest flow priority - what should be harvested first
* Constraints 

---

##### Constraints 

The various constraints applied within forest management scenarios include:

* *Land cover*. Percentage of zone to be above or below a given threshold for a particular forest attribute

* *No havesting*. Removing area from the thlb

* *Equivalent Clear Cut Area*. Constraining aggregated disturbance for watershed indicators.

* *Growing stock*. Forcing the future states of the forest to maintain a percentage of the current merchantable growing stock (i.e., standing volume)

The constraints table is a parent table with child tables inheriting the following structure:

    zoneid integer,
    reference_zone text COLLATE pg_catalog."default",
    ndt integer,
    variable text COLLATE pg_catalog."default",
    threshold double precision,
    type text COLLATE pg_catalog."default",
    percentage double precision,
    multi_condition text COLLATE pg_catalog."default"

zoneid = a foreign key that specifies the raster value identifying the  spatial boundary of the constraint.

reference_zone = the name of the corresponding raster that contains the zoneid e.g. rast.zone_cond_beo

ndt = natural disturbance type - required for BEO constraints. Can be left blank if not used.

percentage = the percent [0, 100] of the zoneid from which the constraint will be applied.

threshold = the value of the variable (see below) that determines the constraint.

type = refers to the inequality of the threshold {le (<=), ge (>=)}. An important note between 'le' and 'ge':

 if 'ge', the model sets the number of no harvest pixels = percentage*(total zone area) 
 if 'le', the model sets the number of no harvest pixels = (1-percentage)*(total zone area) 
 
**total zone area is calculated by CLUS.
 
Both {le, ge} set a no harvest flag to pixels that first meet the logic of the inequality statement and if there aren't enough pixels, the model sorts the remaining pixels in the zone according to the variable as either ASC with le or DESC with ge. 

An example, for a constraint with variable = age, type = ge, threshold = 12 and percentage = 10 for a zone with 100 ha -- The model will assign no harvesting for 10% of the zone (10 ha) in pixels with age > 12 and if there are not enough pixels with age > 12 to achieve 10 ha, the model will sort pixels within the zone according to age in a DESC fashion and select the remainder required. 

Conversely, if the type was then set to 'le' then the model will constrain no harvesting for 90% of the zone (90 ha) to pixels with age < 12 and if there are not enough pixels with age < 12 to achieve 90 ha, the model will sort pixels within the zone according to age in a ASC fashion and select the remainder required.

variable = the variable in the pixels table that is to be constraine upon. Note: there are three hard coded variables of interest: eca, dist and multi.

* eca = equivalent clear cut area. This variable uses growingstockCLUS to update its value through simulation time. All cases where eca is used require type = 'le'.

* dist = euclidean distance from a forestry disturbance. This variable uses disturbanceCalcCLUS to update its value through simulation time. All cases where dist is used require type = 'ge'.

* multi = multiple condition. This variable requires an sql statement in the multi_condition column e.g., age > 12 & blockid > 0. All cases where multi is used require type = 'ge'. Because more than one variable is used in the constraint, and if there are not enough pixels to meet the constraint, the order of the remaining pixels required will follow the order in which the mutli condition was set. Thus, for age > 12 & crown_closure > 50, the model will select the remainder from a sort as: age DESC, crown_closure DESC.

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