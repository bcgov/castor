options (scipen = 999)
require (RPostgreSQL)
require (dplyr)
require (ggplot2)
require (raster)
require (rgdal)
require (tidyr)
# require (snow)
require (ggcorrplot)
require (rpart)
require (car)
require (reshape2)
require (lme4)
require (mgcv)
require (gamm4)
require (lattice)
require (ROCR)
library(scales)
library(RColorBrewer)
library(multipanelfigure)
library(jpeg)



#================
# Cutblocks Data Tylers points
#===============
#rsf_data_forestry<-read.csv("C:\\Work\\caribou\\clus_data\\rsf_data_foresty.csv",header=FALSE,col.names=c("pt_id","pttype","uniqueID","du","season","animal_id","year","ECOTYPE","HERD_NAME","ptID","distance_to_cut_1to4yo","distance_to_cut_5to9yo","distance_to_cut_10to29yo","distance_to_cut_30orOveryo","distance_to_paved_road","distance_to_loose_road","distance_to_petroleum_road","distance_to_rough_road","distance_to_trim_transport_road","distance_to_unknown_road",".R_rownames"))

rsf.data.cut.age<-read.csv("T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\caribou\\telemetry_habitat_model_20180904\\rsf_data_cutblock_age.csv")
head(rsf.data.cut.age)

unique(rsf.data.cut.age$pttype)
rsf_data_forestry <- rsf.data.cut.age %>% filter(pttype==0)
rsf_data_forestry$pttype<-1 

#====================================
# Join rsf.data.cut.age to rsf.large.scale.data.age
#===================================
#setwd("C:\\Work\\caribou\\clus_data\\disturbance\\")
#rsf_data_cutblock_age<-read.csv(file='rsf_data_cutblock_age_and_roads.csv')

rsf.large.scale.data.age$ECOTYPE<-rsf.large.scale.data.age$avail.ecotype
rsf.large.scale.data.age$pttype<-0

rsf.large.scale<-rsf.large.scale.data.age[,c(66,65,3:5,14:64)]
rsf_tyler<-rsf_data_forestry[,c(1,7,6,8,3,10:59)]
head(rsf.large.scale)
head(rsf_tyler)

rsf.large.scale$distance_to_cut_1yo<-rsf.large.scale$distance_to_cut_1yo*100
rsf.large.scale$distance_to_cut_2yo<-rsf.large.scale$distance_to_cut_2yo*100
rsf.large.scale$distance_to_cut_3yo<-rsf.large.scale$distance_to_cut_3yo*100
rsf.large.scale$distance_to_cut_4yo<-rsf.large.scale$distance_to_cut_4yo*100
rsf.large.scale$distance_to_cut_5yo<-rsf.large.scale$distance_to_cut_5yo*100
rsf.large.scale$distance_to_cut_6yo<-rsf.large.scale$distance_to_cut_6yo*100
rsf.large.scale$distance_to_cut_7yo<-rsf.large.scale$distance_to_cut_7yo*100
rsf.large.scale$distance_to_cut_8yo<-rsf.large.scale$distance_to_cut_8yo*100
rsf.large.scale$distance_to_cut_9yo<-rsf.large.scale$distance_to_cut_9yo*100
rsf.large.scale$distance_to_cut_10yo<-rsf.large.scale$distance_to_cut_10yo*100
rsf.large.scale$distance_to_cut_11yo<-rsf.large.scale$distance_to_cut_11yo*100
rsf.large.scale$distance_to_cut_12yo<-rsf.large.scale$distance_to_cut_12yo*100
rsf.large.scale$distance_to_cut_13yo<-rsf.large.scale$distance_to_cut_13yo*100
rsf.large.scale$distance_to_cut_14yo<-rsf.large.scale$distance_to_cut_14yo*100
rsf.large.scale$distance_to_cut_15yo<-rsf.large.scale$distance_to_cut_15yo*100
rsf.large.scale$distance_to_cut_16yo<-rsf.large.scale$distance_to_cut_16yo*100
rsf.large.scale$distance_to_cut_17yo<-rsf.large.scale$distance_to_cut_17yo*100
rsf.large.scale$distance_to_cut_18yo<-rsf.large.scale$distance_to_cut_18yo*100
rsf.large.scale$distance_to_cut_19yo<-rsf.large.scale$distance_to_cut_19yo*100
rsf.large.scale$distance_to_cut_20yo<-rsf.large.scale$distance_to_cut_20yo*100
rsf.large.scale$distance_to_cut_21yo<-rsf.large.scale$distance_to_cut_21yo*100
rsf.large.scale$distance_to_cut_22yo<-rsf.large.scale$distance_to_cut_22yo*100
rsf.large.scale$distance_to_cut_23yo<-rsf.large.scale$distance_to_cut_23yo*100
rsf.large.scale$distance_to_cut_24yo<-rsf.large.scale$distance_to_cut_24yo*100
rsf.large.scale$distance_to_cut_25yo<-rsf.large.scale$distance_to_cut_25yo*100
rsf.large.scale$distance_to_cut_26yo<-rsf.large.scale$distance_to_cut_26yo*100
rsf.large.scale$distance_to_cut_27yo<-rsf.large.scale$distance_to_cut_27yo*100
rsf.large.scale$distance_to_cut_28yo<-rsf.large.scale$distance_to_cut_28yo*100
rsf.large.scale$distance_to_cut_29yo<-rsf.large.scale$distance_to_cut_29yo*100
rsf.large.scale$distance_to_cut_30yo<-rsf.large.scale$distance_to_cut_30yo*100
rsf.large.scale$distance_to_cut_31yo<-rsf.large.scale$distance_to_cut_31yo*100
rsf.large.scale$distance_to_cut_32yo<-rsf.large.scale$distance_to_cut_32yo*100
rsf.large.scale$distance_to_cut_33yo<-rsf.large.scale$distance_to_cut_33yo*100
rsf.large.scale$distance_to_cut_34yo<-rsf.large.scale$distance_to_cut_34yo*100
rsf.large.scale$distance_to_cut_35yo<-rsf.large.scale$distance_to_cut_35yo*100
rsf.large.scale$distance_to_cut_36yo<-rsf.large.scale$distance_to_cut_36yo*100
rsf.large.scale$distance_to_cut_37yo<-rsf.large.scale$distance_to_cut_37yo*100
rsf.large.scale$distance_to_cut_38yo<-rsf.large.scale$distance_to_cut_38yo*100
rsf.large.scale$distance_to_cut_39yo<-rsf.large.scale$distance_to_cut_39yo*100
rsf.large.scale$distance_to_cut_40yo<-rsf.large.scale$distance_to_cut_40yo*100
rsf.large.scale$distance_to_cut_41yo<-rsf.large.scale$distance_to_cut_41yo*100
rsf.large.scale$distance_to_cut_42yo<-rsf.large.scale$distance_to_cut_42yo*100
rsf.large.scale$distance_to_cut_43yo<-rsf.large.scale$distance_to_cut_43yo*100
rsf.large.scale$distance_to_cut_44yo<-rsf.large.scale$distance_to_cut_44yo*100
rsf.large.scale$distance_to_cut_45yo<-rsf.large.scale$distance_to_cut_45yo*100
rsf.large.scale$distance_to_cut_46yo<-rsf.large.scale$distance_to_cut_46yo*100
rsf.large.scale$distance_to_cut_47yo<-rsf.large.scale$distance_to_cut_47yo*100
rsf.large.scale$distance_to_cut_48yo<-rsf.large.scale$distance_to_cut_48yo*100
rsf.large.scale$distance_to_cut_49yo<-rsf.large.scale$distance_to_cut_49yo*100
rsf.large.scale$distance_to_cut_50yo<-rsf.large.scale$distance_to_cut_50yo*100

rsf.large.scale<-st_set_geometry(rsf.large.scale,NULL)

sample_data<-rbind(rsf.large.scale,rsf_tyler)
write.csv(sample_data,"C:\\Work\\caribou\\clus\\R\\range_scale_habitat_analysis\\data\\Range_scale_data.csv")
dim(sample_data)
names(sample_data)


#====================================
# Frequency plot of distance to cutblock by point type
#===================================
setwd("C:\\Work\\caribou\\clus_data\\disturbance\\Cutblock_figures")

