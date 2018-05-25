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
#  Script Name: 03_regression_analysis_caribou_range.R
#  Script Version: 1.0
#  Script Purpose: Caribou range-scale climate analysis.
#  Script Author: Tyler Muhly, Natural Resource Modeling Specialist, Forest Analysis and 
#                 Inventory Branch, B.C. Ministry of Forests, Lands, and Natural Resource Operations.
#                 Report is located here: 
#  Script Date: 27 March 2018
#  R Version: 3.4.3
#  R Package Versions: 
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
require (dplyr)
require (ggplot2)
require (ggcorrplot)
require (car)
require (MASS)
require (ROCR)
require (lme4)
require (mcgv)
require (rpart)
require (nloptr)
require (arm)
require (sjPlot)
require (sjmisc)
require (lattice)

#=================================
# Load data
#=================================
data <- read.table ("model\\model_data_20180502.csv", header = T, stringsAsFactors = T, sep = ",")

#======================================
# Data cleaning and prep; based on results below
#=====================================
# NA values
# data.na <- data [is.na (data$tave.wt.1990),]
# there are some NA climate variables; visual inspection shows these are on the Alberta/BC border
# so they can be removed
data.clean <- data [complete.cases (data), ]
# removed some winter temp and snow outliers on western edge of study area; 
# rational: these are likely not representative of available habitat to caribou, but are artefacts
# of the smapling area; these areas may be on the fringe of being influenced by coastal climate
data.clean <- data.clean %>%
              filter (pas.wt.2010 < 1000)
data.clean <- data.clean %>%
              filter (tave.wt.2010 < -1)
# removed some negative cutblock values; these are errors due to being on study area edge
data.clean <- data.clean %>%
              filter (cut.perc >= 0)
# if using this covariate; removed extreme severity values at western edge of study area
# data.clean <- data.clean %>%
#               filter (wint.sever.2010 > -13000)

# quadratic term for temperature
data.clean$sq.tave.wt.2010 <- data.clean$tave.wt.2010 * data.clean$tave.wt.2010

# creating BEC class; above variant level
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

# creating new BEC class; variant level
data.clean$bec.curr.var <- as.character (data.clean$bec.current)
data.clean$bec.curr.var [data.clean$bec.curr.var == "BAFAun" | 
                         data.clean$bec.curr.var == "BAFAunp"] <- "BAFAun"
data.clean$bec.curr.var [data.clean$bec.curr.var == "BWBSwk 1" |  
                         data.clean$bec.curr.var == "BWBSwk 2" |   
                         data.clean$bec.curr.var == "BWBSwk 3"] <- "BWBSwk"
data.clean$bec.curr.var [data.clean$bec.curr.var == "CMA un" |
                         data.clean$bec.curr.var == "CMA unp"] <- "CMAun"
data.clean$bec.curr.var [data.clean$bec.curr.var == "CWH ds 2"] <- "CWHds"
data.clean$bec.curr.var [data.clean$bec.curr.var == "CWH ms 2"] <- "CWHms"
data.clean$bec.curr.var [data.clean$bec.curr.var == "CWH vm 1" |
                         data.clean$bec.curr.var == "CWH vm 2"] <- "CWHvm"
data.clean$bec.curr.var [data.clean$bec.curr.var == "CWH ws 1" | 
                         data.clean$bec.curr.var == "CWH ws 2" | 
                         data.clean$bec.curr.var == "CWH ws 2" ] <- "CWHws"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ESSFdc 1" |
                         data.clean$bec.curr.var == "ESSFdc 3"] <- "ESSFdc"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ESSFdk 1" |
                         data.clean$bec.curr.var == "ESSFdk 2" |  
                         data.clean$bec.curr.var == "ESSFdkp" | 
                         data.clean$bec.curr.var == "ESSFdkw" ] <- "ESSFdk"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ESSFmc"  |
                         data.clean$bec.curr.var == "ESSFmcp"] <- "ESSFmc"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ESSFmk"  |
                         data.clean$bec.curr.var == "ESSFmkp"] <- "ESSFmk"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ESSFmm 1"  |
                         data.clean$bec.curr.var == "ESSFmmp"  |
                         data.clean$bec.curr.var == "ESSFmmw"] <- "ESSFmm"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ESSFmv 1"  |
                         data.clean$bec.curr.var == "ESSFmv 2"  |
                         data.clean$bec.curr.var == "ESSFmv 3"  |
                         data.clean$bec.curr.var == "ESSFmv 4"  |
                         data.clean$bec.curr.var == "ESSFmvp"] <- "ESSFmv"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ESSFmw"  |
                         data.clean$bec.curr.var == "ESSFmwp"] <- "ESSFmw"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ESSFun" |
                         data.clean$bec.curr.var == "ESSFunp" ] <- "ESSFun"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ESSFvc"  |
                         data.clean$bec.curr.var == "ESSFvcp"  |
                         data.clean$bec.curr.var == "ESSFvcw" ] <- "ESSFvc"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ESSFwc 2"  |
                         data.clean$bec.curr.var == "ESSFwc 2w"  |
                         data.clean$bec.curr.var == "ESSFwc 3"  |
                         data.clean$bec.curr.var == "ESSFwc 4"  |
                         data.clean$bec.curr.var == "ESSFwcp"  |
                         data.clean$bec.curr.var == "ESSFwcw"] <- "ESSFwc"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ESSFwh 1"  |
                         data.clean$bec.curr.var == "ESSFwh 2"  |
                         data.clean$bec.curr.var == "ESSFwh 3"] <- "ESSFwh"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ESSFwk 1"  |
                         data.clean$bec.curr.var == "ESSFwk 2"] <- "ESSFwk"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ESSFwm"  |
                         data.clean$bec.curr.var == "ESSFwm 2"  |
                         data.clean$bec.curr.var == "ESSFwm 3"  |
                         data.clean$bec.curr.var == "ESSFwm 4"  |
                         data.clean$bec.curr.var == "ESSFwmp"  |
                         data.clean$bec.curr.var == "ESSFwmw"  ] <- "ESSFwm"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ESSFwv"  |
                         data.clean$bec.curr.var == "ESSFwvp"] <- "ESSFwv"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ESSFxv 1"  |
                         data.clean$bec.curr.var == "ESSFxvp"] <- "ESSFxv"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ICH dk"] <- "ICHdk"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ICH dm"] <- "ICHdm"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ICH dw 1" |
                         data.clean$bec.curr.var == "ICH dw 3" |  
                         data.clean$bec.curr.var == "ICH dw 4" ] <- "ICHdw"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ICH mc 1"] <- "ICHmc"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ICH mk 2"  |
                         data.clean$bec.curr.var == "ICH mk 3"  |
                         data.clean$bec.curr.var == "ICH mk 4"] <- "ICHmk"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ICH mm"] <- "ICHmm"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ICH mw 1"  |
                         data.clean$bec.curr.var == "ICH mw 2"  |
                         data.clean$bec.curr.var == "ICH mw 3"  |
                         data.clean$bec.curr.var == "ICH mw 4"  |
                         data.clean$bec.curr.var == "ICH mw 5"  ] <- "ICHmw"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ICH vk 1"  |
                         data.clean$bec.curr.var == "ICH vk 2"] <- "ICHvk"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ICH wc"] <- "ICHwc"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ICH wk 1"  |
                         data.clean$bec.curr.var == "ICH wk 2"  |
                         data.clean$bec.curr.var == "ICH wk 3"  |
                         data.clean$bec.curr.var == "ICH wk 4"  ] <- "ICHwk"
data.clean$bec.curr.var [data.clean$bec.curr.var == "ICH xw"  |
                         data.clean$bec.curr.var == "ICH xw  a"] <- "ICHxw"
data.clean$bec.curr.var [data.clean$bec.curr.var == "IDF dk 4"] <- "IDFdk"
data.clean$bec.curr.var [data.clean$bec.curr.var == "IDF dm 2"] <- "IDFdm"
data.clean$bec.curr.var [data.clean$bec.curr.var == "IDF dw"] <- "IDFdw"
data.clean$bec.curr.var [data.clean$bec.curr.var == "IDF mw 1" |  
                         data.clean$bec.curr.var == "IDF mw 2" ] <- "IDFmw"
data.clean$bec.curr.var [data.clean$bec.curr.var == "IDF ww"] <- "IDFww"
data.clean$bec.curr.var [data.clean$bec.curr.var == "IDF xm"] <- "IDFxm"
data.clean$bec.curr.var [data.clean$bec.curr.var == "IMA un" |
                         data.clean$bec.curr.var == "IMA unp" ] <- "IMAun"
data.clean$bec.curr.var [data.clean$bec.curr.var == "MH  mm 1" |
                         data.clean$bec.curr.var == "MH  mm 2" |
                         data.clean$bec.curr.var == "MH  mmp"] <- "MHmm"
data.clean$bec.curr.var [data.clean$bec.curr.var == "MH  unp" ] <- "MHun"
data.clean$bec.curr.var [data.clean$bec.curr.var == "MS  dc 2"] <- "MSdc"
data.clean$bec.curr.var [data.clean$bec.curr.var == "MS  dk 1" |
                         data.clean$bec.curr.var == "MS  dk 2"] <- "MSdk"
data.clean$bec.curr.var [data.clean$bec.curr.var == "MS  un"] <- "MSun"
data.clean$bec.curr.var [data.clean$bec.curr.var == "MS  xv" ] <- "MSxv"
data.clean$bec.curr.var [data.clean$bec.curr.var == "PP  dh 2" ] <- "PPdh"
data.clean$bec.curr.var [data.clean$bec.curr.var == "SBS dk"] <- "SBSdk"
data.clean$bec.curr.var [ data.clean$bec.curr.var == "SBS dh 1"] <- "SBSdh"
data.clean$bec.curr.var [data.clean$bec.curr.var == "SBS dw 1" | 
                         data.clean$bec.curr.var == "SBS dw 3" ] <- "SBSdw"
data.clean$bec.curr.var [data.clean$bec.curr.var == "SBS mc 1"  |
                         data.clean$bec.curr.var == "SBS mc 2"  |
                         data.clean$bec.curr.var == "SBS mc 3"  ] <- "SBSmc"
data.clean$bec.curr.var [data.clean$bec.curr.var == "SBS mh"] <- "SBSmh"
data.clean$bec.curr.var [data.clean$bec.curr.var == "SBS mk 1"  |
                         data.clean$bec.curr.var == "SBS mk 2"] <- "SBSmk"
data.clean$bec.curr.var [data.clean$bec.curr.var == "SBS mm"] <- "SBSmm"
data.clean$bec.curr.var [data.clean$bec.curr.var == "SBS mw"] <- "SBSmw"
data.clean$bec.curr.var [data.clean$bec.curr.var == "SBS un"] <- "SBSun"
data.clean$bec.curr.var [data.clean$bec.curr.var == "SBS vk"] <- "SBSvk"
data.clean$bec.curr.var [data.clean$bec.curr.var == "SBS wk 1"  |
                         data.clean$bec.curr.var == "SBS wk 2"  |
                         data.clean$bec.curr.var == "SBS wk 3"  |
                         data.clean$bec.curr.var == "SBS wk 3a" ] <- "SBSwk"
data.clean$bec.curr.var [data.clean$bec.curr.var == "SWB mk"  |
                         data.clean$bec.curr.var == "SWB mks"] <- "SWBmk"
data.clean$bec.curr.var [data.clean$bec.curr.var == "SWB un" |
                         data.clean$bec.curr.var == "SWB uns" ] <- "SWBun"
data.clean$bec.curr.var <- as.factor (data.clean$bec.curr.var)

# subset data by ecotype
data.boreal <- dplyr::filter (data.clean, ecotype == "Boreal")
data.north <- dplyr::filter (data.clean, ecotype == "Northern")
data.mount <- dplyr::filter (data.clean, ecotype == "Mountain")

#=================================
# Data exploration/visualization
#=================================
# box plots; nothing too much of concern here; precip values are skewed a bit, and surprisingly 
# suggest caribou may use lower snow areas; outliers may be driving this (see below)
ggplot (data.clean, aes (x = as.factor (pttype), y = tave.wt.2010)) +
        geom_boxplot () +
        xlab ("point type")
ggplot (data.clean, aes (x = as.factor (pttype), y = tmax.wt.2010)) +
        geom_boxplot () +
        xlab ("point type")
