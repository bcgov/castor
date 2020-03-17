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

#================
# Cutblocks Data Tylers points
#===============
#rsf_data_forestry<-read.csv("C:\\Work\\caribou\\clus_data\\rsf_data_foresty.csv",header=FALSE,col.names=c("pt_id","pttype","uniqueID","du","season","animal_id","year","ECOTYPE","HERD_NAME","ptID","distance_to_cut_1to4yo","distance_to_cut_5to9yo","distance_to_cut_10to29yo","distance_to_cut_30orOveryo","distance_to_paved_road","distance_to_loose_road","distance_to_petroleum_road","distance_to_rough_road","distance_to_trim_transport_road","distance_to_unknown_road",".R_rownames"))

rsf_data_cutblock_age<-read.csv("T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\caribou\\telemetry_habitat_model_20180904\\rsf_data_cutblock_age.csv")
head(rsf_data_cutblock_age)

points_used <- rsf_data_forestry %>% filter(pttype==0)
points_used$pttype<-1 

#=======================================================================
# re-categorize forestry data and test correlations, beta coeffs again
#=====================================================================

conn <- dbConnect (dbDriver ("PostgreSQL"), 
                   host = "",
                   user = "postgres",
                   dbname = "postgres",
                   password = "postgres",
                   port = "5432")
rsf.large.scale.data.age <- sf::st_read  (dsn = conn,
                                       query = "SELECT * FROM caribou.dist_to_disturbance_summary")
dbDisconnect (conn) # connKyle

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


#=================================
# Data exploration/visualization
#=================================
# Correlations
# broke into 10 year chunks;
# first 10 years
dist.cut.1.10.corr <- st_drop_geometry(rsf.large.scale.data.age [c (15,16,63,64,17:32)])
corr.1.10 <- round (cor (dist.cut.1.10.corr, method = "spearman"), 3)
p.mat.1.10 <- round (cor_pmat (dist.cut.1.10.corr), 2)
ggcorrplot (corr.1.10, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Distance to Cutblock Correlation Years 1 to 10")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_1_10.png")
# ggcorrplot (corr, type = "lower", p.mat = p.mat, insig = "blank")

# 10-20  years
dist.cut.11.20.corr <- rsf.large.scale.data.age [c (20:29)]
corr.11.20 <- round (cor (dist.cut.11.20.corr, method = "spearman"), 3)
p.mat.11.20 <- round (cor_pmat (dist.cut.11.20.corr), 2)
ggcorrplot (corr.11.20, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Distance to Cutblock Correlation Years 11 to 20")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_11_20.png")

# 21-30  years
dist.cut.21.30.corr <- rsf.large.scale.data.age [c (30:39)]
corr.21.30 <- round (cor (dist.cut.21.30.corr, method = "spearman"), 3)
p.mat.21.30 <- round (cor_pmat (dist.cut.21.30.corr), 2)
ggcorrplot (corr.21.30, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Distance to Cutblock Correlation Years 21 to 30")

# 31-40  years
dist.cut.31.40.corr <- rsf.large.scale.data.age [c (40:49)]
corr.31.40 <- round (cor (dist.cut.31.40.corr, method = "spearman"), 3)
p.mat.31.40 <- round (cor_pmat (dist.cut.31.40.corr), 2)
ggcorrplot (corr.31.40, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Distance to Cutblock Correlation Years 31 to 40")

# >41  years
dist.cut.41.50.corr <- rsf.large.scale.data.age [c (50:60)]
corr.41.50 <- round (cor (dist.cut.41.50.corr, method = "spearman"), 3)
p.mat.41.50 <- round (cor_pmat (dist.cut.41.50.corr), 2)
ggcorrplot (corr.41.50, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3,
            title = "All Data Distance to Cutblock Correlation Years 41 to >50")

#########
## DU6 ## 
#########
dist.cut.corr.du.6 <- rsf.large.scale.data.age %>%
  dplyr::filter (du == "du6")

dist.cut.1.10.corr.du.6 <- st_drop_geometry(dist.cut.corr.du.6 [c (15,16,63,64,17:32)])
corr.1.10.du6 <- round (cor (dist.cut.1.10.corr.du.6, method = "spearman"), 3)
p.mat.1.10 <- round (cor_pmat (corr.1.10.du6), 2)
ggcorrplot (corr.1.10.du6, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU6 Distance to Cutblock Correlation Years 1 to 10")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_1_10_du6.png")

dist.cut.11.20.corr.du.6 <- dist.cut.corr.du.6 [c (20:29)]
corr.11.20.du6 <- round (cor (dist.cut.11.20.corr.du.6, method = "spearman"), 3)
p.mat.11.20 <- round (cor_pmat (corr.11.20.du6), 2)
ggcorrplot (corr.11.20.du6, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU6 Distance to Cutblock Correlation Years 11 to 20")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_11_20_du6.png")

dist.cut.21.30.corr.du.6 <- dist.cut.corr.du.6 [c (30:39)]
corr.21.30.du6 <- round (cor (dist.cut.21.30.corr.du.6, method = "spearman"), 3)
p.mat.21.30 <- round (cor_pmat (corr.21.30.du6), 2)
ggcorrplot (corr.21.30.du6, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU6 Distance to Cutblock Correlation Years 21 to 30")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_21_30_du6.png")

dist.cut.31.40.corr.du.6 <- dist.cut.corr.du.6 [c (40:49)]
corr.31.40.du6 <- round (cor (dist.cut.31.40.corr.du.6, method = "spearman"), 3)
p.mat.31.40 <- round (cor_pmat (corr.31.40.du6), 2)
ggcorrplot (corr.31.40.du6, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU6 Distance to Cutblock Correlation Years 31 to 40")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_31_40_du6.png")

dist.cut.41.50.corr.du.6 <- dist.cut.corr.du.6 [c (50:60)]
corr.41.50.du6 <- round (cor (dist.cut.41.50.corr.du.6, method = "spearman"), 3)
p.mat.41.50 <- round (cor_pmat (corr.41.50.du6), 2)
ggcorrplot (corr.41.50.du6, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3, 
            title = "DU6 Distance to Cutblock Correlation Years 41 to >50")
ggsave ("C:\\Work\\caribou\\clus_github\\R\\caribou_habitat\\plots\\plot_dist_cut_corr_41_50_du6.png")

