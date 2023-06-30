## FLEXplorer Documentation

### Introduction
The *FLEXplorer* module was developed to estimate the effects of forest change on fisher populations. It is an agent-based model, which are models that simulate the actions of agents (in this case, individual fisher) in response to their environment (i.e., habitat) based on their ecology and behaviour. Therefore, it is a 'bottom-up' approach, where the behaviours of individuals are simulated to understand the collective impacts to a population.

Here we describe the logic of how *FLEXplorer* simulates the ecology and behaviour of individual fisher. *FLEXplorer* works with within the Castor set of models through the *fisherHabitatCastor* module, where *fisherHabitatCastor* estimates fisher habitat attributes from forest stand attributes that are estimated from *forestryCastor* (a forest simulator). Therefore, the fisher agents simulated in *FLEXplorer* interact with landscapes simulated from *forestryCastor*. This version of the model only simulates female fisher, and therefore assumes the landscape does not affect interactions, and thus mating rates, between males and females.  

The *FLEXplorer* module consists of an initiation (init) phase that establishes fisher on the landscape, and an annual simulation phase, that iteratively simulates individual fisher life-history events and behaviours over the coruse of a year, including survival, dispersal and territory formation, reproduction and aging. Below we describe these phases and events in more detail.

### Habitat Input to FLEXplorer
The *FLEXplorer* module interacts with the landscape and fisher habitat though the habitat data parameter (rasterHabitat), which is specified as a multi-band raster in Tag Image File Format (TIFF). This includes data on the location of fisher habitat sub-populations, and the location (presence or absence) of each fisher habitat type (denning, rust, movement, coarse-woody debris, cavity and open) across the simulation area of interest for each simulation interval, as specified in the forest simulator (i.e., *forestryCastor*). Therefore, it provides estimates of the location of key fisher habitat types over time as it changes in response to forest dynamics, including potentially disturbances such as forestry or fire. The rasterHabitat parameter is provided as an output from *fisherHabitatCastor* when run concurrently with *forestryCastor*. 

### Initiation of the Fisher Population 
The *FLEXplorer* module starts by establishing a fisher population on the landscape, which consists of placing adult female fisher within denning habitat across the landscape. The general objective of the init phase is to 'saturate' the landscape with fisher, i.e., identify the number of fisher territories that can be supported by the habitat in the landscape. To do that, the init phase identifies the number of fisher that potentially could be supported on the landscape, distributes them across the landscape based on the distribution of fisher denning habitat, and then determines which fisher can form a territory. The result of that process is a landscape at or close to its maximum potential for fisher occupancy. Therefore the assumed starting point of the model is a fisher population at its carrying capacity for the habitat in the landscape. 

#### Identifying the Number of Fisher to Place on the Landscape
The user can either specify the number of fisher to distribute on the landscape using the initialFisherPop, or estimate the number of fisher to distribute on the landscape based on the average fisher home range size and the distribution of denning habitat across the study area. We currently recommend using the latter approach to ensure that a saturated landscape is achieved. 

To estimate the number of fisher on the landscape, first the model aggregates the existing pixels (typically 1 ha) in the area of interest into larger pixels with the size of the average home range for fisher across all fisher habitat types (i.e., 3,750 ha). Then the number of aggregated pixels with greater than 1% denning habitat within them are summed to determine the number of fisher to distribute across the landscape. 

