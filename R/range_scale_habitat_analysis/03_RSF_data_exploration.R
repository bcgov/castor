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

rsf.large.scale.data.age$ECOTYPE<-rsf.large.scale.data.age$avail.ecotype
rsf.large.scale.data.age$pttype<-0

rsf.large.scale<-rsf.large.scale.data.age[,c(66,65,3:5,14:63)]
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
dim(sample_data)


#====================================
# Frequency plot of distance to cutblock by point type
#===================================
setwd("C:\\Work\\caribou\\clus_data\\disturbance\\Cutblock_figures")

for (i in 1:50){
  # cutblock_mean<- sample_data %>%
  #   group_by(pttype) %>%
  #   summarise(median_dist=(mean(get(paste("distance_to_cut_",i,"yo",sep="")))))
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
    scale_x_continuous(name="Distance to cutblocks (m)",limits=c(0, 400000)) +
    scale_y_continuous(name = "Density") + 
    ggtitle(paste("Distance to cut in year", i))
    #geom_vline(xintercept=cutblock_mean$median_dist, size=1,colour="black",linetype="dashed")

#nam<-paste("dist_to_cut",i,"pdf",sep=".")
nam2<-paste("density.plot.year",i,"jpeg",sep=".")
#assign(nam,P)
assign(nam2,plot2)

ggsave(nam2)
}


table.diff.dist <- data.frame (matrix (ncol = 5, nrow = 0))
colnames (table.diff.dist) <- c ("cutblock_age", "du6","du7","du8","du9")