ggplot (data.clean, aes (x = as.factor (pttype), y = tmin.wt.2010)) +
        geom_boxplot () +
        xlab ("point type")
ggplot (data.clean, aes (x = as.factor (pttype), y = tave.su.2010)) +
        geom_boxplot () +
        xlab ("point type")
ggplot (data.clean, aes (x = as.factor (pttype), y = tmax.su.2010)) +
        geom_boxplot () +
        xlab ("point type")
ggplot (data.clean, aes (x = as.factor (pttype), y = ppt.wt.2010)) +
        geom_boxplot () +
        xlab ("point type")
ggplot (data.clean, aes (x = as.factor (pttype), y = pas.wt.2010)) +
        geom_boxplot () +
        xlab ("point type")
ggplot (data.clean, aes (x = as.factor (pttype), y = dd.wt.2010)) +
        geom_boxplot () +
        xlab ("point type")
ggplot (data.clean, aes (x = as.factor (pttype), y = dd.sp.2010)) +
        geom_boxplot () +
        xlab ("point type")
ggplot (data.clean, aes (x = as.factor (pttype), y = dd.at.2010)) +
        geom_boxplot () +
        xlab ("point type")
ggplot (data.clean, aes (x = as.factor (pttype), y = nffd.sp.2010)) +
        geom_boxplot () +
        xlab ("point type")
ggplot (data.clean, aes (x = as.factor (pttype), y = nffd.at.2010)) +
        geom_boxplot () +
        xlab ("point type")
ggplot (data.clean, aes (x = as.factor (pttype), y = road.dns.1k)) + # skewed data
        geom_boxplot () +
        xlab ("point type")
ggplot (data.clean, aes (x = as.factor (pttype), y = road.dns.27k)) + # less skewed roads data
        geom_boxplot () +
        xlab ("point type")
ggplot (data.clean, aes (x = as.factor (pttype), y = well.perc)) + # lots of zeros; use only in boreal
        geom_boxplot () +
        xlab ("point type")
ggplot (data.clean, aes (x = as.factor (pttype), y = cut.perc)) + # lots of zeros; skewed; transform?
        geom_boxplot () +
        xlab ("point type")

ggplot (data.clean, aes (x = as.factor (ecotype), y = tave.wt.2010)) +
        geom_boxplot () +
        xlab ("point type") +
        facet_grid ( ~ pttype)
ggplot (data.clean, aes (x = as.factor (ecotype), y = tmax.wt.2010)) +
        geom_boxplot () +
        xlab ("point type") +
        facet_grid ( ~ pttype)
ggplot (data.clean, aes (x = as.factor (ecotype), y = tmin.wt.2010)) +
        geom_boxplot () +
        xlab ("point type") +
        facet_grid ( ~ pttype) 
ggplot (data.clean, aes (x = as.factor (ecotype), y = tave.su.2010)) +
        geom_boxplot () +
        xlab ("point type") +
        facet_grid ( ~ pttype) 
ggplot (data.clean, aes (x = as.factor (ecotype), y = tmax.su.2010)) +
        geom_boxplot () +
        xlab ("point type") +
        facet_grid ( ~ pttype)
ggplot (data.clean, aes (x = as.factor (ecotype), y = ppt.wt.2010)) +
        geom_boxplot () +
        xlab ("point type") +
        facet_grid ( ~ pttype)
ggplot (data.clean, aes (x = as.factor (ecotype), y = pas.wt.2010)) +
        geom_boxplot () +
        xlab ("point type") +
        facet_grid ( ~ pttype) 
ggplot (data.clean, aes (x = as.factor (ecotype), y = dd.wt.2010)) +
        geom_boxplot () +
        xlab ("point type") +
        facet_grid ( ~ pttype) 
ggplot (data.clean, aes (x = as.factor (ecotype), y = dd.sp.2010)) +
        geom_boxplot () +
        xlab ("point type") +
        facet_grid ( ~ pttype) 
ggplot (data.clean, aes (x = as.factor (ecotype), y = dd.at.2010)) +
        geom_boxplot () +
        xlab ("point type") +
        facet_grid ( ~ pttype) 
ggplot (data.clean, aes (x = as.factor (ecotype), y = nffd.sp.2010)) +
        geom_boxplot () +
        xlab ("point type") +
        facet_grid ( ~ pttype) 
ggplot (data.clean, aes (x = as.factor (ecotype), y = nffd.at.2010)) +
        geom_boxplot () +
        xlab ("point type") +
        facet_grid ( ~ pttype)
ggplot (data.clean, aes (x = as.factor (ecotype), y = road.dns.1k)) +
        geom_boxplot () +
        xlab ("point type") +
        facet_grid ( ~ pttype) 
ggplot (data.clean, aes (x = as.factor (ecotype), y = road.dns.27k)) +
        geom_boxplot () +
        xlab ("point type") +
        facet_grid ( ~ pttype) # best for homogenity of variance?
ggplot (data.clean, aes (x = as.factor (ecotype), y = well.perc)) +
        geom_boxplot () +
        xlab ("point type") +
        facet_grid ( ~ pttype) 
ggplot (data.clean, aes (x = as.factor (ecotype), y = cut.perc)) +
        geom_boxplot () +
        xlab ("point type") +
        facet_grid ( ~ pttype) # some cut <0?; these were on edge of study area; delete them

# Cleveland dot plots
dotchart (data.clean$tave.wt.2010) # some high temperature 'outliers' >-1C on the western edge; removed
dotchart (data.clean$tmax.wt.2010)
dotchart (data.clean$tmin.wt.2010)
dotchart (data.clean$tave.su.2010) # some low temperature 'outliers' <3C; didn't remove; these are scattered amongst the range and appear legit
dotchart (data.clean$tmax.su.2010)
dotchart (data.clean$ppt.wt.2010)
dotchart (data.clean$pas.wt.2010) # some high precip 'outliers' >1000 cm at the western edge of the study area; 
                                  # these may be a coastal effect and were deleted
dotchart (data.clean$dd.wt.2010)
dotchart (data.clean$dd.sp.2010)
dotchart (data.clean$dd.at.2010)
dotchart (data.clean$nffd.sp.2010)
dotchart (data.clean$nffd.at.2010)
dotchart (data.clean$road.dns.27k)
dotchart (data.clean$cut.perc)

# Histograms
ggplot (data.clean, aes (x = tave.wt.2010)) + # normal distirbution bang-on for mountain; problematic for boreal and northern
        geom_histogram () +
        facet_grid ( ~ ecotype) +
        theme_bw ()
ggplot (data.clean, aes (x = tmax.wt.2010)) +
        geom_histogram () +
        facet_grid ( ~ ecotype) +
        theme_bw ()
ggplot (data.clean, aes (x = tmin.wt.2010)) +
        geom_histogram () +
        facet_grid ( ~ ecotype) +
        theme_bw ()
ggplot (data.clean, aes (x = tave.su.2010)) +
        geom_histogram () +
        facet_grid ( ~ ecotype) +
        theme_bw ()
ggplot (data.clean, aes (x = tmax.su.2010)) +
        geom_histogram () +
        facet_grid ( ~ ecotype) +
        theme_bw ()
ggplot (data.clean, aes (x = ppt.wt.2010)) +
        geom_histogram () +
        facet_grid ( ~ ecotype) +
        theme_bw ()
ggplot (data.clean, aes (x = pas.wt.2010)) + # ecotype precipitation is fundamentally different; seperate models?
        geom_histogram () +
        facet_grid ( ~ ecotype) +
        theme_bw ()
ggplot (data.clean, aes (x = dd.wt.2010)) + 
        geom_histogram () +
        facet_grid ( ~ ecotype) +
        theme_bw ()
ggplot (data.clean, aes (x = dd.sp.2010)) + 
        geom_histogram () +
        facet_grid ( ~ ecotype) +
        theme_bw ()
ggplot (data.clean, aes (x = dd.at.2010)) + 
        geom_histogram () +
        facet_grid ( ~ ecotype) +
        theme_bw ()
ggplot (data.clean, aes (x = nffd.sp.2010)) + 
        geom_histogram () +
        facet_grid ( ~ ecotype) +
        theme_bw ()
ggplot (data.clean, aes (x = nffd.at.2010)) + 
        geom_histogram () +
        facet_grid ( ~ ecotype) +
        theme_bw ()
ggplot (data.clean, aes (x = road.dns.1k)) +
        geom_histogram () +
        facet_grid ( ~ ecotype) +
        theme_bw ()
ggplot (data.clean, aes (x = road.dns.27k)) + # these data are less skewed
        geom_histogram () +
        facet_grid ( ~ ecotype) +
        theme_bw ()
ggplot (data.clean, aes (x = well.perc)) + # not very useful data
        geom_histogram () +
        facet_grid ( ~ ecotype) +
        theme_bw ()
ggplot (data.clean, aes (x = cut.perc)) +
        geom_histogram () +
        facet_grid ( ~ ecotype) +
        theme_bw ()

# BEC, by ecotype, used/avail
ggplot (data.boreal, aes (x = bec.current, fill = factor (pttype)))+
        geom_bar (position = "dodge") +
        scale_fill_discrete (name = "Point Type",
                             breaks = c (0, 1),
                             labels = c ("Available", "Used")) +
        xlab ("BEC class") +
        ylab ("Count")
ggplot (data.boreal, aes (x = bec.curr.simple, fill = factor (pttype)))+
        geom_bar (position = "dodge") +
        scale_fill_discrete (name = "Point Type",
                             breaks = c (0, 1),
                             labels = c ("Available", "Used")) +
        xlab ("BEC class") +
        ylab ("Count")
ggplot (data.boreal, aes (x = bec.curr.var, fill = factor (pttype)))+
        geom_bar (position = "dodge") +
        scale_fill_discrete (name = "Point Type",
                             breaks = c (0, 1),
                             labels = c ("Available", "Used")) +
        xlab ("BEC class") +
        ylab ("Count")

ggplot (data.north, aes (x = bec.current, fill = factor (pttype)))+
        geom_bar (position = "dodge") +
        scale_fill_discrete (name = "Point Type",
                             breaks = c (0, 1),
                             labels = c ("Available", "Used")) +
        xlab ("BEC class") +
        ylab ("Count") +
        theme (axis.text.x = element_text (angle = 90, hjust = 1))
ggplot (data.north, aes (x = bec.curr.simple, fill = factor (pttype)))+
        geom_bar (position = "dodge") +
        scale_fill_discrete (name = "Point Type",
                             breaks = c (0, 1),
                             labels = c ("Available", "Used")) +
        xlab ("BEC class") +
        ylab ("Count") +
        theme (axis.text.x = element_text (angle = 90, hjust = 1))
ggplot (data.north, aes (x = bec.curr.var, fill = factor (pttype)))+
        geom_bar (position = "dodge") +
        scale_fill_discrete (name = "Point Type",
                             breaks = c (0, 1),
                             labels = c ("Available", "Used")) +
        xlab ("BEC class") +
        ylab ("Count") +
        theme (axis.text.x = element_text (angle = 90, hjust = 1))


ggplot (data.mount, aes (x = bec.current, fill = factor (pttype)))+
        geom_bar (position = "dodge") +
        scale_fill_discrete (name = "Point Type",
                             breaks = c (0, 1),
                             labels = c ("Available", "Used")) +
        xlab ("BEC class") +
        ylab ("Count")  +
        theme (axis.text.x = element_text (angle = 90, hjust = 1))
ggplot (data.mount, aes (x = bec.curr.simple, fill = factor (pttype)))+
        geom_bar (position = "dodge") +
        scale_fill_discrete (name = "Point Type",
                             breaks = c (0, 1),
                             labels = c ("Available", "Used")) +
        xlab ("BEC class") +
        ylab ("Count")  +
        theme (axis.text.x = element_text (angle = 90, hjust = 1))
ggplot (data.mount, aes (x = bec.curr.var, fill = factor (pttype)))+
        geom_bar (position = "dodge") +
        scale_fill_discrete (name = "Point Type",
                             breaks = c (0, 1),
                             labels = c ("Available", "Used")) +
        xlab ("BEC class") +
        ylab ("Count")  +
        theme (axis.text.x = element_text (angle = 90, hjust = 1))

# use top-level BEC for habitat; variants and subvariants have too many classes and some are too rare
# to calculate a 'stable' model
# use BWBS as reference class; it appears in all types; although rare in mountain