#### Distributing Fisher Across the Landscape
Fisher are randomly distributed across the landscape following a well-balanced sampling design (see: [Brus 2003](https://dickbrus.github.io/SpatialSamplingwithR/BalancedSpreaded.html#LPM)). Specifically, the local pivot method 




well balanced sampling design see:  

inclusionprobabilities






### Input Parameters
The *FLEXplorer* module requires that the user specify the fisher habitat data and several ecological parameters for fisher.



Survival parameters consist of a table (survival_rate_table) that is 'hard-coded' in the model (i.e., it currently cannot be directly input by the user). Survival rates are defined by age class, for each population (boreal, sub-boreal moist, sub-boreal dry, and dry forest) and for dispersers and non-dispersers (i.e., animals with a territory). The age classes are 1 to 2 years old, 3 to 5 years old, 5 to 8 years old and greater than 8 years old (all classes are inclusive). Therefore, there are thirty-two survival rates in the table for each population, age class and disperser class. Note that animals less than 1 year old do not have a survival rate, as survival is a component of the recruitment rate (see below).

Similar to the survival parameters, the reproductive parameters consist of table of recruitment rates (repro_rate_table) that is 'hard-coded' in the model. A rate is specified for each population and thus there four recruitment rates in the table. These recruitment rates represent the probability that kit survives to a juvenile (age 1). For reproduction, the user can also specify a sex ratio (sex_ratio) for assigning the proportion of kits that are female (the default value is 0.5), and the minimum age a aisher has to be to reproduce (reproductive_age; the default value is 2 years old). 







    defineParameter("female_dispersal", "numeric", 785000, 100, 10000000,"The area, in hectares, a fisher could explore during a dispersal to find a territory."),
    

    
    
    defineParameter("timeInterval", "numeric", 1, 1, 20, "The time step, in years, when habtait was updated. It should be consistent with periodLength form growingStockCASTOR. Life history events (reproduce, updateHR, survive, disperse) are calaculated this many times for each interval."),
    
    
    defineParameter("den_target", "numeric", 0.001, 0, 1,"The minimum proportion of a home range that is denning habitat. Values taken from empirical female home range data across populations."), 
    defineParameter("rest_target", "numeric", 0.001, 0, 1, "The minimum proportion of a home range that is resting habitat. Values taken from empirical female home range data across populations."),   
    defineParameter("move_target







FLEX2 documentation
Finds number of potential territories using the aggregation 
Initialization 
Aggregation to define the number of fisher on the landcapes
-	Gagreagte pixels to average home range size
-	Check if there is a dennign pixel in it,
-	- count nymebr of pixels with a dennign pixel 
-	That is the number of fisher to star-
-	 or can input directly 
 
then Sample dennign lcoaitons using the lpm method
-	Randomly picks a location, but hen slects additoan locations base do ten degree of cluserting of den sites and number o samples
-	Fewer samples, and more spread out den pixels means more dispered samples; this variable, contional on the samp,es

Agents tables
-	Attributes of female fihers with terriroties
-	Only these have an id

Dispersers table
-	Attributes of dispersers without a territory 

Table_hab_spread
-	Updated, conditional on habtait classes

Spread to form territories
-	Input is the Table_hab_spread ad agents
-	Open = spread_prob 0.09
-	No habtiat = spread_prob 0.18
-	Habtait spread = spread_prob 1
-	Check to see if achieved mean hr size – 2 sd and amount of habtiat 15% 
-	Meet tthrehdolsds of habtait caterogies and d2 therhfolds as set by the user
-	- if animal doesn’t meet the threholds then ift gets put into the diespersers table

Then dispersers attempt to find a new territory 
-	Finds dennign pixels not in a territory
-	Identifies potential # terriotires using eth ggregation function
o	If more dispersers than potential, then some fisher sdont; get a locations
-	Then use well spread sampling to disperse fisher
-	 Finds the closest denning site for a fisher; the closest fisher gets the dennign site
-	Adults get priority over juveniles in the denning too 
-	Successful dispersers then attempt to spread a territory and check that needs are met

Annual time step
-	Update habitat
-	Check if habitat is still high enough quality
-	Then loop of survive, dispersal, territory formation, reproduce, ,age and then report
-	

Reproduction
-	Includes fertility rate and juvenile survival (i.e., recruitment rate)
-	So reproducers are actually recruitment rate, so more kits were born than estimated as reporducing


Survival first
Age and terriorty based survival rates
1-2, 3-5, 5-8, >8
Dispersers and non-dispersers

Age distribution is poission








