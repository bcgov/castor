## growingStockCastor

### What it does

Updates various yield attributes using a linear interpolation of a standardized yield curve. It also schedules maintenance to the castordb. Lastly, it increments the age of the forest. For example, age of the forest is incremented based on the updateInterval. Various indexes are re-created and the database is vacuumed to increase query efficiency. 

#### Management levers

* Link to the growth and yield assumptions

### Input Parameters

* *periodLength*. The length of the time period. Ex, 1 year, 5 year. Default is 5 year.
* *vacuumInterval*. The interval when the database should be vacuumed. Default is 5 year.
* *maxYieldAge*. Maximum age of the yield curves. Default is 350 years

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