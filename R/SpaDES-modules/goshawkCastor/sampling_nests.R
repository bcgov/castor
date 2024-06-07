#---------------------------------
# Example nesting site allocation via spatially balanced sampling
#---------------------------------
library(sf)
library(terra)
library(data.table)
#Parameters set by the user
required_min_dist = 900 #units in metres
rown = 100 #units of 100 m
coln =100 #units of 100 m

#create a hypothetical landscape with spatial projection to accommodate distances in metres
goshawkNestingHabitat<-rast(nrows = rown, ncols =coln, xmin = 1170000, xmax = 1170000 + coln*100, ymin = 834000, ymax = 834000 + rown*100, vals = runif(rown*coln))

#Initial maximum estimate of n_nests
n_nests = ceiling((rown*100)*(coln*100)/(3.14*(required_min_dist)**2))

#Sample the landscape until achieves the desired minimum spacing.
#As n_nests -> 0, the probability of achieving the desired spacing approaches 1
max_sample_size_needed = TRUE
while(max_sample_size_needed){
  pi <- sampling::inclusionprobabilities(seq(1/(rown*coln),rown*coln), n_nests) #Equal probability
  sim_ex<-rbindlist(lapply(1:250, function(x){
    seed.chosen = runif(1,1, 10000000)
    set.seed(seed.chosen )
    nest.samples <- data.table(cell = BalancedSampling::lpm2(pi, cbind(nests.available.coords$x, nests.available.coords$y))) 
    nest.samples$x<-terra::xFromCell(goshawkNestingHabitat, nest.samples$cell)
    nest.samples$y<-terra::yFromCell(goshawkNestingHabitat, nest.samples$cell)
    
    nest.samples$dists<-RANN::nn2(nest.samples[,c("x", "y")], nest.samples[,c("x", "y")], k=2)$nn.dists[,2]
    data.table(seed = seed.chosen , dist = min(nest.samples$dists))
  }))
   
  if(sim_ex[dist == max(sim_ex$dist), ]$dist[1] > required_min_dist){
    max_sample_size_needed <- FALSE
  }else{
    n_nests<-n_nests-1
  }
}

hist(sim_ex$dist)
result<-sim_ex[dist == max(sim_ex$dist), ]

#plot the result
set.seed(result$seed)
pi <- sampling::inclusionprobabilities(goshawkNestingHabitat[], n_nests) #Equal probability
nest.samples <- data.table(cell = BalancedSampling::lpm1(pi, cbind(nests.available.coords$x, nests.available.coords$y))) 
nest.samples$x<-terra::xFromCell(goshawkNestingHabitat, nest.samples$cell)
nest.samples$y<-terra::yFromCell(goshawkNestingHabitat, nest.samples$cell)

terra::plot(goshawkNestingHabitat)
points(nest.samples$x, nest.samples$y, cex =3) 
points(nest.samples$x, nest.samples$y, cex =1)


### spsurvey approach
goshawkNestingHabitat.sf<-st_as_sf(data.table(terra::xyFromCell(goshawkNestingHabitat, 1:10000)), coords = c("x", "y"), crs = 3005, agr = "constant")
goshawkNestingHabitat.sf$hv<-goshawkNestingHabitat[]
goshawk_legacy<-goshawkNestingHabitat.sf [sample(1:10000, 10),]

n_nests<-75
count = 0
max_sample_size_needed = TRUE
while(max_sample_size_needed){
  count = count +1
 test<-spsurvey::grts(goshawkNestingHabitat.sf, n_base = n_nests, mindis = required_min_dist, legacy_sites = goshawk_legacy)
 if(length(warn_df) > 0 & count > 50){
   n_nests<- n_nests-1
 }
 
 if(n_nests == 0 | length(warn_df) == 0){
   max_sample_size_needed <- FALSE
 }
 
 warn_df<-NULL
}

plot(goshawkNestingHabitat) 
plot(test, cex =3, add=T, col = 'black')

#### Spbsampling approach
library(Spbsampling)
#data("lucas_abruzzo", package = "Spbsampling")
gos.coords<-st_coordinates(goshawkNestingHabitat.sf)
dis_la <- as.matrix(dist(gos.coords))
dis_la_sf <- st_distance(goshawkNestingHabitat.sf)
con <- rep(0, nrow(dis_la))
stand_dist_la_pwd <- stprod(mat = dis_la, con = con)$mat