for (i in 1:50){
   # cutblock_mean<- sample_data %>%
   #   group_by(du, pttype) %>%
   #   summarise(median_dist=(median(get(paste("distance_to_cut_",i,"yo",sep="")))))
  # 
  # P<-ggplot(sample_data, aes(x = get(paste("distance_to_cut_",i,"yo",sep="")))) + 
  # theme_bw() +
  # theme(text = element_text(size=14))+
  # geom_histogram(bins=50) +
  # facet_grid(pttype~.) +
  # labs(y="Frequency", x="Distance to cutblocks (m)")+
  #   ggtitle(paste("Distance to cut in year", i))+
  # geom_vline(data=cutblock_mean, aes(xintercept=median_dist))

  
  plot2 <- ggplot(sample_data, aes(x = get(paste("distance_to_cut_",i,"yo",sep="")),fill=as.factor(pttype))) +
    theme_bw() +
    geom_density(position="identity",alpha=0.6) +
    facet_grid(du~.) +
    scale_fill_brewer(palette="Accent")+
    scale_x_continuous(name="Distance to cutblocks (m)",limits=c(0, 300000)) +
    scale_y_continuous(name = "Density") + 
    ggtitle(paste("Distance to cut in year", i))
   # geom_vline(xintercept=cutblock_mean$median_dist, size=1,colour="black",linetype="dashed")

#nam<-paste("dist_to_cut",i,"pdf",sep=".")
nam2<-paste("density.plot.year",i,"jpeg",sep=".")
#assign(nam,P)
assign(nam2,plot2)

ggsave(nam2)
}


table.diff.dist <- data.frame (matrix (ncol = 5, nrow = 0))
colnames (table.diff.dist) <- c ("cutblock_age", "du6","du7","du8","du9")
sample_data$count<-1

for (i in 1:50){

cutblock_mean<- sample_data %>%
     group_by(du,pttype) %>%
     summarise(mean_dist=(mean(get(paste("distance_to_cut_",i,"yo",sep="")))),
               sd_dist=sd(get(paste("distance_to_cut_",i,"yo",sep=""))),
               n_dist = sum(count),
               se_dist=sd_dist/sqrt(n_dist))

diff_dist_du6<-cutblock_mean$median_dist[which(cutblock_mean$pttype==1 & cutblock_mean$du=="du6")]-cutblock_mean$median_dist[which(cutblock_mean$pttype==0 & cutblock_mean$du=="du6")]
diff_dist_du7<-cutblock_mean$median_dist[which(cutblock_mean$pttype==1 & cutblock_mean$du=="du7")]-cutblock_mean$median_dist[which(cutblock_mean$pttype==0 & cutblock_mean$du=="du7")]
diff_dist_du8<-cutblock_mean$median_dist[which(cutblock_mean$pttype==1 & cutblock_mean$du=="du8")]-cutblock_mean$median_dist[which(cutblock_mean$pttype==0 & cutblock_mean$du=="du8")]
diff_dist_du9<-cutblock_mean$median_dist[which(cutblock_mean$pttype==1 & cutblock_mean$du=="du9")]-cutblock_mean$median_dist[which(cutblock_mean$pttype==0 & cutblock_mean$du=="du9")]

table.diff.dist [i, 1] <- i
table.diff.dist [i, 2] <- diff_dist_du6
table.diff.dist [i, 3] <- diff_dist_du7
table.diff.dist [i, 4] <- diff_dist_du8
table.diff.dist [i, 5] <- diff_dist_du9

}

table.diff.dist<-as.data.frame(table.diff.dist)
diff_dist<- table.diff.dist %>% gather("du6","du7","du8","du9", key=du, value = diff_dist_m)

ggplot(diff_dist, aes(cutblock_age, diff_dist_m)) + 
  geom_point() +
  facet_grid(du~.) 

#====================================
# GLMs, by year
#===================================

# summary table
table.glm.summary <- data.frame (matrix (ncol = 4, nrow = 0))
colnames (table.glm.summary) <- c ("Years_Old", "Coefficient", "AIC", "p-values")


# analysis for all data together
for (i in 1:50) {
  
  
var1<-paste("distance_to_cut_",i,"yo",sep="")

m1<-glm(pttype ~ get(var1), 
        data=sample_data,
        family=binomial(link="logit"))

table.glm.summary[i,1]<-i
table.glm.summary [i, 2] <- m1$coefficients [[2]]
table.glm.summary [i, 3] <- m1$aic
table.glm.summary [i, 4] <- scientific(summary(m1)$coefficients[2,4],digits=3) # p-value
}

ggplot (table.glm.summary, aes (Years_Old, Coefficient)) +
  geom_line()+
  ggtitle ("Beta coefficient values of distance to cutblock \n by year and season for caribou") +
  xlab ("Years since harvest") + 
  ylab ("Beta coefficient") +
  geom_line (aes (x = Years_Old, y = 0), 
             size = 0.5, linetype = "solid", colour = "black") 

#analysis per du
#------
# du6
#------
table.glm.summary.du6 <- data.frame (matrix (ncol = 5, nrow = 0))
colnames (table.glm.summary.du6) <- c ("du","Years_Old", "Coefficient","AIC", "p-values")
du6_dat<-sample_data %>% filter(du=="du6")

for (i in 1:50) {
  
  var1<-paste("distance_to_cut_",i,"yo",sep="")
  
  m1<-glm(pttype ~ get(var1), 
          data=du6_dat,
          family=binomial(link="logit"))
  
  table.glm.summary.du6[i,1]<-"du6"
  table.glm.summary.du6[i,2]<-i
  table.glm.summary.du6 [i, 3] <- m1$coefficients [[2]]
  table.glm.summary.du6 [i, 4] <- m1$aic
  table.glm.summary.du6 [i, 5] <- scientific(summary(m1)$coefficients[2,4],digits=3) # p-value
}

table.glm.summary.du6$DeltaAIC<- table.glm.summary.du6$AIC - min(table.glm.summary.du6$AIC)

fig_du6<-ggplot (table.glm.summary.du6, aes (Years_Old, Coefficient)) +
  geom_line()+
  ggtitle ("Beta coefficient values of distance to cutblock \n by year and season for caribou in du6") +
  xlab ("Years since harvest") + 
  ylab ("Beta coefficient") +
  geom_line (aes (x = Years_Old, y = 0), 
             size = 0.5, linetype = "solid", colour = "black") 

fig_du6_aic<-ggplot (table.glm.summary.du6, aes (Years_Old, DeltaAIC)) +
  geom_line()+
  ggtitle ("AIC values of distance to cutblock \n by year and season for caribou in du6") +
  xlab ("Years since harvest") + 
  ylab ("Beta coefficient") +
  geom_line (aes (x = Years_Old, y = 0), 
             size = 0.5, linetype = "solid", colour = "black") 

#-----
#du7
#-----
table.glm.summary.du7 <- data.frame (matrix (ncol = 5, nrow = 0))
colnames (table.glm.summary.du7) <-  c ("du","Years_Old", "Coefficient","AIC", "p-values")
du7_dat<-sample_data %>% filter(du=="du7")

for (i in 1:50) {
  
  var1<-paste("distance_to_cut_",i,"yo",sep="")
  
  m1<-glm(pttype ~ get(var1), 
          data=du7_dat,
          family=binomial(link="logit"))
  
  table.glm.summary.du7[i,1]<-"du7"
  table.glm.summary.du7[i,2]<-i
  table.glm.summary.du7 [i, 3] <- m1$coefficients [[2]]
  table.glm.summary.du7 [i, 4] <- m1$aic
  table.glm.summary.du7 [i, 5] <- scientific(summary(m1)$coefficients[2,4],digits=3) # p-value
}

dif_du7<-ggplot (table.glm.summary.du7, aes (Years_Old, Coefficient)) +
  geom_line()+
  ggtitle ("Beta coefficient values of distance to cutblock \n by year and season for caribou in du7") +
  xlab ("Years since harvest") + 
  ylab ("Beta coefficient") +
  geom_line (aes (x = Years_Old, y = 0), 
             size = 0.5, linetype = "solid", colour = "black") 

#------
# du8
#------
table.glm.summary.du8 <- data.frame (matrix (ncol = 5, nrow = 0))
colnames (table.glm.summary.du8) <- c ("du","Years_Old", "Coefficient","AIC", "p-values")
du8_dat<-sample_data %>% filter(du=="du8")

for (i in 1:50) {
  
  var1<-paste("distance_to_cut_",i,"yo",sep="")
  
  m1<-glm(pttype ~ get(var1), 
          data=du8_dat,
          family=binomial(link="logit"))
  
  table.glm.summary.du8[i,1]<-"du8"
  table.glm.summary.du8[i,2]<-i
  table.glm.summary.du8 [i, 3] <- m1$coefficients [[2]]
  table.glm.summary.du8 [i, 4] <- m1$aic
  table.glm.summary.du8 [i, 5] <- scientific(summary(m1)$coefficients[2,4],digits=3) # p-value
}

ggplot (table.glm.summary.du8, aes (Years_Old, Coefficient)) +
  geom_line()+
  ggtitle ("Beta coefficient values of distance to cutblock \n by year and season for caribou in du8") +
  xlab ("Years since harvest") + 
  ylab ("Beta coefficient") +
  geom_line (aes (x = Years_Old, y = 0), 
             size = 0.5, linetype = "solid", colour = "black") 

#------
# du9
#------
table.glm.summary.du9 <- data.frame (matrix (ncol = 5, nrow = 0))
colnames (table.glm.summary.du9) <-  c ("du","Years_Old", "Coefficient","AIC", "p-values")
du9_dat<-sample_data %>% filter(du=="du9")