# Correlations
data.corr <- data.clean [c (2, 22:33, 70:73)]
corr <- round (cor (data.corr), 3)
p.mat <- round (cor_pmat (data.corr), 2)
ggcorrplot (corr, type = "lower", lab = TRUE, tl.cex = 10,  lab_size = 3)
# ggcorrplot (corr, type = "lower", p.mat = p.mat, insig = "blank")

# remove a covariate if corr > 0.7
# within season temperatures are highly correlated; use average for season
# precips are correlated; use precip as snow in winter
# winter dd is correlated with winter temp; use winter temp
# spring degree days correlated with summer temp, but <0.7
# autumn degree days correlated with winter temp; use winter temp
# spring frost free days correlated with summer temp and spring degree days; use spring frost free days
# autumn frost free days correlated with summer temp, spring frost free days and spring degree days; use spring frost free days
# don't use wells data; too many zeros

# fit models with:
# average winter temp
# precipt as snow
# spring frost free days
# road density 27km
# cutblock percentage

#==========================================================
# STANDARDIZE DATA (x-mean/SD) to facilicate model fitting
#==========================================================
data.boreal$st.tave.wt.2010 <- (data.boreal$tave.wt.2010 - mean (data.boreal$tave.wt.2010)) /
                                sd (data.boreal$tave.wt.2010)
data.boreal$st.nffd.sp.2010 <- (data.boreal$nffd.sp.2010 - mean (data.boreal$nffd.sp.2010)) /
                                sd (data.boreal$nffd.sp.2010)
data.boreal$st.pas.wt.2010 <- (data.boreal$pas.wt.2010 - mean (data.boreal$pas.wt.2010)) /
                               sd (data.boreal$pas.wt.2010)
data.boreal$st.road.dns.27k <- (data.boreal$road.dns.27k - mean (data.boreal$road.dns.27k)) /
                                sd (data.boreal$road.dns.27k)
data.boreal$st.cut.perc <- (data.boreal$cut.perc - mean (data.boreal$cut.perc)) /
                            sd (data.boreal$cut.perc)
data.boreal$st.sq.tave.wt.2010 <- (data.boreal$sq.tave.wt.2010 - mean (data.boreal$sq.tave.wt.2010)) /
                                   sd (data.boreal$sq.tave.wt.2010)

data.mount$st.tave.wt.2010 <- (data.mount$tave.wt.2010 - mean (data.mount$tave.wt.2010)) /
                                sd (data.mount$tave.wt.2010)
data.mount$st.nffd.sp.2010 <- (data.mount$nffd.sp.2010 - mean (data.mount$nffd.sp.2010)) /
                               sd (data.mount$nffd.sp.2010)
data.mount$st.pas.wt.2010 <- (data.mount$pas.wt.2010 - mean (data.mount$pas.wt.2010)) /
                              sd (data.mount$pas.wt.2010)
data.mount$st.road.dns.27k <- (data.mount$road.dns.27k - mean (data.mount$road.dns.27k)) /
                               sd (data.mount$road.dns.27k)
data.mount$st.cut.perc <- (data.mount$cut.perc - mean (data.mount$cut.perc)) /
                           sd (data.mount$cut.perc)
data.mount$st.sq.tave.wt.2010 <- (data.mount$sq.tave.wt.2010 - mean (data.mount$sq.tave.wt.2010)) /
                                  sd (data.mount$sq.tave.wt.2010)

data.north$st.tave.wt.2010 <- (data.north$tave.wt.2010 - mean (data.north$tave.wt.2010)) /
                               sd (data.north$tave.wt.2010)
data.north$st.nffd.sp.2010 <- (data.north$nffd.sp.2010 - mean (data.north$nffd.sp.2010)) /
                               sd (data.north$nffd.sp.2010)
data.north$st.pas.wt.2010 <- (data.north$pas.wt.2010 - mean (data.north$pas.wt.2010)) /
                              sd (data.north$pas.wt.2010)
data.north$st.road.dns.27k <- (data.north$road.dns.27k - mean (data.north$road.dns.27k)) /
                               sd (data.north$road.dns.27k)
data.north$st.cut.perc <- (data.north$cut.perc - mean (data.north$cut.perc)) /
                           sd (data.north$cut.perc)
data.north$st.sq.tave.wt.2010 <- (data.north$sq.tave.wt.2010 - mean (data.north$sq.tave.wt.2010)) /
                                  sd (data.north$sq.tave.wt.2010)

data.clean$st.tave.wt.2010 <- (data.clean$tave.wt.2010 - mean (data.clean$tave.wt.2010)) /
                                sd (data.clean$tave.wt.2010)
data.clean$st.nffd.sp.2010 <- (data.clean$nffd.sp.2010 - mean (data.clean$nffd.sp.2010)) /
                                sd (data.clean$nffd.sp.2010)
data.clean$st.pas.wt.2010 <- (data.clean$pas.wt.2010 - mean (data.clean$pas.wt.2010)) /
                               sd (data.clean$pas.wt.2010)
data.clean$st.road.dns.27k <- (data.clean$road.dns.27k - mean (data.clean$road.dns.27k)) /
                                sd (data.clean$road.dns.27k)
data.clean$st.cut.perc <- (data.clean$cut.perc - mean (data.clean$cut.perc)) /
                            sd (data.clean$cut.perc)
data.clean$st.sq.tave.wt.2010 <- (data.clean$sq.tave.wt.2010 - mean (data.clean$sq.tave.wt.2010)) /
                                  sd (data.clean$sq.tave.wt.2010)

#=============================================================================
# Classification and regression trees to see how the covariates relate to use
#=============================================================================
############
## BOREAL ##
############
cart.boreal <- rpart (pttype ~ tave.wt.2010 + nffd.sp.2010 + pas.wt.2010 + road.dns.27k + 
                      cut.perc,
                      data = data.boreal, 
                      method = "class")

summary (cart.boreal)
print (cart.boreal)
plot (cart.boreal, uniform = T)
text (cart.boreal, use.n = T, splits = T, fancy = F)
post (cart.boreal, file = "", uniform = T)

##############
## Mountain ##
##############
cart.mtn <- rpart (pttype ~ tave.wt.2010 + nffd.sp.2010 + pas.wt.2010 + road.dns.27k + 
                   cut.perc,
                   data = data.mount, 
                   method = "class")

summary (cart.mtn)
print (cart.mtn)
plot (cart.mtn, uniform = T)
text (cart.mtn, use.n = T, splits = T, fancy = F)
post (cart.mtn, file = "", uniform = T)

##############
## Northern ##
##############
cart.north <- rpart (pttype ~ tave.wt.2010 + nffd.sp.2010 + pas.wt.2010 + road.dns.27k + 
                     cut.perc,
                     data = data.north, 
                     method = "class")

summary (cart.north)
print (cart.north)
plot (cart.north, uniform = T) 
text (cart.north, use.n = T, splits = T, fancy = F)
post (cart.north, file = "", uniform = T)

# results here suggest interactions between roads, snow and temp 

#=======================================================
# Fit logistic regression and do some diagnostics
#=======================================================
table.aic <- data.frame (matrix (ncol = 6, nrow = 0))
colnames (table.aic) <- c ("Ecotype", "Model Name", "Covariates", "AIC", "AICw", "AUC")
table.aic [1:10, 1] <- "Boreal"
table.aic [11:20, 1] <- "Mountain"
table.aic [21:30, 1] <- "Northern"

table.aic [c (1, 11, 21), 2] <- "Climate, Roads and BEC"
table.aic [c (2, 12, 22), 2] <- "Roads"
table.aic [c (3, 13, 23), 2] <- "Climate"
table.aic [c (4, 14, 24), 2] <- "BEC"
table.aic [c (5, 15, 25), 2] <- "Climate and BEC"
table.aic [c (6, 16, 26), 2] <- "Roads and BEC"
table.aic [c (7, 17, 27), 2] <- "Climate, Roads and BEC with Road Interactions"
table.aic [c (8, 18, 28), 2] <- "Climate, Roads and BEC with Spring Frost Free Days Interactions"
table.aic [c (9, 19, 29), 2] <- "Climate, Roads and BEC with Snow Interactions"
table.aic [c (10, 20, 30), 2] <- "Climate, Roads and BEC with Winter Temperature Interactions"

table.aic [c (1, 11, 21), 3] <- "Average winter temperature, Total precipitation as snow, 
                                 Number of spring frost free days, Road density, BEC zone"
table.aic [c (2, 12, 22), 3] <- "Road density"
table.aic [c (3, 13, 23), 3] <- "Average winter temperature, Total precipitation as snow, 
                                 Number of spring frost free days"
table.aic [c (4, 14, 24), 3] <- "BEC zone"
table.aic [c (5, 15, 25), 3] <- "Average winter temperature, Total precipitation as snow, 
                                 Number of spring frost free days BEC zone"
table.aic [c (6, 16, 26), 3] <- "Road density, BEC zone"
table.aic [c (7, 17, 27), 3] <- "Average winter temperature, Total precipitation as snow, 
                                 Number of spring frost free days, Road density, 
                                 BEC zone, Winter temperature*Road density,
                                 Snow*Road density, Frost free days*Road density"
table.aic [c (8, 18, 28), 3] <- "Average winter temperature, Total precipitation as snow, 
                                 Number of spring frost free days, Road density, 
                                 BEC zone, Winter temperature*Frost free days,
                                 Snow*Frost free days, Road density*Frost free days"
table.aic [c (9, 19, 29), 3] <- "Average winter temperature, Total precipitation as snow, 
                                 Number of spring frost free days, Road density, 
                                 BEC zone, Winter temperature*Snow, Frost free days*Snow, 
                                 Road density*Snow"
table.aic [c (10, 20, 30), 3] <- "Average winter temperature, Total precipitation as snow, 
                                 Number of spring frost free days, Road density, 
                                 BEC zone, Snow*Winter temperature,
                                 Frost free days*Winter temperature, Road density*Winter temperature"

############
## BOREAL ##
############
data.boreal <- within (data.boreal, bec.curr.simple <- relevel (bec.curr.simple, ref = "BWBS"))
model.boreal <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                       bec.curr.simple, 
                     data = data.boreal,
                     family = binomial (link = 'logit'))
model.boreal2 <- glm (pttype ~ st.road.dns.27k, 
                      data = data.boreal,
                      family = binomial (link = 'logit'))
model.boreal3 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010, 
                      data = data.boreal,
                      family = binomial (link = 'logit'))
model.boreal4 <- glm (pttype ~ bec.curr.simple, 
                      data = data.boreal,
                      family = binomial (link = 'logit'))
model.boreal5 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + bec.curr.simple, 
                      data = data.boreal,
                      family = binomial (link = 'logit'))
model.boreal6 <- glm (pttype ~ st.road.dns.27k + bec.curr.simple,
                      data = data.boreal,
                      family = binomial (link = 'logit'))
model.boreal7 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                        bec.curr.simple + 
                        (st.tave.wt.2010*st.road.dns.27k) + (st.nffd.sp.2010*st.road.dns.27k) +
                        (st.pas.wt.2010*st.road.dns.27k), 
                      data = data.boreal,
                      family = binomial (link = 'logit'))
model.boreal8 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                        bec.curr.simple + 
                        (st.tave.wt.2010*st.nffd.sp.2010) + (st.pas.wt.2010*st.nffd.sp.2010) + 
                        (st.road.dns.27k*st.nffd.sp.2010), 
                      data = data.boreal,
                      family = binomial (link = 'logit'))
model.boreal9 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                      bec.curr.simple + 
                        (st.tave.wt.2010*st.pas.wt.2010) + (st.nffd.sp.2010*st.pas.wt.2010) +
                        (st.road.dns.27k*st.pas.wt.2010), 
                      data = data.boreal,
                      family = binomial (link = 'logit'))
model.boreal10 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                       bec.curr.simple + 
                       (st.pas.wt.2010*st.tave.wt.2010) + (st.nffd.sp.2010*st.tave.wt.2010) +
                       (st.road.dns.27k*st.tave.wt.2010), 
                       data = data.boreal,
                       family = binomial (link = 'logit'))

save (model.boreal10, 
      file = "C:\\Work\\caribou\\climate_analysis\\output\\model_boreal_top_fin_20180514.rda")

