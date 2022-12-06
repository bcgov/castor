[![img](https://img.shields.io/badge/Lifecycle-Experimental-339999)](https://github.com/bcgov/repomountie/blob/master/doc/lifecycle-badges.md)
## Caribou and Land Use Simulator
### Description and Usage
The Caribou and Land Use Simulator (CLUS) is a spatial, large-scale analytical model for simulating forest harvest and it's potential influence on other forest values (e.g., wildlife habitat). It was first designed to support the government of British Columbia's caribou recovery program, by providing a tool to spatially estimate future forestry and caribou habitat conditions under hypothetical, alternative forest management regimes. It has since been and will continue to be expanded and developed to examine other forest values. 

The code in this github is open-source and provides a transparent record of the CLUS model. Anyone is free to download, reproduce and apply the model. However, this is not a self-contained piece of software. In particular, using CLUS as-is requires accessing our data management framework, or modifying the code here to work with your preferred data structure. The repository here also consists of code to create backend apps to develop CLUS model scenarios and review outputs. 


### Getting Help or Reporting an Issue
We've developed a [Wiki page](https://github.com/bcgov/clus/wiki) to help you with understanding the structure and functions of the CLUS model. We are also working on a [tutorial](https://github.com/bcgov/clus/blob/master/documentation/clus_quick_start_tutorial.md) that will describe the steps to get a basic CLUS model up and running. 

Once you are familiar with CLUS, if you find any errors with the code, please submit them via the github  ["Issues"](https://github.com/bcgov/clus/issues) tab.

For more information on working with the CLUS team to use the CLUS model for a forest management problem, please don't hesitate to contact Tyler Muhly (tyler.muhly@gov.bc.ca), Acting Team Lead, Strategic Analysis, Forest Analysis and Inventory Branch, Office of the Chief Forester, Ministry of Forests, Lands, Natural Resource Operations and Rural Development.  

### Core Team
Tyler Muhly, Team Lead, Strategic Analysis, Forest Analysis and Inventory Branch, Office of the Chief Forester, Ministry of Forests, Lands, Natural Resource Operations and Rural Development

Kyle Lochhead, Ecological Modeling Specialist, Forest Analysis and Inventory Branch, Office of the Chief Forester, Ministry of Forests, Lands, Natural Resource Operations and Rural Development

Elizabeth Kleynhans, Ecological Modeling Specialist, Forest Analysis and Inventory Branch, Office of the Chief Forester, Ministry of Forests, Lands, Natural Resource Operations and Rural Development

### Contributors
Mike Fowler, Spatial Data Analyst, Forest Analysis and Inventory Branch, Office of the Chief Forester, Ministry of Forests, Lands, Natural Resource Operations and Rural Development

Cora Skaien, Ecological Modeling Specialist, Forest Analysis and Inventory Branch, Office of the Chief Forester, Ministry of Forests, Lands, Natural Resource Operations and Rural Development

### Requirements
The model is coded using the R programming language. Thus, you will need to [download program R](https://cran.r-project.org/bin/windows/base/) to work with the code, but don't worry, it's free, open-source software. We also recommend downloading the free version of [RStudio](https://rstudio.com/products/rstudio/download/), which provides a nice integrated development environment for working with R. 

R consists of many 'packages' developed by R users that bundle-up specific functions for manipulating, analyzing and visualizing aspatail and spatial data. The packages needed to run CLUS are documented in the respective pieces of code where they are used, and we do not list them all here. However, we note here that you will need the open source simulation engine ['SpaDES'](https://spades.predictiveecology.org/) R package to use CLUS. We recommend familiarizing yourself with this package if you want to use CLUS.

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
