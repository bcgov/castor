# Copyright 2018 Province of British Columbia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

#=================================
#  Script Name: 04_model_predict.R
#  Script Version: 1.0
#  Script Purpose: Predict regression model on raster maps.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 2 May 2018
#  R Version: 3.4.3
#  R Packages: 
#  Data: 
#=================================

#=================================
# data directory
#=================================
setwd ('C:\\Work\\caribou\\climate_analysis\\data\\')
options (scipen = 999)

#=================================
# Load packages
#=================================
require (sp) # spatial package; particulary useful for working with vector data
require (raster) # for working with and processing raster data; 
# provides tools for automatic tiling of raster objects too large to fit into memory
require (rgeos) # geoprocessing functions
require (dplyr)
require (rgdal) # for loading and writing spatial data
require (maptools)
require (spatstat)
require (ggplot2)
require (ggmap)

#=================================
# Load data and models
#=================================
# model.all <- load (file = "C:\\Work\\caribou\\climate_analysis\\output\\model_all_road_20180504.rda")
model.boreal <- load (file = "C:\\Work\\caribou\\climate_analysis\\output\\model_boreal_top_fin_20180514.rda")
model.north <- load (file = "C:\\Work\\caribou\\climate_analysis\\output\\model_north_top_fin_20180514.rda")
model.mount <- load (file = "C:\\Work\\caribou\\climate_analysis\\output\\model_mountain_top_fin_20180514.rda")

data <- read.table ("model\\model_data_20180502.csv", header = T, stringsAsFactors = T, sep = ",")
data.clean <- data [complete.cases (data), ]
data.clean <- data.clean %>%
  filter (pas.wt.2010 < 1000) %>%
  filter (tave.wt.2010 < -1) %>%
  filter (cut.perc >= 0)
data.clean$bec.curr.simple <- as.character (data.clean$bec.current)
data.clean$bec.curr.simple [data.clean$bec.curr.simple == "BAFAun" | 
                              data.clean$bec.curr.simple == "BAFAunp"] <- "BAFA"
data.clean$bec.curr.simple [data.clean$bec.curr.simple == "BWBSdk" | 
                              data.clean$bec.curr.simple == "BWBSmk" |
                              data.clean$bec.curr.simple == "BWBSmw" |
                              data.clean$bec.curr.simple == "BWBSwk 1" |  
                              data.clean$bec.curr.simple == "BWBSwk 2" |   
                              data.clean$bec.curr.simple == "BWBSwk 3"] <- "BWBS"
data.clean$bec.curr.simple [data.clean$bec.curr.simple == "CMA un" |
                              data.clean$bec.curr.simple == "CMA unp"] <- "CMA"
data.clean$bec.curr.simple [data.clean$bec.curr.simple == "CWH ds 2" |
                              data.clean$bec.curr.simple == "CWH ms 2" |
                              data.clean$bec.curr.simple == "CWH vm 1" |
                              data.clean$bec.curr.simple == "CWH vm 2" |  
                              data.clean$bec.curr.simple == "CWH ws 1" | 
                              data.clean$bec.curr.simple == "CWH ws 2" | 
                              data.clean$bec.curr.simple == "CWH ws 2" ] <- "CWH"
data.clean$bec.curr.simple [data.clean$bec.curr.simple == "ESSFdc 1" |
                              data.clean$bec.curr.simple == "ESSFdc 3" |
                              data.clean$bec.curr.simple == "ESSFdk 1" |
                              data.clean$bec.curr.simple == "ESSFdk 2" |  
                              data.clean$bec.curr.simple == "ESSFdkp" | 
                              data.clean$bec.curr.simple == "ESSFdkw" | 
                              data.clean$bec.curr.simple == "ESSFmc"  |
                              data.clean$bec.curr.simple == "ESSFmcp"  |
                              data.clean$bec.curr.simple == "ESSFmh"  |
                              data.clean$bec.curr.simple == "ESSFmk"  |
                              data.clean$bec.curr.simple == "ESSFmkp"  |
                              data.clean$bec.curr.simple == "ESSFmm 1"  |
                              data.clean$bec.curr.simple == "ESSFmmp"  |
                              data.clean$bec.curr.simple == "ESSFmmw"  |
                              data.clean$bec.curr.simple == "ESSFmv 1"  |
                              data.clean$bec.curr.simple == "ESSFmv 2"  |
                              data.clean$bec.curr.simple == "ESSFmv 3"  |
                              data.clean$bec.curr.simple == "ESSFmv 4"  |
                              data.clean$bec.curr.simple == "ESSFmvp"  |
                              data.clean$bec.curr.simple == "ESSFmw"  |
                              data.clean$bec.curr.simple == "ESSFmwp"  |
                              data.clean$bec.curr.simple == "ESSFun"  |
                              data.clean$bec.curr.simple == "ESSFunp"  |
                              data.clean$bec.curr.simple == "ESSFvc"  |
                              data.clean$bec.curr.simple == "ESSFvcp"  |
                              data.clean$bec.curr.simple == "ESSFvcw"  |
                              data.clean$bec.curr.simple == "ESSFwc 2"  |
                              data.clean$bec.curr.simple == "ESSFwc 2w"  |
                              data.clean$bec.curr.simple == "ESSFwc 3"  |
                              data.clean$bec.curr.simple == "ESSFwc 4"  |
                              data.clean$bec.curr.simple == "ESSFwcp"  |
                              data.clean$bec.curr.simple == "ESSFwcw"  |
                              data.clean$bec.curr.simple == "ESSFwh 1"  |
                              data.clean$bec.curr.simple == "ESSFwh 2"  |
                              data.clean$bec.curr.simple == "ESSFwh 3"  |
                              data.clean$bec.curr.simple == "ESSFwk 1"  |
                              data.clean$bec.curr.simple == "ESSFwk 2"  |
                              data.clean$bec.curr.simple == "ESSFwm"  |
                              data.clean$bec.curr.simple == "ESSFwm 2"  |
                              data.clean$bec.curr.simple == "ESSFwm 3"  |
                              data.clean$bec.curr.simple == "ESSFwm 4"  |
                              data.clean$bec.curr.simple == "ESSFwmp"  |
                              data.clean$bec.curr.simple == "ESSFwmw"  |
                              data.clean$bec.curr.simple == "ESSFwv"  |
                              data.clean$bec.curr.simple == "ESSFwvp"  |
                              data.clean$bec.curr.simple == "ESSFxv 1"  |
                              data.clean$bec.curr.simple == "ESSFxvp"] <- "ESSF"
data.clean$bec.curr.simple [data.clean$bec.curr.simple == "ICH dk" |
                              data.clean$bec.curr.simple == "ICH dm" |
                              data.clean$bec.curr.simple == "ICH dw 1" |
                              data.clean$bec.curr.simple == "ICH dw 3" |  
                              data.clean$bec.curr.simple == "ICH dw 4" | 
                              data.clean$bec.curr.simple == "ICH mc 1" | 
                              data.clean$bec.curr.simple == "ICH mk 2"  |
                              data.clean$bec.curr.simple == "ICH mk 3"  |
                              data.clean$bec.curr.simple == "ICH mk 4"  |
                              data.clean$bec.curr.simple == "ICH mm"  |
                              data.clean$bec.curr.simple == "ICH mw 1"  |
                              data.clean$bec.curr.simple == "ICH mw 2"  |
                              data.clean$bec.curr.simple == "ICH mw 3"  |
                              data.clean$bec.curr.simple == "ICH mw 4"  |
                              data.clean$bec.curr.simple == "ICH mw 5"  |
                              data.clean$bec.curr.simple == "ICH vk 1"  |
                              data.clean$bec.curr.simple == "ICH vk 2"  |
                              data.clean$bec.curr.simple == "ICH wc"  |
                              data.clean$bec.curr.simple == "ICH wk 1"  |
                              data.clean$bec.curr.simple == "ICH wk 2"  |
                              data.clean$bec.curr.simple == "ICH wk 3"  |
                              data.clean$bec.curr.simple == "ICH wk 4"  |
                              data.clean$bec.curr.simple == "ICH xw"  |
                              data.clean$bec.curr.simple == "ICH xw  a"] <- "ICH"
data.clean$bec.curr.simple [data.clean$bec.curr.simple == "IDF dk 4" |
                              data.clean$bec.curr.simple == "IDF dm 2" |
                              data.clean$bec.curr.simple == "IDF dw" |
                              data.clean$bec.curr.simple == "IDF mw 1" |  
                              data.clean$bec.curr.simple == "IDF mw 2" | 
                              data.clean$bec.curr.simple == "IDF ww" | 
                              data.clean$bec.curr.simple == "IDF xm"] <- "IDF"
data.clean$bec.curr.simple [data.clean$bec.curr.simple == "IMA un" |
                              data.clean$bec.curr.simple == "IMA unp" ] <- "IMA"
data.clean$bec.curr.simple [data.clean$bec.curr.simple == "MH  mm 1" |
                              data.clean$bec.curr.simple == "MH  mm 2" |
                              data.clean$bec.curr.simple == "MH  mmp" |
                              data.clean$bec.curr.simple == "MH  unp" ] <- "MH"
data.clean$bec.curr.simple [data.clean$bec.curr.simple == "MS  dc 2" |
                              data.clean$bec.curr.simple == "MS  dk 1" |
                              data.clean$bec.curr.simple == "MS  dk 2" |
                              data.clean$bec.curr.simple == "MS  un" |
                              data.clean$bec.curr.simple == "MS  xv" ] <- "MS"
data.clean$bec.curr.simple [data.clean$bec.curr.simple == "PP  dh 2" ] <- "PP"
data.clean$bec.curr.simple [data.clean$bec.curr.simple == "SBPSdc" |
                              data.clean$bec.curr.simple == "SBPSmc" |
                              data.clean$bec.curr.simple == "SBPSmk" |
                              data.clean$bec.curr.simple == "SBPSxc" ] <- "SBPS"
data.clean$bec.curr.simple [data.clean$bec.curr.simple == "SBS dk" |
                              data.clean$bec.curr.simple == "SBS dh 1" |
                              data.clean$bec.curr.simple == "SBS dw 1" | 
                              data.clean$bec.curr.simple == "SBS dw 3"  |
                              data.clean$bec.curr.simple == "SBS mc 1"  |
                              data.clean$bec.curr.simple == "SBS mc 2"  |
                              data.clean$bec.curr.simple == "SBS mc 3"  |
                              data.clean$bec.curr.simple == "SBS mh"  |
                              data.clean$bec.curr.simple == "SBS mk 1"  |
                              data.clean$bec.curr.simple == "SBS mk 2"  |
                              data.clean$bec.curr.simple == "SBS mm"  |
                              data.clean$bec.curr.simple == "SBS mw"  |
                              data.clean$bec.curr.simple == "SBS un"  |
                              data.clean$bec.curr.simple == "SBS vk"  |
                              data.clean$bec.curr.simple == "SBS wk 1"  |
                              data.clean$bec.curr.simple == "SBS wk 2"  |
                              data.clean$bec.curr.simple == "SBS wk 3"  |
                              data.clean$bec.curr.simple == "SBS wk 3a"] <- "SBS"
data.clean$bec.curr.simple [data.clean$bec.curr.simple == "SWB mk"  |
                              data.clean$bec.curr.simple == "SWB mks"  |
                              data.clean$bec.curr.simple == "SWB un" |
                              data.clean$bec.curr.simple == "SWB uns" ] <- "SWB"
data.clean$bec.curr.simple <- as.factor (data.clean$bec.curr.simple)

data.boreal <- dplyr::filter (data.clean, ecotype == "Boreal")
data.north <- dplyr::filter (data.clean, ecotype == "Northern")
data.mount <- dplyr::filter (data.clean, ecotype == "Mountain")

#================================================
# Load caribou range data
#===============================================
caribou.range <- readOGR ("caribou\\caribou_herd\\GCPB_CARIBOU_POPULATION_SP\\GCBP_CARIB_polygon.shp", 
                          stringsAsFactors = T)
caribou.range.boreal <- subset (caribou.range, caribou.range@data$ECOTYPE == "Boreal")
caribou.range.mtn <- subset (caribou.range, caribou.range@data$ECOTYPE == "Mountain")
caribou.range.north <- subset (caribou.range, caribou.range@data$ECOTYPE == "Northern")
caribou.boreal.sa <- readOGR ("studyarea\\caribou_boreal_study_area.shp", 
                               stringsAsFactors = T)
caribou.mount.sa <- readOGR ("studyarea\\caribou_mtn_study_area.shp", 
                              stringsAsFactors = T)
caribou.north.sa <- readOGR ("studyarea\\caribou_north_study_area.shp", 
                             stringsAsFactors = T)

#================================================
# Load rasters of BEC and climate data
#===============================================
bec2020.rst <- raster ("bec\\BEC_zone_2020s\\BEC_zone_2020s.tif")
bec2050.rst <- raster ("bec\\BEC_zone_2050s\\BEC_zone_2050s.tif")
bec2080.rst <- raster ("bec\\BEC_zone_2080s\\BEC_zone_2080s.tif")
roads.27k.rst <- raster ("roads\\dra_dens_27km_tif\\dra_dns_27k.tif")

table.bec2020.factors <- data.frame (levels (bec2020.rst[[1]])) # factor level tables
table.bec2020.factors$zone.factor.num <- as.numeric (table.bec2020.factors$ZONE)
table.bec2050.factors <- data.frame (levels (bec2050.rst[[1]]))
table.bec2050.factors$zone.factor.num <- as.numeric (table.bec2050.factors$ZONE)
table.bec2080.factors <- data.frame (levels (bec2080.rst[[1]]))
table.bec2080.factors$zone.factor.num <- as.numeric (table.bec2080.factors$ZONE)

clim.1961.1990.tavewt.rst <- raster ("climate\\Normal_1961_1990_seasonal\\tave_wt") 
clim.1961.1990.tavewt.rst <- clim.1961.1990.tavewt.rst / 10 # multiplied by 10 @ source; need to be divided by ten
clim.1961.1990.paswt.rst <- raster ("climate\\Normal_1961_1990_seasonal\\pas_wt") # winter precipitation as snow
clim.1961.1990.nffdsp.rst <- raster ("climate\\Normal_1961_1990_seasonal\\nffd_sp") # number of frost free days spring

clim.1981.2010.tavewt.rst <- raster ("climate\\Normal_1981_2010_seasonal\\tave_wt") 
clim.1981.2010.tavewt.rst <- clim.1981.2010.tavewt.rst / 10 # multiplied by 10 @ source; need to be divided by ten
clim.1981.2010.paswt.rst <- raster ("climate\\Normal_1981_2010_seasonal\\pas_wt")
clim.1981.2010.nffdsp.rst <- raster ("climate\\Normal_1981_2010_seasonal\\nffd_sp") 

canesm2.2025.tavewt.rst <- raster ("climate\\CanESM2_RCP45_2025_seasonal\\tave_wt") # average winter temp
canesm2.2025.paswt.rst <- raster ("climate\\CanESM2_RCP45_2025_seasonal\\pas_wt") # winter precipitation as snow
canesm2.2025.nffdsp.rst <- raster ("climate\\CanESM2_RCP45_2025_seasonal\\nffd_sp") 

canesm2.2055.tavewt.rst <- raster ("climate\\CanESM2_RCP45_2055_seasonal\\tave_wt") # average winter temp
canesm2.2055.paswt.rst <- raster ("climate\\CanESM2_RCP45_2055_seasonal\\pas_wt") # winter precipitation as snow
canesm2.2055.nffdsp.rst <- raster ("climate\\CanESM2_RCP45_2055_seasonal\\nffd_sp") 

canesm2.2085.tavewt.rst <- raster ("climate\\CanESM2_RCP45_2085_seasonal\\tave_wt") # average winter temp
canesm2.2085.paswt.rst <- raster ("climate\\CanESM2_RCP45_2085_seasonal\\pas_wt") # winter precipitation as snow
canesm2.2085.nffdsp.rst <- raster ("climate\\CanESM2_RCP45_2085_seasonal\\nffd_sp") 

ccsm4.2025.tavewt.rst <- raster ("climate\\CCSM4_RCP45_2025_seasonal\\tave_wt") # average winter temp
ccsm4.2025.paswt.rst <- raster ("climate\\CCSM4_RCP45_2025_seasonal\\pas_wt") # winter precipitation as snow
ccsm4.2025.nffdsp.rst <- raster ("climate\\CCSM4_RCP45_2025_seasonal\\nffd_sp") 

ccsm4.2055.tavewt.rst <- raster ("climate\\CCSM4_RCP45_2055_seasonal\\tave_wt") # average winter temp
ccsm4.2055.paswt.rst <- raster ("climate\\CCSM4_RCP45_2055_seasonal\\pas_wt") # winter precipitation as snow
ccsm4.2055.nffdsp.rst <- raster ("climate\\CCSM4_RCP45_2055_seasonal\\nffd_sp") 

ccsm4.2085.tavewt.rst <- raster ("climate\\CCSM4_RCP45_2085_seasonal\\tave_wt") # average winter temp
ccsm4.2085.paswt.rst <- raster ("climate\\CCSM4_RCP45_2085_seasonal\\pas_wt") # winter precipitation as snow
ccsm4.2085.nffdsp.rst <- raster ("climate\\CCSM4_RCP45_2085_seasonal\\nffd_sp") 

hadgem.2025.tavewt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2025_seasonal\\tave_wt") # average winter temp
hadgem.2025.paswt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2025_seasonal\\pas_wt") # winter precipitation as snow
hadgem.2025.nffdsp.rst <- raster ("climate\\HadGEM2-ES_RCP45_2025_seasonal\\nffd_sp") 

hadgem.2055.tavewt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2055_seasonal\\tave_wt") # average winter temp
hadgem.2055.paswt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2055_seasonal\\pas_wt") # winter precipitation as snow
hadgem.2055.nffdsp.rst <- raster ("climate\\HadGEM2-ES_RCP45_2055_seasonal\\nffd_sp") 

hadgem.2085.tavewt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2085_seasonal\\tave_wt") # average winter temp
hadgem.2085.paswt.rst <- raster ("climate\\HadGEM2-ES_RCP45_2085_seasonal\\pas_wt") # winter precipitation as snow
hadgem.2085.nffdsp.rst <- raster ("climate\\HadGEM2-ES_RCP45_2085_seasonal\\nffd_sp") 

tavewt.2025 <- mean (canesm2.2025.tavewt.rst, ccsm4.2025.tavewt.rst, hadgem.2025.tavewt.rst) # take average of three climate models
tavewt.2025 <- tavewt.2025 / 10 # divide by ten for temp covariates
paswt.2025 <- mean (canesm2.2025.paswt.rst, ccsm4.2025.paswt.rst, hadgem.2025.paswt.rst) 
nffdsp.2025 <- mean (canesm2.2025.nffdsp.rst, ccsm4.2025.nffdsp.rst, hadgem.2025.nffdsp.rst) 
tavewt.2055 <- mean (canesm2.2055.tavewt.rst, ccsm4.2055.tavewt.rst, hadgem.2055.tavewt.rst) # take average of three climate models
tavewt.2055 <- tavewt.2055 / 10 # divide by ten for temp covariates
paswt.2055 <- mean (canesm2.2055.paswt.rst, ccsm4.2055.paswt.rst, hadgem.2055.paswt.rst) 
nffdsp.2055 <- mean (canesm2.2055.nffdsp.rst, ccsm4.2055.nffdsp.rst, hadgem.2055.nffdsp.rst) 
tavewt.2085 <- mean (canesm2.2085.tavewt.rst, ccsm4.2085.tavewt.rst, hadgem.2085.tavewt.rst) # take average of three climate models
tavewt.2085 <- tavewt.2085 / 10 # divide by ten for temp covariates
paswt.2085 <- mean (canesm2.2085.paswt.rst, ccsm4.2085.paswt.rst, hadgem.2085.paswt.rst) 
nffdsp.2085 <- mean (canesm2.2085.nffdsp.rst, ccsm4.2085.nffdsp.rst, hadgem.2085.nffdsp.rst) 
rm (canesm2.2025.tavewt.rst, ccsm4.2025.tavewt.rst, hadgem.2025.tavewt.rst,
    canesm2.2025.paswt.rst, ccsm4.2025.paswt.rst, hadgem.2025.paswt.rst,
    canesm2.2025.nffdsp.rst, ccsm4.2025.nffdsp.rst, hadgem.2025.nffdsp.rst,
    canesm2.2055.tavewt.rst, ccsm4.2055.tavewt.rst, hadgem.2055.tavewt.rst,
    canesm2.2055.paswt.rst, ccsm4.2055.paswt.rst, hadgem.2055.paswt.rst,
    canesm2.2055.nffdsp.rst, ccsm4.2055.nffdsp.rst, hadgem.2055.nffdsp.rst,
    canesm2.2085.tavewt.rst, ccsm4.2085.tavewt.rst, hadgem.2085.tavewt.rst,
    canesm2.2085.paswt.rst, ccsm4.2085.paswt.rst, hadgem.2085.paswt.rst,
    canesm2.2085.nffdsp.rst, ccsm4.2085.nffdsp.rst, hadgem.2085.nffdsp.rst)

#================================================
# Load and rasterize current BEC data
#===============================================
# bec.current <- readOGR ("bec\\BEC_current\\BEC_BIOGEOCLIMATIC_POLY\\BEC_POLY_polygon.shp", 
#                          stringsAsFactors = T) # proj4string (bec.current)
# bec.current.prj <- spTransform (bec.current, CRS = ras.crs) 
# table.bec.curr.factors <- data.frame (levels (bec.current.prj@data$ZONE))
# table.bec.curr.factors$factor.num <- c (1:16)
# empty.raster <- raster (nrows = 1404, ncols = 3001, xmn = -139.0632,  
#                        xmx = -114.055, ymn = 48.30073, ymx = 60.00068, 
#                        res = 0.0083333, crs = ras.crs)
# bec.current.prj@data$raster <- as.numeric (bec.current.prj@data$ZONE)
# becCurr.rst <- rasterize (bec.current.prj, empty.raster, field = "raster", fun = 'first',
#                           update = TRUE, updateValue = "all")
# writeRaster (becCurr.rst, filename = "bec\\BEC_current\\raster\\becCurrRas", format = "raster")
becCurr.rst <- raster ("bec\\BEC_current\\raster\\becCurrRas")
# plot (becCurr.rst)