# collinearity
vif (model.boreal) # all VIFs <2.5; except quadratic
vif (model.boreal2)
vif (model.boreal3) 
vif (model.boreal4) 
vif (model.boreal5) 
vif (model.boreal6) 
vif (model.boreal7) 
vif (model.boreal8) 
vif (model.boreal9) 
vif (model.boreal10) 

# AIC
table.aic [1, 4] <- AIC (model.boreal)
table.aic [2, 4] <- AIC (model.boreal2)
table.aic [3, 4] <- AIC (model.boreal3)
table.aic [4, 4] <- AIC (model.boreal4)
table.aic [5, 4] <- AIC (model.boreal5)
table.aic [6, 4] <- AIC (model.boreal6)
table.aic [7, 4] <- AIC (model.boreal7)
table.aic [8, 4] <- AIC (model.boreal8)
table.aic [9, 4] <- AIC (model.boreal9)
table.aic [10, 4] <- AIC (model.boreal10)

list.aic.like <- c ((exp (-0.5 * (table.aic [1, 4] - min (table.aic [1:10, 4])))), 
                    (exp (-0.5 * (table.aic [2, 4] - min (table.aic [1:10, 4])))),
                    (exp (-0.5 * (table.aic [3, 4] - min (table.aic [1:10, 4])))),
                    (exp (-0.5 * (table.aic [4, 4] - min (table.aic [1:10, 4])))),
                    (exp (-0.5 * (table.aic [5, 4] - min (table.aic [1:10, 4])))),
                    (exp (-0.5 * (table.aic [6, 4] - min (table.aic [1:10, 4])))),
                    (exp (-0.5 * (table.aic [7, 4] - min (table.aic [1:10, 4])))),
                    (exp (-0.5 * (table.aic [8, 4] - min (table.aic [1:10, 4])))),
                    (exp (-0.5 * (table.aic [9, 4] - min (table.aic [1:10, 4])))),
                    (exp (-0.5 * (table.aic [10, 4] - min (table.aic [1:10, 4])))))

table.aic [1, 5] <- round ((exp (-0.5 * (table.aic [1, 4] - min (table.aic [1:10, 4])))) / sum (list.aic.like), 3)
table.aic [2, 5] <- round ((exp (-0.5 * (table.aic [2, 4] - min (table.aic [1:10, 4])))) / sum (list.aic.like), 3)
table.aic [3, 5] <- round ((exp (-0.5 * (table.aic [3, 4] - min (table.aic [1:10, 4])))) / sum (list.aic.like), 3)
table.aic [4, 5] <- round ((exp (-0.5 * (table.aic [4, 4] - min (table.aic [1:10, 4])))) / sum (list.aic.like), 3)
table.aic [5, 5] <- round ((exp (-0.5 * (table.aic [5, 4] - min (table.aic [1:10, 4])))) / sum (list.aic.like), 3)
table.aic [6, 5] <- round ((exp (-0.5 * (table.aic [6, 4] - min (table.aic [1:10, 4])))) / sum (list.aic.like), 3)
table.aic [7, 5] <- round ((exp (-0.5 * (table.aic [7, 4] - min (table.aic [1:10, 4])))) / sum (list.aic.like), 3)
table.aic [8, 5] <- round ((exp (-0.5 * (table.aic [8, 4] - min (table.aic [1:10, 4])))) / sum (list.aic.like), 3)
table.aic [9, 5] <- round ((exp (-0.5 * (table.aic [9, 4] - min (table.aic [1:10, 4])))) / sum (list.aic.like), 3)
table.aic [10, 5] <- round ((exp (-0.5 * (table.aic [10, 4] - min (table.aic [1:10, 4])))) / sum (list.aic.like), 3)

# ROC plot/AUC
pr <- prediction (predict (model.boreal, type = 'response'), data.boreal$pttype)
prf <- performance (pr, measure = "tpr", x.measure = "fpr")
plot (prf)
auc <- performance (pr, measure = "auc")
auc <- auc@y.values[[1]]
table.aic [1, 6] <- auc

pr2 <- prediction (predict (model.boreal2, type = 'response'), data.boreal$pttype)
prf2 <- performance (pr2, measure = "tpr", x.measure = "fpr")
plot (prf2)
auc2 <- performance (pr2, measure = "auc")
auc2 <- auc2@y.values[[1]]
table.aic [2, 6] <- auc2

pr3 <- prediction (predict (model.boreal3, type = 'response'), data.boreal$pttype)
prf3 <- performance (pr3, measure = "tpr", x.measure = "fpr")
plot (prf3)
auc3 <- performance (pr3, measure = "auc")
auc3 <- auc3@y.values[[1]]
table.aic [3, 6] <- auc3

pr4 <- prediction (predict (model.boreal4, type = 'response'), data.boreal$pttype)
prf4 <- performance (pr4, measure = "tpr", x.measure = "fpr")
plot (prf4)
auc4 <- performance (pr4, measure = "auc")
auc4 <- auc4@y.values[[1]]
table.aic [4, 6] <- auc4

pr5 <- prediction (predict (model.boreal5, type = 'response'), data.boreal$pttype)
prf5 <- performance (pr5, measure = "tpr", x.measure = "fpr")
plot (prf5)
auc5 <- performance (pr5, measure = "auc")
auc5 <- auc5@y.values[[1]]
table.aic [5, 6] <- auc5

pr6 <- prediction (predict (model.boreal6, type = 'response'), data.boreal$pttype)
prf6 <- performance (pr6, measure = "tpr", x.measure = "fpr")
plot (prf6)
auc6 <- performance (pr6, measure = "auc")
auc6 <- auc6@y.values[[1]]
table.aic [6, 6] <- auc6

pr7 <- prediction (predict (model.boreal7, type = 'response'), data.boreal$pttype)
prf7 <- performance (pr7, measure = "tpr", x.measure = "fpr")
plot (prf7)
auc7 <- performance (pr7, measure = "auc")
auc7 <- auc7@y.values[[1]]
table.aic [7, 6] <- auc7

pr8 <- prediction (predict (model.boreal8, type = 'response'), data.boreal$pttype)
prf8 <- performance (pr8, measure = "tpr", x.measure = "fpr")
plot (prf8)
auc8 <- performance (pr8, measure = "auc")
auc8 <- auc8@y.values[[1]]
table.aic [8, 6] <- auc8

pr9 <- prediction (predict (model.boreal9, type = 'response'), data.boreal$pttype)
prf9 <- performance (pr9, measure = "tpr", x.measure = "fpr")
plot (prf9)
auc9 <- performance (pr9, measure = "auc")
auc9 <- auc9@y.values[[1]]
table.aic [9, 6] <- auc9

pr10 <- prediction (predict (model.boreal10, type = 'response'), data.boreal$pttype)
prf10 <- performance (pr10, measure = "tpr", x.measure = "fpr")
plot (prf10)
auc10 <- performance (pr10, measure = "auc")
auc10 <- auc10@y.values[[1]]
table.aic [10, 6] <- auc10

# residual plots of 'top' model
model.boreal.resid.partial <- data.frame (residuals.glm (model.boreal10, type = "partial")) # calculate partial residuals
plot (predict (model.boreal10, type = 'response'), residuals.glm (model.boreal10, type = "pearson")) # should be mostly a straight line
plot (data.boreal$st.tave.wt.2010, model.boreal.resid.partial$st.tave.wt.2010) # shows effect of covariate
plot (data.boreal$st.pas.wt.2010, model.boreal.resid.partial$st.pas.wt.2010)
plot (data.boreal$st.nffd.sp.2010, model.boreal.resid.partial$st.nffd.sp.2010)
plot (data.boreal$st.road.dns.27k, model.boreal.resid.partial$st.road.dns.27k) 

plot (data.boreal$st.tave.wt.2010, predict (model.boreal10, type = 'response')) # shoudl this be quadratic?
plot (data.boreal$st.pas.wt.2010, predict (model.boreal10, type = 'response')) 
plot (data.boreal$st.nffd.sp.2010, predict (model.boreal10, type = 'response')) 
plot (data.boreal$st.road.dns.27k, predict (model.boreal10, type = 'response')) 

# model coefficients table
table.coef.boreal <- data.frame (round (summary.glm (model.boreal10)$coefficients, 5))
write.table (table.coef.boreal, file = "C:\\Work\\caribou\\climate_analysis\\output\\table_coef_boreal.csv",
             sep = ",")

##############
## MOUNTAIN ##
##############
data.mount <- within (data.mount, bec.curr.simple <- relevel (bec.curr.simple, ref = "ESSF"))
model.mount <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                       bec.curr.simple, 
                     data = data.mount,
                     family = binomial (link = 'logit'))
model.mount2 <- glm (pttype ~ st.road.dns.27k, 
                      data = data.mount,
                      family = binomial (link = 'logit'))
model.mount3 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010, 
                      data = data.mount,
                      family = binomial (link = 'logit'))
model.mount4 <- glm (pttype ~ bec.curr.simple, 
                      data = data.mount,
                      family = binomial (link = 'logit'))
model.mount5 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + bec.curr.simple, 
                      data = data.mount,
                      family = binomial (link = 'logit'))
model.mount6 <- glm (pttype ~ st.road.dns.27k + bec.curr.simple,
                      data = data.mount,
                      family = binomial (link = 'logit'))
model.mount7 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                        bec.curr.simple + 
                        (st.tave.wt.2010*st.road.dns.27k) + (st.nffd.sp.2010*st.road.dns.27k) +
                        (st.pas.wt.2010*st.road.dns.27k), 
                      data = data.mount,
                      family = binomial (link = 'logit'))
model.mount8 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                        bec.curr.simple + 
                        (st.tave.wt.2010*st.nffd.sp.2010) + (st.pas.wt.2010*st.nffd.sp.2010) + 
                        (st.road.dns.27k*st.nffd.sp.2010), 
                      data = data.mount,
                      family = binomial (link = 'logit'))
model.mount9 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                        bec.curr.simple + 
                        (st.tave.wt.2010*st.pas.wt.2010) + (st.nffd.sp.2010*st.pas.wt.2010) +
                        (st.road.dns.27k*st.pas.wt.2010), 
                      data = data.mount,
                      family = binomial (link = 'logit'))
model.mount10 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                         bec.curr.simple + 
                         (st.pas.wt.2010*st.tave.wt.2010) + (st.nffd.sp.2010*st.tave.wt.2010) +
                         (st.road.dns.27k*st.tave.wt.2010), 
                       data = data.mount,
                       family = binomial (link = 'logit'))

save (model.mount8, 
      file = "C:\\Work\\caribou\\climate_analysis\\output\\model_mountain_top_fin_20180514.rda")

# collinearity
vif (model.mount) # all VIFs <10; spring frost free days a bit inflated
vif (model.mount2)
vif (model.mount3) 
vif (model.mount4) 
vif (model.mount5) 
vif (model.mount6) 
vif (model.mount7) 
vif (model.mount8) 
vif (model.mount9) 
vif (model.mount10) 

# AIC
table.aic [11, 4] <- AIC (model.mount)
table.aic [12, 4] <- AIC (model.mount2)
table.aic [13, 4] <- AIC (model.mount3)
table.aic [14, 4] <- AIC (model.mount4)
table.aic [15, 4] <- AIC (model.mount5)
table.aic [16, 4] <- AIC (model.mount6)
table.aic [17, 4] <- AIC (model.mount7)
table.aic [18, 4] <- AIC (model.mount8)
table.aic [19, 4] <- AIC (model.mount9)
table.aic [20, 4] <- AIC (model.mount10)

list.aic.like <- c ((exp (-0.5 * (table.aic [11, 4] - min (table.aic [11:20, 4])))), 
                    (exp (-0.5 * (table.aic [12, 4] - min (table.aic [11:20, 4])))),
                    (exp (-0.5 * (table.aic [13, 4] - min (table.aic [11:20, 4])))),
                    (exp (-0.5 * (table.aic [14, 4] - min (table.aic [11:20, 4])))),
                    (exp (-0.5 * (table.aic [15, 4] - min (table.aic [11:20, 4])))),
                    (exp (-0.5 * (table.aic [16, 4] - min (table.aic [11:20, 4])))),
                    (exp (-0.5 * (table.aic [17, 4] - min (table.aic [11:20, 4])))),
                    (exp (-0.5 * (table.aic [18, 4] - min (table.aic [11:20, 4])))),
                    (exp (-0.5 * (table.aic [19, 4] - min (table.aic [11:20, 4])))),
                    (exp (-0.5 * (table.aic [20, 4] - min (table.aic [11:20, 4])))))

