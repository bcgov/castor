The forest hierarchy code uses graph based image segementation to cluster pixels into harvest units under the constraint of homogeneity and patch size distribution.

Homogeneity is defined as the [Mahalanobis distance](https://en.wikipedia.org/wiki/Mahalanobis_distance) of height and basal area within a cluster or harvest unit. A small Mahalanobis distance indicates greater homogeneity within a harvest unit.