#=============================================================
# Make a bunch of categorical raaster data out of BEC rasters
#============================================================
becCurr.rst.bafa <- reclassify (becCurr.rst, c (1,1,1,  2,16,0), include.lowest = T, right = NA)
becCurr.rst.bg <- reclassify (becCurr.rst, c (0,1,0,  2,2,1,  3,16,0), include.lowest = T, right = NA)
becCurr.rst.bwbs <- reclassify (becCurr.rst, c (0,2,0,  3,3,1,  4,16,0), include.lowest = T, right = NA)
becCurr.rst.cdf <- reclassify (becCurr.rst, c (0,3,0,  4,4,1,  5,16,0), include.lowest = T, right = NA)
becCurr.rst.cma <- reclassify (becCurr.rst, c (0,4,0,  5,5,1,  6,16,0), include.lowest = T, right = NA)
becCurr.rst.cwh <- reclassify (becCurr.rst, c (0,5,0,  6,6,1,  7,16,0), include.lowest = T, right = NA)
becCurr.rst.essf <- reclassify (becCurr.rst, c (0,6,0,  7,7,1,  8,16,0), include.lowest = T, right = NA)
becCurr.rst.ich <- reclassify (becCurr.rst, c (0,7,0,  8,8,1,  9,16,0), include.lowest = T, right = NA)
becCurr.rst.idf <- reclassify (becCurr.rst, c (0,8,0,  9,9,1,  10,16,0), include.lowest = T, right = NA)
becCurr.rst.ima <- reclassify (becCurr.rst, c (0,9,0,  10,10,1, 11,16,0), include.lowest = T, right = NA)
becCurr.rst.mh <- reclassify (becCurr.rst, c (0,10,0,  11,11,1,  12,16,0), include.lowest = T, right = NA)
becCurr.rst.ms <- reclassify (becCurr.rst, c (0,11,0,  12,12,1,  13,16,0), include.lowest = T, right = NA)
becCurr.rst.pp <- reclassify (becCurr.rst, c (0,12,0,  13,13,1,  14,16,0), include.lowest = T, right = NA)
becCurr.rst.sbps <- reclassify (becCurr.rst, c (0,13,0,  14,14,1,  15,16,0), include.lowest = T, right = NA)
becCurr.rst.sbs <- reclassify (becCurr.rst, c (0,14,0,  15,15,1,  16,16,0), include.lowest = T, right = NA)
becCurr.rst.swb <- reclassify (becCurr.rst, c (0,15,0,  16,16,1), include.lowest = T, right = NA)

bec2020.rst.bafa <- reclassify (bec2020.rst, c (0,0,0,  1,1,1, 0,48,0,  49,49,1,  50,195,0), include.lowest = T, right = NA)
bec2020.rst.bg <- reclassify (bec2020.rst, c (0,116,0,  117,118,1,  119,121,0,  122,122,1,
                                              123,183,0,  184,185,1,  186,195,0), include.lowest = T, right = NA)
bec2020.rst.bwbs <- reclassify (bec2020.rst, c (0,3,0,  4,4,1,  5,7,0,  8,8,1, 9,12,0,  13,13,1,  
                                                14,43,0,  44,47,1, 48,48,0,  49,49,1,  50,195,0), 
                                include.lowest = T, right = NA)
bec2020.rst.cdf <- reclassify (bec2020.rst, c (0,170,0,  171,171,1,  172,195,0), 
                                include.lowest = T, right = NA)
bec2020.rst.cma <- reclassify (bec2020.rst, c (1,1,1,  2,34,0,  35,35,1,  36,195,0), 
                               include.lowest = T, right = NA)
bec2020.rst.cwh <- reclassify (bec2020.rst, c (1,13,0,  14,14,1,  15,27,0,  28,29,1,  30,31,0,
                                               32,34,1,  35,36,0,  37,41,1,  42,64,0,  65,65,1,
                                               66,70,0,  71,71,1,  72,74,0,  75,75,1,  76,84,0,
                                               85,85,1,  86,104,0,  105,105,1,  106,151,0, 152,152,1,
                                               153,166,0,  167,167,1,  168,168,0, 169,170,1, 171,195,0), 
                               include.lowest = T, right = NA)
memory.limit (size = 50000)
bec2020.rst.essf <- reclassify (bec2020.rst, c (1,5,0,  6,6,1,  7,9,0,  10,10,1,  11,16,0,
                                               17,17,1,  18,20,0,  21,22,1,  23,26,0,  27,27,1,
                                               28,29,0,  30,30,1,  31,50,0,  51,55,1,  56,57,0,
                                               58,58,1,  59,62,0,  63,63,1,  64,67,0,  68,70,1,
                                               71,72,0,  73,73,1,  74,75,0,  76,76,1,  77,77,0,
                                               78,78,1,  79,100,0,  101,101,1, 102,103,0,  104,104,1,
                                               105,105,0,  106,107,1,  108,114,0,  115,115,1,
                                               116,119,0, 120,120,1, 121,124,0, 125,125,1, 126,128,0,
                                               129,130,1,  131,131,0,  132,132,1, 133,133,0, 134,135,1,
                                               136,139,0, 140,140,1, 141,141,0, 142,142,1, 143,145,0,
                                               146,146,1, 147,147,0, 148,149,1, 150,152,0, 153,153,1,
                                               154,155,0, 156,156,1, 157,157,0, 158,159,1, 160,160,0,
                                               161,163,1, 164,164,0, 165,165,1, 166,167,0, 168,168,1,
                                               169,171,0, 172,172,1, 173,174,0, 175,176,1, 177,178,0,
                                               179,179,1, 180,180,0, 181,181,1, 182,182,0, 183,183,1,
                                               184,185,0, 186,187,1, 188,188,0, 189,189,1, 190,191,0,
                                               192,193,1, 194,195,0), 
                               include.lowest = T, right = NA)
bec2020.rst.ich <- reclassify (bec2020.rst, c (1,14,0,  15,15,1,  16,23,0,  24,26,1,  27,59,0,
                                                60,60,1,  61,63,0,  64,64,1,  65,66,0,  67,67,1,
                                                68,73,0,  74,74,1,  75,81,0,  82,83,1,  84,86,0,
                                                87,89,1,  90,92,0,  93,93,1,  94,125,0, 126,128,1,
                                                129,135,0,  136,136,1,  137,137,0,  138,138,1,  139,140,0,
                                                141,141,1,  142,146,0,  147,147,1, 148,179,0,  180,180,1,
                                                181,187,0,  188,188,1,  189,189,0,  190,190,1,
                                                191,193,0, 194,194,1, 195,195,0), 
                                include.lowest = T, right = NA)
bec2020.rst.idf <- reclassify (bec2020.rst, c (1,71,0,  72,72,1,  73,76,0,  77,77,1,  78,78,0,
                                               79,79,1,  80,94,0,  95,95,1,  96,96,0,  97,97,1,
                                               98,98,0,  99,100,1,  101,102,0,  103,103,1,  104,107,0,
                                               108,108,1,  109,110,0,  111,113,1,  114,115,0, 116,116,1,
                                               117,118,0,  119,119,1,  120,149,0,  150,150,1,  151,159,0,
                                               160,160,1,  161,173,0,  174,174,1, 175,177,0,  178,178,1,
                                               179,181,0,  182,182,1,  183,190,0,  191,191,1,
                                               192,195,0), 
                               include.lowest = T, right = NA)
bec2020.rst.ima <- reclassify (bec2020.rst, c (1,61,0,  62,62,1,  63,120,0,  121,121,1,
                                               122,195,0), 
                               include.lowest = T, right = NA)
bec2020.rst.mh <- reclassify (bec2020.rst, c (1,19,0,  20,20,1,  21,30,0,  31,31,1,
                                              32,35,0,  36,36,1,  37,41,0,  42,43,1,
                                              44,56,0,  57,57,1, 58,195,0), 
                               include.lowest = T, right = NA)
bec2020.rst.ms <- reclassify (bec2020.rst, c (1,97,0,  98,98,1,  99,108,0,  109,109,1,
                                              110,113,0,  114,114,1,  115,123,0,  124,124,1,
                                              125,132,0,  133,133,1,  134,136,0,
                                              137,137,1,  138,138,0,  139,139,1, 
                                              140,144,0,  145,145,1,  146,150,0,
                                              151,151,1,  152,153,0,  154,154,1,
                                              155,156,0,  157,157,1,  158,163,0,
                                              164,164,1,  165,165,0,  166,166,1,
                                              167,172,0,  173,173,1,  174,176,0,
                                              177,177,1,  178,195,0), 
                              include.lowest = T, right = NA)
bec2020.rst.pp <- reclassify (bec2020.rst, c (1,122,0,  123,123,1,  124,142,0,
                                              143,143,1, 144,154,0,  155,155,1,
                                              156,194,0, 195,195,1), 
                              include.lowest = T, right = NA)
bec2020.rst.sbps <- reclassify (bec2020.rst, c (1,91,0,  92,92,1,  93,93,0,
                                                94,94,1, 95,95,0,  96,96,1,
                                                97,101,0, 102,102,1,  103,195,0), 
                              include.lowest = T, right = NA)
bec2020.rst.sbs <- reclassify (bec2020.rst, c (1,6,0,  7,7,1,  8,10,0,
                                               11,11,1, 12,15,0,  16,16,1,
                                               17,17,0, 18,19,1,  20,22,0,
                                               23,23,1,  24,55,0, 56,56,1,
                                               57,58,0, 59,59,1, 60,60,0,
                                               61,61,1, 62,65,0, 66,66,1,
                                               67,79,0, 80,81,1, 82,83,0,
                                               84,84,1, 85,85,0, 86,86,1,
                                               87,89,0, 90,91,1, 92,109,0,
                                               110,110,1, 111,130,0, 131,131,1,
                                               132,143,0, 144,144,1, 145,195,0), 
                                include.lowest = T, right = NA)
bec2020.rst.swb <- reclassify (bec2020.rst, c (1,2,0,  3,3,1,  4,4,0,
                                               5,5,1, 6,8,0,  9,9,1,
                                               10,11,0, 12,12,1,  13,47,0,
                                               48,48,1,  49,195,0), 
                               include.lowest = T, right = NA)



bec2050.rst.bafa <- reclassify (bec2050.rst, c (0,2,0,  3,3,1, 4,30,0,  
                                                31,31,1,  32,182,0), include.lowest = T, right = NA)
bec2050.rst.bg <- reclassify (bec2050.rst, c (0,123,0,  124,124,1,  125,125,0,  126,126,1,
                                              127,127,0,  128,128,1,  129,175,0,  176,176,1,
                                              177,182,0), include.lowest = T, right = NA)

bec2050.rst.bwbs <- reclassify (bec2050.rst, c (0,3,0,  4,4,1,  5,8,0,  9,9,1, 10,21,0,  22,22,1,  
                                                23,37,0,  38,38,1, 39,57,0,  58,60,1,  61,61,0,
                                                62,62,1,  63,182,0), 
                                include.lowest = T, right = NA)
bec2050.rst.cdf <- reclassify (bec2050.rst, c (0,168,0,  169,169,1,  170,182,0), 
                               include.lowest = T, right = NA)
bec2050.rst.cma <- reclassify (bec2050.rst, c (1,1,1,  2,48,0,  49,49,1,  50,182,0), 
                               include.lowest = T, right = NA)
bec2050.rst.cwh <- reclassify (bec2050.rst, c (1,16,0,  17,17,1,  18,31,0,  32,32,1,  33,34,0,
                                               35,36,1,  37,39,0,  40,44,1,  45,46,0,  47,47,1,
                                               48,49,0,  50,54,1,  55,55,0,  56,56,1,  57,85,0,
                                               86,86,1,  87,118,0,  119,119,1,  120,170,0, 171,172,1,
                                               173,182,0), 
                               include.lowest = T, right = NA)
bec2050.rst.essf <- reclassify (bec2050.rst, c (1,5,0,  6,6,1,  7,10,0,  11,12,1,  13,15,0,
                                                16,16,1,  17,17,0,  18,19,1,  20,26,0,  27,27,1,
                                                28,29,0,  30,30,1,  31,45,0,  46,46,1,  47,60,0,
                                                61,61,1,  62,62,0,  63,63,1,  64,64,0,  65,66,1,
                                                67,67,0,  68,68,1,  69,71,0,  72,73,1,  74,74,0,
                                                75,76,1,  77,78,0,  79,79,1, 80,84,0,  85,85,1,
                                                86,90,0,  91,91,1,  92,92,0,  93,93,1,
                                                94,113,0, 114,114,1, 115,115,0, 116,116,1, 117,120,0,
                                                121,121,1,  122,122,0,  123,123,1, 124,128,0, 129,130,1,
                                                131,133,0, 134,135,1, 136,140,0, 141,141,1, 142,142,0,
                                                143,144,1, 145,145,0, 146,148,1, 149,150,0, 151,153,1,
                                                154,155,0, 156,156,1, 157,157,0, 158,160,1, 161,162,0,
                                                163,167,1, 168,169,0, 170,170,1, 171,174,0, 175,175,1,
                                                176,177,0, 178,179,1, 180,181,0, 182,182,1), 
                                include.lowest = T, right = NA)
bec2050.rst.ich <- reclassify (bec2050.rst, c (1,6,0,  7,7,1,  8,20,0,  21,21,1,  22,25,0,
                                               26,26,1,  27,27,0,  28,28,1,  29,36,0,  37,37,1,
                                               38,66,0,  67,67,1,  68,70,0,  71,71,1,  72,73,0,
                                               74,74,1,  75,76,0,  77,77,1,  78,80,0,  81,81,1,
                                               82,86,0,  87,87,1,  88,100,0,  101,101,1,  102,114,0,
                                               115,115,1,  116,131,0,  132,133,1, 134,135,0,  136,137,1,
                                               138,141,0,  142,142,1,  143,148,0,  149,150,1,
                                               151,153,0,  154,154,1, 155,156,0,  157,157,1,  158,176,0,
                                               177,177,1,  178,182,0), 
                               include.lowest = T, right = NA)
bec2050.rst.idf <- reclassify (bec2050.rst, c (1,79,0,  80,80,1,  81,83,0,  84,84,1,  85,87,0,
                                               88,90,1,  91,93,0,  94,96,1,  97,99,0,  100,100,1,
                                               101,102,0,  103,103,1,  104,108,0,  109,111,1,  112,112,0,
                                               113,113,1,  114,119,0,  120,120,1,  121,172,0, 173,173,1,
                                               174,179,0,  180,181,1,  182,182,0), 
                               include.lowest = T, right = NA)
bec2050.rst.ima <- reclassify (bec2050.rst, c (1,13,0,  14,14,1,  15,137,0,  138,138,1,
                                               139,182,0), 
                               include.lowest = T, right = NA)
bec2050.rst.mh <- reclassify (bec2050.rst, c (1,19,0,  20,20,1,  21,28,0,  29,29,1,
                                              30,38,0,  39,39,1,  40,47,0,  48,48,1,
                                              49,54,0,  55,55,1,  56,56,0,  57,57,1, 58,182,0), 
                              include.lowest = T, right = NA)
bec2050.rst.ms <- reclassify (bec2050.rst, c (1,68,0,  69,70,1,  71,91,0,  92,92,1,
                                              93,105,0,  106,106,1,  107,107,0,  108,108,1,
                                              109,116,0,  117,117,1,  118,126,0,
                                              127,127,1,  128,130,0,  131,131,1, 
                                              132,138,0,  139,139,1,  140,154,0,
                                              155,155,1,  156,160,0,  161,162,1,
                                              163,167,0,  168,168,1,  169,173,0,
                                              174,174,1,  175,182,0), 
                              include.lowest = T, right = NA)
bec2050.rst.pp <- reclassify (bec2050.rst, c (1,117,0,  118,118,1,  119,121,0,
                                              122,122,1, 123,124,0,  125,125,1,
                                              126,182,0), 
                              include.lowest = T, right = NA)
bec2050.rst.sbps <- reclassify (bec2050.rst, c (1,103,0,  104,105,1,  106,106,0,
                                                107,107,1, 108,111,0,  112,112,1,
                                                113,182,0), 
                                include.lowest = T, right = NA)
bec2050.rst.sbs <- reclassify (bec2050.rst, c (1,7,0,  8,8,1,  9,12,0,
                                               13,13,1, 14,22,0, 23,25,1,
                                               26,32,0, 33,34,1, 35,44,0,
                                               45,45,1, 46,77,0, 78,78,1,
                                               79,81,0, 82,83,1, 84,96,0,
                                               97,99,1, 100,101,0, 102,102,1,
                                               103,139,0, 140,140,1, 141,144,0,
                                               145,145,1, 146,182,0), 
                               include.lowest = T, right = NA)
bec2050.rst.swb <- reclassify (bec2050.rst, c (1,1,0,  2,2,1,  3,4,0,
                                               5,5,1, 6,9,0,  10,10,1,
                                               11,14,0, 15,15,1,  16,63,0,
                                               64,64,1,  65,182,0), 
                               include.lowest = T, right = NA)


bec2080.rst.bafa <- reclassify (bec2080.rst, c (0,2,0,  3,3,1, 4,29,0,  
                                                30,30,1,  31,171,0), include.lowest = T, right = NA)
bec2080.rst.bg <- reclassify (bec2080.rst, c (0,126,0,  127,128,1,  129,130,0,  131,131,1,
                                              132,164,0,  165,165,1,  166,171,0), include.lowest = T, right = NA)
bec2080.rst.bwbs <- reclassify (bec2080.rst, c (0,4,0,  5,5,1,  6,13,0,  14,14,1, 15,56,0,  57,58,1,  
                                                59,62,0,  63,65,1, 66,67,0,  68,68,1,  69,171,0), 
                                include.lowest = T, right = NA)
bec2080.rst.cdf <- reclassify (bec2080.rst, c (0,45,0,  46,46,1,  47,171,0), 
                               include.lowest = T, right = NA)
bec2080.rst.cma <- reclassify (bec2080.rst, c (1,1,1,  2,90,0,  91,91,1,  92,171,0), 
                               include.lowest = T, right = NA)
bec2080.rst.cwh <- reclassify (bec2080.rst, c (1,16,0,  17,18,1,  19,32,0,  33,33,1,  34,37,0,
                                               38,38,1,  39,41,0,  42,42,1,  43,44,0,  45,45,1,
                                               46,48,0,  49,52,1,  53,53,0,  54,56,1,  57,61,0,
                                               62,62,1,  63,94,0,  95,95,1,  96,125,0, 126,126,1,
                                               127,153,0,  154,154,1,  155,161,0,  162,162,1,
                                               163,172,0), 
                               include.lowest = T, right = NA)
bec2080.rst.essf <- reclassify (bec2080.rst, c (1,6,0,  7,7,1,  8,8,0,  9,9,1,  10,15,0,
                                                16,16,1,  17,22,0,  23,23,1,  24,24,0,  25,26,1,
                                                27,31,0,  32,32,1,  33,36,0,  37,37,1,  38,38,0,
                                                39,39,1,  40,42,0,  43,44,1,  45,65,0,  66,66,1,
                                                67,71,0,  72,73,1,  74,74,0,  75,75,1,  76,76,0,
                                                77,79,1,  80,81,0,  82,82,1, 83,84,0,  85,86,1,
                                                87,91,0,  92,92,1,  93,95,0,  96,96,1,
                                                97,100,0, 101,102,1, 103,119,0, 120,120,1, 121,122,0,
                                                123,123,1,  124,132,0,  133,137,1, 138,139,0, 140,142,1,
                                                143,144,0, 145,146,1, 147,147,0, 148,151,1, 152,152,0,
                                                153,153,1, 154,155,0, 156,156,1, 157,157,0, 158,159,1,
                                                160,160,0, 161,161,1, 162,162,0, 163,163,1, 164,165,0,
                                                166,167,1, 168,172,0), 
                                include.lowest = T, right = NA)
bec2080.rst.ich <- reclassify (bec2080.rst, c (1,5,0,  6,6,1,  7,9,0,  10,11,1,  12,14,0,
                                               15,15,1,  16,23,0,  24,24,1,  25,27,0,  28,28,1,
                                               29,30,0,  31,31,1,  32,35,0,  36,36,1,  37,59,0,
                                               60,60,1,  61,79,0,  80,80,1,  81,92,0,  93,93,1,
                                               94,107,0,  108,108,1,  109,111,0,  112,113,1,  114,138,0,
                                               139,139,1,  140,142,0,  143,144,1, 145,146,0,  147,147,1,
                                               148,159,0,  160,160,1,  161,172,0), 
                               include.lowest = T, right = NA)
bec2080.rst.idf <- reclassify (bec2080.rst, c (1,46,0,  47,47,1,  48,52,0,  53,53,1,  54,58,0,
                                               59,59,1, 60,68,0,  69,69,1,  70,80,0,  81,81,1,
                                               82,83,0, 84,84,1,  85,87,0,  88,88,1,  89,97,0,
                                               98,100,1,  101,102,0,  103,104,1,  105,109,0, 110,110,1,
                                               111,113,0,  114,114,1,  115,121,0,  122,122,1,
                                               123,124,0,  125,125,1,  126,151,0,  152,152,1,
                                               153,163,0,  164,164,1,  165,167,0,  168,169,1,
                                               170,172,0), 
                               include.lowest = T, right = NA)
bec2080.rst.ima <- reclassify (bec2080.rst, c (1,18,0,  19,19,1,  20,137,0,  138,138,1,
                                               139,172,0), 
                               include.lowest = T, right = NA)
bec2080.rst.mh <- reclassify (bec2080.rst, c (1,3,0,  4,4,1,  5,34,0,  35,35,1,
                                              36,47,0,  48,48,1,  49,60,0,  61,61,1,
                                              62,172,0), 
                              include.lowest = T, right = NA)
bec2080.rst.ms <- reclassify (bec2080.rst, c (1,70,0,  71,71,1,  72,73,0,  74,74,1,
                                              75,82,0, 83,83,1,  84,114,0, 115,115,1,
                                              116,116,0,  117,117,1,  118,118,0,
                                              119,119,1,  120,120,0,  121,121,1, 
                                              122,123,0,  124,124,1,  125,129,0,
                                              130,130,1,  131,131,0,  132,132,1,
                                              133,154,0,  155,155,1,  156,156,0,
                                              157,157,1,  158,170,0, 171,171,1, 172,172,0), 
                              include.lowest = T, right = NA)