table.aic [11, 5] <- round ((exp (-0.5 * (table.aic [11, 4] - min (table.aic [11:20, 4])))) / sum (list.aic.like), 3)
table.aic [12, 5] <- round ((exp (-0.5 * (table.aic [12, 4] - min (table.aic [11:20, 4])))) / sum (list.aic.like), 3)
table.aic [13, 5] <- round ((exp (-0.5 * (table.aic [13, 4] - min (table.aic [11:20, 4])))) / sum (list.aic.like), 3)
table.aic [14, 5] <- round ((exp (-0.5 * (table.aic [14, 4] - min (table.aic [11:20, 4])))) / sum (list.aic.like), 3)
table.aic [15, 5] <- round ((exp (-0.5 * (table.aic [15, 4] - min (table.aic [11:20, 4])))) / sum (list.aic.like), 3)
table.aic [16, 5] <- round ((exp (-0.5 * (table.aic [16, 4] - min (table.aic [11:20, 4])))) / sum (list.aic.like), 3)
table.aic [17, 5] <- round ((exp (-0.5 * (table.aic [17, 4] - min (table.aic [11:20, 4])))) / sum (list.aic.like), 3)
table.aic [18, 5] <- round ((exp (-0.5 * (table.aic [18, 4] - min (table.aic [11:20, 4])))) / sum (list.aic.like), 3)
table.aic [19, 5] <- round ((exp (-0.5 * (table.aic [19, 4] - min (table.aic [11:20, 4])))) / sum (list.aic.like), 3)
table.aic [20, 5] <- round ((exp (-0.5 * (table.aic [20, 4] - min (table.aic [11:20, 4])))) / sum (list.aic.like), 3)

# ROC plot/AUC
pr <- prediction (predict (model.mount, type = 'response'), data.mount$pttype)
prf <- performance (pr, measure = "tpr", x.measure = "fpr")
plot (prf)
auc <- performance (pr, measure = "auc")
auc <- auc@y.values[[1]]
table.aic [11, 6] <- auc

pr2 <- prediction (predict (model.mount2, type = 'response'), data.mount$pttype)
prf2 <- performance (pr2, measure = "tpr", x.measure = "fpr")
plot (prf2)
auc2 <- performance (pr2, measure = "auc")
auc2 <- auc2@y.values[[1]]
table.aic [12, 6] <- auc2

pr3 <- prediction (predict (model.mount3, type = 'response'), data.mount$pttype)
prf3 <- performance (pr3, measure = "tpr", x.measure = "fpr")
plot (prf3)
auc3 <- performance (pr3, measure = "auc")
auc3 <- auc3@y.values[[1]]
table.aic [13, 6] <- auc3

pr4 <- prediction (predict (model.mount4, type = 'response'), data.mount$pttype)
prf4 <- performance (pr4, measure = "tpr", x.measure = "fpr")
plot (prf4)
auc4 <- performance (pr4, measure = "auc")
auc4 <- auc4@y.values[[1]]
table.aic [14, 6] <- auc4

pr5 <- prediction (predict (model.mount5, type = 'response'), data.mount$pttype)
prf5 <- performance (pr5, measure = "tpr", x.measure = "fpr")
plot (prf5)
auc5 <- performance (pr5, measure = "auc")
auc5 <- auc5@y.values[[1]]
table.aic [15, 6] <- auc5

pr6 <- prediction (predict (model.mount6, type = 'response'), data.mount$pttype)
prf6 <- performance (pr6, measure = "tpr", x.measure = "fpr")
plot (prf6)
auc6 <- performance (pr6, measure = "auc")
auc6 <- auc6@y.values[[1]]
table.aic [16, 6] <- auc6

pr7 <- prediction (predict (model.mount7, type = 'response'), data.mount$pttype)
prf7 <- performance (pr7, measure = "tpr", x.measure = "fpr")
plot (prf7)
auc7 <- performance (pr7, measure = "auc")
auc7 <- auc7@y.values[[1]]
table.aic [17, 6] <- auc7

pr8 <- prediction (predict (model.mount8, type = 'response'), data.mount$pttype)
prf8 <- performance (pr8, measure = "tpr", x.measure = "fpr")
plot (prf8)
auc8 <- performance (pr8, measure = "auc")
auc8 <- auc8@y.values[[1]]
table.aic [18, 6] <- auc8

pr9 <- prediction (predict (model.mount9, type = 'response'), data.mount$pttype)
prf9 <- performance (pr9, measure = "tpr", x.measure = "fpr")
plot (prf9)
auc9 <- performance (pr9, measure = "auc")
auc9 <- auc9@y.values[[1]]
table.aic [19, 6] <- auc9

pr10 <- prediction (predict (model.mount10, type = 'response'), data.mount$pttype)
prf10 <- performance (pr10, measure = "tpr", x.measure = "fpr")
plot (prf10)
auc10 <- performance (pr10, measure = "auc")
auc10 <- auc10@y.values[[1]]
table.aic [20, 6] <- auc10

# residual plots of 'top' model
model.mount.resid.partial <- data.frame (residuals.glm (model.mount8, type = "partial")) # calculate partial residuals
plot (predict (model.mount8, type = 'response'), residuals.glm (model.mount8, type = "pearson")) # should be mostly a straight line
plot (data.mount$st.tave.wt.2010, model.mount.resid.partial$st.tave.wt.2010) # shows effect of covariate
plot (data.mount$st.pas.wt.2010, model.mount.resid.partial$st.pas.wt.2010)
plot (data.mount$st.nffd.sp.2010, model.mount.resid.partial$st.nffd.sp.2010)
plot (data.mount$st.road.dns.27k, model.mount.resid.partial$st.road.dns.27k) 
plot (data.mount$st.nffd.sp.2010, model.mount.resid.partial$st.nffd.sp.2010)

plot (data.mount$st.tave.wt.2010, predict (model.mount8, type = 'response')) # quadratic?
plot (data.mount$st.pas.wt.2010, predict (model.mount8, type = 'response')) 
plot (data.mount$st.nffd.sp.2010, predict (model.mount8, type = 'response')) 
plot (data.mount$st.road.dns.27k, predict (model.mount8, type = 'response')) 

# model coefficients table
table.coef.mount <- data.frame (round (summary.glm (model.mount8)$coefficients, 5))
write.table (table.coef.mount, file = "C:\\Work\\caribou\\climate_analysis\\output\\table_coef_mount.csv",
             sep = ",")

##############
## NORTHERN ##
##############
data.north <- within (data.north, bec.curr.simple <- relevel (bec.curr.simple, ref = "ESSF"))
model.north <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                       bec.curr.simple, 
                     data = data.north,
                     family = binomial (link = 'logit'))
model.north2 <- glm (pttype ~ st.road.dns.27k, 
                      data = data.north,
                      family = binomial (link = 'logit'))
model.north3 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + 
                       st.pas.wt.2010 , 
                      data = data.north,
                      family = binomial (link = 'logit'))
model.north4 <- glm (pttype ~ bec.curr.simple, 
                      data = data.north,
                      family = binomial (link = 'logit'))
model.north5 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + bec.curr.simple, 
                      data = data.north,
                      family = binomial (link = 'logit'))
model.north6 <- glm (pttype ~ st.road.dns.27k + bec.curr.simple,
                      data = data.north,
                      family = binomial (link = 'logit'))
model.north7 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                        bec.curr.simple +
                        (st.tave.wt.2010*st.road.dns.27k) + (st.nffd.sp.2010*st.road.dns.27k) +
                        (st.pas.wt.2010*st.road.dns.27k), 
                      data = data.north,
                      family = binomial (link = 'logit'))
model.north8 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                        bec.curr.simple +
                        (st.tave.wt.2010*st.nffd.sp.2010) + (st.pas.wt.2010*st.nffd.sp.2010) + 
                        (st.road.dns.27k*st.nffd.sp.2010), 
                      data = data.north,
                      family = binomial (link = 'logit'))
model.north9 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                        bec.curr.simple +
                        (st.tave.wt.2010*st.pas.wt.2010) + (st.nffd.sp.2010*st.pas.wt.2010) +
                        (st.road.dns.27k*st.pas.wt.2010), 
                      data = data.north,
                      family = binomial (link = 'logit'))
model.north10 <- glm (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                         bec.curr.simple +
                         (st.pas.wt.2010*st.tave.wt.2010) + (st.nffd.sp.2010*st.tave.wt.2010) +
                         (st.road.dns.27k*st.tave.wt.2010), 
                       data = data.north,
                       family = binomial (link = 'logit'))

save (model.north7, 
      file = "C:\\Work\\caribou\\climate_analysis\\output\\model_north_top_fin_20180514.rda")

# collinearity
vif (model.north) # all VIFs <10 except BEC
vif (model.north2)
vif (model.north3) 
vif (model.north4) 
vif (model.north5) 
vif (model.north6) 
vif (model.north7) 
vif (model.north8) 
vif (model.north9) 
vif (model.north10) #  bec has VIF >10; but categorical, so  difficult to interpret

# AIC
table.aic [21, 4] <- AIC (model.north)
table.aic [22, 4] <- AIC (model.north2)
table.aic [23, 4] <- AIC (model.north3)
table.aic [24, 4] <- AIC (model.north4)
table.aic [25, 4] <- AIC (model.north5)
table.aic [26, 4] <- AIC (model.north6)
table.aic [27, 4] <- AIC (model.north7)
table.aic [28, 4] <- AIC (model.north8)
table.aic [29, 4] <- AIC (model.north9)
table.aic [30, 4] <- AIC (model.north10)

list.aic.like <- c ((exp (-0.5 * (table.aic [21, 4] - min (table.aic [21:30, 4])))), 
                    (exp (-0.5 * (table.aic [22, 4] - min (table.aic [21:30, 4])))),
                    (exp (-0.5 * (table.aic [23, 4] - min (table.aic [21:30, 4])))),
                    (exp (-0.5 * (table.aic [24, 4] - min (table.aic [21:30, 4])))),
                    (exp (-0.5 * (table.aic [25, 4] - min (table.aic [21:30, 4])))),
                    (exp (-0.5 * (table.aic [26, 4] - min (table.aic [21:30, 4])))),
                    (exp (-0.5 * (table.aic [27, 4] - min (table.aic [21:30, 4])))),
                    (exp (-0.5 * (table.aic [28, 4] - min (table.aic [21:30, 4])))),
                    (exp (-0.5 * (table.aic [29, 4] - min (table.aic [21:30, 4])))),
                    (exp (-0.5 * (table.aic [30, 4] - min (table.aic [21:30, 4])))))

table.aic [21, 5] <- round ((exp (-0.5 * (table.aic [21, 4] - min (table.aic [21:30, 4])))) / sum (list.aic.like), 3)
table.aic [22, 5] <- round ((exp (-0.5 * (table.aic [22, 4] - min (table.aic [21:30, 4])))) / sum (list.aic.like), 3)
table.aic [23, 5] <- round ((exp (-0.5 * (table.aic [23, 4] - min (table.aic [21:30, 4])))) / sum (list.aic.like), 3)
table.aic [24, 5] <- round ((exp (-0.5 * (table.aic [24, 4] - min (table.aic [21:30, 4])))) / sum (list.aic.like), 3)
table.aic [25, 5] <- round ((exp (-0.5 * (table.aic [25, 4] - min (table.aic [21:30, 4])))) / sum (list.aic.like), 3)
table.aic [26, 5] <- round ((exp (-0.5 * (table.aic [26, 4] - min (table.aic [21:30, 4])))) / sum (list.aic.like), 3)
table.aic [27, 5] <- round ((exp (-0.5 * (table.aic [27, 4] - min (table.aic [21:30, 4])))) / sum (list.aic.like), 3)
table.aic [28, 5] <- round ((exp (-0.5 * (table.aic [28, 4] - min (table.aic [21:30, 4])))) / sum (list.aic.like), 3)
table.aic [29, 5] <- round ((exp (-0.5 * (table.aic [29, 4] - min (table.aic [21:30, 4])))) / sum (list.aic.like), 3)
table.aic [30, 5] <- round ((exp (-0.5 * (table.aic [30, 4] - min (table.aic [21:30, 4])))) / sum (list.aic.like), 3)

