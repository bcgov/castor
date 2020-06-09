library (dplyr)
library (ggplot2)
library (lme4)
library (arm)
library (car)
library (optimx)
library (dfoptim)
library (kableExtra)
library (here)
library (magick)
library (data.table)
require (ggcorrplot)
require (sf)
require (RPostgreSQL)
require (rpostgis)
library(sjPlot)
library(sjlabelled)
library(sjmisc)
library(ggeffects)
library(cowplot)
library(ggpubr)
library(mgcv)
library(mgcViz)
library(geoR)
library(gstat)
library(rgdal)
library(magrittr)

conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")
Range_scale_data <- sf::st_read  (dsn = conn, # connKyle
                                  query = "SELECT * FROM caribou.try")
dbDisconnect (conn) # connKyle

#convert distances to km. I created distance rasters in QGIS in pixel (ha) scale so here I convert the number of pixels i.e. ha between points to km

Range_scale_data$distance_to_cut_1yo<-Range_scale_data$distance_to_cut_1yo/100
Range_scale_data$distance_to_cut_2yo<-Range_scale_data$distance_to_cut_2yo/100
Range_scale_data$distance_to_cut_3yo<-Range_scale_data$distance_to_cut_3yo/100
Range_scale_data$distance_to_cut_4yo<-Range_scale_data$distance_to_cut_4yo/100
Range_scale_data$distance_to_cut_5yo<-Range_scale_data$distance_to_cut_5yo/100
Range_scale_data$distance_to_cut_6yo<-Range_scale_data$distance_to_cut_6yo/100
Range_scale_data$distance_to_cut_7yo<-Range_scale_data$distance_to_cut_7yo/100
Range_scale_data$distance_to_cut_8yo<-Range_scale_data$distance_to_cut_8yo/100
Range_scale_data$distance_to_cut_9yo<-Range_scale_data$distance_to_cut_9yo/100
Range_scale_data$distance_to_cut_10yo<-Range_scale_data$distance_to_cut_10yo/100
Range_scale_data$distance_to_cut_11yo<-Range_scale_data$distance_to_cut_11yo/100
Range_scale_data$distance_to_cut_12yo<-Range_scale_data$distance_to_cut_12yo/100
Range_scale_data$distance_to_cut_13yo<-Range_scale_data$distance_to_cut_13yo/100
Range_scale_data$distance_to_cut_14yo<-Range_scale_data$distance_to_cut_14yo/100
Range_scale_data$distance_to_cut_15yo<-Range_scale_data$distance_to_cut_15yo/100
Range_scale_data$distance_to_cut_16yo<-Range_scale_data$distance_to_cut_16yo/100
Range_scale_data$distance_to_cut_17yo<-Range_scale_data$distance_to_cut_17yo/100
Range_scale_data$distance_to_cut_18yo<-Range_scale_data$distance_to_cut_18yo/100
Range_scale_data$distance_to_cut_19yo<-Range_scale_data$distance_to_cut_19yo/100
Range_scale_data$distance_to_cut_20yo<-Range_scale_data$distance_to_cut_20yo/100
Range_scale_data$distance_to_cut_21yo<-Range_scale_data$distance_to_cut_21yo/100
Range_scale_data$distance_to_cut_22yo<-Range_scale_data$distance_to_cut_22yo/100
Range_scale_data$distance_to_cut_23yo<-Range_scale_data$distance_to_cut_23yo/100
Range_scale_data$distance_to_cut_24yo<-Range_scale_data$distance_to_cut_24yo/100
Range_scale_data$distance_to_cut_25yo<-Range_scale_data$distance_to_cut_25yo/100
Range_scale_data$distance_to_cut_26yo<-Range_scale_data$distance_to_cut_26yo/100
Range_scale_data$distance_to_cut_27yo<-Range_scale_data$distance_to_cut_27yo/100
Range_scale_data$distance_to_cut_28yo<-Range_scale_data$distance_to_cut_28yo/100
Range_scale_data$distance_to_cut_29yo<-Range_scale_data$distance_to_cut_29yo/100
Range_scale_data$distance_to_cut_30yo<-Range_scale_data$distance_to_cut_30yo/100
Range_scale_data$distance_to_cut_31yo<-Range_scale_data$distance_to_cut_31yo/100
Range_scale_data$distance_to_cut_32yo<-Range_scale_data$distance_to_cut_32yo/100
Range_scale_data$distance_to_cut_33yo<-Range_scale_data$distance_to_cut_33yo/100
Range_scale_data$distance_to_cut_34yo<-Range_scale_data$distance_to_cut_34yo/100
Range_scale_data$distance_to_cut_35yo<-Range_scale_data$distance_to_cut_35yo/100
Range_scale_data$distance_to_cut_36yo<-Range_scale_data$distance_to_cut_36yo/100
Range_scale_data$distance_to_cut_37yo<-Range_scale_data$distance_to_cut_37yo/100
Range_scale_data$distance_to_cut_38yo<-Range_scale_data$distance_to_cut_38yo/100
Range_scale_data$distance_to_cut_39yo<-Range_scale_data$distance_to_cut_39yo/100
Range_scale_data$distance_to_cut_40yo<-Range_scale_data$distance_to_cut_40yo/100
Range_scale_data$distance_to_cut_41yo<-Range_scale_data$distance_to_cut_41yo/100
Range_scale_data$distance_to_cut_42yo<-Range_scale_data$distance_to_cut_42yo/100
Range_scale_data$distance_to_cut_43yo<-Range_scale_data$distance_to_cut_43yo/100
Range_scale_data$distance_to_cut_44yo<-Range_scale_data$distance_to_cut_44yo/100
Range_scale_data$distance_to_cut_45yo<-Range_scale_data$distance_to_cut_45yo/100
Range_scale_data$distance_to_cut_46yo<-Range_scale_data$distance_to_cut_46yo/100
Range_scale_data$distance_to_cut_47yo<-Range_scale_data$distance_to_cut_47yo/100
Range_scale_data$distance_to_cut_48yo<-Range_scale_data$distance_to_cut_48yo/100
Range_scale_data$distance_to_cut_49yo<-Range_scale_data$distance_to_cut_49yo/100
Range_scale_data$distance_to_cut_50yo<-Range_scale_data$distance_to_cut_50yo/100
Range_scale_data$dist_crds_resource<-Range_scale_data$dist_crds_resource/1000 # dividing by 1000 because the distance raster was created by Tyler and this is what he does in his script to convert his values to km.
Range_scale_data$dist_crds_loose<-Range_scale_data$dist_crds_loose/1000
Range_scale_data$dist_crds_paved<-Range_scale_data$dist_crds_paved/1000
Range_scale_data$dist_crds_petroleum<-Range_scale_data$dist_crds_petroleum/1000
Range_scale_data$dist_crds_rough<-Range_scale_data$dist_crds_rough/1000
Range_scale_data$dist_crds_trim_transport<-Range_scale_data$dist_crds_trim_transport/1000
Range_scale_data$dist_crds_unknown<-Range_scale_data$dist_crds_unknown/1000

