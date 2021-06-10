---
title: "blockingCLUS examples and comparison"
output: 
  html_document: 
    keep_md: yes
---



# Introduction

The size of a harvest unit (ie. a cutblock) and its spatial boundaries have important implications for forest management. Economic feasiblity, patch size distribution objectives and metrics important to wildlife habitat (i.e., distance to a cutblock) are all influenced by cutblock size, shape and location. The information used to guide the design of cutblocks often entails forest inventory attributes which can be represented as either vector (polygons) or raster (pixels) data structures. Often, individual polygons (typicaly from photo-interpreation) are assumed to represent harvest units, however, there are many cases where polygons or pixels will require aggregation or disaggregation to meet management assumptions. For example, the aggregation of forest polygons or pixels is often required given operations can capture economies of scale resulting from harvesting a number of stands in a spatially contiguous manner. Conversely, forest cover polygons may require disaggragation when the size of the polygon is too large to meet size constraints on harvest units. Aggregating or disaggregating polygons or pixels into operational units is one of the intital steps for making decisions in forest management planning. Largely, because forest mangement activites (i.e., harvesting, silvicuture) are often prescribed and implemented at the scale of a harvest unit. Thus, the simulation of harvesting units (including the size, shape and location) is an important step required by many strategic forest management models. 

The goal of the blockingCLUS module within the caribou and land use simulator (CLUS) is to provide a means for segmenting information from forest cover polygons and other remote sensing products into harvest units or blocks that result in a shape that would emulate actual harvest units. Note that the term block here does not convey any information concerning the geometry of the harvest unit but rather the term is used to describe the operational harvesting boundary which can take on many shapes and include alternative harvesting systems to clearcutting.

## CLUS Block Building Approaches

Two approaches to the block building algorithm within CLUS can be taken: i) 'pre-blocking' which assumes perfect information into the future and ii) 'dynamic blocking' which assumes very little information about the future harvest units. Using a pre-blocking approach, the entire landscape is divided into blocks before the harvest schedule is determined. This assumption can be limiting given harvest unit configurations are known _a_ _priori_ which may evidently restrict the flexibility of the modelled outcome. Conversely, dynamic blocking assigns harvest unit size and its geometry during the harvest scheduling simulation. This dynamic behaviour may better emulate flexible management strategies like salavage operations but is harder to achieve optimality by the blocking method due to the lack of forward or proactive use of information. Typically, the choice of assumptions are made in concordance with the proposed harvest scheduling approach. Various harvest scheduling approaches are linked with a blocking algorthuim, however, the various advantages and disadvantages will be left for another module.

In reality a combination of approaches is implemeneted (given the flexiblity of management and spectrum of future insight given to the model) which allows advantages from both approaches to be realized. For CLUS applications, our interest is in the automated process of simulating the size, shape and location of future harvest units for purposes of tracking forestry landuses. We are interested in how future forestry landuses could impact the habitat supply for caribou across British Columbia. In particular, disturbed area, including harvesting can negatively impact caribou habitat through a variety of direct and indirect pathways. As such harvest blocks are often buffered by 500 m or more to account for the degradation of caribou habitat that results from harvesting operations. Thus, the size, shape and location of harvest units may be sensitive outcome impacting the projections of caribou habitat. The following sections describes in greater detail the blocking algorithms considered in CLUS modelling efforts. 

### Dynamic blocking

The general dynamic blocking algorithm is as follows from Murray and Weintraub (2002):
1. the area is seeded with harvest units 'growing' around these seeds. These "seeds" may be conditional on forest attribute information or randomly choosen
2. polygons/pixels are then aggregated into harvest units based on the 'closest' seed point (i.e., 'closest' can mean both real and variable space)
3. the harvest unit size is thus controlled by the number of initial seed points or some target size

Various modifications to this approach have been made with consideration to i) randomly sampling a harvest unit size target distribution and ii) including various priorities for aggregating various layers of information (e.g., stand type, age, and terrain) while achieving objectives of harvest unit homogeneity. It should be noted that both pre-blocking and dynamic blocking approches can be implemented with this simple algorithm.

### Pre-blocking 

Conversely, harvest units can be pre-blocked during the intial step of the model. The advantages of 'pre-blocking' are often a cost saving during run time of the simulation and the ability to support formulations of spatially exact optimization harvest scheduling problems. In particular, these assumptions allow the model to have greater insights into future outcomes and can be argued to result in improved decisions (intertemporal decision making). The unit restriction model (URM) is an example of an exact spatial harvest scheduling formulation that leverages the outputs of a pre-blocking algorithm (Murray 1999). This model is a spatial extension of a Model 1 aspatial formulation (Johnson and Scheurman 1977) which declares the decision variable as a binary representing whether a block is to be harvested or not (Murray 1999). Note that the URM has a similar formulation known as the Area restriction model (ARM) which endogenously includes the process of blocking. However, ARM are known to be very difficult to solve for large problems given the 'adjacency' and area restriction constraints impose a large amount of 'branching' in the solving algorithms. 