# ROC plot/AUC
pr <- prediction (predict (model.north, type = 'response'), data.north$pttype)
prf <- performance (pr, measure = "tpr", x.measure = "fpr")
plot (prf)
auc <- performance (pr, measure = "auc")
auc <- auc@y.values[[1]]
table.aic [21, 6] <- auc

pr2 <- prediction (predict (model.north2, type = 'response'), data.north$pttype)
prf2 <- performance (pr2, measure = "tpr", x.measure = "fpr")
plot (prf2)
auc2 <- performance (pr2, measure = "auc")
auc2 <- auc2@y.values[[1]]
table.aic [22, 6] <- auc2

pr3 <- prediction (predict (model.north3, type = 'response'), data.north$pttype)
prf3 <- performance (pr3, measure = "tpr", x.measure = "fpr")
plot (prf3)
auc3 <- performance (pr3, measure = "auc")
auc3 <- auc3@y.values[[1]]
table.aic [23, 6] <- auc3

pr4 <- prediction (predict (model.north4, type = 'response'), data.north$pttype)
prf4 <- performance (pr4, measure = "tpr", x.measure = "fpr")
plot (prf4)
auc4 <- performance (pr4, measure = "auc")
auc4 <- auc4@y.values[[1]]
table.aic [24, 6] <- auc4

pr5 <- prediction (predict (model.north5, type = 'response'), data.north$pttype)
prf5 <- performance (pr5, measure = "tpr", x.measure = "fpr")
plot (prf5)
auc5 <- performance (pr5, measure = "auc")
auc5 <- auc5@y.values[[1]]
table.aic [25, 6] <- auc5

pr6 <- prediction (predict (model.north6, type = 'response'), data.north$pttype)
prf6 <- performance (pr6, measure = "tpr", x.measure = "fpr")
plot (prf6)
auc6 <- performance (pr6, measure = "auc")
auc6 <- auc6@y.values[[1]]
table.aic [26, 6] <- auc6

pr7 <- prediction (predict (model.north7, type = 'response'), data.north$pttype)
prf7 <- performance (pr7, measure = "tpr", x.measure = "fpr")
plot (prf7)
auc7 <- performance (pr7, measure = "auc")
auc7 <- auc7@y.values[[1]]
table.aic [27, 6] <- auc7

pr8 <- prediction (predict (model.north8, type = 'response'), data.north$pttype)
prf8 <- performance (pr8, measure = "tpr", x.measure = "fpr")
plot (prf8)
auc8 <- performance (pr8, measure = "auc")
auc8 <- auc8@y.values[[1]]
table.aic [28, 6] <- auc8

pr9 <- prediction (predict (model.north9, type = 'response'), data.north$pttype)
prf9 <- performance (pr9, measure = "tpr", x.measure = "fpr")
plot (prf9)
auc9 <- performance (pr9, measure = "auc")
auc9 <- auc9@y.values[[1]]
table.aic [29, 6] <- auc9

pr10 <- prediction (predict (model.north10, type = 'response'), data.north$pttype)
prf10 <- performance (pr10, measure = "tpr", x.measure = "fpr")
plot (prf10)
auc10 <- performance (pr10, measure = "auc")
auc10 <- auc10@y.values[[1]]
table.aic [30, 6] <- auc10

# residual plots of 'top' model
model.north.resid.partial <- data.frame (residuals.glm (model.north7, type = "partial")) # calculate partial residuals
plot (predict (model.north7, type = 'response'), residuals.glm (model.north7, type = "pearson")) # should be mostly a straight line
plot (data.north$st.tave.wt.2010, model.north.resid.partial$st.tave.wt.2010) # shows effect of covariate
plot (data.north$st.pas.wt.2010, model.north.resid.partial$st.pas.wt.2010)
plot (data.north$st.nffd.sp.2010, model.north.resid.partial$st.nffd.sp.2010)
plot (data.north$st.road.dns.27k, model.north.resid.partial$st.road.dns.27k) 
plot (data.north$st.nffd.sp.2010, model.north.resid.partial$st.nffd.sp.2010)

plot (data.north$st.tave.wt.2010, predict (model.north7, type = 'response')) # weird result here
plot (data.north$st.pas.wt.2010, predict (model.north7, type = 'response')) 
plot (data.north$st.nffd.sp.2010, predict (model.north7, type = 'response')) 
plot (data.north$st.road.dns.27k, predict (model.north7, type = 'response')) 

# model coefficients table
table.coef.north <- data.frame (round (summary.glm (model.north7)$coefficients, 5))
write.table (table.coef.north, file = "C:\\Work\\caribou\\climate_analysis\\output\\table_coef_north.csv",
             sep = ",")
# AIC table output
write.table (table.aic, file = "C:\\Work\\caribou\\climate_analysis\\output\\table_aic.csv",
             sep = ",")

#==============================================================================
# Mixed model with ecotype as random effect; these didn't work; don't use them
#=============================================================================
data.clean <- within (data.clean, bec.curr.simple <- relevel (bec.curr.simple, ref = "BWBS"))
model.all1 <- glmer (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                     bec.curr.simple +
                     (1 | ecotype ) + (st.tave.wt.2010 | ecotype) + 
                     (st.nffd.sp.2010 | ecotype) + (st.pas.wt.2010 | ecotype) +
                     (st.road.dns.27k | ecotype) + (bec.curr.simple | ecotype), 
                     data = data.clean,
                     family = binomial (link = "logit"),
                     verbose = T, 
                     nAGQ = 0, # should be set to 1 in final model; this setting provides results quicker, but not reliable
                     control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                             optimizer = "nloptwrap", # these settings should provide results quicker
                                             optCtrl = list (maxfun = 2e5))) # 20,000 iterations
model.all2 <- glmer (pttype ~ st.road.dns.27k  +
                       (1 | ecotype ) + 
                       (st.road.dns.27k | ecotype), 
                     data = data.clean,
                     family = binomial (link = "logit"),
                     verbose = T, 
                     nAGQ = 0, # should be set to 1 in final model; this setting provides results quicker, but not reliable
                     control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                             optimizer = "nloptwrap", # these settings should provide results quicker
                                             optCtrl = list (maxfun = 2e5))) # 20,000 iterations
model.all3 <- glmer (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + 
                     st.pas.wt.2010  +
                     (1 | ecotype ) +  (st.tave.wt.2010 | ecotype) +
                     (st.nffd.sp.2010 | ecotype) + (st.pas.wt.2010 | ecotype), 
                     data = data.clean,
                     family = binomial (link = "logit"),
                     verbose = T, 
                     nAGQ = 0, # should be set to 1 in final model; this setting provides results quicker, but not reliable
                     control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                             optimizer = "nloptwrap", # these settings should provide results quicker
                                             optCtrl = list (maxfun = 2e5))) # 20,000 iterations
model.all4 <- glmer (pttype ~ bec.curr.simple +
                       (1 | ecotype ) +  (bec.curr.simple | ecotype), 
                     data = data.clean,
                     family = binomial (link = "logit"),
                     verbose = T, 
                     nAGQ = 0, # should be set to 1 in final model; this setting provides results quicker, but not reliable
                     control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                             optimizer = "nloptwrap", # these settings should provide results quicker
                                             optCtrl = list (maxfun = 2e5))) # 20,000 iterations
model.all5 <- glmer (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + 
                     st.pas.wt.2010 + bec.curr.simple +
                     (1 | ecotype ) + (st.tave.wt.2010 | ecotype) +
                     (st.nffd.sp.2010 | ecotype) + (st.pas.wt.2010 | ecotype) +
                     (bec.curr.simple | ecotype), 
                     data = data.clean,
                     family = binomial (link = "logit"),
                     verbose = T, 
                     nAGQ = 0, # should be set to 1 in final model; this setting provides results quicker, but not reliable
                     control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                             optimizer = "nloptwrap", # these settings should provide results quicker
                                             optCtrl = list (maxfun = 2e5))) # 20,000 iterations
model.all6 <- glmer (pttype ~ st.road.dns.27k + bec.curr.simple +
                     (1 | ecotype ) + (st.road.dns.27k | ecotype) +
                      (bec.curr.simple | ecotype), 
                     data = data.clean,
                     family = binomial (link = "logit"),
                     verbose = T, 
                     nAGQ = 0, # should be set to 1 in final model; this setting provides results quicker, but not reliable
                     control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                             optimizer = "nloptwrap", # these settings should provide results quicker
                                             optCtrl = list (maxfun = 2e5))) # 20,000 iterations
model.all.temp <- glmer (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                          bec.curr.simple +  
                          (st.pas.wt.2010*st.tave.wt.2010) + (st.nffd.sp.2010*st.tave.wt.2010) +
                          (st.road.dns.27k*st.tave.wt.2010) +
                          (1 | ecotype ) + (st.tave.wt.2010 | ecotype) + 
                          (st.nffd.sp.2010 | ecotype) + (st.pas.wt.2010 | ecotype) +
                          (st.road.dns.27k | ecotype) + (bec.curr.simple | ecotype) +
                          (st.pas.wt.2010*st.tave.wt.2010 | ecotype) +
                          (st.nffd.sp.2010*st.tave.wt.2010 | ecotype) +
                          (st.road.dns.27k*st.tave.wt.2010 | ecotype), 
                          data = data.clean,
                          family = binomial (link = "logit"),
                          verbose = T, 
                          nAGQ = 0, # should be set to 1 in final model; this setting provides results quicker, but not reliable
                          control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                  optimizer = "nloptwrap", # these settings should provide results quicker
                                                  optCtrl = list (maxfun = 2e5))) # 20,000 iterations
model.all.ffd <- glmer (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                           bec.curr.simple +  
                           (st.pas.wt.2010*st.nffd.sp.2010) + (st.nffd.sp.2010*st.tave.wt.2010) +
                           (st.road.dns.27k*st.nffd.sp.2010) +
                           (1 | ecotype ) + (st.tave.wt.2010 | ecotype) + 
                           (st.nffd.sp.2010 | ecotype) + (st.pas.wt.2010 | ecotype) +
                           (st.road.dns.27k | ecotype) + (bec.curr.simple | ecotype) +
                           (st.pas.wt.2010*st.nffd.sp.2010 | ecotype) +
                           (st.tave.wt.2010*st.nffd.sp.2010 | ecotype) +
                           (st.road.dns.27k*st.nffd.sp.2010 | ecotype), 
                           data = data.clean,
                           family = binomial (link = "logit"),
                           verbose = T, 
                           nAGQ = 0,
                           control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                   optimizer = "nloptwrap", # these settings should provide results quicker
                                                   optCtrl = list (maxfun = 2e5)))
model.all.rd <- glmer (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                         bec.curr.simple + (st.pas.wt.2010*st.road.dns.27k) + (st.nffd.sp.2010*st.road.dns.27k) +
                         (st.tave.wt.2010*st.road.dns.27k) + (1 | ecotype ) + (st.tave.wt.2010 | ecotype) + 
                         (st.nffd.sp.2010 | ecotype) + (st.pas.wt.2010 | ecotype) + (st.road.dns.27k | ecotype) + 
                         (bec.curr.simple | ecotype) + (st.pas.wt.2010*st.road.dns.27k | ecotype) +
                         (st.tave.wt.2010*st.road.dns.27k | ecotype) + (st.nffd.sp.2010*st.road.dns.27k | ecotype), 
                          data = data.clean,
                          family = binomial (link = "logit"),
                          verbose = T, 
                          nAGQ = 0,
                          control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                  optimizer = "nloptwrap", # these settings should provide results quicker
                                                  optCtrl = list (maxfun = 2e5)))
model.all.snow <- glmer (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                         bec.curr.simple +
                         (st.tave.wt.2010*st.pas.wt.2010) + (st.nffd.sp.2010*st.pas.wt.2010) +
                         (st.road.dns.27k*st.pas.wt.2010) +
                         (1 | ecotype ) + (st.tave.wt.2010 | ecotype) + 
                         (st.nffd.sp.2010 | ecotype) + (st.pas.wt.2010 | ecotype) +
                         (st.road.dns.27k | ecotype) + (bec.curr.simple | ecotype) +
                         (st.tave.wt.2010*st.pas.wt.2010 | ecotype) +
                         (st.nffd.sp.2010*st.pas.wt.2010 | ecotype) +
                         (st.road.dns.27k*st.pas.wt.2010 | ecotype), 
                       data = data.clean,
                       family = binomial (link = "logit"),
                       verbose = T, 
                       nAGQ = 0,
                       control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                               optimizer = "nloptwrap", # these settings should provide results quicker
                                               optCtrl = list (maxfun = 2e5)))