for (i in 1:50) {
  
  var1<-paste("distance_to_cut_",i,"yo",sep="")
  
  m1<-glm(pttype ~ get(var1), 
          data=du9_dat,
          family=binomial(link="logit"))
  
  table.glm.summary.du9[i,1]<-"du9"
  table.glm.summary.du9[i,2]<-i
  table.glm.summary.du9 [i, 3] <- m1$coefficients [[2]]
  table.glm.summary.du9 [i, 4] <- m1$aic
  table.glm.summary.du9 [i, 5] <- scientific(summary(m1)$coefficients[2,4],digits=3) # p-value
}

ggplot (table.glm.summary.du9, aes (Years_Old, Coefficient)) +
  geom_line()+
  ggtitle ("Beta coefficient values of distance to cutblock \n by year and season for caribou in du9") +
  xlab ("Years since harvest") + 
  ylab ("Beta coefficient") +
  geom_line (aes (x = Years_Old, y = 0), 
             size = 0.5, linetype = "solid", colour = "black") 





#=======================================================================
# re-categorize forestry data and test correlations, beta coeffs again
#=====================================================================


head(sample_data)

# binning the data into groups that are less correlated
sample_data <- dplyr::mutate (sample_data, distance_to_cut_1to7yo = pmin (distance_to_cut_1yo, distance_to_cut_2yo, distance_to_cut_3yo, distance_to_cut_4yo, distance_to_cut_5yo, distance_to_cut_6yo, distance_to_cut_7yo))

sample_data <- dplyr::mutate (sample_data, distance_to_cut_8to14yo = pmin (distance_to_cut_8yo, distance_to_cut_9yo, distance_to_cut_10yo, distance_to_cut_11yo, distance_to_cut_12yo, distance_to_cut_13yo, distance_to_cut_14yo))

sample_data <- dplyr::mutate (sample_data, distance_to_cut_15to20yo = pmin (distance_to_cut_15yo, distance_to_cut_16yo, distance_to_cut_17yo, distance_to_cut_18yo, distance_to_cut_19yo, distance_to_cut_20yo))

sample_data <- dplyr::mutate (sample_data, distance_to_cut_21to37 = pmin (distance_to_cut_21yo, distance_to_cut_22yo, distance_to_cut_23yo, distance_to_cut_24yo, distance_to_cut_25yo, distance_to_cut_26yo, distance_to_cut_27yo, distance_to_cut_28yo, distance_to_cut_2yo, distance_to_cut_30yo, distance_to_cut_31yo, distance_to_cut_32yo, distance_to_cut_33yo, distance_to_cut_34yo, distance_to_cut_35yo, distance_to_cut_36yo, distance_to_cut_37yo))

sample_data <- dplyr::mutate (sample_data, distance_to_cut_38to50 = pmin (distance_to_cut_38yo, distance_to_cut_39yo, distance_to_cut_40yo, distance_to_cut_41yo, distance_to_cut_42yo, distance_to_cut_43yo, distance_to_cut_44yo, distance_to_cut_45yo, distance_to_cut_46yo, distance_to_cut_47yo, distance_to_cut_48yo, distance_to_cut_49yo, distance_to_cut_50yo))



setwd('C:\\Work\\caribou\\clus_data\\disturbance\\')
write.csv (sample_data, file = "Range_Extension_points.csv")
names(sample_data)

# Correlations
dist.cut.corr <- (sample_data [c (56:60)])
corr <- round (cor (dist.cut.corr), 3)
p.mat <- round (cor_pmat (dist.cut.corr), 2)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Distance to Cutblock Correlation")
# ggcorrplot (corr, type = "lower", p.mat = p.mat, insig = "blank")

dist.cut.corr_1_to_15 <- (sample_data [c (6:20)])
corr <- round (cor (dist.cut.corr_1_to_15), 3)
p.mat <- round (cor_pmat (dist.cut.corr_1_to_15), 2)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Distance to Cutblock Correlation")

dist.cut.corr_16_to_35 <- (sample_data [c (21:40)])
corr <- round (cor (dist.cut.corr_16_to_35), 3)
p.mat <- round (cor_pmat (dist.cut.corr_16_to_35), 2)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Distance to Cutblock Correlation")

dist.cut.corr_36_to_50 <- (sample_data [c (41:55)])
corr <- round (cor (dist.cut.corr_36_to_50), 3)
p.mat <- round (cor_pmat (dist.cut.corr_36_to_50), 2)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Distance to Cutblock Correlation")




#=================================================
# Model selection Process by DU and Season 
#================================================


# load data
#rsf.data.cut.age <- read.csv ("C:\\Work\\caribou\\clus_data\\rsf_data_cutblock_age2.csv")
dist.cut.data <- (sample_data [c (1,4,5,56:60)]) # cutblock age class data only

dist.cut.data2 <- dist.cut.data %>%
  mutate(pttype = factor(pttype, levels = c(0,1)),
         HERD_NAME=factor(HERD_NAME),
         du=factor(du)) %>%
  na.omit()
glimpse(dist.cut.data2)

# filter by DU, Season 
dist.cut.data.du.6 <- dist.cut.data2 %>%
  dplyr::filter (du == "du6") 

dist.cut.data.du.7 <- dist.cut.data2 %>%
  dplyr::filter (du == "du7") 

dist.cut.data.du.8 <- dist.cut.data2 %>%
  dplyr::filter (du == "du8") 

dist.cut.data.du.9 <- dist.cut.data2 %>%
  dplyr::filter (du == "du9") 

#================================
# GLMs
#================================
## Build an AIC and AUC Table
table.aic <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.aic) <- c ("DU", "Model Type", "Fixed Effects Covariates", "Random Effects Covariates", "AIC", "AICw", "AUC")

#===============
## DU6 ##
#==============

### CART
library(rpart.plot)
library(rattle)
cart.du.6 <- rpart(pttype ~ distance_to_cut_1to7yo + 
                      distance_to_cut_8to14yo + 
                         distance_to_cut_15to20yo + 
                      distance_to_cut_21to37 + 
                      distance_to_cut_38to50,
                       data = dist.cut.data.du.6,
                   method="class")
summary (cart.du.6)
print (cart.du.6)
fancyRpartPlot (cart.du.6)
text (cart.du.6, use.n = T, splits = T, fancy = F)
post (cart.du.6, file = "", uniform = T)
# results indicate no partioning, suggesting no effect of cutblocks

### VIF
model.glm.du6 <- glm (pttype ~ distance_to_cut_1to7yo + 
                        distance_to_cut_8to14yo + 
                        distance_to_cut_15to20yo + 
                        distance_to_cut_21to37 + 
                        distance_to_cut_38to50, 
                         data = dist.cut.data.du.6,
                         family = binomial (link = 'logit'))
vif (model.glm.du6) 


# Generalized Linear Mixed Models (GLMMs)
# standardize covariates  (helps with model convergence)

dist.cut.data.du.6$std.distance_to_cut_1to7yo<-scale(dist.cut.data.du.6$distance_to_cut_1to7yo, center=TRUE, scale=TRUE)
dist.cut.data.du.6$std.distance_to_cut_8to14yo<-scale(dist.cut.data.du.6$distance_to_cut_8to14yo, center=TRUE, scale=TRUE)
dist.cut.data.du.6$std.distance_to_cut_15to20yo<-scale(dist.cut.data.du.6$distance_to_cut_15to20yo, center=TRUE, scale=TRUE)
dist.cut.data.du.6$std.distance_to_cut_21to37yo<-scale(dist.cut.data.du.6$distance_to_cut_21to37, center=TRUE, scale=TRUE)
dist.cut.data.du.6$std.distance_to_cut_38to50yo<-scale(dist.cut.data.du.6$distance_to_cut_38to50, center=TRUE, scale=TRUE)


### fit corr random effects models
# ALL COVARS
model.lme.du6 <- glmer (pttype ~ std.distance_to_cut_1to7yo + 
                             std.distance_to_cut_8to14yo + 
                             std.distance_to_cut_15to20yo + 
                             std.distance_to_cut_21to37yo +
                             std.distance_to_cut_38to50yo +
                             (std.distance_to_cut_1to7yo | HERD_NAME) + 
                             (std.distance_to_cut_8to14yo | HERD_NAME) +
                             (std.distance_to_cut_15to20yo | HERD_NAME) +
                             (std.distance_to_cut_21to37yo | HERD_NAME) +
                             (std.distance_to_cut_38to50yo | HERD_NAME), 
                           data = dist.cut.data.du.6, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                   optimizer = "nloptwrap", # these settings should provide results quicker
                                                   optCtrl = list (maxfun = 2e5))) # 20,000 iterations)
summary (model.lme.du6)
anova (model.lme.du6)
plot (model.lme.du6) # should be mostly a straight line

dist.cut.data.du.6$preds.lme.re <- predict (model.lme.du6, type = 'response') 
dist.cut.data.du.6$preds.lme.re.fe <- predict (model.lme.du6, type = 'response', 
                                                  re.form = NA,
                                                  newdata = dist.cut.data.du.6) 