bec2080.rst.pp <- reclassify (bec2080.rst, c (1,96,0,  97,97,1,  98,117,0,
                                              118,118,1, 119,128,0,  129,129,1,
                                              130,172,0), 
                              include.lowest = T, right = NA)
bec2080.rst.sbps <- reclassify (bec2080.rst, c (1,105,0,  106,106,1,  107,108,0,
                                                109,109,1, 110,110,0,  111,111,1,
                                                112,115,0,  116,116,1,  117,172,0), 
                                include.lowest = T, right = NA)
bec2080.rst.sbs <- reclassify (bec2080.rst, c (1,11,0,  12,13,1, 14,19,0,
                                               20,20,1, 21,26,0, 27,27,1,
                                               28,28,0, 29,29,1, 30,33,0,
                                               34,34,1, 35,39,0, 40,41,1,
                                               42,66,0, 67,67,1, 68,75,0,
                                               76,76,1, 77,86,0, 87,87,1,
                                               88,88,0, 89,90,1, 91,93,0,
                                               94,94,1, 95,104,0, 105,105,1, 106,106,0, 107,107,1,
                                               108,172,0), 
                               include.lowest = T, right = NA)
bec2080.rst.swb <- reclassify (bec2080.rst, c (1,1,0,  2,2,1,  3,7,0,
                                               8,8,1, 9,20,0,  21,22,1,
                                               23,69,0, 70,70,1,  71,172,0), 
                               include.lowest = T, right = NA)
# plot (bec2080.rst.swb)
# dplyr::filter (table.bec2080.factors, ZONE == "SWB")
# unique (table.bec2080.factors$ZONE)

#=================================================================
# Adjustments for standardizing the raster data
#================================================================
###########
# BOREAL #
#########
ras.st.nffd.1990.boreal <- (clim.1961.1990.nffdsp.rst - mean (data.boreal$nffd.sp.2010)) /
                            sd (data.boreal$nffd.sp.2010)
ras.st.nffd.2010.boreal <- (clim.1981.2010.nffdsp.rst - mean (data.boreal$nffd.sp.2010)) /
                            sd (data.boreal$nffd.sp.2010)
ras.st.nffd.2025.boreal <- (nffdsp.2025 - mean (data.boreal$nffd.sp.2010)) /
                            sd (data.boreal$nffd.sp.2010)
ras.st.nffd.2055.boreal <- (nffdsp.2055 - mean (data.boreal$nffd.sp.2010)) /
                            sd (data.boreal$nffd.sp.2010)
ras.st.nffd.2085.boreal <- (nffdsp.2085 - mean (data.boreal$nffd.sp.2010)) /
                            sd (data.boreal$nffd.sp.2010)

ras.st.pas.1990.boreal <- (clim.1961.1990.paswt.rst - mean (data.boreal$pas.wt.2010)) /
                            sd (data.boreal$pas.wt.2010)
ras.st.pas.2010.boreal <- (clim.1981.2010.paswt.rst - mean (data.boreal$pas.wt.2010)) /
                            sd (data.boreal$pas.wt.2010)
ras.st.pas.2025.boreal <- (paswt.2025 - mean (data.boreal$pas.wt.2010)) /
                            sd (data.boreal$pas.wt.2010)
ras.st.pas.2055.boreal <- (paswt.2055 - mean (data.boreal$pas.wt.2010)) /
                            sd (data.boreal$pas.wt.2010)
ras.st.pas.2085.boreal <- (paswt.2085 - mean (data.boreal$pas.wt.2010)) /
                            sd (data.boreal$pas.wt.2010)

ras.st.tave.1990.boreal <- (clim.1961.1990.tavewt.rst - mean (data.boreal$tave.wt.2010)) /
                            sd (data.boreal$tave.wt.2010)
ras.st.tave.2010.boreal <- (clim.1981.2010.tavewt.rst - mean (data.boreal$tave.wt.2010)) /
                            sd (data.boreal$tave.wt.2010)
ras.st.tave.2025.boreal <- (tavewt.2025 - mean (data.boreal$tave.wt.2010)) /
                            sd (data.boreal$tave.wt.2010)
ras.st.tave.2055.boreal <- (tavewt.2055 - mean (data.boreal$tave.wt.2010)) /
                           sd (data.boreal$tave.wt.2010)
ras.st.tave.2085.boreal <- (tavewt.2085 - mean (data.boreal$tave.wt.2010)) /
                           sd (data.boreal$tave.wt.2010)

ras.st.roads.boreal <- (roads.27k.rst - mean (data.boreal$road.dns.27k)) /
                        sd (data.boreal$road.dns.27k)

#############
# MOUNTAIN #
###########
ras.st.nffd.1990.mount <- (clim.1961.1990.nffdsp.rst - mean (data.mount$nffd.sp.2010)) /
  sd (data.mount$nffd.sp.2010)
ras.st.nffd.2010.mount <- (clim.1981.2010.nffdsp.rst - mean (data.mount$nffd.sp.2010)) /
  sd (data.mount$nffd.sp.2010)
ras.st.nffd.2025.mount <- (nffdsp.2025 - mean (data.mount$nffd.sp.2010)) /
  sd (data.mount$nffd.sp.2010)
ras.st.nffd.2055.mount <- (nffdsp.2055 - mean (data.mount$nffd.sp.2010)) /
  sd (data.mount$nffd.sp.2010)
ras.st.nffd.2085.mount <- (nffdsp.2085 - mean (data.mount$nffd.sp.2010)) /
  sd (data.mount$nffd.sp.2010)

ras.st.pas.1990.mount <- (clim.1961.1990.paswt.rst - mean (data.mount$pas.wt.2010)) /
  sd (data.mount$pas.wt.2010)
ras.st.pas.2010.mount <- (clim.1981.2010.paswt.rst - mean (data.mount$pas.wt.2010)) /
  sd (data.mount$pas.wt.2010)
ras.st.pas.2025.mount <- (paswt.2025 - mean (data.mount$pas.wt.2010)) /
  sd (data.mount$pas.wt.2010)
ras.st.pas.2055.mount <- (paswt.2055 - mean (data.mount$pas.wt.2010)) /
  sd (data.mount$pas.wt.2010)
ras.st.pas.2085.mount <- (paswt.2085 - mean (data.mount$pas.wt.2010)) /
  sd (data.mount$pas.wt.2010)

ras.st.tave.1990.mount <- (clim.1961.1990.tavewt.rst - mean (data.mount$tave.wt.2010)) /
  sd (data.mount$tave.wt.2010)
ras.st.tave.2010.mount <- (clim.1981.2010.tavewt.rst - mean (data.mount$tave.wt.2010)) /
  sd (data.mount$tave.wt.2010)
ras.st.tave.2025.mount <- (tavewt.2025 - mean (data.mount$tave.wt.2010)) /
  sd (data.mount$tave.wt.2010)
ras.st.tave.2055.mount <- (tavewt.2055 - mean (data.mount$tave.wt.2010)) /
  sd (data.mount$tave.wt.2010)
ras.st.tave.2085.mount <- (tavewt.2085 - mean (data.mount$tave.wt.2010)) /
  sd (data.mount$tave.wt.2010)

ras.st.roads.mount <- (roads.27k.rst - mean (data.mount$road.dns.27k)) /
  sd (data.mount$road.dns.27k)

##########
# NORTH #
########
ras.st.nffd.1990.north <- (clim.1961.1990.nffdsp.rst - mean (data.north$nffd.sp.2010)) /
  sd (data.north$nffd.sp.2010)
ras.st.nffd.2010.north <- (clim.1981.2010.nffdsp.rst - mean (data.north$nffd.sp.2010)) /
  sd (data.north$nffd.sp.2010)
ras.st.nffd.2025.north <- (nffdsp.2025 - mean (data.north$nffd.sp.2010)) /
  sd (data.north$nffd.sp.2010)
ras.st.nffd.2055.north <- (nffdsp.2055 - mean (data.north$nffd.sp.2010)) /
  sd (data.north$nffd.sp.2010)
ras.st.nffd.2085.north <- (nffdsp.2085 - mean (data.north$nffd.sp.2010)) /
  sd (data.north$nffd.sp.2010)

ras.st.pas.1990.north <- (clim.1961.1990.paswt.rst - mean (data.north$pas.wt.2010)) /
  sd (data.north$pas.wt.2010)
ras.st.pas.2010.north <- (clim.1981.2010.paswt.rst - mean (data.north$pas.wt.2010)) /
  sd (data.north$pas.wt.2010)
ras.st.pas.2025.north <- (paswt.2025 - mean (data.north$pas.wt.2010)) /
  sd (data.north$pas.wt.2010)
ras.st.pas.2055.north <- (paswt.2055 - mean (data.north$pas.wt.2010)) /
  sd (data.north$pas.wt.2010)
ras.st.pas.2085.north <- (paswt.2085 - mean (data.north$pas.wt.2010)) /
  sd (data.north$pas.wt.2010)

ras.st.tave.1990.north <- (clim.1961.1990.tavewt.rst - mean (data.north$tave.wt.2010)) /
  sd (data.north$tave.wt.2010)
ras.st.tave.2010.north <- (clim.1981.2010.tavewt.rst - mean (data.north$tave.wt.2010)) /
  sd (data.north$tave.wt.2010)
ras.st.tave.2025.north <- (tavewt.2025 - mean (data.north$tave.wt.2010)) /
  sd (data.north$tave.wt.2010)
ras.st.tave.2055.north <- (tavewt.2055 - mean (data.north$tave.wt.2010)) /
  sd (data.north$tave.wt.2010)
ras.st.tave.2085.north <- (tavewt.2085 - mean (data.north$tave.wt.2010)) /
  sd (data.north$tave.wt.2010)

ras.st.roads.north <- (roads.27k.rst - mean (data.north$road.dns.27k)) /
  sd (data.north$road.dns.27k)

#=============================================================
# Raster stacks for calculating model predictions
#============================================================

###########
# BOREAL #
##########
ras.crs <- proj4string (bec2020.rst)
caribou.boreal.sa <- spTransform (caribou.boreal.sa, CRS = ras.crs)
caribou.range.boreal <- spTransform (caribou.range.boreal, CRS = ras.crs)
summary (model.boreal10)
# 1990 #
ras.st.nffd.1990.boreal <- raster::crop (ras.st.nffd.1990.boreal, caribou.boreal.sa)
ras.st.pas.1990.boreal <- raster::crop (ras.st.pas.1990.boreal, caribou.boreal.sa)
ras.st.tave.1990.boreal <- raster::crop (ras.st.tave.1990.boreal, caribou.boreal.sa)
# becCurr.rst.swb.boreal <- raster::crop (becCurr.rst.swb, caribou.boreal.sa) # left out SWB BEC because very large SE
ras.st.roads.boreal <- raster::crop (ras.st.roads.boreal, caribou.boreal.sa)
# roads extent data is very slightly different (not sure why, the resolutioon is the same) so need 
# resample the data
ras.st.roads.boreal <- raster::resample (ras.st.roads.boreal, ras.st.tave.1990.boreal, method = "ngb")

predict.map.boreal.1990 <- (exp (0.88815 + (0.79681 * ras.st.tave.1990.boreal) +
                                (-0.20956 * ras.st.nffd.1990.boreal) + 
                                (0.02847 * ras.st.pas.1990.boreal) +
                                (-0.47809 * ras.st.roads.boreal) +
                                (-0.40638 * ras.st.tave.1990.boreal * ras.st.pas.1990.boreal) +
                                (0.15057 * ras.st.tave.1990.boreal * ras.st.nffd.1990.boreal) +
                                (-0.61681 * ras.st.tave.1990.boreal * ras.st.roads.boreal))) / 
                           (1 + exp (0.88815 + (0.79681 * ras.st.tave.1990.boreal) +
                                       (-0.20956 * ras.st.nffd.1990.boreal) + 
                                       (0.02847 * ras.st.pas.1990.boreal) +
                                       (-0.47809 * ras.st.roads.boreal) +
                                       (-0.40638 * ras.st.tave.1990.boreal * ras.st.pas.1990.boreal) +
                                       (0.15057 * ras.st.tave.1990.boreal * ras.st.nffd.1990.boreal) +
                                       (-0.61681 * ras.st.tave.1990.boreal * ras.st.roads.boreal)))
writeRaster (predict.map.boreal.1990, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\boreal\\predboreal1990", 
             format = "raster")
writeRaster (predict.map.boreal.1990, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\boreal\\predboreal1990tif", 
             format = "GTiff")

# 2010 #
ras.st.nffd.2010.boreal <- raster::crop (ras.st.nffd.2010.boreal, caribou.boreal.sa)
ras.st.pas.2010.boreal <- raster::crop (ras.st.pas.2010.boreal, caribou.boreal.sa)
ras.st.tave.2010.boreal <- raster::crop (ras.st.tave.2010.boreal, caribou.boreal.sa)
# becCurr.rst.swb.boreal <- raster::crop (becCurr.rst.swb, caribou.boreal.sa) # left out SWB BEC because very large SE
ras.st.roads.boreal <- raster::crop (ras.st.roads.boreal, caribou.boreal.sa)
# roads extent data is very slightly different (not sure why, the resolutioon is the same) so need 
# resample the data
ras.st.roads.boreal <- raster::resample (ras.st.roads.boreal, ras.st.tave.2010.boreal, method = "ngb")
predict.map.boreal.2010 <- (exp (0.88815 + (0.79681 * ras.st.tave.2010.boreal) +
                                   (-0.20956 * ras.st.nffd.2010.boreal) + 
                                   (0.02847 * ras.st.pas.2010.boreal) +
                                   (-0.47809 * ras.st.roads.boreal) +
                                   (-0.40638 * ras.st.tave.2010.boreal * ras.st.pas.2010.boreal) +
                                   (0.15057 * ras.st.tave.2010.boreal * ras.st.nffd.2010.boreal) +
                                   (-0.61681 * ras.st.tave.2010.boreal * ras.st.roads.boreal))) / 
  (1 + exp (0.88815 + (0.79681 * ras.st.tave.2010.boreal) +
              (-0.20956 * ras.st.nffd.2010.boreal) + 
              (0.02847 * ras.st.pas.2010.boreal) +
              (-0.47809 * ras.st.roads.boreal) +
              (-0.40638 * ras.st.tave.2010.boreal * ras.st.pas.2010.boreal) +
              (0.15057 * ras.st.tave.2010.boreal * ras.st.nffd.2010.boreal) +
              (-0.61681 * ras.st.tave.2010.boreal * ras.st.roads.boreal)))
writeRaster (predict.map.boreal.2010, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\boreal\\predboreal2010", 
             format = "raster")
writeRaster (predict.map.boreal.2010, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\boreal\\predboreal2010tif", 
             format = "GTiff")

# 2025 #
ras.st.nffd.2025.boreal <- raster::crop (ras.st.nffd.2025.boreal, caribou.boreal.sa)
ras.st.pas.2025.boreal <- raster::crop (ras.st.pas.2025.boreal, caribou.boreal.sa)
ras.st.tave.2025.boreal <- raster::crop (ras.st.tave.2025.boreal, caribou.boreal.sa)
# becCurr.rst.swb.boreal <- raster::crop (becCurr.rst.swb, caribou.boreal.sa) # left out SWB BEC because very large SE
ras.st.roads.boreal <- raster::crop (ras.st.roads.boreal, caribou.boreal.sa)
# roads extent data is very slightly different (not sure why, the resolutioon is the same) so need 
# resample the data
ras.st.roads.boreal <- raster::resample (ras.st.roads.boreal, ras.st.tave.2025.boreal, method = "ngb")
predict.map.boreal.2025 <- (exp (0.88815 + (0.79681 * ras.st.tave.2025.boreal) +
                                   (-0.20956 * ras.st.nffd.2025.boreal) + 
                                   (0.02847 * ras.st.pas.2025.boreal) +
                                   (-0.47809 * ras.st.roads.boreal) +
                                   (-0.40638 * ras.st.tave.2025.boreal * ras.st.pas.2025.boreal) +
                                   (0.15057 * ras.st.tave.2025.boreal * ras.st.nffd.2025.boreal) +
                                   (-0.61681 * ras.st.tave.2025.boreal * ras.st.roads.boreal))) / 
  (1 + exp (0.88815 + (0.79681 * ras.st.tave.2025.boreal) +
              (-0.20956 * ras.st.nffd.2025.boreal) + 
              (0.02847 * ras.st.pas.2025.boreal) +
              (-0.47809 * ras.st.roads.boreal) +
              (-0.40638 * ras.st.tave.2025.boreal * ras.st.pas.2025.boreal) +
              (0.15057 * ras.st.tave.2025.boreal * ras.st.nffd.2025.boreal) +
              (-0.61681 * ras.st.tave.2025.boreal * ras.st.roads.boreal)))
writeRaster (predict.map.boreal.2025, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\boreal\\predboreal2025", 
             format = "raster")
writeRaster (predict.map.boreal.2025, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\boreal\\predboreal2025tif", 
             format = "GTiff")

# 2055 #
ras.st.nffd.2055.boreal <- raster::crop (ras.st.nffd.2055.boreal, caribou.boreal.sa)
ras.st.pas.2055.boreal <- raster::crop (ras.st.pas.2055.boreal, caribou.boreal.sa)
ras.st.tave.2055.boreal <- raster::crop (ras.st.tave.2055.boreal, caribou.boreal.sa)
# becCurr.rst.swb.boreal <- raster::crop (becCurr.rst.swb, caribou.boreal.sa) # left out SWB BEC because very large SE
ras.st.roads.boreal <- raster::crop (ras.st.roads.boreal, caribou.boreal.sa)
# roads extent data is very slightly different (not sure why, the resolutioon is the same) so need 
# resample the data
ras.st.roads.boreal <- raster::resample (ras.st.roads.boreal, ras.st.tave.2055.boreal, method = "ngb")
predict.map.boreal.2055 <- (exp (0.88815 + (0.79681 * ras.st.tave.2055.boreal) +
                                   (-0.20956 * ras.st.nffd.2055.boreal) + 
                                   (0.02847 * ras.st.pas.2055.boreal) +
                                   (-0.47809 * ras.st.roads.boreal) +
                                   (-0.40638 * ras.st.tave.2055.boreal * ras.st.pas.2055.boreal) +
                                   (0.15057 * ras.st.tave.2055.boreal * ras.st.nffd.2055.boreal) +
                                   (-0.61681 * ras.st.tave.2055.boreal * ras.st.roads.boreal))) / 
  (1 + exp (0.88815 + (0.79681 * ras.st.tave.2055.boreal) +
              (-0.20956 * ras.st.nffd.2055.boreal) + 
              (0.02847 * ras.st.pas.2055.boreal) +
              (-0.47809 * ras.st.roads.boreal) +
              (-0.40638 * ras.st.tave.2055.boreal * ras.st.pas.2055.boreal) +
              (0.15057 * ras.st.tave.2055.boreal * ras.st.nffd.2055.boreal) +
              (-0.61681 * ras.st.tave.2055.boreal * ras.st.roads.boreal)))
writeRaster (predict.map.boreal.2055, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\boreal\\predboreal2055", 
             format = "raster")
writeRaster (predict.map.boreal.2055, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\boreal\\predboreal2055tif", 
             format = "GTiff")

# 2085 #
ras.st.nffd.2085.boreal <- raster::crop (ras.st.nffd.2085.boreal, caribou.boreal.sa)
ras.st.pas.2085.boreal <- raster::crop (ras.st.pas.2085.boreal, caribou.boreal.sa)
ras.st.tave.2085.boreal <- raster::crop (ras.st.tave.2085.boreal, caribou.boreal.sa)
# becCurr.rst.swb.boreal <- raster::crop (becCurr.rst.swb, caribou.boreal.sa) # left out SWB BEC because very large SE
ras.st.roads.boreal <- raster::crop (ras.st.roads.boreal, caribou.boreal.sa)
# roads extent data is very slightly different (not sure why, the resolutioon is the same) so need 
# resample the data
ras.st.roads.boreal <- raster::resample (ras.st.roads.boreal, ras.st.tave.2085.boreal, method = "ngb")
predict.map.boreal.2085 <- (exp (0.88815 + (0.79681 * ras.st.tave.2085.boreal) +
                                   (-0.20956 * ras.st.nffd.2085.boreal) + 
                                   (0.02847 * ras.st.pas.2085.boreal) +
                                   (-0.47809 * ras.st.roads.boreal) +
                                   (-0.40638 * ras.st.tave.2085.boreal * ras.st.pas.2085.boreal) +
                                   (0.15057 * ras.st.tave.2085.boreal * ras.st.nffd.2085.boreal) +
                                   (-0.61681 * ras.st.tave.2085.boreal * ras.st.roads.boreal))) / 
  (1 + exp (0.88815 + (0.79681 * ras.st.tave.2085.boreal) +
              (-0.20956 * ras.st.nffd.2085.boreal) + 
              (0.02847 * ras.st.pas.2085.boreal) +
              (-0.47809 * ras.st.roads.boreal) +
              (-0.40638 * ras.st.tave.2085.boreal * ras.st.pas.2085.boreal) +
              (0.15057 * ras.st.tave.2085.boreal * ras.st.nffd.2085.boreal) +
              (-0.61681 * ras.st.tave.2085.boreal * ras.st.roads.boreal)))
writeRaster (predict.map.boreal.2085, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\boreal\\predboreal2085", 
             format = "raster")
writeRaster (predict.map.boreal.2085, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\boreal\\predboreal2085tif", 
             format = "GTiff")

