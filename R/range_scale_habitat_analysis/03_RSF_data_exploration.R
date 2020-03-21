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

rsf.data.cut.age<-read.csv("T:\\FOR\\VIC\\HTS\\ANA\\PROJECTS\\CLUS\\Data\\caribou\\telemetry_habitat_model_20180904\\rsf_data_cutblock_age.csv")
head(rsf.data.cut.age)

unique(rsf.data.cut.age$pttype)
rsf_data_forestry <- rsf.data.cut.age %>% filter(pttype==0)
rsf_data_forestry$pttype<-1 

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

#====================================
# Join rsf.data.cut.age to rsf.large.scale.data.age
#===================================




#====================================
# GLMs, by year
#===================================
Herd_name<-c("Central_Selkirks","Columbia_North","Groundhog", "Monashee", "Purcell_Central", "Purcell_South","South_Selkirks","Wells_Gray_South","Columbia_South","Hart_Ranges","North_Cariboo","Telkwa","Wells_Gray_North","Central_Rockies","Charlotte_Alplands","Itcha_Ilgachuz","Rainbows","Barkerville","Narrow_Lake","Frisby_Boulder","Redrock_Prairie_Creek")

distance_to_cut_list<-c("distance_to_cutblocks_1","distance_to_cutblocks_2","distance_to_cutblocks_3",)
#test this
paste("distance_to_cutblocsk",j,sep="_")

# summary table
table.glm.summary <- data.frame (matrix (ncol = 5, nrow = 0))
colnames (table.glm.summary) <- c ("DU", "HERD_NAME", "Years Old", "Coefficient", "p-values")


for (i in 1:length(Herd_name)){
  for(j in 1:50){

glm_results <- glm (pttype ~ distance_to_cut_1yo, 
                        data = dist.cut.data.du.6.ew,
                        family = binomial (link = 'logit'))
table.glm.summary [1, 4] <- glm.du.6.ew.1yo$coefficients [[2]]
table.glm.summary [1, 5] <- summary(glm.du.6.ew.1yo)$coefficients[2,4] # p-value
rm (glm.du.6.ew.1yo)