Range_scale_data$cnt<-1

#write.csv(Range_scale_data, file="C:\\Work\\caribou\\clus\\R\\range_scale_habitat_analysis\\data\\Range_scale_data.csv")

#Range_scale_data$distance_to_resource_road<-Range_scale_data$dist_crds_resource
#Range_scale_data$distance_to_resource_road_log<-log(Range_scale_data$distance_to_resource_road+0.00001)


# Binning the data into cutblock age categories and binned distance to the disturbance
Range_scale_data <- dplyr::mutate (Range_scale_data, distance_to_cut_1to5yo = pmin (distance_to_cut_1yo, distance_to_cut_2yo, distance_to_cut_3yo, distance_to_cut_4yo, distance_to_cut_5yo))

Range_scale_data <- dplyr::mutate (Range_scale_data, distance_to_cut_6to10yo = pmin (distance_to_cut_6yo, distance_to_cut_7yo,distance_to_cut_8yo, distance_to_cut_9yo, distance_to_cut_10yo))

Range_scale_data <- dplyr::mutate (Range_scale_data, distance_to_cut_11to40yo = pmin (distance_to_cut_11yo, distance_to_cut_12yo, distance_to_cut_13yo, distance_to_cut_14yo,distance_to_cut_15yo,distance_to_cut_16yo, distance_to_cut_17yo, distance_to_cut_18yo, distance_to_cut_19yo,distance_to_cut_20yo,distance_to_cut_21yo, distance_to_cut_22yo, distance_to_cut_23yo, distance_to_cut_24yo, distance_to_cut_25yo, distance_to_cut_26yo, distance_to_cut_27yo, distance_to_cut_28yo, distance_to_cut_2yo, distance_to_cut_30yo, distance_to_cut_31yo, distance_to_cut_32yo, distance_to_cut_33yo, distance_to_cut_34yo, distance_to_cut_35yo, distance_to_cut_36yo, distance_to_cut_37yo,distance_to_cut_38yo, distance_to_cut_39yo, distance_to_cut_40yo))