#############
# Mountain #
###########
caribou.range.mtn <- spTransform (caribou.range.mtn, CRS = ras.crs)
caribou.mount.sa <- spTransform (caribou.mount.sa, CRS = ras.crs)
summary (model.mount8)
# 1990 #
ras.st.nffd.1990.mount <- raster::crop (ras.st.nffd.1990.mount, caribou.mount.sa)
ras.st.pas.1990.mount <- raster::crop (ras.st.pas.1990.mount, caribou.mount.sa)
ras.st.tave.1990.mount <- raster::crop (ras.st.tave.1990.mount, caribou.mount.sa)
# becCurr.rst.bwbs.mount <- raster::crop (becCurr.rst.bwbs, caribou.mount.sa) # extents do not overlap
becCurr.rst.bafa.mount <- raster::crop (becCurr.rst.bafa, caribou.mount.sa) 
becCurr.rst.ich.mount <- raster::crop (becCurr.rst.ich, caribou.mount.sa) 
# becCurr.rst.idf.mount <- raster::crop (becCurr.rst.idf, caribou.mount.sa) # left out due to large SE
becCurr.rst.ima.mount <- raster::crop (becCurr.rst.ima, caribou.mount.sa) 
becCurr.rst.ms.mount <- raster::crop (becCurr.rst.ms, caribou.mount.sa) 
# becCurr.rst.pp.mount <- raster::crop (becCurr.rst.pp, caribou.mount.sa) # left out due to large SE
becCurr.rst.sbs.mount <- raster::crop (becCurr.rst.sbs, caribou.mount.sa) 
ras.st.roads.mount <- raster::crop (ras.st.roads.mount, caribou.mount.sa)
# roads extent data is very slightly different (not sure why, the resolutioon is the same) so need 
# resample the data
ras.st.roads.mount <- raster::resample (ras.st.roads.mount, ras.st.tave.1990.mount, method = "ngb")
predict.map.mount.1990 <- (exp (0.01888 + (-0.11842 * ras.st.tave.1990.mount) +
                                   (-0.08810 * ras.st.nffd.1990.mount) + 
                                   (0.27382 * ras.st.pas.1990.mount) +
                                   (-0.86654 * ras.st.roads.mount) +
                                   (3.96844 * becCurr.rst.bafa.mount) +
                                   (-0.20156 * becCurr.rst.ich.mount) +
                                   (-0.54303 * becCurr.rst.ima.mount) +
                                   (-1.35786 * becCurr.rst.ms.mount) +
                                   (0.48337 * becCurr.rst.sbs.mount) +
                                   (-0.18366 * ras.st.tave.1990.mount * ras.st.nffd.1990.mount) +
                                   (0.40370 * ras.st.pas.1990.mount * ras.st.nffd.1990.mount) +
                                   (-0.53965 * ras.st.roads.mount * ras.st.nffd.1990.mount))) / 
  (1 + exp (0.01888 + (-0.11842 * ras.st.tave.1990.mount) +
              (-0.08810 * ras.st.nffd.1990.mount) + 
              (0.27382 * ras.st.pas.1990.mount) +
              (-0.86654 * ras.st.roads.mount) +
              (3.96844 * becCurr.rst.bafa.mount) +
              (-0.20156 * becCurr.rst.ich.mount) +
              (-0.54303 * becCurr.rst.ima.mount) +
              (-1.35786 * becCurr.rst.ms.mount) +
              (0.48337 * becCurr.rst.sbs.mount) +
              (-0.18366 * ras.st.tave.1990.mount * ras.st.nffd.1990.mount) +
              (0.40370 * ras.st.pas.1990.mount * ras.st.nffd.1990.mount) +
              (-0.53965 * ras.st.roads.mount * ras.st.nffd.1990.mount)))
writeRaster (predict.map.mount.1990, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\mountain\\predmount1990", 
             format = "raster")
writeRaster (predict.map.mount.1990, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\mountain\\predmount1990tif", 
             format = "GTiff")

# 2010 #
ras.st.nffd.2010.mount <- raster::crop (ras.st.nffd.2010.mount, caribou.mount.sa)
ras.st.pas.2010.mount <- raster::crop (ras.st.pas.2010.mount, caribou.mount.sa)
ras.st.tave.2010.mount <- raster::crop (ras.st.tave.2010.mount, caribou.mount.sa)
becCurr.rst.bafa.mount <- raster::crop (becCurr.rst.bafa, caribou.mount.sa) 
becCurr.rst.ich.mount <- raster::crop (becCurr.rst.ich, caribou.mount.sa) 
# becCurr.rst.idf.mount <- raster::crop (becCurr.rst.idf, caribou.mount.sa) # left out due to large SE
becCurr.rst.ima.mount <- raster::crop (becCurr.rst.ima, caribou.mount.sa) 
becCurr.rst.ms.mount <- raster::crop (becCurr.rst.ms, caribou.mount.sa) 
# becCurr.rst.pp.mount <- raster::crop (becCurr.rst.pp, caribou.mount.sa) # left out due to large SE
becCurr.rst.sbs.mount <- raster::crop (becCurr.rst.sbs, caribou.mount.sa) 
ras.st.roads.mount <- raster::crop (ras.st.roads.mount, caribou.mount.sa)
# roads extent data is very slightly different (not sure why, the resolutioon is the same) so need 
# resample the data
ras.st.roads.mount <- raster::resample (ras.st.roads.mount, ras.st.tave.2010.mount, method = "ngb")
predict.map.mount.2010 <- (exp (0.01888 + (-0.11842 * ras.st.tave.2010.mount) +
                                  (-0.08810 * ras.st.nffd.2010.mount) + 
                                  (0.27382 * ras.st.pas.2010.mount) +
                                  (-0.86654 * ras.st.roads.mount) +
                                  (3.96844 * becCurr.rst.bafa.mount) +
                                  (-0.20156 * becCurr.rst.ich.mount) +
                                  (-0.54303 * becCurr.rst.ima.mount) +
                                  (-1.35786 * becCurr.rst.ms.mount) +
                                  (0.48337 * becCurr.rst.sbs.mount) +
                                  (-0.18366 * ras.st.tave.2010.mount * ras.st.nffd.2010.mount) +
                                  (0.40370 * ras.st.pas.2010.mount * ras.st.nffd.2010.mount) +
                                  (-0.53965 * ras.st.roads.mount * ras.st.nffd.2010.mount))) / 
  (1 + exp (0.01888 + (-0.11842 * ras.st.tave.2010.mount) +
              (-0.08810 * ras.st.nffd.2010.mount) + 
              (0.27382 * ras.st.pas.2010.mount) +
              (-0.86654 * ras.st.roads.mount) +
              (3.96844 * becCurr.rst.bafa.mount) +
              (-0.20156 * becCurr.rst.ich.mount) +
              (-0.54303 * becCurr.rst.ima.mount) +
              (-1.35786 * becCurr.rst.ms.mount) +
              (0.48337 * becCurr.rst.sbs.mount) +
              (-0.18366 * ras.st.tave.2010.mount * ras.st.nffd.2010.mount) +
              (0.40370 * ras.st.pas.2010.mount * ras.st.nffd.2010.mount) +
              (-0.53965 * ras.st.roads.mount * ras.st.nffd.2010.mount)))
writeRaster (predict.map.mount.2010, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\mountain\\predmount2010", 
             format = "raster")
writeRaster (predict.map.mount.2010, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\mountain\\predmount2010tif", 
             format = "GTiff")

# 2025 #
ras.st.nffd.2025.mount <- raster::crop (ras.st.nffd.2025.mount, caribou.mount.sa)
ras.st.pas.2025.mount <- raster::crop (ras.st.pas.2025.mount, caribou.mount.sa)
ras.st.tave.2025.mount <- raster::crop (ras.st.tave.2025.mount, caribou.mount.sa)
bec2020.rst.bafa.mount <- raster::crop (bec2020.rst.bafa, caribou.mount.sa) 
bec2020.rst.ich.mount <- raster::crop (bec2020.rst.ich, caribou.mount.sa) 
# bec2020.rst.idf.mount <- raster::crop (bec2020.rst.idf, caribou.mount.sa) # left out due to large SE
bec2020.rst.ima.mount <- raster::crop (bec2020.rst.ima, caribou.mount.sa) 
bec2020.rst.ms.mount <- raster::crop (bec2020.rst.ms, caribou.mount.sa) 
# bec2020.rst.pp.mount <- raster::crop (bec2020.rst.pp, caribou.mount.sa) # left out due to large SE
bec2020.rst.sbs.mount <- raster::crop (bec2020.rst.sbs, caribou.mount.sa) 
ras.st.roads.mount <- raster::crop (ras.st.roads.mount, caribou.mount.sa)
# roads extent data is very slightly different (not sure why, the resolutioon is the same) so need 
# resample the data
ras.st.roads.mount <- raster::resample (ras.st.roads.mount, ras.st.tave.2025.mount, method = "ngb")
predict.map.mount.2025 <- (exp (0.01888 + (-0.11842 * ras.st.tave.2025.mount) +
                                  (-0.08810 * ras.st.nffd.2025.mount) + 
                                  (0.27382 * ras.st.pas.2025.mount) +
                                  (-0.86654 * ras.st.roads.mount) +
                                  (3.96844 * becCurr.rst.bafa.mount) +
                                  (-0.20156 * becCurr.rst.ich.mount) +
                                  (-0.54303 * becCurr.rst.ima.mount) +
                                  (-1.35786 * becCurr.rst.ms.mount) +
                                  (0.48337 * becCurr.rst.sbs.mount) +
                                  (-0.18366 * ras.st.tave.2025.mount * ras.st.nffd.2025.mount) +
                                  (0.40370 * ras.st.pas.2025.mount * ras.st.nffd.2025.mount) +
                                  (-0.53965 * ras.st.roads.mount * ras.st.nffd.2025.mount))) / 
  (1 + exp (0.01888 + (-0.11842 * ras.st.tave.2025.mount) +
              (-0.08810 * ras.st.nffd.2025.mount) + 
              (0.27382 * ras.st.pas.2025.mount) +
              (-0.86654 * ras.st.roads.mount) +
              (3.96844 * becCurr.rst.bafa.mount) +
              (-0.20156 * becCurr.rst.ich.mount) +
              (-0.54303 * becCurr.rst.ima.mount) +
              (-1.35786 * becCurr.rst.ms.mount) +
              (0.48337 * becCurr.rst.sbs.mount) +
              (-0.18366 * ras.st.tave.2025.mount * ras.st.nffd.2025.mount) +
              (0.40370 * ras.st.pas.2025.mount * ras.st.nffd.2025.mount) +
              (-0.53965 * ras.st.roads.mount * ras.st.nffd.2025.mount)))
writeRaster (predict.map.mount.2025, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\mountain\\predmount2025", 
             format = "raster")
writeRaster (predict.map.mount.2025, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\mountain\\predmount2025tif", 
             format = "GTiff")

# 2055 #
ras.st.nffd.2055.mount <- raster::crop (ras.st.nffd.2055.mount, caribou.mount.sa)
ras.st.pas.2055.mount <- raster::crop (ras.st.pas.2055.mount, caribou.mount.sa)
ras.st.tave.2055.mount <- raster::crop (ras.st.tave.2055.mount, caribou.mount.sa)
bec2050.rst.bafa.mount <- raster::crop (bec2050.rst.bafa, caribou.mount.sa) 
bec2050.rst.ich.mount <- raster::crop (bec2050.rst.ich, caribou.mount.sa) 
# bec2050.rst.idf.mount <- raster::crop (bec2050.rst.idf, caribou.mount.sa) # left out due to large SE
bec2050.rst.ima.mount <- raster::crop (bec2050.rst.ima, caribou.mount.sa) 
bec2050.rst.ms.mount <- raster::crop (bec2050.rst.ms, caribou.mount.sa) 
# bec2050.rst.pp.mount <- raster::crop (bec2050.rst.pp, caribou.mount.sa) # left out due to large SE
bec2050.rst.sbs.mount <- raster::crop (bec2050.rst.sbs, caribou.mount.sa) 
ras.st.roads.mount <- raster::crop (ras.st.roads.mount, caribou.mount.sa)
# roads extent data is very slightly different (not sure why, the resolutioon is the same) so need 
# resample the data
ras.st.roads.mount <- raster::resample (ras.st.roads.mount, ras.st.tave.2055.mount, method = "ngb")
predict.map.mount.2055 <- (exp (0.01888 + (-0.11842 * ras.st.tave.2055.mount) +
                                  (-0.08810 * ras.st.nffd.2055.mount) + 
                                  (0.27382 * ras.st.pas.2055.mount) +
                                  (-0.86654 * ras.st.roads.mount) +
                                  (3.96844 * becCurr.rst.bafa.mount) +
                                  (-0.20156 * becCurr.rst.ich.mount) +
                                  (-0.54303 * becCurr.rst.ima.mount) +
                                  (-1.35786 * becCurr.rst.ms.mount) +
                                  (0.48337 * becCurr.rst.sbs.mount) +
                                  (-0.18366 * ras.st.tave.2055.mount * ras.st.nffd.2055.mount) +
                                  (0.40370 * ras.st.pas.2055.mount * ras.st.nffd.2055.mount) +
                                  (-0.53965 * ras.st.roads.mount * ras.st.nffd.2055.mount))) / 
  (1 + exp (0.01888 + (-0.11842 * ras.st.tave.2055.mount) +
              (-0.08810 * ras.st.nffd.2055.mount) + 
              (0.27382 * ras.st.pas.2055.mount) +
              (-0.86654 * ras.st.roads.mount) +
              (3.96844 * becCurr.rst.bafa.mount) +
              (-0.20156 * becCurr.rst.ich.mount) +
              (-0.54303 * becCurr.rst.ima.mount) +
              (-1.35786 * becCurr.rst.ms.mount) +
              (0.48337 * becCurr.rst.sbs.mount) +
              (-0.18366 * ras.st.tave.2055.mount * ras.st.nffd.2055.mount) +
              (0.40370 * ras.st.pas.2055.mount * ras.st.nffd.2055.mount) +
              (-0.53965 * ras.st.roads.mount * ras.st.nffd.2055.mount)))
writeRaster (predict.map.mount.2055, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\mountain\\predmount2055", 
             format = "raster")
writeRaster (predict.map.mount.2055, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\mountain\\predmount2055tif", 
             format = "GTiff")

# 2085 #
ras.st.nffd.2085.mount <- raster::crop (ras.st.nffd.2085.mount, caribou.mount.sa)
ras.st.pas.2085.mount <- raster::crop (ras.st.pas.2085.mount, caribou.mount.sa)
ras.st.tave.2085.mount <- raster::crop (ras.st.tave.2085.mount, caribou.mount.sa)
bec2080.rst.bafa.mount <- raster::crop (bec2080.rst.bafa, caribou.mount.sa) 
bec2080.rst.ich.mount <- raster::crop (bec2080.rst.ich, caribou.mount.sa) 
# bec2080.rst.idf.mount <- raster::crop (bec2080.rst.idf, caribou.mount.sa) # left out due to large SE
bec2080.rst.ima.mount <- raster::crop (bec2080.rst.ima, caribou.mount.sa) 
bec2080.rst.ms.mount <- raster::crop (bec2080.rst.ms, caribou.mount.sa) 
# bec2080.rst.pp.mount <- raster::crop (bec2080.rst.pp, caribou.mount.sa) # left out due to large SE
bec2080.rst.sbs.mount <- raster::crop (bec2080.rst.sbs, caribou.mount.sa) 
ras.st.roads.mount <- raster::crop (ras.st.roads.mount, caribou.mount.sa)
# roads extent data is very slightly different (not sure why, the resolutioon is the same) so need 
# resample the data
ras.st.roads.mount <- raster::resample (ras.st.roads.mount, ras.st.tave.2085.mount, method = "ngb")
predict.map.mount.2085 <- (exp (0.01888 + (-0.11842 * ras.st.tave.2085.mount) +
                                  (-0.08810 * ras.st.nffd.2085.mount) + 
                                  (0.27382 * ras.st.pas.2085.mount) +
                                  (-0.86654 * ras.st.roads.mount) +
                                  (3.96844 * becCurr.rst.bafa.mount) +
                                  (-0.20156 * becCurr.rst.ich.mount) +
                                  (-0.54303 * becCurr.rst.ima.mount) +
                                  (-1.35786 * becCurr.rst.ms.mount) +
                                  (0.48337 * becCurr.rst.sbs.mount) +
                                  (-0.18366 * ras.st.tave.2085.mount * ras.st.nffd.2085.mount) +
                                  (0.40370 * ras.st.pas.2085.mount * ras.st.nffd.2085.mount) +
                                  (-0.53965 * ras.st.roads.mount * ras.st.nffd.2085.mount))) / 
  (1 + exp (0.01888 + (-0.11842 * ras.st.tave.2085.mount) +
              (-0.08810 * ras.st.nffd.2085.mount) + 
              (0.27382 * ras.st.pas.2085.mount) +
              (-0.86654 * ras.st.roads.mount) +
              (3.96844 * becCurr.rst.bafa.mount) +
              (-0.20156 * becCurr.rst.ich.mount) +
              (-0.54303 * becCurr.rst.ima.mount) +
              (-1.35786 * becCurr.rst.ms.mount) +
              (0.48337 * becCurr.rst.sbs.mount) +
              (-0.18366 * ras.st.tave.2085.mount * ras.st.nffd.2085.mount) +
              (0.40370 * ras.st.pas.2085.mount * ras.st.nffd.2085.mount) +
              (-0.53965 * ras.st.roads.mount * ras.st.nffd.2085.mount)))
writeRaster (predict.map.mount.2085, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\mountain\\predmount2085", 
             format = "raster")
writeRaster (predict.map.mount.2085, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\mountain\\predmount2085tif", 
             format = "GTiff")

#############
# NORTHERN # 
###########
caribou.range.north <- spTransform (caribou.range.north, CRS = ras.crs)
caribou.north.sa <- spTransform (caribou.north.sa, CRS = ras.crs)
summary (model.north7)
# 1990 #
ras.st.nffd.1990.north <- raster::crop (ras.st.nffd.1990.north, caribou.north.sa)
ras.st.pas.1990.north <- raster::crop (ras.st.pas.1990.north, caribou.north.sa)
ras.st.tave.1990.north <- raster::crop (ras.st.tave.1990.north, caribou.north.sa)
becCurr.rst.bwbs.north <- raster::crop (becCurr.rst.bwbs, caribou.north.sa) # extents do not overlap
becCurr.rst.bafa.north <- raster::crop (becCurr.rst.bafa, caribou.north.sa) 
becCurr.rst.cma.north <- raster::crop (becCurr.rst.cma, caribou.north.sa) 
becCurr.rst.cwh.north <- raster::crop (becCurr.rst.cwh, caribou.north.sa) 
becCurr.rst.ich.north <- raster::crop (becCurr.rst.ich, caribou.north.sa) 
becCurr.rst.idf.north <- raster::crop (becCurr.rst.idf, caribou.north.sa)
becCurr.rst.ima.north <- raster::crop (becCurr.rst.ima, caribou.north.sa) 
becCurr.rst.mh.north <- raster::crop (becCurr.rst.mh, caribou.north.sa) 
becCurr.rst.ms.north <- raster::crop (becCurr.rst.ms, caribou.north.sa) 
becCurr.rst.sbps.north <- raster::crop (becCurr.rst.sbps, caribou.north.sa) 
becCurr.rst.sbs.north <- raster::crop (becCurr.rst.sbs, caribou.north.sa) 
becCurr.rst.swb.north <- raster::crop (becCurr.rst.swb, caribou.north.sa) 
ras.st.roads.north <- raster::crop (ras.st.roads.north, caribou.north.sa)
# roads extent data is very slightly different (not sure why, the resolutioon is the same) so need 
# resample the data
ras.st.roads.north <- raster::resample (ras.st.roads.north, ras.st.tave.1990.north, method = "ngb")
predict.map.north.1990 <- (exp (1.25974 + (0.10483 * ras.st.tave.1990.north) +
                                  (-0.04148 * ras.st.nffd.1990.north) + 
                                  (-0.10072 * ras.st.pas.1990.north) +
                                  (0.03685 * ras.st.roads.north) +
                                  (0.28460 * becCurr.rst.bafa.north) +
                                  (-0.28562 * becCurr.rst.bwbs.north) +
                                  (-2.25088 * becCurr.rst.cma.north) +
                                  (-2.61817 * becCurr.rst.cwh.north) +
                                  (-0.21375 * becCurr.rst.ich.north) +
                                  (-1.04387 * becCurr.rst.idf.north) +
                                  (0.39033 * becCurr.rst.ima.north) +
                                  (-2.04956 * becCurr.rst.mh.north) +
                                  (0.32881 * becCurr.rst.ms.north) +
                                  (0.48523 * becCurr.rst.sbps.north) +
                                  (-1.18792 * becCurr.rst.sbs.north) +
                                  (0.18808 * becCurr.rst.swb.north) +
                                  (-0.20605 * ras.st.tave.1990.north * ras.st.roads.north) +
                                  (0.79609 * ras.st.pas.1990.north * ras.st.roads.north) +
                                  (-0.14386 * ras.st.nffd.1990.north * ras.st.roads.north))) / 
  (1 + exp (1.25974 + (0.10483 * ras.st.tave.1990.north) +
              (-0.04148 * ras.st.nffd.1990.north) + 
              (-0.10072 * ras.st.pas.1990.north) +
              (0.03685 * ras.st.roads.north) +
              (0.28460 * becCurr.rst.bafa.north) +
              (-0.28562 * becCurr.rst.bwbs.north) +
              (-2.25088 * becCurr.rst.cma.north) +
              (-2.61817 * becCurr.rst.cwh.north) +
              (-0.21375 * becCurr.rst.ich.north) +
              (-1.04387 * becCurr.rst.idf.north) +
              (0.39033 * becCurr.rst.ima.north) +
              (-2.04956 * becCurr.rst.mh.north) +
              (0.32881 * becCurr.rst.ms.north) +
              (0.48523 * becCurr.rst.sbps.north) +
              (-1.18792 * becCurr.rst.sbs.north) +
              (0.18808 * becCurr.rst.swb.north) +
              (-0.20605 * ras.st.tave.1990.north * ras.st.roads.north) +
              (0.79609 * ras.st.pas.1990.north * ras.st.roads.north) +
              (-0.14386 * ras.st.nffd.1990.north * ras.st.roads.north)))
writeRaster (predict.map.north.1990, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\northern\\prednorth1990", 
             format = "raster")
writeRaster (predict.map.north.1990, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\northern\\prednorth1990tif", 
             format = "GTiff")