save (model.all.temp, file = "C:\\Work\\caribou\\climate_analysis\\output\\model_all_temp_20180504.rda")
save (model.all.ffd, file = "C:\\Work\\caribou\\climate_analysis\\output\\model_all_ffd_20180504.rda")
save (model.all.rd, file = "C:\\Work\\caribou\\climate_analysis\\output\\model_all_road_20180504.rda")
save (model.all.snow, file = "C:\\Work\\caribou\\climate_analysis\\output\\model_all_snow_20180504.rda")
save (model.all1, file = "C:\\Work\\caribou\\climate_analysis\\output\\model_all1_20180504.rda")
save (model.all2, file = "C:\\Work\\caribou\\climate_analysis\\output\\model_all2_20180504.rda")
save (model.all3, file = "C:\\Work\\caribou\\climate_analysis\\output\\model_all3_20180504.rda")
save (model.all4, file = "C:\\Work\\caribou\\climate_analysis\\output\\model_all4_20180504.rda")
save (model.all5, file = "C:\\Work\\caribou\\climate_analysis\\output\\model_all5_20180504.rda")
save (model.all6, file = "C:\\Work\\caribou\\climate_analysis\\output\\model_all6_20180504.rda")

# AIC/AUC output table
table.all.aic <- data.frame (matrix (ncol = 5, nrow = 0))
colnames (table.all.aic) <- c ("Model Name", "Covariates", "AIC", "AICw", "AUC")
table.all.aic [1, 1] <- "Climate, Roads and BEC"
table.all.aic [2, 1] <- "Roads"
table.all.aic [3, 1] <- "Climate"
table.all.aic [4, 1] <- "BEC"
table.all.aic [5, 1] <- "Climate and BEC"
table.all.aic [6, 1] <- "Roads and BEC"
table.all.aic [7, 1] <- "Climate, Roads and BEC with Road Interactions"
table.all.aic [8, 1] <- "Climate, Roads and BEC with Spring Frost Free Days Interactions"
table.all.aic [9, 1] <- "Climate, Roads and BEC with Snow Interactions"
table.all.aic [10, 1] <- "Climate, Roads and BEC with Winter Temperature Interactions"

table.all.aic [1, 2] <- "Average winter temperature, Total precipitation as snow, 
                        Number of spring frost free days, Road density, BEC zone"
table.all.aic [2, 2] <- "Road density"
table.all.aic [3, 2] <- "Average winter temperature, Total precipitation as snow, 
                          Number of spring frost free days"
table.all.aic [4, 2] <- "BEC zone"
table.all.aic [5, 2] <- "Average winter temperature, Total precipitation as snow, 
                          Number of spring frost free days BEC zone"
table.all.aic [6, 2] <- "Road density, BEC zone"
table.all.aic [7, 2] <- "Average winter temperature, Total precipitation as snow, 
                          Number of spring frost free days, Road density, 
                          BEC zone, Winter temperature*Road density,
                          Snow*Road density, Frost free days*Road density"
table.all.aic [8, 2] <- "Average winter temperature, Total precipitation as snow, 
                        Number of spring frost free days, Road density, 
                        BEC zone, Winter temperature*Frost free days,
                        Snow*Frost free days, Road density*Frost free days"
table.all.aic [9, 2] <- "Average winter temperature, Total precipitation as snow, 
                        Number of spring frost free days, Road density, 
                        BEC zone, Winter temperature*Snow, Frost free days*Snow, 
                        Road density*Snow"
table.all.aic [10, 2] <- "Average winter temperature, Total precipitation as snow, 
                          Number of spring frost free days, Road density, 
                          BEC zone, Snow*Winter temperature,
                          Frost free days*Winter temperature, Road density*Winter temperature"

# AIC
table.all.aic [1, 3] <- AIC (model.all1)
table.all.aic [2, 3] <- AIC (model.all2)
table.all.aic [3, 3] <- AIC (model.all3)
table.all.aic [4, 3] <- AIC (model.all4)
table.all.aic [5, 3] <- AIC (model.all5)
table.all.aic [6, 3] <- AIC (model.all6)
table.all.aic [7, 3] <- AIC (model.all.rd)
table.all.aic [8, 3] <- AIC (model.all.ffd)
table.all.aic [9, 3] <- AIC (model.all.snow)
table.all.aic [10, 3] <- AIC (model.all.temp)

list.aic.like <- c ((exp (-0.5 * (table.all.aic [1, 3] - min (table.all.aic [1:10, 3])))), 
                    (exp (-0.5 * (table.all.aic [2, 3] - min (table.all.aic [1:10, 3])))),
                    (exp (-0.5 * (table.all.aic [3, 3] - min (table.all.aic [1:10, 3])))),
                    (exp (-0.5 * (table.all.aic [4, 3] - min (table.all.aic [1:10, 3])))),
                    (exp (-0.5 * (table.all.aic [5, 3] - min (table.all.aic [1:10, 3])))),
                    (exp (-0.5 * (table.all.aic [6, 3] - min (table.all.aic [1:10, 3])))),
                    (exp (-0.5 * (table.all.aic [7, 3] - min (table.all.aic [1:10, 3])))),
                    (exp (-0.5 * (table.all.aic [8, 3] - min (table.all.aic [1:10, 3])))),
                    (exp (-0.5 * (table.all.aic [9, 3] - min (table.all.aic [1:10, 3])))),
                    (exp (-0.5 * (table.all.aic [10, 3] - min (table.all.aic [1:10, 3])))))

table.all.aic [1, 4] <- round ((exp (-0.5 * (table.all.aic [1, 3] - min (table.all.aic [1:10, 3])))) / sum (list.aic.like), 3)
table.all.aic [2, 4] <- round ((exp (-0.5 * (table.all.aic [2, 3] - min (table.all.aic [1:10, 3])))) / sum (list.aic.like), 3)
table.all.aic [3, 4] <- round ((exp (-0.5 * (table.all.aic [3, 3] - min (table.all.aic [1:10, 3])))) / sum (list.aic.like), 3)
table.all.aic [4, 4] <- round ((exp (-0.5 * (table.all.aic [4, 3] - min (table.all.aic [1:10, 3])))) / sum (list.aic.like), 3)
table.all.aic [5, 4] <- round ((exp (-0.5 * (table.all.aic [5, 3] - min (table.all.aic [1:10, 3])))) / sum (list.aic.like), 3)
table.all.aic [6, 4] <- round ((exp (-0.5 * (table.all.aic [6, 3] - min (table.all.aic [1:10, 3])))) / sum (list.aic.like), 3)
table.all.aic [7, 4] <- round ((exp (-0.5 * (table.all.aic [7, 3] - min (table.all.aic [1:10, 3])))) / sum (list.aic.like), 3)
table.all.aic [8, 4] <- round ((exp (-0.5 * (table.all.aic [8, 3] - min (table.all.aic [1:10, 3])))) / sum (list.aic.like), 3)
table.all.aic [9, 4] <- round ((exp (-0.5 * (table.all.aic [9, 3] - min (table.all.aic [1:10, 3])))) / sum (list.aic.like), 3)
table.all.aic [10, 4] <- round ((exp (-0.5 * (table.all.aic [10, 3] - min (table.all.aic [1:10, 3])))) / sum (list.aic.like), 3)

# AUC
pr.all1 <- prediction (predict (model.all1, type = 'response'), data.clean$pttype)
prf.all1 <- performance (pr.all1, measure = "tpr", x.measure = "fpr")
plot (prf.all1)
auc1 <- performance (pr.all1, measure = "auc")
auc1 <- auc1@y.values[[1]]
table.all.aic [1, 5] <- auc1

pr.all2 <- prediction (predict (model.all2, type = 'response'), data.clean$pttype)
prf.all2 <- performance (pr.all2, measure = "tpr", x.measure = "fpr")
plot (prf.all2)
auc2 <- performance (pr.all2, measure = "auc")
auc2 <- auc2@y.values[[1]]
table.all.aic [2, 5] <- auc2

pr.all3 <- prediction (predict (model.all3, type = 'response'), data.clean$pttype)
prf.all3 <- performance (pr.all3, measure = "tpr", x.measure = "fpr")
plot (prf.all3)
auc3 <- performance (pr.all3, measure = "auc")
auc3 <- auc3@y.values[[1]]
table.all.aic [3, 5] <- auc3

pr.all4 <- prediction (predict (model.all4, type = 'response'), data.clean$pttype)
prf.all4 <- performance (pr.all4, measure = "tpr", x.measure = "fpr")
plot (prf.all4)
auc4 <- performance (pr.all4, measure = "auc")
auc4 <- auc4@y.values[[1]]
table.all.aic [4, 5] <- auc4

pr.all5 <- prediction (predict (model.all5, type = 'response'), data.clean$pttype)
prf.all5 <- performance (pr.all5, measure = "tpr", x.measure = "fpr")
plot (prf.all5)
auc5 <- performance (pr.all5, measure = "auc")
auc5 <- auc5@y.values[[1]]
table.all.aic [5, 5] <- auc5

pr.all6 <- prediction (predict (model.all6, type = 'response'), data.clean$pttype)
prf.all6 <- performance (pr.all6, measure = "tpr", x.measure = "fpr")
plot (prf.all6)
auc6 <- performance (pr.all6, measure = "auc")
auc6 <- auc6@y.values[[1]]
table.all.aic [6, 5] <- auc6

pr.rd <- prediction (predict (model.all.rd, type = 'response'), data.clean$pttype)
prf.rd <- performance (pr.rd, measure = "tpr", x.measure = "fpr")
plot (prf.rd)
auc.rd <- performance (pr.rd, measure = "auc")
auc.rd <- auc.rd@y.values[[1]]
table.all.aic [7, 5] <- auc.rd

pr.ffd <- prediction (predict (model.all.ffd, type = 'response'), data.clean$pttype)
prr.ffd <- performance (pr.ffd, measure = "tpr", x.measure = "fpr")
plot (prr.ffd)
auc.ffd <- performance (pr.ffd, measure = "auc")
auc.ffd <- auc.ffd@y.values[[1]]
table.all.aic [8, 5] <- auc.ffd

pr.snow <- prediction (predict (model.all.snow, type = 'response'), data.clean$pttype)
prf.snow <- performance (pr.snow, measure = "tpr", x.measure = "fpr")
plot (prf.snow)
auc.snow <- performance (pr.snow, measure = "auc")
auc.snow <- auc.snow@y.values[[1]]
table.all.aic [9, 5] <- auc.ffd

pr.temp <- prediction (predict (model.all.temp, type = 'response'), data.clean$pttype)
prf.temp <- performance (pr.temp, measure = "tpr", x.measure = "fpr")
plot (prf.temp)
auc.temp <- performance (pr.temp, measure = "auc")
auc.temp <- auc.temp@y.values[[1]]
table.all.aic [10, 5] <- auc.ffd

# AIC table output
write.table (table.all.aic, file = "C:\\Work\\caribou\\climate_analysis\\output\\table_aic_all_data.csv",
             sep = ",")

#=================================
# Fit plots
#=================================
plot (model.all.rd, type = c ("p", "smooth"))
sjp.lmer (model.all.rd, type = "fe.slope")
sjp.lmer (model.all.rd, type = "pred", vars = "st.tave.wt.2010")
sjp.lmer (model.all.rd, type = "pred", vars = "st.nffd.sp.2010")
sjp.lmer (model.all.rd, type = "pred", vars = "st.pas.wt.2010")
sjp.lmer (model.all.rd, type = "pred", vars = "st.road.dns.27k")

#=================================
# model coeffs output
#=================================
table.vcov.all.top<- as.data.frame (VarCorr (model.all.rd))
write.table (table.vcov.all.top, file = "C:\\Work\\caribou\\climate_analysis\\output\\table_vcov_top_rd.csv",
             sep = ",")
table.fixef.all.top <- as.data.frame (fixef (model.all.rd))
write.table (table.fixef.all.top, file = "C:\\Work\\caribou\\climate_analysis\\output\\table_fixef_top_rd.csv",
             sep = ",")
