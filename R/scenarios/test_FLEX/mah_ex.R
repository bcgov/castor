
load(file = "F:/Fisher/Sub_Boreal_dry_FHE_home_ranges.rda")


#sample covariance matrix
sigma <- cov(Sub_Boreal_dry_FHE_home_ranges[,2:6])
#mean vector for Dry Forest Fisher
mu<-colMeans(Sub_Boreal_dry_FHE_home_ranges[,2:6])
#create a simulation of the multivariate normal
bivn <- MASS::mvrnorm(5000, mu = mu, Sigma = sigma )  
bivn.kde <- MASS::kde2d(bivn[,1], bivn[,5], n = 50)  
# plot the simulated distribution
image(bivn.kde, ylim=c(10,60), xlim =c(-1,4))      
contour(bivn.kde, add = TRUE)  

#examples (Denning, Rust, Cavity, CWD, Movement)
mahalanobis(c(1.2, 19, 0.3, 6, 31.0), mu,  sigma, FALSE)
mahalanobis(c(1.16, 19, 0.1, 6, 21.5), mu,  sigma, FALSE)
mahalanobis(c(1.16, 19, 0.1, 6, 8), mu, sigma, FALSE)
mahalanobis(c(1.1,    15, 0.2, 7,  7), mu, sigma, FALSE)
mahalanobis(c(1.16, 19, 0.45,   8.86, 21), mu, sigma, FALSE)
mahalanobis(c(1.16, 19.1, 0.45, 8.86, 21), mu, sigma, FALSE)
Sub_Boreal_dry_FHE_home_ranges$d2<-mahalanobis(Sub_Boreal_dry_FHE_home_ranges[,2:6], mu, sigma, FALSE)
Sub_Boreal_dry_FHE_home_ranges$p<-pchisq(Sub_Boreal_dry_FHE_home_ranges$d2, df=4, lower.tail=FALSE)

#robust covariance estimator via MCD
mcd<-MASS::cov.rob(Sub_Boreal_dry_FHE_home_ranges[,2:6], method = "mcd", nsamp = "exact")
bivn <- MASS::mvrnorm(5000, mu = mcd$center, Sigma = mcd$cov )  # from Mass package
bivn.kde <- MASS::kde2d(bivn[,1], bivn[,5], n = 50)   # from MASS package
image(bivn.kde)     
contour(bivn.kde, add = TRUE)  

mahalanobis(c(1.2, 19, 0.3, 6, 31.0), mcd$center,  mcd$cov, FALSE)
mahalanobis(c(1.16, 19, 0.1, 6, 21.5), mcd$center,  mcd$cov, FALSE)
mahalanobis(c(1.16, 19, 0.1, 6, 8), mcd$center, mcd$cov, FALSE)
mahalanobis(c(1.1,    15, 0.2, 7,  7), mcd$center, mcd$cov, FALSE)
mahalanobis(c(1.16, 19, 0.45,   8.86, 21), mcd$center, mcd$cov, FALSE)
mahalanobis(c(1.2, 19.8, 0.5, 6.2, 27.0), mcd$center,  mcd$cov, FALSE)
Sub_Boreal_dry_FHE_home_ranges$d2_mcd<-mahalanobis(Sub_Boreal_dry_FHE_home_ranges[,2:6], mcd$center, mcd$cov, FALSE)
Sub_Boreal_dry_FHE_home_ranges$p_mcd<-pchisq(Sub_Boreal_dry_FHE_home_ranges$d2_mcd, df=4, lower.tail=FALSE)