Various approaches to 'pre-blocking' have included optimization formulations and near optimal solutions via heuristics. Lu and Eriksson (1999) used a genetic algorithm to build harvest units and applied the algorithm to a 20 ha landscape with realtively long run-times. Boyland (2004) used simulated annealing to group polygons into harvest units based on area, age, species and shape criteria for the Invermere Timber Supply Area in British Columbia. Heuristic alorgithums offer a near optimal solution while accounting for the complexity of the problem. These characteristics are vitally important to the caribou and landscape simulator, which requires the simulation of land use events across very large spatial and temporal scales in a timely manner.  

Creating spatially contigous harvesting units has some similarities to the image segementation problem. The goal of image segmentation is to partition or cluster pixels into regions that represent meaningful objects or parts of objects. The problem of segementing an image has been posed for many applications ranging from improving the stratification of the forest which is needed in some forest inventory sampling regimes to  interpreting biomedical images (e.g., delineating organs or tumours). Typically, image segmentation involves region merging which can be approached using either top-down or bottom-up workflows.

Keeping in line with forestry applications- a common commercial software used for image segemetnation is [eCognition](http://www.ecognition.com/). This software is proprietary, and uses a bottom-up region merging technique (Baatz and Schape 2000), that merges indiviudal pixels into larger objects based on a 'scale' parameter. However, as shown by Blaschke and Hay (2001), finding any relationship between this 'scale' parameter and spatial indicators is complicated, which forces a trial and error approach for meeting segementation objectives (i.e., size and homogenity). Hay et al. (2005) attempted to overcome this issue by developing multiscale object-specific segmentation (MOSS) which uses an integrative three-part approach. For purposes of blocking harvest units, the size constrained region merging (SCRM) part of the approach is of importance.

The SCRM can be conceptualized using a topographic view of a watershed. Watersheds define a network of 'ridges' that represent the boundaries where water would drain towards. In the harvest blocking problem these ridges are boundaries of homogenous harvest units. To complete the region merging, the idea is to find sinks across the image where the rain would drain towards. Assuming these sink areas are 'water springs' from which the uplift of water would fill these areas, object instantiation becomes apparent. As water fills a sink, these areas represent contiguous areas with similar features (i.e., elevation). Various size constraints can then be used to stop the process of merging which allows objects to be delineated.

In blockingCLUS, we leverage ideas from image based segementation (Felzenszwalb and Huttenlocher 2004) and SCRM (Hay et al. 2005) to develop a graph based image segementation approach that spatialy clusters pixels into harvest units based on similarity between adjacent pixels and size constraints. The goal of this approach is to produce homogenous harvest units subject to size constraints.

The following steps are used:

1. Convert the raster image into a undirected weighted graph
2. Calculate the weights between pixels (i.e., edges) as a multivarate distance (e.g., [mahalanobis](https://en.wikipedia.org/wiki/Mahalanobis_distance))
3. Solve the minnimum spanning tree of the graph to get a list of edges (i.e., ridge lines)
4. Sort the edgelist according to a metric of similarity (i.e., multivariate distance)
5. Starting with the pixel with the largest [degree](https://en.wikipedia.org/wiki/Degree_(graph_theory)), cluster surounding pixels
6. When there are no more adjacent pixels or the size has been met or till the allowable amount of variation within the block has been exceeded, go on to the next block
7. Complete 5-6 until the target distribution is achieved

>Note: Since a MST is used as an input into this algorithm -more than one solution can exist. Hence there is a need for a seed variable to make the solution reproducible. After running the blocking algorithm 10 times on the same area of interest the number of harvest units changed by 2%.

# Objectives

"When interpreting decision support system output, as in all models, the major issue is whether the abstractions that the data and algorithms represent are sufficiently reliable to suffer the treatment of generalization from model output to practice in the real world" (Bunnell and Boyland 1999).

Our goal for blockingCLUS is to provide a degree of confidence that the logic of the algorithm could reproduce historical harvest units - including the size and shape as it pertains to the historical harvest disturbance for caribou. Note: this obejctive differs from trying to simultaneously optimize the size, shape and location of harvest units, as described earler by an ARM. Further, it is important to note that the number of cutblocks and their respective sizes are largely related. If the size of a harvest unit is artifically set too small, a greater footprint could result from the scheduler, as it looks to find more fibre for harvesting. 

We used historic harvest unit locations to compare the ability of blocking methods to reproduce the historical harvest disturbance for caribou. As stated earlier, this disturbance metric is the total area of harvest units with a buffer of 500 m. Since pre-blocking takes into account forest attribute information used to design cutblock shape we hypothesize that the pre-blocking alogrothuinm will produce cutblock shapes that better ressemble historical cutblock shapes and thus be more accurate in estimating the historical disturbance for caribou. 

# Methods

## Case Study

### Study Area
The study area was set to Fort Nelson [supply block](https://catalogue.data.gov.bc.ca/dataset/forest-tenure-managed-licence) 08B. This supply block was chosen at random. 


### Forest attributes information

The 2003 VRI infromation was used to set the similarity metric for the pre-blocking alogrithum. Both 2003 VRI photo-interpreted crown closure and height were used to calcualte the mahalanobis distance for determing the similarity metric. Both crown closure and height were scaled (mean subtracted and divided by the standard deviation) to remove any variable dominance in the distance calucaltion. The mahalanobis distance ($D^2$) was calculated  as

$$D^2=(x_{i} - x_{j})^{'}\Sigma^{-1}(x_i - x_j)$$
where $x$ is a vector containing the scaled crownclosure and height for the ${i}$ and its adjacent ${j}$ pixel; $\Sigma^{-1}$ is the inverse of the correlation matrix (since these are scaled) between crown closure and height. The mahalanobis distance ($D^2$) has a chi-square distrubution ($\chi_n^2$) with *n* degrees of freedom equal to the number of dimensions (here it is 2 for crown closure and height). Using the associated cummulative distribution function of $\chi_n^2$ when $x > 0$ the values of $D^2$ can be converted into probabilities which is useful to test the null hypothesis of no difference between the two pixels. By specifying the signficance level $\alpha$ this process has been used to detect outliers (see [Etherington 2019](https://peerj.com/articles/6678.pdf) ) or in the blocking algorithm the amount of allowable difference between pixels. Thus, the larger the $D^2$ the greater the allowable difference with a significant different being described by  $\alpha$. For example at $\alpha$ = 0.05 would correspond to a $D^2 = 6$ which means the two pixels have a 1 in 20 chance of being different. 

Cutblocks older than 2003 were queried from the [consolidated cutblock dataset](https://catalogue.data.gov.bc.ca/dataset/harvested-areas-of-bc-consolidated-cutblocks-) which represents the observed cutblock locations, size and shape. The following query was used to select harvest unit size, shape and location.


```sql
Create Table cutseq_Centroid as
  SELECT a.areaha, a.harvestyr, a.geom, ST_X(a.point) as X , ST_Y(a.point) as Y, point 
  FROM (SELECT areaha, harvestyr, st_Force2D(wkb_geometry) as geom, ST_Centroid(st_Force2D(wkb_geometry)) as point
  FROM cns_cut_bl_polygon where areaha >= 1) a 
```

Below is a histogram of the historical (1908-2018) cutblock size. The negative "J" shaped curve is often similar to natural distrubance size - frequency which provides some empirical evidence of cutblock size emulating natural disturbances. 

![](draft-CLUS-blocking_files/figure-html/unnamed-chunk-2-1.png)<!-- -->![](draft-CLUS-blocking_files/figure-html/unnamed-chunk-2-2.png)<!-- -->

```
##    size    fitted.p
## 1:   40 0.871201251
## 2:   80 0.089498035
## 3:  120 0.025656662
## 4:  160 0.008613012
## 5:  220 0.003803053
## 6:  240 0.001227987
```

To provide a comparison to the proccess that mimicks timber supply review assumptions, we used a patch size distribution from the [biodiversity handbook](https://www.for.gov.bc.ca/hfd/library/documents/bib19715.pdf) which provides a unique target distribution for each natural disturbance type. 
![](draft-CLUS-blocking_files/figure-html/patchsize-1.png)<!-- -->


#References

Felzenszwalb, P.F. and Huttenlocher, D.P., 2004. Efficient graph-based image segmentation. International journal of computer vision, 59(2), pp.167-181.

Gustafson, E.J. 1998. Clustering timber harvests and the effect of dynamic forest management policy on forest fragmentation.
Ecosystems 1:484-492.

Johnson, K.N., Scheurman, H.L. 1977. Techniques for prescribing optimal timber harvest and investment under different objectives--discussion and synthesis. Forest Sci. 23(1): a0001–z0001. doi: 10.1093/forestscience/23.s1.a0001.

Lu, F. and Eriksson, L.O. 2000. Formation of harvest units with genetic algorithms. For. Ecol. And Manage. 130:57-67.

Nelson, J.D. 2001. Assessment of harvest blocks generate from operational polygons and forest cover polygons in tactical and strategic planning. Can. J. For. Res. 31:682-693.

Murray, A.T. 1999. Spatial Restrictions in harvest scheduling. Forest Science 45(1): 45-52.

Murray, A.T., and Weintraub, A. 2002. Scale and unit specification influences in harvest scheduling with maximum area restrictions. For. Sci. 48(4):779-789.


