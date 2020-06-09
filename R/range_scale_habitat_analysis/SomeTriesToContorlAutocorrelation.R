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
