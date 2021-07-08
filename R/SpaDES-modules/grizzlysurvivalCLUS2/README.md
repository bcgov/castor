## grizzlysurvivalCLUS

### What it does

The purpose of this module is to model the relationship between grizzly bear survival and forestry
development. The goal is to develop an understanding of how current and future road development for forestry might influence grizzly bear populations. 

Throughout western North America ([McLellan and Shackleton 1988](https://www.jstor.org/stable/2403836); [McLellan 1989](https://cdnsciencepub.com/doi/abs/10.1139/z89-264); [McLellan 1990](https://www.jstor.org/stable/3872902); [Mace et al. 1996](https://www.jstor.org/stable/2404779); [Nielsen et al. 2004](https://www.sciencedirect.com/science/article/pii/S0378112704003457); [Proctor et al. 2004](https://bioone.org/journals/ursus/volume-15/issue-2/1537-6176(2004)015%3C0145:ACAOMO%3E2.0.CO;2/A-comparative-analysis-of-management-options-for-grizzly-bear-conservation/10.2192/1537-6176(2004)015%3C0145:ACAOMO%3E2.0.CO;2.short); [Boulanger and Stenhouse (2014)](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0115535)), research shows that roads facilitate interactions between humans and grizzly bear that can result in grizzly bear mortalities. Grizzly bear mortality rates may reach unsustainable levels (i.e., causing population declines) once road density increases beyond 0.75 km/km^2^ ([Boulanger and Stenhouse (2014)](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0115535)), and a road density less than 0.6 km/km^2^ is a target for grizzly bear conservation units in Alberta (Alberta Grizzly Bear Recovery Plan 2008) and is a recognized threshold of concern in [British  Columbia](http://www.env.gov.bc.ca/soe/indicators/plants-and-animals/grizzly-bears.html).  

### Input Parameters
* *rasterGBPU* - Name of the raster of the grizzly beer population units raster that is stored in the Postgres database. see [here](https://github.com/bcgov/clus/blob/master/R/Params/grizzly_bear_population_units.Rmd) 
* *tableGBPU* - The look up table of grizzly beer population unit names for each unique raster values. see [here](https://github.com/bcgov/clus/blob/master/R/Params/grizzly_bear_population_units.Rmd)
* *roadDensity* - The road desnity to assign to 'roaded' 1 ha pixels in the model. Recommended values is 10km/km^2^


### Outputs

* grizzly survival report - estimate of the adult female grizzly bear survival rates for each grizzly bear population unit *rasterGBPU* that overlaps the area of interest (e.g., timebr suppyl area) for each time period of the simulation.

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

















## Module Methods and Parameters
Here I adapt a model developed by [Boulanger and Stenhouse (2014)](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0115535) that related grizzly bear survival rates to their exposure to roads in a landscape in Alberta with active forestry to estimate the effects of roads on grizzly bear survival and population trend.  

The module is broken into two steps:
1. Estimate the amount of 'roaded' areas in a grizzly bear population unit, and assign a road density to the unit.
2. Estimate the survival rate of female grizzly bears in a population unit from road density.

### Grizzly Bear Population Units
The module first obtains grizzly bear management units (i.e., [grizzly bear population units, or GBPUs](https://catalogue.data.gov.bc.ca/dataset/caa22f7a-87df-4f31-89e0-d5295ec5c725)) as defined by the government of British Columbia. A raster parameter (*rasterGBPU*) with a corresponding look-up table parameter (*tableGBPU*) define the location and name of GBPUs in the province. 

### Estimate of Road Densities by Grizzly Bear Population Unit
The [Boulanger and Stenhouse (2014)](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0115535) model calculates survival as a function of average road density within 300 m of grizzly bear locations for the duration that a bear was tracked with a GPS collar. However, the CLUS model resolution (i.e., pixel size) is 1 ha, and we simply estimate whether a pixel is 'roaded' (i.e., contains a road) or not. Thus, we need to assign a road density to 'roaded' pixels. Here we set the road density of roaded pixels (i.e., the *roadDensity* parameter) to 10km/km^2^.  Obviously, in reality there will be variety of road densities in a roaded pixels, but we believe 10km/km^2^ represents a reasonable 'standard' density. A density of 10km/km^2^ is equivalent to a 100m road in a pixel, which is the minimum length of road needed to traverse a pixel. In addition, this parameter can be adjusted by the user.  

In addition, we do not calculate density in a 300 m radius area, but simply within a single 1 ha pixel. Thus, at a fine scale, our data do not match the resolution of the [Boulanger and Stenhouse (2014)](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0115535) model. However, [Boulanger and Stenhouse (2014)](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0115535) estimated grizzly bear survival rates as a function of average road densities at grizzly bear locations, and therefore, while the 'local' road densities we estimate here are likely less precise, ultimately this may not influence the averages in a significant way. Furthermore, we believe that measuring road density within a distance of 100 m is reasonable given that [McLellan (2015)](https://wildlife.onlinelibrary.wiley.com/doi/abs/10.1002/jwmg.896) found that 84% of human-caused grizzly bear deaths were less than 120 m from a road in southeast British Columbia and [Ciarniello et al. (2009)](https://bioone.org/journals/Wildlife-Biology/volume-15/issue-3/08-080/Comparison-of-Grizzly-Bear-Ursus-arctos-Demographics-in-Wilderness-Mountains/10.2981/08-080.short)
found that for monitored grizzly bear, seven of nine human caused mortalities in central British Columbia were less than 100 m from a road. Thus, mortality events themselves appear to be related to being in very close proximity to roads. 

To estimate road density in a GBPU, the module counts the number of 'roaded' pixels and multiplies them by the *roadDensity* parameter (10km/km^2^), then divides that by the total number of pixels (roaded + unroaded) in the GBPU.

### Estimate of Grizzly Bear Survival Rate
The module uses the [Boulanger and Stenhouse (2014)](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0115535) model from Figure 2 to estimate adult female survival rates. Here we focus on adult females because of their importance to population dynamics, but all grizzly bear age and sex classes show a similar negative relationship between survival and road density. The equations for figure 2 are not included in [Boulanger and Stenhouse (2014)](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0115535), therefore we approximate it in this module using the equation:

S = 1 / (1 + exp (-3.9 + (D * 1.06)) 

where S = survival rate and D = road density. Survival rate  is 0.980 at 0km/km^2^ road density, 0.945 at a road density of 1km/km^2^ and 0.856 at a road density of 2km/km^2^.













