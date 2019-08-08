---
title: "Review of Wolf Density Models and Moose Density and Habtiat Thresholds Needed to Achieve Low Predation on Caribou"
author: "Tyler Muhly"
date: "07/08/2019"
output: 
  html_document:
    keep_md: true
---



## Introduction
Federal recovery strategies for caribou have recommended wolf density thresholds for certain types of critical habitat. Specifcally, a threshold of less than 3 wolves per 1000 km ^2^ has been recommended for some southern moutnain cariobu 'matrix' habtiat types ([Environment Canada 2014](https://www.registrelep-sararegistry.gc.ca/virtual_sara/files/plans/rs_woodland_caribou_bois_s_mtn_pop_0114_e.pdf)). In addition, habtiat 'disturbance' threholds have been recommended for other types of ctritical habitat, with the implict assumption that staying below these thresholds will maintain habitats with low enough predator densities as to allow for stable or increasing cariobu popualtions. Specifically, a threshold of 35% 'disturbance' (i.e., area of cutblocks and roads buffered by 500m and burns) has been recommended for low elevation witner range and some matrix habtiat types ([Environment Canada 2014](https://www.registrelep-sararegistry.gc.ca/virtual_sara/files/plans/rs_woodland_caribou_bois_s_mtn_pop_0114_e.pdf)).

Here I attempt to estimate what moose density we likely need to acheieve to hit a target of 3 wolves per 1,000 km^2^ using exisitng pulbished wolf density models. I also review current moose density in teh CHilctoin region of British COlumbia and estimate wolf densities using these models. I then use a statiscial model that estimates mosose density as a fucntion fo variosu types of habtiat disturabnces (i.e., cutblocks, fires and roads) to estimate habitat conditions necesary to acheieve these moose densities. 

## Estimating Wolf Density from Moose Density
Seevral models have been developed to estimate wolf density from ungulate biomass or density. HEre I review some commonly cited and relevant models to British Columbia. 

### The [Fuller et al. (2003)](https://www.press.uchicago.edu/ucp/books/book/chicago/W/bo3641392.html) Model 
[Fuller et al. (2003)](https://www.press.uchicago.edu/ucp/books/book/chicago/W/bo3641392.html) developed an equation to estimate wolf density from an ungulate biomass index based on a variety of resarch studies form across North America. The equation applies an index factor to measured or estimated ungulate densities (animals/km^2^), where larger factors are applied to ungulates (i.e., moose density is multiplied by 6, elk density is multiplied by 3 and deer density is multiplied by 1). Wolf density (wolves/1,000 km ^2^) is then calculated with the equation: $W = 3.5 + (UB * 3.3)$, where W = wolf desnity and UB euqals total estimated ungulate biomass in the area of interest. The estiamted moose density to achieve estimated wolf density targets, assumign no oither ungulates are available in teh system, (or that wolves are not predating on other ungulates there) is illustrated in Figure 1. However, explicit in the [Fuller et al. (2003)](https://www.press.uchicago.edu/ucp/books/book/chicago/W/bo3641392.html) model is that there are a minimum of 3.5 wolves/1,000km^2^, regardless of ungulate biomass. This models suggests a very low, essentially near 0 ungulate density is necessary to achieve threhsolds below 3 wolves/1,000km^2^.
<div class="figure" style="text-align: left">
<img src="03_moose_density_summary_files/figure-html/Fuller Wolf Density Equation-1.png" alt="Figure 1. Estimated Wolf Density as a Function of Moose Density Using the Fuller et al. (2003) Model"  />
<p class="caption">Figure 1. Estimated Wolf Density as a Function of Moose Density Using the Fuller et al. (2003) Model</p>
</div>

### The [Kuzyk and Hatter (2014)](https://wildlife.onlinelibrary.wiley.com/doi/abs/10.1002/wsb.475) Model 
[Kuzyk and Hatter (2014)](https://wildlife.onlinelibrary.wiley.com/doi/abs/10.1002/wsb.475) developed a statistical model of wolf density based on estiamted ungulate biomasss in regions of British COlumiba. Similar to [Fuller et al. (2003)](https://www.press.uchicago.edu/ucp/books/book/chicago/W/bo3641392.html), they calcualted wolf density as a fucntion of ungualte biomass, using the same ungulate biomass index. Wolf density (wolves/1,000 km ^2^) is calculated with the equation: $W = (UB * 5.4) - (UB^2^ * 3.3)$, where W = wolf desnity and UB euqals total estimated ungulate biomass in the area of interest. The estiamted moose density to achieve estimated wolf density targets, assumign no oither ungulates are available in the region, (or that wolves are not predating on other ungulates there) is illustrated in Figure 2. This model is perhaps more practical than the [Fuller et al. (2003)](https://www.press.uchicago.edu/ucp/books/book/chicago/W/bo3641392.html) model for estimatign wolf density in low ungulaet biomass regions because areas with no unglate biomass would have no wolves. This models suggests a density of approximately 0.09 moose/km^2^ is necessary to achieve thresholds below 3 wolves/1,000km^2^.
<div class="figure" style="text-align: left">
<img src="03_moose_density_summary_files/figure-html/Kuzyk and Hatter Wolf Density Equation-1.png" alt="Figure 2. Estimated Wolf Density as a Function of Moose Density Using the Kuzyk and Hatter (2014) Model"  />
<p class="caption">Figure 2. Estimated Wolf Density as a Function of Moose Density Using the Kuzyk and Hatter (2014) Model</p>
</div>

### The [Messier (1994)](https://www.jstor.org/stable/1939551?seq=1#page_scan_tab_contents) Model 
[Messier (1994)](https://www.jstor.org/stable/1939551?seq=1#page_scan_tab_contents) developed a statistical model of wolf density from moose desnity using data from across North America where moose were the primary prey of wolves. He calcualted wolf density as a function of moose density using a hyperbolic, Michaelis-Menten functio, using the equation: $W = (58.7 * (M - 0.03)) / (M + 0.76)$, where W = wolf density (wolves/1,000km^2^)and M = estimated moose density (moose/km^2^).The estiamted moose density to achieve estimated wolf density targets is illustrated in Figure 3.

This model allows for negative wolf densities at very low mosoe desnities, and requires a moose desnity greater than 0.03 moose/km^2^ to sustain wolves. THis model is also useful for estimatign wolf density in low ungulate biomass areas, also in areas where moose are known to be the doimannt prey of wolves. It is likely not useful in areas where otehr ungulaets are hte primary prey for wolves. This models suggests a density of less than approximately 0.08 moose/km^2^ is necessary to achieve thresholds below 3 wolves/1,000km^2^.

<div class="figure" style="text-align: left">
<img src="03_moose_density_summary_files/figure-html/Messier 1994 wolf density model-1.png" alt="Figure 3. Estimated Wolf Density as a Function of Moose Density Using the Messier (1994) Model"  />
<p class="caption">Figure 3. Estimated Wolf Density as a Function of Moose Density Using the Messier (1994) Model</p>
</div>

### Estimated Wolf Densities in the Chilcotin Region of British Columbia
Caribou recovery planning has begun in the Chilcotin local population unit (LPU). This LPU consists of the Itcha-Ilgachuz, Rainbows and Charlotte Alplands caribou herds, and constitutes the southernmost LPU of the Northern Mountain Caribou Designatible Unit (DU 7). These caribou are classified as *Threatened* under Canada's *Species at Risk Act*. 

The Itcha-Ilgachuz herd is considered to be of significant conservation importance provincially because it is the largest and highest density herd in west-central British Columbia (cite herd plan). However, the herd declined 17.2% annually between 2014 and 2018, and the habitat has experienced significant amounts of timber harvesting, associated road development, wildfire and mountain pine beetle infestations (cite herd plan). In addition, the 2019 population census showed a 40% popualion decline from 2018, and at that rate of decline, the herd would be functionally extirpated (i.e., less than 20 animals) in eight years (Carolyn Shores, Provincial Cariobu Biologist, pers. comm.). 

There is an  urgent need to develop an effective recovery plan for the Chilcotin LPU caribou. A critical component of this is managing wolf density directly (i.e., culling), but also indireclty by managing moose via their habitat. Addtional habtiat protections might be considered with the intent of minimizing habitat disturabnce so that moose densities adn ultimately wolf densiites are maitnained at low levels. 

Estimated moose desnities form aerial surveys done in wildlife managmen units (WMUs) of the Chilcotin region are described in Table 1. I estimated wolf densities using the three models described above and averaged them. The models suggest that wolf densities were never below 3 wolves/1,000km^2^ in any of the WMUs over the periods that they were surveyed. The lowest averaged estimates of wolf density were in WMUs 5-02-A in 1996 (4 wolves/1,000km^2^), 5-04 in 2012 (6 wolves/1,000km^2^), and 5-15-C in 2008 (5 wolves/1,000km^2^). The median wolf density estimate in the region throughout the surbvey period was 16 wolves/1,000km^2^, suggesting that wolf densities have generally been pretty high.  

<table class="table table-striped table-hover table-condensed" style="width: auto !important; ">
<caption>Table 1. Wolf desnity esitmates calcualted from pulbished modles and estimated moose densities form aerial surveys in teh CHilctoin region of Brtisih Columbia.</caption>
 <thead>
  <tr>
   <th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;"> WMU </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> SurveyYear </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> MooseDensityKm2 </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> WolfDensityFuller </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> WolfDensityKuzyk </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> WolfDensityMessier </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> WolfDensityAverage </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> 5-01 </td>
   <td style="text-align:right;"> 2015 </td>
   <td style="text-align:right;"> 0.360 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 13 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-01 </td>
   <td style="text-align:right;"> 2000 </td>
   <td style="text-align:right;"> 0.320 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 12 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-01 </td>
   <td style="text-align:right;"> 1996 </td>
   <td style="text-align:right;"> 0.440 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 15 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-02-A </td>
   <td style="text-align:right;"> 2014 </td>
   <td style="text-align:right;"> 0.330 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 12 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-02-A </td>
   <td style="text-align:right;"> 2001 </td>
   <td style="text-align:right;"> 0.220 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 9 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-02-A </td>
   <td style="text-align:right;"> 1998 </td>
   <td style="text-align:right;"> 0.260 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-02-A </td>
   <td style="text-align:right;"> 1996 </td>
   <td style="text-align:right;"> 0.100 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 4 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-02-B </td>
   <td style="text-align:right;"> 2018 </td>
   <td style="text-align:right;"> 0.460 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 16 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-02-B </td>
   <td style="text-align:right;"> 2006 </td>
   <td style="text-align:right;"> 0.390 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:right;"> 14 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-02-B </td>
   <td style="text-align:right;"> 2000 </td>
   <td style="text-align:right;"> 0.590 </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 24 </td>
   <td style="text-align:right;"> 19 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-02-B </td>
   <td style="text-align:right;"> 1996 </td>
   <td style="text-align:right;"> 0.730 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 28 </td>
   <td style="text-align:right;"> 22 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-02-B </td>
   <td style="text-align:right;"> 1994 </td>
   <td style="text-align:right;"> 1.420 </td>
   <td style="text-align:right;"> 32 </td>
   <td style="text-align:right;"> 34 </td>
   <td style="text-align:right;"> 37 </td>
   <td style="text-align:right;"> 34 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-02-C </td>
   <td style="text-align:right;"> 2019 </td>
   <td style="text-align:right;"> 0.370 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:right;"> 13 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-02-C </td>
   <td style="text-align:right;"> 2011 </td>
   <td style="text-align:right;"> 0.510 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 17 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-02-C </td>
   <td style="text-align:right;"> 2001 </td>
   <td style="text-align:right;"> 0.620 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:right;"> 25 </td>
   <td style="text-align:right;"> 20 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-02-C </td>
   <td style="text-align:right;"> 1997 </td>
   <td style="text-align:right;"> 0.300 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 11 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-02-C </td>
   <td style="text-align:right;"> 1994 </td>
   <td style="text-align:right;"> 0.560 </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 24 </td>
   <td style="text-align:right;"> 18 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-02-D </td>
   <td style="text-align:right;"> 2014 </td>
   <td style="text-align:right;"> 0.860 </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 23 </td>
   <td style="text-align:right;"> 30 </td>
   <td style="text-align:right;"> 25 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-02-D </td>
   <td style="text-align:right;"> 1999 </td>
   <td style="text-align:right;"> 0.670 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 26 </td>
   <td style="text-align:right;"> 21 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-02-D </td>
   <td style="text-align:right;"> 1994 </td>
   <td style="text-align:right;"> 1.190 </td>
   <td style="text-align:right;"> 27 </td>
   <td style="text-align:right;"> 30 </td>
   <td style="text-align:right;"> 35 </td>
   <td style="text-align:right;"> 31 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-03 </td>
   <td style="text-align:right;"> 2019 </td>
   <td style="text-align:right;"> 0.231 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 9 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-03 </td>
   <td style="text-align:right;"> 1997 </td>
   <td style="text-align:right;"> 0.350 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 13 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-04 </td>
   <td style="text-align:right;"> 2017 </td>
   <td style="text-align:right;"> 0.220 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 9 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-04 </td>
   <td style="text-align:right;"> 2012 </td>
   <td style="text-align:right;"> 0.140 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 6 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-04 </td>
   <td style="text-align:right;"> 2005 </td>
   <td style="text-align:right;"> 0.290 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 11 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-04 </td>
   <td style="text-align:right;"> 1998 </td>
   <td style="text-align:right;"> 0.410 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 14 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-04 </td>
   <td style="text-align:right;"> 1995 </td>
   <td style="text-align:right;"> 0.390 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:right;"> 14 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-04 </td>
   <td style="text-align:right;"> 1994 </td>
   <td style="text-align:right;"> 0.710 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 27 </td>
   <td style="text-align:right;"> 22 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-06 </td>
   <td style="text-align:right;"> 1995 </td>
   <td style="text-align:right;"> 0.180 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 7 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-10 </td>
   <td style="text-align:right;"> 1995 </td>
   <td style="text-align:right;"> 0.260 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-12-B </td>
   <td style="text-align:right;"> 2012 </td>
   <td style="text-align:right;"> 0.230 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 9 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-12-B </td>
   <td style="text-align:right;"> 2002 </td>
   <td style="text-align:right;"> 0.580 </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 17 </td>
   <td style="text-align:right;"> 24 </td>
   <td style="text-align:right;"> 19 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-13-A </td>
   <td style="text-align:right;"> 2017 </td>
   <td style="text-align:right;"> 0.170 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 7 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-13-A </td>
   <td style="text-align:right;"> 2003 </td>
   <td style="text-align:right;"> 0.300 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 11 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-13-A </td>
   <td style="text-align:right;"> 1998 </td>
   <td style="text-align:right;"> 0.440 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 20 </td>
   <td style="text-align:right;"> 15 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-13-A </td>
   <td style="text-align:right;"> 1995 </td>
   <td style="text-align:right;"> 0.320 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 12 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-13-B </td>
   <td style="text-align:right;"> 2018 </td>
   <td style="text-align:right;"> 0.370 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 18 </td>
   <td style="text-align:right;"> 13 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-13-B </td>
   <td style="text-align:right;"> 1999 </td>
   <td style="text-align:right;"> 0.310 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 11 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-13-C </td>
   <td style="text-align:right;"> 2019 </td>
   <td style="text-align:right;"> 0.270 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-13-C </td>
   <td style="text-align:right;"> 2008 </td>
   <td style="text-align:right;"> 0.490 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 22 </td>
   <td style="text-align:right;"> 16 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-13-C </td>
   <td style="text-align:right;"> 1997 </td>
   <td style="text-align:right;"> 0.400 </td>
   <td style="text-align:right;"> 11 </td>
   <td style="text-align:right;"> 12 </td>
   <td style="text-align:right;"> 19 </td>
   <td style="text-align:right;"> 14 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-14 </td>
   <td style="text-align:right;"> 2019 </td>
   <td style="text-align:right;"> 0.261 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-14 </td>
   <td style="text-align:right;"> 2013 </td>
   <td style="text-align:right;"> 0.250 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 8 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 10 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-14 </td>
   <td style="text-align:right;"> 2001 </td>
   <td style="text-align:right;"> 0.460 </td>
   <td style="text-align:right;"> 13 </td>
   <td style="text-align:right;"> 14 </td>
   <td style="text-align:right;"> 21 </td>
   <td style="text-align:right;"> 16 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-14 </td>
   <td style="text-align:right;"> 1994 </td>
   <td style="text-align:right;"> 0.330 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 10 </td>
   <td style="text-align:right;"> 16 </td>
   <td style="text-align:right;"> 12 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-15-A </td>
   <td style="text-align:right;"> 2008 </td>
   <td style="text-align:right;"> 0.290 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 15 </td>
   <td style="text-align:right;"> 11 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-15-B </td>
   <td style="text-align:right;"> 2008 </td>
   <td style="text-align:right;"> 0.170 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 9 </td>
   <td style="text-align:right;"> 7 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-15-C </td>
   <td style="text-align:right;"> 2008 </td>
   <td style="text-align:right;"> 0.110 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 3 </td>
   <td style="text-align:right;"> 5 </td>
   <td style="text-align:right;"> 5 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> 5-15-D </td>
   <td style="text-align:right;"> 2004 </td>
   <td style="text-align:right;"> 0.130 </td>
   <td style="text-align:right;"> 6 </td>
   <td style="text-align:right;"> 4 </td>
   <td style="text-align:right;"> 7 </td>
   <td style="text-align:right;"> 6 </td>
  </tr>
</tbody>
</table>

### Estimated Moose Densities in Undisturbed Habitat in the Chilcotin Region
Moose density estimates were calculated from survey data collected between 1994 and 2019, a period during which disturabnce (i.e., forest harvest, fire and insect infestation) signfcianly inlfuenced the landscape. In apritcualr, these disturabnces likely influenced the availability and amount of forage available to moose. I fit a model 