Range_scale_data <- dplyr::mutate (Range_scale_data, distance_to_road = pmin (dist_crds_resource))

Range_scale_data_st <- st_transform (Range_scale_data, 3005)
st_crs(Range_scale_data_st) # this confirmes that my data is in UTM's and that the scale of measurment i.e. distance between points is measured in meters.

#plot(st_geometry(prov.bnd)) 
#plot(st_geometry(Range_scale_data_st), add=TRUE)


xy.coordinates<-st_as_sf(Range_scale_data_st, coords=c("lon","lat"))
xy.coordinates2 <- do.call(rbind, st_geometry(xy.coordinates)) %>% 
  as_tibble() %>% setNames(c("lon","lat"))
Range_scale_data2<-Range_scale_data_st[,c(1:6,64, 67:70)]
Range_scale_data2<-st_set_geometry(Range_scale_data2,NULL)

Range_scale_data1<-cbind(Range_scale_data2,xy.coordinates2)


library(mgcv)
Narraway<-Range_scale_data1 %>% filter(HERD_NAME=="Calendar", year==2010)
Narraway$individual<-as.factor(Narraway$individual)
Narraway$year<-as.numeric(Narraway$year)
str(Narraway)

# run GLM and test for autocorrelation
library(NLMR)
library(DHARMa)

glm_mod<-glm(pttype~distance_to_road + 
               distance_to_cut_1to5yo +
               distance_to_cut_6to10yo +
               distance_to_cut_11to40yo + individual,
             family=binomial, 
             data=Narraway)

Narraway$resids<-resid(glm_mod)
Narraway_new<-Narraway
coordinates(Narraway_new)=~lat+lon
ggplot(Narraway, aes(x=lat,y=lon,size=resids)) +
  geom_point() +
  scale_size_continuous(range=c(0,5))

library(spdep)
moran.mc(Narraway$resids,lw,999)



# try gam now


gam1<-gam(pttype~distance_to_road + 
            distance_to_cut_1to5yo +
            distance_to_cut_6to10yo +
            distance_to_cut_11to40yo + 
            s(individual, bs="re") +
            #s(year, bs="re") +
            s(lat,lon) ,
          family = binomial(link="logit"),
          data = Narraway 
          )

summary(gam1)


gam2<-gam(pttype~distance_to_road + 
            distance_to_cut_1to5yo +
            distance_to_cut_6to10yo +
            distance_to_cut_11to40yo + 
            #s(individual, bs="re") +
            s(year, bs="re") +
            s(lat,lon) ,
          family = binomial,
          data = Narraway 
)
summary(gam2)

gam3<-gam(pttype~distance_to_road + 
            distance_to_cut_1to5yo +
            distance_to_cut_6to10yo +
            distance_to_cut_11to40yo + 
            s(individual, bs="re") +
            #s(year, bs="re") +
            s(lat,lon) ,
          family = binomial(link="logit"),
          data = Narraway 
)
summary(gam3)

gam4<-gam(pttype~distance_to_road + 
            distance_to_cut_1to5yo +
            distance_to_cut_6to10yo +
            distance_to_cut_11to40yo + 
            s(individual, bs="re") +
            s(year, bs="re"),
            #s(lat,lon) ,
          family = binomial,
          data = Narraway 
)
summary(gam4)