ranef (model.all.rd)
model.coefs <- coef (model.all.rd)
summary (model.all.rd)


#==============================================
# Re-run the top model with nAGQ =1
#============================================
model.all.rd.fin <- glmer (pttype ~ st.tave.wt.2010 + st.nffd.sp.2010 + st.pas.wt.2010 + st.road.dns.27k + 
                           bec.curr.simple +  
                           (st.pas.wt.2010*st.tave.wt.2010) + (st.nffd.sp.2010*st.tave.wt.2010) +
                           (st.road.dns.27k*st.tave.wt.2010) +
                           (1 | ecotype ) + (st.tave.wt.2010 | ecotype) + 
                           (st.nffd.sp.2010 | ecotype) + (st.pas.wt.2010 | ecotype) +
                           (st.road.dns.27k | ecotype) + (bec.curr.simple | ecotype) +
                           (st.pas.wt.2010*st.road.dns.27k | ecotype) +
                           (st.tave.wt.2010*st.road.dns.27k | ecotype) +
                           (st.nffd.sp.2010*st.road.dns.27k | ecotype), 
                             data = data.clean,
                             family = binomial (link = "logit"),
                             verbose = T, 
                             nAGQ = 1,
                             control = glmerControl (calc.derivs = FALSE, # these settings should provide results quicker
                                                     optimizer = "nloptwrap", # these settings should provide results quicker
                                                     optCtrl = list (maxfun = 2e5)))
   

model.all.rd.fin <- update (model.all.rd, 
                            verbose = T, 
                            nAGQ = 1,
                            start = getME (model.all.rd, 
                                            c ("theta","fixef")),
                            control = glmerControl (calc.derivs = FALSE,
                                                    optimizer = "nloptwrap", 
                                                    optCtrl = list (maxfun = 2e5)))

model.all.rd.fin.bbq <- update (model.all.rd.fin, 
                                start = getME (model.all.rd.fin, 
                                               c ("theta","fixef")),
                                control = glmerControl (optimizer = "bobyqa"))

summary (model.all.rd.fin)


save (model.all.rd.fin, 
      file = "C:\\Work\\caribou\\climate_analysis\\output\\model_all_top_fin_20180511.rda")


#===============================================================================
# "Unified" model across ecotpyes, but with fixed effects only (From Peter Ott)
#==============================================================================
raw.dat <- read.csv (file = "model\\tyler data.csv", stringsAsFactors = T)

#grabbing four specific independent variables
ind.vars <- raw.dat [,c("tave.wt.2010", "nffd.sp.2010", "pas.wt.2010", "road.dns.27k")]  

# Scaling all vars using z-transformation
mean.vars <- apply (ind.vars, 2, mean, na.rm=TRUE) 
sd.vars <- apply (ind.vars, 2, sd, na.rm=TRUE)
scaled.vars <- as.data.frame (scale (ind.vars, center = mean.vars, scale = sd.vars))

#Create dummy variables for ecotype with coding of 0, 1 and -1
dummies <- model.matrix (pttype ~ ecotype, contrasts.arg = list (ecotype = contr.sum), data = raw.dat)
colnames (dummies) <- c ("int","d1","d2")
attributes(dummies)$contrasts

#piecing data back together for fitting glm model & dropping the last obs with some missing vars 
glm.dat <- na.omit (cbind (raw.dat[,c("pttype","ecotype","bec.curr.simple")], 
                           scaled.vars, dummies[,-1]))

#need to ditch missing level from bec factor now that last obs has been removed
glm.dat$bec.curr.simple <- droplevels(glm.dat$bec.curr.simple)
levels(glm.dat$bec.curr.simple)
length(levels(glm.dat$bec.curr.simple))

#fit the glm
glm.fit <- glm (pttype ~  d1 + d2 + bec.curr.simple +
                 tave.wt.2010 + nffd.sp.2010 + pas.wt.2010 + road.dns.27k +
                 tave.wt.2010:road.dns.27k + nffd.sp.2010:road.dns.27k + pas.wt.2010:road.dns.27k +
                 tave.wt.2010:d1 + nffd.sp.2010:d1 + pas.wt.2010:d1 + road.dns.27k:d1 +
                 tave.wt.2010:road.dns.27k:d1 + nffd.sp.2010:road.dns.27k:d1 + pas.wt.2010:road.dns.27k:d1 +
                 tave.wt.2010:d2 + nffd.sp.2010:d2 + pas.wt.2010:d2 + road.dns.27k:d2 +
                 tave.wt.2010:road.dns.27k:d2 + nffd.sp.2010:road.dns.27k:d2 + pas.wt.2010:road.dns.27k:d2,
                family = binomial (link = "logit"), 
                contrasts = list(bec.curr.simple = contr.treatment), data = glm.dat)
summary (glm.fit)

#Estimates for the 'average' curve are:
#(Intercept), bec dummies, tave.wt.2010 , nffd.sp.2010, pas.wt.2010, and interactions
#Coefficients with d1 are deviations from average for ecoptype=="Boreal"
#Coefficients with d2 are deviations from average for ecotype=="Mountain"
#Ecotype=="Northern" deviations are the negative sum of d1 and d2 coefficients
#Note: if you check/test this out with either: (i) a simple model without ecotype dummies, or (ii) individual models for each ecotype
#      the estimates will be a bit off due to the imbalance in ecotype samples and the incomplete levels for bec*ecotype   

#=========================================================
# Fit some GAMs; exploratory alternative
#==========================================================
#############
## Boreal ##
############
model.boreal.gam <- gam (pttype ~ s (st.tave.wt.2010) + s(st.nffd.sp.2010) + s(st.pas.wt.2010) + 
                          s(st.road.dns.27k) + bec.curr.simple + 
                         (st.pas.wt.2010*st.tave.wt.2010) + (st.nffd.sp.2010*st.tave.wt.2010) +
                         (st.road.dns.27k*st.tave.wt.2010), 
                         data = data.boreal,
                         family = binomial (link = 'logit'))
model.boreal.gam.resid.partial <- data.frame (predict (model.boreal.gam, type = "terms") + 
                                              residuals (model.boreal.gam)) # calculate partial residuals
plot (predict (model.boreal.gam, type = 'response'), residuals.gam (model.boreal.gam, type = "pearson")) # should be mostly a straight line
plot (data.boreal$st.tave.wt.2010, model.boreal.gam.resid.partial$s.st.tave.wt.2010.) 
plot (data.boreal$st.road.dns.27k, model.boreal.gam.resid.partial$s.st.road.dns.27k.)
plot (data.boreal$st.nffd.sp.2010, model.boreal.gam.resid.partial$s.st.nffd.sp.2010.)
plot (data.boreal$st.pas.wt.2010, model.boreal.gam.resid.partial$s.st.pas.wt.2010.)

# gam-specific model checks
plot (model.boreal.gam, all.terms = F, residuals = T, pch = 20)  
gam.check (model.boreal.gam) 
vis.gam (model.boreal.gam, view = c ("st.tave.wt.2010", "st.pas.wt.2010"), type = "response",
         plot.type = "contour") 
vis.gam (model.boreal.gam, view = c ( "st.tave.wt.2010", "st.road.dns.27k"), type = "response",
         plot.type = "contour") 
vis.gam (model.boreal.gam, view = c ( "st.tave.wt.2010", "st.nffd.sp.2010"), type = "response",
         plot.type = "contour") 

# fit plots
plot (data.boreal$st.tave.wt.2010, predict (model.boreal.gam, type = 'response'))
plot (data.boreal$st.nffd.sp.2010, predict (model.boreal.gam, type = 'response'))
plot (data.boreal$st.pas.wt.2010, predict (model.boreal.gam, type = 'response'))
plot (data.boreal$st.road.dns.27k, predict (model.boreal.gam, type = 'response'))


##############
## MOUNTAIN ##
##############
model.mount.gam <- gam (pttype ~ s(st.tave.wt.2010) + s(st.nffd.sp.2010) + s(st.pas.wt.2010) + 
                          s(st.road.dns.27k) + bec.curr.simple + 
                           (st.tave.wt.2010*st.nffd.sp.2010) + (st.pas.wt.2010*st.nffd.sp.2010) + 
                           (st.road.dns.27k*st.nffd.sp.2010), 
                         data = data.mount,
                         family = binomial (link = 'logit'))

model.mount.gam.resid.partial <- data.frame (predict (model.mount.gam, type = "terms") + 
                                                residuals (model.mount.gam)) # calculate partial residuals
plot (predict (model.mount.gam, type = 'response'), residuals.gam (model.mount.gam, type = "pearson")) # should be mostly a straight line
plot (data.mount$st.tave.wt.2010, model.mount.gam.resid.partial$s.st.tave.wt.2010.) 
plot (data.mount$st.road.dns.27k, model.mount.gam.resid.partial$s.st.road.dns.27k.)
plot (data.mount$st.nffd.sp.2010, model.mount.gam.resid.partial$s.st.nffd.sp.2010.)
plot (data.mount$st.pas.wt.2010, model.mount.gam.resid.partial$s.st.pas.wt.2010.)

# gam-specific model checks
plot (model.mount.gam, all.terms = F, residuals = T, pch = 20)  
gam.check (model.mount.gam) 
vis.gam (model.mount.gam, view = c ("st.nffd.sp.2010", "st.pas.wt.2010"), type = "response",
         plot.type = "contour") 
vis.gam (model.mount.gam, view = c ( "st.nffd.sp.2010", "st.road.dns.27k"), type = "response",
         plot.type = "contour") 
vis.gam (model.mount.gam, view = c ( "st.nffd.sp.2010", "st.tave.wt.2010"), type = "response",
         plot.type = "contour") 

# fit plots
plot (data.mount$st.tave.wt.2010, predict (model.mount.gam, type = 'response'))
plot (data.mount$st.nffd.sp.2010, predict (model.mount.gam, type = 'response'))
plot (data.mount$st.pas.wt.2010, predict (model.mount.gam, type = 'response'))
plot (data.mount$st.road.dns.27k, predict (model.mount.gam, type = 'response'))


##############
## NORTH ##
##############
model.north.gam <- gam (pttype ~ s(st.tave.wt.2010) + s(st.nffd.sp.2010) + s(st.pas.wt.2010) + 
                        s(st.road.dns.27k) + bec.curr.simple +
                        (st.tave.wt.2010*st.road.dns.27k) + (st.nffd.sp.2010*st.road.dns.27k) +
                        (st.pas.wt.2010*st.road.dns.27k) + (st.cut.perc*st.road.dns.27k), 
                        data = data.north,
                        family = binomial (link = 'logit'))

model.north.gam.resid.partial <- data.frame (predict (model.north.gam, type = "terms") + 
                                               residuals (model.north.gam)) # calculate partial residuals
plot (predict (model.north.gam, type = 'response'), residuals.gam (model.north.gam, type = "pearson")) # should be mostly a straight line
plot (data.north$st.tave.wt.2010, model.north.gam.resid.partial$s.st.tave.wt.2010.) 
plot (data.north$st.road.dns.27k, model.north.gam.resid.partial$s.st.road.dns.27k.)
plot (data.north$st.nffd.sp.2010, model.north.gam.resid.partial$s.st.nffd.sp.2010.)
plot (data.north$st.pas.wt.2010, model.north.gam.resid.partial$s.st.pas.wt.2010.)

# gam-specific model checks
plot (model.north.gam, all.terms = F, residuals = T, pch = 20)  
gam.check (model.north.gam) 
vis.gam (model.north.gam, view = c ("st.road.dns.27k", "st.pas.wt.2010"), type = "response",
         plot.type = "contour") 
vis.gam (model.north.gam, view = c (  "st.road.dns.27k", "st.nffd.sp.2010"), type = "response",
         plot.type = "contour") 
vis.gam (model.north.gam, view = c ( "st.road.dns.27k", "st.tave.wt.2010"), type = "response",
         plot.type = "contour") 

# fit plots
plot (data.north$st.tave.wt.2010, predict (model.north.gam, type = 'response'))
plot (data.north$st.nffd.sp.2010, predict (model.north.gam, type = 'response'))
plot (data.north$st.pas.wt.2010, predict (model.north.gam, type = 'response'))
plot (data.north$st.road.dns.27k, predict (model.north.gam, type = 'response'))