# 2010 #
ras.st.nffd.2010.north <- raster::crop (ras.st.nffd.2010.north, caribou.north.sa)
ras.st.pas.2010.north <- raster::crop (ras.st.pas.2010.north, caribou.north.sa)
ras.st.tave.2010.north <- raster::crop (ras.st.tave.2010.north, caribou.north.sa)
becCurr.rst.bwbs.north <- raster::crop (becCurr.rst.bwbs, caribou.north.sa) # extents do not overlap
becCurr.rst.bafa.north <- raster::crop (becCurr.rst.bafa, caribou.north.sa) 
becCurr.rst.cma.north <- raster::crop (becCurr.rst.cma, caribou.north.sa) 
becCurr.rst.cwh.north <- raster::crop (becCurr.rst.cwh, caribou.north.sa) 
becCurr.rst.ich.north <- raster::crop (becCurr.rst.ich, caribou.north.sa) 
becCurr.rst.idf.north <- raster::crop (becCurr.rst.idf, caribou.north.sa)
becCurr.rst.ima.north <- raster::crop (becCurr.rst.ima, caribou.north.sa) 
becCurr.rst.mh.north <- raster::crop (becCurr.rst.mh, caribou.north.sa) 
becCurr.rst.ms.north <- raster::crop (becCurr.rst.ms, caribou.north.sa) 
becCurr.rst.sbps.north <- raster::crop (becCurr.rst.sbps, caribou.north.sa) 
becCurr.rst.sbs.north <- raster::crop (becCurr.rst.sbs, caribou.north.sa) 
becCurr.rst.swb.north <- raster::crop (becCurr.rst.swb, caribou.north.sa)
ras.st.roads.north <- raster::crop (ras.st.roads.north, caribou.north.sa)
# roads extent data is very slightly different (not sure why, the resolutioon is the same) so need 
# resample the data
ras.st.roads.north <- raster::resample (ras.st.roads.north, ras.st.tave.2010.north, method = "ngb")
predict.map.north.2010 <- (exp (1.25974 + (0.10483 * ras.st.tave.2010.north) +
                                  (-0.04148 * ras.st.nffd.2010.north) + 
                                  (-0.10072 * ras.st.pas.2010.north) +
                                  (0.03685 * ras.st.roads.north) +
                                  (0.28460 * becCurr.rst.bafa.north) +
                                  (-0.28562 * becCurr.rst.bwbs.north) +
                                  (-2.25088 * becCurr.rst.cma.north) +
                                  (-2.61817 * becCurr.rst.cwh.north) +
                                  (-0.21375 * becCurr.rst.ich.north) +
                                  (-1.04387 * becCurr.rst.idf.north) +
                                  (0.39033 * becCurr.rst.ima.north) +
                                  (-2.04956 * becCurr.rst.mh.north) +
                                  (0.32881 * becCurr.rst.ms.north) +
                                  (0.48523 * becCurr.rst.sbps.north) +
                                  (-1.18792 * becCurr.rst.sbs.north) +
                                  (0.18808 * becCurr.rst.swb.north) +
                                  (-0.20605 * ras.st.tave.2010.north * ras.st.roads.north) +
                                  (0.79609 * ras.st.pas.2010.north * ras.st.roads.north) +
                                  (-0.14386 * ras.st.nffd.2010.north * ras.st.roads.north))) / 
  (1 + exp (1.25974 + (0.10483 * ras.st.tave.2010.north) +
              (-0.04148 * ras.st.nffd.2010.north) + 
              (-0.10072 * ras.st.pas.2010.north) +
              (0.03685 * ras.st.roads.north) +
              (0.28460 * becCurr.rst.bafa.north) +
              (-0.28562 * becCurr.rst.bwbs.north) +
              (-2.25088 * becCurr.rst.cma.north) +
              (-2.61817 * becCurr.rst.cwh.north) +
              (-0.21375 * becCurr.rst.ich.north) +
              (-1.04387 * becCurr.rst.idf.north) +
              (0.39033 * becCurr.rst.ima.north) +
              (-2.04956 * becCurr.rst.mh.north) +
              (0.32881 * becCurr.rst.ms.north) +
              (0.48523 * becCurr.rst.sbps.north) +
              (-1.18792 * becCurr.rst.sbs.north) +
              (0.18808 * becCurr.rst.swb.north) +
              (-0.20605 * ras.st.tave.2010.north * ras.st.roads.north) +
              (0.79609 * ras.st.pas.2010.north * ras.st.roads.north) +
              (-0.14386 * ras.st.nffd.2010.north * ras.st.roads.north)))
writeRaster (predict.map.north.2010, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\northern\\prednorth2010", 
             format = "raster")
writeRaster (predict.map.north.2010, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\northern\\prednorth2010tif", 
             format = "GTiff")

# 2025 #
ras.st.nffd.2025.north <- raster::crop (ras.st.nffd.2025.north, caribou.north.sa)
ras.st.pas.2025.north <- raster::crop (ras.st.pas.2025.north, caribou.north.sa)
ras.st.tave.2025.north <- raster::crop (ras.st.tave.2025.north, caribou.north.sa)
bec2020.rst.bwbs.north <- raster::crop (bec2020.rst.bwbs, caribou.north.sa) # extents do not overlap
bec2020.rst.bafa.north <- raster::crop (bec2020.rst.bafa, caribou.north.sa) 
bec2020.rst.cma.north <- raster::crop (bec2020.rst.cma, caribou.north.sa) 
bec2020.rst.cwh.north <- raster::crop (bec2020.rst.cwh, caribou.north.sa) 
bec2020.rst.ich.north <- raster::crop (bec2020.rst.ich, caribou.north.sa) 
bec2020.rst.idf.north <- raster::crop (bec2020.rst.idf, caribou.north.sa)
bec2020.rst.ima.north <- raster::crop (bec2020.rst.ima, caribou.north.sa) 
bec2020.rst.mh.north <- raster::crop (bec2020.rst.mh, caribou.north.sa) 
bec2020.rst.ms.north <- raster::crop (bec2020.rst.ms, caribou.north.sa) 
bec2020.rst.sbps.north <- raster::crop (bec2020.rst.sbps, caribou.north.sa) 
bec2020.rst.sbs.north <- raster::crop (bec2020.rst.sbs, caribou.north.sa) 
bec2020.rst.swb.north <- raster::crop (bec2020.rst.swb, caribou.north.sa)
ras.st.roads.north <- raster::crop (ras.st.roads.north, caribou.north.sa)
# roads extent data is very slightly different (not sure why, the resolutioon is the same) so need 
# resample the data
ras.st.roads.north <- raster::resample (ras.st.roads.north, ras.st.tave.2025.north, method = "ngb")
predict.map.north.2025 <- (exp (1.25974 + (0.10483 * ras.st.tave.2025.north) +
                                  (-0.04148 * ras.st.nffd.2025.north) + 
                                  (-0.10072 * ras.st.pas.2025.north) +
                                  (0.03685 * ras.st.roads.north) +
                                  (0.28460 * bec2020.rst.bafa.north) +
                                  (-0.28562 * bec2020.rst.bwbs.north) +
                                  (-2.25088 * bec2020.rst.cma.north) +
                                  (-2.61817 * bec2020.rst.cwh.north) +
                                  (-0.21375 * bec2020.rst.ich.north) +
                                  (-1.04387 * bec2020.rst.idf.north) +
                                  (0.39033 * bec2020.rst.ima.north) +
                                  (-2.04956 * bec2020.rst.mh.north) +
                                  (0.32881 * bec2020.rst.ms.north) +
                                  (0.48523 * bec2020.rst.sbps.north) +
                                  (-1.18792 * bec2020.rst.sbs.north) +
                                  (0.18808 * bec2020.rst.swb.north) +
                                  (-0.20605 * ras.st.tave.2025.north * ras.st.roads.north) +
                                  (0.79609 * ras.st.pas.2025.north * ras.st.roads.north) +
                                  (-0.14386 * ras.st.nffd.2025.north * ras.st.roads.north))) / 
  (1 + exp (1.25974 + (0.10483 * ras.st.tave.2025.north) +
              (-0.04148 * ras.st.nffd.2025.north) + 
              (-0.10072 * ras.st.pas.2025.north) +
              (0.03685 * ras.st.roads.north) +
              (0.28460 * bec2020.rst.bafa.north) +
              (-0.28562 * bec2020.rst.bwbs.north) +
              (-2.25088 * bec2020.rst.cma.north) +
              (-2.61817 * bec2020.rst.cwh.north) +
              (-0.21375 * bec2020.rst.ich.north) +
              (-1.04387 * bec2020.rst.idf.north) +
              (0.39033 * bec2020.rst.ima.north) +
              (-2.04956 * bec2020.rst.mh.north) +
              (0.32881 * bec2020.rst.ms.north) +
              (0.48523 * bec2020.rst.sbps.north) +
              (-1.18792 * bec2020.rst.sbs.north) +
              (0.18808 * bec2020.rst.swb.north) +
              (-0.20605 * ras.st.tave.2025.north * ras.st.roads.north) +
              (0.79609 * ras.st.pas.2025.north * ras.st.roads.north) +
              (-0.14386 * ras.st.nffd.2025.north * ras.st.roads.north)))
writeRaster (predict.map.north.2025, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\northern\\prednorth2025", 
             format = "raster")
writeRaster (predict.map.north.2025, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\northern\\prednorth2025tif", 
             format = "GTiff")

# 2055 #
ras.st.nffd.2055.north <- raster::crop (ras.st.nffd.2055.north, caribou.north.sa)
ras.st.pas.2055.north <- raster::crop (ras.st.pas.2055.north, caribou.north.sa)
ras.st.tave.2055.north <- raster::crop (ras.st.tave.2055.north, caribou.north.sa)
bec2050.rst.bwbs.north <- raster::crop (bec2050.rst.bwbs, caribou.north.sa) # extents do not overlap
bec2050.rst.bafa.north <- raster::crop (bec2050.rst.bafa, caribou.north.sa) 
bec2050.rst.cma.north <- raster::crop (bec2050.rst.cma, caribou.north.sa) 
bec2050.rst.cwh.north <- raster::crop (bec2050.rst.cwh, caribou.north.sa) 
bec2050.rst.ich.north <- raster::crop (bec2050.rst.ich, caribou.north.sa) 
bec2050.rst.idf.north <- raster::crop (bec2050.rst.idf, caribou.north.sa)
bec2050.rst.ima.north <- raster::crop (bec2050.rst.ima, caribou.north.sa) 
bec2050.rst.mh.north <- raster::crop (bec2050.rst.mh, caribou.north.sa) 
bec2050.rst.ms.north <- raster::crop (bec2050.rst.ms, caribou.north.sa) 
bec2050.rst.sbps.north <- raster::crop (bec2050.rst.sbps, caribou.north.sa) 
bec2050.rst.sbs.north <- raster::crop (bec2050.rst.sbs, caribou.north.sa) 
bec2050.rst.swb.north <- raster::crop (bec2050.rst.swb, caribou.north.sa)
ras.st.roads.north <- raster::crop (ras.st.roads.north, caribou.north.sa)
# roads extent data is very slightly different (not sure why, the resolutioon is the same) so need 
# resample the data
ras.st.roads.north <- raster::resample (ras.st.roads.north, ras.st.tave.2055.north, method = "ngb")
predict.map.north.2055 <- (exp (1.25974 + (0.10483 * ras.st.tave.2055.north) +
                                  (-0.04148 * ras.st.nffd.2055.north) + 
                                  (-0.10072 * ras.st.pas.2055.north) +
                                  (0.03685 * ras.st.roads.north) +
                                  (0.28460 * bec2050.rst.bafa.north) +
                                  (-0.28562 * bec2050.rst.bwbs.north) +
                                  (-2.25088 * bec2050.rst.cma.north) +
                                  (-2.61817 * bec2050.rst.cwh.north) +
                                  (-0.21375 * bec2050.rst.ich.north) +
                                  (-1.04387 * bec2050.rst.idf.north) +
                                  (0.39033 * bec2050.rst.ima.north) +
                                  (-2.04956 * bec2050.rst.mh.north) +
                                  (0.32881 * bec2050.rst.ms.north) +
                                  (0.48523 * bec2050.rst.sbps.north) +
                                  (-1.18792 * bec2050.rst.sbs.north) +
                                  (0.18808 * bec2050.rst.swb.north) +
                                  (-0.20605 * ras.st.tave.2055.north * ras.st.roads.north) +
                                  (0.79609 * ras.st.pas.2055.north * ras.st.roads.north) +
                                  (-0.14386 * ras.st.nffd.2055.north * ras.st.roads.north))) / 
  (1 + exp (1.25974 + (0.10483 * ras.st.tave.2055.north) +
              (-0.04148 * ras.st.nffd.2055.north) + 
              (-0.10072 * ras.st.pas.2055.north) +
              (0.03685 * ras.st.roads.north) +
              (0.28460 * bec2050.rst.bafa.north) +
              (-0.28562 * bec2050.rst.bwbs.north) +
              (-2.25088 * bec2050.rst.cma.north) +
              (-2.61817 * bec2050.rst.cwh.north) +
              (-0.21375 * bec2050.rst.ich.north) +
              (-1.04387 * bec2050.rst.idf.north) +
              (0.39033 * bec2050.rst.ima.north) +
              (-2.04956 * bec2050.rst.mh.north) +
              (0.32881 * bec2050.rst.ms.north) +
              (0.48523 * bec2050.rst.sbps.north) +
              (-1.18792 * bec2050.rst.sbs.north) +
              (0.18808 * bec2050.rst.swb.north) +
              (-0.20605 * ras.st.tave.2055.north * ras.st.roads.north) +
              (0.79609 * ras.st.pas.2055.north * ras.st.roads.north) +
              (-0.14386 * ras.st.nffd.2055.north * ras.st.roads.north)))
writeRaster (predict.map.north.2055, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\northern\\prednorth2055", 
             format = "raster")
writeRaster (predict.map.north.2055, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\northern\\prednorth2055tif", 
             format = "GTiff")

# 2085 #
ras.st.nffd.2085.north <- raster::crop (ras.st.nffd.2085.north, caribou.north.sa)
ras.st.pas.2085.north <- raster::crop (ras.st.pas.2085.north, caribou.north.sa)
ras.st.tave.2085.north <- raster::crop (ras.st.tave.2085.north, caribou.north.sa)
bec2080.rst.bwbs.north <- raster::crop (bec2080.rst.bwbs, caribou.north.sa) # extents do not overlap
bec2080.rst.bafa.north <- raster::crop (bec2080.rst.bafa, caribou.north.sa) 
bec2080.rst.cma.north <- raster::crop (bec2080.rst.cma, caribou.north.sa) 
bec2080.rst.cwh.north <- raster::crop (bec2080.rst.cwh, caribou.north.sa) 
bec2080.rst.ich.north <- raster::crop (bec2080.rst.ich, caribou.north.sa) 
bec2080.rst.idf.north <- raster::crop (bec2080.rst.idf, caribou.north.sa)
bec2080.rst.ima.north <- raster::crop (bec2080.rst.ima, caribou.north.sa) 
bec2080.rst.mh.north <- raster::crop (bec2080.rst.mh, caribou.north.sa) 
bec2080.rst.ms.north <- raster::crop (bec2080.rst.ms, caribou.north.sa) 
bec2080.rst.sbps.north <- raster::crop (bec2080.rst.sbps, caribou.north.sa) 
bec2080.rst.sbs.north <- raster::crop (bec2080.rst.sbs, caribou.north.sa) 
bec2080.rst.swb.north <- raster::crop (bec2080.rst.swb, caribou.north.sa)
ras.st.roads.north <- raster::crop (ras.st.roads.north, caribou.north.sa)
# roads extent data is very slightly different (not sure why, the resolutioon is the same) so need 
# resample the data
ras.st.roads.north <- raster::resample (ras.st.roads.north, ras.st.tave.2085.north, method = "ngb")
predict.map.north.2085 <- (exp (1.25974 + (0.10483 * ras.st.tave.2085.north) +
                                  (-0.04148 * ras.st.nffd.2085.north) + 
                                  (-0.10072 * ras.st.pas.2085.north) +
                                  (0.03685 * ras.st.roads.north) +
                                  (0.28460 * bec2080.rst.bafa.north) +
                                  (-0.28562 * bec2080.rst.bwbs.north) +
                                  (-2.25088 * bec2080.rst.cma.north) +
                                  (-2.61817 * bec2080.rst.cwh.north) +
                                  (-0.21375 * bec2080.rst.ich.north) +
                                  (-1.04387 * bec2080.rst.idf.north) +
                                  (0.39033 * bec2080.rst.ima.north) +
                                  (-2.04956 * bec2080.rst.mh.north) +
                                  (0.32881 * bec2080.rst.ms.north) +
                                  (0.48523 * bec2080.rst.sbps.north) +
                                  (-1.18792 * bec2080.rst.sbs.north) +
                                  (0.18808 * bec2080.rst.swb.north) +
                                  (-0.20605 * ras.st.tave.2085.north * ras.st.roads.north) +
                                  (0.79609 * ras.st.pas.2085.north * ras.st.roads.north) +
                                  (-0.14386 * ras.st.nffd.2085.north * ras.st.roads.north))) / 
  (1 + exp (1.25974 + (0.10483 * ras.st.tave.2085.north) +
              (-0.04148 * ras.st.nffd.2085.north) + 
              (-0.10072 * ras.st.pas.2085.north) +
              (0.03685 * ras.st.roads.north) +
              (0.28460 * bec2080.rst.bafa.north) +
              (-0.28562 * bec2080.rst.bwbs.north) +
              (-2.25088 * bec2080.rst.cma.north) +
              (-2.61817 * bec2080.rst.cwh.north) +
              (-0.21375 * bec2080.rst.ich.north) +
              (-1.04387 * bec2080.rst.idf.north) +
              (0.39033 * bec2080.rst.ima.north) +
              (-2.04956 * bec2080.rst.mh.north) +
              (0.32881 * bec2080.rst.ms.north) +
              (0.48523 * bec2080.rst.sbps.north) +
              (-1.18792 * bec2080.rst.sbs.north) +
              (0.18808 * bec2080.rst.swb.north) +
              (-0.20605 * ras.st.tave.2085.north * ras.st.roads.north) +
              (0.79609 * ras.st.pas.2085.north * ras.st.roads.north) +
              (-0.14386 * ras.st.nffd.2085.north * ras.st.roads.north)))
writeRaster (predict.map.north.2085, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\northern\\prednorth2085", 
             format = "raster")
writeRaster (predict.map.north.2085, 
             filename = "C:\\Work\\caribou\\climate_analysis\\output\\rasters\\northern\\prednorth2085tif", 
             format = "GTiff")

#=============================================================
# Table for predicting boreal model and plotting predictions
#============================================================
table.predict.boreal <- data.frame (matrix (ncol = 6, nrow = 0))
colnames (table.predict.boreal) <- c ("tave.wt.2010", "nffd.sp.2010", 
                                       "pas.wt.2010", "road.dns.27k", 
                                       "bec.curr.simple", "Temperature")
table.predict.boreal$bec.curr.simple <-  factor (table.predict.boreal$bec.curr.simple , 
                                          levels = levels (data.clean$bec.curr.simple))
min (data.boreal$road.dns.27k)
max (data.boreal$road.dns.27k)
seq.temp.boreal <- c (-20:-10)
seq.nffd.boreal <- c (seq (from = 10, to = 35, by = 1))
seq.pas.boreal <- c (seq (from = 55, to = 85, by = 2))
seq.rds.boreal <- c (seq (from = 0, to = 2.4, by = 0.2))
table.predict.boreal [1:11, 1] <- seq.temp.boreal 
table.predict.boreal [1:11, 2] <- mean (data.boreal$nffd.sp.2010)
table.predict.boreal [1:11, 3] <- mean (data.boreal$pas.wt.2010)
table.predict.boreal [1:11, 4] <- mean (data.boreal$road.dns.27k)
table.predict.boreal [1:11, 5] <- "BWBS" # equivalent to BWBS
table.predict.boreal [1:11, 6] <- "Range of Winter Temperatures"
table.predict.boreal [12:37, 1] <- mean (data.boreal$tave.wt.2010)
table.predict.boreal [12:37, 2] <- seq.nffd.boreal
table.predict.boreal [12:37, 3] <- mean (data.boreal$pas.wt.2010)
table.predict.boreal [12:37, 4] <- mean (data.boreal$road.dns.27k)
table.predict.boreal [12:37, 5] <- "BWBS"
table.predict.boreal [12:37, 6] <- "Average Winter Temperature"
table.predict.boreal [38:53, 1] <- mean (data.boreal$tave.wt.2010)
table.predict.boreal [38:53, 2] <- mean (data.boreal$nffd.sp.2010)
table.predict.boreal [38:53, 3] <- seq.pas.boreal
table.predict.boreal [38:53, 4] <- mean (data.boreal$road.dns.27k)
table.predict.boreal [38:53, 5] <- "BWBS"
table.predict.boreal [38:53, 6] <- "Average Winter Temperature"
table.predict.boreal [54:66, 1] <- mean (data.boreal$tave.wt.2010)
table.predict.boreal [54:66, 2] <- mean (data.boreal$nffd.sp.2010)
table.predict.boreal [54:66, 3] <- mean (data.boreal$pas.wt.2010)
table.predict.boreal [54:66, 4] <- seq.rds.boreal 
table.predict.boreal [54:66, 5] <- "BWBS"
table.predict.boreal [54:66, 6] <- "Average Winter Temperature"
table.predict.boreal [67:92, 1] <- mean (data.boreal$tave.wt.2010) - sd (data.boreal$tave.wt.2010)
table.predict.boreal [67:92, 2] <- seq.nffd.boreal
table.predict.boreal [67:92, 3] <- mean (data.boreal$pas.wt.2010)
table.predict.boreal [67:92, 4] <- mean (data.boreal$road.dns.27k)
table.predict.boreal [67:92, 5] <- "BWBS"
table.predict.boreal [67:92, 6] <- "Low Winter Temperature" # one SD lower than average
table.predict.boreal [93:108, 1] <- mean (data.boreal$tave.wt.2010) - sd (data.boreal$tave.wt.2010)
table.predict.boreal [93:108, 2] <- mean (data.boreal$nffd.sp.2010)
table.predict.boreal [93:108, 3] <- seq.pas.boreal
table.predict.boreal [93:108, 4] <- mean (data.boreal$road.dns.27k)
table.predict.boreal [93:108, 5] <- "BWBS"
table.predict.boreal [93:108, 6] <- "Low Winter Temperature"
table.predict.boreal [109:121, 1] <- mean (data.boreal$tave.wt.2010) - sd (data.boreal$tave.wt.2010)
table.predict.boreal [109:121, 2] <- mean (data.boreal$nffd.sp.2010)
table.predict.boreal [109:121, 3] <- mean (data.boreal$pas.wt.2010)
table.predict.boreal [109:121, 4] <- seq.rds.boreal
table.predict.boreal [109:121, 5] <- "BWBS"
table.predict.boreal [109:121, 6] <- "Low Winter Temperature"
table.predict.boreal [122:147, 1] <- mean (data.boreal$tave.wt.2010) + sd (data.boreal$tave.wt.2010)
table.predict.boreal [122:147, 2] <- seq.nffd.boreal
table.predict.boreal [122:147, 3] <- mean (data.boreal$pas.wt.2010)
table.predict.boreal [122:147, 4] <- mean (data.boreal$road.dns.27k)
table.predict.boreal [122:147, 5] <- "BWBS"
table.predict.boreal [122:147, 6] <- "High Winter Temperature" # one SD higher than average
table.predict.boreal [148:163, 1] <- mean (data.boreal$tave.wt.2010) + sd (data.boreal$tave.wt.2010)
table.predict.boreal [148:163, 2] <- mean (data.boreal$nffd.sp.2010)
table.predict.boreal [148:163, 3] <- seq.pas.boreal
table.predict.boreal [148:163, 4] <- mean (data.boreal$road.dns.27k)
table.predict.boreal [148:163, 5] <- "BWBS"
table.predict.boreal [148:163, 6] <- "High Winter Temperature" # one SD higher than average
table.predict.boreal [164:176, 1] <- mean (data.boreal$tave.wt.2010) + sd (data.boreal$tave.wt.2010)
table.predict.boreal [164:176, 2] <- mean (data.boreal$nffd.sp.2010)
table.predict.boreal [164:176, 3] <- mean (data.boreal$pas.wt.2010)
table.predict.boreal [164:176, 4] <- seq.rds.boreal
table.predict.boreal [164:176, 5] <- "BWBS"
table.predict.boreal [164:176, 6] <- "High Winter Temperature" # one SD higher than average
table.predict.boreal$Temperature <-  as.factor (table.predict.boreal$Temperature)
table.predict.boreal$st.tave.wt.2010 <- (table.predict.boreal$tave.wt.2010 - mean (data.boreal$tave.wt.2010)) /
                                         sd (data.boreal$tave.wt.2010)
