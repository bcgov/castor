# things I did to test Autocorrelation

# 1.) I sampled subsets of my data from my big dataset to see if the pattern stayed even when my samples were different. 
# Outcome: The pattern did not change even when I sampled 25% of my data 10 different times. 
# This suggests that the pattern is a large landscale pattern

setwd("C:\\Work\\caribou\\clus_data\\caribou_range_scale_model\\du6_resid_test")

for (i in 1:10){
  du6_0_25perc<-du6 %>% filter(pttype==0) %>% sample_frac(0.25)
  du6_1_25perc<-du6 %>% filter(pttype==1) %>% sample_frac(0.25)
  du6_perc25<-rbind(du6_0_25perc,du6_1_25perc)
  
  model.lme4.du6.25perc <- glmer (pttype ~ distance_to_road +
                                    distance_to_cut_1to5yo +
                                    distance_to_cut_6to10yo +
                                    distance_to_cut_11to40yo +
                                    (distance_to_road +
                                       distance_to_cut_1to5yo +
                                       distance_to_cut_6to10yo +
                                       distance_to_cut_11to40yo || HERD_NAME) +
                                    (1|year),
                                  nAGQ = 0,
                                  data = du6_perc25, 
                                  family = binomial (link = "logit"),
                                  verbose = T) 
  
  nam1<-paste("mod.du6.resid",i,"pdf",sep=".")
  pdf(nam1)
  binnedplot (fitted(model.lme4.du6.25perc), 
              residuals(model.lme4.du6.25perc, type = "response"), 
              nclass = NULL, 
              xlab = "Expected Values", 
              ylab = "Average residual", 
              main = paste("DU6 Model Binned Residual Plot",i,sep=" "), 
              cex.pts = 0.4, 
              col.pts = 1, 
              col.int = "red")
              
   dev.off()
              
  
}

##
# I also tried running different fits of my model i.e. polynomial fits e.g. example below.
# This had no impact


model.lme4.du7.cut.rd.yr <- glm (pttype ~ poly(distance_to_road,5, raw=TRUE) +
                                   poly(distance_to_cut_1to40yo,4, raw = TRUE),
                                 data = du7, 
                                 family = binomial (link = "logit"))  
plot(du7$distance_to_cut_1to40yo, du7$pttype,)
curve (invlogit (coef(model.lme4.du7.cut.rd.yr)[1] + coef(model.lme4.du7.cut.rd.yr)[2]*x), add=TRUE)

binnedplot (fitted (model.lme4.du7.cut.rd.yr), 
            residuals(model.lme4.du7.cut.rd.yr, type = "response"), 
            nclass = 1000, 
            xlab = "Expected Values", 
            ylab = "Average residual",
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

binnedplot (du7$distance_to_road, 
            residuals(model.lme4.du7.cut.rd.yr, type = "response"), 
            nclass = 1000, 
            xlab = "Expected Values", 
            ylab = "Average residual",
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

binnedplot (du7$distance_to_cut_1to40yo, 
            residuals(model.lme4.du7.cut.rd.yr, type = "response"), 
            nclass = 1000, 
            xlab = "Expected Values", 
            ylab = "Average residual",
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

summary(model.lme4.du7.cut.rd.yr)
Anova(model.lme4.du7.cut.rd.yr,type="III")

max(fitted(model.lme4.du7.cut.rd.yr))

error.rate <- mean ((predicted>0.5 & y==0) | (predicted<.5 & y==1))


####################
# I also tried subsetting my data into the different herds and running individual models on individual herds. E.g. below. I ran these models just as glm's
# outcome: this did not help either there was still crazy structure in my binned residual plots
#####################
# Kennedy Siding
Kennedy<-du8.sample %>% filter(HERD_NAME=="Kennedy Siding")


model.kennedy <- glm (pttype ~ distance_to_road +
                        distance_to_cut_1to5yo +
                        distance_to_cut_6to40yo + year,
                      data = Kennedy, 
                      #nAGQ=0,
                      family = binomial (link = "logit")) 
summary(model.kennedy)
binnedplot (predict (model.kennedy), 
            residuals(model.kennedy, type = "response"), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual",
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

Kennedy$resid<-resid(model.kennedy, type="response")

binnedplot (Kennedy$distance_to_road, 
            Kennedy$resid, 
            nclass = NULL, 
            xlab = "Distance to road", 
            ylab = "Average residual",
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

binnedplot (Kennedy$distance_to_cut_1to5yo, 
            Kennedy$resid, 
            nclass = NULL, 
            xlab = "Distance to 1 to 5 cut", 
            ylab = "Average residual",
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

binnedplot (Kennedy$distance_to_cut_6to40yo, 
            Kennedy$resid, 
            nclass = NULL, 
            xlab = "Distance to 6 to 40 cut", 
            ylab = "Average residual",
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

# Narraway
Narraway<-du8.sample %>% filter(HERD_NAME=="Narraway")


model.Narraway <- glm (pttype ~ distance_to_road,
                       distance_to_cut_1to5yo +
                         distance_to_cut_6to40yo + year ,
                       data = Narraway, 
                       # nAGQ=0,
                       family = binomial (link = "logit")) 
summary(model.Narraway)
binnedplot (predict (model.Narraway), 
            residuals(model.Narraway, type = "response"), 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual",
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

Narraway$resid<-resid(model.Narraway, type="response")

binnedplot (Narraway$distance_to_road, 
            Narraway$resid, 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual",
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

binnedplot (Narraway$distance_to_cut_1to5yo, 
            Narraway$resid, 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual",
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

binnedplot (Narraway$distance_to_cut_6to40yo, 
            Narraway$resid, 
            nclass = NULL, 
            xlab = "Expected Values", 
            ylab = "Average residual",
            cex.pts = 0.4, 
            col.pts = 1, 
            col.int = "red")

# I also plotted semivariograms
coordinates(Narraway_new)=~lat+lon
v1<-variogram(resid1~lat+lon, Narraway_new,alpha=c(0,45,90,135))
plot(v1, main="X-Y smoothing term")


# I tried running a gam with a smoothing term with latitude and longitude to accound to spatial patterns
# e.g. below
# this helped quite a bit but did not remove the spatial autocorrelation entirely.

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

# lastly I tried including a glmmpql with a correlation term to account for cells that are closer together being more similar than cells futher away. There are various correlation structures that can be specified e.g. linear, exponential, gaussian, spherical, and ratio. I tried them all.

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




summary(gam1)