plot (dist.cut.data.du.6$std.distance_to_cut_1to7yo, dist.cut.data.du.6$preds.lme.re.fe) # fixed effect predictions against covariate value
plot (dist.cut.data.du.6$std.distance_to_cut_8to14yo, dist.cut.data.du.6$preds.lme.re.fe) 
plot (dist.cut.data.du.6$std.distance_to_cut_15to20yo, dist.cut.data.du.6$preds.lme.re.fe) 
plot (dist.cut.data.du.6$std.distance_to_cut_21to37yo, dist.cut.data.du.6$preds.lme.re.fe) 

save (model.lme.du6, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_range_scale_model\\Rmodels\\model_lme_du6.rda")
# sjp.lmer (model.lme.du6.ew, type = "pred", vars = "std.distance_to_cut_1to4yo")
# AIC
table.aic [1, 1] <- "DU6"
table.aic [1, 2] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [1, 3] <- "DC1to7, DC8to14,DC15to20, DC21to37, DC38to50"
table.aic [1, 4] <- "(DC1to7 | herd.name), (DC8to14 | herd.name), (DC15to20 | herd.name), (DC21to37 | herd.name), (DC38to50 | herd.name)"
table.aic [1, 5] <- AIC (model.lme.du6)

# AUC 
pr.temp <- prediction (predict (model.lme.du6, type = 'response'), dist.cut.data.du.6$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [1, 7] <- auc.temp@y.values[[1]]



#=======================================
# Individual fixed effects model
#=======================================
var.list<-c("std.distance_to_cut_1to7yo", "std.distance_to_cut_8to14yo", "std.distance_to_cut_15to20yo", "std.distance_to_cut_21to37yo" , "std.distance_to_cut_38to50yo")
name<-c("DC1to7","DC8to14","DC15to20","DC21to37","DC38to50")

for(i in 1:length(var.list)){
model.du6 <- glmer (pttype ~ get(var.list[i]) + 
                                (get(var.list[i]) | HERD_NAME), 
                              data = dist.cut.data.du.6, 
                              family = binomial (link = "logit"),
                              verbose = T,
                              control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                      optimizer = "nloptwrap", # these settings should provide results quicker
                                                      optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [i+1, 1] <- "DU6"
table.aic [i+1, 2] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [i+1, 3] <- name[i]
table.aic [i+1, 4] <- paste(name[i],"herd.name",sep="|")
table.aic [i+1, 5] <- AIC (model.du6)

# AUC 
pr.temp <- prediction (predict (model.du6, type = 'response'), dist.cut.data.du.6$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [i+1, 7] <- auc.temp@y.values[[1]]

}

#=======================================
# Two variables fixed effects model
#=======================================
var.list<-c("std.distance_to_cut_1to7yo", "std.distance_to_cut_8to14yo", "std.distance_to_cut_15to20yo", "std.distance_to_cut_21to37yo" , "std.distance_to_cut_38to50yo")
name<-c("DC1to7","DC8to14","DC15to20","DC21to37","DC38to50")

for(i in 1:length(var.list)){
  for(j in 1:length(var.list)){
    if (i<j){
      
      model.du6 <- glmer (pttype ~ get(var.list[i]) + 
                            get(var.list[j]) +
                          (get(var.list[i]) | HERD_NAME) +
                            (get(var.list[j]) | HERD_NAME), 
                          data = dist.cut.data.du.6, 
                          family = binomial (link = "logit"),
                          verbose = T,
                          control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                  optimizer = "nloptwrap", # these settings should provide results quicker
                                                  optCtrl = list (maxfun = 2e5))) 
      # AIC
      if (i==1) {
        num = 7-2
        table.aic [num +j, 1] <- "DU6"
        table.aic [num +j, 2] <- "GLMM with Individual and Year (UniqueID) Random Effect"
        table.aic [num +j, 3] <- paste(name[i],name[j])
        table.aic [num +j, 4] <- paste(name[i],"|herd.name",", ",name[j],"|herd.name",sep="")
        table.aic [num +j, 5] <- AIC (model.du6)
        
        # AUC 
        pr.temp <- prediction (predict (model.du6, type = 'response'), dist.cut.data.du.6$pttype)
        prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
        plot (prf.temp)
        auc.temp <- performance (pr.temp, measure = "auc")
        table.aic [num +j, 7] <- auc.temp@y.values[[1]]
      
      } else { 
        if (i==2) {
        num=11-3
        table.aic [num +j, 1] <- "DU6"
        table.aic [num +j, 2] <- "GLMM with Individual and Year (UniqueID) Random Effect"
        table.aic [num +j, 3] <- paste(name[i],name[j])
        table.aic [num +j, 4] <- paste(name[i],"|herd.name",", ",name[j],"|herd.name",sep="")
        table.aic [num +j, 5] <- AIC (model.du6)
        
        # AUC 
        pr.temp <- prediction (predict (model.du6, type = 'response'), dist.cut.data.du.6$pttype)
        prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
        plot (prf.temp)
        auc.temp <- performance (pr.temp, measure = "auc")
        table.aic [num+j, 7] <- auc.temp@y.values[[1]]
      
      } else { 
        if (i==3){
        num = 14-4
      table.aic [num +j, 1] <- "DU6"
      table.aic [num +j, 2] <- "GLMM with Individual and Year (UniqueID) Random Effect"
      table.aic [num +j, 3] <- paste(name[i],name[j])
      table.aic [num +j, 4] <- paste(name[i],"|herd.name",", ",name[j],"|herd.name",sep="")
      table.aic [num +j, 5] <- AIC (model.du6)
      
      # AUC 
      pr.temp <- prediction (predict (model.du6, type = 'response'), dist.cut.data.du.6$pttype)
      prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
      plot (prf.temp)
      auc.temp <- performance (pr.temp, measure = "auc")
      table.aic [num+j, 7] <- auc.temp@y.values[[1]]
      
      } else {
        num = 16-5
        table.aic [num +j, 1] <- "DU6"
        table.aic [num +j, 2] <- "GLMM with Individual and Year (UniqueID) Random Effect"
        table.aic [num +j, 3] <- paste(name[i],name[j])
        table.aic [num +j, 4] <- paste(name[i],"|herd.name",", ",name[j],"|herd.name",sep="")
        table.aic [num +j, 5] <- AIC (model.du6)
        
        # AUC 
        pr.temp <- prediction (predict (model.du6, type = 'response'), dist.cut.data.du.6$pttype)
        prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
        plot (prf.temp)
        auc.temp <- performance (pr.temp, measure = "auc")
        table.aic [num +j, 7] <- auc.temp@y.values[[1]]
      }
      }
      }
    }
  }
}


#=======================================
# Three variables fixed effects model
#=======================================
var.list<-c("std.distance_to_cut_1to7yo", "std.distance_to_cut_8to14yo", "std.distance_to_cut_15to20yo", "std.distance_to_cut_21to37yo" , "std.distance_to_cut_38to50yo")
name<-c("DC1to7","DC8to14","DC15to20","DC21to37","DC38to50")

for(i in 1:length(var.list)){
  for(j in 1:length(var.list)){
    for(k in 1:length(var.list)){
    if (i<j){
      if (j<k){
      
      model.du6 <- glmer (pttype ~ get(var.list[i]) + 
                            get(var.list[j]) +
                            get(var.list[k]) +
                            (get(var.list[i]) | HERD_NAME) +
                            (get(var.list[j]) | HERD_NAME)
                            (get(var.list[k]) | HERD_NAME), 
                          data = dist.cut.data.du.6, 
                          family = binomial (link = "logit"),
                          verbose = T,
                          control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                  optimizer = "nloptwrap", # these settings should provide results quicker
                                                  optCtrl = list (maxfun = 2e5))) 
      # AIC
      table.aic [i+, 1] <- "DU6"
      table.aic [i+, 2] <- "GLMM with Individual and Year (UniqueID) Random Effect"
      table.aic [i+, 3] <- paste(name[i],name[j],name[k])
      table.aic [i+, 4] <- paste(name[i],"|herd.name",", ",name[j],"|herd.name",", ",name[k],"|herd.name",sep="")
      table.aic [i+, 5] <- AIC (model.du6)
      
      # AUC 
      pr.temp <- prediction (predict (model.du6, type = 'response'), dist.cut.data.du.6$pttype)
      prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
      plot (prf.temp)
      auc.temp <- performance (pr.temp, measure = "auc")
      table.aic [i+, 7] <- auc.temp@y.values[[1]]
      }
    }
      
    }
  }
}








### Fit model with functional responses
# Calculating dataframe with covariate expectations
sub <- subset (dist.cut.data.du.6.ew, pttype == 0)
std.distance_to_cut_1to4yo_E <- tapply (sub$std.distance_to_cut_1to4yo, sub$uniqueID, mean)
std.distance_to_cut_5to9yo_E <- tapply (sub$std.distance_to_cut_5to9yo, sub$uniqueID, mean)
std.distance_to_cut_10yoorOver_E <- tapply (sub$std.distance_to_cut_10yoorOver, sub$uniqueID, mean)
inds <- as.character (dist.cut.data.du.6.ew$uniqueID)
dist.cut.data.du.6.ew <- cbind (dist.cut.data.du.6.ew, 
                                "std.distance_to_cut_1to4yo_E" = std.distance_to_cut_1to4yo_E [inds],
                                "std.distance_to_cut_5to9yo_E" = std.distance_to_cut_5to9yo_E [inds],
                                "std.distance_to_cut_10yoorOver_E" = std.distance_to_cut_10yoorOver_E [inds])

# ALL COVARS
model.lme.fxn.du6.ew <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                                 std.distance_to_cut_10yoorOver + std.distance_to_cut_1to4yo_E +
                                 std.distance_to_cut_5to9yo_E + std.distance_to_cut_10yoorOver_E +
                                 std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                 std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                 std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                 (1 | uniqueID), 
                               data = dist.cut.data.du.6.ew, 
                               family = binomial (link = "logit"),
                               verbose = T,
                               control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                       optimizer = "nloptwrap", # these settings should provide results quicker
                                                       optCtrl = list (maxfun = 2e5)))
