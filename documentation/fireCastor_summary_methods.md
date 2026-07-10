## Introduction

Wildfires are a major driver of landscape change and are increasing in
frequency, severity, and area burned throughout British Columbia
([Parisien et al., 2023](#ref-parisien2023)). Forecasting wildfire
disturbance is therefore essential for understanding future risks to
timber supply, ecosystem services, biodiversity, and other forest
values. To support landscape-level planning and scenario analysis, we
developed two linked wildfire modelling modules within the Castor forest
and land-use simulation framework: lavaf3r (latent variable future
forest fire regime; (Lochhead, in prep.) and fireCastor (Kleynhans et
al., in prep). These modules integrate climate projections, vegetation
attributes, and management activities to simulate future wildfire
occurrence, extent, and spatial distribution across British Columbia.

## Modelling Framework

The fire modelling framework is based loosely on the approach described
by Marchal et al. ([Marchal et al., 2020](#ref-marchal2020turning)) and
combines statistical fire-regime models with spatial fire-spread
simulations. To account for processes occurring at different spatial
scales, we model wildfire activity at two resolutions. At a coarse scale
(10 × 10 km), lavaf3r predicts the expected number of ignitions and
total area burned using empirical statistical relationships between
climate, fuels, and historical wildfire activity. At a finer scale (1
ha), fireCastor predicts where ignitions occur and how fires spread
across the landscape. Together, these modules stochastically simulate
the number, size, and location of wildfire events. Vegetation affected
by simulated fires is updated after each simulation step, creating
feedbacks between wildfire disturbance, vegetation succession, and
future fire activity.

## lavaf3r: Fire Occurrence and Area Burned

Lavaf3r is a stochastic, spatially explicit fire-regime modelling
framework that forecasts wildfire occurrence and area burned using
empirical statistical relationships derived from historical
observations. Models were developed for lightning-caused wildfires
larger than 1 ha using annual data from 2009–2022 summarized within 10 ×
10 km grid cells across British Columbia. Predictor variables included
fire-season climate metrics derived from downscaled climate surfaces,
fire regime type ([Erni et al., 2020](#ref-erni2020zonation)), and
land-cover information derived from the provincial Vegetation Resources
Inventory (VRI) ([GeoBC, 2024b](#ref-BC_VRI_Historical_2002_2024)).
Vegetation was classified into broad fuel groups including coniferous,
deciduous, mixedwood, young forest, and non-treed vegetation. Historical
fire occurrence data were obtained from the BC Wildfire Service fire
incident database ([GeoBC,
2025](#ref-bc_wildfire_incident_locations_historical)).

### Fire Occurrence Model

Annual wildfire occurrence was modelled using a spatial negative
binomial generalized linear mixed model. Candidate predictor variables
were evaluated using forward model selection based on improvements in
AIC. The final model included fire regime type, fuel composition,
flammable area following Beverly et al. ([Beverly et al.,
2021](#ref-beverly2021fireexposure)), and several climate variables
describing moisture and temperature conditions. Spatial autocorrelation
was accommodated using a spatial random field.

### Fire Size Model

Wildfire size was modelled separately using a finite-mixture statistical
framework that combined multiple probability distributions to represent
both typical wildfires and rare extreme events. Candidate climate, fuel,
accessibility, and occurrence variables were evaluated using forward
selection. The final model included summer temperature, precipitation,
climate moisture indices, fire regime type, conifer abundance, distance
to roads, and ignition pressure.

### Model Evaluation

Models were calibrated using data from 2009–2017 and evaluated with
independent data from 2018–2022. For each evaluation year, 1,000 Monte
Carlo simulations were performed. Simulated ignitions from the
occurrence model were passed to the fire-size model to estimate annual
area burned. Predicted annual ignitions and area burned were then
compared against observed data. Overall model performance was strong.
Detailed methods and evaluation results are being prepared and will be
presented in a publication (Lochhead, in prep).

## fireCastor: Ignition location and fire spread

FireCastor translates the regional fire-regime outputs from lavaf3r into
spatially explicit wildfire events at a 1 ha resolution.

### Ignition location

A binomial logistic regression model was fitted to ignition records
([GeoBC, 2025](#ref-bc_wildfire_incident_locations_historical)) from
2009–2022 to estimate the probability that an ignition would develop
into a wildfire larger than 1 ha. The response variable indicated
whether an ignition resulted in a fire larger than 1 ha (1) or remained
smaller than 1 ha (0). Candidate predictors represented vegetation,
climate, accessibility, and fire regime characteristics, and variable
selection followed a forward–backward procedure based on AIC. The final
model retained fire regime type, vegetation type, vegetation age,
distance to roads, spring and summer moisture conditions, and June
precipitation.

### Fire Spread

Wildfire spread was modelled using generalized linear mixed models with
a logit link function. Locations inside and outside observed wildfire
perimeters ([GeoBC, 2024a](#ref-bc_wildfire_fire_perimeters_historical))
for the years 2009 - 2022 were sampled and used as binary responses
representing burned and unburned conditions. Fire identity was included
as a random effect to account for variation among events. Predictor
variables included vegetation characteristics, climate conditions, fire
regime type, slope, aspect, and accessibility variables. The resulting
model generated spatially explicit burn-probability surfaces that
describe the relative likelihood of a location burning once exposed to a
wildfire.

### Model validation

Ignition and spread models were validated using observed fire occurrence
and perimeter data from 2023 to 2025, following the methods outlined in
([Johnson et al., 2006](#ref-Johnson2006RSF)). This methods is commonly
used to assess the predictive performance of wildlife resource selection
studies and is well suited to testing our generated probability of
ignition and spread surfaces. Detailed methods and validation results
are being prepared for publication and will be provided in the future
(Kleynhans et al. in prep).

## Simulation Workflow

During a simulation, lavaf3r first predicts the annual number of
wildfire ignitions and total area burned within each region. FireCastor
then uses ignition probability surfaces to select stochastic ignition
locations and spread probability surfaces to stochastically simulate
fire growth at the 1 ha scale. Fires continue to spread until the target
area burned predicted by lavaf3r is reached. Because wildfire
occurrence, fire size, ignition location, and spread are all modelled
stochastically, multiple simulation replicates are required to
characterize wildfire risk and uncertainty. If a location is burned at a
time step during the simulation, vegetation attributes such as age,
basal area, and height are updated to reflect a stand-replacing
disturbance, allowing wildfire and vegetation dynamics to interact
through time. We are working to incoporate fire severity in future
versions of the framework and thereby allow partial mortality and also
salvage harvesting to better represent heterogeneous wildfire effects.

## References

<div id="refs" class="references csl-bib-body hanging-indent"
entry-spacing="0" line-spacing="2">

<div id="ref-beverly2021fireexposure" class="csl-entry">

Beverly, J. L., McLoughlin, N., & Chapman, E. (2021). A simple metric of
landscape fire exposure. *Landscape Ecology*, *36*(3), 785–801.
<https://doi.org/10.1007/s10980-020-01173-8>

</div>

<div id="ref-erni2020zonation" class="csl-entry">

Erni, S., Wang, X., Taylor, S. W., Boulanger, Y., Swystun, T.,
Flannigan, M. D., & Parisien, M.-A. (2020). Developing a two-level fire
regime zonation system for canada. *Canadian Journal of Forest
Research*, *50*(3), 259–273. <https://doi.org/10.1139/cjfr-2019-0191>

</div>

<div id="ref-bc_wildfire_fire_perimeters_historical" class="csl-entry">

GeoBC. (2024a). *BC wildfire fire perimeters – historical*.
<https://catalogue.data.gov.bc.ca/dataset/bc-wildfire-fire-perimeters-historical>.

</div>

<div id="ref-BC_VRI_Historical_2002_2024" class="csl-entry">

GeoBC. (2024b). *VRI – historical vegetation resource inventory
(2002–2024)* \[Dataset\]. Ministry of Forests; Government of British
Columbia.
<https://catalogue.data.gov.bc.ca/dataset/vri-historical-vegetation-resource-inventory-2002-2023->

</div>

<div id="ref-bc_wildfire_incident_locations_historical"
class="csl-entry">

GeoBC. (2025). *BC wildfire fire incident locations – historical*.
Province of British Columbia;
<https://catalogue.data.gov.bc.ca/dataset/bc-wildfire-fire-incident-locations-historical>.
<https://catalogue.data.gov.bc.ca/dataset/bc-wildfire-fire-incident-locations-historical>

</div>

<div id="ref-Johnson2006RSF" class="csl-entry">

Johnson, C. J., Nielsen, S. E., Merrill, E. H., McDonald, T. L., &
Boyce, M. S. (2006). Resource selection functions based on
use–availability data: Theoretical motivation and evaluation methods.
*Journal of Wildlife Management*, *70*(2), 347–357.
[https://doi.org/10.2193/0022-541X(2006)70\[347:RSFBOU\]2.0.CO;2](https://doi.org/10.2193/0022-541X(2006)70[347:RSFBOU]2.0.CO;2)

</div>

<div id="ref-kleynhans_inprep" class="csl-entry">

Kleynhans, E. J., Lochhead, K., Skaien, C., & Muhly, T. (n.d.).
*Modelling local level fire escape, spread, and fire severity*
\[Unpublished manuscript\].

</div>

<div id="ref-lochhead_inprep" class="csl-entry">

Lochhead, K. (n.d.). *Latent variable future forest fire regime*
\[Unpublished manuscript\].

</div>

<div id="ref-marchal2020turning" class="csl-entry">

Marchal, J., Cumming, S. G., & McIntire, E. J. B. (2020). Turning down
the heat: Vegetation feedbacks limit fire regime responses to global
warming. *Ecosystems*, *23*(5), 1101–1115.
<https://doi.org/10.1007/s10021-019-00398-2>

</div>

<div id="ref-parisien2023" class="csl-entry">

Parisien, M.-A., Barber, Q. E., Bourbonnais, M. L., Daniels, L. D.,
Flannigan, M. D., Gray, R. W., Hoffman, K. M., Jain, P., Stephens, S.
L., Taylor, S. W., & Whitman, E. (2023). Abrupt, climate-induced
increase in wildfires in british columbia since the mid-2000s.
*Communications Earth & Environment*, *4*(309).
<https://doi.org/10.1038/s43247-023-00977-1>

</div>

</div>
