[![img](https://img.shields.io/badge/Lifecycle-Experimental-339999)](https://github.com/bcgov/repomountie/blob/master/doc/lifecycle-badges.md)
## Castor - Forest and Land Use Simulator
### Description and Usage
Castor is a spatial, large-scale analytical model for simulating forest harvest and it's potential influence on other forest values (e.g., wildlife habitat). It was first designed to support the government of British Columbia's caribou recovery program, by providing a tool to spatially estimate future forestry and caribou habitat conditions under hypothetical, alternative forest management regimes. It has since been and will continue to be expanded and developed to examine other forest values. 

The code in this GitHub is open-source and provides a transparent record of the Castor model. Anyone is free to download, reproduce and apply the model. However, this is not a self-contained piece of software. In particular, using Castor as-is requires accessing our data management framework, or modifying the code here to work with your preferred data structure. The repository here also consists of code to create backend apps to develop Castor model scenarios and review outputs. 


### Getting Help or Reporting an Issue
We've developed a [Wiki page](https://github.com/bcgov/castor/wiki) to help you with understanding the structure and functions of the Castor model. We are also working on a [tutorial](https://github.com/bcgov/castor/blob/main/documentation/clus_quick_start_tutorial.md) that will describe the steps to get a basic Castor model up and running. 

Once you are familiar with Castor, if you find any errors with the code, please submit them via the GitHub  ["Issues"](https://github.com/bcgov/castor/issues) tab.

For more information on working with the Castor team and model for a forest management problem, please don't hesitate to contact Tyler Muhly (tyler.muhly@gov.bc.ca), Team Lead, Strategic Analysis, Forest Analysis and Inventory Branch, Office of the Chief Forester, Ministry of Forests.  

### Core Team
Tyler Muhly, Team Lead, Strategic Analysis, Forest Analysis and Inventory Branch, Office of the Chief Forester, Ministry of Forests

Kyle Lochhead, Ecological Modeling Specialist, Forest Analysis and Inventory Branch, Office of the Chief Forester, Ministry of Forests

Elizabeth Kleynhans, Ecological Modeling Specialist, Forest Analysis and Inventory Branch, Office of the Chief Forester, Ministry of Forests

### Contributors
Mike Fowler, Spatial Data Analyst, Forest Analysis and Inventory Branch, Office of the Chief Forester, Ministry of Forests

Cora Skaien, Ecological Modeling Specialist, Forest Analysis and Inventory Branch, Office of the Chief Forester, Ministry of Forests

### Requirements
The model is coded using the R programming language. Thus, you will need to [download program R](https://cran.r-project.org/bin/windows/base/) to work with the code. We also recommend downloading the free version of [RStudio](https://rstudio.com/products/rstudio/download/), which provides a nice integrated development environment for working with R. 

R consists of many 'packages' developed by R users that bundle-up specific functions for manipulating, analyzing and visualizing data. The packages needed to run Castor are documented in the respective pieces of code where they are used, and we do not list them all here. However, we note here that you will need the open source simulation engine ['SpaDES'](https://spades.predictiveecology.org/) R package to use Castor. We recommend familiarizing yourself with this package if you want to use Castor.

### License
Copyright 2020-2021 Province of British Columbia

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at 

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

### Purpose of Castor
The purpose of Castor is *compare* alternative *plausible* scenarios of various human-centric forestry decisions in a simulation environment. The relative comparison between scenarios is the true value/purpose of these analyses, whereas, the absolute values of the outcomes should be used with caution. What is deemed *plausible* is left to the quality of the information being used and the resulting logic of the human-centric decisions about harvest scheduling.  

###	Assumptions and Overview
The Castor model is a spatial strategic model used for quantifying and accounting the impacts of forest management on various indicators over long time periods. Thus, its ability to design site specific plans and their corresponding operations is very limited. Fine scale, operational decisions are important but their complexity is simplified in Castor to meet the resolution (e.g., 1 ha)  and scale (e.g., multiple Timber Supply Areas, very large landscapes (> 1 M ha), long time horizons > 100 years) of the study area. The model uses empirical yield curves (from provincial growth models) to project the forest inventory (VRI) attributes into the future. Human-centric decisions around harvest scheduling are the main assumptions which include WHAT, WHERE, WHEN and HOW much timber to harvest. The model is given a demand of timber volume for each time period (i.e., the HOW much) and the goal of Castor is to “find” that timber volume while meeting various constraints like no harvest areas and aspatial land cover constraints. Castor uses some rules around minimum harvest criteria (i.e, merchantable volume > 150 m3 per ha, etc) to determine WHAT gets harvested. Castor uses a priority (closest to disturbance, oldest age, etc) to figure out the WHERE and WHEN to “find” the timber volume in a specific time period. Castor is “greedy” in that it can’t figure out how to find the optimal harvest schedule. The result of a Castor simulation is a *plausible* harvesting sequence that allows cutblock size, adjacency and other spatial considerations.