table.predict.boreal$st.nffd.sp.2010 <- (table.predict.boreal$nffd.sp.2010 - mean (data.boreal$nffd.sp.2010)) /
                                         sd (data.boreal$nffd.sp.2010)
table.predict.boreal$st.pas.wt.2010 <- (table.predict.boreal$pas.wt.2010 - mean (data.boreal$pas.wt.2010)) /
                                        sd (data.boreal$pas.wt.2010)
table.predict.boreal$st.road.dns.27k <- (table.predict.boreal$road.dns.27k - mean (data.boreal$road.dns.27k)) /
                                          sd (data.boreal$road.dns.27k)

#=============================================================
# Table for predicting mountain model and plotting predictions
#============================================================
table.predict.mount <- data.frame (matrix (ncol = 6, nrow = 0))
colnames (table.predict.mount) <- c ("tave.wt.2010", "nffd.sp.2010", 
                                      "pas.wt.2010", "road.dns.27k", 
                                      "bec.curr.simple", "nffd.scn")
table.predict.mount$bec.curr.simple <-  factor (table.predict.mount$bec.curr.simple , 
                                                 levels = levels (data.clean$bec.curr.simple))
min (data.mount$road.dns.27k)
max (data.mount$road.dns.27k)
seq.temp.mount <- c (-20:-1)
seq.nffd.mount <- c (seq (from = 0, to = 65, by = 5))
seq.pas.mount <- c (seq (from = 50, to = 750, by = 50))
seq.rds.mount <- c (seq (from = 0, to = 3.2, by = 0.2))
table.predict.mount [1:20, 1] <- seq.temp.mount 
table.predict.mount [1:20, 2] <- mean (data.mount$nffd.sp.2010)
table.predict.mount [1:20, 3] <- mean (data.mount$pas.wt.2010)
table.predict.mount [1:20, 4] <- mean (data.mount$road.dns.27k)
table.predict.mount [1:20, 5] <- "ESSF" # equivalent to ESSF
table.predict.mount [1:20, 6] <- "Average Spring Frost Free Days"
table.predict.mount [21:34, 1] <- mean (data.mount$tave.wt.2010)
table.predict.mount [21:34, 2] <- seq.nffd.mount
table.predict.mount [21:34, 3] <- mean (data.mount$pas.wt.2010)
table.predict.mount [21:34, 4] <- mean (data.mount$road.dns.27k)
table.predict.mount [21:34, 5] <- "ESSF"
table.predict.mount [21:34, 6] <- "Range of Spring Frost Free Days"
table.predict.mount [35:49, 1] <- mean (data.mount$tave.wt.2010)
table.predict.mount [35:49, 2] <- mean (data.mount$nffd.sp.2010)
table.predict.mount [35:49, 3] <- seq.pas.mount
table.predict.mount [35:49, 4] <- mean (data.mount$road.dns.27k)
table.predict.mount [35:49, 5] <- "ESSF"
table.predict.mount [35:49, 6] <- "Average Spring Frost Free Days"
table.predict.mount [50:66, 1] <- mean (data.mount$tave.wt.2010)
table.predict.mount [50:66, 2] <- mean (data.mount$nffd.sp.2010)
table.predict.mount [50:66, 3] <- mean (data.mount$pas.wt.2010)
table.predict.mount [50:66, 4] <- seq.rds.mount 
table.predict.mount [50:66, 5] <- "ESSF"
table.predict.mount [50:66, 6] <- "Average Spring Frost Free Days"
table.predict.mount [67:86, 1] <- seq.temp.mount
table.predict.mount [67:86, 2] <- mean (data.mount$nffd.sp.2010) - sd (data.mount$nffd.sp.2010)
table.predict.mount [67:86, 3] <- mean (data.mount$pas.wt.2010)
table.predict.mount [67:86, 4] <- mean (data.mount$road.dns.27k)
table.predict.mount [67:86, 5] <- "ESSF"
table.predict.mount [67:86, 6] <- "Low Spring Frost Free Days" # one SD lower than average
table.predict.mount [87:101, 1] <- mean (data.mount$tave.wt.2010)
table.predict.mount [87:101, 2] <- mean (data.mount$nffd.sp.2010) - sd (data.mount$nffd.sp.2010)
table.predict.mount [87:101, 3] <- seq.pas.mount
table.predict.mount [87:101, 4] <- mean (data.mount$road.dns.27k)
table.predict.mount [87:101, 5] <- "ESSF"
table.predict.mount [87:101, 6] <- "Low Spring Frost Free Days"
table.predict.mount [102:118, 1] <- mean (data.mount$tave.wt.2010)
table.predict.mount [102:118, 2] <- mean (data.mount$nffd.sp.2010) - sd (data.mount$nffd.sp.2010)
table.predict.mount [102:118, 3] <- mean (data.mount$pas.wt.2010)
table.predict.mount [102:118, 4] <- seq.rds.mount
table.predict.mount [102:118, 5] <- "ESSF"
table.predict.mount [102:118, 6] <- "Low Spring Frost Free Days"
table.predict.mount [119:138, 1] <- seq.temp.mount
table.predict.mount [119:138, 2] <- mean (data.mount$nffd.sp.2010) + sd (data.mount$nffd.sp.2010)
table.predict.mount [119:138, 3] <- mean (data.mount$pas.wt.2010)
table.predict.mount [119:138, 4] <- mean (data.mount$road.dns.27k)
table.predict.mount [119:138, 5] <- "ESSF"
table.predict.mount [119:138, 6] <- "High Spring Frost Free Days" # one SD higher than average
table.predict.mount [139:153, 1] <- mean (data.mount$tave.wt.2010) 
table.predict.mount [139:153, 2] <- mean (data.mount$nffd.sp.2010) + sd (data.mount$nffd.sp.2010)
table.predict.mount [139:153, 3] <- seq.pas.mount
table.predict.mount [139:153, 4] <- mean (data.mount$road.dns.27k)
table.predict.mount [139:153, 5] <- "ESSF"
table.predict.mount [139:153, 6] <- "High Spring Frost Free Days" # one SD higher than average
table.predict.mount [154:170, 1] <- mean (data.mount$tave.wt.2010)
table.predict.mount [154:170, 2] <- mean (data.mount$nffd.sp.2010) + sd (data.mount$nffd.sp.2010)
table.predict.mount [154:170, 3] <- mean (data.mount$pas.wt.2010)
table.predict.mount [154:170, 4] <- seq.rds.mount
table.predict.mount [154:170, 5] <- "ESSF"
table.predict.mount [154:170, 6] <- "High Spring Frost Free Days" # one SD higher than average
table.predict.mount$nffd.scn <-  as.factor (table.predict.mount$nffd.scn)
table.predict.mount$st.tave.wt.2010 <- (table.predict.mount$tave.wt.2010 - mean (data.mount$tave.wt.2010)) /
                                         sd (data.mount$tave.wt.2010)
table.predict.mount$st.nffd.sp.2010 <- (table.predict.mount$nffd.sp.2010 - mean (data.mount$nffd.sp.2010)) /
                                          sd (data.mount$nffd.sp.2010)
table.predict.mount$st.pas.wt.2010 <- (table.predict.mount$pas.wt.2010 - mean (data.mount$pas.wt.2010)) /
                                          sd (data.mount$pas.wt.2010)
table.predict.mount$st.road.dns.27k <- (table.predict.mount$road.dns.27k - mean (data.mount$road.dns.27k)) /
                                          sd (data.mount$road.dns.27k)

#=============================================================
# Table for predicting Northern model and plotting predictions
#============================================================
table.predict.north <- data.frame (matrix (ncol = 6, nrow = 0))
colnames (table.predict.north) <- c ("tave.wt.2010", "nffd.sp.2010", 
                                     "pas.wt.2010", "road.dns.27k", 
                                     "bec.curr.simple", "road.scn")
table.predict.north$bec.curr.simple <-  factor (table.predict.north$bec.curr.simple , 
                                                levels = levels (data.clean$bec.curr.simple))
min (data.north$road.dns.27k)
max (data.north$road.dns.27k)
seq.temp.north <- c (-20:-1)
seq.nffd.north <- c (seq (from = 0, to = 60, by = 5))
seq.pas.north <- c (seq (from = 50, to = 1000, by = 50))
seq.rds.north <- c (seq (from = 0, to = 2.6, by = 0.1))
table.predict.north [1:20, 1] <- seq.temp.north 
table.predict.north [1:20, 2] <- mean (data.north$nffd.sp.2010)
table.predict.north [1:20, 3] <- mean (data.north$pas.wt.2010)
table.predict.north [1:20, 4] <- mean (data.north$road.dns.27k)
table.predict.north [1:20, 5] <- "ESSF" # equivalent to ESSF
table.predict.north [1:20, 6] <- "Average Road Density"
table.predict.north [21:33, 1] <- mean (data.north$tave.wt.2010)
table.predict.north [21:33, 2] <- seq.nffd.north
table.predict.north [21:33, 3] <- mean (data.north$pas.wt.2010)
table.predict.north [21:33, 4] <- mean (data.north$road.dns.27k)
table.predict.north [21:33, 5] <- "ESSF"
table.predict.north [21:33, 6] <- "Average Road Density"
table.predict.north [34:53, 1] <- mean (data.north$tave.wt.2010)
table.predict.north [34:53, 2] <- mean (data.north$nffd.sp.2010)
table.predict.north [34:53, 3] <- seq.pas.north
table.predict.north [34:53, 4] <- mean (data.north$road.dns.27k)
table.predict.north [34:53, 5] <- "ESSF"
table.predict.north [34:53, 6] <- "Average Road Density"
table.predict.north [54:80, 1] <- mean (data.north$tave.wt.2010)
table.predict.north [54:80, 2] <- mean (data.north$nffd.sp.2010)
table.predict.north [54:80, 3] <- mean (data.north$pas.wt.2010)
table.predict.north [54:80, 4] <- seq.rds.north 
table.predict.north [54:80, 5] <- "ESSF"
table.predict.north [54:80, 6] <- "NA"
table.predict.north [81:100, 1] <- seq.temp.north
table.predict.north [81:100, 2] <- mean (data.north$nffd.sp.2010)
table.predict.north [81:100, 3] <- mean (data.north$pas.wt.2010)
table.predict.north [81:100, 4] <- mean (data.north$road.dns.27k) - sd (data.north$road.dns.27k)
table.predict.north [81:100, 5] <- "ESSF"
table.predict.north [81:100, 6] <- "Low Road Density" # one SD lower than average
table.predict.north [101:113, 1] <- mean (data.north$tave.wt.2010)
table.predict.north [101:113, 2] <- seq.nffd.north
table.predict.north [101:113, 3] <- mean (data.north$pas.wt.2010)
table.predict.north [101:113, 4] <- mean (data.north$road.dns.27k) - sd (data.north$road.dns.27k)
table.predict.north [101:113, 5] <- "ESSF"
table.predict.north [101:113, 6] <- "Low Road Density"
table.predict.north [114:133, 1] <- mean (data.north$tave.wt.2010)
table.predict.north [114:133, 2] <- mean (data.north$nffd.sp.2010)
table.predict.north [114:133, 3] <- seq.pas.north
table.predict.north [114:133, 4] <- mean (data.north$road.dns.27k) - sd (data.north$road.dns.27k)
table.predict.north [114:133, 5] <- "ESSF"
table.predict.north [114:133, 6] <- "Low Road Density"
table.predict.north [134:153, 1] <- seq.temp.north
table.predict.north [134:153, 2] <- mean (data.north$nffd.sp.2010)
table.predict.north [134:153, 3] <- mean (data.north$pas.wt.2010)
table.predict.north [134:153, 4] <- mean (data.north$road.dns.27k) + sd (data.north$road.dns.27k)
table.predict.north [134:153, 5] <- "ESSF"
table.predict.north [134:153, 6] <- "High Road Density" # one SD higher than average
table.predict.north [154:166, 1] <- mean (data.north$tave.wt.2010) 
table.predict.north [154:166, 2] <- seq.nffd.north
table.predict.north [154:166, 3] <- mean (data.north$pas.wt.2010)
table.predict.north [154:166, 4] <- mean (data.north$road.dns.27k) + sd (data.north$road.dns.27k)
table.predict.north [154:166, 5] <- "ESSF"
table.predict.north [154:166, 6] <- "High Road Density" # one SD higher than average
table.predict.north [167:186, 1] <- mean (data.north$tave.wt.2010)
table.predict.north [167:186, 2] <- mean (data.north$nffd.sp.2010)
table.predict.north [167:186, 3] <- seq.pas.north
table.predict.north [167:186, 4] <- mean (data.north$road.dns.27k) + sd (data.north$road.dns.27k)
table.predict.north [167:186, 5] <- "ESSF"
table.predict.north [167:186, 6] <- "High Road Density" # one SD higher than average
table.predict.north$road.scn <-  as.factor (table.predict.north$road.scn)
table.predict.north$st.tave.wt.2010 <- (table.predict.north$tave.wt.2010 - mean (data.north$tave.wt.2010)) /
                                        sd (data.north$tave.wt.2010)
table.predict.north$st.nffd.sp.2010 <- (table.predict.north$nffd.sp.2010 - mean (data.north$nffd.sp.2010)) /
                                        sd (data.north$nffd.sp.2010)
table.predict.north$st.pas.wt.2010 <- (table.predict.north$pas.wt.2010 - mean (data.north$pas.wt.2010)) /
                                        sd (data.north$pas.wt.2010)
table.predict.north$st.road.dns.27k <- (table.predict.north$road.dns.27k - mean (data.north$road.dns.27k)) /
                                        sd (data.north$road.dns.27k)

#========================================================================
# Table for predicting GLMER model and plotting predictions; DO NOT USE
#=======================================================================
table.predict <- data.frame (matrix (ncol = 7, nrow = 0))
colnames (table.predict) <- c ("ecotype", "tave.wt.2010", "nffd.sp.2010", 
                               "pas.wt.2010", "road.dns.27k", 
                               "bec.curr.simple", "road.dens")
table.predict$bec.curr.simple <-  factor (table.predict$bec.curr.simple , 
                                          levels = levels (data.clean$bec.curr.simple))
table.predict$ecotype <-  factor (table.predict$ecotype, 
                                  levels = levels (data.clean$ecotype))
