## roadCastor

### What it does

Simulates the development of roads for transporting timber. Three approaches can be simulated: 1) as the crow flies; 2) as the wolf runs; and 3) a minimum spanning tree (see [here](https://github.com/bcgov/castor/blob/master/reports/roads/draft-CLUS-roads.md) )

>porting this code over to R package roads: https://github.com/LandSciTech/roads ???

#### Management levers

* Restricting roading - spatially remove the ability to develop roads 

### Input Parameters

* *roadMethod*. The method to simulate roads. Currently, the choice of: as the crow flies (called 'snap'); 2) as the wolf runs (called 'lcp'); and 3) a minimum spanning tree (called 'mst').
* *nameRoads*. The name of the raster that contains the roads.
* *nameCostSurfaceRas*. Name of the raster that contains the cost surface for simulating roads with 'snap' or 'mst'. This cost surface can be estimated from either the interior or coast appraisal mannuals.
* *Landings*. Spatial locations where new landings will be developed for stacking timber.

#### Data Needs

Raster of Cost surface is needed. Currently using interior and coast appraisal mannuals to economically determine the cost of roads. These include dollar value costing for stream crossings, pipeline crossings, slope, moisture, while netting out non-roadable areas like lakes and mountain tops. 

### Outputs

* Raster of simulated roads for each year of the simulation.

## Licence

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