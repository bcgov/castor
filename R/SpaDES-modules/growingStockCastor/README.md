## growingStockCastor

### What it does

Updates various yield parameters using a linear interpolation and provides maintenance to the castordb. For example, age of the forest is incremented based on the updateInterval. Various indexes are re-created and the database is vacuumed to increase query efficiency. 

#### Management levers

* Growing stock constraint - maintain an amount of forest structure throughout the simulation

### Input Parameters

* *updateInterval*. Time period from which to update the yield parameters. e.g., yearly. Default = 1 year
    
#### Data Needs

Yield curves that describe the current projection and the transition of that projection following harvesting.

### Outputs

* growingStockReport - a report that describes the standing volume for each time period in the simulation.

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