seq.temp <- c (-20:0)
seq.nffd <- c (seq (from = 0, to = 65, by = 5))
seq.pas.boreal <- c (seq (from = 0, to = 100, by = 5))
seq.pas.non.bor <- c (seq (from = 0, to = 1000, by = 50))
seq.rds <- c (seq (from = 0, to = 3.2, by = 0.2))
table.predict [1:21, 1] <- "Boreal"
table.predict [c (1:21), 2] <- seq.temp 
table.predict [c (1:21), 3] <- mean (data.clean$nffd.sp.2010)
table.predict [c (1:21), 4] <- mean (data.clean$pas.wt.2010)
table.predict [c (1:21), 5] <- mean (data.clean$road.dns.27k)
table.predict [c (1:21), 6] <- "BWBS" # equivalent to BWBS
table.predict [c (1:21), 7] <- "Average Road Density"
table.predict [22:42, 1] <- "Mountain"
table.predict [c (22:42), 2] <- seq.temp
table.predict [22:42, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [22:42, 4] <- mean (data.clean$pas.wt.2010)
table.predict [22:42, 5] <- mean (data.clean$road.dns.27k)
table.predict [22:42, 6] <- "ESSF" # equivalent to ESSF
table.predict [22:42, 7] <- "Average Road Density"
table.predict [43:63, 1] <- "Northern"
table.predict [c (43:63), 2] <- seq.temp
table.predict [43:63, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [43:63, 4] <- mean (data.clean$pas.wt.2010)
table.predict [43:63, 5] <- mean (data.clean$road.dns.27k)
table.predict [43:63, 6] <- "ESSF" # equivalent to ESSF
table.predict [43:63, 7] <- "Average Road Density"
table.predict [64:77, 1] <- "Boreal"
table.predict [64:77, 2] <- mean (data.clean$tave.wt.2010)
table.predict [c (64:77), 3] <- seq.nffd
table.predict [64:77, 4] <- mean (data.clean$pas.wt.2010)
table.predict [64:77, 5] <- mean (data.clean$road.dns.27k)
table.predict [64:77, 6] <- "BWBS"
table.predict [64:77, 7] <- "Average Road Density"
table.predict [78:91, 1] <- "Mountain"
table.predict [78:91, 2] <- mean (data.clean$tave.wt.2010)
table.predict [78:91, 3] <- seq.nffd
table.predict [78:91, 4] <- mean (data.clean$pas.wt.2010)
table.predict [78:91, 5] <- mean (data.clean$road.dns.27k)
table.predict [78:91, 6] <- "ESSF"
table.predict [78:91, 7] <- "Average Road Density"
table.predict [92:105, 1] <- "Northern"
table.predict [92:105, 2] <- mean (data.clean$tave.wt.2010)
table.predict [92:105, 3] <- seq.nffd
table.predict [92:105, 4] <- mean (data.clean$pas.wt.2010)
table.predict [92:105, 5] <- mean (data.clean$road.dns.27k)
table.predict [92:105, 6] <- "ESSF"
table.predict [92:105, 7] <- "Average Road Density"
table.predict [106:126, 1] <- "Boreal"
table.predict [106:126, 2] <- mean (data.clean$tave.wt.2010)
table.predict [106:126, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [106:126, 4] <- seq.pas.boreal
table.predict [106:126, 5] <- mean (data.clean$road.dns.27k)
table.predict [106:126, 6] <- "BWBS"
table.predict [106:126, 7] <- "Average Road Density"
table.predict [127:147, 1] <- "Mountain"
table.predict [127:147, 2] <- mean (data.clean$tave.wt.2010)
table.predict [127:147, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [127:147, 4] <- seq.pas.non.bor
table.predict [127:147, 5] <- mean (data.clean$road.dns.27k)
table.predict [127:147, 6] <- "ESSF"
table.predict [127:147, 7] <- "Average Road Density"
table.predict [148:168, 1] <- "Northern"
table.predict [148:168, 2] <- mean (data.clean$tave.wt.2010)
table.predict [148:168, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [148:168, 4] <- seq.pas.non.bor
table.predict [148:168, 5] <- mean (data.clean$road.dns.27k)
table.predict [148:168, 6] <- "ESSF"
table.predict [148:168, 7] <- "Average Road Density"
table.predict [169:185, 1] <- "Boreal"
table.predict [169:185, 2] <- mean (data.clean$tave.wt.2010)
table.predict [169:185, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [169:185, 4] <- mean (data.clean$pas.wt.2010)
table.predict [169:185, 5] <- seq.rds 
table.predict [169:185, 6] <- "BWBS"
table.predict [169:185, 7] <- "Average Road Density"
table.predict [186:202, 1] <- "Mountain"
table.predict [186:202, 2] <- mean (data.clean$tave.wt.2010)
table.predict [186:202, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [186:202, 4] <- mean (data.clean$pas.wt.2010)
table.predict [186:202, 5] <- seq.rds
table.predict [186:202, 6] <- "ESSF"
table.predict [186:202, 7] <- "Average Road Density"
table.predict [203:219, 1] <- "Northern"
table.predict [203:219, 2] <- mean (data.clean$tave.wt.2010)
table.predict [203:219, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [203:219, 4] <- mean (data.clean$pas.wt.2010)
table.predict [203:219, 5] <- seq.rds
table.predict [203:219, 6] <- "ESSF"
table.predict [203:219, 7] <- "Average Road Density"
table.predict [220:240, 1] <- "Boreal"
table.predict [c (220:240), 2] <- seq.temp
table.predict [220:240, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [220:240, 4] <- mean (data.clean$pas.wt.2010)
table.predict [220:240, 5] <- mean (data.clean$road.dns.27k) - sd (data.clean$road.dns.27k)
table.predict [220:240, 6] <- "BWBS"
table.predict [220:240, 7] <- "Low Road Density"
table.predict [241:261, 1] <- "Mountain"
table.predict [c (241:261), 2] <- seq.temp
table.predict [241:261, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [241:261, 4] <- mean (data.clean$pas.wt.2010)
table.predict [241:261, 5] <- mean (data.clean$road.dns.27k) - sd (data.clean$road.dns.27k)
table.predict [241:261, 6] <- "ESSF"
table.predict [241:261, 7] <- "Low Road Density"
table.predict [262:282, 1] <- "Northern"
table.predict [c (262:282), 2] <- seq.temp
table.predict [262:282, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [262:282, 4] <- mean (data.clean$pas.wt.2010)
table.predict [262:282, 5] <- mean (data.clean$road.dns.27k) - sd (data.clean$road.dns.27k)
table.predict [262:282, 6] <- "ESSF"
table.predict [262:282, 7] <- "Low Road Density"
table.predict [283:296, 1] <- "Boreal"
table.predict [283:296, 2] <- mean (data.clean$tave.wt.2010) 
table.predict [283:296, 3] <- seq.nffd
table.predict [283:296, 4] <- mean (data.clean$pas.wt.2010)
table.predict [283:296, 5] <- mean (data.clean$road.dns.27k) - sd (data.clean$road.dns.27k)
table.predict [283:296, 6] <- "BWBS"
table.predict [283:296, 7] <- "Low Road Density"
table.predict [297:310, 1] <- "Mountain"
table.predict [297:310, 2] <- mean (data.clean$tave.wt.2010) 
table.predict [297:310, 3] <- seq.nffd
table.predict [297:310, 4] <- mean (data.clean$pas.wt.2010)
table.predict [297:310, 5] <- mean (data.clean$road.dns.27k) - sd (data.clean$road.dns.27k)
table.predict [297:310, 6] <- "ESSF"
table.predict [297:310, 7] <- "Low Road Density"
table.predict [311:324, 1] <- "Northern"
table.predict [311:324, 2] <- mean (data.clean$tave.wt.2010) 
table.predict [311:324, 3] <- seq.nffd
table.predict [311:324, 4] <- mean (data.clean$pas.wt.2010)
table.predict [311:324, 5] <- mean (data.clean$road.dns.27k) - sd (data.clean$road.dns.27k)
table.predict [311:324, 6] <- "ESSF"
table.predict [311:324, 7] <- "Low Road Density"
table.predict [325:345, 1] <- "Boreal"
table.predict [325:345, 2] <- mean (data.clean$tave.wt.2010) 
table.predict [325:345, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [325:345, 4] <- seq.pas.boreal
table.predict [325:345, 5] <- mean (data.clean$road.dns.27k) - sd (data.clean$road.dns.27k)
table.predict [325:345, 6] <- "BWBS"
table.predict [325:345, 7] <- "Low Road Density"
table.predict [346:366, 1] <- "Mountain"
table.predict [346:366, 2] <- mean (data.clean$tave.wt.2010)
table.predict [346:366, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [346:366, 4] <- seq.pas.non.bor
table.predict [346:366, 5] <- mean (data.clean$road.dns.27k) - sd (data.clean$road.dns.27k)
table.predict [346:366, 6] <- "ESSF"
table.predict [346:366, 7] <- "Low Road Density"
table.predict [367:387, 1] <- "Northern"
table.predict [367:387, 2] <- mean (data.clean$tave.wt.2010)
table.predict [367:387, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [367:387, 4] <- seq.pas.non.bor
table.predict [367:387, 5] <- mean (data.clean$road.dns.27k) - sd (data.clean$road.dns.27k)
table.predict [367:387, 6] <- "ESSF"
table.predict [367:387, 7] <- "Low Road Density"
table.predict [388:408, 1] <- "Boreal"
table.predict [388:408, 2] <- seq.temp
table.predict [388:408, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [388:408, 4] <- mean (data.clean$pas.wt.2010)
table.predict [388:408, 5] <- mean (data.clean$road.dns.27k) + sd (data.clean$road.dns.27k)
table.predict [388:408, 6] <- "BWBS"
table.predict [388:408, 7] <- "High Road Density"
table.predict [409:429, 1] <- "Mountain"
table.predict [409:429, 2] <- seq.temp
table.predict [409:429, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [409:429, 4] <- mean (data.clean$pas.wt.2010)
table.predict [409:429, 5] <- mean (data.clean$road.dns.27k) + sd (data.clean$road.dns.27k)
table.predict [409:429, 6] <- "ESSF"
table.predict [409:429, 7] <- "High Road Density"
table.predict [430:450, 1] <- "Northern"
table.predict [430:450, 2] <- seq.temp
table.predict [430:450, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [430:450, 4] <- mean (data.clean$pas.wt.2010)
table.predict [430:450, 5] <- mean (data.clean$road.dns.27k) + sd (data.clean$road.dns.27k)
table.predict [430:450, 6] <- "ESSF"
table.predict [430:450, 7] <- "High Road Density"
table.predict [451:464, 1] <- "Boreal"
table.predict [451:464, 2] <- mean (data.clean$tave.wt.2010) 
table.predict [451:464, 3] <- seq.nffd
table.predict [451:464, 4] <- mean (data.clean$pas.wt.2010)
table.predict [451:464, 5] <- mean (data.clean$road.dns.27k) + sd (data.clean$road.dns.27k)
table.predict [451:464, 6] <- "BWBS"
table.predict [451:464, 7] <- "High Road Density"
table.predict [465:478, 1] <- "Mountain"
table.predict [465:478, 2] <- mean (data.clean$tave.wt.2010) 
table.predict [465:478, 3] <- seq.nffd
table.predict [465:478, 4] <- mean (data.clean$pas.wt.2010)
table.predict [465:478, 5] <- mean (data.clean$road.dns.27k) + sd (data.clean$road.dns.27k)
table.predict [465:478, 6] <- "ESSF"
table.predict [465:478, 7] <- "High Road Density"
table.predict [479:492, 1] <- "Northern"
table.predict [479:492, 2] <- mean (data.clean$tave.wt.2010) 
table.predict [479:492, 3] <- seq.nffd
table.predict [479:492, 4] <- mean (data.clean$pas.wt.2010)
table.predict [479:492, 5] <- mean (data.clean$road.dns.27k) + sd (data.clean$road.dns.27k)
table.predict [479:492, 6] <- "ESSF"
table.predict [479:492, 7] <- "High Road Density"
table.predict [493:513, 1] <- "Boreal"
table.predict [493:513, 2] <- mean (data.clean$tave.wt.2010) 
table.predict [493:513, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [493:513, 4] <- seq.pas.boreal
table.predict [493:513, 5] <- mean (data.clean$road.dns.27k) + sd (data.clean$road.dns.27k)
table.predict [493:513, 6] <- "BWBS"
table.predict [493:513, 7] <- "High Road Density"
table.predict [514:534, 1] <- "Mountain"
table.predict [514:534, 2] <- mean (data.clean$tave.wt.2010)  
table.predict [514:534, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [514:534, 4] <- seq.pas.non.bor
table.predict [514:534, 5] <- mean (data.clean$road.dns.27k) + sd (data.clean$road.dns.27k)
table.predict [514:534, 6] <- "ESSF"
table.predict [514:534, 7] <- "High Road Density"
table.predict [535:555, 1] <- "Northern"
table.predict [535:555, 2] <- mean (data.clean$tave.wt.2010)  
table.predict [535:555, 3] <- mean (data.clean$nffd.sp.2010)
table.predict [535:555, 4] <- seq.pas.non.bor
table.predict [535:555, 5] <- mean (data.clean$road.dns.27k) + sd (data.clean$road.dns.27k)
table.predict [535:555, 6] <- "ESSF"
table.predict [535:555, 7] <- "High Road Density"
table.predict$road.dens <-  as.factor (table.predict$road.dens)
table.bec.curr.simple.factors <- data.frame (levels (data.clean$bec.curr.simple))
table.bec.curr.simple.factors$factor.num <- c (1:14)

table.predict$st.tave.wt.2010 <- (table.predict$tave.wt.2010 - mean (data.clean$tave.wt.2010)) /
  sd (data.clean$tave.wt.2010)
table.predict$st.nffd.sp.2010 <- (table.predict$nffd.sp.2010 - mean (data.clean$nffd.sp.2010)) /
  sd (data.clean$nffd.sp.2010)
table.predict$st.pas.wt.2010 <- (table.predict$pas.wt.2010 - mean (data.clean$pas.wt.2010)) /
  sd (data.clean$pas.wt.2010)
table.predict$st.road.dns.27k <- (table.predict$road.dns.27k - mean (data.clean$road.dns.27k)) /
  sd (data.clean$road.dns.27k)

#=================================
# Predict the models 
#=================================
# lme.pred.all <- predict (get (model.all), newdata = table.predict,
#                            type = 'response',
#                            re.form = NULL, # If NULL, include all random effects; if NA or ~0, include no random effects
#                            allow.new.levels = F) 
# lme.pred.all <- data.frame (lme.pred.all)
# table.predict$top.model.pred <- lme.pred.all
# names (table.predict [ , 12]) <- "top.model.pred"

glm.pred.boreal <- predict (get (model.boreal), newdata = table.predict.boreal,
                             type = 'response') 
glm.pred.boreal <- data.frame (glm.pred.boreal)
table.predict.boreal$top.model.pred <- glm.pred.boreal
names (table.predict.boreal [ , 11]) <- "top.model.pred"

glm.pred.mount <- predict (get (model.mount), newdata = table.predict.mount,
                            type = 'response') 
glm.pred.mount <- data.frame (glm.pred.mount)
table.predict.mount$top.model.pred <- glm.pred.mount
names (table.predict.mount [ , 11]) <- "top.model.pred"

glm.pred.north <- predict (get (model.north), newdata = table.predict.north,
                           type = 'response') 
glm.pred.north <- data.frame (glm.pred.north)
table.predict.north$top.model.pred <- glm.pred.north
names (table.predict.north [ , 11]) <- "top.model.pred"

#=============================================
# Plot the Predictions Across Range of Values
#============================================
####################
# GLMM DO NOT USE #
##################
table.predict.temp <- dplyr::slice (table.predict, c (1:63, 220:282, 388:450))
table.predict.nffd <- dplyr::slice (table.predict, c (64:105, 283:324, 451:492))
table.predict.pas <- dplyr::slice (table.predict, c (106:168, 325:387, 493:555))
table.predict.rd <- dplyr::slice (table.predict, 169:219)

plot.all.temp <- ggplot (table.predict.temp, aes (x = tave.wt.2010, y = top.model.pred, 
                                                  colour = ecotype, shape = road.dens)) +
                          geom_point (aes (shape = road.dens), size = 2.5) +
                          geom_line (aes (colour = ecotype), size = 0.5) +
                          labs (colour = "Ecotype",
                                shape = "Road Density") +
                          xlab ("Average Winter Temperature") +
                          ylab ("Probability of Range Selection") +    
                          theme (axis.text = element_text (size = 12),
                                 axis.title = element_text (size = 14),
                                 axis.line.x = element_line (size = 1),
                                 axis.line.y = element_line (size = 1),
                                 panel.grid.minor = element_line (),
                                 panel.border = element_blank (),
                                 panel.background = element_blank (),
                                 legend.position = c (0.86, 0.28),
                                 legend.key = element_rect (fill = NA),
                                 legend.title = element_text (size = 10),
                                 legend.key.size = unit (0.35, "cm"),
                                 legend.background = element_rect (colour = "black",
                                                                   size = 0.5, 
                                                                   linetype = 'solid'))
ggsave ("plot_alldata_temp_predict_20180514.tif", plot = plot.all.temp, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
          
plot.all.nffd <- ggplot (table.predict.nffd, aes (x = nffd.sp.2010, y = top.model.pred, 
                                                  colour = ecotype, shape = road.dens)) +
                          geom_point (aes (shape = road.dens), size = 2.5) +
                          geom_line (aes (colour = ecotype), size = 1) +
                          labs (colour = "Ecotype",
                                shape = "Road Density") +                        
                          xlab ("Number of Spring Frost Free Days") +
                          ylab ("Probability of Range Selection") +    
                          theme (axis.text = element_text (size = 12),
                                 axis.title = element_text (size = 14),
                                 axis.line.x = element_line (size = 1),
                                 axis.line.y = element_line (size = 1),
                                 panel.grid.minor = element_line (),
                                 panel.border = element_blank (),
                                 panel.background = element_blank (),
                                 legend.position = c (0.55, 0.30),
                                 legend.key = element_rect (fill = NA),
                                 legend.key.size = unit (0.35, "cm"),
                                 legend.box = "horizontal",
                                 legend.background = element_rect (colour = "black",
                                                                   size = 0.5, 
                                                                   linetype = 'solid'))
ggsave ("plot_alldata_nffd_predict_20180514.tif", plot = plot.all.nffd, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.pas <- ggplot (table.predict.pas, aes (x = pas.wt.2010, y = top.model.pred, 
                                                colour = ecotype, shape = road.dens)) +
                          geom_point (aes (shape = road.dens), size = 2.5) +
                          geom_line (aes (colour = ecotype), size = 1) +
                          labs (shape = "Road Density",
                                colour = "Ecotype") +                        
                          xlab ("Winter Precipitation as Snow") +
                          ylab ("Probability of Range Selection") +    
                          theme (axis.text = element_text (size = 12),
                                 axis.title = element_text (size = 14),
                                 axis.line.x = element_line (size = 1),
                                 axis.line.y = element_line (size = 1),
                                 panel.grid.minor = element_line (),
                                 panel.border = element_blank (),
                                 panel.background = element_blank (),
                                 legend.position = c (0.75, 0.17),
                                 legend.key = element_rect (fill = NA),
                                 legend.box = "horizontal",
                                 legend.key.size = unit (0.35, "cm"),
                                 legend.background = element_rect (colour = "black",
                                                                   size = 0.5, 
                                                                   linetype = 'solid'))
ggsave ("plot_alldata_pas_predict_20180514.tif", plot = plot.all.pas, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.rd <- ggplot (table.predict.rd, aes (x = road.dns.27k, y = top.model.pred, 
                                              colour = ecotype)) +
                        geom_point (aes (colour = ecotype), size = 2.5) +
                        geom_line (aes (colour = ecotype), size = 1) +
                        labs (colour = "Ecotype") + 
                        xlab ("Road Density") +
                        ylab ("Probability of Range Selection") +    
                        theme (axis.text = element_text (size = 12),
                               axis.title = element_text (size = 14),
                               axis.line.x = element_line (size = 1),
                               axis.line.y = element_line (size = 1),
                               panel.grid.minor = element_line (),
                               panel.border = element_blank (),
                               panel.background = element_blank (),
                               legend.position = c (0.86, 0.7),
                               legend.key = element_rect (fill = NA),
                               legend.key.size = unit (0.35, "cm"),
                               legend.background = element_rect (colour = "black",
                                                                 size = 0.5, 
                                                                 linetype = 'solid'))
ggsave ("plot_alldata_road_density_predict_20180514.tif", plot = plot.all.rd, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)


###########
# Boreal #
##########
table.predict.boreal.temp <- dplyr::slice (table.predict.boreal, 1:11)
table.predict.boreal.nffd <- dplyr::slice (table.predict.boreal, c (12:37, 67:92, 122:147))
table.predict.boreal.pas <- dplyr::slice (table.predict.boreal, c (38:53, 93:108, 148:163))
table.predict.boreal.rd <- dplyr::slice (table.predict.boreal, c (54:66, 109:121, 164:176))

plot.boreal.temp <- ggplot (table.predict.boreal.temp, aes (x = tave.wt.2010, y = top.model.pred)) +
                            geom_point () + 
                            geom_line () +
                            xlab ("Average Winter Temperature") +
                            ylab ("Probability of Range Selection") +    
                            theme (axis.text = element_text (size = 12),
                                   axis.title = element_text (size = 14),
                                   axis.line.x = element_line (size = 1),
                                   axis.line.y = element_line (size = 1),
                                   panel.grid.minor = element_line (),
                                   panel.border = element_blank (),
                                   panel.background = element_blank ())
ggsave ("plot_boreal_temp_predict_20180514.tif", plot = plot.boreal.temp, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.nffd <- ggplot (table.predict.boreal.nffd, aes (x = nffd.sp.2010, y = top.model.pred,
                                                         colour = Temperature)) +
                          geom_point () +
                          geom_line (aes (colour = Temperature), size = 1) +
                          xlab ("Number of Spring Frost Free Days") +
                          ylab ("Probability of Range Selection") + 
                          labs (colour = "Legend")  +
                          scale_y_continuous (breaks = seq (0, 1, by = 0.1)) +
                          theme (axis.text = element_text (size = 12),
                                 axis.title = element_text (size = 14),
                                 axis.line.x = element_line (size = 1),
                                 axis.line.y = element_line (size = 1),
                                 panel.grid.minor = element_line (),
                                 panel.border = element_blank (),
                                 panel.background = element_blank (),
                                 legend.position = c (0.25, 0.2),
                                 legend.key = element_rect (fill = NA))
ggsave ("plot_boreal_nffd_predict_20180514.tif", plot = plot.all.nffd, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)


plot.all.pas <- ggplot (table.predict.boreal.pas, aes (x = pas.wt.2010, y = top.model.pred,
                                                       colour = Temperature)) +
                        geom_point () +
                        geom_line (aes (colour = Temperature), size = 1) +
                        xlab ("Winter Precipitation as Snow") +
                        ylab ("Probability of Range Selection") +  
                        labs (colour = "Legend")  +
                        scale_y_continuous (breaks = seq (0, 1, by = 0.1)) +
                        scale_x_continuous (breaks = seq (55, 85, by = 5)) +
                        theme (axis.text = element_text (size = 12),
                               axis.title = element_text (size = 14),
                               axis.line.x = element_line (size = 1),
                               axis.line.y = element_line (size = 1),
                               panel.grid.minor = element_line (),
                               panel.border = element_blank (),
                               panel.background = element_blank (),
                               legend.position = c (0.75, 0.2),
                               legend.key = element_rect (fill = NA))
ggsave ("plot_boreal_pas_predict_20180514.tif", plot = plot.all.pas, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.rd <- ggplot (table.predict.boreal.rd, aes (x = road.dns.27k, y = top.model.pred,
                                                     colour = Temperature)) +
                        geom_point () +
                        geom_line (aes (colour = Temperature), size = 1) +
                        xlab ("Road Density") +
                        ylab ("Probability of Range Selection") +    
                        labs (colour = "Legend")  +
                        scale_y_continuous (breaks = seq (0, 1, by = 0.1)) +
                        theme (axis.text = element_text (size = 12),
                               axis.title = element_text (size = 14),
                               axis.line.x = element_line (size = 1),
                               axis.line.y = element_line (size = 1),
                               panel.grid.minor = element_line (),
                               panel.border = element_blank (),
                               panel.background = element_blank (),
                               legend.position = c (0.25, 0.2),
                               legend.key = element_rect (fill = NA))
ggsave ("plot_boreal_road_density_predict_20180514.tif", plot = plot.all.rd, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

#############
# Mountain #
###########
table.predict.mount.temp <- dplyr::slice (table.predict.mount, c (1:20, 67:86, 119:138))
table.predict.mount.nffd <- dplyr::slice (table.predict.mount, 21:34)
table.predict.mount.pas <- dplyr::slice (table.predict.mount, c (35:49, 87:101, 139:153))
table.predict.mount.rd <- dplyr::slice (table.predict.mount, c (50:66, 102:118, 154:170))

plot.mount.temp <- ggplot (table.predict.mount.temp, aes (x = tave.wt.2010, y = top.model.pred,
                                                          colour = nffd.scn)) +
                            geom_point () + 
                            geom_line (aes (colour = nffd.scn), size = 1) +
                            xlab ("Average Winter Temperature") +
                            ylab ("Probability of Range Selection") +    
                            scale_y_continuous (breaks = seq (0, 1, by = 0.1)) +
                            labs (colour = "Legend") +
                            theme (axis.text = element_text (size = 12),
                                   axis.title = element_text (size = 14),
                                   axis.line.x = element_line (size = 1),
                                   axis.line.y = element_line (size = 1),
                                   panel.grid.minor = element_line (),
                                   panel.border = element_blank (),
                                   panel.background = element_blank (),
                                   legend.position = c (0.8, 0.75),
                                   legend.key = element_rect (fill = NA))
ggsave ("plot_mount_temp_predict_20180514.tif", plot = plot.mount.temp, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.nffd <- ggplot (table.predict.mount.nffd, aes (x = nffd.sp.2010, y = top.model.pred)) +
                          geom_point () +
                          geom_line (size = 1) +
                          xlab ("Number of Spring Frost Free Days") +
                          ylab ("Probability of Range Selection") +
                          theme (axis.text = element_text (size = 12),
                                 axis.title = element_text (size = 14),
                                 axis.line.x = element_line (size = 1),
                                 axis.line.y = element_line (size = 1),
                                 panel.grid.minor = element_line (),
                                 panel.border = element_blank (),
                                 panel.background = element_blank (),
                                 legend.position = c (0.25, 0.2),
                                 legend.key = element_rect (fill = NA))
ggsave ("plot_mount_nffd_predict_20180514.tif", plot = plot.all.nffd, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.pas <- ggplot (table.predict.mount.pas, aes (x = pas.wt.2010, y = top.model.pred,
                                                      colour = nffd.scn)) +
                          geom_point () +
                          geom_line (aes (colour = nffd.scn), size = 1) +
                          xlab ("Winter Precipitation as Snow") +
                          ylab ("Probability of Range Selection") +
                          labs (colour = "Legend") +
                          theme (axis.text = element_text (size = 12),
                               axis.title = element_text (size = 14),
                               axis.line.x = element_line (size = 1),
                               axis.line.y = element_line (size = 1),
                               panel.grid.minor = element_line (),
                               panel.border = element_blank (),
                               panel.background = element_blank (),
                               legend.position = c (0.25, 0.8),
                               legend.key = element_rect (fill = NA))
ggsave ("plot_mount_pas_predict_20180514.tif", plot = plot.all.pas, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.rd <- ggplot (table.predict.mount.rd, aes (x = road.dns.27k, y = top.model.pred,
                                                    colour = nffd.scn)) +
                        geom_point () +
                        geom_line (aes (colour = nffd.scn), size = 1) +
                        xlab ("Road Density") +
                        ylab ("Probability of Range Selection") +   
                        labs (colour = "Legend") +
                          theme (axis.text = element_text (size = 12),
                               axis.title = element_text (size = 14),
                               axis.line.x = element_line (size = 1),
                               axis.line.y = element_line (size = 1),
                               panel.grid.minor = element_line (),
                               panel.border = element_blank (),
                               panel.background = element_blank (),
                               legend.position = c (0.75, 0.8),
                               legend.key = element_rect (fill = NA))
ggsave ("plot_mount_road_density_predict_20180514.tif", plot = plot.all.rd, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

############
# Northern #
###########
table.predict.north.temp <- dplyr::slice (table.predict.north, c (1:20, 81:100, 134:153))
table.predict.north.nffd <- dplyr::slice (table.predict.north, c (21:33, 101:113, 154:166))
table.predict.north.pas <- dplyr::slice (table.predict.north, c (34:53, 114:133, 167:186))
table.predict.north.rd <- dplyr::slice (table.predict.north, 54:80)

plot.north.temp <- ggplot (table.predict.north.temp, aes (x = tave.wt.2010, y = top.model.pred,
                                                          colour = road.scn)) +
                            geom_point () + 
                            geom_line (aes (colour = road.scn), size = 1) +
                            scale_y_continuous (breaks = seq (0, 1, by = 0.1)) +
                            scale_x_continuous (breaks = seq (-20, 0, by = 2)) +                          
                            xlab ("Average Winter Temperature") +
                            ylab ("Probability of Range Selection") + 
                            labs (colour = "Legend") +
                            theme (axis.text = element_text (size = 12),
                                   axis.title = element_text (size = 14),
                                   axis.line.x = element_line (size = 1),
                                   axis.line.y = element_line (size = 1),
                                   panel.grid.minor = element_line (),
                                   panel.border = element_blank (),
                                   legend.position = c (0.75, 0.2),
                                   panel.background = element_blank (),
                                   legend.key = element_rect (fill = NA))
ggsave ("plot_north_temp_predict_20180514.tif", plot = plot.north.temp, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.nffd <- ggplot (table.predict.north.nffd, aes (x = nffd.sp.2010, y = top.model.pred,
                                                        colour = road.scn)) +
                        geom_point () +
                        geom_line (aes (colour = road.scn), size = 1) +
                        scale_y_continuous (breaks = seq (0, 1, by = 0.1)) +
                        xlab ("Number of Spring Frost Free Days") +
                        ylab ("Probability of Range Selection") + 
                        labs (colour = "Legend") +
                          theme (axis.text = element_text (size = 12),
                               axis.title = element_text (size = 14),
                               axis.line.x = element_line (size = 1),
                               axis.line.y = element_line (size = 1),
                               panel.grid.minor = element_line (),
                               panel.border = element_blank (),
                               panel.background = element_blank (),
                               legend.position = c (0.25, 0.2),
                               legend.key = element_rect (fill = NA))
ggsave ("plot_north_nffd_predict_20180514.tif", plot = plot.all.nffd, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.pas <- ggplot (table.predict.north.pas, aes (x = pas.wt.2010, y = top.model.pred,
                                                      colour = road.scn)) +
                        geom_point () +
                        geom_line (aes (colour = road.scn), size = 1) +
                        xlab ("Winter Precipitation as Snow") +
                        ylab ("Probability of Range Selection") +
                        labs (colour = "Legend") +
                        theme (axis.text = element_text (size = 12),
                               axis.title = element_text (size = 14),
                               axis.line.x = element_line (size = 1),
                               axis.line.y = element_line (size = 1),
                               panel.grid.minor = element_line (),
                               panel.border = element_blank (),
                               panel.background = element_blank (),
                               legend.position = c (0.25, 0.2),
                               legend.key = element_rect (fill = NA))
ggsave ("plot_north_pas_predict_20180514.tif", plot = plot.all.pas, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.rd <- ggplot (table.predict.north.rd, aes (x = road.dns.27k, y = top.model.pred)) +
                        geom_point () +
                        geom_line (size = 1) +
                        xlab ("Road Density") +
                        ylab ("Probability of Range Selection") +   
                        theme (axis.text = element_text (size = 12),
                               axis.title = element_text (size = 14),
                               axis.line.x = element_line (size = 1),
                               axis.line.y = element_line (size = 1),
                               panel.grid.minor = element_line (),
                               panel.border = element_blank (),
                               panel.background = element_blank (),
                               legend.position = c (0.75, 0.2),
                               legend.key = element_rect (fill = NA))
ggsave ("plot_north_road_density_predict_20180514.tif", plot = plot.all.rd, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)


#==========================================================================================
# Plot the Predictions Across Available Values (Avgar et al. 2017 - Ecology and Evolution)
#==========================================================================================
###########
# Boreal #
##########
data.boreal$st.tave.wt.2010 <- (data.boreal$tave.wt.2010 - mean (data.boreal$tave.wt.2010)) /
                                sd (data.boreal$tave.wt.2010)
data.boreal$st.nffd.sp.2010 <- (data.boreal$nffd.sp.2010 - mean (data.boreal$nffd.sp.2010)) /
                                 sd (data.boreal$nffd.sp.2010)
data.boreal$st.pas.wt.2010 <- (data.boreal$pas.wt.2010 - mean (data.boreal$pas.wt.2010)) /
                                sd (data.boreal$pas.wt.2010)
data.boreal$st.road.dns.27k <- (data.boreal$road.dns.27k - mean (data.boreal$road.dns.27k)) /
                                sd (data.boreal$road.dns.27k)

glm.pred.boreal.all <- predict (get (model.boreal), newdata = data.boreal,
                            type = 'response') 
glm.pred.boreal.all <- data.frame (glm.pred.boreal.all)
data.boreal$top.model.pred <- glm.pred.boreal.all
names (data.boreal [ , 79]) <- "top.model.pred"

data.boreal.low.temp <- dplyr::filter (data.boreal, tave.wt.2010 < -17.5)
data.boreal.mod.temp <- dplyr::filter (data.boreal, tave.wt.2010 >= -17.5 | tave.wt.2010 <= -12.5)
data.boreal.hi.temp <- dplyr::filter (data.boreal, tave.wt.2010 > -12.5)

plot.boreal.temp.data <- ggplot (data.boreal, aes (x = tave.wt.2010, y = top.model.pred)) +
                                  geom_point () + 
                                  geom_smooth (aes (x = tave.wt.2010, y = top.model.pred),
                                               method = "auto", colour = "blue")  +
                                  xlab ("Average Winter Temperature") +
                                  ylab ("Probability of Range Selection") +    
                                  theme (axis.text = element_text (size = 12),
                                         axis.title = element_text (size = 14),
                                         axis.line.x = element_line (size = 1),
                                         axis.line.y = element_line (size = 1),
                                         panel.grid.minor = element_line (),
                                         panel.border = element_blank (),
                                         panel.background = element_blank ())
ggsave ("plot_boreal_temp_predict_data_20180523.tif", plot = plot.boreal.temp.data, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.nffd.data <- ggplot (data.boreal, aes (x = nffd.sp.2010, y = top.model.pred)) +
                                geom_point () +
                                geom_smooth (aes (x = nffd.sp.2010, y = top.model.pred),
                                             method = "auto",
                                             data = data.boreal.low.temp, colour = "blue") +
                                geom_smooth (aes (x = nffd.sp.2010, y = top.model.pred),
                                             method = "auto",
                                             data = data.boreal.mod.temp, colour = "green") +                                
                                geom_smooth (aes (x = nffd.sp.2010, y = top.model.pred),
                                             method = "auto",
                                             data = data.boreal.hi.temp, colour = "red") +
                                xlab ("Number of Spring Frost Free Days") +
                                ylab ("Probability of Range Selection") +
                                scale_y_continuous (breaks = seq (0, 1, by = 0.1),
                                                    limits = c (0, 1)) +
                                theme (axis.text = element_text (size = 12),
                                       axis.title = element_text (size = 14),
                                       axis.line.x = element_line (size = 1),
                                       axis.line.y = element_line (size = 1),
                                       panel.grid.minor = element_line (),
                                       panel.border = element_blank (),
                                       panel.background = element_blank ())
ggsave ("plot_boreal_nffd_predict_data_20180523.tif", plot = plot.all.nffd.data, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.pas.data <- ggplot (data.boreal, aes (x = pas.wt.2010, y = top.model.pred)) +
                              geom_point () +
                              geom_smooth (aes (x = pas.wt.2010, y = top.model.pred),
                                           method = "auto",
                                           data = data.boreal.low.temp, colour = "blue") +
                              geom_smooth (aes (x = pas.wt.2010, y = top.model.pred),
                                           method = "auto",
                                           data = data.boreal.mod.temp, colour = "green") +                                
                              geom_smooth (aes (x = pas.wt.2010, y = top.model.pred),
                                           method = "auto",
                                           data = data.boreal.hi.temp, colour = "red") +
                              xlab ("Winter Precipitation as Snow") +
                              ylab ("Probability of Range Selection") +  
                              labs (colour = "Legend")  +
                              scale_y_continuous (breaks = seq (0, 1, by = 0.1),
                                                  limits = c (0, 1)) +
                              scale_x_continuous (breaks = seq (55, 85, by = 5)) +
                              theme (axis.text = element_text (size = 12),
                                     axis.title = element_text (size = 14),
                                     axis.line.x = element_line (size = 1),
                                     axis.line.y = element_line (size = 1),
                                     panel.grid.minor = element_line (),
                                     panel.border = element_blank (),
                                     panel.background = element_blank ())
ggsave ("plot_boreal_pas_predict_data_20180523.tif", plot = plot.all.pas.data, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.rd.data <- ggplot (data.boreal, aes (x = road.dns.27k, y = top.model.pred)) +
                              geom_point () +
                              geom_smooth (aes (x = road.dns.27k, y = top.model.pred),
                                           method = "auto",
                                           data = data.boreal.low.temp, colour = "blue") +
                              geom_smooth (aes (x = road.dns.27k, y = top.model.pred),
                                           method = "auto",
                                           data = data.boreal.mod.temp, colour = "green") +                                
                              geom_smooth (aes (x = road.dns.27k, y = top.model.pred),
                                           method = "auto",
                                           data = data.boreal.hi.temp, colour = "red") +
                              xlab ("Road Density") +
                              ylab ("Probability of Range Selection") +    
                              scale_y_continuous (breaks = seq (0, 1, by = 0.1),
                                                  limits = c (0, 1)) +
                              theme (axis.text = element_text (size = 12),
                                     axis.title = element_text (size = 14),
                                     axis.line.x = element_line (size = 1),
                                     axis.line.y = element_line (size = 1),
                                     panel.grid.minor = element_line (),
                                     panel.border = element_blank (),
                                     panel.background = element_blank ())
ggsave ("plot_boreal_road_density_predict_data_20180523.tif", plot = plot.all.rd.data, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)


#############
# Mountain #
###########
data.mount$st.tave.wt.2010 <- (data.mount$tave.wt.2010 - mean (data.mount$tave.wt.2010)) /
                                sd (data.mount$tave.wt.2010)
data.mount$st.nffd.sp.2010 <- (data.mount$nffd.sp.2010 - mean (data.mount$nffd.sp.2010)) /
                                sd (data.mount$nffd.sp.2010)
data.mount$st.pas.wt.2010 <- (data.mount$pas.wt.2010 - mean (data.mount$pas.wt.2010)) /
                                sd (data.mount$pas.wt.2010)
data.mount$st.road.dns.27k <- (data.mount$road.dns.27k - mean (data.mount$road.dns.27k)) /
                                sd (data.mount$road.dns.27k)

glm.pred.mount.all <- predict (get (model.mount), newdata = data.mount,
                                type = 'response') 
glm.pred.mount.all <- data.frame (glm.pred.mount.all)
data.mount$top.model.pred <- glm.pred.mount.all
names (data.mount [ , 79]) <- "top.model.pred"

data.mount.low.nffd <- dplyr::filter (data.mount, nffd.sp.2010 < 20)
data.mount.mod.nffd <- dplyr::filter (data.mount, nffd.sp.2010 >= 20 | road.dns.27k <= 40)
data.mount.hi.nffd <- dplyr::filter (data.mount, nffd.sp.2010 > 40)

plot.mount.temp.data <- ggplot (data.mount, aes (x = tave.wt.2010, y = top.model.pred)) +
                                geom_point () + 
                                geom_smooth (aes (x = tave.wt.2010, y = top.model.pred),
                                             method = "auto",
                                             data = data.mount.low.nffd, colour = "blue") +
                                geom_smooth (aes (x = tave.wt.2010, y = top.model.pred),
                                             method = "auto",
                                             data = data.mount.mod.nffd, colour = "green") +                                
                                geom_smooth (aes (x = tave.wt.2010, y = top.model.pred),
                                             method = "auto",
                                             data = data.mount.hi.nffd, colour = "red") +
                                xlab ("Average Winter Temperature") +
                                ylab ("Probability of Range Selection") +    
                                scale_y_continuous (breaks = seq (0, 1, by = 0.1),
                                                    limits = c (0, 1)) +
                                theme (axis.text = element_text (size = 12),
                                       axis.title = element_text (size = 14),
                                       axis.line.x = element_line (size = 1),
                                       axis.line.y = element_line (size = 1),
                                       panel.grid.minor = element_line (),
                                       panel.border = element_blank (),
                                       panel.background = element_blank ())
ggsave ("plot_mount_temp_predict_data_20180514.tif", plot = plot.mount.temp.data, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.nffd.data <- ggplot (data.mount, aes (x = nffd.sp.2010, y = top.model.pred)) +
                              geom_point () +
                              geom_smooth (aes (x = nffd.sp.2010, y = top.model.pred),
                                           method = "auto", colour = "blue") + 
                              xlab ("Number of Spring Frost Free Days") +
                              ylab ("Probability of Range Selection") +
                              scale_y_continuous (breaks = seq (0, 1, by = 0.1),
                                                  limits = c (0, 1)) +
                              theme (axis.text = element_text (size = 12),
                                     axis.title = element_text (size = 14),
                                     axis.line.x = element_line (size = 1),
                                     axis.line.y = element_line (size = 1),
                                     panel.grid.minor = element_line (),
                                     panel.border = element_blank (),
                                     panel.background = element_blank ())
ggsave ("plot_mount_nffd_predict_data_20180514.tif", plot = plot.all.nffd.data, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.pas.data <- ggplot (data.mount, aes (x = pas.wt.2010, y = top.model.pred)) +
                              geom_point () +
                              geom_smooth (aes (x = pas.wt.2010, y = top.model.pred),
                                           method = "auto",
                                           data = data.mount.low.nffd, colour = "blue") +
                              geom_smooth (aes (x = pas.wt.2010, y = top.model.pred),
                                           method = "auto",
                                           data = data.mount.mod.nffd, colour = "green") +                                
                              geom_smooth (aes (x = pas.wt.2010, y = top.model.pred),
                                           method = "auto",
                                           data = data.mount.hi.nffd, colour = "red") +
                              scale_y_continuous (breaks = seq (0, 1, by = 0.1),
                                                  limits = c (0, 1)) +
                              xlab ("Winter Precipitation as Snow") +
                              ylab ("Probability of Range Selection") +
                              theme (axis.text = element_text (size = 12),
                                     axis.title = element_text (size = 14),
                                     axis.line.x = element_line (size = 1),
                                     axis.line.y = element_line (size = 1),
                                     panel.grid.minor = element_line (),
                                     panel.border = element_blank (),
                                     panel.background = element_blank ())
ggsave ("plot_mount_pas_predict_data_20180523.tif", plot = plot.all.pas.data, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.rd.data <- ggplot (data.mount, aes (x = road.dns.27k, y = top.model.pred)) +
                        geom_point () +
                        geom_smooth (aes (x = road.dns.27k, y = top.model.pred),
                                     method = "auto",
                                     data = data.mount.low.nffd, colour = "blue") +
                        geom_smooth (aes (x = road.dns.27k, y = top.model.pred),
                                     method = "auto",
                                     data = data.mount.mod.nffd, colour = "green") +                                
                        geom_smooth (aes (x = road.dns.27k, y = top.model.pred),
                                     method = "auto",
                                     data = data.mount.hi.nffd, colour = "red") +
                        xlab ("Road Density") +
                        ylab ("Probability of Range Selection") +   
                        scale_y_continuous (breaks = seq (0, 1, by = 0.1),
                                            limits = c (0, 1)) +
                        theme (axis.text = element_text (size = 12),
                               axis.title = element_text (size = 14),
                               axis.line.x = element_line (size = 1),
                               axis.line.y = element_line (size = 1),
                               panel.grid.minor = element_line (),
                               panel.border = element_blank (),
                               panel.background = element_blank ())
ggsave ("plot_mount_road_density_predict_data_20180523.tif", plot = plot.all.rd.data, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

############
# Northern #
###########
data.north$st.tave.wt.2010 <- (data.north$tave.wt.2010 - mean (data.north$tave.wt.2010)) /
                               sd (data.north$tave.wt.2010)
data.north$st.nffd.sp.2010 <- (data.north$nffd.sp.2010 - mean (data.north$nffd.sp.2010)) /
                                sd (data.north$nffd.sp.2010)
data.north$st.pas.wt.2010 <- (data.north$pas.wt.2010 - mean (data.north$pas.wt.2010)) /
                                sd (data.north$pas.wt.2010)
data.north$st.road.dns.27k <- (data.north$road.dns.27k - mean (data.north$road.dns.27k)) /
                               sd (data.north$road.dns.27k)

glm.pred.north.all <- predict (get (model.north), newdata = data.north,
                               type = 'response') 
glm.pred.north.all <- data.frame (glm.pred.north.all)
data.north$top.model.pred <- glm.pred.north.all
names (data.north [ , 79]) <- "top.model.pred"

data.north.low.road <- dplyr::filter (data.north, road.dns.27k < 0.5)
data.north.mod.road <- dplyr::filter (data.north, road.dns.27k >= 0.5 | road.dns.27k <= 1.5)
data.north.hi.road <- dplyr::filter (data.north, road.dns.27k > 1.5)

plot.north.temp.data <- ggplot (data.north, aes (x = tave.wt.2010, y = top.model.pred)) +
                                      geom_point () + 
                                      geom_smooth (aes (x = tave.wt.2010, y = top.model.pred),
                                                   method = "auto",
                                                   data = data.north.low.road, colour = "blue") +
                                      geom_smooth (aes (x = tave.wt.2010, y = top.model.pred),
                                                   method = "auto",
                                                   data = data.north.mod.road, colour = "green") +                                
                                      geom_smooth (aes (x = tave.wt.2010, y = top.model.pred),
                                                   method = "auto",
                                                   data = data.north.hi.road, colour = "red") +
                                      scale_y_continuous (breaks = seq (0, 1, by = 0.1),
                                                          limits = c (0, 1)) +                          
                                      xlab ("Average Winter Temperature") +
                                      ylab ("Probability of Range Selection") + 
                                      theme (axis.text = element_text (size = 12),
                                             axis.title = element_text (size = 14),
                                             axis.line.x = element_line (size = 1),
                                             axis.line.y = element_line (size = 1),
                                             panel.grid.minor = element_line (),
                                             panel.border = element_blank (),
                                             panel.background = element_blank ())
ggsave ("plot_north_temp_predict_data_20180523.tif", plot = plot.north.temp.data, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.nffd.data <- ggplot (data.north, aes (x = nffd.sp.2010, y = top.model.pred)) +
                                geom_point () +
                                geom_smooth (aes (x = nffd.sp.2010, y = top.model.pred),
                                             method = "auto",
                                             data = data.north.low.road, colour = "blue") +
                                geom_smooth (aes (x = nffd.sp.2010, y = top.model.pred),
                                             method = "auto",
                                             data = data.north.mod.road, colour = "green") +                                
                                geom_smooth (aes (x = nffd.sp.2010, y = top.model.pred),
                                             method = "auto",
                                             data = data.north.hi.road, colour = "red") +
                                scale_y_continuous (breaks = seq (0, 1, by = 0.1),
                                                    limits = c (0, 1)) +
                                xlab ("Number of Spring Frost Free Days") +
                                ylab ("Probability of Range Selection") + 
                                theme (axis.text = element_text (size = 12),
                                       axis.title = element_text (size = 14),
                                       axis.line.x = element_line (size = 1),
                                       axis.line.y = element_line (size = 1),
                                       panel.grid.minor = element_line (),
                                       panel.border = element_blank (),
                                       panel.background = element_blank ())
ggsave ("plot_north_nffd_predict_data_20180523.tif", plot = plot.all.nffd.data, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.pas.data <- ggplot (data.north, aes (x = pas.wt.2010, y = top.model.pred)) +
                              geom_point () +
                              geom_smooth (aes (x = pas.wt.2010, y = top.model.pred),
                                           method = "auto",
                                           data = data.north.low.road, colour = "blue") +
                              geom_smooth (aes (x = pas.wt.2010, y = top.model.pred),
                                           method = "auto",
                                           data = data.north.mod.road, colour = "green") +                                
                              geom_smooth (aes (x = pas.wt.2010, y = top.model.pred),
                                           method = "auto",
                                           data = data.north.hi.road, colour = "red") +
                              xlab ("Winter Precipitation as Snow") +
                              ylab ("Probability of Range Selection") +
                              scale_y_continuous (breaks = seq (0, 1, by = 0.1),
                                                  limits = c (0, 1)) +
                              theme (axis.text = element_text (size = 12),
                                     axis.title = element_text (size = 14),
                                     axis.line.x = element_line (size = 1),
                                     axis.line.y = element_line (size = 1),
                                     panel.grid.minor = element_line (),
                                     panel.border = element_blank (),
                                     panel.background = element_blank ())
ggsave ("plot_north_pas_predict_data_20180523.tif", plot = plot.all.pas.data, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)

plot.all.rd.data <- ggplot (data.north, aes (x = road.dns.27k, y = top.model.pred)) +
                              geom_point () +
                              geom_smooth (aes (x = road.dns.27k, y = top.model.pred),
                                           method = "auto", colour = "blue") +
                              xlab ("Road Density") +
                              ylab ("Probability of Range Selection") +   
                              scale_y_continuous (breaks = seq (0, 1, by = 0.1),
                                                  limits = c (0, 1)) +
                              theme (axis.text = element_text (size = 12),
                                     axis.title = element_text (size = 14),
                                     axis.line.x = element_line (size = 1),
                                     axis.line.y = element_line (size = 1),
                                     panel.grid.minor = element_line (),
                                     panel.border = element_blank (),
                                     panel.background = element_blank ())
ggsave ("plot_north_road_density_predict_data_20180523.tif", plot = plot.all.rd.data, 
        device = "tiff", path = "C:\\Work\\caribou\\climate_analysis\\figs\\",
        scale = 1, width = 7, height = 5, units = "in", dpi = 300, limitsize = TRUE)