summary (model.lme.fxn.du6.ew)
anova (model.lme.fxn.du6.ew)
plot (model.lme.fxn.du6.ew) # should be mostly a straight line

dist.cut.data.du.6.ew$preds.lme.re.fxn <- predict (model.lme.fxn.du6.ew, type = 'response') 
dist.cut.data.du.6.ew$preds.lme.re.fe.fxn <- predict (model.lme.fxn.du6.ew, type = 'response', 
                                                      re.form = NA,
                                                      newdata = dist.cut.data.du.6.ew) 
plot (dist.cut.data.du.6.ew$distance_to_cut_1to4yo, dist.cut.data.du.6.ew$preds.lme.re.fe.fxn) # fixed effect predictions against covariate value
plot (dist.cut.data.du.6.ew$std.distance_to_cut_5to9yo, dist.cut.data.du.6.ew$preds.lme.re.fe.fxn) 
plot (dist.cut.data.du.6.ew$std.distance_to_cut_10yoorOver, dist.cut.data.du.6.ew$preds.lme.re.fe.fxn) 
save (model.lme.du6.ew, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_lme_fxn_du6_ew.rda")
# sjp.lmer (model.lme.du6.ew, type = "pred", vars = "std.distance_to_cut_1to4yo")
# AIC
table.aic [8, 1] <- "DU6"
table.aic [8, 2] <- "Early Winter"
table.aic [8, 3] <- "GLMM with Functional Response"
table.aic [8, 4] <- "DC1to4, DC5to9, DCover9, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DCover9"
table.aic [8, 5] <- "(1 | UniqueID)"
table.aic [8, 6] <- AIC (model.lme.fxn.du6.ew)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [8, 8] <- auc.temp@y.values[[1]]

# Age 1to4
model.lme.fxn.du6.ew.1to4 <- glmer (pttype ~ std.distance_to_cut_1to4yo +
                                      std.distance_to_cut_1to4yo_E +
                                      std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                      (1 | uniqueID), 
                                    data = dist.cut.data.du.6.ew, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                            optimizer = "nloptwrap", # these settings should provide results quicker
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [9, 1] <- "DU6"
table.aic [9, 2] <- "Early Winter"
table.aic [9, 3] <- "GLMM with Functional Response"
table.aic [9, 4] <- "DC1to4, A_DC1to4, DC1to4*A_DC1to4"
table.aic [9, 5] <- "(1 | UniqueID)"
table.aic [9, 6] <- AIC (model.lme.fxn.du6.ew.1to4)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.ew.14over9, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [9, 8] <- auc.temp@y.values[[1]]

# Age 5to9
model.lme.fxn.du6.ew.59 <- glmer (pttype ~ std.distance_to_cut_5to9yo +
                                    std.distance_to_cut_5to9yo_E +
                                    std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                    (1 | uniqueID), 
                                  data = dist.cut.data.du.6.ew, 
                                  family = binomial (link = "logit"),
                                  verbose = T,
                                  control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                          optimizer = "nloptwrap", # these settings should provide results quicker
                                                          optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [10, 1] <- "DU6"
table.aic [10, 2] <- "Early Winter"
table.aic [10, 3] <- "GLMM with Functional Response"
table.aic [10, 4] <- "DC5to9, A_DC5to9, DC5to9*A_DC5to9"
table.aic [10, 5] <- "(1 | UniqueID)"
table.aic [10, 6] <- AIC (model.lme.fxn.du6.ew.59)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.59, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [10, 8] <- auc.temp@y.values[[1]]

# Age over9
model.lme.fxn.du6.ew.over9 <- glmer (pttype ~ std.distance_to_cut_10yoorOver +
                                       std.distance_to_cut_10yoorOver_E +
                                       std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                       (1 | uniqueID), 
                                     data = dist.cut.data.du.6.ew, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                             optimizer = "nloptwrap", # these settings should provide results quicker
                                                             optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [11, 1] <- "DU6"
table.aic [11, 2] <- "Early Winter"
table.aic [11, 3] <- "GLMM with Functional Response"
table.aic [11, 4] <- "DCover9, A_DCover9, DCover9*A_DCover9"
table.aic [11, 5] <- "(1 | UniqueID)"
table.aic [11, 6] <- AIC (model.lme.fxn.du6.ew.over9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.59, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [11, 8] <- auc.temp@y.values[[1]]

# Age 1to4, 5to9
model.lme.fxn.du6.ew.1459 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                      std.distance_to_cut_5to9yo +
                                      std.distance_to_cut_1to4yo_E +
                                      std.distance_to_cut_5to9yo_E +
                                      std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                      std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                      (1 | uniqueID), 
                                    data = dist.cut.data.du.6.ew, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                            optimizer = "nloptwrap", # these settings should provide results quicker
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [12, 1] <- "DU6"
table.aic [12, 2] <- "Early Winter"
table.aic [12, 3] <- "GLMM with Functional Response"
table.aic [12, 4] <- "DC1to4, DC5to9, A_DC1to4, A_DC5to9, DC1to4*A_DC1to4, DC5to9*A_DC5to9"
table.aic [12, 5] <- "(1 | UniqueID)"
table.aic [12, 6] <- AIC (model.lme.fxn.du6.ew.1459)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.1459, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [12, 8] <- auc.temp@y.values[[1]]

# Age 1to4, over9
model.lme.fxn.du6.ew.14over9 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                         std.distance_to_cut_10yoorOver +
                                         std.distance_to_cut_1to4yo_E +
                                         std.distance_to_cut_10yoorOver_E +
                                         std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                         std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                         (1 | uniqueID), 
                                       data = dist.cut.data.du.6.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T,
                                       control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                               optimizer = "nloptwrap", # these settings should provide results quicker
                                                               optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [13, 1] <- "DU6"
table.aic [13, 2] <- "Early Winter"
table.aic [13, 3] <- "GLMM with Functional Response"
table.aic [13, 4] <- "DC1to4, DCover9, A_DC1to4, A_DCover9, DC1to4*A_DC1to4, DCover9*A_DCover9"
table.aic [13, 5] <- "(1 | UniqueID)"
table.aic [13, 6] <- AIC (model.lme.fxn.du6.ew.14over9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.14over9, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [13, 8] <- auc.temp@y.values[[1]]

# Age 5to9, over9
model.lme.fxn.du6.ew.59over9 <- glmer (pttype ~ std.distance_to_cut_5to9yo  + 
                                         std.distance_to_cut_10yoorOver +
                                         std.distance_to_cut_5to9yo_E +
                                         std.distance_to_cut_10yoorOver_E +
                                         std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                         std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                         (1 | uniqueID), 
                                       data = dist.cut.data.du.6.ew, 
                                       family = binomial (link = "logit"),
                                       verbose = T,
                                       control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                               optimizer = "nloptwrap", # these settings should provide results quicker
                                                               optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [14, 1] <- "DU6"
table.aic [14, 2] <- "Early Winter"
table.aic [14, 3] <- "GLMM with Functional Response"
table.aic [14, 4] <- "DC5to9, DCover9, A_DC5to9, A_DCover9, DC5to9*A_DC5to9, DCover9*A_DCover9"
table.aic [14, 5] <- "(1 | UniqueID)"
table.aic [14, 6] <- AIC (model.lme.fxn.du6.ew.59over9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.ew.59over9, type = 'response'), dist.cut.data.du.6.ew$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [14, 8] <- auc.temp@y.values[[1]]

# AIC comparison DU6 early winter
list.aic.like <- c ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:14, 6])))), 
                    (exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [4, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [5, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [6, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [7, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [8, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [9, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [10, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [11, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [12, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [13, 6] - min (table.aic [1:14, 6])))),
                    (exp (-0.5 * (table.aic [14, 6] - min (table.aic [1:14, 6])))))
table.aic [1, 7] <- round ((exp (-0.5 * (table.aic [1, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [2, 7] <- round ((exp (-0.5 * (table.aic [2, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [3, 7] <- round ((exp (-0.5 * (table.aic [3, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [4, 7] <- round ((exp (-0.5 * (table.aic [4, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [5, 7] <- round ((exp (-0.5 * (table.aic [5, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [6, 7] <- round ((exp (-0.5 * (table.aic [6, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [7, 7] <- round ((exp (-0.5 * (table.aic [7, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [8, 7] <- round ((exp (-0.5 * (table.aic [8, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [9, 7] <- round ((exp (-0.5 * (table.aic [9, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [10, 7] <- round ((exp (-0.5 * (table.aic [10, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [11, 7] <- round ((exp (-0.5 * (table.aic [11, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [12, 7] <- round ((exp (-0.5 * (table.aic [12, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [13, 7] <- round ((exp (-0.5 * (table.aic [13, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)
table.aic [14, 7] <- round ((exp (-0.5 * (table.aic [14, 6] - min (table.aic [1:14, 6])))) / sum (list.aic.like), 3)

# save the top model
save (model.lme.du6.ew.59over9, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_lme_du6_ew_top.rda")

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_forestry.csv", sep = ",")

#============================================
## Late Winter ##
### Corrletion
corr.dist.cut.du.6.lw <- round (cor (dist.cut.data.du.6.lw [10:13], method = "spearman"), 3)
ggcorrplot (corr.dist.cut.du.6.lw, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Distance to Cutblock Correlation DU6 Late Winter")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_dist_cut_corr_du_6_lw.png")

# distance to cutblocks 10 to 29 years old and 30 or over years old were highly correlated
# grouped together
dist.cut.data.du.6.lw <- dplyr::mutate (dist.cut.data.du.6.lw, distance_to_cut_10yoorOver = pmin (distance_to_cut_10to29yo, distance_to_cut_30orOveryo))

### CART
cart.du.6.lw <- rpart (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                         distance_to_cut_10yoorOver,
                       data = dist.cut.data.du.6.lw, 
                       method = "class")
summary (cart.du.6.lw)
print (cart.du.6.lw)
plot (cart.du.6.lw, uniform = T)
text (cart.du.6.lw, use.n = T, splits = T, fancy = F)
post (cart.du.6.lw, file = "", uniform = T)
# results indicate no partioning, suggesting no effect of cutblocks

### VIF
model.glm.du6.lw <- glm (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                           distance_to_cut_10yoorOver, 
                         data = dist.cut.data.du.6.lw,
                         family = binomial (link = 'logit'))
vif (model.glm.du6.lw) 

# Generalized Linear Mixed Models (GLMMs)
# standardize covariates  (helps with model convergence)
dist.cut.data.du.6.lw$std.distance_to_cut_1to4yo <- (dist.cut.data.du.6.lw$distance_to_cut_1to4yo - mean (dist.cut.data.du.6.lw$distance_to_cut_1to4yo)) / sd (dist.cut.data.du.6.lw$distance_to_cut_1to4yo)
dist.cut.data.du.6.lw$std.distance_to_cut_5to9yo <- (dist.cut.data.du.6.lw$distance_to_cut_5to9yo - mean (dist.cut.data.du.6.lw$distance_to_cut_5to9yo)) / sd (dist.cut.data.du.6.lw$distance_to_cut_5to9yo)
dist.cut.data.du.6.lw$std.distance_to_cut_10yoorOver <- (dist.cut.data.du.6.lw$distance_to_cut_10yoorOver - mean (dist.cut.data.du.6.lw$distance_to_cut_10yoorOver)) / sd (dist.cut.data.du.6.lw$distance_to_cut_10yoorOver)

### fit corr random effects model
model.lme.du6.lw <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                             std.distance_to_cut_10yoorOver + 
                             (std.distance_to_cut_1to4yo | uniqueID) + 
                             (std.distance_to_cut_5to9yo | uniqueID) +
                             (std.distance_to_cut_10yoorOver | uniqueID), 
                           data = dist.cut.data.du.6.lw, 
                           family = binomial (link = "logit"),
                           verbose = T,
                           control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                   optimizer = "nloptwrap", # these settings should provide results quicker
                                                   optCtrl = list (maxfun = 2e5))) # 20,000 iterations)
summary (model.lme.du6.lw)
anova (model.lme.du6.lw)
plot (model.lme.du6.lw) # should be mostly a straight line

dist.cut.data.du.6.lw$preds.lme.re <- predict (model.lme.du6.lw, type = 'response') 
dist.cut.data.du.6.lw$preds.lme.re.fe <- predict (model.lme.du6.lw, type = 'response', 
                                                  re.form = NA,
                                                  newdata = dist.cut.data.du.6.lw) 
plot (dist.cut.data.du.6.lw$distance_to_cut_1to4yo, dist.cut.data.du.6.lw$preds.lme.re.fe) # fixed effect predictions against covariate value
plot (dist.cut.data.du.6.lw$std.distance_to_cut_5to9yo, dist.cut.data.du.6.lw$preds.lme.re.fe) 
plot (dist.cut.data.du.6.lw$std.distance_to_cut_10yoorOver, dist.cut.data.du.6.lw$preds.lme.re.fe) 
# sjp.lmer (model.lme.du6.lw, type = "pred", vars = "std.distance_to_cut_1to4yo")
# AIC
table.aic [15, 1] <- "DU6"
table.aic [15, 2] <- "Late Winter"
table.aic [15, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [15, 4] <- "DC1to4, DC5to9, DCover9"
table.aic [15, 5] <- "(DC1to4 | UniqueID), (DC5to9 | UniqueID), (DCover9 | UniqueID)"
table.aic [15, 6] <- AIC (model.lme.du6.lw)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [15, 8] <- auc.temp@y.values[[1]]

# AGE 1to4
model.lme.du6.lw.14 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                (std.distance_to_cut_1to4yo | uniqueID), 
                              data = dist.cut.data.du.6.lw, 
                              family = binomial (link = "logit"),
                              verbose = T,
                              control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                      optimizer = "nloptwrap", # these settings should provide results quicker
                                                      optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [16, 1] <- "DU6"
table.aic [16, 2] <- "Late Winter"
table.aic [16, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [16, 4] <- "DC1to4"
table.aic [16, 5] <- "(DC1to4 | UniqueID)"
table.aic [16, 6] <- AIC (model.lme.du6.lw.14)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.14, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [16, 8] <- auc.temp@y.values[[1]]

# AGE 5to9
model.lme.du6.lw.59 <- glmer (pttype ~ std.distance_to_cut_5to9yo  + 
                                (std.distance_to_cut_5to9yo  | uniqueID), 
                              data = dist.cut.data.du.6.lw, 
                              family = binomial (link = "logit"),
                              verbose = T,
                              control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                      optimizer = "nloptwrap", # these settings should provide results quicker
                                                      optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [17, 1] <- "DU6"
table.aic [17, 2] <- "Late Winter"
table.aic [17, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [17, 4] <- "DC5to9"
table.aic [17, 5] <- "(DC5to9 | UniqueID)"
table.aic [17, 6] <- AIC (model.lme.du6.lw.59)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.59, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [17, 8] <- auc.temp@y.values[[1]]

# AGE over9
model.lme.du6.lw.over9 <- glmer (pttype ~ std.distance_to_cut_10yoorOver  + 
                                   (std.distance_to_cut_10yoorOver  | uniqueID), 
                                 data = dist.cut.data.du.6.lw, 
                                 family = binomial (link = "logit"),
                                 verbose = T,
                                 control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                         optimizer = "nloptwrap", # these settings should provide results quicker
                                                         optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [18, 1] <- "DU6"
table.aic [18, 2] <- "Late Winter"
table.aic [18, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [18, 4] <- "DCover9"
table.aic [18, 5] <- "(DCover9 | UniqueID)"
table.aic [18, 6] <- AIC (model.lme.du6.lw.over9)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.over9, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [18, 8] <- auc.temp@y.values[[1]]

# AGE 1to4, 5to9
model.lme.du6.lw.1459 <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                                  (std.distance_to_cut_1to4yo | uniqueID) +
                                  (std.distance_to_cut_5to9yo | uniqueID), 
                                data = dist.cut.data.du.6.lw, 
                                family = binomial (link = "logit"),
                                verbose = T,
                                control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                        optimizer = "nloptwrap", # these settings should provide results quicker
                                                        optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [19, 1] <- "DU6"
table.aic [19, 2] <- "Late Winter"
table.aic [19, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [19, 4] <- "DC1to4, DC5to9"
table.aic [19, 5] <- "(DC1to4 | UniqueID), (DC5to9 | UniqueID)"
table.aic [19, 6] <- AIC (model.lme.du6.lw.1459)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.over9, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [19, 8] <- auc.temp@y.values[[1]]

# AGE 1to4, over9
model.lme.du6.lw.14over9 <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_10yoorOver + 
                                     (std.distance_to_cut_1to4yo | uniqueID) +
                                     (std.distance_to_cut_10yoorOver | uniqueID), 
                                   data = dist.cut.data.du.6.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                           optimizer = "nloptwrap", # these settings should provide results quicker
                                                           optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [20, 1] <- "DU6"
table.aic [20, 2] <- "Late Winter"
table.aic [20, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [20, 4] <- "DC1to4, DCover9"
table.aic [20, 5] <- "(DC1to4 | UniqueID), (DCover9 | UniqueID)"
table.aic [20, 6] <- AIC (model.lme.du6.lw.14over9)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.14over9, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [20, 8] <- auc.temp@y.values[[1]]

# AGE 5to9, over9
model.lme.du6.lw.59over9 <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo  + 
                                     (std.distance_to_cut_1to4yo | uniqueID) +
                                     (std.distance_to_cut_5to9yo  | uniqueID), 
                                   data = dist.cut.data.du.6.lw, 
                                   family = binomial (link = "logit"),
                                   verbose = T,
                                   control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                           optimizer = "nloptwrap", # these settings should provide results quicker
                                                           optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [21, 1] <- "DU6"
table.aic [21, 2] <- "Late Winter"
table.aic [21, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [21, 4] <- "DC5to9, DCover9"
table.aic [21, 5] <- "(DC5to9 | UniqueID), (DCover9 | UniqueID)"
table.aic [21, 6] <- AIC (model.lme.du6.lw.59over9)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.lw.59over9, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [21, 8] <- auc.temp@y.values[[1]]

### Fit model with functional responses
# Calculating dataframe with covariate expectations
sub <- subset (dist.cut.data.du.6.lw, pttype == 0)
std.distance_to_cut_1to4yo_E <- tapply (sub$std.distance_to_cut_1to4yo, sub$uniqueID, mean)
std.distance_to_cut_5to9yo_E <- tapply (sub$std.distance_to_cut_5to9yo, sub$uniqueID, mean)
std.distance_to_cut_10yoorOver_E <- tapply (sub$std.distance_to_cut_10yoorOver, sub$uniqueID, mean)
inds <- as.character (dist.cut.data.du.6.lw$uniqueID)
dist.cut.data.du.6.lw <- cbind (dist.cut.data.du.6.lw, 
                                "std.distance_to_cut_1to4yo_E" = std.distance_to_cut_1to4yo_E [inds],
                                "std.distance_to_cut_5to9yo_E" = std.distance_to_cut_5to9yo_E [inds],
                                "std.distance_to_cut_10yoorOver_E" = std.distance_to_cut_10yoorOver_E [inds])
# All COVARS
model.lme.fxn.du6.lw <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                                 std.distance_to_cut_10yoorOver + std.distance_to_cut_1to4yo_E +
                                 std.distance_to_cut_5to9yo_E + std.distance_to_cut_10yoorOver_E +
                                 std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                 std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                 std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                 (1 | uniqueID), 
                               data = dist.cut.data.du.6.lw, 
                               family = binomial (link = "logit"),
                               verbose = T,
                               control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                       optimizer = "nloptwrap", # these settings should provide results quicker
                                                       optCtrl = list (maxfun = 2e5)))
summary (model.lme.fxn.du6.lw)
anova (model.lme.fxn.du6.lw)
plot (model.lme.fxn.du6.lw) # should be mostly a straight line

dist.cut.data.du.6.lw$preds.lme.re.fxn <- predict (model.lme.fxn.du6.lw, type = 'response') 
dist.cut.data.du.6.lw$preds.lme.re.fe.fxn <- predict (model.lme.fxn.du6.lw, type = 'response', 
                                                      re.form = NA,
                                                      newdata = dist.cut.data.du.6.lw) 
plot (dist.cut.data.du.6.lw$distance_to_cut_1to4yo, dist.cut.data.du.6.lw$preds.lme.re.fe.fxn) # fixed effect predictions against covariate value
plot (dist.cut.data.du.6.lw$std.distance_to_cut_5to9yo, dist.cut.data.du.6.lw$preds.lme.re.fe.fxn) 
plot (dist.cut.data.du.6.lw$std.distance_to_cut_10yoorOver, dist.cut.data.du.6.lw$preds.lme.re.fe.fxn) 
# sjp.lmer (model.lme.du6.lw, type = "pred", vars = "std.distance_to_cut_1to4yo")

# AIC
table.aic [22, 1] <- "DU6"
table.aic [22, 2] <- "Late Winter"
table.aic [22, 3] <- "GLMM with Functional Response"
table.aic [22, 4] <- "DC1to4, DC5to9, DCover9, A_DC1to4, A_DC5to9, A_DCover9, DC1to4*A_DC1to4, DC5to9*A_DC5to9, DCover9*A_DCover9"
table.aic [22, 5] <- "(1 | UniqueID)"
table.aic [22, 6] <- AIC (model.lme.fxn.du6.lw)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [22, 8] <- auc.temp@y.values[[1]]

# 1to4
model.lme.fxn.du6.lw.1to4 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                      std.distance_to_cut_1to4yo_E +
                                      std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                      (1 | uniqueID), 
                                    data = dist.cut.data.du.6.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                            optimizer = "nloptwrap", # these settings should provide results quicker
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [23, 1] <- "DU6"
table.aic [23, 2] <- "Late Winter"
table.aic [23, 3] <- "GLMM with Functional Response"
table.aic [23, 4] <- "DC1to4, A_DC1to4, DC1to4*A_DC1to4"
table.aic [23, 5] <- "(1 | UniqueID)"
table.aic [23, 6] <- AIC (model.lme.fxn.du6.lw.1to4)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.1to4, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [23, 8] <- auc.temp@y.values[[1]]

# 5to9
model.lme.fxn.du6.lw.5to9 <- glmer (pttype ~ std.distance_to_cut_5to9yo  + 
                                      std.distance_to_cut_5to9yo_E  +
                                      std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                      (1 | uniqueID), 
                                    data = dist.cut.data.du.6.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                            optimizer = "nloptwrap", # these settings should provide results quicker
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [24, 1] <- "DU6"
table.aic [24, 2] <- "Late Winter"
table.aic [24, 3] <- "GLMM with Functional Response"
table.aic [24, 4] <- "DC5to9, A_DC5to9, DC5to9*A_DC5to9"
table.aic [24, 5] <- "(1 | UniqueID)"
table.aic [24, 6] <- AIC (model.lme.fxn.du6.lw.5to9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.5to9, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [24, 8] <- auc.temp@y.values[[1]]

# over9
model.lme.fxn.du6.lw.over9 <- glmer (pttype ~ std.distance_to_cut_10yoorOver  + 
                                       std.distance_to_cut_10yoorOver_E   +
                                       std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                       (1 | uniqueID), 
                                     data = dist.cut.data.du.6.lw, 
                                     family = binomial (link = "logit"),
                                     verbose = T,
                                     control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                             optimizer = "nloptwrap", # these settings should provide results quicker
                                                             optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [25, 1] <- "DU6"
table.aic [25, 2] <- "Late Winter"
table.aic [25, 3] <- "GLMM with Functional Response"
table.aic [25, 4] <- "DCover9, A_DCover9, DCover9*A_DCover9"
table.aic [25, 5] <- "(1 | UniqueID)"
table.aic [25, 6] <- AIC (model.lme.fxn.du6.lw.over9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.over9, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [25, 8] <- auc.temp@y.values[[1]]

# 1to4, 5to9
model.lme.fxn.du6.lw.1459 <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo +
                                      std.distance_to_cut_1to4yo_E +
                                      std.distance_to_cut_5to9yo_E +
                                      std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                      std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                      (1 | uniqueID), 
                                    data = dist.cut.data.du.6.lw, 
                                    family = binomial (link = "logit"),
                                    verbose = T,
                                    control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                            optimizer = "nloptwrap", # these settings should provide results quicker
                                                            optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [26, 1] <- "DU6"
table.aic [26, 2] <- "Late Winter"
table.aic [26, 3] <- "GLMM with Functional Response"
table.aic [26, 4] <- "DC1to4, DC5to9, A_DC1to4, A_DC5to9, DC1to4*A_DC1to4, DC5to9*A_DC5to9"
table.aic [26, 5] <- "(1 | UniqueID)"
table.aic [26, 6] <- AIC (model.lme.fxn.du6.lw.1459)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.1459, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [26, 8] <- auc.temp@y.values[[1]]

# 1to4, over9
model.lme.fxn.du6.lw.14over9 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                                         std.distance_to_cut_10yoorOver +
                                         std.distance_to_cut_1to4yo_E +
                                         std.distance_to_cut_10yoorOver_E  +
                                         std.distance_to_cut_1to4yo:std.distance_to_cut_1to4yo_E +
                                         std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                         (1 | uniqueID), 
                                       data = dist.cut.data.du.6.lw, 
                                       family = binomial (link = "logit"),
                                       verbose = T,
                                       control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                               optimizer = "nloptwrap", # these settings should provide results quicker
                                                               optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [27, 1] <- "DU6"
table.aic [27, 2] <- "Late Winter"
table.aic [27, 3] <- "GLMM with Functional Response"
table.aic [27, 4] <- "DC1to4, DCover9, A_DC1to4, A_DCover9, DC1to4*A_DC1to4, DCover9*A_DCover9"
table.aic [27, 5] <- "(1 | UniqueID)"
table.aic [27, 6] <- AIC (model.lme.fxn.du6.lw.14over9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.14over9, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [27, 8] <- auc.temp@y.values[[1]]

# 5to9, over9
model.lme.fxn.du6.lw.59over9 <- glmer (pttype ~ std.distance_to_cut_5to9yo + 
                                         std.distance_to_cut_10yoorOver +
                                         std.distance_to_cut_5to9yo_E +
                                         std.distance_to_cut_10yoorOver_E  +
                                         std.distance_to_cut_5to9yo:std.distance_to_cut_5to9yo_E +
                                         std.distance_to_cut_10yoorOver:std.distance_to_cut_10yoorOver_E +
                                         (1 | uniqueID), 
                                       data = dist.cut.data.du.6.lw, 
                                       family = binomial (link = "logit"),
                                       verbose = T,
                                       control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                               optimizer = "nloptwrap", # these settings should provide results quicker
                                                               optCtrl = list (maxfun = 2e5)))
# AIC
table.aic [28, 1] <- "DU6"
table.aic [28, 2] <- "Late Winter"
table.aic [28, 3] <- "GLMM with Functional Response"
table.aic [28, 4] <- "DC5to9, DCover9, A_DC5to9, A_DCover9, DC5to9*A_DC5to9, DCover9*A_DCover9"
table.aic [28, 5] <- "(1 | UniqueID)"
table.aic [28, 6] <- AIC (model.lme.fxn.du6.lw.59over9)

# AUC 
pr.temp <- prediction (predict (model.lme.fxn.du6.lw.59over9, type = 'response'), dist.cut.data.du.6.lw$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [28, 8] <- auc.temp@y.values[[1]]


# AIC comparison DU6 late winter
list.aic.like <- c ((exp (-0.5 * (table.aic [15, 6] - min (table.aic [15:28, 6])))), 
                    (exp (-0.5 * (table.aic [16, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [17, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [18, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [19, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [20, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [21, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [22, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [23, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [24, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [25, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [26, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [27, 6] - min (table.aic [15:28, 6])))),
                    (exp (-0.5 * (table.aic [28, 6] - min (table.aic [15:28, 6])))))
table.aic [15, 7] <- round ((exp (-0.5 * (table.aic [15, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [16, 7] <- round ((exp (-0.5 * (table.aic [16, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [17, 7] <- round ((exp (-0.5 * (table.aic [17, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [18, 7] <- round ((exp (-0.5 * (table.aic [18, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [19, 7] <- round ((exp (-0.5 * (table.aic [19, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [20, 7] <- round ((exp (-0.5 * (table.aic [20, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [21, 7] <- round ((exp (-0.5 * (table.aic [21, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [22, 7] <- round ((exp (-0.5 * (table.aic [22, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [23, 7] <- round ((exp (-0.5 * (table.aic [23, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [24, 7] <- round ((exp (-0.5 * (table.aic [24, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [25, 7] <- round ((exp (-0.5 * (table.aic [25, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [26, 7] <- round ((exp (-0.5 * (table.aic [26, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [27, 7] <- round ((exp (-0.5 * (table.aic [27, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)
table.aic [28, 7] <- round ((exp (-0.5 * (table.aic [28, 6] - min (table.aic [15:28, 6])))) / sum (list.aic.like), 3)

# save the table
write.table (table.aic, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\table_aic_forestry.csv", sep = ",")

# save the top model
save (model.lme.du6.lw, 
      file = "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\Rmodels\\model_lme_du6_lw_top.rda")

#============================================
## Summer ##
### Correlation
corr.dist.cut.du.6.s <- round (cor (dist.cut.data.du.6.s [10:13], method = "spearman"), 3)
ggcorrplot (corr.dist.cut.du.6.s, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "Distance to Cutblock Correlation DU6 Summer")
ggsave ("C:\\Work\\caribou\\clus_github\\reports\\caribou_rsf\\plots\\plot_dist_cut_corr_du_6_s.png")

# distance to cutblocks 10 to 29 years old and 30 or over years old were highly correlated
# grouped together
dist.cut.data.du.6.s <- dplyr::mutate (dist.cut.data.du.6.s, distance_to_cut_10yoorOver = pmin (distance_to_cut_10to29yo, distance_to_cut_30orOveryo))

### CART
cart.du.6.s <- rpart (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                        distance_to_cut_10yoorOver,
                      data = dist.cut.data.du.6.s, 
                      method = "class")
summary (cart.du.6.s)
print (cart.du.6.s)
plot (cart.du.6.s, uniform = T)
text (cart.du.6.s, use.n = T, splits = T, fancy = F)
post (cart.du.6.s, file = "", uniform = T)
# results indicate no partioning, suggesting no effect of cutblocks

### VIF
model.glm.du6.s <- glm (pttype ~ distance_to_cut_1to4yo + distance_to_cut_5to9yo + 
                          distance_to_cut_10yoorOver, 
                        data = dist.cut.data.du.6.s,
                        family = binomial (link = 'logit'))
vif (model.glm.du6.s) 

# Generalized Linear Mixed Models (GLMMs)
# standardize covariates  (helps with model convergence)
dist.cut.data.du.6.s$std.distance_to_cut_1to4yo <- (dist.cut.data.du.6.s$distance_to_cut_1to4yo - mean (dist.cut.data.du.6.s$distance_to_cut_1to4yo)) / sd (dist.cut.data.du.6.s$distance_to_cut_1to4yo)
dist.cut.data.du.6.s$std.distance_to_cut_5to9yo <- (dist.cut.data.du.6.s$distance_to_cut_5to9yo - mean (dist.cut.data.du.6.s$distance_to_cut_5to9yo)) / sd (dist.cut.data.du.6.s$distance_to_cut_5to9yo)
dist.cut.data.du.6.s$std.distance_to_cut_10yoorOver <- (dist.cut.data.du.6.s$distance_to_cut_10yoorOver - mean (dist.cut.data.du.6.s$distance_to_cut_10yoorOver)) / sd (dist.cut.data.du.6.s$distance_to_cut_10yoorOver)

### fit corr random effects model
model.lme.du6.s <- glmer (pttype ~ std.distance_to_cut_1to4yo + std.distance_to_cut_5to9yo + 
                            std.distance_to_cut_10yoorOver + 
                            (std.distance_to_cut_1to4yo | uniqueID) + 
                            (std.distance_to_cut_5to9yo | uniqueID) +
                            (std.distance_to_cut_10yoorOver | uniqueID), 
                          data = dist.cut.data.du.6.s, 
                          family = binomial (link = "logit"),
                          verbose = T,
                          control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                  optimizer = "nloptwrap", # these settings should provide results quicker
                                                  optCtrl = list (maxfun = 2e5))) # 20,000 iterations)
summary (model.lme.du6.s)
anova (model.lme.du6.s)
plot (model.lme.du6.s) # should be mostly a straight line

# AIC
table.aic [29, 1] <- "DU6"
table.aic [29, 2] <- "Summer"
table.aic [29, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [29, 4] <- "DC1to4, DC5to9, DCover9"
table.aic [29, 5] <- "(DC1to4 | UniqueID), (DC5to9 | UniqueID), (DCover9 | UniqueID)"
table.aic [29, 6] <- AIC (model.lme.du6.s)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.s, type = 'response'), dist.cut.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [29, 8] <- auc.temp@y.values[[1]]

# AGE 1to4
model.lme.du6.s.14 <- glmer (pttype ~ std.distance_to_cut_1to4yo + 
                               (std.distance_to_cut_1to4yo | uniqueID), 
                             data = dist.cut.data.du.6.s, 
                             family = binomial (link = "logit"),
                             verbose = T,
                             control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                     optimizer = "nloptwrap", # these settings should provide results quicker
                                                     optCtrl = list (maxfun = 2e5))) 
# AIC
table.aic [30, 1] <- "DU6"
table.aic [30, 2] <- "Summer"
table.aic [30, 3] <- "GLMM with Individual and Year (UniqueID) Random Effect"
table.aic [30, 4] <- "DC1to4"
table.aic [30, 5] <- "(DC1to4 | UniqueID)"
table.aic [30, 6] <- AIC (model.lme.du6.s.14)

# AUC 
pr.temp <- prediction (predict (model.lme.du6.s.14, type = 'response'), dist.cut.data.du.6.s$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
table.aic [30, 8] <- auc.temp@y.values[[1]]

# AGE 5to9
model.lme.du6.s.59 <- glmer (pttype ~ std.distance_to_cut_5to9yo + 
                               (std.distance_to_cut_5to9yo | uniqueID), 
                             data = dist.cut.data.du.6.s, 
                             family = binomial (link = "logit"),
                             verbose = T,
                             control = glmerControl (calc.derivs = FALSE, # these settings should provide results quick
                                                     