for (i in 1:50){

cutblock_mean<- sample_data %>%
     group_by(du,pttype) %>%
     summarise(median_dist=(median(get(paste("distance_to_cut_",i,"yo",sep="")))))

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
table.glm.summary <- data.frame (matrix (ncol = 3, nrow = 0))
colnames (table.glm.summary) <- c ("Years_Old", "Coefficient", "p-values")


# analysis for all data together
for (i in 1:50) {
  
  
var1<-paste("distance_to_cut_",i,"yo",sep="")

m1<-glm(pttype ~ get(var1), 
        data=sample_data,
        family=binomial(link="logit"))

table.glm.summary[i,1]<-i
table.glm.summary [i, 2] <- m1$coefficients [[2]]
table.glm.summary [i, 3] <- scientific(summary(m1)$coefficients[2,4],digits=3) # p-value
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
table.glm.summary.du6 <- data.frame (matrix (ncol = 4, nrow = 0))
colnames (table.glm.summary.du6) <- c ("du","Years_Old", "Coefficient", "p-values")
du6_dat<-sample_data %>% filter(du=="du6")

for (i in 1:50) {
  
  var1<-paste("distance_to_cut_",i,"yo",sep="")
  
  m1<-glm(pttype ~ get(var1), 
          data=du6_dat,
          family=binomial(link="logit"))
  
  table.glm.summary.du6[i,1]<-"du6"
  table.glm.summary.du6[i,2]<-i
  table.glm.summary.du6 [i, 3] <- m1$coefficients [[2]]
  table.glm.summary.du6 [i, 4] <- scientific(summary(m1)$coefficients[2,4],digits=3) # p-value
}

fig_du6<-ggplot (table.glm.summary.du6, aes (Years_Old, Coefficient)) +
  geom_line()+
  ggtitle ("Beta coefficient values of distance to cutblock \n by year and season for caribou in du6") +
  xlab ("Years since harvest") + 
  ylab ("Beta coefficient") +
  geom_line (aes (x = Years_Old, y = 0), 
             size = 0.5, linetype = "solid", colour = "black") 

#-----
#du7
#-----
table.glm.summary.du7 <- data.frame (matrix (ncol = 4, nrow = 0))
colnames (table.glm.summary.du7) <- c ("du","Years_Old", "Coefficient", "p-values")
du7_dat<-sample_data %>% filter(du=="du7")

for (i in 1:50) {
  
  var1<-paste("distance_to_cut_",i,"yo",sep="")
  
  m1<-glm(pttype ~ get(var1), 
          data=du7_dat,
          family=binomial(link="logit"))
  
  table.glm.summary.du7[i,1]<-"du7"
  table.glm.summary.du7[i,2]<-i
  table.glm.summary.du7 [i, 3] <- m1$coefficients [[2]]
  table.glm.summary.du7 [i, 4] <- scientific(summary(m1)$coefficients[2,4],digits=3) # p-value
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
table.glm.summary.du8 <- data.frame (matrix (ncol = 4, nrow = 0))
colnames (table.glm.summary.du8) <- c ("du","Years_Old", "Coefficient", "p-values")
du8_dat<-sample_data %>% filter(du=="du8")

for (i in 1:50) {
  
  var1<-paste("distance_to_cut_",i,"yo",sep="")
  
  m1<-glm(pttype ~ get(var1), 
          data=du8_dat,
          family=binomial(link="logit"))
  
  table.glm.summary.du8[i,1]<-"du8"
  table.glm.summary.du8[i,2]<-i
  table.glm.summary.du8 [i, 3] <- m1$coefficients [[2]]
  table.glm.summary.du8 [i, 4] <- scientific(summary(m1)$coefficients[2,4],digits=3) # p-value
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
table.glm.summary.du9 <- data.frame (matrix (ncol = 4, nrow = 0))
colnames (table.glm.summary.du9) <- c ("du","Years_Old", "Coefficient", "p-values")
du9_dat<-sample_data %>% filter(du=="du9")

for (i in 1:50) {
  
  var1<-paste("distance_to_cut_",i,"yo",sep="")
  
  m1<-glm(pttype ~ get(var1), 
          data=du9_dat,
          family=binomial(link="logit"))
  
  table.glm.summary.du9[i,1]<-"du9"
  table.glm.summary.du9[i,2]<-i
  table.glm.summary.du9 [i, 3] <- m1$coefficients [[2]]
  table.glm.summary.du9 [i, 4] <- scientific(summary(m1)$coefficients[2,4],digits=3) # p-value
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
# I need to join tylers points to mine then run a GLM (poison distribution) for each du or maybe herd for each year of distance to cutblock pulling out the p values, and coefficients


conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")
rsf.large.scale.data.age <- sf::st_read  (dsn = conn,
                                          query = "SELECT * FROM caribou.dist_to_disturbance_summary")
dbDisconnect (conn) # connKyle

head(rsf.large.scale.data.age)

# binning the data into groups that are less correlated
rsf.large.scale.data.age <- dplyr::mutate (rsf.large.scale.data.age, distance_to_cut_1to4yo = pmin (distance_to_cut_1yo, distance_to_cut_2yo, distance_to_cut_3yo, distance_to_cut_4yo))

rsf.large.scale.data.age <- dplyr::mutate (rsf.large.scale.data.age, distance_to_cut_5to9yo = pmin (distance_to_cut_5yo, distance_to_cut_6yo, distance_to_cut_7yo, distance_to_cut_8yo, distance_to_cut_9yo))

rsf.large.scale.data.age <- dplyr::mutate (rsf.large.scale.data.age, distance_to_cut_10to29yo = pmin (distance_to_cut_10yo, distance_to_cut_11yo, distance_to_cut_12yo, distance_to_cut_13yo, distance_to_cut_14yo, distance_to_cut_15yo,distance_to_cut_16yo, distance_to_cut_17yo, distance_to_cut_18yo, distance_to_cut_19yo, distance_to_cut_20yo, distance_to_cut_21yo, distance_to_cut_22yo, distance_to_cut_23yo, distance_to_cut_24yo, distance_to_cut_25yo, distance_to_cut_26yo, distance_to_cut_27yo, distance_to_cut_28yo, distance_to_cut_29yo))

rsf.large.scale.data.age <- dplyr::mutate (rsf.large.scale.data.age, distance_to_cut_30orOveryo = pmin (distance_to_cut_30yo, distance_to_cut_31yo, distance_to_cut_32yo, distance_to_cut_33yo, distance_to_cut_34yo, distance_to_cut_35yo, distance_to_cut_36yo, distance_to_cut_37yo, distance_to_cut_38yo, distance_to_cut_39yo, distance_to_cut_40yo, distance_to_cut_41yo, distance_to_cut_42yo, distance_to_cut_43yo, distance_to_cut_44yo, distance_to_cut_45yo, distance_to_cut_46yo, distance_to_cut_47yo, distance_to_cut_48yo, distance_to_cut_49yo, distance_to_cut_50yo))


# write.table (rsf.large.scale.data.age, "C:\\Work\\caribou\\clus_data\\caribou_habitat_model\\rsf_data_cutblock_age.csv", sep = ",")
names(rsf.large.scale.data.age)
# Correlations
dist.cut.corr <- st_drop_geometry(rsf.large.scale.data.age [c (65:68)])
corr <- round (cor (dist.cut.corr), 3)
p.mat <- round (cor_pmat (dist.cut.corr), 2)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Distance to Cutblock Correlation")
# ggcorrplot (corr, type = "lower", p.mat = p.mat, insig = "blank")

