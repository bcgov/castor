nb_pt <- 50
dd <- data.frame(x = runif(nb_pt, 0, 100),
                 y = runif(nb_pt, 0,50))

sf <- sf::st_as_sf(dd, coords = c("x","y"))
sf<-as(sf, "Spatial")

n.points.targ <- 15 # targeted no of points/plots (actual may be a little different)
set.seed(3)
sample.bas <- bas.point(sf, n.points.targ)

plot(sf)
plot(sample.bas, col = 'red', add=T)


library(BalancedSampling)
library(sampling)
n <- 10
pi <- inclusionprobabilities(runif(nrow(dd), 0,1), n)
X <- cbind(dd$x, dd$y)

units <- lpm(pi, X, h = 100)
sample.lpm1 <- dd[units, ]
plot(sf)
plot(sf::st_as_sf(sample.lpm1, coords = c("x","y")), col = 'red', add=T)

##TRY
den.pix.coords<- data.table(xyFromCell(den.rast, den.pix$pixelid))
dd <- unique(den.pix.coords)
sf <- sf::st_as_sf(dd, coords = c("x","y"))
sf<-as(sf, "Spatial")
plot(sf)

n.points.targ <- round(nrow(den.pix.coords)/ 3000, 0) # targeted no of points/plots (actual may be a little different)
set.seed(3)
sample.bas <- bas.point(sf, n.points.targ)

plot(sf)
plot(sample.bas, col = 'red', add=T)

#LPM

n <- 100
pi <- inclusionprobabilities(rep(1/nrow(dd), nrow(dd)), n)
X <- cbind(dd$x, dd$y)

units <- lpm(pi, cbind(dd$x, dd$y), h = 5000)
sample.lpm1 <- dd[units, ]
plot(sf)
plot(sf::st_as_sf(sample.lpm1, coords = c("x","y")), col = 'red', add=T)
