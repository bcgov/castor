---
title: "Review of Wolf and Moose Density Models and their Use in Caribou Recovery Planning in the Chilcotin Region"
author: "Tyler Muhly"
date: "14/08/2019"
output: 
  html_document:
    keep_md: true
---



## Introduction
Federal recovery strategies for woodland caribou have recommended wolf density thresholds for some types of caribou critical habitat. Specifically, a threshold of less than 3 wolves per 1,000 km^2^ has been recommended for some southern mountain caribou habitat types ([Environment Canada 2014](https://www.registrelep-sararegistry.gc.ca/virtual_sara/files/plans/rs_woodland_caribou_bois_s_mtn_pop_0114_e.pdf)). In addition, habitat 'disturbance' thresholds have been recommended for other types of critical habitat, with the assumption that staying below these thresholds will maintain sustainable caribou populations. Specifically, a threshold of 35% 'disturbance' (i.e., percentage of area that is cutblocks and roads buffered by 500 m and burns) has been recommended for low elevation winter range and some matrix critical habitat types for southern mountain caribou ([Environment Canada 2014](https://www.registrelep-sararegistry.gc.ca/virtual_sara/files/plans/rs_woodland_caribou_bois_s_mtn_pop_0114_e.pdf)). Thus, to support effective caribou recovery planning there is a need to estimate predator (primarily wolf) densities in caribou recovery areas, and understand how habitat disturbances might influence wolf densities. 

Here I use existing, published wolf density models, and data on moose densities obtained from aerial surveys, to estimate wolf densities in wildlife management units (WMUs) in the Chilcotin region of British Columbia. I also use these models to estimate the moose densities necessary to achieve a target of 3 wolves per 1,000 km^2^. I then use the moose density data to develop a statistical model of moose density as a function of habitat, including 'disturbances' (i.e., cutblocks, burnt areas and roads). I use this model to estimate the influence of changing habitat disturbance conditions on moose and wolf densities. I discuss how these moose and wolf density models may be used to inform caribou recovery planning in the Chilcotin region of British Columbia.  

## Estimating Wolf Density from Moose Density
Several models have been developed to estimate wolf density from ungulate biomass or density data. Here I review some commonly cited and relevant models to British Columbia. 

### The [Fuller et al. (2003)](https://www.press.uchicago.edu/ucp/books/book/chicago/W/bo3641392.html) Model 
[Fuller et al. (2003)](https://www.press.uchicago.edu/ucp/books/book/chicago/W/bo3641392.html) developed a model to estimate wolf density from ungulate biomass using data collected across North America. The model applies a factor to calculate ungulate biomass from estimated ungulate densities (i.e., individuals/km^2^), where larger factors are applied to larger ungulates (i.e., moose density is multiplied by 6, elk density is multiplied by 3 and deer density is multiplied by 1). Wolf density (wolves/1,000 km ^2^) is then calculated with the equation: $$W = 3.5 + (UB * 3.3)$$ 
Here W = wolf density and UB = total estimated ungulate biomass in the area of interest. 

The modeled relationship between moose density and wolf density is illustrated in Figure 1 (assuming no other ungulates occur in the system or are hunted by wolves). Explicit in the [Fuller et al. (2003)](https://www.press.uchicago.edu/ucp/books/book/chicago/W/bo3641392.html) model is that there is a minimum threshold of 3.5 wolves/1,000 km^2^ in any wolf-ungulate system (i.e., the model intercept, at an ungulate biomass of 0, is 3.5 wolves/1,000 km^2^). Thus, this model suggests a very low, essentially 0 moose density is necessary to achieve landscapes with less than 3 wolves/1,000 km^2^.

<div class="figure" style="text-align: left">
<img src="03_moose_density_summary_files/figure-html/Fuller Wolf Density Equation-1.png" alt="Figure 1. Estimated wolf density as a function of moose density using the Fuller et al. (2003) model."  />
<p class="caption">Figure 1. Estimated wolf density as a function of moose density using the Fuller et al. (2003) model.</p>
</div>

### The [Kuzyk and Hatter (2014)](https://wildlife.onlinelibrary.wiley.com/doi/abs/10.1002/wsb.475) Model 
[Kuzyk and Hatter (2014)](https://wildlife.onlinelibrary.wiley.com/doi/abs/10.1002/wsb.475) developed a model to estimate wolf density from ungulate biomass using data collected in regions of British Columbia, using the same ungulate biomass index developed by [Fuller et al. (2003)](https://www.press.uchicago.edu/ucp/books/book/chicago/W/bo3641392.html). Wolf density (wolves/1,000 km^2^) is calculated with the equation: $$W = (UB * 5.4) - (UB^2 * 0.166)$$

Here W = wolf density and UB = total estimated ungulate biomass in the area of interest. 

The modeled relationship between moose density and wolf density is illustrated in Figure 2 (assuming no other ungulates occur in the system or are hunted by wolves). This model is more useful than the [Fuller et al. (2003)](https://www.press.uchicago.edu/ucp/books/book/chicago/W/bo3641392.html) model for estimating wolf densities in low moose density areas, as the model has an intercept of zero, allowing for wolf density estimates of less than 3.5 wolves/1,000 km^2^ in regions with low ungulate biomass. This models suggests a density of approximately 0.09 moose/km^2^ is necessary to achieve thresholds below 3 wolves/1,000km^2^.

<div class="figure" style="text-align: left">
<img src="03_moose_density_summary_files/figure-html/Kuzyk and Hatter Wolf Density Equation-1.png" alt="Figure 2. Estimated wolf density as a function of moose density using the Kuzyk and Hatter (2014) model."  />
<p class="caption">Figure 2. Estimated wolf density as a function of moose density using the Kuzyk and Hatter (2014) model.</p>
</div>

### The [Messier (1994)](https://www.jstor.org/stable/1939551?seq=1#page_scan_tab_contents) Model 
[Messier (1994)](https://www.jstor.org/stable/1939551?seq=1#page_scan_tab_contents) developed a model of wolf density exclusively from moose density, using data collected from areas across North America where moose were the primary prey of wolves. He calculated wolf density as a function of moose density using a hyperbolic, Michaelis-Menten function, using the equation: $$W = (58.7 * (M - 0.03)) / (M + 0.76)$$

Here W = wolf density (wolves/1,000 km^2^) and M = moose density (moose/km^2^). 

The modeled relationship between moose density and wolf density is illustrated in Figure 3. Notably, this model allows for negative wolf densities at very low moose densities, and requires a moose density greater than 0.03 moose/km^2^ to sustain wolves. Thus, similar to [Kuzyk and Hatter (2014)](https://wildlife.onlinelibrary.wiley.com/doi/abs/10.1002/wsb.475), this model is useful for estimating wolf density in low moose density areas. This model may also be more appropriate than the [Fuller et al. (2003)](https://www.press.uchicago.edu/ucp/books/book/chicago/W/bo3641392.html) model or [Kuzyk and Hatter (2014)](https://wildlife.onlinelibrary.wiley.com/doi/abs/10.1002/wsb.475) model for estimating wolf densites in areas where moose are known to be the primary prey of wolves. This model suggests a density of approximately 0.08 moose/km^2^ is necessary to achieve thresholds below 3 wolves/1,000 km^2^.

<div class="figure" style="text-align: left">
<img src="03_moose_density_summary_files/figure-html/Messier 1994 wolf density model-1.png" alt="Figure 3. Estimated wolf density as a function of moose density using the Messier (1994) model."  />
<p class="caption">Figure 3. Estimated wolf density as a function of moose density using the Messier (1994) model.</p>
</div>

## Estimated Wolf Densities in the Chilcotin Region of British Columbia
Caribou recovery planning has begun in the Chilcotin local population unit (LPU) of caribou. This LPU consists of the Itcha-Ilgachuz, Rainbows and Charlotte Alplands caribou herds, and constitutes the southernmost LPU of the Northern Mountain Caribou Designatible Unit (DU 7). These caribou are classified as *Threatened* under Canada's *Species at Risk Act*. The Itcha-Ilgachuz herd is considered to be of significant conservation importance provincially because it is the largest and highest density herd in west-central British Columbia (cite herd plan). However, the herd declined 17.2% annually between 2014 and 2018, and the habitat has experienced significant amounts of timber harvesting, road development, wildfire and mountain pine beetle infestations (cite herd plan). In addition, the 2019 caribou population census showed a 40% population decline from 2018, and at that rate of decline, the herd would be functionally extirpated (i.e., less than 20 animals) in eight years (Carolyn Shores, Provincial Caribou Biologist, pers. comm.). Thus, there is an urgent need to develop a recovery plan for the Chilcotin LPU. A critical component of this plan will be identifying ways to effectively minimize wolf density in the region, both directly (i.e., culling) and indirectly (by managing moose populations and moose and wolf habitat). 

Estimated moose densities from aerial surveys done in WMUs in the Chilcotin region are provided in Table 1. I estimated wolf densities from this data using the three models described above. 

The models suggest that wolf densities were never below 3 wolves/1,000 km^2^ in any of the WMUs over the periods that they were surveyed. The lowest averaged estimates of wolf density were in WMUs 5-02-A in 1996 (4 wolves/1,000 km^2^), 5-04 in 2012 (6 wolves/1,000 km^2^), and 5-15-C in 2008 (5 wolves/1,000 km^2^). The median wolf density estimate in the region throughout the survey period was 12 wolves/1,000 km^2^.  

<table class="table table-striped table-hover table-condensed" style="font-size: 11px; width: auto !important; ">
<caption style="font-size: initial !important;"><b>Table 1. Estimated moose densities from aerial survey data and wolf densities from published wolf density models in the Chilcotin region of British Columbia.<b></b></b></caption>
 <thead>
  <tr>
   <th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;"> Wildlife Management Unit (WMU) </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> Survey Year </th>
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

## Estimating Moose Densities from Habitat in the Chilcotin Region
I fit a statistical model of moose density in the Chilcotin region (Table 1) as a function of habitat features measured in WMUs. Habitat features considered in the model included: climate (i.e., temperature and precipitation), elevation, forest age and site productivity, road density, and area of wetlands, lakes, rivers, burns, forestry cutblocks, and stands of different types of leading tree species. Habitat features were estimated using publically available spatial datasets and geographic information systems software (see [here](https://github.com/bcgov/clus/blob/master/R/moose/02_moose_density_chilcotin.Rmd) for details).

I tested for collinearity among estimated habitat covariates using Spearman's correlation ($\rho$) and variance inflation factors (VIFs) ([Montgomery et al. 2012](https://www.wiley.com/en-ca/Introduction+to+Linear+Regression+Analysis%2C+5th+Edition-p-9780470542811); [DeCesare et al. 2012](https://esajournals.onlinelibrary.wiley.com/doi/abs/10.1890/11-1610.1)). If two or more covariates were correlated, i.e., $\rho$ $\ge$ 0.7, I removed at least one of them from the analysis. Then, I fit a generalized linear model (GLM) with all the remaining covariates and iteratively removed covariates with the largest VIFs and re-fit the model until all covariates had VIFs less than 10. After this procedure, the remaining covariates tested in the model were: mean precipitation as snow, proportion of wetland area, proportion of river area, proportion of lake area, proportion of shrub area, proportion of area cut 1 to 10 years old and 11 to 30 years old, proportion of area burnt 1 to 15 years old and 16 to 30 years old, proportion of *Populus* species leading tree stands, proportion of pine species leading tree stands, proportion of spruce species leading tree stands, proportion of Douglas fir leading tree stands, and density of paved and unpaved roads. 

I fit a generalized linear mixed model (GLMM) with the remaining covariates (i.e., a 'global' model) using the 'glmer' function in the lme4 package in R ([Bates et al. 2015](https://www.jstatsoft.org/article/view/v067i01)). I fit this model with a random intercept for WMU to account for potential correlation of multiple moose density estimates obtained from the same WMU. I then used the 'dredge' function in the MuMin package ([Barton 2019](https://cran.r-project.org/web/packages/MuMIn/MuMIn.pdf)) to fit models with all combinations of covariates in the global model. I compared these models based on their parsimonious fit to the data by calculating corrected Akaike Information Criteria (AIC~c~) scores. I considered models with a difference in AIC~c~ score of less than 2 from the top model (i.e., the model with the minimum AIC~c~ score) as good candidate models of moose density (Table 2). I then calculated weighted averaged model coefficients from this candidate set of models using AIC weights (AIC~w~), and used these coefficients to estimate moose density under varying habitat conditions in the Chilcotin WMUs. 

The top-ranked moose density model had AIC~w~ = 0.526 and *R^2^* = 0.830, and included covariates for proportion of area of *Populus* leading forest stands, proportion of area of rivers, proportion of area burnt 16 to 30 years ago, proportion of area cut 1 to 10 and 11 to 30 years ago, and density of paved and unpaved roads (Table 2). The second ranked-model (AIC~w~ = 0.267; *R^2^* = 0.830) included these same covariates and proportion of area burnt 1 to 15 years ago. The third ranked-model (AIC~w~ = 0.207; *R^2^* = 0.828) included the same covariates as the top model and proportion of area that was Douglas fir leading forest stands. 

<table class="table table-striped table-hover table-condensed" style="width: auto !important; ">
<caption><b>Table 2. Top moose density models as determined using corrected Akaike Information Criteria (AICc) scores and weights<b></b></b></caption>
 <thead>
  <tr>
   <th style="text-align:left;"> Model Covariates </th>
   <th style="text-align:right;"> AICc </th>
   <th style="text-align:right;"> delta AIC </th>
   <th style="text-align:right;"> AIC weight </th>
   <th style="text-align:right;"> R-squared </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Density Paved Road, Density Unpaved Roads, Proportion Cutblocks 1 to 10 years old, Proportion Cutblocks 11 to 30 years old, Proportion Burnt 16 to 30 years old, Proportion Populus Spp., Proportion River </td>
   <td style="text-align:right;"> -67.92 </td>
   <td style="text-align:right;"> 0.00 </td>
   <td style="text-align:right;"> 0.53 </td>
   <td style="text-align:right;"> 0.82 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Density Paved Road, Density Unpaved Roads, Proportion Cutblocks 1 to 10 years old, Proportion Cutblocks 11 to 30 years old, Proportion Burnt 1 to 15 years old, Proportion Burnt 16 to 30 years old, Proportion Populus Spp., Proportion River </td>
   <td style="text-align:right;"> -66.56 </td>
   <td style="text-align:right;"> 1.36 </td>
   <td style="text-align:right;"> 0.27 </td>
   <td style="text-align:right;"> 0.83 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Density Paved Road, Density Unpaved Roads, Proportion Cutblocks 1 to 10 years old, Proportion Cutblocks 11 to 30 years old, Proportion Burnt 16 to 30 years old, Proportion Populus Spp., Proportion River, Proportion Douglas Fir </td>
   <td style="text-align:right;"> -66.05 </td>
   <td style="text-align:right;"> 1.87 </td>
   <td style="text-align:right;"> 0.21 </td>
   <td style="text-align:right;"> 0.83 </td>
  </tr>
</tbody>
</table>

Coefficients (\( \beta \ \)) of the averaged moose density model (Table 3) indicated that the proportion of area of the WMU that was river (\( \beta \ \) = 17.84), burned 16 to 30 years ago  (\( \beta \ \) = 12.16) and *Populus* species leading forest stands (\( \beta \ \) = 3.34) had a statistically significant, positive influence on moose density. The proportion of area of the WMU that was younger (1 to 10 year old) cutblocks  positively influenced moose density (\( \beta \ \) = 1.28) and the proportion of area of older (11 to 30 year old) cutblocks negatively influenced moose density (\( \beta \ \) = -0.97). The density of paved roads in the WMU had a statistically siginificant, negative influence on moose density (\( \beta \ \) = -13.84) and the density of unpaved roads had a weak negative influence on moose density (\( \beta \ \) = -0.28). The proportion of area of the WMU that was Douglas fir leading forest stands had a very weak, positive influence on moose density (\( \beta \ \) = 0.02) and the proportion of the WMU that was burned 1 to 15 years ago  had a very weak, negative influence on moose density (\( \beta \ \) = -0.05) .  

<table class="table table-striped table-hover table-condensed" style="width: auto !important; ">
<caption><b>Table 3. Coefficient values of an averaged moose density model for the Chilcotin region of British Columbia.<b></b></b></caption>
 <thead>
  <tr>
   <th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;"> Coefficient Name </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> Coefficient Estimate </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> Adjusted Std. Error </th>
   <th style="text-align:right;position: sticky; top:0; background-color: #FFFFFF;"> z-value </th>
   <th style="text-align:left;position: sticky; top:0; background-color: #FFFFFF;"> Pr(&gt;|z|) </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> Intercept </td>
   <td style="text-align:right;"> 0.14 </td>
   <td style="text-align:right;"> 0.04 </td>
   <td style="text-align:right;"> 3.91 </td>
   <td style="text-align:left;"> &lt;0.01 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Density Paved Roads </td>
   <td style="text-align:right;"> -13.84 </td>
   <td style="text-align:right;"> 4.06 </td>
   <td style="text-align:right;"> 3.41 </td>
   <td style="text-align:left;"> &lt;0.01 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Density Unpaved Roads </td>
   <td style="text-align:right;"> -0.28 </td>
   <td style="text-align:right;"> 1.31 </td>
   <td style="text-align:right;"> 0.22 </td>
   <td style="text-align:left;"> 0.83 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Proportion Cutblocks 1 to 10 years old </td>
   <td style="text-align:right;"> 1.28 </td>
   <td style="text-align:right;"> 0.53 </td>
   <td style="text-align:right;"> 2.39 </td>
   <td style="text-align:left;"> 0.02 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Proportion Cutblocks 11 to 30 years old </td>
   <td style="text-align:right;"> -0.97 </td>
   <td style="text-align:right;"> 0.36 </td>
   <td style="text-align:right;"> 2.68 </td>
   <td style="text-align:left;"> 0.01 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Proportion Burnt 1 to 15 years old </td>
   <td style="text-align:right;"> -0.05 </td>
   <td style="text-align:right;"> 0.11 </td>
   <td style="text-align:right;"> 0.47 </td>
   <td style="text-align:left;"> 0.64 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Proportion Burnt 16 to 30 years old </td>
   <td style="text-align:right;"> 12.16 </td>
   <td style="text-align:right;"> 3.18 </td>
   <td style="text-align:right;"> 3.82 </td>
   <td style="text-align:left;"> &lt;0.01 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Proportion Poplar spp. </td>
   <td style="text-align:right;"> 3.34 </td>
   <td style="text-align:right;"> 0.54 </td>
   <td style="text-align:right;"> 6.13 </td>
   <td style="text-align:left;"> &lt;0.01 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Proportion River </td>
   <td style="text-align:right;"> 17.84 </td>
   <td style="text-align:right;"> 5.25 </td>
   <td style="text-align:right;"> 3.40 </td>
   <td style="text-align:left;"> &lt;0.01 </td>
  </tr>
  <tr>
   <td style="text-align:left;"> Proportion Douglas Fir </td>
   <td style="text-align:right;"> 0.02 </td>
   <td style="text-align:right;"> 0.06 </td>
   <td style="text-align:right;"> 0.38 </td>
   <td style="text-align:left;"> 0.71 </td>
  </tr>
</tbody>
</table>

## Estimating Moose Densities Under Varying Habitat Disturbance Conditions in the Chilcotin Region
I used the averaged moose density model to estimate moose densities in WMUs in the Chilcotin region if they were undisturbed (i.e., had no roads or cutblocks) or disturbed at different proportions of forest harvest (i.e., no harvest, 10%, 20%, 30% or 40% of the area of the WMU was cutblocks aged 1 to 30 years old), assuming all other habitat conditions (e.g., area of *Populus* species leading forest stands) remained the same as current conditions. Moose density estimates were then used to estimate  wolf densities taking the average estimates of the three wolf desnity models described above. 

Estimated moose and wolf densities should be used with a high degree of caution. Many complex factors influence wildlife population dynamics, and the estimates provided here greatly oversimplify that complexity. For example, here I do not directly consider the effects of hunting or trapping on moose and wolf populations. However, the estimates provided here can be used to inform management decisions within an adaptive management approach.

### Effects of Roads and Cutblocks on Moose and Wolf Densities
In the majority of WMUs, estimated wolf densities were higher when habitat was undisturbed compared to current habitat disturbance (Fig. 4). This result is perhaps counterintuitive, as current understanding of wolf-caribou-moose population dynamics is that forestry disturbance positively influences moose and wolf densities. However, the moose density model includes a strong negative effect of roads (particularly paved roads), and a negative effect of cutblocks 11 to 30 years old. Therefore, removal of roads and cutblocks from WMUs had a strong positive influence on moose, and ultimately wolf density estimates. The negative effect of roads on moose density may be indicative of high human hunting pressure on moose ([Mumma and Gillingham 2019](http://web.unbc.ca/~michael/Mumma_and_Gillingham_2019.pdf)), or that roads degrade the quality of moose habitat by displacing moose.

<div class="figure" style="text-align: left">
<img src="03_moose_density_summary_files/figure-html/estimated wolf densites from recovery of disturbed habitat-1.png" alt="Figure 4. Estimated wolf density in wildlife management units (WMUs) as a function of habitat disturbance at varying levels of disturbance."  />
<p class="caption">Figure 4. Estimated wolf density in wildlife management units (WMUs) as a function of habitat disturbance at varying levels of disturbance.</p>
</div>

Compared to current habitat conditions, removing cutblocks but not roads from WMUs (i.e., the "No Cutblocks" scenario) had a mixed effect on moose (and wolf) density estimates, depending on the WMU (Fig. 4). Removing cutblocks from WMUs with more older than younger cutblocks had a positive effect on moose density, whereas removing cutblocks from WMUs with more younger than older cutblocks had a negative effect. These results show a positive influence of young cutblocks and negative influence of older cutblocks on moose density estimates. I could speculate that this effect might be due to younger cutblocks providing greater forage benefits to moose than older cutblocks, thus supporting higher moose densities. However, [Mumma and Gillingham (2019)](http://web.unbc.ca/~michael/Mumma_and_Gillingham_2019.pdf) found a negative effect of young (1 to 8 year old) cutblocks on adult female moose survival in several areas of British Columbia, including the Chilcotin region, essentially supporting the opposite relationship of what I found at the WMU scale. Perhaps that while individual cow moose are more likely to die from hunting or starvation in areas with younger cutblocks, it takes a decade for this effect to manifest in a population at a WMU scale (i.e., a lag between individual and population scales). This might explain the negative effect of older cutblocks on moose densities in WMUs that I found. However, this lag effect cannot be adequately tested with the data in hand and requires more consideration.

Overall, the moose density model identifies a net negative effect of roads and cutblocks on moose densities (Fig. 4). Younger aged cutblocks might benefit moose, but over time, as cutblocks age, the effects become negative. Therefore, scenarios with increasing proprotions of WMUs cut by forestry show decreasing wolf density estimates. Clearly, there are complexities and uncertainties in the wolf-moose-forestry relationship in the Chilcotin region that require careful consideration in caribou recovery planning. 

### Effects of Burns, Riparian Areas and Forest Stand Types on Moose and Wolf Densities
In the moose density model, burns had a significant, positive influence on moose density that was much larger than the influence of forestry. Younger burns (1 to 15 years old) had virtually no effect on moose densities, but older burns (16 to 30 years old) had a strong positive influence. It may be that older burns provide better foraging opportunities for moose than younger burns, supporting higher moose densities. Alternatively, older burns may indicate a lag effect of the benefits of younger burns to individual moose that takes several years to manifest at the population scale. Regardless, fire regimes in Canada are changing, with very large, more intense fires becoming more common ([Flannigan et al. 2005](https://link.springer.com/article/10.1007/s10584-005-5935-y); [Wang et al. 2015](https://link.springer.com/article/10.1007/s10584-015-1375-5)). It's unclear whether moose densities will continue to respond strongly and positively to burned areas given this changing regime, and thus the influence of future fire on moose densities should be considered with some caution.

The area of *Populus* species leading forest stands and rivers had significant, positive influences on moose (and thus wolf) densities. Rivers are relatively 'static' habitat for moose, and the amount of river habitat is not typically managed, although the quality of riparian habitat can be considered in habitat management. However, the area of *Populus* species leading forest stands could be managed as part of forest planning. In addition, the amount of *Populus* species leading forest stands will likely change as a consequence of increasingly changing climate conditions ([Hamann and Wang 2006](https://esajournals.onlinelibrary.wiley.com/doi/abs/10.1890/0012-9658(2006)87%5B2773:PEOCCO%5D2.0.CO%3B2); [Iverson et al. 2008](https://www.sciencedirect.com/science/article/pii/S0378112707005439)). Greater monitoring of trends in *Populus* species leading stands could help inform moose and wolf management in caribou recovery areas. 

## Implications of the Moose and Wolf Density Model Results for Caribou Recovery Planning in the Chilcotin Region
Managing for low moose and wolf densities in the Chilcotin region to minimize predation on caribou is going to be a significant challenge. Using existing models, I estimate that there are currently relatively high wolf densities in the region (median of WMUs = 12 wolves/1,000 km^2^), well above thresholds (i.e., 3 wolves/1,000km^2^) recommended for some caribou critical habitat types. In addition, according to results of my moose density model, reducing forestry disturbance in caribou critical habitat could potentially benefit moose and wolf populations, paradoxically increasing the vulnerability of caribou populations to predation. Conversely, fire suppression could help maintain low moose densities in the region, which could be important to supporting caribou recovery. In addition, regardless of habitat disturbance type, the moose density model suggests that we need to consider the potential for lag effects of habitat disturbance on moose and wolf populations. Current moose density estimates in the Chilcotin region appear to not only reflect current habitat conditions, but trends in habitat.

Results of the models described here should not discourage the implementation of new habitat protections for caribou. However, clearly the model results suggest we need to very carefully consider how managing habitat disturbance will influence moose, wolves and caribou. Each of these species interacts with habitat disturbance in a dynamic, complex way, making it a challenge to predict how habitat disturbance management will influence interactions between these species. Improtantly, I think the models highlight the challenges and limitations in using very specific wildlife population density (e.g., 3 wolves/1,000km^2^) and habitat area thresholds (e.g., 35% area of disturbance) as management targets. I would not necessarily discourage the use of these targets, but they should be considered as being highly uncertain. Caribou recovery actions, including habitat protections, are much more likely to be succesfull if they are flexible and responsive to new information.

If the moose density model here is reasonably correct, than habitat protections in caribou critical habitat could benefit moose, but these protections could then also potentially benefit moose hunters in the region. Improved moose habitat could support more productive moose populations and thus higher hunting quotas. Despite habtiat protections, moose populations could still be kept at relatively low densites by allowing for intensive hunting, which would likely benefit caribou ([Serrouya et al. 2017](https://peerj.com/articles/3736/?utm_source=TrendMD&utm_campaign=PeerJ_TrendMD_1&utm_medium=TrendMD)). The dynamics between habitat protections and moose population management (i.e., hunting) also needs further consideration here, and flexible and responsive moose hunting policies in conjunction with habitat protections may be beneficial to caribou recovery. 

Prior to implementing the models described here as part of caribou recovery planning, they should be critically discussed among wildlife experts (i.e., First Nations, government wildlife biologists, academic wildlife biolgists, and outfitters and hunters) with good knowledge of wildlife in the Chilcotin region. Ultimately, these experts should evaluate whether the models here are useful to informing a discussion about caribou recovery in the Chilcotin region. 