AIC(gam1)
plot(fitted(gam1), residuals(gam1))
AIC(gam1_te)
AIC(gam2)
AIC(gam3)
AIC(gam4)

Narraway_new<-Narraway
Narraway_new$resid1<-resid(gam1)
coordinates(Narraway_new)=~lat+lon
v1<-variogram(resid1~lat+lon, Narraway_new,alpha=c(0,45,90,135))
plot(v1, main="X-Y smoothing term")

binnedplot (fitted(gam1), 
            residuals(gam1), 
            nclass = 100, 
            xlab = "Expected Values", 
            ylab = "Average residual",
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

binnedplot (Narraway$distance_to_road, 
            residuals(gam1), 
            nclass = 100, 
            xlab = "Expected Values", 
            ylab = "Average residual",
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

binnedplot (Narraway$distance_to_cut_1to5yo, 
            residuals(gam1), 
            nclass = 100, 
            xlab = "Expected Values", 
            ylab = "Average residual",
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

binnedplot (Narraway$distance_to_cut_6to10yo, 
            residuals(gam1), 
            nclass = 100, 
            xlab = "Expected Values", 
            ylab = "Average residual",
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

binnedplot (Narraway$distance_to_cut_11to40yo, 
            residuals(gam1), 
            nclass = 100, 
            xlab = "Expected Values", 
            ylab = "Average residual",
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")


require(spdep)
?autocov_dist
# prepare neighbour lists for spatial autocorrelation analysis
nb.list <- dnearneigh(as.matrix(Narraway[,c("X", "Y")]), 0, 5)
nb.weights <- nb2listw(nb.list)
#Make a matrix of coordinates
coords<-as.matrix(cbind(data$X,data$Y))
# compute the autocovariate based on the above distance and weight
ac <- autocov_dist(snouter1.1, coords, nbs = 1, type = "inverse")



model.Narraway8 <- glm (pttype ~ distance_to_road + 
                           distance_to_cut_1to5yo +
                           distance_to_cut_6to10yo +
                           distance_to_cut_11to40yo,
                    data = Narraway, 
                    family = binomial (link = "probit"))

summary(model.Narraway8)
drop1(model.Narraway8)
temp_data=data.frame(error=rstandard(model.Narraway8), x=Narraway8$lat, y=Narraway8$lon)
coordinates(temp_data)=~x+y
bubble(temp_data,"error",col=c("black","grey"),
       main="residuals",xlab="x-coordinates",ylab="Y-coordinates")
plot(temp_data$error~temp_data$x)
plot(temp_data$error~temp_data$y)
plot(variogram(error~1,temp_data))

# construct models with correlation structure

library(MASS)
library(nlme)

modelbase<-glmmPQL(pttype ~ distance_to_road + 
                  distance_to_cut_1to5yo +
                  distance_to_cut_6to10yo +
                  distance_to_cut_11to40yo, 
                random=~1|individual,
                data = Narraway8, 
                family = binomial (link = "logit"))
summary(modelbase)
plot(Variogram(modelbase), main="uncorrelated")
Narraway8$resid<-residuals(modelbase, type="normalized")


model1<-glmmPQL(pttype ~ distance_to_road + 
              distance_to_cut_1to5yo +
              distance_to_cut_6to10yo +
              distance_to_cut_11to40yo, 
              random=~1|individual,
              correlation=corAR1(),
            data = Narraway, 
            family = binomial (link = "logit"))
summary(model1)
plot(Variogram(model1), main="corAR1")


model2<-glmmPQL(pttype ~ distance_to_road + 
                  distance_to_cut_1to5yo +
                  distance_to_cut_6to10yo +
                  distance_to_cut_11to40yo, 
                random=~1|individual,
                correlation=corExp(),
                data = Narraway, 
                family = binomial (link = "logit"))
summary(model2)
plot(Variogram(model2), main="Exponential")

binnedplot(Narraway$distance_to_road,resid(model2))
binnedplot(Narraway$distance_to_cut_1to5yo,resid(model2))
binnedplot(Narraway$distance_to_cut_6to10yo,resid(model2))
plot(Narraway$distance_to_cut_11to40yo,resid(model2))




Narraway16$resid1<-residuals(model1, type="normalized")
coordinates(Narraway16)=~lat+lon
v1<-variogram(resid1~lat+lon, Narraway16,alpha=c(0,45,90,135))
plot(v1, main="Exponential correlation")

model2<-glmmPQL(pttype ~ distance_to_road + 
                  distance_to_cut_1to5yo +
                  distance_to_cut_6to10yo +
                  distance_to_cut_11to40yo, 
                random=~1|year,
                correlation=corGaus(form=~lat+lon, nugget=T),
                data = Narraway, 
                family = binomial (link = "probit"))
summary(model2)
Narraway$resid2<-residuals(model2, type="normalized")
v2<-variogram(resid2~lat+lon, Narraway)
plot(v2, main="Gaussian correlation")

model3<-glmmPQL(pttype ~ distance_to_road + 
                  distance_to_cut_1to5yo +
                  distance_to_cut_6to10yo +
                  distance_to_cut_11to40yo, 
                random=~1|year,
                correlation=corSpher(form=~x+y, nugget=T),
                data = Narraway16, 
                family = binomial (link = "probit"))
summary(model3)
Narraway16$resid<-residuals(model3, type="normalized")
coordinates(Narraway16)=~lat+lon
v3<-variogram(resid~lat+lon, Narraway16)
plot(v3, main="Spherical correlation")


model4<-glmmPQL(pttype ~ distance_to_road + 
                  distance_to_cut_1to5yo +
                  distance_to_cut_6to10yo +
                  distance_to_cut_11to40yo, 
                random=~1|year,
                correlation=corRatio(form=~x+y, nugget=T),
                data = Narraway16, 
                family = binomial (link = "probit"))
summary(model4)
Narraway16$resid<-residuals(model4, type="normalized")
coordinates(Narraway16)=~lat+lon
v4<-variogram(resid~lat+lon, Narraway16)
plot(v4, main="Rational Quadratic correlation")

vroad<-variogram(distance_to~lat+lon, Narraway16)







Narraway8<-Range_scale_data1 %>% filter(HERD_NAME=="Narraway", year=="2008")
model.Narraway8 <- glm (pttype ~ distance_to_road ,
                         data = Narraway8, 
                         family = binomial (link = "logit"))

Narraway8$resid<-residuals(model.Narraway8, type="response")
coordinates(Narraway8)=~lat+lon
v<-variogram(resid~lat+lon, Narraway8, alpha=c(0,45,90,135))
plot(v)

Narraway9<-Range_scale_data1 %>% filter(HERD_NAME=="Narraway", year=="2009")
model.Narraway9 <- glm (pttype ~ distance_to_road ,
                        data = Narraway9, 
                        family = binomial (link = "logit"))

Narraway9$resid<-residuals(model.Narraway9, type="response")
coordinates(Narraway9)=~lat+lon
v<-variogram(resid~lat+lon, Narraway9, alpha=c(0,45,90,135))
plot(v)

Narraway10<-Range_scale_data1 %>% filter(HERD_NAME=="Narraway", year=="2010")
model.Narraway10 <- glm (pttype ~ distance_to_road ,
                        data = Narraway10, 
                        family = binomial (link = "logit"))

Narraway10$resid<-residuals(model.Narraway10, type="response")
Narraway10red<-Narraway10 %>% sample_frac(0.05)
coordinates(Narraway10red)=~lat+lon
bubble(Narraway10red, "resid")

plot(Narraway10red[Narraway10red$pttype==1,], pch = 1, col="blue")
points(Narraway10red[Narraway10red$pttype==0,], pch = 6, col="red")

v<-variogram(resid~lat+lon, Narraway10red, alpha=c(0,45,90,135))
plot(v)


binnedplot (predict (model.Narraway), 
            residuals(model.Narraway, type = "response"), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual",
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

Narraway$resid<-residuals(model.Narraway, type="response")
coordinates(Narraway)=~lat+lon

bubble(Narraway10red, "resid")
